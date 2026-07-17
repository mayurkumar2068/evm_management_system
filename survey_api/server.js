'use strict';

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const { requireAuth, loginHandler, districtLoginHandler } = require('./auth');

/* ===========================================================================
 *  MPSECIEMS Survey API  (mapped to the ACTUAL database schema)
 *
 *  Rural : Districts → BLOCKS → PANCHAYATS → RPSBUILDINGS (मतदान केंद्र)
 *  Urban : Districts → NNN_TYPES → NNN → UPSBUILDINGS    (मतदान केंद्र)
 *
 *  Names: prefer Hindi (*_NAME) with English (*_NAME_EN) fallback.
 *  Survey checklist + submissions use the SURVEY_* tables (see migrations/).
 * =========================================================================== */

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'MPSECIEMS',
  waitForConnections: true,
  connectionLimit: 10,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
});

const MAX_IMAGES = Number(process.env.MAX_IMAGES || 10);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const rows = async (sql, params = []) => {
  const [r] = await pool.query(sql, params);
  return r;
};
const toOptions = (r) =>
  r.map((x) => ({ id: String(x.id), name: String(x.name ?? x.id) }));
const asHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Language: `?lang=en` or Accept-Language header; defaults to Hindi.
const langOf = (req) =>
  (String(req.query.lang || '') || String(req.headers['accept-language'] || ''))
    .toLowerCase()
    .startsWith('en')
    ? 'en'
    : 'hi';
// Pick a localized name column order (Hindi-first or English-first).
const nameExpr = (lang, hi, en, fallback = 'ID') =>
  lang === 'en'
    ? `COALESCE(NULLIF(${en},''), NULLIF(${hi},''), ${fallback})`
    : `COALESCE(NULLIF(${hi},''), NULLIF(${en},''), ${fallback})`;

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
const app = express();
app.set('trust proxy', true); // capture real client IP behind the proxy
app.use(cors());
app.use(express.json({ limit: '25mb' })); // base64 photos

const clientIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() ||
  req.socket?.remoteAddress ||
  null;
const userAgent = (req) => (req.headers['user-agent'] || '').slice(0, 512) || null;

app.get('/api/health', asHandler(async (_req, res) => {
  await rows('SELECT 1');
  res.json({ ok: true, db: process.env.DB_NAME || 'MPSECIEMS' });
}));

// ---- Auth (public) ---------------------------------------------------------
app.post('/api/auth/login', asHandler(loginHandler(pool)));
app.post('/api/auth/district-login', asHandler(districtLoginHandler(pool)));

// Public district list for the login dropdown (no token exists yet at login).
app.get('/api/auth/districts', asHandler(async (req, res) => {
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id, ${nameExpr(lang, 'DIST_NAME', 'DIST_NAME_EN')} AS name
       FROM Districts ORDER BY DIST_NO`,
  );
  res.json(toOptions(r));
}));

app.get('/api/auth/me', requireAuth, (req, res) => res.json({ user: req.auth }));

// Location master lookups are public (read-only dropdown data). Survey
// checklist + submit still require a valid token.
app.use('/api/survey', requireAuth);

// ---- Districts -------------------------------------------------------------
app.get('/api/locations/districts', asHandler(async (req, res) => {
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id, ${nameExpr(lang, 'DIST_NAME', 'DIST_NAME_EN')} AS name
       FROM Districts ORDER BY DIST_NO`,
  );
  res.json(toOptions(r));
}));

// ---- Rural: BLOCKS → PANCHAYATS → RPSBUILDINGS -----------------------------
app.get('/api/locations/blocks', asHandler(async (req, res) => {
  const districtId = String(req.query.districtId || '');
  if (!districtId) return res.json([]);
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id, ${nameExpr(lang, 'BLOCK_NAME', 'BLOCK_NAME_EN')} AS name
       FROM BLOCKS WHERE DIST_ID = ? ORDER BY BLOCK_NO`,
    [districtId],
  );
  res.json(toOptions(r));
}));

app.get('/api/locations/panchayats', asHandler(async (req, res) => {
  const blockId = String(req.query.blockId || '');
  if (!blockId) return res.json([]);
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id, ${nameExpr(lang, 'PANCHYT_NAME', 'PANCHYT_NAME_EN')} AS name
       FROM PANCHAYATS WHERE BLOCK_ID = ? ORDER BY PANCHYT_NO`,
    [blockId],
  );
  res.json(toOptions(r));
}));

