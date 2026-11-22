# agent-init

> Opinionated, idempotent project scaffolding for AI coding agents — **Claude Code, OpenAI Codex CLI, or both** — with a shared source of truth so the two tools stay in sync automatically.

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/HankH18/agent-init/main/install.sh | bash

# Scaffold a project
cd my-project
agent-init --agent=both
```

That's it. You get `AGENTS.md` (canonical project memory), a `.agents/` source of truth, and rendered `.claude/` and `.codex/` directories pointing at the same hook scripts, the same skills, and the same specialist definitions.

---

## Why

If you use both Claude Code and Codex CLI on the same project, you've probably noticed:

- **Two project memory files** — `CLAUDE.md` and `AGENTS.md` — that drift apart
- **Two sub-agent systems** — `.claude/agents/*.md` (Markdown + YAML frontmatter) and `.codex/agents/*.toml` (TOML schema)
- **Two hook systems** — different config formats, but the actual scripts are identical
- **Two slash command systems** — Claude's `.claude/commands/` vs Codex's deprecated `~/.codex/prompts/` vs Codex's `.codex/skills/`
- **Two MCP config formats** — JSON for Claude, TOML for Codex

`agent-init` treats `.agents/` as a tool-agnostic source of truth, renders both tools' configs from it, and gives you `sync` and `doctor` subcommands to keep drift in check.

---

## What it sets up

```
your-project/
├── AGENTS.md                            # canonical project memory (<200 lines)
├── CLAUDE.md                            # one-line bridge: @AGENTS.md
├── .agents/                             # SOURCE OF TRUTH — hand-edit these
│   ├── specialists/
│   │   ├── planner.yaml                 # tool-agnostic spec for each specialist
│   │   ├── code-reviewer.yaml
│   │   ├── test-runner.yaml
│   │   └── debugger.yaml
│   ├── skills/
│   │   ├── plan/SKILL.md                # cross-tool skill format
│   │   ├── review/SKILL.md
│   │   └── ship/SKILL.md
│   ├── hooks/
│   │   ├── format.sh                    # polyglot post-edit formatter
│   │   ├── danger-guard.sh              # pre-bash safety net
│   │   └── test-on-stop.sh              # run tests when agent stops
│   └── mcp.yaml                         # logical MCP server list
│
├── .claude/                             # GENERATED — do not hand-edit
│   ├── settings.json                    # hooks config (refs .agents/hooks/*)
│   ├── agents/{planner,…}.md            # rendered from .agents/specialists/
│   ├── commands/{plan,review,ship}.md   # thin wrappers around .agents/skills/
│   └── MCP_SETUP.md                     # install commands for Claude
│
└── .codex/                              # GENERATED — do not hand-edit
    ├── config.toml                      # [features], [agents], [mcp_servers]
    ├── hooks.json                       # Pre/PostToolUse, Stop (refs .agents/hooks/)
    ├── agents/{planner,…}.toml          # rendered from .agents/specialists/
    ├── skills/{plan,review,ship}        # symlinks → .agents/skills/
    └── MCP_SETUP.md                     # install commands for Codex
```

**The big idea:** edit `.agents/`, run `agent-init sync`, and both tools see your changes.

---

## Quick start

```bash
# (Optional) Set global defaults once
agent-init --configure

# Initialize a project
cd ~/code/my-project
agent-init --agent=both              # Claude + Codex
agent-init --agent=claude            # Claude only (default if --agent omitted)
agent-init --agent=codex             # Codex only

# After editing .agents/specialists/*.yaml or .agents/skills/*/SKILL.md
agent-init sync                      # re-render .claude/ and .codex/

# Health check
agent-init doctor                    # detect drift, broken links, trust issues

