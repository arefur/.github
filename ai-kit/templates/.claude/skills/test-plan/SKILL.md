---
name: test-plan
description: Write a feature-level test plan (test case scenarios, acceptance criteria, manual QA checklist) before or after building a feature. Use when asked for test cases, test scenarios, a QA plan, or acceptance tests for a feature, user story, issue or PR.
---

# Test plan for a feature

Input: a feature description, GitHub issue (`gh issue view N`), PR (`gh pr view N --json title,body,files`), or the current branch's diff.

Produce `docs/test-plans/<feature-slug>.md` with:

1. **Scope** — what is in / out, the user roles involved.
2. **Acceptance criteria** — Given/When/Then, one per behaviour the user can observe.
3. **Test cases** — table: ID (TC-01…), Scenario, Preconditions, Steps, Expected, Level (unit/component/api/e2e/manual), Priority (P0/P1/P2), Automated? (file path or "manual").
   Must include: happy path per role, validation errors, empty states, permission denied, network/API failure, slow network (loading state), double-submit, mobile viewport, Bangla text input, money/time edge cases when relevant.
4. **Non-functional** — performance budget (e.g. page < 2.5 s LCP on 4G), accessibility (keyboard only, screen-reader labels), security (OWASP items touched).
5. **Test data** — accounts/fixtures needed.
6. **Manual QA checklist** — the P0/P1 cases that are not automated, as checkboxes.
7. **Exit criteria** — all P0 pass, no open P0/P1 bugs, CI green.

Then ask whether to automate the P0/P1 cases now with the write-tests skill.
