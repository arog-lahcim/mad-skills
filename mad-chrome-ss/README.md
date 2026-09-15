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
- The backdrop dimensions come from the current display, not hardcoded pixels.
- Context-menu captures use a full-display source; ordinary pages use
  window-id capture.
- Final output keeps the source aspect ratio and uses a white canvas. It is
  never stretched to fit.

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
