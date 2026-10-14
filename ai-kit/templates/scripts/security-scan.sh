#!/usr/bin/env bash
# Security scan — same checks locally and in CI.
#   bash scripts/security-scan.sh            # all
#   bash scripts/security-scan.sh secrets    # one of: secrets | deps | code
# Exit code is non-zero if anything at the blocking level is found.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
WHAT="${1:-all}"; FAIL=0
GITLEAKS_VERSION=8.21.2; SEMGREP_VERSION=1.95.0
BIN="${XDG_CACHE_HOME:-$HOME/.cache}/security-scan"; mkdir -p "$BIN"

gitleaks_bin() {
  command -v gitleaks >/dev/null && { command -v gitleaks; return; }
  [ -x "$BIN/gitleaks" ] && { echo "$BIN/gitleaks"; return; }
  os=$(uname -s | tr '[:upper:]' '[:lower:]'); arch=$(uname -m); case "$arch" in x86_64) arch=x64;; aarch64|arm64) arch=arm64;; esac
  curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${os}_${arch}.tar.gz" | tar xz -C "$BIN" gitleaks
  echo "$BIN/gitleaks"
}

if [ "$WHAT" = all ] || [ "$WHAT" = secrets ]; then
  echo "━━ Secrets (gitleaks: working tree + git history)"
  GL=$(gitleaks_bin)
  CFG=(); [ -f .gitleaks.toml ] && CFG=(--config .gitleaks.toml)
  if git rev-parse --git-dir >/dev/null 2>&1; then
    "$GL" git . "${CFG[@]}" --no-banner --redact -v --exit-code 1 || FAIL=1                # every commit in history
    "$GL" dir . "${CFG[@]}" --no-banner --redact -v --exit-code 1 || FAIL=1               # working tree incl. new files
  else
    "$GL" dir . "${CFG[@]}" --no-banner --redact -v --exit-code 1 || FAIL=1
  fi
fi

if [ "$WHAT" = all ] || [ "$WHAT" = deps ]; then
  echo "━━ Vulnerable dependencies (production, high+critical block)"
  if [ -f pnpm-lock.yaml ]; then pnpm audit --prod --audit-level high || FAIL=1
  elif [ -f yarn.lock ]; then yarn npm audit --environment production --severity high 2>/dev/null || yarn audit --groups dependencies --level high || FAIL=1
  elif [ -f package-lock.json ]; then node scripts/audit-gate.mjs || FAIL=1
  else echo "no lockfile — skipped"; fi
fi

if [ "$WHAT" = all ] || [ "$WHAT" = code ]; then
  echo "━━ Code (semgrep: OWASP Top 10, Next.js, React, TypeScript, secrets) — ERROR severity blocks"
  if command -v semgrep >/dev/null; then SG=(semgrep)
  elif command -v pipx >/dev/null; then SG=(pipx run "semgrep==${SEMGREP_VERSION}")
  elif command -v uvx >/dev/null; then SG=(uvx "semgrep==${SEMGREP_VERSION}")
  elif command -v docker >/dev/null; then SG=(docker run --rm -v "$PWD:/src" -w /src "semgrep/semgrep:${SEMGREP_VERSION}" semgrep)
  else echo "semgrep not found — install with: brew install semgrep   (skipped)"; SG=(); fi
  if [ ${#SG[@]} -gt 0 ]; then
    "${SG[@]}" scan --metrics=off --quiet \
      --config p/owasp-top-ten --config p/nextjs --config p/react --config p/typescript --config p/secrets \
      --config .semgrep.yml \
      --exclude node_modules --exclude .next --exclude coverage --exclude playwright-report --exclude 'tests/**' --exclude '**/*.test.*' \
      --severity ERROR --error . || FAIL=1
  fi
fi

[ "$FAIL" = 0 ] && echo "✓ security scan clean" || echo "✗ security scan found problems (see above)"
exit "$FAIL"
