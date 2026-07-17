#!/usr/bin/env bash
# Rancher UI Extension initializer
# - Runs the official scaffold
# - Pins @rancher/shell to a version matching the target Rancher env
# - Adds community-convention folders (assets/components/composables/store/utils + types.ts + READMEs)
# - Writes rancher.annotations consistently across pkg/<name>/package.json
#
# Usage:
#   init-extension.sh --name <pkg> [--shell-version <x.y.z>] [--rancher-version <range>]
#                     [--display-name <str>] [--dir <path>] [--org <gh-org>]
#                     [--minimal] [--yes]
#                     [--no-tests] [--with-e2e cypress|playwright]
#
# Options:
#   --no-tests           Skip Jest wiring (Jest is installed by default)
#   --with-e2e MODE      Install E2E scaffolding; MODE is 'cypress' or 'playwright'
#
# Defaults:
#   --shell-version   3.0.8   (verified for Rancher 2.13.x, incl. 2.13.3)
set -euo pipefail

# ---------- defaults ----------
NAME=""
SHELL_VERSION="3.0.8"      # aligns with Rancher 2.13.x (verified against 2.13.3)
RANCHER_VERSION=""
DISPLAY_NAME=""
OUT_DIR=""
ORG="<org>"
MINIMAL=0
YES=0
NO_TESTS=0
WITH_E2E=""     # empty | cypress | playwright

# ---------- arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)             NAME="$2"; shift 2 ;;
    --shell-version)    SHELL_VERSION="$2"; shift 2 ;;
    --rancher-version)  RANCHER_VERSION="$2"; shift 2 ;;
    --display-name)     DISPLAY_NAME="$2"; shift 2 ;;
    --dir)              OUT_DIR="$2"; shift 2 ;;
    --org)              ORG="$2"; shift 2 ;;
    --minimal)          MINIMAL=1; shift ;;
    --yes)              YES=1; shift ;;
    --no-tests)         NO_TESTS=1; shift ;;
    --with-e2e)         WITH_E2E="$2"; shift 2 ;;
    -h|--help)          sed -n '1,19p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$NAME" ]] && { echo "ERROR: --name is required" >&2; exit 2; }
[[ -z "$DISPLAY_NAME" ]] && DISPLAY_NAME="$NAME"
[[ -z "$OUT_DIR" ]]      && OUT_DIR="./$NAME"

case "$WITH_E2E" in
  ""|cypress|playwright) ;;
  *) echo "ERROR: --with-e2e must be 'cypress' or 'playwright' (got: $WITH_E2E)" >&2; exit 2 ;;
esac

# ---------- derive rancher-version if omitted ----------
if [[ -z "$RANCHER_VERSION" ]]; then
  case "$SHELL_VERSION" in
    3.0.*)   RANCHER_VERSION=">= 2.13.0" ;;
    3.1.*)   RANCHER_VERSION=">= 2.14.0"
             echo "WARN: shell 3.1.x → Rancher mapping unverified; please double-check" >&2 ;;
    4.*)     RANCHER_VERSION=">= 2.15.0"
             echo "WARN: shell 4.x → Rancher mapping unverified; please double-check" >&2 ;;
    *)       RANCHER_VERSION=">= 2.13.0"
             echo "WARN: unknown shell version, defaulting rancher-version to $RANCHER_VERSION" >&2 ;;
  esac
fi

# ---------- derive ui-extensions-version ----------
case "$SHELL_VERSION" in
  3.*) EXT_API_RANGE=">= 3.0.0 < 4.0.0" ;;
  4.*) EXT_API_RANGE=">= 4.0.0 < 5.0.0" ;;
  *)   EXT_API_RANGE=">= 3.0.0 < 4.0.0" ;;
esac

# ---------- confirmation ----------
if [[ "$SHELL_VERSION" == "3.0.8" ]]; then
  SHELL_HINT=" (default, for Rancher 2.13.x)"
else
  SHELL_HINT=""
fi

cat <<EOF
Will scaffold Rancher UI extension:
  name:                  $NAME
  display-name:          $DISPLAY_NAME
  output dir:            $OUT_DIR
  @rancher/shell:        $SHELL_VERSION$SHELL_HINT
  rancher-version:       $RANCHER_VERSION
  ui-extensions-version: $EXT_API_RANGE
  mode:                  $([[ $MINIMAL -eq 1 ]] && echo minimal || echo full)
  tests (Jest):          $([[ $NO_TESTS -eq 1 ]] && echo skipped || echo installed)
  E2E:                   ${WITH_E2E:-none}
EOF

