#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXTENSION_DIR="${EXTENSION_DIR:?EXTENSION_DIR is required}"
OUTPUT_PATH="${OUTPUT_PATH:?OUTPUT_PATH is required}"

DEBUG_PORT="${DEBUG_PORT:-9224}"
if [[ -n "${PROFILE_DIR:-}" ]]; then
  OWNS_PROFILE=false
else
  PROFILE_DIR="$(mktemp -d /tmp/mad-chrome-ss-profile.XXXXXX)"
  OWNS_PROFILE=true
fi
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-800}"
WINDOW_WIDTH="${WINDOW_WIDTH:-1280}"
WINDOW_HEIGHT="${WINDOW_HEIGHT:-800}"
FRAME_MARGIN="${FRAME_MARGIN:-48}"
DISPLAY_INDEX="${DISPLAY_INDEX:-1}"
TAB_STRIP_LEFT_INSET="${TAB_STRIP_LEFT_INSET:-100}"
TAB_STRIP_RIGHT_INSET="${TAB_STRIP_RIGHT_INSET:-80}"
TAB_STRIP_CENTER_Y="${TAB_STRIP_CENTER_Y:-18}"
MAX_TAB_WIDTH="${MAX_TAB_WIDTH:-240}"
PROCESS_NAME="${PROCESS_NAME:-Google Chrome for Testing}"
FOREGROUND_TITLE_PREFIX="${FOREGROUND_TITLE_PREFIX:-}"
OPEN_CONTEXT_MENU="${OPEN_CONTEXT_MENU:-false}"
CONTEXT_MENU_TAB_INDEX="${CONTEXT_MENU_TAB_INDEX:-}"
CONTEXT_MENU_POINT="${CONTEXT_MENU_POINT:-}"
LOCALE_SUFFIX="${LOCALE_SUFFIX:-1}"
KEEP_SESSION="${KEEP_SESSION:-false}"
PID_POLL_ATTEMPTS="${PID_POLL_ATTEMPTS:-20}"
PID_POLL_INTERVAL="${PID_POLL_INTERVAL:-0.25}"
PID_POLL_TIMEOUT="$(
  awk -v attempts="${PID_POLL_ATTEMPTS}" -v interval="${PID_POLL_INTERVAL}" \
    'BEGIN { printf "%.2f", attempts * interval }'
)"

RAW_CAPTURE="/tmp/mad-chrome-ss-raw-$$.png"
PREVIEW_PATH="${PREVIEW_PATH:-/tmp/mad-chrome-ss-preview-$$.png}"
SESSION_MARKER="/tmp/mad-chrome-ss-session-$$"
PREPARE_STATE="/tmp/mad-chrome-ss-prepare-$$.json"
DIAGNOSTICS_PATH="/tmp/mad-chrome-ss-diagnostics-$$.json"

SESSION_PID=""
CAPTURE_TITLE=""
CAPTURE_MODE="window-id"
SCREEN_BOUNDS=""
WINDOW_BOUNDS=""
TAB_COUNT=""
MENU_POINT=""

