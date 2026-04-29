# Support matrixes

## Shell support matrix

The Shell package enables Extensions to integrate with Rancher.  
It's important to know which version of the Shell package is compatible with each Rancher version:

| | Rancher 2.7.x | Rancher 2.8.x <br/> (Extensions API V1) | Rancher 2.9.x <br/> (Extensions API V2) | Rancher 2.10.x+ <br/> (Extensions API V3) |
|---|---|---|---|---|
|Shell **0.3.8**|**Supported**|Limited support|Not supported|Not supported|
|Shell 0.5.3/**1.2.3**|Limited support|**Supported**|Not supported|Not supported|
|Shell **2.0.1**|Not supported|Not supported|**Supported**|Not supported|
|Shell **3.0.x**|Not supported|Not supported|Not supported|**Supported**|

> **Note:** Shell 3.0.x covers Rancher 2.10.x through 2.15.x (current master). The exact Shell patch version for each Rancher release is in `shell/package.json` (currently 3.0.10 on master / v2.15.0).

To know more about the Shell package versioning take a look at the [Rancher 2.9 support docs](https://extensions.rancher.io/extensions/rancher-2.9-support).

## Extension API support matrix

Here's the support matrix for every Extension API hook available in Rancher:

| API | Rancher Version support (Minimum version)|
| --- | --- |
| Metadata | v2.7.0 |
| Products | v2.7.0 |
| Routes | v2.7.0 |
| Actions | v2.7.2 |
| Cards | v2.7.2 |
| Panels | v2.7.2 |
| Tabs | v2.7.2 |
| Table Columns | v2.7.2 |
| Table | v2.14.0 |
| Components | v2.7.0 |


## LocationConfig support matrix

The `LocationConfig` object is one of the keystones to define in which place in the UI a given Extension API hook should be applied to. For more information about its usage and support matrix check the [LocationConfig documentation](location-config.md#locationconfig).
