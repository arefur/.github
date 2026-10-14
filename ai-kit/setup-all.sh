#!/usr/bin/env bash
# Everything for one repo, in the right order: rules → tests + CI/CD → security → git automation.
#   cd ~/Projects/<repo> && curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-all.sh | bash
set -euo pipefail
BASE="${AI_KIT_BASE_ROOT:-https://raw.githubusercontent.com/arefur/.github/main/ai-kit}"
run() { echo; echo "════ $1"; if [ -d "${AI_KIT_LOCAL_ROOT:-/nonexistent}" ]; then AI_KIT_LOCAL="$AI_KIT_LOCAL_ROOT/templates" bash "$AI_KIT_LOCAL_ROOT/$1"; else curl -fsSL "$BASE/$1" | bash; fi; }
run install.sh
run setup-testing.sh
run setup-security.sh      # must run before setup-automation so the ruleset requires the security checks
run setup-automation.sh
echo
echo "All set. Next: fill AGENTS.md placeholders (ask Claude), then:"
echo "  npm run security && npm run test && npm run ship -- \"ci: add AI rules, tests, security and automation\""
