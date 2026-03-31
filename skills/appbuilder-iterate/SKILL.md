---
name: appbuilder-iterate
description: "Modify an existing AppBuilder project. Classifies change type, loads cached artifacts, runs the appropriate shortened pipeline with subagent-driven builder and parallel hardener."
---

# /appbuilder-iterate — Modify an Existing AppBuilder Project

You are the orchestrator for AppBuilder's iteration pipeline. The pipeline is shorter than `/appbuilder-build` — only the agents relevant to the change type are run. Cached artifacts from previous builds are reused where valid.

---

## Arguments

The user invokes `/appbuilder-iterate <change description>`.

The change description is available as `$ARGUMENTS`. Use it directly — do not re-ask.

- If `$ARGUMENTS` is empty or blank, ask: "What would you like to change?"
- Wait for their response before proceeding.

---

## Step 1 — Detect Current Project

1. Check the current working directory for a recognized project structure (`app.json`, `next.config.*`, `manifest.json`, or `.appbuilder/cache/` directory).
2. If detected: "I'll apply this change to **<App Name>** at `<path>`. Is that correct?"
3. If not detected: read `~/.appbuilder/registry.json` and list projects. Ask user to select.
4. If registry empty: "No AppBuilder projects found. Run `/appbuilder-build` to create one first."

---

## Step 2 — Load Cached Artifacts

Load from `.appbuilder/cache/`:
- `01-plan.json` — product plan
- `02-design-system.json` — design tokens
- `02-coder-rulebook.json` — builder rules
- `03-architecture.json` — file structure, deps, data model

Also read `docs/*.md` for human-readable context.

If any cache file is missing, note it — the corresponding agent will need to re-run.

---

## Step 3 — Classify the Change

| Keywords / Signals | Classification | Pipeline | Cache Invalidation |
|---|---|---|---|
| redesign, rethink, premium, rebrand, overhaul | `design-overhaul` | Design Studio → GATE → Builder → Hardener → Reviewer | Invalidate: design, rulebook |
| color, font, theme, dark mode, typography | `visual-change` | Design Studio (phases 2–4) → GATE → Builder → Reviewer | Invalidate: design |
| fix, bug, broken, crash, error, not working | `bug-fix` | Builder → Reviewer | Invalidate: nothing |
| deploy, eas, vercel, app store, publish | `deploy-config` | Deployer only | Invalidate: nothing |
| add, new feature, implement, integrate | `new-feature` | Architect → Builder → Hardener → Reviewer | Invalidate: architecture |
| refactor, split, extract, rename, reorganize, clean up | `refactor` | Architect → Builder → Reviewer | Invalidate: architecture |

**Mixed intents:** If the change description matches multiple classifications (e.g., "fix login bug and add forgot password"), split into separate iterations. State: "This involves both a **bug-fix** and a **new-feature**. I'll handle the bug-fix first, then the new feature as a second iteration." Run each pipeline sequentially.

State your classification: "This looks like a **visual-change**. I'll re-run the Design Studio for color/font/theme, get your approval, then update the code. Cached plan and architecture will be reused."

---

## Step 4 — Run the Classified Pipeline

### Pipeline: design-overhaul

1. **Design Studio** (all 8 phases) — dispatch via Agent tool with existing plan as context
2. **Design Review Gate** — present design, loop until approved (max 5 revisions)
3. **Builder** (subagent-driven, per-screen) — only screens affected by the redesign
4. **Hardener** (parallel: slop detection + platform compliance)
5. **Reviewer**

### Pipeline: visual-change

1. **Design Studio** (phases 2–4 only) — show before→after for every modified token
2. **Design Review Gate** — loop until approved
3. **Builder** — update affected screens with new tokens
4. **Reviewer**

### Pipeline: bug-fix

No design review gate. Use systematic debugging:

1. Confirm reproduction steps with user
2. **Phase 1 — Root Cause**: Read error, reproduce, trace data flow backward
3. **Phase 2 — Pattern Analysis**: Find working examples, compare
4. **Phase 3 — Failing Test**: Write a test that captures the bug (must fail before fix)
5. **Phase 4 — Fix**: Minimum change to pass the test
6. **Reviewer** — verify fix doesn't break anything

### Pipeline: deploy-config

Invoke the `/appbuilder-deploy-config` skill — this is a separate skill, not an agent dispatch.

### Pipeline: new-feature

1. **Architect** — extend existing architecture (new files, deps, routes, data model)
2. **Builder** (subagent-driven) — build new screens/components with TDD
3. **Hardener** (parallel: security + edge cases for new code)
4. **Reviewer**

### Pipeline: refactor

1. **Architect** — update file structure, move/rename/split files in architecture
2. **Builder** — apply refactor: move code, update imports, ensure existing tests still pass
3. **Reviewer** — verify no regressions (all existing tests must pass, no new lint errors)

---

## Step 5 — Design Review Gate (design-overhaul and visual-change only)

Same protocol as `/appbuilder-build`:
- Present revised design with before→after diffs
- A) Approve, R) Revise, C) Cancel
- Max 5 revision rounds
- Loop until approved

---

## Step 6 — Builder (Subagent-Driven)

For iterations that require code changes:

**Per-screen subagent dispatch** (sequential):
- Dispatch builder subagent for each affected screen via Agent tool
- After each screen: dispatch spec reviewer subagent (model: haiku)
- If issues found: re-dispatch builder with feedback (max 2 retries)
- Report per-screen progress

**For bug-fix:** Single builder subagent focused on the buggy file(s).

---

## Step 7 — Hardener (Parallel, when applicable)

For `new-feature` and `design-overhaul`:

Dispatch parallel subagents (model: haiku) via Agent tool:
1. Security audit (scoped to changed/new files)
2. Platform compliance (scoped to changed screens)
3. AI slop detection (visual + copy on changed components)

For `bug-fix` and `visual-change`: skip hardener (scope is too small to warrant).

---

## Step 8 — Reviewer

Dispatch reviewer agent. Must follow verification-before-completion:
- Run build, tsc, eslint, tests fresh
- Read FULL output
- Verify changed screens match design spec
- Report verdict: PASS / PASS-WITH-WARNINGS / FAIL

---

## Step 9 — Save Artifacts and Report

**Update artifact cache** (`.appbuilder/cache/`):
- Only overwrite invalidated artifacts (based on change-type classification)
- Keep valid cached artifacts untouched

**Update docs/**:
- Regenerate affected doc files (e.g., `02-design-spec.md` for visual changes)
- Append to `04-build-log.md` (don't overwrite — add iteration entry)

**Update registry** (`~/.appbuilder/registry.json`):
- Increment `iterations` counter
- Update `updatedAt` timestamp
- Set `lastChange` description

**Report:**
```
## Iteration Complete

**App:** <App Name>
**Change type:** <classification>
**Iteration:** #<count>
**Cache reused:** plan, architecture (not invalidated)

### What changed
<bullet list of files modified/added/deleted>

### What's next?
- Preview: /appbuilder-preview
- Iterate: /appbuilder-iterate "another change"
- Docs: <path>/docs/
```

---

## Key Rules

- ALWAYS detect and confirm the target project before changes.
- ALWAYS load cached artifacts — don't re-run agents that aren't invalidated.
- Design review gate is MANDATORY for design-overhaul and visual-change.
- Bug fixes ALWAYS use systematic debugging (root cause → failing test → fix).
- Builder uses subagent-driven development (per-screen Agent dispatches).
- Never modify the Coder Rulebook during iteration unless it's a design-overhaul.
- Write/update `docs/*.md` after each agent completes.
- Increment the iteration counter in the registry on every successful iteration.
