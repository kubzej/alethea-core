# Alethea Architecture

## Goal

Build a filesystem-first markdown knowledge system where raw source files and generated markdown pages are the source of truth, with a hard boundary between syncable knowledge and local-only workspace material.

## Root layout

```text
<alethea-root>/
  alethea-core/
  alethea-knowledge/
    personal/
    shared/
  work/
```

## Boundary rules

- `alethea-core/` owns tooling, templates, docs, and bootstrap scripts.
- `alethea-knowledge/` is the git-synced knowledge repo.
- `work/` is local-only by design and should not rely on `.gitignore` as its main safety boundary.
- Obsidian is allowed as a client over the files, not as the system backend.

## Common domain primitives

Most domains use the same base primitives:

```text
<domain>/
  raw/
  wiki/
  logs/
  schema/
```

Some domains also include:

```text
<domain>/
  workspace/
```

Use `workspace/` only for domains that need active research and planning artifacts.

## Project-specific layout

This project currently uses these domain roots:

```text
alethea-knowledge/personal/
  raw/
  wiki/
  workspace/
  logs/
  schema/

alethea-knowledge/shared/
  raw/
  wiki/
  logs/
  schema/

work/
  raw/
  wiki/
  workspace/
  logs/
  schema/
```

## Why some domains omit `workspace/`

A domain that acts as a curated destination should not also act as an inbox. Draft work should happen in an active domain, then move into the curated domain only through an explicit promote step.

## Schema placement

Common rules live in `alethea-core`.

Domain-specific wiki taxonomy should live next to the domain in its local `schema/` folder. That keeps `alethea-core` generic while still allowing each domain to use its own top-level folders.

## Why v1 is intentionally small

- Keep the number of top-level wiki categories small.
- Keep draft work in `workspace/`, not in durable wiki categories.
- Add finer taxonomy only after repeated use proves it is worth the maintenance cost.
