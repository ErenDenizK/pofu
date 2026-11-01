// Pofu island game prototype (v2): Home close-up -> a fixed-camera painted
// diorama with stations on fixed slots. Care over currency: Pofu's health,
// the calm multiplier (grows while you stay away, resets when a guarded app
// opens), idle production collected on open, pre-planned station upgrades,
// island expansion, and Pofu's emotional range. Dependency-free.
// Everything except Pofu (production art R1) and Mochi (concept art) is a
// code stand-in. Spec: docs/product/game-design.md.
'use strict';

const Q = new URLSearchParams(location.search);
if (Q.get('bare') === '1') document.body.classList.add('bare');
if (Q.get('labels') === '0') document.body.classList.add('hide-labels');

// ---------------------------------------------------------------- tuning (mirrors tools/sim/island_economy.py)
const W = 402, H = 874;
const STAGE_NEED = [0, 1, 4, 10, 20, 34];      // tended days for stage 1..6
const COST_GROWTH = 2.3, RATE_GROWTH = 0.55;
const CALM_MAX = 2.0;
const STATIONS = [
  { id: 'garden', name: 'Sunflower garden', tr: 'Ayçiçeği bahçesi', stage: 0, rate: 6, build: 0, who: 'Pofu', slot: [-66, -4],
    levels: ['A small bed of three sunflowers', 'A picket fence and two more sunflowers', 'A watering can and a row of seedlings', 'A sunflower arch with bunting', 'One giant sunflower that turns to follow the sun'] },
  { id: 'cay', name: 'Çay ocağı', tr: 'Çay ocağı', stage: 1, rate: 5, build: 40, who: 'Mochi the bunny', slot: [64, -2],
    levels: ['A wooden counter, a çaydanlık, two tulip glasses', 'A striped awning', 'Two stools and a tiny table (choose a style)', 'String lights for the evening', 'A tiled roof, a geranium, a little flag'] },
  { id: 'simit', name: 'Simit stand', tr: 'Simitçi', stage: 2, rate: 8, build: 250, who: 'Simit the kitten', slot: [-132, 16],
    levels: ['A cart with a pile of simit', 'A sun umbrella', 'A simit pole, stacked high', 'A bench for regulars', 'A little kiosk with a flag'] },
  { id: 'pond', name: 'Lily pond', tr: 'Nilüferli gölet', stage: 2, rate: 4, build: 200, who: 'the frogs', slot: [132, 18],
    levels: ['A small pond ringed with pebbles', 'Lily pads, one per calm night', 'Reeds and a blossom', 'A wooden dock', 'Floating lanterns'] },
  { id: 'library', name: 'Library', tr: 'Kütüphane', stage: 3, rate: 10, build: 700, who: 'Bulut the chinchilla', slot: [-62, -74],
    levels: ['A round book hut', 'A lit window and a book stack', 'A second floor', 'A reading bench and lamp', 'A tower with a flag'] },
  { id: 'workshop', name: 'Workshop', tr: 'Atölye', stage: 3, rate: 10, build: 800, who: 'Fındık the hedgehog', slot: [62, -70],
    levels: ['A shed and a workbench', 'A wall of tools', 'A spinning wind vane', 'A chimney', 'A big gear sign'] },
  { id: 'observatory', name: 'Observatory', tr: 'Gözlemevi', stage: 4, rate: 14, build: 1800, who: 'Pofu, at night', slot: [226, -118],
    levels: ['A small dome', 'A brass telescope', 'A star map wall', 'A second dome', 'A beacon'] },
  { id: 'hamam', name: 'Hamam', tr: 'Hamam', stage: 5, rate: 16, build: 2400, who: 'everyone', slot: [-222, -92],
    levels: ['One dome, one basin', 'Steam and towels', 'Two small domes', 'Lanterns', 'A garden courtyard'] },
];
const stById = Object.fromEntries(STATIONS.map((s) => [s.id, s]));
function cost(st, to) { return st.id === 'garden' ? (to === 1 ? 0 : Math.round(30 * COST_GROWTH ** (to - 2))) : Math.round(st.build * COST_GROWTH ** (to - 1)); }
function rate(st, L) { return L ? st.rate * (1 + RATE_GROWTH * (L - 1)) : 0; }
const POFU = { x: 6, y: 20 };
const POFU_W = 52, HOME_S = 2.6, HOME_FEET = 594;

// ---------------------------------------------------------------- state
let S;
function fresh() {
  S = {
    day: 1, tended: 0, stage: 0, health: 72, calm: 1.3, goodies: 0, pending: 34, levels: { garden: 1 }, variant: {},
    beads: [], night: false, mode: 'home', msg: null, emotion: null, skipsHealed: 0, caughtUp: false, calmFlash: null,
    neighbor: null, reveal: null,
  };
  for (const st of STATIONS) S.levels[st.id] ??= 0;
  say('Good morning! While you were away, the garden made 34 goodies.', 'collect');
}
const lv = (id) => S.levels[id] || 0;
const stageFor = (t) => STAGE_NEED.reduce((s, need, i) => (t >= need ? i : s), 0);
const prodRate = () => STATIONS.reduce((s, st) => s + rate(st, lv(st.id)), 0) * (S.health < 25 ? 0.6 : 1);
function mood() {
  const h = S.health;
  return h >= 75 ? 'Cozy' : h >= 50 ? 'Content' : h >= 25 ? 'Tired' : h >= 12 ? 'Unwell' : 'Curled up';
}

