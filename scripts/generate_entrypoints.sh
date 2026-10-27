#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:?Usage: generate_entrypoints.sh ROOT [--check]}"
MODE="${2:-}"
ENTRYPOINTS=(.claude/commands/alethea.md .github/agents/alethea.agent.md .agents/skills/alethea/SKILL.md)
MANIFEST=.alethea/entrypoints.json

fail() {
  printf 'Entrypoint generation failed: %s\n' "$1" >&2
  exit 1
}

safe_path() {
  local remaining="$1" current="$ROOT" part
  while [[ -n "$remaining" ]]; do
    part="${remaining%%/*}"
    current="$current/$part"
    [[ ! -L "$current" ]] || fail "symlink in path: $1"
    if [[ "$remaining" == */* ]]; then
      [[ ! -e "$current" || -d "$current" ]] || fail "non-directory parent: $1"
      remaining="${remaining#*/}"
    else
      remaining=""
    fi
  done
}

private_path() {
  local pattern='^(\.github/(agents/[A-Za-z0-9][A-Za-z0-9._-]*\.agent|prompts/[A-Za-z0-9][A-Za-z0-9._-]*\.prompt)\.md|\.claude/commands/[A-Za-z0-9][A-Za-z0-9._-]*\.md|\.agents/skills/[A-Za-z0-9][A-Za-z0-9._-]*/SKILL\.md)$'
  [[ "$1" =~ $pattern ]] || fail "unsupported private entrypoint path"
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    .github/agents/alethea.agent.md|.claude/commands/alethea.md|.agents/skills/alethea/skill.md)
      fail "private entrypoint collides with a canonical output: $1" ;;
  esac
}

digest() {
  "${HASH_COMMAND[@]}" < "$1" | awk '{print $1}'
}

