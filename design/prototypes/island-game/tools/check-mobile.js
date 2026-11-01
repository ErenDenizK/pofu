// Automated phone and desktop checks for the island game prototype (Playwright, Chromium).
//
//   node tools/check-mobile.js
//
// Phone (iPhone 15 and iPhone SE emulation, touch, mobile): full-screen layout, no horizontal
// overflow in any state, taps on the canvas and chrome, touch scrolling inside sheets and the
// demo drawer, tap targets of at least 44 pt, no touch-action: none. Desktop: the device frame
// and the side panel. Sandbox: the page inside <iframe sandbox="allow-scripts"> over HTTP.
// Exits non-zero on any failure.
const { chromium, devices } = require('playwright');
const path = require('path');
const fs = require('fs');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`); if (!cond) failures++; };

function serve() {
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.woff2': 'font/woff2', '.png': 'image/png' };
  const srv = http.createServer((req, res) => {
    const u = decodeURIComponent(req.url.split('?')[0].split('#')[0]);
    if (u === '/wrap.html') { res.writeHead(200, { 'content-type': types['.html'] }); res.end('<!doctype html><meta charset="utf-8"><body style="margin:0"><iframe sandbox="allow-scripts" src="/index.html" style="width:390px;height:844px;border:0"></iframe>'); return; }
    const f = path.join(ROOT, path.normalize(u).replace(/^(\.\.[/\\])+/, ''));
    if (!f.startsWith(ROOT) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
    // A sandboxed iframe has an opaque origin, so fonts load in CORS mode: like a static host or CDN,
    // send Access-Control-Allow-Origin. Without it the fonts fall back to ui-rounded/system-ui.
    res.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream', 'access-control-allow-origin': '*' });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv)));
}

async function noHScroll(page, label) {
  const m = await page.evaluate(() => ({ sw: document.documentElement.scrollWidth, bw: document.body.scrollWidth, w: window.innerWidth }));
  ok(m.sw <= m.w && m.bw <= m.w, `${label}: no horizontal overflow (${m.sw}/${m.w})`);
}
async function touchScroll(page, cdp, selector, label) {
  const box = await page.locator(selector).boundingBox();
  const before = await page.$eval(selector, (e) => ({ top: e.scrollTop, can: e.scrollHeight > e.clientHeight + 2 }));
  ok(before.can, `${label}: content is taller than the panel, so it must scroll`);
  // A real finger: touchStart, a dozen touchMoves upward, touchEnd (dispatched as touch events, so
  // anything that swallowed touchmove or set touch-action: none would make this fail).
  const x = box.x + box.width / 2, y0 = box.y + box.height * 0.75;
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y: y0 }] });
  for (let i = 1; i <= 12; i++) { await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x, y: y0 - i * 22 }] }); await page.waitForTimeout(16); }
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await page.waitForTimeout(500);
  const { after, max } = await page.$eval(selector, (e) => ({ after: e.scrollTop, max: e.scrollHeight - e.clientHeight }));
  ok(after >= Math.min(before.top + 40, max - 1), `${label}: a touch swipe scrolls it (${before.top} → ${Math.round(after)})`);
}
async function tapTargets(page, label) {
  const small = await page.evaluate(() => [...document.querySelectorAll('#chrome button, #sheet-root button, .demo-tab, #panel button')]
    .filter((b) => { const r = b.getBoundingClientRect(); const cs = getComputedStyle(b); return r.width && r.height && cs.visibility !== 'hidden' && cs.pointerEvents !== 'none' && b.closest('.layer.off') === null && Number(cs.opacity) > 0.1; })
    .map((b) => { const r = b.getBoundingClientRect(); return { t: (b.getAttribute('aria-label') || b.textContent).trim().slice(0, 28), w: Math.round(r.width), h: Math.round(r.height) }; })
    .filter((x) => x.w < 44 || x.h < 44));
  ok(small.length === 0, `${label}: every visible tap target is at least 44 × 44 pt${small.length ? ' — ' + JSON.stringify(small) : ''}`);
}

async function phone(browser, device, label) {
  const ctx = await browser.newContext({ ...devices[device], hasTouch: true, isMobile: true });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('dialog', (d) => { errors.push('dialog: ' + d.type()); d.dismiss(); });
  await page.goto(`file://${ROOT}/index.html`);
  await page.waitForTimeout(600);
  const cdp = await ctx.newCDPSession(page);
  const vp = page.viewportSize();

  const scr = await page.locator('#screen').boundingBox();
  ok(Math.abs(scr.width - vp.width) < 1 && Math.abs(scr.height - vp.height) < 1, `${label}: the game fills the screen (${Math.round(scr.width)}×${Math.round(scr.height)} of ${vp.width}×${vp.height})`);
  ok(await page.$eval('.status', (e) => getComputedStyle(e).display === 'none'), `${label}: no fake status bar or device frame`);
  const ta = await page.evaluate(() => ['html', 'body', '#device', '#screen', '#world', '#panel'].map((s) => getComputedStyle(document.querySelector(s)).touchAction));
  ok(!ta.includes('none'), `${label}: nothing sets touch-action: none (${ta.join(', ')})`);
  const top = await page.$eval('.layer:not(.off) .topbar', (e) => e.getBoundingClientRect().top);
  ok(top >= 8 && top <= 60, `${label}: the top bar sits at the safe-area inset, not under a fake status bar (${Math.round(top)} px)`);
  await noHScroll(page, `${label} home`);
  await tapTargets(page, `${label} home`);

  // taps: the canvas pulls back to the island
  await page.touchscreen.tap(vp.width * 0.16, vp.height * 0.64);
  await page.waitForTimeout(1100);
  ok(await page.evaluate(() => G.S().mode === 'isle'), `${label}: tapping the island on Home opens the island view`);
  await noHScroll(page, `${label} island`);
  await tapTargets(page, `${label} island`);
  await page.locator('[aria-label="Archipelago map"]').tap();
  await page.waitForTimeout(1200);
  ok(await page.evaluate(() => G.S().mode === 'map'), `${label}: the map button opens the archipelago`);
  await noHScroll(page, `${label} map`);

  // the demo drawer: open by tap, scroll by touch, act by tap
  await page.locator('#demoTab').tap();
  await page.waitForTimeout(600);
  ok(await page.evaluate(() => document.body.classList.contains('drawer-open')), `${label}: the Demo tab opens the drawer`);
  await touchScroll(page, cdp, '#panel', `${label} demo drawer`);
  await tapTargets(page, `${label} demo drawer`);
  await page.locator('#panel [data-act="ff11"]').tap();
  await page.waitForTimeout(600);
  ok(await page.evaluate(() => G.S().day === 11 && !document.body.classList.contains('drawer-open')), `${label}: a drawer action applies and closes the drawer`);

  // map → tap the harbor island → island sheet → visit
  await page.evaluate(() => G.toMap(true));
  await page.waitForTimeout(300);
  const hp = await page.evaluate(() => { const r = document.getElementById('world').getBoundingClientRect(); const s = G.S(); return { x: r.left + r.width / 2 + (220 - 0) * 0.48 * Math.min(1.1, r.width / 402, r.height / 874), y: r.top + (300 + 70 + 25) * 0.48 * Math.min(1.1, r.width / 402, r.height / 874) + 437 * r.height / 874 }; });
  await page.touchscreen.tap(hp.x, hp.y);
  await page.waitForTimeout(700);
  ok(await page.evaluate(() => G.S().sheet === 'isle:harbor'), `${label}: tapping İskele on the map opens its sheet`);
  await noHScroll(page, `${label} island sheet`);
  await tapTargets(page, `${label} island sheet`);
  const tall = await page.$eval('.isle-sheet', (e) => e.scrollHeight > e.clientHeight + 2);
  if (tall) await touchScroll(page, cdp, '.isle-sheet', `${label} island sheet`);
  else ok(true, `${label} island sheet: fits without scrolling`);
  await page.locator('[data-visit="harbor"]').tap();
  await page.waitForTimeout(900);
  ok(await page.evaluate(() => G.S().mode === 'isle' && G.S().isle === 'harbor'), `${label}: “Visit İskele” moves to the harbor`);

  // Hop! and the breathing break
  await page.evaluate(() => { G.toHome(true); G.useLimit(); G.openHop(); });
  await page.waitForTimeout(500);
  await noHScroll(page, `${label} Hop!`);
  await tapTargets(page, `${label} Hop!`);
  if (await page.$eval('.hop', (e) => e.scrollHeight > e.clientHeight + 2)) await touchScroll(page, cdp, '.hop', `${label} Hop!`);
  await page.locator('[data-ui="open"]').tap();
  await page.waitForTimeout(400);
  ok(await page.evaluate(() => G.S().sheet === 'breath'), `${label}: past 60 min, “Open” starts the breathing break`);
  await noHScroll(page, `${label} breathing break`);
  await page.evaluate(() => G.breathAt(10200));
  await page.waitForTimeout(700);
  await page.locator('.breath [data-ui="breathSkip"]').first().tap();
  await page.waitForTimeout(400);
  ok(await page.evaluate(() => G.S().beads.slice(-1)[0] === 'S' && !G.S().sheet), `${label}: “I’m good. Skip it” after the breath counts as a skip`);

  ok(errors.length === 0, `${label}: no page errors or dialogs${errors.length ? ' — ' + errors.join('; ') : ''}`);
  await ctx.close();
}

