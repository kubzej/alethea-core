#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:?Usage: generate_entrypoints.sh ROOT [--check]}"
MODE="${2:-}"
CORE_DIR="$ROOT/alethea-core"
EXTENSION="$ROOT/work/agents/entrypoint.json"
ROUTING="$ROOT/work/agents/routing.md"
ENTRYPOINTS=(.claude/commands/alethea.md .github/agents/alethea.agent.md .agents/skills/alethea/SKILL.md)

fail() {
  printf 'Entrypoint generation failed: %s\n' "$1" >&2
  exit 1
}

[[ $# -le 2 && ( -z "$MODE" || "$MODE" == --check ) ]] || fail "expected ROOT and optional --check"
command -v jq >/dev/null 2>&1 || fail "jq is required"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/alethea-entrypoints.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

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
    cp "$STAGING_DIR/$relative" "$ROOT/$relative"
  done
fi