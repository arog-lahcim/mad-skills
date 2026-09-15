#!/usr/bin/env bash
set -euo pipefail

WINDOW_ID="${1:?window id required}"
OUTPUT_PATH="${2:?output path required}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"
screencapture -x -l "${WINDOW_ID}" "${OUTPUT_PATH}"

if [[ ! -s "${OUTPUT_PATH}" ]]; then
  echo "Capture failed or empty: ${OUTPUT_PATH}" >&2
  exit 1
fi

printf '%s\n' "${OUTPUT_PATH}"
