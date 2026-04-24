# Work Orchestrator Convention

This document defines how `work.*` sub-orchestrators are structured and managed. It is a conventions doc, not an agent spec.

## Naming

`work.<project-name>`

Use the project name as it appears in the repo or path — lowercase, no spaces.

Examples: `work.alpha`, `work.beta`

## Role

A `work.*` orchestrator is a thin bridge. It knows the project, its agents, and the knowledge boundary. It routes — it does not act.

## Knowledge boundary

All knowledge for a work project goes to:

```
alethea-knowledge/work/wiki/projects/<project-name>/
```

Never into `personal/`. Never scattered across ad hoc locations.

## Structure rules

- **Thin bridge only** — a `work.*` spec lists the project's own agents and routes to them; it defines no new agents itself
- **No shared agent layer** — work projects own their own agent definitions (in their own `.github/agents/` or equivalent); Alethea does not absorb them
- **Project path is explicit** — every `work.*` spec states the absolute path to the project repo
- **Delegation only** — the sub-orchestrator never directly edits project code or writes knowledge pages

## Lifecycle

- **Created** when active work on a project begins and routing is needed
- **Deleted** when the project ends or the user stops working on it — no archiving, no migration; the knowledge stays in `alethea-knowledge/work/`, the spec file disappears
- Deletion is clean by design: the spec is a thin pointer, not a content store

## How to add a new work orchestrator

1. Copy `agents/shared/templates/work.template.md` and rename it to `agents/shared/specs/work.<new-project>.md`
2. Update:
   - agent name (`work.<new-project>`)
   - project path
   - knowledge path
   - project agents table (from the project's `.github/agents/` or equivalent)
3. Add the spec to all three platform entrypoints under the work routing section:
   - `.claude/commands/alethea.md`
   - `.github/agents/alethea.agent.md`
   - `.agents/skills/alethea/SKILL.md`
4. Add the agent to `agents/shared/README.md` under "Work project orchestrators"

## How to remove a work orchestrator

1. Delete `agents/shared/specs/work.<project>.md`
2. Remove routing entries from all three platform entrypoints
3. Remove from `agents/shared/README.md`
4. Leave `alethea-knowledge/work/wiki/projects/<project>/` in place — knowledge outlives the orchestrator

## Ownership

`system.keeper` owns this convention and keeps it in sync with the platform entrypoints.
