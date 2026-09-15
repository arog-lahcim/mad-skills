---
name: mad-chrome-ss
description: >-
  Use when the user explicitly asks for real Chrome extension UI screenshots,
  store listing images, README visuals, or /mad-chrome-ss on macOS.
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
2. **Node.js** (for CDP helpers, and for the Playwright install when no Chrome
   for Testing build is cached yet).
3. **Python 3 + Pillow** (`pip3 install Pillow`) for crop/fit.
4. **Swift** (Xcode CLT) for window-id lookup.
5. Unpacked extension directory (Manifest V3) with a valid `manifest.json`.

## Quick start (active tab content)

Required env:

| Variable | Meaning |
|----------|---------|
| `EXTENSION_DIR` | Path to unpacked extension root |
| `OUTPUT_PATH` | Intended final PNG path (written only after preview approval) |

Optional:

| Variable | Default | Meaning |
|----------|---------|---------|
| `ACTIVE_URL` | first tab URL | Page shown in the active tab |
| `TAB_URLS` | `about:blank` | Comma-separated URLs opened at launch |
| `WIDTH` | `1280` | Final width |
| `HEIGHT` | `800` | Final height |
| `DEBUG_PORT` | `9224` | Chrome remote debugging port |
| `PROFILE_DIR` | new `mktemp` directory | Dedicated ephemeral user-data dir |
| `REUSE_PROFILE` | `false` | Permit intentional reuse of a supplied non-empty profile |
| `DISPLAY_INDEX` | `1` | Display captured for context-menu variants |
| `PROCESS_NAME` | `Google Chrome for Testing` | Window owner for capture |
| `FOREGROUND_TITLE_PREFIX` | *(empty)* | Match foreground window title prefix |
| `LOCALE_SUFFIX` | `1` | Append `?hl=en` / `?hl=en&gl=US` to http(s) URLs |
| `KEEP_SESSION` | `false` | Keep a failed run's browser and profile for diagnostics |
| `CHROME_BIN` | newest cached build | Chrome for Testing binary to use instead of the cache lookup |

Run from the skill directory:

```bash
cd "$(dirname "$0")/.."   # mad-chrome-ss/
./scripts/capture-active-tab.sh
```

The script writes raw and cropped preview PNGs under `/tmp/mad-chrome-ss-*`.
Read the preview, then run the printed `promote-screenshot.sh` command to write
`OUTPUT_PATH`.

## Profile isolation (critical)

1. Use a newly created dedicated profile by default.
2. Never point `PROFILE_DIR` at the user's regular Chrome profile.
3. A supplied non-empty profile fails unless `REUSE_PROFILE=true`.
4. Do not quit unrelated Chrome for Testing processes. Track this session by
   its unique `--user-data-dir` and reported PID.
5. Launch with English UI preferences (`--lang=en-US`,
   `--accept-lang=en-US,en`).
6. Never let the session touch OS credential storage. The launch uses
   `--use-mock-keychain` and `--password-store=basic`, so a screenshot run must
   never raise a macOS keychain password prompt ("Chromium Safe Storage") or the
   "Relaunch the browser to load your profile data" infobar. A prompt means the
   flags are missing - stop and fix the launch, never type a password.
7. A failed run kills only its own PID and deletes only a profile it created
   with `mktemp`; captures, previews, promoted finals, and the diagnostics JSON
   survive. Use `KEEP_SESSION=true` to keep the browser alive for inspection.

## User-specified variants

Same orchestrator; set any combination:

| Variable | Example | Effect |
|----------|---------|--------|
| `OPTIONS_PAGE` | `options.html` or `chrome-extension://…/options.html` | Navigate a tab to the extension options page (relative paths resolved via extension id) |
| `TAB_URLS` | comma-separated http(s) URLs | Set tab URLs by index at prepare time |
| `ACTIVE_TAB_INDEX` | `2` | Active tab after highlight; must occur in `HIGHLIGHT_TABS` when both are set |
| `HIGHLIGHT_TABS` | `0,1,2` | Multi-select tabs (`chrome.tabs.highlight`) |
| `OPEN_CONTEXT_MENU` | `true` | Right-click menu on one highlighted tab; no menu-item names are targeted |
| `CONTEXT_MENU_TAB_INDEX` | `1` | Zero-based tab index for the menu (default: first entry in `HIGHLIGHT_TABS`, else `0`) |
| `CONTEXT_MENU_POINT` | `560,222` | Optional absolute `x,y` override when Chrome tab geometry needs calibration |
| `EXTRA_TAB_URL` | `https://en.wikipedia.org/wiki/Browser_extension` | One extra **unhighlighted** tab for selection contrast |

