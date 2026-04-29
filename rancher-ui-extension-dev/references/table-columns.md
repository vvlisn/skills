# Table Columns

Table Columns are added to Rancher via the `addTableColumn` method.

## addTableColumn

This method adds a table column to a `ResourceTable` element-based table on the UI.

Method:

```ts
plugin.addTableColumn(where: TableColumnLocation | string, when: LocationConfig | string, column: TableColumn);
```

> When `when` is a plain string, it is treated as `{ resource: [string] }` shorthand.

_Arguments_

`where` string parameter admissible values for this method:

| Key | Type | Description |
|---|---|---|
|`TableColumnLocation.RESOURCE`| String | Location for a table column on a Resource List View page |

<br/>

`when` Object admissible values:

`LocationConfig` as described above for the [LocationConfig object](location-config.md#locationconfig).

An additional `paginationColumn` parameter can be provided which will be used to support the column when server-side pagination is enabled. For more information see the [performance docs](https://extensions.rancher.io/extensions/performance).

The default position for a new column is just before the `Age` column. Use the `weight` property to specify a custom position (`0` = first column).

```ts
plugin.addTableColumn(where: TableColumnLocation | string, when: LocationConfig | string, column: TableColumn, paginationColumn?: PaginationTableColumn);
```

### TableColumnLocation.RESOURCE column

<!-- Screenshot: table columns -->

`column` config object. Admissible parameters for the `column` with `'TableColumnLocation.RESOURCE'` are:

| Key | Type | Description |
|---|---|---|
|`name`| String | Unique identifier for the column |
|`label`| String | Display label for the column header |
|`weight`| Int | Order/position of the table column added inside a table |
|`labelKey`| String | Same as "label" but allows for translation. Will supersede "label" |
|`value`| String | Object property to obtain the value from |
|`getValue`| Function | Same as "value", but it can be a function. Will supersede "value" |
|`width`| Int | Column width (in `px`). Optional |
|`sort`| boolean,string,Array | Object properties to be bound to the table sorting. Optional |
|`search`| boolean,string,Array | Object properties to be bound to the table search. Optional |
| `formatter`| string | Name of a `formatter` component used to render the cell. Components should be in the extension `formatters` folder
| `formatterOpts`| any | Provide additional values to the `formatter` component via a `formatterOpts` component param

Usage example for `'TableColumnLocation.RESOURCE'`:

```ts
plugin.addTableColumn(
  TableColumnLocation.RESOURCE,
  { resource: ['configmap'] },
  {
    name:     'some-prop-col',
    labelKey: 'generic.comingSoon',
    weight: 2,
    getValue: (row: any) => {
      return `${ row.id }-DEMO-COL-STRING-ADDED!`;
    },
    width: 100,
    sort: ['stateSort', 'nameSort'],
    search: ['stateSort', 'nameSort'],
  }
);
```