// ---------------------------------------------------------------- camera
let cam = { x: 0, y: 0, s: HOME_S, ay: HOME_FEET };
let camFrom = null, camTo = null, camT0 = 0, camDur = 900;
const now = () => performance.now();
function homeCam() { return { x: POFU.x, y: POFU.y, s: HOME_S, ay: HOME_FEET }; }
function villageCam() {
  const st = S.stage;
  if (st <= 1) return { x: 0, y: -14, s: 1.5, ay: 400 };
  if (st === 2) return { x: 0, y: -20, s: 1.12, ay: 410 };
  if (st === 3) return { x: 0, y: -40, s: 1.1, ay: 430 };
  return { x: 0, y: -52, s: st === 4 ? 0.98 : 0.86, ay: 430 };
}
function moveCam(to, dur = 900) { camFrom = { ...cam }; camTo = to; camT0 = now(); camDur = dur; }
const ease = (t) => 1 - Math.pow(1 - t, 3);

// ---------------------------------------------------------------- canvas helpers
const cvs = document.getElementById('world');
const ctx = cvs.getContext('2d');
const DPR = 2;
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
const stars = Array.from({ length: 60 }, (_, i) => ({ x: (i * 73.3) % 402, y: (i * 41.7) % 520, r: 0.6 + (i % 3) * 0.45, ph: i }));
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
const RESIDENT = { cay: ['bunny', 26, 8], simit: ['kitten', 26, 6], library: ['chin', 30, 6], workshop: ['hog', -30, 6] };

