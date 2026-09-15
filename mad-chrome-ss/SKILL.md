---
name: mad-chrome-ss
description: >-
  Capture real Chrome extension UI screenshots on macOS using Chrome for Testing,
  optional about:blank backdrop in /tmp, window-id capture, and alpha-bbox crop
  to a parametric size. Use when the user asks for extension screenshots, store
  listing images, or /mad-chrome-ss.
disable-model-invocation: true
---

# Chrome extension screenshots (macOS)

Capture **real** browser UI (not mockups). Scope: macOS only. Output: one PNG at
`WIDTH` x `HEIGHT` (default 1280x800). Git/LFS/commit is out of scope.

Scripts live next to this file: `scripts/`.

## Prerequisites

1. **macOS** with Accessibility enabled for the agent host (Cursor):
   `osascript -e 'tell application "System Events" to get UI elements enabled'` -> `true`
   If `false`: System Settings -> Privacy & Security -> Accessibility -> enable Cursor, then **quit and restart Cursor** (`Cmd+Q`).
2. **Node.js** (for CDP helpers and Playwright browser install).
3. **Python 3 + Pillow** (`pip3 install Pillow`) for crop/resize.
4. **Swift** (Xcode CLT) for window-id lookup.
5. Unpacked extension directory (Manifest V3) with a valid `manifest.json`.

## Quick start (active tab content)

Required env:

| Variable | Meaning |
|----------|---------|
| `EXTENSION_DIR` | Path to unpacked extension root |
| `OUTPUT_PATH` | Final PNG path (repo asset or `/tmp` preview) |

Optional:

| Variable | Default | Meaning |
|----------|---------|---------|
| `ACTIVE_URL` | first tab URL | Page shown in the active tab |
| `TAB_URLS` | `about:blank` | Comma-separated URLs opened at launch |
| `WIDTH` | `1280` | Final width |
| `HEIGHT` | `800` | Final height |
| `DEBUG_PORT` | `9224` | Chrome remote debugging port |
| `PROFILE_DIR` | `/tmp/mad-chrome-ss-profile-$$` | Ephemeral user-data dir |
| `PROCESS_NAME` | `Google Chrome for Testing` | Window owner for capture |
| `FOREGROUND_TITLE_PREFIX` | *(empty)* | Match foreground window title prefix |
| `LOCALE_SUFFIX` | `1` | Append `?hl=en` / `?hl=en&gl=US` to http(s) URLs |

Run from the skill directory:

```bash
cd "$(dirname "$0")/.."   # mad-chrome-ss/
./scripts/capture-active-tab.sh
```

The script writes a **cropped** PNG to `OUTPUT_PATH`. Large captures with the
`about:blank` backdrop stay under `/tmp/mad-chrome-ss-*` only.

## User-specified variants

Same orchestrator; set any combination:

| Variable | Example | Effect |
|----------|---------|--------|
| `OPTIONS_PAGE` | `options.html` or `chrome-extension://…/options.html` | Navigate a tab to the extension options page (relative paths resolved via extension id) |
| `HIGHLIGHT_TABS` | `0,1,2` | Multi-select tabs (`chrome.tabs.highlight`) |
| `OPEN_CONTEXT_MENU` | `true` | Right-click menu on one highlighted tab (generic `AXShowMenu`; no menu-item names in this skill) |
| `CONTEXT_MENU_TAB_INDEX` | `1` | Zero-based tab index for the menu (default: first entry in `HIGHLIGHT_TABS`, else `0`) |
| `EXTRA_TAB_URL` | `https://en.wikipedia.org/wiki/Browser_extension` | One extra **unhighlighted** tab for selection contrast |

Recipe intent (agent chooses params, not hardcoded flows):

- **Active tab content** — default; one URL, no menu.
- **Options page** — `OPTIONS_PAGE=options.html`, optional `HIGHLIGHT_TABS`.
- **Multi-select state** — `HIGHLIGHT_TABS=0,1,2` + `EXTRA_TAB_URL=…` (contrast tab not highlighted).
- **Context menu on selection** — add `OPEN_CONTEXT_MENU=true`; cursor is moved off-menu before capture.

Always use **English** demo pages when possible (`LOCALE_SUFFIX=1` or explicit `?hl=en` in URLs).

## Agent workflow

```
Task progress:
- [ ] Preflight (Accessibility, Pillow, extension path)
- [ ] Confirm OUTPUT_PATH and variant params with user when unclear
- [ ] Run capture-active-tab.sh
- [ ] Read OUTPUT_PATH (or /tmp preview) — verify framing before claiming success
- [ ] Save only cropped finals to the repo; never commit /tmp backdrop frames
```

1. **Preflight** — run the Accessibility check; install Pillow if missing.
2. **Inputs** — `EXTENSION_DIR`, `OUTPUT_PATH`, and variant env vars.
3. **Capture** — `./scripts/capture-active-tab.sh` (installs CfT via Playwright if needed).
4. **Verify** — confirm dimensions (`file` / Pillow) and visually inspect: full window chrome + shadow, no desktop, no backdrop browser bar in **final** PNG.
5. **Hand off** — return `OUTPUT_PATH`; git steps use other skills if the user asks.

## Backdrop rule (critical)

1. Launch a **second** maximized window on `about:blank` behind the foreground window.
2. Capture foreground with `screencapture -l WINDOW_ID`.
3. **Crop** to the extension window (alpha bbox + resize) — backdrop chrome must not appear in the committed asset.
4. Keep raw fullscreen/window captures only in `/tmp/mad-chrome-ss-*`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Accessibility: false` | Cursor not granted / not restarted | Enable + full restart |
| `Extension service worker not found` | MV3 worker asleep | Script wakes via options page; retry |
| `window not found` | Wrong `PROCESS_NAME` / title prefix | Set `FOREGROUND_TITLE_PREFIX` |
| Developer mode blocked | Regular Chrome managed by policy | Use Chrome for Testing (this skill) |
| Menu item hover in shot | Cursor over menu | Script warps cursor away before capture |
| Crop cuts window | Wrong window id | See [reference.md](reference.md) |

## Additional resources

- CDP snippets, AppleScript notes, crop details: [reference.md](reference.md)
- Human-oriented summary: [README.md](README.md)
