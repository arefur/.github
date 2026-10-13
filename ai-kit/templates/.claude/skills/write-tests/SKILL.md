---
name: write-tests
description: Design test cases first, then write and run Vitest/Testing Library/Playwright tests for a file, function, component, API route or the current diff. Use when asked to write tests, add test coverage, test a bug fix, or "test this".
---

# Write tests — cases first, code second

Target: the file/function/route the user named; if none, the uncommitted diff (`git diff HEAD`); if clean, the last commit.

## 1. Read before writing
- Read the target and its callers. Read 1–2 existing tests in the repo and copy their style, helpers and mocks.
- Note every branch, thrown error, early return, external call (DB, fetch, env, time, random).

## 2. Test-case table (show it before any code)
| ID | Scenario | Given | When | Then | Level | Priority |
|---|---|---|---|---|---|---|
Cover, in order, and skip a row only if it truly cannot apply:
1. **Happy path** — the main promise of the unit.
2. **Boundaries** — 0, 1, max, empty string/array, exactly-at-limit, off-by-one.
3. **Invalid input** — wrong type, missing field, malformed (zod should reject), very long, unicode/Bangla text.
4. **Error paths** — dependency throws/times out/returns 500; assert our handling, not the dependency.
5. **Auth & permissions** — logged out, wrong role, someone else's resource (IDOR).
6. **State & time** — idempotency (call twice), concurrency where relevant, dates around midnight Asia/Dhaka, month end, DST-free but UTC offset +6.
7. **Money** — integer paisa, rounding, negative/refund, ৳ formatting.
8. **Regression** — for a bug fix: the exact failing input from the bug report.
Level = unit (Vitest), component (Testing Library), api (route handler called directly), e2e (Playwright).
Priority = P0 (money, auth, data loss), P1 (core flow), P2 (nice to have). Write all P0/P1; list P2 as `it.todo`.

## 3. Write
- Unit/component → next to the source as `*.test.ts(x)` (or `tests/unit/` if the repo does that). e2e → `tests/e2e/*.spec.ts`.
- One `describe` per unit; `it('does X when Y')` reads as a sentence; Arrange → Act → Assert.
- Components: query by role/label (`getByRole('button', { name: /save/i })`), drive with `userEvent`, never by class names or test ids unless no accessible handle exists.
- Mock only at the boundary (fetch, DB client, `Date` via `vi.useFakeTimers()`); never mock the unit under test.
- No snapshot tests for logic. No `sleep`; use `findBy*` / `expect.poll`.

## 4. Run and report
- Run `npm run test -- <files>` (and `npm run test:e2e -- <spec>` for e2e). Iterate until green.
- If a test fails because the **code** is wrong, do NOT change the assertion to match: stop and report the bug with the failing case ID.
- Finish with: cases written / todo, files touched, the run output summary, and any bugs found.
