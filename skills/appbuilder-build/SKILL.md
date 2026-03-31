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

## Step 1 — Output Directory (BLOCKING)

**This step MUST wait for the user's response before proceeding.**

Present the question and STOP. Do not continue until the user responds:

> **Step 1/3 — Project Location**
>
> Where should I create this project?
> Default: `~/projects/<slugified-app-name>`
>
> *(Type a path, or press Enter for default)*

Wait for their response. If they provide a path, use it. If they press Enter or say "default", use the default.
If the directory already exists, ask if they want to use a different name — and wait again.

After confirming the path, create the directory and a `docs/` subdirectory inside it. Then tell the user:

> "Project directory created at `<path>`. Moving to platform selection."

---

## Step 2 — Determine Platform (BLOCKING)

**This step MUST wait for the user's response before proceeding.**

Present the options and STOP:

> **Step 2/3 — Platform**
>
> Which platform are you building for?
>
> 1. **Expo** — React Native mobile app (iOS + Android) *(default)*
> 2. **Next.js** — Web app
> 3. **Chrome Extension** — Browser extension (Manifest V3)
> 4. **Safari Extension** — Safari Web Extension
>
> *(Type 1-4, or press Enter for Expo)*

Wait for the user's choice. Confirm back: "Got it — building as an **Expo** app."

---

## Step 3 — Interactive Planning (BLOCKING — 6 topics, strictly sequential)

**Goal:** Establish product strategy before any design or code.

### CRITICAL RULES FOR THIS STEP

1. **Ask exactly ONE topic per message.** Your message MUST contain only ONE topic's question.
2. **STOP after each topic.** Do not include the next topic in the same message. Ever.
3. **Do not batch.** Even if you know what comes next, only show the current topic.
4. **Wait for the user to respond** before presenting the next topic.
5. **These questions are asked by you** (the orchestrator), NOT by a subagent.

If you find yourself writing "Topic 2" in the same message as "Topic 1" — STOP. Delete it. Send only Topic 1.

### Topic 1/6 — Core Product

Send this message and NOTHING ELSE:

> **Planning — Topic 1/6: Core Product**
>
> Describe the core problem your app solves and who the primary user is.

That's it. One question. Wait for the answer.

If the user's answer is thin, you may ask ONE follow-up (e.g., "What's the 'aha moment' — when does the user first feel value?"). But do not move to Topic 2 until you have a clear answer.

### Topic 2/6 — Architecture

Only after the user answers Topic 1, send this message and NOTHING ELSE:

> **Planning — Topic 2/6: Architecture**
>
> How should the app's data and backend work?
>
> A. **Self-Contained** — All on-device, no server
> B. **Cloud Sync** — Local data synced to cloud
> C. **Own API Backend** — Custom backend you control
> D. **Third-Party API** — Calls external APIs
> E. **Hybrid** — Mix of the above
>
> Which fits best?

Wait for their choice. If they pick but don't mention auth or offline needs, ask ONE follow-up: "Got it. Any existing backend to integrate with? And what auth approach — email/password, social login, magic link, or something else?"

### Topic 3/6 — Monetization

Only after Topic 2 is resolved:

> **Planning — Topic 3/6: Monetization**
>
> How will the app make money?
>
> A. **Free** — No monetization
> B. **Freemium** — Free core + paid features
> C. **Subscription** — Monthly/annual recurring
> D. **One-Time Purchase**
> E. **Consumable IAP** — Credits/tokens
> F. **Advertising**
> G. **Hybrid**
> H. **Let AI Suggest** — I'll research competitors and recommend

Wait. If they choose but don't mention pricing, follow up with ONE question about price point.

### Topic 4/6 — Growth

Only after Topic 3:

> **Planning — Topic 4/6: Growth**
>
> How will users discover and keep using the app?
> - Primary acquisition channel? (ASO, ads, content, referral, etc.)
> - Retention mechanics? (push notifications, streaks, social features)
> - Any virality/referral loops?
> - What action signals a user is "retained"?
Wait. If the answer is brief, follow up on retention: "What would bring a user back the next day/week?"

### Topic 5/6 — Features

Only after Topic 4. Based on all answers so far, propose a feature list:

> **Planning — Topic 5/6: Features**
>
> Based on what you've told me, here's my proposed feature breakdown:
>
> **MVP:** [list]
> **V1.1:** [list]
> **Backlog:** [list]
>
> Want to add, remove, or reprioritize anything?

Wait for confirmation or changes.

### Topic 6/6 — Platform Details

Only after Topic 5. Ask ONE platform-specific question based on the platform chosen in Step 2. Do not list 5-7 questions at once. Ask the most important one:

