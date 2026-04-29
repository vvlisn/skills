# Edit & Detail Page Patterns

This document describes the standard patterns for creating edit (create/update) and detail (view) pages in Rancher UI extensions. **Always** follow these patterns instead of implementing custom form handling or save logic.

## Edit Page Pattern

An edit page handles Create, Edit, and View modes for a resource.

### Required structure

1. **File location**: `pkg/<extension>/edit/<resource.type>.vue`
2. **Wrapper component**: `CruResource` (handles form/YAML toggle, save button, error display)
3. **Mixin**: `CreateEditView` (provides `save()`, `done()`, `isCreate`, `isEdit`, `isView`, etc.)
4. **Form components**: Use `@shell/components/form/*` — never implement raw `<input>` or custom save buttons

### Minimal edit page template

```vue
<script>
import CreateEditView from '@shell/mixins/create-edit-view';
import CruResource from '@shell/components/CruResource.vue';
import NameNsDescription from '@shell/components/form/NameNsDescription';
import LabeledInput from '@components/Form/LabeledInput/LabeledInput.vue';
import LabeledSelect from '@shell/components/form/LabeledSelect.vue';
import Tab from '@shell/components/Tabbed/Tab';
import Tabbed from '@shell/components/Tabbed';
import Labels from '@shell/components/form/Labels.vue';

export default {
  name: 'MyResourceEdit',

  components: {
    CruResource,
    NameNsDescription,
    LabeledInput,
    LabeledSelect,
    Tab,
    Tabbed,
    Labels,
  },

  mixins: [CreateEditView],

  props: {
    mode: {
      type:     String,
      required: true,
    },
    value: {
      type:     Object,
      required: true,
    },
  },
};
</script>

<template>
  <CruResource
    :resource="value"
    :mode="mode"
    :errors="errors"
    :done-route="doneRoute"
    @finish="save"
    @error="e => errors = e"
  >
    <NameNsDescription
      :value="value"
      :mode="mode"
      :namespaced="isNamespaced"
    />

    <Tabbed :side-tabs="true">
      <Tab name="basics" :label="t('generic.basics')" :weight="10">
        <LabeledInput
          v-model:value="value.spec.someField"
          :mode="mode"
          label="Some Field"
          required
        />
        <LabeledSelect
          v-model:value="value.spec.type"
          :mode="mode"
          label="Type"
          :options="typeOptions"
        />
      </Tab>

      <Tab name="labels" :label="t('generic.labelsAndAnnotations')" :weight="-1">
        <Labels
          :value="value"
          :mode="mode"
          :display-side-by-side="false"
        />
      </Tab>
    </Tabbed>
  </CruResource>
</template>
```

### Key rules

- **CruResource** wraps the entire form. It provides:
  - Save/Cancel buttons (via `CruResourceFooter`)
  - YAML editor toggle
  - Error banner display
  - Wizard step support (via `steps` prop)
- **@finish event** on CruResource triggers `CreateEditView.save()` which calls `SteveModel.save()`.
- **Never** implement your own save button or API call. Use the built-in flow.
- **Never** use raw `<input>`, `<select>`, or `<textarea>`. Use Rancher form components.

### Save flow

```
User clicks Save → CruResource emits "finish"
  → CreateEditView.save() is called
    → applyHooks(BEFORE_SAVE_HOOKS)
    → resource.save() (SteveModel)
      → SteveModel.cleanForSave() removes internal fields
      → POST (create) or PUT (edit) to Steve API
    → applyHooks(AFTER_SAVE_HOOKS)
    → done() navigates to doneRoute
```

To customize save behavior, override `saveOverride()` or register hooks with `registerBeforeSaveHook()` / `registerAfterSaveHook()`.

### CruResource props

| Prop | Type | Description |
|------|------|-------------|
| `resource` | Object | The resource being edited (required) |
| `mode` | String | `_CREATE`, `_EDIT`, or `_VIEW` (required) |
| `errors` | Array | Error messages to display |
| `doneRoute` | String/Object | Route after save/cancel |
| `validationPassed` | Boolean | Enable/disable save button |
| `canYaml` | Boolean | Show YAML editor toggle (default: true) |
| `finishButtonMode` | String | Override save button label |
| `steps` | Array | Wizard steps configuration |

### CruResource slots

| Slot | Description |
|------|-------------|
| `default` | Main form content |
| `form-footer` | Custom footer (overrides Save/Cancel) |
| `noticeBanner` | Top notice banner |
| `subtypes` | Resource subtype selection |

## Detail Page Pattern

A detail page displays read-only information about a resource.

### Required structure

