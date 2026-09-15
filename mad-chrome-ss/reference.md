# mad-chrome-ss reference

## Why Chrome for Testing

Regular Chrome may block **Developer mode** or unpacked extensions via enterprise
policy. Chrome for Testing (Playwright `chromium` install) avoids that and matches
recent extension APIs (e.g. tab context menus on current channels).

Install / resolve:

```bash
./scripts/find-chrome-for-testing.sh
```

## Remote debugging (CDP)

Launch uses `--remote-debugging-port=$DEBUG_PORT` (default `9224`). The prepare
script talks to `http://127.0.0.1:$DEBUG_PORT/json/list`.

Wake a sleeping MV3 service worker by opening any `chrome-extension://` page target,
then match the `service_worker` target against `background.service_worker` from
the unpacked extension's manifest. Do not select the first extension worker;
Chrome for Testing can expose built-in extension workers too.
If no extension target remains, derive the unpacked extension id from the
absolute load path and open its options page before sending the wake message.

Page preparation polls `tab.status === "complete"` with a timeout. Fixed sleeps
are not evidence that pages are ready.

## Dedicated profile

Every default run creates `/tmp/mad-chrome-ss-profile.XXXXXX` with `mktemp`.
The unique `--user-data-dir` isolates extensions, storage, locale, and browsing
state and identifies the process owned by the run.

Supplying a non-empty `PROFILE_DIR` requires `REUSE_PROFILE=true`. Never use the
user's regular Chrome profile. Do not quit all Chrome for Testing processes;
other automation may own them.

## Tab highlight vs Shift-click

`chrome.tabs.highlight({ windowId, tabs: [indices] })` sets `highlighted: true` in
the API. The active tab must belong to that set. Put `ACTIVE_TAB_INDEX` first in
the array to keep it active, e.g. `[2, 0, 1]`; activating an index outside the
set collapses multi-selection. UI selection styling can be subtle; add an
**unhighlighted** tab (`EXTRA_TAB_URL`) when the shot must show contrast.

For context-menu screenshots, verify both the API state and plural native menu
labels such as `Add Tabs` or `Mute Sites`. Singular labels mean the menu targets
one tab.

## Context menu (generic)

When `OPEN_CONTEXT_MENU=true`:

1. Foreground window raised via AppleScript.
2. Read the prepared tab count from the CDP state.
3. Calculate a tab-strip point from the window bounds and
   `CONTEXT_MENU_TAB_INDEX`.
4. Post a CoreGraphics right-click at that point.
5. Warp cursor away from the menu before `screencapture` (avoids accidental hover).

Current Chrome builds may expose zero tab-strip `AXRadioButton` elements, so
`AXShowMenu` is not the default. Use `CONTEXT_MENU_POINT=x,y` to override the
calculated point when Chrome changes tab geometry. This skill does **not** name
or target a specific menu row (extension-specific).

## Window capture

```bash
WINDOW_ID=$(swift scripts/find-window-id.swift "$PROCESS_NAME" "$FOREGROUND_TITLE_PREFIX")
./scripts/capture-window.sh "$WINDOW_ID" /tmp/mad-chrome-ss-raw.png
```

`screencapture -l` returns Retina-resolution PNG (often 2x logical size).

For `OPEN_CONTEXT_MENU=true`, capture the selected display instead. Native menu
windows can expand the window-id capture's alpha bounds and make the source
nearly square. `crop-screen-to-size.py` reads the logical screen/window bounds,
builds an exact target-ratio crop around the foreground window, then applies one
uniform resize.

The `about:blank` backdrop fills `NSScreen.main.visibleFrame`. Its dimensions
must be queried for every run; hardcoded dimensions fail on different displays,
scaling modes, menu-bar sizes, and monitor layouts.

## Crop

`crop-to-size.py`:

1. Open RGBA PNG.
2. `alpha.getbbox()` for non-transparent pixels (drops window shadow padding when present).
3. If no alpha bbox, fall back to content bbox vs near-white background.
4. Compute one uniform scale factor (`min(target_width/source_width,
   target_height/source_height)`).
5. `LANCZOS` resize with the original aspect ratio.
6. Alpha-composite the result onto a centered white `WIDTH` x `HEIGHT` canvas.

Final assets must show the **full** browser window (title bar, tabs, shadow margin).
Never convert transparent RGBA directly to RGB (transparent pixels become black).
If chrome is clipped or stretched, adjust capture window or bbox logic — do not
commit.

## Preview gate

The orchestrator produces:

1. `/tmp/mad-chrome-ss-raw-*.png`
2. `/tmp/mad-chrome-ss-preview-*.png`
3. A printed `promote-screenshot.sh` command

Read the preview before promotion. `validate-screenshot.py` checks target
dimensions and white outer corners, but it cannot judge framing, menu state, or
semantic correctness.

## Locale helpers

When `LOCALE_SUFFIX=1` (default), http(s) URLs without `hl=` get:

- YouTube hosts: `?hl=en&gl=US` (or `&hl=en&gl=US`)
- Others: `?hl=en` (or `&hl=en`)

## Temp artifacts

| Path | Purpose |
|------|---------|
| `/tmp/mad-chrome-ss-profile.*` | Dedicated ephemeral user-data-dir |
| `/tmp/mad-chrome-ss-raw-*.png` | Uncropped window capture |
| `/tmp/mad-chrome-ss-preview-*.png` | Cropped preview awaiting visual approval |

Delete when done; never commit.

## Failure modes

- **ECONNREFUSED on debug port** — session not ready; increase launch sleep or check port conflict.
- **LFS push errors** — out of scope; use git skills separately.
- **Infobar on CfT** — launch includes `--disable-infobars`; may return on very old builds.
