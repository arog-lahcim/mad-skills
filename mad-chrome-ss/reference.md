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

Readiness is polled at three points: the CDP handshake on `/json/version`, the
session PID lookup by `--user-data-dir`, and the tab/service-worker state. Every
readiness failure reports the session PID, the CDP port, the poll timeout it
exhausted, and the service worker state (`missing`, `asleep`, `running`,
`woken`). Treat those values as the diagnosis; a longer sleep is not a fix.

## AppleScript window references

`System Events` window references go stale. Identify the session by the PID of
the process this run launched and match windows by title:

```applescript
set targetProcess to first application process whose unix id is processPid
```

Never address `application process "Google Chrome for Testing"` by name - other
Chrome for Testing sessions may be running and the name resolves to the wrong
process.

Any operation that reorders or reshapes windows (`AXRaise`, `position`, `size`)
invalidates a stored reference: the saved index no longer points at the same
window. Capture the window **name** once, then re-resolve the window for every
operation instead of reusing a variable:

```applescript
set foregroundName to name of foregroundWindow
set size of (first window whose name is foregroundName) to {w, h}
set position of (first window whose name is foregroundName) to {x, y}
perform action "AXRaise" of (first window whose name is foregroundName)
set foregroundWindow to first window whose name is foregroundName
```

The same rule applies to the `about:blank` backdrop window, which is re-resolved
for its own size/position/`AXRaise` calls.

The AppleScript block returns the resolved window name, and the orchestrator
passes it to `find-window-id.swift` / `find-window-bounds.swift` together with
the session PID. Accessibility window names carry a ` - <process name>` suffix
that `CGWindowList` titles do not, so the orchestrator strips it before
matching. PID alone is not enough: the backdrop belongs to the same
process, and once a menu or raise reorders windows, "first window of this PID"
can be the backdrop - that is how a 1280x800 capture turns into full-display
backdrop bounds. Both helpers also skip `about:blank` windows when they are
called without a title, so a direct call cannot pick the backdrop either.

## Dedicated profile

Every default run creates `/tmp/mad-chrome-ss-profile.XXXXXX` with `mktemp`.
The unique `--user-data-dir` isolates extensions, storage, locale, and browsing
state and identifies the process owned by the run.

Supplying a non-empty `PROFILE_DIR` requires `REUSE_PROFILE=true`. Never use the
user's regular Chrome profile. Do not quit all Chrome for Testing processes;
other automation may own them.

## No credential access

An ephemeral screenshot profile has nothing to encrypt, so the session must stay
out of the macOS keychain. The launch passes:

| Flag | Effect |
|------|--------|
| `--use-mock-keychain` | In-memory Safe Storage key; no keychain read |
| `--password-store=basic` | No OS keyring for the password store |
| `--disable-sync` | No sign-in or profile sync |
| `--no-default-browser-check` | No default-browser dialog |

Without the first two, Chrome asks for the login keychain password ("Google
Chrome for Testing wants to use your confidential information stored in
Chromium Safe Storage") and, when denied, shows a "Relaunch the browser to load
your profile data and keep it encrypted" infobar that lands in the screenshot.

A keychain prompt during a capture is a bug in the launch flags, not a user
task: deny it, fix the flags, and re-run. Never enter a password for a
screenshot session.

## Failed-run cleanup

The orchestrator installs an exit trap that runs only when the run fails:

1. `kill` the single PID resolved from this run's `--user-data-dir` - never
   `pkill`/`killall` against Chrome for Testing as a whole.
2. `rm -rf` the ephemeral profile only when this run created it with `mktemp`
   (a caller-supplied `PROFILE_DIR` is left untouched).
3. Remove the session marker file.
4. Keep the raw capture, the preview, and the diagnostics JSON - they are the
   evidence for the failure. A promoted `OUTPUT_PATH` is never touched.

`KEEP_SESSION=true` skips steps 1-3 so the browser and profile stay alive for
live inspection (CDP targets, window state); the run prints the PID, profile,
debug port, and diagnostics path instead.

## Diagnostics JSON

Every run writes `/tmp/mad-chrome-ss-diagnostics-<pid>.json` and prints the path
as `diagnostics=...` (also on failure, before cleanup):

```json
{
  "pid": 12345,
  "profile": "/tmp/mad-chrome-ss-profile.AbC123",
  "debugPort": 9224,
  "captureMode": "window-id",
  "windowTitle": "Example Domain",
  "screenBounds": { "x": 0, "y": 0, "width": 1512, "height": 982 },
  "windowBounds": { "x": 116, "y": 91, "width": 1280, "height": 800 },
  "tabCount": 3,
  "menuPoint": null,
  "rawPath": "/tmp/mad-chrome-ss-raw-12345.png",
  "previewPath": "/tmp/mad-chrome-ss-preview-12345.png",
  "prepareStatePath": "/tmp/mad-chrome-ss-prepare-12345.json",
  "pidPollTimeoutSeconds": 5
}
```

`captureMode` is `window-id` or `display-crop`. `windowTitle` is the title the
capture was matched against - if it reads `about:blank`, the run captured the
backdrop. `menuPoint` is `null` unless
`OPEN_CONTEXT_MENU=true`. The file holds session geometry and paths only - no
extension-specific state, menu row names, or tab titles. Per-tab state stays in
`prepareStatePath`, which also carries the `serviceWorker` state object.

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
WINDOW_ID=$(swift scripts/find-window-id.swift "$PROCESS_NAME" "$WINDOW_TITLE" "$SESSION_PID")
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
| `/tmp/mad-chrome-ss-prepare-*.json` | CDP prepare state (tabs, service worker) |
| `/tmp/mad-chrome-ss-diagnostics-*.json` | Session geometry, paths, PID, port |
| `/tmp/mad-chrome-ss-session-*` | Session marker (profile + PID) |

Delete when done; never commit.

## Failure modes

- **ECONNREFUSED on debug port** — the CDP handshake poll exhausted its timeout.
  Read the reported PID, port, and poll timeout, then check for a port conflict
  (another session on `DEBUG_PORT`) or a launch that died before opening the
  port. Re-run with `KEEP_SESSION=true` and inspect
  `http://127.0.0.1:$DEBUG_PORT/json/list`. Do not raise a sleep.
- **`window plus margin cannot fit inside a target-ratio screen crop`** — a
  context menu left open by an earlier run holds the event loop, so AppleScript
  never applies size/position and the window keeps off-screen bounds. The
  diagnostics JSON shows it: `windowBounds` far outside `screenBounds`. Close
  the stray menu (`key code 53`) and the session that owns it, then re-run.
- **LFS push errors** — out of scope; use git skills separately.
- **Infobar on CfT** — launch includes `--disable-infobars`; may return on very old builds.