// ---------------------------------------------------------------- Pofu and his faces (code stand-ins for the face edits)
const EYE = [[0.339, 0.44], [0.675, 0.44]], MOUTH = [0.509, 0.515], CHEEK = [[0.27, 0.56], [0.75, 0.56]];
const FUR = '#FCF4EC';
function emotionNow() { return S.emotion && now() < S.emotion.until ? S.emotion.kind : baseEmotion(); }
function baseEmotion() { if (S.night) return 'sleepy'; if (S.health < 25) return 'unwell'; if (S.calm >= CALM_MAX) return 'smug'; return null; }
function emote(kind, ms = 4200) { S.emotion = { kind, until: now() + ms, t0: now() }; }
function drawPofuAt(c, x, y, w, t, kind) {
  if (!pofuImg.complete) return;
  const h = w * pofuImg.height / pofuImg.width;
  const br = Math.sin(t / 3200 * Math.PI * 2);
  const e0 = S.emotion ? (t - S.emotion.t0) / 1000 : 9;
  let sx = 1 + 0.012 * br, sy = 1 + 0.022 * br, rot = 0, dx = 0, dy = 0;
  if (kind === 'pout') { sy *= 0.97; sx *= 1.03; rot = 0.05; }
  if (kind === 'jealous') { rot = -0.07; dx = -w * 0.03; }
  if (kind === 'smug') { rot = -0.04; sy *= 1.02; }
  if (kind === 'worried') { dx = Math.sin(t / 60) * w * 0.006; }
  if (kind === 'unwell') { sy *= 0.9; sx *= 1.04; }
  if (kind === 'excited' || kind === 'proud') { dy = -Math.abs(Math.sin(e0 * 6)) * w * 0.12 * Math.max(0, 1 - e0 / 1.6); }
  if (kind === 'relieved') { sy *= 1 + 0.03 * Math.max(0, 1 - e0); }
  softShadow(c, x, y + 1, w * 0.4, w * 0.12, 0.3);
  c.save(); c.translate(x + dx, y + dy); c.rotate(rot); c.scale(sx, sy);
  if (kind === 'unwell') c.filter = 'saturate(.62) brightness(.97)';
  if (S.night) c.filter = 'brightness(.82) saturate(.85) hue-rotate(-8deg)';
  const X = (u) => -w / 2 + u * w, Y = (v) => -h * 0.985 + v * h;
  c.drawImage(pofuImg, -w / 2, -h * 0.985, w, h);
  c.filter = 'none';
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
  if (kind === 'sleepy' || kind === 'unwell') { closed(...EYE[0], false); closed(...EYE[1], false); if (kind === 'unwell') mouth((mx, my, m) => { c.moveTo(mx - m, my + m * 0.2); c.quadraticCurveTo(mx - m * 0.5, my - m * 0.3, mx, my + m * 0.1); c.quadraticCurveTo(mx + m * 0.5, my + m * 0.4, mx + m, my - m * 0.1); }); }
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

// ---------------------------------------------------------------- render
let particles = [];
function burst(wx, wy, kind = 'sparkle', n = 10) { for (let i = 0; i < n; i++) particles.push({ x: wx, y: wy, vx: (Math.random() - 0.5) * 34, vy: -12 - Math.random() * 26, t0: now(), life: 900 + Math.random() * 600, kind }); }
function goodieIcon(c, x, y, r, a = 1) { c.globalAlpha = a; c.save(); c.translate(x, y); c.rotate(0.5); ellipse(c, 0, 0, r * 0.55, r, '#F5B83D'); c.strokeStyle = '#7A4A12'; c.lineWidth = r * 0.18; c.beginPath(); c.moveTo(0, -r * 0.8); c.lineTo(0, r * 0.8); c.stroke(); c.restore(); c.globalAlpha = 1; }
let lastPop = 0;
function frame() {
  const t = now();
  if (camTo) { const q = Math.min(1, (t - camT0) / camDur), e = ease(q); for (const k of ['x', 'y', 's', 'ay']) cam[k] = camFrom[k] + (camTo[k] - camFrom[k]) * e; if (q >= 1) camTo = null; }
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  drawSky(t); drawSea(t);
  ctx.setTransform(DPR * cam.s, 0, 0, DPR * cam.s, DPR * (W / 2 - cam.x * cam.s), DPR * (cam.ay - cam.y * cam.s));
  const st = S.stage;
  // islets behind
  if (st >= 4) { islet(ctx, 226, -118, 48, t); bridge(ctx, { x: 150, y: -60 }, { x: 196, y: -112 }); }
  if (st >= 5) { islet(ctx, -222, -92, 50, t); bridge(ctx, { x: -150, y: -50 }, { x: -190, y: -88 }); }
  const big = st >= 2;
  islandBody(ctx, 0, 0, big ? 172 : 124, big ? 56 : 42, big ? 150 : 110, true);
  if (st >= 3) terrace(ctx, t);
  // sorted scene: stations, plots, residents, Pofu (by y)
  const items = [];
  for (const s of STATIONS) {
    if (s.stage > st + (s.stage === st + 1 && st < 5 ? 1 : 0) + 0) { /* hidden until the stage before */ }
    const L = lv(s.id);
    const visible = s.stage <= st || (s.stage === st + 1 && ((s.slot[1] > -40 && s.stage <= 2) || (st >= 2 && s.stage === 3)));
    if (!visible) continue;
    if ((s.stage === 4 && st < 4) || (s.stage === 5 && st < 5)) continue;
    items.push({ y: s.slot[1], f: () => { ctx.save(); ctx.translate(...s.slot); const pop = S.popT && S.popT.id === s.id ? (t - S.popT.t) / 700 : 2; if (pop < 1) { const k = 0.85 + 0.15 * pop + 0.12 * Math.sin(pop * Math.PI); ctx.scale(k, k); } ctx.scale(1.3, 1.3); softShadow(ctx, 0, 1, 32, 8, 0.18); if (L) DRAW[s.id](ctx, L, t); else plot(ctx, s, t, s.stage <= st); ctx.restore(); } });
    const r = RESIDENT[s.id];
    if (r && L) items.push({ y: s.slot[1] + r[2], f: () => critter(ctx, r[0], s.slot[0] + r[1] * 1.3, s.slot[1] + r[2], t, 1.35) });
  }
  const kind = emotionNow();
  items.push({ y: POFU.y, f: () => drawPofuAt(ctx, POFU.x, POFU.y, POFU_W, t, kind) });
  items.sort((a, b) => a.y - b.y).forEach((i) => i.f());
  if (S.night) { ctx.save(); ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.globalCompositeOperation = 'multiply'; ctx.fillStyle = '#6E66A6'; ctx.fillRect(0, 0, W, H); ctx.restore(); ctx.globalCompositeOperation = 'source-over'; drawGlows(t); }
  // idle production: a goodie pops from a working station now and then
  if (!S.night && t - lastPop > 1300 && S.health >= 12) { lastPop = t; const built = STATIONS.filter((s) => lv(s.id) && (s.stage <= st)); const s = built[Math.floor(Math.random() * built.length)]; if (s) particles.push({ x: s.slot[0] + (Math.random() - 0.5) * 20, y: s.slot[1] - 30, vx: 0, vy: -10, t0: t, life: 1400, kind: 'goodie' }); }
  particles = particles.filter((p) => t - p.t0 < p.life);
  for (const p of particles) {
    const k = (t - p.t0) / p.life, d = (t - p.t0) / 1000;
    const x = p.x + p.vx * d, y = p.y + p.vy * d + (p.kind === 'goodie' ? 0 : 22 * d * d);
    if (p.kind === 'goodie') goodieIcon(ctx, x, y, 3.2, Math.sin(k * Math.PI));
    else if (p.kind === 'seed') goodieIcon(ctx, x, y, 2.4, 1 - k);
    else sparkle(ctx, x, y, 2.4 * (1 - k * 0.5), 1 - k);
  }
  const hop = document.getElementById('hopPofu');
  if (hop) { const c2 = hop.getContext('2d'); c2.setTransform(1, 0, 0, 1, 0, 0); c2.clearRect(0, 0, hop.width, hop.height); c2.setTransform(2, 0, 0, 2, 0, 0); drawPofuAt(c2, 90, 168, 150, t, 'jealous'); }
  positionTags();
  requestAnimationFrame(frame);
}
function drawGlows(t) {
  const glow = (x, y, r, a) => { const g = ctx.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, `rgba(255,206,110,${a})`); g.addColorStop(1, 'rgba(255,206,110,0)'); ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2); };
  if (lv('cay') >= 4) glow(64, -36, 30, 0.5);
  if (lv('library') >= 2) glow(-62, -74 - (lv('library') >= 3 ? 38 : 24) + 4, 14, 0.7);
  glow(-124 * 0.52 + (S.stage >= 2 ? -24 : 0), 52, 16, 0.5);
}

