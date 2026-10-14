---
name: security-review
description: Audit a Next.js/TypeScript repo, diff or feature for security problems (OWASP Top 10, auth/IDOR, injection, XSS, secrets, headers, dependencies), then implement the fixes with tests. Use when asked for a security review, security check, "is this secure", hardening, or before launching or handling payments or personal data.
---

# Security review → fix → prove

Scope: what the user named, or else the current diff (`git diff origin/main...HEAD`), or else the whole `src/`.

## 1. Run the scanners first (facts before opinions)
```bash
bash scripts/security-scan.sh        # gitleaks (secrets), dependency audit, semgrep (OWASP + Next.js + house rules)
```
Every finding goes in the report. Don't re-derive what a scanner already proved.

## 2. Manual review — what scanners miss
Go through this list for the scope. Each item is **Pass**, **Fail (file:line)** or **N/A**.

**Access control (OWASP A01). This is where most real breaches happen.**
- Every route handler and server action that reads or writes user data checks the session *and ownership*. `where: { id, userId: session.user.id }`, never `where: { id }` alone (IDOR).
- Role checks happen on the server. Hiding a button is not access control.
- `middleware.ts` matchers really cover the protected routes. Check that `/api/*` is included.

**Injection & input (A03)**
- Every external input (body, params, searchParams, headers, webhooks) is validated with zod at the boundary.
- No raw SQL with interpolation. No `eval`, no `new Function`. No `child_process` with user input.
- File uploads: type and size are limited, files are stored outside `public/`, filenames are randomised.

**XSS**
- `dangerouslySetInnerHTML` only with DOMPurify. Markdown is rendered with HTML sanitised.
- No user-controlled `href` that can be `javascript:`.

**Secrets & data exposure (A02, A04)**
- No secret in a `NEXT_PUBLIC_*` variable. Server-only modules start with `import 'server-only'`.
- API responses select explicit fields. No password hashes or tokens are returned.
- Logs contain no tokens, passwords, OTPs or full card or NID numbers.

**Auth & sessions (A07)**
- Cookies are `httpOnly`, `secure` and `sameSite=lax|strict`.
- Login, OTP and password-reset are rate-limited, and errors don't reveal whether an account exists.
- Passwords are hashed with argon2/bcrypt. Reset tokens are single-use and expire.

**SSRF (A10)**
- A server-side `fetch(userUrl)` uses an allowlist of hosts and blocks private IPs.

**Webhooks & payments**
- Signatures are verified (Stripe, SSLCommerz, bKash) and handlers are idempotent.
- Amounts come from the server, never from the client.

**Config (A05)**
- Security headers are present (`src/lib/security/headers.ts` is wired in `next.config.ts`) and `poweredByHeader: false` is set.
- CORS is not `*` on authenticated routes. Error pages don't leak stack traces in production.

**Dependencies (A06)**
- The audit gate passes. Every `.audit-allowlist.json` entry has a reason and hasn't expired.

## 3. Report
| ID | Severity (Critical/High/Medium/Low) | Category | File:line | What an attacker can do | Fix |
|---|---|---|---|---|---|

Order the rows by severity. Critical means remote, unauthenticated access to data or money.

## 4. Implement (ask first if > 5 files or any auth/payment logic changes)
For each Critical or High finding, in this order:
1. Write a **failing test that reproduces the attack**, e.g. "user B cannot DELETE user A's invoice → expect 403/404", or "`<script>` in bio is not executed".
2. Fix the code with the smallest change.
3. Re-run the test (now green) and `bash scripts/security-scan.sh`.

Baseline hardening to apply when missing:
- headers via `src/lib/security/headers.ts`
- a zod-validated `src/env.ts` for server env vars
- `import 'server-only'` in DB and secret modules
- a rate limit on auth routes

## 5. Finish
Give the summary table with a Fixed / Remaining status per finding, the tests added, the scanner output, and anything that needs a human decision (for example a breaking dependency upgrade). Ship fixes with `--no-merge`: security changes get a human review.
