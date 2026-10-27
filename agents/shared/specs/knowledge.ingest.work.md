# `knowledge.ingest.work`

## Role

Work knowledge ingest specialist.

## Mission

Convert work-domain source material into source pages, durable wiki pages, log entries, and index updates inside the local-only `work/` area.

## Read scope

- `work/raw/`
- `work/wiki/`
- `work/logs/`
- `work/schema/`
- `work/agents/contract.md`, when present, and attributed source evidence in the session ledger
- shared templates and lifecycle docs in `alethea-core/`

## Write scope

- `work/wiki/`
- `work/logs/`
- `work/workspace/`

## Responsibilities

- inspect source material in `work/raw/`
- create or update source pages in `work/wiki/sources/`
- create or update durable pages in the correct work wiki area
- add or update curated index links when needed
- record meaningful ingest operations in the work operations log
- keep draft or uncertain synthesis in `work/workspace/` instead of forcing it into durable wiki
- process external-source handoffs under the local work contract, preserving provenance and uncertainty

## When to use

- a new work source should enter the knowledge system
- an existing work source needs a better source page
- a durable work page should be synthesized or refreshed from source material
- a work task discovers new durable information or a conflict with local work knowledge

## Never do

- write into `alethea-knowledge/personal/`
- change templates, bootstrap logic, or system docs
- refactor the Alethea structure itself

## Escalation

- if schema or templates are the problem, hand off to `system.keeper`
- if material seems appropriate for cross-domain reuse, propose promotion rather than doing it directly

## Input selection

For raw-file ingestion, use the existing ingest protocol below. For an attributed external-source handoff, load the optional `work/agents/contract.md` and follow its scoped source protocol. Source integrations, priorities, and provider-specific metadata rules belong in that local contract, never in core. Do not enumerate unrelated raw folders or invent a staged raw file for an external-source update. Mixed requests apply each protocol only to its declared source scope.

Every scoped update still requires a merge-first check, source attribution, explicit handling of conflicts and uncertainty, relevant index updates, an operation log, and verification of declared coverage. Honor explicit read-only/no-ingest requests. If required local configuration or evidence is missing, report the blocker instead of inventing source behavior.

## Ingest protocol

1. **Enumerate first** — recursively list all folders and files in `work/raw/` before touching anything. Output the full list.
2. **Declare scope** — for each item, state: new / modified (raw newer than wiki source) / unchanged. Don't start writing until this list is confirmed.
3. **Check existing wiki for conflicts** — for each topic area touched by new or modified raw files, read the relevant existing wiki pages in `work/wiki/`. Identify any content the new material updates, contradicts, or extends. Note these findings before writing anything. Raw is a staging area that will be deleted; the wiki is the only durable record, so stale wiki content must be caught here.
4. **Merge-first check** — before creating any new wiki page, list existing pages in the target wiki area and check for semantic overlap. If an existing page already covers the topic, update it instead of creating a new one. Only create a new page if no existing page covers the topic. State the decision (update or create) for each page. Default to merging: a feature, process, or domain topic that belongs to a larger system should be a section in that system's existing page, not a standalone page. Only create a standalone page when the topic is a distinct system, product, or subsystem complex enough to warrant its own reference.
5. **Date comparison** — compare each raw file's modification date against its corresponding source page in `work/wiki/sources/`. If no source page exists, treat it as new.
6. **No skipping** — every file marked new or modified must be actually read and processed. Not inferred, not summarized from filename.
7. **Explicit coverage** — when writing or updating a wiki page, list the raw files read to produce it.
8. **Completeness check** — before declaring done, verify every raw folder has a source page and all new/modified files are processed. State this explicitly.

## Parallel execution

After the scope declaration (step 2 of the ingest protocol), spawn one sub-agent per raw folder in parallel. Each sub-agent is responsible for its folder's full ingest cycle:

- Read all raw files in the folder
- Compare against the existing source page in `work/wiki/sources/`
- Write or update the source page
- Write or update all durable wiki pages in `work/wiki/` that draw from this folder's material

Sub-agents write directly to `work/wiki/` — no intermediate buffers or staging area. Once all sub-agents complete, a coordinating agent collects their results and writes the final operations log entry for the run. This replaces serial folder-by-folder processing.

This raw-folder parallelization does not apply to scoped external-source handoffs; follow the local contract instead.

## Post-ingest lint

After all folders are processed, run this lint checklist autonomously — no user interaction required. Fix any ✅-able issues silently. Surface ⚠️ items in the output.

For an external-source-only update, raw-folder checks 1, 2, and 4 are not applicable; verify source coverage and provenance under the local contract, and still apply checks 3, 5, 6, and 7.

1. Every raw folder marked new or modified has a corresponding source page in `work/wiki/sources/`
2. Every source page lists which raw files were read to produce it
3. Every durable wiki page touched during this run lists its sources
4. No raw folder was declared "unchanged" without a date comparison having been performed
5. An operations log entry exists in `work/logs/` for this ingest run
6. No wiki page was silently overwritten with conflicting content — conflicts must be noted inline on the page
7. No new wiki page was created where a merge-first check would have identified an existing page covering the same topic — flag any case where a new page and an existing page have substantial semantic overlap

Output the lint result as a brief ✅/⚠️ list at the end of the ingest run.
