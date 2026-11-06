const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts';
const FS = 'http://127.0.0.1:8080/v1/projects/demo-mtalchemy/databases/(default)/documents';
let fails = 0;
async function token(email, password, signUp = false) {
  const r = await fetch(`${AUTH}:${signUp ? 'signUp' : 'signInWithPassword'}?key=demo-api-key`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password, returnSecureToken: true }) });
  const j = await r.json(); return { t: j.idToken, uid: j.localId };
}
const h = (t) => ({ 'Content-Type': 'application/json', ...(t ? { Authorization: 'Bearer ' + t } : {}) });
const S = (v) => ({ stringValue: v });
async function expect(label, promise, want) {
  const r = await promise; const ok = want.includes(r.status);
  if (!ok) fails++;
  console.log(ok ? '  PASS' : '  FAIL', label, '->', r.status);
}
const runQuery = (t, coll, field, value) => fetch(`${FS}:runQuery`, { method: 'POST', headers: h(t), body: JSON.stringify({ structuredQuery: { from: [{ collectionId: coll }], ...(field ? { where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: S(value) } } } : {}) } }) });
(async () => {
  const L = await token('learner@mtalchemy.demo', 'AlchemyLearner!26');
  const E = await token('employer@mtalchemy.demo', 'AlchemyEmployer!26');
  const T = await token('trainer@mtalchemy.demo', 'AlchemyTrainer!26');
  console.log('Privilege escalation');
  await expect('learner cannot make self Admin', fetch(`${FS}/users/${L.uid}?updateMask.fieldPaths=role`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { role: S('Admin') } }) }), [403]);
  const N = await token(`rules.${Date.now()}@example.com`, 'Password123!', true);
  await expect('new account cannot register as Admin', fetch(`${FS}/users?documentId=${N.uid}`, { method: 'POST', headers: h(N.t), body: JSON.stringify({ fields: { role: S('Admin'), email: S('x') } }) }), [403]);
  await expect('learner can update own display name', fetch(`${FS}/users/${L.uid}?updateMask.fieldPaths=displayName`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { displayName: S('Aisha Rahman') } }) }), [200]);
  console.log('Data isolation');
  await expect('learner cannot list all orders', runQuery(L.t, 'orders'), [403]);
  await expect('learner can list own orders', runQuery(L.t, 'orders', 'customerEmail', 'learner@mtalchemy.demo'), [200]);
  await expect('guest cannot read enquiries', runQuery(null, 'enquiries'), [403]);
  await expect('employer cannot read another org employees', runQuery(E.t, 'employees', 'organization', 'other@corp.com'), [403]);
  await expect('learner cannot read another learner progress', fetch(`${FS}/progress/alicia@example.com`, { headers: h(L.t) }), [403]);
  await expect('trainer can read learner progress', fetch(`${FS}/progress/learner@mtalchemy.demo`, { headers: h(T.t) }), [200, 404]);
  console.log('Write protection');
  await expect('learner cannot change product price', fetch(`${FS}/products/mindful-journal?updateMask.fieldPaths=price`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { price: { integerValue: '1' } } }) }), [403]);
  await expect('learner cannot set stock negative', fetch(`${FS}/products/mindful-journal?updateMask.fieldPaths=stock`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { stock: { integerValue: '-5' } } }) }), [403]);
  await expect('learner cannot create order for someone else', fetch(`${FS}/orders?documentId=FAKE1`, { method: 'POST', headers: h(L.t), body: JSON.stringify({ fields: { customerEmail: S('alicia@example.com'), paymentStatus: S('Pending') } }) }), [403]);
  await expect('learner cannot create order with invalid payment state', fetch(`${FS}/orders?documentId=FAKE2`, { method: 'POST', headers: h(L.t), body: JSON.stringify({ fields: { customerEmail: S('learner@mtalchemy.demo'), paymentStatus: S('Refunded') } }) }), [403]);
  await expect('learner cannot send notifications', fetch(`${FS}/notifications?documentId=N1`, { method: 'POST', headers: h(L.t), body: JSON.stringify({ fields: { recipient: S('alicia@example.com'), sender: S('learner@mtalchemy.demo') } }) }), [403]);
  await expect('learner cannot forge a certificate for someone else', fetch(`${FS}/certificates/FAKE-CERT`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { learnerEmail: S('alicia@example.com') } }) }), [403]);
  await expect('learner cannot edit courses', fetch(`${FS}/courses/ei-fundamentals?updateMask.fieldPaths=status`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { status: S('Archived') } }) }), [403]);
  await expect('trainer can edit courses', fetch(`${FS}/courses/ei-fundamentals?updateMask.fieldPaths=status`, { method: 'PATCH', headers: h(T.t), body: JSON.stringify({ fields: { status: S('Published') } }) }), [200]);
  await expect('learner cannot create quotes (employer only)', fetch(`${FS}/quotes?documentId=FAKEQ`, { method: 'POST', headers: h(L.t), body: JSON.stringify({ fields: { ownerEmail: S('learner@mtalchemy.demo'), status: S('New') } }) }), [403]);
  await expect('guest cannot change courses', fetch(`${FS}/courses/ei-fundamentals?updateMask.fieldPaths=price`, { method: 'PATCH', headers: h(null), body: JSON.stringify({ fields: { price: { integerValue: '0' } } }) }), [403]);
  await expect('guest can read courses', fetch(`${FS}/courses/ei-fundamentals`, { headers: h(null) }), [200]);
  const att = await (await runQuery(L.t, 'quizAttempts', 'learner', 'learner@mtalchemy.demo')).json();
  const attId = att.find(x => x.document)?.document.name.split('/').pop();
  await expect('learner cannot write own trainer feedback', fetch(`${FS}/quizAttempts/${attId}?updateMask.fieldPaths=feedback`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { feedback: S('I am great') } }) }), [403]);
  await expect('learner cannot change assignment course/due', fetch(`${FS}/assignments/employer@mtalchemy.demo__learner@mtalchemy.demo__Mindfulness_at_Work?updateMask.fieldPaths=due`, { method: 'PATCH', headers: h(L.t), body: JSON.stringify({ fields: { due: S('never') } }) }), [403]);
  console.log('FAILURES', fails);
})();
