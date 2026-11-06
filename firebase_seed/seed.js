// Seeds MT Alchemy demo accounts and starter data.
//
// Emulator:      node seed.js --emulator
// Real project:  set GOOGLE_APPLICATION_CREDENTIALS=<service-account.json>
//                node seed.js --project <your-project-id>
//            or: node seed.js --project <your-project-id> --gcloud  (uses `gcloud auth`)
//
// Safe to re-run: accounts are created or updated, starter documents are
// written with merge, and existing orders/enquiries are left alone.
const admin = require('firebase-admin');
const data = require('./seed_data.json');

const args = process.argv.slice(2);
const emulator = args.includes('--emulator');
const projectIndex = args.indexOf('--project');
const projectId = projectIndex >= 0 ? args[projectIndex + 1] : 'demo-mtalchemy';

if (emulator) {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
}

// --gcloud: use the signed-in gcloud user instead of a service-account key.
const useGcloud = args.includes('--gcloud');
const gcloudCredential = {
  getAccessToken: async () => ({
    access_token: require('child_process')
      .execSync('gcloud auth print-access-token', { encoding: 'utf8', shell: true })
      .trim(),
    expires_in: 3000,
  }),
};
if (useGcloud) process.env.GOOGLE_CLOUD_QUOTA_PROJECT = projectId;
admin.initializeApp({ projectId, ...(useGcloud ? { credential: gcloudCredential } : {}) });
const auth = admin.auth();
const db = admin.firestore();

const { accounts, employerSeatOrders } = require('./seed_accounts');

async function upsertUser(account) {
  let user;
  try {
    user = await auth.getUserByEmail(account.email);
    await auth.updateUser(user.uid, { password: account.password, displayName: account.displayName });
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    user = await auth.createUser({ email: account.email, password: account.password, displayName: account.displayName, emailVerified: true });
  }
  await db.collection('users').doc(user.uid).set({
    email: account.email,
    role: account.role,
    displayName: account.displayName,
    createdAt: new Date().toISOString(),
    ...(account.extra || {}),
  }, { merge: true });
  return user.uid;
}

async function writeCollection(name, docs) {
  const batch = db.batch();
  for (const [id, doc] of Object.entries(docs)) {
    batch.set(db.collection(name).doc(id), doc, { merge: true });
  }
  await batch.commit();
  console.log(`  ${name}: ${Object.keys(docs).length} documents`);
}

(async () => {
  console.log(`Seeding project "${projectId}"${emulator ? ' (emulator)' : ''}...`);
  for (const account of accounts) {
    await upsertUser(account);
    console.log(`  user ${account.email} (${account.role})`);
  }
  await writeCollection('products', data.products);
  await writeCollection('courses', data.courses);
  await writeCollection('employees', data.employees);
  await writeCollection('assignments', data.assignments);
  await writeCollection('orders', Object.fromEntries(employerSeatOrders().map((o) => [o.number, o])));
  console.log('Done.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
