#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CORE_DIR="$ROOT/alethea-core"
KNOWLEDGE_DIR="$ROOT/alethea-knowledge"
WORK_DIR="$ROOT/work"

ensure_dir() {
  mkdir -p "$1"
}

ensure_file() {
  if [ ! -f "$1" ]; then
    : > "$1"
  fi
}

ensure_dir "$CORE_DIR/docs"
ensure_dir "$CORE_DIR/templates"
ensure_dir "$CORE_DIR/scripts"
ensure_dir "$CORE_DIR/agents/shared"
ensure_dir "$CORE_DIR/.agents/skills"
ensure_dir "$CORE_DIR/.claude/commands"
ensure_dir "$CORE_DIR/.github/agents"

ensure_dir "$KNOWLEDGE_DIR/personal/raw"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/self"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/projects"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/knowledge"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/sources"
ensure_dir "$KNOWLEDGE_DIR/personal/wiki/indexes"
ensure_dir "$KNOWLEDGE_DIR/personal/workspace/research"
ensure_dir "$KNOWLEDGE_DIR/personal/workspace/plans"
ensure_dir "$KNOWLEDGE_DIR/personal/logs"
ensure_dir "$KNOWLEDGE_DIR/personal/schema"

ensure_dir "$KNOWLEDGE_DIR/shared/raw"
ensure_dir "$KNOWLEDGE_DIR/shared/wiki/knowledge"
ensure_dir "$KNOWLEDGE_DIR/shared/wiki/playbooks"
ensure_dir "$KNOWLEDGE_DIR/shared/wiki/sources"
ensure_dir "$KNOWLEDGE_DIR/shared/wiki/indexes"
ensure_dir "$KNOWLEDGE_DIR/shared/logs"
ensure_dir "$KNOWLEDGE_DIR/shared/schema"

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

ensure_file "$KNOWLEDGE_DIR/personal/logs/operations.md"
ensure_file "$KNOWLEDGE_DIR/shared/logs/operations.md"
ensure_file "$WORK_DIR/logs/operations.md"

echo "Alethea scaffold ensured under: $ROOT"
