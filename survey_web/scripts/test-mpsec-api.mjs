/**
 * Live mpsec API integration tests for survey_web masters cascade.
 *
 * Rural: login-survey-pass → districts/{DistID} → block-list/{BodyID} → rps-list/{BodyID}
 * Urban: login-survey-pass → districts/{DistID} → ub-list/{BodyID} → ups-list/{BodyID}
 *
 * Uses curl (mpsec TLS needs legacy renegotiation that Node fetch disables).
 *
 * Run: node scripts/test-mpsec-api.mjs
 * Env overrides: RURAL_USER RURAL_PASS URBAN_USER URBAN_PASS BASE_URL
 */
import { execFileSync } from 'node:child_process';
import { writeFileSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const BASE =
  (process.env.BASE_URL || 'https://mpsecerms.mp.gov.in/POElectionAPI').replace(/\/+$/, '');

const RURAL_USER = process.env.RURAL_USER || 'sr1';
const RURAL_PASS = process.env.RURAL_PASS || 'sr1';
const URBAN_USER = process.env.URBAN_USER || 'su1';
const URBAN_PASS = process.env.URBAN_PASS || 'su1';

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

function api(method, path, { token, body } = {}) {
  const url = `${BASE}${path.startsWith('/') ? path : `/${path}`}`;
  const args = ['-sS', '-w', '\n%{http_code}', '-X', method, url, '-H', 'Accept: application/json'];
  let bodyFile = null;
  if (token) {
    args.push('-H', `Authorization: Bearer ${token}`);
  }
  if (body !== undefined) {
    bodyFile = join(tmpdir(), `mpsec-test-${Date.now()}.json`);
    writeFileSync(bodyFile, JSON.stringify(body));
    args.push('-H', 'Content-Type: application/json', '--data-binary', `@${bodyFile}`);
  }
  try {
    const out = execFileSync('curl', args, { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
    const nl = out.lastIndexOf('\n');
    const text = nl >= 0 ? out.slice(0, nl) : out;
    const status = Number(nl >= 0 ? out.slice(nl + 1).trim() : '0');
    let json;
    try {
      json = JSON.parse(text);
    } catch {
      json = { Status: false, Message: text.slice(0, 200), Data: null };
    }
    return { status, json };
  } finally {
    if (bodyFile) {
      try {
        unlinkSync(bodyFile);
      } catch {
        /* ignore */
      }
    }
  }
}

function login(userName, password) {
  const { status, json } = api('POST', '/api/Account/login-survey-pass', {
    body: { userName, password },
  });
  return { status, json, data: json?.Data || null };
}

function runRural() {
  console.log('\n=== RURAL live API (sr1) ===\n');

  const loginRes = login(RURAL_USER, RURAL_PASS);
  ok('login Status true', loginRes.json?.Status === true, loginRes.json?.Message);
  ok('login HTTP 200', loginRes.status === 200);
  const d = loginRes.data;
  ok('AccessToken present', Boolean(d?.AccessToken));
  ok('UrbanRural is R', String(d?.UrbanRural || '').toUpperCase() === 'R', `got ${d?.UrbanRural}`);
  ok('DistID present', Boolean(d?.DistID));
  ok('BodyID present', Boolean(d?.BodyID));

  if (!d?.AccessToken || !d?.DistID || !d?.BodyID) {
    console.error('  (skip rural masters — login incomplete)');
    return;
  }

  const token = d.AccessToken;
  const distId = d.DistID;
  const bodyId = d.BodyID;

  const dist = api('GET', `/api/Masters/districts/${encodeURIComponent(distId)}`, { token });
  ok('districts Status true', dist.json?.Status === true, dist.json?.Message);
  const distRows = Array.isArray(dist.json?.Data) ? dist.json.Data : [];
  ok('districts has ≥1 row', distRows.length >= 1, `len=${distRows.length}`);
  if (distRows[0]) {
    const id = distRows[0].DistID || distRows[0].ID;
    ok('district ID matches DistID', id === distId, `api=${id}`);
  }

  const blocksBody = api('GET', `/api/Masters/block-list/${encodeURIComponent(bodyId)}`, {
    token,
  });
  ok('block-list/{BodyID} Status true', blocksBody.json?.Status === true, blocksBody.json?.Message);
  const blockRows = Array.isArray(blocksBody.json?.Data) ? blocksBody.json.Data : [];
  ok('block-list/{BodyID} has ≥1 row', blockRows.length >= 1, `len=${blockRows.length}`);
  if (blockRows[0]) {
    ok(
      'block ID equals login BodyID',
      blockRows[0].ID === bodyId || blockRows[0].BlockID === bodyId,
      `block=${blockRows[0].ID}`,
    );
  }

  const blocksDist = api('GET', `/api/Masters/block-list/${encodeURIComponent(distId)}`, {
    token,
  });
  const distBlockRows = Array.isArray(blocksDist.json?.Data) ? blocksDist.json.Data : [];
  ok(
    'block-list/{DistID} is empty (app must not use DistID first)',
    distBlockRows.length === 0,
    `len=${distBlockRows.length}`,
  );

  const rps = api('GET', `/api/Masters/rps-list/${encodeURIComponent(bodyId)}`, { token });
  ok('rps-list/{BodyID} Status true', rps.json?.Status === true, rps.json?.Message);
  const rpsRows = Array.isArray(rps.json?.Data) ? rps.json.Data : [];
  ok('rps-list/{BodyID} has booths', rpsRows.length > 0, `len=${rpsRows.length}`);

  const questions = api('GET', '/api/PSSurvey/survey_questions', { token });
  const qData = questions.json?.Data;
  const qRows = Array.isArray(qData) ? qData : Array.isArray(questions.json) ? questions.json : [];
  ok(
    'survey_questions returns list',
    questions.status === 200 && questions.json?.Status !== false,
    `status=${questions.status} len=${qRows.length}`,
  );
  ok('survey_questions has items', qRows.length > 0, `len=${qRows.length}`);

  if (qRows.length > 0 && blockRows[0]) {
    const qid = qRows[0].Id || qRows[0].id;
    const psid = rpsRows[0]?.ID || rpsRows[0]?.id || bodyId;
    const save = api('POST', '/api/PSSurvey/save_survey_answer', {
      token,
      body: {
        id: null,
        questionId: qid,
        answerYN: false,
        answerText: 'No',
        remark: 'automated-test',
        psType: 'R',
        psId: psid,
        lat: 23.25,
        long: 77.41,
        userId: d.UserId,
        photo: null,
      },
    });
    ok('save_survey_answer Status true', save.json?.Status === true, save.json?.Message);
    const saveId =
      typeof save.json?.Data === 'string'
        ? save.json.Data
        : save.json?.Data?.Id || save.json?.Id || '';
    ok('save_survey_answer returns answer Id in Data', Boolean(saveId), `Data=${save.json?.Data}`);
    ok(
      'app must map Status/Data → Success/Id (not raw Success)',
      save.json?.Success === undefined && save.json?.Status === true,
    );
  }

  console.log(`\n  Rural BodyID (for app): ${bodyId}`);
  console.log(`  Rural DistID: ${distId}`);
  console.log(`  Booths: ${rpsRows.length}`);
}

function runUrban() {
  console.log('\n=== URBAN live API (su1) ===\n');

  const loginRes = login(URBAN_USER, URBAN_PASS);
  ok('login Status true', loginRes.json?.Status === true, loginRes.json?.Message);
  ok('login HTTP 200', loginRes.status === 200);
  const d = loginRes.data;
  ok('AccessToken present', Boolean(d?.AccessToken));
  ok('UrbanRural is U', String(d?.UrbanRural || '').toUpperCase() === 'U', `got ${d?.UrbanRural}`);
  ok('DistID present', Boolean(d?.DistID));
  ok('BodyID present', Boolean(d?.BodyID));

  if (!d?.AccessToken || !d?.DistID || !d?.BodyID) {
    console.error('  (skip urban masters — login incomplete)');
    return;
  }

  const token = d.AccessToken;
  const distId = d.DistID;
  const bodyId = d.BodyID;

  const dist = api('GET', `/api/Masters/districts/${encodeURIComponent(distId)}`, { token });
  ok('districts Status true', dist.json?.Status === true, dist.json?.Message);
  const distRows = Array.isArray(dist.json?.Data) ? dist.json.Data : [];
  ok('districts has ≥1 row', distRows.length >= 1, `len=${distRows.length}`);

  const ub = api('GET', `/api/Masters/ub-list/${encodeURIComponent(bodyId)}`, { token });
  ok('ub-list/{BodyID} Status true', ub.json?.Status === true, ub.json?.Message);
  const ubRows = Array.isArray(ub.json?.Data) ? ub.json.Data : [];
  ok('ub-list/{BodyID} has ≥1 row', ubRows.length >= 1, `len=${ubRows.length}`);

  const ups = api('GET', `/api/Masters/ups-list/${encodeURIComponent(bodyId)}`, { token });
  ok('ups-list/{BodyID} Status true', ups.json?.Status === true, ups.json?.Message);
  const upsRows = Array.isArray(ups.json?.Data) ? ups.json.Data : [];
  ok('ups-list/{BodyID} has booths', upsRows.length > 0, `len=${upsRows.length}`);

  const wrongBlock = api('GET', `/api/Masters/block-list/${encodeURIComponent(bodyId)}`, {
    token,
  });
  const wrongRows = Array.isArray(wrongBlock.json?.Data) ? wrongBlock.json.Data : [];
  console.log(`  (info) urban BodyID → block-list len=${wrongRows.length}`);

  console.log(`\n  Urban BodyID: ${bodyId}`);
  console.log(`  Urban DistID: ${distId}`);
  console.log(`  Booths: ${upsRows.length}`);
}

function main() {
  console.log(`BASE = ${BASE}`);
  try {
    runRural();
    runUrban();
  } catch (err) {
    failed += 1;
    console.error('\nFatal:', err);
  }
  console.log(`\n=== SUMMARY: ${passed} passed, ${failed} failed ===\n`);
  process.exit(failed > 0 ? 1 : 0);
}

main();
