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

PRIVATE_ENTRYPOINTS=(.github/agents/example.agent.md .github/prompts/example.prompt.md .claude/commands/example.md .agents/skills/example/SKILL.md)
MANIFEST=.alethea/entrypoints.json

configure_entrypoints() {
  for relative in "${PRIVATE_ENTRYPOINTS[@]}"; do
    mkdir -p "$ROOT/work/agents/entrypoints/$(dirname "$relative")"
    printf '%s\n' '---' 'description: Synthetic entrypoint' 'tools: ["example_source/*"]' '---' \
      'Load work/agents/specs/work.example.md and alethea-core/agents/shared/specs/system.keeper.md.' \
      > "$ROOT/work/agents/entrypoints/$relative"
  done
}

bootstrap() {
  local expected="${1:-success}"
  local result=success
  PATH="$CASE_DIR/bin:$PATH" bash "$ROOT/alethea-core/scripts/bootstrap.sh" "$ROOT" > "$CASE_DIR/output" 2>&1 || result=failure
  [[ "$result" == "$expected" ]] || fail "bootstrap: expected $expected, got $result (case $TEST_COUNT)"
}

snapshot() {
  for relative in "${ENTRYPOINTS[@]}" "$@"; do
    mkdir -p "$CASE_DIR/snapshot/$(dirname "$relative")"
    cp "$ROOT/$relative" "$CASE_DIR/snapshot/$relative"
  done
}

unchanged() {
  for relative in "${ENTRYPOINTS[@]}" "$@"; do
    cmp -s "$ROOT/$relative" "$CASE_DIR/snapshot/$relative" || fail "generated entrypoint changed unexpectedly: $relative"
  done
}

check() {
  local expected="${1:-success}" result=success
  bash "$ROOT/alethea-core/scripts/generate_entrypoints.sh" "$ROOT" --check > "$CASE_DIR/output" 2>&1 || result=failure
  [[ "$result" == "$expected" ]] || fail "check: expected $expected, got $result (case $TEST_COUNT)"
}

