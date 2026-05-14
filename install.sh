#!/usr/bin/env bash
# install.sh — one-line installer for agent-init
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/HankH18/agent-init/main/install.sh | bash
#
# Optional environment overrides:
#   AGENT_INIT_REPO    — owner/repo (default: HankH18/agent-init)
#   AGENT_INIT_BRANCH  — branch or tag (default: main)
#   AGENT_INIT_PREFIX  — install dir (default: $HOME/.local/bin)
#
# Examples:
#   # Install from a fork
#   AGENT_INIT_REPO=acme/agent-init curl -fsSL .../install.sh | bash
#
#   # Pin to a specific tag
#   AGENT_INIT_BRANCH=v2.0.0 curl -fsSL .../install.sh | bash

set -euo pipefail

REPO="${AGENT_INIT_REPO:-HankH18/agent-init}"
BRANCH="${AGENT_INIT_BRANCH:-main}"
PREFIX="${AGENT_INIT_PREFIX:-$HOME/.local/bin}"
DEST="$PREFIX/agent-init"
URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/bin/agent-init"

if [[ -t 2 ]]; then
  R=$'\033[0m'; B=$'\033[1m'; GR=$'\033[32m'; YL=$'\033[33m'; RD=$'\033[31m'
else
  R=""; B=""; GR=""; YL=""; RD=""
fi
say()  { printf "%s\n" "$*" >&2; }
ok()   { printf "${GR}✓${R}  %s\n" "$*" >&2; }
warn() { printf "${YL}⚠${R}  %s\n" "$*" >&2; }
die()  { printf "${RD}✗${R}  %s\n" "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required."
command -v bash >/dev/null 2>&1 || die "bash is required."

# Structural check (substitution-proof): repo must be owner/repo format
if [[ "$REPO" != */* || "$REPO" == \<* || "$REPO" == *\>* ]]; then
  die "Invalid repo '$REPO'. Expected 'owner/repo' format. Run setup-fork.sh from the repo root to substitute placeholders, or set AGENT_INIT_REPO=owner/repo."
fi

say ""
say "${B}agent-init installer${R}"
say "  source: $URL"
say "  target: $DEST"
say ""

mkdir -p "$PREFIX"
if ! curl -fsSL "$URL" -o "$DEST.tmp"; then
  die "Download failed. Check that $REPO exists and the branch '$BRANCH' has bin/agent-init."
fi

if ! head -n 1 "$DEST.tmp" | grep -q '^#!/usr/bin/env bash'; then
  rm -f "$DEST.tmp"
  die "Downloaded file doesn't look like a bash script. Aborting."
fi

mv "$DEST.tmp" "$DEST"
chmod +x "$DEST"
ok "Installed to $DEST"

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *)
    warn "$PREFIX is not on your PATH."
    say ""
    say "  Add this to your shell rc (~/.zshrc, ~/.bashrc, etc.):"
    say "    ${B}export PATH=\"$PREFIX:\$PATH\"${R}"
    say ""
    say "  Then reload: ${B}source ~/.zshrc${R}  (or restart your terminal)"
    say ""
    ;;
esac

if "$DEST" --help >/dev/null 2>&1; then
  ok "Verified: $DEST --help works"
fi

say ""
say "${GR}${B}Done.${R}"
say ""
say "Next:"
say "  ${B}agent-init --configure${R}            # (optional) set global model defaults"
say "  ${B}cd /path/to/project${R}               # then..."
say "  ${B}agent-init --agent=both${R}           # initialize for both Claude and Codex"
say ""
say "Subcommands:"
say "  ${B}agent-init${R}                        initialize a project"
say "  ${B}agent-init sync${R}                   re-render .claude/ and .codex/ from .agents/"
say "  ${B}agent-init doctor${R}                 detect drift, broken links, trust issues"
say "  ${B}agent-init migrate${R}                upgrade a legacy claude-init project"
say ""
say "Help: ${B}agent-init --help${R}"
say "Docs: https://github.com/$REPO"
say ""