// Local-only candidate import preparation. Never reads credentials or original .env.
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';

const input = 'D:/DoAnTotNghiep-group';
const output = resolve('database/candidate');
const originalSchema = await readFile(resolve(input, 'lms_mobile_learning_schema.sql'));
if (createHash('sha256').update(originalSchema).digest('hex') !==
    'cbcf93bf99bb3fe3153980ddc9ca0e976f374b26fd3c436e30e9cee0e07a1867') {
  throw new Error('SCHEMA_CHANGED_REVIEW_REQUIRED');
}
function portable(sql) {
  const result = sql.replaceAll('\r\n', '\n')
    .replace(/^\\(?:un)?restrict [^\n]+\n/gm, '')
    .replace(/^SET row_security = off;\n/gm, '');
  if (/^\\/m.test(result)) throw new Error('UNSUPPORTED_PSQL_DIRECTIVE');
  if (/^(?:DROP|TRUNCATE|DELETE|UPDATE|GRANT|REVOKE|ALTER ROLE|CREATE ROLE)\b/m.test(result)) {
    throw new Error('UNEXPECTED_MUTATION_IN_INPUT');
  }
  return result;
}
const schema = portable(originalSchema.toString('utf8'));
const originalSeed = await readFile(resolve(input, 'lms_mobile_learning_mock_data.sql'), 'utf8');
let users = 0;
let enrolments = 0;
const seed = portable(originalSeed).replace(
  /^INSERT INTO lms\.("user"|enrol) \(([^\n]+)\) VALUES \(([^\n]+)\);$/gm,
  (line, table, columnText, valueText) => {
    const columns = columnText.split(',').map(v => v.trim());
    const values = valueText.match(/'(?:''|[^'])*'|[^,]+/g)?.map(v => v.trim());
    if (!values || values.length !== columns.length) throw new Error('SEED_PARSE_FAILED');
    for (const field of ['password', 'secret']) {
      const index = columns.indexOf(field);
      if (index >= 0) values[index] = 'NULL';
    }
    if (table === '"user"') users++; else enrolments++;
    return `INSERT INTO lms.${table} (${columnText}) VALUES (${values.join(', ')});`;
  },
);
if (users !== 18 || seed.includes('mock_password')) throw new Error('SANITIZATION_FAILED');
const postDataAt = schema.search(/^--\n-- Name: [^\n]+; Type: (?:CONSTRAINT|INDEX|FK CONSTRAINT);/m);
if (postDataAt < 0) throw new Error('POST_DATA_BOUNDARY_NOT_FOUND');
const restore = `BEGIN;
DO $$ BEGIN
  IF current_database() <> 'lms_mobile_learning_candidate' THEN
    RAISE EXCEPTION 'CANDIDATE_DATABASE_REQUIRED';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname IN ('lms','app','derived')) THEN
    RAISE EXCEPTION 'CANDIDATE_MUST_BE_EMPTY';
  END IF;
END $$;
${schema.slice(0, postDataAt)}
${seed}
${schema.slice(postDataAt)}
COMMIT;
SELECT 'CANDIDATE_RESTORE_COMPLETE' AS result;
`;
await mkdir(output, { recursive: true });
await writeFile(resolve(output, 'mock_data_sanitized.sql'), seed, { flag: 'wx' });
await writeFile(resolve(output, 'restore_candidate.sql'), restore, { flag: 'wx' });
console.log(JSON.stringify({ prepared: true, usersSanitized: users,
  enrolmentsSanitized: enrolments, bytes: Buffer.byteLength(restore),
  originalFiles: 'UNCHANGED', credentials: 'NOT_READ' }));
