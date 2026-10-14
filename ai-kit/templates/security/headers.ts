// Security headers for every response. Wired in next.config.ts by setup-security.sh:
//   import { securityHeaders } from './src/lib/security/headers'
//   async headers() { return [{ source: '/(.*)', headers: securityHeaders }] }
// CSP starts as Report-Only so nothing breaks. Check the browser console for violations, add the
// domains you really use (analytics, Stripe, fonts…), then set CSP_ENFORCE=1 to enforce it.

const isDev = process.env.NODE_ENV !== 'production'
const enforce = process.env.CSP_ENFORCE === '1'
const extra = (process.env.CSP_EXTRA_SOURCES ?? '').split(/[\s,]+/).filter(Boolean).join(' ')

const csp = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline'${isDev ? " 'unsafe-eval'" : ''} ${extra}`.trim(),
  `style-src 'self' 'unsafe-inline' ${extra}`.trim(),
  `img-src 'self' data: blob: https: ${extra}`.trim(),
  `font-src 'self' data: ${extra}`.trim(),
  `connect-src 'self'${isDev ? ' ws: wss:' : ''} ${extra}`.trim(),
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
  // only valid in an enforced policy (browsers warn about it in Report-Only)
  ...(!isDev && enforce ? ['upgrade-insecure-requests'] : []),
].join('; ')

export const securityHeaders = [
  { key: enforce ? 'Content-Security-Policy' : 'Content-Security-Policy-Report-Only', value: csp },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), payment=(self), usb=()' },
  { key: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
]
