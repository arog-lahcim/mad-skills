#!/usr/bin/env bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required (Node.js)." >&2
  exit 1
fi

npx -y playwright@latest install chromium >/dev/null 2>&1 || npx -y playwright@latest install chromium

CHROME_BIN="$(npx -y playwright@latest executable-path chromium 2>/dev/null || true)"
if [[ -z "${CHROME_BIN}" || ! -x "${CHROME_BIN}" ]]; then
  echo "Chrome for Testing not found after playwright install." >&2
  exit 1
fi

printf '%s\n' "${CHROME_BIN}"
