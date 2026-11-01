// Renders the island game prototype with Playwright (Chromium): desktop states inside the
// device frame at 2x, phone states full-screen in iPhone 15 emulation, and overview.png.
//
//   node tools/render.js [OUTDIR]          default: ../screenshots
//   node tools/render.js OUTDIR name ...   only the named shots
//
// Then optimize: pngquant --quality 65-90 --speed 1 --force --ext .png screenshots/*.png
const { chromium, devices } = require('playwright');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..');

// Each shot: name, caption, a script against window.G, settle ms, 'phone' for full-screen emulation.
const SHOTS = [
  ['01-home', 'Home: Pofu up close, seeds gathered while you were away', async () => {}],
  ['02-island-day1', 'Tap the island: day 1, the first build is affordable', async (p) => p.evaluate(() => { G.collect(); G.toVillage(true); })],
  ['03-station-sheet', 'A station: the next designed level, paid in seeds', async (p) => p.evaluate(() => { G.fastForward(5); G.collect(); G.toVillage(true); G.openStation('cay'); })],
  ['04-upgraded', 'Built: çay ocağı level 3, Pofu is excited', async (p) => p.evaluate(() => { G.fastForward(5); G.collect(); G.toVillage(true); G.openStation('cay'); G.upgrade(); })],
  ['05-hop', 'Hop!: a quick check halves calm, an open resets it', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.openHop(); })],
  ['06-quick-check', 'Quick check: calm halves, no jealousy', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.openApp(true); }), 500],
  ['07-pout-reset', 'A full open: calm back to ×1.0, Pofu pouts', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.openApp(false); }), 1300],
  ['08-hop-over', 'Past 60 minutes: every open waits for a breath', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.useLimit(); G.openHop(); })],
  ['09-breath', 'The breathing break waits for your tap: “Breathe with Pofu”', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.useLimit(); G.wantOpen(false); }); }, 250],
  ['10-breath-done', 'After a 5 s breath: skip is first, opening stays one tap', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.useLimit(); G.wantOpen(false); G.breathAt(5400); }); }, 900],
  ['11-unwell', 'After a binge: Pofu is unwell, never gone', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.binge(); }), 3000],
  ['12-expansion', 'Next morning: the island grew, the lily pond plot', async (p) => p.evaluate(() => { G.fastForward(5); G.set({ day: 4, tended: 3, stage: 1 }); G.collect(); G.toVillage(true); G.nextDay(); }), 1700],
  ['13-iskele-arrives', 'Day 9: a new island drifted close in the night', async (p) => p.evaluate(() => { G.fastForward(8); G.collect(); G.nextDay(); })],
  ['14-map', 'The archipelago: home, İskele, three teasers', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.toMap(true); }), 1600],
  ['15-isle-sheet', 'A locked island: its own loop, neighbor, and when', async (p) => p.evaluate(() => { G.fastForward(20); G.collect(); G.toMap(true); G.openIsle('stars'); }), 1200],
  ['16-harbor', 'İskele: Simit’s cart, the ferry pier, the lighthouse', async (p) => p.evaluate(() => { G.fastForward(20); G.collect(); G.visit('harbor', true); }), 1600],
  ['17-night', 'Bedtime: the island sleeps, Pofu too', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.setNight(true); })],
  ['m1-phone-home', 'Phone, full-screen: safe areas, no frame', async () => {}, 1400, 'phone'],
  ['m2-phone-map', 'Phone: the archipelago map', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.toMap(true); }), 1600, 'phone'],
  ['m3-phone-breath', 'Phone: the breathing break, mid-breath', async (p) => p.evaluate(() => { G.fastForward(11); G.collect(); G.useLimit(); G.wantOpen(false); G.breathAt(1800); }), 250, 'phone'],
  ['m4-phone-demo', 'Phone: the demo drawer scrolls with touch', async (p) => p.evaluate(() => { G.drawer(true); }), 900, 'phone'],
];

