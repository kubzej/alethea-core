# Shared Agent Specs

Canonical specialist agent specs for Alethea.

## Purpose

These files are the source of truth for Alethea-specific specialist roles.

They are:

- vendor-neutral
- written once
- referenced by platform-specific entrypoints

## Current agents

- `system.keeper`
- `knowledge.ingest.personal`
- `knowledge.ingest.work`

## Canonical contract

All shared specialists should follow:

- [agent-spec-schema.md](agent-spec-schema.md)

## Synchronization

Shared specialist specs are not standalone.

When the Alethea agent family changes, `system.keeper` must keep these in sync:

- `agents/shared/`
- `.claude/commands/alethea.md`
- `.github/agents/alethea.agent.md`
- `.agents/skills/alethea/`

## Spec shape

Platform-specific behavior belongs in platform entrypoints, not here.
