#!/usr/bin/env bash
set -euo pipefail

# sync-plugin.sh — Sync external sources into a plugin via from→to mapping
# Usage: ./scripts/sync-plugin.sh <plugin-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME="${1:-}"

usage() {
  echo "Usage: $0 <plugin-name>"
  exit 1
}

abort() { echo "Error: $*" >&2; exit 1; }

[[ -n "$PLUGIN_NAME" ]] || usage

SYNC_JSON="$SCRIPT_DIR/plugins/$PLUGIN_NAME/sync.json"
INTEGRITY_JSON="$SCRIPT_DIR/plugins/$PLUGIN_NAME/integrity.json"
PLUGIN_DIR="$ROOT_DIR/plugins/$PLUGIN_NAME"

[[ -f "$SYNC_JSON" ]] || abort "sync.json not found: $SYNC_JSON"

# ---- parse sync.json ----
# Extracts from→to pairs from: { "sync": [ { "from": "...", "to": "..." }, ... ] }

FROM_PATHS=()
TO_PATHS=()

in_sync=false first=true
while IFS= read -r line; do
  if [[ "$line" =~ \"sync\" ]]; then
    in_sync=true
    continue
  fi
  if $in_sync; then
    $first && { [[ "$line" =~ \[ ]] && { first=false; continue; }; }
    first=false
    [[ "$line" =~ ^[[:space:]]*\] ]] && break

    if [[ "$line" =~ \"from\" ]]; then
      # Extract the value (last quoted string on the line, after the key)
      f="$(echo "$line" | grep -oE '"[^"]*"' | tail -1 | sed 's/"//g')"
      [[ -n "$f" ]] && FROM_PATHS+=("$f")
    elif [[ "$line" =~ \"to\" ]]; then
      t="$(echo "$line" | grep -oE '"[^"]*"' | tail -1 | sed 's/"//g')"
      [[ -n "$t" ]] && TO_PATHS+=("$t")
    fi
  fi
done < "$SYNC_JSON"

[[ ${#FROM_PATHS[@]} -gt 0 ]] || abort "no sync entries found in sync.json"
[[ ${#FROM_PATHS[@]} -eq ${#TO_PATHS[@]} ]] || abort "mismatched from/to pairs in sync.json"

# ---- helpers ----

dir_hash() {
  local dir="$1"
  if [[ ! -d "$dir" ]] || [[ -z "$(find "$dir" -type f 2>/dev/null)" ]]; then
    echo ""
    return
  fi
  find "$dir" -type f | LC_ALL=C sort | xargs md5 -q 2>/dev/null | md5 -q
}

read_integrity_hash() {
  local file="$1" key="$2"
  if [[ ! -f "$file" ]]; then
    echo ""
    return
  fi
  grep -F "\"$key\"" "$file" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || true
}

write_integrity_json() {
  local file="$1"
  shift
  if [[ $# -eq 0 ]]; then
    printf '{\n}\n' > "$file"
    return
  fi
  printf '{\n' > "$file"
  local count=$#
  local i=1
  while [[ $i -le $# ]]; do
    local key val comma
    key="${!i}"
    i=$((i + 1))
    val="${!i}"
    i=$((i + 1))
    if [[ $i -gt $# ]]; then
      comma=""
    else
      comma=","
    fi
    printf '  "%s": "%s"%s\n' "$key" "$val" "$comma" >> "$file"
  done
  printf '}\n' >> "$file"
}

# ---- sync ----

echo "sync-plugin: $PLUGIN_NAME"
echo ""

local_count=${#FROM_PATHS[@]}
synced=0
skipped=0
failed=0

for ((i = 0; i < local_count; i++)); do
  from="${FROM_PATHS[$i]}"
  to="${TO_PATHS[$i]}"
  dest="$PLUGIN_DIR/$to"

  if [[ ! -d "$from" ]]; then
    echo "  [skip] source not found: $from"
    skipped=$((skipped + 1))
    continue
  fi

  echo "  $from → $to"
  mkdir -p "$dest"
  if rsync -a --delete "$from/" "$dest/"; then
    synced=$((synced + 1))
  else
    echo "  [FAIL] rsync error" >&2
    failed=$((failed + 1))
  fi
done

echo ""
echo "  synced: $synced  skipped: $skipped  failed: $failed"
echo ""

[[ $failed -gt 0 ]] && abort "rsync failures detected"

# ---- integrity ----

mkdir -p "$(dirname "$INTEGRITY_JSON")"

INTEGRITY_PAIRS=()
changed=0
unchanged=0
created=0

for ((i = 0; i < local_count; i++)); do
  to="${TO_PATHS[$i]}"
  dest="$PLUGIN_DIR/$to"

  new_hash="$(dir_hash "$dest")"
  old_hash="$(read_integrity_hash "$INTEGRITY_JSON" "$to")"

  INTEGRITY_PAIRS+=("$to" "$new_hash")

  if [[ -z "$new_hash" ]]; then
    echo "  $to: empty (no files)"
    continue
  fi

  if [[ -z "$old_hash" ]]; then
    echo "  $to: created (→ $new_hash)"
    created=$((created + 1))
  elif [[ "$new_hash" == "$old_hash" ]]; then
    echo "  $to: up to date"
    unchanged=$((unchanged + 1))
  else
    echo "  $to: updated ($old_hash → $new_hash)"
    changed=$((changed + 1))
  fi
done

write_integrity_json "$INTEGRITY_JSON" "${INTEGRITY_PAIRS[@]}"

echo ""
echo "  created: $created  updated: $changed  up to date: $unchanged"
