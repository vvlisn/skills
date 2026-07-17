# Products

A product is a top-level view in Rancher. A product typically adds a navigation entry into the
top-level slide-in menu in Rancher. When the user navigates to the link, the product renders
the entire view beneath the header bar.

Products typically declare their navigation such that it is presented on the left-hand side, e.g.

## Registering a Product

Defining a product leverages the `addProduct` extension method, which should be defined on the `index.ts` on your root folder:

```ts
import { IPlugin } from '@shell/core/types';

// Init the package
export default function(plugin: IPlugin) {
  // ....

  // ... provide metadata

  // Load a product
  plugin.addProduct(require('./product'));
}
```

The `addProduct` method registers a module which will be invoked by Rancher at the
appropriate point in its lifecycle to create the product.

You can register more than one product in an extension.

## Product Definition

The module registered via `addProduct` must export an `init` method. This is invoked with two parameters;

- The `$extension` API
- The VueX store

### Creating a product

An example `init` function for creating a new product is shown below:

```ts
import { IPlugin } from '@shell/core/types';

export function init($extension: IPlugin, store: any) {
  const YOUR_PRODUCT_NAME = 'myProductName';
  
  const { product } = $extension.DSL(store, YOUR_PRODUCT_NAME);

  product({
    icon: 'gear',
    inStore: 'management',
    weight: 100,
    to: // this will the route path that will be your entry point for this product
  });
}
```
The function `product` comes from `$extension.DSL` will add your extension to the top-level slide-in menu.

> Note: `plugin.DSL` is called with the store and your product name and returns a number of functions to add and configure products and navigation. The example above shows the use of the `product` function


The allowed parameters for the `product` function are:

