'use strict';

/**
 * Creates the SURVEY_* tables and seeds the checklist questions.
 * Run:  node setup.js
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

(async () => {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'MPSECIEMS',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
    multipleStatements: true,
  });

  const sql = fs.readFileSync(
    path.join(__dirname, 'migrations', '001_survey.sql'),
    'utf8',
  );
  await conn.query(sql);

  // Patch tables that already existed before tracking columns were added.
  const db = process.env.DB_NAME || 'MPSECIEMS';
  const ensureColumn = async (table, column, definition) => {
    const [[{ n }]] = await conn.query(
      `SELECT COUNT(*) AS n FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
      [db, table, column],
    );
    if (!n) {
      await conn.query(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
      console.log(`  + ${table}.${column}`);
    }
  };

  await ensureColumn('SURVEY_SUBMISSIONS', 'STATUS', `VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED'`);
  await ensureColumn('SURVEY_SUBMISSIONS', 'IP_ADDRESS', 'VARCHAR(64) NULL');
  await ensureColumn('SURVEY_SUBMISSIONS', 'USER_AGENT', 'VARCHAR(512) NULL');
  await ensureColumn('SURVEY_SUBMISSIONS', 'APP_VERSION', 'VARCHAR(40) NULL');
  await ensureColumn('SURVEY_SUBMISSIONS', 'DEVICE_INFO', 'VARCHAR(255) NULL');
  await ensureColumn(
    'SURVEY_SUBMISSIONS',
    'UPDATED_AT',
    'DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  );
  await ensureColumn('SURVEY_ANSWERS', 'CREATED_AT', 'DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP');

  const [[q]] = await conn.query('SELECT COUNT(*) AS n FROM SURVEY_QUESTIONS');
  console.log(`✓ Survey tables ready. SURVEY_QUESTIONS rows: ${q.n}`);
  await conn.end();
})().catch((e) => {
  console.error('Setup failed:', e.code || '', e.sqlMessage || e.message);
  process.exit(1);
});
