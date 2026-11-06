// Renders the critique boards of mock.html to PNG (Playwright, Chromium).
//   NODE_PATH=<global node_modules> node render.js <outdir>
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const out = process.argv[2];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 2000, height: 1200 }, deviceScaleFactor: 2 });
  for (const b of ['current', 'a', 'b', 'c', 'compare']) {
    await page.goto('file://' + path.join(__dirname, 'mock.html') + '?b=' + b);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(300);
    await page.locator('#board').screenshot({ path: path.join(out, b + '.png') });
    console.log('wrote', b);
  }
  await browser.close();
})();
