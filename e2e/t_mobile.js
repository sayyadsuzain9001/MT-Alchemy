const L = require('./lib');
(async () => {
  const shots = [
    [null, ['/', '/store', '/hub', '/contact']],
    ['learner', ['/dashboard', '/cart', '/orders']],
    ['trainer', ['/trainer-dashboard']],
    ['employer', ['/employer', '/employees', '/reports']],
    ['admin', ['/admin', '/admin/orders', '/admin/products']],
  ];
  const pw = { learner: 'AlchemyLearner!26', trainer: 'AlchemyTrainer!26', employer: 'AlchemyEmployer!26', admin: 'AlchemyAdmin!26' };
  for (const [role, routes] of shots) {
    const { browser, page } = await L.start(390, 844);
    if (role) await L.signIn(page, `${role}@mtalchemy.demo`, pw[role]);
    for (const r of routes) {
      await L.open(page, r, 4500);
      await L.shot(page, `m_${role || 'guest'}${r.replace(/\//g, '_')}`);
    }
    if (page.errors.length) console.log(role, 'errors', page.errors.length);
    await browser.close();
  }
  console.log('done');
})();
