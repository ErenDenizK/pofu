// Checks and screenshots for the interaction prototype (Playwright, Chromium).
//
//   node tools/check.js            checks only
//   node tools/check.js --shots    checks, then writes screenshots/ (pngquant them after)
//
// Runs at 390 x 844 with hasTouch and isMobile. Gestures are real touch input sent through the
// Chrome DevTools Protocol (Input.dispatchTouchEvent), including two-finger pinches, long presses,
// and drags, so the page sees the same pointer events Safari would send. It checks that every tap
// lands where it should (nothing overlaps or swallows input), that no long task blocks input for
// more than 150 ms, that every control is at least 44 x 44 pt, and that every asset loads.
// Exits non-zero on any failure.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const SHOTS = process.argv.includes('--shots');
let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`); if (!cond) failures++; };

function serve() {
  const types = { '.html': 'text/html; charset=utf-8', '.webp': 'image/webp', '.woff2': 'font/woff2', '.png': 'image/png', '.js': 'text/javascript', '.json': 'application/json' };
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

// ------------------------------------------------------------------ touch through CDP
function touch(cdp) {
  const send = (type, pts) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map(([x, y], i) => ({ x, y, id: i + 1, radiusX: 4, radiusY: 4, force: 1 })) });
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  return {
    async tap(x, y) { await send('touchStart', [[x, y]]); await wait(40); await send('touchEnd', []); },
    async doubleTap(x, y) { await this.tap(x, y); await wait(120); await this.tap(x, y); },
    async press(x, y, ms) { await send('touchStart', [[x, y]]); await wait(ms); return { move: (x2, y2) => send('touchMove', [[x2, y2]]), end: () => send('touchEnd', []) }; },
    async drag(x0, y0, x1, y1, ms = 300, steps = 12) {
      await send('touchStart', [[x0, y0]]);
      for (let i = 1; i <= steps; i++) { await wait(ms / steps); await send('touchMove', [[x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps]]); }
      await send('touchEnd', []);
    },
    // Two fingers centred on (cx, cy), from distance d0 to d1, horizontally.
    async pinch(cx, cy, d0, d1, ms = 360, steps = 14, hold = false) {
      const pts = (d) => [[cx - d / 2, cy], [cx + d / 2, cy]];
      await send('touchStart', pts(d0));
      for (let i = 1; i <= steps; i++) { await wait(ms / steps); await send('touchMove', pts(d0 + (d1 - d0) * i / steps)); }
      if (hold) return { end: () => send('touchEnd', []) };
      await send('touchEnd', []);
    },
    async twoFingerTap(cx, cy) { await send('touchStart', [[cx - 30, cy], [cx + 30, cy]]); await wait(60); await send('touchEnd', []); },
  };
}

const settle = (p, ms) => p.waitForTimeout(ms);
const st = (p) => p.evaluate(() => window.__pofu.state());
const pos = (p, id) => p.evaluate((i) => window.__pofu.screenOf(i), id);
async function shot(page, name) { if (!SHOTS) return; await page.screenshot({ path: path.join(ROOT, 'screenshots', name + '.png') }); console.log('  shot', name); }
// What element would actually receive a tap at (x, y)?
const topAt = (p, x, y) => p.evaluate(([x, y]) => { const e = document.elementFromPoint(x, y); return e ? (e.id || e.className || e.tagName).toString() + '|' + (e.closest('#world') ? 'world' : e.closest('#chrome') ? 'chrome' : e.closest('#sheet') ? 'sheet' : 'other') : 'none'; }, [x, y]);

async function phone(browser, base) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, hasTouch: true, isMobile: true, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1' });
  const page = await ctx.newPage();
  const errors = [], failed = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('requestfailed', (r) => failed.push(r.url()));
  page.on('response', (r) => { if (r.status() >= 400) failed.push(r.status() + ' ' + r.url()); });
  page.on('dialog', (d) => { errors.push('dialog: ' + d.message()); d.dismiss(); });
  await page.addInitScript(() => {
    window.__long = [];
    try { new PerformanceObserver((l) => { for (const e of l.getEntries()) window.__long.push(e.duration); }).observe({ type: 'longtask', buffered: true }); } catch (e) { /* unsupported */ }
  });
  await page.goto(base + '/index.html');
  await page.waitForFunction(() => window.__pofu && [...document.images].every((i) => i.complete));
  await settle(page, 900);
  const cdp = await ctx.newCDPSession(page);
  const T = touch(cdp);

  // ---- layout
  const m = await page.evaluate(() => ({ sw: document.documentElement.scrollWidth, sh: document.documentElement.scrollHeight, w: innerWidth, h: innerHeight }));
  ok(m.sw <= m.w && m.sh <= m.h, `no page scroll (${m.sw}×${m.sh} in ${m.w}×${m.h})`);
  const small = await page.evaluate(() => [...document.querySelectorAll('button')].filter((b) => { const r = b.getBoundingClientRect(); const cs = getComputedStyle(b); return r.width && r.height && cs.visibility !== 'hidden' && b.offsetParent && !b.closest('.morph:not(.open)') && (r.width < 43.5 || r.height < 43.5); }).map((b) => b.textContent.trim().slice(0, 20) + ' ' + Math.round(b.getBoundingClientRect().width) + '×' + Math.round(b.getBoundingClientRect().height)));
  ok(small.length === 0, `visible buttons are at least 44 × 44 pt${small.length ? ': ' + small.join('; ') : ''}`);
  // Chrome buttons are on top where they are drawn; the world receives taps on Pofu and stations.
  for (const id of ['seedBtn', 'moreBtn', 'tabBtn']) {
    const r = await page.locator('#' + id).boundingBox(); const t = await topAt(page, r.x + r.width / 2, r.y + r.height / 2);
    ok(t.includes(id) || t.includes('chrome'), `#${id} receives its own taps (${t})`);
  }
  for (const b of ['Pofu', 'Ada', 'Harita']) { const r = await page.locator('#seg button', { hasText: b }).boundingBox(); const t = await topAt(page, r.x + r.width / 2, r.y + r.height / 2); ok(t.includes('chrome'), `segment "${b}" receives its taps`); }
  let p = await pos(page, 'pofu');
  ok((await topAt(page, p.x, p.y)).endsWith('world'), 'a tap on Pofu reaches the world, not the chrome');
  let s = await st(page);
  ok(s.view === 'home' && Math.abs(s.z - 2) < 0.02, `starts at Home (z ${s.z.toFixed(2)})`);
  ok(s.blur.garden > 0.9 && s.blur.pofu === 0, `Home depth of field: stations soft (${s.blur.garden}), Pofu sharp`);
  await shot(page, '01-home');

  // ---- Pofu: poke, escalation, pet
  await T.tap(p.x, p.y); await settle(page, 80);
  s = await st(page); ok(s.run === 1 && s.faceKind === 'excited', `poke: Pofu reacts at once (run ${s.run}, face ${s.faceKind})`);
  await T.tap(p.x, p.y); await settle(page, 120); await T.tap(p.x, p.y); await settle(page, 200);
  const bubble = await page.evaluate(() => { const b = document.querySelector('.bubble'); return { t: b.textContent, o: +getComputedStyle(b).opacity }; });
  ok(s.run >= 1 && bubble.t.includes('Dıt') && bubble.o > 0.5, `third poke in a run says the line once ("${bubble.t}")`);
  await shot(page, '02-poke-line');
  for (let i = 0; i < 6; i++) { await T.tap(p.x, p.y); await settle(page, 90); }
  s = await st(page); ok(s.run >= 8, `rapid pokes keep counting a run (${s.run}) without blocking input`);
  const hudCount = await page.evaluate(() => document.querySelectorAll('#hud div').length);
  ok(hudCount <= 4, `haptic HUD stays rationed (${hudCount} visible)`);
  await settle(page, 2700);
  const lp = await T.press(p.x, p.y, 520);
  s = await st(page); ok(s.petting, 'long press (350 ms) starts petting');
  for (let i = 0; i < 9; i++) { await lp.move(p.x + (i % 2 ? 40 : -40), p.y); await settle(page, 70); }
  await shot(page, '03-pet');
  await lp.end(); await settle(page, 300);
  s = await st(page); ok(!s.petting && s.dozing, `strokes lean him into the hand; eight strokes and he dozes (dozing ${s.dozing})`);
  await T.tap(p.x, p.y); await settle(page, 300);
  s = await st(page); ok(!s.dozing, 'a poke wakes him');

  // ---- camera: pinch with snapping (C)
  await settle(page, 2600);
  await T.pinch(195, 450, 260, 150, 320); await settle(page, 1300);
  s = await st(page); ok(s.view === 'island' && Math.abs(s.z - 1) < 0.03, `pinch in from Home snaps to the island (z ${s.z.toFixed(2)})`);
  await shot(page, '04-island');

  // ---- residents and lawn (at the island framing, where they are in focus)
  const bun = await pos(page, 'bunny');
  await T.tap(bun.x, bun.y); await settle(page, 200);
  const chipT = await page.evaluate(() => [...document.querySelectorAll('.chipw')].map((c) => c.textContent).join(' '));
  ok(chipT.includes('Mochi'), `Mochi answers a tap once ("${chipT}")`);
  const [lx, ly] = await page.evaluate(() => window.__pofu.toScreen(-110, 25));
  const lawn = await page.evaluate(([x, y]) => window.__pofu.hit(x, y), [lx, ly]);
  ok(lawn.type === 'empty', `open lawn is empty space, not a station (${lawn.type})`);
  await T.tap(lx, ly); await settle(page, 60);
  const rip = await page.evaluate(() => document.querySelectorAll('.ripple').length);
  ok(rip === 1, `a tap on the lawn ripples where it landed (${rip})`);
  await settle(page, 700);

  const held = await T.pinch(195, 450, 280, 160, 300, 12, true); await settle(page, 120);
  s = await st(page); ok(s.z < 0.9 && s.z > 0, `the camera follows the fingers mid-pinch (z ${s.z.toFixed(2)})`);
  await shot(page, '05-pinch-mid');
  await held.end(); await settle(page, 1500);
  s = await st(page); ok(s.view === 'map' && Math.abs(s.z) < 0.03, `released past the midpoint, it settles on the map (z ${s.z.toFixed(2)})`);
  const pinOp = await page.evaluate(() => +getComputedStyle(document.querySelector('.pin')).opacity);
  ok(pinOp > 0.95, 'Pofu is the 30 pt vector pin on the map');
  await shot(page, '06-map');
  await T.pinch(195, 450, 200, 150, 260); await settle(page, 1200);
  s = await st(page); ok(Math.abs(s.z) < 0.03, `rubber band past the map springs back (z ${s.z.toFixed(2)})`);
  await T.doubleTap(60, 640); await settle(page, 1500);
  s = await st(page); ok(s.view === 'island', `double tap on empty space zooms in one framing (${s.view})`);
  await T.doubleTap(30, 300); await settle(page, 1500);
  s = await st(page); ok(s.view === 'home', `double tap again goes to Home (${s.view})`);
  await T.twoFingerTap(195, 400); await settle(page, 1400);
  s = await st(page); ok(s.view === 'island', `two-finger tap steps out one framing (${s.view})`);

  // ---- Home: the blurred world is one target
  await page.locator('#seg button', { hasText: 'Pofu' }).tap(); await settle(page, 1300);
  const hh = await page.evaluate(() => window.__pofu.hit(330, 260));
  ok(hh.type === 'island', `at Home a tap on the soft world means "the island" (${hh.type})`);
  // ---- interruption: a tap during a camera flight retargets it
  await page.locator('#seg button', { hasText: 'Ada' }).tap(); await settle(page, 380);
  const cay0 = await pos(page, 'cay');
  await T.tap(cay0.x, cay0.y); await settle(page, 80);
  s = await st(page); ok(s.focus === 'cay', `a tap mid-flight is honoured: the station opens (${s.focus})`);
  await settle(page, 1200);

  // ---- station focus, depth of field, detents, build
  s = await st(page);
  ok(s.focus === 'cay' && s.sheet.open && Math.abs(s.sheet.y - (844 - Math.round(844 * 0.42))) < 3, `station sheet at the medium detent (y ${Math.round(s.sheet.y)})`);
  ok(s.blur.cay < 0.05 && s.blur.bunny < 0.05 && s.blur.garden > 0.9 && s.blur.home > 0.9, `focus: çay ocağı and Mochi sharp, the rest soft (cay ${s.blur.cay}, garden ${s.blur.garden})`);
  const c1 = await pos(page, 'cay');
  ok(c1.y > 120 && c1.y < s.sheet.y - 20, `the focused station stays visible above the sheet (y ${Math.round(c1.y)})`);
  await shot(page, '07-station');
  await T.drag(195, s.sheet.y + 14, 195, 120, 260); await settle(page, 900);
  s = await st(page); ok(s.sheet.detent === 'large', `drag up: large detent (${s.sheet.detent})`);
  await shot(page, '08-station-large');
  await T.drag(195, s.sheet.y + 14, 195, s.sheet.y + 300, 260); await settle(page, 900);
  s = await st(page); ok(s.sheet.detent === 'medium', `drag down: back to medium (${s.sheet.detent})`);
  const seeds0 = s.seeds;
  const bb = await page.locator('#buildBtn').boundingBox();
  ok(!!bb && (await topAt(page, bb.x + bb.width / 2, bb.y + bb.height / 2)).includes('sheet'), 'the build button receives its tap');
  await page.locator('#buildBtn').tap(); await settle(page, 450);
  await shot(page, '09-build-mid');
  s = await st(page); ok(s.seeds === seeds0 - 194 && s.building === 'cay' && s.sheet.detent === 'compact', `build: seeds spent (${seeds0} → ${s.seeds}), sheet compact`);
  await settle(page, 1700);
  s = await st(page); ok(!s.building && s.sheet.detent === 'medium', 'after the moment the sheet returns to medium with the next level');
  const lv = await page.evaluate(() => document.querySelector('#stBody .dots span').textContent);
  ok(lv.includes('3'), `level is now 3 ("${lv}")`);
  await shot(page, '10-built');
  // Retarget behind the sheet.
  const gp = await pos(page, 'workshop');
  ok(gp.y > 130 && gp.y < s.sheet.y && (await topAt(page, gp.x, gp.y)).endsWith('world'), `the workshop behind a medium sheet can be tapped (y ${Math.round(gp.y)})`);
  await T.tap(gp.x, gp.y); await settle(page, 1000);
  s = await st(page); ok(s.focus === 'workshop' && s.sheet.open, `tapping another station retargets the focus without closing (${s.focus})`);
  ok(s.blur.hog < 0.05 && s.blur.cay > 0.9, `Fındık is sharp with his workshop; the çay ocağı softens (${s.blur.cay})`);
  await shot(page, '10b-retarget');
  await T.tap(40, 200); await settle(page, 1200);
  s = await st(page); ok(!s.sheet.open && s.view === 'island', `tap on empty world dismisses and returns to where you were (${s.view})`);
  await page.locator('#seg button', { hasText: 'Ada' }).tap(); await settle(page, 1200);
  const gp2 = await pos(page, 'garden'); await T.tap(gp2.x, gp2.y); await settle(page, 1200);
  s = await st(page); ok(s.focus === 'garden' && s.blur.pofu < 0.05, 'Pofu stays sharp when his garden is in focus');
  await page.locator('#sheetClose').tap(); await settle(page, 1000);

  // ---- glass morph menu
  await page.locator('#seedBtn').tap(); await settle(page, 450);
  s = await st(page); ok(s.morph === 'seedMorph', 'seed pill morphs into its panel');
  await shot(page, '11-morph');
  await page.mouse.click(195, 700); await settle(page, 400);
  s = await st(page); ok(!s.morph && !s.sheet.open, 'a tap outside closes the panel and does nothing else');
  await page.locator('#moreBtn').tap(); await settle(page, 450);
  await page.locator('#moreMorph button[data-act="hits"]').tap(); await settle(page, 500);
  await shot(page, '12-hit-areas');
  const hitSizes = await page.evaluate(() => [...document.querySelectorAll('.hit')].filter((h) => h.style.display !== 'none').map((h) => [h.offsetWidth, h.offsetHeight]));
  ok(hitSizes.length > 0 && hitSizes.every(([w, h]) => w >= 43.5 && h >= 43.5), `every hit area is at least 44 pt (${hitSizes.length} areas)`);
  await page.evaluate(() => window.__pofu.set('hits', false)); await page.evaluate(() => { document.getElementById('hits').style.display = 'none'; });

  // ---- compare panel: free model, tap-only, live blur, reduce motion, cloud pass
  await page.locator('#tabBtn').tap(); await settle(page, 600);
  await shot(page, '13-panel');
  await page.locator('#panelBody button[data-k="model"][data-v="B"]').tap();
  await page.locator('#panelClose').tap(); await settle(page, 600);
  await T.pinch(195, 450, 100, 300, 300); await settle(page, 900);
  s = await st(page); ok(s.s > 2.5, `free model: pinch zooms past Home without snapping (scale ${s.s.toFixed(2)})`);
  await T.drag(120, 450, 300, 450, 250); await settle(page, 900);
  await shot(page, '14-free');
  await page.evaluate(() => window.__pofu.set('model', 'A'));
  await page.locator('#seg button', { hasText: 'Ada' }).tap(); await settle(page, 1300);
  await T.pinch(195, 450, 140, 300, 300); await settle(page, 1400);
  s = await st(page); ok(s.view === 'home', `tap-only model: a pinch past the threshold fires the same move (${s.view})`);
  await page.evaluate(() => window.__pofu.set('model', 'C'));
  await page.evaluate(() => window.__pofu.set('blur', 'live'));
  await page.locator('#seg button', { hasText: 'Ada' }).tap(); await settle(page, 1300);
  await shot(page, '15-live-blur-island');
  await page.evaluate(() => window.__pofu.set('blur', 'pre'));
  await page.evaluate(() => window.__pofu.set('rm', true));
  await page.locator('#seg button', { hasText: 'Harita' }).tap(); await settle(page, 400);
  s = await st(page); ok(s.view === 'map' && Math.abs(s.z) < 0.02, `Reduce Motion: a 200 ms cut instead of travel (z ${s.z.toFixed(2)} after 400 ms)`);
  await page.evaluate(() => window.__pofu.set('rm', false));
  await page.locator('#tabBtn').tap(); await settle(page, 600);
  await page.locator('#panelBody button[data-c="1"]').tap(); await settle(page, 700);
  await shot(page, '16-cloud-pass');
  await T.tap(195, 400); await settle(page, 300);
  s = await st(page); ok(s.view === 'map', 'a tap skips the cloud pass and lands on the map');
  await page.locator('#tabBtn').tap(); await settle(page, 600);
  await page.locator('#panelBody button[data-r="proud"]').tap(); await settle(page, 1400);
  await shot(page, '17-return-proud');

  // ---- input never blocked
  const longs = await page.evaluate(() => window.__long);
  ok(longs.every((d) => d <= 150), `no long task over 150 ms (${longs.length ? Math.round(Math.max(...longs)) + ' ms max' : 'none'})`);
  ok(errors.length === 0, `no errors or dialogs${errors.length ? ': ' + errors.slice(0, 3).join(' | ') : ''}`);
  ok(failed.length === 0, `every request succeeded${failed.length ? ': ' + failed.slice(0, 3).join(', ') : ''}`);
  // Idle: nothing animates in JS when nobody touches it (CSS breathing only).
  await page.locator('#panelClose').tap().catch(() => {}); await settle(page, 4000);
  s = await st(page); ok(s.idle, 'the JS frame loop stops when the world is at rest');
  await ctx.close();
}

