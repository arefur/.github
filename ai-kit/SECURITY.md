# Security layer

```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-security.sh | bash
npm run security
```

## What runs and where
| Layer | Tool | Local | CI (`security.yml`, required check) | Blocks on |
|---|---|---|---|---|
| Secrets | gitleaks 8.21.2 (working tree + **entire git history**) | `npm run security` + pre-commit hook | "Secrets & dependencies" | any leak |
| Dependencies | `npm audit` through `scripts/audit-gate.mjs` | same | same | high/critical in production deps, unless allowlisted with a reason and an expiry ≤ 90 days |
| Code | semgrep 1.180.0: OWASP Top 10, Next.js, React, TypeScript, secrets packs + house rules (`.semgrep.yml`) | same | "Code scan (semgrep)" | ERROR severity |
| Headers | `src/lib/security/headers.ts`, wired into `next.config.ts` | — | e2e smoke test fails on CSP console errors | — |
| Review + fixes | `security-review` skill (OWASP checklist → report → failing attack test → fix) | ask Claude | `claude-review.yml` checks security on every PR | — |
| Risky paths | Risk gate (auth, payments, migrations, workflows, env, Docker) | — | "Risk gate" | until the `human-approved` label is added |
| Agent safety | `.claude/settings.json` deny/ask rules + toolsmith install guard | always | — | `.env`/`~/.ssh`/`~/.aws` reads, `curl \| sh`, force-push; installs always ask |

The scans run weekly too (Monday 09:30 Dhaka), because new CVEs show up in code that hasn't changed.

House rules in `.semgrep.yml`:
- `NEXT_PUBLIC_*SECRET|TOKEN|KEY` (blocks)
- raw SQL interpolation (blocks)
- unsanitised `dangerouslySetInnerHTML` (blocks)
- mutating route handler with no auth call (warning)

## Verified on a real Next.js app
| Test | Result |
|---|---|
| Fresh `create-next-app@15.5.4` | ❌ **audit gate blocked it: Next 15.5.4 has a critical CVE.** I upgraded to 15.5.27. Two postcss highs remain inside Next 15 and are only fixed in Next 16 (breaking), so I allowlisted them until 2027-01-10 with a reason. |
| Planted AWS key + GitHub PAT | ✅ gitleaks: `aws-access-token`, `github-pat` |
| Planted `DELETE` route with `db.query(\`… ${id}\`)` | ✅ semgrep `raw-sql-interpolation` |
| `dangerouslySetInnerHTML={{__html: bio}}` from searchParams | ✅ semgrep `dangerously-set-html-unsanitized` |
| `NEXT_PUBLIC_STRIPE_SECRET_KEY` | ✅ semgrep `next-public-secret` |
| `.next/` build output (preview-mode keys) | ✅ not flagged (allowlisted build output) |
| Headers after build (`curl -I`) | ✅ CSP (Report-Only), HSTS, nosniff, X-Frame-Options DENY, Referrer-Policy, Permissions-Policy, COOP; no `X-Powered-By` |
| e2e with CSP Report-Only **and** enforced | ✅ both pass. The first version had `upgrade-insecure-requests` in Report-Only, and the smoke test caught the console warning, so I fixed it. |
| `security-review` skill on the vulnerable branch | ✅ found all of the planted issues and more: 3 Critical (SQLi + no auth, secret in NEXT_PUBLIC, hardcoded keys), 2 High (XSS, no middleware), 1 Medium (CSP not enforced), 1 Low. It stopped before fixing auth logic, as AGENTS.md requires. |

## Turning CSP on for real
1. Deploy with Report-Only (the default). Use the app and watch the browser console for `[Report Only]` violations.
2. Add the domains you really use: `CSP_EXTRA_SOURCES="https://js.stripe.com https://www.googletagmanager.com"`.
3. Set `CSP_ENFORCE=1` in Coolify env and redeploy. The e2e smoke test fails if the page logs a CSP error.
