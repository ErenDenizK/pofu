// Checks and screenshots for Pofu Hub (Playwright, Chromium).
//
//   node design/hub/tools/check.js            checks only
//   node design/hub/tools/check.js --shots    checks, then writes design/hub/screenshots/
//
// The page is published as an artifact, so the platform wraps it in a document skeleton; the
// local server does the same. A mock `window.claude` supplies an in-memory db that follows
// db.d.ts (doc/collection refs, get/set/update/delete/add, onSnapshot with frozen snapshots and
// metadata) and a `user` namespace. Runs at 390 x 844 with touch and at 1280 x 800, light and
// dark. Exercises choosing and changing an option, adding a note (and a live lead follow-up that
// must not wipe a draft), adding an idea from the Fikir sheet, review verdicts and a review note,
// section switching and filters, the empty states, a read-only viewer, and a plain browser with no
// `window.claude`. Also checks 44 pt hit targets, no sideways scroll, and no console errors.
// Exits non-zero on any failure. If Playwright is not found, set NODE_PATH to the folder that
// holds it (for example NODE_PATH=/opt/node22/lib/node_modules).
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const SHOT_DIR = path.join(ROOT, 'screenshots');
const SHOTS = process.argv.includes('--shots');
let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`); if (!cond) failures++; };
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

// The artifact publisher's skeleton around the page fragment.
const SKELETON_HEAD = '<!doctype html><html><head><meta charset=utf8><meta name=viewport content="width=device-width,initial-scale=1,viewport-fit=cover"><style>body{margin:0}</style></head><body>';
const SKELETON_TAIL = '</body></html>';

function serve() {
  const page = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const srv = http.createServer((req, res) => {
    const u = req.url.split('?')[0];
    if (u === '/' || u === '/index.html') {
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      res.end(SKELETON_HEAD + page + SKELETON_TAIL);
      return;
    }
    const sm = u.match(/^\/sample\/(s\d+)\.svg$/);
    if (sm && SAMPLES[sm[1]]) { res.writeHead(200, { 'content-type': 'image/svg+xml' }); res.end(SAMPLES[sm[1]]); return; }
    const m = u.match(/^\/_blob\/([0-9a-f]{32})$/);
    if (m) { res.writeHead(200, { 'content-type': 'image/svg+xml' }); res.end(sampleSvg('#6C4FD8', 'asset')); return; }
    res.writeHead(404); res.end();
  });
  return new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv)));
}

function sampleSvg(color, label, w = 800, h = 500) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">`
    + `<rect width="${w}" height="${h}" fill="#FBEBDD"/><circle cx="${w / 2}" cy="${h / 2 + 30}" r="${h / 3}" fill="${color}" opacity=".85"/>`
    + `<ellipse cx="${w / 2}" cy="${h - 40}" rx="${w / 2.6}" ry="26" fill="#4F8A5B" opacity=".6"/>`
    + `<text x="24" y="44" font-family="sans-serif" font-size="28" font-weight="700" fill="#2A1F2D">${label}</text></svg>`;
}
// Sample images are served by the local server, as https images or /_blob/ assets would be.
const SAMPLES = {};
const dataSvg = (color, label, w, h) => { const k = 's' + Object.keys(SAMPLES).length; SAMPLES[k] = sampleSvg(color, label, w, h); return '/sample/' + k + '.svg'; };

