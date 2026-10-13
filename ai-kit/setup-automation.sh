#!/usr/bin/env bash
# Git automation for a repo: commit hooks, scripts/ship.sh, /ship skill, auto-merge + risk gate, Dependabot.
#   curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-automation.sh | bash
# Never overwrites existing files (FORCE=1 to overwrite).
set -euo pipefail
BASE="${AI_KIT_BASE:-https://raw.githubusercontent.com/arefur/.github/main/ai-kit/templates}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
fetch() {
  if [ -e "$2" ] && [ "${FORCE:-0}" != 1 ]; then echo "skip  $2 (exists)"; return; fi
  mkdir -p "$(dirname "$2")"
  if [ -d "${AI_KIT_LOCAL:-/nonexistent}" ]; then cp "$AI_KIT_LOCAL/$1" "$2"; else curl -fsSL "$BASE/$1" -o "$2"; fi
  echo "write $2"
}
for f in .githooks/commit-msg .githooks/pre-commit .githooks/pre-push scripts/ship.sh \
         .claude/skills/ship/SKILL.md .github/workflows/auto-merge.yml .github/dependabot.yml \
         .github/workflows/release.yml release-please-config.json; do fetch "$f" "$f"; done
# release-please needs to know the current version
if [ ! -e .release-please-manifest.json ]; then
  VER=$( [ -f package.json ] && node -p "require('./package.json').version || '0.1.0'" || echo 0.1.0 )
  printf '{ ".": "%s" }\n' "$VER" > .release-please-manifest.json; echo "write .release-please-manifest.json ($VER)"
fi
chmod +x .githooks/* scripts/ship.sh
git config core.hooksPath .githooks
# make the hooks turn on for anyone who runs npm install
if [ -f package.json ]; then npm pkg set scripts.prepare="git config core.hooksPath .githooks || true" scripts.ship="bash scripts/ship.sh"; fi

if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
  if [ -n "$REPO" ]; then
    echo "▶ GitHub settings for $REPO"
    gh repo edit "$REPO" --enable-auto-merge --delete-branch-on-merge --enable-squash-merge >/dev/null && echo "  auto-merge + delete-branch-on-merge: on"
    gh label create automerge --color 0E8A16 --description "Merge automatically when checks pass" --repo "$REPO" 2>/dev/null || true
    gh label create human-approved --color D93F0B --description "Owner reviewed risky changes" --repo "$REPO" 2>/dev/null || true
    DEFAULT=$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)
    if ! gh api "repos/$REPO/rulesets" -q '.[].name' 2>/dev/null | grep -qx "protect-$DEFAULT"; then
      gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null <<JSON && echo "  ruleset protect-$DEFAULT: PR required, CI + risk gate required, no force-push"
{ "name": "protect-$DEFAULT", "target": "branch", "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" }, { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": false, "require_last_push_approval": false, "required_review_thread_resolution": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": false,
      "required_status_checks": [ { "context": "Typecheck, lint, unit tests" }, { "context": "Build + e2e (Playwright)" }, { "context": "Risk gate" } ] } }
  ] }
JSON
    fi
  fi
else
  echo "ℹ gh not logged in: enable 'Allow auto-merge' and add the ruleset by hand (see ai-kit/GIT-AUTOMATION.md)."
fi
echo
echo "Done. Ship work with:  npm run ship -- \"feat(scope): what changed\"   (or ask Claude: ship it)"