async function desktop(browser) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 960 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto(`file://${ROOT}/index.html`);
  await page.waitForTimeout(500);
  const dev = await page.locator('#device').boundingBox();
  ok(Math.round(dev.width) === 426 && Math.round(dev.height) === 898, `desktop: the device frame is kept (${Math.round(dev.width)}×${Math.round(dev.height)})`);
  ok(await page.$eval('#panel', (e) => getComputedStyle(e).position !== 'fixed' && e.getBoundingClientRect().width > 300), 'desktop: the demo panel sits beside the device');
  ok(await page.$eval('#demoTab', (e) => getComputedStyle(e).display === 'none'), 'desktop: no Demo tab');
  await noHScroll(page, 'desktop');
  await page.click('#panel [data-act="reach"]');
  await page.waitForTimeout(300);
  ok(await page.evaluate(() => G.S().sheet === 'hop'), 'desktop: panel buttons work');
  ok(errors.length === 0, `desktop: no page errors${errors.length ? ' — ' + errors.join('; ') : ''}`);
  await page.setViewportSize({ width: 720, height: 900 });
  await page.waitForTimeout(200);
  await noHScroll(page, 'desktop at 720 px');
  await page.close();
}

async function sandboxed(browser, port) {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('dialog', (d) => { errors.push('dialog'); d.dismiss(); });
  page.on('requestfailed', (r) => errors.push('failed ' + r.url()));
  await page.goto(`http://127.0.0.1:${port}/wrap.html`);
  await page.waitForTimeout(1200);
  const frame = page.frames().find((f) => f.url().endsWith('/index.html'));
  ok(!!frame, 'sandbox: the page loads inside <iframe sandbox="allow-scripts">');
  const st = await frame.evaluate(() => ({ day: G.S().day, mode: G.S().mode, fonts: [...document.fonts].filter((f) => f.status === 'loaded').length, w: document.getElementById('world').getBoundingClientRect().width }));
  ok(st.day === 1 && st.w > 380, `sandbox: the game runs and fills the frame (${Math.round(st.w)} px)`);
  ok(st.fonts >= 2, `sandbox: the bundled fonts load from relative files (${st.fonts} faces)`);
  await frame.locator('#demoTab').click();
  await frame.locator('#panel [data-act="nextDay"]').click();
  await page.waitForTimeout(400);
  ok(await frame.evaluate(() => G.S().day === 2), 'sandbox: the in-page demo drawer drives the game (no query strings)');
  ok(errors.length === 0, `sandbox: no errors, dialogs or failed requests${errors.length ? ' — ' + errors.join('; ') : ''}`);
  await page.close();
}

