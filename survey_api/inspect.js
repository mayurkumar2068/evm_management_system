'use strict';

/**
 * MPSECIEMS schema inspector.
 *
 * Reads the ACTUAL schema from information_schema (no assumptions) and writes:
 *   - schema-report.json   (structured: tables, columns, PKs, FKs, indexes, rows)
 *   - schema-report.md     (human-readable report)
 *
 * Run:  node inspect.js
 * Then share / let the report files be read for mapping.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

const DB = process.env.DB_NAME || 'MPSECIEMS';

(async () => {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: DB,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
  });

  // --- Tables (+ engine, approx rows, comment) ---
  const [tables] = await conn.query(
    `SELECT TABLE_NAME, ENGINE, TABLE_ROWS, TABLE_COMMENT
       FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE'
      ORDER BY TABLE_NAME`,
    [DB],
  );

  // --- Columns ---
  const [columns] = await conn.query(
    `SELECT TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE, COLUMN_TYPE,
            IS_NULLABLE, COLUMN_KEY, EXTRA, COLUMN_DEFAULT, COLUMN_COMMENT
       FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = ?
      ORDER BY TABLE_NAME, ORDINAL_POSITION`,
    [DB],
  );

  // --- Foreign keys ---
  const [fks] = await conn.query(
    `SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
            REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
       FROM information_schema.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL
      ORDER BY TABLE_NAME, COLUMN_NAME`,
    [DB],
  );

  // --- Indexes ---
  const [indexes] = await conn.query(
    `SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME
       FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = ?
      ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX`,
    [DB],
  );

  await conn.end();

  // ---- Build structured model ----
  const byTable = {};
  for (const t of tables) {
    byTable[t.TABLE_NAME] = {
      engine: t.ENGINE,
      approxRows: t.TABLE_ROWS,
      comment: t.TABLE_COMMENT || '',
      columns: [],
      primaryKey: [],
      foreignKeys: [],
      indexes: {},
    };
  }
  for (const c of columns) {
    const t = byTable[c.TABLE_NAME];
    if (!t) continue;
    t.columns.push({
      name: c.COLUMN_NAME,
      type: c.COLUMN_TYPE,
      nullable: c.IS_NULLABLE === 'YES',
      key: c.COLUMN_KEY,
      extra: c.EXTRA,
      default: c.COLUMN_DEFAULT,
      comment: c.COLUMN_COMMENT || '',
    });
    if (c.COLUMN_KEY === 'PRI') t.primaryKey.push(c.COLUMN_NAME);
  }
  for (const f of fks) {
    byTable[f.TABLE_NAME]?.foreignKeys.push({
      column: f.COLUMN_NAME,
      constraint: f.CONSTRAINT_NAME,
      references: `${f.REFERENCED_TABLE_NAME}.${f.REFERENCED_COLUMN_NAME}`,
    });
  }
  for (const ix of indexes) {
    const t = byTable[ix.TABLE_NAME];
    if (!t) continue;
    (t.indexes[ix.INDEX_NAME] ||= { unique: ix.NON_UNIQUE === 0, columns: [] })
      .columns.push(ix.COLUMN_NAME);
  }

  const report = { database: DB, generatedAt: new Date().toISOString(), tables: byTable };

  // ---- Write JSON ----
  const jsonPath = path.join(__dirname, 'schema-report.json');
  fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));

  // ---- Write Markdown ----
  const lines = [];
  lines.push(`# ${DB} — Schema Report`);
  lines.push(`Generated: ${report.generatedAt}`);
  lines.push(`Total tables: ${tables.length}\n`);

  lines.push(`## Tables overview\n`);
  lines.push(`| Table | Rows (approx) | Columns | PK | FKs |`);
  lines.push(`| --- | --- | --- | --- | --- |`);
  for (const [name, t] of Object.entries(byTable)) {
    lines.push(
      `| ${name} | ${t.approxRows ?? ''} | ${t.columns.length} | ${t.primaryKey.join(', ')} | ${t.foreignKeys.length} |`,
    );
  }
  lines.push('');

  for (const [name, t] of Object.entries(byTable)) {
    lines.push(`## ${name}`);
    if (t.comment) lines.push(`> ${t.comment}`);
    lines.push(`Engine: ${t.engine} · Approx rows: ${t.approxRows ?? 'n/a'}\n`);
    lines.push(`| Column | Type | Null | Key | Extra | Default |`);
    lines.push(`| --- | --- | --- | --- | --- | --- |`);
    for (const c of t.columns) {
      lines.push(
        `| ${c.name} | ${c.type} | ${c.nullable ? 'Y' : 'N'} | ${c.key} | ${c.extra} | ${c.default ?? ''} |`,
      );
    }
    if (t.foreignKeys.length) {
      lines.push(`\n**Foreign keys:**`);
      for (const f of t.foreignKeys) lines.push(`- \`${f.column}\` → \`${f.references}\` (${f.constraint})`);
    }
    lines.push('');
  }

  const mdPath = path.join(__dirname, 'schema-report.md');
  fs.writeFileSync(mdPath, lines.join('\n'));

  console.log(`\n✓ Inspected ${tables.length} tables in ${DB}`);
  console.log(`✓ Wrote ${jsonPath}`);
  console.log(`✓ Wrote ${mdPath}`);
  console.log(`\nTables:\n  ${tables.map((t) => t.TABLE_NAME).join('\n  ')}\n`);
})().catch((e) => {
  console.error('\nInspect failed:', e.code || '', e.sqlMessage || e.message);
  if (e.code === 'ER_ACCESS_DENIED_ERROR') console.error('→ Check DB_USER / DB_PASSWORD in .env');
  if (e.code === 'ECONNREFUSED') console.error('→ Is MySQL running on the host/port in .env?');
  process.exit(1);
});
