// Pofu island game prototype (v3): an archipelago of pre-planned idle islands.
// Home is Pofu up close; one tap pulls back to his island, another to the
// archipelago map. Seeds (çekirdek) are world material only: they gather
// while you are away and buy station levels, never screen time (ADR-0015).
// Opening a guarded app costs calm (huzur) and Pofu's wellbeing (keyif); a
// quick check only halves the calm; past the daily threshold every open
// offers a short breathing break with Pofu that the user starts with a tap
// (v2: 5 s, at most 10 s). Pofu never dies (ADR-0017).
// Dependency-free, mobile-first, works inside a sandboxed iframe (no dialogs,
// no query strings, relative assets only). Everything except Pofu (R1) and
// Mochi (concept) is a code stand-in. Spec: docs/product/game-design.md.
'use strict';

// Flags come from the hash only (#bare, #labels=0), never the query string.
const FLAGS = new Set(location.hash.replace(/^#/, '').split(/[&,]/).filter(Boolean));
if (FLAGS.has('bare')) document.body.classList.add('bare');
if (FLAGS.has('labels=0')) document.body.classList.add('hide-labels');

// ---------------------------------------------------------------- tuning (mirrors tools/sim/island_economy.py)
const REF_W = 402, REF_H = 874;               // the design frame (iPhone 17, pt)
let W = REF_W, H = REF_H, FIT = 1;            // live canvas size in CSS px, and the world fit factor
const DPR = Math.min(2, Math.max(1, window.devicePixelRatio || 1));
const HOME_STAGES = [0, 1, 4, 10, 24];        // tended days for home stage 1..5
const COST_GROWTH = 2.2, RATE_GROWTH = 0.55;
const CALM_MAX = 2.0;
const SKIP_SEEDS = 3, SKIP_SEEDS_CAP = 5;      // a resisted reach adds a little, capped
const QUIET_SEEDS_HOUR = 6;                   // Pofu gathers 1 seed per 10 quiet minutes (ADR-0014)
const BREATH_LIMIT = 60;                      // guarded minutes a day before every open needs a breath
const BREATH_CAP = 10;                        // seconds: no breath is ever longer (breathing break v2)
const QUICK_MIN = 3, OPEN_MIN = 15;
// One breath, started by the user: 5 s for the 1st to 3rd over-limit open of the day, 10 s from the 4th on.
// The exhale is always the longer part (in : out = 2 : 3).
const breathSecsFor = (n) => Math.min(BREATH_CAP, n < 3 ? 5 : 10);

const ISLES = [
  { id: 'home', name: 'Ayçiçeği', en: 'Sunflower Island', pos: [0, 0],
    who: 'Pofu, Mochi the bunny, Fındık the hedgehog, the frogs',
    theme: 'Pofu’s home: a sunflower garden, Mochi’s çay ocağı, a lily pond, a workshop and a windmill on the terrace.',
    loop: ['The calm island', 'Calm grows while you are away; the residents make seeds faster; you spend them on the next designed level.'],
    need: 'Home from day 1. New spots appear on tended days 1, 4, 10 and 24.' },
  { id: 'harbor', name: 'İskele', en: 'The tea-and-simit harbor', pos: [220, 300], rx: 112,
    who: 'Simit, a honey tabby kitten who sells out by noon',
    theme: 'A little harbor with a simit cart, a ferry pier and a striped lighthouse. Mochi’s regulars wanted simit with their tea.',
    loop: ['The morning ferry', 'After every calm night the little vapur docks with a postcard from somewhere far away. Seven make a set for Pofu’s wall.'],
    need: '8 tended days and the çay ocağı at level 3.', stations: ['Simit cart', 'Ferry pier', 'Lighthouse'] },
  { id: 'stars', name: 'Yıldız', en: 'The night observatory', pos: [-150, -540], rx: 100,
    who: 'Nane, a sleepy little owl who keeps the star book',
    theme: 'A high, quiet island that wakes at dusk: a domed observatory, a firefly meadow, a hammock between two pines.',
    loop: ['Stargazing', 'Each calm night adds a star. At bedtime, a 20-second moment: Pofu points at tonight’s star, then says good night. Seven stars make a constellation you name.'],
    need: '21 tended days and 10 calm nights (any, not in a row).', stations: ['Observatory', 'Firefly meadow', 'Hammock'] },
  { id: 'hamam', name: 'Kaplıca', en: 'The hot-spring hamam', pos: [215, -345], rx: 106,
    who: 'Pamuk, an unbothered capybara',
    theme: 'Steam, domes and warm stone: a hot spring, a tiny hamam and a şerbet stand.',
    loop: ['The warm spring', 'Quiet hours fill the spring one ladle at a time. When it is full, everyone soaks together for an evening and Pofu comes out glowing.'],
    need: '35 tended days and the ferry pier at level 3.', stations: ['Hot spring', 'Hamam', 'Şerbet stand'] },
  { id: 'library', name: 'Kitap', en: 'The library island', pos: [-225, 330], rx: 100,
    who: 'Bulut, a cloud-soft chinchilla who reads aloud',
    theme: 'A reading tree, a round book house and a little printing press.',
    loop: ['Bulut’s story', 'A short illustrated story, one page per tended day, read in half a minute. Never more than one page a day; finished books go on the shelf.'],
    need: 'Arrives with a season update, for everyone, and stays.', season: true, stations: ['Reading tree', 'Book house', 'Printing press'] },
];
const isleById = Object.fromEntries(ISLES.map((i) => [i.id, i]));

const STATIONS = [
  { id: 'garden', isle: 'home', gate: 0, name: 'Sunflower garden', tr: 'Ayçiçeği bahçesi', rate: 6, build: 0, who: 'Pofu', slot: [-66, -4],
    levels: ['A small bed of three sunflowers', 'A picket fence and two more sunflowers', 'A watering can and a row of seedlings', 'A sunflower arch with bunting', 'One giant sunflower that turns to follow the sun'] },
  { id: 'cay', isle: 'home', gate: 1, name: 'Çay ocağı', tr: 'Çay ocağı', rate: 5, build: 40, who: 'Mochi the bunny', slot: [64, -2],
    levels: ['A wooden counter, a çaydanlık, two tulip glasses', 'A striped awning', 'Two stools and a tiny table (choose a style)', 'String lights for the evening', 'A tiled roof, a geranium, a little flag'] },
  { id: 'pond', isle: 'home', gate: 2, name: 'Lily pond', tr: 'Nilüferli gölet', rate: 6, build: 160, who: 'the frogs', slot: [132, 18],
    levels: ['A small pond ringed with pebbles', 'Lily pads, one per calm night', 'Reeds and a blossom', 'A wooden dock', 'Floating lanterns'] },
  { id: 'workshop', isle: 'home', gate: 3, name: 'Workshop', tr: 'Atölye', rate: 9, build: 500, who: 'Fındık the hedgehog', slot: [62, -70],
    levels: ['A shed and a workbench', 'A wall of tools', 'A spinning wind vane', 'A chimney', 'A big gear sign'] },
  { id: 'windmill', isle: 'home', gate: 4, name: 'Windmill', tr: 'Yel değirmeni', rate: 12, build: 1400, who: 'Pofu and Fındık', slot: [-62, -74],
    levels: ['A stone mill with four bare sails', 'Cream sail cloths', 'Sacks of sunflower seeds', 'Lanterns along the cap', 'A flag and window boxes'] },
  { id: 'simit', isle: 'harbor', gate: 0, name: 'Simit cart', tr: 'Simitçi', rate: 8, build: 300, who: 'Simit the kitten', slot: [-46, 0],
    levels: ['A cart with a pile of simit', 'A sun umbrella', 'A simit pole, stacked high', 'A bench for regulars', 'A little kiosk with a flag'] },
  { id: 'pier', isle: 'harbor', gate: 3, name: 'Ferry pier', tr: 'İskele', rate: 9, build: 550, who: 'the ferry crew', slot: [58, 12],
    levels: ['Planks and posts over the clouds', 'A lantern post', 'The little vapur moors here', 'A bench and two tea glasses', 'Bunting from post to post'] },
  { id: 'lighthouse', isle: 'harbor', gate: 7, name: 'Lighthouse', tr: 'Fener', rate: 11, build: 1000, who: 'Simit, at dusk', slot: [6, -30],
    levels: ['A striped tower', 'A lit lamp room', 'A balcony all around', 'A slow, warm beam at night', 'A flag and a garden at its foot'] },
];
const stById = Object.fromEntries(STATIONS.map((s) => [s.id, s]));
function cost(st, to) { return st.id === 'garden' ? (to === 1 ? 0 : Math.round(30 * COST_GROWTH ** (to - 2))) : Math.round(st.build * COST_GROWTH ** (to - 1)); }
function rate(st, L) { return L ? st.rate * (1 + RATE_GROWTH * (L - 1)) : 0; }
const POFU = { x: 6, y: 20 };
const POFU_W = 52, HOME_S = 2.6, HOME_FEET = 594;
const ease = (t) => 1 - Math.pow(1 - t, 3);
const now = () => performance.now();
let breathPhase = 0;   // -1..1, drives Pofu's belly during the breathing break
// ---------------------------------------------------------------- canvas helpers
const cvs = document.getElementById('world');
const ctx = cvs.getContext('2d');
const pofuImg = new Image(); pofuImg.src = 'assets/pofu.webp';
const bunnyImg = new Image(); bunnyImg.src = 'assets/neighbor-bunny.webp';
function ellipse(c, x, y, rx, ry, fill) { c.beginPath(); c.ellipse(x, y, Math.max(0.01, rx), Math.max(0.01, ry), 0, 0, Math.PI * 2); c.fillStyle = fill; c.fill(); }
function ball(c, x, y, r, light, dark, hl = 0.35) { const g = c.createRadialGradient(x - r * hl, y - r * hl, r * 0.1, x, y, r); g.addColorStop(0, light); g.addColorStop(1, dark); ellipse(c, x, y, r, r, g); }
function lin(c, x0, y0, x1, y1, a, b) { const g = c.createLinearGradient(x0, y0, x1, y1); g.addColorStop(0, a); g.addColorStop(1, b); return g; }
function rrect(c, x, y, w, h, r, fill) { c.beginPath(); c.roundRect(x, y, w, h, r); c.fillStyle = fill; c.fill(); }
function softShadow(c, x, y, rx, ry, a = 0.22) { c.save(); c.translate(x, y); c.scale(1, ry / rx); const g = c.createRadialGradient(0, 0, 0, 0, 0, rx); g.addColorStop(0, `rgba(47,72,52,${a})`); g.addColorStop(1, 'rgba(47,72,52,0)'); ellipse(c, 0, 0, rx, rx, g); c.restore(); }
function sparkle(c, x, y, r, a, col = '#FFF6D0') { c.save(); c.globalAlpha = Math.max(0, a); c.fillStyle = col; c.beginPath(); c.moveTo(x, y - r); c.quadraticCurveTo(x, y, x + r, y); c.quadraticCurveTo(x, y, x, y + r); c.quadraticCurveTo(x, y, x - r, y); c.quadraticCurveTo(x, y, x, y - r); c.fill(); c.restore(); }
function leaf(c, x, y, len, ang, a = '#9AD48A', b = '#5E9E6A') { c.save(); c.translate(x, y); c.rotate(ang); c.beginPath(); c.moveTo(0, 0); c.quadraticCurveTo(len * 0.5, -len * 0.42, len, 0); c.quadraticCurveTo(len * 0.5, len * 0.42, 0, 0); c.fillStyle = lin(c, 0, 0, len, 0, b, a); c.fill(); c.restore(); }
function stem(c, x, y, x2, y2, w = 1.1) { c.strokeStyle = '#5E9E6A'; c.lineWidth = w; c.lineCap = 'round'; c.beginPath(); c.moveTo(x, y); c.quadraticCurveTo(x + (x2 - x) * 0.3, (y + y2) / 2, x2, y2); c.stroke(); }
function cloud(c, x, y, r, a) { c.globalAlpha = a; for (const [dx, dy, k] of [[0, 0, 1], [r * 0.9, 4, 0.75], [-r * 0.9, 5, 0.7], [r * 0.4, -r * 0.45, 0.8]]) ball(c, x + dx, y + dy, r * k, '#FFFFFF', '#EDE8F4', 0.4); c.globalAlpha = 1; }
const WOOD = ['#EDBE86', '#B87650'];

// ---------------------------------------------------------------- sky and cloud sea (screen space)
const clouds = Array.from({ length: 6 }, (_, i) => ({ x: (i * 97) % 420, y: 170 + ((i * 53) % 220), r: 16 + ((i * 7) % 12), sp: 3 + (i % 3) * 2 }));
const stars = Array.from({ length: 70 }, (_, i) => ({ x: (i * 73.3) % 440, y: (i * 41.7) % 620, r: 0.6 + (i % 3) * 0.45, ph: i }));
function drawSky(t) {
  const g = ctx.createLinearGradient(0, 0, 0, H);
  if (S.night) { g.addColorStop(0, '#15111C'); g.addColorStop(0.55, '#2A2050'); g.addColorStop(1, '#3A3070'); }
  else { g.addColorStop(0, '#A9D3EC'); g.addColorStop(0.45, '#CBE6F1'); g.addColorStop(0.8, '#F6EDE2'); g.addColorStop(1, '#FCEBDD'); }
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  if (!S.night) { const s = ctx.createRadialGradient(40, 90, 0, 40, 90, 260); s.addColorStop(0, 'rgba(255,240,205,.85)'); s.addColorStop(1, 'rgba(255,240,205,0)'); ctx.fillStyle = s; ctx.fillRect(0, 0, W, H); }
  else { for (const st of stars) { ctx.globalAlpha = 0.35 + 0.65 * Math.abs(Math.sin(t / 1400 + st.ph)); ellipse(ctx, st.x, st.y, st.r, st.r, '#FFF1D6'); } ctx.globalAlpha = 1; ball(ctx, 58, 120, 17, '#FFF8E8', '#F4E3C0', 0.2); }
  const sick = S.health < 25 ? (25 - S.health) / 20 : 0;
  if (sick > 0) { ctx.fillStyle = `rgba(196,190,198,${0.45 * Math.min(1, sick)})`; ctx.fillRect(0, 0, W, H); }
  for (const c of clouds) cloud(ctx, ((c.x + t / 1000 * c.sp) % 480) - 40, c.y - (cam.s - 1) * 8, c.r, S.night ? 0.13 : 0.85);
}
function drawSea(t) {
  const base = H - 120 + (cam.s - 1.2) * 12;
  for (let i = 0; i < 14; i++) { const x = ((i * 47 + t / 220) % 520) - 60, y = base + (i % 3) * 16 + Math.sin(t / 2400 + i) * 2; ball(ctx, x, y, 34 + (i % 4) * 9, S.night ? '#4A4282' : '#FFFFFF', S.night ? '#352E66' : '#E7DEEE', 0.3); }
  ctx.fillStyle = S.night ? '#2E2858' : '#EFE6F3'; ctx.fillRect(0, base + 30, W, H);
}

// ---------------------------------------------------------------- the diorama (world space, fixed camera)
function islandBody(c, cx, cy, rx, ry, depth, door = false) {
  // earth body
  c.beginPath(); c.moveTo(cx - rx, cy);
  c.bezierCurveTo(cx - rx * 0.9, cy + depth * 0.7, cx - rx * 0.25, cy + depth, cx + rx * 0.05, cy + depth);
  c.bezierCurveTo(cx + rx * 0.4, cy + depth * 0.95, cx + rx * 0.92, cy + depth * 0.6, cx + rx, cy);
  c.closePath(); c.fillStyle = lin(c, cx - rx, cy, cx + rx * 0.4, cy + depth, '#D9A06B', '#94603F'); c.fill();
  c.save(); c.clip();
  for (let i = 1; i < 5; i++) { c.strokeStyle = `rgba(255,226,190,${0.12 + (i % 2) * 0.05})`; c.lineWidth = 1.2; c.beginPath(); c.ellipse(cx, cy + i * depth * 0.17, rx * (1 - i * 0.12), ry * 0.6, 0, 0.1, Math.PI - 0.1); c.stroke(); }
  for (let i = 0; i < 7; i++) ball(c, cx - rx * 0.6 + ((i * 37) % (rx * 1.2)), cy + 12 + ((i * 23) % (depth * 0.6)), 1.6 + (i % 3) * 0.6, '#FBEBDD', '#D9BFA6');
  c.restore();
  c.strokeStyle = '#8A5A3A'; c.lineCap = 'round';
  for (let i = 0; i < 3; i++) { const x = cx - 6 + i * 6; c.lineWidth = 1.2 - i * 0.2; c.beginPath(); c.moveTo(x, cy + depth - 2); c.bezierCurveTo(x - 3, cy + depth + 8, x + 3, cy + depth + 12, x + 1, cy + depth + 18 + i * 3); c.stroke(); }
  if (door) {
    const dx = cx - rx * 0.52, dy = cy + ry * 0.75 + 16;
    c.beginPath(); c.moveTo(dx - 7, dy); c.lineTo(dx - 7, dy - 9); c.arc(dx, dy - 9, 7, Math.PI, 0); c.lineTo(dx + 7, dy); c.closePath(); c.fillStyle = '#8A5A3A'; c.fill();
    c.beginPath(); c.moveTo(dx - 5.4, dy); c.lineTo(dx - 5.4, dy - 9); c.arc(dx, dy - 9, 5.4, Math.PI, 0); c.lineTo(dx + 5.4, dy); c.closePath(); c.fillStyle = '#C98B5A'; c.fill();
    ellipse(c, dx, dy - 10, 2.2, 2.2, S.night ? '#F7D27A' : '#F3E3C4');
    c.fillStyle = '#E8C9A2'; c.fillRect(dx - 8, dy, 16, 1.8);
  }
  // lawn
  c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2); c.fillStyle = lin(c, cx - rx, cy - ry, cx + rx * 0.5, cy + ry, '#DCEFB9', '#79B577'); c.fill();
  c.save(); c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2); c.clip();
  for (let i = 0; i < rx * 0.5; i++) { const a = i * 2.39996, r = Math.sqrt(i / (rx * 0.5)); const x = cx + Math.cos(a) * r * rx * 0.95, y = cy + Math.sin(a) * r * ry * 0.9; c.strokeStyle = 'rgba(80,140,85,.38)'; c.lineWidth = 0.55; c.beginPath(); c.moveTo(x, y); c.lineTo(x - 0.6, y - 2.2); c.moveTo(x + 1.2, y); c.lineTo(x + 1.6, y - 2); c.stroke(); }
  c.restore();
  // grass lip along the front
  c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0.02, Math.PI - 0.02); c.lineWidth = 3.2; c.strokeStyle = '#5E9E6A'; c.stroke();
  for (let a = 0.15; a < Math.PI - 0.1; a += 0.13) ellipse(c, cx + Math.cos(a) * rx, cy + Math.sin(a) * ry + 2, 2.6, 1.9, a * 10 % 2 > 1 ? '#6BAA70' : '#5A9864');
}
function terrace(c, t) { // stage 4+: a raised back hill
  const cx = 0, cy = -66, rx = 132, ry = 34, h = 26;
  c.beginPath(); c.ellipse(cx, cy + h, rx, ry, 0, 0, Math.PI); c.lineTo(cx - rx, cy); c.ellipse(cx, cy, rx, ry, 0, Math.PI, 0, true); c.closePath();
  c.fillStyle = lin(c, cx - rx, cy, cx + rx, cy + h, '#E1A873', '#A86C45'); c.fill();
  c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2); c.fillStyle = lin(c, cx - rx, cy - ry, cx + rx, cy + ry, '#E3F2C4', '#86BE7F'); c.fill();
  c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0.05, Math.PI - 0.05); c.lineWidth = 2.6; c.strokeStyle = '#5E9E6A'; c.stroke();
  // steps up to the terrace
  for (let i = 0; i < 4; i++) rrect(c, -122 + i * 2.5, cy + ry * 0.55 + h - 4 - i * 6.5, 18 - i, 4, 2, i % 2 ? '#F3E6D6' : '#E9D7C2');
}
function islet(c, cx, cy, rx, t) { islandBody(c, cx, cy + Math.sin(t / 1700 + cx) * 2, rx, rx * 0.36, rx * 0.8); }
function bridge(c, a, b) {
  const sag = (q) => Math.sin(q * Math.PI) * 8;
  c.strokeStyle = '#B08A66'; c.lineWidth = 0.9;
  for (const off of [-9, -1]) { c.beginPath(); for (let i = 0; i <= 20; i++) { const q = i / 20; const x = a.x + (b.x - a.x) * q, y = a.y + (b.y - a.y) * q + sag(q) + off; i ? c.lineTo(x, y) : c.moveTo(x, y); } c.stroke(); }
  for (let i = 0; i < 8; i++) { const q = (i + 0.5) / 8; const x = a.x + (b.x - a.x) * q, y = a.y + (b.y - a.y) * q + sag(q); rrect(c, x - 3, y - 2, 6, 4, 1.2, i % 2 ? '#E2A86C' : '#C98B5A'); }
}

