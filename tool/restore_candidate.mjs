import { readFile } from 'node:fs/promises';
import { connectCandidate, safeFailure } from './candidate_database.mjs';

let client;
try {
  client = await connectCandidate();
  const { rows: [target] } = await client.query(`SELECT current_database() AS name,
    (SELECT count(*)::int FROM pg_namespace WHERE nspname IN ('lms','app','derived')) AS schemas`);
  if (target.name !== 'lms_mobile_learning_candidate' || target.schemas !== 0) {
    throw new Error('CANDIDATE_MUST_BE_EMPTY');
  }
  const sql = await readFile(new URL('../database/candidate/restore_candidate.sql', import.meta.url), 'utf8');
  if (!sql.startsWith('BEGIN;') || !sql.includes('CANDIDATE_MUST_BE_EMPTY') ||
      sql.includes('mock_password')) throw new Error('IMPORT_GUARD_FAILED');
  await client.query(sql);
  console.log(JSON.stringify({ restore: 'PASS', target: 'ISOLATED_CANDIDATE', runtimeModified: false }));
} catch (error) {
  await client?.query('ROLLBACK').catch(() => {});
  console.log(JSON.stringify(safeFailure(error)));
  process.exitCode = 1;
} finally { await client?.end().catch(() => {}); }
