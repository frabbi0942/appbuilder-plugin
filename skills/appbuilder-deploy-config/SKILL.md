---
name: appbuilder-deploy-config
description: "Generate deployment configuration files for an AppBuilder project. Supports EAS (mobile), Vercel (web), and Railway (backend)."
---

# /appbuilder-deploy-config — Generate Deployment Configuration

You are the orchestrator for generating deployment configuration files for AppBuilder projects. When the user invokes `/appbuilder-deploy-config`, follow every step below.

---

## Arguments

The user invokes `/appbuilder-deploy-config [targets]`.

Targets (optional, comma-separated):
- `eas` — mobile deployment via Expo Application Services (iOS, Android)
- `vercel` — web deployment via Vercel
- `railway` — backend deployment via Railway
- `all` — generate all three (default if no targets specified)

Examples:
- `/appbuilder-deploy-config` — generates eas.json, vercel.json, and railway.toml
- `/appbuilder-deploy-config eas` — generates only eas.json
- `/appbuilder-deploy-config vercel,railway` — generates vercel.json and railway.toml

---

## Step 1 — Detect Current Project

Determine which AppBuilder project to configure.

1. Check the current working directory for a recognized project structure (presence of `app.json`, `next.config.*`, `manifest.json`, or `package.json` with a `.appbuilder/` subdirectory).
2. If a project is detected, state: "I'll generate deployment configs for **<App Name>** at `<path>`. Is that correct?"
3. If no project is detected in the current directory, read `~/.appbuilder/registry.json` and list registered projects. Ask: "Which project would you like to configure?" and wait for selection.
4. If the registry is empty or does not exist, inform the user: "No AppBuilder projects found. Run `/appbuilder-build` to create one first."

Once the project is confirmed, proceed to Step 2.

---

## Step 2 — Determine Targets

Ask the user which deployment targets they need. If targets were not specified in the command, display:

```
Which deployment targets would you like to configure?

1. EAS (mobile via Expo) — for iOS and Android distribution
2. Vercel (web) — for hosting Next.js or web apps
3. Railway (backend) — for Node.js APIs and services
4. All of the above

Enter your choice (1–4, or comma-separated list like "1,3"):
```

Wait for the user's selection. Map responses to targets:
- `1` or `eas` → EAS only
- `2` or `vercel` → Vercel only
- `3` or `railway` → Railway only
- `4` or `all` → All three

---

## Step 3 — Generate Configuration Files

For each selected target, generate the appropriate configuration file. Skip any file that already exists in the project root (do not overwrite).

---

### Generate: eas.json

**When to generate:** User selected EAS target and project is Expo (React Native).

**File location:** `<project-root>/eas.json`

**Content:**
```json
{
  "cli": {
    "version": ">= 14.0.0"
  },
  "build": {
    "development": {
      "distribution": "internal",
      "android": {
        "gradleCommand": ":app:assembleDebug"
      },
      "ios": {
        "buildConfiguration": "Debug"
      }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "distribution": "store"
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "YOUR_APPLE_ID",
        "ascAppId": "YOUR_ASC_APP_ID",
        "appleTeamId": "YOUR_TEAM_ID"
      },
      "android": {
        "serviceAccount": "path/to/google-services.json",
        "track": "production"
      }
    }
  }
}
```

**Notes:**
- Adjust build profiles based on the app's needs (development, preview, production)
- User must fill in Apple ID, ASC App ID, and team ID for iOS submissions
- User must provide Google Cloud service account JSON for Android submissions

---

### Generate: Vercel configuration

**When to generate:** User selected Vercel target and project is Next.js or web.

**For Next.js projects:** Vercel auto-detects Next.js — no configuration file is needed for basic deployments. Tell the user:

> "Next.js projects deploy to Vercel with zero configuration. Just run `vercel deploy`. If you need custom rewrites, redirects, headers, or cron jobs, I'll generate a `vercel.ts` config."

Only generate `vercel.ts` if the project needs custom routing, cron jobs, or headers:

**File location:** `<project-root>/vercel.ts`

```typescript
import { routes, type VercelConfig } from '@vercel/config/v1';

export const config: VercelConfig = {
  framework: 'nextjs',
  // Add rewrites, redirects, headers, or crons as needed:
  // rewrites: [routes.rewrite('/api/(.*)', 'https://backend.example.com/$1')],
  // crons: [{ path: '/api/cleanup', schedule: '0 0 * * *' }],
};
```

If `vercel.ts` is generated, also install the config package:
```bash
npm install -D @vercel/config
```

**For static / SPA projects:** Generate `vercel.ts`:

