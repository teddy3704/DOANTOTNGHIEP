// Compare actual secret bytes silently against Git candidates and index.
import {readFile} from 'node:fs/promises';
import {parseEnv} from 'node:util';
import {resolve} from 'node:path';
import {createGitObjectReader,scanGitIndex} from '../integration-api/scripts/git-index-scan.ts';
try {
  const root=resolve('.');const needles=[];
  for(const [path,key] of [
    ['integration-api/.env.candidate','CANDIDATE_DATABASE_URL'],
    ['D:/DoAnTotNghiep/integration-api/.env','DATABASE_URL'],
  ]){
    const env=parseEnv(await readFile(path,'utf8'));const value=env[key];
    if(!value)throw new Error('CONFIG_REQUIRED');
    const url=new URL(value);const password=decodeURIComponent(url.password);
    if(password.length<8)throw new Error('SCAN_INPUT_INVALID');
    for(const needle of [value,url.password,password])needles.push(Buffer.from(needle));
  }
  const git=createGitObjectReader(root);
  const names=git(['ls-files','-z','--cached','--others','--exclude-standard']).toString().split('\0').filter(Boolean);
  let matches=0;
  for(const name of new Set(names)){
    const content=await readFile(resolve(root,name));
    if(needles.some(n=>content.includes(n)))matches++;
  }
  const index=scanGitIndex(needles,git);
  const staged=git(['diff','--cached','--name-only','-z']).toString().split('\0').filter(Boolean);
  const forbidden=staged.filter(n=>/\.env(?:\.|$)|\.(?:apk|aab|dump|pem|jks)$|(?:^|\/)(?:node_modules|build|dist|candidate)\//i.test(n)&&!n.endsWith('.env.example')).length;
  const pass=matches===0&&index.secretValueMatches===0&&index.privateConfigFiles===0&&forbidden===0;
  console.log(JSON.stringify({secretScan:pass?'PASS':'FAIL',files:new Set(names).size,matches,indexedSecretMatches:index.secretValueMatches,privateConfigFiles:index.privateConfigFiles,forbiddenStaged:forbidden}));
  if(!pass)process.exitCode=1;
}catch{console.log('CANDIDATE_SECRET_SCAN_FAILED');process.exitCode=1;}
