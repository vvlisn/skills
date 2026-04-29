# Panels

A Panel is a defined area in the Rancher UI where custom UI components can be shown.

Panels are added to Rancher via the `addPanel` method.

## addPanel

This method adds a panel/content to the UI.

Method:

```ts
plugin.addPanel(where: PanelLocation | string, when: LocationConfig | string, options: Object);
```

> When `when` is a plain string, it is treated as `{ resource: [string] }` shorthand.

_Arguments_

`where` string parameter admissable values for this method:

| Key | Type | Description |
|---|---|---|
|`PanelLocation.DETAILS_MASTHEAD`| String | Location for a panel on the Details Masthead area of a Resource Detail page (modes: `detail`, `edit`, `config`, `create`) |
|`PanelLocation.DETAIL_TOP`| String | Location for a panel on the Detail Top area of a Resource Detail page (modes: `detail`, `edit`, `config`, `create`) |
|`PanelLocation.RESOURCE_LIST`| String | Location for a panel on a Resource List View page (above the table area, mode: `list`) |
|`PanelLocation.ABOUT_TOP`| String | Location for a panel on the About page of Rancher Dashboard |

<br/>

`when` Object admissable values:

`LocationConfig` as described above for the [LocationConfig object](location-config.md#locationconfig).

<br/>
<br/>

### PanelLocation.DETAILS_MASTHEAD options

<!-- Screenshot: masthead panel -->

`options` config object. Admissable parameters for the `options` with `'PanelLocation.DETAILS_MASTHEAD'` are:

| Key | Type | Description |
|---|---|---|
|`component`| Function | Component to be rendered as content on the "detail view" Masthead component |

Usage example for `'PanelLocation.DETAILS_MASTHEAD'`:

```ts
plugin.addPanel(
  PanelLocation.DETAILS_MASTHEAD,
  { resource: ['catalog.cattle.io.clusterrepo'] },
  { component: () => import('./MastheadDetailsComponent.vue') }
);
```

<br/>
<br/>

### PanelLocation.DETAIL_TOP options

<!-- Screenshot: detail top panel -->

`options` config object. Admissable parameters for the `options` with `'PanelLocation.DETAIL_TOP'` are:

| Key | Type | Description |
|---|---|---|
|`component`| Function | Component to be rendered as content on the "detail view" detailTop component |

Usage example for `'PanelLocation.DETAIL_TOP'`:

```ts
plugin.addPanel(
  PanelLocation.DETAIL_TOP,
  { resource: ['catalog.cattle.io.clusterrepo'] },
  { component: () => import('./DetailTopComponent.vue') }
);
```

<br/>
<br/>

### PanelLocation.RESOURCE_LIST options

<!-- Screenshot: list view panel -->

`options` config object. Admissable parameters for the `options` with `'PanelLocation.RESOURCE_LIST'` are:

| Key | Type | Description |
|---|---|---|
|`component`| Function | Component to be rendered as content above a table on a "list view" |

Usage example for `'PanelLocation.RESOURCE_LIST'`:

```ts
plugin.addPanel(
  PanelLocation.RESOURCE_LIST,
  { resource: ['catalog.cattle.io.app'] },
  { component: () => import('./BannerComponent.vue') }
);
```

<br/>
<br/>

### PanelLocation.ABOUT_TOP options

<!-- Screenshot: about top panel -->

> NOTE: this Panel will only appear on the area designated in the screenshot in the About page of Rancher UI

`options` config object. Admissable parameters for the `options` with `'PanelLocation.ABOUT_TOP'` are:

| Key | Type | Description |
|---|---|---|
|`component`| Function | Component to be rendered as content above a table on a "list view" |

Usage example for `'PanelLocation.ABOUT_TOP'`:

```ts
plugin.addPanel(
  PanelLocation.ABOUT_TOP,
  {},
  { component: () => import('./BannerComponent.vue') }
);
```