// stations ------------------------------------------------------------
function sunflower(c, x, y, h, t, k = 1) {
  stem(c, x, y, x, y - h, 1.3 * k); leaf(c, x, y - h * 0.4, 6 * k, -2.6); leaf(c, x, y - h * 0.55, 6 * k, -0.5);
  c.save(); c.translate(x, y - h); c.rotate(Math.sin(t / 1200 + x) * 0.06);
  for (let i = 0; i < 12; i++) { c.save(); c.rotate(i * Math.PI / 6); ellipse(c, 0, -4.2 * k, 1.6 * k, 3.2 * k, i % 2 ? '#FFD45E' : '#F7C13D'); c.restore(); }
  ball(c, 0, 0, 2.8 * k, '#9A6440', '#5E3A26'); c.restore();
}
function awning(c, x, y, w, col) { for (let i = 0; i < 6; i++) { c.fillStyle = i % 2 ? '#FFF8EE' : col; c.beginPath(); const x0 = x - w / 2 + i * w / 6; c.moveTo(x0, y); c.lineTo(x0 + w / 6, y); c.lineTo(x0 + w / 6, y + 7); c.quadraticCurveTo(x0 + w / 12, y + 10, x0, y + 7); c.fill(); } }
function lights(c, x0, x1, y, t) { c.strokeStyle = 'rgba(120,90,60,.6)'; c.lineWidth = 0.5; c.beginPath(); c.moveTo(x0, y); c.quadraticCurveTo((x0 + x1) / 2, y + 6, x1, y); c.stroke(); for (let i = 1; i < 6; i++) { const q = i / 6; const x = x0 + (x1 - x0) * q, yy = y + Math.sin(q * Math.PI) * 4.5; ball(c, x, yy + 1, 1.3, '#FFF3C4', i % 2 ? '#F5B83D' : '#F48C9A'); } }
function flag(c, x, y, col) { c.strokeStyle = '#8A5A3A'; c.lineWidth = 0.8; c.beginPath(); c.moveTo(x, y); c.lineTo(x, y - 12); c.stroke(); c.beginPath(); c.moveTo(x, y - 12); c.lineTo(x + 7, y - 10); c.lineTo(x, y - 8); c.fillStyle = col; c.fill(); }
function simitRing(c, x, y, r = 3) { c.beginPath(); c.ellipse(x, y, r, r * 0.6, 0, 0, Math.PI * 2); c.lineWidth = r * 0.7; c.strokeStyle = '#C98635'; c.stroke(); for (let i = 0; i < 5; i++) { const a = i * 1.3; ellipse(c, x + Math.cos(a) * r, y + Math.sin(a) * r * 0.6 - 0.3, 0.35, 0.25, '#FFF3E0'); } }
function dome(c, x, y, r, a, b) { c.beginPath(); c.moveTo(x - r, y); c.quadraticCurveTo(x - r, y - r * 1.15, x, y - r * 1.2); c.quadraticCurveTo(x + r, y - r * 1.15, x + r, y); c.closePath(); c.fillStyle = lin(c, x - r, y - r, x + r, y, a, b); c.fill(); }
function wall(c, x, y, w, h, a = '#FFF8EE', b = '#DCC4AA') { c.fillStyle = lin(c, x - w / 2, y - h, x + w / 2, y, a, b); c.fillRect(x - w / 2, y - h, w, h); }

