#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"

if [ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ] && [ -d "${CI_PRIMARY_REPOSITORY_PATH}/Grock/Config" ]; then
  REPO_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
fi

CONFIG_DIR="$REPO_ROOT/Grock/Config"
OUTPUT_FILE="$CONFIG_DIR/Secrets.generated.xcconfig"

mkdir -p "$CONFIG_DIR"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

write_setting() {
  key="$1"
  value="${2:-}"

  if [ -n "$value" ]; then
    printf '%s = %s\n' "$key" "$value" >> "$tmp_file"
  fi
}

write_setting "REVENUECAT_API_KEY" "${REVENUECAT_API_KEY:-}"
write_setting "USERJOT_PROJECT_ID" "${USERJOT_PROJECT_ID:-}"

if [ -s "$tmp_file" ]; then
  mv "$tmp_file" "$OUTPUT_FILE"
  echo "Generated $OUTPUT_FILE for Xcode Cloud."
else
  rm -f "$OUTPUT_FILE"
  echo "No Xcode Cloud secrets provided. Skipping generated xcconfig."
fi
