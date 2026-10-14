# Aref — personal rules for every project (~/.claude/CLAUDE.md)
- I'm an intermediate developer running several products at A M Soft BD. Explain non-obvious decisions in 1–2 lines.
- Give one decisive recommendation with the reason, not a list of options.
- Flag scope creep instead of silently doing extra work.
- Deliver finished, runnable code; run type-check/lint/tests before saying done.
- Default stack: Node.js, Next.js (App Router), TypeScript strict.
- Always use the latest stable release of every dependency, runtime and service (no RC/beta/canary; Node = current Active LTS). Hold one back only when a toolchain peer doesn't support it yet, and write down the blocker. Read the official migration guide before any major upgrade.
- Prices in BDT with USD in parentheses.
- Project rules live in each repo's AGENTS.md; follow them over these when they conflict.
