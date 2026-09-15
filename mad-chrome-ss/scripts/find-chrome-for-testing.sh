#!/usr/bin/env bash
set -euo pipefail

# Resolve a Chrome for Testing binary. Cached browsers are reused without
# network access; Playwright only runs when nothing is cached.

BINARY_NAME="Google Chrome for Testing"
APP_SUFFIX="${BINARY_NAME}.app/Contents/MacOS/${BINARY_NAME}"

cache_roots() {
  if [[ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ]]; then
    printf '%s\n' "${PLAYWRIGHT_BROWSERS_PATH}"
  fi
  printf '%s\n' "${HOME}/Library/Caches/ms-playwright"
  printf '%s\n' "${HOME}/.cache/ms-playwright"
  printf '%s\n' "${TMPDIR:-/tmp}"
}

# Newest cached build wins, so a stale revision never shadows a fresh install.
newest_cached_binary() {
  local root candidate ranked
  local candidates=()

  while IFS= read -r root; do
    [[ -d "${root}" ]] || continue
    while IFS= read -r candidate; do
      if [[ -x "${candidate}" ]]; then
        candidates+=("${candidate}")
      fi
    done < <(
      find "${root}" -maxdepth 8 -type f \
        -path "*/chromium-*/chrome-mac*/${APP_SUFFIX}" 2>/dev/null
    )
  done < <(cache_roots)

  (( ${#candidates[@]} > 0 )) || return 0

  ranked="$(
    printf '%s\n' "${candidates[@]}" \
      | awk -F'chromium-' '{ split($2, segments, "/"); print segments[1] "\t" $0 }' \
      | sort -rn
  )"
  printf '%s\n' "${ranked%%$'\n'*}" | cut -f2-
}

if [[ -n "${CHROME_BIN:-}" ]]; then
  if [[ ! -x "${CHROME_BIN}" ]]; then
    echo "CHROME_BIN is not executable: ${CHROME_BIN}" >&2
    exit 1
  fi
  printf '%s\n' "${CHROME_BIN}"
  exit 0
fi

RESOLVED="$(newest_cached_binary)"

if [[ -z "${RESOLVED}" ]]; then
  if ! command -v npx >/dev/null 2>&1; then
    echo "No cached Chrome for Testing and npx is unavailable (needs Node.js), or set CHROME_BIN." >&2
    exit 1
  fi
  echo "No cached Chrome for Testing; installing via Playwright." >&2
  npx -y playwright@latest install chromium >&2
  RESOLVED="$(newest_cached_binary)"
fi

if [[ -z "${RESOLVED}" ]]; then
  {
    echo "Chrome for Testing not found after Playwright install. Searched for"
    echo "*/chromium-*/chrome-mac*/${APP_SUFFIX} under:"
    cache_roots | sed 's/^/  /'
    echo "Set CHROME_BIN to a Chrome for Testing binary to bypass this lookup."
  } >&2
  exit 1
fi

printf '%s\n' "${RESOLVED}"
