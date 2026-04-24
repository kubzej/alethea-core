# Alethea Lifecycle

## Core rule

The system of record is:

1. raw source files
2. source pages describing those files
3. durable wiki pages synthesized from them

Chat history is not the source of truth.

## v1 ingest flow

1. Put source material into `raw/`.
2. Create or update a source page in `wiki/sources/`.
3. Synthesize durable knowledge into the target wiki folder.
4. Record the operation in `logs/operations.md`.
5. If the output needs to move across domains, do it through an explicit promote step.

## Workspace versus wiki

### `workspace/` is for

- active research
- rough synthesis
- ongoing plans
- temporary working notes

### `wiki/` is for

- durable conclusions
- reusable knowledge
- curated source summaries
- stable navigation

If something still feels draft-like, it belongs in `workspace/`.

## Cross-domain promotion rule

A curated destination domain should be promote-only.

That means:

- no direct ingest into the curated destination
- no direct drafting inside the curated destination wiki
- no `workspace/` in the curated destination

Content should first exist in an active domain, then move into the curated domain only after it has been cleaned up, generalized, and stripped of context that should not travel.

## Minimum metadata

### Source page

Required frontmatter:

```yaml
title:
type: source
source_file:
created:
updated:
status:
```

Recommended sections:

- `## Summary`
- `## Key Points`
- `## Limits`
- `## Links`

### Durable wiki page

Required frontmatter:

```yaml
title:
type:
created:
updated:
status:
```

Recommended sections:

- `## Summary`
- `## Details`
- `## Sources`
- `## Links`

### Workspace note or plan

Required frontmatter:

```yaml
title:
type: workspace-note
created:
updated:
status:
```

Recommended sections:

- `## Goal`
- `## Notes`
- `## Open Questions`
- `## Next`

## Logs and indexes

### Logs

`logs/operations.md` is append-only history for meaningful changes:

- source ingested
- wiki page created
- wiki page substantially updated
- content promoted across domains

### Indexes

`wiki/indexes/` is for curated navigation:

- home pages
- maps of content
- hand-written overviews

Indexes are allowed to be partly generated later, but in v1 they should remain understandable and editable by hand.
