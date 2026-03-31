---
name: appbuilder-assets
description: "Generate app assets: icon (SVG→PNG), splash screen, adaptive icon, favicon, and App Store/Play Store screenshots. Uses SVG generation, Figma MCP (if available), or image generation APIs."
---

# /appbuilder-assets — Generate App Assets

Generate production-quality visual assets for an AppBuilder project: app icon, splash screen, adaptive icon, favicon, and store screenshots.

---

## Arguments

The user invokes `/appbuilder-assets [options]`.

Options:
- No arguments → generate all assets
- `icon` → app icon only
- `splash` → splash screen only
- `screenshots` → App Store / Play Store screenshots only
- `favicon` → favicon only

---

## Step 1 — Detect Project and Load Context

1. Find the project (same detection as `/appbuilder-iterate`)
2. Read the design system from `.appbuilder/cache/02-design-system.json` or `docs/02-design-spec.md`
3. Extract: app name, primary color, secondary color, background color, brand personality, icon style, font family

If no design system exists, ask the user:
- "What is the app name?"
- "What is the primary brand color? (hex)"
- "Describe the app in one sentence (for icon design)"

---

## Step 2 — Create Asset Directories

Ensure the output directories exist before generating any files:

```bash
mkdir -p assets/screenshots
mkdir -p public  # for web projects only
```

---

## Step 3 — Choose Generation Strategy

Check available tools and choose the best strategy:

| Tool Available | Strategy | Quality |
|---|---|---|
| **Figma MCP** (`use_figma`) | Generate vector icon in Figma, export as PNG | Best — editable, scalable |
| **Image generation MCP** (any tool that generates images) | Generate raster icon via AI image model | Good — photorealistic option |
| **Neither** (default) | Generate SVG code, save as `.svg`, convert note | Good — clean vector, needs manual PNG conversion |

State which strategy you're using: "I'll generate assets using [Figma MCP / SVG code / image generation]."

---

## Step 4 — App Icon (1024×1024)

### Requirements
- Exactly 1024×1024 pixels (App Store requirement)
- NO rounded corners (iOS and Android apply their own masking)
- NO text or wordmark — symbol only
- Single centered symbol on solid or subtle gradient background
- Must be recognizable at 29×29 (smallest iOS size)
- Flat design, sharp edges, professional quality

### Strategy A: Figma MCP

Invoke the `figma-use` skill, then:

1. `create_new_file` → "AppName — Assets"
2. `use_figma` → Create a 1024×1024 frame named "App Icon"
3. Build the icon using geometric shapes:
   - Background: solid rectangle with primary color (or subtle gradient)
   - Symbol: 2-4 geometric shapes that represent the app's core concept
   - Use the design system's color tokens
   - Keep it simple — the best app icons use 1-3 shapes max
4. Create variants: light background + dark background versions

Provide the Figma file URL so the user can export PNGs.

### Strategy B: SVG Code (default)

Write an SVG file to `assets/icon.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <!-- Solid background -->
  <rect width="1024" height="1024" fill="[backgroundColor]"/>
  <!-- Centered symbol using geometric shapes -->
  <!-- 2-4 shapes that represent the app concept -->
</svg>
```

