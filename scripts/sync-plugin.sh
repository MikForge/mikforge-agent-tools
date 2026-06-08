#!/usr/bin/env bash
set -euo pipefail

# sync-plugin.sh — Sync skills from external sources into a plugin
# Usage: ./scripts/sync-plugin.sh <plugin-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME="${1:-}"
SYNC_JSON="$SCRIPT_DIR/plugins/$PLUGIN_NAME/sync.json"
INTEGRITY_JSON="$SCRIPT_DIR/plugins/$PLUGIN_NAME/integrity.json"
SKILLS_DIR="$ROOT_DIR/plugins/$PLUGIN_NAME/skills"

usage() {
  echo "Usage: $0 <plugin-name>"
  exit 1
}

abort() { echo "Error: $*" >&2; exit 1; }

# ---- validate ----

[[ -n "$PLUGIN_NAME" ]] || usage
[[ -f "$SYNC_JSON" ]] || abort "sync.json not found: $SYNC_JSON"

# ---- parse sync.json (native bash, no jq) ----

parse_sources() {
  local file="$1"
  # Extract string values between "sources": [ and the closing ]
  # Works for both [] and multi-line arrays
  local in_sources=false first=true
  while IFS= read -r line; do
    if [[ "$line" =~ \"sources\" ]]; then
      in_sources=true
      continue
    fi
    if $in_sources; then
      [[ "$line" =~ ^[[:space:]]*\] ]] && break
      # For "[" on the same line as sources
      $first && [[ "$line" =~ ^[[:space:]]*\[ ]] && { first=false; continue; }
      first=false
      local val
      val="$(echo "$line" | grep -oE '"[^"]*"' | sed 's/"//g')"
      [[ -n "$val" ]] && echo "$val"
    fi
  done < "$file"
}

SOURCES=()
while IFS= read -r src; do
  [[ -n "$src" ]] && SOURCES+=("$src")
done < <(parse_sources "$SYNC_JSON")

[[ ${#SOURCES[@]} -gt 0 ]] || abort "no sources defined in sync.json"

# ---- compute current skills hash ----

skills_hash() {
  if [[ ! -d "$SKILLS_DIR" ]] || [[ -z "$(find "$SKILLS_DIR" -type f 2>/dev/null)" ]]; then
    echo ""
    return
  fi
  find "$SKILLS_DIR" -type f | LC_ALL=C sort | xargs md5 -q 2>/dev/null | md5 -q
}

read_integrity_hash() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo ""
    return
  fi
  sed -n 's/.*"skills"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$file" | head -1
}

write_integrity_json() {
  local file="$1" hash="$2"
  printf '{\n  "skills": "%s"\n}\n' "$hash" > "$file"
}

# ---- sync ----

echo "sync-plugin: $PLUGIN_NAME"

mkdir -p "$SKILLS_DIR"

for src in "${SOURCES[@]}"; do
  [[ -d "$src" ]] || { echo "  [skip] not a directory: $src" >&2; continue; }

  name="$(basename "$src")"
  dest="$SKILLS_DIR/$name"

  echo "  sync: $src → $dest"
  rsync -a --delete "$src/" "$dest/"
  echo "  [ok] $name"
done

# ---- integrity ----

old_hash="$(read_integrity_hash "$INTEGRITY_JSON")"
new_hash="$(skills_hash)"

if [[ -z "$new_hash" ]]; then
  abort "skills directory is empty after sync"
fi

mkdir -p "$(dirname "$INTEGRITY_JSON")"

if [[ "$new_hash" == "$old_hash" ]]; then
  echo "Up to date ($new_hash)"
  exit 0
elif [[ -z "$old_hash" ]]; then
  write_integrity_json "$INTEGRITY_JSON" "$new_hash"
  echo "Created: → $new_hash"
  exit 0
else
  write_integrity_json "$INTEGRITY_JSON" "$new_hash"
  echo "Updated: $old_hash → $new_hash"
  exit 0
fi
