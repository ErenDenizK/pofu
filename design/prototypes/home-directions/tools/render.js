// Renders the Home direction mockups with Playwright (Chromium), device only, at 2x.
//
//   node tools/render.js OUTDIR [page:preset ...]      e.g. a-meadow:day b-island:night
//   node tools/render.js OUTDIR --all                   every preset of every page, plus the sheet
//   node tools/render.js OUTDIR --sheet                 only comparison.png (index.html?sheet=1)
//
// Screenshots wait for fonts and let ambient motion settle for 1.6 s, so
// particles are mid-flight, as on a device.
const { chromium } = require('playwright');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const ALL = {
  'a-meadow': ['day', 'golden', 'night', 'wilting'],
  'b-island': ['day', 'early', 'night', 'wilting'],
  'c-burrow': ['day', 'night', 'wilting'],
  'today-room': ['day'],
};

async function shoot(page, out, file, preset, labels) {
  await page.goto(`file://${ROOT}/${file}.html?preset=${preset}&bare=1${labels ? '' : '&labels=0'}`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(1600);
  const name = `${file}-${preset}.png`;
  await (await page.$('#device')).screenshot({ path: path.join(out, name), omitBackground: true });
  console.log('rendered', name);
}

async function main() {
  const out = path.resolve(process.argv[2] || '.');
  const args = process.argv.slice(3);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 520, height: 960 }, deviceScaleFactor: 2 });
  page.on('pageerror', (e) => console.error('PAGEERROR', e.message));
  page.on('console', (m) => { if (m.type() === 'error') console.error('CONSOLE', m.text()); });
  const list = args.includes('--all') ? Object.entries(ALL).flatMap(([f, ps]) => ps.map((p) => `${f}:${p}`)) : args.filter((a) => !a.startsWith('--'));
  for (const item of list) { const [f, p] = item.split(':'); await shoot(page, out, f, p, true); }
  if (args.includes('--all') || args.includes('--sheet')) {
    const sheet = await browser.newPage({ viewport: { width: 1800, height: 1200 }, deviceScaleFactor: 1 });
    await sheet.goto(`file://${ROOT}/index.html?sheet=1`);
    await sheet.evaluate(() => document.fonts.ready);
    await sheet.waitForTimeout(800);
    await (await sheet.$('#sheet')).screenshot({ path: path.join(out, 'comparison.png') });
    console.log('rendered comparison.png');
  }
  await browser.close();
}
main();
