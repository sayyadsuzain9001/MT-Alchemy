const L = require('./lib');
const dump = async (page, n = 30) => console.log((await L.text(page)).split('\n').filter(l => /button|heading|radio|checkbox|textbox|text:/.test(l)).slice(0, n).join('\n').slice(0, 3000));
(async () => {
  const { browser, page } = await L.start(1280, 900);
  await L.signIn(page, 'learner@mtalchemy.demo', 'AlchemyLearner!26');
  await L.click(page, 'Continue Course', 'button', { wait: 3000 });
  await L.click(page, 'Mark Complete', 'button', { exact: true, wait: 1500 });
  const prog = (await L.fsList('progress')).find(p => p.id === 'learner@mtalchemy.demo');
  L.check(prog && prog.done['ei-fundamentals'].length === 20, 'all 20 lessons saved to Firestore', JSON.stringify(prog?.done));
  await L.click(page, 'Take Quiz', 'button', { wait: 3000 });
  await L.shot(page, 'quiz_start');
  await dump(page, 30);
  await browser.close();
  console.log('FAILURES', L.failures());
})();
