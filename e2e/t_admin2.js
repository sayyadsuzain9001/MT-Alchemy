const L = require('./lib');
(async () => {
  let browser, page;
  ({ browser, page } = await L.start(1400, 1000));
  await L.open(page, '/store', 5000);
  const t = await L.text(page);
  L.check(!t.includes('Resilience Habit Tracker'), 'unpublished product hidden from public store');
  console.log('Chatbot');
  await L.click(page, 'Ask Alchemy assistant', 'button', { wait: 1000 });
  await L.click(page, 'How do I get a certificate?', 'checkbox', { wait: 1500 });
  await L.expectText(page, 'at least 60%', 'chatbot answers certificate question');
  await L.shot(page, 'chat');
  await L.click(page, 'My dashboard', 'button', { wait: 3000 });
  await L.expectText(page, 'Welcome back', 'chat shortcut navigates (dashboard requires sign-in)');
  await browser.close();

  ({ browser, page } = await L.start(1400, 1000));
  await L.signIn(page, 'trainer@mtalchemy.demo', 'AlchemyTrainer!26');
  await L.open(page, '/profile', 5000);
  console.log((await L.text(page)).split('\n').filter(l => /button|textbox/.test(l)).slice(11, 20).join('\n'));
  await browser.close();
  console.log('FAILURES', L.failures());
})();