async function dark(browser, base) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true, colorScheme: 'dark' });
  const page = await ctx.newPage(); await page.goto(base + '/index.html'); await page.waitForFunction(() => window.__pofu); await settle(page, 900);
  const cdp = await ctx.newCDPSession(page); const T = touch(cdp);
  await page.locator('#seg button', { hasText: 'Ada' }).tap(); await settle(page, 1300);
  const c = await pos(page, 'garden'); await T.tap(c.x, c.y); await settle(page, 1200);
  await shot(page, '18-dark-station');
  await ctx.close();
}

async function desktop(browser, base) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await ctx.newPage(); const errors = []; page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(base + '/index.html'); await page.waitForFunction(() => window.__pofu); await settle(page, 600);
  const r = await page.locator('#app').boundingBox();
  ok(Math.round(r.width) === 402, `desktop: the phone frame is 402 pt wide (${Math.round(r.width)})`);
  await page.mouse.move(r.x + 201, r.y + 450);
  for (let i = 0; i < 6; i++) { await page.mouse.wheel(0, 60); await settle(page, 30); }
  await settle(page, 1400);
  const s = await st(page); ok(s.view !== 'home', `desktop: trackpad or wheel zoom uses the same rail (${s.view})`);
  ok(errors.length === 0, 'desktop: no errors');
  await shot(page, '19-desktop');
  await ctx.close();
}