```typescript
import { type VercelConfig } from '@vercel/config/v1';

export const config: VercelConfig = {
  buildCommand: 'npm run build',
  outputDirectory: 'dist',
};
```

**Notes:**
- Environment variables should be set via `vercel env add` or the Vercel dashboard — not in config files
- `vercel.ts` replaces `vercel.json` as the recommended config format (TypeScript support, dynamic logic)

---

### Generate: railway.toml

**When to generate:** User selected Railway target and project has a backend service.

**File location:** `<project-root>/railway.toml`

**Content:**
```toml
[build]
builder = "nixpacks"
buildCommand = "npm run build"
startCommand = "npm start"

[deploy]
startCommand = "npm start"
healthcheckUrl = "http://localhost:3001/health"
healthcheckInterval = 10
restartPolicyMaxRetries = 3

[env]
NODE_ENV = "production"
LOG_LEVEL = "info"
```

**Notes:**
- Adjust `buildCommand`, `startCommand`, and `healthcheckUrl` based on the actual backend structure
- Railway uses Nixpacks by default; Dockerfile is also supported if present
- Health check endpoint must return 200 OK for the service to be considered healthy

---

### Generate: Chrome Web Store config (Chrome Extension)

**When to generate:** User selected Chrome Extension target and project has `manifest.json` with Manifest V3.

No config file needed — Chrome Web Store submission is done via the web dashboard. Instead, generate a build script:

**File location:** `<project-root>/scripts/build-extension.sh`

```bash
#!/usr/bin/env bash
# Build and package Chrome extension for Web Store submission
set -euo pipefail
npm run build
cd dist
zip -r ../extension.zip . -x "*.map"
echo "Extension packaged: extension.zip (upload to Chrome Web Store)"
```

Make it executable: `chmod +x scripts/build-extension.sh`

**Next steps for Chrome Extension:**
1. Build: `./scripts/build-extension.sh`
2. Go to https://chrome.google.com/webstore/devconsole
3. Upload `extension.zip`
4. Fill in listing details and submit for review

### Generate: Safari Web Extension config

**When to generate:** User selected Safari Extension target.

Safari Web Extensions require an Xcode project wrapper. If not already present, inform the user:

> "Safari Web Extensions must be built through Xcode. Run `xcrun safari-web-extension-converter <path-to-extension>` to generate the Xcode project, then submit via Xcode → Product → Archive → Distribute App."

---

## Step 4 — Summary and Next Steps

After generating all requested files, display a summary:

```
┌─────────────────────────────────────────────────────────────┐
│  Deployment Configuration Generated                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ✓ eas.json — Expo Application Services config             │
│    → Set Apple ID and Google credentials before deploying   │
│    → Run: eas build --platform ios --build-profile preview │
│                                                             │
│  ✓ vercel.json — Vercel deployment config                  │
│    → Link project: vercel link                              │
│    → Deploy: vercel deploy --prod                           │
│                                                             │
│  ✓ railway.toml — Railway backend config                   │
│    → Link project: railway link                             │
│    → Deploy: railway up                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Then provide detailed next steps:

**For EAS:**
```
1. Install EAS CLI: npm install -g eas-cli
2. Authenticate: eas login
3. Create app on EAS: eas app:create
4. Fill in credentials in eas.json
5. Run: eas build --platform all --build-profile preview
```

**For Vercel:**
```
1. Install Vercel CLI: npm install -g vercel
2. Authenticate: vercel login
3. Link project: vercel link
4. Set environment variables: vercel env pull
5. Deploy: vercel deploy --prod
```

**For Railway:**
```
1. Install Railway CLI: npm install -g @railway/cli
2. Authenticate: railway login
3. Create project: railway init
4. Set environment variables: railway variables
5. Deploy: railway up
```

---

## Step 5 — Handle Existing Files

If any configuration file already exists in the project root, skip generation for that file and inform the user:

```
⚠ eas.json already exists — skipping generation
  (To regenerate, delete the file manually and run /appbuilder-deploy-config again)
```

Do NOT overwrite existing files. Respect the user's existing configuration.

---

## Key Rules

- ALWAYS detect the current project before generating configs
- ALWAYS ask which targets to configure if not specified in the command
- NEVER overwrite existing configuration files — skip them and inform the user
- Generate all requested files in a single run (do not prompt separately for each target)
- Provide clear next steps for each target so the user knows what to do after configs are generated
- Include helpful notes in each config (comments for JSON/TOML) about required credentials and modifications
- For missing or ambiguous platform details (e.g., is this a Next.js or static site?), ask the user for clarification before generating Vercel config
