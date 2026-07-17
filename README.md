# rancher-ui-extension-dev

AI Skill for developing [Rancher Dashboard](https://github.com/rancher/dashboard) UI extensions — scaffolding, product registration, routing, UI injection, testing, and publishing.

---

## Quick Start

### Install via npx (Recommended)

```bash
# Install to Qoder (project-level)
npx skills add vvlisn/skills --skill rancher-ui-extension-dev -a qoder

# Install to Qoder (user-level, available in all projects)
npx skills add vvlisn/skills --skill rancher-ui-extension-dev -a qoder --global

# Install to multiple agents at once
npx skills add vvlisn/skills --skill rancher-ui-extension-dev -a qoder -a claude-code -a cursor
```

### Install manually

Copy the entire `skills/rancher-ui-extension-dev/` directory to one of these locations:

| Scope | Path | Effect |
|-------|------|--------|
| Project-level | `<project>/.qoder/skills/rancher-ui-extension-dev/` | Current project only |
| User-level | `~/.qoder/skills/rancher-ui-extension-dev/` | All projects |

```bash
# Example: install as user-level skill
cp -r skills/rancher-ui-extension-dev ~/.qoder/skills/
```

Restart Qoder IDE after installation. Type `/` in chat to verify it appears in the skill list.

---

## What this skill does

Once installed, the agent **automatically activates** when it detects Rancher UI extension context — no slash command needed. It covers:

| Capability | Description |
|-----------|-------------|
| **Scaffolding** | Initialize a new extension project via `scripts/init-extension.sh` |
| **Product registration** | Top-level, cluster-level, or parasitic (hook-into-explorer) patterns |
| **Routing & navigation** | Route definitions, side-menu ordering, custom pages, resource pages |
| **UI injection** | Tabs, actions, panels, cards, table columns via `LocationConfig` |
| **Edit/Detail pages** | `CruResource` + `CreateEditView` patterns, custom Vue components |
| **Performance** | Server-Side Pagination (SSP) integration |
| **Testing** | Jest unit tests, Playwright/Cypress E2E scaffolding |
| **Publishing** | Helm chart packaging, ECI (Extension Catalog Image), GitHub Actions |

### Trigger examples

```
"Create a new Rancher extension for managing Widgets"
"Add a tab to the cluster detail page"
"How do I register a cluster-level product?"
"Set up SSP for my CRD list page"
/rancher-ui-extension-dev
```

---

## Compatibility

| Component | Supported versions |
|-----------|-------------------|
| Rancher | 2.11.x – 2.13.x |
| @rancher/shell | 2.0.x – 3.0.x |
| Node.js | ≥ 20 |
| Vue | 3 (Composition API preferred) |

---

## Repository structure

```
skills/rancher-ui-extension-dev/
├── SKILL.md                     # Skill definition (agent reads this)
├── README.md                    # Human-facing docs (this file)
├── scripts/
│   └── init-extension.sh        # Project scaffolding CLI
├── references/                  # Deep-dive documentation
│   ├── concepts.md              # Top-level vs cluster-level products
│   ├── products.md              # Product registration via DSL
│   ├── routing.md               # Route definitions and patterns
│   ├── custom-page.md           # virtualType registration
│   ├── resource-page.md         # configureType registration
│   ├── side-menu.md             # Side menu customization
│   ├── tabs.md                  # Tab injection
│   ├── actions.md               # Action injection
│   ├── panels.md                # Panel injection
│   ├── cards.md                 # Card injection
│   ├── table-columns.md         # Table column injection
│   ├── location-config.md       # LocationConfig reference
│   ├── edit-detail-patterns.md  # Edit/Detail page patterns
│   ├── folder-structure.md      # Magic directories convention
│   ├── getting-started.md       # Quick start guide
│   ├── configuration.md         # rancher.annotations & compatibility
│   ├── performance.md           # SSP & pagination
│   ├── publishing.md            # Build, package, publish
│   └── testing.md               # Test infrastructure
└── evals/
    └── evals.json               # Skill evaluation test cases
```

---

## Key patterns

| Pattern | `inStore` | Use case | Reference |
|---------|-----------|----------|----------|
| Top-level product | `'management'` | Global tools like Fleet | [products.md](references/products.md) |
| Cluster-level product | `'cluster'` | Per-cluster feature with its own nav | [products.md § Cluster-level](references/products.md#cluster-level-product-complete-example) |
| Hook-into-explorer | N/A (parasitic) | Add 1–3 CRDs to existing Explorer sidebar | [products.md § Hook-into-explorer](references/products.md#hook-into-explorer-pattern-parasitic-mode) |
| Kubewarden variant | `'cluster'` + `inExplorer` | Embed inside Explorer with custom pages | [products.md § Kubewarden](references/products.md#kubewarden-variant-production-reference) |

---

## Init script usage

```bash
bash scripts/init-extension.sh \
  --name my-extension \
  --dir ./my-extension \
  --shell-version 3.0.11
```

Run `--help` for all available options including `--no-tests`, `--with-e2e`, and lint configuration.

---

## Contributing

To update this skill:

1. Edit files under `skills/rancher-ui-extension-dev/`
2. Run `bash -n scripts/init-extension.sh` to validate shell syntax
3. Sync to `~/.qoder/skills/rancher-ui-extension-dev/` if using user-level install

---

## License

Apache-2.0
