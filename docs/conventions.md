# Alethea Conventions

## Markdown first

- Use plain markdown files as the durable artifact.
- Keep files readable outside any specific app.
- Avoid relying on Obsidian-only features as required infrastructure.

## Filenames

- Use lowercase kebab-case filenames.
- Prefer stable names over clever names.
- Keep filenames descriptive enough to be understandable in a terminal.

Examples:

- `how-i-think-about-tools.md`
- `tool-evaluation-workflow.md`
- `order-intake-overview.md`

## Linking

- Prefer relative markdown links that remain valid in plain files and in Obsidian.
- Use explicit file links over magic conventions.
- Do not depend on wiki-link syntax as the only supported format.

## Frontmatter

- Keep frontmatter minimal.
- Every page should have `title`, `type`, `created`, `updated`, and `status`.
- Add more fields only when they clearly reduce confusion or improve regeneration.

## Status values

Suggested v1 values:

- `draft`
- `active`
- `stable`
- `archived`

## Obsidian compatibility

Allowed:

- opening the vaults directly
- using graph view, backlinks, search, and manual editing
- keeping optional local `.obsidian/` state if useful

Not allowed as an architectural dependency:

- plugin-only data formats
- app-specific automation that becomes the source of truth
- required hidden state outside the markdown files