Recipe intent (agent chooses params, not hardcoded flows):

- **Active tab content** — default; one URL, no menu.
- **Options page** — `OPTIONS_PAGE=options.html`, optional `HIGHLIGHT_TABS`.
- **Multi-select state** — `HIGHLIGHT_TABS=0,1,2` + `EXTRA_TAB_URL=…` (contrast tab not highlighted).
- **Context menu on selection** — add `OPEN_CONTEXT_MENU=true`; the script
  computes a tab point from the window geometry, tab count, and
  `CONTEXT_MENU_TAB_INDEX`, then moves the cursor off-menu before capture.
  Provide `CONTEXT_MENU_POINT=x,y` only to override that calculation.

Always use **English** demo pages when possible (`LOCALE_SUFFIX=1` or explicit `?hl=en` in URLs).

## Agent workflow

```
Task progress:
- [ ] Preflight (Accessibility, Pillow, extension path)
- [ ] Confirm OUTPUT_PATH and variant params with user when unclear
- [ ] Run capture-active-tab.sh
- [ ] Read the `/tmp` preview — verify framing before promotion
- [ ] Promote the approved preview to OUTPUT_PATH
- [ ] Save only promoted finals to the repo; never commit /tmp backdrop frames
```

1. **Preflight** — run the Accessibility check; install Pillow if missing.
2. **Inputs** — `EXTENSION_DIR`, `OUTPUT_PATH`, and variant env vars.
3. **Capture** — `./scripts/capture-active-tab.sh` (reuses a cached Chrome for
   Testing build, installing one via Playwright only when none is cached). It
   prints `diagnostics=` — a `/tmp` JSON with pid, profile,
   debug port, capture mode, screen/window bounds, tab count, menu point, and
   raw/preview paths. Read it first when a run misbehaves.
4. **Verify** — confirm dimensions and white corners, then visually inspect:
   full window chrome + shadow, no desktop, no backdrop browser bar, no
   stretching.
5. **Promote** — only after visual approval, run the command printed by the
   orchestrator.
6. **Hand off** — return `OUTPUT_PATH`; git steps use other skills if the user asks.

## Backdrop rule (critical)

1. Read the current display dimensions; never hardcode a screen size.
2. Fill the display's visible frame with a second `about:blank` window.
3. Center the foreground window within that frame and raise it last.
4. For context menus, capture the display and crop a target-ratio frame around
   the foreground window. For ordinary pages, use window-id capture.
5. Preserve aspect ratio. Alpha-composite window captures onto white; never
   stretch or convert transparent pixels directly to RGB.
6. Keep raw fullscreen/window captures only in `/tmp/mad-chrome-ss-*`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Accessibility: false` | Cursor not granted / not restarted | Enable + full restart |
| `Extension service worker not found` | MV3 worker asleep | Script wakes via options page; read the reported worker state, then retry |
| Session never becomes ready | Port conflict or dead launch | Read PID, CDP port, poll timeout, worker state from the error and diagnostics JSON; never raise a sleep |
| Keychain password prompt | Launch missing `--use-mock-keychain` / `--password-store=basic` | Deny the prompt, restore the flags, re-run; never enter a password |
| "Relaunch the browser..." infobar in shot | Safe Storage access was denied | Same fix as the keychain prompt |
| `window not found` | Wrong `PROCESS_NAME` / title prefix | Set `FOREGROUND_TITLE_PREFIX` |
| Developer mode blocked | Regular Chrome managed by policy | Use Chrome for Testing (this skill) |
| `Chrome for Testing not found` | No cached build in the searched roots | Read the listed roots, run `npx playwright install chromium`, or set `CHROME_BIN` |
| Menu item hover in shot | Cursor over menu | Script warps cursor away before capture |
| Multi-select collapses | Active index is outside highlighted indices | Include `ACTIVE_TAB_INDEX` in `HIGHLIGHT_TABS` |
| Singular menu labels | Context menu opened on one tab, not the group | Verify highlighted state and plural menu labels |
| Black background | RGBA converted directly to RGB | Alpha-composite onto white |
| Distorted window | Independent width/height resize | Use one uniform scale factor |
| Crop cuts window | Wrong window id | See [reference.md](reference.md) |

## Additional resources

- CDP snippets, AppleScript notes, crop details: [reference.md](reference.md)
- Human-oriented summary: [README.md](README.md)
