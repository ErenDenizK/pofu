// Renders the island game prototype states with Playwright (Chromium), device only, at 2x,
// plus overview.png (all key states on one sheet).
//
//   node tools/render.js [OUTDIR]          default: ../screenshots
//   node tools/render.js OUTDIR name ...   only the named shots
//
// Then optimize: pngquant --quality 70-92 --speed 1 --force --ext .png screenshots/*.png
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..');

// Each shot: a fresh page, a script against window.G, a settle time.
const SHOTS = [
  ['01-home', 'Home: Pofu up close, calm ×1.3 growing, goodies waiting', async (p) => {}],
  ['02-zoom', 'Tap the island: the camera pulls back', async (p) => { await p.evaluate(() => { G.collect(); G.toVillage(true); G.lerpCam(0.5); }); }],
  ['03-village-day1', 'Day 1: Pofu’s garden, the çay ocağı plot waits', async (p) => { await p.evaluate(() => { G.collect(); G.toVillage(true); }); }],
  ['04-station-sheet', 'Tap a station: the next designed level, pick a style', async (p) => { await p.evaluate(() => { G.fastForward(5); G.collect(); G.toVillage(true); G.openStation('cay'); }); }],
  ['05-upgraded', 'Upgraded: çay ocağı level 3, Pofu is excited', async (p) => { await p.evaluate(() => { G.fastForward(5); G.collect(); G.toVillage(true); G.openStation('cay'); G.upgrade(); }); }, 900],
  ['06-hop-jealous', 'Hop!: jealous Pofu, and what opening would cost', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.openHop(); }); }],
  ['07-pout-reset', 'Opened anyway: calm resets to ×1.0, Pofu pouts', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.openApp(); }); }, 1300],
  ['08-smug', 'Calm ×2.0: smug Pofu', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.quietHour(); G.quietHour(); }); }],
  ['09-unwell', 'After a binge: Pofu is unwell, never gone', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.binge(); }); }, 3000],
  ['10-expansion', 'Next morning: the island grew, two new slots', async (p) => { await p.evaluate(() => { G.fastForward(5); G.set({ day: 4, tended: 3, stage: 1, levels: { ...G.S().levels, simit: 0, pond: 0 } }); G.collect(); G.toVillage(true); G.nextDay(); }); }, 1600],
  ['11-village-day11', 'Day 11: the terrace opens (library, workshop)', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.toVillage(true); }); }],
  ['12-night', 'Bedtime: the island sleeps, Pofu too', async (p) => { await p.evaluate(() => { G.fastForward(11); G.collect(); G.setNight(true); }); }],
  ['13-village-day36', 'Day 36: stage 6, both islets', async (p) => { await p.evaluate(() => { G.fastForward(36); G.collect(); G.toVillage(true); }); }],
];

async function shoot(browser, out, [name, , fn, settle = 1400]) {
  const page = await browser.newPage({ viewport: { width: 470, height: 940 }, deviceScaleFactor: 2 });
  page.on('pageerror', (e) => console.error('PAGEERROR', name, e.message));
  page.on('console', (m) => { if (m.type() === 'error') console.error('CONSOLE', name, m.text()); });
  await page.goto(`file://${ROOT}/index.html?bare=1`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);
  await fn(page);
  await page.waitForTimeout(settle);
  await (await page.$('#device')).screenshot({ path: path.join(out, `${name}.png`), omitBackground: true });
  await page.close();
  console.log('rendered', name);
}

async function overview(browser, out, list) {
  const page = await browser.newPage({ viewport: { width: 2400, height: 1600 }, deviceScaleFactor: 1 });
  const cells = list.map(([name, caption]) => `<figure><img src="${name}.png"><figcaption><b>${name.slice(0, 2)}</b> ${caption}</figcaption></figure>`).join('');
  const tmp = path.join(out, '_overview.html');
  fs.writeFileSync(tmp, `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
    @font-face { font-family: Nunito; src: url("file://${ROOT}/../../boards/fonts/nunito-latin-wght-normal.woff2"); font-weight: 200 1000; }
    @font-face { font-family: "Baloo 2"; src: url("file://${ROOT}/../../boards/fonts/baloo-2-latin-wght-normal.woff2"); font-weight: 400 800; }
    body { margin: 0; background: #EFE6E1; font-family: Nunito, sans-serif; color: #2A1F2D; }
    #sheet { padding: 40px 48px 36px; width: max-content; }
    h1 { font-family: "Baloo 2"; font-size: 46px; margin: 0; line-height: 1; }
    p { margin: 6px 0 26px; font-size: 18px; color: #66555F; font-weight: 650; }
    .grid { display: grid; grid-template-columns: repeat(7, 300px); gap: 28px 26px; }
    figure { margin: 0; } img { width: 300px; display: block; }
    figcaption { font-size: 15px; font-weight: 700; margin-top: 8px; line-height: 1.3; color: #4A3B4A; }
    figcaption b { color: #6C4FD8; margin-right: 4px; }
  </style></head><body><div id="sheet"><h1>Pofu's island · playable prototype</h1>
  <p>Home close-up → fixed-camera diorama. Care over currency: Pofu's wellbeing, the calm multiplier, idle stations. Stand-in art except Pofu (R1) and Mochi (concept).</p>
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
  const only = process.argv.slice(3);
  const browser = await chromium.launch();
  const list = only.length ? SHOTS.filter((s) => only.includes(s[0])) : SHOTS;
  for (const s of list) await shoot(browser, out, s);
  if (!only.length) await overview(browser, out, SHOTS);
  await browser.close();
}
main();
