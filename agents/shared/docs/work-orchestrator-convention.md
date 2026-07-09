# Work Agent Convention

This document defines how work agents are structured and managed. It is a conventions doc, not an agent spec.

## Two categories

### Project orchestrators (`project.<name>`)

Thin bridges to a specific work project's own agents.

- **Naming:** `project.<project-name>` — use the project name as it appears in the repo or path, lowercase, no spaces
- **Examples:** `project.alpha`, `project.beta`
- **Role:** knows the project path, knowledge path, and which project agents exist; routes to them; does not act
- **Location:** `work/agents/specs/project.<name>.md`

### Work specialists (`work.<capability>`)

Cross-cutting specialists for work-wide tasks — not tied to a specific project.

- **Naming:** `work.<capability>` — use a short, descriptive capability name
- **Examples:** `work.debug`, `work.activity.timeline`
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
work/wiki/projects/<project-name>/
```

This is the top-level, local-only `work/` domain — never `alethea-knowledge/` (which is the git-synced personal repo). Never into `personal/`. Never scattered across ad hoc locations.

---

## Structure rules

- **Project orchestrators are thin bridges only** — list the project's own agents and route to them; define no new agents
- **No shared agent layer** — work projects own their own agent definitions (in their own `.github/agents/` or equivalent); Alethea does not absorb them
- **Project path is explicit** — every `project.*` spec states the absolute path to the project repo
- **Delegation only** — orchestrators never directly edit project code or write knowledge pages

---

## Lifecycle

- **Created** when active work begins and routing is needed
- **Deleted** when the project ends or the user stops working on it — no archiving, no migration; knowledge stays in `work/wiki/`; spec file disappears
- Deletion is clean by design: the spec is a thin pointer, not a content store

---

## Work domain lifecycle (job change)

The section above is per-agent. This section is the whole-domain flow for changing jobs or moving to a new machine.

The work **framework** is permanent and job-independent — it stays whether or not there is a current job:

- this document
- the `knowledge.ingest.work` spec
- the `work/` scaffold that `bootstrap.sh` creates
- the generic `project.*` / `work.*` routing patterns described in the entrypoints

Only two things are job-specific and get attached or detached per job:

- the contents of `work/` — local-only and unversioned (specs, wiki, raw, logs)
- the concrete work-routing block in the three entrypoints, fenced by `<!-- work-routing:start -->` … `<!-- work-routing:end -->`

### Detach — leaving a job

1. `work/` is local-only and unversioned — it goes away with the machine or a manual delete. No git action. Confirm it is gone.
2. In `alethea-core`, delete everything **between** the `work-routing` markers in all three entrypoints (leave the two marker lines in place as an empty slot for the next job):
   - `.claude/commands/alethea.md`
   - `.github/agents/alethea.agent.md`
   - `.agents/skills/alethea/SKILL.md`
3. Re-run `scripts/bootstrap.sh` to regenerate the parent-level entrypoints.
4. Commit `alethea-core`. Core now carries no job-specific work references — only the generic framework.

Nothing else in `alethea-core` points at a specific job.

### Attach — new job or new PC

1. Run `scripts/bootstrap.sh` — recreates the `work/` scaffold and regenerates the parent entrypoints.
2. Create work agents in `work/agents/specs/` (local-only): `project.<name>.md` orchestrators and any `work.<capability>.md` specialists. Start from `agents/shared/templates/project.template.md`.
3. In `alethea-core`, add one routing line per work agent **inside** the `work-routing` markers of all three entrypoints. Routing lines only — never the specs themselves.
4. Re-run `scripts/bootstrap.sh` to regenerate the parent entrypoints.
5. Ingest work knowledge with `knowledge.ingest.work` into `work/wiki/`.
6. Commit the entrypoint changes in `alethea-core`.

`system.keeper` owns both flows and keeps the markers in sync across the three entrypoints.

---

## How to add a new project orchestrator

1. Create `work/agents/specs/project.<name>.md` (use existing project spec as template)
2. Fill in: agent name, project path, knowledge path, project agents table
3. Add routing rule to all three platform entrypoints, inside the `<!-- work-routing:start -->` … `<!-- work-routing:end -->` markers (routing rule only — no spec list entry):
   - `.claude/commands/alethea.md`
   - `.github/agents/alethea.agent.md`
   - `.agents/skills/alethea/SKILL.md`
   Then re-run `scripts/bootstrap.sh` to regenerate the parent-level entrypoints.

## How to add a new work specialist

1. Create `work/agents/specs/work.<capability>.md`
2. Add routing rule to all three platform entrypoints, inside the `<!-- work-routing:start -->` … `<!-- work-routing:end -->` markers (routing rule only — no spec list entry):
   - `.claude/commands/alethea.md`
   - `.github/agents/alethea.agent.md`
   - `.agents/skills/alethea/SKILL.md`
   Then re-run `scripts/bootstrap.sh` to regenerate the parent-level entrypoints.

## How to remove a work agent

1. Delete `work/agents/specs/<agent>.md`
2. Remove the routing entries from inside the `work-routing` markers in all three platform entrypoints, then re-run `scripts/bootstrap.sh`
3. Leave `work/wiki/projects/<project>/` in place — knowledge outlives the agent

---

## Ownership

`system.keeper` owns this convention and keeps it in sync with the platform entrypoints.