const DRAW = {
  garden(c, L, t) {
    ellipse(c, 0, 0, 34, 10, '#B98A63'); ellipse(c, 0, -0.8, 31, 8.5, '#C99A70');
    const n = [3, 5, 6, 7, 8][L - 1];
    if (L >= 4) { c.strokeStyle = '#B08A66'; c.lineWidth = 2; c.beginPath(); c.arc(0, -10, 30, Math.PI * 1.05, Math.PI * 1.95); c.stroke(); for (let i = 0; i < 7; i++) { const a = Math.PI * (1.12 + i * 0.12); c.fillStyle = ['#F48C9A', '#F5B83D', '#8FD3E0'][i % 3]; c.beginPath(); c.moveTo(Math.cos(a) * 30, -10 + Math.sin(a) * 30); c.lineTo(Math.cos(a) * 30 + 2.5, -10 + Math.sin(a) * 30 + 5); c.lineTo(Math.cos(a) * 30 + 5, -10 + Math.sin(a) * 30); c.fill(); } }
    if (L >= 5) sunflower(c, 0, -2, 40, t, 1.7);
    for (let i = 0; i < n; i++) { const x = -26 + i * (52 / (n - 1 || 1)); if (L >= 5 && Math.abs(x) < 8) continue; sunflower(c, x, (i % 2) * 3, 17 + ((i * 5) % 7), t); }
    if (L >= 2) for (let i = -3; i <= 3; i++) { const x = i * 10; rrect(c, x - 1.2, 2, 2.4, 9, 1, '#FFF8EE'); } if (L >= 2) { c.fillStyle = '#F1E3D2'; c.fillRect(-31, 5, 62, 1.5); }
    if (L >= 3) { rrect(c, 30, -2, 9, 7, 2, '#8FB8D8'); c.strokeStyle = '#6C93B5'; c.lineWidth = 1.2; c.beginPath(); c.moveTo(39, 0); c.lineTo(44, -4); c.stroke(); }
  },
  cay(c, L, t) {
    const v = S.variant.cay === 'blue';
    if (L >= 3) { for (const x of [-30, 30]) { rrect(c, x - 4, -8, 8, 3, 1.5, v ? '#7EA6D8' : '#E98A97'); c.fillStyle = '#B87650'; c.fillRect(x - 3, -5, 1.4, 6); c.fillRect(x + 1.6, -5, 1.4, 6); } }
    if (L >= 2 && L < 5) { c.fillStyle = '#B87650'; c.fillRect(-24, -40, 2, 40); c.fillRect(22, -40, 2, 40); awning(c, 0, -44, 52, v ? '#7EA6D8' : '#E9696F'); }
    if (L >= 5) { c.fillStyle = '#B87650'; c.fillRect(-24, -40, 2, 40); c.fillRect(22, -40, 2, 40); c.beginPath(); c.moveTo(-30, -38); c.lineTo(0, -54); c.lineTo(30, -38); c.closePath(); c.fillStyle = lin(c, -30, -54, 30, -38, '#E98A6A', '#B85A3E'); c.fill(); flag(c, 0, -54, '#E9696F'); ball(c, 26, -2, 4, '#F48C9A', '#D9606E'); }
    if (L >= 4) lights(c, -23, 23, -38, t);
    rrect(c, -18, -16, 36, 16, 3, lin(c, -18, -16, 18, 0, WOOD[0], WOOD[1])); rrect(c, -20, -18, 40, 4, 2, '#F2C995');
    ball(c, -6, -23, 5, '#F0B27A', '#B8703E'); ball(c, -6, -29.5, 3.3, '#F0B27A', '#B8703E'); rrect(c, -7, -34.5, 2, 2.2, 1, '#8A5A3A');
    for (const x of [6, 12]) { c.fillStyle = 'rgba(255,255,255,.55)'; c.beginPath(); c.moveTo(x - 2, -26); c.quadraticCurveTo(x - 0.5, -22, x - 1.6, -18); c.lineTo(x + 1.6, -18); c.quadraticCurveTo(x + 0.5, -22, x + 2, -26); c.fill(); ellipse(c, x, -21, 1.4, 2.5, '#C0392B'); ellipse(c, x, -17.6, 2.2, 0.6, '#FFF8EE'); }
    if (t % 3000 < 1800) { c.globalAlpha = 0.5; ball(c, -6 + Math.sin(t / 500) * 1.5, -40 - (t % 1800) / 120, 2.2, '#FFFFFF', '#EEE'); c.globalAlpha = 1; }
  },
  simit(c, L, t) {
    if (L >= 4) { rrect(c, 22, -7, 22, 3, 1.5, '#E2A86C'); c.fillStyle = '#B87650'; c.fillRect(24, -4, 2, 5); c.fillRect(40, -4, 2, 5); }
    if (L >= 2 && L < 5) { c.fillStyle = '#8A5A3A'; c.fillRect(-1, -46, 1.6, 30); c.beginPath(); c.moveTo(-24, -42); c.quadraticCurveTo(0, -58, 24, -42); c.closePath(); c.fillStyle = lin(c, -24, -56, 24, -42, '#FFE08A', '#F0A93A'); c.fill(); }
    if (L >= 5) { c.fillStyle = '#B87650'; c.fillRect(-22, -42, 2, 32); c.fillRect(20, -42, 2, 32); c.beginPath(); c.moveTo(-28, -40); c.lineTo(0, -54); c.lineTo(28, -40); c.closePath(); c.fillStyle = lin(c, -28, -54, 28, -40, '#F7C873', '#C98635'); c.fill(); flag(c, 0, -54, '#E9696F'); }
    if (L >= 4) lights(c, -20, 20, -38, t);
    rrect(c, -18, -18, 36, 12, 3, lin(c, -18, -18, 18, -6, '#E98A6A', '#B85A3E'));
    for (const x of [-12, 12]) { ellipse(c, x, -4, 5, 5, '#8A5A3A'); ellipse(c, x, -4, 3.4, 3.4, '#C98B5A'); }
    for (let i = 0; i < 4 + L; i++) simitRing(c, -12 + (i % 5) * 6, -20 - Math.floor(i / 5) * 3.5);
    if (L >= 3) { c.fillStyle = '#8A5A3A'; c.fillRect(19, -36, 1.6, 30); for (let i = 0; i < 6; i++) simitRing(c, 20, -12 - i * 4, 3.2); }
  },
  pond(c, L, t) {
    const r = [24, 26, 30, 32, 34][L - 1];
    for (let i = 0; i < 14; i++) { const a = i / 14 * Math.PI * 2; ball(c, Math.cos(a) * r, Math.sin(a) * r * 0.36 - 3, 2.8 + (i % 3), '#F6EBDD', '#CDB8A2'); }
    ellipse(c, 0, -3, r - 1, (r - 1) * 0.34, lin(c, -r, -10, r, 8, '#BFE6EE', '#6FB3C6')); ellipse(c, -r * 0.3, -5, r * 0.35, 1.6, 'rgba(255,255,255,.4)');
    if (L >= 2) for (let i = 0; i < 2 + L; i++) { const x = -r * 0.6 + i * (r * 1.2 / (1 + L)), y = -3 + (i % 2 ? 2 : -2); ellipse(c, x, y, 3.6, 1.6, '#7CC17A'); if (i === 1) ball(c, x, y - 1.2, 1.5, '#FFE3EA', '#F4A9BB'); }
    if (L >= 3) for (let i = 0; i < 4; i++) { c.strokeStyle = '#5E9E6A'; c.lineWidth = 1; c.beginPath(); c.moveTo(r - 4 + i * 1.6, -2); c.lineTo(r - 3 + i * 2, -16 - (i % 2) * 4); c.stroke(); ellipse(c, r - 3 + i * 2, -15 - (i % 2) * 4, 0.9, 2.4, '#8A5A3A'); }
    if (L >= 4) { rrect(c, -r - 6, -6, 16, 5, 1.5, '#D99E62'); c.fillStyle = '#B87650'; c.fillRect(-r - 4, -1, 1.5, 5); }
    if (L >= 5) for (let i = 0; i < 3; i++) { const x = -8 + i * 9, y = -4 + Math.sin(t / 900 + i) * 0.8; ball(c, x, y - 2, 2, '#FFF1C8', '#F5B83D'); }
  },
  library(c, L, t) {
    const h = L >= 3 ? 44 : 30;
    wall(c, 0, 0, 40, h, '#FFF8EE', '#DCC4AA');
    for (let i = 0; i < 4; i++) rrect(c, -16 + i * 8, -9, 6, 8, 1, ['#8F74F0', '#E98A97', '#7EA6D8', '#F5B83D'][i]);
    rrect(c, -4, -h + 6, 8, 9, 4, L >= 2 ? '#FFE7A8' : '#DDEFF5');
    if (L >= 3) rrect(c, -14, -h + 20, 7, 8, 3.5, '#DDEFF5');
    dome(c, 0, -h, 24, '#B9A2FF', '#6C4FD8');
    if (L >= 2) for (let i = 0; i < 3; i++) rrect(c, 22, -4 - i * 3, 9, 3, 1, ['#E98A97', '#7EA6D8', '#F5B83D'][i]);
    if (L >= 4) { rrect(c, -40, -6, 18, 3, 1.5, '#E2A86C'); ball(c, -44, -18, 3, '#FFF1C8', '#F5B83D'); c.fillStyle = '#8A5A3A'; c.fillRect(-44.6, -15, 1.2, 15); }
    if (L >= 5) { wall(c, 14, -h + 4, 10, 18, '#FFF8EE', '#DCC4AA'); dome(c, 14, -h - 14, 7, '#B9A2FF', '#6C4FD8'); flag(c, 14, -h - 22, '#F5B83D'); }
  },
  workshop(c, L, t) {
    wall(c, 0, 0, 42, 24, '#EDBE86', '#B87650');
    c.beginPath(); c.moveTo(-26, -22); c.lineTo(6, -38); c.lineTo(26, -24); c.lineTo(26, -20); c.lineTo(-26, -20); c.closePath(); c.fillStyle = lin(c, -26, -38, 26, -20, '#9AD4C0', '#4F8F7E'); c.fill();
    rrect(c, -6, -16, 12, 16, 2, '#8A5A3A'); rrect(c, 10, -16, 9, 7, 2, '#DDEFF5');
    rrect(c, -40, -9, 14, 3, 1, '#C98B5A'); c.fillStyle = '#8A5A3A'; c.fillRect(-38, -6, 1.5, 6); c.fillRect(-29, -6, 1.5, 6);
    if (L >= 2) { c.strokeStyle = '#8E7D88'; c.lineWidth = 1.2; for (let i = 0; i < 3; i++) { c.beginPath(); c.moveTo(-18 + i * 4, -18); c.lineTo(-18 + i * 4, -10); c.stroke(); } }
    if (L >= 3) { c.save(); c.translate(-22, -40); c.rotate(t / 700); for (let i = 0; i < 4; i++) { c.rotate(Math.PI / 2); c.fillStyle = '#F5B83D'; c.fillRect(-1, 1, 2, 8); } c.restore(); c.fillStyle = '#8A5A3A'; c.fillRect(-22.6, -40, 1.2, 18); }
    if (L >= 4) { rrect(c, 14, -42, 6, 14, 1, '#B87650'); c.globalAlpha = 0.45; ball(c, 17 + Math.sin(t / 700) * 2, -48 - (t % 2000) / 200, 3, '#FFFFFF', '#E8E2EA'); c.globalAlpha = 1; }
    if (L >= 5) { c.save(); c.translate(32, -34); c.rotate(-t / 1500); c.fillStyle = '#F5B83D'; for (let i = 0; i < 8; i++) { c.rotate(Math.PI / 4); c.fillRect(-1.5, 5, 3, 3); } ellipse(c, 0, 0, 6, 6, '#F5B83D'); ellipse(c, 0, 0, 2.5, 2.5, '#B87650'); c.restore(); }
  },
  observatory(c, L, t) {
    wall(c, 0, 0, 34, 20); dome(c, 0, -20, 19, '#EDE8F4', '#9C8FB8');
    c.fillStyle = '#2A2236'; c.fillRect(-3, -40, 6, 14);
    if (L >= 2) { c.save(); c.translate(0, -34); c.rotate(-0.7); rrect(c, -3, -16, 6, 16, 2, '#F5B83D'); c.restore(); }
    if (L >= 4) { wall(c, -24, 0, 14, 12); dome(c, -24, -12, 8, '#EDE8F4', '#9C8FB8'); }
    if (L >= 5) ball(c, 20, -30, 3, '#FFF1C8', '#F5B83D');
    for (let i = 0; i < L; i++) sparkle(c, -18 + i * 9, -50 - (i % 2) * 6, 2, 0.5 + 0.5 * Math.sin(t / 500 + i));
  },
  hamam(c, L, t) {
    wall(c, 0, 0, 44, 18, '#FFF8EE', '#DCC4AA'); dome(c, 0, -18, 22, '#FFFFFF', '#C9C3D6');
    for (let i = 0; i < 3; i++) rrect(c, -14 + i * 11, -14, 6, 9, 3, '#8FD3E0');
    if (L >= 3) { dome(c, -24, -8, 7, '#FFFFFF', '#C9C3D6'); dome(c, 24, -8, 7, '#FFFFFF', '#C9C3D6'); }
    for (let i = 0; i < 1 + L; i++) { c.globalAlpha = 0.35; ball(c, -10 + i * 6 + Math.sin(t / 800 + i) * 2, -44 - ((t / 40 + i * 30) % 20), 3.4, '#FFFFFF', '#EEE'); c.globalAlpha = 1; }
  },
};
function plot(c, st, t, open) {
  c.setLineDash([3, 3]); c.lineWidth = 1; c.strokeStyle = open ? 'rgba(108,79,216,.7)' : 'rgba(90,70,60,.35)';
  c.beginPath(); c.ellipse(0, 0, 26, 8, 0, 0, Math.PI * 2); c.stroke(); c.setLineDash([]);
  c.fillStyle = '#B87650'; c.fillRect(-1, -16, 2, 16); rrect(c, -9, -20, 18, 8, 2, open ? '#F2C995' : '#E3CDB6');
  if (open) { sparkle(c, 14, -22, 3, 0.6 + 0.4 * Math.sin(t / 300)); sparkle(c, -16, -10, 2, 0.6 + 0.4 * Math.cos(t / 400)); }
}

// residents (stand-ins except Mochi)
function critter(c, kind, x, y, t, k = 1) {
  const b = Math.sin(t / 700 + x) * 0.8;
  c.save(); c.translate(x, y); c.scale(k, k);
  softShadow(c, 0, 0.5, 7, 2.2, 0.25);
  if (kind === 'bunny' && bunnyImg.complete) { const w = 20, h = w * bunnyImg.height / bunnyImg.width; c.drawImage(bunnyImg, -w / 2, -h + 1 + b * 0.5, w, h); c.restore(); return; }
  const col = { kitten: ['#FFD9A8', '#E9A35A'], chin: ['#FBF7F2', '#CFC6CF'], hog: ['#F6DCC0', '#B98A63'] }[kind];
  if (kind === 'hog') { c.fillStyle = '#8A5A3A'; for (let i = 0; i < 9; i++) { const a = Math.PI * (1.05 + i * 0.1); c.beginPath(); c.moveTo(Math.cos(a) * 6, -6 + Math.sin(a) * 6 + b); c.lineTo(Math.cos(a) * 9.5, -6 + Math.sin(a) * 9.5 + b); c.lineTo(Math.cos(a + 0.12) * 6, -6 + Math.sin(a + 0.12) * 6 + b); c.fill(); } }
  if (kind === 'kitten') for (const s of [-1, 1]) { c.beginPath(); c.moveTo(s * 2.5, -11 + b); c.lineTo(s * 5.5, -15 + b); c.lineTo(s * 6, -9 + b); c.fillStyle = col[1]; c.fill(); }
  if (kind === 'chin') for (const s of [-1, 1]) ball(c, s * 5, -12 + b, 3.4, '#FBF7F2', '#D9CFD6');
  ball(c, 0, -6 + b, 7, col[0], col[1], 0.3);
  if (kind === 'kitten') { c.strokeStyle = 'rgba(200,120,50,.6)'; c.lineWidth = 0.8; for (let i = -1; i <= 1; i++) { c.beginPath(); c.moveTo(i * 2.2, -12.5 + b); c.lineTo(i * 2.2, -10 + b); c.stroke(); } }
  for (const s of [-1, 1]) { ellipse(c, s * 2.4, -6.5 + b, 1.1, 1.3, '#2B1A14'); ellipse(c, s * 2.4 - 0.3, -7 + b, 0.35, 0.35, '#fff'); ellipse(c, s * 3.6, -4.6 + b, 1.2, 0.7, 'rgba(253,193,176,.8)'); }
  ellipse(c, 0, -5.2 + b, 0.6, 0.45, '#F48C9A');
  c.restore();
}