if [[ $MINIMAL -eq 1 && $NO_TESTS -eq 1 && -z "$WITH_E2E" ]]; then
  echo "  → leanest possible scaffold (no community folders, no test wiring)"
fi

if [[ $YES -ne 1 ]]; then
  read -r -p "Proceed? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

# ---------- 1. scaffold ----------
if [[ -e "$OUT_DIR" ]]; then
  echo "ERROR: $OUT_DIR already exists" >&2; exit 1
fi

parent="$(dirname "$OUT_DIR")"
target="$(basename "$OUT_DIR")"
mkdir -p "$parent"
( cd "$parent" && npm init @rancher/extension@latest "$target" )

cd "$OUT_DIR"

# ---------- 2. pin @rancher/shell version in top-level package.json ----------
node -e "
  const fs=require('fs'), p='./package.json';
  const j=JSON.parse(fs.readFileSync(p,'utf8'));
  ['dependencies','devDependencies'].forEach(k=>{
    if(j[k] && j[k]['@rancher/shell']) j[k]['@rancher/shell']='$SHELL_VERSION';
  });
  fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');
"

# ---------- 3. patch pkg/<name>/package.json ----------
PKG="pkg/$NAME/package.json"
[[ -f "$PKG" ]] || { echo "ERROR: expected $PKG after scaffold" >&2; exit 1; }

node -e "
  const fs=require('fs'), p='$PKG';
  const j=JSON.parse(fs.readFileSync(p,'utf8'));
  j.rancher = j.rancher || {};
  j.rancher.annotations = Object.assign({}, j.rancher.annotations, {
    'catalog.cattle.io/display-name':          '$DISPLAY_NAME',
    'catalog.cattle.io/rancher-version':       '$RANCHER_VERSION',
    'catalog.cattle.io/ui-extensions-version': '$EXT_API_RANGE'
  });
  j.icon = j.icon || 'https://raw.githubusercontent.com/$ORG/$NAME/main/pkg/$NAME/assets/extension-icon.svg';
  fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');
"

# ---------- 4. community-convention scaffolding (skip if --minimal) ----------
if [[ $MINIMAL -eq 0 ]]; then
  cd "pkg/$NAME"

  for d in assets components composables store utils; do
    mkdir -p "$d"
    [[ -e "$d/.gitkeep" ]] || touch "$d/.gitkeep"
  done

  if [[ ! -f types.ts ]]; then
    cat > types.ts <<'TS'
// Module-level TypeScript types for this extension.
// Convention: colocate cross-file interfaces and label constants here.

export interface ExtensionConfig {
  enabled: boolean;
}
TS
  fi

  if [[ ! -f README.md ]]; then
    cat > README.md <<MD
# $DISPLAY_NAME

Rancher UI extension.

