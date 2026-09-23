import {readFile} from 'node:fs/promises';
import {connectCandidate,safeFailure} from './candidate_database.mjs';
let client;
try {
  client=await connectCandidate();
  const sql=await readFile(new URL('../demo/02_council_database_demo.sql',import.meta.url),'utf8');
  const results=await client.query(sql);
  console.log(JSON.stringify({councilSql:'PASS',readOnly:true,resultRowCounts:results.filter(r=>r.command==='SELECT').map(r=>r.rowCount)}));
} catch(error) {console.log(JSON.stringify(safeFailure(error)));process.exitCode=1;}
finally {await client?.end();}