> **Planning — Topic 6/6: Platform Details**
>
> For your `<platform>` app — any specific requirements for [the single most relevant platform question]?
> - Minimum OS versions?
> - Accessibility requirements beyond WCAG AA?
> - Localization/i18n needs?
> - App Store category and age rating?
> - Regulatory constraints? (HIPAA, COPPA, GDPR, etc.)

If they give a brief answer, that's fine — the planner agent will fill gaps with sensible defaults. Do not grill them with a checklist.

### After all 6 topics are answered

Tell the user:

> "All planning questions answered. Now I'll research competitors and synthesize everything into the product plan. This takes a moment..."

Then dispatch the **planner** agent using the Agent tool. Pass:
- The app description
- The confirmed platform
- **All 6 topic answers collected above** (verbatim user responses)
- Instruction: "Synthesize these user answers into 01-plan.json. Do NOT re-ask these questions — the user has already answered them. Research competitors via web search, then produce the plan."

After the planner completes:
- Save `01-plan.json` to the project root
- Save `.appbuilder/cache/01-plan.json` (artifact cache)
- Write `docs/01-product-plan.md` — human-readable markdown summary of the plan

Present a brief summary of key decisions to the user:

> **Planning complete.** Here's what we decided:
> - [3-5 bullet summary of key decisions]
>
> Product plan saved to `docs/01-product-plan.md`. Moving to design.

---

## Step 4 — Run Design Studio Agent

**Goal:** Produce a complete design system, screen specs, and coder rulebook.

Tell the user what's happening:

> **Step 4 — Design Studio**
> Now I'll generate a complete design system: colors, typography, components, and screen specs. This may take a moment...

### Figma Mockups (optional, BLOCKING)

Check if the Figma MCP is available (look for `mcp__*Figma*` tools). If available, ask and **wait**:

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
- Tell the user: "Design system generated. Let me show you the results for review."

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

Tell the user:

> **Step 6 — Architecture**
> Design approved! Now I'll plan the file structure, dependencies, data model, and navigation graph...

Dispatch the **architect** agent using the Agent tool. Pass:
- `01-plan.json` content
- `02-design.json` content

After completion:
- Save `03-architecture.json`
- Save `.appbuilder/cache/03-architecture.json`
- Write `docs/03-architecture.md` — file structure, dependencies, data model, navigation
- Tell downstream agents: "Reference docs/01-product-plan.md, docs/02-design-spec.md, docs/03-architecture.md"
- Tell the user: "Architecture complete. See `docs/03-architecture.md` for the full breakdown."

---

## Step 7 — Scaffold Project and Install Dependencies

Tell the user:

> **Step 7 — Scaffolding**
> Setting up the project structure and installing dependencies...

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

After scaffolding succeeds, tell the user: "Project scaffolded and dependencies installed. Ready for the build phase."

---

## Step 8 — Builder Approval Gate (BLOCKING)

**This step MUST wait for the user's response before proceeding. This is the last interactive checkpoint before coding begins.**

Before code generation, show the user what will be built:

> **Step 8 — Build Approval (last checkpoint before coding)**
>
> Here's what I'm about to build:
>
> **Screens:** <list from architecture>
> **Dependencies:** <key packages>
> **Approach:** TDD (failing tests first, then implementation)
>
> Y) **Proceed** — start building
> M) **Modify** — add changes before building
> C) **Cancel** — stop pipeline
>
> *After this point, coding runs autonomously screen by screen.*

**Wait for the user's response.**

If **Modify**: append their changes to builder context and re-present this gate.
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

### Interactivity (CRITICAL)
- **Steps 1-3, 5, 8 are BLOCKING** — each must wait for the user's explicit response before proceeding. Do NOT combine multiple questions in one message.
- **One question per message** during planning (Step 3). Ask Topic 1, wait, ask Topic 2, wait, etc.
- **Planning questions are asked by the orchestrator** (you), NOT by the planner subagent. Subagents cannot interact with users.
- **Show progress** at every step: tell the user what step you're on, what's happening, and what comes next.
- **After each agent completes**, summarize what happened before moving to the next step.

### Pipeline
- ALWAYS complete interactive planning (Step 3) before dispatching the planner agent.
- ALWAYS show the Design Review Gate (Step 5) and loop until approved — max 5 revisions.
- ALWAYS show the Builder Approval Gate (Step 8) before code generation — this is the last interactive checkpoint.
- Builder uses subagent-driven development: one Agent dispatch per screen, sequential.
- Hardener uses parallel Agent dispatches: 4 concurrent audit subagents.
- Write `docs/*.md` after each agent — both humans and downstream agents use these.
- Cache artifacts in `.appbuilder/cache/` for token-efficient iterations.
- Never skip the Hardener or Reviewer.
- If any step fails, stop and report with resume instructions.
- The spec reviewer after each screen uses model: haiku for cost efficiency.
- The hardener subagents use model: haiku for cost efficiency.