function sampleSeed() {
  const now = Date.now();
  const iso = (minAgo) => new Date(now - minAgo * 60e3).toISOString();
  return {
    'questions/q-shield-tone': {
      title: 'Kalkan Pofu\'nun sesiyle mi konuşsun, nötr mü?',
      context: 'Kalkan, uygulamayı açmak istediğin anda çıkan ekran. Pofu\'nun ağzından konuşursa sıcak olur ama bazı anlarda suçlayıcı gelebilir. Nötr metin daha az duygusal ama daha az akılda kalıcı.',
      imageUrl: dataSvg('#B9A2FF', 'Kalkan taslakları'),
      options: [
        { key: 'a', label: 'Pofu konuşsun', pros: 'Sıcak, karakterle bağ kurar', cons: 'Yorgun anlarda iğneleyici gelebilir', cost: 'Metin kütüphanesi: 2 gün' },
        { key: 'b', label: 'Nötr metin', pros: 'Güvenli, sakin', cons: 'Akılda kalmaz, karakter silikleşir', cost: 'Yarım gün' },
        { key: 'c', label: 'Karışık: ilk açılış Pofu, sonrası nötr', pros: 'İkisinin iyi yanı', cons: 'Kural karmaşıklaşır', cost: '2,5 gün, test zor' },
      ],
      recommendation: { key: 'a', reason: 'Gate v2 testlerinde Pofu\'nun sesi açılmayı en çok azaltan şeydi; metinleri suçlamayan bir tona çekeriz.' },
      status: 'open', priority: 1, createdAt: iso(50),
    },
    'questions/q-seed-cap': {
      title: 'Günlük tohum sınırı olsun mu?',
      context: 'Sınırsız tohum, ilk haftada adanın çok hızlı dolmasına yol açıyor.',
      options: [
        { key: 'yes', label: 'Evet, günde 24', pros: 'Tempo dengeli', cons: 'Bazı günler cezalandırıcı hisseder', cost: 'Ekonomi dokümanı güncellenir' },
        { key: 'no', label: 'Hayır', pros: 'Basit', cons: 'İkinci hafta boşluk', cost: 'Yok' },
      ],
      recommendation: { key: 'yes', reason: 'Ada iki haftada dolmamalı.' },
      status: 'open', priority: 2, createdAt: iso(300),
    },
    'questions/q-old': {
      title: 'Uygulama adı: Pofu mu?',
      context: 'Karar verildi.',
      options: [{ key: 'pofu', label: 'Pofu', pros: 'Kısa', cons: '', cost: '' }, { key: 'rot', label: 'Rot', pros: '', cons: 'Olumsuz', cost: '' }],
      recommendation: { key: 'pofu', reason: 'Sıcak ve kısa.' },
      status: 'closed', priority: 5, createdAt: iso(60 * 24 * 9),
    },
    'answers/q-old': { choice: 'pofu', updatedAt: iso(60 * 24 * 8), authorId: 'u_founder' },
    'notes/n1': { targetType: 'question', targetId: 'q-shield-tone', text: 'Bence sıcak olsun ama asla suçlamasın.', createdAt: iso(40), authorId: 'u_founder' },
    'notes/n2': { targetType: 'question', targetId: 'q-shield-tone', text: 'Anlaştık. Üç örnek metin hazırlayıp Onay\'a koyacağım.', createdAt: iso(20), authorId: 'u_founder', fromLead: true },
    'status/now': {
      updatedAt: iso(12),
      doing: [
        { title: 'Prova modu', line: 'Kalkanın uygulama içi kopyası, aynı kod yolu', link: 'https://github.com/ErenDenizK/pofu/pulls' },
        { title: 'Ada sahnesi, tur 2', line: 'Gökyüzü saati ve bulut denizi', imageUrl: dataSvg('#ECA96E', 'Ada, tur 2', 900, 450) },
      ],
      doneToday: [{ title: 'Gate v2 birleşti', line: 'Konuşan kalkan ve dürüst sayım' }],
      next: [{ title: 'Üyelik günü 1', line: 'PofuLive iPhone\'a yüklenir' }, { title: '7 günlük deneme', line: 'Sen kullanırsın, biz ölçeriz' }],
    },
    'roadmap/main': {
      items: [
        { title: 'Yumuşak kapı v1', status: 'done', when: 'Ekim', line: 'Hop! akışı, Pofu\'nun odası' },
        { title: 'Gate v2', status: 'done', when: '1 Kas', line: 'Konuşan kalkan, onboarding demosu' },
        { title: 'Prova modu', status: 'doing', when: 'bu hafta', line: 'Üyelikten önce döngüyü hisset' },
        { title: 'Üyelik günü 1', status: 'next', when: '24 Kas sonrası', line: 'Screen Time cihazda' },
        { title: 'Arkadaş betası', status: 'next', when: 'Aralık (tahmini)', line: 'TestFlight, 10 kişi' },
      ],
    },
    'reviews/r-hamster': { title: 'Pofu ifade seti, tur 3', context: 'Altı ifade: mutlu, uykulu, meraklı, şaşkın, gururlu, sakin. Çizgi kalınlığı art bible\'a göre.', imageUrl: dataSvg('#C4577A', 'İfade seti (kontak sayfası)', 1000, 640), createdAt: iso(90) },
    'reviews/r-island': { title: 'Ada gökyüzü, gün batımı', context: 'Altın saat paleti.', imageUrl: '/_blob/0123456789abcdef0123456789abcdef', createdAt: iso(60 * 30), verdict: 'liked', verdictAt: iso(60 * 26) },
    'ideas/i1': { text: 'Pofu kış uykusuna yatsa, telefonu bıraktığın gece sayısı kadar.', tags: ['Oyun', 'Ada'], createdAt: iso(60 * 5), authorId: 'u_founder' },
  };
}

