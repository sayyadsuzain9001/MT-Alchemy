// Visits every route as each role on the live build and records console
// errors, page errors and failed Firebase/Stripe/Gemini network requests.
const L = require('./lib');
const routes = {
  guest: ['/', '/individual', '/about', '/services', '/coaching', '/organizations', '/programmes', '/impact', '/insights', '/contact', '/store', '/hub', '/cart', '/sitemap', '/verify', '/login', '/register'],
  learner: ['/dashboard', '/hub', '/orders', '/digital-library', '/profile', '/cart', '/checkout', '/store'],
  trainer: ['/trainer-dashboard', '/admin/courses', '/profile'],
  employer: ['/employer', '/employees', '/assign-course', '/reports', '/purchase-courses', '/quote-requests', '/quote-request', '/orders', '/profile'],
  admin: ['/admin', '/admin/users', '/admin/organizations', '/admin/courses', '/admin/products', '/admin/orders', '/admin/quotes', '/admin/enquiries', '/profile'],
};
const pw = { learner: 'AlchemyLearner!26', trainer: 'AlchemyTrainer!26', employer: 'AlchemyEmployer!26', admin: 'AlchemyAdmin!26' };
(async () => {
  let total = 0, problems = 0;
  for (const [role, list] of Object.entries(routes)) {
    const { browser, page } = await L.start(1280, 900);
    const failed = [];
    page.on('requestfailed', r => { if (/firestore|googleapis|identitytoolkit|stripe|4242/.test(r.url())) failed.push(`${r.failure()?.errorText} ${r.url().slice(0, 100)}`); });
    page.on('response', r => { if (r.status() >= 400 && /firestore|identitytoolkit|securetoken|generativelanguage|4242/.test(r.url())) failed.push(`${r.status()} ${r.url().slice(0, 100)}`); });
    if (role !== 'guest') await L.signIn(page, `${role}@mtalchemy.demo`, pw[role]);
    for (const r of list) {
      const before = page.errors.length, fBefore = failed.length;
      await L.open(page, r, 4000);
      const snap = await L.text(page);
      const denied = /permission|could not be loaded|unavailable|Workspace access required/i.test(snap);
      const errs = page.errors.slice(before).filter(e => !/Running in emulator mode/.test(e));
      const nf = failed.slice(fBefore);
      total++;
      if (errs.length || nf.length || denied) {
        problems++;
        console.log(`  PROBLEM ${role} ${r}`, errs.slice(0, 2), nf.slice(0, 3), denied ? 'denied/error text on page' : '');
      }
    }
    console.log(`${role}: ${list.length} pages checked`);
    await browser.close();
  }
  console.log(`TOTAL ${total} pages, ${problems} with problems`);
})();
