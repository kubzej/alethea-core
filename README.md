```text
 ▄▀█ █░░ █▀▀ ▀█▀ █░█ █▀▀ ▄▀█
 █▀█ █▄▄ ██▄ ░█░ █▀█ ██▄ █▀█
```

> **ἀλήθεια** · _aletheia_ — truth as **unconcealment**.
> Not facts stored, but knowledge brought out of hiding and kept from _lethe_, forgetting.

**Alethea Core** is the tooling, conventions, and agent layer of a filesystem-first
markdown knowledge system. Plain text is the durable artifact. The chat is not the
record — the files are.

---

## The idea

Raw material comes in. It gets disclosed into durable, curated knowledge.
Nothing survives only in a conversation.

```text
     raw/               wiki/sources/              wiki/
  ░░░░░░░░░   ───▶    ▒▒▒▒▒▒▒▒▒▒▒▒▒   ───▶    ▓▓▓▓▓▓▓▓▓▓▓
  concealed             provenance              unconcealed
   (lethe)                                       (aletheia)
```

The gradient is the point: material moves from hidden to disclosed.
`raw/` is disposable staging; `wiki/` is the record that lasts.

## What lives here

- architecture, lifecycle, and conventions docs
- markdown templates for source, wiki, and workspace pages
- bootstrap scripts that create or repair the expected filesystem shape
- shared specialist agent specs plus platform-specific entrypoints
- lightweight validation and inspection tooling, over time

## What does not

- durable knowledge content — that lives in `alethea-knowledge/`
- local workspace content — that lives in `work/`
- employer-specific names, integrations, source details, tool permissions, policies, and concrete work routing, including in examples and tests
- Obsidian-specific state as a required backend layer

## Workspace model

One umbrella workspace, three repos with clean boundaries:

```text
<alethea-root>/
  alethea-core/        tooling, docs, agent specs   ( this repo )
  alethea-knowledge/   git-synced durable knowledge
  work/                local-only work workspace
```

- `alethea-core/` — the system itself: how things are shaped and who does what
- `alethea-knowledge/` — the git-synced record; the truth that outlives sessions
- `work/` — local-only by design; leaves no trace in the synced repos

## Setup on a new machine

Requires Bash, Git, standard shell utilities, and `jq`.

```bash
mkdir ~/path/to/alethea
git clone https://github.com/kubzej/alethea-core.git ~/path/to/alethea/alethea-core
bash ~/path/to/alethea/alethea-core/scripts/bootstrap.sh
```

Bootstrap clones `alethea-knowledge`, creates the `work/` structure, and generates the
parent-level agent entrypoints so `/alethea` works when the `alethea/` folder is the IDE
workspace root.

Core templates remain employer-independent. Optional `work/agents/routing.md` and
`work/agents/entrypoint.json` supply local routing and additional Copilot tools;
`work/agents/contract.md` supplies local policy to shared specialists. These inputs
are never copied into core. Regenerate after attaching, changing, or removing the
local extension. See [Work agent convention](agents/shared/docs/work-orchestrator-convention.md).

Run the isolated bootstrap regression checks with `bash tests/bootstrap_test.sh`
from this repo. They use synthetic work fixtures, no real work sources or network.

## Start here

|              |                                                    |
| ------------ | -------------------------------------------------- |
| Architecture | [docs/architecture.md](docs/architecture.md)       |
| Lifecycle    | [docs/lifecycle.md](docs/lifecycle.md)             |
| Conventions  | [docs/conventions.md](docs/conventions.md)         |
| Agents       | [agents/shared/README.md](agents/shared/README.md) |
| Bootstrap    | [scripts/bootstrap.sh](scripts/bootstrap.sh)       |

---

<sub>Against forgetting.</sub>

```

```
