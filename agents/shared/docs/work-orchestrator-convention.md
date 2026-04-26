# Work Agent Convention

This document defines how work agents are structured and managed. It is a conventions doc, not an agent spec.

## Two categories

### Project orchestrators (`project.<name>`)

Thin bridges to a specific work project's own agents.

- **Naming:** `project.<project-name>` — use the project name as it appears in the repo or path, lowercase, no spaces
- **Examples:** `project.sherlog`, `project.alpha`
- **Role:** knows the project path, knowledge path, and which project agents exist; routes to them; does not act
- **Location:** `work/agents/specs/project.<name>.md`

### Work specialists (`work.<capability>`)

Cross-cutting specialists for work-wide tasks — not tied to a specific project.

- **Naming:** `work.<capability>` — use a short, descriptive capability name
- **Examples:** `work.debug`
- **Role:** full specialist agent; executes the capability directly for any work context
- **Location:** `work/agents/specs/work.<capability>.md`

---

## Why work agents live in `work/`, not `alethea-core`

Work agent specs contain company-specific content (project paths, infra details, subscription names). They must not live in `alethea-core`, which is a personal repo that may be pushed publicly.

**All work agent specs go in:** `work/agents/specs/`

Alethea entrypoints reference them by name in routing rules only (no spec list entry).

---

## Knowledge boundary

All knowledge for a work project goes to:

```
alethea-knowledge/work/wiki/projects/<project-name>/
```

Never into `personal/`. Never scattered across ad hoc locations.

---

## Structure rules

- **Project orchestrators are thin bridges only** — list the project's own agents and route to them; define no new agents
- **No shared agent layer** — work projects own their own agent definitions (in their own `.github/agents/` or equivalent); Alethea does not absorb them
- **Project path is explicit** — every `project.*` spec states the absolute path to the project repo
- **Delegation only** — orchestrators never directly edit project code or write knowledge pages

---

## Lifecycle

- **Created** when active work begins and routing is needed
- **Deleted** when the project ends or the user stops working on it — no archiving, no migration; knowledge stays in `alethea-knowledge/work/`; spec file disappears
- Deletion is clean by design: the spec is a thin pointer, not a content store

---

## How to add a new project orchestrator

1. Create `work/agents/specs/project.<name>.md` (use existing project spec as template)
2. Fill in: agent name, project path, knowledge path, project agents table
3. Add routing rule to all three platform entrypoints (routing rule only — no spec list entry):
   - `.claude/commands/alethea.md`
   - `.github/agents/alethea.agent.md`
   - `.agents/skills/alethea/SKILL.md`

## How to add a new work specialist

1. Create `work/agents/specs/work.<capability>.md`
2. Add routing rule to all three platform entrypoints (routing rule only — no spec list entry):
   - `.claude/commands/alethea.md`
   - `.github/agents/alethea.agent.md`
   - `.agents/skills/alethea/SKILL.md`

## How to remove a work agent

1. Delete `work/agents/specs/<agent>.md`
2. Remove routing entries from all three platform entrypoints
3. Leave `alethea-knowledge/work/wiki/projects/<project>/` in place — knowledge outlives the agent

---

## Ownership

`system.keeper` owns this convention and keeps it in sync with the platform entrypoints.
