---
name: ship
description: Commit, push, open a PR and turn on auto-merge for the current work. Use when the user says ship it, commit and push, make a PR, merge this, or the task is finished and verified.
---

# Ship the current work

1. Look at `git status` and `git diff HEAD`. If the diff mixes unrelated changes, propose splitting it into separate ships and wait.
2. Make sure the work is done by the repo's rules: typecheck, lint and tests pass (`ship.sh` runs them again; fix failures before shipping, never skip).
3. Write ONE Conventional Commits message: `type(scope): imperative summary` (≤ 72 chars). type ∈ feat fix chore docs refactor perf test build ci style revert. Add `!` for breaking changes. Scope = the area touched (auth, invoice, ui…).
4. Run `bash scripts/ship.sh "<message>"`.
   - Use `--draft` when the user wants review first or the work is partial.
   - Use `--no-merge` when the diff touches migrations, auth, payments, workflows or env handling — those need the human's eyes (the CI risk gate would block them anyway).
5. Report: branch, PR URL, whether auto-merge is on, and what CI still has to pass. Never merge with failing checks, never force-push, never push straight to main.
