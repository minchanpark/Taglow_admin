#!/usr/bin/env bash
set -euo pipefail

api_base_url="${TAGLOW_API_BASE_URL:-https://vote.newdawnsoi.site}"
spec_path="${TAGLOW_OPENAPI_SPEC:-${1:-dev/tagvote-openapi.json}}"
tmp_file="$(mktemp)"

cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT

mkdir -p "$(dirname "$spec_path")"
curl -fsSL "$api_base_url/v3/api-docs" -o "$tmp_file"

if command -v jq >/dev/null 2>&1; then
  title="$(jq -r '.info.title + " " + .info.version' "$tmp_file")"
  echo "Fetched $title from $api_base_url/v3/api-docs"
  echo
  echo "API paths:"
  jq -r '.paths | keys[]' "$tmp_file"
else
  echo "Fetched OpenAPI spec from $api_base_url/v3/api-docs"
fi

if [[ -f "$spec_path" ]] && cmp -s "$tmp_file" "$spec_path"; then
  echo
  echo "No OpenAPI changes: $spec_path"
  exit 0
fi

cp "$tmp_file" "$spec_path"
echo
echo "Updated $spec_path"
