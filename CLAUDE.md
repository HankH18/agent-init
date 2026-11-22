# agent-init

## What this is

Bash CLI (`bin/agent-init`) that scaffolds Claude Code and Codex CLI project config (`.agents/`, `.claude/`, `.codex/`, `AGENTS.md`, `CLAUDE.md`) from one shared `.agents/` source. Installed with `install.sh`; the only dependency is `jq`.

## Build & test

- `bash -n bin/agent-init && bash -n install.sh && bash -n setup-fork.sh`
- `shellcheck --severity=warning bin/agent-init install.sh setup-fork.sh` (CI adds an exclude list; see the workflow)
- CI: `.github/workflows/lint.yml` (ShellCheck, syntax check, and an init → doctor → sync smoke test)

## Topology

- `bin/agent-init` — the CLI: init, sync, doctor, migrate
- `install.sh`, `setup-fork.sh` — installer and fork setup
- `docs/MCP_REFERENCE.md` — MCP server reference
- `.github/workflows/lint.yml` — CI