// Booths (rural) = RPSBUILDINGS linked to the chosen panchayat's wards.
// RWARDS.RPS_ID is empty in this DB, so we match on the composite natural key
// (DIST_NO, BLOCK_NO, RPSBUILDING_NO).
app.get('/api/locations/rural-booths', asHandler(async (req, res) => {
  const panchayatId = String(req.query.panchayatId || '');
  if (!panchayatId) return res.json([]);
  const lang = langOf(req);
  const r = await rows(
    `SELECT b.ID AS id,
            ${nameExpr(lang, 'b.RPSBUILDING_NAME', 'b.RPSBUILDING_NAME_EN', 'b.ID')} AS name,
            b.RPSBUILDING_NO AS sort
       FROM RPSBUILDINGS b
       JOIN RWARDS w
         ON w.DIST_NO = b.DIST_NO
        AND w.BLOCK_NO = b.BLOCK_NO
        AND w.RPSBUILDING_NO = b.RPSBUILDING_NO
      WHERE w.PANCHYT_ID = ?
      GROUP BY b.ID, name, sort
      ORDER BY sort`,
    [panchayatId],
  );
  res.json(toOptions(r));
}));

// ---- Urban: NNN_TYPES → NNN → UPSBUILDINGS ---------------------------------
app.get('/api/locations/body-types', asHandler(async (req, res) => {
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id,
            ${nameExpr(lang, 'NNN_TYPE_DESC', 'NNN_TYPE_DESC_EN', 'NNN_TYPE')} AS name
       FROM NNN_TYPES ORDER BY NNN_TYPE`,
  );
  res.json(toOptions(r));
}));

// NNN (urban body) is filtered by BOTH district and body-type.
app.get('/api/locations/bodies', asHandler(async (req, res) => {
  const districtId = String(req.query.districtId || '');
  const bodyTypeId = String(req.query.bodyTypeId || '');
  if (!districtId || !bodyTypeId) return res.json([]);
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id, ${nameExpr(lang, 'NNN_NAME', 'NNN_NAME_EN')} AS name
       FROM NNN WHERE DIST_ID = ? AND NNN_TYPE_ID = ? ORDER BY NNN_NO`,
    [districtId, bodyTypeId],
  );
  res.json(toOptions(r));
}));

// Booths (urban) = UPSBUILDINGS of the chosen body.
app.get('/api/locations/urban-booths', asHandler(async (req, res) => {
  const bodyId = String(req.query.bodyId || '');
  if (!bodyId) return res.json([]);
  const lang = langOf(req);
  const r = await rows(
    `SELECT ID AS id, ${nameExpr(lang, 'UPSBUILDING_NAME', 'UPSBUILDING_NAME_EN')} AS name
       FROM UPSBUILDINGS WHERE NNN_ID = ? ORDER BY UPSBUILDING_NO`,
    [bodyId],
  );
  res.json(toOptions(r));
}));

// ---- Checklist -------------------------------------------------------------
app.get('/api/survey/checklist', asHandler(async (req, res) => {
  const lang = langOf(req);
  const titleExpr =
    lang === 'en'
      ? `COALESCE(NULLIF(QUESTION_EN,''), QUESTION_HI)`
      : `COALESCE(NULLIF(QUESTION_HI,''), QUESTION_EN)`;
  const r = await rows(
    `SELECT ID AS surveyId, ${titleExpr} AS title, PHOTO_REQUIRED AS photoRequired
       FROM SURVEY_QUESTIONS WHERE IS_ACTIVE = 1 ORDER BY SORT_ORDER`,
  );
  res.json({
    maxImages: MAX_IMAGES,
    items: r.map((x) => ({
      surveyId: String(x.surveyId),
      title: String(x.title),
      photoRequired: Boolean(x.photoRequired),
    })),
  });
}));

