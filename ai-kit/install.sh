#!/usr/bin/env bash
# A M Soft BD — AI rules kit installer. Run inside any repo:
#   curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/install.sh | bash
# Never overwrites existing files (use FORCE=1 to overwrite).
set -euo pipefail
BASE="${AI_KIT_BASE:-https://raw.githubusercontent.com/arefur/.github/main/ai-kit/templates}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
NAME="$(basename "$ROOT")"
PM=npm; [ -f pnpm-lock.yaml ] && PM=pnpm; [ -f yarn.lock ] && PM=yarn; [ -f bun.lockb ] && PM=bun

fetch() { # src dest
  if [ -e "$2" ] && [ "${FORCE:-0}" != 1 ]; then echo "skip  $2 (exists)"; return; fi
  mkdir -p "$(dirname "$2")"
  if [ -d "${AI_KIT_LOCAL:-/nonexistent}" ]; then cp "$AI_KIT_LOCAL/$1" "$2"; else curl -fsSL "$BASE/$1" -o "$2"; fi
  echo "write $2"
}

fetch AGENTS.md AGENTS.md
sed -i.bak -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{PM}}/$PM/g" AGENTS.md && rm -f AGENTS.md.bak
fetch CLAUDE.md CLAUDE.md
fetch .claude/settings.json .claude/settings.json
fetch .agents/rules/project.md .agents/rules/project.md
fetch ai-sync.sh ai-sync.sh && chmod +x ai-sync.sh
bash ai-sync.sh
grep -q '^\.claude/settings.local.json' .gitignore 2>/dev/null || echo '.claude/settings.local.json' >> .gitignore
echo
echo "Done. Now open AGENTS.md and fill the {{...}} placeholders (or ask Claude: 'fill AGENTS.md placeholders from this codebase'), then run: bash ai-sync.sh"
