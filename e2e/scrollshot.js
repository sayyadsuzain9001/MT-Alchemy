// usage: node scrollshot.js <route> <prefix> [width] [steps] [email password]
const L = require('./lib');
(async () => {
  const [route, prefix, width = '1440', steps = '6', email, pw] = process.argv.slice(2);
  const w = Number(width);
  const { browser, page } = await L.start(w, w > 500 ? 900 : 844);
  if (email) await L.signIn(page, email, pw);
  await L.open(page, route, 5000);
  for (let i = 0; i < Number(steps); i++) {
    await page.screenshot({ path: `shots/${prefix}_${i}.png` });
    await page.mouse.move(w / 2, 400);
    await page.mouse.wheel(0, w > 500 ? 800 : 700);
    await page.waitForTimeout(900);
  }
  if (page.errors.length) console.log('errors', page.errors.slice(0, 3));
  await browser.close();
})();
