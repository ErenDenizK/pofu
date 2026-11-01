// Checks and screenshots for the gate v2 prototype (Playwright, Chromium).
//
//   node tools/check.js            checks only
//   node tools/check.js --shots    checks, then writes screenshots/ (pngquant them after)
//
// Runs at 390 x 844 with hasTouch and isMobile. Every tap is real touch input sent through the
// Chrome DevTools Protocol at the centre of the element, after asserting that the element is the
// one that would receive the tap (nothing overlaps or swallows it). It walks the whole day-1 flow:
// onboarding with a granted and a denied Screen Time alert, the picker, the live demo, the shield's
// copy ladder, the submenu's quick check, the expiry shield, the open request with the waiting
// shield and the banner, Hop! (the 3-second skip path), the minute, the 15-minute hand-off with the
// Live Activity, the breathing break, notifications off, repair, and the Today sheet. It also runs
// the shield copy engine over every context and checks the length limits of gate-v2.md §5.6, that
// every control is at least 44 x 44 pt, that nothing scrolls sideways, and that every asset loads.
// Exits non-zero on any failure. If Playwright is not found, run with NODE_PATH set to the folder
// that holds it (for example NODE_PATH=/opt/node-tools/node_modules).
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const SHOTS = process.argv.includes('--shots');
let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`); if (!cond) failures++; };

function serve() {
  const types = { '.html': 'text/html; charset=utf-8', '.webp': 'image/webp', '.woff2': 'font/woff2', '.png': 'image/png' };
  const srv = http.createServer((req, res) => {
    const u = decodeURIComponent(req.url.split('?')[0].split('#')[0]);
    const f = path.join(ROOT, path.normalize(u === '/' ? '/index.html' : u).replace(/^(\.\.[/\\])+/, ''));
    if (!f.startsWith(ROOT) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream' });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv)));
}

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function phone(browser, base, scheme = 'light') {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true, colorScheme: scheme,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.4 Mobile/15E148 Safari/604.1' });
  const page = await ctx.newPage();
  const errors = [], failed = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('requestfailed', (r) => failed.push(r.url()));
  page.on('response', (r) => { if (r.status() >= 400) failed.push(r.status() + ' ' + r.url()); });
  page.on('request', (r) => { if (!r.url().startsWith(base)) failed.push('network: ' + r.url()); });
  await page.goto(base + '/index.html');
  await page.waitForLoadState('networkidle');
  const cdp = await ctx.newCDPSession(page);
  const touch = async (x, y) => {
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id: 1, radiusX: 4, radiusY: 4, force: 1 }] });
    await wait(40);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  };
  // Tap the visible element matching `sel` (optionally containing `text`), after checking that it
  // is the element on top at its centre.
  const tap = async (sel, text, label) => {
    const loc = text ? page.locator(sel, { hasText: text }).last() : page.locator(sel).last();
    await loc.waitFor({ state: 'visible', timeout: 4000 });
    const b = await loc.boundingBox();
    const x = b.x + b.width / 2, y = b.y + b.height / 2;
    const hit = await page.evaluate(([x, y, s, t]) => {
      const top = document.elementFromPoint(x, y);
      const cands = [...document.querySelectorAll(s)].filter((e) => !t || e.textContent.includes(t));
      return cands.some((c) => c === top || c.contains(top));
    }, [x, y, sel, text || '']);
    ok(hit, `tap lands on ${label || text || sel}`);
    await touch(x, y);
    await wait(350);
  };
  const st = () => page.evaluate(() => window.__pofu.state());
  const set = (o) => page.evaluate((o) => window.__pofu.set(o), o);
  const goView = (v, a) => page.evaluate(([v, a]) => window.__pofu.go(v, a), [v, a]);
  const shot = async (name) => { if (!SHOTS) return; await page.screenshot({ path: path.join(ROOT, 'screenshots', name + '.png') }); console.log('  shot', name); };
  const text = (sel) => page.locator(sel).first().textContent();
  return { ctx, page, errors, failed, tap, st, set, goView, shot, text };
}

async function layoutChecks(p, where) {
  const r = await p.page.evaluate(() => {
    const small = [];
    for (const e of document.querySelectorAll('button, summary, [role=button]')) {
      const b = e.getBoundingClientRect(); const cs = getComputedStyle(e);
      if (!b.width || !b.height || cs.visibility === 'hidden' || cs.display === 'none') continue;
      if (b.bottom < 0 || b.top > innerHeight) continue;
      if (b.width < 44 - 0.5 || b.height < 44 - 0.5) small.push(`${(e.id || e.className || e.tagName)} "${e.textContent.trim().slice(0, 24)}" ${Math.round(b.width)}x${Math.round(b.height)}`);
    }
    return { small, sx: document.documentElement.scrollWidth, w: innerWidth };
  });
  ok(r.small.length === 0, `${where}: every control ≥ 44 × 44 pt${r.small.length ? ' — ' + r.small.join('; ') : ''}`);
  ok(r.sx <= r.w, `${where}: no horizontal scroll (${r.sx} ≤ ${r.w})`);
}

(async () => {
  const srv = await serve();
  const base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  if (SHOTS) fs.mkdirSync(path.join(ROOT, 'screenshots'), { recursive: true });

  // ---------------------------------------------------------------- the copy engine
  {
    const p = await phone(browser, base);
    const rows = await p.page.evaluate(() => {
      const out = [];
      const base = { picked: ['instagram', 'youtube', 'tiktok'], onboarded: true, notif: true, submenu: true, calm: 1.8, reaches: 6, resisted: 3, day: 1, clockMin: 100, lastQuick: -1e9, request: null, justEnded: null, overLimit: false, tired: false, jealousToday: 0, lastJealous: false, lastTitle: '' };
      const cases = [
        ['morning', { time: 'morning', hourReach: 1 }], ['day', { time: 'day', hourReach: 1 }], ['evening', { time: 'evening', hourReach: 1 }],
        ['second', { time: 'day', hourReach: 2 }], ['jealous', { time: 'day', hourReach: 3 }], ['kind', { time: 'day', hourReach: 4, lastJealous: true }],
        ['bedtime', { time: 'night', hourReach: 1 }], ['breath', { time: 'day', overLimit: true, hourReach: 1 }], ['breath10', { time: 'day', overLimit: true, overLimitOpens: 4, hourReach: 1 }],
        ['tired', { time: 'day', tired: true, hourReach: 1 }], ['expiry', { time: 'day', justEnded: { app: 'instagram', mins: 15 }, hourReach: 1 }],
        ['waiting', { time: 'day', request: { app: 'instagram', at: Date.now() } }], ['waiting-off', { time: 'day', notif: false, request: { app: 'instagram', at: Date.now() } }],
        ['chain', { time: 'day', hourReach: 1, clockMin: 100, lastQuick: 95 }], ['no-submenu', { time: 'day', hourReach: 1, submenu: false }],
      ];
      for (const app of ['instagram', 'youtube', 'tiktok']) for (const [name, o] of cases) {
        window.__pofu.set({ ...base, ...o });
        if (o.request) o.request.app = app; if (o.justEnded) o.justEnded.app = app;
        const m = window.__pofu.shieldModel(app);
        out.push({ name, app, ...m });
      }
      return out;
    });
    const over = [];
    for (const m of rows) {
      const lines = m.sub.split('\n');
      if (m.title.length > 26) over.push(`${m.name}/${m.app} title ${m.title.length}: ${m.title}`);
      if (lines[0].length > 60) over.push(`${m.name}/${m.app} subtitle ${lines[0].length}: ${lines[0]}`);
      if (lines[1] && lines[1].length > 32) over.push(`${m.name}/${m.app} tally ${lines[1].length}`);
      if (m.primary.length > 18 || (m.secondary && m.secondary.length > 18)) over.push(`${m.name} buttons`);
      if (m.menu && m.menu.some((x) => x.length > 22)) over.push(`${m.name} menu`);
      if (/engel|limit|ceza|blocked/i.test(m.title + m.sub)) over.push(`${m.name}: forbidden word`);
      if ((m.title + m.sub).split('!').length > 2) over.push(`${m.name}: more than one "!"`);
    }
    ok(over.length === 0, `copy engine: ${rows.length} shields within length limits and tone rules${over.length ? ' — ' + over.join(' | ') : ''}`);
    const by = Object.fromEntries(rows.filter((r) => r.app === 'instagram').map((r) => [r.name, r]));
    ok(by.day.primary === 'Boş ver' && by.day.secondary === 'Açmam lazım' && by.day.menu && by.day.menu[0] === '3 dakika bakacağım', 'default shield: Boş ver · Açmam lazım → 3 dakika bakacağım / Pofu\'yla aç');
    ok(by.breath.secondary === "Pofu'yla nefes al" && !by.breath.menu, 'past the daily hour: the only way through is a breath');
    ok(/10 saniye/.test(by.breath10.sub) && /5 saniye/.test(by.breath.sub), 'breath: 5 s, 10 s from the 4th over-limit open');
    ok(by.expiry.primary === 'Bitti, kapat' && by.expiry.title === 'Süre doldu.', 'expiry shield: "Süre doldu." with "Bitti, kapat"');
    ok(by.chain.secondary === "Pofu'yla aç" && !by.chain.menu, 'chain rule: no quick check within 20 min of the last');
    ok(by.bedtime.primary === 'İyi geceler' && by.bedtime.palette === 'night', 'bedtime: night palette, "İyi geceler"');
    ok(by['waiting-off'].title === "Pofu'yu kendin aç", 'notifications off: the waiting shield says to open Pofu');
    ok(by.jealous.icon === 'pofu-jealous' && by.kind.icon === 'pofu', 'jealous at most once in a row, then kind');
    ok(/Bugün 3 \/ 5 boş verdin\./.test(by.day.sub), 'the tally line is on the shield');
    await p.ctx.close();
  }

  // ---------------------------------------------------------------- the day-1 flow
  const p = await phone(browser, base);
  await p.shot('01-welcome');
  await layoutChecks(p, 'welcome');
  await p.tap('[data-act="ob2"]', 'Başlayalım');
  await p.shot('02-why-screen-time');
  await p.tap('[data-act="askST"]', 'Ekran Süresi');
  await p.shot('03-screen-time-alert');
  await p.tap('.alert button', 'Devam');
  await wait(1200);
  ok((await p.st()).view === 'ob4', 'Screen Time granted (with Face ID) → picker primer');
  await p.shot('04-picker-primer');
  await layoutChecks(p, 'picker primer');
  await p.tap('[data-act="picker"]', 'Uygulamaları seç');
  await p.tap('[data-act="pkopen:social"]', null, 'Sosyal chevron');
  await p.tap('[data-act="pkapp:instagram"]', 'Instagram');
  await p.tap('[data-act="pkapp:tiktok"]', 'TikTok');
  await p.tap('[data-act="pkopen:ent"]', null, 'Eğlence chevron');
  await p.tap('[data-act="pkapp:youtube"]', 'YouTube');
  await p.shot('05-picker');
  await layoutChecks(p, 'picker');
  await p.tap('[data-act="pkdone"]', 'Bitti');
  let s = await p.st();
  ok(s.picked.length === 3 && !s.category && s.view === 'ob6', 'picked Instagram, YouTube, TikTok as apps → notifications primer');
  await p.shot('06-notifications-primer');
  await p.tap('[data-act="askNotif"]', 'Bildirimlere izin ver');
  await p.tap('.alert button', 'İzin Ver');
  ok((await p.st()).view === 'ob7', 'notifications allowed → try it');
  await p.shot('07-try-it');
  await p.tap('#homebar', null, 'home indicator');
  ok((await p.st()).view === 'springboard', 'home indicator → iPhone Home Screen');
  await p.shot('08-home-screen');
  await layoutChecks(p, 'home screen');
  await p.tap('[data-act="open:instagram"]', null, 'Instagram icon');
  s = await p.st();
  ok(s.view === 'shield' && s.reaches === 1, 'opening Instagram shows the shield and counts one reach');
  ok((await p.text('.shield .p1')) === 'Boş ver' && (await p.text('.shield .p2')) === 'Açmam lazım', 'shield buttons: Boş ver · Açmam lazım');
  await p.shot('09-shield-first');
  await layoutChecks(p, 'shield');
  await p.tap('[data-act="shPrimary"]', 'Boş ver');
  await p.tap('[data-act="openPofu"]', null, 'Pofu icon');
  ok((await p.st()).view === 'ob8', 'back to Pofu after the first skip → "Yakaladım!"');
  await wait(2200);
  await p.shot('10-got-it');
  const t0 = Date.now();
  await p.tap('[data-act="toHome"]', 'Tamam');
  ok((await p.st()).onboarded, 'onboarding complete');
  await p.shot('11-pofu-home');
  await layoutChecks(p, 'Pofu home');

  // second reach: the ladder and the tally
  await p.tap('#homebar', null, 'home indicator');
  await p.tap('[data-act="open:instagram"]', null, 'Instagram icon');
  const t2 = await p.text('#shTitle'), sub2 = await p.text('#shSub');
  ok(['Az önce de geldik.', 'Bir daha mı?'].includes(t2), `second reach this hour: "${t2}"`);
  ok(sub2.includes('Bugün 1 / 1 boş verdin.'), 'second reach: the tally "Bugün 1 / 1 boş verdin."');
  await p.shot('12-shield-second');
  await p.tap('[data-act="shSecondary"]', 'Açmam lazım');
  await p.shot('13-shield-submenu');
  await layoutChecks(p, 'submenu');
  await p.tap('[data-act="quick"]', '3 dakika');
  s = await p.st();
  ok(s.view === 'feed' && s.pass && s.pass.mins === 3 && !s.pass.la, 'quick check from the shield: 3 min, no app, no Live Activity');
  ok(Math.abs(s.calm - 1.3) < 1e-9, 'quick check halves the calm bonus: ×1.6 → ×1.3');
  await p.tap('[data-act="expire"]', 'süreyi bitir');
  s = await p.st();
  ok(s.view === 'shield' && (await p.text('#shTitle')) === 'Süre doldu.' && s.reaches === 2, 'at the end the shield returns: "Süre doldu." (not a new reach)');
  await p.shot('14-shield-expiry');
  await p.tap('[data-act="shPrimary"]', 'Bitti, kapat');
  s = await p.st();
  ok(s.resisted === 1, '"Bitti, kapat" is not counted as a skip');

  // third reach: the open request, the waiting shield, the banner, Hop!
  await p.set({ clockMin: 60 });
  await p.tap('[data-act="open:instagram"]', null, 'Instagram icon');
  ok(/Instagram/.test(await p.text('#shTitle')), `third reach this hour teases the app: "${await p.text('#shTitle')}"`);
  await p.tap('[data-act="shSecondary"]', 'Açmam lazım');
  await p.tap('[data-act="request"]', "Pofu'yla aç");
  ok((await p.text('#shTitle')) === 'Bildirime dokun ↑', 'the shield redraws into the waiting state');
  await wait(900);
  await p.shot('15-shield-waiting-banner');
  const tBanner = Date.now();
  await p.tap('.banner', null, 'notification banner');
  ok((await p.st()).view === 'hop', 'the banner opens Hop!');
  await p.shot('16-hop-care');
  await layoutChecks(p, 'Hop!');
  await p.tap('#skipBtn', 'Boş ver');
  const skipMs = Date.now() - tBanner;
  s = await p.st();
  ok(s.view === 'skipped' && s.resisted === 2, 'Hop! skip counted');
  ok(skipMs < 3000, `skip path from the banner tap: ${skipMs} ms < 3 s (including the harness's waits)`);
  await wait(500);
  await p.shot('17-hop-skipped');
  await layoutChecks(p, 'skipped');
  await p.tap('[data-act="minute"]', 'bir dakika');
  for (let i = 0; i < 3; i++) await p.tap('#brush', null, 'Pofu (brush)');
  await wait(1900);
  ok((await p.text('#mline')).startsWith('Bu kadar.'), 'the minute ends with "Bu kadar. Telefonu bırakalım mı?"');
  await p.shot('18-minute-end');

  // the 15-minute open with the Live Activity
  await p.tap('#homebar', null, 'home indicator');
  await p.set({ hourReach: 0, clockMin: 100 });
  await p.tap('[data-act="open:youtube"]', null, 'YouTube icon');
  await p.tap('[data-act="shSecondary"]', 'Açmam lazım');
  await p.tap('[data-act="request"]', "Pofu'yla aç");
  await wait(800);
  await p.tap('.banner', null, 'notification banner');
  await p.tap('[data-act="pass:15"]', '15 dakika');
  await p.shot('19-handoff');
  await wait(1500);
  s = await p.st();
  ok(s.view === 'feed' && s.pass && s.pass.la && s.calm === 1, '15 min open: Live Activity on, calm resets to ×1.0');
  ok(await p.page.evaluate(() => document.getElementById('island').classList.contains('live')), 'the Dynamic Island shows the pass');
  await p.shot('20-feed-live-activity');
  await p.goView('lock');
  await wait(300);
  ok(await p.page.locator('.la').count() === 1, 'Lock Screen: the Live Activity and the glance widgets');
  await p.shot('21-lock-screen');
  await layoutChecks(p, 'lock screen');
  await p.tap('[data-act="endNow"]', 'Şimdi bitir');
  ok(!(await p.st()).pass, '"Şimdi bitir" ends the pass');

  // past the daily hour: the breathing break
  await p.set({ overLimit: true, hourReach: 0 });
  await p.goView('springboard');
  await p.tap('[data-act="open:tiktok"]', null, 'TikTok icon');
  ok((await p.text('.shield .p2')) === "Pofu'yla nefes al", 'past the hour the shield offers only the breath');
  await p.shot('22-shield-breath');
  await p.tap('[data-act="shSecondary"]', 'nefes');
  await wait(800);
  await p.tap('.banner', null, 'notification banner');
  ok((await p.st()).view === 'breath', 'the banner opens the breathing room');
  await p.shot('23-breath-waiting');
  await layoutChecks(p, 'breath');
  await p.tap('[data-act^="breathe"]', "Pofu'yla nefes al");
  await wait(1000);
  await p.shot('24-breath-in');
  await wait(4600);
  ok((await p.text('#bTitle')) === 'Çok güzel.', 'a 5 s breath, then "Çok güzel."');
  await p.shot('25-breath-done');
  await p.tap('[data-act="breathSkip"]', 'İyiyim');
  ok((await p.st()).view === 'skipped', '"İyiyim, boş ver" is a skip');

  // notifications off
  await p.set({ overLimit: false, notif: false, hourReach: 0 });
  await p.goView('springboard');
  await p.tap('[data-act="open:instagram"]', null, 'Instagram icon');
  await p.tap('[data-act="shSecondary"]', 'Açmam lazım');
  await p.tap('[data-act="request"]', "Pofu'yla aç");
  await wait(800);
  ok((await p.text('#shTitle')) === "Pofu'yu kendin aç" && (await p.page.locator('.banner').count()) === 0, 'notifications off: no banner, the shield says to open Pofu');
  await p.shot('26-shield-notifications-off');
  await p.tap('#homebar', null, 'home indicator');
  await p.tap('[data-act="openPofu"]', null, 'Pofu icon');
  ok((await p.st()).view === 'hop', 'opening Pofu by hand within 10 minutes starts Hop!');

  // repair and Today
  await p.set({ revoked: true, notif: true });
  await p.goView('home');
  ok(/Kapıda değilim/.test(await p.text('.nbanner')), 'revoked: a native banner on Home');
  await p.shot('27-home-revoked');
  await p.tap('[data-act="repair"]', 'Düzelt');
  await wait(400);
  await p.shot('28-repair');
  await layoutChecks(p, 'repair');
  await p.set({ revoked: false, day: 3 });
  await p.goView('home');
  await p.tap('[data-act="openToday"]', null, 'Today card');
  await wait(400);
  ok(/boş verdin/.test(await p.text('.sheet')), 'Today sheet: skips, guarded time, calm, Pofu\'s minutes');
  await p.shot('29-today');
  await layoutChecks(p, 'Today sheet');

  // the night shield
  await p.goView('springboard');
  await p.set({ time: 'night', hourReach: 0 });
  await p.tap('[data-act="open:instagram"]', null, 'Instagram icon');
  ok((await p.text('.shield .p1')) === 'İyi geceler', 'bedtime shield: "İyi geceler"');
  await p.shot('30-shield-night');
  ok(p.errors.length === 0, `no page errors${p.errors.length ? ': ' + p.errors.join(' | ') : ''}`);
  ok(p.failed.length === 0, `every asset loads, no network${p.failed.length ? ': ' + p.failed.join(' | ') : ''}`);
  await p.ctx.close();

  // ---------------------------------------------------------------- denial, and dark mode
  {
    const d = await phone(browser, base, 'dark');
    await d.tap('[data-act="ob2"]', 'Başlayalım');
    await d.tap('[data-act="askST"]', 'Ekran Süresi');
    await d.tap('.alert button', 'İzin Verme');
    ok((await d.st()).view === 'ob3b' && /zorlamam/.test(await d.text('h1')), 'denied → "Tamam, zorlamam."');
    await d.tap('[data-act="askST"]', 'Tekrar dene');
    await d.tap('.alert button', 'İzin Verme');
    ok(/Ayarlar → Ekran Süresi/.test(await d.text('.list')), 'denied twice → the Settings path, as steps');
    await d.shot('31-denied-dark');
    await layoutChecks(d, 'denied');
    await d.page.evaluate(() => { window.__pofu.ACT.skipOb(); });
    await d.tap('[data-act="open:instagram"]', null, 'Instagram icon');
    const bg = await d.page.evaluate(() => getComputedStyle(document.querySelector('.shield')).backgroundColor);
    ok(bg === 'rgb(21, 17, 28)', `dark mode shield uses night-950 (${bg})`);
    await d.shot('32-shield-dark');
    ok(d.errors.length === 0, 'dark run: no page errors');
    await d.ctx.close();
  }

  await browser.close();
  srv.close();
  console.log(failures ? `\n${failures} check(s) failed` : '\nAll checks passed');
  process.exit(failures ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
