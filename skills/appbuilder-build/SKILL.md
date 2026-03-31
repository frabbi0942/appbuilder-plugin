---
name: appbuilder-build
description: "Create a new app from a natural language description. Runs the full agent pipeline: Planner → Design Studio → User Review → Architect → Builder (subagent per screen) → Hardener (parallel audits) → Reviewer. Generates docs/, caches artifacts, tracks costs."
---

# /appbuilder-build — Full App Build Pipeline

You are the orchestrator for AppBuilder's full build pipeline. When the user invokes `/appbuilder-build`, follow every step below in strict order. Do not skip or reorder steps.

---

## Arguments

The user invokes `/appbuilder-build <app description>`.

The app description is available as `$ARGUMENTS`. Use it directly — do not re-ask.

- If `$ARGUMENTS` is empty or blank, ask: "What would you like to build? Please describe your app idea."
- Wait for their response before proceeding.

---

## Step 1 — Output Directory

Ask the user where to create the project:

> "Where should I create this project?"
> Default: `~/projects/<slugified-app-name>`
> (Press Enter for default, or provide a path)

If they provide a path, use it. If they press Enter or say "default", use the default.
If the directory already exists, ask if they want to use a different name.

Create the directory and a `docs/` subdirectory inside it.

---

## Step 2 — Determine Platform

Before running any agent, determine the target platform. Default to **Expo (React Native)** unless the user specifies otherwise.

Supported platforms:
- **expo** — React Native mobile app via Expo (default)
- **nextjs** — Next.js web app
- **chrome-ext** — Chrome browser extension (Manifest V3)
- **safari-ext** — Safari Web Extension

Ask the user if the platform is ambiguous. Otherwise, infer and state: "I'll build this as an **Expo** app. Let me know if you'd like a different platform."

---

## Step 3 — Run Planner Agent

**Goal:** Establish product strategy before any design or code.

Dispatch the **planner** agent using the Agent tool. Pass:
- The app description
- The confirmed platform
- Instructions to ask the 6 structured questions (Core Product, Architecture, Monetization, Growth, Features, Platform)

After the planner completes:
- Save `01-plan.json` to the project root
- Save `.appbuilder/cache/01-plan.json` (artifact cache)
- Write `docs/01-product-plan.md` — human-readable markdown summary of the plan
- Report to user: "Planner complete. Product plan saved."

---

## Step 4 — Run Design Studio Agent

**Goal:** Produce a complete design system, screen specs, and coder rulebook.

### Figma Mockups (optional)

Check if the Figma MCP is available (look for `mcp__*Figma*` tools). If available, ask:

> "Figma MCP detected. Would you like me to generate visual mockups in Figma? (Y/n)"

If yes, include Figma mockup instructions in the Design Studio dispatch.

### Dispatch

Dispatch the **design-studio** agent using the Agent tool. Pass:
- The plan from `01-plan.json`
- Platform context
- User's design preferences (if they mentioned any)
- Figma mockup flag if enabled

After the Design Studio completes:
- Save `02-design.json` to project root
- Save `.appbuilder/cache/02-design-system.json` and `.appbuilder/cache/02-coder-rulebook.json`
- Write `docs/02-design-spec.md` — human-readable design summary

---

## Step 5 — DESIGN REVIEW GATE (BLOCKING — loops until approved)

**This step is mandatory. Do not proceed until the user approves. Maximum 5 revision rounds.**

Present a summary:
- Brand identity and color palette (show hex values)
- Typography choices
- List of screens with their states
- Navigation structure
- Key anti-patterns that will be enforced
- Figma file URL (if mockups were generated)

Then ask:

> **Design Review — approval required**
>
> A) **Approve** — proceed to architecture and build
> R) **Revise** — describe what to change (I'll re-run Design Studio with your feedback)
> C) **Cancel** — stop the pipeline
>
> Revision round: 1/5

