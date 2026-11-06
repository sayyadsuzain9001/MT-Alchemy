// Smoke test against the real Firebase project and Gemini (BASE=http://localhost:8090/).
const L = require('./lib');
(async () => {
  for (const [email, pw, expect] of [
    ['learner@mtalchemy.demo', 'AlchemyLearner!26', 'Welcome, Aisha Rahman'],
    ['trainer@mtalchemy.demo', 'AlchemyTrainer!26', 'TRAINER WORKSPACE'],
    ['employer@mtalchemy.demo', 'AlchemyEmployer!26', 'EMPLOYER PORTAL'],
    ['admin@mtalchemy.demo', 'AlchemyAdmin!26', 'Platform operations'],
  ]) {
    const { browser, page } = await L.start(1280, 900);
    await L.signIn(page, email, pw);
    await L.expectText(page, expect, `live sign-in ${email}`);
    if (page.errors.length) console.log('  errors:', page.errors.length);
    await browser.close();
  }
  const { browser, page } = await L.start(1280, 900);
  await L.open(page, '/store', 5000);
  await L.expectText(page, 'Mindful Reflection Journal', 'live catalogue from Firestore');
  await L.click(page, 'Ask Alchemy assistant', 'button', { wait: 1000 });
  await L.expectText(page, 'AI answers', 'assistant uses Gemini');
  await L.click(page, 'Which course should I start with?', 'checkbox', { wait: 100 });
  let snap = '';
  for (let i = 0; i < 40; i++) {
    await page.waitForTimeout(1000);
    snap = await L.text(page);
    if (/Emotional Intelligence Fundamentals|could not|busy/.test(snap.split('Which course should I start with?').pop())) break;
  }
  const reply = snap.split('Which course should I start with?').pop().slice(0, 600);
  console.log('  reply:', reply.replace(/\s+/g, ' ').slice(0, 400));
  L.check(!/could not reach|error \d+/.test(reply), 'Gemini answered');
  await L.shot(page, 'live_chat');
  await browser.close();
  console.log('FAILURES', L.failures());
})();
