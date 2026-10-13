# Antigravity rule: testing
When writing or changing code, follow AGENTS.md → "Testing":
- Before writing tests, list a test-case table (happy path, boundaries, invalid input, error paths, auth, time, money, regression) with P0/P1/P2 priority.
- Vitest + Testing Library for unit/component, Playwright for e2e in tests/e2e.
- Run `npm run test` (and `npm run test:e2e` for UI flows) and show the result before saying a task is done.
- If a test exposes a bug in the code, report it; never weaken the assertion to make it pass.
