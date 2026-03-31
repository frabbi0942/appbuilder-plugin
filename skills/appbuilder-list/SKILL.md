---
name: appbuilder-list
description: "List all registered AppBuilder projects with their status, platform, and location."
---

# /appbuilder-list — List Registered Projects

When the user invokes `/appbuilder-list`, show all projects tracked in the AppBuilder registry.

---

## Step 1 — Read Registry

Read the file `~/.appbuilder/registry.json`.

If the file does not exist or is empty, print:

> **No projects yet.** Run `/appbuilder-build "your app idea"` to create your first app.

Then stop.

---

## Step 2 — Display Projects

For each project in `registry.json`, read its directory to determine current status.

Present a table:

```
## AppBuilder Projects

| # | Name           | Platform | Location                          | Status   |
|---|----------------|----------|-----------------------------------|----------|
| 1 | HabitTracker   | expo     | ~/projects/habit-tracker          | complete |
| 2 | CharmDeal      | expo     | ~/projects/charmdeal-mobile       | building |
| 3 | MyPortfolio    | nextjs   | ~/projects/my-portfolio           | failed   |
```

**Status is determined by checking the project directory:**

- **complete** — `06-reviewer-report.json` exists and contains `"verdict": "PASS"` or `"verdict": "PASS-WITH-WARNINGS"`
- **failed** — `06-reviewer-report.json` exists and contains `"verdict": "FAIL"`
- **building** — some artifacts exist (`01-plan.json` through `05-hardener-report.json`) but no `06-reviewer-report.json`
- **planned** — only `01-plan.json` exists
- **missing** — the project directory no longer exists on disk

---

## Step 3 — Show Available Actions

After the table, show:

> **Actions:**
> - `/appbuilder-build` — Create a new app
> - `/appbuilder-iterate "change"` — Modify a project (cd into it first)
> - `/appbuilder-preview` — Start dev server for a project
> - `/appbuilder-deploy-config` — Generate deployment configs

---

## Key Rules

- If the registry file is malformed JSON, print: "Registry file is corrupted. Delete `~/.appbuilder/registry.json` and re-run `/appbuilder-build` to rebuild it."
- If a project directory no longer exists, mark it as **missing** — do not remove it from the registry automatically.
- Sort projects by most recently created first (use the registry entry order or timestamp if available).