// world-anchored tags
let tags = [];
function tag(wx, wy, html, ms = 3200) { const el = document.createElement('div'); el.className = 'tag'; el.innerHTML = html; document.getElementById('fx').appendChild(el); const r = { el, wx, wy }; tags.push(r); setTimeout(() => { el.remove(); tags = tags.filter((x) => x !== r); }, ms); }
function positionTags() { for (const r of tags) { r.el.style.left = Math.max(78, Math.min(W - 78, (r.wx - cam.x) * cam.s + W / 2)) + 'px'; r.el.style.top = (r.wy - cam.y) * cam.s + cam.ay + 'px'; } }
function clearTags() { tags.forEach((r) => r.el.remove()); tags = []; }

// ---------------------------------------------------------------- chrome
const ICON = {
  gear: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3.2"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>`,
  chev: `<svg class="chev" width="10" height="16" viewBox="0 0 10 16" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M2 2l6 6-6 6"/></svg>`,
  home: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11.5 12 5l8 6.5"/><path d="M6.5 10v8.5h11V10"/></svg>`,
  isle: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><ellipse cx="12" cy="10" rx="9" ry="3.2"/><path d="M3.5 11c1.5 5 5 8.5 8.5 9.5 3.5-1 7-4.5 8.5-9.5"/><path d="M9 9.5V6l3-2 3 2v3.5"/></svg>`,
  heart: (low) => `<svg width="22" height="22" viewBox="0 0 24 24"><path d="M12 20.5s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.6a4.3 4.3 0 0 1 7.5 2.7c0 5.6-7.5 10.2-7.5 10.2z" fill="${low ? '#D9BCC4' : '#F48C9A'}"/><path d="M8 9.5a2 2 0 0 1 2-1.4" stroke="#fff" stroke-width="1.4" fill="none" stroke-linecap="round" opacity=".8"/></svg>`,
  basket: (s = 22) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24"><path d="M4 10h16l-1.6 8.2a2 2 0 0 1-2 1.6H7.6a2 2 0 0 1-2-1.6z" fill="#E2A86C"/><path d="M5.2 13h13.6M6 16h12" stroke="#B87650" stroke-width="1.2"/><g transform="rotate(25 9 8)"><ellipse cx="9" cy="8" rx="1.8" ry="3" fill="#F5B83D"/></g><g transform="rotate(-20 14 7.5)"><ellipse cx="14" cy="7.5" rx="1.8" ry="3" fill="#F7C873"/></g><circle cx="11.5" cy="9" r="2.2" fill="none" stroke="#C98635" stroke-width="1.4"/><path d="M7 10c0-4 10-4 10 0" stroke="#B87650" stroke-width="1.4" fill="none"/></svg>`,
  ig: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="4" y="4" width="16" height="16" rx="5"/><circle cx="12" cy="12" r="3.6"/><circle cx="17" cy="7" r=".9" fill="#fff"/></svg>`,
  up: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V6M6 11l6-6 6 6"/></svg>`,
};
const sig = (c) => `<svg width="18" height="12" viewBox="0 0 18 12" fill="${c}"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>`;
const wifi = (c) => `<svg width="17" height="12" viewBox="0 0 17 12" fill="${c}"><path d="M8.5 2.3c2.4 0 4.6.9 6.2 2.5l1.2-1.2A10.4 10.4 0 0 0 8.5.6 10.4 10.4 0 0 0 1.1 3.6l1.2 1.2a8.7 8.7 0 0 1 6.2-2.5zm0 3.4c1.5 0 2.8.6 3.8 1.5l1.2-1.2a7 7 0 0 0-10 0l1.2 1.2c1-.9 2.3-1.5 3.8-1.5zm0 3.4c.6 0 1.1.2 1.5.6L8.5 11.2 7 9.7c.4-.4.9-.6 1.5-.6z"/></svg>`;
const batt = (c) => `<svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="${c}" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2.5" fill="${c}"/><path d="M25 4.5v4a2.2 2.2 0 0 0 0-4z" fill="${c}" opacity=".45"/></svg>`;
function ring(calm) { const full = calm >= CALM_MAX; const p = full ? 1 : ((calm * 10) % 1) || 0.35; const r = 12, C = 2 * Math.PI * r; return `<svg width="30" height="30" viewBox="0 0 30 30"><circle cx="15" cy="15" r="${r}" fill="none" stroke="rgba(95,181,122,.2)" stroke-width="3.5"/><circle cx="15" cy="15" r="${r}" fill="none" stroke="#5FB57A" stroke-width="3.5" stroke-linecap="round" stroke-dasharray="${(C * (calm - 1)).toFixed(1)} ${C.toFixed(1)}" transform="rotate(-90 15 15)"/><circle cx="15" cy="15" r="4" fill="#5FB57A" opacity="${full ? 1 : 0.55}"/></svg>`; }
const fmt = (n) => Math.round(n).toLocaleString('en-US');

