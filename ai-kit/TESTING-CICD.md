# Testing + CI/CD kit (Next.js / TypeScript)

## 1. Install in any repo (repo root, once)

```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/install.sh | bash        # AGENTS.md rules (if not done yet)
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-testing.sh | bash  # tests + CI/CD
git add -A && git commit -m "chore: testing + CI/CD kit" && git push
```

What it adds (never overwrites existing files; `FORCE=1` to overwrite):

| Layer | Tool | Files | Command |
|---|---|---|---|
| Unit / logic | Vitest | `vitest.config.mts`, `vitest.setup.ts`, `tests/unit/example.test.ts` | `npm run test` · `test:watch` · `test:coverage` |
| Component | Testing Library + user-event (jsdom) | `tests/unit/example-component.test.tsx` | same |
| End-to-end | Playwright (desktop Chrome + Pixel 7) | `playwright.config.ts`, `tests/e2e/smoke.spec.ts` | `npm run test:e2e` · `test:e2e:ui` |
| Types | tsc | — | `npm run typecheck` |
| CI | GitHub Actions | `.github/workflows/ci.yml` | every PR + push to main |
| CD | Coolify webhook | `.github/workflows/deploy.yml` | after CI passes on main |
| AI review | Claude Code Action | `.github/workflows/claude-review.yml` | every PR + `@claude` comments |
| Test-case design | Claude skills / Copilot prompt / Antigravity rule | `.claude/skills/write-tests`, `.claude/skills/test-plan`, `.github/prompts/write-tests.prompt.md`, `.agents/rules/testing.md` | see §3 |

Tests run with `TZ=Asia/Dhaka`, so midnight/month-end bugs show up locally the same way they do for users.

## 2. The pipeline

```
PR opened ──► CI: typecheck → lint → unit + coverage ──► build → e2e (Playwright)
          └─► Claude review: bugs, security, missing test cases, perf → verdict comment
merge to main ──► CI again ──(green)──► Deploy: Coolify webhook ──► health check on APP_URL
```

### One-time GitHub settings per repo
1. **Branch protection** (Settings → Rules → New ruleset on `main`): require PR, require status checks **"Typecheck, lint, unit tests"** and **"Build + e2e (Playwright)"**, block force-push.
2. **Secrets** (Settings → Secrets and variables → Actions):

| Name | Kind | Where to get it | Needed for |
|---|---|---|---|
| `COOLIFY_WEBHOOK` | secret | Coolify → app → Webhooks → Deploy Webhook URL | deploy |
| `COOLIFY_TOKEN` | secret | Coolify → Keys & Tokens → API token (deploy permission) | deploy |
| `APP_URL` | variable | your live URL | post-deploy health check |
| `CLAUDE_CODE_OAUTH_TOKEN` | secret | run `claude setup-token` on your Mac (uses Claude Pro) | AI review |

3. **Coolify**: turn **off** the app's "Auto Deploy". Otherwise Coolify deploys on every push, even when CI is red.
4. **Claude GitHub App**: in Claude Code run `/install-github-app` once.
5. Optional, free with GitHub Pro / Copilot: in the ruleset, enable **"Request Copilot code review"** for a second reviewer.

A missing secret never breaks CI. The deploy and review jobs skip with a notice.

## 3. Writing test cases with AI

| Tool | How |
|---|---|
| Claude Code | `Use the write-tests skill on src/lib/invoice.ts`, or just "write tests for this diff". For a whole feature: `use test-plan for issue #42` |
| Copilot (VS Code) | Chat → `/write-tests` (prompt file), with code selected |
| Antigravity | the rule makes the agent show a test-case table and run the tests before it says it's done |

The method, for all three: **write the case table first, then the code.** It covers happy path, boundaries, invalid input, error paths, auth/permission (IDOR), time (Asia/Dhaka), money (integer paisa) and the regression case for a bug fix. P0 is money/auth/data loss, P1 is the core flow, P2 becomes an `it.todo`. If a test exposes a bug, the AI reports it and must not weaken the assertion.

**Real run, kept in `examples/`:** on `invoice.ts`, the skill wrote 13 tests. 2 failed because they found real bugs: a `NaN` discount came back as a `NaN` total, and fractional `unitPaisa` was accepted. The AI reported both and left the assertions alone.

## 4. Verified
I tested this kit on a fresh `create-next-app@15.5.4` project (React 19, npm):

- typecheck ✅, lint ✅, 7 unit/component tests ✅, build ✅, 2 e2e ✅
- `actionlint` ✅ on all 3 workflows
- Negative checks:
  - I broke the email validation: the component test failed ✅
  - I added a console error to the page: the e2e smoke test failed ✅
- Gotcha I hit and fixed in the script: vitest 5 needs `@types/node` ≥ 22, and create-next-app ships 20. The script now upgrades it.

## 5. Raise the bar over time
- Coverage: in `vitest.config.mts`, raise `thresholds` (start 40 → 60 → 80 on `src/lib`). CI fails below them.
- Add e2e for each P0 flow (login, payment, data export) in `tests/e2e/`.
- Run e2e against a preview deploy: `E2E_BASE_URL=https://staging… npm run test:e2e`.