**If the user requests revisions:**
1. Increment the revision counter
2. Re-dispatch the design-studio agent with: the original context + "REVISION REQUEST: <user's feedback>. Keep everything not mentioned — only change what was requested."
3. Re-save artifacts with the updated design
4. Re-present for review
5. Repeat until approved or 5 rounds reached

**If cancelled:** Stop the pipeline. Print: "Pipeline cancelled at design review. Resume with `/appbuilder-build` in this project directory."

---

## Step 6 — Run Architect Agent

Dispatch the **architect** agent using the Agent tool. Pass:
- `01-plan.json` content
- `02-design.json` content

After completion:
- Save `03-architecture.json`
- Save `.appbuilder/cache/03-architecture.json`
- Write `docs/03-architecture.md` — file structure, dependencies, data model, navigation
- Tell downstream agents: "Reference docs/01-product-plan.md, docs/02-design-spec.md, docs/03-architecture.md"

---

## Step 7 — Scaffold Project and Install Dependencies

Before building, scaffold the project structure from the architecture:

1. **Initialize the project** — run the appropriate init command based on platform:
   - **Expo:** `npx create-expo-app@latest <app-name> --template blank-typescript` in the output directory
   - **Next.js:** `npx create-next-app@latest <app-name> --typescript --tailwind --app --src-dir` in the output directory
   - **Chrome Extension:** create `manifest.json` (Manifest V3), `src/`, `public/` directories
   - **Safari Extension:** create Xcode project structure with web extension target

2. **Create the directory structure** from `03-architecture.json` — create all directories and empty files listed in the file tree.

3. **Install dependencies** listed in `03-architecture.json`:
   ```bash
   cd <project-path>
   npm install <production-deps>
   npm install -D <dev-deps>
   ```

4. **Verify setup** — run `npx tsc --noEmit` (should pass with no source files yet) and confirm `node_modules/` exists.

If any step fails, stop and report the error to the user before proceeding.

---

## Step 8 — Builder Approval Gate

Before code generation, show the user what will be built:

> **Build Plan**
> Screens: <list from architecture>
> Dependencies: <key packages>
> Testing: TDD (tests first, then implementation)
>
> Y) Proceed with build
> M) Modify — add changes before building
> C) Cancel

If **Modify**: append their changes to builder context.
If **Cancel**: stop pipeline with resume instructions.

---

## Step 9 — Run Builder (Subagent-Driven, Per-Screen)

**Goal:** Build each screen with focused context using subagent-driven development.

### Extract screen list from architecture

Parse `03-architecture.json` to get the list of screens with their names and routes.

### Per-screen loop (sequential — each screen sees previous work)

For each screen in the architecture:

**Step 9a — Dispatch builder subagent**

Use the Agent tool to dispatch the **builder** agent with:
- The specific screen spec from `02-design.json`
- The coder rulebook
- Design system tokens
- Architecture context (file structure, data model)
- Reference to `docs/02-design-spec.md` and `docs/03-architecture.md`
- Instruction: "Build ONLY the `<ScreenName>` screen following TDD. Write tests first, then implementation."

Report progress: "Building: <ScreenName> (3/6 screens)"

**Step 9b — Dispatch spec reviewer subagent**