// ---------------------------------------------------------------- Pofu and his faces (code stand-ins for the face edits)
const EYE = [[0.339, 0.44], [0.675, 0.44]], MOUTH = [0.509, 0.515], CHEEK = [[0.27, 0.56], [0.75, 0.56]];
const FUR = '#FCF4EC';
function emotionNow() { return S.emotion && now() < S.emotion.until ? S.emotion.kind : baseEmotion(); }
function baseEmotion() { if (S.night) return 'sleepy'; if (S.health < 25) return 'unwell'; if (S.calm >= CALM_MAX) return 'smug'; return null; }
function emote(kind, ms = 4200) { S.emotion = { kind, until: now() + ms, t0: now() }; }
function drawPofuAt(c, x, y, w, t, kind) {
  if (!pofuImg.complete) return;
  const h = w * pofuImg.height / pofuImg.width;
  const br = kind === 'breathe' ? breathPhase : Math.sin(t / 3200 * Math.PI * 2);
  const e0 = S.emotion ? (t - S.emotion.t0) / 1000 : 9;
  const amp = kind === 'breathe' ? 3.2 : 1;
  let sx = 1 + 0.012 * amp * br, sy = 1 + 0.022 * amp * br, rot = 0, dx = 0, dy = 0;
  if (kind === 'pout') { sy *= 0.97; sx *= 1.03; rot = 0.05; }
  if (kind === 'jealous') { rot = -0.07; dx = -w * 0.03; }
  if (kind === 'smug') { rot = -0.04; sy *= 1.02; }
  if (kind === 'worried') { dx = Math.sin(t / 60) * w * 0.006; }
  if (kind === 'unwell') { sy *= 0.9; sx *= 1.04; }
  if (kind === 'excited' || kind === 'proud') { dy = -Math.abs(Math.sin(e0 * 6)) * w * 0.12 * Math.max(0, 1 - e0 / 1.6); }
  if (kind === 'relieved') { sy *= 1 + 0.03 * Math.max(0, 1 - e0); }
  softShadow(c, x, y + 1, w * 0.4, w * 0.12, 0.3);
  c.save(); c.translate(x + dx, y + dy); c.rotate(rot); c.scale(sx, sy);
  const X = (u) => -w / 2 + u * w, Y = (v) => -h * 0.985 + v * h;
  c.drawImage(pofuVariant(S.night ? 'night' : kind === 'unwell' ? 'unwell' : null), -w / 2, -h * 0.985, w, h);
  const er = w * 0.072, ery = h * 0.078;
  const cover = (u, v, rx, ry) => { const g = c.createRadialGradient(X(u), Y(v), 0, X(u), Y(v), rx * 1.25); g.addColorStop(0, FUR); g.addColorStop(0.8, FUR); g.addColorStop(1, 'rgba(252,244,236,0)'); c.save(); c.translate(X(u), Y(v)); c.scale(1, ry / rx); c.translate(-X(u), -Y(v)); ellipse(c, X(u), Y(v), rx * 1.25, rx * 1.25, g); c.restore(); };
  const ink = (lw = w * 0.018) => { c.strokeStyle = '#4A2E24'; c.lineWidth = lw; c.lineCap = 'round'; };
  const lid = (u, v, frac, slant = 0) => { // fur covers the top `frac` of the eye, flat or slanted lid line
    c.save(); c.beginPath(); c.ellipse(X(u), Y(v), er * 1.08, ery * 1.08, 0, 0, Math.PI * 2); c.clip();
    const yc = Y(v) - ery + frac * 2 * ery;
    c.beginPath(); c.moveTo(X(u) - er * 1.3, yc + slant * er); c.lineTo(X(u) + er * 1.3, yc - slant * er); c.lineTo(X(u) + er * 1.3, Y(v) - ery * 1.5); c.lineTo(X(u) - er * 1.3, Y(v) - ery * 1.5); c.closePath(); c.fillStyle = FUR; c.fill();
    ink(w * 0.016); c.beginPath(); c.moveTo(X(u) - er * 1.05, yc + slant * er * 0.9 + 0.2); c.lineTo(X(u) + er * 1.05, yc - slant * er * 0.9 + 0.2); c.stroke(); c.restore();
  };
  const closed = (u, v, up) => { cover(u, v, er * 1.1, ery * 1.1); ink(); c.beginPath(); if (up) c.arc(X(u), Y(v) + ery * 0.35, er * 0.7, Math.PI * 1.15, Math.PI * 1.85); else c.arc(X(u), Y(v) - ery * 0.3, er * 0.7, Math.PI * 0.15, Math.PI * 0.85); c.stroke(); };
  const mouth = (fn) => { cover(MOUTH[0], MOUTH[1] + 0.008, w * 0.055, h * 0.03); ink(w * 0.013); c.beginPath(); fn(X(MOUTH[0]), Y(MOUTH[1]) + h * 0.004, w * 0.03); c.stroke(); };
  const puff = (side) => { const [u, v] = CHEEK[side]; c.save(); c.beginPath(); c.ellipse(X(u), Y(v), w * 0.13, h * 0.1, 0, 0, Math.PI * 2); c.clip(); c.translate(X(u), Y(v)); c.scale(1.16, 1.16); c.translate(-X(u), -Y(v)); c.drawImage(pofuImg, -w / 2, -h * 0.985, w, h); c.restore(); };
  if (kind === 'sleepy' || kind === 'unwell' || kind === 'breathe') { closed(...EYE[0], false); closed(...EYE[1], false); if (kind === 'unwell') mouth((mx, my, m) => { c.moveTo(mx - m, my + m * 0.2); c.quadraticCurveTo(mx - m * 0.5, my - m * 0.3, mx, my + m * 0.1); c.quadraticCurveTo(mx + m * 0.5, my + m * 0.4, mx + m, my - m * 0.1); }); }
  if (kind === 'proud' || kind === 'excited' || kind === 'relieved') { closed(...EYE[0], true); closed(...EYE[1], true); if (kind === 'excited') { cover(MOUTH[0], MOUTH[1] + 0.01, w * 0.05, h * 0.03); ellipse(c, X(MOUTH[0]), Y(MOUTH[1]) + h * 0.012, w * 0.026, h * 0.022, '#7A3B36'); ellipse(c, X(MOUTH[0]), Y(MOUTH[1]) + h * 0.022, w * 0.016, h * 0.009, '#F48C9A'); } }
  if (kind === 'smug') { lid(...EYE[0], 0.5, 0.15); lid(...EYE[1], 0.5, -0.15); mouth((mx, my, m) => { c.moveTo(mx - m * 0.9, my); c.quadraticCurveTo(mx, my + m * 0.35, mx + m, my - m * 0.45); }); }
  if (kind === 'jealous') { lid(...EYE[0], 0.55, -0.25); lid(...EYE[1], 0.55, 0.25); mouth((mx, my, m) => { c.moveTo(mx - m * 0.8, my + m * 0.1); c.lineTo(mx + m * 0.8, my - m * 0.05); }); }
  if (kind === 'pout') { puff(0); puff(1); lid(...EYE[0], 0.32, -0.2); lid(...EYE[1], 0.32, 0.2); mouth((mx, my, m) => { c.moveTo(mx - m * 0.5, my + m * 0.25); c.quadraticCurveTo(mx, my - m * 0.45, mx + m * 0.5, my + m * 0.25); }); }
  if (kind === 'worried') { mouth((mx, my, m) => { c.moveTo(mx - m, my + m * 0.15); c.quadraticCurveTo(mx - m * 0.5, my - m * 0.35, mx, my + m * 0.1); c.quadraticCurveTo(mx + m * 0.5, my + m * 0.45, mx + m, my); }); }
  c.restore();
  // marks around the head (world space)
  const hx = x + dx, hy = y + dy - h * 0.95;
  if (kind === 'jealous' || kind === 'pout') { c.save(); c.translate(hx + w * 0.36, hy + h * 0.12); c.strokeStyle = '#E9696F'; c.lineWidth = w * 0.025; c.lineCap = 'round'; for (let i = 0; i < 4; i++) { c.rotate(Math.PI / 2); c.beginPath(); c.arc(w * 0.05, w * 0.05, w * 0.035, Math.PI, Math.PI * 1.5); c.stroke(); } c.restore(); }
  if (kind === 'pout') for (let i = 0; i < 3; i++) { const p = ((t / 900) + i / 3) % 1; c.globalAlpha = 1 - p; ellipse(c, x - w * 0.36 - p * w * 0.2, y - h * 0.42 + i * 2, w * 0.03 * (1 + p), w * 0.022 * (1 + p), '#FFFFFF'); c.globalAlpha = 1; }
  if (kind === 'worried' || kind === 'unwell') { const sx2 = hx + w * 0.4, sy2 = hy + h * 0.2 + Math.sin(t / 400) * 1; c.beginPath(); c.moveTo(sx2, sy2 - w * 0.06); c.quadraticCurveTo(sx2 + w * 0.04, sy2, sx2, sy2 + w * 0.03); c.quadraticCurveTo(sx2 - w * 0.04, sy2, sx2, sy2 - w * 0.06); c.fillStyle = 'rgba(150,200,235,.9)'; c.fill(); }
  if (kind === 'smug') { sparkle(c, hx - w * 0.42, hy + h * 0.32, w * 0.06, 0.6 + 0.4 * Math.sin(t / 300)); sparkle(c, hx + w * 0.45, hy + h * 0.15, w * 0.045, 0.6 + 0.4 * Math.cos(t / 260)); }
  if (kind === 'proud' || kind === 'excited') for (let i = 0; i < 3; i++) sparkle(c, hx + (i - 1) * w * 0.42, hy + h * (0.05 + (i % 2) * 0.15), w * 0.05, 0.5 + 0.5 * Math.sin(t / 250 + i));
  if (kind === 'sleepy') for (let i = 0; i < 2; i++) { const ph = ((t / 2400) + i * 0.5) % 1; c.globalAlpha = 1 - ph; c.fillStyle = '#EDE6FF'; c.font = `800 ${w * (0.1 + i * 0.04)}px Nunito`; c.fillText('z', hx + w * 0.3 + ph * 6, hy + h * 0.1 - ph * 14); c.globalAlpha = 1; }
}

// ---------------------------------------------------------------- new station art (stand-ins)
Object.assign(DRAW, {
  windmill(c, L, t) {
    c.beginPath(); c.moveTo(-14, 0); c.lineTo(-10, -40); c.lineTo(10, -40); c.lineTo(14, 0); c.closePath(); c.fillStyle = lin(c, -14, -40, 14, 0, '#FFF3E2', '#D9BFA6'); c.fill();
    rrect(c, -4, -12, 8, 12, 4, '#B87650'); rrect(c, -3, -31, 6, 7, 3, L >= 4 ? '#FFE7A8' : '#DDEFF5');
    if (L >= 5) { rrect(c, -6, -23.5, 12, 3, 1.5, '#E9696F'); for (let i = 0; i < 3; i++) ball(c, -4 + i * 4, -24.5, 1.2, '#FFE3EA', '#F48C9A'); }
    if (L >= 3) for (let i = 0; i < 3; i++) { rrect(c, 15 + i * 6.5, -9 - (i === 1 ? 3 : 0), 6.5, 9, 3, '#EFE0CC'); ellipse(c, 18.2 + i * 6.5, -5 - (i === 1 ? 3 : 0), 1, 1.6, '#5B4636'); }
    c.beginPath(); c.moveTo(-13, -40); c.quadraticCurveTo(0, -57, 13, -40); c.closePath(); c.fillStyle = lin(c, -13, -55, 13, -40, '#E98A6A', '#B85A3E'); c.fill();
    if (L >= 4) lights(c, -12, 12, -41, t);
    if (L >= 5) flag(c, 0, -53, '#F5B83D');
    c.save(); c.translate(0, -45); c.rotate((S.night ? 0 : t / 2200) + 0.3);
    for (let i = 0; i < 4; i++) { c.rotate(Math.PI / 2); c.fillStyle = '#8A5A3A'; c.fillRect(-0.8, 0, 1.6, 31); if (L >= 2) rrect(c, 1.2, 7, 7, 22, 1.5, 'rgba(255,248,238,.96)'); else { c.strokeStyle = '#B08A66'; c.lineWidth = 0.8; c.strokeRect(1.2, 7, 7, 22); c.beginPath(); c.moveTo(1.2, 18); c.lineTo(8.2, 18); c.stroke(); } }
    ball(c, 0, 0, 2.6, '#C98B5A', '#8A5A3A'); c.restore();
  },
  pier(c, L, t) {
    for (const x of [-18, 8, 34, 56]) { c.fillStyle = '#8A5A3A'; c.fillRect(x, 1 + x * 0.04, 2.2, 13); }
    for (let i = 0; i < 9; i++) rrect(c, -24 + i * 9.4, -3 + i * 0.45, 8.6, 6, 1.6, i % 2 ? '#E2A86C' : '#C98B5A');
    if (L >= 2) { c.fillStyle = '#8A5A3A'; c.fillRect(56, -26, 1.8, 24); ball(c, 57, -28, 2.6, '#FFF1C8', '#F5B83D'); }
    if (L >= 3) { const y = 13 + Math.sin(t / 900) * 1.2; c.save(); c.translate(66, y); c.rotate(Math.sin(t / 1300) * 0.03);
      c.beginPath(); c.moveTo(-17, -6); c.lineTo(17, -6); c.quadraticCurveTo(15, 4, 8, 5); c.lineTo(-10, 5); c.quadraticCurveTo(-16, 3, -17, -6); c.fillStyle = lin(c, 0, -6, 0, 5, '#FFFFFF', '#E3DCE8'); c.fill();
      c.fillStyle = '#E9696F'; c.fillRect(-16, -2.4, 32, 2); rrect(c, -10, -13, 18, 7, 2, '#FFF8EE'); for (let i = 0; i < 3; i++) rrect(c, -8 + i * 5.5, -11.5, 3.5, 3, 1, '#8FD3E0');
      rrect(c, 2, -20, 4, 7, 1, '#E9696F'); c.fillStyle = '#2A2236'; c.fillRect(2, -20, 4, 1.6);
      c.globalAlpha = 0.45; ball(c, 4 + Math.sin(t / 600) * 1.5, -24 - (t % 1600) / 160, 2.2, '#FFFFFF', '#E8E2EA'); c.globalAlpha = 1; c.restore(); }
    if (L >= 4) { rrect(c, -18, -9, 16, 3, 1.5, '#E2A86C'); c.fillStyle = '#B87650'; c.fillRect(-16, -6, 1.4, 4); c.fillRect(-5, -6, 1.4, 4); for (const x of [0, 4]) ellipse(c, x, -6, 1.1, 2, '#C0392B'); }
    if (L >= 5) { c.strokeStyle = 'rgba(120,90,60,.6)'; c.lineWidth = 0.5; c.beginPath(); c.moveTo(-17, -16); c.quadraticCurveTo(20, -8, 57, -26); c.stroke(); for (let i = 1; i < 9; i++) { const q = i / 9, x = -17 + 74 * q, y = -16 + (-10) * q + Math.sin(q * Math.PI) * 6; c.fillStyle = ['#F48C9A', '#F5B83D', '#8FD3E0'][i % 3]; c.beginPath(); c.moveTo(x - 2, y); c.lineTo(x + 2, y); c.lineTo(x, y + 4); c.fill(); } }
  },
  lighthouse(c, L, t) {
    if (L >= 5) for (let i = 0; i < 5; i++) ball(c, -14 + i * 7, -1, 2, i % 2 ? '#FFE3EA' : '#FFF1C8', i % 2 ? '#F48C9A' : '#F5B83D');
    c.save(); c.beginPath(); c.moveTo(-9, 0); c.lineTo(-6, -50); c.lineTo(6, -50); c.lineTo(9, 0); c.closePath(); c.fillStyle = lin(c, -9, 0, 9, 0, '#FFFFFF', '#E3DCE8'); c.fill(); c.clip();
    c.fillStyle = '#E9696F'; for (const y of [-12, -30]) c.fillRect(-10, y - 7, 20, 7); c.restore();
    rrect(c, -3, -9, 6, 9, 3, '#8A5A3A');
    rrect(c, -7, -60, 14, 10, 3, L >= 2 ? '#FFE7A8' : '#DDEFF5'); dome(c, 0, -60, 7.5, '#E98A6A', '#B85A3E');
    if (L >= 3) { rrect(c, -10, -51.5, 20, 2.6, 1.2, '#8A5A3A'); c.strokeStyle = '#8A5A3A'; c.lineWidth = 0.6; for (let i = 0; i < 6; i++) { c.beginPath(); c.moveTo(-9 + i * 3.6, -51.5); c.lineTo(-9 + i * 3.6, -55); c.stroke(); } }
    if (L >= 5) flag(c, 0, -69, '#E9696F');
  },
});
const RESIDENT = { cay: ['bunny', 26, 8], workshop: ['hog', -30, 6], simit: ['kitten', 26, 6] };

