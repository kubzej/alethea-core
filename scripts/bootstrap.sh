#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CORE_DIR="$ROOT/alethea-core"
KNOWLEDGE_DIR="$ROOT/alethea-knowledge"
WORK_DIR="$ROOT/work"

KNOWLEDGE_REPO="https://github.com/kubzej/alethea-knowledge.git"

ensure_dir() {
  mkdir -p "$1"
}

ensure_file() {
  if [ ! -f "$1" ]; then
    : > "$1"
  fi
}

generate_entrypoint() {
  local src="$1"
  local dst="$2"
  ensure_dir "$(dirname "$dst")"
  sed 's|agents/shared/|alethea-core/agents/shared/|g' "$src" > "$dst"
}

if [ "$(basename "$ROOT")" != "alethea" ]; then
  echo "Error: expected parent folder to be named 'alethea', got '$(basename "$ROOT")'."
  echo "Clone alethea-core into alethea/alethea-core/ and run bootstrap from there."
  exit 1
fi

echo "Alethea bootstrap — root: $ROOT"

# --- clone alethea-knowledge if missing ---
if [ ! -d "$KNOWLEDGE_DIR/.git" ]; then
  echo "Cloning alethea-knowledge..."
  git clone "$KNOWLEDGE_REPO" "$KNOWLEDGE_DIR"
else
  echo "alethea-knowledge already present, skipping clone."
fi

# --- alethea-core structure ---
ensure_dir "$CORE_DIR/docs"
ensure_dir "$CORE_DIR/templates"
ensure_dir "$CORE_DIR/scripts"
ensure_dir "$CORE_DIR/agents/shared"
ensure_dir "$CORE_DIR/.agents/skills"
ensure_dir "$CORE_DIR/.claude/commands"
ensure_dir "$CORE_DIR/.github/agents"

# --- alethea-knowledge structure ---
ensure_dir "$KNOWLEDGE_DIR/personal/raw"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/self"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/projects"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/knowledge"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/sources"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/indexes"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/discussions"
ensure_dir "$KNOWLEDGE_DIR/personal/workspace/research"
ensure_dir "$KNOWLEDGE_DIR/personal/workspace/plans"
ensure_dir "$KNOWLEDGE_DIR/personal/logs"
ensure_dir "$KNOWLEDGE_DIR/personal/schema"

# --- work structure ---
ensure_dir "$WORK_DIR/raw"
ensure_dir "$WORK_DIR/wiki/systems"
ensure_dir "$WORK_DIR/wiki/projects"
ensure_dir "$WORK_DIR/wiki/knowledge"
ensure_dir "$WORK_DIR/wiki/sources"
ensure_dir "$WORK_DIR/wiki/indexes"
ensure_dir "$WORK_DIR/workspace/research"
ensure_dir "$WORK_DIR/workspace/plans"
ensure_dir "$WORK_DIR/logs"
ensure_dir "$WORK_DIR/schema"
ensure_dir "$WORK_DIR/agents/specs"

ensure_file "$KNOWLEDGE_DIR/personal/logs/operations.md"
ensure_file "$WORK_DIR/logs/operations.md"

# --- parent-level entrypoints (generated, not versioned) ---
echo "Generating parent-level entrypoints..."

generate_entrypoint \
  "$CORE_DIR/.claude/commands/alethea.md" \
  "$ROOT/.claude/commands/alethea.md"

generate_entrypoint \
  "$CORE_DIR/.github/agents/alethea.agent.md" \
  "$ROOT/.github/agents/alethea.agent.md"

generate_entrypoint \
  "$CORE_DIR/.agents/skills/alethea/SKILL.md" \
  "$ROOT/.agents/skills/alethea/SKILL.md"

cp "$CORE_DIR/.agents/skills/alethea/agents/openai.yaml" \
   "$ROOT/.agents/skills/alethea/agents/openai.yaml" 2>/dev/null || true

cat > "$ROOT/.claude/CLAUDE.md" <<'EOF'
# Alethea

This is the Alethea workspace root. It contains three repos:

- `alethea-core/` — tooling, agent specs, templates, scripts
- `alethea-knowledge/` — git-synced personal knowledge
- `work/` — local-only work workspace

Use `/alethea` to start any Alethea task. Agent specs live in `alethea-core/agents/shared/specs/`.
EOF

echo "Done. Alethea scaffold ensured under: $ROOT"