After the screen is built, use the Agent tool (with model: haiku) to dispatch a reviewer that:
- Reads the actual generated code files (not the builder's self-report)
- Verifies the screen matches the design spec exactly
- Checks: all states implemented, tokens used correctly, copy matches, accessibility labels present
- Reports: PASS or issues found

If issues are found, re-dispatch the builder subagent with the feedback. Loop until the spec reviewer passes (max 2 retries per screen).

**If a screen still fails after 2 retries:** Log it as FAILED in the builder log, skip to the next screen, and continue the build. Do NOT abort the entire pipeline. Failed screens will be flagged in the reviewer report and can be fixed with `/appbuilder-iterate`.

Report: "Screen <ScreenName>: [pass] or [issues found — revising] or [FAILED after 2 retries — skipped]"

### After all screens

- Save `04-builder-log.json` with per-screen results
- Write `docs/04-build-log.md` — screens built, test counts, pass/fail status

---

## Step 10 — Run Hardener (Parallel Audit Subagents)

**Goal:** 4 independent audits running concurrently.

Dispatch 4 subagents in parallel using the Agent tool (all with model: haiku):

1. **Security Audit** — secrets scan, dependency vulnerabilities, OWASP Mobile Top 10, injection checks, supply chain (Trail of Bits), dangerous code patterns
2. **Platform Compliance** — iOS HIG, Material Design, cross-platform leaks, web security (Next.js)
3. **Edge Cases** — text overflow, offline handling, keyboard interaction, orientation, memory leaks
4. **AI Slop Detection** — visual anti-patterns (Impeccable), copy anti-patterns (Stop-Slop), banned phrases

Also include platform-specific performance checks:
- **Web (Next.js):** Core Web Vitals budgets (LCP <2.5s, INP <200ms, CLS <0.1), bundle sizes, next/image, next/font
- **Mobile (Expo):** JS bundle <2MB, FlatList optimization, Reanimated usage, Hermes enabled

After all 4 complete:
- Merge results into `05-hardener-report.json`
- Apply auto-fixes (pure black/white → palette tint, bounce easing → spring, banned phrases → specific alternatives)
- Write `docs/05-security-report.md` — summary, findings by category, auto-fixes applied

Report: "Hardener complete. <N> auto-fixed, <N> require review."

---

## Step 11 — Run Reviewer Agent

Dispatch the **reviewer** agent using the Agent tool. Pass references to all previous artifacts and docs.

The reviewer must follow the **verification-before-completion** protocol:
1. Run each verification command fresh (build, tsc, eslint, test suite)
2. Read FULL output — not just exit codes
3. Verify that hardener auto-fixes did not introduce regressions
4. Flag any screens that were skipped due to builder failures
5. Paste relevant output in the report
6. Never claim success without evidence

After completion:
- Save `06-reviewer-report.json`
- Write `docs/06-review-verdict.md` — verdict, build/test/coverage status, issues

---

## Step 12 — Register and Report

**Save to artifact cache:**
- `.appbuilder/cache/01-plan.json`
- `.appbuilder/cache/02-design-system.json`
- `.appbuilder/cache/02-coder-rulebook.json`
- `.appbuilder/cache/03-architecture.json`

These cached artifacts enable token-efficient `/iterate` runs — change-type classification determines which caches to invalidate.

**Register the project** in `~/.appbuilder/registry.json`.

**Present next steps based on verdict:**

If PASS:
```
## Build Complete

**App:** <App Name>
**Platform:** <Platform>
**Location:** <path>

### What's next?
- Preview:      /appbuilder-preview
- Iterate:      /appbuilder-iterate "add dark mode"
- Deploy:       /appbuilder-deploy-config
- Assets:       /appbuilder-assets (icon, splash, screenshots)
- Docs:         <path>/docs/
```

If FAIL:
```
## Build Incomplete

**Verdict:** FAIL — <primary blocking issue>

### To fix:
- Review docs/06-review-verdict.md for details
- Run /iterate "<fix description>" to address issues
```

---

## Key Rules

- ALWAYS run the Planner agent (Step 3) before any other agent.
- ALWAYS show the Design Review Gate (Step 5) and loop until approved — max 5 revisions.
- ALWAYS show the Builder Approval Gate (Step 7) before code generation.
- Builder uses subagent-driven development: one Agent dispatch per screen, sequential.
- Hardener uses parallel Agent dispatches: 4 concurrent audit subagents.
- Write `docs/*.md` after each agent — both humans and downstream agents use these.
- Cache artifacts in `.appbuilder/cache/` for token-efficient iterations.
- Never skip the Hardener or Reviewer.
- If any step fails, stop and report with resume instructions.
- The spec reviewer after each screen uses model: haiku for cost efficiency.
- The hardener subagents use model: haiku for cost efficiency.
