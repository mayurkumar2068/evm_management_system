'use strict';

const crypto = require('crypto');

/* ===========================================================================
 *  Stateless token auth for the survey micro-app.
 *  Token = base64url(header).base64url(payload).base64url(HMAC-SHA256)
 *  (a minimal JWT-compatible shape, no external dependency).
 * =========================================================================== */

const SECRET = process.env.TOKEN_SECRET || 'mpseciems-dev-secret-change-me';
const TTL_HOURS = Number(process.env.TOKEN_TTL_HOURS || 12);

const b64url = (buf) =>
  Buffer.from(buf)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

const b64urlJson = (obj) => b64url(JSON.stringify(obj));

const sign = (data) =>
  b64url(crypto.createHmac('sha256', SECRET).update(data).digest());

/** Create a signed token for an authenticated user. */
function issueToken(user) {
  const header = b64urlJson({ alg: 'HS256', typ: 'JWT' });
  const now = Math.floor(Date.now() / 1000);
  const payload = b64urlJson({
    sub: String(user.id),
    uid: user.userid,
    name: user.name || null,
    section: user.section || null,
    dist: user.district ? String(user.district.id) : null,
    distName: user.district ? user.district.name : null,
    iat: now,
    exp: now + TTL_HOURS * 3600,
  });
  const signature = sign(`${header}.${payload}`);
  return `${header}.${payload}.${signature}`;
}

/** Verify a token; returns the payload object or null when invalid/expired. */
function verifyToken(token) {
  if (!token || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [header, payload, signature] = parts;
  const expected = sign(`${header}.${payload}`);
  // constant-time compare
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  let data;
  try {
    data = JSON.parse(Buffer.from(payload, 'base64').toString('utf8'));
  } catch {
    return null;
  }
  if (!data.exp || data.exp < Math.floor(Date.now() / 1000)) return null;
  return data;
}

/**
 * Express middleware: requires a valid Bearer token (or `?token=` query, which
 * the WebView uses). Attaches `req.auth` with the decoded payload.
 */
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const bearer = header.startsWith('Bearer ') ? header.slice(7) : '';
  const token = bearer || String(req.query.token || '');
  const data = verifyToken(token);
  if (!data) {
    return res.status(401).json({ error: 'UNAUTHORIZED', message: 'सत्र अमान्य या समाप्त।' });
  }
  req.auth = data;
  next();
}

/**
 * Login handler factory. `pool` is the shared mysql2 pool.
 * Validates against IEMS_SECUsers (plaintext password in this DB).
 */
function loginHandler(pool) {
  return async (req, res) => {
    const userid = String((req.body && req.body.userid) || '').trim();
    const password = String((req.body && req.body.password) || '');
    if (!userid || !password) {
      return res.status(400).json({ error: 'BAD_REQUEST', message: 'यूज़र आईडी व पासवर्ड आवश्यक हैं।' });
    }
    const [rows] = await pool.query(
      `SELECT ID, userid, SO_Name, section, password
         FROM IEMS_SECUsers
        WHERE userid = ? AND isactive = 1
        LIMIT 1`,
      [userid],
    );
    const row = rows[0];
    // constant-time-ish password comparison
    const ok =
      row &&
      Buffer.byteLength(password) === Buffer.byteLength(String(row.password)) &&
      crypto.timingSafeEqual(Buffer.from(password), Buffer.from(String(row.password)));
    if (!ok) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'गलत यूज़र आईडी या पासवर्ड।' });
    }
    const user = {
      id: row.ID,
      userid: row.userid,
      name: row.SO_Name,
      section: row.section,
    };
    const token = issueToken(user);
    res.json({ success: true, token, ttlHours: TTL_HOURS, user });
  };
}

/**
 * District login factory. The officer just picks their district and enters the
 * shared password (default `admin123`, override with env DISTRICT_PASSWORD).
 * Validates the district exists in `Districts` and issues a district-scoped
 * token so the WebView gets the district context.
 */
function districtLoginHandler(pool) {
  return async (req, res) => {
    const body = req.body || {};
    const districtId = String(
      body.districtId ?? body.district_code ?? body.districtCode ?? '',
    ).trim();
    const password = String(body.password || '');
    if (!districtId || !password) {
      return res
        .status(400)
        .json({ error: 'BAD_REQUEST', message: 'ज़िला व पासवर्ड आवश्यक हैं।' });
    }

    const expected = process.env.DISTRICT_PASSWORD || 'admin123';
    const okPass =
      Buffer.byteLength(password) === Buffer.byteLength(expected) &&
      crypto.timingSafeEqual(Buffer.from(password), Buffer.from(expected));
    if (!okPass) {
      return res
        .status(401)
        .json({ error: 'INVALID_CREDENTIALS', message: 'गलत पासवर्ड।' });
    }

    const [rows] = await pool.query(
      `SELECT ID, DIST_NO, DIST_NAME, DIST_NAME_EN
         FROM Districts WHERE ID = ? LIMIT 1`,
      [districtId],
    );
    const row = rows[0];
    if (!row) {
      return res
        .status(401)
        .json({ error: 'INVALID_DISTRICT', message: 'अमान्य ज़िला।' });
    }

    const name = row.DIST_NAME || row.DIST_NAME_EN || String(row.ID);
    const user = {
      id: row.ID,
      userid: String(row.ID),
      name,
      section: 'DISTRICT',
      district: { id: String(row.ID), name },
    };
    const token = issueToken(user);
    return res.json({ success: true, token, ttlHours: TTL_HOURS, user });
  };
}

module.exports = {
  issueToken,
  verifyToken,
  requireAuth,
  loginHandler,
  districtLoginHandler,
};