// ---------------------------------------------------------------- state
let S;
function fresh() {
  S = {
    day: 1, tended: 0, stage: 0, health: 72, calm: 1.3, seeds: 0, pending: 34, levels: { garden: 1 }, variant: {},
    beads: [], night: false, mode: 'home', isle: 'home', msg: null, emotion: null, skipsHealed: 0, skipsPaid: 0, caughtUp: false,
    calmFlash: null, calmNote: null, used: 0, overOpens: 0, quickChain: false, calmNights: 0, arrived: { home: 1 }, visited: {}, postcards: 0,
    sheet: null, breath: null, popT: null, reveal: null,
  };
  for (const st of STATIONS) S.levels[st.id] ??= 0;
  say('Good morning! While you were away, the island gathered 34 seeds.', 'collect');
}
const lv = (id) => S.levels[id] || 0;
const stageFor = (t) => HOME_STAGES.reduce((s, need, i) => (t >= need ? i : s), 0);
const isOpen = (st) => (st.isle === 'home' ? st.gate <= S.stage : !!S.arrived[st.isle] && S.day - S.arrived[st.isle] >= st.gate);
const daysUntil = (st) => (st.isle === 'home' ? HOME_STAGES[st.gate] - S.tended : st.gate - (S.day - S.arrived[st.isle]));
const prodRate = () => STATIONS.reduce((s, st) => s + rate(st, lv(st.id)), 0) * (S.health < 25 ? 0.6 : 1);
const harborReady = () => S.tended >= 8 && lv('cay') >= 3;
const isleCount = () => Object.keys(S.arrived).length;
function mood() {
  const h = S.health;
  return h >= 75 ? 'Cozy' : h >= 50 ? 'Content' : h >= 25 ? 'Tired' : h >= 12 ? 'Unwell' : 'Curled up';
}
const over = () => S.used >= BREATH_LIMIT;

// ---------------------------------------------------------------- camera and layout
let cam = { x: 0, y: 0, s: HOME_S, ay: HOME_FEET };
let camFrom = null, camTo = null, camT0 = 0, camDur = 900;
function homeCam() { return { x: POFU.x, y: POFU.y, s: HOME_S, ay: HOME_FEET }; }
function isleCam(id = S.isle) {
  if (id !== 'home') { const p = isleById[id].pos; return { x: p[0] + 26, y: p[1] - 18, s: 1.42, ay: 410 }; }
  const st = S.stage;
  if (st <= 1) return { x: 0, y: -14, s: 1.5, ay: 400 };
  if (st === 2) return { x: 0, y: -20, s: 1.12, ay: 410 };
  return { x: 0, y: -40, s: 1.08, ay: 430 };
}
function mapCam() { return { x: 0, y: -70, s: 0.48, ay: 437 }; }
function camFor(mode) { return mode === 'home' ? homeCam() : mode === 'map' ? mapCam() : isleCam(); }
function moveCam(to, dur = 900) { camFrom = { ...cam }; camTo = to; camT0 = now(); camDur = dur; }
const camS = () => cam.s * FIT;
const camAY = () => cam.ay * H / REF_H;
const toScreen = (wx, wy) => [(wx - cam.x) * camS() + W / 2, (wy - cam.y) * camS() + camAY()];
const toWorld = (sx, sy) => [(sx - W / 2) / camS() + cam.x, (sy - camAY()) / camS() + cam.y];

const screenEl = document.getElementById('screen');
function layout() {
  const r = screenEl.getBoundingClientRect();
  W = Math.max(280, Math.round(r.width)) || REF_W; H = Math.max(420, Math.round(r.height)) || REF_H;
  FIT = Math.min(1.1, W / REF_W, H / REF_H);
  cvs.width = Math.round(W * DPR); cvs.height = Math.round(H * DPR);
  if (S) renderChrome();
}

// ---------------------------------------------------------------- other islands
// Canvas filters are very slow per frame (they took a phone-sized canvas from ~56 to ~2 fps in
// Chromium's software renderer), so anything graded is graded once and cached as an image.
const gradeCache = {};
function pofuVariant(v) {
  if (!v || !pofuImg.complete || !pofuImg.naturalWidth) return pofuImg;
  if (!gradeCache[v]) {
    const o = document.createElement('canvas'); o.width = pofuImg.naturalWidth; o.height = pofuImg.naturalHeight;
    const oc = o.getContext('2d'); oc.filter = v === 'unwell' ? 'saturate(.62) brightness(.97)' : 'brightness(.82) saturate(.85) hue-rotate(-8deg)';
    oc.drawImage(pofuImg, 0, 0); gradeCache[v] = o;
  }
  return gradeCache[v];
}
function lockedIsle(isle) {
  const key = 'isle:' + isle.id;
  if (gradeCache[key]) return gradeCache[key];
  const K = 3, rx = isle.rx, w = Math.ceil(2.4 * rx * K), h = Math.ceil(2.1 * rx * K);
  const raw = document.createElement('canvas'); raw.width = w; raw.height = h;
  const rc = raw.getContext('2d'); rc.setTransform(K, 0, 0, K, 1.2 * rx * K, rx * K);
  isleContent(rc, isle, 0, 0, 0, false);
  const o = document.createElement('canvas'); o.width = w; o.height = h;
  const oc = o.getContext('2d'); oc.filter = 'grayscale(.85) brightness(1.1)'; oc.drawImage(raw, 0, 0);
  return (gradeCache[key] = o);
}
function isleScene(c, isle, t, x, y) {
  const arrived = !!S.arrived[isle.id];
  const fa = focusAlpha(isle.id);
  if (fa < 1) { c.save(); c.globalAlpha = fa; }
  const bob = Math.sin(t / 1900 + isle.pos[0]) * 2;
  if (arrived) isleContent(c, isle, t, x, y + bob, true);
  else {
    const rx = isle.rx;
    c.save(); c.globalAlpha *= isle.season ? 0.42 : 0.6;
    c.drawImage(lockedIsle(isle), x - 1.2 * rx, y + bob - rx, 2.4 * rx, 2.1 * rx);
    c.restore();
    cloud(c, x - rx * 0.55, y + rx * 0.22 + bob, rx * 0.2, 0.75 * (fa < 1 ? fa : 1));
    cloud(c, x + rx * 0.6, y - rx * 0.02 + bob, rx * 0.17, 0.7 * (fa < 1 ? fa : 1));
  }
  if (fa < 1) c.restore();
}
function isleContent(c, isle, t, x, y, arrived) {
  const bob = 0;
  islandBody(c, x, y, isle.rx, isle.rx * 0.34, isle.rx * 0.82);
  const at = (sx, sy, f) => { c.save(); c.translate(x + sx, y + sy + bob); c.scale(1.3, 1.3); f(); c.restore(); };
  if (isle.id === 'harbor') {
    const list = STATIONS.filter((s) => s.isle === 'harbor').sort((a, b) => a.slot[1] - b.slot[1]);
    for (const s of list) {
      const L = arrived ? lv(s.id) : (s.id === 'pier' ? 0 : 1);
      at(s.slot[0], s.slot[1], () => {
        const pop = S.popT && S.popT.id === s.id ? (t - S.popT.t) / 700 : 2;
        if (pop < 1) { const k = 0.85 + 0.15 * pop + 0.12 * Math.sin(pop * Math.PI); c.scale(k, k); }
        softShadow(c, 0, 1, 30, 8, 0.18);
        if (L) DRAW[s.id](c, L, t); else plot(c, s, t, arrived && isOpen(s));
      });
      const r = RESIDENT[s.id];
      if (r && arrived && lv(s.id)) critter(c, r[0], x + s.slot[0] + r[1] * 1.3, y + s.slot[1] + r[2] + bob, t, 1.35);
    }
  } else if (isle.id === 'stars') { at(-24, -6, () => DRAW.observatory(c, 2, t)); at(40, 6, () => { for (let i = 0; i < 5; i++) ball(c, -14 + i * 7, -6 - (i % 2) * 5, 1.4, '#FFF6D0', '#F5B83D'); }); }
  else if (isle.id === 'hamam') { at(-10, -4, () => DRAW.hamam(c, 2, t)); at(46, 8, () => { ellipse(c, 0, 0, 16, 5, '#8FD3E0'); }); }
  else if (isle.id === 'library') { at(-14, -6, () => DRAW.library(c, 1, t)); at(42, 4, () => { stem(c, 0, 0, 0, -18, 2.2); ball(c, 0, -24, 11, '#9AD48A', '#5E9E6A'); }); }
}
// While one island is in view, the others recede, so the archipelago is felt but never clutters.
function focusAlpha(id) { return S.mode === 'isle' && S.isle !== id ? 0.35 : 1; }
function ferryRoute(c, t) {
  if (!S.arrived.harbor || S.mode !== 'map') return;
  const a = { x: 150, y: 70 }, b = isleById.harbor.pos, e = { x: b[0] - 70, y: b[1] - 4 };
  const ctl = { x: 210, y: 120 };
  c.save(); c.setLineDash([5, 7]); c.lineWidth = 2; c.strokeStyle = S.night ? 'rgba(255,255,255,.35)' : 'rgba(108,79,216,.35)';
  c.beginPath(); c.moveTo(a.x, a.y); c.quadraticCurveTo(ctl.x, ctl.y, e.x, e.y); c.stroke(); c.restore();
  if (S.mode !== 'map') return;
  const q = (Math.sin(t / 5200) + 1) / 2, u = 1 - q;
  const x = u * u * a.x + 2 * u * q * ctl.x + q * q * e.x, y = u * u * a.y + 2 * u * q * ctl.y + q * q * e.y;
  c.save(); c.translate(x, y + Math.sin(t / 700) * 1.5); c.scale(1.6, 1.6);
  c.beginPath(); c.moveTo(-10, -3); c.lineTo(10, -3); c.quadraticCurveTo(9, 3, 4, 3.5); c.lineTo(-6, 3.5); c.quadraticCurveTo(-9, 2, -10, -3); c.fillStyle = '#FFFFFF'; c.fill();
  c.fillStyle = '#E9696F'; c.fillRect(-9, -1, 18, 1.4); rrect(c, -5, -8, 10, 5, 1.5, '#FFF8EE'); rrect(c, 1, -12, 3, 4, 1, '#E9696F');
  c.restore();
}

// ---------------------------------------------------------------- render
let particles = [];
function burst(wx, wy, kind = 'sparkle', n = 10) { for (let i = 0; i < n; i++) particles.push({ x: wx, y: wy, vx: (Math.random() - 0.5) * 34, vy: -12 - Math.random() * 26, t0: now(), life: 900 + Math.random() * 600, kind }); }
function seedIcon(c, x, y, r, a = 1) { c.save(); c.globalAlpha = Math.max(0, a); c.translate(x, y); c.rotate(0.5); ellipse(c, 0, 0, r * 0.6, r, '#5B4636'); c.strokeStyle = '#F3E6D6'; c.lineWidth = r * 0.16; c.beginPath(); c.moveTo(0, -r * 0.75); c.lineTo(0, r * 0.75); c.stroke(); c.restore(); }
let lastPop = 0;
function frame() {
  const t = now();
  if (camTo) { const q = Math.min(1, (t - camT0) / camDur), e = ease(q); for (const k of ['x', 'y', 's', 'ay']) cam[k] = camFrom[k] + (camTo[k] - camFrom[k]) * e; if (q >= 1) camTo = null; }
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  drawSky(t); drawSea(t);
  const s = camS();
  ctx.setTransform(DPR * s, 0, 0, DPR * s, DPR * (W / 2 - cam.x * s), DPR * (camAY() - cam.y * s));
  const st = S.stage;
  // the other islands (behind first, by y)
  const others = ISLES.filter((i) => i.id !== 'home').sort((a, b) => a.pos[1] - b.pos[1]);
  for (const isle of others) if (isle.pos[1] < 0) isleScene(ctx, isle, t, isle.pos[0], isle.pos[1]);
  ferryRoute(ctx, t);
  const big = st >= 2;
  const homeA = focusAlpha('home');
  if (homeA < 1) { ctx.save(); ctx.globalAlpha = homeA; }
  islandBody(ctx, 0, 0, big ? 172 : 124, big ? 56 : 42, big ? 150 : 110, true);
  if (st >= 3) terrace(ctx, t);
  const items = [];
  for (const s2 of STATIONS.filter((x) => x.isle === 'home')) {
    const L = lv(s2.id);
    const visible = s2.gate <= st || (s2.gate === st + 1 && (s2.gate <= 2 || st >= 3));
    if (!visible) continue;
    items.push({ y: s2.slot[1], f: () => { ctx.save(); ctx.translate(...s2.slot); const pop = S.popT && S.popT.id === s2.id ? (t - S.popT.t) / 700 : 2; if (pop < 1) { const k = 0.85 + 0.15 * pop + 0.12 * Math.sin(pop * Math.PI); ctx.scale(k, k); } ctx.scale(1.3, 1.3); softShadow(ctx, 0, 1, 32, 8, 0.18); if (L) DRAW[s2.id](ctx, L, t); else plot(ctx, s2, t, s2.gate <= st); ctx.restore(); } });
    const r = RESIDENT[s2.id];
    if (r && L) items.push({ y: s2.slot[1] + r[2], f: () => critter(ctx, r[0], s2.slot[0] + r[1] * 1.3, s2.slot[1] + r[2], t, 1.35) });
  }
  const kind = emotionNow();
  items.push({ y: POFU.y, f: () => drawPofuAt(ctx, POFU.x, POFU.y, POFU_W, t, kind) });
  items.sort((a, b) => a.y - b.y).forEach((i) => i.f());
  if (homeA < 1) ctx.restore();
  for (const isle of others) if (isle.pos[1] >= 0) isleScene(ctx, isle, t, isle.pos[0], isle.pos[1]);
  if (S.night) { ctx.save(); ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.globalCompositeOperation = 'multiply'; ctx.fillStyle = '#6E66A6'; ctx.fillRect(0, 0, W, H); ctx.restore(); ctx.globalCompositeOperation = 'source-over'; drawGlows(t); }
  // idle production: a seed pops from a working station on the island in view
  if (!S.night && S.mode !== 'map' && t - lastPop > 1300 && S.health >= 12) {
    lastPop = t;
    const isle = S.mode === 'home' ? 'home' : S.isle;
    const built = STATIONS.filter((x) => x.isle === isle && lv(x.id) && isOpen(x));
    const b = built[Math.floor(Math.random() * built.length)];
    if (b) { const p = isleById[b.isle].pos; particles.push({ x: p[0] + b.slot[0] + (Math.random() - 0.5) * 20, y: p[1] + b.slot[1] - 30, vx: 0, vy: -10, t0: t, life: 1400, kind: 'seed' }); }
  }
  particles = particles.filter((p) => t - p.t0 < p.life);
  for (const p of particles) {
    const k = (t - p.t0) / p.life, d = (t - p.t0) / 1000;
    const x = p.x + p.vx * d, y = p.y + p.vy * d + (p.kind === 'seed' ? 0 : 22 * d * d);
    if (p.kind === 'seed') seedIcon(ctx, x, y, 3.2, Math.sin(k * Math.PI));
    else if (p.kind === 'gift') seedIcon(ctx, x, y, 2.6, 1 - k);
    else sparkle(ctx, x, y, 2.4 * (1 - k * 0.5), 1 - k);
  }
  const hop = document.getElementById('hopPofu');
  if (hop) { const c2 = hop.getContext('2d'); c2.setTransform(1, 0, 0, 1, 0, 0); c2.clearRect(0, 0, hop.width, hop.height); c2.setTransform(2, 0, 0, 2, 0, 0); drawPofuAt(c2, 90, 168, 150, t, S.hopKind || 'jealous'); }
  breathTick(t);
  positionTags();
  requestAnimationFrame(frame);
}
function drawGlows(t) {
  const glow = (x, y, r, a) => { const g = ctx.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, `rgba(255,206,110,${a})`); g.addColorStop(1, 'rgba(255,206,110,0)'); ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2); };
  if (lv('cay') >= 4) glow(64, -36, 30, 0.5);
  if (lv('windmill') >= 4) glow(-62, -128, 24, 0.5);
  glow(-124 * 0.52 + (S.stage >= 2 ? -24 : 0), 52, 16, 0.5);
  const h = isleById.harbor.pos;
  if (S.arrived.harbor && lv('lighthouse') >= 2) glow(h[0] + 6, h[1] - 30 - 72, 26, 0.7);
  if (S.arrived.harbor && lv('pier') >= 2) glow(h[0] + 58 + 74, h[1] + 12 - 36, 12, 0.6);
}

