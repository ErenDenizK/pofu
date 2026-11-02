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
// Dictation: the segmenter and text clean-up, the model installer (mock asset store), the
// "no model" and "microphone blocked" panels, transcribing a picked file, and live recording with
// Chromium's fake microphone. The Whisper worker is replaced by a mock that answers per window;
// design/hub/tools/dictation-e2e.js runs the real worker and a real model.
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
    if (u === '/dictation/worker.js') { res.writeHead(200, { 'content-type': 'text/javascript' }); res.end(MOCK_WORKER); return; }
    const sm = u.match(/^\/sample\/(s\d+)\.svg$/);
    if (sm && SAMPLES[sm[1]]) { res.writeHead(200, { 'content-type': 'image/svg+xml' }); res.end(SAMPLES[sm[1]]); return; }
    const m = u.match(/^\/_blob\/([0-9a-f]{32})$/);
    if (m) { res.writeHead(200, { 'content-type': 'image/svg+xml' }); res.end(sampleSvg('#6C4FD8', 'asset')); return; }
    res.writeHead(404); res.end();
  });
  return new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv)));
}

// Stands in for dictation/worker.js: reports model progress, then answers each window with its
// index and length, so the checks can see where the audio was cut.
const MOCK_WORKER = `
let n = 0;
self.onmessage = async (e) => {
  const { id, type } = e.data;
  const post = (m) => self.postMessage({ id, ...m });
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));
  if (type === 'load') {
    for (let i = 1; i <= 4; i++) { post({ type: 'progress', phase: 'download', loaded: i * 25e6, total: 100e6 }); await wait(40); }
    post({ type: 'progress', phase: 'init', device: e.data.device }); await wait(40);
    post({ type: 'done', device: e.data.device });
  } else if (type === 'transcribe') {
    await wait(120); n++;
    post({ type: 'done', text: ' Parça ' + n + ' (' + (e.data.audio.length / 16000).toFixed(1) + ' sn, ' + e.data.language + ').', ms: 120 });
  } else post({ type: 'done' });
};`;

// 70 s of 44.1 kHz stereo "speech" (amplitude-modulated tones) with two short pauses, at 20 to 21 s
// and 45 to 46.5 s, as a WAV file.
function sampleWav() {
  const sr = 44100, secs = 70, n = sr * secs;
  const buf = Buffer.alloc(44 + n * 4);
  buf.write('RIFF', 0); buf.writeUInt32LE(36 + n * 4, 4); buf.write('WAVE', 8); buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(sr, 24);
  buf.writeUInt32LE(sr * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34); buf.write('data', 36); buf.writeUInt32LE(n * 4, 40);
  for (let i = 0; i < n; i++) {
    const t = i / sr;
    const quiet = (t >= 20 && t < 21) || (t >= 45 && t < 46.5);
    const v = quiet ? 0 : 0.3 * Math.sin(2 * Math.PI * 180 * t) * (0.55 + 0.45 * Math.sin(2 * Math.PI * 3 * t));
    const x = Math.round(v * 32767);
    buf.writeInt16LE(x, 44 + i * 4); buf.writeInt16LE(x, 46 + i * 4);
  }
  return buf;
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
  const blobs = new Map();
  const assets = Object.freeze({
    upload: async (blob, opts = {}) => {
      const type = opts.type || blob.type;
      const okTypes = ['text/plain', 'video/mp4', 'video/webm', 'image/png', 'image/jpeg'];
      if (!okTypes.includes(type)) throw err('unsupported_type', 'type ' + type);
      if (blob.size > 20 * 1024 * 1024) throw err('too_large', 'too large');
      const id = Array.from(crypto.getRandomValues(new Uint8Array(16)), (b) => b.toString(16).padStart(2, '0')).join('');
      blobs.set(id, { type, size: blob.size, text: type === 'text/plain' ? await blob.text() : null });
      return { id, url: '/_blob/' + id, sizeBytes: blob.size, contentType: type };
    },
    list: async () => ({ assets: [...blobs].map(([id, b]) => ({ id, url: '/_blob/' + id, contentType: b.type, sizeBytes: b.size, createdAt: '' })), usage: { files: blobs.size, bytes: [...blobs.values()].reduce((s, b) => s + b.size, 0), maxFiles: 5000, maxBytes: 1073741824 } }),
    delete: async (id) => ({ deleted: blobs.delete(id) }),
  });
  window.__mock = {
    docs, writes, blobs,
    // A write from outside this page (the lead through the tool).
    external(p, data) { docs.set(p, data); notify(p); },
  };
  window.claude = Object.freeze({ use: (name) => new Promise((r) => setTimeout(() => r(cfg.nullDb && name === 'db' ? null : name === 'db' ? db : name === 'user' ? user : name === 'assets' && cfg.assets ? assets : null), 30)) });
}