rejected_before_outputs() {
  rm -rf "$ROOT/alethea-knowledge/.git"
  check failure
  unchanged "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
  bootstrap failure
  unchanged "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
  if grep -Fq 'Unexpected Git invocation' "$CASE_DIR/output"; then fail "invalid entrypoints reached Git"; fi
  grep -Fq 'Entrypoint generation failed:' "$CASE_DIR/output" || fail "missing validation diagnostic"
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

setup
configure_entrypoints
check
[[ ! -e "$ROOT/.github" && ! -e "$ROOT/$MANIFEST" ]] || fail "check mode created outputs"
bootstrap
for relative in "${PRIVATE_ENTRYPOINTS[@]}"; do
  cmp -s "$ROOT/work/agents/entrypoints/$relative" "$ROOT/$relative" || fail "private entrypoint not installed verbatim: $relative"
done
cp "$ROOT/$MANIFEST" "$CASE_DIR/manifest"
snapshot
bootstrap
unchanged
cmp -s "$ROOT/$MANIFEST" "$CASE_DIR/manifest" || fail "manifest is not idempotent"
for relative in "${PRIVATE_ENTRYPOINTS[@]}"; do
  cmp -s "$ROOT/work/agents/entrypoints/$relative" "$ROOT/$relative" || fail "private entrypoint changed on repeat: $relative"
done
printf 'PASS: private native agent, slash prompt, command and skill install verbatim; check mode and idempotency\n'

setup
configure_entrypoints
bootstrap
snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
for relative in "${PRIVATE_ENTRYPOINTS[@]}"; do
  printf '\nUpdated synthetic entrypoint.\n' >> "$ROOT/work/agents/entrypoints/$relative"
done
check
unchanged "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
bootstrap
for relative in "${PRIVATE_ENTRYPOINTS[@]}"; do
  cmp -s "$ROOT/work/agents/entrypoints/$relative" "$ROOT/$relative" || fail "managed entrypoint not updated: $relative"
done
check
printf 'PASS: managed updates and read-only preflight\n'

setup
configure
configure_entrypoints
bootstrap
printf 'Unrelated user entrypoint.\n' > "$ROOT/.github/agents/unmanaged.agent.md"
snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST" .github/agents/unmanaged.agent.md
rm -rf "$ROOT/work"
check
unchanged "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST" .github/agents/unmanaged.agent.md
bootstrap
for relative in "${PRIVATE_ENTRYPOINTS[@]}"; do
  [[ ! -e "$ROOT/$relative" ]] || fail "managed entrypoint remains after detach: $relative"
done
for relative in "${ENTRYPOINTS[@]}"; do
  [[ -f "$ROOT/$relative" ]] || fail "canonical entrypoint removed on detach"
  if grep -Fq 'example_source/*' "$ROOT/$relative" || grep -Fq "$ROUTING" "$ROOT/$relative"; then fail "routing or tools remain after detach"; fi
done
cmp -s "$ROOT/.github/agents/unmanaged.agent.md" "$CASE_DIR/snapshot/.github/agents/unmanaged.agent.md" || fail "unmanaged sibling changed"
jq -e '.files == []' "$ROOT/$MANIFEST" >/dev/null
snapshot "$MANIFEST"
bootstrap
unchanged "$MANIFEST"
printf 'PASS: full detach removes only managed entries and is idempotent\n'

setup
configure_entrypoints
bootstrap
rm "$ROOT/work/agents/entrypoints/.github/prompts/example.prompt.md"
bootstrap
[[ ! -e "$ROOT/.github/prompts/example.prompt.md" ]] || fail "removed template was not detached"
cmp -s "$ROOT/.github/agents/example.agent.md" "$ROOT/work/agents/entrypoints/.github/agents/example.agent.md" || fail "retained entrypoint changed"
jq -e '.files | length == 3' "$ROOT/$MANIFEST" >/dev/null
rm "$ROOT/.github/agents/example.agent.md"
bootstrap
[[ -f "$ROOT/.github/agents/example.agent.md" ]] || fail "missing managed output was not restored"
rm "$ROOT/.github/agents/example.agent.md"
rm -rf "$ROOT/work/agents/entrypoints"
bootstrap
jq -e '.files == []' "$ROOT/$MANIFEST" >/dev/null
printf 'PASS: partial detach, missing output repair and missing output detach\n'

for action in update detach; do
  for changed in "${PRIVATE_ENTRYPOINTS[@]}"; do
    setup
    configure_entrypoints
    bootstrap
    printf '\nUser modification.\n' >> "$ROOT/$changed"
    snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
    if [[ "$action" == detach ]]; then
      rm -rf "$ROOT/work/agents/entrypoints"
    else
      printf '\nPending template update.\n' >> "$ROOT/work/agents/entrypoints/.github/agents/example.agent.md"
    fi
    rejected_before_outputs
    grep -Fq 'managed entrypoint modified' "$CASE_DIR/output" || fail "missing modification diagnostic"
  done
done
printf 'PASS: all four platforms preserve modified outputs during update and detach\n'

for content in identical different; do
  setup
  configure_entrypoints
  bootstrap
  snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
  source="$ROOT/work/agents/entrypoints/.github/prompts/unmanaged.prompt.md"
  cp "$ROOT/.github/prompts/example.prompt.md" "$source"
  cp "$source" "$ROOT/.github/prompts/unmanaged.prompt.md"
  if [[ "$content" == different ]]; then printf 'User content.\n' > "$ROOT/.github/prompts/unmanaged.prompt.md"; fi
  cp "$ROOT/.github/prompts/unmanaged.prompt.md" "$CASE_DIR/unmanaged"
  rejected_before_outputs
  cmp -s "$ROOT/.github/prompts/unmanaged.prompt.md" "$CASE_DIR/unmanaged" || fail "unmanaged file overwritten"
done
printf 'PASS: unmanaged entries are never adopted or overwritten, even with identical content\n'

for invalid in .github/agents/alethea.agent.md .claude/commands/alethea.md .agents/skills/alethea/SKILL.md \
  .github/agents/ALETHEA.agent.md .github/prompts/nested/example.prompt.md .agents/skills/example/extra.md \
  .github/agents/.hidden.agent.md .github/agents/example.txt $'.github/agents/line\nbreak.agent.md'; do
  setup
  configure_entrypoints
  bootstrap
  snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
  mkdir -p "$ROOT/work/agents/entrypoints/$(dirname "$invalid")"
  printf 'Invalid private entrypoint.\n' > "$ROOT/work/agents/entrypoints/$invalid"
  rejected_before_outputs
done
printf 'PASS: canonical collisions, unsupported paths and unsafe names rejected before outputs or clone\n'

for invalid in malformed traversal absolute canonical duplicate digest; do
  setup
  configure_entrypoints
  bootstrap
  case "$invalid" in
    malformed) printf '{invalid' > "$ROOT/$MANIFEST" ;;
    traversal|absolute|canonical)
      case "$invalid" in
        traversal) path=../outside ;;
        absolute) path="$CASE_DIR/outside" ;;
        canonical) path=.github/agents/alethea.agent.md ;;
      esac
      jq --arg path "$path" '.files[0].path = $path' "$ROOT/$MANIFEST" > "$CASE_DIR/manifest"
      cp "$CASE_DIR/manifest" "$ROOT/$MANIFEST" ;;
    duplicate)
      jq '.files += [.files[0]]' "$ROOT/$MANIFEST" > "$CASE_DIR/manifest"
      cp "$CASE_DIR/manifest" "$ROOT/$MANIFEST" ;;
    digest)
      jq '.files[0].sha256 = ("0" * 64)' "$ROOT/$MANIFEST" > "$CASE_DIR/manifest"
      cp "$CASE_DIR/manifest" "$ROOT/$MANIFEST" ;;
  esac
  printf 'Outside sentinel.\n' > "$CASE_DIR/outside"
  cp "$CASE_DIR/outside" "$CASE_DIR/sentinel"
  snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
  rejected_before_outputs
  cmp -s "$CASE_DIR/outside" "$CASE_DIR/sentinel" || fail "manifest escaped the workspace"
