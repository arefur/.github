#!/usr/bin/env bash
# Regenerates tool-specific instruction files from AGENTS.md. Run after editing AGENTS.md.
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f AGENTS.md ] || { echo "AGENTS.md not found"; exit 1; }
mkdir -p .github
{
  echo "<!-- GENERATED from AGENTS.md by ai-sync.sh. Do not edit here. -->"
  echo
  cat AGENTS.md
} > .github/copilot-instructions.md
[ -f CLAUDE.md ] || printf '@AGENTS.md\n' > CLAUDE.md
grep -q '^@AGENTS.md' CLAUDE.md || { printf '@AGENTS.md\n\n' | cat - CLAUDE.md > CLAUDE.md.tmp && mv CLAUDE.md.tmp CLAUDE.md; }
echo "Synced: .github/copilot-instructions.md, CLAUDE.md -> AGENTS.md"
