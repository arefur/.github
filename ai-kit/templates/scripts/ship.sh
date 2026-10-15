#!/usr/bin/env bash
# One command from "code works locally" to "merged when CI is green":
#   scripts/ship.sh "feat(auth): add Google login" [--draft] [--no-merge]
# Ships whatever is pending — uncommitted changes, commits already made locally (even on main), or both:
# checks → branch (if on main) → commit → push → PR → auto-merge (squash, commit title = message) → back to main.
set -euo pipefail
MSG="${1:-}"; shift || true
DRAFT=0; MERGE=1
for a in "$@"; do case "$a" in --draft) DRAFT=1; MERGE=0 ;; --no-merge) MERGE=0 ;; esac; done

die() { echo "✗ $*" >&2; exit 1; }
[ -n "$MSG" ] || die 'usage: scripts/ship.sh "feat(scope): what changed" [--draft] [--no-merge]'
echo "$MSG" | grep -Eq '^(feat|fix|chore|docs|refactor|perf|test|build|ci|style|revert)(\([a-z0-9._/-]+\))?!?: .{3,100}$' \
  || die "message must be Conventional Commits, e.g. feat(auth): add Google login"

cd "$(git rev-parse --show-toplevel)"
git fetch -q origin 2>/dev/null || true
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
DEFAULT=${DEFAULT:-main}
BASE="origin/$DEFAULT"; git rev-parse --verify -q "$BASE" >/dev/null || BASE=""

DIRTY=0; [ -n "$(git status --porcelain)" ] && DIRTY=1
AHEAD=0; [ -n "$BASE" ] && AHEAD=$(git rev-list --count "$BASE..HEAD")
[ "$DIRTY" = 1 ] || [ "$AHEAD" -gt 0 ] || die "nothing to ship: no changes and no unpushed commits"
[ "$DIRTY" = 0 ] && echo "ℹ no uncommitted changes — shipping $AHEAD local commit(s) already made"

# back on the default branch, in sync with GitHub, whatever happens after the push
finish() {
  git switch -q "$DEFAULT" 2>/dev/null && git pull -q --ff-only 2>/dev/null || true
  echo "↩ back on $DEFAULT"
}

# 1. checks (same as CI's first job)
if [ "${SKIP_CHECKS:-0}" != 1 ] && [ -f package.json ]; then
  echo "▶ typecheck / lint / test"
  npm run -s typecheck --if-present
  npm run -s lint --if-present
  npm run -s test --if-present
fi

# 2. branch: never ship from the default branch — move pending work (incl. local commits) to a new one
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "$DEFAULT" ] || [ "$BRANCH" = master ] || [ -z "$BRANCH" ]; then
  TYPE=${MSG%%[(:!]*}
  SLUG=$(echo "${MSG#*: }" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g' | cut -c1-40)
  BRANCH="$TYPE/$SLUG"
  git show-ref --verify -q "refs/heads/$BRANCH" && BRANCH="$BRANCH-$(date +%H%M%S)"
  git switch -c "$BRANCH"
  # the default branch goes back to the remote so it can't diverge (its local commits now live on $BRANCH)
  [ -n "$BASE" ] && git branch -f "$DEFAULT" "$BASE"
fi

# 3. commit uncommitted work (hooks run: secrets, formatting, message format)
if [ "$DIRTY" = 1 ]; then
  git add -A
  if git diff --cached --name-only | grep -Eq '(^|/)\.env($|\.)' && ! git diff --cached --name-only | grep -Eq '\.env\.example$'; then
    git reset -q; die ".env file staged — add it to .gitignore"
  fi
  git commit -m "$MSG"
fi

# 4. push (pre-push hook runs; checks already passed above)
SKIP_CHECKS=1 git push -u origin "$BRANCH"

# 5. PR + auto-merge
if ! command -v gh >/dev/null || ! gh auth status >/dev/null 2>&1; then
  echo "ℹ gh CLI not logged in — pushed $BRANCH; open the PR on GitHub."; finish; exit 0
fi
EXISTING=$(gh pr view "$BRANCH" --json url -q .url 2>/dev/null || true)
if [ -z "$EXISTING" ]; then
  BODY=$(printf '## What\n%s\n\n## Commits\n%s\n\n## Checks\n- [x] typecheck, lint, unit tests passed locally\n- [ ] CI green\n' \
    "$MSG" "$(git log --format='- %s' "${BASE:-HEAD~1}..HEAD" 2>/dev/null || echo "- $MSG")")
  ARGS=(--base "$DEFAULT" --head "$BRANCH" --title "$MSG" --body "$BODY")
  [ "$DRAFT" = 1 ] && ARGS+=(--draft)
  EXISTING=$(gh pr create "${ARGS[@]}")
fi
echo "✓ PR: $EXISTING"
if [ "$MERGE" = 1 ]; then
  # --subject keeps the squash commit Conventional even if a local commit message wasn't
  if gh pr merge "$BRANCH" --auto --squash --delete-branch --subject "$MSG" 2>/dev/null; then
    echo "✓ auto-merge on: it squash-merges by itself once CI (and the risk gate) pass"
  else
    echo "ℹ could not enable auto-merge — turn on Settings → General → 'Allow auto-merge' and add a branch ruleset with required checks"
  fi
else
  echo "ℹ --no-merge: review it, add the 'human-approved' label if the Risk gate asks, then: gh pr merge $BRANCH --squash --auto --subject \"$MSG\""
fi
finish
