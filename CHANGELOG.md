# Changelog

All notable changes to `agent-init` are documented here. The format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — 2026-05-14

Initial public release of `agent-init` as a separate project from `claude-init`. This is a ground-up redesign for cross-tool support; the `2.0.0` version number reflects its lineage from `claude-init` v1.x rather than two prior 1.x releases of `agent-init`.

### Added

- **Multi-agent support.** `--agent=claude|codex|both` flag selects which tool(s) to scaffold for. Default is `claude` for back-compat with the `claude-init` mental model.
- **Source-of-truth architecture.** `.agents/` directory is the canonical hand-edited source; `.claude/` and `.codex/` are generated artifacts. Edit one, sync both.
- **Cross-tool specialist IR.** Each specialist (planner, code-reviewer, test-runner, debugger) is defined once in `.agents/specialists/*.yaml` as a tool-agnostic intermediate representation. Renderers produce Claude's Markdown-with-frontmatter and Codex's TOML formats.
- **Independent per-tool model assignment.** Claude side uses Opus/Sonnet/Haiku tiers; Codex side uses gpt-5-pro/gpt-5.4/gpt-5.4-mini with reasoning effort (low/medium/high). Five presets per tool (`opus-heavy`/`pro-heavy`, `balanced`, `thrifty`, `minimal`, `haiku-runner`/`mini-runner`).
- **Shared hooks.** A single physical copy of `format.sh`, `danger-guard.sh`, and `test-on-stop.sh` lives in `.agents/hooks/` and is referenced from both tools' configs.
- **Cross-tool skills.** Three starter skills (`plan`, `review`, `ship`) live in `.agents/skills/<name>/SKILL.md`. Codex reads them via symlinks at `.codex/skills/<name>/`; Claude wraps them via thin `.claude/commands/<name>.md` pointers.
- **MCP unification.** Logical server list in `.agents/mcp.yaml` renders to both Claude (JSON / `claude mcp add` commands in `.claude/MCP_SETUP.md`) and Codex (TOML / `codex mcp add` commands in `.codex/MCP_SETUP.md`).
- **AGENTS.md as canonical project memory** with a one-line `@AGENTS.md` `CLAUDE.md` bridge for Claude Code (which does not natively read AGENTS.md as of May 2026).
- **New `sync` subcommand.** Re-renders `.claude/` and `.codex/` from `.agents/`. Always force-overwrites generated artifacts (since that's the user's intent in invoking `sync`).
- **New `doctor` subcommand.** Detects:
  - Missing source-of-truth files
  - Drift between `.agents/specialists/*.yaml` and the rendered `.claude/agents/*.md` / `.codex/agents/*.toml`
  - Broken or wrong-target symlinks in `.codex/skills/`
  - Missing `CLAUDE.md` `@AGENTS.md` bridge
  - Missing `.codex/auth.json` / `.claude/settings.local.json` in `.gitignore`
  - Oversized AGENTS.md (>250 lines warning)
  - Surfaces Codex trust-gate reminder
- **New `migrate` subcommand.** Upgrades a legacy `claude-init` project to the new v2 layout:
  - Promotes existing `CLAUDE.md` content to `AGENTS.md` (preserves user prose verbatim)
  - Installs the `@AGENTS.md` bridge as the new `CLAUDE.md`
  - Builds `.agents/` source of truth
  - Re-renders `.claude/` (and optionally `.codex/`) — backs up originals to `*.bak.<timestamp>`
- **Codex configuration extras** beyond what Claude Code supports:
  - Per-specialist `model_reasoning_effort` (low/medium/high)
  - Per-specialist `sandbox_mode` (read-only for planner/reviewer, workspace-write for test-runner/debugger)
  - `[features] codex_hooks = true`, `multi_agent = true` pinned in `.codex/config.toml`
- **Codex hooks file.** `.codex/hooks.json` mirrors Claude's `.claude/settings.json` hook config, pointing at the same `.agents/hooks/` scripts.
- **Cross-tool stdin parsing in hooks.** `format.sh` and `danger-guard.sh` extract file paths and commands from both Claude's and Codex's hook input JSON shapes (e.g., `.tool_input.file_path` vs `.tool_input.path` vs `.tool_input.files[]`).

### Configuration

- Config file location: `${XDG_CONFIG_HOME:-$HOME/.config}/agent-init/config`. Set via `agent-init --configure`.
- Config priority (highest first): CLI flags → env vars → config file → defaults.
- All Claude env vars renamed: `CLAUDE_INIT_*_MODEL` → `AGENT_INIT_*_MODEL`. New `AGENT_INIT_CODEX_*_MODEL` family for Codex side.

### Notes

- Codex CLI is a fast-moving target as of May 2026. Pinned feature flags (`codex_hooks`, `multi_agent`) insulate scaffolded projects from upstream churn. Re-run `agent-init sync` and check `agent-init doctor` after each Codex release.
- The danger-guard hook is defense-in-depth, not a hard boundary, on the Codex side — `PreToolUse` does not yet reliably fire for `apply_patch` and MCP tool calls (see [openai/codex#16732](https://github.com/openai/codex/issues/16732)).
- Subagent project-config has an open regression: [openai/codex#14579](https://github.com/openai/codex/issues/14579). The renderer pins specialist names in `[agents.<name>]` blocks in `.codex/config.toml` with explicit `config_file` paths, which is the documented workaround.

### Diff from `claude-init` v1.3.0

- Binary renamed: `claude-init` → `agent-init`. Run `agent-init migrate` inside a `claude-init`-scaffolded project to upgrade.
- `.claude/` is no longer hand-edited; edit `.agents/specialists/*.yaml` and run `agent-init sync`.
- Hook scripts moved from `.claude/hooks/` to `.agents/hooks/`. Both tools' configs now reference the same physical scripts.
- CLAUDE.md no longer holds project memory directly; it's a one-line bridge to AGENTS.md.
- New subcommands: `sync`, `doctor`, `migrate`.

[2.0.0]: https://github.com/HankH18/agent-init/releases/tag/v2.0.0