write_diagnostics() {
  MAD_SS_DIAG_PATH="${DIAGNOSTICS_PATH}" \
  MAD_SS_PID="${SESSION_PID}" \
  MAD_SS_PROFILE="${PROFILE_DIR}" \
  MAD_SS_DEBUG_PORT="${DEBUG_PORT}" \
  MAD_SS_CAPTURE_MODE="${CAPTURE_MODE}" \
  MAD_SS_WINDOW_TITLE="${CAPTURE_TITLE}" \
  MAD_SS_SCREEN_BOUNDS="${SCREEN_BOUNDS}" \
  MAD_SS_WINDOW_BOUNDS="${WINDOW_BOUNDS}" \
  MAD_SS_TAB_COUNT="${TAB_COUNT}" \
  MAD_SS_MENU_POINT="${MENU_POINT}" \
  MAD_SS_RAW_PATH="${RAW_CAPTURE}" \
  MAD_SS_PREVIEW_PATH="${PREVIEW_PATH}" \
  MAD_SS_PREPARE_STATE="${PREPARE_STATE}" \
  MAD_SS_PID_POLL_TIMEOUT="${PID_POLL_TIMEOUT}" \
  python3 - <<'PY' || true
import json
import os


def numbers(name, keys):
    raw = os.environ.get(name, "").strip()
    if not raw:
        return None
    parts = [part for part in raw.replace(" ", ",").split(",") if part]
    if len(parts) != len(keys):
        return None
    try:
        return dict(zip(keys, (int(float(part)) for part in parts)))
    except ValueError:
        return None


def integer(name):
    raw = os.environ.get(name, "").strip()
    try:
        return int(raw)
    except ValueError:
        return None


diagnostics = {
    "pid": integer("MAD_SS_PID"),
    "profile": os.environ.get("MAD_SS_PROFILE") or None,
    "debugPort": integer("MAD_SS_DEBUG_PORT"),
    "captureMode": os.environ.get("MAD_SS_CAPTURE_MODE") or None,
    "windowTitle": os.environ.get("MAD_SS_WINDOW_TITLE") or None,
    "screenBounds": numbers("MAD_SS_SCREEN_BOUNDS", ("x", "y", "width", "height")),
    "windowBounds": numbers("MAD_SS_WINDOW_BOUNDS", ("x", "y", "width", "height")),
    "tabCount": integer("MAD_SS_TAB_COUNT"),
    "menuPoint": numbers("MAD_SS_MENU_POINT", ("x", "y")),
    "rawPath": os.environ.get("MAD_SS_RAW_PATH") or None,
    "previewPath": os.environ.get("MAD_SS_PREVIEW_PATH") or None,
    "prepareStatePath": os.environ.get("MAD_SS_PREPARE_STATE") or None,
    "pidPollTimeoutSeconds": float(os.environ.get("MAD_SS_PID_POLL_TIMEOUT") or 0) or None,
}

with open(os.environ["MAD_SS_DIAG_PATH"], "w", encoding="utf-8") as handle:
    json.dump(diagnostics, handle, indent=2)
    handle.write("\n")
PY
}

on_exit() {
  local status=$?
  if (( status == 0 )); then
    return
  fi
  write_diagnostics
  if [[ "${KEEP_SESSION}" == "true" ]]; then
    printf 'KEEP_SESSION=true: session left running for diagnostics (pid=%s profile=%s debug_port=%s diagnostics=%s)\n' \
      "${SESSION_PID:-unknown}" "${PROFILE_DIR}" "${DEBUG_PORT}" "${DIAGNOSTICS_PATH}" >&2
    return
  fi
  if [[ -n "${SESSION_PID}" ]] && kill -0 "${SESSION_PID}" 2>/dev/null; then
    kill "${SESSION_PID}" 2>/dev/null || true
  fi
  if [[ "${OWNS_PROFILE}" == "true" && "${PROFILE_DIR}" == /tmp/mad-chrome-ss-profile.* ]]; then
    rm -rf "${PROFILE_DIR}"
  fi
  rm -f "${SESSION_MARKER}"
  printf 'cleaned up failed run (pid=%s profile=%s). Captures kept: %s %s. Diagnostics: %s. Set KEEP_SESSION=true to keep the session next time.\n' \
    "${SESSION_PID:-none}" "${PROFILE_DIR}" "${RAW_CAPTURE}" "${PREVIEW_PATH}" "${DIAGNOSTICS_PATH}" >&2
}
trap on_exit EXIT

if [[ ! -d "${EXTENSION_DIR}" ]]; then
  echo "EXTENSION_DIR is not a directory: ${EXTENSION_DIR}" >&2
  exit 1
fi
EXTENSION_DIR="$(cd "${EXTENSION_DIR}" && pwd)"