function nextGoal() {
  const opts = STATIONS.filter((s) => s.stage <= S.stage && lv(s.id) < 5).map((s) => ({ s, c: cost(s, lv(s.id) + 1) }));
  opts.sort((a, b) => a.c - b.c);
  return opts[0];
}
function say(text, act) { S.msg = text ? { text, act } : null; }

function renderChrome() {
  const root = document.getElementById('chrome');
  document.getElementById('screen').classList.toggle('dark', S.night);
  const c = S.night ? '#fff' : '#2A1F2D';
  const home = S.mode === 'home';
  const skips = S.beads.filter((b) => b === 'S').length;
  const low = S.health < 25;
  const full = S.calm >= CALM_MAX;
  const flash = S.calmFlash && now() - S.calmFlash < 1000;
  const g = nextGoal();
  const bubbleBottom = 874 - (HOME_FEET - POFU_W * 0.95 * HOME_S) + 14;
  let bubble = '';
  if (S.msg && home) {
    const b = S.msg.act === 'collect' ? `<button class="chipbtn press" data-ui="collect">${ICON.basket(18)}Collect ${fmt(S.pending)}</button>`
      : S.msg.act === 'island' ? `<button class="chipbtn press" data-ui="toVillage">${ICON.isle}See the island</button>`
      : S.msg.act === 'heal' ? `<button class="chipbtn press" data-ui="quiet">Quiet hour together</button>` : '';
    bubble = `<div class="bubble" style="bottom:${bubbleBottom}px">${S.msg.text}${b}</div>`;
  }
  root.innerHTML = `
    <div class="status"><span>9:41</span><div class="di"></div><span class="icons">${sig(c)}${wifi(c)}${batt(c)}</span></div>
    <div class="layer ${home ? '' : 'off'}">
      <div class="topbar">
        <button class="glass care press ${low ? 'low' : ''}" aria-label="Pofu is ${mood()}">${ICON.heart(low)}<span class="bar"><i style="width:${Math.max(6, S.health)}%"></i></span><span class="mood">${mood()}</span></button>
        <span class="spacer"></span>
        <button class="glass circle press" aria-label="Friends"><span class="avatar">D</span></button>
        <button class="glass circle press" aria-label="Settings">${ICON.gear}</button>
      </div>
      ${S.night ? '' : `<div class="glass calm ${flash ? 'reset' : ''} ${full ? 'full' : ''}">${ring(S.calm)}<span class="x">Calm ×${S.calm.toFixed(1)}</span><small>${full ? 'full' : flash ? 'starts again now' : 'growing'}</small></div>`}
      ${bubble}
      <div class="bottom">
        <button class="today press"><div class="grow"><div class="big">${S.beads.length ? `${skips} of ${S.beads.length} skipped` : 'No reaches yet'}<small>today</small></div>
          <div class="beads">${S.beads.map((b) => `<span class="bead ${b === 'S' ? 's' : 'o'}"></span>`).join('')}</div></div>${ICON.chev}</button>
        <div class="actions"><button class="glass prominent primary press" data-ui="quiet">Quiet time with Pofu</button><button class="glass secondary press" data-ui="toVillage" aria-label="The island">${ICON.isle}</button></div>
      </div>
    </div>
    <div class="layer ${home ? 'off' : ''}">
      <div class="topbar">
        <button class="glass circle press" data-ui="toHome" aria-label="Back to Pofu">${ICON.home}</button>
        <span class="spacer"></span>
        <div class="glass title-cap">Day ${S.day} <small>· stage ${S.stage + 1}/6</small></div>
        <span class="spacer"></span>
        <button class="glass pill press" data-ui="${S.pending ? 'collect' : ''}">${ICON.basket(24)}<span class="num">${fmt(S.goodies)}</span>${S.pending ? `<span class="plus">+${fmt(S.pending)}</span>` : ''}</button>
      </div>
      <div class="bottom">
        ${g ? `<button class="next press" data-st="${g.s.id}"><div class="grow"><div class="t">${g.s.name} → level ${lv(g.s.id) + 1}</div>
          <div class="s">${S.goodies >= g.c ? `Ready · ${fmt(g.c)} goodies` : `${fmt(S.goodies)} of ${fmt(g.c)} goodies · residents are on it`}</div>
          <div class="prog"><i style="width:${Math.min(100, (S.goodies / g.c) * 100)}%"></i></div></div>${ICON.chev}</button>` : ''}
        <div class="actions">${S.night ? `<button class="glass prominent primary" disabled>The island sleeps until 6:00</button>`
          : g && S.goodies >= g.c ? `<button class="glass prominent primary press" data-st="${g.s.id}">${ICON.up}Upgrade ${g.s.name}</button>`
          : `<button class="glass primary press" data-ui="toHome">All caught up · back to Pofu</button>`}</div>
      </div>
    </div>`;
  readout();
}
function toast(text) { const el = document.createElement('div'); el.className = 'glass toast'; el.textContent = text; document.getElementById('screen').appendChild(el); setTimeout(() => el.remove(), 2700); }

