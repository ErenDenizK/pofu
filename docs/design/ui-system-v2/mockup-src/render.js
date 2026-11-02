// Renders the UI system v2 boards of mock.html to PNG (Playwright, Chromium).
//   NODE_PATH=$(npm root -g) node render.js <outdir> [board ...]
// Boards: home, skins, game, today (default: all four).
const { chromium } = require('playwright');
const path = require('path');
const NAMES = {
  home: '01-home-day-night.png',
  skins: '02-home-glass-vs-crafted.png',
  game: '03-island-game-round.png',
  today: '04-today-panel.png',
  test: 'test.png',
};
(async () => {
  const out = process.argv[2];
  const list = process.argv.slice(3).length ? process.argv.slice(3) : ['home', 'skins', 'game', 'today'];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 2000, height: 1200 }, deviceScaleFactor: 2 });
  for (const b of list) {
    await page.goto('file://' + path.join(__dirname, 'mock.html') + '?b=' + b);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(500);
    await page.locator('#board').screenshot({ path: path.join(out, NAMES[b] || b + '.png') });
    console.log('wrote', b);
  }
  await browser.close();
})();
