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

## Evolution rule

If a new agent cannot be described cleanly with this schema, fix the schema first instead of inventing an ad hoc format for one agent.
