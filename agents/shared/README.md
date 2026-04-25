# Shared Agent Specs

Canonical specialist agent specs for Alethea.

## Purpose

These files are the source of truth for Alethea-specific specialist roles.

They are:

- vendor-neutral
- written once
- referenced by platform-specific entrypoints

## Structure

```
agents/shared/
├── specs/         ← all agent specs
├── templates/     ← reusable templates for creating new specs
└── docs/          ← system docs (schema, conventions, shared context)
```

## specs/

All specialist agent specs:

- `system.keeper`
- `knowledge.ingest.personal`
- `knowledge.ingest.work`
- `discussion`
- `investing`
- `dev.plan`
- `dev.build`
- `dev.explore`
- `dev.review`
- `dev.architect`
- `dev.test`

### Work agents

Work agents live in `work/agents/specs/` (private repo) — not in this directory. Two categories:

- **`project.<name>`** — project orchestrators, thin bridges to a specific work project's own agents
- **`work.<capability>`** — cross-cutting work specialists (e.g. `work.debug`)

See [docs/work-orchestrator-convention.md](docs/work-orchestrator-convention.md) for the full convention: naming, lifecycle, how to add and remove.

## templates/

Reusable templates for creating new specs:

- `work.template.md` — starting point for new `work.*` orchestrator specs

## docs/

System docs shared across the agent layer:

- `agent-spec-schema.md` — canonical contract all shared specialists must follow
- `user-communication-style.md` — how to communicate with the user; loaded by all agents on all platforms
- `work-orchestrator-convention.md` — naming, lifecycle, and management rules for `work.*` orchestrators

## Synchronization

Shared specialist specs are not standalone.

When the Alethea agent family changes, `system.keeper` must keep these in sync:

- `agents/shared/specs/`
- `.claude/commands/alethea.md`
- `.github/agents/alethea.agent.md`
- `.agents/skills/alethea/`

## Spec shape

Platform-specific behavior belongs in platform entrypoints, not here.
