#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

EXTENSION_DIR="${EXTENSION_DIR:?EXTENSION_DIR is required}"
OUTPUT_PATH="${OUTPUT_PATH:?OUTPUT_PATH is required}"

DEBUG_PORT="${DEBUG_PORT:-9224}"
PROFILE_DIR="${PROFILE_DIR:-/tmp/mad-chrome-ss-profile-$$}"
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-800}"
PROCESS_NAME="${PROCESS_NAME:-Google Chrome for Testing}"
FOREGROUND_TITLE_PREFIX="${FOREGROUND_TITLE_PREFIX:-}"
OPEN_CONTEXT_MENU="${OPEN_CONTEXT_MENU:-false}"
CONTEXT_MENU_TAB_INDEX="${CONTEXT_MENU_TAB_INDEX:-}"
LOCALE_SUFFIX="${LOCALE_SUFFIX:-1}"

RAW_CAPTURE="/tmp/mad-chrome-ss-raw-$$.png"
SESSION_MARKER="/tmp/mad-chrome-ss-session-$$"

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

# Close prior CfT sessions launched by this skill (best effort).
if pgrep -x "Google Chrome for Testing" >/dev/null 2>&1; then
  osascript -e 'tell application "Google Chrome for Testing" to quit' >/dev/null 2>&1 || true
  sleep 1
fi

"${SCRIPT_DIR}/launch-session.sh" >/dev/null
printf '%s\n' "${PROFILE_DIR}" >"${SESSION_MARKER}"

sleep 2
node "${SCRIPT_DIR}/cdp-prepare-session.mjs" >/tmp/mad-chrome-ss-prepare-$$.json

MENU_TAB_INDEX="${CONTEXT_MENU_TAB_INDEX:-}"
if [[ -z "${MENU_TAB_INDEX}" && -n "${HIGHLIGHT_TABS}" ]]; then
  MENU_TAB_INDEX="${HIGHLIGHT_TABS%%,*}"
fi
MENU_TAB_INDEX="${MENU_TAB_INDEX:-0}"

/usr/bin/osascript <<APPLESCRIPT
set processName to "${PROCESS_NAME}"
set titlePrefix to "${FOREGROUND_TITLE_PREFIX}"
set openMenu to "${OPEN_CONTEXT_MENU}"
set menuTabIndex to ${MENU_TAB_INDEX}

tell application "System Events"
  tell process processName
    set frontmost to true
    set foregroundWindow to missing value
    repeat with candidate in windows
      try
        if titlePrefix is missing value or titlePrefix is "" then
          set foregroundWindow to candidate
          exit repeat
        else if name of candidate starts with titlePrefix then
          set foregroundWindow to candidate
          exit repeat
        end if
      end try
    end repeat
    if foregroundWindow is missing value then error "Foreground window not found"

    set backgroundWindow to missing value
    repeat with candidate in windows
      try
        if name of candidate starts with "about:blank" then
          set backgroundWindow to candidate
          exit repeat
        end if
      end try
    end repeat
    if backgroundWindow is not missing value then
      tell backgroundWindow
        set position to {0, 25}
        set size to {1800, 1144}
        perform action "AXRaise"
      end tell
    end if

    tell foregroundWindow
      set position to {260, 170}
      set size to {1280, 800}
      perform action "AXRaise"
    end tell

    if openMenu is "true" then
      set tabButtons to {}
      repeat with e in (entire contents of foregroundWindow)
        try
          if role of e is "AXRadioButton" then set end of tabButtons to e
        end try
      end repeat
      if (count of tabButtons) is 0 then error "No tab strip buttons found"
      set menuIndex to menuTabIndex + 1
      if menuIndex < 1 or menuIndex > (count of tabButtons) then
        error "CONTEXT_MENU_TAB_INDEX out of range"
      end if
      perform action "AXShowMenu" of item menuIndex of tabButtons
    end if
  end tell
end tell
APPLESCRIPT

if [[ "${OPEN_CONTEXT_MENU}" == "true" ]]; then
  swift -e 'import CoreGraphics; CGWarpMouseCursorPosition(CGPoint(x: 1700, y: 1000))' >/dev/null 2>&1 || true
  sleep 0.5
else
  osascript -e "tell application \"System Events\" to tell process \"${PROCESS_NAME}\" to key code 53" >/dev/null 2>&1 || true
fi

sleep 0.8

WINDOW_ID="$(
  swift "${SCRIPT_DIR}/find-window-id.swift" "${PROCESS_NAME}" "${FOREGROUND_TITLE_PREFIX}"
)"
"${SCRIPT_DIR}/capture-window.sh" "${WINDOW_ID}" "${RAW_CAPTURE}"
python3 "${SCRIPT_DIR}/crop-to-size.py" "${RAW_CAPTURE}" "${OUTPUT_PATH}" --width "${WIDTH}" --height "${HEIGHT}"

python3 - <<PY
from pathlib import Path
from PIL import Image
path = Path("${OUTPUT_PATH}")
size = Image.open(path).size
assert size == (${WIDTH}, ${HEIGHT}), size
print(f"verified {path} {size[0]}x{size[1]}")
PY

echo "output=${OUTPUT_PATH}"
echo "raw=${RAW_CAPTURE}"
echo "profile=${PROFILE_DIR}"
