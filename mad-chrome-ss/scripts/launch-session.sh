#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHROME_BIN="${CHROME_BIN:-$("$SCRIPT_DIR/find-chrome-for-testing.sh")}"
PROFILE_DIR="${PROFILE_DIR:-$(mktemp -d /tmp/mad-chrome-ss-profile.XXXXXX)}"
REUSE_PROFILE="${REUSE_PROFILE:-false}"
DEBUG_PORT="${DEBUG_PORT:-9224}"
EXTENSION_DIR="${EXTENSION_DIR:?EXTENSION_DIR is required}"
TAB_URLS="${TAB_URLS:-about:blank}"

if [[ ! -d "${EXTENSION_DIR}" ]]; then
  echo "EXTENSION_DIR is not a directory: ${EXTENSION_DIR}" >&2
  exit 1
fi
EXTENSION_DIR="$(cd "${EXTENSION_DIR}" && pwd)"

if [[ -e "${PROFILE_DIR}" && -n "$(ls -A "${PROFILE_DIR}" 2>/dev/null)" && "${REUSE_PROFILE}" != "true" ]]; then
  echo "PROFILE_DIR must be new or empty. Set REUSE_PROFILE=true only for an intentional retry: ${PROFILE_DIR}" >&2
  exit 1
fi
mkdir -p "${PROFILE_DIR}"

APP_BUNDLE="$(cd "$(dirname "${CHROME_BIN}")/../.." && pwd)"
if [[ ! -d "${APP_BUNDLE}" ]]; then
  echo "Could not resolve Chrome app bundle from ${CHROME_BIN}" >&2
  exit 1
fi

read -r -a URL_ARRAY <<<"$(echo "${TAB_URLS}" | tr ',' ' ')"

open -na "${APP_BUNDLE}" --args \
  --user-data-dir="${PROFILE_DIR}" \
  --remote-debugging-port="${DEBUG_PORT}" \
  --load-extension="${EXTENSION_DIR}" \
  --disable-extensions-except="${EXTENSION_DIR}" \
  --disable-infobars \
  --lang=en-US \
  --accept-lang=en-US,en \
  --no-first-run \
  --disable-default-apps \
  --new-window \
  "${URL_ARRAY[@]}"

printf '%s\n' "${PROFILE_DIR}"
