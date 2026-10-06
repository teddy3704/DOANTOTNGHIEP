// Opt-in app-owned workflow smoke; never writes official LMS data or prints credentials.
// Local mode uses the configured candidate; staging mode contacts only the fixed service.
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { parseEnv } from 'node:util';
import { randomUUID } from 'node:crypto';
import { performance } from 'node:perf_hooks';
import { safeFailure } from './candidate_database.mjs';

const mode = process.argv[2];
if (!['local', 'staging'].includes(mode)) throw new Error('EXPLICIT_SMOKE_MODE_REQUIRED');
const base = 'https://dlu-lms-student-support-staging.onrender.com';
let app, pool, failed = 0;
const checks = [], timings = [];
const student = { 'X-Demo-Student-Code': 'SV001' };
const student2 = { 'X-Demo-Student-Code': 'SV002' };
const teacher = { 'X-Demo-Teacher-Code': 'GV001' };
const teacher2 = { 'X-Demo-Teacher-Code': 'GV002' };
function verify(name, pass) {
  checks.push({ name, pass });
  if (!pass) failed++;
  console.log(JSON.stringify({ check: name, pass }));
}
async function request(path, headers = {}, expected = 200, method = 'GET', body) {
  const start = performance.now();
  let status, text;
  if (app) {
    const response = await app.inject({ method, url: path, headers, payload: body });
    status = response.statusCode; text = response.body;
  } else {
    const response = await fetch(base + path, { method,
      headers: { ...headers, ...(body ? { 'Content-Type': 'application/json' } : {}) },
      body: body ? JSON.stringify(body) : undefined,
      redirect: 'error', signal: AbortSignal.timeout(60000) });
    status = response.status; text = await response.text();
  }
  const durationMs = Math.round(performance.now() - start);
  timings.push({ path: path.replace(/[0-9a-f]{8}-(?:[0-9a-f-]{27,})/g, ':id'), method, durationMs });
  verify(`${method} ${path} => ${expected}`, status === expected);
  verify('sanitized response', !/postgres(?:ql)?:\/\/|BEGIN (?:RSA )?PRIVATE KEY/i.test(text));
  let data;
  try { data = JSON.parse(text); } catch { data = null; }
  if (data?.meta) verify('collection envelope', Array.isArray(data.data) && data.meta.count === data.data.length);
  if (status !== expected) throw new Error('SMOKE_UNEXPECTED_RESPONSE');
  return data;
}
try {
  if (mode === 'local') {
    const env = parseEnv(await readFile(new URL('../integration-api/.env.candidate', import.meta.url), 'utf8'));
    const { loadConfig } = await import('../integration-api/src/config.ts');
    const { createPool, PostgresReadDatabase } = await import('../integration-api/src/data/database.ts');
    const { GroupStudentDataSource } = await import('../integration-api/src/data/group-student-data-source.ts');
    const { GroupTeacherDataSource } = await import('../integration-api/src/data/group-teacher-data-source.ts');
    const { PostgresAppDatabase, PostgresInnovationStore } = await import('../integration-api/src/data/innovation-store.ts');
    const { buildApp } = await import('../integration-api/src/app.ts');
    const config = loadConfig({ APP_ENV: 'staging', DEMO_AUTH_ENABLED: 'true',
      DATABASE_MODEL: 'group_39_20', DATABASE_URL: env.CANDIDATE_DATABASE_URL });
    pool = createPool(config.databaseUrl, 'group_39_20');
    const db = new PostgresReadDatabase(pool);
    app = await buildApp(config, new GroupStudentDataSource(db), false,
      new GroupTeacherDataSource(db), new PostgresInnovationStore(new PostgresAppDatabase(pool)));
  }
  const health = await request('/health');
  verify('actual database reachable', health.status === 'ok' && health.database === 'reachable');
  const spec = await request('/openapi.json');
  verify('published plan + intervention contracts',
    !!spec.paths['/api/v1/me/study-plan/items']?.post &&
    !!spec.paths['/api/v1/me/teacher/interventions/{id}/followups']?.post);
  for (const headers of [student, student2]) {
    for (const path of ['','/courses','/assignments','/assignment-status','/grades','/progress','/overview','/recommendations','/study-plan'])
      await request('/api/v1/me' + path, headers);
  }
  for (const headers of [teacher, teacher2]) {
    for (const path of ['','/courses','/overview','/attention','/interventions','/followups'])
      await request('/api/v1/me/teacher' + path, headers);
  }
  await request('/api/v1/me/recommendations', {}, 401);
  await request('/api/v1/me/study-plan', teacher, 401);
  await request('/api/v1/me/teacher/interventions', student, 401);
  await request('/api/v1/me/study-plan?userId=202', student, 400);
  const recommendations = (await request('/api/v1/me/recommendations', student)).data;
  const again = (await request('/api/v1/me/recommendations', student)).data;
  verify('deterministic ranking', JSON.stringify(recommendations) === JSON.stringify(again));
  verify('explainable + bounded recommendations', recommendations.every(r => r.reasons.length > 0 && r.priorityScore >= 0 && r.priorityScore <= 100));
  const itemSource = recommendations.find(r => !r.planned);
  if (!itemSource) throw new Error('UNPLANNED_SOURCE_REQUIRED');
  const future = new Date(Date.now() + 3600000).toISOString();
  const created = (await request('/api/v1/me/study-plan/items', student, 201, 'POST', {
    assignmentId: itemSource.assignmentId, scheduledStartAt: future, estimatedMinutes: 45, notes: 'Kiểm thử kế hoạch cá nhân.' })).data;
  const itemPath = '/api/v1/me/study-plan/items/' + created.id;
  await request(itemPath, student2, 404, 'PATCH', { status: 'handled' });
  await request(itemPath, student2, 404, 'DELETE');
  verify('student isolation', !(await request('/api/v1/me/study-plan', student2)).data.some(p => p.id === created.id));
  await request(itemPath, student, 400, 'PATCH', { ownerUserId: 202 });
  await request(itemPath, student, 400, 'PATCH', { estimatedMinutes: 0 });
  await request('/api/v1/me/study-plan/items', student, 409, 'POST', {
    assignmentId: itemSource.assignmentId, scheduledStartAt: future });
  const changed = (await request(itemPath, student, 200, 'PATCH', { estimatedMinutes: 60,
    scheduledStartAt: new Date(Date.now() + 7200000).toISOString() })).data;
  verify('plan edit persisted', (await request('/api/v1/me/study-plan', student)).data.some(p => p.id === created.id && p.estimatedMinutes === 60 && p.scheduledStartAt === changed.scheduledStartAt));
  await request(itemPath, student, 200, 'PATCH', { status: 'handled' });
  verify('handled hides recommendation, not academic source',
    !(await request('/api/v1/me/recommendations', student)).data.some(r => r.assignmentId === itemSource.assignmentId));
  verify('official assignment still exists', (await request('/api/v1/me/assignments', student)).data.some(a => a.assignmentId === itemSource.assignmentId));
  await request(itemPath, student, 200, 'DELETE');
  verify('removed plan persisted', !(await request('/api/v1/me/study-plan', student)).data.some(p => p.id === created.id));
  const attention = (await request('/api/v1/me/teacher/attention', teacher)).data;
  const current = (await request('/api/v1/me/teacher/interventions', teacher)).data;
  const target = attention.find(a => !current.some(i => i.studentId === a.studentId && i.courseId === a.courseId && i.status !== 'resolved'));
  if (!target) throw new Error('UNTRACKED_ATTENTION_REQUIRED');
  const createdIntervention = (await request('/api/v1/me/teacher/interventions', teacher, 201, 'POST', {
    courseId: target.courseId, studentId: target.studentId, title: 'Kiểm thử theo dõi ' + randomUUID().slice(0, 8),
    note: 'Ghi nhận kiểm thử workflow trên dữ liệu mô phỏng.', actionType: 'contacted',
    followUpAt: new Date(Date.now() - 60000).toISOString() })).data;
  const interventionPath = '/api/v1/me/teacher/interventions/' + createdIntervention.id;
  await request(interventionPath, teacher2, 404);
  await request(interventionPath, teacher2, 404, 'PATCH', { note: 'Không thuộc phạm vi.' });
  await request(interventionPath + '/followups', teacher2, 404, 'POST', { note: 'Không thuộc phạm vi.', outcomeStatus: 'resolved' });
  verify('teacher isolation', !(await request('/api/v1/me/teacher/interventions', teacher2)).data.some(i => i.id === createdIntervention.id));
  const otherAttention = (await request('/api/v1/me/teacher/attention', teacher2)).data;
  const outside = otherAttention.find(a => !attention.some(t => t.courseId === a.courseId && t.studentId === a.studentId));
  if (outside) await request('/api/v1/me/teacher/interventions', teacher, 404, 'POST', {
    courseId: outside.courseId, studentId: outside.studentId, title: 'Không thuộc phạm vi',
    note: 'Không thuộc phạm vi.', actionType: 'monitoring', followUpAt: null });
  verify('due follow-up persisted', (await request('/api/v1/me/teacher/followups', teacher)).data.some(i => i.id === createdIntervention.id));
  const history = (await request(interventionPath + '/followups', teacher, 201, 'POST', {
    note: 'Đã kiểm tra lại; đây không phải đánh giá hay điểm chính thức.', outcomeStatus: 'following_up',
    nextFollowUpAt: future })).data;
  verify('actual source snapshot + history', history.followups.length === 1 &&
    history.followups[0].progressPercent === target.progressPercent && history.status === 'following_up');
  const resolved = (await request(interventionPath + '/followups', teacher, 201, 'POST', {
    note: 'Kết thúc bản ghi kiểm thử.', outcomeStatus: 'resolved' })).data;
  verify('closure persisted without fabricated improvement', resolved.status === 'resolved' &&
    resolved.followups.length === 2 && resolved.followUpAt === null &&
    (await request(interventionPath, teacher)).data.status === 'resolved');
  await request(interventionPath + '/followups', teacher, 409, 'POST', { note: 'Đã đóng.', outcomeStatus: 'resolved' });
  await request('/api/v1/me/assignments', student, 404, 'POST', { grade: 10 });
  const report = { status: failed ? 'FAIL' : 'PASS', mode, checkedAt: new Date().toISOString(),
    checks, timings, testData: 'Plan item removed; synthetic teacher test record resolved, history retained.' };
  await mkdir(new URL('../evidence/innovation/', import.meta.url), { recursive: true });
  await writeFile(new URL(`../evidence/innovation/${mode}-smoke.json`, import.meta.url), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ status: report.status, checks: checks.length, failed }));
} catch (error) {
  console.log(JSON.stringify(safeFailure(error))); process.exitCode = 1;
} finally {
  await app?.close().catch(() => {}); await pool?.end().catch(() => {});
  if (failed) process.exitCode = 1;
}
