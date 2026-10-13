---
mode: agent
description: Design test cases first, then write and run tests for the selected code
---
Write tests for ${selection} (or the current file ${file} if nothing is selected), following AGENTS.md → "Testing".

1. First show a test-case table: ID | Scenario | Given | When | Then | Level | Priority. Cover happy path, boundaries, invalid input, error paths, auth/permissions, time (Asia/Dhaka), money (integer paisa) and, for bug fixes, the exact regression input.
2. Write Vitest + Testing Library tests (Playwright for e2e) in the repo's existing style. Query by role/label, mock only at boundaries.
3. Run them in the terminal and iterate until green. If the code is wrong, report the bug instead of changing the assertion.
