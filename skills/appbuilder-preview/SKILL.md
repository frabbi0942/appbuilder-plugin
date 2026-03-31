---
name: appbuilder-preview
description: "Start a dev server for an AppBuilder project with Docker isolation. Shows QR code for Expo Go or localhost URL."
---

# /appbuilder-preview — Start Dev Server for an AppBuilder Project

You are the orchestrator for starting and previewing AppBuilder projects in development. When the user invokes `/appbuilder-preview`, follow every step below.

---

## Arguments

The user invokes `/appbuilder-preview [options]`.

Options (all optional):
- `--ios` — start iOS simulator alongside dev server
- `--android` — start Android emulator alongside dev server
- `--web` — open web version in default browser
- `--no-isolation` — run in local environment (skip Docker)

If no options provided, default to starting the dev server and displaying the QR code and localhost URL.

---

## Step 1 — Detect Current Project

Determine which AppBuilder project to preview.

1. Check the current working directory for a recognized project structure (presence of `app.json`, `next.config.*`, `manifest.json`, or `package.json` with a `.appbuilder/` subdirectory).
2. If a project is detected, state: "I'll start the dev server for **<App Name>** at `<path>`. Is that correct?"
3. If no project is detected in the current directory, read `~/.appbuilder/registry.json` and list registered projects. Ask: "Which project would you like to preview?" and wait for selection.
4. If the registry is empty or does not exist, inform the user: "No AppBuilder projects found. Run `/appbuilder-build` to create one first."

Once the project is confirmed, proceed to Step 2.

---

## Step 2 — Choose Isolation Method

Determine how to run the dev server. Prefer the first available option in this order:

1. **Packnplay Docker** (preferred) — if `packnplay` is available in the environment, run the dev server inside an isolated container with forwarded ports
2. **Docker** (fallback) — if `packnplay` is not available but Docker is available, use standard Docker
3. **Local** (fallback) — run the dev server directly in the working directory

State your choice: "I'll run the dev server using **<method>**."

---

## Step 3 — Forward Ports

Configure port forwarding for the development server based on platform:

**Expo (React Native):**
- **8081** — Metro bundler
- **19000** — Expo dev server
- **19006** — Expo web (if `--web` flag)

**Next.js:**
- **3000** — Next.js dev server

**Chrome Extension:**
- No dev server needed — load unpacked from `dist/` directory via `chrome://extensions`

**Safari Extension:**
- Build via Xcode, no port forwarding needed

---

## Step 4 — Ensure Dependencies Are Installed

Before starting the dev server, check if `node_modules/` exists in the project directory.

If missing, run:
```bash
cd <project-path>
npm install
```

Wait for installation to complete. If it fails, report the error and stop.

---

## Step 5 — Start the Dev Server

Execute the appropriate start command based on the platform detected:

**Expo (React Native):**

First check the build mode by reading `03-architecture.json` for the `build_mode` field:

- If `build_mode: "expo-go"` (or field absent — default):
  ```bash
  cd <project-path>
  npx expo start
  ```
  Instruct the user to scan the QR code with Expo Go.

- If `build_mode: "dev-build"`:
  ```bash
  cd <project-path>
  npx expo prebuild
  npx expo run:ios   # or npx expo run:android
  ```
  Inform the user: "This app uses a Development Build (native modules that require Xcode/Android Studio). Building now — this takes longer than Expo Go but gives full native access."

If using isolation, prepend the appropriate command (e.g., `packnplay run npx expo start` or Docker equivalent).

**Next.js:**
```bash
cd <project-path>
npm run dev
```

Wait for the server to start successfully. Confirm output includes either:
- For Expo: "Expo dev server running" or Metro bundler ready
- For Next.js: "ready - started server on"

If the server fails to start, output the error and ask the user to review logs.

---

## Step 6 — Display Connection Instructions

Once the dev server is running, show the user:

**For Expo projects:**
```
┌─────────────────────────────────────────┐
│  Dev Server Started                     │
├─────────────────────────────────────────┤
│                                         │
│  iOS: Scan QR code with Camera app      │
│  Android: Scan QR code with Expo Go     │
│                                         │
│  [QR CODE ASCII ART or IMAGE]           │
│                                         │
│  Manual: exp://[LAN_IP]:8081            │
│  Web: http://localhost:19006            │
│                                         │
└─────────────────────────────────────────┘
```

**For Next.js projects:**
```
┌─────────────────────────────────────────┐
│  Dev Server Started                     │
├─────────────────────────────────────────┤
│  Localhost: http://localhost:3000       │
│                                         │
│  Press Ctrl+C to stop the server        │
│                                         │
└─────────────────────────────────────────┘
```

---

## Step 7 — Handle Platform Options

If the user specified `--ios`, `--android`, or `--web`, take these actions:

**--ios:**
- Run `xcrun simctl list | grep Booted` to verify a simulator is running
- If not, run `open -a Simulator` to launch the iOS Simulator
- After Expo dev server is ready, send the QR code and instruct: "Open the Simulator and use Expo Go to scan the QR code"

**--android:**
- Run `adb devices` to verify an emulator or device is connected
- If not running, run the Android emulator from Android Studio or `$ANDROID_HOME/emulator/emulator -avd <emulator-name>` (after asking which AVD to use)
- After Expo dev server is ready, send the QR code and instruct: "Open Expo Go on your Android device and scan the QR code"

**--web:**
- For Expo web: `npx expo start --web` (already running if Step 5 succeeded)
- Open the web URL in the default browser: `open http://localhost:19006` (macOS) or `start http://localhost:19006` (Windows)

---

## Step 8 — Keep Server Running

Once the dev server is successfully started and connection instructions are displayed, keep the terminal session running. The dev server will watch for file changes and hot-reload automatically.

Instruct the user:
```
The dev server is running. You can now:
- Edit files and see changes live
- Open the app on your device/emulator by scanning the QR code
- Press Ctrl+C to stop the server
```

---

## Key Rules

- ALWAYS detect the current project before starting the dev server
- ALWAYS show the QR code and connection URLs to the user
- If the server fails to start, do NOT attempt to restart automatically — ask the user to review the error
- If ports are in use, suggest the user close other processes or specify a different port
- Maintain isolation (Docker/packnplay) unless the user explicitly specifies `--no-isolation`
- Keep the terminal process running so the dev server continues to serve requests
