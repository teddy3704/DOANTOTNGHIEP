// Android-only QA for the approved synthetic staging workflow.
// Does not clear app data, change permissions or touch credentials.
import { execFileSync } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const adb = 'D:/DLU-LMS/Android/Sdk/platform-tools/adb.exe';
const device = 'emulator-5554';
const run = (args) => execFileSync(adb, ['-s', device, ...args], {
  encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'],
});
const decode = (value) => value.replace(/&quot;/g, '"').replace(/&amp;/g, '&')
  .replace(/&#10;/g, '\n').replace(/&apos;/g, "'");
function snapshot() {
  run(['shell', 'uiautomator', 'dump', '/sdcard/dlu-innovation-qa.xml']);
  const xml = run(['exec-out', 'cat', '/sdcard/dlu-innovation-qa.xml']);
  return [...xml.matchAll(/<node\b([^>]+)>?/g)].map((match) => Object.fromEntries(
    [...match[1].matchAll(/([\w-]+)="([^"]*)"/g)].map((attribute) =>
      [attribute[1], decode(attribute[2])]),
  )).filter((node) => node.text || node['content-desc']).map((node) => ({
    label: node.text || node['content-desc'], bounds: node.bounds,
  }));
}
try {
  const [action, argument] = process.argv.slice(2);
  if (action === 'tap') {
    const targets = snapshot().filter((node) => new RegExp(argument, 'u').test(node.label));
    if (targets.length !== 1) throw new Error('AMBIGUOUS_TARGET');
    const [x1, y1, x2, y2] = targets[0].bounds.match(/\d+/g).map(Number);
    run(['shell', 'input', 'tap', `${Math.floor((x1 + x2) / 2)}`, `${Math.floor((y1 + y2) / 2)}`]);
  } else if (action === 'back') run(['shell', 'input', 'keyevent', '4']);
  else if (action === 'down') run(['shell', 'input', 'swipe', '540', '1850', '540', '700', '450']);
  else if (action === 'up') run(['shell', 'input', 'swipe', '540', '700', '540', '1850', '450']);
  else if (action === 'capture') {
    if (!/^\d{2}_[a-z_]+\.png$/.test(argument)) throw new Error('UNSAFE_FILENAME');
    const directory = resolve('evidence/mobile/innovation-final');
    await mkdir(directory, { recursive: true });
    const bytes = execFileSync(adb, ['-s', device, 'exec-out', 'screencap', '-p'], {
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    await writeFile(resolve(directory, argument), bytes);
    console.log(JSON.stringify({ screenshot: resolve(directory, argument) }));
  } else if (action !== 'snapshot') throw new Error('UNSUPPORTED_ACTION');
  console.log(JSON.stringify(snapshot()));
} catch {
  console.log('ANDROID_INNOVATION_QA_FAILED');
  process.exitCode = 1;
}