async function sandbox(browser, base) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  const page = await ctx.newPage(); const errors = []; page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(base + '/wrap.html'); await settle(page, 1500);
  const f = page.frames().find((x) => x.url().endsWith('/index.html'));
  const okLoad = f && await f.evaluate(() => !!window.__pofu && [...document.images].every((i) => i.complete && i.naturalWidth > 0));
  ok(!!okLoad && errors.length === 0, 'inside <iframe sandbox="allow-scripts">: scripts run and every image loads');
  await ctx.close();
}

(async () => {
  const srv = await serve(); const base = `http://127.0.0.1:${srv.address().port}`;
  if (SHOTS) fs.mkdirSync(path.join(ROOT, 'screenshots'), { recursive: true });
  const browser = await chromium.launch();
  try { await phone(browser, base); await dark(browser, base); await desktop(browser, base); await sandbox(browser, base); }
  catch (e) { console.error(e); failures++; }
  await browser.close(); srv.close();
  const size = fs.readdirSync(path.join(ROOT, 'assets')).reduce((a, f) => a + fs.statSync(path.join(ROOT, 'assets', f)).size, 0);
  ok(size < 3e6, `assets under 3 MB (${(size / 1e6).toFixed(2)} MB)`);
  console.log(failures ? `\n${failures} failure(s)` : '\nall checks passed');
  process.exit(failures ? 1 : 0);
})();
