// Explicit local allowlist; never reads .env, browser state or unsanitized seed.
import {mkdir,copyFile,readdir,readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const root=resolve(new URL('..',import.meta.url).pathname.replace(/^\/([A-Za-z]:)/,'$1'));
const output=resolve(root,'evidence/council-backup/group39-20-final');
const apk='D:/DoAnTotNghiep/evidence/mobile/DLU_LMS_Support_staging_final_debug.apk';
const inputs=[
  ['D:/DoAnTotNghiep-group/lms_mobile_learning_schema.sql','schema.sql'],
  [resolve(root,'database/candidate/mock_data_sanitized.sql'),'sanitized_seed.sql'],
  [resolve(root,'integration-api/openapi.group-39-20.json'),'openapi.json'],
  [resolve(root,'integration-api/postman/DLU_LMS_GROUP_39_20.postman_collection.json'),'postman_collection.json'],
  ...['01_verify_database_baseline.sql','02_council_database_demo.sql','DEMO_CHECKLIST.md','COUNCIL_DEMO_SCRIPT.md'].map(n=>[resolve(root,'demo',n),n]),
  [apk,'DLU_LMS_Support_staging_final_debug.apk'],
];
try {
  await mkdir(output,{recursive:true});
  for(const [source,name] of inputs) await copyFile(source,resolve(output,name));
  const screenshots=resolve(root,'evidence/mobile/group39-20-final');
  await mkdir(resolve(output,'screenshots'),{recursive:true});
  const images=(await readdir(screenshots)).filter(n=>/^\d{2}_[a-z_]+\.png$/.test(n));
  for(const n of images)await copyFile(resolve(screenshots,n),resolve(output,'screenshots',n));
  console.log(JSON.stringify({offlineBackup:'PASS',files:inputs.length,screenshots:images.length,
    apkSha256:createHash('sha256').update(await readFile(apk)).digest('hex'),originals:'UNCHANGED'}));
}catch{console.log('OFFLINE_BACKUP_INCOMPLETE');process.exitCode=1;}
