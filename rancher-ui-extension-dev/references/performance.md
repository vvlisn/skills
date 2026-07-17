# Performance & scaling (Server-Side Pagination)

Rancher deployments routinely connect to clusters with **10,000+ pods** or **20,000+ nodes**. From **v2.12.0** the Dashboard shifted away from the legacy "fetch every resource + subscribe to every WebSocket update" model — a model that does not scale and produces long load times, memory bloat, and hundreds of socket messages per second.

The replacement is **Server-Side Pagination (SSP)** plus sparse watches: fetch only what the current view needs, get a single "type changed" watch notification, and re-fetch with the original filters when that happens.

**Extensions MUST support both SSP-enabled and SSP-disabled modes.** SSP is controlled by the `ui-sql-cache` feature flag; the user can toggle it, and until v2.13.0 the legacy path is not deprecated.

---

## When this applies

SSP only affects the Rancher **"Steve" API**:

| API surface | Example URL | SSP applies? |
|---|---|---|
| Steve (aggregated) | `/v1/<resource>`, `/k8s/clusters/<cid>/v1/...` | **Yes — refactor required** |
| Norman | `/v3/<resource>` | No — leave as-is |
| Native Kube | `/apis/...`, `/k8s/clusters/<cid>/apis/...` | No — leave as-is |

If an extension only talks to `/v3/*` or `/apis/*` there is nothing to do here.

---

## Detecting SSP availability per resource type

Even when the feature flag is on, individual resource types may not have SSP wired up yet. Always probe before choosing a code path:

```ts
// cluster-scoped resource
this.$store.getters['cluster/paginationEnabled'](POD);

// management-scoped resource
this.$store.getters['management/paginationEnabled'](MANAGEMENT.CLUSTER);
```

Branch on the boolean: use the new API when `true`, fall back to `findAll` when `false`.

---

## Three refactor axes

### 1. `findAll` → `findPage` (globally cached types)

The store keeps **one cache per resource type**. When the whole extension only needs a single filtered view of that type, replace `findAll` with `findPage`, which fetches a single page's worth via server-side pagination.

Filter argument shape lives in `shell/types/store/pagination.types.ts` — see the `FilterArgs` type and inline comments. The underlying wire format is the Steve API (internal; may change without notice).