// Runs in the page before any page script. Implements the db.d.ts surface in memory.
function installMock(cfg) {
  if (cfg.none) return;
  const docs = new Map(Object.entries(cfg.seed || {}).map(([k, v]) => [k, JSON.parse(JSON.stringify(v))]));
  const docSubs = new Map(); // path -> Set(fn)
  const colSubs = new Map(); // collection path -> Set(fn)
  const err = (code, message) => Object.assign(new Error(message), { code, message });
  const parent = (p) => p.split('/').slice(0, -1).join('/');
  const segs = (p) => p.split('/');
  const check = (p, parity) => {
    if (typeof p !== 'string' || !p || segs(p).some((s) => !/^[A-Za-z0-9_\-.~:@+]+$/.test(s) || s === '.' || s === '..')) throw new TypeError('bad path ' + p);
    if (segs(p).length % 2 !== parity) throw new TypeError('wrong parity ' + p);
  };
  const freeze = (o) => { if (o && typeof o === 'object') { Object.values(o).forEach(freeze); Object.freeze(o); } return o; };
  const meta = Object.freeze({ fromCache: false, hasPendingWrites: false });
  const dsnap = (p) => {
    const d = docs.get(p);
    const body = d ? freeze(JSON.parse(JSON.stringify(d))) : undefined;
    return Object.freeze({ id: segs(p).pop(), exists: !!d, data: () => body, metadata: meta });
  };
  const qsnap = (col) => {
    const list = [...docs.keys()].filter((k) => parent(k) === col).sort().map(dsnap);
    return Object.freeze({ docs: list, size: list.length, empty: !list.length, docChanges: () => list.map((d, i) => ({ type: 'added', doc: d, oldIndex: -1, newIndex: i })), metadata: meta });
  };
  const notify = (p) => setTimeout(() => {
    (docSubs.get(p) || []).forEach((fn) => fn(dsnap(p)));
    (colSubs.get(parent(p)) || []).forEach((fn) => fn(qsnap(parent(p))));
  }, 5);
  const writes = [];
  const guard = () => { if (cfg.readOnly) throw err('invalid_argument', 'write below the minimum level'); };
  let idn = 0;
  function docRef(p) {
    check(p, 0);
    return Object.freeze({
      id: segs(p).pop(), path: p,
      get: async () => dsnap(p),
      set: async (data) => { guard(); docs.set(p, JSON.parse(JSON.stringify(data))); writes.push(['set', p, data]); notify(p); },
      update: async (data) => {
        guard();
        if (!docs.has(p)) throw err('invalid_argument', 'update needs an existing document');
        docs.set(p, Object.assign(docs.get(p), JSON.parse(JSON.stringify(data)))); writes.push(['update', p, data]); notify(p);
      },
      delete: async () => { guard(); docs.delete(p); notify(p); },
      acquire: async () => ({ acquired: true }),
      onSnapshot(next) {
        if (!docSubs.has(p)) docSubs.set(p, new Set());
        docSubs.get(p).add(next); window.__subs.push(p);
        setTimeout(() => next(dsnap(p)), cfg.delay || 20);
        return () => docSubs.get(p).delete(next);
      },
      collection: (c) => colRef(p + '/' + c),
    });
  }
  function colRef(c) {
    check(c, 1);
    const q = {
      path: c,
      where() { return q; }, orderBy() { return q; }, limit() { return q; },
      get: async () => qsnap(c),
      onSnapshot(next) {
        if (!colSubs.has(c)) colSubs.set(c, new Set());
        colSubs.get(c).add(next); window.__subs.push(c);
        setTimeout(() => next(qsnap(c)), cfg.delay || 20);
        return () => colSubs.get(c).delete(next);
      },
      doc: (id) => docRef(c + '/' + (id || 'auto' + (++idn) + Math.random().toString(36).slice(2, 8))),
      add: async (data) => { const r = q.doc(); await r.set(data); return r; },
    };
    return Object.freeze(q);
  }
  const db = Object.freeze({ doc: docRef, collection: colRef });
  const user = Object.freeze({
    isOwner: async () => !cfg.readOnly, canEdit: async () => !cfg.readOnly,
    can: async (n) => (n === 'data.write' ? !cfg.readOnly : false),
    id: async () => 'u_founder', me: async () => ({ id: 'u_founder', name: '', avatarUrl: '', color: '#6C4FD8', email: null, isOwner: !cfg.readOnly, canEdit: !cfg.readOnly }),
    profiles: async (ids) => Object.fromEntries([].concat(ids).map((id) => [id, { id, name: '', avatarUrl: '', color: '#6C4FD8', email: null, isMe: id === 'u_founder', guest: false }])),
    name: async () => '', avatarUrl: async () => null, search: async () => [], email: async () => null,
  });
  window.__subs = [];
  window.__mock = {
    docs, writes,
    // A write from outside this page (the lead through the tool).
    external(p, data) { docs.set(p, data); notify(p); },
  };
  window.claude = Object.freeze({ use: (name) => new Promise((r) => setTimeout(() => r(cfg.nullDb && name === 'db' ? null : name === 'db' ? db : name === 'user' ? user : null), 30)) });
}