## Compatibility
- \`@rancher/shell\`: $SHELL_VERSION
- Rancher: $RANCHER_VERSION
- Extensions API: $EXT_API_RANGE
MD
  fi

  if [[ ! -f assets/extension-icon.svg ]]; then
    cat > assets/extension-icon.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect width="64" height="64" rx="12" fill="#3d98d3"/>
  <text x="50%" y="55%" text-anchor="middle" font-size="28"
        font-family="Helvetica,Arial,sans-serif" fill="#fff">R</text>
</svg>
SVG
  fi

  cd ../..
fi

# ---------- 5. top-level README ----------
if [[ ! -f README.md ]]; then
  cat > README.md <<MD
# $NAME

Development app hosting the \`$NAME\` Rancher UI extension.

## Development
\`\`\`bash
yarn install 
API=https://your-rancher yarn dev  # https://localhost:8005
\`\`\`

## Build
\`\`\`bash
yarn build-pkg $NAME
# output: dist-pkg/$NAME-<version>/
\`\`\`

## Version pinning
- \`@rancher/shell\`: $SHELL_VERSION (must match target Rancher env: $RANCHER_VERSION)
MD
fi

# ---------- 6. patch vue.config.js with TS6059 rootDir workaround ----------
# Works around https://github.com/rancher/dashboard/issues/17118
# Fixed upstream in rancher/dashboard#17119 (milestone v2.15.0) but not yet
# released to @rancher/shell 3.0.x. Safe to keep after the fix ships.
if [[ -f vue.config.js ]] && ! grep -q 'TS6059 rootDir bug' vue.config.js; then
  cat > vue.config.js <<'JS'
const path = require('path');
const config = require('@rancher/shell/vue.config'); // eslint-disable-line @typescript-eslint/no-var-requires

const cfg = config(__dirname, {
  excludes: [],
});

// -----------------------------------------------------------------------------
// Workaround for @rancher/shell 3.0.x TS6059 rootDir bug on `yarn dev`.
// Upstream fix: https://github.com/rancher/dashboard/pull/17119 (milestone v2.15.0)
// Safe to keep once the fix ships; the override is idempotent.
// -----------------------------------------------------------------------------
const originalConfigureWebpack = cfg.configureWebpack;
cfg.configureWebpack = (webpackConfig) => {
  if (typeof originalConfigureWebpack === 'function') {
    originalConfigureWebpack(webpackConfig);
  }
  (webpackConfig.module && webpackConfig.module.rules || []).forEach((rule) => {
    if (rule.test && /tsx\?/.test(rule.test.toString())) {
      (rule.use || []).forEach((u) => {
        if (u && u.loader === 'ts-loader') {
          u.options = {
            ...(u.options || {}),
            compilerOptions: {
              ...((u.options && u.options.compilerOptions) || {}),
              rootDir: __dirname,
            },
          };
        }
      });
    }
  });
};

module.exports = cfg;
JS
fi

# ---------- 7. lint scripts + configs ----------
# The official scaffold ships .eslintrc.js + .eslintignore (244-line Vue3+TS
# ruleset). Two things are missing to make it actually usable:
#   1) `lint` / `lint:fix` scripts in package.json
#   2) The shared configs the .eslintrc.js `extends` — `standard` and
#      `@vue/standard` — are NOT transitively installed by @rancher/shell
#      3.0.11, so `yarn lint` blows up with:
#        "ESLint couldn't find the config \"@vue/standard\" to extend from"
#      We add the missing configs (v6 line, matched to the v3 shell era) plus
#      their peer plugins.
node -e "
  const fs=require('fs'), p='./package.json';
  const j=JSON.parse(fs.readFileSync(p,'utf8'));
  j.scripts = Object.assign({}, j.scripts, {
    'lint':     'eslint --ext .js,.ts,.vue .',
    'lint:fix': 'eslint --ext .js,.ts,.vue . --fix'
  });
  const dd = j.devDependencies = j.devDependencies || {};
  Object.assign(dd, {
    'eslint-config-standard':      '^16.0.3',
    '@vue/eslint-config-standard': '^6.1.0',
    '@vue/eslint-config-typescript': '^7.0.0',
    'eslint-plugin-import':        '^2.25.0',
    'eslint-plugin-node':          '^11.1.0',
    'eslint-plugin-promise':       '^5.1.0',
    'eslint-plugin-standard':      '^5.0.0'
  });
  fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');
"
echo "→ Lint scripts + configs wired (yarn lint / yarn lint:fix)"

# Patch the scaffold's .eslintrc.js: replace the shorthand `@vue/typescript/recommended`
# with the fully-qualified `@vue/eslint-config-typescript/recommended`. ESLint
# 7.32 (the version @rancher/shell 3.0.x pins) has a broken shorthand resolver
# for scoped configs with a subpath, and errors out with:
#   "ESLint couldn't find the config @vue/typescript/recommended to extend from"
# even when the package is installed. The full name resolves cleanly.
if [[ -f .eslintrc.js ]] && grep -q "'@vue/typescript/recommended'" .eslintrc.js; then
  # BSD sed (macOS) requires -i '' ; GNU sed accepts -i alone. Use a portable form:
  perl -i -pe "s|'\\@vue/typescript/recommended'|'\@vue/eslint-config-typescript/recommended'|g" .eslintrc.js
  echo "→ .eslintrc.js patched: '@vue/typescript/recommended' → '@vue/eslint-config-typescript/recommended'"
fi

# ---------- 8. Jest wiring (skip with --no-tests) ----------
if [[ $NO_TESTS -eq 0 ]]; then
  node -e "
    const fs=require('fs'), p='./package.json';
    const j=JSON.parse(fs.readFileSync(p,'utf8'));
    j.scripts = Object.assign({}, j.scripts, {
      'test:unit': 'jest --watch',
      'test:ci':   'jest --collectCoverage'
    });
    const dd = j.devDependencies = j.devDependencies || {};
    Object.assign(dd, {
      'jest':                   '^29.7.0',
      '@types/jest':            '^29.5.14',
      'ts-jest':                '^29.4.6',
      '@vue/vue3-jest':         '^29.2.6',
      'jest-environment-jsdom': '^29.7.0',
      'flush-promises':         '^1.0.2',
      'eslint-plugin-jest':     '^28.11.0'
    });
    fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');
  "

  if [[ ! -f jest.config.ts ]]; then
    cat > jest.config.ts <<TS
import type { Config } from '@jest/types';

const config: Config.InitialOptions = {
  preset:               'ts-jest',
  testEnvironment:      'jest-environment-jsdom',
  setupFilesAfterEach:  ['./jest.setup.ts'],
  moduleFileExtensions: ['js', 'json', 'vue', 'ts', 'tsx'],
  moduleNameMapper: {
    '^~/(.*)\$':         '<rootDir>/\$1',
    '^~~/(.*)\$':        '<rootDir>/\$1',
    '^@/(.*)\$':         '<rootDir>/\$1',
    '@shell/(.*)':      '<rootDir>/node_modules/@rancher/shell/\$1',
    '@components/(.*)': '<rootDir>/node_modules/@rancher/components/dist/@rancher/components.common.js',
    '@${NAME}/(.*)':    '<rootDir>/pkg/${NAME}/\$1',
    '@tests/(.*)':      '<rootDir>/tests/\$1'
  },
  transform: {
    '^.+\\\\.js\$':   '<rootDir>/node_modules/babel-jest',
    '.*\\\\.vue\$':   '<rootDir>/node_modules/@vue/vue3-jest',
    '^.+\\\\.tsx?\$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.json' }],
    '^.+\\\\.svg\$':  '<rootDir>/tests/unit/config/svgTransform.ts'
  },
  transformIgnorePatterns:  ['/node_modules/(?!(@vue|@rancher|jsonpath-plus))'],
  modulePathIgnorePatterns: [
    '<rootDir>/scripts/',
    '<rootDir>/assets/',
    '<rootDir>/charts/',
    '<rootDir>/extensions/',
    '<rootDir>/tests/e2e/'
  ],
  coverageDirectory: '<rootDir>/coverage/unit',
  coverageReporters: ['json', 'text-summary'],
  coverageProvider:  'v8'
};

export default config;
TS
  fi

  if [[ ! -f jest.setup.ts ]]; then
    cat > jest.setup.ts <<'TS'
import { config } from '@vue/test-utils';

// Stub RouterLink / RouterView so shell components don't emit warnings.
config.global.stubs = { RouterLink: true, RouterView: true, transition: false };

// Provide a minimal $t so Options-API components that call this.t('...') don't blow up.
config.global.mocks = { t: (key: string) => key };
TS
  fi

  mkdir -p tests/unit/config
  if [[ ! -f tests/unit/config/svgTransform.ts ]]; then
    cat > tests/unit/config/svgTransform.ts <<'TS'
// Jest transform that turns .svg imports into an empty module.
module.exports = {
  process() {
    return { code: 'module.exports = {};' };
  },
};
TS
  fi

  touch .gitignore
  grep -qxF 'coverage/' .gitignore || echo 'coverage/' >> .gitignore

  echo "→ Jest wired (yarn test:unit / yarn test:ci)"
fi

# ---------- 9. E2E wiring (--with-e2e cypress|playwright) ----------
RUN_CYPRESS_INIT=0
RUN_PLAYWRIGHT_INSTALL=0

case "$WITH_E2E" in
  cypress)
    node -e "
      const fs=require('fs'), p='./package.json';
      const j=JSON.parse(fs.readFileSync(p,'utf8'));
      j.scripts = Object.assign({}, j.scripts, {
        'cy:open': 'cypress open --e2e --browser chrome',
        'cy:run':  'cypress run --browser chrome'
      });
      const dd = j.devDependencies = j.devDependencies || {};
      Object.assign(dd, {
        '@rancher/cypress': '^1.0.6',
        'cypress':          '11.1.0'
      });
      fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');
    "
    touch .gitignore
    for entry in cypress/screenshots/ cypress/videos/ cypress/downloads/; do
      grep -qxF "$entry" .gitignore || echo "$entry" >> .gitignore
    done
    RUN_CYPRESS_INIT=1
    echo "→ Cypress wired (yarn cy:open / yarn cy:run); 'rancher-cypress init' will run post-install"
    ;;

  playwright)
    node -e "
      const fs=require('fs'), p='./package.json';
      const j=JSON.parse(fs.readFileSync(p,'utf8'));
      j.scripts = Object.assign({}, j.scripts, {
        'test:e2e': 'cd tests && yarn playwright test'
      });
      fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');
    "

    mkdir -p tests/e2e

    if [[ ! -f tests/package.json ]]; then
      cat > tests/package.json <<'JSON'
{
  "name": "playwright",
  "version": "1.0.0",
  "license": "MIT",
  "devDependencies": {
    "@playwright/test": "~1.61.1",
    "@types/node":      "^24.0.0"
  },
  "engines": { "node": ">=24" }
}
JSON
    fi

    if [[ ! -f tests/tsconfig.json ]]; then
      cat > tests/tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "target":           "ESNext",
    "module":           "ESNext",
    "moduleResolution": "Bundler",
    "strict":           true,
    "esModuleInterop":  true,
    "skipLibCheck":     true,
    "noEmit":           true,
    "types":            ["node", "@playwright/test"]
  },
  "include": ["./**/*.ts"],
  "exclude": ["node_modules", "./unit"]
}
JSON
    fi

    if [[ ! -f tests/playwright.config.ts ]]; then
      cat > tests/playwright.config.ts <<'TS'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir:              './e2e',
  forbidOnly:           !!process.env.CI,
  workers:              1,
  timeout:              7 * 60_000,
  expect:               { timeout: 10_000 },
  globalSetup:          require.resolve('./global-setup'),
  snapshotPathTemplate: '{testDir}/screenshots/{projectName}/{arg}{ext}',
  reporter:             [[process.env.CI ? 'html' : 'list']],
  use: {
    baseURL:           process.env.RANCHER_URL,
    ignoreHTTPSErrors: true,
    storageState:      'storageState.json',
    screenshot:        'only-on-failure',
    trace:             'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use:  { ...devices['Desktop Chrome'], viewport: { width: 1600, height: 900 } },
    },
  ],
  webServer: process.env.ORIGIN === 'source'
    ? {
        command:             'yarn serve-pkgs',
        url:                 'http://127.0.0.1:4500',
        cwd:                 '../',
        reuseExistingServer: !process.env.CI,
      }
    : undefined,
});
TS
    fi

    if [[ ! -f tests/global-setup.ts ]]; then
      cat > tests/global-setup.ts <<'TS'
import { request, type FullConfig } from '@playwright/test';

// Logs in as admin and persists the session to storageState.json so specs skip auth.
// Override credentials via RANCHER_USER / RANCHER_PASS.
export default async function globalSetup(config: FullConfig) {
  const { baseURL, storageState } = config.projects[0].use;
  const ctx = await request.newContext({ baseURL, ignoreHTTPSErrors: true });
  await ctx.post('/v3-public/localProviders/local?action=login', {
    data: {
      username:     process.env.RANCHER_USER || 'admin',
      password:     process.env.RANCHER_PASS || 'admin',
      responseType: 'cookie',
    },
  });
  await ctx.storageState({ path: storageState as string });
  await ctx.dispose();
}
TS
    fi

    if [[ ! -f tests/e2e/00-smoke.spec.ts ]]; then
      cat > tests/e2e/00-smoke.spec.ts <<'TS'
import { test, expect } from '@playwright/test';

test('rancher dashboard loads', async ({ page }) => {
  await page.goto('/dashboard/home');
  await expect(page).toHaveTitle(/Rancher/);
});
TS
    fi

    if [[ ! -f tests/.gitignore ]]; then
      cat > tests/.gitignore <<'GI'
node_modules/
storageState.json
test-results/
playwright-report/
e2e/screenshots/**/actual/
GI
    fi

    RUN_PLAYWRIGHT_INSTALL=1
    echo "→ Playwright wired (yarn test:e2e); tests/ workspace deps will install post-install"
    ;;
esac

# ---------- 10. yarn install ----------
if command -v yarn >/dev/null 2>&1; then
  yarn install

  if [[ $RUN_CYPRESS_INIT -eq 1 ]]; then
    if command -v npx >/dev/null 2>&1; then
      npx --yes rancher-cypress init || echo "WARN: 'rancher-cypress init' failed; run it manually inside $OUT_DIR" >&2
    else
      echo "WARN: npx not found; run 'npx rancher-cypress init' manually" >&2
    fi
  fi

  if [[ $RUN_PLAYWRIGHT_INSTALL -eq 1 ]]; then
    ( cd tests && yarn install ) || echo "WARN: playwright deps install failed; run 'yarn install' inside tests/" >&2
  fi
else
  echo "WARN: yarn not found; run 'yarn install' manually" >&2
  [[ $RUN_CYPRESS_INIT -eq 1 ]]      && echo "       then run 'npx rancher-cypress init'" >&2
  [[ $RUN_PLAYWRIGHT_INSTALL -eq 1 ]] && echo "       then run 'yarn install' inside tests/" >&2
fi

echo ""
echo "✅ Done. Next steps:"
echo "   cd $OUT_DIR"
echo "   API=https://your-rancher yarn dev"
