// Seeds a real Firebase project over REST using your gcloud login
// (no service-account key needed). Requires `gcloud auth login` with an
// account that owns the project.
//   node seed_rest.js --project <project-id>
const { execSync } = require('child_process');
const data = require('./seed_data.json');
const { accounts, employerSeatOrders } = require('./seed_accounts');

const args = process.argv.slice(2);
const project = args[args.indexOf('--project') + 1];
if (!project || project.startsWith('--')) throw new Error('Pass --project <id>');
const token = execSync('gcloud auth print-access-token', { encoding: 'utf8', shell: true }).trim();
const H = { Authorization: `Bearer ${token}`, 'x-goog-user-project': project, 'Content-Type': 'application/json' };
const IT = `https://identitytoolkit.googleapis.com/v1/projects/${project}`;
const FS = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;

function enc(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
}
async function call(url, method, body) {
  const r = await fetch(url, { method, headers: H, body: body && JSON.stringify(body) });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(`${method} ${url} -> ${r.status} ${JSON.stringify(j).slice(0, 300)}`);
  return j;
}
async function setDoc(path, obj) {
  await call(`${FS}/${path}`, 'PATCH', { fields: enc(obj).mapValue.fields });
}
async function upsertUser(a) {
  const found = await call(`${IT}/accounts:lookup`, 'POST', { email: [a.email] });
  let uid = found.users?.[0]?.localId;
  if (uid) {
    await call(`${IT}/accounts:update`, 'POST', { localId: uid, password: a.password, displayName: a.displayName });
  } else {
    uid = (await call(`${IT}/accounts`, 'POST', { email: a.email, password: a.password, displayName: a.displayName, emailVerified: true })).localId;
  }
  await setDoc(`users/${uid}`, { email: a.email, role: a.role, displayName: a.displayName, status: 'Active', createdAt: new Date().toISOString(), ...(a.extra || {}) });
  return uid;
}
(async () => {
  console.log(`Seeding ${project} over REST...`);
  for (const a of accounts) { await upsertUser(a); console.log(`  user ${a.email} (${a.role})`); }
  for (const coll of ['products', 'courses', 'employees', 'assignments']) {
    for (const [id, doc] of Object.entries(data[coll])) await setDoc(`${coll}/${encodeURIComponent(id)}`, doc);
    console.log(`  ${coll}: ${Object.keys(data[coll]).length}`);
  }
  for (const o of employerSeatOrders()) await setDoc(`orders/${o.number}`, o);
  console.log('  employer seat orders: 2');
  console.log('Done.');
})().catch((e) => { console.error(e.message); process.exit(1); });
