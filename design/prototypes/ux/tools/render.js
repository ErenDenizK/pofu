// Renders prototype screens (device only, final static states, 2x) and
// audits tap targets. Requires Playwright with Chromium.
//
//   node tools/render.js OUTDIR [screen[:lang[:query[:name]]] ...]
//   node tools/render.js --audit
//
// Examples:
//   node tools/render.js /tmp/shots home hop-pause:tr "hop-intent::reason=3:hop-intent"
const { chromium } = require('playwright');
const path = require('path');

const PAGE = 'file://' + path.resolve(__dirname, '../index.html');
const DEFAULT = ['onb-welcome', 'onb-apps', 'onb-name', 'onb-setup', 'onb-pip', 'onb-verify', 'onb-gotcha',
  'home', 'home-quiet', 'springboard', 'hop-pause', 'hop-intent::reason=3:hop-intent', 'hop-pay', 'hop-friend',
  'hop-skipped', 'hop-handoff', 'app-sim', 'hop-night', 'earn', 'focus', 'focus-done', 'store', 'recap', 'bedtime',
  'concept-ledger', 'concept-wheel'];

async function render(out, list) {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 520, height: 960 }, deviceScaleFactor: 2 });
  page.on('pageerror', (e) => console.error('PAGEERROR', e.message));
  for (const item of list) {
    const [id, lang, extra, nick] = item.split(':');
    await page.goto(`${PAGE}?screen=${id}&bare=1&static=1${lang ? '&lang=' + lang : ''}${extra ? '&' + extra : ''}`);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(250);
    const name = (nick || id) + (lang ? '-' + lang : '');
    await (await page.$('#device')).screenshot({ path: path.join(out, name + '.png'), omitBackground: true });
    console.log('rendered', name);
  }
  await browser.close();
}

async function audit() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 520, height: 960 } });
  await page.goto(PAGE + '?bare=1&static=1&screen=home');
  await page.evaluate(() => document.fonts.ready);
  const ids = await page.evaluate(() => Object.keys(SCREENS));
  let total = 0;
  for (const id of ids) {
    await page.evaluate((i) => go(i, { instant: true }), id);
    const bad = await page.evaluate(() => [...document.querySelectorAll('#view button, #view [data-go], #view [data-open], #view .chip')]
      .filter((e) => !e.classList.contains('dim'))
      .map((e) => { const r = e.getBoundingClientRect(); return { label: (e.innerText || e.getAttribute('aria-label') || '').trim().slice(0, 30), w: Math.round(r.width), h: Math.round(r.height) }; })
      .filter((x) => x.w > 0 && (x.w < 44 || x.h < 44)));
    total += bad.length;
    if (bad.length) console.log(id, JSON.stringify(bad));
  }
  console.log(`${ids.length} screens, ${total} tap targets under 44 pt`);
  await browser.close();
  process.exitCode = total ? 1 : 0;
}

if (process.argv[2] === '--audit') audit();
else render(process.argv[2] || '.', process.argv.length > 3 ? process.argv.slice(3) : DEFAULT);
