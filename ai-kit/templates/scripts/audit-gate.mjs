#!/usr/bin/env node
// Dependency gate over `npm audit --json`: fails on advisories at/above AUDIT_LEVEL (default high)
// unless listed in .audit-allowlist.json with a reason and an expiry date (max 90 days — then it must be re-reviewed).
//   .audit-allowlist.json: [{ "id": "GHSA-xxxx-xxxx-xxxx", "reason": "only in next's build-time postcss; fixed in next 16", "expires": "2027-01-15" }]
import { execSync } from 'node:child_process'
import { existsSync, readFileSync } from 'node:fs'

const LEVELS = ['info', 'low', 'moderate', 'high', 'critical']
const min = LEVELS.indexOf(process.env.AUDIT_LEVEL ?? 'high')
let raw
try { raw = execSync('npm audit --omit=dev --json', { stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 64 << 20 }).toString() }
catch (e) { raw = e.stdout?.toString() ?? '{}' } // npm audit exits non-zero when it finds anything
const report = JSON.parse(raw || '{}')
const allow = existsSync('.audit-allowlist.json') ? JSON.parse(readFileSync('.audit-allowlist.json', 'utf8')) : []
const today = new Date().toISOString().slice(0, 10)
const maxDay = new Date(Date.now() + 90 * 86400000).toISOString().slice(0, 10)
for (const a of allow) if (!a.reason || !a.expires || a.expires > maxDay) { console.log(`✗ allowlist entry ${a.id} needs a reason and an expiry within 90 days (≤ ${maxDay}) — ignored`); a.expires = '0000-00-00' }
const allowed = new Map(allow.map(a => [a.id, a]))

const advisories = new Map()
for (const [pkg, v] of Object.entries(report.vulnerabilities ?? {}))
  for (const via of v.via) if (typeof via === 'object') {
    const id = (via.url ?? '').split('/').pop() || String(via.source)
    advisories.set(id, { id, pkg, severity: via.severity, title: via.title, url: via.url, range: via.range })
  }

let blocking = 0
for (const a of [...advisories.values()].sort((x, y) => LEVELS.indexOf(y.severity) - LEVELS.indexOf(x.severity))) {
  if (LEVELS.indexOf(a.severity) < min) continue
  const ok = allowed.get(a.id)
  if (ok && ok.expires >= today) { console.log(`  allowed  ${a.severity.padEnd(8)} ${a.pkg} ${a.id} — ${ok.reason} (until ${ok.expires})`); continue }
  blocking++
  console.log(`✗ ${a.severity.padEnd(8)} ${a.pkg} ${a.id} — ${a.title}${ok ? ` (allowlist EXPIRED ${ok.expires})` : ''}\n           ${a.url}`)
}
for (const a of allow) if (!advisories.has(a.id)) console.log(`  note: ${a.id} is no longer reported — remove it from .audit-allowlist.json`)
if (blocking) { console.log(`\n${blocking} blocking advisor${blocking > 1 ? 'ies' : 'y'}. Fix: npm audit fix (or upgrade the parent package). If no fix exists yet, add it to .audit-allowlist.json with a reason and an expiry ≤ 90 days.`); process.exit(1) }
console.log(`✓ no unallowed ${LEVELS[min]}+ advisories in production dependencies`)