// ---------------------------------------------------------------- sheets
function closeSheet() { document.getElementById('sheet-root').innerHTML = ''; S.sheet = null; renderChrome(); }
function openStation(id) {
  if (S.night) return toast('The island sleeps until 6:00');
  const s = stById[id]; const L = lv(id);
  if (s.stage > S.stage) return toast(`${s.name} opens at stage ${s.stage + 1}`);
  S.sheet = id;
  const to = L + 1, c = cost(s, to), maxed = L >= 5;
  const can = !maxed && S.goodies >= c;
  const variant = to === 3 && id === 'cay';
  const root = document.getElementById('sheet-root');
  root.innerHTML = `<div class="scrim" data-ui="closeSheet"></div>
    <div class="sheet station-sheet" role="dialog" aria-label="${s.name}">
      <div class="grabber"></div>
      <div class="head"><canvas width="184" height="160" id="stThumb"></canvas>
        <div><div class="who">${s.who}</div><h3 style="display:block">${s.name}</h3>
        <div class="lvl">${L ? `Level ${L} of 5 · ${fmt(rate(s, L))} goodies an hour` : 'Not built yet'}</div>
        <div class="pips">${[1, 2, 3, 4, 5].map((i) => `<i class="${i <= L ? 'f' : i === to ? 'n' : ''}"></i>`).join('')}</div></div></div>
      ${maxed ? `<div class="box"><b>Complete.</b><p>Every level is built. ${s.who === 'Pofu' ? 'Pofu' : s.who.split(' ')[0]} is very proud of it.</p></div>` : `
      <div class="box"><b>Level ${to}:</b> <p>${s.levels[to - 1]}.</p>
        <div class="row2"><span>${L ? `+${fmt(rate(s, to) - rate(s, L))} goodies an hour` : `${fmt(rate(s, 1))} goodies an hour`}</span><span>${ICON.basket(15)} ${fmt(Math.min(S.goodies, c))} / ${fmt(c)}</span></div>
        <div class="prog"><i style="width:${Math.min(100, S.goodies / c * 100)}%"></i></div>
        ${variant ? `<div class="variants"><button class="${S.variant.cay !== 'blue' ? 'on' : ''}" data-var="red"><span class="sw" style="background:#E9696F"></span>Rose stripes</button><button class="${S.variant.cay === 'blue' ? 'on' : ''}" data-var="blue"><span class="sw" style="background:#7EA6D8"></span>İznik blue</button></div>` : ''}
      </div>
      <button class="glass prominent go press" data-ui="upgrade" ${can ? '' : 'disabled'}>${can ? `${ICON.up}${L ? 'Upgrade' : 'Build'} · ${fmt(c)}` : `About ${Math.ceil((c - S.goodies) / Math.max(1, prodRate() * S.calm))} h of calm away`}</button>`}
    </div>`;
  const tc = document.getElementById('stThumb').getContext('2d'); tc.setTransform(2, 0, 0, 2, 0, 0); tc.translate(46, 66); const k = id === 'observatory' || id === 'hamam' ? 0.85 : 1; tc.scale(k, k);
  if (L) DRAW[id](tc, Math.max(1, L), now()); else plot(tc, s, now(), true);
}
function upgrade() {
  const id = S.sheet, s = stById[id], to = lv(id) + 1, c = cost(s, to);
  if (S.goodies < c) return;
  S.goodies -= c; S.levels[id] = to; S.popT = { id, t: now() };
  closeSheet();
  burst(s.slot[0], s.slot[1] - 20, 'sparkle', 16);
  tag(s.slot[0], s.slot[1] - 46, `<b>${s.name}</b> · level ${to}`, 2600);
  emote('excited', 2600);
  renderChrome();
}
function openHop() {
  closeSheet(); S.night = false;
  const lossH = S.health >= 50 ? 'a bit tired' : 'unwell';
  const lines = ['Instagram again? What does it have that I don’t?', 'Oh. TikTok. I see how it is.', 'Is it more interesting than me? Be honest.'];
  document.getElementById('sheet-root').innerHTML = `<div class="hop" role="dialog" aria-label="Hop!">
    <div class="app"><span class="ig">${ICON.ig}</span>Instagram · 3rd reach this hour</div>
    <h2>Hop!</h2>
    <canvas class="pofu" id="hopPofu" width="360" height="360"></canvas>
    <div class="quip">“${lines[(S.day + S.beads.length) % lines.length]}”</div>
    <div class="loss">
      <div><div class="k">Calm built up</div><div class="v"><span class="from">×${S.calm.toFixed(1)}</span>→<span class="to">×1.0</span></div></div>
      <div><div class="k">Pofu</div><div class="v"><span class="from" style="color:#E9696F">${mood().toLowerCase()}</span>→<span class="to">${lossH}</span></div></div>
    </div>
    <div class="spacer"></div>
    <button class="spend press" data-ui="open">Open for 15 minutes</button>
    <button class="glass prominent skip press" data-ui="skip">Skip it</button>
    <div class="fine">Skipping keeps your calm growing.</div>
  </div>`;
  S.sheet = 'hop';
}

