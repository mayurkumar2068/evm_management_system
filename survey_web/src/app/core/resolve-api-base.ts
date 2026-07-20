/**
 * Resolves the POElectionAPI base URL for survey_web.
 *
 * Priority (recommended for Flutter WebView + IIS):
 * 1. Flutter override — cookie `app_api_base`, query `apiBase`, or
 *    `window.__APP_CONTEXT__.apiBaseUrl` (matches active app flavor).
 * 2. Same-host — when the UI is served from `/pssurvey/` on a real host,
 *    use `{origin}/POElectionAPI` so DEV (10.x) and PROD (mpsecerms) stay aligned.
 * 3. Build-time `environment.apiBaseUrl` fallback.
 */
export function resolveApiBaseUrl(buildTimeDefault: string): string {
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

function readOverride(): string {
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
    const ctx = (
      window as {
        __APP_CONTEXT__?: { apiBaseUrl?: string };
      }
    ).__APP_CONTEXT__;
    return (ctx?.apiBaseUrl || '').trim();
  } catch {
    return '';
  }
}

function deriveSameHostApiBase(): string | null {
  try {
    const { hostname, origin, pathname } = window.location;
    if (!hostname || hostname === 'localhost' || hostname === '127.0.0.1') {
      return null;
    }
    // GitHub Pages keeps a fixed production API in its own environment file.
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

function readCookie(name: string): string {
  try {
    const match = document.cookie.match(
      new RegExp(
        `(?:^|; )${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}=([^;]*)`,
      ),
    );
    return match ? decodeURIComponent(match[1]) : '';
  } catch {
    return '';
  }
}
