#!/usr/bin/env bash

set -euo pipefail

CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/alethea-bootstrap.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
ENTRYPOINTS=(.claude/commands/alethea.md .github/agents/alethea.agent.md .agents/skills/alethea/SKILL.md)
ROUTING='Route local example tasks to work.example in work/agents/specs/work.example.md.'
TEST_COUNT=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

setup() {
  TEST_COUNT=$((TEST_COUNT + 1))
  CASE_DIR="$TEST_DIR/case $TEST_COUNT"
  ROOT="$CASE_DIR/alethea"
  for relative in "${ENTRYPOINTS[@]}" scripts/bootstrap.sh scripts/generate_entrypoints.sh .agents/skills/alethea/agents/openai.yaml; do
    mkdir -p "$ROOT/alethea-core/$(dirname "$relative")"
    cp "$CORE_DIR/$relative" "$ROOT/alethea-core/$relative"
  done
  mkdir -p "$ROOT/alethea-knowledge/.git" "$CASE_DIR/bin"
  printf '#!/usr/bin/env bash\nprintf "Unexpected Git invocation\\n" >&2\nexit 99\n' > "$CASE_DIR/bin/git"
  chmod +x "$CASE_DIR/bin/git"
}

configure() {
  mkdir -p "$ROOT/work/agents"
  printf '%s\n' '{"tools":["example_source/*","read","example_source/*"]}' > "$ROOT/work/agents/entrypoint.json"
  printf '%s\n' "$ROUTING" > "$ROOT/work/agents/routing.md"
}

bootstrap() {
  local expected="${1:-success}"
  local result=success
  PATH="$CASE_DIR/bin:$PATH" bash "$ROOT/alethea-core/scripts/bootstrap.sh" "$ROOT" > "$CASE_DIR/output" 2>&1 || result=failure
  [[ "$result" == "$expected" ]] || fail "bootstrap: expected $expected, got $result (case $TEST_COUNT)"
}

snapshot() {
  for relative in "${ENTRYPOINTS[@]}"; do
    mkdir -p "$CASE_DIR/snapshot/$(dirname "$relative")"
    cp "$ROOT/$relative" "$CASE_DIR/snapshot/$relative"
  done
}

unchanged() {
  for relative in "${ENTRYPOINTS[@]}"; do
    cmp -s "$ROOT/$relative" "$CASE_DIR/snapshot/$relative" || fail "generated entrypoint changed unexpectedly: $relative"
  done
}

tools() {
  sed -n 's/^tools: //p' "$ROOT/.github/agents/alethea.agent.md"
}

setup
bootstrap
for relative in "${ENTRYPOINTS[@]}"; do
  grep -Fq 'alethea-core/agents/shared/' "$ROOT/$relative" || fail "shared paths were not rewritten"
  if grep -Fq 'example_source/*' "$ROOT/$relative"; then fail "work tools without extension"; fi
done
[[ -f "$ROOT/.agents/skills/alethea/agents/openai.yaml" ]] || fail "missing skill packaging"
tools | jq -e 'index("read") != null and index("example_source/*") == null' >/dev/null
printf 'PASS: no work extension\n'

setup
configure
bootstrap
for relative in "${ENTRYPOINTS[@]}"; do
  [[ "$(grep -Fc "$ROUTING" "$ROOT/$relative")" == 1 ]] || fail "routing not inserted exactly once"
  cmp -s "$ROOT/alethea-core/$relative" "$CORE_DIR/$relative" || fail "core template was modified"
done
tools | jq -e 'map(select(. == "example_source/*")) | length == 1' >/dev/null
tools | jq -e 'map(select(. == "read")) | length == 1' >/dev/null
grep -Fxq 'user-invocable: true' "$ROOT/.github/agents/alethea.agent.md" || fail "metadata changed"
grep -Fxq 'disable-model-invocation: false' "$ROOT/.github/agents/alethea.agent.md" || fail "metadata changed"
snapshot
bootstrap
unchanged
printf 'PASS: local extension, deduplication, metadata preservation and idempotency\n'

setup
configure
bootstrap
rm -rf "$ROOT/work"
bootstrap
for relative in "${ENTRYPOINTS[@]}"; do
  if grep -Fq 'example_source/*' "$ROOT/$relative" || grep -Fq "$ROUTING" "$ROOT/$relative"; then
    fail "work configuration remained after detach"
  fi
done
printf 'PASS: detached work configuration removed\n'

setup
configure
bootstrap
snapshot
printf '%s\n' '{private-test-value' > "$ROOT/work/agents/entrypoint.json"
rm -rf "$ROOT/alethea-knowledge/.git"
bootstrap failure
unchanged
if grep -Eq 'private-test-value|Unexpected Git invocation' "$CASE_DIR/output"; then fail "invalid config leaked content or reached Git"; fi
printf 'PASS: invalid JSON rejected before writes or clone, without content disclosure\n'

setup
configure
printf '%s\n' '{"tools":"example_source/*"}' > "$ROOT/work/agents/entrypoint.json"
bootstrap failure
[[ ! -e "$ROOT/.claude/commands/alethea.md" ]] || fail "output created for invalid tools"
printf 'PASS: invalid tools rejected\n'

setup
configure
printf '%s\n' '{"tools":[],"unexpected":true}' > "$ROOT/work/agents/entrypoint.json"
bootstrap failure
[[ ! -e "$ROOT/.claude/commands/alethea.md" ]] || fail "output created for unknown keys"
printf 'PASS: unknown config keys rejected\n'

setup
configure
bootstrap
snapshot
template="$ROOT/alethea-core/.agents/skills/alethea/SKILL.md"
awk '/<!-- work-routing:start -->/ { print; print "Concrete local routing must not be stored here."; next } { print }' "$template" > "$CASE_DIR/template"
cp "$CASE_DIR/template" "$template"
bootstrap failure
unchanged
printf 'PASS: nonempty core slot rejected before outputs change\n'

setup
configure
for relative in "${ENTRYPOINTS[@]}"; do
  sed 's/^[[:space:]]*<!-- work-routing:/    <!-- work-routing:/' "$ROOT/alethea-core/$relative" > "$CASE_DIR/template"
  cp "$CASE_DIR/template" "$ROOT/alethea-core/$relative"
done
bootstrap
for relative in "${ENTRYPOINTS[@]}"; do
  grep -Fq "$ROUTING" "$ROOT/$relative" || fail "indented routing slot not supported"
done
printf 'PASS: formatter-indented routing markers\n'

setup
configure
template="$ROOT/alethea-core/.github/agents/alethea.agent.md"
awk '/^tools:/ { print "tools:"; print "  ["; print "    \"read\","; print "    \"search\""; print "  ]"; next } { print }' "$template" > "$CASE_DIR/template"
cp "$CASE_DIR/template" "$template"
bootstrap
tools | jq -e '. == ["read","search","example_source/*"]' >/dev/null
grep -Fxq 'user-invocable: true' "$ROOT/.github/agents/alethea.agent.md" || fail "multiline tools damaged metadata"
printf 'PASS: multiline JSON tools in YAML frontmatter\n'

setup
configure
printf '%s\n' '{"tools":[]}' '{"tools":[]}' > "$ROOT/work/agents/entrypoint.json"
bootstrap failure
[[ ! -e "$ROOT/.claude/commands/alethea.md" ]] || fail "multiple JSON documents accepted"
printf 'PASS: multiple JSON documents rejected\n'

printf '%s tests passed.\n' "$TEST_COUNT"