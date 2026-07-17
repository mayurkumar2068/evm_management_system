import { Lang } from '../i18n/translations';

/**
 * Parameters handed in by the Flutter WebView via the launch URL
 * (`?token=...&lang=hi|en`). Captured ONCE at module load — before Angular's
 * router runs and rewrites the URL (which would drop the query string) — so the
 * token/language survive client-side navigation between the two pages.
 */
export interface AppParams {
  token: string;
  lang: Lang;
  userName: string;
  password: string;
  userId: string;
  districtId: string;
  bodyId: string;
  urbanRural: string;
  electionId: number | null;
  psId: string;
}

function readCookie(name: string): string {
  const match = document.cookie.match(
    new RegExp(`(?:^|; )${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}=([^;]*)`),
  );
  return match ? decodeURIComponent(match[1]) : '';
}

function read(): AppParams {
  try {
    const ctx = (window as { __APP_CONTEXT__?: { districtId?: string } }).__APP_CONTEXT__;
    const q = new URLSearchParams(window.location.search);
    const readParam = (names: string[], cookieName: string): string => {
      for (const name of names) {
        const value = q.get(name);
        if (value && value.trim().length > 0) {
          return value.trim();
        }
      }
      return readCookie(cookieName).trim();
    };

    const token = readParam(['token', 'accessToken'], 'app_token');
    const langParam = readParam(['lang'], 'app_lang');
    const userName = readParam(['userName', 'username'], 'app_user_name');
    const password = readParam(['password'], 'app_password');
    const userId = readParam(['userId', 'userid', 'id'], 'app_user_id');
    const districtId =
      readParam(['districtId', 'districtid', 'distId', 'distid'], 'app_district_id') ||
      (ctx?.districtId ?? '').trim();
    const bodyId = readParam(['bodyId', 'bodyid'], 'app_body_id');
    const urbanRural = readParam(['urbanRural', 'urbanrural'], 'app_urban_rural');
    const electionIdRaw = readParam(['electionId', 'electionid'], 'app_election_id');
    const psId = readParam(['psId', 'psid'], 'app_ps_id');
    const parsedElectionId = Number(electionIdRaw);
    const electionId = Number.isFinite(parsedElectionId) && parsedElectionId > 0
      ? parsedElectionId
      : null;

    const lang: Lang = langParam.toLowerCase().startsWith('en') ? 'en' : 'hi';
    return { token, lang, userName, password, userId, districtId, bodyId, urbanRural, electionId, psId };
  } catch {
    return {
      token: '',
      lang: 'hi',
      userName: '',
      password: '',
      userId: '',
      districtId: '',
      bodyId: '',
      urbanRural: '',
      electionId: null,
      psId: '',
    };
  }
}

export const APP_PARAMS: AppParams = read();
