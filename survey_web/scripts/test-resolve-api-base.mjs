/**
 * Unit tests for resolveApiBaseUrl priority (DEV / PROD / Flutter override).
 * Run: node scripts/test-resolve-api-base.mjs
 */

function resolveApiBaseUrl(buildTimeDefault) {
  const override = readOverride().replace(/\/+$/, '');
  if (override.length > 0) {
    return override;
  }
  const sameHost = deriveSameHostApiBase();
  if (sameHost) {
    return sameHost;
  }
  return buildTimeDefault.replace(/\/+$/, '');
}

function readOverride() {
  try {
    const q = new URLSearchParams(window.location.search);
    const fromQuery = (q.get('apiBase') || q.get('apiBaseUrl') || '').trim();
    if (fromQuery) {
      return fromQuery;
    }
  } catch {
    // ignore
  }
  const fromCookie = readCookie('app_api_base').trim();
  if (fromCookie) {
    return fromCookie;
  }
  try {
    return (window.__APP_CONTEXT__?.apiBaseUrl || '').trim();
  } catch {
    return '';
  }
}

function deriveSameHostApiBase() {
  try {
    const { hostname, origin, pathname } = window.location;
    if (!hostname || hostname === 'localhost' || hostname === '127.0.0.1') {
      return null;
    }
    if (hostname.includes('github.io')) {
      return null;
    }
    const underPssurvey = pathname.includes('/pssurvey');
    const knownHosts =
      hostname === '10.115.197.192' ||
      hostname.endsWith('.mp.gov.in') ||
      hostname === 'mpsecerms.mp.gov.in';
    if (!underPssurvey && !knownHosts) {
      return null;
    }
    return `${origin}/POElectionAPI`.replace(/\/+$/, '');
  } catch {
    return null;
  }
}

function readCookie(name) {
  try {
    const match = document.cookie.match(
      new RegExp(`(?:^|; )${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}=([^;]*)`),
    );
    return match ? decodeURIComponent(match[1]) : '';
  } catch {
    return '';
  }
}

let passed = 0;
let failed = 0;

function ok(name, cond, detail = '') {
  if (cond) {
    passed += 1;
    console.log(`  ✓ ${name}`);
  } else {
    failed += 1;
    console.error(`  ✗ ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

function withWindow(location, ctx, cookie, fn) {
  const prevWindow = globalThis.window;
  const prevDocument = globalThis.document;
  globalThis.window = { location, __APP_CONTEXT__: ctx };
  globalThis.document = { cookie: cookie || '' };
  try {
    return fn();
  } finally {
    globalThis.window = prevWindow;
    globalThis.document = prevDocument;
  }
}

console.log('\n=== resolveApiBaseUrl tests ===\n');

ok(
  'DEV same-host IIS',
  withWindow(
    {
      hostname: '10.115.197.192',
      origin: 'http://10.115.197.192',
      pathname: '/pssurvey/location',
      search: '',
    },
    null,
    '',
    () =>
      resolveApiBaseUrl('http://wrong-host/POElectionAPI') ===
      'http://10.115.197.192/POElectionAPI',
  ),
);

ok(
  'PROD same-host IIS',
  withWindow(
    {
      hostname: 'mpsecerms.mp.gov.in',
      origin: 'https://mpsecerms.mp.gov.in',
      pathname: '/pssurvey/checklist',
      search: '',
    },
    null,
    '',
    () =>
      resolveApiBaseUrl('http://wrong-host/POElectionAPI') ===
      'https://mpsecerms.mp.gov.in/POElectionAPI',
  ),
);

ok(
  'Flutter __APP_CONTEXT__ override wins on DEV',
  withWindow(
    {
      hostname: '10.115.197.192',
      origin: 'http://10.115.197.192',
      pathname: '/pssurvey/',
      search: '',
    },
    { apiBaseUrl: 'http://10.115.197.192/POElectionAPI' },
    '',
    () =>
      resolveApiBaseUrl('https://mpsecerms.mp.gov.in/POElectionAPI') ===
      'http://10.115.197.192/POElectionAPI',
  ),
);

ok(
  'app_api_base cookie override wins on PROD',
  withWindow(
    {
      hostname: 'mpsecerms.mp.gov.in',
      origin: 'https://mpsecerms.mp.gov.in',
      pathname: '/pssurvey/',
      search: '',
    },
    null,
    'app_api_base=https%3A%2F%2Fmpsecerms.mp.gov.in%2FPOElectionAPI',
    () =>
      resolveApiBaseUrl('http://10.115.197.192/POElectionAPI') ===
      'https://mpsecerms.mp.gov.in/POElectionAPI',
  ),
);

ok(
  'localhost falls back to build-time default',
  withWindow(
    {
      hostname: 'localhost',
      origin: 'http://localhost:4200',
      pathname: '/',
      search: '',
    },
    null,
    '',
    () =>
      resolveApiBaseUrl('http://10.115.197.192/POElectionAPI') ===
      'http://10.115.197.192/POElectionAPI',
  ),
);

console.log(`\nresolve-api-base: ${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