// ---- Submit ----------------------------------------------------------------
app.post('/api/survey/submit', asHandler(async (req, res) => {
  const p = req.body || {};
  const loc = p.location || {};
  const ip = clientIp(req);
  const ua = userAgent(req);
  const items = Array.isArray(p.surveyItems) ? p.surveyItems : [];
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [result] = await conn.query(
      `INSERT INTO SURVEY_SUBMISSIONS
         (AREA_TYPE, DIST_ID, BLOCK_ID, PANCHYT_ID, NNN_ID, BOOTH_ID,
          LATITUDE, LONGITUDE, REMARKS, STATUS,
          SUBMITTED_BY, IP_ADDRESS, USER_AGENT, APP_VERSION, DEVICE_INFO)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        p.areaType || null,
        loc.districtId || null,
        loc.blockId || null,
        loc.panchayatId || null,
        loc.bodyId || null,
        loc.boothId || null,
        p.latitude || null,
        p.longitude || null,
        (p.remarks || '').trim() || null,
        'SUBMITTED',
        p.submittedBy || null,
        ip,
        ua,
        p.appVersion || null,
        (p.deviceInfo || '').slice(0, 255) || null,
      ],
    );
    const submissionId = result.insertId;

    for (const item of items) {
      await conn.query(
        `INSERT INTO SURVEY_ANSWERS (SUBMISSION_ID, QUESTION_ID, CHECKED, IMAGE)
         VALUES (?,?,?,?)`,
        [submissionId, item.surveyId, item.checked ? 1 : 0, item.image || null],
      );
    }

    await conn.query(
      `INSERT INTO SURVEY_SUBMISSION_LOGS
         (SUBMISSION_ID, ACTION, DETAIL, IP_ADDRESS, USER_AGENT)
       VALUES (?,?,?,?,?)`,
      [
        submissionId,
        'CREATED',
        `area=${p.areaType || '-'}, booth=${loc.boothId || '-'}, answers=${items.length}`,
        ip,
        ua,
      ],
    );

    await conn.commit();
    console.log(
      `[submit] #${submissionId} area=${p.areaType} booth=${loc.boothId} ` +
        `answers=${items.length} ip=${ip}`,
    );
    res.json({
      success: true,
      referenceId: `MP-${submissionId}`,
      message:
        langOf(req) === 'en'
          ? 'Survey submitted successfully.'
          : 'सर्वे सफलतापूर्वक जमा हुआ।',
    });
  } catch (e) {
    await conn.rollback();
    // Best-effort failure log (outside the rolled-back transaction).
    pool
      .query(
        `INSERT INTO SURVEY_SUBMISSION_LOGS (SUBMISSION_ID, ACTION, DETAIL, IP_ADDRESS, USER_AGENT)
         VALUES (NULL, 'ERROR', ?, ?, ?)`,
        [(e.sqlMessage || e.message || '').slice(0, 1000), ip, ua],
      )
      .catch(() => {});
    throw e;
  } finally {
    conn.release();
  }
}));

// Lightweight tracking view: recent submissions with answer counts.
app.get('/api/survey/submissions', asHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit || 50), 200);
  const r = await rows(
    `SELECT s.ID AS id, s.AREA_TYPE AS areaType, s.BOOTH_ID AS boothId,
            s.STATUS AS status, s.LATITUDE AS latitude, s.LONGITUDE AS longitude,
            s.IP_ADDRESS AS ip, s.CREATED_AT AS createdAt, s.UPDATED_AT AS updatedAt,
            (SELECT COUNT(*) FROM SURVEY_ANSWERS a WHERE a.SUBMISSION_ID = s.ID) AS answers
       FROM SURVEY_SUBMISSIONS s
      ORDER BY s.ID DESC
      LIMIT ?`,
    [limit],
  );
  res.json(r);
}));

// Central error handler
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('[api-error]', err.code || '', err.sqlMessage || err.message);
  res.status(500).json({
    error: 'DB_ERROR',
    code: err.code,
    message: err.sqlMessage || err.message,
  });
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => {
  console.log(`MPSECIEMS Survey API → http://localhost:${PORT}`);
  console.log(`Health: http://localhost:${PORT}/api/health`);
});