export DEBUG_PORT PROFILE_DIR EXTENSION_DIR LOCALE_SUFFIX
export ACTIVE_URL="${ACTIVE_URL:-}"
export ACTIVE_TAB_INDEX="${ACTIVE_TAB_INDEX:-}"
export OPTIONS_PAGE="${OPTIONS_PAGE:-}"
export HIGHLIGHT_TABS="${HIGHLIGHT_TABS:-}"
export EXTRA_TAB_URL="${EXTRA_TAB_URL:-}"

if [[ -z "${TAB_URLS:-}" ]]; then
  TAB_URLS="about:blank"
  if [[ -n "${ACTIVE_URL}" ]]; then
    TAB_URLS="${ACTIVE_URL}"
  fi
  if [[ -n "${OPTIONS_PAGE}" ]]; then
    TAB_URLS="${TAB_URLS},about:blank"
  fi
fi
export TAB_URLS

if [[ "${OPEN_CONTEXT_MENU}" == "true" && -z "${HIGHLIGHT_TABS}" ]]; then
  echo "OPEN_CONTEXT_MENU requires HIGHLIGHT_TABS" >&2
  exit 1
fi

if ! osascript -e 'tell application "System Events" to get UI elements enabled' 2>/dev/null | grep -qx 'true'; then
  echo "Accessibility is disabled for this host. Enable Cursor in System Settings -> Privacy -> Accessibility, quit Cursor (Cmd+Q), and retry." >&2
  exit 1
fi

if ! python3 -c 'import PIL' 2>/dev/null; then
  echo "Pillow is required: pip3 install Pillow" >&2
  exit 1
fi

"${SCRIPT_DIR}/launch-session.sh" >/dev/null
for _ in $(seq 1 "${PID_POLL_ATTEMPTS}"); do
  SESSION_PID="$(
    pgrep -f -- "--user-data-dir=${PROFILE_DIR}" 2>/dev/null | tail -1 || true
  )"
  [[ -n "${SESSION_PID}" ]] && break
  sleep "${PID_POLL_INTERVAL}"
done
if [[ -z "${SESSION_PID}" ]]; then
  printf 'No Chrome process owns this session after %ss of polling: profile=%s debug_port=%s. Check the launch output; a longer fixed sleep is not the fix.\n' \
    "${PID_POLL_TIMEOUT}" "${PROFILE_DIR}" "${DEBUG_PORT}" >&2
  exit 1
fi
printf 'profile=%s\npid=%s\n' "${PROFILE_DIR}" "${SESSION_PID}" >"${SESSION_MARKER}"

export SESSION_PID
if ! node "${SCRIPT_DIR}/cdp-prepare-session.mjs" >"${PREPARE_STATE}"; then
  printf 'CDP session preparation failed: pid=%s debug_port=%s profile=%s. Readiness is polled (CDP handshake, tab status, service worker); inspect %s and %s instead of adding sleeps.\n' \
    "${SESSION_PID}" "${DEBUG_PORT}" "${PROFILE_DIR}" "${PREPARE_STATE}" "${DIAGNOSTICS_PATH}" >&2
  exit 1
fi

TAB_COUNT="$(
  python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["tabs"]))' \
    "${PREPARE_STATE}"
)"

MENU_TAB_INDEX="${CONTEXT_MENU_TAB_INDEX:-}"
if [[ -z "${MENU_TAB_INDEX}" && -n "${HIGHLIGHT_TABS}" ]]; then
  MENU_TAB_INDEX="${HIGHLIGHT_TABS%%,*}"
fi
MENU_TAB_INDEX="${MENU_TAB_INDEX:-0}"

read -r SCREEN_X SCREEN_Y SCREEN_WIDTH SCREEN_HEIGHT MENU_BAR_HEIGHT < <(
  swift "${SCRIPT_DIR}/screen-frame.swift"
)
SCREEN_BOUNDS="${SCREEN_X},${SCREEN_Y},${SCREEN_WIDTH},${SCREEN_HEIGHT}"
VISIBLE_Y=$((SCREEN_Y + MENU_BAR_HEIGHT))
VISIBLE_HEIGHT=$((SCREEN_HEIGHT - MENU_BAR_HEIGHT))
if (( WINDOW_WIDTH > SCREEN_WIDTH - 160 )); then
  WINDOW_WIDTH=$((SCREEN_WIDTH - 160))
