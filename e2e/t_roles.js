const L = require('./lib');
(async () => {
  const accounts = [
    ['learner@mtalchemy.demo', 'AlchemyLearner!26', 'learner'],
    ['trainer@mtalchemy.demo', 'AlchemyTrainer!26', 'trainer'],
    ['employer@mtalchemy.demo', 'AlchemyEmployer!26', 'employer'],
    ['admin@mtalchemy.demo', 'AlchemyAdmin!26', 'admin'],
  ];
  for (const [email, pw, name] of accounts) {
    const { browser, page } = await L.start();
    console.log('ROLE', name);
    await L.signIn(page, email, pw);
    await L.shot(page, 'role_' + name);
    const snap = await L.text(page);
    console.log(snap.slice(0, 700));
    await browser.close();
  }
  // wrong password
  const { browser, page } = await L.start();
  await L.signIn(page, 'learner@mtalchemy.demo', 'nope-nope');
  await L.expectText(page, 'Email or password is incorrect', 'wrong password message');
  await browser.close();
  console.log('FAILURES', L.failures());
})();
