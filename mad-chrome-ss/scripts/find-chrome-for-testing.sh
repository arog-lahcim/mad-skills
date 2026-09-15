#!/usr/bin/env bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required (Node.js)." >&2
  exit 1
fi

npx -y playwright@latest install chromium >/dev/null 2>&1 || npx -y playwright@latest install chromium

CHROME_BIN=""
if command -v node >/dev/null 2>&1; then
  CHROME_BIN="$(node <<'NODE' 2>/dev/null || true
try {
  const { chromium } = require('playwright');
  process.stdout.write(chromium.executablePath());
} catch {
  // fall through
}
NODE
)"
fi

if [[ -z "${CHROME_BIN}" || ! -x "${CHROME_BIN}" ]]; then
  CHROME_BIN="$(find "${TMPDIR:-/tmp}" -path '*/playwright/chromium-*/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing' -perm +111 2>/dev/null | head -1)"
fi

if [[ -z "${CHROME_BIN}" || ! -x "${CHROME_BIN}" ]]; then
  echo "Chrome for Testing not found after playwright install." >&2
  exit 1
fi

printf '%s\n' "${CHROME_BIN}"
