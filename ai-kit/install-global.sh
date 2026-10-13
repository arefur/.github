#!/usr/bin/env bash
# One-time, on your Mac: personal rules for Claude Code + Antigravity. Never overwrites.
set -euo pipefail
BASE="${AI_KIT_BASE:-https://raw.githubusercontent.com/arefur/.github/main/ai-kit}"
put() { [ -e "$2" ] && { echo "skip  $2 (exists)"; return; }; mkdir -p "$(dirname "$2")"; curl -fsSL "$BASE/$1" -o "$2"; echo "write $2"; }
put global/CLAUDE.md "$HOME/.claude/CLAUDE.md"
put global/GEMINI.md "$HOME/.gemini/GEMINI.md"
echo "VS Code/Antigravity: merge ai-kit/vscode/settings.json into your user settings (Cmd+Shift+P → 'Open User Settings (JSON)')."
