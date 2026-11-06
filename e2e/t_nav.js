// Every page has a working Back button; header links don't stack pages.
const L = require('./lib');
const fresh = async (page, route, wait) => { await page.goto('about:blank'); await L.open(page, route, wait); };
const back = async (page) => {
  const b = page.getByRole('button', { name: /^(Back|Go back)$/ }).first();
  if (!(await b.count())) return false;
  await b.click(); await page.waitForTimeout(1500); return true;
};
const title = async (page) => (await L.text(page)).split('\n').find((l) => /heading|text: [A-Z]/.test(l)) || '';
(async () => {
  let { browser, page } = await L.start(1440, 900);
  await L.open(page, '/', 4000);
  console.log('Header links replace, Back returns to home');
  for (const name of ['About', 'Services', 'Store', 'Insights', 'Contact']) {
    await L.click(page, name, 'button', { exact: true, wait: 1500 });
  }
  L.check(await back(page), 'back button present after header navigation');
  await L.expectText(page, 'Elevate your value', 'one Back press returns home (no stacked history)');

  console.log('Deep links (page refresh) still have Back');
  const pages = [
    ['/about', 'Elevate your value'], ['/services', 'Elevate your value'], ['/coaching', 'Grow the skills'],
    ['/programmes', 'Build emotionally intelligent leaders'], ['/impact', 'Elevate your value'], ['/contact', 'Elevate your value'],
    ['/store', 'Elevate your value'], ['/cart', 'Tools for everyday practice'], ['/hub', 'Elevate your value'],
    ['/individual', 'Elevate your value'], ['/sitemap', 'Elevate your value'], ['/verify', 'Elevate your value'],
    ['/login', 'Elevate your value'], ['/register', 'Elevate your value'],
  ];
  for (const [route, expect] of pages) {
    await fresh(page, route, 3500);
    const ok = await back(page);
    L.check(ok && (await L.text(page)).includes(expect), `${route}: Back → parent page`);
  }
  await browser.close();

  console.log('Signed-in pages');
  ({ browser, page } = await L.start(1440, 900));
  await L.signIn(page, 'employer@mtalchemy.demo', 'AlchemyEmployer!26');
  for (const [route, expect] of [['/employees', 'EMPLOYER PORTAL'], ['/reports', 'EMPLOYER PORTAL'], ['/purchase-courses', 'EMPLOYER PORTAL'], ['/profile', 'EMPLOYER PORTAL'], ['/employer', 'Elevate your value']]) {
    await fresh(page, route, 4500);
    L.check(await back(page) && (await L.text(page)).includes(expect), `employer ${route}: Back → ${expect}`);
  }
  await browser.close();
  ({ browser, page } = await L.start(1440, 900));
  await L.signIn(page, 'learner@mtalchemy.demo', 'AlchemyLearner!26');
  for (const [route, expect] of [['/dashboard', 'Elevate your value'], ['/orders', 'YOUR LEARNING JOURNEY'], ['/digital-library', 'YOUR LEARNING JOURNEY']]) {
    await fresh(page, route, 4500);
    L.check(await back(page) && (await L.text(page)).includes(expect), `learner ${route}: Back → ${expect}`);
  }
  await browser.close();
  ({ browser, page } = await L.start(1440, 900));
  await L.signIn(page, 'admin@mtalchemy.demo', 'AlchemyAdmin!26');
  for (const [route, expect] of [['/admin/users', 'MT ALCHEMY ADMIN'], ['/admin/orders', 'MT ALCHEMY ADMIN'], ['/admin', 'Elevate your value']]) {
    await fresh(page, route, 4500);
    L.check(await back(page) && (await L.text(page)).includes(expect), `admin ${route}: Back → ${expect}`);
  }
  await browser.close();
  console.log('FAILURES', L.failures());
})();