// ---------------------------------------------------------------- actions
function toVillage(instant) { if (S.mode === 'village') return; S.mode = 'village'; instant ? Object.assign(cam, villageCam()) : moveCam(villageCam(), 1000); renderChrome(); }
function toHome(instant) { document.getElementById('sheet-root').innerHTML = ''; S.mode = 'home'; instant ? Object.assign(cam, homeCam()) : moveCam(homeCam(), 900); if (S.caughtUp && !S.msg) say('All caught up. Nothing is waiting; the island keeps going without you.'); renderChrome(); }
function collect() {
  if (!S.pending) return;
  burst(POFU.x, POFU.y - 30, 'seed', 16);
  S.goodies += S.pending; S.pending = 0; S.caughtUp = true;
  const g = nextGoal();
  say(g && S.goodies >= g.c ? `Enough for the ${g.s.name.toLowerCase()}! Want to see?` : 'Saved in the pantry. That’s everything for now.', g && S.goodies >= g.c ? 'island' : null);
  if (S.mode === 'village') S.msg = null;
  renderChrome();
}
function resist() {
  closeSheet(); S.night = false;
  S.beads.push('S');
  if (S.skipsHealed < 6) { S.skipsHealed++; S.health = Math.min(100, S.health + 1); }
  const quips = [['proud', `Skipped! Calm keeps growing: ×${S.calm.toFixed(1)}.`], ['relieved', 'Phew. You came back to me.'], ['proud', 'We did that. Together. Mostly you.']];
  const [k, line] = quips[(S.beads.length - 1) % quips.length];
  emote(k, 3000); say(line); renderChrome();
}
function quietHour() {
  closeSheet();
  if (S.night) return toast('Bedtime: calm holds until morning');
  const wasLow = S.health < 25;
  const before = S.calm;
  const avg = Math.min(CALM_MAX, S.calm + 0.15);
  S.pending += Math.round(prodRate() * avg);
  S.calm = Math.min(CALM_MAX, Math.round((S.calm + 0.3) * 10) / 10);
  S.health = Math.min(100, S.health + (wasLow ? 14 : 5));
  if (S.calm >= CALM_MAX && before < CALM_MAX) { emote('smug', 5000); say('Calm ×2.0. Maxed out. I’m basically a zen master now.', 'collect'); }
  else if (wasLow) { emote('relieved', 4000); say('That helped. I’m feeling more like myself.', 'collect'); }
  else { emote('proud', 2200); say(`A quiet hour. Calm ×${S.calm.toFixed(1)} and climbing.`, 'collect'); }
  renderChrome();
}
function openApp() {
  closeSheet();
  S.beads.push('O');
  S.calm = 1.0; S.calmFlash = now();
  S.health = Math.max(5, S.health - 8);
  emote('pout', 5000);
  say('Hmph. Calm’s back to ×1.0. Fine. It’ll grow again.');
  renderChrome();
  setTimeout(renderChrome, 1050);
}
function binge() {
  closeSheet();
  for (let i = 0; i < 4; i++) S.beads.push('O');
  S.calm = 1.0; S.health = 16; S.calmFlash = now();
  emote('worried', 2500);
  say('That was a long one. I feel a bit wobbly. Sit with me for a quiet hour?', 'heal');
  renderChrome(); setTimeout(renderChrome, 1050);
}
function setNight(v) { S.night = v === undefined ? !S.night : v; closeSheet(); say(S.night ? 'Sleep well. The residents are closing up too.' : 'Good morning!'); renderChrome(); }
function nextDay(silent) {
  document.getElementById('sheet-root').innerHTML = '';
  const calmNight = S.health >= 25;
  const made = Math.round(prodRate() * (S.calm + (calmNight ? 0.1 : 0)) * 9);
  S.pending += made;
  S.day++; S.tended++;
  const before = S.stage; S.stage = stageFor(S.tended);
  if (S.health < 60) S.health += 0.3 * (60 - S.health);   // Pofu sleeps it off
  if (calmNight) { S.health = Math.min(100, S.health + 10); S.calm = Math.min(CALM_MAX, Math.round((S.calm + 0.2) * 10) / 10); }
  S.beads = []; S.night = false; S.skipsHealed = 0; S.caughtUp = false;
  if (silent) return;
  const grew = S.stage > before;
  const opened = STATIONS.filter((s) => s.stage === S.stage && grew).map((s) => s.name);
  say(`While you slept, the residents made ${fmt(made)} goodies${S.calm > 1 ? ` (calm ×${S.calm.toFixed(1)})` : ''}.${grew ? ` The island grew! New spot${opened.length > 1 ? 's' : ''}: ${opened.join(' and ')}.` : ''}`, 'collect');
  emote(grew ? 'excited' : 'relieved', 3000);
  if (grew) { S.reveal = now(); for (const s of STATIONS.filter((x) => x.stage === S.stage)) { burst(s.slot[0], s.slot[1] - 10, 'sparkle', 14); tag(s.slot[0], s.slot[1] - 34, `New spot: <b>${s.name}</b>`, 6000); } if (S.mode === 'village') moveCam(villageCam(), 1200); }
  renderChrome();
}
function fastForward(day) {
  fresh(); S.msg = null;
  const plans = {
    2: { levels: { garden: 2 }, goodies: 18, calm: 1.4, health: 78 },
    5: { levels: { garden: 3, cay: 2 }, goodies: 120, calm: 1.5, health: 74 },
    11: { levels: { garden: 4, cay: 3, simit: 2, pond: 1 }, goodies: 412, calm: 1.6, health: 82, variant: { cay: 'blue' } },
    36: { levels: { garden: 5, cay: 5, simit: 4, pond: 4, library: 3, workshop: 3, observatory: 2, hamam: 1 }, goodies: 2310, calm: 1.8, health: 92, variant: { cay: 'blue' } },
  };
  const p = plans[day];
  S.day = day; S.tended = day - 1; S.stage = stageFor(S.tended);
  Object.assign(S.levels, p.levels); S.goodies = p.goodies; S.calm = p.calm; S.health = p.health; S.variant = p.variant || {};
  S.pending = Math.round(prodRate() * S.calm * 6);
  say(`Day ${day}. You stayed away most of the morning. The residents made ${fmt(S.pending)} goodies.`, 'collect');
  Object.assign(cam, S.mode === 'home' ? homeCam() : villageCam());
  renderChrome();
}
function readout() {
  const el = document.getElementById('readout'); if (!el) return;
  el.innerHTML = [['Day', `${S.day} (stage ${S.stage + 1}/6, tended ${S.tended})`], ['Pofu', `${Math.round(S.health)} · ${mood()}`], ['Calm', `×${S.calm.toFixed(1)}`], ['Goodies', `${fmt(S.goodies)} (+${fmt(S.pending)} waiting)`], ['Production', `${fmt(prodRate())}/h × calm`], ['Stations', STATIONS.filter((s) => lv(s.id)).map((s) => `${s.id} ${lv(s.id)}`).join(', ')]].map(([k, v]) => `<span>${k}</span><b>${v}</b>`).join('');
}

