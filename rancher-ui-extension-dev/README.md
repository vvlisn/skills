# rancher-ui-extension-dev

AI Skill for developing Rancher Dashboard UI extensions.

## What this skill does

Guides an AI agent through the full lifecycle of Rancher UI extension development:

- **Scaffolding** — initialize a new extension project with `scripts/init-extension.sh`
- **Product registration** — top-level, cluster-level, or parasitic (hook-into-explorer) patterns
- **Routing & navigation** — route definitions, side-menu, custom pages, resource pages
- **UI injection** — tabs, actions, panels, cards, table columns via LocationConfig
- **Edit/Detail pages** — CruResource + CreateEditView patterns, custom components
- **Performance** — Server-Side Pagination (SSP) integration
- **Testing** — Jest unit tests, Playwright/Cypress E2E scaffolding
- **Publishing** — Helm chart packaging, ECI (Extension Catalog Image), GitHub Actions

## File structure

```
rancher-ui-extension-dev/
├── SKILL.md                     # Skill definition (agent reads this)
├── README.md                    # This file (maintainer overview)
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

## Key patterns

| Pattern | `inStore` | Use case |
|---------|-----------|----------|
| Top-level product | `'management'` | Global tools like Fleet |
| Cluster-level product | `'cluster'` | Per-cluster feature with its own nav |
| Hook-into-explorer | N/A (parasitic) | Add 1–3 CRDs to existing Explorer sidebar |
| Kubewarden variant | `'cluster'` + `inExplorer` | Embed inside Explorer with custom pages |

## Compatibility

| Component | Supported versions |
|-----------|-------------------|
| Rancher | 2.11.x – 2.13.x |
| @rancher/shell | 2.0.x – 3.0.x |
| Node.js | ≥ 20 |
| Vue | 3 (Composition API preferred) |

## Contributing

1. Edit files under `rancher-ui-extension-dev/`
2. Run `bash -n scripts/init-extension.sh` to validate shell syntax
3. Sync to `~/.qoder/skills/rancher-ui-extension-dev/` if using user-level install
