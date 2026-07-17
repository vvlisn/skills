# Testing (Jest + E2E)

The official scaffold (`npm init @rancher/extension@latest`) does **not** generate any test wiring. Extensions have to opt in. The pattern that production extensions (notably [kubewarden-ui](https://github.com/rancher/kubewarden-ui)) converge on is:

- **Unit tests**: Jest + `@vue/vue3-jest` + `ts-jest`, run from the extension root.
- **E2E tests**: either `@rancher/cypress` (official, page-objects included) or Playwright in an isolated `tests/` sub-workspace.

Pick unit tests first — they run fast and don't need a live Rancher. Add E2E only when the extension has non-trivial UI flows or you're shipping to a Prime channel that requires them.

---

## 1. Jest — minimal wiring

### 1.1 `package.json`

Add to your **top-level** development-app `package.json` (not the `pkg/<name>/package.json`):

```json
{
  "scripts": {
    "test:unit": "jest --watch",
    "test:ci":   "jest --collectCoverage"
  },
  "devDependencies": {
    "jest":                    "^29.7.0",
    "@types/jest":             "^29.5.14",
    "ts-jest":                 "^29.4.6",
    "@vue/vue3-jest":          "^29.2.6",
    "jest-environment-jsdom":  "^29.7.0",
    "flush-promises":          "^1.0.2",
    "eslint-plugin-jest":      "^28.11.0"
  }
}
```

Version notes:
- `jest@29` is the last major that plays well with the shell's Babel / Webpack toolchain. Do **not** jump to 30.x.
- `@vue/vue3-jest` — use the `vue3-jest` package, not the legacy `vue-jest`. Rancher UI is Vue 3.
- `ts-jest@29` matches Jest 29's peer.

### 1.2 `jest.config.ts` — complete template

Drop this at the extension root (next to `package.json`). It is the kubewarden config, generalised (rename `@kubewarden/*` to `@<yourpkg>/*`):

```ts
import type { Config } from '@jest/types';

const config: Config.InitialOptions = {
  preset:               'ts-jest',
  testEnvironment:      'jest-environment-jsdom',
  setupFilesAfterEach:  ['./jest.setup.ts'],           // optional, see 1.4
  moduleFileExtensions: ['js', 'json', 'vue', 'ts', 'tsx'],

  // Resolve shell + your own package aliases. See 1.3 for details.
  moduleNameMapper: {
    '^~/(.*)$':         '<rootDir>/$1',
    '^~~/(.*)$':        '<rootDir>/$1',
    '^@/(.*)$':         '<rootDir>/$1',
    '@shell/(.*)':      '<rootDir>/node_modules/@rancher/shell/$1',
    '@components/(.*)': '<rootDir>/node_modules/@rancher/components/dist/@rancher/components.common.js',
    '@<yourpkg>/(.*)':  '<rootDir>/pkg/<yourpkg>/$1',
    '@tests/(.*)':      '<rootDir>/tests/$1'
  },

  transform: {
    '^.+\\.js$':   '<rootDir>/node_modules/babel-jest',
    '.*\\.vue$':   '<rootDir>/node_modules/@vue/vue3-jest',
    '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.json' }],
    '^.+\\.svg$':  '<rootDir>/tests/unit/config/svgTransform.ts'
  },

  // Shell + a few upstream packages ship untranspiled ESM — let Jest transform them.
  transformIgnorePatterns: ['/node_modules/(?!(@vue|@rancher|jsonpath-plus))'],

  modulePathIgnorePatterns: [
    '<rootDir>/scripts/',
    '<rootDir>/assets/',
    '<rootDir>/charts/',
    '<rootDir>/extensions/',
    '<rootDir>/tests/e2e/'    // if you host Playwright specs under tests/
  ],

  coverageDirectory: '<rootDir>/coverage/unit',
  coverageReporters: ['json', 'text-summary'],
  coverageProvider:  'v8'
};

export default config;
```

### 1.3 `moduleNameMapper` — why `@shell/*` is the crucial one

Your extension imports shell code via aliases that Webpack rewrites at build time:

```ts
import LabeledInput from '@shell/components/form/LabeledInput.vue';
import { CATTLE_NAMESPACE } from '@shell/config/labels-annotations';
```

Jest doesn't run Webpack. Without a mapping, every `@shell/...` import throws `Cannot find module '@shell/...'`. The line

```ts
'@shell/(.*)': '<rootDir>/node_modules/@rancher/shell/$1'
```

points Jest at the shell package that `yarn install` already dropped into `node_modules`. Do the same for **any** alias your `vue.config.js` / `tsconfig.paths.json` declares:

| Alias in your code | Maps to |
|---|---|
| `@shell/*` | `node_modules/@rancher/shell/*` |
| `@components/*` | `node_modules/@rancher/components/dist/...common.js` |
| `@<yourpkg>/*` | `pkg/<yourpkg>/*` |
| `@tests/*` | `tests/*` |
| `~/*` / `~~/*` / `@/*` | `<rootDir>/*` (Nuxt-style aliases some samples still use) |

If you add a new alias to `vue.config.js` later, mirror it here or unit tests will start failing with unhelpful `Cannot find module` errors.

### 1.4 `jest.setup.ts` (optional)

Register Vue 3 global stubs, silence noisy console output, or install `flush-promises`:

```ts
import { config } from '@vue/test-utils';

// Stub RouterLink / RouterView so shell components that reference them don't warn.
config.global.stubs = { RouterLink: true, RouterView: true, transition: false };

// Provide a minimal $t so components that call this.t('...') don't blow up.
config.global.mocks = { t: (key: string) => key };
```

### 1.5 Where to put spec files

Two conventions coexist; pick one and be consistent:

| Convention | Where | Pros |
|---|---|---|
| Colocated | `pkg/<yourpkg>/components/Foo.vue` + `Foo.spec.ts` | Easy to find; tests move with the component. |
| Central | `tests/unit/**/*.spec.ts` | Keeps `pkg/` clean; matches Playwright layout under `tests/e2e/`. |

Kubewarden uses colocated for component-level tests and a `tests/unit/mocks/` folder for shared fixtures. Follow suit.

---

## 2. E2E — two routes

### 2.1 Side-by-side comparison

| | **`@rancher/cypress`** (Route A) | **Playwright / `tests/` sub-workspace** (Route B) |
|---|---|---|
| Framework | Cypress `11.1.0` (pinned) | Playwright (any recent version) |
| Install | `yarn add -D @rancher/cypress cypress@11.1.0` at extension root | Separate `tests/package.json` with its own `yarn.lock` |
| Page objects | Bundled — `import { HomePagePo } from '@rancher/cypress/e2e/po/...'` | Roll your own under `tests/e2e/components/` |
| Cluster/user setup | Cypress commands + fixtures in the package | Custom `global-setup.ts` that logs in via `/v3-public/localProviders/local` |
| Version freedom | Locked to `cypress@11.1.0` (upstream peer) | Full |
| Dependency isolation | Shares the extension's `node_modules` | Isolated sub-workspace; no leak into runtime deps |
| Best for | Extensions that want to mimic dashboard's own E2E style and reuse selectors | Extensions with their own test culture, custom auth, or that need parallel Playwright fixtures |

Do **not** mix both in one repo — the peer-dep matrix gets ugly.

### 2.2 Route A — `@rancher/cypress`

```bash
yarn add -D @rancher/cypress cypress@11.1.0
npx rancher-cypress init
```

The CLI drops `cypress.config.ts`, a `support/` folder, and a `cypress/e2e/` template. Then in a spec:

```ts
import HomePagePo from '@rancher/cypress/e2e/po/pages/home.po';

describe('my extension', () => {
  it('lands on the home page', () => {
    const home = new HomePagePo();
    home.goTo();
    home.checkIsCurrentPage();
  });
});
```

The package name is `@rancher/cypress` and lives at [`dashboard/cypress/`](https://github.com/rancher/dashboard/tree/master/cypress). The `bin` entry is `rancher-cypress`.

### 2.3 Route B — Playwright in `tests/`

Kubewarden's layout (verified against the current repo):

```
kubewarden-ui/
├── package.json                 ← Jest lives here (top-level workspace)
├── jest.config.ts
├── pkg/kubewarden/…
└── tests/                       ← isolated E2E workspace
    ├── package.json             ← only @playwright/test + fixtures
    ├── yarn.lock
    ├── tsconfig.json            ← target ESNext, types: [node, @playwright/test]
    ├── playwright.config.ts
    ├── global-setup.ts          ← logs in, resolves clusterId
    ├── e2e/
    │   ├── 00-setup.spec.ts     ← ordered numeric prefixes control execution order
    │   ├── 10-<feature>.spec.ts
    │   ├── 50-<feature>.spec.ts
    │   ├── 90-<feature>.spec.ts
    │   ├── components/          ← page-object equivalents
    │   │   ├── common.ts
    │   │   ├── navigation.ts
    │   │   ├── rancher-ui.ts
    │   │   └── table-row.ts
    │   └── screenshots/
    │       ├── chromium/
    │       └── firefox/
    └── unit/                    ← (kubewarden also puts Jest mocks here)
        ├── mocks/*.ts
        └── config/svgTransform.ts
```

Key file — `tests/package.json`:

```json
{
  "name": "playwright",
  "version": "1.0.0",
  "license": "MIT",
  "devDependencies": {
    "@playwright/test":         "~1.61.1",
    "@types/js-yaml":           "^4.0.9",
    "@types/lodash":            "^4.17.24",
    "js-yaml":                  "^5.2.1",
    "lodash":                   "^4.18.1",
    "playwright-qase-reporter": "^2.5.6",
    "semver":                   "^7.8.5"
  },
  "engines": { "node": ">=24" }
}
```

Key file — `tests/playwright.config.ts` highlights:

```ts
export default defineConfig({
  testDir: './e2e',
  workers: 1,                                     // Rancher UI is stateful — no parallelism
  timeout: 7 * 60_000,                            // Rancher pages can be slow
  expect:  { timeout: 10_000 },
  globalSetup: require.resolve('./global-setup'), // login + clusterId resolution
  use: {
    baseURL:           process.env.RANCHER_URL,
    ignoreHTTPSErrors: true,
    storageState:      'storageState.json',       // reuse cookies across specs
    screenshot:        'only-on-failure',
    trace:             'retain-on-failure'
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'], viewport: { width: 1600, height: 900 } } }],
  webServer: process.env.ORIGIN === 'source'
    ? { command: 'yarn serve-pkgs', url: 'http://127.0.0.1:4500', cwd: '../', reuseExistingServer: !process.env.CI }
    : undefined
});
```

Key file — `tests/global-setup.ts` (skeleton):

```ts
import { request, expect, type FullConfig } from '@playwright/test';

export default async function globalSetup(config: FullConfig) {
  const { baseURL, storageState } = config.projects[0].use;
  const ctx = await request.newContext({ baseURL, ignoreHTTPSErrors: true });

  await ctx.post('/v3-public/localProviders/local?action=login', {
    data: { username: 'admin', password: 'sa', responseType: 'cookie' }
  });
  await ctx.storageState({ path: storageState as string });
}
```

Run from `tests/`:

```bash
cd tests
yarn install
RANCHER_URL=https://<rancher-host> npx playwright test
# or against your local dev server:
ORIGIN=source npx playwright test
```

---

## 3. Dual-mode testing (SSP on/off)

Extensions must run under both `ui-sql-cache` on and off (see [performance.md](performance.md)). Bake it into every layer:

- **Unit**: parameterise Vuex getters `cluster/paginationEnabled` in each spec — one describe block per state.
- **E2E**: run the full suite twice in CI with the feature flag toggled, or gate individual specs with a `test.describe.parallel` per state.

If a component behaves identically under both flag states, one spec is fine — but you must have consciously verified that, not assumed it.

---

## 4. Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot find module '@shell/…'` in Jest | Missing `moduleNameMapper` entry for `@shell/*` | Add `'@shell/(.*)': '<rootDir>/node_modules/@rancher/shell/$1'`. |
| `SyntaxError: Cannot use import statement outside a module` on a shell file | `transformIgnorePatterns` excludes `@rancher/*` from transform | Use `'/node_modules/(?!(@vue|@rancher|jsonpath-plus))'`. |
| `.vue` file "unexpected token" | Missing `@vue/vue3-jest` in `transform` | Add `'.*\\.vue$': '<rootDir>/node_modules/@vue/vue3-jest'`. |
| Cypress install fails with peer conflict | `@rancher/cypress` pins `cypress@11.1.0`; you installed a newer major | Downgrade to `cypress@11.1.0` or switch to Route B. |
| Playwright can't reach `http://127.0.0.1:4500` | `webServer.cwd` doesn't point at the extension root | Set `cwd: '../'` from `tests/`, matching kubewarden. |
| Tests pass locally, fail in CI with `storageState.json not found` | `global-setup.ts` didn't run (missing `globalSetup` in config) | Wire `globalSetup: require.resolve('./global-setup')`. |
| SSP-only regressions slip through | Only tested with the feature flag in one state | Add dual-mode CI job (see §3). |

---

## 5. Reference implementations

- **Jest + mocks**: [`kubewarden-ui/jest.config.ts`](https://github.com/rancher/kubewarden-ui/blob/main/jest.config.ts), [`kubewarden-ui/tests/unit/mocks/`](https://github.com/rancher/kubewarden-ui/tree/main/tests/unit/mocks)
- **Playwright suite**: [`kubewarden-ui/tests/`](https://github.com/rancher/kubewarden-ui/tree/main/tests) — full working setup with `global-setup.ts`, `webServer` + `serve-pkgs`, page-object components, numeric-prefix ordering
- **`@rancher/cypress` package**: [`rancher/dashboard/cypress/`](https://github.com/rancher/dashboard/tree/master/cypress) — source of the CLI, base config, and shared page objects