| Key | Type | Description |
| --- | --- | --- |
| `icon` | String | icon name (based on [rancher icons](https://rancher.github.io/icons/)) |
| `svg` | Module | SVG icon (alernative to above). Typically use the `require` method with a path of an SVG file|
| `inStore` | String |  Which store should the product be registered on. Use `management` for a top-level product and `cluster` for a cluster-level product |
| `weight` | Int |  Side menu ordering (bigger number on top) |
| `to` | [Vue Router route config](https://v3.router.vuejs.org/api/#routes) |  Route to where the click on the product top-level menu should lead to |

---

## Top-level vs cluster-level products

| Aspect | Top-level | Cluster-level |
|---|---|---|
| `inStore` (only defining field) | `'management'` | `'cluster'` |
| URL shape | `/<PRODUCT>/c/:cluster/…` | `/c/:cluster/<PRODUCT>/…` |
| Route name prefix | `${PRODUCT}-c-cluster-*` | `c-cluster-${PRODUCT}-*` |
| `meta.cluster` in routes | `'_'` (BLANK_CLUSTER) | omitted — the `:cluster` URL param is enough |
| Placement | Global side-nav (like Fleet, Continuous Delivery) | Inside Cluster Explorer for the selected cluster |
| `plugin.addRoutes(...)` in `index.ts` | **Required** | **Required** |

Official complete examples:
- Top-level: https://extensions.rancher.io/extensions/next/usecases/top-level-product
- Cluster-level: https://extensions.rancher.io/extensions/next/usecases/cluster-level-product

### Cluster-level product complete example

Three files are always needed. Missing `plugin.addRoutes(routes)` or
using the top-level route naming will make the side-nav entry 404 even
when `inStore: 'cluster'` is set correctly.

**`pkg/<name>/index.ts`** — register the product **and** its routes:

```ts
import { importTypes } from '@rancher/auto-import';
import { IPlugin } from '@shell/core/types';
import extensionRouting from './routing/extension-routing';

export default function(plugin: IPlugin) {
  importTypes(plugin);
  plugin.metadata = require('./package.json');
  plugin.addProduct(require('./product'));
  plugin.addRoutes(extensionRouting);  // MANDATORY for cluster-level products
}
```

**`pkg/<name>/product/index.ts`** — the DSL registration:

```ts
import { IPlugin } from '@shell/core/types';

export function init($extension: IPlugin, store: any) {
  const PRODUCT = 'myProduct';
  const RESOURCE = 'my.group.io.widget';

  const { product, configureType, basicType, headers } = $extension.DSL(store, PRODUCT);

  product({
    inStore: 'cluster',                              // ← the ONLY switch
    icon:    'globe',
    weight:  100,
    to:      {
      name:   `c-cluster-${ PRODUCT }-resource`,     // ← template string, not a literal
      params: { product: PRODUCT, resource: RESOURCE },
    },
  });

  configureType(RESOURCE, {
    displayName: 'Widget',
    isCreatable: true,
    isEditable:  true,
    isRemovable: true,
    canYaml:     true,
    namespaced:  false,
    customRoute: {
      name:   `c-cluster-${ PRODUCT }-resource`,
      params: { product: PRODUCT, resource: RESOURCE },
    },
  });

  basicType([RESOURCE]);
  headers(RESOURCE, [/* your columns */]);
}
```

**`pkg/<name>/routing/extension-routing.ts`** — reuse shell resource pages:

```ts
import ListResource from '@shell/pages/c/_cluster/_product/_resource/index.vue';
import CreateResource from '@shell/pages/c/_cluster/_product/_resource/create.vue';
import ViewResource from '@shell/pages/c/_cluster/_product/_resource/_id.vue';
import ViewNamespacedResource from '@shell/pages/c/_cluster/_product/_resource/_namespace/_id.vue';

const PRODUCT = 'myProduct';

export default [
  { name: `c-cluster-${ PRODUCT }-resource`,               path: `/c/:cluster/${ PRODUCT }/:resource`,                     component: ListResource,           meta: { product: PRODUCT } },
  { name: `c-cluster-${ PRODUCT }-resource-create`,        path: `/c/:cluster/${ PRODUCT }/:resource/create`,              component: CreateResource,         meta: { product: PRODUCT } },
  { name: `c-cluster-${ PRODUCT }-resource-id`,            path: `/c/:cluster/${ PRODUCT }/:resource/:id`,                 component: ViewResource,           meta: { product: PRODUCT } },
  { name: `c-cluster-${ PRODUCT }-resource-namespace-id`,  path: `/c/:cluster/${ PRODUCT }/:resource/:namespace/:id`,      component: ViewNamespacedResource, meta: { product: PRODUCT } },
];
```

The `list/`, `detail/`, `edit/` `.vue` files under `pkg/<name>/` are
auto-imported and slot into these shell pages as per-type overrides.

### Kubewarden variant (production reference)

The Kubewarden extension is a real cluster-level product that deviates
from the official example in two ways worth knowing about:

```ts
// pkg/kubewarden/config/kubewarden.ts (excerpt)
product({
  inStore:             'cluster',
  inExplorer:          true,      // ← not in the official example, but valid
  icon:                'kubewarden',
  removeable:          false,
  showNamespaceFilter: true,
  // no `to`, no `weight`
});
```

- **`inExplorer: true`** mounts the product as a group *inside* the
  Cluster Explorer side-nav (rather than as a sibling product). When set,
  `to` and `weight` can be omitted — shell picks a default landing route
  from the first `virtualType`/`basicType` entry.
- **Custom pages instead of shell resource pages**: Kubewarden routes
  point to `@kubewarden/pages/…` instead of `@shell/pages/c/_cluster/_product/_resource/*`.
  Use this pattern when you want a bespoke dashboard page instead of
  Rancher's default list/create/detail chrome.

Either pattern is valid — pick the official one for stock CRD CRUD, the
Kubewarden one when you need a custom dashboard.

### Hook-into-explorer pattern (parasitic mode)

When you only need to add a few CRD entries to the **existing** Cluster
Explorer side-nav — without creating a standalone product — you can hook
directly into the `explorer` product.

**Key difference from cluster-level product**: no `product()` call, no
`plugin.addRoutes()`, no custom routing file. Explorer's built-in routes
handle everything.

#### DSL call: `import { DSL }` vs `plugin.DSL`

| Scenario | Use | Why |
|----------|-----|-----|
| Registering **your own** product (top-level or cluster-level) | `$extension.DSL(store, MY_PRODUCT)` | Plugin tracks the product in `productNames`; uninstall cleans it properly |
| Hooking into **someone else's** product (e.g. explorer) | `import { DSL } from '@shell/store/type-map'` | Avoids registering `'explorer'` in your `productNames` — otherwise uninstalling your extension triggers `removeProduct('explorer')` and **destroys the entire Cluster Explorer** |

**Source-code proof** (`@shell/core/plugin.ts`):
```ts
DSL(store: any, productName: string) {
  const storeDSL = STORE_DSL(store, productName);
  this.productNames.push(productName);  // ← unconditional push
  return storeDSL;
}
```

On uninstall (`@shell/core/extension-manager-impl.js`):
```ts
plugin.productNames.forEach((product) => {
  store.dispatch('type-map/removeProduct', { product, plugin });
});
```

`removeProduct` splices the product from `state.products`, deletes its
`virtualTypes`, `basicTypes`, `typeOptions`, `headers`, and all caches.
If `'explorer'` was in your `productNames`, the entire Cluster Explorer
UI is wiped.

#### When to use this pattern

- You have 1–3 CRDs that logically belong inside Cluster Explorer
- The CRDs may already be grouped under an API group mapped by another
  extension (e.g. `container.starbucks.net → PaaS`)
- You need standard CRUD (list / detail / edit / YAML) with no custom
  dashboard or landing page

#### Complete example

```ts
// pkg/<name>/config/types.ts
export const EXPLORER = 'explorer';
export const MY_CRD = 'my.group.io.widget';
```

```ts
// pkg/<name>/config/product.ts
import { DSL } from '@shell/store/type-map';   // ← NOT plugin.DSL
import { EXPLORER, MY_CRD } from './types';

export function init(_plugin: any, store: any): void {
  const {
    basicType,
    configureType,
    headers,
    mapGroup,
    virtualType,
    weightType,
  } = DSL(store, EXPLORER);

  virtualType({
    labelKey:   'myCrd.menuLabel',
    name:       'my-crd-menu',
    namespaced: false,
    group:      'myGroup',
    route:      {
      name:   'c-cluster-product-resource',
      params: { product: EXPLORER, resource: MY_CRD },
    },
    exact: false,
  });

  configureType(MY_CRD, {
    displayName: 'Widget',
    isCreatable: true,
    isEditable:  true,
    isRemovable: true,
    showAge:     true,
    showState:   true,
    canYaml:     true,
  });

  basicType(['my-crd-menu'], 'myGroup');
  headers(MY_CRD, [/* your columns */]);

  // Safety net: re-assert group display name in case another extension
  // that originally registered it loads after you, or gets reloaded.
  mapGroup('my.group.io', 'My Group');
}
```

```ts
// pkg/<name>/index.ts — NO addRoutes needed
import { importTypes } from '@rancher/auto-import';
import { IPlugin } from '@shell/core/types';

export default function(plugin: IPlugin): void {
  importTypes(plugin);
  plugin.metadata = require('./package.json');
  plugin.addProduct(require('./config/product'));
}
```

> **Warning**: The official `ui-plugin-examples/extension-crd` uses
> `plugin.DSL(store, 'explorer')`. This works in isolation but **breaks
> on uninstall** in production when other extensions also contribute to
> explorer. Always use `import { DSL }` for the parasitic pattern.

