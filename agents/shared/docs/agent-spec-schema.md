# Alethea Agent Spec Schema

This file defines the canonical contract for Alethea-specific agents.

Every specialist agent in `agents/shared/specs/` should follow this shape so the system stays predictable as the agent family grows.

## Required sections

### 1. `Role`

One short line describing what the agent is.

### 2. `Mission`

What outcome the agent is responsible for.

This should describe the agent's job, not its implementation details.

### 3. `Read scope`

What the agent is allowed and expected to read.

This should be path-oriented whenever possible.

### 4. `Write scope`

What the agent is allowed to modify.

This is the strongest practical boundary in the spec.

If an agent should not write anywhere, say so explicitly.

### 5. `Responsibilities`

The concrete kinds of work the agent owns.

Use flat bullets. Each bullet should be something a user could reasonably expect the agent to do.

### 6. `When to use`

Typical triggers or request shapes that should route to this agent.

This section is mainly for root orchestrators and future maintainers.

### 7. `Never do`

Hard boundaries. These are not preferences.

Use this section to prevent agent drift into neighboring roles.

### 8. `Escalation` or `Delegation`

What to do when the task crosses this agent's boundary.

Use:

- `Escalation` when the agent should hand off to a different owner
- `Delegation` when the agent may remain the owner but sequence another role

## Optional sections

Beyond the eight required sections, a spec may add operational sections when the role genuinely needs them. These are allowed and should follow the naming below so specs stay comparable:

- `Protocol` — a numbered, ordered procedure the agent must follow (e.g. ingest agents' `Ingest protocol`, `knowledge.audit`'s `Audit protocol`). Use when correctness depends on doing steps in a fixed order.
- `Calibration` — how the agent adapts its behavior from stored context or past sessions (e.g. `discussion`, `investing`). Use for thinking-partner agents whose tone or depth must adjust to the user.
- `Parallel execution` — how the agent fans work out to sub-agents. Use only when parallelism is part of the contract, not an implementation detail.
- `Output format` — the exact shape of the agent's deliverable, when the format itself is load-bearing (e.g. `knowledge.audit`, `dev.audit`). Use when downstream consumers depend on a stable structure.
- `Post-run lint` / checklist — self-verification the agent runs before declaring done (e.g. ingest agents' `Post-ingest lint`).

Rules for optional sections:

- Add one only when the role needs it — do not pad a spec to look complete.
- Keep them operational, same as the required sections.
- If several specs grow the same optional section, that is a signal it may belong in a shared doc instead of being duplicated per spec.

## Style rules

- Keep the language operational, not aspirational.
- Prefer file and folder paths over vague references.
- Do not put platform-specific instructions in shared specialist specs.
- Do not describe tools or models unless they are essential to the role.
- Do not bury hard boundaries in prose; put them in `Write scope` and `Never do`.

## Boundary rules

- `system.keeper` owns the Alethea system itself.
- `system.keeper` owns synchronization between shared specialist specs and all platform root orchestrators.
- ingest agents own content creation inside their domains.
- root orchestrators route only and do not absorb specialist work.
- any new agent must have a boundary that is meaningfully different from existing agents.

## Session context ledger

The root orchestrator maintains a small conversational ledger for the current session and passes it with every specialist handoff. The ledger contains:

- sources already loaded, identified by path and relevant revision or state
- concise summaries of the loaded sources
- current task state, decisions, open questions, and pending work
- the communication-style guidance already loaded for the session

A specialist treats the ledger as the current-session context and must not reload a listed source by default. Re-read a source only when it changed, the ledger lacks a required detail, or context compaction may have discarded the loaded context. The ledger is handoff state in the conversation, not a new runtime store or durable knowledge artifact.

## Evolution rule

If a new agent cannot be described cleanly with this schema, fix the schema first instead of inventing an ad hoc format for one agent.
