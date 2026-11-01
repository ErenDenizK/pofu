// Checks and screenshots for the design review page (Playwright, Chromium).
//
//   node tools/check-review.js            checks only
//   node tools/check-review.js --shots    checks, then writes screenshots/ (pngquant them after)
//
// Phone (iPhone 15 emulation, touch; and 375 px wide): no horizontal page scroll, every visible
// interactive element at least 44 x 44 pt, the carousels swipe inside their own container, the
// framing buttons change a mock. Desktop: three phones side by side. Sandbox: the page inside
// <iframe sandbox="allow-scripts"> over HTTP, with relative fonts and assets. Size under 8 MB.
// Exits non-zero on any failure.
const { chromium, devices } = require('playwright');
const path = require('path');
const fs = require('fs');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const SHOTS = process.argv.includes('--shots');
let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`); if (!cond) failures++; };

function serve() {
  const types = { '.html': 'text/html; charset=utf-8', '.webp': 'image/webp', '.woff2': 'font/woff2', '.png': 'image/png', '.js': 'text/javascript' };
  const srv = http.createServer((req, res) => {
    const u = decodeURIComponent(req.url.split('?')[0].split('#')[0]);
    if (u === '/wrap.html') { res.writeHead(200, { 'content-type': types['.html'] }); res.end('<!doctype html><meta charset="utf-8"><body style="margin:0"><iframe sandbox="allow-scripts" src="/index.html" style="width:390px;height:844px;border:0"></iframe>'); return; }
    const f = path.join(ROOT, path.normalize(u === '/' ? '/index.html' : u).replace(/^(\.\.[/\\])+/, ''));
    if (!f.startsWith(ROOT) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream', 'access-control-allow-origin': '*' });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv)));
}

async function noHScroll(page, label) {
  const m = await page.evaluate(() => ({ sw: document.documentElement.scrollWidth, w: window.innerWidth }));
  ok(m.sw <= m.w, `${label}: no horizontal page scroll (${m.sw}/${m.w})`);
}
async function targets(page, label) {
  const bad = await page.evaluate(() => {
    const out = [];
    for (const el of document.querySelectorAll('button, a[href], [role="tab"], summary, input')) {
      const r = el.getBoundingClientRect(); const cs = getComputedStyle(el);
      if (!r.width || !r.height || cs.visibility === 'hidden' || cs.display === 'none') continue;
      if (r.width < 43.5 || r.height < 43.5) out.push(`${el.tagName}.${el.className} "${el.textContent.trim().slice(0, 24)}" ${Math.round(r.width)}×${Math.round(r.height)}`);
    }
    return out;
  });
  ok(bad.length === 0, `${label}: every interactive element is at least 44 × 44 pt${bad.length ? ' — ' + bad.slice(0, 5).join('; ') : ''}`);
}
const settle = (p, ms) => p.waitForTimeout(ms);
async function shot(page, name, opts = {}) {
  if (!SHOTS) return;
  await page.screenshot({ path: path.join(ROOT, 'screenshots', name + '.png'), ...opts });
  console.log('  shot', name);
}
async function shotEl(page, sel, name) {
  if (!SHOTS) return;
  await page.locator(sel).first().screenshot({ path: path.join(ROOT, 'screenshots', name + '.png') });
  console.log('  shot', name);
}

(async () => {
  const srv = await serve();
  const base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  if (SHOTS) fs.mkdirSync(path.join(ROOT, 'screenshots'), { recursive: true });

  // ---------------------------------------------------------------- size
  let bytes = 0; const walk = (d) => { for (const f of fs.readdirSync(d)) { const p = path.join(d, f); const st = fs.statSync(p); if (st.isDirectory()) { if (!['screenshots', 'tools'].includes(f)) walk(p); } else bytes += st.size; } };
  walk(ROOT);
  ok(bytes < 8 * 1024 * 1024, `publishable files total ${(bytes / 1024 / 1024).toFixed(2)} MB (< 8 MB)`);

  // ---------------------------------------------------------------- phone: iPhone 15, touch
  for (const [label, dev] of [['iPhone 15', devices['iPhone 15']], ['375 px', { ...devices['iPhone SE'], viewport: { width: 375, height: 740 } }]]) {
    const ctx = await browser.newContext({ ...dev });
    const page = await ctx.newPage();
    const errors = []; page.on('pageerror', (e) => errors.push(e.message)); page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('dialog', (d) => { errors.push('dialog: ' + d.message()); d.dismiss(); });
    await page.goto(base + '/index.html'); await page.waitForFunction(() => window.REVIEW && window.REVIEW.ready);
    await settle(page, 800);
    await noHScroll(page, `${label} top`);
    await targets(page, `${label} page`);
    const vpMeta = await page.evaluate(() => document.querySelector('meta[name=viewport]').content);
    ok(/viewport-fit=cover/.test(vpMeta), `${label}: viewport-fit=cover`);
    ok(await page.evaluate(() => document.characterSet === 'UTF-8'), `${label}: UTF-8`);
    if (label === 'iPhone 15') await shot(page, 'p1-phone-hero');
    // Each concept: scroll to it, check the carousel, swipe, tap a framing.
    for (const [id, name] of [['olcu', 'proportion'], ['arayuz', 'ui-language'], ['hareket', 'choreography']]) {
      await page.locator('#' + id).scrollIntoViewIfNeeded();
      await page.evaluate((id) => document.getElementById(id).scrollIntoView(), id);
      await settle(page, 300);
      await noHScroll(page, `${label} ${name}`);
      const trio = `#${id} .trio`;
      const can = await page.$eval(trio, (e) => e.scrollWidth > e.clientWidth + 10 && getComputedStyle(e).overflowX === 'auto');
      ok(can, `${label} ${name}: the three mocks form a swipeable carousel`);
      // Tap the second tab: the carousel scrolls to card B.
      await page.locator(`#${id} .tabs button`).nth(1).tap();
      await settle(page, 700);
      const sl = await page.$eval(trio, (e) => e.scrollLeft);
      ok(sl > 100, `${label} ${name}: the B tab scrolls the carousel (scrollLeft ${Math.round(sl)})`);
      // Touch swipe inside the carousel.
      const box = await page.locator(trio).boundingBox();
      const cdp = await ctx.newCDPSession(page);
      const y = box.y + 120, x0 = box.x + box.width * 0.8, x1 = box.x + box.width * 0.15;
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: x0, y }] });
      for (let i = 1; i <= 8; i++) await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: x0 + (x1 - x0) * i / 8, y }] });
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
      await settle(page, 800);
      const sl2 = await page.$eval(trio, (e) => e.scrollLeft);
      ok(sl2 > sl + 50, `${label} ${name}: a touch swipe moves to the next mock (${Math.round(sl)} → ${Math.round(sl2)})`);
      await noHScroll(page, `${label} ${name} after swipe`);
      // Back to B and tap its second framing button.
      await page.locator(`#${id} .tabs button`).nth(1).tap(); await settle(page, 700);
      const card = `#${id} .card[data-alt="B"]`;
      await page.locator(`${card} .seg button`).nth(1).tap();
      await settle(page, 1600);
      ok(await page.$eval(`${card} .seg button:nth-child(2)`, (b) => b.getAttribute('aria-pressed') === 'true'), `${label} ${name}: a framing button switches the B mock`);
      if (id === 'olcu') { await page.locator(`${card} .tog`).tap(); await settle(page, 500); ok(await page.$eval(`${card} .ovl`, (e) => e.classList.contains('on')), `${label}: "Ölçüler" shows the measurement overlay`); }
      await targets(page, `${label} ${name}`);
      if (label === 'iPhone 15') await shot(page, `p-${name}`);
    }
    // Moments and summary.
    await page.evaluate(() => document.getElementById('anlar').scrollIntoView()); await settle(page, 2400);
    await noHScroll(page, `${label} moments`);
    await targets(page, `${label} moments`);
    if (label === 'iPhone 15') await shot(page, 'p-moments');
    await page.evaluate(() => document.getElementById('ozet').scrollIntoView()); await settle(page, 400);
    await noHScroll(page, `${label} summary`);
    if (label === 'iPhone 15') await shot(page, 'p-summary');
    ok(errors.length === 0, `${label}: no page errors or dialogs${errors.length ? ' — ' + errors.slice(0, 3).join(' | ') : ''}`);
    await ctx.close();
  }

  // ---------------------------------------------------------------- desktop
  {
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    const errors = []; page.on('pageerror', (e) => errors.push(e.message));
    await page.goto(base + '/index.html'); await page.waitForFunction(() => window.REVIEW && window.REVIEW.ready);
    await settle(page, 600);
    await noHScroll(page, 'desktop');
    const cols = await page.$$eval('#olcu .trio > .card', (cs) => cs.map((c) => Math.round(c.getBoundingClientRect().top)));
    ok(cols.length === 3 && new Set(cols).size === 1, 'desktop: the three mocks sit side by side');
    ok(await page.$eval('#olcu .tabs', (e) => getComputedStyle(e).display === 'none'), 'desktop: no carousel tabs');
    await shot(page, 'd0-top');
    for (const [id, name] of [['olcu', 'proportion'], ['arayuz', 'ui-language'], ['hareket', 'choreography']]) {
      await page.evaluate((id) => document.getElementById(id).scrollIntoView(), id); await settle(page, 900);
      if (id === 'olcu') { for (const a of ['A', 'B', 'C']) await page.locator(`#olcu .card[data-alt="${a}"] .tog`).click(); await settle(page, 500); }
      await shotEl(page, `#${id} .trio`, `d-${name}`);
    }
    // Choreography mid-transition: tap "Ada" on all three and catch the move.
    await page.evaluate(() => document.getElementById('hareket').scrollIntoView()); await settle(page, 300);
    for (const a of ['A', 'B', 'C']) await page.locator(`#hareket .card[data-alt="${a}"] .seg button`).nth(0).click();
    await settle(page, 2600);
    for (const a of ['A', 'B', 'C']) await page.locator(`#hareket .card[data-alt="${a}"] .seg button`).nth(2).click();
    await settle(page, 380);
    await shotEl(page, '#hareket .trio', 'd-choreography-mid');
    await settle(page, 2200);
    // Framing states for the proportion overlay, one per framing.
    for (const [i, n] of [[0, 'home'], [1, 'island'], [2, 'map']]) {
      for (const a of ['A', 'B', 'C']) await page.locator(`#olcu .card[data-alt="${a}"] .seg button`).nth(i).click();
      await settle(page, 1700);
      await shotEl(page, '#olcu .trio', `d-proportion-${n}`);
    }
    for (const [i, n] of [[1, 'sheet'], [2, 'hop']]) {
      for (const a of ['A', 'B', 'C']) await page.locator(`#arayuz .card[data-alt="${a}"] .seg button`).nth(i).click();
      await settle(page, 900);
      await shotEl(page, '#arayuz .trio', `d-ui-${n}`);
    }
    await page.evaluate(() => document.getElementById('anlar').scrollIntoView()); await settle(page, 300);
    for (const b of await page.locator('.moment .play').all()) await b.click();
    await settle(page, 2100);
    await shotEl(page, '#anlar .moments', 'd-moments-mid');
    await settle(page, 4200);
    await shotEl(page, '#anlar .moments', 'd-moments-end');
    await page.evaluate(() => document.getElementById('ozet').scrollIntoView()); await settle(page, 300);
    await shotEl(page, '#ozet', 'd-summary');
    ok(errors.length === 0, `desktop: no page errors${errors.length ? ' — ' + errors.join(' | ') : ''}`);
    await ctx.close();
  }

  // ---------------------------------------------------------------- sandbox
  {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const page = await ctx.newPage();
    const errors = [], failed = [];
    page.on('pageerror', (e) => errors.push(e.message)); page.on('requestfailed', (r) => failed.push(r.url()));
    page.on('response', (r) => { if (r.status() >= 400) failed.push(r.status() + ' ' + r.url()); });
    await page.goto(base + '/wrap.html'); await settle(page, 1500);
    const fr = page.frames().find((f) => f.url().endsWith('/index.html'));
    ok(!!fr, 'sandbox: the page loads inside <iframe sandbox="allow-scripts">');
    if (fr) {
      ok(await fr.evaluate(() => !!(window.REVIEW && window.REVIEW.ready)), 'sandbox: scripts run');
      const fonts = await fr.evaluate(async () => { await document.fonts.ready; return [...document.fonts].filter((f) => f.status === 'loaded').length; });
      ok(fonts >= 2, `sandbox: relative font files load (${fonts} faces)`);
      const imgs = await fr.evaluate(() => [...document.images].filter((i) => i.complete && i.naturalWidth === 0 && i.getAttribute('src')).map((i) => i.src).slice(0, 3));
      ok(imgs.length === 0, `sandbox: every image loads${imgs.length ? ' — ' + imgs.join(', ') : ''}`);
      ok(await fr.evaluate(() => !/[?]/.test([...document.querySelectorAll('[src],[href]')].map((e) => e.getAttribute('src') || e.getAttribute('href')).join(' '))), 'sandbox: no query strings in URLs');
    }
    ok(errors.length === 0 && failed.length === 0, `sandbox: no errors or failed requests${errors.concat(failed).length ? ' — ' + errors.concat(failed).slice(0, 3).join(' | ') : ''}`);
    await ctx.close();
  }
  await browser.close(); srv.close();
  console.log(failures ? `\n${failures} check(s) failed` : '\nAll checks passed');
  process.exit(failures ? 1 : 0);
})();
