#!/usr/bin/env bash
set -euo pipefail

# sync-plugin.sh — Sync skills from source list to a single target, bump version on change
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
CLAUDE_MANIFEST="$ROOT_DIR/plugins/$PLUGIN_NAME/.claude-plugin/plugin.json"
CODEX_MANIFEST="$ROOT_DIR/plugins/$PLUGIN_NAME/.codex-plugin/plugin.json"

[[ -f "$SYNC_JSON" ]] || abort "sync.json not found: $SYNC_JSON"

# ---- parse sync.json ----
# Format: { "source": ["/path/1", "/path/2"], "target": "rel/path" }

SOURCES=()
TARGET=""

in_source=false first=true
while IFS= read -r line; do
  if [[ "$line" =~ \"source\" ]]; then
    in_source=true
    continue
  fi
  if $in_source; then
    $first && { [[ "$line" =~ \[ ]] && { first=false; continue; }; }
    first=false
    if [[ "$line" =~ ^[[:space:]]*\] ]]; then
      in_source=false
      continue
    fi
    val="$(echo "$line" | grep -oE '"[^"]*"' | head -1 | sed 's/"//g')"
    [[ -n "$val" ]] && SOURCES+=("$val")
  fi
  if [[ "$line" =~ \"target\" ]]; then
    TARGET="$(echo "$line" | grep -oE '"[^"]*"' | tail -1 | sed 's/"//g')"
  fi
done < "$SYNC_JSON"

[[ ${#SOURCES[@]} -gt 0 ]] || abort "no source entries in sync.json"
[[ -n "$TARGET" ]] || abort "no target in sync.json"

TARGET_DIR="$ROOT_DIR/$TARGET"

# ---- helpers ----

dir_hash() {
  local dir="$1"
  if [[ ! -d "$dir" ]] || [[ -z "$(find "$dir" -type f 2>/dev/null)" ]]; then
    echo ""
    return
  fi
  find "$dir" -type f | LC_ALL=C sort | xargs md5 -q 2>/dev/null | md5 -q
}

read_json_str() {
  local file="$1" key="$2"
  if [[ ! -f "$file" ]]; then
    echo ""
    return
  fi
  grep -F "\"$key\"" "$file" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' || true
}

# ---- semver ----

is_semver() {
  [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

bump_patch() {
  local v="$1"
  local major minor patch
  IFS='.' read -r major minor patch <<<"$v"
  [[ -n "$major" && -n "$minor" && -n "$patch" ]] || abort "invalid version: $v"
  echo "$major.$minor.$((patch + 1))"
}

write_manifest_version() {
  local file="$1" version="$2"
  if grep -q '"version"' "$file" 2>/dev/null; then
    # Update existing version field
    VERSION="$version" perl -pi -e 's/^(\s*)"version"\s*:\s*"[^"]*"/$1"version": "$ENV{VERSION}"/' "$file"
  else
    # Add version after opening brace
    perl -pi -e 's/^\{/\{\n  "version": "NEW_VERSION",/' "$file"
    local escaped
    escaped="$(printf '%s\n' "$version" | sed 's/[&/\]/\\&/g')"
    sed -i '' "s/NEW_VERSION/$escaped/" "$file"
  fi
}

# ---- sync ----

echo "sync-plugin: $PLUGIN_NAME"
echo ""

# Step 1: Clear and recreate target
if [[ -d "$TARGET_DIR" ]]; then
  echo "  clear: $TARGET_DIR"
  rm -rf "$TARGET_DIR"
fi
mkdir -p "$TARGET_DIR"

# Step 2: rsync each source
synced=0
skipped=0

for src in "${SOURCES[@]}"; do
  if [[ ! -d "$src" ]]; then
    echo "  [skip] source not found: $src"
    skipped=$((skipped + 1))
    continue
  fi
  name="$(basename "$src")"
  echo "  sync: $src → $TARGET/$name"
  rsync -a --delete "$src/" "$TARGET_DIR/$name/"
  synced=$((synced + 1))
done

echo ""
echo "  synced: $synced  skipped: $skipped"
echo ""

# Step 3: Compute hash and compare
new_hash="$(dir_hash "$TARGET_DIR")"
old_hash="$(read_json_str "$INTEGRITY_JSON" "hash")"

if [[ -z "$new_hash" ]]; then
  abort "target is empty after sync: $TARGET_DIR"
fi

if [[ "$new_hash" == "$old_hash" ]]; then
  version="$(read_json_str "$INTEGRITY_JSON" "version")"
  echo "Up to date (v${version:-?})"
  exit 0
fi

# Step 4: Bump version
current_version="$(read_json_str "$INTEGRITY_JSON" "version")"
if [[ -z "$current_version" ]]; then
  current_version="$(read_json_str "$CLAUDE_MANIFEST" "version")"
fi
if [[ -z "$current_version" ]]; then
  current_version="0.0.0"
fi
is_semver "$current_version" || abort "invalid semver: $current_version"
new_version="$(bump_patch "$current_version")"

echo "  changed: $old_hash → $new_hash"
echo "  version: $current_version → $new_version"
echo ""

# Step 5: Write integrity.json
mkdir -p "$(dirname "$INTEGRITY_JSON")"
printf '{\n  "version": "%s",\n  "hash": "%s"\n}\n' "$new_version" "$new_hash" > "$INTEGRITY_JSON"

# Step 6: Write plugin manifests
if [[ -f "$CLAUDE_MANIFEST" ]]; then
  write_manifest_version "$CLAUDE_MANIFEST" "$new_version"
  echo "  updated: .claude-plugin/plugin.json"
fi
if [[ -f "$CODEX_MANIFEST" ]]; then
  write_manifest_version "$CODEX_MANIFEST" "$new_version"
  echo "  updated: .codex-plugin/plugin.json"
fi

echo ""
echo "Updated to v$new_version"