[[ $# -le 2 && ( -z "$MODE" || "$MODE" == --check ) ]] || fail "expected ROOT and optional --check"
command -v jq >/dev/null 2>&1 || fail "jq is required"
if command -v shasum >/dev/null 2>&1; then
  HASH_COMMAND=(shasum -a 256)
elif command -v sha256sum >/dev/null 2>&1; then
  HASH_COMMAND=(sha256sum)
else
  fail "shasum or sha256sum is required"
fi
ROOT="$(cd "$ROOT" && pwd -P)"
CORE_DIR="$ROOT/alethea-core"
EXTENSION="$ROOT/work/agents/entrypoint.json"
ROUTING="$ROOT/work/agents/routing.md"
PRIVATE_DIR="$ROOT/work/agents/entrypoints"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/alethea-entrypoints.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

for relative in "${ENTRYPOINTS[@]}" .agents/skills/alethea/agents/openai.yaml .claude/CLAUDE.md \
  work/agents/entrypoint.json work/agents/routing.md "$MANIFEST"; do
  safe_path "$relative"
  [[ ! -e "$ROOT/$relative" || -f "$ROOT/$relative" ]] || fail "expected a regular file: $relative"
done
for relative in "${ENTRYPOINTS[@]}"; do
  safe_path "alethea-core/$relative"
done
safe_path work/agents/entrypoints
[[ ! -e "$PRIVATE_DIR" || -d "$PRIVATE_DIR" ]] || fail "private entrypoints must be a directory"

if [[ -f "$ROOT/$MANIFEST" ]]; then
  jq -e -s '
    length == 1 and (.[0] |
      type == "object" and keys == ["files", "version"] and .version == 1 and
      (.files | type == "array" and all(
        type == "object" and keys == ["path", "sha256"] and
        (.path | type == "string" and (test("[^A-Za-z0-9._/-]") | not)) and
        (.sha256 | type == "string" and test("^[a-f0-9]{64}$")))) and
      ([.files[].path | ascii_downcase] | length == (unique | length)))
  ' "$ROOT/$MANIFEST" >/dev/null 2>&1 || fail "invalid private entrypoint ownership manifest"
  cp "$ROOT/$MANIFEST" "$STAGING_DIR/previous.json"
else
  printf '%s\n' '{"version":1,"files":[]}' > "$STAGING_DIR/previous.json"
fi
jq -r '.files[].path' "$STAGING_DIR/previous.json" > "$STAGING_DIR/previous-paths"
while IFS= read -r relative; do
  private_path "$relative"
  safe_path "$relative"
  if [[ -e "$ROOT/$relative" ]]; then
    [[ -f "$ROOT/$relative" ]] || fail "managed entrypoint is not a regular file: $relative"
    expected="$(jq -r --arg path "$relative" '.files[] | select(.path == $path) | .sha256' "$STAGING_DIR/previous.json")"
    [[ "$(digest "$ROOT/$relative")" == "$expected" ]] || fail "managed entrypoint modified; preserve or reconcile it before retrying: $relative"
  fi
done < "$STAGING_DIR/previous-paths"

: > "$STAGING_DIR/private-files.jsonl"
if [[ -d "$PRIVATE_DIR" ]]; then
  find "$PRIVATE_DIR" -mindepth 1 -print0 > "$STAGING_DIR/private-tree"
  while IFS= read -r -d '' source; do
    relative="${source#"$PRIVATE_DIR/"}"
    [[ ! -L "$source" ]] || fail "symlink in private entrypoint tree"
    if [[ -d "$source" ]]; then
      case "$relative" in
        .github|.github/agents|.github/prompts|.claude|.claude/commands|.agents|.agents/skills) continue ;;
      esac
      directory_pattern='^\.agents/skills/[A-Za-z0-9][A-Za-z0-9._-]*$'
      [[ "$relative" =~ $directory_pattern ]] || fail "unsupported private entrypoint directory"
      continue
    fi
    [[ -f "$source" ]] || fail "private entrypoint must be a regular file"
    private_path "$relative"
    safe_path "$relative"
    if [[ -e "$ROOT/$relative" ]]; then
      jq -e --arg path "$relative" 'any(.files[]; .path == $path)' "$STAGING_DIR/previous.json" >/dev/null \
        || fail "unmanaged entrypoint would be overwritten: $relative"
    fi
    mkdir -p "$STAGING_DIR/$(dirname "$relative")"
    cp "$source" "$STAGING_DIR/$relative"
    jq -cn --arg path "$relative" --arg sha256 "$(digest "$STAGING_DIR/$relative")" \
      '{path: $path, sha256: $sha256}' >> "$STAGING_DIR/private-files.jsonl"
  done < "$STAGING_DIR/private-tree"
fi
jq -s '{version: 1, files: sort_by(.path)}' "$STAGING_DIR/private-files.jsonl" > "$STAGING_DIR/next.json"
jq -e '[.files[].path | ascii_downcase] | length == (unique | length)' "$STAGING_DIR/next.json" >/dev/null \
  || fail "case-insensitive private entrypoint collision"
jq -r '.files[].path' "$STAGING_DIR/next.json" > "$STAGING_DIR/next-paths"

if [[ -f "$EXTENSION" ]]; then
  jq -e -s '
    length == 1 and (.[0] |
      type == "object" and (keys - ["tools"] | length == 0) and
      ((if has("tools") then .tools else [] end) |
        type == "array" and all(type == "string" and test("\\S") and (test("[\r\n\u0000]") | not))))
  ' "$EXTENSION" >/dev/null 2>&1 || fail "invalid local configuration; expected only a tools string array"
  jq -c '.tools // []' "$EXTENSION" > "$STAGING_DIR/extra-tools.json"
else
  printf '[]\n' > "$STAGING_DIR/extra-tools.json"
fi

if [[ -f "$ROUTING" ]]; then
  if grep -Fq '<!-- work-routing:' "$ROUTING"; then
    fail "local routing must not contain routing markers"
  fi
else
  ROUTING=/dev/null
fi

awk '
  NR == 1 { if ($0 != "---") exit 1; header = 1; next }
  header && $0 == "---" { closed = 1; exit }
  header && /^tools:/ {
    count++; collecting = 1
    sub(/^tools:[[:space:]]*/, "")
    print; next
  }
  header && collecting {
    if ($0 ~ /^[^[:space:]]/) collecting = 0
    else print
  }
  END { if (!closed || count != 1) exit 1 }
' "$CORE_DIR/.github/agents/alethea.agent.md" > "$STAGING_DIR/base-tools.json" || fail "agent frontmatter must contain exactly one tools field"

jq -e -s 'length == 1 and (.[0] | type == "array" and all(type == "string" and test("\\S") and (test("[\r\n\u0000]") | not)))' \
  "$STAGING_DIR/base-tools.json" >/dev/null 2>&1 || fail "core tools must be a JSON string array (also valid YAML)"
jq -cn --slurpfile base "$STAGING_DIR/base-tools.json" --slurpfile extra "$STAGING_DIR/extra-tools.json" '
  ($base[0] + $extra[0]) | reduce .[] as $tool ([]; if index($tool) == null then . + [$tool] else . end)
' > "$STAGING_DIR/merged-tools.json"

for relative in "${ENTRYPOINTS[@]}"; do
  tools_file=""
  [[ "$relative" != .github/agents/alethea.agent.md ]] || tools_file="$STAGING_DIR/merged-tools.json"
  mkdir -p "$STAGING_DIR/$(dirname "$relative")"
  ROUTING_FILE="$ROUTING" TOOLS_FILE="$tools_file" awk '
    BEGIN {
      if (ENVIRON["TOOLS_FILE"] != "") {
        getline tools < ENVIRON["TOOLS_FILE"]
        close(ENVIRON["TOOLS_FILE"])
      }
    }
    {
      if (NR == 1 && $0 == "---") header = 1
      else if (header && $0 == "---") { header = 0; skip_tools = 0 }
      if (header && tools != "" && /^tools:/) {
        print "tools: " tools; skip_tools = 1; next
      }
      if (skip_tools && ($0 ~ /^[[:space:]]/ || $0 == "")) next
      skip_tools = 0
      if ($0 ~ /^[[:space:]]*<!-- work-routing:start -->[[:space:]]*$/) {
        starts++; inside = 1; print; next
      }
      if ($0 ~ /^[[:space:]]*<!-- work-routing:end -->[[:space:]]*$/) {
        if (!inside) invalid = 1
        ends++; inside = 0
        while ((getline local_line < ENVIRON["ROUTING_FILE"]) > 0) print local_line
        close(ENVIRON["ROUTING_FILE"])
        print; next
      }
      if (inside) {
        if ($0 !~ /^[[:space:]]*$/) invalid = 1
        next
      }
      gsub(/agents\/shared\//, "alethea-core/agents/shared/")
      print
    }
    END { if (starts != 1 || ends != 1 || inside || invalid) exit 1 }
  ' "$CORE_DIR/$relative" > "$STAGING_DIR/$relative" || fail "each core template must have exactly one empty work-routing slot"
done

if [[ "$MODE" != --check ]]; then
  for relative in "${ENTRYPOINTS[@]}"; do
    mkdir -p "$ROOT/$(dirname "$relative")"
    mv -f "$STAGING_DIR/$relative" "$ROOT/$relative"
  done
  while IFS= read -r relative; do
    if ! jq -e --arg path "$relative" 'any(.files[]; .path == $path)' "$STAGING_DIR/next.json" >/dev/null; then
      rm -f "$ROOT/$relative"
    fi
  done < "$STAGING_DIR/previous-paths"
  while IFS= read -r relative; do
    mkdir -p "$ROOT/$(dirname "$relative")"
    mv -f "$STAGING_DIR/$relative" "$ROOT/$relative"
  done < "$STAGING_DIR/next-paths"
  if [[ -s "$STAGING_DIR/next-paths" || -f "$ROOT/$MANIFEST" ]]; then
    mkdir -p -m 700 "$ROOT/.alethea"
    chmod 600 "$STAGING_DIR/next.json"
    mv -f "$STAGING_DIR/next.json" "$ROOT/$MANIFEST"
  fi
fi