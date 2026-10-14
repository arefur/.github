#!/usr/bin/env bash
# Security for a Next.js/TS repo: CI scans (secrets, deps, code), house semgrep rules, security headers, review skill.
#   curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-security.sh | bash
# Never overwrites existing files (FORCE=1 to overwrite).
set -euo pipefail
BASE="${AI_KIT_BASE:-https://raw.githubusercontent.com/arefur/.github/main/ai-kit/templates}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
fetch() {
  if [ -e "$2" ] && [ "${FORCE:-0}" != 1 ]; then echo "skip  $2 (exists)"; return; fi
  mkdir -p "$(dirname "$2")"
  if [ -d "${AI_KIT_LOCAL:-/nonexistent}" ]; then cp "$AI_KIT_LOCAL/$1" "$2"; else curl -fsSL "$BASE/$1" -o "$2"; fi
  echo "write $2"
}
for f in scripts/security-scan.sh scripts/audit-gate.mjs .semgrep.yml .gitleaks.toml \
         .github/workflows/security.yml .claude/skills/security-review/SKILL.md; do fetch "$f" "$f"; done
chmod +x scripts/security-scan.sh
SRC=src; [ -d src ] || SRC=.
fetch security/headers.ts "$SRC/lib/security/headers.ts"
[ -f package.json ] && npm pkg set scripts.security="bash scripts/security-scan.sh"

# wire headers + hide x-powered-by in next.config.(ts|mjs|js)
for cfg in next.config.ts next.config.mjs next.config.js; do
  [ -f "$cfg" ] || continue
  node -e '
    const fs = require("fs"); const [f, src] = process.argv.slice(1); let s = fs.readFileSync(f, "utf8")
    if (s.includes("securityHeaders")) { console.log("skip  " + f + " (headers already wired)"); process.exit(0) }
    const rel = "./" + (src === "." ? "" : src + "/") + "lib/security/headers"
    const m = /(const\s+\w+\s*(?::\s*NextConfig)?\s*=\s*\{)/.exec(s) || /(module\.exports\s*=\s*\{)/.exec(s) || /(export\s+default\s*\{)/.exec(s)
    if (!m) { console.log("! could not find the config object in " + f + " — add headers() by hand (see TESTING-CICD.md)"); process.exit(0) }
    s = `import { securityHeaders } from "${rel}";\n` + s.replace(m[1], m[1] + `\n  poweredByHeader: false,\n  async headers() {\n    return [{ source: "/(.*)", headers: securityHeaders }];\n  },`)
    fs.writeFileSync(f, s); console.log("write " + f + " (security headers + poweredByHeader:false)")
  ' "$cfg" "$SRC"
  break
done
echo
echo "Done. Run:  npm run security     (secrets + deps + code; same checks as CI)"
echo "Ask Claude: 'run the security-review skill' for the manual OWASP review + fixes."
