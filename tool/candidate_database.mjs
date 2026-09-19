// Candidate-only connection. Never loads the current runtime .env or logs secrets.
import { readFile } from 'node:fs/promises';
import { parseEnv } from 'node:util';
import { createRequire } from 'node:module';

export async function connectCandidate() {
  const env = parseEnv(await readFile(new URL('../integration-api/.env.candidate', import.meta.url), 'utf8'));
  let url;
  try { url = new URL(env.CANDIDATE_DATABASE_URL); }
  catch { throw new Error('CANDIDATE_CONFIG_REQUIRED'); }
  if (!['postgres:', 'postgresql:'].includes(url.protocol) ||
      !/^ep-soft-waterfall-b32kjeu0(?:-pooler)?\./.test(url.hostname) ||
      !url.hostname.endsWith('.neon.tech') ||
      url.pathname !== '/lms_mobile_learning_candidate' ||
      (url.port && url.port !== '5432') || !url.username || !url.password) {
    throw new Error('CANDIDATE_TARGET_REJECTED');
  }
  const require = createRequire(new URL('../integration-api/package.json', import.meta.url));
  let pg;
  try { pg = require('pg'); }
  catch { pg = createRequire('D:/DoAnTotNghiep/integration-api/package.json')('pg'); }
  const client = new pg.Client({ host: url.hostname, port: 5432,
    user: decodeURIComponent(url.username), password: decodeURIComponent(url.password),
    database: 'lms_mobile_learning_candidate', ssl: { rejectUnauthorized: true },
    enableChannelBinding: true, connectionTimeoutMillis: 20000,
    statement_timeout: 60000, application_name: 'dlu-isolated-candidate-verification' });
  client.on('error', () => {}); // Operations still reject; never emit raw credentials/errors.
  try { await client.connect(); return client; }
  catch (error) { await client.end().catch(() => {}); throw error; }
}

export function safeFailure(error) {
  const code = /^[A-Z0-9_]{3,80}$/.test(error.code ?? '') ? error.code
    : /^[A-Z_]{5,80}$/.test(error.message ?? '') ? error.message : 'CANDIDATE_OPERATION_FAILED';
  const safeObject = value => /^[a-zA-Z0-9_]{1,80}$/.test(value ?? '') ? value : undefined;
  return { status: 'FAIL', code, table: safeObject(error.table),
    constraint: safeObject(error.constraint), position: /^\d+$/.test(error.position ?? '') ? error.position : undefined };
}