// ---------------------------------------------------------------- input
document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-ui],[data-act],[data-st],[data-var]');
  if (!el) return;
  if (el.dataset.var) { S.variant.cay = el.dataset.var; openStation('cay'); return; }
  if (el.dataset.st) return openStation(el.dataset.st);
  if (el.dataset.act) return ACT[el.dataset.act]();
  ({ collect, toVillage: () => toVillage(), toHome: () => toHome(), closeSheet, upgrade, skip: resist, open: openApp, quiet: quietHour })[el.dataset.ui]?.();
});
cvs.addEventListener('pointerdown', (e) => {
  const r = cvs.getBoundingClientRect(); const sx = (e.clientX - r.left) * W / r.width, sy = (e.clientY - r.top) * H / r.height;
  const wx = (sx - W / 2) / cam.s + cam.x, wy = (sy - cam.ay) / cam.s + cam.y;
  if (S.mode === 'home') { if (Math.hypot(wx - POFU.x, wy - POFU.y + 22) < 26) { emote(['excited', 'smug', 'proud'][Math.floor(Math.random() * 3)], 1800); return; } toVillage(); return; }
  let best = null;
  for (const s of STATIONS) { const d = Math.hypot(wx - s.slot[0], (wy - s.slot[1] + 18) * 1.3); if (d < 40 && (!best || d < best.d)) best = { s, d }; }
  if (best) openStation(best.s.id);
});
const ACT = {
  resist, quiet: quietHour, reach: openHop, binge, night: () => setNight(), nextDay: () => nextDay(),
  ff5: () => { S.mode = 'home'; fastForward(5); }, ff11: () => { S.mode = 'home'; fastForward(11); }, ff36: () => { S.mode = 'home'; fastForward(36); },
  reset: () => { fresh(); S.mode = 'home'; Object.assign(cam, homeCam()); document.getElementById('sheet-root').innerHTML = ''; clearTags(); renderChrome(); },
};

// Public API for tools/render.js
window.G = { S: () => S, resist, quietHour, binge, setNight, nextDay, openHop, openApp, openStation, upgrade, collect, toVillage, toHome, fastForward, emote, render: renderChrome,
  set: (o) => { Object.assign(S, o); renderChrome(); }, say: (t, a) => { say(t, a); renderChrome(); },
  lerpCam: (q) => { const a = homeCam(), b = villageCam(); for (const k of ['x', 'y', 's', 'ay']) cam[k] = a[k] + (b[k] - a[k]) * q; } };

fresh();
Object.assign(cam, homeCam());
renderChrome();
requestAnimationFrame(frame);
