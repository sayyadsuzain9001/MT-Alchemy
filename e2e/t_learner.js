const L = require('./lib');
(async () => {
  const { browser, page } = await L.start(1280, 900);
  const email = `e2e.learner.${Date.now()}@example.com`;
  console.log('1. Register new learner', email);
  await L.open(page, '/register');
  await L.fill(page, 'Full name', 'Priya Nair');
  await L.fill(page, 'Email', email);
  await L.fill(page, 'Phone', '+60 12 555 0101');
  await L.click(page, 'Emotional Intelligence', 'checkbox', { wait: 300 });
  await L.fill(page, 'Password', 'Learner2026!');
  await L.fill(page, 'Confirm password', 'Learner2026!');
  await L.click(page, 'I agree', 'checkbox', { wait: 300 });
  await L.click(page, 'Create learner account', 'button', { wait: 5000 });
  await L.expectText(page, 'Welcome, Priya Nair', 'registered learner lands on dashboard');
  const users = await L.fsList('users');
  const u = users.find(x => x.email === email);
  L.check(u && u.role === 'Learner' && u.learningAreas === 'Emotional Intelligence', 'users doc created with role + interests', JSON.stringify(u));

  console.log('2. Enrol in EI Fundamentals from the hub');
  await L.open(page, '/hub', 4000);
  await L.click(page, 'Emotional Intelligence Fundamentals', 'button', { wait: 2500 }).catch(() => {});
  let snap = await L.text(page);
  console.log(snap.split('\n').filter(l => /button/.test(l)).slice(0, 15).join('\n'));
  await L.shot(page, 'learner_course');
  await browser.close();
  console.log('FAILURES', L.failures());
})();