async function open(browser, base, { phone = true, scheme = 'light', cfg = {} } = {}) {
  const ctx = await browser.newContext(phone
    ? { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true, colorScheme: scheme,
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Mobile/15E148 Safari/604.1' }
    : { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, colorScheme: scheme });
  // Google Fonts is the only external request; answer it locally so runs are offline and stable.
  await ctx.route(/fonts\.(googleapis|gstatic)\.com/, (r) => r.fulfill({ status: 200, contentType: 'text/css', body: '' }));
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('request', (r) => { const u = r.url(); if (!u.startsWith(base) && !/fonts\.(googleapis|gstatic)/.test(u)) errors.push('network: ' + u); });
  await page.addInitScript(installMock, cfg);
  await page.goto(base + '/');
  await page.waitForTimeout(400);
  const cdp = phone ? await ctx.newCDPSession(page) : null;
  // A real tap (touch on phone, mouse on desktop) at the centre of the element, after checking
  // that nothing covers it.
  const tap = async (locator, label) => {
    await locator.scrollIntoViewIfNeeded();
    await wait(80);
    const box = await locator.boundingBox();
    if (!box) { ok(false, `tap target visible: ${label}`); return; }
    const x = box.x + box.width / 2, y = box.y + box.height / 2;
    const onTop = await locator.evaluate((el, [px, py]) => { const t = document.elementFromPoint(px, py); return !!t && (t === el || el.contains(t)); }, [x, y]);
    if (!onTop) ok(false, `nothing covers ${label}`);
    if (cdp) {
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id: 1, radiusX: 4, radiusY: 4, force: 1 }] });
      await wait(40);
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    } else await page.mouse.click(x, y);
    await wait(120);
  };
  return { ctx, page, errors, tap };
}