// world-anchored tags
let tags = [];
function tag(wx, wy, html, ms = 3200, cls = '') {
  const el = document.createElement('div'); el.className = `tag ${cls}`; el.innerHTML = html; document.getElementById('fx').appendChild(el);
  const r = { el, wx, wy }; tags.push(r);
  if (ms) setTimeout(() => { el.remove(); tags = tags.filter((x) => x !== r); }, ms);
  return r;
}
function positionTags() { for (const r of tags) { const [x, y] = toScreen(r.wx, r.wy); r.el.style.left = Math.max(70, Math.min(W - 70, x)) + 'px'; r.el.style.top = y + 'px'; } }
function clearTags(cls) { tags.filter((r) => !cls || r.el.classList.contains(cls)).forEach((r) => r.el.remove()); tags = tags.filter((r) => r.el.isConnected); }
function mapTags() {
  clearTags('isle-tag');
  if (S.mode !== 'map') return;
  for (const isle of ISLES) {
    const p = isle.pos, rx = isle.id === 'home' ? (S.stage >= 2 ? 172 : 124) : isle.rx;
    const status = isle.id === 'home' ? 'home' : S.arrived[isle.id] ? (S.visited[isle.id] ? 'open' : '<i class="new">new</i>') : isle.season ? 'with a season' : 'locked';
    tag(p[0], p[1] - rx * 0.36 - (isle.id === 'home' ? 70 : 34), `<b>${isle.name}</b> · ${status}`, 0, `stay isle-tag ${S.arrived[isle.id] ? '' : 'locked'}`);
  }
}

