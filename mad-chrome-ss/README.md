# mad-chrome-ss

Real **Chrome extension UI screenshots** on macOS: Chrome for Testing, optional
`about:blank` backdrop (tmp only), window-id capture, alpha-bbox crop to a
parametric size. Agent instructions: [`SKILL.md`](SKILL.md).

Stay generic — no project names, no store-specific copy.

## When

The user asks for extension screenshots, store listing images, README visuals, or
`/mad-chrome-ss`.

## Platform

**macOS only.** Requires Accessibility (for window/menu automation), Pillow, Node,
Swift (CLT), and Playwright-managed Chrome for Testing.

## Output

One cropped PNG at `WIDTH` x `HEIGHT` (default **1280x800**). Git/LFS/commit is
not part of this skill.

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
| `scripts/capture-window.sh` | `screencapture -l` |
| `scripts/crop-to-size.py` | Alpha bbox crop + resize |
