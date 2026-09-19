// Creates LOCAL evidence only. Does not import SQL, modify originals or read .env.
import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(process.argv[2] ?? 'D:/DoAnTotNghiep');
const groupSeed = process.argv[3];
if (!groupSeed) throw new Error('GROUP_SEED_PATH_REQUIRED');
const output = resolve(root, 'evidence/council-backup');
await mkdir(resolve(output, 'current-neon-ddl'), { recursive: true });
for (const name of [
  '001_create_schema.sql', '002_create_tables.sql',
  '003_constraints_indexes.sql', '004_seed_demo.sql', '005_views.sql',
  '007_student_support_scope.sql',
]) {
  await copyFile(resolve(root, 'database', name),
    resolve(output, 'current-neon-ddl', name));
}
await copyFile(new URL('../integration-api/openapi.json', import.meta.url),
  resolve(output, 'openapi.json'));
let sanitizedUsers = 0;
const original = await readFile(groupSeed, 'utf8');
const sanitized = original.replace(
  /^INSERT INTO lms\."user" \(([^\n]+)\) VALUES \(([^\n]+)\);$/gm,
  (line, columnsText, valuesText) => {
    const columns = columnsText.split(',').map(v => v.trim());
    const values = valuesText.match(/'(?:''|[^'])*'|[^,]+/g)?.map(v => v.trim());
    if (!values || values.length !== columns.length) {
      throw new Error('GROUP_SEED_FORMAT_UNSUPPORTED');
    }
    for (const name of ['password', 'secret']) {
      const index = columns.indexOf(name);
      if (index >= 0) values[index] = "'!AUTH_DISABLED!'";
    }
    sanitizedUsers++;
    return `INSERT INTO lms."user" (${columnsText}) VALUES (${values.join(', ')});`;
  },
);
if (sanitizedUsers === 0 || sanitized.includes("'mock_password'")) {
  throw new Error('GROUP_SEED_SANITIZATION_FAILED');
}
await writeFile(resolve(output, 'group_mock_data_AUTH_DISABLED.sql'),
  '-- GROUP INPUT ONLY. Incompatible with the current 22-table Neon baseline.\n' +
  '-- Do not import into the working staging database. Authentication disabled.\n' +
  sanitized, { flag: 'wx' });
console.log(JSON.stringify({ BACKUP: 'PASS', sanitizedUsers,
  schemaExport: 'MISSING', currentBaselineDdl: 'COPIED',
  groupSeed: 'AUTH_DISABLED_COPY', originalFiles: 'UNCHANGED' }));