fi
if (( WINDOW_HEIGHT > VISIBLE_HEIGHT - 160 )); then
  WINDOW_HEIGHT=$((VISIBLE_HEIGHT - 160))
fi
FOREGROUND_X=$((SCREEN_X + (SCREEN_WIDTH - WINDOW_WIDTH) / 2))
FOREGROUND_Y=$((VISIBLE_Y + (VISIBLE_HEIGHT - WINDOW_HEIGHT) / 2))

if [[ "${OPEN_CONTEXT_MENU}" == "true" && -z "${CONTEXT_MENU_POINT}" ]]; then
  if (( MENU_TAB_INDEX < 0 || MENU_TAB_INDEX >= TAB_COUNT )); then
    echo "CONTEXT_MENU_TAB_INDEX out of range: ${MENU_TAB_INDEX}/${TAB_COUNT}" >&2
    exit 1
  fi
  TAB_WIDTH=$(( (WINDOW_WIDTH - TAB_STRIP_LEFT_INSET - TAB_STRIP_RIGHT_INSET) / TAB_COUNT ))
  if (( TAB_WIDTH > MAX_TAB_WIDTH )); then
    TAB_WIDTH="${MAX_TAB_WIDTH}"
  fi
  MENU_X=$((FOREGROUND_X + TAB_STRIP_LEFT_INSET + TAB_WIDTH * MENU_TAB_INDEX + TAB_WIDTH / 2))
  MENU_Y=$((FOREGROUND_Y + TAB_STRIP_CENTER_Y))
  CONTEXT_MENU_POINT="${MENU_X},${MENU_Y}"
fi

FOREGROUND_NAME="$(/usr/bin/osascript <<APPLESCRIPT
set processPid to ${SESSION_PID}
set titlePrefix to "${FOREGROUND_TITLE_PREFIX}"

tell application "System Events"
  set targetProcess to first application process whose unix id is processPid
  tell targetProcess
    set frontmost to true
    set foregroundWindow to missing value
    repeat with candidate in windows
      try
        if titlePrefix is missing value or titlePrefix is "" then
          if name of candidate does not start with "about:blank" then
            set foregroundWindow to candidate
            exit repeat
          end if
        else if name of candidate starts with titlePrefix then
          set foregroundWindow to candidate
          exit repeat
        end if
      end try
    end repeat
    if foregroundWindow is missing value then error "Foreground window not found"
    set foregroundName to name of foregroundWindow

    if exists (first window whose name starts with "about:blank") then
      set size of (first window whose name starts with "about:blank") to {${SCREEN_WIDTH}, ${VISIBLE_HEIGHT}}
      set position of (first window whose name starts with "about:blank") to {${SCREEN_X}, ${VISIBLE_Y}}
      perform action "AXRaise" of (first window whose name starts with "about:blank")
    end if

    set size of (first window whose name is foregroundName) to {${WINDOW_WIDTH}, ${WINDOW_HEIGHT}}
    set position of (first window whose name is foregroundName) to {${FOREGROUND_X}, ${FOREGROUND_Y}}
    perform action "AXRaise" of (first window whose name is foregroundName)
    set foregroundWindow to first window whose name is foregroundName
    try
      set value of attribute "AXMain" of foregroundWindow to true
    end try
    try
      set value of attribute "AXFocused" of foregroundWindow to true
    end try

    return foregroundName
  end tell
end tell
APPLESCRIPT
)"
if [[ -n "${FOREGROUND_TITLE_PREFIX}" ]]; then
  CAPTURE_TITLE="${FOREGROUND_TITLE_PREFIX}"
else
  CAPTURE_TITLE="${FOREGROUND_NAME% - ${PROCESS_NAME}}"
fi

