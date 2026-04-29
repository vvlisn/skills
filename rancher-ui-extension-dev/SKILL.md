---
name: rancher-ui-extension-dev
description: Develop Rancher Dashboard UI extensions using the Rancher Extensions API. Use when the user wants to (1) create new UI extensions for Rancher, (2) modify existing Rancher extensions, (3) add custom pages, tabs, actions, panels, cards, or table columns to Rancher Dashboard, (4) work with @rancher/shell or @rancher/extension packages, (5) register products or configure routing in extensions, (6) build/publish Rancher extensions as Helm charts or ECI, or (7) asks about extension folder structure, version compatibility, or LocationConfig. Also use when the user mentions Rancher extensions, plugin.addProduct, plugin.addTab, plugin.addAction, SteveModel, or any Rancher extension API method.
---

# Rancher UI Extension Development

This skill helps develop Rancher Dashboard UI extensions. Extensions are packaged Vue libraries that extend Rancher UI with custom functionality via the Extensions API.

## When to use

- Creating or scaffolding new Rancher extensions
- Adding products, pages, routes, tabs, actions, panels, cards, or table columns
- Working with extension folder conventions (detail/, edit/, list/, models/, l10n/, etc.)
- Configuring version compatibility via `rancher.annotations`
- Building, developer-loading, or publishing extensions
- Understanding routing patterns (top-level vs cluster-level products)

## When NOT to use

- Generic Vue/TypeScript work unrelated to Rancher extensions
- Core dashboard development in `shell/` (use the project AGENTS.md instead)
- Kubernetes backend, controller, or CRD schema work with no Rancher UI scope

## First moves

1. **Classify the request**: scaffolding, API usage, routing, publishing, migration, or debugging.
2. **Read the relevant doc** from the reference map below before writing code.
3. **Follow the AGENTS.md** rules in `creators/extension/app/files/AGENTS.md` for code style and boundaries.

## Key concepts

### Two product types

| Type | `inStore` | Route pattern | Scope |
|------|-----------|---------------|-------|
| Top-level | `'management'` | `/<PRODUCT>/c/:cluster` | Global, like Fleet |
| Cluster-level | `'cluster'` | `/c/:cluster/<PRODUCT>` | Single cluster, within Cluster Explorer |

### Edit & detail page pattern

**Edit pages** must use `CruResource` + `CreateEditView` mixin. **Never** implement custom save buttons, raw `<input>` elements, or direct API calls.

| Role | Component / Mixin | Import |
|------|-------------------|--------|
| Form wrapper | `CruResource` | `@shell/components/CruResource.vue` |
| CRUD behavior | `CreateEditView` | `@shell/mixins/create-edit-view` |
| Name/NS/Desc | `NameNsDescription` | `@shell/components/form/NameNsDescription` |
| Text input | `LabeledInput` | `@components/Form/LabeledInput` |
| Dropdown | `LabeledSelect` | `@shell/components/form/LabeledSelect.vue` |
| Key-value pairs | `KeyValue` | `@shell/components/form/KeyValue` |
| Array/list | `ArrayList` | `@shell/components/form/ArrayList` |
| Labels/Annotations | `Labels` | `@shell/components/form/Labels.vue` |
| Tabs | `Tabbed` + `Tab` | `@shell/components/Tabbed` |
| Detail tabs | `ResourceTabs` | `@shell/components/form/ResourceTabs` |

Save flow: `CruResource @finish` → `CreateEditView.save()` → `SteveModel.save()` → API. Customize via `registerBeforeHook()` / `registerAfterHook()` or override `actuallySave(url)`.

**Read [references/edit-detail-patterns.md](references/edit-detail-patterns.md) before creating any edit or detail page.**

### Extension entry pattern

Every extension needs three files wired together:

1. **`index.ts`** — calls `importTypes(plugin)`, sets `plugin.metadata`, registers products via `plugin.addProduct()` and routes via `plugin.addRoutes()`.
2. **`product.ts`** — exports `init()` function, uses `$extension.DSL(store, name)` to call `product()` for side-menu registration.
3. **`routing/extension-routing.ts`** — defines Vue Router routes with required `product` and `cluster` params in `meta`.

### Extensions API methods

All UI enhancement methods follow the pattern: `plugin.<method>(where, when, options)`

| Method | `where` locations |
|--------|------------------|
| `addAction` | `ActionLocation.HEADER`, `ActionLocation.TABLE` |
| `addTab` | `TabLocation.RESOURCE_DETAIL_PAGE`, `RESOURCE_EDIT_PAGE`, `RESOURCE_CREATE_PAGE`, `RESOURCE_SHOW_CONFIGURATION`, `CLUSTER_CREATE_RKE2`, `OTHER` |
| `addPanel` | `PanelLocation.DETAILS_MASTHEAD`, `DETAIL_TOP`, `RESOURCE_LIST`, `ABOUT_TOP` |
| `addCard` | `CardLocation.CLUSTER_DASHBOARD_CARD` |
| `addTableColumn` | `TableColumnLocation.RESOURCE` |
| `addTableHook` | `TableLocation.RESOURCE` |

Additional plugin methods (no `where`/`when` pattern):