function staticChecks() {
  const js = fs.readFileSync(path.join(ROOT, 'game.js'), 'utf8');
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const css = fs.readFileSync(path.join(ROOT, 'island.css'), 'utf8');
  ok(!/\b(alert|confirm|prompt)\s*\(/.test(js), 'static: no alert, confirm or prompt');
  ok(!/location\.search|URLSearchParams/.test(js), 'static: no query strings');
  ok(!/preventDefault/.test(js), 'static: no preventDefault (nothing can swallow a scroll)');
  ok(!/\.\.\//.test(css + html), 'static: only relative paths inside the prototype folder (no ../)');
  ok(/viewport-fit=cover/.test(html), 'static: viewport-fit=cover');
  ok(/100dvh/.test(css), 'static: 100dvh for the full-screen layout');
  ok(/env\(safe-area-inset-top/.test(css) && /env\(safe-area-inset-bottom/.test(css), 'static: chrome respects safe-area insets');
}

(async () => {
  staticChecks();
  const srv = await serve();
  const browser = await chromium.launch();
  await phone(browser, 'iPhone 15', 'iPhone 15');
  await phone(browser, 'iPhone SE', 'iPhone SE');
  await desktop(browser);
  await sandboxed(browser, srv.address().port);
  await browser.close();
  srv.close();
  console.log(failures ? `\n${failures} check(s) failed` : '\nAll checks passed');
  process.exit(failures ? 1 : 0);
})();
