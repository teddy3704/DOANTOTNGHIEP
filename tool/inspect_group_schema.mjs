// Offline pg_dump DDL inspection. Never modifies input or connects to a database.
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

const file = process.argv[2];
if (!file) throw new Error('SCHEMA_PATH_REQUIRED');
const sql = (await readFile(file, 'utf8')).replaceAll('\r\n', '\n');
const schemas = [...sql.matchAll(/^CREATE SCHEMA (\w+);$/gm)].map(m => m[1]);
const tables = [...sql.matchAll(/^CREATE TABLE (\w+)\.("?\w+"?) \(\n([\s\S]*?)^\);$/gm)]
  .map(m => {
    const lines = m[3].split('\n').filter(line => line.trim());
    const columns = lines.filter(line => /^    "?\w+"?\s/.test(line)
      && !/^    (CONSTRAINT|PRIMARY|FOREIGN|UNIQUE|CHECK)\b/.test(line));
    if (lines.some(line => !/^    /.test(line))) {
      throw new Error('MULTILINE_COLUMN_FORMAT_REQUIRES_REVIEW');
    }
    return { schema: m[1], name: m[2].replaceAll('"', ''),
      columns: columns.length,
      passwordNullable: columns.some(line => /^    password /.test(line))
        ? !columns.find(line => /^    password /.test(line)).includes('NOT NULL')
        : undefined };
  });
const views = [...sql.matchAll(/^CREATE VIEW (\w+)\.("?\w+"?) AS$/gm)]
  .map(m => `${m[1]}.${m[2].replaceAll('"', '')}`);
const counts = {
  schemas: schemas.length, physicalTables: tables.length,
  lmsTables: tables.filter(t => t.schema === 'lms').length,
  appTables: tables.filter(t => t.schema === 'app').length,
  derivedViews: views.filter(v => v.startsWith('derived.')).length,
  primaryKeys: [...sql.matchAll(/ADD CONSTRAINT [^\n]+ PRIMARY KEY\s*\(/g)].length,
  physicalForeignKeys: [...sql.matchAll(/ADD CONSTRAINT [^\n]+ FOREIGN KEY\s*\(/g)].length,
  physicalColumns: tables.reduce((total, t) => total + t.columns, 0),
};
// Cross-check pg_dump's object headers as a second independent inventory.
const tableHeaders = [...sql.matchAll(/^-- Name: .+; Type: TABLE; Schema: (lms|app); Owner:.*$/gm)].length;
if (tableHeaders !== tables.length || tables.length === 0) {
  throw new Error('DDL_TABLE_INVENTORY_MISMATCH');
}
console.log(JSON.stringify({ scope: 'OFFLINE_DDL_ONLY',
  sha256: createHash('sha256').update(await readFile(file)).digest('hex'),
  counts, schemas, tables, views,
  passwordColumn: tables.find(t => t.schema === 'lms' && t.name === 'user'),
}, null, 2));
