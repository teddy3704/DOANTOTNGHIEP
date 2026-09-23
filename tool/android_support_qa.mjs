// Android CLI QA only; never changes app data, credentials or system permissions.
import {execFileSync} from 'node:child_process';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const adb='D:/DLU-LMS/Android/Sdk/platform-tools/adb.exe';
const run=(args)=>execFileSync(adb,['-s','emulator-5554',...args],{encoding:'utf8',stdio:['ignore','pipe','pipe']});
const decode=s=>s.replace(/&quot;/g,'"').replace(/&amp;/g,'&').replace(/&#10;/g,'\n').replace(/&apos;/g,"'");
function snapshot(){
  run(['shell','uiautomator','dump','/sdcard/dlu-support-qa.xml']);
  const xml=run(['exec-out','cat','/sdcard/dlu-support-qa.xml']);
  return [...xml.matchAll(/<node\b([^>]+)>?/g)].map(m=>Object.fromEntries([...m[1].matchAll(/([\w-]+)="([^"]*)"/g)].map(a=>[a[1],decode(a[2])]))).filter(n=>n.text||n['content-desc']).map(n=>({label:n.text||n['content-desc'],bounds:n.bounds}));
}
try {
  const [action,arg]=process.argv.slice(2);
  if(action==='tap'){
    const candidates=snapshot().filter(n=>new RegExp(arg,'u').test(n.label));
    if(candidates.length!==1)throw new Error('AMBIGUOUS_UI_TARGET');
    const [x1,y1,x2,y2]=candidates[0].bounds.match(/\d+/g).map(Number);
    run(['shell','input','tap',String(Math.floor((x1+x2)/2)),String(Math.floor((y1+y2)/2))]);
  } else if(action==='back')run(['shell','input','keyevent','4']);
  else if(action==='down')run(['shell','input','swipe','540','1850','540','700','450']);
  else if(action==='up')run(['shell','input','swipe','540','700','540','1850','450']);
  else if(action==='capture'){
    if(!/^\d{2}_[a-z_]+\.png$/.test(arg))throw new Error('UNSAFE_CAPTURE_NAME');
    const dir=resolve('evidence/mobile/group39-20-final');await mkdir(dir,{recursive:true});
    const bytes=execFileSync(adb,['-s','emulator-5554','exec-out','screencap','-p'],{stdio:['ignore','pipe','pipe']});
    await writeFile(resolve(dir,arg),bytes);console.log(JSON.stringify({screenshot:resolve(dir,arg)}));
  } else if(action!=='snapshot')throw new Error('UNSUPPORTED_QA_ACTION');
  console.log(JSON.stringify(snapshot()));
}catch {console.log('ANDROID_QA_ACTION_FAILED');process.exitCode=1;}