1. **File location**: `pkg/<extension>/detail/<resource.type>.vue`
2. The framework automatically renders detail pages via `ResourceDetail` component
3. For custom detail views, create the file and it will be auto-discovered

### Minimal detail page template

```vue
<script>
import { Banner } from '@components/Banner';
import ResourceTabs from '@shell/components/form/ResourceTabs';
import Tab from '@shell/components/Tabbed/Tab';

export default {
  name: 'MyResourceDetail',

  components: {
    Banner,
    ResourceTabs,
    Tab,
  },

  props: {
    value: {
      type:     Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <ResourceTabs
      :value="value"
      :side-tabs="true"
    >
      <template #before>
        <Banner
          v-if="value.spec.someWarning"
          color="warning"
          :label="value.spec.someWarning"
        />
      </template>

      <Tab name="overview" label="Overview" :weight="10">
        <div class="row mb-20">
          <div class="col span-6">
            <span class="text-label">Status</span>
            <span>{{ value.status.phase }}</span>
          </div>
        </div>
      </Tab>
    </ResourceTabs>
  </div>
</template>
```

### Key rules

- **ResourceTabs** extends `Tabbed` and auto-includes Conditions, Related Resources, and Events tabs.
- The `DetailTop` component (metadata, labels, annotations) is automatically rendered by `ResourceDetail`.
- Detail pages receive `value` prop (the resource model) — use model computed properties for display.

## Available Form Components

All form components support `mode` prop (`_CREATE`, `_EDIT`, `_VIEW`) and auto-disable in view mode.

### Core form components

| Component | Import | Purpose |
|-----------|--------|---------|
| `NameNsDescription` | `@shell/components/form/NameNsDescription` | Name + namespace + description fields |
| `LabeledInput` | `@components/Form/LabeledInput/LabeledInput.vue` | Text/number input |
| `LabeledSelect` | `@shell/components/form/LabeledSelect.vue` | Dropdown select |
| `KeyValue` | `@shell/components/form/KeyValue` | Key-value pair editor |
| `ArrayList` | `@shell/components/form/ArrayList` | Array/list editor |
| `Labels` | `@shell/components/form/Labels.vue` | Kubernetes labels/annotations |
| `Checkbox` | `@components/Form/Checkbox` | Checkbox |
| `RadioGroup` | `@components/Form/Radio/RadioGroup.vue` | Radio button group |
| `FileSelector` | `@shell/components/form/FileSelector` | File upload |
| `Select` | `@shell/components/form/Select` | Basic select |

### Layout components

| Component | Import | Purpose |
|-----------|--------|---------|
| `Tabbed` | `@shell/components/Tabbed` | Tab container |
| `Tab` | `@shell/components/Tabbed/Tab` | Individual tab |
| `Accordion` | `@components/Accordion/Accordion.vue` | Collapsible section |
| `Banner` | `@components/Banner/Banner.vue` | Info/warning/error banner |
| `Loading` | `@shell/components/Loading` | Loading spinner |
| `AsyncButton` | `@shell/components/AsyncButton` | Button with loading state |
| `ResourceTabs` | `@shell/components/form/ResourceTabs` | Tab container with auto Conditions/Events tabs |

### Kubernetes-specific form components

| Component | Import | Purpose |
|-----------|--------|---------|
| `MatchExpressions` | `@shell/components/form/MatchExpressions` | Label selectors |
| `Tolerations` | `@shell/components/form/Tolerations` | Pod tolerations |
| `NodeAffinity` | `@shell/components/form/NodeAffinity` | Node affinity rules |
| `PodAffinity` | `@shell/components/form/PodAffinity` | Pod affinity rules |

## CreateEditView Mixin

The `CreateEditView` mixin from `@shell/mixins/create-edit-view` provides:

### Computed properties

| Property | Description |
|----------|-------------|
| `isCreate` | `mode === _CREATE` |
| `isEdit` | `mode === _EDIT` |
| `isView` | `mode === _VIEW` |
| `schema` | Resource schema from store |
| `isNamespaced` | Whether resource type is namespaced |
| `labels` / `annotations` | Getter/setter for resource labels/annotations |
| `doneRoute` | Auto-computed return route after save |

### Methods

| Method | Description |
|--------|-------------|
| `save(buttonDone, url)` | Standard save flow — calls `SteveModel.save()` |
| `done()` | Navigate to `doneRoute` |
| `setErrors(errors)` | Set error messages for display |

### Hooks

Register hooks for custom pre/post save logic:

```js
created() {
  this.registerBeforeSaveHook(this.validate, 'my-validation');
  this.registerAfterSaveHook(this.createRelated, 'create-related-resource');
},
```
