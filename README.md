# Alethea Core

Core tooling, conventions, and bootstrap artifacts for the Alethea knowledge system.

## What lives here

- architecture and lifecycle docs
- markdown templates for source, wiki, and workspace pages
- bootstrap scripts for creating or repairing the expected filesystem shape
- shared Alethea specialist specs plus platform-specific entrypoints
- lightweight validation and inspection tooling over time

## What does not live here

- durable knowledge content
- local workspace content
- Obsidian-specific state as a required backend layer

## Workspace model

`Alethea` is one umbrella local workspace rooted at:

```text
<alethea-root>/
```

with these siblings:

```text
<alethea-root>/
  alethea-core/
  alethea-knowledge/
  work/
```

- `alethea-core/` is the tooling repo
- `alethea-knowledge/` is the git-synced knowledge repo
- `work/` is the local-only workspace root

## Setup on a new machine

```bash
mkdir ~/path/to/alethea
git clone https://github.com/kubzej/alethea-core.git ~/path/to/alethea/alethea-core
bash ~/path/to/alethea/alethea-core/scripts/bootstrap.sh
```

Bootstrap clones `alethea-knowledge`, creates the `work/` structure, and generates parent-level agent entrypoints so `/alethea` works when the `alethea/` folder is the IDE workspace root.

## Start here

- Architecture: [docs/architecture.md](docs/architecture.md)
- Lifecycle: [docs/lifecycle.md](docs/lifecycle.md)
- Conventions: [docs/conventions.md](docs/conventions.md)
- Agents: [agents/shared/README.md](agents/shared/README.md)
- Bootstrap: [scripts/bootstrap.sh](scripts/bootstrap.sh)
