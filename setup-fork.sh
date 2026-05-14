#!/usr/bin/env bash
# setup-fork.sh — one-shot placeholder replacement for your fork of agent-init.
#
# Usage:
#   ./setup-fork.sh USERNAME            # defaults LICENSE name to USERNAME
#   ./setup-fork.sh USERNAME "Real Name"
#
# Idempotent: re-running detects already-substituted state.

set -euo pipefail

if [[ -t 1 ]]; then
  R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'; GR=$'\033[32m'; YL=$'\033[33m'; RD=$'\033[31m'
else
  R=""; B=""; D=""; GR=""; YL=""; RD=""
fi
ok()   { printf "${GR}✓${R}  %s\n" "$*"; }
warn() { printf "${YL}⚠${R}  %s\n" "$*"; }
die()  { printf "${RD}✗${R}  %s\n" "$*" >&2; exit 1; }

if [[ $# -lt 1 ]]; then
  cat <<EOF
Usage: $0 USERNAME [REAL_NAME]

  USERNAME    Your GitHub user or org (e.g. 'acme-corp', 'hank-dev')
  REAL_NAME   Name for the LICENSE copyright line (defaults to USERNAME)

Examples:
  $0 acme-corp
  $0 hank-dev "Hank Smith"
EOF
  exit 1
fi

USERNAME="$1"
REAL_NAME="${2:-$USERNAME}"

if [[ "$USERNAME" =~ [[:space:]/] ]]; then
  die "Username '$USERNAME' contains spaces or slashes. GitHub usernames don't allow these."
fi
[[ -z "$USERNAME" ]] && die "Username cannot be empty."

for required in install.sh README.md LICENSE CHANGELOG.md bin/agent-init; do
  [[ -f "$required" ]] || die "Expected file '$required' not found. Run this from the repo root."
done

# Detect already-substituted state. Exclude setup-fork.sh itself.
REMAINING=$(grep -rl "<YOUR-GITHUB-USERNAME>\|<YOUR NAME>" . 2>/dev/null \
              --include='*.sh' --include='*.md' --include='LICENSE' \
              --exclude='setup-fork.sh' || true)
if [[ -z "$REMAINING" ]]; then
  warn "No placeholders found — this fork has already been set up. Nothing to do."
  exit 0
fi

rewrite_file() {
  local file="$1" pattern="$2" replacement="$3" content
  content=$(<"$file") || die "Couldn't read $file"
  if [[ "$content" != *"$pattern"* ]]; then
    return 1
  fi
  content="${content//$pattern/$replacement}"
  printf "%s" "$content" > "$file" || die "Couldn't write $file"
  return 0
}

printf "\n${B}Setting up your fork${R}\n"
printf "  GitHub user/org : ${B}%s${R}\n" "$USERNAME"
printf "  LICENSE name    : ${B}%s${R}\n\n" "$REAL_NAME"

CHANGED=0
for file in install.sh README.md CHANGELOG.md; do
  if rewrite_file "$file" "<YOUR-GITHUB-USERNAME>" "$USERNAME"; then
    ok "$file ${D}— GitHub username substituted${R}"
    CHANGED=$((CHANGED + 1))
  fi
done

if rewrite_file "LICENSE" "<YOUR NAME>" "$REAL_NAME"; then
  ok "LICENSE ${D}— copyright name substituted${R}"
  CHANGED=$((CHANGED + 1))
fi

LEFTOVERS=$(grep -rl "<YOUR-GITHUB-USERNAME>\|<YOUR NAME>" . 2>/dev/null \
              --include='*.sh' --include='*.md' --include='LICENSE' \
              --exclude='setup-fork.sh' || true)
if [[ -n "$LEFTOVERS" ]]; then
  warn "Some placeholders remained — check these files manually:"
  printf '   %s\n' $LEFTOVERS
  exit 1
fi

printf "\n${GR}${B}Done.${R} Modified %d file(s).\n\n" "$CHANGED"
cat <<EOF
${B}Next steps:${R}
  ${D}1.${R}  Review the diffs:
        ${B}git diff${R}

  ${D}2.${R}  Initialize git and push:
        ${B}git init${R}
        ${B}git add -A${R}
        ${B}git commit -m "Initial release: agent-init v2.0.0"${R}
        ${B}gh repo create agent-init --public --source=. --remote=origin --push${R}

  ${D}3.${R}  Test the install one-liner:
        ${B}curl -fsSL https://raw.githubusercontent.com/$USERNAME/agent-init/main/install.sh | bash${R}

  ${D}4.${R}  (Optional) Tag a release:
        ${B}git tag v2.0.0 && git push --tags${R}
EOF
