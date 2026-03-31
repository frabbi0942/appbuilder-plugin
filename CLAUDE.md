# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

AppBuilder is a **Claude Code plugin** (not a traditional app). It consists of markdown-based agent definitions, skill definitions, and hooks that orchestrate a 6-agent pipeline to generate production-quality apps from natural language. Zero runtime dependencies — the plugin is purely agent prompts (~3,400 lines across 17 files).

## Validation

There is no build step, test suite, or linter. The only validation command is:

```bash
claude plugin validate /path/to/appbuilder-plugin
```

To test the plugin locally:

```bash
claude --plugin-dir /path/to/appbuilder-plugin
```

## Architecture

### Pipeline Flow

The core product is a sequential 6-agent pipeline orchestrated by the `/appbuilder-build` skill:

```
Planner (sonnet) → Design Studio (sonnet) → [User Review Gate] → Architect (sonnet) → Builder (sonnet, per-screen subagents) → Hardener (haiku, 4 parallel) → Reviewer (sonnet)
```

- **Planner** — Orchestrator asks 6 questions interactively (one at a time), then planner agent synthesizes answers + competitor research into `01-plan.json`
- **Design Studio** — 8-phase design system, produces `02-design.json` + Coder Rulebook
- **User Review Gate** — Blocking approval loop (max 5 revisions)
- **Architect** — File structure, deps, nav graph, data model → `03-architecture.json`
- **Builder** — Dispatches one subagent per screen (TDD: failing test first). After each screen, dispatches Spec Reviewer (haiku) for compliance check. Max 2 retries per screen.
- **Hardener** — 4 concurrent audit subagents: security, platform compliance, edge cases, AI slop detection. Auto-fixes safe issues. Produces `05-hardener-report.json`
- **Reviewer** — Runs build/test/lint, cross-validates hardener findings, never auto-fixes. Produces `06-reviewer-report.json`

### File Layout

- `agents/` — 7 agent markdown files with frontmatter (name, description, model). Dispatched via Claude's Agent tool.
- `skills/` — 5 user-facing commands, each in its own directory with a `SKILL.md`.
- `hooks/hooks.json` + `hooks/session-start.sh` — SessionStart hook that reads `~/.appbuilder/registry.json` and injects project count.
- `.mcp.json` — Declares Expo MCP server (`https://mcp.expo.dev`).

### Artifact System

Generated apps produce artifacts at three levels:
1. **JSON artifacts** in project root: `01-plan.json` through `06-reviewer-report.json`
2. **Cache** in `.appbuilder/cache/`: enables token-efficient iterations via `/appbuilder-iterate`
3. **Human-readable docs** in `docs/`: `01-product-plan.md` through `06-review-verdict.md`

### Iteration Pipeline (`/appbuilder-iterate`)

Classifies changes by type and runs only the necessary pipeline stages:
- `design-overhaul` → Design Studio through Reviewer (invalidates design + rulebook cache)
- `visual-change` → Design Studio phases 2-4 through Reviewer
- `bug-fix` → Builder through Reviewer (no cache invalidation)
- `new-feature` → Architect through Reviewer

### Model Selection Convention

- **sonnet**: Complex reasoning (planner, architect, builder, reviewer, design-studio)
- **haiku**: Audit/verification tasks (hardener, spec-reviewer) — cost efficiency on parallel dispatches

## Key Conventions

- Agent prompts embed all quality rules directly — no external config files. Edit the agent `.md` to change behavior.
- Builder enforces TDD Iron Law: write failing test first, then implementation (Red-Green-Refactor).
- Builder has 15 absolute rules baked into its prompt (no ScrollView with map, no inline styles, use design tokens, no `any` types, etc.).
- Hardener dispatches 4 parallel subagents and auto-fixes only safe issues (move secrets to env, fix dependency vulns, adjust contrast).
- Reviewer never auto-fixes — it only reports PASS/FAIL/PASS-WITH-WARNINGS.
- Supported target platforms: Expo (React Native, default), Next.js, Chrome Extension (Manifest V3), Safari Web Extension.

## External Integrations

- **Expo MCP** — declared in `.mcp.json`, used by builder for React Native guidance
- **Figma MCP** — optional, auto-detected by Design Studio for wireframe generation
- **Web Search** — used by Planner for competitor analysis before finalizing monetization
- **Project Registry** — `~/.appbuilder/registry.json` tracks generated projects globally
