# AGENTS.md — single source of truth for every AI coding tool
<!-- Read by: Claude Code (via @AGENTS.md in CLAUDE.md), Antigravity (root AGENTS.md),
     GitHub Copilot (VS Code agent mode + generated .github/copilot-instructions.md).
     Edit THIS file only, then run: bash ai-sync.sh -->

## Project
- Name: {{PROJECT_NAME}}
- What it does: {{ONE_LINE_PURPOSE}}
- Owner: A M Soft BD (arefur@amsoftbd.com)
- Stack: Node.js, Next.js (App Router), TypeScript (strict), {{DB_AND_EXTRAS}}

## Commands
- Install: `{{PM}} install`
- Dev: `{{PM}} run dev`
- Type-check: `{{PM}} run typecheck`
- Lint: `{{PM}} run lint`
- Unit tests: `{{PM}} run test` (watch: `{{PM}} run test:watch`, coverage: `{{PM}} run test:coverage`)
- e2e: `{{PM}} run test:e2e`
- Build: `{{PM}} run build`
Run type-check + lint + tests before saying a task is done. If one fails, fix it or say so plainly.

## Code rules
- TypeScript strict. No `any`, no `@ts-ignore` without a one-line reason.
- Server Components by default; add `"use client"` only where state/effects/browser APIs are needed.
- Validate every external input (request bodies, params, env) with zod at the boundary.
- Keep functions under ~50 lines; extract instead of nesting.
- Match the existing patterns in the folder you are editing before inventing new ones.
- No new dependency without saying why and what it replaces.
- Money: store as integer minor units (paisa/cents); format BDT with ৳ and USD in parentheses.

## Testing
- Stack: Vitest + Testing Library (unit/component, jsdom), Playwright (e2e in `tests/e2e`). TZ is Asia/Dhaka in tests.
- Every bug fix ships with a regression test that failed before the fix.
- Every new function/route/component ships with tests for: happy path, boundaries, invalid input, error path; plus auth/permission for anything behind login; money in integer paisa.
- Write the test-case table first (skills: `write-tests`, `test-plan`), then the tests.
- Query the DOM by role/label; mock only at boundaries (fetch, DB, time). No snapshots for logic, no sleeps.
- A failing test that reveals a code bug is reported, never "fixed" by weakening the assertion.
- CI (`.github/workflows/ci.yml`) must be green before merge: typecheck, lint, unit+coverage, build, e2e.

## Workflow
- For anything touching 3+ files: write a short plan first and wait for approval.
- Small, reviewable diffs. Don't reformat files you didn't otherwise change.
- Commits: Conventional Commits (`feat:`, `fix:`, `chore:` …), one logical change each (the commit-msg hook enforces it).
- Ship finished, verified work with `{{PM}} run ship -- "type(scope): summary"` (checks → branch → commit → push → PR → auto-merge when CI is green). Never push to the default branch directly; never force-push.
- Changes to migrations, auth, payments, workflows or env handling: ship with `--no-merge` and tell the owner — the Risk gate blocks them until a human adds `human-approved`.
- Never commit secrets. `.env*` files are read-only for agents.

## Don't
- Don't run destructive commands (`rm -rf`, `git push --force`, `DROP`, prod migrations) without asking.
- Don't edit generated files, lockfiles by hand, or `node_modules`.
- Don't claim something works without having run it.

## Notes for this repo
- {{ANYTHING_SPECIFIC: folders, gotchas, domain terms}}