Design rules for the SVG icon:
- Generate TWO variants: `assets/icon.svg` (light background) and `assets/icon-dark.svg` (dark background). iOS 18+ supports dark mode app icons, and Android 13+ supports themed icons.
- Use ONLY the app's design system colors (primary, secondary, accent)
- Maximum 4 shapes for the symbol — simplicity is key
- Center the symbol with ~25% padding on all sides (symbol occupies ~512×512 of the 1024×1024 canvas)
- No strokes thinner than 32px at 1024×1024 scale (won't be visible at small sizes)
- No fine details that disappear at 29×29
- Test: describe the icon at thumbnail size — can you still tell what it is?

After writing the SVG, inform the user:
> "Icon SVG saved to `assets/icon.svg`. To convert to PNG, run:
> `npx sharp --input assets/icon.svg --output assets/icon.png resize 1024 1024`
> Or open in any design tool and export as 1024×1024 PNG."

---

## Step 5 — Splash Screen (1284×2778)

### Requirements
- 1284×2778 pixels (iPhone 15 Pro Max — largest common size)
- Solid background color (from design system)
- Centered app symbol (same as icon, or simplified version)
- NO text, NO tagline — just the symbol
- Must feel clean and premium (it's the first thing users see)

### Figma MCP
Create a 1284×2778 frame in the same Assets file. Center the icon symbol at ~256×256 on the background.

### SVG Code
Write `assets/splash.svg`:
- Same background color as design system's `background` token
- Icon symbol centered at roughly 20% of frame width
- Minimal — just background + centered symbol

---

## Step 6 — Adaptive Icon (Android)

Android requires a foreground layer (the symbol) on a transparent background, which gets composited onto a system-chosen background shape.

### Requirements
- 1024×1024 foreground layer with transparent background
- Symbol centered with extra padding (Android masks ~18% on each edge)
- Safe zone: keep all content within the center 66% (circular safe area)

### Implementation
Write `assets/adaptive-icon.svg`:
- Transparent background
- Same symbol as app icon but positioned within the 66% safe zone
- Primary color for the symbol

---

## Step 7 — Favicon and Apple Touch Icon (web apps only)

For Next.js projects, generate:
- `public/favicon.ico` — 32×32 and 16×16 (ICO format, can be generated from SVG)
- `public/icon.svg` — scalable SVG favicon (modern browsers)
- `public/apple-touch-icon.png` — 180×180 (required for iOS home screen bookmarks)
- `app/icon.png` — 512×512 for PWA manifest

### Implementation
Write `public/icon.svg` — simplified version of the app icon that's legible at 16×16:
- Maximum 2 shapes
- High contrast against both light and dark browser chrome
- Bold, simple geometry

---

## Step 8 — App Store Screenshots (5-6 per platform)

### Requirements
- **iOS**: 6.7" (1290×2796), 6.5" (1284×2778), 5.5" (1242×2208)
- **Android**: Phone (1080×1920 minimum), 7" tablet (1200×1920), 10" tablet (1920×1200)
- Each screenshot tells a story — not just a feature tour
- Text overlay: benefit headline (not feature name)
- Device frame optional but recommended

### Strategy: HTML Screenshot Frames

For each screenshot, generate an HTML file in `assets/screenshots/` that can be opened in a browser and captured:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    /* 1290x2796 viewport */
    body {
      width: 1290px; height: 2796px; margin: 0;
      background: [gradient or solid from design system];
      font-family: [design system font], system-ui;
      display: flex; flex-direction: column;
      align-items: center; justify-content: center;
    }
    .headline {
      font-size: 72px; font-weight: 700;
      color: [onBackground]; text-align: center;
      max-width: 900px; margin-bottom: 80px;
    }
    .device-frame {
      width: 780px; border-radius: 60px;
      box-shadow: 0 40px 80px rgba(0,0,0,0.3);
      overflow: hidden; background: [surface];
    }
    .screen-content {
      /* Simplified representation of the screen */
    }
  </style>
</head>
<body>
  <div class="headline">[Benefit headline — what the user gets, not what the feature is]</div>
  <div class="device-frame">
    <div class="screen-content">
      <!-- Simplified visual of the screen using CSS shapes and text -->
    </div>
  </div>
</body>
</html>
```

### Screenshot sequence (storytelling order):
1. **Hero** — the app's primary value in one visual (core screen with data)
2. **Core action** — the main thing users do (e.g., creating a bouquet)
3. **Result** — what the user gets (e.g., completed bouquet, shared link)
4. **Personalization** — customization or settings that make it theirs
5. **Social proof or delight** — achievements, streaks, sharing
6. **Differentiator** — the one thing no competitor has

### Headline copy rules (from Stop-Slop):
- Benefit-first: "Design stunning bouquets in seconds" not "Bouquet Builder Feature"
- Active voice with "you" or implied "you"
- Max 6 words per headline
- No feature jargon

### If Playwright/Chrome DevTools MCP is available:
Capture each HTML file as a PNG automatically:
1. Open the HTML file in the browser
2. Set viewport to the exact screenshot dimensions
3. Take a screenshot
4. Save to `assets/screenshots/01-hero.png`, `02-core-action.png`, etc.

---

## Step 9 — Output Summary

After generating all assets, report:

```
## Assets Generated

| Asset | Path | Size | Status |
|-------|------|------|--------|
| App Icon | assets/icon.svg | 1024×1024 | ✓ Generated |
| Splash Screen | assets/splash.svg | 1284×2778 | ✓ Generated |
| Adaptive Icon | assets/adaptive-icon.svg | 1024×1024 | ✓ Generated |
| Favicon | public/icon.svg | scalable | ✓ Generated |
| Screenshot 1 | assets/screenshots/01-hero.html | 1290×2796 | ✓ Generated |
| Screenshot 2 | assets/screenshots/02-core-action.html | 1290×2796 | ✓ Generated |
| ... | | | |

### To convert SVGs to PNGs:
npx sharp --input assets/icon.svg --output assets/icon.png resize 1024 1024
npx sharp --input assets/splash.svg --output assets/splash.png resize 1284 2778

### To capture screenshots:
Open each HTML file in Chrome at the correct viewport size and take a screenshot,
or use Playwright: npx playwright screenshot assets/screenshots/01-hero.html assets/screenshots/01-hero.png --viewport-size=1290,2796
```

---

## Key Rules

- ALWAYS use the design system colors — no random colors
- App icon: symbol only, no text, no rounded corners, recognizable at 29×29
- Splash: minimal — centered symbol on solid background, nothing else
- Screenshots: benefit headlines, storytelling order, not feature tours
- SVG is the primary format — it's scalable, editable, and can be converted to any PNG size
- If Figma MCP is available, prefer it for icons (vector editing, easy export)
- If Playwright/Chrome DevTools is available, auto-capture screenshot PNGs from HTML