**Reference implementations** in `rancher/dashboard`:
- `shell/edit/serviceaccount.vue` → `filterSecretsByApi` — fetches only secrets matching a specific type when SSP is enabled, otherwise falls back to all secrets.
- `shell/detail/node.vue` → `fetch` — fetches only pods belonging to a specific node when SSP is enabled.
- `shell/pages/home.vue` — `fetchSecondaryResources` runs when SSP is **disabled** (fetch all); `fetchPageSecondaryResources` runs when SSP is **enabled** (fetch just the current page's associations).

Pattern sketch:

```ts
const paged = store.getters['cluster/paginationEnabled'](POD);

if (paged) {
  await store.dispatch('cluster/findPage', { type: POD, opts: { filters, pagination } });
} else {
  await store.dispatch('cluster/findAll', { type: POD });
}
```

### 2. `findAll` / ad-hoc fetch → `PaginationWrapper` (uncached / multi-context)

The cache is 1:1 with type. If a single view needs **multiple different filtered result sets of the same type** (e.g. "clusters in error state" plus "clusters offline"), successive `findPage` calls would overwrite each other's cache. Use **`PaginationWrapper`** to hold each result set out of the store cache while still receiving updates.

**Reference implementation**: `shell/components/nav/TopLevelMenu.helper.ts` — the top-of-sidebar cluster list needs two independently filtered views of the same `MANAGEMENT.CLUSTER` type:
- SSP **disabled**: fill the shared cache with all clusters, apply local filters.
- SSP **enabled**: two `PaginationWrapper` instances each fetch their server-filtered slice, keep it in their own state, and subscribe to updates (cluster comes online, is created, deleted, etc.).

### 3. `findMatching` / local label filtering → `findLabelSelector` + typed `matching()`

Kubernetes `labelSelectors` used to be applied either through the native Kube API or by fetching **all** resources and filtering client-side. From v2.12.0 the Rancher API can apply them server-side.

Replace:
- `findMatching(...)` (store action) → **`findLabelSelector(...)`** — picks the right transport based on the SSP flag.
- `shell/utils/selector.js` `matching(array, selector)` → **`shell/utils/selector-typed.ts` `matching(...)`** — the new helper both fetches and filters, choosing the right transport internally.

**Reference implementations**:
- `shell/models/service.js` → `fetchPods` — calls `findLabelSelector` to fetch pods matching the service's relationship selector.
- `shell/components/form/ResourceSelector.vue` — the labelSelector-driven picker; internally uses the typed `matching`.

---

## Component replacement: `LabeledSelect` → `ResourceLabeledSelect`

Any form field where the user picks a resource from a list must use **`ResourceLabeledSelect`**. It supports both modes transparently:

- SSP off → fetches everything, displays everything (legacy behavior).
- SSP on → fetches only a page's worth, shows only that page.

Extra behavior is tuned via the `paginatedResourceSettings` prop (type: `ResourceLabeledSelectPaginateSettings`) — configure the resource type, filters, and page size for your use case.

**Reference implementations**:
- `shell/components/form/SecretSelector.vue`
- `shell/chart/rancher-backup/S3.vue`

---

## Pre-merge checklist

Every change that touches Steve API access must be validated against **both** feature-flag states.

- [ ] All `findAll` calls for globally cached types have a `findPage` branch guarded by `paginationEnabled`.
- [ ] Types that require multiple concurrent filtered views use `PaginationWrapper` under SSP-on.
- [ ] All `findMatching` and local `selector.js` `matching(...)` calls are replaced with `findLabelSelector` + `selector-typed.ts` `matching(...)`.
- [ ] All resource-picking form controls use `ResourceLabeledSelect` (not `LabeledSelect`) with `paginatedResourceSettings` configured.
- [ ] The extension has been **manually tested** with `ui-sql-cache=enabled` **and** `ui-sql-cache=disabled` — both should render and behave identically to the user.
- [ ] Only Steve API endpoints were refactored. Norman (`/v3/*`) and native Kube (`/apis/*`) calls are untouched.
- [ ] For each resource type touched, the code probes `paginationEnabled` — types may not have SSP support even when the flag is on.

---

## Toggling the flag while testing

The `ui-sql-cache` feature flag lives under `Global Settings → Feature Flags` in Rancher (or `management.cattle.io.feature` resource). Toggle it, reload the extension, and re-exercise the affected flows.

---

## Common symptoms of missing this work

| Symptom | Likely cause |
|---|---|
| List page takes seconds to render on a large cluster; memory balloons | `findAll` on a type with thousands of instances — needs `findPage` under SSP-on. |
| Small clusters fine, large clusters lag when scrolling a picker | `LabeledSelect` not replaced with `ResourceLabeledSelect`. |
| WebSocket messages flood the console; the page re-renders constantly | Legacy `findAll` + change-broadcast path — SSP path not implemented, so with SSP off the browser is drowning in socket updates. |
| Two panels of the same resource type "fight" each other (one wipes the other's data) | Both call `findPage` against the same store cache — one must switch to `PaginationWrapper`. |
| `findMatching` returns empty on a huge cluster | Server-side pagination is enabled and the extension is still applying the label selector locally on an already-truncated dataset. Switch to `findLabelSelector`. |

---

## References

- Overview: <https://extensions.rancher.io/extensions/next/performance/scaling/overview>
- Requests: <https://extensions.rancher.io/extensions/next/performance/scaling/requests>
- Selects:  <https://extensions.rancher.io/extensions/next/performance/scaling/selects>
- Filter types: `shell/types/store/pagination.types.ts` (`FilterArgs`)
- Feature flag: `ui-sql-cache`
- Rancher 2.12.0 release notes for the underlying platform change
