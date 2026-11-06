const L = require('./lib');
const dump = async (page, n = 30) => console.log((await L.text(page)).split('\n').filter(l => /button|heading|textbox|text:/.test(l)).slice(0, n).join('\n').slice(0, 2500));
(async () => {
  const pending = (await L.fsList('quizAttempts')).filter(a => a.status === 'Submitted').sort((a, b) => b.submittedAt.localeCompare(a.submittedAt))[0];
  if (!pending) { console.log('  FAIL no submitted quiz to review (run t_journeyA first)'); return; }
  const learnerPw = pending.learner.startsWith('journey.a.') ? 'Journey2026!' : 'AlchemyLearner!26';
  let { browser, page } = await L.start(1280, 900);
  await L.signIn(page, 'trainer@mtalchemy.demo', 'AlchemyTrainer!26');
  await L.expectText(page, 'Awaiting review', 'trainer dashboard stats');
  await L.expectText(page, pending.learnerName, 'submission from learner listed');
  await L.shot(page, 'trainer_dash');
  await L.click(page, 'Review', 'button', { exact: true, wait: 1500 });
  await L.click(page, 'Save feedback', 'button', { wait: 800 });
  await L.expectText(page, 'Write at least a short sentence', 'feedback validation');
  await L.fill(page, 'Feedback for the learner', 'Great work. Try applying the pause-and-breathe step in your next team meeting.');
  await L.click(page, 'Save feedback', 'button', { wait: 2500 });
  await L.expectText(page, 'Feedback sent to', 'feedback saved snackbar');
  await L.click(page, 'Learner progress', 'button', { wait: 1500 });
  await L.expectText(page, 'Completed', 'progress tab shows completion');
  await L.shot(page, 'trainer_progress');
  const a = (await L.fsList('quizAttempts')).find(x => x.id === pending.id && x.status === 'Reviewed');
  L.check(a && a.reviewedBy === 'Mabel Tan', 'attempt reviewed in Firestore by trainer', JSON.stringify(a)?.slice(0, 200));
  await browser.close();

  ({ browser, page } = await L.start(1280, 900));
  await L.signIn(page, pending.learner, learnerPw);
  await page.mouse.wheel(0, 2000); await page.waitForTimeout(800);
  await L.expectText(page, 'Feedback from Mabel Tan', 'learner sees trainer feedback');
  await L.click(page, 'Certificates', 'checkbox', { wait: 1000 });
  await dump(page, 40);
  await L.shot(page, 'learner_feedback');
  await browser.close();
  console.log('FAILURES', L.failures());
})();