# Upgrade an old claude-init project to the new layout
agent-init migrate --agent=both
```

---

## Specialist model assignment

Both tools get four specialists out of the box: **planner**, **code-reviewer**, **test-runner**, **debugger**. The system prompts are identical across tools (same logical IR in `.agents/specialists/*.yaml`), but **models are assigned independently per tool** because the cost/capability curves are different.

### Claude presets

Maps each specialist to Opus / Sonnet / Haiku.

| Preset         | planner | code-reviewer | test-runner | debugger |
|----------------|---------|---------------|-------------|----------|
| `opus-heavy`   | Opus    | Opus          | Opus        | Opus     |
| `balanced` ★   | Opus    | Opus          | Sonnet      | Opus     |
| `thrifty`      | Opus    | Sonnet        | Sonnet      | Sonnet   |
| `minimal`      | Sonnet  | Sonnet        | Sonnet      | Sonnet   |
| `haiku-runner` | Opus    | Opus          | Haiku       | Opus     |

```bash
agent-init --preset=thrifty
agent-init --planner=opus --reviewer=sonnet --test-runner=haiku --debugger=opus
```

### Codex presets

Maps each specialist to gpt-5-pro / gpt-5.4 / gpt-5.4-mini, with reasoning effort (low/medium/high).

| Preset        | planner       | code-reviewer | test-runner       | debugger       |
|---------------|---------------|---------------|-------------------|----------------|
| `pro-heavy`   | gpt-5-pro/h   | gpt-5-pro/h   | gpt-5-pro/h       | gpt-5-pro/h    |
| `balanced` ★  | gpt-5-pro/h   | gpt-5-pro/h   | gpt-5.4/m         | gpt-5-pro/h    |
| `thrifty`     | gpt-5-pro/h   | gpt-5.4/m     | gpt-5.4/m         | gpt-5.4/m      |
| `minimal`     | gpt-5.4/m     | gpt-5.4/m     | gpt-5.4/m         | gpt-5.4/m      |
| `mini-runner` | gpt-5-pro/h   | gpt-5-pro/h   | gpt-5.4-mini/l    | gpt-5-pro/h    |

```bash
agent-init --agent=both --preset=balanced --codex-preset=mini-runner
agent-init --codex-planner=gpt-5-pro --codex-test-runner=gpt-5.4-mini
```

### Configuration priority (highest wins)

1. CLI flags (`--planner=opus`, `--codex-preset=mini-runner`)
2. Environment variables (`AGENT_INIT_PLANNER_MODEL`, `AGENT_INIT_CODEX_PLANNER_MODEL`, etc.)
3. Config file (`~/.config/agent-init/config` — set via `--configure`)
4. Built-in defaults (the `balanced` preset for both tools)

---

## Subcommands

| Command               | What it does |
|-----------------------|--------------|
| `agent-init`          | Initialize a fresh project (creates `.agents/`, renders `.claude/` and/or `.codex/`) |
| `agent-init sync`     | Re-render `.claude/` and `.codex/` from `.agents/` — always force-overwrites |
| `agent-init doctor`   | Drift detection for specialist files (.claude/agents, .codex/agents) against .agents/specialists; broken symlinks; gitignore sanity; Codex trust gate reminder |
| `agent-init migrate`  | Upgrade a legacy `claude-init` project: promote `CLAUDE.md` to `AGENTS.md`, install bridge, build `.agents/`, re-render. Customized `.claude/agents/*.md` are backed up and re-baselined from defaults, not imported. |

Common flags work across all subcommands: `--agent=`, `--force`, `--dry-run`, `--quiet`.

---

## What's included out of the box

**Specialists** (in both tools):
- `planner` — decomposes complex tasks; read-only; never writes code
- `code-reviewer` — reviews diffs for correctness, security, missing tests; read-only
- `test-runner` — runs tests, returns tight failure summaries; saves context
- `debugger` — reproduces, isolates, fixes; one bug per session

**Skills / slash commands:**
- `/plan` — invoke the planner specialist for a feature request
- `/review` — review uncommitted changes
- `/ship` — test then commit (no push)

**Hooks:**
- `format.sh` — post-edit polyglot formatter (Prettier/Biome, Ruff/Black, gofmt, rustfmt, terraform fmt, shfmt, rubocop)
- `danger-guard.sh` — pre-bash blocker for `rm -rf /`, `git push --force main`, `DROP DATABASE`, etc.
- `test-on-stop.sh` — runs the project test suite on stop; loops the agent back if tests fail

**Stack detection** auto-detects Node/TypeScript, Python, Rust, Go, Ruby, PHP, JVM, Terraform, Serverless, Docker — and writes appropriate test/build/lint commands into `AGENTS.md`.

**MCP reference** — `.agents/mcp.yaml` lists 5 starter servers (GitHub, Context7, Postgres, Playwright, Sentry); the renderers produce copy-paste install commands in both `.claude/MCP_SETUP.md` (JSON / `claude mcp add`) and `.codex/MCP_SETUP.md` (TOML / `codex mcp add`). A longer server reference is in [docs/MCP_REFERENCE.md](docs/MCP_REFERENCE.md).

---

## Hot-swap between agents

```bash
# Start with Claude only
agent-init --agent=claude

# Months later, decide to add Codex — just re-run
agent-init --agent=both

# .claude/ is preserved unchanged; .codex/ is added, sharing the same .agents/ source of truth
```

`agent-init` is fully idempotent. Re-running with the same flags is a no-op. Re-running with different `--agent` values adds the missing tool's tree without disturbing the other.

---

## The Codex trust gate

Codex CLI requires explicit trust before loading project-scoped `.codex/` config (including hooks and MCP servers). After `agent-init --agent=codex` or `--agent=both`:

```bash
codex   # accept the trust prompt the first time
```

`agent-init doctor` will remind you about this.

---

## Cross-tool fidelity notes

Things that are **mirrored cleanly** between Claude and Codex:
- Project memory (AGENTS.md is canonical; CLAUDE.md is a `@AGENTS.md` bridge — see "Why no symlink" below)
- Specialist definitions (Codex's TOML supports a strict superset of Claude's frontmatter)
- Skills (the SKILL.md format works in both)
- Hook scripts (identical shell scripts referenced from both tools' configs)
- MCP servers (rendered from `.agents/mcp.yaml`)

Things that **degrade gracefully**:
- Codex's `PreToolUse`/`PostToolUse` hooks have incomplete coverage for `apply_patch` and MCP tool calls (as of May 2026, [openai/codex#16732](https://github.com/openai/codex/issues/16732)) — Bash is the only reliable matcher. Don't rely on `danger-guard.sh` as a hard boundary.
- Claude Code does not natively read AGENTS.md as of May 2026. `agent-init` writes a one-line `CLAUDE.md` (`@AGENTS.md`) that imports it via Claude's `@`-syntax. If Anthropic ships native AGENTS.md support, this bridge becomes unnecessary.

### Why no symlink CLAUDE.md → AGENTS.md?

Symlinks work, but `@AGENTS.md` is more robust:
- Works on Windows without symlink permission tweaks
- Survives platforms that flatten symlinks (some Docker volume drivers, some CI checkout actions)
- Allows Claude-specific extras *below* the import line

---

## Configuration file

`agent-init --configure` writes a global config to `~/.config/agent-init/config`:

```ini
agent=both

# Claude specialists
planner=opus
reviewer=opus
test-runner=sonnet
debugger=opus

# Codex specialists
codex-planner=gpt-5-pro
codex-reviewer=gpt-5-pro
codex-test-runner=gpt-5.4
codex-debugger=gpt-5-pro

# Codex reasoning effort
codex-planner-effort=high
codex-reviewer-effort=high
codex-test-runner-effort=medium
codex-debugger-effort=high
```

Per-project, override with CLI flags or env vars (`AGENT_INIT_PLANNER_MODEL=sonnet agent-init`).

---

## Forking and customizing

`setup-fork.sh` is a one-shot helper for downstream forks — it substitutes the GitHub-username and copyright-name placeholders in `install.sh`, `README.md`, `LICENSE`, and `CHANGELOG.md`:

```bash
git clone https://github.com/HankH18/agent-init my-fork
cd my-fork
./setup-fork.sh my-github-handle "My Real Name"
git diff
gh repo create agent-init --public --source=. --push
```

---

## Comparison with `claude-init`

`agent-init` is a sibling project. The key differences:

| | claude-init | agent-init |
|---|---|---|
| Target agents | Claude Code only | Claude Code, Codex CLI, or both |
| Project memory | CLAUDE.md (canonical) | AGENTS.md (canonical) + CLAUDE.md bridge |
| Source of truth | `.claude/` (hand-edited) | `.agents/` (tool-agnostic IR) |
| Sync subcommand | — | `agent-init sync` |
| Drift detection | — | `agent-init doctor` |
| Migration | — | `agent-init migrate` |

`claude-init` (Claude-only, v1.3.0) is superseded; `agent-init --agent=claude` produces the Claude-only setup and `agent-init migrate` upgrades old projects. If you use both — or want the option — use `agent-init`.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Acknowledgments

- The cross-tool [AGENTS.md](https://agents.md/) standard, stewarded by the Agentic AI Foundation
- OpenAI's [Codex CLI](https://developers.openai.com/codex/cli) docs and changelog
- Anthropic's [Claude Code](https://docs.claude.com/en/docs/claude-code) docs
- Patterns borrowed from [SSW Rules on AGENTS.md symlinks](https://www.ssw.com.au/rules/symlink-agents-to-claude), [kau.sh aikado pattern](https://kau.sh/blog/agents-md/), and the [Kedro AGENTS.md rollout](https://github.com/kedro-org/kedro/issues/5408)