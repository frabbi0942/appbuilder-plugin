# AppBuilder — Ship Apps, Not Invoices

**Stop paying dev shops for apps you could build yourself.**

AppBuilder is a free, open-source Claude Code plugin that turns a plain English description into a production-quality app — complete with design system, TDD tests, security hardening, and deployment configs. No middlemen. No retainers. No "discovery phase" billing.

You describe the app. Six AI agents build it. You own 100% of the code.

## Install

### From the marketplace (recommended)

Inside Claude Code, run:

```
/plugin marketplace add frabbi0942/appbuilder-plugin
/plugin install appbuilder@appbuilder-marketplace
```

Auto-updates included. When the plugin updates on GitHub, you get the latest version automatically.

### From GitHub directly

```bash
git clone https://github.com/frabbi0942/appbuilder-plugin.git
claude --plugin-dir /path/to/appbuilder-plugin
```

**Tip:** Add a shell alias:
```bash
alias claude-ab='claude --plugin-dir /path/to/appbuilder-plugin'
```

### For teams

Add to your repo's `.claude/settings.json` so every team member gets AppBuilder automatically:

```json
{
  "extraKnownMarketplaces": {
    "appbuilder-marketplace": {
      "source": {
        "source": "github",
        "repo": "frabbi0942/appbuilder-plugin"
      }
    }
  },
  "enabledPlugins": {
    "appbuilder@appbuilder-marketplace": true
  }
}
```

### Verify

You'll see:
```
AppBuilder: Ready. Use /appbuilder-build "your app idea" to create your first app.
```

**Validate** (optional):
```bash
claude plugin validate /path/to/appbuilder-plugin
```

## Commands

| Command | What It Does |
|---------|-------------|
| `/appbuilder-build` | Create a new app from a description — runs the full 6-agent pipeline |
| `/appbuilder-list` | List all registered projects with status, platform, and location |
| `/appbuilder-iterate` | Modify an existing app — cached artifacts, only re-runs what changed |
| `/appbuilder-preview` | Start dev server with QR code for mobile testing |
| `/appbuilder-assets` | Generate app icon, splash screen, adaptive icon, favicon, screenshots |
| `/appbuilder-deploy-config` | Generate deployment configs (EAS, Vercel, Railway) |

## How It Works

You describe your app. AppBuilder runs a 6-agent pipeline that does everything a dev shop would, but better.

```
You: "Build a habit tracker with streaks and social accountability"
                    │
                    ▼
    ┌──────────────────────────────┐
    │  1. PLANNER                  │  Product strategy, competitor research,
    │     (interactive Q&A)        │  monetization, feature prioritization
    └──────────────┬───────────────┘
                   ▼
    ┌──────────────────────────────┐
    │  2. DESIGN STUDIO            │  Color palette, typography, components,
    │     (8 design phases)        │  screen specs, Coder Rulebook
    └──────────────┬───────────────┘
                   ▼
    ┌──────────────────────────────┐
    │  3. YOU REVIEW THE DESIGN    │  Approve, revise (up to 5 rounds),
    │     (blocking gate)          │  or cancel — you're in control
    └──────────────┬───────────────┘
                   ▼
    ┌──────────────────────────────┐
    │  4. ARCHITECT                │  File structure, dependencies,
    │                              │  data model, navigation graph
    └──────────────┬───────────────┘
                   ▼
    ┌──────────────────────────────┐
    │  5. BUILDER                  │  One subagent per screen, TDD:
    │     (test-driven)            │  failing test first, then code
    └──────────────┬───────────────┘
                   ▼
    ┌──────────────────────────────┐
    │  6. HARDENER                 │  4 parallel audits: security,
    │     (4 concurrent agents)    │  compliance, edge cases, AI slop
    └──────────────┬───────────────┘
                   ▼
    ┌──────────────────────────────┐
    │  7. REVIEWER                 │  Build, test, lint, design fidelity
    │     (final verdict)          │  PASS / FAIL / PASS-WITH-WARNINGS
    └──────────────────────────────┘
                   ▼
              Your app is ready.
```

### The Pipeline Is Interactive

Unlike black-box code generators, AppBuilder keeps you in the loop:

- **Planning** asks you 6 questions, one at a time — core product, architecture, monetization, growth, features, platform
- **Design Review** is a blocking gate — nothing gets built until you approve
- **Build Approval** shows you exactly what will be built before coding starts
- After coding starts, each screen reports progress and spec compliance

You make the decisions. The agents do the work.

## Supported Platforms

- **Expo** (React Native) — iOS + Android mobile apps *(default)*
- **Next.js** — Full-stack web apps
- **Chrome Extension** — Manifest V3 browser extensions
- **Safari Extension** — Safari Web Extensions with App Store distribution

## What's Built Into Every App

**Quality rules are baked directly into the agent prompts — no config needed.**

- **TDD Iron Law** — Every screen starts with a failing test before any implementation code
- **Design tokens** — No hardcoded colors, no inline styles, no magic numbers
- **Security scanning** — Secrets detection, OWASP Mobile Top 10, dependency vulnerabilities, supply chain checks
- **Platform compliance** — iOS HIG, Material Design, cross-platform leak detection
- **Performance budgets** — Core Web Vitals for web; JS bundle size, FlatList optimization, Hermes for mobile
- **AI slop detection** — Catches generic AI copy ("streamline", "leverage"), visual anti-patterns, placeholder content
- **Accessibility** — WCAG AA baseline, screen reader labels, touch targets
- **Auto-fixes** — Hardener fixes safe issues automatically (contrast, easing curves, banned phrases)

## Iteration Without Starting Over

Already built an app? `/appbuilder-iterate` classifies your change and only re-runs the necessary stages:

| Change Type | What Re-Runs | Cache Invalidated |
|------------|-------------|-------------------|
| `design-overhaul` | Design Studio → Reviewer | Design + Rulebook |
| `visual-change` | Design phases 2-4 → Reviewer | Partial design |
| `bug-fix` | Builder → Reviewer | None |
| `new-feature` | Architect → Reviewer | None |

Cached artifacts in `.appbuilder/cache/` mean iterations use fewer tokens and cost less.

## Generated Artifacts

Every build produces documentation for reference:

```
your-app/
├── 01-plan.json              # Product strategy + competitor research
├── 02-design.json            # Complete design system + screen specs
├── 03-architecture.json      # File tree, deps, data model, nav graph
├── 04-builder-log.json       # Per-screen build results
├── 05-hardener-report.json   # Security + compliance audit findings
├── 06-reviewer-report.json   # Final verdict with evidence
├── docs/
│   ├── 01-product-plan.md    # Human-readable product plan
│   ├── 02-design-spec.md     # Design system documentation
│   ├── 03-architecture.md    # Technical architecture spec
│   ├── 04-build-log.md       # Build progress and test results
│   ├── 05-security-report.md # Security audit report
│   └── 06-review-verdict.md  # Final review with PASS/FAIL
└── .appbuilder/cache/        # Cached artifacts for iterations
```

## Optional Integrations

- **Figma MCP** — If detected, Design Studio generates wireframe mockups in Figma
- **Expo MCP** — React Native guidance via Expo's MCP server
- **Context7 MCP** — Verifies latest SDK versions and API signatures (no stale docs)

## Requirements

- **Claude Code** (latest version)
- That's it. Zero runtime dependencies. The plugin is purely agent prompts (~3,400 lines of markdown).

## Credits

Quality rules baked into the agents are inspired by:

- [superpowers](https://github.com/obra/superpowers) — TDD, systematic debugging, verification-before-completion
- [impeccable](https://github.com/pbakaus/impeccable) — AI slop detection, visual anti-patterns
- [stop-slop](https://github.com/hardikpandya/stop-slop) — Copy quality, banned phrases
- [web-quality-skills](https://github.com/addyosmani/web-quality-skills) — Core Web Vitals budgets
- [agent-skills](https://github.com/callstackincubator/agent-skills) — React Native performance
- [trailofbits/skills](https://github.com/trailofbits/skills) — Supply chain security

## License

MIT

---

## Support

If this plugin saves you time and money, please consider supporting development:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=flat&logo=buy-me-a-coffee)](https://buymeacoffee.com/fazlayrabbi)