async function noSideScroll(page, label) {
  const w = await page.evaluate(() => [document.documentElement.scrollWidth, window.innerWidth]);
  ok(w[0] <= w[1], `${label}: no horizontal scroll (${w[0]} <= ${w[1]})`);
}
async function hitTargets(page, label) {
  const small = await page.evaluate(() => Array.from(document.querySelectorAll('button, a, textarea'))
    .filter((e) => e.offsetParent !== null && !e.closest('[hidden]'))
    .map((e) => { const r = e.getBoundingClientRect(); return { t: (e.textContent || e.getAttribute('aria-label') || e.tagName).trim().slice(0, 30), w: r.width, h: r.height }; })
    .filter((r) => r.w > 0 && (r.w < 44 || r.h < 40)));
  // Segment buttons are 40 pt tall inside a 46 pt bar (with padding), like UISegmentedControl.
  const real = small.filter((s) => !(s.h >= 40 && s.w >= 44));
  ok(real.length === 0, `${label}: hit targets at least 44 pt ${real.length ? JSON.stringify(real) : ''}`);
}
async function shot(page, name, full = false) {
  if (!SHOTS) return;
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  await page.screenshot({ path: path.join(SHOT_DIR, name + '.jpg'), type: 'jpeg', quality: 82, fullPage: full });
}
async function tab(t, page, name) { await t(page.locator(`.seg button[data-tab="${name}"]`), `tab ${name}`); }

