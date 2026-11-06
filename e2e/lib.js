const { chromium } = require('playwright-core');
const BASE = process.env.BASE || 'http://localhost:8085/';
let failures = 0;
async function start(width = 1280, height = 900) {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({ viewport: { width, height } });
  const page = await context.newPage();
  page.errors = [];
  page.on('pageerror', e => { page.errors.push(e.message); console.log('  PAGEERROR', e.message.slice(0, 300)); });
  page.on('console', m => { if (m.type() === 'error') { page.errors.push(m.text()); console.log('  CONSOLE', m.text().slice(0, 300)); } });
  return { browser, context, page };
}
async function open(page, route, wait = 5000) {
  await page.goto(BASE + '#' + route, { waitUntil: 'load' });
  await page.waitForTimeout(wait);
}
const role = (page, r, name, exact = false) => page.getByRole(r, { name, exact });
async function bringIntoView(page, el) {
  for (let i = 0; i < 6; i++) {
    const bb = await el.boundingBox().catch(() => null);
    const vh = page.viewportSize().height;
    if (!bb || (bb.y >= 60 && bb.y + bb.height <= vh - 10)) return;
    await page.mouse.move(600, 400);
    await page.mouse.wheel(0, bb.y + bb.height > vh - 10 ? Math.min(bb.y - vh / 3, 600) : -300);
    await page.waitForTimeout(400);
  }
}
async function fill(page, label, text) {
  const box = page.getByRole('textbox', { name: label, exact: true }).first();
  for (let i = 0; i < 8 && !(await box.count()); i++) {
    await page.mouse.move(600, 500); await page.mouse.wheel(0, 400); await page.waitForTimeout(400);
  }
  await bringIntoView(page, box);
  await box.click();
  await page.waitForTimeout(150);
  await page.keyboard.press('Control+A');
  await page.keyboard.type(text, { delay: 5 });
}
async function click(page, name, r = 'button', opts = {}) {
  const el = page.getByRole(r, { name, exact: opts.exact ?? false }).first();
  for (let i = 0; i < 8 && !(await el.count()); i++) {
    await page.mouse.move(600, 500); await page.mouse.wheel(0, 400); await page.waitForTimeout(400);
  }
  await bringIntoView(page, el);
  await el.click();
  await page.waitForTimeout(opts.wait ?? 1200);
}
async function text(page) {
  return page.locator('flt-semantics-host').ariaSnapshot().catch(() => '');
}
async function expectText(page, needle, label) {
  let snap = '';
  for (let i = 0; i < 12; i++) {
    snap = await text(page);
    if (snap.includes(needle)) { console.log('  PASS', label || needle); return true; }
    await page.waitForTimeout(500);
  }
  failures++;
  console.log('  FAIL', label || needle, '\n---\n' + snap.slice(0, 1500) + '\n---');
  return false;
}
async function shot(page, name) { await page.screenshot({ path: `shots/${name}.png` }); }
async function signIn(page, email, password) {
  await open(page, '/login');
  await fill(page, 'Email address', email);
  await fill(page, 'Password', password);
  await click(page, 'Sign in', 'button', { exact: true, wait: 4000 });
}
module.exports = { start, open, fill, click, text, expectText, shot, signIn, role, failures: () => failures, BASE };
const FS = 'http://127.0.0.1:8080/v1/projects/demo-mtalchemy/databases/(default)/documents';
async function fsList(collection) {
  const r = await fetch(`${FS}/${collection}?pageSize=300`, { headers: { Authorization: 'Bearer owner' } });
  const j = await r.json();
  return (j.documents || []).map(d => ({ id: d.name.split('/').pop(), ...unwrap({ mapValue: { fields: d.fields || {} } }) }));
}
function unwrap(v) {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(unwrap);
  if ('mapValue' in v) { const o = {}; for (const [k, x] of Object.entries(v.mapValue.fields || {})) o[k] = unwrap(x); return o; }
  return v;
}
function check(cond, label, extra) {
  if (cond) console.log('  PASS', label); else { console.log('  FAIL', label, extra ?? ''); module.exports._fail(); }
}
module.exports.fsList = fsList;
module.exports.check = check;
module.exports._fail = () => { failures++; };