async function shoot(browser, out, [name, , fn, settle = 1400, kind]) {
  const phone = kind === 'phone';
  const ctx = phone
    ? await browser.newContext({ ...devices['iPhone 15'], deviceScaleFactor: 2 })
    : await browser.newContext({ viewport: { width: 560, height: 960 }, deviceScaleFactor: 2 });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.error('PAGEERROR', name, e.message));
  page.on('console', (m) => { if (m.type() === 'error') console.error('CONSOLE', name, m.text()); });
  await page.goto(`file://${ROOT}/index.html${phone ? '' : '#bare'}`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);
  await fn(page);
  await page.waitForTimeout(settle);
  if (phone) await page.screenshot({ path: path.join(out, `${name}.png`) });
  else await (await page.$('#device')).screenshot({ path: path.join(out, `${name}.png`), omitBackground: true });
  await ctx.close();
  console.log('rendered', name);
}

async function overview(browser, out, list) {
  const page = await browser.newPage({ viewport: { width: 2400, height: 1600 }, deviceScaleFactor: 1 });
  const cells = list.map(([name, caption, , , kind]) => `<figure class="${kind || ''}"><img src="${name}.png"><figcaption><b>${name.split('-')[0]}</b> ${caption}</figcaption></figure>`).join('');
  const tmp = path.join(out, '_overview.html');
  fs.writeFileSync(tmp, `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
    @font-face { font-family: Nunito; src: url("file://${ROOT}/fonts/nunito-latin-wght-normal.woff2"); font-weight: 200 1000; }
    @font-face { font-family: Nunito; src: url("file://${ROOT}/fonts/nunito-latin-ext-wght-normal.woff2"); font-weight: 200 1000; unicode-range: U+0100-024F; }
    @font-face { font-family: "Baloo 2"; src: url("file://${ROOT}/fonts/baloo-2-latin-wght-normal.woff2"); font-weight: 400 800; }
    body { margin: 0; background: #EFE6E1; font-family: Nunito, sans-serif; color: #2A1F2D; }
    #sheet { padding: 40px 48px 36px; width: max-content; }
    h1 { font-family: "Baloo 2"; font-size: 46px; margin: 0; line-height: 1; }
    p { margin: 6px 0 26px; font-size: 18px; color: #66555F; font-weight: 650; }
    .grid { display: grid; grid-template-columns: repeat(7, 280px); gap: 26px 24px; align-items: start; }
    figure { margin: 0; } img { width: 280px; display: block; }
    figure.phone img { width: 258px; margin: 0 11px; border-radius: 30px; box-shadow: 0 0 0 6px #1B1620; }
    figcaption { font-size: 14.5px; font-weight: 700; margin-top: 8px; line-height: 1.3; color: #4A3B4A; }
    figure.phone figcaption { margin-top: 14px; }
    figcaption b { color: #6C4FD8; margin-right: 4px; }
  </style></head><body><div id="sheet"><h1>Pofu's archipelago · playable prototype</h1>
  <p>Seeds are world material, never screen time. A quick check halves calm; past 60 minutes, every open waits for a 5 s breath you start with Pofu. New islands drift close over time. Stand-in art except Pofu (R1) and Mochi (concept).</p>
  <div class="grid">${cells}</div></div></body></html>`);
  await page.goto(`file://${tmp}`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(500);
  await (await page.$('#sheet')).screenshot({ path: path.join(out, 'overview.png') });
  fs.unlinkSync(tmp);
  await page.close();
  console.log('rendered overview.png');
}

async function main() {
  const out = path.resolve(process.argv[2] || path.join(ROOT, 'screenshots'));
  fs.mkdirSync(out, { recursive: true });
  const only = process.argv.slice(3);
  const browser = await chromium.launch();
  const list = only.length ? SHOTS.filter((s) => only.includes(s[0])) : SHOTS;
  for (const s of list) await shoot(browser, out, s);
  if (!only.length) await overview(browser, out, SHOTS);
  await browser.close();
}
main();