if [[ "${OPEN_CONTEXT_MENU}" == "true" ]]; then
  IFS=',' read -r MENU_X MENU_Y <<<"${CONTEXT_MENU_POINT}"
  swift -e "import CoreGraphics; let p=CGPoint(x:${MENU_X},y:${MENU_Y}); CGEvent(mouseEventSource:nil,mouseType:.rightMouseDown,mouseCursorPosition:p,mouseButton:.right)?.post(tap:.cghidEventTap); CGEvent(mouseEventSource:nil,mouseType:.rightMouseUp,mouseCursorPosition:p,mouseButton:.right)?.post(tap:.cghidEventTap)"
  swift -e "import CoreGraphics; CGWarpMouseCursorPosition(CGPoint(x:${SCREEN_WIDTH}-20,y:${SCREEN_HEIGHT}-20))" >/dev/null 2>&1 || true
  sleep 0.5
else
  osascript -e "tell application \"System Events\" to tell (first application process whose unix id is ${SESSION_PID}) to key code 53" >/dev/null 2>&1 || true
fi

sleep 0.8

if [[ "${OPEN_CONTEXT_MENU}" == "true" ]]; then
  CAPTURE_MODE="display-crop"
  MENU_POINT="${CONTEXT_MENU_POINT}"
  read -r WINDOW_X WINDOW_Y ACTUAL_WINDOW_WIDTH ACTUAL_WINDOW_HEIGHT < <(
    swift "${SCRIPT_DIR}/find-window-bounds.swift" \
      "${PROCESS_NAME}" \
      "${CAPTURE_TITLE}" \
      "${SESSION_PID}"
  )
  WINDOW_BOUNDS="${WINDOW_X},${WINDOW_Y},${ACTUAL_WINDOW_WIDTH},${ACTUAL_WINDOW_HEIGHT}"
  screencapture -x -D "${DISPLAY_INDEX}" "${RAW_CAPTURE}"
  python3 "${SCRIPT_DIR}/crop-screen-to-size.py" \
    "${RAW_CAPTURE}" \
    "${PREVIEW_PATH}" \
    --screen "${SCREEN_X},${SCREEN_Y},${SCREEN_WIDTH},${SCREEN_HEIGHT}" \
    --window "${WINDOW_X},${WINDOW_Y},${ACTUAL_WINDOW_WIDTH},${ACTUAL_WINDOW_HEIGHT}" \
    --width "${WIDTH}" \
    --height "${HEIGHT}" \
    --margin "${FRAME_MARGIN}"
else
  WINDOW_ID="$(
    swift "${SCRIPT_DIR}/find-window-id.swift" \
      "${PROCESS_NAME}" \
      "${CAPTURE_TITLE}" \
      "${SESSION_PID}"
  )"
  WINDOW_BOUNDS="$(
    swift "${SCRIPT_DIR}/find-window-bounds.swift" \
      "${PROCESS_NAME}" \
      "${CAPTURE_TITLE}" \
      "${SESSION_PID}" 2>/dev/null || true
  )"
  "${SCRIPT_DIR}/capture-window.sh" "${WINDOW_ID}" "${RAW_CAPTURE}"
  python3 "${SCRIPT_DIR}/crop-to-size.py" \
    "${RAW_CAPTURE}" \
    "${PREVIEW_PATH}" \
    --width "${WIDTH}" \
    --height "${HEIGHT}"
fi

write_diagnostics

python3 "${SCRIPT_DIR}/validate-screenshot.py" \
  "${PREVIEW_PATH}" \
  --width "${WIDTH}" \
  --height "${HEIGHT}"

echo "preview=${PREVIEW_PATH}"
echo "intended_output=${OUTPUT_PATH}"
echo "raw=${RAW_CAPTURE}"
echo "profile=${PROFILE_DIR}"
echo "pid=${SESSION_PID}"
echo "diagnostics=${DIAGNOSTICS_PATH}"
echo "After visually inspecting the preview, promote it with:"
printf 'WIDTH=%q HEIGHT=%q %q %q %q\n' \
  "${WIDTH}" \
  "${HEIGHT}" \
  "${SCRIPT_DIR}/promote-screenshot.sh" \
  "${PREVIEW_PATH}" \
  "${OUTPUT_PATH}"
