# AppBuilder — Claude Code Plugin

AI-powered app builder that generates production-quality apps from natural language descriptions. Open source, runs locally, only needs Claude Code.

## Commands

- **`/appbuilder-build`** — Create a new app from a description (full 6-agent pipeline)
- **`/appbuilder-iterate`** — Modify an existing app (cached artifacts, shortened pipeline)
- **`/appbuilder-preview`** — Start dev server with QR code
- **`/appbuilder-assets`** — Generate app icon (SVG), splash screen, adaptive icon, favicon, App Store screenshots
- **`/appbuilder-deploy-config`** — Generate deployment configs (EAS, Vercel, Railway)

## Install

**Per-session** (for testing):

```bash
claude --plugin-dir /path/to/appbuilder-free/plugin
```

**Validate first** (optional — checks plugin structure):

```bash
claude plugin validate /path/to/appbuilder-free/plugin
```

Once loaded, you'll see:

```
AppBuilder: Ready. Use /appbuilder-build "your app idea" to create your first app.
```

**Note:** Local plugins use `--plugin-dir`, not `claude plugin install` (which is for marketplace plugins only). Pass `--plugin-dir` each time you start Claude Code, or add it to a shell alias:

```bash
alias claude-ab='claude --plugin-dir /path/to/appbuilder-free/plugin'
```

## Requirements

- **Claude Code** (latest version)
- **Node.js 22+**
- **Docker** (optional, for containerized builds via packnplay)

## How It Works

The plugin uses a 6-agent pipeline with subagent-driven development:

1. **Planner** — Product strategy, architecture, monetization, features
2. **Design Studio** — Complete design system, screens, UX flows, coder rulebook
3. **Architect** — File structure, dependencies, data model, navigation
4. **Builder** — Per-screen TDD subagents with spec review after each screen
5. **Hardener** — 4 parallel audit subagents (security, compliance, edge-cases, slop detection)
6. **Reviewer** — Verification-before-completion protocol with evidence

## Key Features

- **Interactive design review** — loops until user approves (max 5 revisions)
- **Subagent-driven builder** — one Agent dispatch per screen, sequential with spec review
- **Parallel hardener** — 4 concurrent audit subagents (haiku for cost efficiency)
- **Artifact caching** — `.appbuilder/cache/` enables token-efficient iterations
- **Doc generation** — `docs/01` through `docs/06` written after each agent
- **Figma mockups** — generates wireframes if Figma MCP is available
- **Anti-slop** — Impeccable visual tells, Stop-Slop copy rules, 15+ anti-patterns
- **Performance budgets** — Core Web Vitals (web), FlatList/Reanimated/Hermes (mobile)
- **Supply chain security** — Trail of Bits lockfile/typosquatting/dependency checks

## Quality Rules (baked into agent prompts)

Inspired by and credited to:
- [superpowers](https://github.com/obra/superpowers) — TDD Iron Law, systematic debugging, verification-before-completion
- [impeccable](https://github.com/pbakaus/impeccable) — AI slop detection, visual anti-patterns
- [stop-slop](https://github.com/hardikpandya/stop-slop) — Copy quality, banned phrases
- [web-quality-skills](https://github.com/addyosmani/web-quality-skills) — Core Web Vitals budgets
- [agent-skills](https://github.com/callstackincubator/agent-skills) — React Native performance
- [trailofbits/skills](https://github.com/trailofbits/skills) — Supply chain security