async function main() {
  const srv = await serve();
  const base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  try {
    // ---------------------------------------------------------------- phone, light, full data
    {
      const { ctx, page, errors, tap } = await open(browser, base, { cfg: { seed: sampleSeed() } });
      ok(await page.title() === 'Pofu Hub', 'title is Pofu Hub');
      const subs = await page.evaluate(() => window.__subs.slice());
      ok(subs.length === 7 && new Set(subs).size === 7, `subscribes once per query (${subs.length})`);
      ok(await page.locator('#banner').isHidden(), 'no banner when live');
      const cards = page.locator('#q-list article');
      ok(await cards.count() === 2, 'Açık shows the two open questions');
      ok((await cards.first().locator('h4').textContent()).includes('Kalkan'), 'priority 1 first');
      ok(await page.locator('.atlas-link').getAttribute('href') === 'https://claude.ai/artifact/8FrYGRfEJYgmZwENn66mBK', 'atlas link');
      await noSideScroll(page, 'phone questions');
      await hitTargets(page, 'phone questions');
      await shot(page, 'phone-questions-light');
      await shot(page, 'phone-questions-light-full', true);

      // Choose, then change, an option.
      const q1 = page.locator('article[data-qid="q-shield-tone"]');
      await tap(q1.locator('.opt').nth(1), 'option b');
      await wait(150);
      let ans = await page.evaluate(() => window.__mock.docs.get('answers/q-shield-tone'));
      ok(ans && ans.choice === 'b' && ans.authorId === 'u_founder' && !!ans.updatedAt, 'choice stored in answers/{qid}');
      ok(await q1.locator('.opt').nth(1).getAttribute('aria-checked') === 'true', 'chosen option is checked');
      ok(await q1.isVisible(), 'answered question stays in place under Açık');
      ok((await q1.locator('.pill').textContent()) === 'Cevaplandı', 'status pill reads Cevaplandı');
      await tap(q1.locator('.opt').nth(0), 'option a');
      await wait(150);
      ans = await page.evaluate(() => window.__mock.docs.get('answers/q-shield-tone'));
      ok(ans.choice === 'a', 'choice can be changed');
      await shot(page, 'phone-question-chosen-light');

      // Add a note.
      const ta = q1.locator('textarea');
      ok(await q1.locator('.hint').first().textContent() === 'Klavyedeki mikrofonla dikte edebilirsin', 'dictation hint');
      ok(await q1.locator('.composer .btn').isDisabled(), 'Ekle disabled while empty');
      await tap(ta, 'note textarea');
      await page.keyboard.type('Metinler kısa olsun, en fazla iki satır.');
      await tap(q1.locator('.composer .btn'), 'Ekle');
      await wait(200);
      const notes = await page.evaluate(() => [...window.__mock.docs.entries()].filter(([k]) => k.startsWith('notes/')).map(([, v]) => v));
      const mine = notes.find((n) => n.text === 'Metinler kısa olsun, en fazla iki satır.');
      ok(mine && mine.targetType === 'question' && mine.targetId === 'q-shield-tone' && mine.authorId === 'u_founder' && !mine.fromLead, 'note stored in notes/');
      ok((await q1.locator('.note').last().textContent()).includes('iki satır'), 'note shows at the bottom of the thread');
      ok(await ta.inputValue() === '', 'textarea clears after adding');

      // A live lead follow-up arrives while a draft is being typed: the draft and focus survive.
      await tap(ta, 'note textarea again');
      await page.keyboard.type('Yarım kalan taslak');
      await page.evaluate(() => window.__mock.external('notes/lead2', { targetType: 'question', targetId: 'q-shield-tone', text: 'Not aldım, örnekleri buna göre yazıyorum.', createdAt: new Date().toISOString(), authorId: 'u_founder', fromLead: true }));
      await wait(200);
      ok((await q1.locator('.note.lead').last().textContent()).includes('örnekleri'), 'lead follow-up appears live, styled as lead');
      ok(await ta.inputValue() === 'Yarım kalan taslak', 'draft survives a live update');
      ok(await ta.evaluate((e) => document.activeElement === e), 'focus survives a live update');
      await page.evaluate(() => document.activeElement.blur());
      await shot(page, 'phone-thread-light');

      // Filters.
      await tap(page.locator('.chip[data-filter="answered"]'), 'filter answered');
      ok(await page.locator('#q-list article').count() === 1, 'Cevaplandı lists the answered question');
      await tap(page.locator('.chip[data-filter="all"]'), 'filter all');
      ok(await page.locator('#q-list article').count() === 3, 'Hepsi lists every question');
      ok(await page.locator('article[data-qid="q-old"] .opt').first().isDisabled(), 'closed question options are locked');
      await tap(page.locator('.chip[data-filter="open"]'), 'filter open');
      ok(await page.locator('#q-list article').count() === 1, 'after leaving the filter, the answered question leaves Açık');

      // Şu an + idea.
      await tab(tap, page, 'now');
      ok(await page.locator('#panel-now').isVisible() && await page.locator('#panel-questions').isHidden(), 'switches to Şu an');
      ok((await page.locator('#now-meta').textContent()).startsWith('son güncelleme'), 'son güncelleme timestamp');
      ok(await page.locator('#now-doing .item').count() === 2 && await page.locator('#now-next .item').count() === 2, 'Şu an lists render');
      await noSideScroll(page, 'phone now');
      await shot(page, 'phone-now-light');
      await tap(page.locator('#fab'), 'Fikir');
      await wait(350);
      ok(await page.locator('#sheet').isVisible(), 'Fikir sheet opens');
      ok(await page.locator('#idea-send').isDisabled(), 'Gönder disabled while empty');
      await page.keyboard.type('Pofu\'ya mevsimlik şapkalar');
      await tap(page.locator('#idea-tags .chip', { hasText: 'Tasarım' }), 'tag Tasarım');
      await tap(page.locator('#idea-tags .chip', { hasText: 'Ada' }), 'tag Ada');
      await hitTargets(page, 'phone sheet');
      await shot(page, 'phone-idea-sheet-light');
      await tap(page.locator('#idea-send'), 'Gönder');
      await wait(450);
      const idea = await page.evaluate(() => [...window.__mock.docs.entries()].filter(([k]) => k.startsWith('ideas/')).map(([, v]) => v).find((v) => v.text.includes('şapka')));
      ok(idea && idea.tags.join(',') === 'Ada,Tasarım' && idea.authorId === 'u_founder' && !!idea.createdAt, 'idea stored in ideas/ with tags');
      ok(await page.locator('#sheet').isHidden(), 'sheet closes after sending');
      ok((await page.locator('#ideas .item').first().textContent()).includes('şapka'), 'new idea listed first under Fikirler');
      await page.locator('#ideas').scrollIntoViewIfNeeded();
      await shot(page, 'phone-ideas-light');

      // Yol haritası.
      await tab(tap, page, 'roadmap');
      ok(await page.locator('#timeline .ms').count() === 5, 'roadmap milestones render');
      ok(await page.locator('#timeline .ms.doing').count() === 1, 'one milestone in progress');
      await noSideScroll(page, 'phone roadmap');
      await shot(page, 'phone-roadmap-light');

      // Onay.
      await tab(tap, page, 'reviews');
      const r1 = page.locator('article[data-rid="r-hamster"]');
      ok(await r1.locator('.pill').textContent() === 'Bekliyor', 'pending review');
      await shot(page, 'phone-reviews-light');
      await tap(r1.locator('.vbtn.redo'), 'Yeniden');
      await wait(150);
      let rv = await page.evaluate(() => window.__mock.docs.get('reviews/r-hamster'));
      ok(rv.verdict === 'redo' && !!rv.verdictAt && rv.title, 'verdict stored by update');
      await tap(r1.locator('.vbtn.like'), 'Beğendim');
      await wait(150);
      rv = await page.evaluate(() => window.__mock.docs.get('reviews/r-hamster'));
      ok(rv.verdict === 'liked', 'verdict can be changed');
      await tap(r1.locator('.vbtn.note'), 'Not');
      await wait(300);
      ok(await r1.locator('textarea').evaluate((e) => document.activeElement === e), 'Not opens and focuses the review note');
      await page.keyboard.type('Uykulu ifade biraz hüzünlü, daha huzurlu olsun.');
      await tap(r1.locator('.composer .btn'), 'Ekle (review)');
      await wait(200);
      const rnote = await page.evaluate(() => [...window.__mock.docs.values()].find((v) => v.targetType === 'review'));
      ok(rnote && rnote.targetId === 'r-hamster', 'review note stored');
      await hitTargets(page, 'phone reviews');
      await page.evaluate(() => window.scrollTo(0, 0));
      await shot(page, 'phone-reviews-verdict-light');

      // Section choice survives a reload (per-viewer convenience).
      await page.reload(); await wait(400);
      ok(await page.locator('#panel-reviews').isVisible(), 'remembers the section');
      ok(errors.length === 0, `phone light: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- phone, dark
    {
      const { ctx, page, errors, tap } = await open(browser, base, { scheme: 'dark', cfg: { seed: sampleSeed() } });
      const bg = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
      ok(bg === 'rgb(21, 17, 28)', `dark body background (${bg})`);
      await shot(page, 'phone-questions-dark');
      await tab(tap, page, 'now'); await shot(page, 'phone-now-dark');
      await tab(tap, page, 'roadmap'); await shot(page, 'phone-roadmap-dark');
      await tab(tap, page, 'reviews'); await shot(page, 'phone-reviews-dark');
      await page.locator('#fab').click(); await wait(350); await shot(page, 'phone-idea-sheet-dark');
      ok(errors.length === 0, `phone dark: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- explicit theme overrides
    {
      const { ctx, page } = await open(browser, base, { scheme: 'dark', cfg: { seed: sampleSeed() } });
      await page.evaluate(() => document.documentElement.setAttribute('data-theme', 'light'));
      ok(await page.evaluate(() => getComputedStyle(document.body).backgroundColor) === 'rgb(255, 246, 236)', 'data-theme="light" wins over a dark system');
      await ctx.close();
      const b = await open(browser, base, { scheme: 'light', cfg: { seed: sampleSeed() } });
      await b.page.evaluate(() => document.documentElement.setAttribute('data-theme', 'dark'));
      ok(await b.page.evaluate(() => getComputedStyle(document.body).backgroundColor) === 'rgb(21, 17, 28)', 'data-theme="dark" wins over a light system');
      await b.ctx.close();
    }

    // ---------------------------------------------------------------- desktop, light and dark
    for (const scheme of ['light', 'dark']) {
      const { ctx, page, errors, tap } = await open(browser, base, { phone: false, scheme, cfg: { seed: sampleSeed() } });
      const w = await page.evaluate(() => document.querySelector('.wrap').getBoundingClientRect().width);
      ok(w <= 720, `desktop ${scheme}: column at most 720 px (${w})`);
      await noSideScroll(page, `desktop ${scheme}`);
      await shot(page, `desktop-questions-${scheme}`);
      await tab(tap, page, 'now'); await shot(page, `desktop-now-${scheme}`);
      await tab(tap, page, 'roadmap'); await shot(page, `desktop-roadmap-${scheme}`);
      await tab(tap, page, 'reviews'); await shot(page, `desktop-reviews-${scheme}`);
      ok(errors.length === 0, `desktop ${scheme}: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- empty db
    {
      const { ctx, page, errors, tap } = await open(browser, base, { cfg: { seed: {} } });
      ok((await page.locator('#q-list .empty').textContent()).includes('Henüz soru yok'), 'empty questions line');
      await shot(page, 'phone-empty-questions');
      await tap(page.locator('.chip[data-filter="answered"]'), 'filter answered (empty)');
      ok(await page.locator('#q-list .empty').isVisible(), 'empty answered line');
      await tab(tap, page, 'now');
      ok(await page.locator('#panel-now .empty').count() === 4, 'empty Şu an lists and ideas');
      await shot(page, 'phone-empty-now');
      await tab(tap, page, 'roadmap');
      ok((await page.locator('#timeline .empty').textContent()).includes('henüz yazılmadı'), 'empty roadmap line');
      await tab(tap, page, 'reviews');
      ok((await page.locator('#rv-list .empty').textContent()).includes('Onay bekleyen'), 'empty reviews line');
      await shot(page, 'phone-empty-reviews');
      ok(errors.length === 0, `empty: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- open questions only answered: friendly line
    {
      const seed = sampleSeed();
      seed['answers/q-shield-tone'] = { choice: 'a', updatedAt: new Date().toISOString(), authorId: 'u_founder' };
      seed['answers/q-seed-cap'] = { choice: 'yes', updatedAt: new Date().toISOString(), authorId: 'u_founder' };
      const { ctx, page, errors } = await open(browser, base, { cfg: { seed } });
      ok((await page.locator('#q-list .empty').textContent()).includes('Açık soru yok'), 'no open questions line');
      ok(await page.locator('#tab-questions .dot').isHidden(), 'no dot when nothing is open');
      ok(errors.length === 0, `all answered: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- read-only viewer
    {
      const { ctx, page, errors } = await open(browser, base, { cfg: { seed: sampleSeed(), readOnly: true } });
      ok(await page.locator('#banner').isVisible(), 'read-only banner');
      ok(await page.locator('.opt').first().isDisabled(), 'options locked when read-only');
      ok(await page.locator('#q-list textarea').first().isDisabled(), 'composer locked when read-only');
      ok(await page.locator('#fab').isHidden(), 'no Fikir button when read-only');
      await shot(page, 'phone-readonly');
      ok(errors.length === 0, `read-only: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- db unavailable (use resolves null)
    {
      const { ctx, page, errors } = await open(browser, base, { cfg: { nullDb: true } });
      ok((await page.locator('#banner').textContent()).includes('salt okunur'), 'null db: read-only message');
      ok(await page.locator('#q-list .empty').isVisible(), 'null db: empty state');
      ok(errors.length === 0, `null db: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- plain browser, no window.claude
    {
      const { ctx, page, errors, tap } = await open(browser, base, { cfg: { none: true } });
      ok(await page.evaluate(() => typeof window.claude) === 'undefined', 'no window.claude');
      ok((await page.locator('#banner').textContent()).includes('salt okunur'), 'plain browser: read-only message');
      ok(await page.locator('#fab').isHidden(), 'plain browser: no Fikir button');
      await tab(tap, page, 'roadmap');
      ok(await page.locator('#timeline .empty').isVisible(), 'plain browser: roadmap empty state');
      await tab(tap, page, 'questions');
      await shot(page, 'phone-no-claude');
      ok(errors.length === 0, `plain browser: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }
  } finally {
    await browser.close();
    srv.close();
  }
  console.log(failures ? `\n${failures} check(s) failed` : '\nAll checks passed');
  process.exit(failures ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