async function open(browser, base, { phone = true, scheme = 'light', cfg = {}, mic = false } = {}) {
  const ctx = await browser.newContext(Object.assign(mic ? { permissions: ['microphone'] } : {}, phone
    ? { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true, colorScheme: scheme,
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.1 Mobile/15E148 Safari/604.1' }
    : { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, colorScheme: scheme }));
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
      ok(subs.length === 8 && new Set(subs).size === 8, `subscribes once per query (${subs.length})`);
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
      ok((await q1.locator('.micbtn').first().textContent()) === 'Dikte', 'Dikte button under the note field');
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

    // ---------------------------------------------------------------- dictation: helpers, installer, blocked mic, file
    {
      const { ctx, page, errors, tap } = await open(browser, base, { cfg: { seed: sampleSeed(), assets: true } });
      const pure = await page.evaluate(() => {
        const D = window.__pofuDictation; const sr = 1000; const x = new Float32Array(70 * sr);
        for (let i = 0; i < x.length; i++) { const t = i / sr; x[i] = (t >= 20 && t < 21) || (t >= 45 && t < 46.5) ? 0 : 0.3 * Math.sin(i); }
        const live = D.splitSegments(x.subarray(0, 40 * sr), sr, false);
        const all = D.splitSegments(x, sr, true);
        return {
          live: live.segments.map(([a, b]) => [a / sr, b / sr]), consumed: live.consumed / sr,
          all: all.segments.map(([a, b]) => [a / sr, b / sr]),
          silent: D.isSilent(new Float32Array(16000), 0, 16000, 16000), loud: D.isSilent(x, 0, 16000, sr),
          junk: D.cleanText(' Bugün ada sahnesine baktım. Altyazı M.K. '),
          loop: D.cleanText('Liquid Glass olsun olsun olsun olsun ama sade kalsın.'),
          loop2: D.cleanText('ve sonra ve sonra ve sonra ve sonra golden hour ışığı'),
          keep: D.cleanText('çok çok güzel'),
          join: [D.joinText('Merhaba', 'dünya'), D.joinText('Merhaba ', 'dünya'), D.joinText('Merhaba', ', dünya'), D.joinText('', 'İlk')],
          types: ['audio/mp4', 'audio/webm;codecs=opus', 'audio/x-m4a', 'audio/mpeg', 'audio/wav', ''].map(D.assetTypeFor),
        };
      });
      ok(pure.live.length === 1 && pure.live[0][1] >= 20.3 && pure.live[0][1] <= 20.7 && pure.consumed === pure.live[0][1], `live split cuts in the first pause and keeps the tail (${JSON.stringify(pure.live)})`);
      ok(pure.all.length === 3 && pure.all[1][1] >= 45.5 && pure.all[1][1] <= 46 && pure.all[2][1] === 70, `file split: three windows cut in the pauses (${JSON.stringify(pure.all)})`);
      ok(pure.all.every(([a, b]) => b - a <= 29.5), 'no window longer than 29.5 s');
      ok(pure.silent === true && pure.loud === false, 'silence is skipped, speech is not');
      ok(pure.junk === 'Bugün ada sahnesine baktım.', `Whisper's subtitle credit is removed (${pure.junk})`);
      ok(pure.loop === 'Liquid Glass olsun ama sade kalsın.' && pure.loop2 === 've sonra golden hour ışığı' && pure.keep === 'çok çok güzel', `decoding loops collapse (${pure.loop} | ${pure.loop2} | ${pure.keep})`);
      ok(JSON.stringify(pure.join) === JSON.stringify([' dünya', 'dünya', ', dünya', 'İlk']), 'pieces join with one space');
      ok(JSON.stringify(pure.types) === JSON.stringify(['video/mp4', 'video/webm', 'video/mp4', null, null, null]), 'recordings map to the asset store types');

      // No model yet: the panel offers the installer.
      const q1 = page.locator('article[data-qid="q-shield-tone"]');
      await tap(q1.locator('.micbtn'), 'Dikte (no model)');
      ok((await q1.locator('.dict-title').textContent()) === 'Konuşma modeli kurulu değil', 'no model: panel says so');
      await hitTargets(page, 'phone dictation panel');
      await shot(page, 'phone-dictation-nomodel');
      await tap(q1.locator('.dict .btn', { hasText: 'Modeli kur' }), 'Modeli kur');
      await wait(350);
      ok(await page.locator('#dsheet').isVisible(), 'Dikte sheet opens');
      ok(await page.locator('#dsheet .chip[aria-pressed="true"]', { hasText: 'Small' }).count() === 1, 'phone suggests Small');
      const crypto = require('crypto');
      const enc = crypto.randomBytes(2_500_000), dec = crypto.randomBytes(16_000_000);
      const json = (o) => Buffer.from(JSON.stringify(o));
      await page.setInputFiles('#model-files', [
        { name: 'config.json', mimeType: 'application/json', buffer: json({ model_type: 'whisper' }) },
        { name: 'generation_config.json', mimeType: 'application/json', buffer: json({ lang_to_id: {} }) },
        { name: 'preprocessor_config.json', mimeType: 'application/json', buffer: json({ feature_size: 80 }) },
        { name: 'tokenizer.json', mimeType: 'application/json', buffer: json({ model: { type: 'BPE' }, note: 'çğış' }) },
        { name: 'tokenizer_config.json', mimeType: 'application/json', buffer: json({}) },
        { name: 'encoder_model_quantized.onnx', mimeType: 'application/octet-stream', buffer: enc },
        { name: 'decoder_model_merged_quantized.onnx', mimeType: 'application/octet-stream', buffer: dec },
      ]);
      await wait(200);
      ok(await page.locator('#dsheet .files .ok').count() === 7, 'all seven files recognised');
      await hitTargets(page, 'phone Dikte sheet');
      await noSideScroll(page, 'phone Dikte sheet');
      await shot(page, 'phone-dictation-install');
      await tap(page.locator('#dsheet .btn', { hasText: 'Yükle' }), 'Yükle');
      let man = null;
      for (let i = 0; i < 100 && !man; i++) { await wait(150); man = await page.evaluate(() => window.__mock.docs.get('dictation/small')); }
      ok(!!man && man.modelId === 'pofu/whisper-small' && man.dtype.encoder_model === 'q8' && man.dtype.decoder_model_merged === 'q8' && man.files.length === 7, 'manifest stored in dictation/small');
      const decFile = man && man.files.find((f) => f.name === 'onnx/decoder_model_merged_quantized.onnx');
      ok(decFile && decFile.chunks.length === 2 && decFile.enc === 'b64', 'large file split into two base64 chunks');
      const shaOf = (b) => crypto.createHash('sha256').update(b).digest('hex');
      ok(decFile && decFile.chunks[0].sha256 === shaOf(dec.subarray(0, 15_000_000)) && decFile.chunks[1].sha256 === shaOf(dec.subarray(15_000_000)), 'chunk checksums match the source bytes');
      const roundTrip = await page.evaluate(async (m) => {
        const f = m.files.find((x) => x.name.includes('decoder'));
        const bytes = f.chunks.map((c) => Uint8Array.from(atob(window.__mock.blobs.get(c.id).text), (ch) => ch.charCodeAt(0)));
        const hex = async (b) => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', b)), (x) => x.toString(16).padStart(2, '0')).join('');
        return Promise.all(bytes.map(hex));
      }, man);
      ok(decFile && roundTrip.join() === decFile.chunks.map((c) => c.sha256).join(), 'stored base64 decodes back to the same bytes');
      ok(await page.evaluate(() => window.__mock.blobs.get(window.__mock.docs.get('dictation/small').files[3].chunks[0].id).text.includes('çğış')), 'JSON files are stored as plain UTF-8');
      await shot(page, 'phone-dictation-installed');
      await tap(page.locator('#dsheet-close'), 'Kapat');
      await wait(350);

      // Microphone refused (as in the artifact frame): the panel offers a recorded file instead.
      await tap(q1.locator('.micbtn'), 'Dikte (no mic)');
      let title = '';
      for (let i = 0; i < 30 && !/mikrofon/i.test(title); i++) { await wait(100); title = (await q1.locator('.dict-title').textContent().catch(() => '')) || ''; }
      ok(/mikrofon/i.test(title), `blocked microphone explained (${title})`);
      ok(await q1.locator('.dict .btn', { hasText: 'Ses dosyası seç' }).count() === 1, 'offers a recorded file');
      await shot(page, 'phone-dictation-blocked');
      const assetsBefore = await page.evaluate(() => window.__mock.blobs.size);
      await tap(q1.locator('textarea'), 'note field'); await page.keyboard.type('Önce şunu yazdım.');
      const [fc] = await Promise.all([page.waitForEvent('filechooser'), tap(q1.locator('.dict .btn', { hasText: 'Ses dosyası seç' }), 'Ses dosyası seç')]);
      await fc.setFiles({ name: 'kayit.wav', mimeType: 'audio/wav', buffer: sampleWav() });
      let sawWork = false;
      for (let i = 0; i < 100; i++) {
        await wait(100);
        const t = await q1.locator('.dict-title').textContent().catch(() => '');
        if (!sawWork && /Yazıya|hazırlanıyor/.test(t)) { sawWork = true; await shot(page, 'phone-dictation-working'); }
        if (t === 'Hazır') break;
      }
      const val = await q1.locator('textarea').inputValue();
      ok(await q1.locator('.dict-title').textContent() === 'Hazır', 'file transcribed');
      const lens = [...val.matchAll(/\((\d+\.\d) sn, turkish\)/g)].map((m) => Number(m[1]));
      ok(val.startsWith('Önce şunu yazdım. Parça 1') && lens.length === 3, `text lands after the typed words, three windows in order (${val})`);
      ok(lens.length === 3 && lens[0] >= 20 && lens[0] <= 21 && Math.abs(lens.reduce((a, b) => a + b, 0) - 70) < 0.3, `windows cut in the pauses (${lens.join(', ')})`);
      ok(!(await q1.locator('textarea').evaluate((e) => e.readOnly)), 'text stays editable');
      ok(await page.evaluate(() => window.__mock.blobs.size) === assetsBefore, 'a WAV file is not kept (no matching asset type)');
      await shot(page, 'phone-dictation-done');
      await tap(q1.locator('.composer .btn', { hasText: 'Ekle' }), 'Ekle after dictation');
      await wait(250);
      const dnote = await page.evaluate(() => [...window.__mock.docs.values()].find((v) => v.text && v.text.includes('Parça 3')));
      ok(dnote && !dnote.audio && dnote.text.startsWith('Önce şunu yazdım.'), 'dictated note saved');
      ok(await q1.locator('.dict').isHidden(), 'panel closes after saving');

      // The idea sheet has the same button.
      await tab(tap, page, 'now');
      await tap(page.locator('#fab'), 'Fikir'); await wait(350);
      ok(await page.locator('#idea-foot .micbtn').isVisible(), 'Dikte button in the idea sheet');
      ok(errors.length === 0, `dictation: no console errors ${errors.join(' | ')}`);
      await ctx.close();
    }

    // ---------------------------------------------------------------- dictation: live microphone (Chromium's fake device)
    {
      const micBrowser = await chromium.launch({ args: ['--use-fake-device-for-media-stream', '--use-fake-ui-for-media-stream'] });
      const seed = sampleSeed();
      seed['dictation/small'] = { preset: 'small', modelId: 'pofu/whisper-small', version: 1, dtype: { encoder_model: 'q8', decoder_model_merged: 'q8' }, totalBytes: 250e6, installedAt: new Date().toISOString(), files: [{ name: 'config.json', size: 2, enc: 'raw', chunks: [{ id: '0123456789abcdef0123456789abcdef', size: 2, sha256: '' }] }] };
      const { ctx, page, errors, tap } = await open(micBrowser, base, { mic: true, cfg: { seed, assets: true } });
      const q1 = page.locator('article[data-qid="q-shield-tone"]');
      await tap(q1.locator('.micbtn'), 'Dikte (live)');
      let t = '';
      for (let i = 0; i < 30 && t !== 'Dinliyorum'; i++) { await wait(100); t = await q1.locator('.dict-title').textContent().catch(() => ''); }
      ok(t === 'Dinliyorum', 'recording starts');
      ok(await q1.locator('.micbtn').getAttribute('aria-pressed') === 'true' && (await q1.locator('.micbtn').textContent()) === 'Bitir', 'mic button turns into Bitir');
      ok(await q1.locator('textarea').evaluate((e) => e.readOnly && e.classList.contains('dictating')), 'field is locked and marked while listening');
      await wait(2600);
      const timer = await q1.locator('.dict-time').textContent();
      ok(timer === '0:02' || timer === '0:03', `timer runs (${timer})`);
      const heights = await q1.locator('.meter i').evaluateAll((bars) => bars.map((b) => b.getBoundingClientRect().height));
      ok(new Set(heights.map(Math.round)).size > 1, 'level meter moves');
      await hitTargets(page, 'phone recording');
      await noSideScroll(page, 'phone recording');
      await shot(page, 'phone-dictation-recording');
      await tap(q1.locator('.dict .btn.stop'), 'Bitir');
      for (let i = 0; i < 60; i++) { await wait(100); if ((await q1.locator('.dict-title').textContent().catch(() => '')) === 'Hazır') break; }
      const val = await q1.locator('textarea').inputValue();
      ok(/^Parça 1 \((2|3)\.\d sn, turkish\)\.$/.test(val), `live recording transcribed (${val})`);
      let kept = 0;
      for (let i = 0; i < 30 && !kept; i++) { await wait(100); kept = await page.evaluate(() => window.__mock.blobs.size); }
      const keptType = await page.evaluate(() => [...window.__mock.blobs.values()].map((b) => b.type).join());
      ok(kept === 1 && /^video\/(mp4|webm)$/.test(keptType), `recording kept as an asset (${keptType})`);
      await tap(q1.locator('.composer .btn', { hasText: 'Ekle' }), 'Ekle (live)');
      await wait(250);
      const n = await page.evaluate(() => [...window.__mock.docs.values()].find((v) => v.text && v.text.startsWith('Parça 1')));
      ok(n && Array.isArray(n.audio) && n.audio.length === 1 && /^[0-9a-f]{32}$/.test(n.audio[0].id) && n.audio[0].seconds >= 2, 'note carries the recording');
      ok(await q1.locator('.note audio').count() === 1, 'note shows a player for the recording');
      // Cancel leaves the field as it was.
      await tap(q1.locator('textarea'), 'note field'); await page.keyboard.type('Taslak');
      await tap(q1.locator('.micbtn'), 'Dikte (cancel)');
      await wait(1200);
      await tap(q1.locator('.dict .btn', { hasText: 'Vazgeç' }), 'Vazgeç');
      await wait(200);
      ok(await q1.locator('textarea').inputValue() === 'Taslak' && await q1.locator('.dict').isHidden(), 'Vazgeç leaves the field unchanged');
      ok(errors.length === 0, `live dictation: no console errors ${errors.join(' | ')}`);
      await ctx.close();
      await micBrowser.close();
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

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
module.exports = { installMock, sampleSeed };