// ---------------------------------------------------------------- chrome
const ICON = {
  gear: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3.2"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>`,
  chev: `<svg class="chev" width="10" height="16" viewBox="0 0 10 16" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M2 2l6 6-6 6"/></svg>`,
  home: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11.5 12 5l8 6.5"/><path d="M6.5 10v8.5h11V10"/></svg>`,
  isle: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><ellipse cx="12" cy="11" rx="9" ry="3"/><path d="M3.2 11.6c1.7 4.6 5 7.6 8.8 8.9 3.8-1.3 7.1-4.3 8.8-8.9"/><path d="M12 8V3.6"/><path d="M12 4.6c1.5-1.3 3.3-1.3 4.6 0-1.4 1.2-3.2 1.2-4.6 0zM12 6c-1.3-1.1-2.9-1.1-4 0 1.2 1 2.8 1 4 0z"/></svg>`,
  map: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 4.5 3.5 6.8v13l5.5-2.3 6 2.3 5.5-2.3v-13L15 6.8z"/><path d="M9 4.5v13M15 6.8v13"/></svg>`,
  heart: (low) => `<svg width="22" height="22" viewBox="0 0 24 24"><path d="M12 20.5s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.6a4.3 4.3 0 0 1 7.5 2.7c0 5.6-7.5 10.2-7.5 10.2z" fill="${low ? '#D9BCC4' : '#F48C9A'}"/><path d="M8 9.5a2 2 0 0 1 2-1.4" stroke="#fff" stroke-width="1.4" fill="none" stroke-linecap="round" opacity=".8"/></svg>`,
  seed: (s = 22) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" aria-hidden="true"><g transform="rotate(28 12 12)"><ellipse cx="12" cy="12" rx="5.8" ry="9.2" fill="#5B4636"/><ellipse cx="10.6" cy="9" rx="1.6" ry="3.4" fill="#7A604B"/><path d="M12 3.6v16.8M9.3 5.6c-.9 4-.9 8.8 0 12.8M14.7 5.6c.9 4 .9 8.8 0 12.8" stroke="#F3E6D6" stroke-width="1.15" fill="none" stroke-linecap="round"/></g></svg>`,
  ig: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="4" y="4" width="16" height="16" rx="5"/><circle cx="12" cy="12" r="3.6"/><circle cx="17" cy="7" r=".9" fill="#fff"/></svg>`,
  up: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V6M6 11l6-6 6 6"/></svg>`,
  ferry: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 14h18l-2 5H5z"/><path d="M7 14V9h8v5M11 9V5h3"/></svg>`,
  close: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>`,
};
const sig = (c) => `<svg width="18" height="12" viewBox="0 0 18 12" fill="${c}"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>`;
const wifi = (c) => `<svg width="17" height="12" viewBox="0 0 17 12" fill="${c}"><path d="M8.5 2.3c2.4 0 4.6.9 6.2 2.5l1.2-1.2A10.4 10.4 0 0 0 8.5.6 10.4 10.4 0 0 0 1.1 3.6l1.2 1.2a8.7 8.7 0 0 1 6.2-2.5zm0 3.4c1.5 0 2.8.6 3.8 1.5l1.2-1.2a7 7 0 0 0-10 0l1.2 1.2c1-.9 2.3-1.5 3.8-1.5zm0 3.4c.6 0 1.1.2 1.5.6L8.5 11.2 7 9.7c.4-.4.9-.6 1.5-.6z"/></svg>`;
const batt = (c) => `<svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="${c}" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2.5" fill="${c}"/><path d="M25 4.5v4a2.2 2.2 0 0 0 0-4z" fill="${c}" opacity=".45"/></svg>`;
function ring(calm) { const full = calm >= CALM_MAX; const r = 12, C = 2 * Math.PI * r; return `<svg width="30" height="30" viewBox="0 0 30 30" aria-hidden="true"><circle cx="15" cy="15" r="${r}" fill="none" stroke="rgba(95,181,122,.2)" stroke-width="3.5"/><circle cx="15" cy="15" r="${r}" fill="none" stroke="#5FB57A" stroke-width="3.5" stroke-linecap="round" stroke-dasharray="${(C * (calm - 1)).toFixed(1)} ${C.toFixed(1)}" transform="rotate(-90 15 15)"/><circle cx="15" cy="15" r="4" fill="#5FB57A" opacity="${full ? 1 : 0.55}"/></svg>`; }
const fmt = (n) => Math.round(n).toLocaleString('en-US');
const esc = (s) => String(s).replace(/[&<>"]/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[ch]));

function nextGoal(isle) {
  const opts = STATIONS.filter((s) => (!isle || s.isle === isle) && isOpen(s) && lv(s.id) < 5).map((s) => ({ s, c: cost(s, lv(s.id) + 1) }));
  opts.sort((a, b) => a.c - b.c);
  return opts[0];
}
function nextIsle() { return ISLES.find((i) => !S.arrived[i.id] && !i.season); }
function isleProgress(isle) {
  const rows = [];
  const need = { harbor: { tended: 8, st: ['cay', 3] }, stars: { tended: 21, nights: 10 }, hamam: { tended: 35, st: ['pier', 3] } }[isle.id];
  if (!need) return rows;
  rows.push(['Tended days', Math.min(S.tended, need.tended), need.tended]);
  if (need.nights) rows.push(['Calm nights', Math.min(S.calmNights, need.nights), need.nights]);
  if (need.st) rows.push([`${stById[need.st[0]].name} level`, Math.min(lv(need.st[0]), need.st[1]), need.st[1]]);
  return rows;
}
function say(text, act) { S.msg = text ? { text, act } : null; }

function seedPill() { return `<button class="glass pill press" data-ui="${S.pending ? 'collect' : 'none'}" aria-label="${fmt(S.seeds)} seeds${S.pending ? `, ${fmt(S.pending)} to collect` : ''}">${ICON.seed(24)}<span class="num">${fmt(S.seeds)}</span>${S.pending ? `<span class="plus">+${fmt(S.pending)}</span>` : ''}</button>`; }

function renderChrome() {
  const root = document.getElementById('chrome');
  screenEl.classList.toggle('dark', S.night);
  const c = S.night ? '#fff' : '#2A1F2D';
  const mode = S.mode;
  const skips = S.beads.filter((b) => b === 'S').length;
  const low = S.health < 25;
  const full = S.calm >= CALM_MAX;
  const flash = S.calmFlash && now() - S.calmFlash < 1000;
  const bubbleBottom = H - (HOME_FEET * H / REF_H - POFU_W * 0.95 * HOME_S * FIT) + 14;
  let bubble = '';
  if (S.msg && mode === 'home') {
    const b = S.msg.act === 'collect' && S.pending ? `<button class="chipbtn press" data-ui="collect">${ICON.seed(18)}Collect ${fmt(S.pending)} seeds</button>`
      : S.msg.act === 'island' ? `<button class="chipbtn press" data-ui="toVillage">${ICON.isle}See the island</button>`
      : S.msg.act === 'map' ? `<button class="chipbtn press" data-ui="toMap">${ICON.map}See the new island</button>`
      : S.msg.act === 'heal' ? `<button class="chipbtn press" data-ui="quiet">Quiet hour together</button>` : '';
    bubble = `<div class="bubble" style="bottom:${bubbleBottom}px">${S.msg.text}${b}</div>`;
  }
  const usedPct = Math.min(100, (S.used / BREATH_LIMIT) * 100);
  const calmWord = flash ? (S.calmNote === 'halved' ? 'halved' : 'starts again now') : full ? 'full' : 'growing';
  const isle = isleById[S.isle];
  const g = nextGoal(mode === 'isle' ? S.isle : null);
  const ni = nextIsle();
  root.innerHTML = `
    <div class="status"><span>9:41</span><div class="di"></div><span class="icons">${sig(c)}${wifi(c)}${batt(c)}</span></div>
    <div class="layer ${mode === 'home' ? '' : 'off'}">
      <div class="topbar">
        <button class="glass care press ${low ? 'low' : ''}" aria-label="Pofu is ${mood()}">${ICON.heart(low)}<span class="bar"><i style="width:${Math.max(6, S.health)}%"></i></span><span class="mood">${mood()}</span></button>
        <span class="spacer"></span>
        <button class="glass circle press" aria-label="Friends"><span class="avatar">D</span></button>
        <button class="glass circle press" aria-label="Settings">${ICON.gear}</button>
      </div>
      ${S.night ? '' : `<div class="glass calm ${flash ? 'reset' : ''} ${full ? 'full' : ''}" role="status">${ring(S.calm)}<span class="x">Calm ×${S.calm.toFixed(1)}</span><small>${calmWord}</small></div>`}
      ${bubble}
      <div class="bottom">
        <button class="today press" aria-label="Today"><div class="grow"><div class="big">${S.beads.length ? `${skips} of ${S.beads.length} skipped` : 'No reaches yet'}<small>today</small></div>
          <div class="beads">${S.beads.map((b) => `<span class="bead ${b === 'S' ? 's' : b === 'Q' ? 'q' : 'o'}"></span>`).join('')}</div></div>
          <div class="usage ${over() ? 'over' : ''}"><span><b>${fmt(S.used)}</b> / ${BREATH_LIMIT} min</span><span class="meter"><i style="width:${usedPct}%"></i></span><small>${over() ? 'a breath before each open' : 'in guarded apps'}</small></div></button>
        <div class="actions"><button class="glass prominent primary press" data-ui="quiet">Quiet time with Pofu</button><button class="glass secondary press" data-ui="toVillage" aria-label="Pofu's island">${ICON.isle}</button></div>
      </div>
    </div>
    <div class="layer ${mode === 'isle' ? '' : 'off'}">
      <div class="topbar">
        <button class="glass circle press" data-ui="toHome" aria-label="Back to Pofu">${ICON.home}</button>
        <button class="glass circle press" data-ui="toMap" aria-label="Archipelago map">${ICON.map}</button>
        <span class="spacer"></span>
        ${seedPill()}
      </div>
      <div class="glass title-cap">${isle.name} <small>· ${S.isle === 'home' ? `stage ${S.stage + 1}/5 · day ${S.day}` : `${ICON.ferry} ${S.postcards}/7 postcards`}</small></div>
      <div class="bottom">
        ${g ? `<button class="next press" data-st="${g.s.id}"><div class="grow"><div class="t">${g.s.name} → level ${lv(g.s.id) + 1}</div>
          <div class="s">${S.seeds >= g.c ? `Ready · ${fmt(g.c)} seeds` : `${fmt(S.seeds)} of ${fmt(g.c)} seeds · gathering while you’re away`}</div>
          <div class="prog"><i style="width:${Math.min(100, (S.seeds / g.c) * 100)}%"></i></div></div>${ICON.chev}</button>` : ''}
        <div class="actions">${S.night ? `<button class="glass prominent primary" disabled>The island sleeps until 6:00</button>`
          : g && S.seeds >= g.c ? `<button class="glass prominent primary press" data-st="${g.s.id}">${ICON.up}Build: ${g.s.name}</button>`
          : `<button class="glass primary press" data-ui="toHome">All caught up · back to Pofu</button>`}</div>
      </div>
    </div>
    <div class="layer ${mode === 'map' ? '' : 'off'}">
      <div class="topbar">
        <button class="glass circle press" data-ui="toHome" aria-label="Back to Pofu">${ICON.home}</button>
        <span class="spacer"></span>
        ${seedPill()}
      </div>
      <div class="glass title-cap">Archipelago <small>· ${isleCount()} of ${ISLES.length} islands</small></div>
      <div class="bottom">
        ${S.arrived.harbor && !S.visited.harbor ? `<button class="next press" data-isle="harbor"><div class="grow"><div class="t">İskele drifted close</div><div class="s">Simit the kitten has opened a cart. Tap to visit.</div></div>${ICON.chev}</button>`
          : ni ? `<button class="next press" data-isle="${ni.id}"><div class="grow"><div class="t">Next: ${ni.name} · ${ni.en.replace(/^The /, '')}</div>
          <div class="s">${isleProgress(ni).map(([k, v, n]) => `${k} ${v}/${n}`).join(' · ')}</div>
          <div class="prog"><i style="width:${Math.min(100, (isleProgress(ni).reduce((s, [, v, n]) => s + v / n, 0) / Math.max(1, isleProgress(ni).length)) * 100)}%"></i></div></div>${ICON.chev}</button>` : ''}
        <div class="actions"><button class="glass primary press" data-ui="toVillage">${ICON.isle}Back to Ayçiçeği</button></div>
      </div>
    </div>`;
  readout();
}
function toast(text) { const el = document.createElement('div'); el.className = 'glass toast'; el.setAttribute('role', 'status'); el.textContent = text; screenEl.appendChild(el); setTimeout(() => el.remove(), 2700); }

// ---------------------------------------------------------------- sheets
function closeSheet() { document.body.classList.remove('cover-open'); document.getElementById('sheet-root').innerHTML = ''; S.sheet = null; S.breath = null; S.hopKind = null; renderChrome(); }
function openStation(id) {
  if (S.night) return toast('The island sleeps until 6:00');
  const s = stById[id]; const L = lv(id);
  if (!isOpen(s)) { const d = daysUntil(s); return toast(d > 0 ? `${s.name} opens in ${d} tended day${d > 1 ? 's' : ''}` : `${s.name} opens soon`); }
  S.sheet = id;
  const to = L + 1, c = cost(s, to), maxed = L >= 5;
  const can = !maxed && S.seeds >= c;
  const variant = to === 3 && id === 'cay';
  document.getElementById('sheet-root').innerHTML = `<div class="scrim" data-ui="closeSheet"></div>
    <div class="sheet station-sheet" role="dialog" aria-label="${s.name}">
      <div class="grabber"></div>
      <div class="head"><canvas width="184" height="160" id="stThumb"></canvas>
        <div><div class="who">${s.who}</div><h3>${s.name}</h3>
        <div class="lvl">${L ? `Level ${L} of 5 · ${fmt(rate(s, L))} seeds an hour` : 'Not built yet'}</div>
        <div class="pips">${[1, 2, 3, 4, 5].map((i) => `<i class="${i <= L ? 'f' : i === to ? 'n' : ''}"></i>`).join('')}</div></div></div>
      ${maxed ? `<div class="box"><b>Complete.</b><p>Every level is built. ${s.who.split(' ')[0]} is very proud of it.</p></div>` : `
      <div class="box"><b>Level ${to}:</b> <p>${s.levels[to - 1]}.</p>
        <div class="row2"><span>${L ? `+${fmt(rate(s, to) - rate(s, L))} seeds an hour` : `${fmt(rate(s, 1))} seeds an hour`}</span><span>${ICON.seed(15)} ${fmt(Math.min(S.seeds, c))} / ${fmt(c)}</span></div>
        <div class="prog"><i style="width:${Math.min(100, S.seeds / c * 100)}%"></i></div>
        ${variant ? `<div class="variants"><button class="${S.variant.cay !== 'blue' ? 'on' : ''}" data-var="red"><span class="sw" style="background:#E9696F"></span>Rose stripes</button><button class="${S.variant.cay === 'blue' ? 'on' : ''}" data-var="blue"><span class="sw" style="background:#7EA6D8"></span>İznik blue</button></div>` : ''}
      </div>
      <button class="glass prominent go press" data-ui="upgrade" ${can ? '' : 'disabled'}>${can ? `${ICON.up}${L ? 'Build level ' + to : 'Build'} · ${fmt(c)} seeds` : `About ${Math.ceil((c - S.seeds) / Math.max(1, prodRate() * S.calm))} quiet hours away`}</button>`}
      <p class="note">Seeds are island material. They never buy screen time.</p>
    </div>`;
  const tc = document.getElementById('stThumb').getContext('2d'); tc.setTransform(2, 0, 0, 2, 0, 0); tc.translate(id === 'pier' ? 34 : 46, id === 'lighthouse' ? 74 : 66); const k = id === 'lighthouse' || id === 'windmill' ? 0.78 : id === 'pier' ? 0.62 : 1; tc.scale(k, k);
  if (L) DRAW[id](tc, Math.max(1, L), now()); else plot(tc, s, now(), true);
}
function openIsle(id) {
  const isle = isleById[id]; const arrived = !!S.arrived[id];
  S.sheet = 'isle:' + id;
  const rows = isleProgress(isle);
  const status = id === 'home' ? 'Home' : arrived ? `Arrived on day ${S.arrived[id]}` : isle.season ? 'Coming with a season' : 'Not here yet';
  const cards = id === 'harbor' ? `<div class="cards7" aria-label="${S.postcards} of 7 postcards">${Array.from({ length: 7 }, (_, i) => `<span class="pc ${i < S.postcards ? 'f' : ''}" style="--h:${(i * 47) % 360}"></span>`).join('')}</div>` : '';
  const btn = id === 'home' ? `<button class="glass prominent go press" data-visit="home">${ICON.isle}Go to Ayçiçeği</button>`
    : arrived ? `<button class="glass prominent go press" data-visit="${id}">${ICON.ferry}Visit ${isle.name}</button>`
    : `<button class="glass prominent go" disabled>${isle.season ? 'Arrives with a season update' : 'It will drift closer on its own'}</button>`;
  document.getElementById('sheet-root').innerHTML = `<div class="scrim" data-ui="closeSheet"></div>
    <div class="sheet isle-sheet" role="dialog" aria-label="${isle.name}">
      <div class="grabber"></div>
      <button class="glass circle sheet-x press" data-ui="closeSheet" aria-label="Close">${ICON.close}</button>
      <div class="head"><canvas width="184" height="140" id="isleThumb"></canvas>
        <div><div class="who">${status}</div><h3>${isle.name}</h3><div class="lvl">${isle.en}</div></div></div>
      <p class="theme">${isle.theme}</p>
      <div class="box loop"><span class="k">Its own little loop</span><b>${isle.loop[0]}</b><p>${isle.loop[1]}</p>${cards}</div>
      <div class="box"><span class="k">Neighbor</span><p>${isle.who}</p></div>
      ${isle.stations ? `<div class="box"><span class="k">Stations</span><p>${isle.stations.join(' · ')}: five designed levels each.</p></div>` : ''}
      <div class="box"><span class="k">${arrived ? 'How it arrived' : 'When it arrives'}</span><p>${isle.need}</p>
        ${!arrived ? rows.map(([k, v, n]) => `<div class="row2"><span>${k}</span><span>${v} / ${n}</span></div><div class="prog"><i style="width:${(v / n) * 100}%"></i></div>`).join('') : ''}</div>
      ${btn}
    </div>`;
  const tc = document.getElementById('isleThumb').getContext('2d');
  tc.setTransform(2, 0, 0, 2, 0, 0); tc.translate(46, 34);
  if (id === 'home') { tc.scale(0.24, 0.24); islandBody(tc, 0, 0, S.stage >= 2 ? 172 : 124, S.stage >= 2 ? 56 : 42, S.stage >= 2 ? 150 : 110, true); DRAW.garden(tc, lv('garden'), now()); }
  else { tc.scale(0.32, 0.32); isleScene(tc, isle, now(), 0, 0); }
}

// Hop! (the care rung) and the breathing break
function openHop() {
  closeSheet(); S.night = false;
  const quickBefore = S.calm, quickAfter = S.quickChain ? 1 : Math.max(1, Math.floor((1 + (S.calm - 1) / 2) * 10 + 1e-9) / 10);
  const lossH = S.health >= 50 ? 'a bit tired' : 'unwell';
  const lines = ['Instagram again? What does it have that I don’t?', 'Oh. Instagram. I see how it is.', 'Is it more interesting than me? Be honest.'];
  const o = over();
  S.hopKind = o ? 'worried' : 'jealous';
  document.getElementById('sheet-root').innerHTML = `<div class="hop ${o ? 'over' : ''}" role="dialog" aria-label="Hop!">
    <div class="app"><span class="ig">${ICON.ig}</span>Instagram · ${o ? 'past today’s 60 minutes' : '3rd reach this hour'}</div>
    <h2>Hop!</h2>
    <canvas class="pofu" id="hopPofu" width="360" height="360"></canvas>
    <div class="quip">“${o ? 'We’ve had our hour today. Breathe with me first?' : lines[(S.day + S.beads.length) % lines.length]}”</div>
    <div class="usage-line"><span>${fmt(S.used)} of ${BREATH_LIMIT} min today</span><span class="meter"><i style="width:${Math.min(100, S.used / BREATH_LIMIT * 100)}%"></i></span></div>
    <div class="spacer"></div>
    <div class="choices">
      <button class="choice press" data-ui="quick"><span class="t">Quick check · ${QUICK_MIN} min</span><span class="d">Calm ×${quickBefore.toFixed(1)} → ×${quickAfter.toFixed(1)}${S.quickChain ? ' (two in a row)' : ''}</span>${o ? '<span class="b">after a breath</span>' : ''}</button>
      <button class="choice press" data-ui="open"><span class="t">Open · ${OPEN_MIN} min</span><span class="d">Calm ×${S.calm.toFixed(1)} → ×1.0 · Pofu ${lossH}</span>${o ? '<span class="b">after a breath</span>' : ''}</button>
    </div>
    <button class="glass prominent skip press" data-ui="skip">Skip it</button>
    <div class="fine">Skipping keeps your calm growing${S.skipsPaid < SKIP_SEEDS_CAP ? ` and adds ${SKIP_SEEDS} seeds` : ''}.</div>
  </div>`;
  S.sheet = 'hop';
  document.body.classList.add('cover-open');
}
function wantOpen(quick) {
  if (!over()) return openApp(quick);
  openBreath(quick);
}
// Breathing break v2: the user starts the breath (ownership), 5 s by default, never more than 10 s.
function openBreath(quick) {
  const secs = breathSecsFor(S.overOpens); S.overOpens++;
  S.breath = { t0: null, secs, quick, done: false };
  S.hopKind = null;
  document.getElementById('sheet-root').innerHTML = `<div class="breath" role="dialog" aria-label="Breathing break">
    <div class="app"><span class="ig">${ICON.ig}</span>Instagram · past today’s 60 minutes</div>
    <h2>${secs > 5 ? 'One deep breath' : 'One breath'} with Pofu</h2>
    <p class="sub" id="breathSub">${secs > 5 ? 'Ten seconds' : 'Five seconds'}, when you’re ready.</p>
    <div class="orb"><div class="halo"></div><div class="disc"></div><canvas id="breathPofu" width="400" height="400"></canvas></div>
    <div class="cue" id="cue" aria-live="polite">“We’ve had our hour today. Breathe with me first?”</div>
    <div class="spacer"></div>
    <div class="start" id="breathStart">
      <button class="glass prominent skip press" data-ui="breathStart">Breathe with Pofu</button>
    </div>
    <div class="after" id="breathAfter">
      <button class="glass prominent skip press" data-ui="breathSkip">I’m good, skip it</button>
      <button class="spend press" data-ui="breathOpen">Open Instagram · ${quick ? QUICK_MIN : OPEN_MIN} min</button>
    </div>
    <button class="link press" id="breathNotNow" data-ui="breathSkip">Not now</button>
  </div>`;
  S.sheet = 'breath';
  document.body.classList.add('cover-open');
}
function startBreath() {
  const B = S.breath; if (!B || B.t0 !== null) return;
  B.t0 = now();
  const el = document.querySelector('.breath'); if (el) el.classList.add('running');
}
function breathTick(t) {
  const B = S.breath; const el = document.getElementById('breathPofu'); if (!B || !el) return;
  const orb = el.parentElement;
  const c2 = el.getContext('2d'); c2.setTransform(1, 0, 0, 1, 0, 0); c2.clearRect(0, 0, el.width, el.height); c2.setTransform(2, 0, 0, 2, 0, 0);
  if (B.t0 === null) {   // waiting for the user's tap: Pofu idles, eyes open, the orb barely moves
    breathPhase = Math.sin(t / 3600 * Math.PI * 2);
    orb.style.setProperty('--k', (0.18 + 0.06 * breathPhase).toFixed(3));
    drawPofuAt(c2, 100, 172, 132, t, null);
    return;
  }
  const total = B.secs * 1000, IN = total * 0.4, e = Math.min(total, t - B.t0);
  const k = e < IN ? 0.5 - 0.5 * Math.cos(Math.PI * e / IN) : 0.5 + 0.5 * Math.cos(Math.PI * (e - IN) / (total - IN));
  breathPhase = k * 2 - 1;
  const done = e >= total;
  orb.style.setProperty('--k', done ? 0.35 : k.toFixed(3));
  const cue = document.getElementById('cue');
  const word = done ? 'Nicely done.' : e < IN ? 'Breathe in…' : '…and out';
  if (cue.textContent !== word) cue.textContent = word;
  if (done && !B.done) { B.done = true; document.querySelector('.breath').classList.add('done'); }
  drawPofuAt(c2, 100, 172, 132, t, done ? 'relieved' : 'breathe');
}

// ---------------------------------------------------------------- actions
function setMode(mode, opts = {}) {
  const was = S.mode;
  if (opts.isle) S.isle = opts.isle;
  document.getElementById('sheet-root').innerHTML = ''; S.sheet = null; S.breath = null; document.body.classList.remove('cover-open');
  S.mode = mode;
  if (mode === 'isle') S.visited[S.isle] = true;
  opts.instant ? Object.assign(cam, camFor(mode)) : moveCam(camFor(mode), mode === 'map' || was === 'map' ? 1100 : 950);
  if (mode === 'home' && S.caughtUp && !S.msg) say('All caught up. Nothing is waiting; the island keeps going without you.');
  mapTags();
  renderChrome();
}
const toVillage = (instant) => setMode('isle', { isle: S.mode === 'isle' ? S.isle : 'home', instant });
const toHome = (instant) => setMode('home', { instant });
const toMap = (instant) => setMode('map', { instant });
const visit = (id, instant) => setMode('isle', { isle: id, instant });
function collect() {
  if (!S.pending) return;
  const [x, y] = S.mode === 'home' ? [POFU.x, POFU.y - 30] : toWorld(W - 80, 90);
  burst(x, y, 'gift', 16);
  S.seeds += S.pending; S.pending = 0; S.caughtUp = true;
  const g = nextGoal();
  say(g && S.seeds >= g.c ? `Enough for the ${g.s.name.toLowerCase()}! Want to see?` : 'Into the seed jar. That’s everything for now.', g && S.seeds >= g.c ? 'island' : null);
  if (S.mode !== 'home') S.msg = null;
  renderChrome();
}
function upgrade() {
  const id = S.sheet, s = stById[id], to = lv(id) + 1, c = cost(s, to);
  if (!s || S.seeds < c) return;
  S.seeds -= c; S.levels[id] = to; S.popT = { id, t: now() };
  closeSheet();
  const p = isleById[s.isle].pos;
  burst(p[0] + s.slot[0], p[1] + s.slot[1] - 20, 'sparkle', 16);
  tag(p[0] + s.slot[0], p[1] + s.slot[1] - 46, `<b>${s.name}</b> · level ${to}`, 2600);
  emote('excited', 2600);
  renderChrome();
}
function resist(fromBreath) {
  closeSheet(); S.night = false;
  S.beads.push('S');
  if (S.skipsHealed < 6) { S.skipsHealed++; S.health = Math.min(100, S.health + 1); }
  const paid = S.skipsPaid < SKIP_SEEDS_CAP;
  if (paid) { S.skipsPaid++; S.seeds += SKIP_SEEDS; burst(POFU.x, POFU.y - 40, 'gift', 5); }
  const gift = paid ? ` +${SKIP_SEEDS} seeds for the island.` : '';
  const quips = [['proud', `Skipped!${gift} Calm keeps growing: ×${S.calm.toFixed(1)}.`], ['relieved', `Phew. You came back to me.${gift}`], ['proud', `We did that. Together. Mostly you.${gift}`]];
  const [k, line] = fromBreath === true ? ['relieved', `That breath was enough. Proud of us.${gift}`] : quips[(S.beads.length - 1) % quips.length];
  if (S.mode !== 'home') setMode('home');
  emote(k, 3000); say(line); renderChrome();
}
function quietHour() {
  closeSheet();
  if (S.night) return toast('Bedtime: calm holds until morning');
  const wasLow = S.health < 25;
  const before = S.calm;
  const avg = Math.min(CALM_MAX, S.calm + 0.15);
  S.pending += Math.round(prodRate() * avg) + QUIET_SEEDS_HOUR;
  S.calm = Math.min(CALM_MAX, Math.round((S.calm + 0.3) * 10) / 10);
  S.health = Math.min(100, S.health + (wasLow ? 14 : 5));
  S.quickChain = false;
  if (S.mode !== 'home') setMode('home');
  if (S.calm >= CALM_MAX && before < CALM_MAX) { emote('smug', 5000); say('Calm ×2.0. Maxed out. I’m basically a zen master now.', 'collect'); }
  else if (wasLow) { emote('relieved', 4000); say('That helped. I’m feeling more like myself.', 'collect'); }
  else { emote('proud', 2200); say(`A quiet hour. Calm ×${S.calm.toFixed(1)} and climbing.`, 'collect'); }
  renderChrome();
}
function openApp(quick) {
  closeSheet();
  if (S.mode !== 'home') setMode('home', { instant: true });
  const chained = quick && S.quickChain;
  S.used += quick ? QUICK_MIN : OPEN_MIN;
  S.beads.push(quick && !chained ? 'Q' : 'O');
  S.calmFlash = now();
  if (quick && !chained) {
    const before = S.calm;
    S.calm = Math.max(1, Math.floor((1 + (S.calm - 1) / 2) * 10 + 1e-9) / 10);
    S.calmNote = 'halved'; S.quickChain = true;
    S.health = Math.max(5, S.health - 2);
    S.emotion = null;
    say(`Quick one? Go ahead. I’ll keep the calm warm: ×${before.toFixed(1)} → ×${S.calm.toFixed(1)}.`);
  } else {
    S.calm = 1.0; S.calmNote = 'reset'; S.quickChain = false;
    S.health = Math.max(5, S.health - 8);
    emote('pout', 5000);
    say(chained ? 'Two quick checks in a row count as a real open. Calm starts again at ×1.0.' : 'Hmph. Calm’s back to ×1.0. Fine. It’ll grow again.');
  }
  renderChrome();
  setTimeout(renderChrome, 1050);
}
function useLimit() { closeSheet(); S.used = Math.max(S.used, BREATH_LIMIT); if (S.mode !== 'home') setMode('home'); say('That’s our 60 minutes for today. From now on, we take a breath together before any app opens.'); emote('worried', 2400); renderChrome(); }
function binge() {
  closeSheet();
  if (S.mode !== 'home') setMode('home');
  for (let i = 0; i < 4; i++) S.beads.push('O');
  S.used += 75; S.calm = 1.0; S.health = 16; S.calmFlash = now(); S.calmNote = 'reset'; S.quickChain = false;
  emote('worried', 2500);
  say('That was a long one. I feel a bit wobbly. Sit with me for a quiet hour?', 'heal');
  renderChrome(); setTimeout(renderChrome, 1050);
}
function setNight(v) { S.night = v === undefined ? !S.night : v; closeSheet(); say(S.night ? 'Sleep well. The residents are closing up too.' : 'Good morning!'); renderChrome(); }
function nextDay(silent) {
  document.body.classList.remove('cover-open');
  document.getElementById('sheet-root').innerHTML = ''; S.sheet = null; S.breath = null;
  const calmNight = S.health >= 25 && !S.lateOpen;
  const made = Math.round(prodRate() * (S.calm + (calmNight ? 0.1 : 0)) * 9) + (calmNight ? 10 : 0);
  S.pending += made;
  S.day++; S.tended++;
  const before = S.stage; S.stage = stageFor(S.tended);
  if (S.health < 60) S.health += 0.3 * (60 - S.health);   // Pofu sleeps it off
  if (calmNight) { S.health = Math.min(100, S.health + 10); S.calm = Math.min(CALM_MAX, Math.round((S.calm + 0.2) * 10) / 10); S.calmNights++; }
  let postcard = false;
  if (calmNight && S.arrived.harbor && S.postcards < 7) { S.postcards++; postcard = true; }
  let arrived = false;
  if (!S.arrived.harbor && harborReady()) { S.arrived.harbor = S.day; arrived = true; }
  S.beads = []; S.night = false; S.skipsHealed = 0; S.skipsPaid = 0; S.caughtUp = false; S.used = 0; S.overOpens = 0; S.quickChain = false;
  if (silent) return;
  const grew = S.stage > before;
  const opened = STATIONS.filter((s) => s.isle === 'home' && s.gate === S.stage && grew).map((s) => s.name);
  const extra = arrived ? ' And look: a new island drifted close in the night. İskele, the harbor!' : grew ? ` The island grew! New spot: ${opened.join(' and ')}.` : postcard ? ' The morning ferry brought a postcard.' : '';
  say(`While you slept, the island gathered ${fmt(made)} seeds${S.calm > 1 ? ` (calm ×${S.calm.toFixed(1)})` : ''}.${extra}`, arrived ? 'map' : 'collect');
  emote(grew || arrived ? 'excited' : 'relieved', 3000);
  if (grew && S.mode === 'isle' && S.isle === 'home') { for (const s of STATIONS.filter((x) => x.isle === 'home' && x.gate === S.stage)) { burst(s.slot[0], s.slot[1] - 10, 'sparkle', 14); tag(s.slot[0], s.slot[1] - 34, `New spot: <b>${s.name}</b>`, 6000); } moveCam(isleCam(), 1200); }
  if (S.mode === 'map') mapTags();
  renderChrome();
}
function fastForward(day) {
  fresh(); S.msg = null;
  const plans = {
    5: { levels: { garden: 3, cay: 2 }, seeds: 120, calm: 1.5, health: 74, used: 12, nights: 3 },
    8: { levels: { garden: 4, cay: 3, pond: 1 }, seeds: 140, calm: 1.6, health: 80, used: 20, nights: 6 },
    11: { levels: { garden: 4, cay: 3, pond: 2, simit: 1 }, seeds: 412, calm: 1.6, health: 82, used: 18, nights: 8, harbor: 9, postcards: 2, variant: { cay: 'blue' } },
    20: { levels: { garden: 5, cay: 4, pond: 3, workshop: 2, simit: 2, pier: 2, lighthouse: 1 }, seeds: 2310, calm: 1.8, health: 92, used: 30, nights: 9, harbor: 9, postcards: 7, variant: { cay: 'blue' } },
  };
  const p = plans[day];
  S.day = day; S.tended = day - 1; S.stage = stageFor(S.tended);
  Object.assign(S.levels, p.levels); S.seeds = p.seeds; S.calm = p.calm; S.health = p.health; S.variant = p.variant || {};
  S.used = p.used; S.calmNights = p.nights; S.postcards = p.postcards || 0;
  if (p.harbor) { S.arrived.harbor = p.harbor; S.visited.harbor = day > 11; }
  S.pending = Math.round(prodRate() * S.calm * 6);
  say(`Day ${day}. You stayed away most of the morning. The island gathered ${fmt(S.pending)} seeds.`, 'collect');
  Object.assign(cam, camFor(S.mode));
  clearTags(); mapTags();
  renderChrome();
}
function readout() {
  const el = document.getElementById('readout'); if (!el) return;
  el.innerHTML = [['Day', `${S.day} · home stage ${S.stage + 1}/5 · tended ${S.tended}`], ['Islands', `${isleCount()} of ${ISLES.length} · calm nights ${S.calmNights}`], ['Pofu', `${Math.round(S.health)} · ${mood()}`], ['Calm', `×${S.calm.toFixed(1)}${S.quickChain ? ' · a quick check just now' : ''}`],
    ['Guarded', `${fmt(S.used)} / ${BREATH_LIMIT} min${over() ? ` · next break: ${breathSecsFor(S.overOpens)} s, on tap` : ''}`], ['Seeds', `${fmt(S.seeds)} (+${fmt(S.pending)} waiting)`], ['Production', `${fmt(prodRate())}/h × calm, while away`],
    ['Built', STATIONS.filter((s) => lv(s.id)).map((s) => `${s.id} ${lv(s.id)}`).join(', ')]].map(([k, v]) => `<span>${k}</span><b>${v}</b>`).join('');
}

// ---------------------------------------------------------------- input
const panel = document.getElementById('panel');
function drawer(open) { document.body.classList.toggle('drawer-open', open); panel.setAttribute('aria-hidden', open || !isPhone() ? 'false' : 'true'); if (open) panel.scrollTop = 0; }
const isPhone = () => window.matchMedia('(max-width: 500px)').matches;
document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-ui],[data-act],[data-st],[data-var],[data-isle],[data-visit]');
  if (!el || el.disabled) return;
  if (el.dataset.var) { S.variant.cay = el.dataset.var; openStation('cay'); return; }
  if (el.dataset.st) return openStation(el.dataset.st);
  if (el.dataset.isle) return openIsle(el.dataset.isle);
  if (el.dataset.visit) return visit(el.dataset.visit);
  if (el.dataset.act) { drawer(false); return ACT[el.dataset.act](); }
  ({ collect, toVillage: () => toVillage(), toHome: () => toHome(), toMap: () => toMap(), closeSheet, upgrade, skip: () => resist(), open: () => wantOpen(false), quick: () => wantOpen(true),
    breathSkip: () => resist(true), breathStart: startBreath, breathOpen: () => openApp(S.breath ? S.breath.quick : false), quiet: quietHour, demo: () => drawer(true), demoClose: () => drawer(false) })[el.dataset.ui]?.();
});
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') { if (document.body.classList.contains('drawer-open')) drawer(false); else if (S.sheet && S.sheet !== 'hop' && S.sheet !== 'breath') closeSheet(); } });
// Canvas taps: a click (not pointerdown), so a touch that starts a scroll elsewhere never triggers it.
cvs.addEventListener('click', (e) => {
  const r = cvs.getBoundingClientRect();
  const [wx, wy] = toWorld(e.clientX - r.left, e.clientY - r.top);
  if (S.mode === 'home') { if (Math.hypot(wx - POFU.x, wy - POFU.y + 22) < 26) { emote(['excited', 'smug', 'proud'][Math.floor(Math.random() * 3)], 1800); return; } toVillage(); return; }
  if (S.mode === 'map') {
    let best = null;
    for (const isle of ISLES) { const rx = isle.id === 'home' ? (S.stage >= 2 ? 172 : 124) : isle.rx; const dx = (wx - isle.pos[0]) / rx, dy = (wy - isle.pos[1] - rx * 0.25) / (rx * 0.75); const d = Math.hypot(dx, dy); if (d < 1.15 && (!best || d < best.d)) best = { isle, d }; }
    if (best) openIsle(best.isle.id);
    return;
  }
  let best = null;
  for (const s of STATIONS.filter((x) => x.isle === S.isle)) { const p = isleById[s.isle].pos; const d = Math.hypot(wx - p[0] - s.slot[0], (wy - p[1] - s.slot[1] + 18) * 1.3); if (d < 44 && (!best || d < best.d)) best = { s, d }; }
  if (best) openStation(best.s.id);
});
const ACT = {
  resist: () => resist(), quiet: quietHour, reach: openHop, limit: useLimit, binge, night: () => setNight(), nextDay: () => nextDay(),
  map: () => toMap(), isle: () => setMode('isle', { isle: 'home' }),
  ff5: () => { S.mode = 'home'; fastForward(5); }, ff8: () => { S.mode = 'home'; fastForward(8); }, ff11: () => { S.mode = 'home'; fastForward(11); }, ff20: () => { S.mode = 'home'; fastForward(20); },
  reset: () => { fresh(); S.mode = 'home'; Object.assign(cam, homeCam()); document.getElementById('sheet-root').innerHTML = ''; clearTags(); renderChrome(); },
};

// Public API for tools/render.js and tools/check-mobile.js
window.G = { S: () => S, resist, quietHour, binge, useLimit, setNight, nextDay, openHop, openApp, wantOpen, openBreath, startBreath, openStation, openIsle, upgrade, collect, toVillage, toHome, toMap, visit, fastForward, emote, drawer, render: renderChrome,
  set: (o) => { Object.assign(S, o); renderChrome(); }, say: (t, a) => { say(t, a); renderChrome(); },
  breathAt: (ms) => { if (S.breath) { startBreath(); S.breath.t0 = now() - ms; } },
  lerpCam: (q, a = homeCam(), b = isleCam()) => { camTo = null; for (const k of ['x', 'y', 's', 'ay']) cam[k] = a[k] + (b[k] - a[k]) * q; } };

fresh();
layout();
window.addEventListener('resize', layout);
if (window.ResizeObserver) new ResizeObserver(layout).observe(screenEl);
Object.assign(cam, homeCam());
renderChrome();
drawer(false);
requestAnimationFrame(frame);