done
printf 'PASS: malformed, unsafe, duplicate and mismatching manifests fail closed\n'

for linked in work work/agents work/agents/entrypoints work/agents/entrypoints/.github \
  work/agents/entrypoints/.github/agents/example.agent.md .github .github/agents/example.agent.md \
  .github/agents/alethea.agent.md .alethea "$MANIFEST"; do
  setup
  configure_entrypoints
  bootstrap
  snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
  mv "$ROOT/$linked" "$CASE_DIR/link-target"
  ln -s "$CASE_DIR/link-target" "$ROOT/$linked"
  rejected_before_outputs
  [[ -L "$ROOT/$linked" ]] || fail "symlink was replaced"
done
printf 'PASS: source, destination, canonical and manifest symlinks are rejected\n'

setup
configure_entrypoints
bootstrap
snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
ln -s "$CASE_DIR/nonexistent" "$ROOT/work/agents/entrypoints/.github/prompts/dangling.prompt.md"
rejected_before_outputs
rm "$ROOT/work/agents/entrypoints/.github/prompts/dangling.prompt.md"
mkfifo "$ROOT/work/agents/entrypoints/.github/prompts/pipe.prompt.md"
rejected_before_outputs
printf 'PASS: dangling source symlinks and special files are rejected\n'

setup
configure_entrypoints
bootstrap
snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
ln -s "$CASE_DIR/nonexistent" "$ROOT/.github/prompts/dangling.prompt.md"
cp "$ROOT/.github/prompts/example.prompt.md" "$ROOT/work/agents/entrypoints/.github/prompts/dangling.prompt.md"
rejected_before_outputs
[[ -L "$ROOT/.github/prompts/dangling.prompt.md" && ! -e "$CASE_DIR/nonexistent" ]] || fail "dangling destination was followed"
printf 'PASS: dangling destination symlinks are rejected\n'

setup
configure_entrypoints
bootstrap
snapshot "${PRIVATE_ENTRYPOINTS[@]}" "$MANIFEST"
mkdir "$ROOT/.github/prompts/directory.prompt.md"
cp "$ROOT/.github/prompts/example.prompt.md" "$ROOT/work/agents/entrypoints/.github/prompts/directory.prompt.md"
rejected_before_outputs
[[ -z "$(ls -A "$ROOT/.github/prompts/directory.prompt.md")" ]] || fail "destination directory was written"
printf 'PASS: destination directories cannot be overwritten\n'

printf '%s tests passed.\n' "$TEST_COUNT"