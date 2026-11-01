// Renders design-language.html to design-language.png with headless Chromium.
// Usage: node design/boards/render.js [scale]   (requires the `playwright` package)
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const scale = Number(process.argv[2] || 1);
  const html = path.join(__dirname, 'design-language.html');
  const out = path.join(__dirname, 'design-language.png');
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1680, height: 1200 }, deviceScaleFactor: scale });
  await page.goto('file://' + html);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(400);
  await page.screenshot({ path: out, fullPage: true });
  await browser.close();
  console.log('Wrote ' + out);
})();
