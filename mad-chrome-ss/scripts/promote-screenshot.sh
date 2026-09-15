#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PREVIEW_PATH="${1:?preview path required}"
OUTPUT_PATH="${2:?output path required}"
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-800}"

python3 "${SCRIPT_DIR}/validate-screenshot.py" \
  "${PREVIEW_PATH}" \
  --width "${WIDTH}" \
  --height "${HEIGHT}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"
cp "${PREVIEW_PATH}" "${OUTPUT_PATH}"
printf 'promoted %s -> %s\n' "${PREVIEW_PATH}" "${OUTPUT_PATH}"
