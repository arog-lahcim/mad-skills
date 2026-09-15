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
then read the `service_worker` target URL for `Runtime.evaluate` calls.

## Tab highlight vs Shift-click

`chrome.tabs.highlight({ windowId, tabs: [indices] })` sets `highlighted: true` in
the API. UI selection styling can be subtle; add an **unhighlighted** tab
(`EXTRA_TAB_URL`) when the shot must show contrast.

## Context menu (generic)

When `OPEN_CONTEXT_MENU=true`:

1. Foreground window raised via AppleScript.
2. Collect `AXRadioButton` elements (tab strip) in order.
3. `perform action "AXShowMenu"` on the button at `CONTEXT_MENU_TAB_INDEX`.
4. Warp cursor away from the menu before `screencapture` (avoids accidental hover).

This skill does **not** name or target a specific menu row (extension-specific).

## Window capture

```bash
WINDOW_ID=$(swift scripts/find-window-id.swift "$PROCESS_NAME" "$FOREGROUND_TITLE_PREFIX")
./scripts/capture-window.sh "$WINDOW_ID" /tmp/mad-chrome-ss-raw.png
```

`screencapture -l` returns Retina-resolution PNG (often 2x logical size).

## Crop

`crop-to-size.py`:

1. Open RGBA PNG.
2. `alpha.getbbox()` for non-transparent pixels (drops window shadow padding when present).
3. If no alpha bbox, fall back to content bbox vs near-white background.
4. `LANCZOS` resize to `WIDTH` x `HEIGHT`.

Final assets must show the **full** browser window (title bar, tabs, shadow margin).
If chrome is clipped, adjust capture window or bbox logic — do not commit.

## Locale helpers

When `LOCALE_SUFFIX=1` (default), http(s) URLs without `hl=` get:

- YouTube hosts: `?hl=en&gl=US` (or `&hl=en&gl=US`)
- Others: `?hl=en` (or `&hl=en`)

## Temp artifacts

| Path | Purpose |
|------|---------|
| `/tmp/mad-chrome-ss-profile-*` | Ephemeral user-data-dir |
| `/tmp/mad-chrome-ss-raw-*.png` | Uncropped window capture |
| `/tmp/mad-chrome-ss-framed-*.png` | Optional fullscreen debug frame |

Delete when done; never commit.

## Failure modes

- **ECONNREFUSED on debug port** — session not ready; increase launch sleep or check port conflict.
- **LFS push errors** — out of scope; use git skills separately.
- **Infobar on CfT** — launch includes `--disable-infobars`; may return on very old builds.
