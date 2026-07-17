/**
 * Pure logic tests — mirrors survey_web masters path + DTO mapping rules.
 * Run: node scripts/test-masters-logic.mjs
 */
import assert from 'node:assert/strict';

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  ✓ ${name}`);
  } catch (err) {
    failed += 1;
    console.error(`  ✗ ${name}`);
    console.error(`    ${err.message}`);
  }
}

function pickId(...candidates) {
  for (const value of candidates) {
    const trimmed = value?.toString().trim();
    if (trimmed) return trimmed;
  }
  return '';
}

function mapDistrict(item) {
  return {
    id: pickId(item.DistID, item.ID),
    name: item.DistName?.trim() || item.DistNameEn?.trim() || pickId(item.DistID, item.ID),
  };
}

function mapBlock(item) {
  return {
    id: pickId(item.ID, item.BlockID),
    name: item.BlockName?.trim() || item.BlockNameEn?.trim() || pickId(item.ID, item.BlockID),
  };
}

function mapUrbanBody(item) {
  return {
    id: pickId(item.ID, item.UrbanBodyID, item.BodyID),
    name:
      item.UrbanBodyName?.trim() ||
      item.UrbanBodyNameEn?.trim() ||
      pickId(item.ID, item.UrbanBodyID, item.BodyID),
  };
}

function mapRuralPs(item) {
  return {
    id: pickId(item.ID, item.PSID),
    name: item.PSNoName?.trim() || item.PSName?.trim() || pickId(item.ID, item.PSID),
  };
}

function mapUrbanPs(item) {
  return {
    id: pickId(item.ID, item.PSID),
    name: item.PSNoName?.trim() || item.PSName?.trim() || pickId(item.ID, item.PSID),
  };
}

/** Same path selection as MastersApiService for rural blocks. */
function ruralBlockListPath({ urbanRural, bodyId, distId }) {
  const scope = (urbanRural || '').toUpperCase();
  if (scope === 'U' || scope === 'URBAN') {
    return null; // urban login must not call block-list with municipal BodyID
  }
  if (bodyId) {
    return `/api/Masters/block-list/${encodeURIComponent(bodyId)}`;
  }
  if (distId) {
    return `/api/Masters/block-list/${encodeURIComponent(distId)}`;
  }
  return null;
}

function ruralRpsPath(blockId) {
  const id = (blockId || '').trim();
  if (!id) return null;
  return `/api/Masters/rps-list/${encodeURIComponent(id)}`;
}

function urbanUbPath({ urbanRural, bodyId }) {
  const scope = (urbanRural || '').toUpperCase();
  if (scope === 'R' || scope === 'RURAL') return null;
  if (!bodyId) return null;
  return `/api/Masters/ub-list/${encodeURIComponent(bodyId)}`;
}

function urbanUpsPath(bodyId) {
  const id = (bodyId || '').trim();
  if (!id) return null;
  return `/api/Masters/ups-list/${encodeURIComponent(id)}`;
}

const RURAL_DIST = 'A1BD3F67-ED9D-44B5-88A4-7A164AADA536';
const RURAL_BODY = '1A5BCA6F-D00C-4C6D-BEEF-C6A878F44A7A';

console.log('\n=== Masters logic unit tests ===\n');

test('mapDistrict uses DistID when present', () => {
  const opt = mapDistrict({ DistID: 'd1', ID: 'd2', DistName: 'भोपाल' });
  assert.equal(opt.id, 'd1');
  assert.equal(opt.name, 'भोपाल');
});

test('mapDistrict falls back to ID (mpsec districts response)', () => {
  const opt = mapDistrict({
    ID: RURAL_DIST,
    DistName: 'भोपाल',
    DistNameEn: 'BHOPAL ',
  });
  assert.equal(opt.id, RURAL_DIST);
  assert.equal(opt.name, 'भोपाल');
});

test('mapBlock uses ID from block-list response', () => {
  const opt = mapBlock({
    ID: RURAL_BODY,
    BlockName: 'बैरसिया ',
    BlockNameEn: 'BERASIA',
  });
  assert.equal(opt.id, RURAL_BODY);
  assert.ok(opt.name.includes('बैरसिया') || opt.name === 'BERASIA');
});

test('mapUrbanBody prefers ID / UrbanBodyID', () => {
  const opt = mapUrbanBody({
    ID: 'ub1',
    UrbanBodyName: 'नगर निगम',
  });
  assert.equal(opt.id, 'ub1');
  assert.equal(opt.name, 'नगर निगम');
});

test('mapRuralPs prefers PSNoName', () => {
  const opt = mapRuralPs({ ID: 'ps1', PSNoName: '12 - School', PSName: 'School' });
  assert.equal(opt.id, 'ps1');
  assert.equal(opt.name, '12 - School');
});

test('mapUrbanPs prefers PSNoName', () => {
  const opt = mapUrbanPs({ ID: 'ups1', PSNoName: '1 - Ward', PSName: 'Ward' });
  assert.equal(opt.id, 'ups1');
  assert.equal(opt.name, '1 - Ward');
});

test('rural block-list path uses BodyID (not DistID)', () => {
  const path = ruralBlockListPath({
    urbanRural: 'R',
    bodyId: RURAL_BODY,
    distId: RURAL_DIST,
  });
  assert.equal(path, `/api/Masters/block-list/${RURAL_BODY}`);
  assert.ok(!path.includes(RURAL_DIST));
});

test('rural block-list path is null for urban login', () => {
  const path = ruralBlockListPath({
    urbanRural: 'U',
    bodyId: 'urban-body-guid',
    distId: RURAL_DIST,
  });
  assert.equal(path, null);
});

test('rural block-list falls back to DistID only when BodyID missing', () => {
  const path = ruralBlockListPath({
    urbanRural: 'R',
    bodyId: '',
    distId: RURAL_DIST,
  });
  assert.equal(path, `/api/Masters/block-list/${RURAL_DIST}`);
});

test('rural rps-list uses selected blockId (= login BodyID)', () => {
  const path = ruralRpsPath(RURAL_BODY);
  assert.equal(path, `/api/Masters/rps-list/${RURAL_BODY}`);
});

test('rural rps-list empty blockId → null', () => {
  assert.equal(ruralRpsPath(''), null);
  assert.equal(ruralRpsPath('   '), null);
});

test('urban ub-list uses BodyID', () => {
  const path = urbanUbPath({ urbanRural: 'U', bodyId: 'ub-guid' });
  assert.equal(path, '/api/Masters/ub-list/ub-guid');
});

test('urban ub-list blocked for rural login', () => {
  assert.equal(urbanUbPath({ urbanRural: 'R', bodyId: RURAL_BODY }), null);
});

test('urban ups-list uses BodyID', () => {
  assert.equal(urbanUpsPath('ub-guid'), '/api/Masters/ups-list/ub-guid');
});

test('unknown urbanRural still allows BodyID for rural block path', () => {
  // App treats non-U as eligible for rural BodyID (missing flag resilience)
  const path = ruralBlockListPath({
    urbanRural: '',
    bodyId: RURAL_BODY,
    distId: RURAL_DIST,
  });
  assert.equal(path, `/api/Masters/block-list/${RURAL_BODY}`);
});

console.log(`\nLogic: ${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
