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
- **Examples:** `work.inspect`, `work.report`
- **Role:** full specialist agent; executes the capability directly for any work context
- **Location:** `work/agents/specs/work.<capability>.md`

---

## Why work agents live in `work/`, not `alethea-core`

Work agent specs contain company-specific content (project paths, infra details, subscription names). They must not live in `alethea-core`, which is a personal repo that may be pushed publicly.

**All work agent specs go in:** `work/agents/specs/`

Concrete routing lives only in `work/agents/routing.md`. Bootstrap inserts it into local workspace entrypoints, never into the core templates or specialist list.

## Safety rule

Core must remain publishable and employer-independent at all times, not only after leaving a job. It may define the generic work boundary, scaffold, role interfaces, and local extension mechanism. It must not contain employer-specific names, services, endpoints, repository paths, source content, tool identifiers, skills, policies, or concrete work routing, including in examples and tests. Use synthetic fixtures only.

Keep the `work-routing` slots in all three core templates empty. Never copy a generated workspace entrypoint back into core. Generic references to the optional local contract are allowed; its contents stay in `work/`. Review changed and staged files before publishing. Cleaning source files does not remove historical Git metadata or previously committed content; history or identity changes need separate explicit authorization.

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

The work framework is permanent and job-independent: this document, the generic `knowledge.ingest.work` role, the `work/` scaffold, and the extension interface. Concrete work contents and configuration are private/local and must not be synced through core or personal knowledge.

### Local extension interface

- `work/agents/routing.md`: optional Markdown routing and handoff rules, inserted between the `work-routing` markers in all three generated workspace entrypoints. Do not include those markers in the input itself.
- `work/agents/entrypoint.json`: optional JSON object with a `tools` array of nonempty single-line strings. Only this key is accepted. Tools are added to the generated Copilot agent's base permissions and deduplicated; no other frontmatter is overridden.
- `work/agents/contract.md`: optional local operating policy loaded by shared specialists for work tasks. Provider-specific retrieval, source priority, and synchronization rules belong here or in local docs it references.

Paths in the local routing must be workspace-root relative. Bootstrap rewrites shared core paths before inserting the local routing, so already-qualified local references are preserved. No inputs means generic entrypoints with no job-specific routing or tools. A client other than Copilot needs its own local tool access setup; generated routing does not configure a server.

Bootstrap uses Bash, standard shell utilities, and `jq`. The core agent's `tools` field must be a JSON string array, which is also valid YAML; keep its `prettier-ignore` directive so formatting does not convert it into another YAML representation. Single-line and indented multiline JSON arrays are supported. Only this field is parsed and replaced; other frontmatter is preserved. Routing markers may be indented, but their slot must stay empty in core.

Configuration and all templates are validated and rendered in a temporary directory before writing any entrypoint or cloning a missing knowledge repository; invalid configuration stops generation. Repeated generation is idempotent and never writes work data into core. Bootstrap writes generated workspace entrypoints, so keep durable edits in the appropriate core template or local extension, not in generated copies. Run `bash tests/bootstrap_test.sh` from core to verify the extension boundary.

### Detach — leaving a job

1. With explicit user approval, remove or securely relocate the private work data and local extension. Never delete work knowledge automatically as part of a bootstrap.
2. Re-run `scripts/bootstrap.sh`. Missing local inputs remove previously generated work routing and tool additions; the generic scaffold is recreated.
3. Verify the three generated entrypoints no longer contain the detached routing or tools. Core requires no employer-specific edit or commit.

### Attach — new job or new PC

1. Run `scripts/bootstrap.sh` to create the generic scaffold.
2. Create private work specs in `work/agents/specs/`; start project orchestrators from `agents/shared/templates/project.template.md`.
3. Add concrete routing, tools, and operating policy to the local extension files above, not core. Configure and authenticate external clients locally without storing secrets in these files.
4. Re-run bootstrap and verify generated routing, tool permissions, and actual tool availability in the intended client.
5. Ingest work knowledge into `work/wiki/` through `knowledge.ingest.work` when requested or required by the local contract.

`system.keeper` owns both flows and the generic extension interface. Attaching or changing a job must not require employer-specific changes in core.

---

## How to add a new project orchestrator

1. Create `work/agents/specs/project.<name>.md` (use existing project spec as template)
2. Fill in: agent name, project path, knowledge path, project agents table
3. Add its routing rule to `work/agents/routing.md`, then re-run `scripts/bootstrap.sh`. Do not modify the core entrypoint slots.

## How to add a new work specialist

1. Create `work/agents/specs/work.<capability>.md`
2. Add its routing rule to `work/agents/routing.md`, then re-run `scripts/bootstrap.sh`. Keep concrete tool additions in `work/agents/entrypoint.json` only.

## How to remove a work agent

1. Delete `work/agents/specs/<agent>.md`
2. Remove its entries from the local routing and any unused local tool permissions, then re-run `scripts/bootstrap.sh`
3. Leave `work/wiki/projects/<project>/` in place — knowledge outlives the agent

---

## Ownership

`system.keeper` owns this convention and keeps it in sync with the platform entrypoints.
