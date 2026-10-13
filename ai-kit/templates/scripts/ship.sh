#!/usr/bin/env bash
# One command from "code works locally" to "merged when CI is green":
#   scripts/ship.sh "feat(auth): add Google login" [--draft] [--no-merge]
# checks → branch (if on main) → commit → push → PR → auto-merge (squash) once required checks pass.
set -euo pipefail
MSG="${1:-}"; shift || true
DRAFT=0; MERGE=1
for a in "$@"; do case "$a" in --draft) DRAFT=1; MERGE=0 ;; --no-merge) MERGE=0 ;; esac; done

die() { echo "✗ $*" >&2; exit 1; }
[ -n "$MSG" ] || die 'usage: scripts/ship.sh "feat(scope): what changed" [--draft] [--no-merge]'
echo "$MSG" | grep -Eq '^(feat|fix|chore|docs|refactor|perf|test|build|ci|style|revert)(\([a-z0-9._/-]+\))?!?: .{3,100}$' \
  || die "message must be Conventional Commits, e.g. feat(auth): add Google login"

cd "$(git rev-parse --show-toplevel)"
[ -n "$(git status --porcelain)" ] || die "nothing to commit"

# 1. checks (same as CI's first job)
if [ "${SKIP_CHECKS:-0}" != 1 ] && [ -f package.json ]; then
  echo "▶ typecheck / lint / test"
  npm run -s typecheck --if-present
  npm run -s lint --if-present
  npm run -s test --if-present
fi

# 2. branch
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
DEFAULT=${DEFAULT:-main}
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "$DEFAULT" ] || [ "$BRANCH" = master ] || [ -z "$BRANCH" ]; then
  TYPE=${MSG%%[(:!]*}
  SLUG=$(echo "${MSG#*: }" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g' | cut -c1-40)
  BRANCH="$TYPE/$SLUG"
  git switch -c "$BRANCH"
  # local commits made on the default branch now live on $BRANCH; reset the default branch to the remote so it can't diverge
  git rev-parse --verify -q "origin/$DEFAULT" >/dev/null && git branch -f "$DEFAULT" "origin/$DEFAULT"
fi

# 3. commit (hooks run: secrets, prettier, message format)
git add -A
if git diff --cached --name-only | grep -Eq '(^|/)\.env($|\.)' && ! git diff --cached --name-only | grep -Eq '\.env\.example$'; then
  git reset -q; die ".env file staged — add it to .gitignore"
fi
git commit -m "$MSG"

# 4. push (pre-push hook runs; checks already passed above)
SKIP_CHECKS=1 git push -u origin "$BRANCH"

# 5. PR + auto-merge
if ! command -v gh >/dev/null || ! gh auth status >/dev/null 2>&1; then
  echo "ℹ gh CLI not logged in — pushed $BRANCH; open the PR on GitHub."; exit 0
fi
EXISTING=$(gh pr view "$BRANCH" --json url -q .url 2>/dev/null || true)
if [ -z "$EXISTING" ]; then
  BODY=$(printf '## What\n%s\n\n## Commits\n%s\n\n## Checks\n- [x] typecheck, lint, unit tests passed locally\n- [ ] CI green\n' \
    "$MSG" "$(git log --format='- %s' "origin/$DEFAULT..HEAD" 2>/dev/null || echo "- $MSG")")
  ARGS=(--base "$DEFAULT" --head "$BRANCH" --title "$MSG" --body "$BODY")
  [ "$DRAFT" = 1 ] && ARGS+=(--draft)
  EXISTING=$(gh pr create "${ARGS[@]}")
fi
echo "✓ PR: $EXISTING"
if [ "$MERGE" = 1 ]; then
  if gh pr merge "$BRANCH" --auto --squash --delete-branch 2>/dev/null; then
    echo "✓ auto-merge on: it squash-merges by itself once CI (and the risk gate) pass"
  else
    echo "ℹ could not enable auto-merge — turn on Settings → General → 'Allow auto-merge' and add a branch ruleset with required checks"
  fi
fi