| Method | Purpose |
|--------|---------|
| `setHomePage(component)` | Set custom home page component |
| `addUninstallHook(hook)` | Register cleanup on plugin uninstall |
| `addStore(name, register, unregister)` | Register generic Vuex store |
| `addDashboardStore(name, specifics, config, init?)` | Register dashboard-aware Vuex store |
| `enableServerSidePagination(config)` | Enable SSP for specified resources |
| `addModelExtension(type, clz)` | *(experimental)* Extend resource models |
| `addNavHooks(hooks)` | Register enter/leave/login/logout hooks |

The `when` parameter is a **LocationConfig** object (also accepts a plain string as shorthand for `{ resource: [string] }`):

| Key | Type | Example |
|-----|------|---------|
| `product` | Array | `['explorer']` |
| `resource` | Array | `['apps.deployment']` or `['*']` |
| `cluster` | Array | `['local']` |
| `namespace` | Array | `['kube-system']` |
| `id` | Array | `['pod-nxr5vm']` |
| `mode` | Array | `['edit', 'create', 'detail', 'config', 'list']` |
| `hash` | Array | `['node-pools', 'conditions']` |
| `path` | Array | `[{ urlPath: '/c/local/explorer', exact: true }]` |
| `queryParam` | Object | `{ type: 'digitalocean' }` |
| `context` | Object | `{ provider: 'digitalocean' }` |

### Folder conventions

| Folder | Convention |
|--------|-----------|
| `detail/`, `edit/`, `list/` | File name = Kubernetes resource name |
| `models/` | Extend `SteveModel` from `@shell/plugins/steve/steve-class` |
| `l10n/` | Keys merge with core translations — scope keys to avoid collisions |
| `promptRemove/` | File name = resource name |

### Version compatibility

Set in `./pkg/<name>/package.json` under `rancher.annotations`:

| Annotation | Purpose |
|------------|---------|
| `catalog.cattle.io/rancher-version` | Rancher Manager semver range |
| `catalog.cattle.io/kube-version` | Kubernetes semver range |
| `catalog.cattle.io/ui-extensions-version` | Extensions API semver range |
| `catalog.cattle.io/display-name` | Display name on Extensions page |

## Reference map

Reference docs are bundled under `references/`. Read the relevant file before implementing. For topics not bundled locally, fetch the online URL.

**Priority rules**: AGENTS.md rules (code style, boundaries) > this SKILL.md > bundled reference docs. Reference docs may contain JS or Options API examples from the upstream Rancher docs — treat them as API reference only. Always generate code in TypeScript with Composition API, except when `CreateEditView` mixin requires Options API (see below).

### Getting started & structure
- [references/getting-started.md](references/getting-started.md) — Scaffolding, dev server, building, developer load
- [references/folder-structure.md](references/folder-structure.md) — Package folder conventions
- [references/configuration.md](references/configuration.md) — Package metadata and annotations
- [references/edit-detail-patterns.md](references/edit-detail-patterns.md) — **Edit & detail page patterns, CruResource, CreateEditView, form components**

### Products, routing & navigation
- [references/concepts.md](references/concepts.md) — Top-level vs cluster-level products
- [references/products.md](references/products.md) — Product registration via DSL
- [references/routing.md](references/routing.md) — Route definitions and patterns
- [references/custom-page.md](references/custom-page.md) — Custom page registration
- [references/resource-page.md](references/resource-page.md) — Resource page registration
- [references/side-menu.md](references/side-menu.md) — Side menu customization

### UI enhancement APIs
- [references/location-config.md](references/location-config.md) — LocationConfig reference
- [references/actions.md](references/actions.md) — addAction (header & table actions)
- [references/tabs.md](references/tabs.md) — addTab (all tab locations)
- [references/panels.md](references/panels.md) — addPanel
- [references/cards.md](references/cards.md) — addCard
- [references/table-columns.md](references/table-columns.md) — addTableColumn

### Publishing & compatibility
- [references/publishing.md](references/publishing.md) — Helm chart & ECI publishing
- [references/support-matrix.md](references/support-matrix.md) — Shell version support matrix

### Online-only (fetch the URL when needed)
- https://extensions.rancher.io/extensions/usecases/top-level-product — Complete top-level product example
- https://extensions.rancher.io/extensions/usecases/cluster-level-product — Complete cluster-level product example
- https://extensions.rancher.io/extensions/advanced/stores — Custom Vuex stores
- https://extensions.rancher.io/extensions/advanced/hooks — Extension lifecycle hooks
- https://extensions.rancher.io/extensions/advanced/localization — i18n / l10n
- https://extensions.rancher.io/extensions/advanced/workflow-configuration — CI/CD workflow config
- https://extensions.rancher.io/extensions/migration — Migration guide
- https://github.com/rancher/ui-plugin-examples — Examples repo

## Workflow

### New extension

1. Read [references/getting-started.md](references/getting-started.md)
2. Scaffold: `npm init @rancher/extension@latest <name>`
3. Create `index.ts`, `product.ts`, routing
4. Run: `API=<URL> yarn dev`

### Add UI enhancement to existing views

1. Read [references/location-config.md](references/location-config.md) for LocationConfig
2. Read the specific API doc (actions/tabs/panels/cards/table-columns)
3. Add the enhancement in `index.ts` using `plugin.add*()` methods
4. Test via dev server

### Publish

1. Read [references/publishing.md](references/publishing.md)
2. Set `rancher.annotations` in package.json
3. Use GitHub workflow (tagged release) or `yarn publish-pkgs`
