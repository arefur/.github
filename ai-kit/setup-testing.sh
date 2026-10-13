#!/usr/bin/env bash
# Adds unit (Vitest + Testing Library), e2e (Playwright) and CI/CD to a Next.js/TS repo. Run in repo root:
#   curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-testing.sh | bash
# Never overwrites existing files (FORCE=1 to overwrite). SKIP_INSTALL=1 skips npm install.
set -euo pipefail
BASE="${AI_KIT_BASE:-https://raw.githubusercontent.com/arefur/.github/main/ai-kit/templates}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
[ -f package.json ] || { echo "No package.json here."; exit 1; }
PM=npm; ADD="npm i -D"
[ -f pnpm-lock.yaml ] && PM=pnpm && ADD="pnpm add -D"
[ -f yarn.lock ] && PM=yarn && ADD="yarn add -D"
{ [ -f bun.lockb ] || [ -f bun.lock ]; } && PM=bun && ADD="bun add -d"

fetch() { # src dest
  if [ -e "$2" ] && [ "${FORCE:-0}" != 1 ]; then echo "skip  $2 (exists)"; return; fi
  mkdir -p "$(dirname "$2")"
  if [ -d "${AI_KIT_LOCAL:-/nonexistent}" ]; then cp "$AI_KIT_LOCAL/$1" "$2"; else curl -fsSL "$BASE/$1" -o "$2"; fi
  echo "write $2"
}

# 1. config + sample tests
fetch testing/vitest.config.mts vitest.config.mts
fetch testing/vitest.setup.ts vitest.setup.ts
fetch testing/playwright.config.ts playwright.config.ts
sed -i.bak "s/{{PM}}/$PM/g" playwright.config.ts && rm -f playwright.config.ts.bak
fetch testing/tests/unit/example.test.ts tests/unit/example.test.ts
fetch testing/tests/unit/example-component.test.tsx tests/unit/example-component.test.tsx
fetch testing/tests/e2e/smoke.spec.ts tests/e2e/smoke.spec.ts

# 2. CI/CD + test-case tooling for Claude / Copilot / Antigravity
fetch .github/workflows/ci.yml .github/workflows/ci.yml
fetch .github/workflows/deploy.yml .github/workflows/deploy.yml
fetch .github/workflows/claude-review.yml .github/workflows/claude-review.yml
fetch .github/prompts/write-tests.prompt.md .github/prompts/write-tests.prompt.md
fetch .claude/skills/write-tests/SKILL.md .claude/skills/write-tests/SKILL.md
fetch .claude/skills/test-plan/SKILL.md .claude/skills/test-plan/SKILL.md
fetch .agents/rules/testing.md .agents/rules/testing.md

# 3. scripts
npm pkg set scripts.typecheck="tsc --noEmit" \
  scripts.test="vitest run" scripts.test:watch="vitest" scripts.test:coverage="vitest run --coverage" \
  scripts.test:e2e="playwright test" scripts.test:e2e:ui="playwright test --ui"
for line in coverage/ playwright-report/ test-results/ blob-report/; do grep -qxF "$line" .gitignore 2>/dev/null || echo "$line" >> .gitignore; done

# 3b. keep ESLint out of generated test reports (they make `npm run lint` explode)
for cfg in eslint.config.mjs eslint.config.js eslint.config.ts; do
  [ -f "$cfg" ] || continue
  node -e '
    const fs = require("fs"); const f = process.argv[1]; let s = fs.readFileSync(f, "utf8");
    const add = ["coverage/**", "playwright-report/**", "test-results/**", "blob-report/**"].filter(x => !s.includes(x));
    if (!add.length) process.exit(0);
    if (/ignores:\s*\[/.test(s)) s = s.replace(/ignores:\s*\[/, m => m + add.map(x => JSON.stringify(x)).join(", ") + ", ");
    else s = s.replace(/export default\s+(\w+)\s*;?/, (m, v) => v + ".push({ ignores: " + JSON.stringify(add) + " });\n" + m);
    fs.writeFileSync(f, s); console.log("write " + f + " (ignore test reports)");
  ' "$cfg"
done

# 4. dev dependencies
if [ "${SKIP_INSTALL:-0}" != 1 ]; then
  # vitest 5 needs @types/node >= 22 (matches Node 22 used in CI); upgrade only if older.
  NODE_TYPES=$(node -p "(require('./package.json').devDependencies||{})['@types/node']||''")
  case "$NODE_TYPES" in *18*|*20*|*21*) $ADD @types/node@^22 ;; esac
  $ADD vitest @vitest/coverage-v8 @vitejs/plugin-react vite-tsconfig-paths jsdom \
    @testing-library/react @testing-library/dom @testing-library/jest-dom @testing-library/user-event \
    @playwright/test
  npx playwright install chromium
fi

echo
echo "Done ($PM). Try:  $PM run test   |   $PM run test:e2e"
echo "CI runs on every PR. For deploy + AI review, add repo secrets — see ai-kit/TESTING-CICD.md."
