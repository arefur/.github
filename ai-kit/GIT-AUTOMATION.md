# Git automation: commit → push → PR → merge → deploy

```
you / Claude / Copilot:  npm run ship -- "feat(invoice): add VAT line"
   │  local: typecheck + lint + tests ──✗──► stops, nothing committed
   │  hooks: conventional message ✓, no .env / API keys ✓, prettier ✓
   ▼
branch feat/add-vat-line ─► push ─► PR (auto body) ─► auto-merge ON
   ▼
GitHub: CI (typecheck, lint, unit, build, e2e) + Risk gate + Claude review
   │  all required checks green ──► squash-merge, branch deleted
   │  risky paths touched ──► waits until you add label "human-approved"
   ▼
main ─► CI ─► Deploy (Coolify) ─► health check
```

## Install (repo root, once per repo)
```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-automation.sh | bash
git add -A && git commit -m "ci: git automation" && git push
```
If `gh` is logged in on your Mac, the script also sets up GitHub for you:
- turns on "Allow auto-merge" and "delete branch on merge"
- creates the labels `automerge` and `human-approved`
- adds a ruleset on the default branch: PR required, no force-push, and three required checks (**Typecheck, lint, unit tests**, **Build + e2e (Playwright)**, **Risk gate**)

Optional: add a secret `AUTOMERGE_TOKEN` (a fine-grained PAT with Contents and Pull requests read/write). With it, merges that the bot starts (Dependabot, the `automerge` label) also trigger CI and Deploy on main. Without it, GitHub does not start workflows for the merge commit. PRs from `ship` are fine either way, because ship enables auto-merge as you.

## What runs where
| Piece | When | What it does |
|---|---|---|
| `.githooks/commit-msg` | every commit | rejects messages that are not Conventional Commits (`feat(auth): …`) |
| `.githooks/pre-commit` | every commit | blocks `.env*` files and API keys (Anthropic, GitHub, AWS, Slack, private keys); runs Prettier on staged files |
| `.githooks/pre-push` | every push | typecheck + unit tests (`SKIP_CHECKS=1 git push` to skip once) |
| `scripts/ship.sh` / `npm run ship` | when work is done | checks → branch (if on main) → commit → push → PR → `gh pr merge --auto --squash` |
| `.claude/skills/ship` | "ship it" in Claude Code | Claude writes the commit message, decides whether to use `--no-merge`, and runs ship.sh |
| `auto-merge.yml` → Risk gate | every PR | fails when migrations, auth, payments/billing/checkout, middleware, workflows, `.env*` or Docker files change, until a human adds `human-approved` |
| `auto-merge.yml` → Enable auto-merge | PR with label `automerge`, or Dependabot | Dependabot patch/minor updates merge by themselves; a major bump gets a comment and waits for you |
| `dependabot.yml` | Sunday 09:00 Dhaka | dependency PRs grouped into 1–2 a week |

Hooks turn on automatically after `npm install` (`prepare` script → `core.hooksPath .githooks`).

## Verified (fresh Next.js 15 repo with a local remote, `gh` stubbed)
| Test | Result |
|---|---|
| commit message "updated stuff" | ✅ rejected |
| staged `.env.local` | ✅ rejected |
| `sk-ant-…` key in code | ✅ rejected |
| `ship` with a bad message | ✅ stopped |
| `ship` with a type error | ✅ stopped, nothing committed |
| `ship` with the 2 failing invoice tests | ✅ stopped |
| fixed the bugs → `ship` | ✅ 20 tests passed → branch `fix/reject-nan-discount-and-fractional-paisa` pushed → `gh pr create` → `gh pr merge --auto --squash --delete-branch` |
| Risk gate regex on 12 paths | ✅ catches migrations, auth.ts, payments, checkout, middleware, workflows, .env.example, Dockerfile; ignores `AuthorCard.tsx` |
| actionlint + shellcheck | ✅ clean |
| bug found during testing | `eslint` was linting `coverage/` and `playwright-report/` (3,059 errors). `setup-testing.sh` now adds those folders to the ESLint ignores |

## Rules of thumb
- **Auto-merge is only as safe as your required checks.** Without the ruleset, `--auto` merges immediately. Keep the ruleset on.
- Keep PRs small, one concern each. Auto-merge plus a big PR means nobody really reviewed it.
- Want to look before merging? `npm run ship -- "…" --draft` (no auto-merge) or `--no-merge`.
