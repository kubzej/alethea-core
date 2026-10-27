# Alethea Core

This repo defines the Alethea system itself.

- Codex entrypoint: `.agents/skills/alethea/`
- Claude entrypoint: `.claude/commands/alethea.md`
- Copilot entrypoint: `.github/agents/alethea.agent.md`
- Keep boundaries between `alethea-core/`, `alethea-knowledge/`, and `work` explicit
- Do not treat this repo as the place for durable knowledge content
- Keep bootstrap and validation tooling in Bash with standard shell utilities and `jq`; do not introduce another runtime without explicit agreement
- Treat core as publishable: never add employer-specific names, systems, endpoints, repository paths, source content, tool identifiers, skills, policies, or concrete work routing, including in examples, tests, and generated artifacts
- Core may contain only the generic work framework and extension interface. Concrete configuration belongs in `work/agents/`; bootstrap merges it only into workspace entrypoints outside core
- Keep canonical work-routing slots empty. Never copy generated workspace entrypoints back into core
- Before publishing, check changed and staged files for work-specific content. Git identity/history changes require separate explicit authorization; source cleanup does not sanitize history
