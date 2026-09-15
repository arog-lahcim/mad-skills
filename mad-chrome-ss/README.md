# mad-chrome-ss

Real **Chrome extension UI screenshots** on macOS: a new dedicated Chrome for
Testing profile, display-sized `about:blank` backdrop (tmp only), preview gate,
and aspect-preserving crop onto a white canvas. Agent instructions:
[`SKILL.md`](SKILL.md).

Stay generic — no project names, no store-specific copy.

## When

The user asks for extension screenshots, store listing images, README visuals, or
`/mad-chrome-ss`.

## Platform

**macOS only.** Requires Accessibility (for window/menu automation), Pillow, Node,
Swift (CLT), and Playwright-managed Chrome for Testing.

## Output

One approved PNG at `WIDTH` x `HEIGHT` (default **1280x800**). The orchestrator
first creates raw and cropped previews in `/tmp`; promotion writes the final
path only after visual inspection. Git/LFS/commit is not part of this skill.

## Isolation and framing

- Every default run creates a new profile with `mktemp`; the user's normal
  Chrome profile is never reused.
- A non-empty supplied profile requires `REUSE_PROFILE=true`.
- The session never touches OS credential storage: `--use-mock-keychain` and
  `--password-store=basic` mean no macOS keychain password prompt and no
  "Relaunch the browser..." infobar in the shot. If a prompt ever appears, deny it
  and treat it as a launch-flag bug.
- A failed run cleans up after itself: it kills only the PID it launched and
  deletes only a profile it created. Other Chrome for Testing sessions, the raw
  capture, the preview, and any promoted final file are left alone.
- `KEEP_SESSION=true` keeps a failed run's browser and profile alive for
  diagnostics.
- The backdrop dimensions come from the current display, not hardcoded pixels.
- Context-menu captures use a full-display source; ordinary pages use
  window-id capture.
- Final output keeps the source aspect ratio and uses a white canvas. It is
  never stretched to fit.

## Readiness and diagnostics

Nothing waits on a guessed delay: the run polls the CDP handshake, the session
PID, tab load status, and the MV3 service worker, and every timeout message
names the PID, the debug port, the exhausted timeout, and the worker state.

Each run also writes a diagnostics JSON to `/tmp` and prints its path as
`diagnostics=`:

```
capture-active-tab.sh
  |-- launch-session.sh ......... dedicated profile + debug port
  |-- poll: PID by --user-data-dir
  |-- cdp-prepare-session.mjs ... poll: CDP, tabs, service worker
  |-- AppleScript ............... re-resolve window per size/position/AXRaise,
  |                               return its title for capture matching
  |-- screencapture ............. window id  OR  display crop
  |-- diagnostics JSON .......... pid, profile, debugPort, captureMode,
  |                               screenBounds, windowBounds, tabCount,
  |                               menuPoint, rawPath, previewPath
  `-- preview gate .............. visual check, then promote-screenshot.sh
```

On failure the same JSON is written before cleanup, so the run leaves evidence
rather than a silent exit.

## Variants (env-driven)

| Goal | Typical env |
|------|-------------|
| Active tab | `ACTIVE_URL`, `OUTPUT_PATH` |
| Options page | `OPTIONS_PAGE=options.html` |
| Multi-select | `HIGHLIGHT_TABS=0,1,2`, optional `EXTRA_TAB_URL` |
| Context menu on selection | `OPEN_CONTEXT_MENU=true`, `HIGHLIGHT_TABS=…` |

## Scripts

| Script | Role |
|--------|------|
| `scripts/capture-active-tab.sh` | Orchestrator (entry point) |
| `scripts/find-chrome-for-testing.sh` | Resolve CfT binary via Playwright |
| `scripts/launch-session.sh` | Isolated profile + extension + debug port |
| `scripts/cdp-prepare-session.mjs` | Tabs, highlight, backdrop, options page |
| `scripts/find-window-id.swift` | CGWindowList -> window id |
| `scripts/find-window-bounds.swift` | Foreground bounds for display crop |
| `scripts/screen-frame.swift` | Current display geometry |
| `scripts/capture-window.sh` | `screencapture -l` |
| `scripts/crop-to-size.py` | Alpha bbox crop + aspect-preserving fit on white |
| `scripts/crop-screen-to-size.py` | Target-ratio display crop around the window |
| `scripts/validate-screenshot.py` | Dimensions and white-corner validation |
| `scripts/promote-screenshot.sh` | Copy an approved preview to final output |
