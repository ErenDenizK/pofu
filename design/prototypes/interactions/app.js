// Pofu interaction prototype. Plain JS, no dependencies, no network.
//
// What it demonstrates (see docs/design/interaction-spec.md for the numbers and the SwiftUI notes):
//   - one continuous camera with three framings (Home, Island, Map) and three zoom models to compare:
//     A tap-only, B free pinch and pan, C detented pinch (recommended);
//   - station focus: camera move, per-object depth of field from pre-blurred layers, a sheet with
//     detents that keeps the station visible, the build moment, interruption and retargeting;
//   - glass panels that morph out of their button; a stack of at most one sheet;
//   - Pofu: poke (with a rationed escalation), pet (long press, then strokes), idle life, glances,
//     return reactions; residents and empty lawn react; haptics are shown in a small HUD.
//
// Performance rules followed here: only transform and opacity are animated per frame (the morph's
// clip-path on one small element is the single exception); depth of field is an opacity cross-fade
// between baked blur variants; one requestAnimationFrame loop runs only while something moves.
'use strict';

// ------------------------------------------------------------------ data
const BLUR = {"_haze":{"isle-hamam":0.3,"isle-harbor":0.3,"isle-home-band0":0.204,"isle-home-band1":0.112,"isle-home-band2":0.026,"isle-library":0.3,"isle-stars":0.3,"st-cay-2":0.073,"st-cay-3":0.073,"st-garden-3":0.076,"st-garden-4":0.076,"st-pond-2":0.038,"st-windmill-2":0.197,"st-workshop-2":0.19},"cloud-a":{"b1":[0.0556,0.1013],"b2":[0.1528,0.2785],"b3":[0.3403,0.6203]},"cloud-b":{"b1":[0.0361,0.0774],"b2":[0.1,0.2143],"b3":[0.225,0.4821]},"isle-hamam":{"b1":[0.0174,0.0202],"b2":[0.0469,0.0547],"b3":[0.1059,0.1235]},"isle-harbor":{"b1":[0.0166,0.0192],"b2":[0.0448,0.0517],"b3":[0.1012,0.1169]},"isle-home":{"b1":[0.0119,0.015],"b2":[0.033,0.0417],"b3":[0.0742,0.0938]},"isle-home-band0":{"b1":[0.0119,0.015],"b2":[0.033,0.0417],"b3":[0.0742,0.0938],"crop":{"b1":[0.02247,0.23596],"b2":[0.02564,0.25],"b3":[0.02734,0.27344],"s":[0.01852,0.22917]}},"isle-home-band1":{"b1":[0.0119,0.015],"b2":[0.033,0.0417],"b3":[0.0742,0.0938],"crop":{"b1":[0.17079,0.40449],"b2":[0.1891,0.41026],"b3":[0.21484,0.41797],"s":[0.16204,0.40278]}},"isle-home-band2":{"b1":[0.0119,0.015],"b2":[0.033,0.0417],"b3":[0.0742,0.0938],"crop":{"b1":[0.33933,0.57528],"b2":[0.34936,0.57051],"b3":[0.35938,0.5625],"s":[0.33565,0.57639]}},"isle-home-band3":{"b1":[0.0119,0.015],"b2":[0.033,0.0417],"b3":[0.0742,0.0938],"crop":{"b1":[0.50787,0.97079],"b2":[0.50962,0.96154],"b3":[0.50781,0.94531],"s":[0.50926,0.97685]}},"isle-library":{"b1":[0.0182,0.0215],"b2":[0.0492,0.0579],"b3":[0.1111,0.1309]},"isle-stars":{"b1":[0.0182,0.0215],"b2":[0.0492,0.0579],"b3":[0.1111,0.1309]},"neighbor-bunny":{"b1":[0.1583,0.1751],"b2":[0.4458,0.4931],"b3":[1.0,1.106]},"pofu":{"b1":[0.0661,0.0698],"b2":[0.1875,0.1981],"b3":[0.4232,0.4472]},"res-hog":{"b1":[0.1567,0.168],"b2":[0.4328,0.464],"b3":[0.9701,1.04]},"st-cay-2":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]},"st-cay-3":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]},"st-garden-3":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]},"st-garden-4":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]},"st-pond-2":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]},"st-windmill-2":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]},"st-workshop-2":{"b1":[0.035,0.0318],"b2":[0.1,0.0909],"b3":[0.225,0.2045]}};
// Image boxes in world units, relative to the object's anchor (feet or footprint centre).
const BOX = {
  'isle-home': [-182, -106, 182, 182], 'isle-harbor': [-134, -106.4, 134, 125.44], 'isle-stars': [-122, -95, 122, 112],
  'isle-hamam': [-128, -100.7, 128, 118.72], 'isle-library': [-122, -95, 122, 112], st: [-60, -112, 60, 20],
  'neighbor-bunny': [-13.5, -24.4, 13.5, 0], 'res-hog': [-14, -22, 14, 4], pofu: [-32, -59.66, 32, 0.91],
  face: [-35.2, -66.67, 35.2, 3.73], 'cloud-a': [-40, -26, 40, 18], 'cloud-b': [-60, -34, 60, 22],
};
// The home plate is four depth bands (tools/preblur.py): back terrace, terrace front, main lawn, lip and rock.
const BANDS = [-78, -25, 25, 75];
BANDS.forEach((d, k) => { BOX['isle-home-band' + k] = BOX['isle-home']; });
const STATIONS = [
  { id: 'windmill', name: 'Yel değirmeni', who: 'Pofu ve Fındık', at: [-62, -74], lv: 2, art: { 2: 'st-windmill-2' }, cost: [1400, 3080, 6776, 14907, 32796], rate: [12, 19, 25, 32, 38],
    lvl: ['Taş değirmen, dört çıplak kanat', 'Krem yelken bezleri', 'Ay çekirdeği çuvalları', 'Tepede fenerler', 'Bayrak ve pencere saksıları'] },
  { id: 'workshop', name: 'Atölye', who: "Fındık'ın", at: [62, -70], lv: 2, art: { 2: 'st-workshop-2' }, cost: [500, 1100, 2420, 5324, 11713], rate: [9, 14, 19, 24, 29], res: 'hog',
    lvl: ['Kulübe ve tezgâh', 'Alet duvarı', 'Dönen rüzgâr gülü', 'Baca', 'Büyük dişli tabela'] },
  { id: 'garden', name: 'Ayçiçeği bahçesi', who: "Pofu'nun", at: [-66, -4], lv: 3, art: { 3: 'st-garden-3', 4: 'st-garden-4' }, cost: [0, 30, 66, 145, 319], rate: [6, 9, 13, 16, 19], res: 'pofu',
    lvl: ['Tarhta üç ayçiçeği', 'Çit ve iki ayçiçeği daha', 'Kova ve fideler', 'Bayraklı ayçiçeği kemeri', 'Güneşi izleyen dev ayçiçeği'] },
  { id: 'cay', name: 'Çay ocağı', who: "Mochi'nin", at: [64, -2], lv: 2, art: { 2: 'st-cay-2', 3: 'st-cay-3' }, cost: [40, 88, 194, 426, 937], rate: [5, 8, 11, 13, 16], res: 'bunny',
    lvl: ['Tezgâh, çaydanlık, iki ince belli bardak', 'Çizgili tente', 'İki tabure ve minik bir masa', 'Işık zinciri', 'Kiremit çatı, sardunya ve bayrak'] },
  { id: 'pond', name: 'Nilüferli gölet', who: 'Kurbağaların', at: [132, 18], lv: 2, art: { 2: 'st-pond-2' }, cost: [160, 352, 774, 1704, 3748], rate: [6, 9, 13, 16, 19],
    lvl: ['Küçük gölet, çakıllar', 'Nilüfer yaprakları', 'Sazlar ve bir çiçek', 'Ahşap iskele', 'Yüzen fenerler'] },
];
const ST = Object.fromEntries(STATIONS.map((s) => [s.id, s]));
const ISLES = [
  { id: 'stars', pos: [-150, -540], name: 'Yıldız', note: 'kilitli', locked: true, label: [-150, -418] },
  { id: 'hamam', pos: [215, -345], name: 'Kaplıca', note: 'kilitli', locked: true, label: [215, -214] },
  { id: 'harbor', pos: [220, 300], name: 'İskele', note: 'yeni', isNew: true, label: [220, 186] },
  { id: 'library', pos: [-225, 330], name: 'Kitap', note: 'bir mevsimle', locked: true, label: [-225, 230] },
];
const POFU_AT = [6, 20];
// Framings in reference points (iPhone 17, 402 x 874), from design review 01 section 1 (B).
const FR_REF = {
  map: { x: 0, y: -80, s: 0.46, ay: 430 },
  island: { x: 0, y: 40, s: 1.06, ay: 470 },
  home: { x: 6, y: 20, s: 2.40, ay: 600 }, // Pofu 154 pt, 38 % (review 01 B, the measured spec)
  home20: { x: 6, y: 20, s: 1.256, ay: 600 }, // Pofu about 20 % (the figure written in ADR-0018)
};
const ORDER = ['map', 'island', 'home'];

// ------------------------------------------------------------------ settings (the compare panel)
const S = {
  model: 'C', // A tap-only, B free, C detented
  blur: 'pre', // pre-blurred layers, live CSS filter, none
  behind: 'dof', // what the world does behind a sheet: dof, dim, scale
  menu: 'morph', // morph from the button, or a bottom sheet
  home: 38,
  rm: window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches,
  hits: false, haptics: true, fps: false,
  dof: 'depth', // depth: continuous blur by distance from a focus plane (v2); flat: v1 on/off levels
  npc: 'card', // a resident tap shows a small card with "Tezgâha git", or opens the station sheet
  fx: { parallax: true, tilt: false, haze: true, bokeh: true, shadows: true, tiltshift: false, depthmap: false, dolly: false },
};
const RECOMMENDED = { parallax: true, tilt: false, haze: true, bokeh: true, shadows: true, tiltshift: false, depthmap: false, dolly: false };

// ------------------------------------------------------------------ helpers
const $ = (s) => document.querySelector(s);
const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
const lerp = (a, b, t) => a + (b - a) * t;
const fmt = (n) => Math.round(n).toLocaleString('tr-TR');
const now = () => performance.now();
const el = (tag, cls, parent, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html) e.innerHTML = html; if (parent) parent.appendChild(e); return e; };
// Apple-style rubber band: the further you pull, the less it follows. D is the asymptote.
const rb = (x, D) => Math.sign(x) * (1 - 1 / (Math.abs(x) * 0.55 / D + 1)) * D;
function setOp(e, v) { v = Math.round(v * 1000) / 1000; if (e._op !== v) { e._op = v; e.style.opacity = v; } }
// Hidden layers leave the render tree (and their CSS animations stop): opacity 0 is not free.
function setShown(e, on) { if (e._shown !== on) { e._shown = on; e.style.display = on ? '' : 'none'; } }
function setTf(e, t) { if (e._tf !== t) { e._tf = t; e.style.transform = t; } }

// A damped spring with SwiftUI parameters, spring(duration:bounce:). Retargeting keeps velocity,
// exactly like SwiftUI's animatable springs, which is what makes every motion interruptible.
const SPRINGS = [];
class Sp {
  constructor(v, eps = 0.001) { this.v = v; this.t = v; this.vel = 0; this.k = 158; this.c = 25; this.on = false; this.eps = eps; SPRINGS.push(this); }
  cfg(d, b) { const w = 2 * Math.PI / d; this.k = w * w; this.c = 4 * Math.PI * (1 - b) / d; return this; }
  to(t, d, b, vel) {
    if (t === this.t && !this.on && this.v === t && vel === undefined) return this;
    this.cfg(d, b); this.t = t; if (vel !== undefined) this.vel = vel; this.on = true; kick(); return this;
  }
  set(v) { this.v = this.t = v; this.vel = 0; this.on = false; }
  push(dv) { this.vel += dv; this.on = true; kick(); }
  step(dt) {
    if (!this.on) return false;
    const n = Math.max(1, Math.ceil(dt / 0.004)), h = dt / n;
    for (let i = 0; i < n; i++) { const a = -this.k * (this.v - this.t) - this.c * this.vel; this.vel += a * h; this.v += this.vel * h; }
    if (Math.abs(this.v - this.t) < this.eps && Math.abs(this.vel) < this.eps * 20) { this.v = this.t; this.vel = 0; this.on = false; }
    return true;
  }
}
// The same spring as a CSS linear() easing for WAAPI and transitions.
function springFn(d, b) {
  const w0 = 2 * Math.PI / d, z = 1 - b;
  if (z >= 1) return (t) => 1 - Math.exp(-w0 * t) * (1 + w0 * t);
  const wd = w0 * Math.sqrt(1 - z * z);
  return (t) => 1 - Math.exp(-z * w0 * t) * (Math.cos(wd * t) + (z * w0 / wd) * Math.sin(wd * t));
}
const LIN = window.CSS && CSS.supports && CSS.supports('animation-timing-function', 'linear(0, 1)');
const EASE = {};
function ease(d, b) {
  const key = d + '/' + b; if (EASE[key]) return EASE[key];
  const f = springFn(d, b); let T = d * 3;
  for (let t = d * 0.4; t < d * 3; t += 0.01) { let ok = true; for (let u = t; u < t + 0.2; u += 0.02) if (Math.abs(f(u) - 1) > 0.004) { ok = false; break; } if (ok) { T = t; break; } }
  const pts = []; for (let i = 0; i <= 40; i++) pts.push(i === 40 ? 1 : +f(T * i / 40).toFixed(4));
  return (EASE[key] = { f, ms: Math.round(T * 1000), css: LIN ? `linear(${pts.join(',')})` : (b > 0.2 ? 'cubic-bezier(.34,1.45,.64,1)' : 'cubic-bezier(.2,.8,.2,1)') });
}
function anim(e, kf, d, b, o = {}) {
  const sp = d ? ease(d, b) : null;
  return e.animate(kf, { duration: o.duration || sp.ms, easing: o.easing || sp.css, fill: o.fill || 'none', delay: o.delay || 0 });
}

// ------------------------------------------------------------------ elements
const app = $('#app'), wrap = $('#wrap'), world = $('#world'), camEl = $('#cam'), ov = $('#ov'), hitsEl = $('#hits');
const sheetEl = $('#sheet'), panelEl = $('#panel'), dimEl = $('#dim'), seaEl = $('#sea'), skyEl = $('#skyc');
let W = 390, H = 844, K = 1, SAFE_T = 47;
let FR = {};
function measure() {
  const r = app.getBoundingClientRect(); W = r.width; H = r.height; K = W / 402;
  SAFE_T = parseFloat(getComputedStyle($('.top')).top) - 4 || 12;
  for (const n in FR_REF) { const f = FR_REF[n]; FR[n] = { x: f.x, y: f.y, l: Math.log(f.s * K), ay: f.ay * H / 874 }; }
}
const homeFr = () => (S.home === 38 ? FR.home : FR.home20);
function framing(n) { return n === 'home' ? homeFr() : FR[n]; }
const topBand = () => SAFE_T + 100;

// ------------------------------------------------------------------ the world
const OBJ = []; // every world object with a depth-of-field level
// Atmospheric perspective is baked into `.hz` variants by tools/preblur.py (amount from depth).
function srcOf(name, lvl) { return 'assets/' + name + (S.fx.haze && BLUR._haze[name] !== undefined ? '.hz' : '') + (lvl ? '.' + lvl : '') + '.webp'; }
function applyHaze() {
  for (const o of OBJ) {
    if (o.kind === 'pofu' || BLUR._haze[o.src] === undefined) continue;
    for (const [im, lvl] of [[o.sharp, ''], [o.b1, 'b1'], [o.b2, 'b2'], [o.clImg, 'b3']]) { if (!im) continue; const u = srcOf(o.src, lvl); if (im._src !== u) { im._src = u; im.src = u; } }
  }
}
function addImg(parent, name, box, cls) {
  const im = el('img', cls || '', parent); im.alt = ''; im.decoding = 'async'; im.draggable = false;
  const LV = cls === 'b1' || cls === 'b2' || cls === 'b3';
  im.src = srcOf(name, LV ? cls : '');
  let [x0, y0, x1, y1] = box;
  if (LV) { const [px, py] = BLUR[name][cls]; const w = x1 - x0, h = y1 - y0; x0 -= px * w; x1 += px * w; y0 -= py * h; y1 += py * h; }
  const crop = BLUR[name] && BLUR[name].crop && BLUR[name].crop[LV ? cls : 's'];
  if (crop) { const h = y1 - y0; [y0, y1] = [y0 + crop[0] * h, y0 + crop[1] * h]; } // band images are cropped to their rows
  Object.assign(im.style, { left: x0 + 'px', top: y0 + 'px', width: (x1 - x0) + 'px', height: (y1 - y0) + 'px' });
  return im;
}
// An object: anchor div at world (x, y) > transform div (press, squash) > sharp, soft, deep images.
function makeObj(o) {
  o.el = el('div', 'obj ' + (o.cls || ''), camEl); o.el.style.left = o.x + 'px'; o.el.style.top = o.y + 'px';
  o.hop = el('div', 'tf', o.el); o.tf = el('div', 'tf', o.hop);
  o.inner = o.tf;
  if (o.kind === 'pofu') { o.inner = el('div', 'br', o.tf); }
  o.b2 = addImg(o.inner, o.src, BOX[o.box], 'b2'); o.b1 = addImg(o.inner, o.src, BOX[o.box], 'b1');
  if (o.kind === 'pofu') {
    o.sharp = el('div', 'tf', o.inner);
    const W0 = 64; el('i', 'psh', o.sharp).style.cssText = `width:${W0 * 0.86}px;height:${W0 * 0.26}px;left:${-W0 * 0.43}px;top:${-W0 * 0.12}px`;
    o.base = addImg(o.sharp, 'pofu', BOX.pofu, ''); o.base.classList.add('base');
    o.faces = {};
    for (const f of ['breathe', 'excited', 'proud', 'relieved', 'worried', 'smug']) { const im = addImg(o.sharp, 'pofu-' + f, BOX.face, ''); im.classList.add('face'); o.faces[f] = im; }
  } else o.sharp = addImg(o.inner, o.src, BOX[o.box], '');
  // Contact shadow and ambient occlusion where the object meets the ground (drawn under the art).
  if (o.kind === 'station' || o.kind === 'res') {
    const st = o.kind === 'station', w = st ? 92 : 24, h = st ? 20 : 6, cy = st ? -4 : 0;
    const sh = el('i', 'csh', null); sh.style.cssText = `left:${-w / 2}px;top:${cy - h / 2}px;width:${w}px;height:${h}px`;
    const ao = el('i', 'cao', null); ao.style.cssText = `left:${-w * 0.27}px;top:${cy - h * 0.22}px;width:${w * 0.54}px;height:${h * 0.44}px`;
    o.inner.insertBefore(ao, o.inner.firstChild); o.inner.insertBefore(sh, o.inner.firstChild);
  }
  o.bs = new Sp(0, 0.002); o.bT = 0; o.w = [-1, -1, -1]; o.par = '';
  OBJ.push(o); return o;
}
function buildWorld() {
  // Sky clouds (screen space, slow parallax) and the sea of clouds in front.
  // Sky clouds and the sea of clouds, each with a deep-blurred twin layer for tilt-shift.
  for (const [layer, lvl] of [[skyEl, ''], [$('#skycB'), 'b3']]) [['cloud-b', 300, 200, 1.1, 0], ['cloud-a', 30, 290, 1, -3], ['cloud-b', 120, 110, 0.8, -6], ['cloud-a', 320, 410, 0.9, -9]].forEach(([n, x, y, k, d]) => {
    const b = BOX[n], [px, py] = lvl ? BLUR[n][lvl] : [0, 0], w = (b[2] - b[0]) * k, h = (b[3] - b[1]) * k;
    const im = el('img', 'drift', layer); im.src = 'assets/' + n + (lvl ? '.' + lvl : '') + '.webp'; im.alt = '';
    Object.assign(im.style, { left: x + b[0] * k - px * w + 'px', top: y + b[1] * k - py * h + 'px', width: w * (1 + 2 * px) + 'px', animationDelay: d + 's' });
  });
  for (const [layer, lvl] of [[seaEl, ''], [$('#seaB'), 'b3']]) [[-20, 1.6], [110, 1.3], [230, 1.7], [360, 1.4], [470, 1.5]].forEach(([x, k], i) => {
    const b = BOX['cloud-b'], [px, py] = lvl ? BLUR['cloud-b'][lvl] : [0, 0], w = (b[2] - b[0]) * k, h = (b[3] - b[1]) * k;
    const im = el('img', 'drift', layer); im.src = 'assets/cloud-b' + (lvl ? '.' + lvl : '') + '.webp'; im.alt = '';
    Object.assign(im.style, { left: x + b[0] * k - px * w + 'px', bottom: (20 + (i % 2) * 18) - py * h + 'px', width: w * (1 + 2 * px) + 'px', animationDelay: -i * 2 + 's' });
  });
  // Foreground bokeh at Home: a few out-of-focus petals, leaves, and pollen near the lens.
  const bk = $('#bokeh');
  [[-14, 120, 70, 'petal', '#F7C548', 0.5, 'bkA', 11], [318, 210, 96, '', '#FFF1C9', 0.35, 'bkB', 14], [-30, 560, 110, 'petal', '#8CC084', 0.42, 'bkA', 16],
    [300, 640, 64, 'petal', '#F7C548', 0.55, 'bkB', 12], [150, 70, 40, '', '#FFFFFF', 0.4, 'bkA', 9], [250, 470, 30, '', '#FFF4C2', 0.5, 'bkB', 10]].forEach(([x, y, d, cls, c, a, an, t], i) => {
    const e = el('i', 'bk ' + cls, bk);
    e.style.cssText = `left:${x}px;top:${y}px;width:${d}px;height:${d * (cls ? 0.7 : 1)}px;opacity:${a};background:radial-gradient(closest-side, ${c}, ${c}cc 45%, ${c}00);animation:${an} ${t}s ease-in-out ${-i * 2}s infinite alternate`;
  });
  const items = [];
  for (const i of ISLES) items.push({ kind: 'isle', id: i.id, src: 'isle-' + i.id, box: 'isle-' + i.id, x: i.pos[0], y: i.pos[1], cls: i.locked ? 'locked' : '', z: -1000 + i.pos[1], data: i });
  BANDS.forEach((d, k) => items.push({ kind: 'plate', id: 'band' + k, src: 'isle-home-band' + k, box: 'isle-home-band' + k, x: 0, y: 0, z: -900 + k, depth: d }));
  for (const s of STATIONS) items.push({ kind: 'station', id: s.id, src: s.art[s.lv], box: 'st', x: s.at[0], y: s.at[1], z: s.at[1], data: s });
  items.push({ kind: 'res', id: 'bunny', name: 'Mochi', src: 'neighbor-bunny', box: 'neighbor-bunny', x: ST.cay.at[0] + 34, y: ST.cay.at[1] + 8, z: ST.cay.at[1] + 8, station: 'cay' });
  items.push({ kind: 'res', id: 'hog', name: 'Fındık', src: 'res-hog', box: 'res-hog', x: ST.workshop.at[0] - 39, y: ST.workshop.at[1] + 6, z: ST.workshop.at[1] + 6, station: 'workshop' });
  items.push({ kind: 'pofu', id: 'pofu', cls: 'pofu', src: 'pofu', box: 'pofu', x: POFU_AT[0], y: POFU_AT[1], z: POFU_AT[1], station: 'garden' });
  // Depth: the diorama's y is the proxy (larger is nearer), refined per object where needed.
  for (const it of items) if (it.depth === undefined) it.depth = it.kind === 'isle' ? -400 : it.y;
  items.sort((a, b) => a.z - b.z).forEach(makeObj);
  // In-focus mid-ground pollen around Pofu's plane (world space, sharp).
  // Tilt-shift twin: each object's deep variant in a second camera layer under a gradient mask.
  const camB = $('#camB');
  for (const o of OBJ) {
    o.cl = el('div', 'obj', camB); o.cl.style.left = o.x + 'px'; o.cl.style.top = o.y + 'px';
    o.clImg = addImg(o.cl, o.src, BOX[o.box], 'b3'); // the strongest blur, used only here
  }
  pollenEl = el('div', 'pollen', camEl);
  [[-40, -30], [-10, -52], [30, -40], [52, -18], [-58, -8], [18, -70], [70, -48], [-26, -78]].forEach(([x, y], i) => { const q = el('i', '', pollenEl); q.style.cssText = `left:${x}px;top:${y}px;animation-delay:${-i * 0.9}s`; });
}
const O = {}; // by id
let pollenEl;
let POFU;

// Screen-space overlays: map labels, the Pofu pin, the speech bubble, chips, tags.
const ANCH = []; // {el, wx, wy, dx, dy, op?}
let pinEl, bubbleEl, labelEls = [];
function buildOverlays() {
  pinEl = el('div', 'pin', ov, '<svg viewBox="0 0 30 30" width="30" height="30"><circle cx="15" cy="15" r="14" fill="#FFFBF5"/><circle cx="15" cy="15" r="14" fill="none" stroke="#6C4FD8" stroke-width="2"/><circle cx="9.5" cy="9" r="3" fill="#F6A290"/><circle cx="20.5" cy="9" r="3" fill="#F6A290"/><ellipse cx="15" cy="16.5" rx="8.6" ry="7.6" fill="#ECA96E"/><ellipse cx="15" cy="18" rx="5.6" ry="5.4" fill="#FEF2E3"/><circle cx="12" cy="15.5" r="1.3" fill="#2A1F2D"/><circle cx="18" cy="15.5" r="1.3" fill="#2A1F2D"/></svg>');
  for (const i of [{ id: 'home', name: 'Ayçiçeği', note: 'ev', label: [0, -112] }, ...ISLES]) {
    const e = el('div', 'mlabel' + (i.isNew ? ' new' : ''), ov, `${i.name}<small>${i.note}</small>`);
    labelEls.push({ el: e, wx: i.label[0], wy: i.label[1] });
  }
  bubbleEl = el('div', 'bubble', ov);
}

// ------------------------------------------------------------------ camera
const cam = { x: new Sp(0, 0.01), y: new Sp(0, 0.01), l: new Sp(0, 0.0004), ay: new Sp(0, 0.05), ox: new Sp(0, 0.05), oy: new Sp(0, 0.05) };
let view = 'home', focus = null, returnView = 'home', returnCam = null, npc = null;
const camS = () => Math.exp(cam.l.v);
// Tilt vector for parallax and the depth-map plate: peek drag plus (opt-in) device orientation.
const tilt = { x: new Sp(0, 0.001), y: new Sp(0, 0.001) }, dev = { x: 0, y: 0, g0: null, b0: null };
function onOrient(e) {
  if (e.gamma == null || e.beta == null) return;
  if (dev.g0 === null) { dev.g0 = e.gamma; dev.b0 = e.beta; }
  dev.g0 += (e.gamma - dev.g0) * 0.01; dev.b0 += (e.beta - dev.b0) * 0.01; // slow recentre, like iOS wallpapers
  dev.x = clamp((e.gamma - dev.g0) / 18, -1, 1); dev.y = clamp((e.beta - dev.b0) / 18, -1, 1); kick();
}
async function enableTilt(on) {
  window.removeEventListener('deviceorientation', onOrient); dev.x = dev.y = 0; dev.g0 = null; S.fx.tilt = false;
  if (on) {
    try {
      // iOS Safari asks for permission, and only from inside a tap.
      if (window.DeviceOrientationEvent && typeof DeviceOrientationEvent.requestPermission === 'function') {
        const r = await DeviceOrientationEvent.requestPermission();
        if (r !== 'granted') { toast('Eğim izni verilmedi; sürükleyerek deneyin.'); renderPanel(); kick(); return; }
      }
      if (!('DeviceOrientationEvent' in window)) throw new Error('none');
      window.addEventListener('deviceorientation', onOrient); S.fx.tilt = true; toast('Telefonu hafifçe eğin.');
    } catch (e) { toast('Eğim bu cihazda yok; sürükleyerek deneyin.'); }
  }
  renderPanel(); kick();
}
function toScreen(wx, wy) { const s = camS(); return [W / 2 + cam.ox.v + (wx - cam.x.v) * s, cam.ay.v + cam.oy.v + (wy - cam.y.v) * s]; }
function toWorld(sx, sy) { const s = camS(); return [cam.x.v + (sx - W / 2 - cam.ox.v) / s, cam.y.v + (sy - cam.ay.v - cam.oy.v) / s]; }
function setCam(f) { cam.x.set(f.x); cam.y.set(f.y); cam.l.set(f.l); cam.ay.set(f.ay); cam.ox.set(0); cam.oy.set(0); kick(); }
// z: the camera's position on the rail. 0 = Map, 1 = Island, 2 = Home. Continuous while pinching.
function zOf(l) { const L0 = FR.map.l, L1 = FR.island.l, L2 = homeFr().l; return l <= L1 ? (l - L0) / (L1 - L0) : 1 + (l - L1) / Math.max(1e-3, L2 - L1); }
function rail(z) {
  const a = z <= 1 ? FR.map : FR.island, b = z <= 1 ? FR.island : homeFr(), f = clamp(z <= 1 ? z : z - 1);
  return { x: lerp(a.x, b.x, f), y: lerp(a.y, b.y, f), ay: lerp(a.ay, b.ay, f), l: lerp(a.l, b.l, f), dxl: (b.x - a.x) / (b.l - a.l || 1), dyl: (b.y - a.y) / (b.l - a.l || 1), dal: (b.ay - a.ay) / (b.l - a.l || 1) };
}
function bandL(l) { const lo = FR.map.l, hi = homeFr().l, D = Math.log(1.25); return l > hi ? hi + rb(l - hi, D) : l < lo ? lo - rb(lo - l, D) : l; }
// Move the camera with a spring; any running move is retargeted, keeping its velocity.
function moveCam(f, d, b, vel = {}) {
  if (S.rm) { dip(() => setCam(f)); return; }
  cam.x.to(f.x, d, b, vel.x); cam.y.to(f.y, d, b, vel.y); cam.l.to(f.l, d, b, vel.l); cam.ay.to(f.ay, d, b, vel.ay);
  cam.ox.to(0, d, b); cam.oy.to(0, d, b);
}
// Reduce Motion: no camera travel. A 100 ms dip to the sky colour, a cut, a 100 ms rise.
let dipping = false;
function dip(apply) {
  if (dipping) { apply(); return; }
  dipping = true;
  const a = wrap.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 100, fill: 'forwards' });
  a.finished.then(() => { apply(); render(); const c = wrap.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 100 }); a.cancel(); c.finished.then(() => { dipping = false; }); });
}
function goTo(n, why) {
  if (cloud) return;
  closeMorph(); closePanel(); hideNpc(false);
  if (sheet.open) closeSheet(true);
  const far = n === 'map' || view === 'map';
  view = n; focus = null;
  moveCam(framing(n), far ? 1.1 : 0.9, far ? 0.08 : 0.1);
  updateSeg(n);
  if (why) toast(why);
}
function stepOut() { const i = ORDER.indexOf(nearestView()); if (i > 0) goTo(ORDER[i - 1]); }
function stepIn() { const i = ORDER.indexOf(nearestView()); goTo(i < 2 ? ORDER[i + 1] : 'island'); }
const nearestView = () => ORDER[clamp(Math.round(zOf(cam.l.v)), 0, 2)];
function focusFr(id, compact) {
  const s = ST[id], top = topBand(), bottom = H - sheetH(compact ? 'compact' : 'medium');
  const sc = Math.min((compact ? 1.95 : 1.7) * K, (bottom - top) * 0.62 / 112);
  return { x: s.at[0], y: s.at[1] - 46, l: Math.log(sc), ay: (top + bottom) / 2 + 8 };
}

// ------------------------------------------------------------------ depth of field
// Each object has a continuous blur level b: 0 sharp, 1 soft, 2 deep. With pre-blurred layers it
// is an opacity cross-fade of three stacked images; with the live option it is a CSS filter.
const SIG = (b) => (b <= 1 ? 1.4 * b : 1.4 + 2.6 * (b - 1)); // world units, matches tools/preblur.py
function weights(b) {
  // Stacked deep < soft < sharp. The sharp layer fades out over the soft one (b 0 to 1), then the
  // soft one over the deep one (b 1 to 2); the lower layer ramps in quickly so edges never thin out.
  if (b <= 1) return [1 - b, clamp(b * 4), 0];
  return [0, 2 - b, clamp((b - 1) * 4)];
}
function applyBlur(o) {
  const b = o.bs.v;
  if (S.blur === 'pre') {
    const w = weights(b);
    if (o.filt) { o.sharp.style.filter = ''; o.filt = ''; }
    setOp(o.sharp, w[0]); setOp(o.b1, w[1]); setOp(o.b2, w[2]);
  } else {
    setOp(o.sharp, 1); setOp(o.b1, 0); setOp(o.b2, 0);
    const f = S.blur === 'live' && b > 0.02 ? `blur(${SIG(b).toFixed(2)}px)` : '';
    if (o.filt !== f) { o.filt = f; o.sharp.style.filter = f; }
  }
}
// Depth of field as a lens: an object's blur grows with its distance from the focus plane.
// b = clamp((|depth - focus| - dz) * k), with focus, dz (half the in-focus slab) and k (1 / range)
// animated by springs, so a new focus is a rack focus, not a cut.
const foc = { f: new Sp(20, 0.05), dz: new Sp(8, 0.05), k: new Sp(0.02, 0.00002) };
const LENS = { home: [20, 8, 1 / 50], island: [-15, 35, 1 / 160], map: [-15, 35, 0], station: [6, 1 / 55], npc: [4, 1 / 45] };
function focusGoal(z) {
  if (npc) return [O[npc].depth, ...LENS.npc];
  if (focus) return [ST[focus].at[1], ...LENS.station];
  if (z >= 1) { const t = clamp(z - 1); return LENS.island.map((v, i) => lerp(v, LENS.home[i], t)); }
  const t = clamp(z); return LENS.map.map((v, i) => lerp(v, LENS.island[i], t));
}
function tiltShiftW(z) { return S.fx.tiltshift && !sheet.open && !npc ? clamp(1 - Math.abs(z - 1) * 2.5) : 0; }
function blurTarget(o, z, sheetP) {
  if (S.dof === 'depth') {
    let b = o.kind === 'isle' ? clamp(z) : clamp((Math.abs(o.depth - foc.f.v) - foc.dz.v) * foc.k.v, 0, 2);
    if (sheet.open && S.behind === 'dof') b = !focus ? Math.max(b, 1) + sheetP : b + 2 * sheetP;
    return Math.min(2, b);
  }
  let b;
  if (o.kind === 'isle') b = clamp(z) * 1.0; // distant islands are soft once you are on an island
  else if (o.kind === 'pofu') b = 0;
  else b = clamp((z - 1.3) / 0.5); // Home: the world behind Pofu softens
  if (npc) b = o.id === npc || o.id === O[npc].station ? 0 : Math.max(b, 1);
  if (sheet.open && S.behind === 'dof') {
    const focused = focus && (o.id === focus || o.station === focus);
    if (focus) b = focused ? 0 : Math.max(b, 1);
    else b = Math.max(b, 1);
    b = focused ? 2 * sheetP : Math.min(2, b + sheetP);
  }
  return b;
}

// ------------------------------------------------------------------ render loop
const RT = { n: 0, sum: 0, max: 0 }; // render() cost, for the check
let raf = 0, lastT = 0, gestureLive = false, fpsN = 0, fpsT = 0;
function kick() { if (!raf) { lastT = now(); raf = requestAnimationFrame(frame); } }
function frame(t) {
  raf = 0; const dt = Math.min(0.05, Math.max(0.001, (t - lastT) / 1000)); lastT = t;
  let busy = false;
  for (const s of SPRINGS) if (s.on) { s.step(dt); busy = true; }
  const r0 = performance.now(); render(); const rt = performance.now() - r0;
  RT.n++; RT.sum += rt; if (rt > RT.max) RT.max = rt;
  if (S.fps) { fpsN++; if (t - fpsT > 500) { $('#fps').textContent = Math.round(fpsN * 1000 / (t - fpsT)) + ' fps'; fpsN = 0; fpsT = t; } }
  // One callback per frame: render() may already have scheduled the next one through kick().
  if (!raf && (busy || gestureLive || S.fps || SPRINGS.some((s) => s.on))) raf = requestAnimationFrame(frame);
}
const CH = {};
function render() {
  if (!CH.calm) { for (const id of ['calm', 'ctxIsland', 'ctxMap', 'segInd', 'seg', 'skycB', 'seaB', 'bokeh', 'tilt', 'npc', 'tsw', 'camB']) CH[id] = $('#' + id); CH.tab = $('#tabBtn'); CH.top = $('.top'); CH.calm2 = CH.calm; }
  const s = camS();
  setTf(camEl, `translate3d(${(W / 2 + cam.ox.v - cam.x.v * s).toFixed(2)}px,${(cam.ay.v + cam.oy.v - cam.y.v * s).toFixed(2)}px,0) scale(${s.toFixed(5)})`);
  const z = zOf(cam.l.v);
  // Sheet and what the world does behind it.
  const sy = sheetY.v; setTf(sheetEl, `translate3d(0,${sy.toFixed(1)}px,0)`);
  const medH = sheetH('medium'), lgH = sheetH('large');
  const shown = clamp((H - sy) / medH), sheetP = clamp((H - sy - medH) / (lgH - medH));
  setTf(panelEl, `translate3d(0,${panelY.v.toFixed(1)}px,0)`);
  let dim = 0, sc = 1;
  if (S.behind === 'dof') dim = 0.14 * sheetP;
  else if (S.behind === 'dim') dim = 0.22 * shown + 0.14 * sheetP;
  else sc = 1 - 0.06 * shown;
  setOp(dimEl, dim);
  setTf(wrap, sc < 0.999 ? `scale(${sc.toFixed(4)})` : 'none');
  const rounded = sc < 0.999; if (wrap._r !== rounded) { wrap._r = rounded; wrap.style.borderRadius = rounded ? '28px' : ''; wrap.style.overflow = rounded ? 'hidden' : ''; }
  const goal = focusGoal(z);
  foc.f.to(goal[0], 0.6, 0); foc.dz.to(goal[1], 0.6, 0); foc.k.to(goal[2], 0.6, 0); // `rack` spring
  // Parallax: the tilt vector comes from the peek drag and, if allowed, the device's tilt.
  const par = S.fx.parallax && !S.rm;
  tilt.x.to(par ? clamp(cam.ox.v / 30 + dev.x, -1.4, 1.4) : 0, 0.3, 0); tilt.y.to(par ? clamp(cam.oy.v / 30 + dev.y, -1.4, 1.4) : 0, 0.3, 0);
  const tx = tilt.x.v, ty = tilt.y.v, pivot = foc.f.v;
  const tsw = tiltShiftW(z);
  for (const o of OBJ) {
    o.bs.to(S.blur === 'none' ? 0 : blurTarget(o, z, sheetP), 0.35, 0);
    applyBlur(o);
    const pd = o.kind === 'isle' ? -260 : o.depth;
    const t = par && (tx || ty) ? `translate3d(${(tx * (pd - pivot) * 0.12 / s).toFixed(2)}px,${(ty * (pd - pivot) * 0.06 / s).toFixed(2)}px,0)` : '';
    if (o.par !== t) { o.par = t; o.el.style.transform = t; if (o.cl) o.cl.style.transform = t; }
    if (o.cl && tsw > 0) setOp(o.cl, o.el._op ?? 1);
    if (o.kind === 'isle') setOp(o.el, (z <= 1 ? lerp(1, 0.35, clamp(z)) : lerp(0.35, 0, clamp(z - 1))) * (o.arrive ?? 1));
  }
  // Pofu becomes the 30 pt vector pin on the map.
  const pin = clamp((0.55 - z) / 0.3);
  setOp(POFU.el, 1 - pin); setOp(pinEl, pin);
  const [px, py] = toScreen(POFU_AT[0], POFU_AT[1] - 30); setTf(pinEl, `translate3d(${px.toFixed(1)}px,${py.toFixed(1)}px,0)`);
  const lab = clamp((0.45 - z) / 0.25);
  for (const L of labelEls) { setOp(L.el, lab); const [x, y] = toScreen(L.wx, L.wy); setTf(L.el, `translate3d(${x.toFixed(1)}px,${y.toFixed(1)}px,0) translate(-50%,-50%)`); }
  // Anchored chips, tags and the bubble follow their world point.
  for (let i = ANCH.length - 1; i >= 0; i--) {
    const a = ANCH[i]; if (!a.el.isConnected) { ANCH.splice(i, 1); continue; }
    const [x, y] = toScreen(a.wx, a.wy); setTf(a.el, `translate3d(${(x + a.dx).toFixed(1)}px,${(y + a.dy).toFixed(1)}px,0) translate(-50%,-100%)`);
  }
  const bub = bubble.on && z > 0.8 && !sheet.open ? 1 : 0; setOp(bubbleEl, bub); bubble.was = !!bub;
  if (bub) { const [bx, by] = toScreen(POFU_AT[0], POFU_AT[1] - 62); setTf(bubbleEl, `translate3d(${bx.toFixed(1)}px,${(by - 12).toFixed(1)}px,0) translate(-50%,-100%)`); }
  // Chrome follows the camera continuously: it is a readout of where the camera is.
  setOp(CH.calm, clamp((z - 0.55) / 0.3) * (1 - Math.max(sheetP, cloud ? 1 : 0)));
  setOp(CH.ctxIsland, clamp(1 - Math.abs(z - 1) * 3) * (sheet.open || morph || npc ? 0 : 1));
  setOp(CH.ctxMap, clamp((0.4 - z) / 0.3) * (cloud ? 0 : 1));
  setTf(CH.segInd, `translateX(${(clamp(2 - z, 0, 2) * 88).toFixed(1)}px)`);
  // The bottom bar slides under a sheet; the top bar yields to a large sheet. No chrome reads through.
  const under = Math.max(clamp(shown * 3), cloud ? 1 : 0), topOut = Math.max(sheetP, cloud ? 1 : 0);
  setOp(CH.seg, 1 - under); setOp(CH.tab, 1 - under); setOp(CH.top, 1 - topOut);
  const blockB = under > 0.5, blockT = topOut > 0.5;
  if (CH._b !== blockB) { CH._b = blockB; CH.seg.style.pointerEvents = CH.tab.style.pointerEvents = blockB ? 'none' : ''; }
  if (CH._t !== blockT) { CH._t = blockT; CH.top.style.visibility = blockT ? 'hidden' : ''; }
  // Parallax: the sky moves less than the island, the sea of clouds more.
  const skyT = `translate3d(${(cam.ox.v * 0.3 - tx * 14).toFixed(1)}px,${(cam.oy.v * 0.3 + (z - 1) * 10 - ty * 7).toFixed(1)}px,0)`;
  const seaT = `translate3d(${(cam.ox.v * 1.25 + tx * 18).toFixed(1)}px,${((2 - z) * -14 + cam.oy.v * 1.2 + ty * 9).toFixed(1)}px,0)`;
  setTf(skyEl, skyT); setTf(seaEl, seaT); setTf(CH.skycB, skyT); setTf(CH.seaB, seaT);
  setOp(CH.skycB, tsw); setOp(CH.seaB, tsw); setOp(CH.tsw, tsw);
  setShown(CH.skycB, tsw > 0); setShown(CH.seaB, tsw > 0); setShown(CH.tsw, tsw > 0);
  if (tsw > 0) setTf(CH.camB, camEl._tf);
  // Foreground bokeh (near the lens, Home only) and in-focus pollen around Pofu's plane.
  const bkO = S.fx.bokeh && !sheet.open ? clamp((z - 1.5) / 0.4) : 0; setOp(CH.bokeh, bkO); setShown(CH.bokeh, bkO > 0);
  setTf(CH.bokeh, `translate3d(${(tx * 26).toFixed(1)}px,${(ty * 13).toFixed(1)}px,0)`);
  const plO = S.fx.bokeh && !sheet.open ? clamp((z - 0.8) / 0.4) : 0; setOp(pollenEl, plO); setShown(pollenEl, plO > 0);
  // A slight perspective tilt while the camera travels between framings (a crane, not a zoom).
  const tiltA = S.fx.dolly && !S.rm ? clamp(-cam.l.vel * 3.2, -6, 6) : 0;
  setTf(CH.tilt, Math.abs(tiltA) > 0.01 ? `perspective(900px) rotateX(${tiltA.toFixed(2)}deg)` : 'none');
  if (S.fx.depthmap && gl) drawGL(tx, ty); // redraws only when tilt or the lens changed
  placeNpc();
  renderPofu();
  if (S.hits) drawHits();
}

// ------------------------------------------------------------------ technique (f): depth-map plate in WebGL
// One canvas replaces the four plate bands. A fragment shader displaces each pixel by its depth
// (from tools/depthmap.py) against the tilt vector, and blends sharp, soft, and deep textures per
// pixel by distance from the focus plane: per-pixel depth of field and a true 3D wobble.
let gl = null, glEl = null, glReady = false, glLast = '', glU = {};
const VS = 'attribute vec2 p; varying vec2 v; void main(){ v = vec2(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5); gl_Position = vec4(p, 0.0, 1.0); }';
const FS = `precision mediump float; varying vec2 v;
uniform sampler2D uS, uB1, uB2, uD; uniform vec4 uPad; uniform vec2 uTilt; uniform vec4 uFoc; uniform float uHaze;
float dep(vec2 q) { return texture2D(uD, q).r * 240.0 - 120.0; }
vec2 pad(vec2 q, vec2 p) { return (q + p) / (1.0 + 2.0 * p); }
void main() {
  float d = dep(v); vec2 q = v - uTilt * (d - uFoc.x);
  d = dep(q); q = v - uTilt * (d - uFoc.x); d = dep(q);           // two refinement steps
  float b = clamp((abs(d - uFoc.x) - uFoc.y) * uFoc.z + uFoc.w, 0.0, 2.0);
  vec4 s = texture2D(uS, q), b1 = texture2D(uB1, pad(q, uPad.xy)), b2 = texture2D(uB2, pad(q, uPad.zw));
  if (q.x < 0.0 || q.y < 0.0 || q.x > 1.0 || q.y > 1.0) s = vec4(0.0);
  vec4 c = b < 1.0 ? mix(s, b1, b) : mix(b1, b2, b - 1.0);
  float hz = clamp((40.0 - d) / 220.0, 0.0, 1.0) * 0.38 * uHaze;  // atmospheric perspective, per pixel
  c.rgb = mix(c.rgb, vec3(0.863, 0.922, 0.961) * c.a, hz);
  gl_FragColor = c;
}`;
function initGL() {
  if (gl) return glReady;
  glEl = document.createElement('canvas'); glEl.className = 'glplate'; glEl.width = 546; glEl.height = 432; // half resolution: the plate is soft at every framing it is drawn at
  const [x0, y0, x1, y1] = BOX['isle-home'];
  Object.assign(glEl.style, { left: x0 + 'px', top: y0 + 'px', width: x1 - x0 + 'px', height: y1 - y0 + 'px' });
  camEl.insertBefore(glEl, O.band0.el);
  const c = glEl.getContext('webgl', { premultipliedAlpha: true, alpha: true, antialias: false });
  if (!c) { toast('WebGL yok.'); return false; }
  gl = c;
  const sh = (t, src) => { const x = c.createShader(t); c.shaderSource(x, src); c.compileShader(x); return x; };
  const pr = c.createProgram(); c.attachShader(pr, sh(c.VERTEX_SHADER, VS)); c.attachShader(pr, sh(c.FRAGMENT_SHADER, FS)); c.linkProgram(pr); c.useProgram(pr);
  const buf = c.createBuffer(); c.bindBuffer(c.ARRAY_BUFFER, buf); c.bufferData(c.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), c.STATIC_DRAW);
  const loc = c.getAttribLocation(pr, 'p'); c.enableVertexAttribArray(loc); c.vertexAttribPointer(loc, 2, c.FLOAT, false, 0, 0);
  for (const n of ['uS', 'uB1', 'uB2', 'uD', 'uPad', 'uTilt', 'uFoc', 'uHaze']) glU[n] = c.getUniformLocation(pr, n);
  const pads = BLUR['isle-home']; c.uniform4f(glU.uPad, pads.b1[0], pads.b1[1], pads.b2[0], pads.b2[1]);
  c.pixelStorei(c.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
  let left = 4;
  ['isle-home', 'isle-home.b1', 'isle-home.b2', 'isle-home.depth'].forEach((n, i) => {
    const im = new Image(); im.crossOrigin = 'anonymous';
    im.onload = () => {
      c.activeTexture(c.TEXTURE0 + i); const t = c.createTexture(); c.bindTexture(c.TEXTURE_2D, t);
      c.texParameteri(c.TEXTURE_2D, c.TEXTURE_MIN_FILTER, c.LINEAR); c.texParameteri(c.TEXTURE_2D, c.TEXTURE_MAG_FILTER, c.LINEAR);
      c.texParameteri(c.TEXTURE_2D, c.TEXTURE_WRAP_S, c.CLAMP_TO_EDGE); c.texParameteri(c.TEXTURE_2D, c.TEXTURE_WRAP_T, c.CLAMP_TO_EDGE);
      try { c.texImage2D(c.TEXTURE_2D, 0, c.RGBA, c.RGBA, c.UNSIGNED_BYTE, im); } catch (e) { toast('Derinlik haritası yüklenemedi (dosyadan açılınca olur).'); return; }
      c.uniform1i(glU[['uS', 'uB1', 'uB2', 'uD'][i]], i);
      if (--left === 0) { glReady = true; glLast = ''; applyFx(); kick(); }
    };
    im.onerror = () => toast('Derinlik haritası yüklenemedi.');
    im.src = 'assets/' + n + '.webp';
  });
  return false;
}
function drawGL(tx, ty) {
  if (!glReady) return;
  const s = camS(), z = zOf(cam.l.v);
  const add = sheet.open && S.behind === 'dof' ? (focus ? 2 : 1) * clamp((H - sheetY.v - sheetH('medium')) / (sheetH('large') - sheetH('medium'))) + (focus ? 0 : 1) : 0;
  const u = [tx * 0.12 / s / 364, ty * 0.06 / s / 288, foc.f.v, foc.dz.v, foc.k.v, add, S.fx.haze ? 1 : 0];
  const key = u.map((x) => x.toFixed(5)).join();
  if (key === glLast) return; glLast = key;
  gl.viewport(0, 0, 546, 432); gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT);
  gl.uniform2f(glU.uTilt, u[0], u[1]); gl.uniform4f(glU.uFoc, u[2], u[3], u[4], u[5]); gl.uniform1f(glU.uHaze, u[6]);
  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  void z;
}
function applyFx() {
  app.classList.toggle('noshadow', !S.fx.shadows); applyHaze();
  const useGL = S.fx.depthmap && (glReady || initGL());
  if (glEl) glEl.style.display = useGL ? 'block' : 'none';
  for (const k of [0, 1, 2, 3]) O['band' + k].el.style.display = useGL ? 'none' : '';
  glLast = ''; kick();
}

// ------------------------------------------------------------------ haptics HUD, toast
const lastHap = {};
function haptic(name) {
  const t = now(); if (lastHap[name] && t - lastHap[name] < 90) return; lastHap[name] = t;
  try { if (navigator.vibrate && S.haptics) navigator.vibrate(8); } catch (e) { /* not supported */ }
  if (!S.haptics) return;
  const hud = $('#hud'); const d = el('div', '', hud); d.textContent = name;
  while (hud.children.length > 4) hud.firstChild.remove();
  d.animate([{ opacity: 0, transform: 'translateY(6px)' }, { opacity: 1, transform: 'none' }], { duration: 120, fill: 'forwards' });
  setTimeout(() => { d.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 220, fill: 'forwards' }).finished.then(() => d.remove()); }, 900);
}
let toastT = 0;
function toast(msg) {
  const t = $('#toast'); t.textContent = msg; clearTimeout(toastT);
  t.getAnimations().forEach((a) => a.cancel());
  t.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 160, fill: 'forwards' });
  toastT = setTimeout(() => t.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 240, fill: 'forwards' }), 1800);
}

// ------------------------------------------------------------------ Pofu
const pf = { sx: new Sp(1), sy: new Sp(1), sk: new Sp(0, 0.01) };
const bubble = { on: false, t: 0, was: false };
let faceT = 0, faceKind = null, faceHeld = null, dozing = false, petting = false;
function renderPofu() {
  setTf(POFU.tf, `skewX(${pf.sk.v.toFixed(2)}deg) scale(${pf.sx.v.toFixed(4)},${pf.sy.v.toFixed(4)})`);
}
function showFace(kind) {
  if (faceKind === kind) return;
  for (const k in POFU.faces) POFU.faces[k].classList.toggle('on', k === kind);
  POFU.base.classList.toggle('off', !!kind); faceKind = kind;
}
function face(kind, ms) { clearTimeout(faceT); showFace(kind); faceT = setTimeout(() => showFace(faceHeld), ms); }
function holdFace(kind) { faceHeld = kind; clearTimeout(faceT); showFace(kind); }
function say(text, ms = 3200) {
  bubbleEl.textContent = text; bubble.on = true; clearTimeout(bubble.t);
  if (!S.rm && !bubble.was) bubbleEl.animate([{ scale: 0.85 }, { scale: 1 }], { duration: ease(0.42, 0.35).ms, easing: ease(0.42, 0.35).css });
  bubble.t = setTimeout(() => { bubble.on = false; kick(); }, ms); kick();
}
function hop(o, h, delay = 0) {
  if (S.rm) return;
  const a = o.hop.animate([{ transform: 'translateY(0)' }, { transform: `translateY(${-h}px)`, offset: 0.42, easing: 'cubic-bezier(.2,.7,.4,1)' }, { transform: 'translateY(0)', offset: 0.84, easing: 'cubic-bezier(.6,0,.9,.5)' }, { transform: 'translateY(0)' }], { duration: 300 + h * 14, delay });
  if (o === POFU) setTimeout(() => { pf.sy.cfg(0.28, 0.45).push(-1.4); pf.sx.cfg(0.28, 0.45).push(0.9); }, delay + (300 + h * 14) * 0.84);
  return a;
}
// Poke escalation. Pokes less than 2.5 s apart form a run. The ladder rises for three pokes,
// stays playful for three more, then calms down: no counters, no combos, haptics fade out.
const run = { n: 0, last: 0 };
let saidBoop = false;
function pokeIntensity() { const fresh = now() - run.last > 2500; const n = fresh ? 1 : run.n + 1; return n; }
function pofuDown() {
  wake();
  const n = pokeIntensity(), amp = n >= 7 ? 0.45 : 1;
  // The squash starts on touch-down (it can still become a pinch, a pet, or a pan); the haptic
  // waits for the recognised tap so a gesture that is not a poke never buzzes.
  if (!S.rm) { pf.sx.to(1 + 0.05 * amp, 0.16, 0); pf.sy.to(1 - 0.09 * amp, 0.16, 0); }
}
function pofuUp() { pf.sx.to(1, 0.28, 0.45); pf.sy.to(1, 0.28, 0.45); }
function poke() {
  const t = now(); if (t - run.last > 2500) run.n = 0; run.n++; run.last = t;
  const n = run.n;
  if (n <= 8) haptic(n >= 5 ? 'yumuşak darbe · 0,3' : 'yumuşak darbe · 0,5');
  if (n === 1) face('excited', 520);
  else if (n === 2) { face('excited', 650); hop(POFU, 8); }
  else if (n === 3) { face('proud', 800); hop(POFU, 5); if (!saidBoop) { saidBoop = true; say('Dıt. Orası benim burnum.'); } }
  else if (n <= 6) { face('excited', 600); if (!S.rm) pf.sk.cfg(0.3, 0.55).push(n % 2 ? 70 : -70); }
  else face('smug', 1000);
}
let glanceT = 0, lastGlance = 0;
function glance(sx) {
  if (S.rm || petting || now() - lastGlance < 1200) return; lastGlance = now();
  const [px] = toScreen(POFU_AT[0], POFU_AT[1]); const dir = Math.sign(sx - px) || 1;
  pf.sk.to(-dir * 3.2, 0.5, 0.2); clearTimeout(glanceT); glanceT = setTimeout(() => pf.sk.to(0, 0.7, 0.15), 1100);
}
function wake() { if (dozing) { dozing = false; POFU.inner.style.animationDuration = ''; faceHeld = null; showFace(null); hop(POFU, 4); } }
// Petting: long press melts him; strokes (direction changes after 22 px) lean him into the hand.
let lastStroke = 0;
function petStart(g) {
  petting = true; g.strokes = 0; g.dir = 0; g.travel = 0; g.lastX = g.x;
  if (!S.rm) { pf.sx.to(1.04, 0.6, 0); pf.sy.to(0.93, 0.6, 0); }
  holdFace('relieved'); haptic('erime · Core Haptics, 0,6 sn');
}
function petMove(g, x, y) {
  const dx = x - g.lastX; g.lastX = x; const dir = Math.sign(dx);
  if (dir && g.dir && dir !== g.dir && g.travel > 22) stroke(g, x, y);
  if (dir && dir !== g.dir) g.travel = 0;
  if (dir) g.dir = dir; g.travel += Math.abs(dx);
  const [px] = toScreen(POFU_AT[0], POFU_AT[1]); const w = 64 * camS();
  if (!S.rm) pf.sk.to(-clamp((x - px) / (w * 0.5), -1, 1) * 5, 0.25, 0);
}
function stroke(g, x, y) {
  g.strokes++;
  if (now() - lastStroke > 250) { lastStroke = now(); haptic('yumuşak · 0,25'); }
  const [wx, wy] = toWorld(x, y);
  if (!S.rm) for (let i = 0; i < 2; i++) {
    const s = camS(), d = el('i', 'wisp', camEl); d.style.left = wx + 'px'; d.style.top = wy + 'px';
    d.animate([{ transform: `scale(${1 / s})`, opacity: 1 }, { transform: `translate(${(i ? 6 : -6)}px,${-14}px) scale(${0.6 / s})`, opacity: 0 }], { duration: 700, easing: 'cubic-bezier(.2,.8,.2,1)' }).finished.then(() => d.remove());
  }
  if (g.strokes === 8 && !dozing) { dozing = true; holdFace('breathe'); POFU.inner.style.animationDuration = '6s'; }
}
function petEnd() {
  petting = false; pf.sk.to(0, 0.5, 0.2);
  if (!S.rm) { pf.sx.to(1, 0.9, 0.1); pf.sy.to(1, 0.9, 0.1); }
  if (!dozing) { faceHeld = null; face('relieved', 1200); }
}

// ------------------------------------------------------------------ residents, lawn
// Residents. A tap focuses on the resident: a small camera move, a rack focus to its depth, and a
// small card with its line, its station, and one action. Lines are rationed: each once per visit.
const NPC = {
  bunny: { name: 'Mochi', lines: ['Çay demlendi. Bir bardak?', 'İnce belli bardakta, tavşan kanı.', 'Tabureler gelince otur biraz.'] },
  hog: { name: 'Fındık', lines: ['Tık tık. Bir şey tamir ediyorum.', 'Rüzgâr gülü yakında döner.', 'Vida mı lazım? Bende bin tane var.'] },
};
const npcSeen = {}; let npcReturn = null;
function residentTap(o) {
  if (S.npc === 'sheet') { hop(o, 7); openStation(o.station); return; }
  showNpc(o);
}
function showNpc(o) {
  closeMorph(); closePanel();
  if (!npc) npcReturn = { ...framing(nearestView()) };
  npc = o.id; hop(o, 7); haptic('yumuşak darbe · 0,4');
  const st = ST[o.station], d = NPC[o.id], i = (npcSeen[o.id] = (npcSeen[o.id] ?? -1) + 1);
  $('#npcName').textContent = d.name; $('#npcSt').textContent = `${st.name} · Seviye ${st.lv}`;
  $('#npcLine').textContent = d.lines[i] || '';
  const c = $('#npc'); c.classList.add('on'); CH.npcH = c.offsetHeight;
  c.getAnimations().forEach((a) => a.cancel());
  const sp = ease(0.42, 0.35);
  c.animate([{ opacity: 0, scale: 0.9 }, { opacity: 1, scale: 1 }], { duration: S.rm ? 150 : sp.ms, easing: S.rm ? 'linear' : sp.css, fill: 'forwards' });
  const b = npcReturn;
  moveCam({ x: lerp(b.x, o.x, 0.35), y: lerp(b.y, o.y - 14, 0.35), l: b.l + Math.log(1.3), ay: b.ay }, 0.6, 0.12);
  kick();
}
function hideNpc(back) {
  if (!npc) return; npc = null; const c = $('#npc');
  c.getAnimations().forEach((a) => a.cancel());
  c.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 140, fill: 'forwards' }).finished.then(() => { if (!npc) c.classList.remove('on'); });
  if (back && npcReturn) moveCam(npcReturn, 0.6, 0.1);
  kick();
}
function placeNpc() {
  if (!npc) return; const o = O[npc], c = CH.npc, w = 232, h = CH.npcH || 130;
  // Below the resident's feet: the card covers lawn and rock, never the resident's own stall.
  const [x, y] = toScreen(o.x, o.y + 2);
  const left = clamp(x - w / 2, 12, W - 12 - w), top = Math.min(y + 14, H - h - 90);
  setTf(c, `translate3d(${left.toFixed(1)}px,${top.toFixed(1)}px,0)`);
  const tail = clamp(x - left, 24, w - 24).toFixed(0) + 'px'; if (c._tail !== tail) { c._tail = tail; c.style.setProperty('--tail', tail); }
}
$('#npcGo').addEventListener('click', () => { const o = O[npc]; if (!o) return; hideNpc(false); openStation(o.station); });
function chip(text, wx, wy, ms) {
  const c = el('div', 'chipw', ov); c.textContent = text; const a = { el: c, wx, wy, dx: 0, dy: -6 }; ANCH.push(a); render();
  c.animate([{ opacity: 0, scale: 0.9 }, { opacity: 1, scale: 1 }], { duration: 260, easing: ease(0.42, 0.35).css });
  setTimeout(() => c.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 240, fill: 'forwards' }).finished.then(() => c.remove()), ms);
}
function onLawn(wx, wy) { return (wx / 172) ** 2 + ((wy + 10) / 82) ** 2 < 1; }
function ripple(sx, sy) {
  const [wx, wy] = toWorld(sx, sy); if (!onLawn(wx, wy)) return;
  const s = camS(), r = el('i', 'ripple', camEl); r.style.left = wx + 'px'; r.style.top = wy + 'px';
  r.animate([{ transform: `scale(${0.3 / s})`, opacity: 0.8 }, { transform: `scale(${1.3 / s})`, opacity: 0 }], { duration: 520, easing: 'cubic-bezier(.2,.8,.2,1)' }).finished.then(() => r.remove());
  if (S.rm) return;
  for (let i = 0; i < 3; i++) {
    const l = el('i', 'leaf', camEl); l.style.left = wx + 'px'; l.style.top = wy + 'px';
    const ang = -Math.PI / 2 + (i - 1) * 0.7, d = 16 / s;
    l.animate([{ transform: `scale(${1 / s})`, opacity: 1 }, { transform: `translate(${Math.cos(ang) * d}px,${Math.sin(ang) * d}px) scale(${1 / s}) rotate(${i * 90}deg)`, opacity: 0 }], { duration: 560, easing: 'cubic-bezier(.2,.8,.2,1)' }).finished.then(() => l.remove());
  }
}

// ------------------------------------------------------------------ hit testing (world space)
// Mirrors SwiftUI contentShape: simple shapes, padded so nothing is smaller than 44 pt on screen.
function pad(w, s) { return Math.max(0, (44 / s - w) / 2); }
function regions() {
  const s = camS(), z = zOf(cam.l.v), out = [];
  if (z > 0.55) {
    const p = pad(64, s); out.push({ type: 'pofu', id: 'pofu', x0: POFU_AT[0] - 30 - p, x1: POFU_AT[0] + 30 + p, y0: POFU_AT[1] - 58 - p, y1: POFU_AT[1] + 4 + p, pr: 3 });
    if (z <= 1.5 || sheet.open || S.model === 'B') for (const id of ['bunny', 'hog']) { const o = O[id], w = 26, p2 = pad(w, s); out.push({ type: 'res', id, x0: o.x - 13 - p2, x1: o.x + 13 + p2, y0: o.y - 24 - p2, y1: o.y + 2 + p2, pr: 2 }); }
    // At Home the world behind Pofu is out of focus: it is one target, "the island", not five.
    if (z > 1.5 && !sheet.open && S.model !== 'B') out.push({ type: 'island', id: 'home', ell: true, cx: 0, cy: 10, rx: 190, ry: 150, pr: 0 });
    else for (const st of STATIONS) out.push({ type: 'station', id: st.id, x0: st.at[0] - 46, x1: st.at[0] + 46, y0: st.at[1] - 84, y1: st.at[1] + 10, pr: 1 });
  } else {
    out.push({ type: 'island', id: 'home', ell: true, cx: 0, cy: 0, rx: Math.max(150, 44 / s), ry: Math.max(110, 44 / s), pr: 1 });
    for (const i of ISLES) out.push({ type: 'island', id: i.id, ell: true, cx: i.pos[0], cy: i.pos[1] + 8, rx: Math.max(105, 44 / s), ry: Math.max(90, 44 / s), pr: 1 });
  }
  return out;
}
function hitTest(sx, sy) {
  const [wx, wy] = toWorld(sx, sy); let best = null, bd = 1e9;
  for (const r of regions()) {
    let inside, d;
    if (r.ell) { const q = ((wx - r.cx) / r.rx) ** 2 + ((wy - r.cy) / r.ry) ** 2; inside = q < 1; d = q; }
    else { inside = wx >= r.x0 && wx <= r.x1 && wy >= r.y0 && wy <= r.y1; d = Math.hypot(wx - (r.x0 + r.x1) / 2, wy - r.y1); }
    // Priority first (Pofu > residents > stations), then the nearest anchor.
    if (inside && (!best || r.pr > best.pr || (r.pr === best.pr && d < bd))) { best = r; bd = d; }
  }
  return best || { type: 'empty' };
}
const hitDivs = [];
function drawHits() {
  const rs = regions(); while (hitDivs.length < rs.length) hitDivs.push(el('div', 'hit', hitsEl, '<i></i>'));
  hitDivs.forEach((d, i) => {
    const r = rs[i]; if (!r) { d.style.display = 'none'; return; } d.style.display = '';
    let x0, y0, x1, y1;
    if (r.ell) { [x0, y0] = toScreen(r.cx - r.rx, r.cy - r.ry); [x1, y1] = toScreen(r.cx + r.rx, r.cy + r.ry); } else { [x0, y0] = toScreen(r.x0, r.y0); [x1, y1] = toScreen(r.x1, r.y1); }
    d.className = 'hit' + (r.ell ? ' e' : '') + (r.type === 'pofu' ? ' p' : r.type === 'res' ? ' r' : '');
    d.style.transform = `translate(${x0.toFixed(1)}px,${y0.toFixed(1)}px)`; d.style.width = (x1 - x0).toFixed(1) + 'px'; d.style.height = (y1 - y0).toFixed(1) + 'px';
    d.firstChild.textContent = `${r.id} ${Math.round(x1 - x0)}×${Math.round(y1 - y0)}`;
  });
}

// ------------------------------------------------------------------ gestures on the world
const P = new Map();
let g = null, lastTap = null, idleAt = now();
function mid() { const a = [...P.values()]; return [(a[0].x + a[1].x) / 2, (a[0].y + a[1].y) / 2, Math.hypot(a[0].x - a[1].x, a[0].y - a[1].y)]; }
function local(e) { const r = app.getBoundingClientRect(); return [e.clientX - r.left, e.clientY - r.top]; }
world.addEventListener('pointerdown', (e) => {
  const [x, y] = local(e); try { world.setPointerCapture(e.pointerId); } catch (err) { /* synthetic */ }
  P.set(e.pointerId, { x, y }); onInput();
  if (cloud) { skipCloud(); g = { type: 'ignore' }; return; }
  if (P.size === 1) start1(x, y); else if (P.size === 2) startPinch(); else g = { type: 'ignore' };
});
world.addEventListener('pointermove', (e) => {
  const p = P.get(e.pointerId); if (!p) return; const [x, y] = local(e); p.x = x; p.y = y;
  if (!g) return;
  if (g.type === 'pinch') movePinch(); else if (P.size === 1) move1(x, y);
});
function up(e, cancel) {
  if (!P.has(e.pointerId)) return; const [x, y] = local(e); P.delete(e.pointerId);
  if (!g) return;
  if (g.type === 'pinch') { if (P.size < 2) { endPinch(); g = P.size ? { type: 'ignore' } : null; } return; }
  if (P.size === 0) { end1(x, y, cancel); g = null; }
}
world.addEventListener('pointerup', (e) => up(e, false));
world.addEventListener('pointercancel', (e) => up(e, true));
world.addEventListener('contextmenu', (e) => e.preventDefault());

function start1(x, y) {
  const hit = hitTest(x, y);
  g = { type: 'pending', hit, x, y, x0: x, y0: y, t0: now(), samples: [[now(), x, y]] };
  if (hit.type === 'pofu' && !sheet.open) { pofuDown(); g.lp = setTimeout(() => { if (g && g.type === 'pending') { g.type = 'pet'; petStart(g); } }, 350); }
  else if ((hit.type === 'station' || hit.type === 'res') && !(sheet.open && hit.type === 'res')) press(O[hit.id], true);
  else if (hit.type === 'empty' && !sheet.open) ripple(x, y);
  gestureLive = true; kick();
}
function releasePress() { if (!g) return; clearTimeout(g.lp); if (g.hit.type === 'pofu') pofuUp(); else if (g.hit.type === 'station' || g.hit.type === 'res') press(O[g.hit.id], false); }
function move1(x, y) {
  g.samples.push([now(), x, y]); if (g.samples.length > 8) g.samples.shift();
  const dx = x - g.x0, dy = y - g.y0;
  if (g.type === 'pending' && Math.hypot(dx, dy) > 9) {
    releasePress();
    if (sheet.open) g.type = 'ignore';
    else if (S.model === 'C' && !S.rm) { g.type = 'peek'; }
    else if (S.model === 'B') { g.type = 'pan'; g.cx = cam.x.v; g.cy = cam.y.v; g.x0 = x; g.y0 = y; cam.x.set(cam.x.v); cam.y.set(cam.y.v); }
    else g.type = 'ignore';
  }
  if (g.type === 'pet') petMove(g, x, y);
  else if (g.type === 'peek') { cam.ox.set(rb(dx, 30)); cam.oy.set(rb(dy, 30)); kick(); }
  else if (g.type === 'pan') { const s = camS(); cam.x.set(bandX(g.cx - (x - g.x0) / s)); cam.y.set(bandY(g.cy - (y - g.y0) / s)); kick(); }
}
const BX = [-260, 260], BY = [-560, 300];
function bandX(x) { return x < BX[0] ? BX[0] - rb(BX[0] - x, 60) : x > BX[1] ? BX[1] + rb(x - BX[1], 60) : x; }
function bandY(y) { return y < BY[0] ? BY[0] - rb(BY[0] - y, 60) : y > BY[1] ? BY[1] + rb(y - BY[1], 60) : y; }
function vel2(samples) {
  const t1 = samples[samples.length - 1]; let t0 = samples[0];
  for (const s of samples) if (t1[0] - s[0] <= 100) { t0 = s; break; }
  if (now() - t1[0] > 60) return [0, 0]; // the finger rested before lifting: no fling
  const dt = (t1[0] - t0[0]) / 1000; return dt > 0.005 ? [(t1[1] - t0[1]) / dt, (t1[2] - t0[2]) / dt] : [0, 0];
}
function end1(x, y, cancel) {
  gestureLive = false;
  if (g.type === 'pending') { releasePress(); if (!cancel) tap(g.hit, x, y); }
  else if (g.type === 'pet') petEnd();
  else if (g.type === 'peek') { cam.ox.to(0, 0.45, 0.15); cam.oy.to(0, 0.45, 0.15); }
  else if (g.type === 'pan') {
    const [vx, vy] = vel2(g.samples), s = camS();
    cam.x.to(clamp(cam.x.v - vx / s * 0.3, BX[0], BX[1]), 0.6, 0, -vx / s);
    cam.y.to(clamp(cam.y.v - vy / s * 0.3, BY[0], BY[1]), 0.6, 0, -vy / s);
  }
  kick();
}
function press(o, down) {
  if (!o) return;
  if (down) anim(o.tf, [{ transform: 'scale(1)' }, { transform: 'scale(0.965)' }], 0.16, 0, { fill: 'forwards' });
  else { const cur = getComputedStyle(o.tf).transform; o.tf.getAnimations().forEach((a) => a.cancel()); anim(o.tf, [{ transform: cur === 'none' ? 'scale(1)' : cur }, { transform: 'scale(1)' }], 0.28, 0.45); }
}
function tap(hit, x, y) {
  if (sheet.open) {
    // A tap on the world behind a medium sheet: another station retargets, anything else dismisses.
    if (hit.type === 'station') openStation(hit.id); else if (hit.type === 'res') openStation(O[hit.id].station); else closeSheet();
    return;
  }
  if (npc) {
    // While a resident's card is up: another resident swaps, a station opens, anything else closes.
    if (hit.type === 'res') residentTap(O[hit.id]);
    else if (hit.type === 'station') openStation(hit.id);
    else hideNpc(true);
    return;
  }
  if (hit.type === 'pofu') { pofuUp(); poke(); }
  else if (hit.type === 'res') residentTap(O[hit.id]);
  else if (hit.type === 'station') openStation(hit.id);
  else if (hit.type === 'island') { if (zOf(cam.l.v) > 1.5) goTo('island'); else islandTap(hit.id); }
  else {
    glance(x);
    const t = now();
    if (lastTap && t - lastTap.t < 300 && Math.hypot(x - lastTap.x, y - lastTap.y) < 40) { lastTap = null; doubleTap(x, y); }
    else lastTap = { t, x, y };
  }
}
function doubleTap(x, y) {
  if (S.model === 'A') return;
  if (S.model === 'B') {
    const s = camS(), target = s > 2.1 * K ? FR.island.l : Math.log(Math.min(3 * K, s * 2));
    const [wx, wy] = toWorld(x, y), s2 = Math.exp(target);
    moveCam({ x: target === FR.island.l ? FR.island.x : wx - (x - W / 2) / s2, y: target === FR.island.l ? FR.island.y : wy - (y - cam.ay.v) / s2, l: target, ay: cam.ay.v }, 0.5, 0.05);
    return;
  }
  stepIn();
}
function islandTap(id) {
  if (id === 'home') { goTo('island'); return; }
  const i = ISLES.find((q) => q.id === id); hop(O[id], 5);
  haptic('seçim');
  toast(i.locked ? `${i.name}: ${i.note}. Koşullar ada sayfasında.` : `${i.name}: bu prototipte yalnızca haritada.`);
}

// Pinch. The three models differ only here and in double tap and pan.
function startPinch() {
  if (g && g.type === 'pending') releasePress();
  if (g && g.type === 'pet') petEnd();
  if (sheet.open) closeSheet(true); // the pinch takes the camera; nothing is swallowed
  hideNpc(false);
  for (const k in cam) cam[k].set(cam[k].v);
  const [mx, my, d] = mid();
  const l0 = cam.l.v, z0 = zOf(l0), r = rail(z0), s0 = camS();
  g = { type: 'pinch', mx0: mx, my0: my, d0: Math.max(10, d), l0, t0: now(), samples: [[now(), l0]], det: Math.round(clamp(z0, 0, 2)), fired: false,
    P0: toWorld(mx, my), ox0: cam.ox.v - (cam.x.v - r.x) * s0, oy0: (cam.ay.v + cam.oy.v - cam.y.v * s0) - (r.ay - r.y * s0), ay0: cam.ay.v, moved: 0 };
  gestureLive = true; kick();
}
function movePinch() {
  const [mx, my, d] = mid(), m = d / g.d0, lm = Math.log(m);
  g.moved = Math.max(g.moved, Math.abs(lm), Math.hypot(mx - g.mx0, my - g.my0) / 100);
  if (S.model === 'A') {
    if (g.fired) return;
    cam.l.set(g.l0 + clamp(lm * 0.25, -0.05, 0.05));
    if (!g.fired && Math.abs(lm) > 0.22) { g.fired = true; cam.l.set(g.l0); if (lm > 0) stepIn(); else stepOut(); }
    kick(); return;
  }
  if (S.model === 'B') {
    const lo = Math.log(0.38 * K), hi = Math.log(3 * K), raw = g.l0 + lm;
    const l = raw > hi ? hi + rb(raw - hi, 0.2) : raw < lo ? lo - rb(lo - raw, 0.2) : raw, s = Math.exp(l);
    cam.l.set(l); cam.x.set(g.P0[0] - (mx - W / 2 - cam.ox.v) / s); cam.y.set(g.P0[1] - (my - g.ay0 - cam.oy.v) / s);
    g.samples.push([now(), raw]); if (g.samples.length > 8) g.samples.shift(); kick(); return;
  }
  // C: the pinch scrubs the rail. Scale follows the fingers 1:1; position follows the rail, with a
  // 35 % pull toward the fingers so the gesture feels anchored, released when the camera snaps.
  const raw = g.l0 + lm, l = bandL(raw), z = zOf(l), r = rail(z), s = Math.exp(l);
  cam.l.set(l); cam.x.set(r.x); cam.y.set(r.y); cam.ay.set(r.ay);
  const sx = W / 2 + g.ox0 + (g.P0[0] - r.x) * s, sy = r.ay + g.oy0 + (g.P0[1] - r.y) * s;
  cam.ox.set(g.ox0 + (mx - sx) * 0.35); cam.oy.set(g.oy0 + (my - sy) * 0.35);
  g.samples.push([now(), raw]); if (g.samples.length > 8) g.samples.shift();
  const v = pinchVel(), det = Math.round(clamp(zOf(raw + v * 0.18), 0, 2));
  if (det !== g.det) { g.det = det; haptic('kademe · .selection'); updateSeg(ORDER[det]); }
  kick();
}
function pinchVel() {
  const sm = g.samples, t1 = sm[sm.length - 1]; let t0 = sm[0];
  for (const s of sm) if (t1[0] - s[0] <= 100) { t0 = s; break; }
  if (now() - t1[0] > 60) return 0;
  const dt = (t1[0] - t0[0]) / 1000; return dt > 0.008 ? (t1[1] - t0[1]) / dt : 0;
}
function endPinch() {
  gestureLive = false;
  const dur = now() - g.t0;
  if (dur < 260 && g.moved < 0.08 && S.model !== 'B') { stepOut(); return; } // two-finger tap: one framing out
  if (S.model === 'A') { if (!g.fired) cam.l.to(g.l0, 0.3, 0); return; }
  const v = clamp(pinchVel(), -6, 6);
  if (S.model === 'B') {
    const lo = Math.log(0.38 * K), hi = Math.log(3 * K);
    if (cam.l.v > hi || cam.l.v < lo) cam.l.to(clamp(cam.l.v, lo, hi), 0.4, 0);
    view = nearestView(); updateSeg(view); return;
  }
  const raw = g.samples[g.samples.length - 1][1];
  const d = Math.round(clamp(zOf(raw + v * 0.18), 0, 2)), n = ORDER[d], f = framing(n);
  const banded = cam.l.v > homeFr().l + 1e-3 || cam.l.v < FR.map.l - 1e-3;
  const r = rail(zOf(cam.l.v)), vl = banded ? 0 : v;
  view = n; focus = null; updateSeg(n);
  if (S.rm) { cam.l.to(f.l, 0.2, 0); cam.x.to(f.x, 0.2, 0); cam.y.to(f.y, 0.2, 0); cam.ay.to(f.ay, 0.2, 0); cam.ox.to(0, 0.2, 0); cam.oy.to(0, 0.2, 0); return; }
  moveCam(f, 0.55, banded ? 0 : 0.08, { l: vl, x: vl * r.dxl, y: vl * r.dyl, ay: vl * r.dal });
}
// Trackpad pinch and ctrl + wheel on a desktop: the same rail, settled 160 ms after the last event.
let wheelT = 0;
world.addEventListener('wheel', (e) => {
  e.preventDefault(); if (cloud || sheet.open) return; onInput();
  const lm = -e.deltaY * (e.ctrlKey ? 0.01 : 0.0025);
  if (S.model === 'A') { if (!g || g.type !== 'wheel') { g = { type: 'wheel', acc: 0 }; } g.acc += lm; if (Math.abs(g.acc) > 0.22) { g.acc > 0 ? stepIn() : stepOut(); g.acc = -1e9 * Math.sign(g.acc); } clearTimeout(wheelT); wheelT = setTimeout(() => { g = null; }, 200); return; }
  for (const k in cam) cam[k].set(cam[k].v);
  const l = S.model === 'B' ? clamp(cam.l.v + lm, Math.log(0.38 * K), Math.log(3 * K)) : bandL(cam.l.v + lm);
  if (S.model === 'B') { const [x, y] = local(e), P0 = toWorld(x, y), s = Math.exp(l); cam.l.set(l); cam.x.set(P0[0] - (x - W / 2 - cam.ox.v) / s); cam.y.set(P0[1] - (y - cam.ay.v - cam.oy.v) / s); }
  else { const r = rail(zOf(l)); cam.l.set(l); cam.x.set(r.x); cam.y.set(r.y); cam.ay.set(r.ay); }
  kick(); clearTimeout(wheelT);
  wheelT = setTimeout(() => { const n = nearestView(); view = n; updateSeg(n); if (S.model === 'C') moveCam(framing(n), 0.55, 0.08); }, 160);
}, { passive: false });

// ------------------------------------------------------------------ sheet with detents
const sheetY = new Sp(9999, 0.1), panelY = new Sp(9999, 0.1);
const sheet = { open: false, detent: 'closed', kind: null };
function sheetH(d) { return d === 'compact' ? 132 : d === 'medium' ? Math.round(H * 0.42) : d === 'large' ? H - SAFE_T - 10 : 0; }
function setDetent(d, vel) {
  sheet.detent = d; const y = d === 'closed' ? H + 24 : H - sheetH(d);
  sheetEl.classList.toggle('compact', d === 'compact');
  if (S.rm) sheetY.to(y, 0.3, 0, vel); else sheetY.to(y, 0.42, 0, vel);
}
function openStation(id) {
  closeMorph(); closePanel(); hideNpc(false);
  const retarget = sheet.open && sheet.kind === 'station';
  if (!sheet.open) { returnView = view; returnCam = S.model === 'B' ? { x: cam.x.t, y: cam.y.t, l: cam.l.t, ay: cam.ay.t } : null; }
  if (retarget && focus === id) return;
  haptic('seçim · .selection');
  focus = id; sheet.open = true; sheet.kind = 'station';
  renderStation(id, retarget);
  setDetent(sheet.detent === 'large' ? 'large' : 'medium');
  const f = focusFr(id);
  moveCam(f, 0.7, 0.12);
}
function closeSheet(keepCam) {
  if (!sheet.open) return;
  sheet.open = false; const wasStation = sheet.kind === 'station'; sheet.kind = null; focus = null; setDetent('closed');
  if (!keepCam && wasStation) { view = returnView; moveCam(returnCam || framing(returnView), 0.6, 0.1); updateSeg(view); }
  kick();
}
$('#sheetClose').addEventListener('click', () => closeSheet());
// Drag anywhere on the sheet. Velocity projection picks the detent; dismiss below half of medium.
let sd = null, suppressClick = false;
sheetEl.addEventListener('pointerdown', (e) => {
  onInput(); const [, y] = local(e);
  sd = { y0: y, sy0: sheetY.v, samples: [[now(), 0, y]], moved: false, onGrab: e.target.classList.contains('grab') };
  try { sheetEl.setPointerCapture(e.pointerId); } catch (err) { /* synthetic */ }
  sheetY.set(sheetY.v);
});
sheetEl.addEventListener('pointermove', (e) => {
  if (!sd) return; const [, y] = local(e); sd.samples.push([now(), 0, y]); if (sd.samples.length > 8) sd.samples.shift();
  if (!sd.moved && Math.abs(y - sd.y0) < 6) return; sd.moved = true;
  const top = H - sheetH('large'); let ny = sd.sy0 + (y - sd.y0);
  if (ny < top) ny = top - rb(top - ny, 40);
  sheetY.set(ny); kick();
});
function sheetUp(e) {
  if (!sd) return; const s = sd; sd = null;
  if (!s.moved) { if (s.onGrab && sheet.detent !== 'compact') setDetent(sheet.detent === 'large' ? 'medium' : 'large'); else if (sheet.open) setDetent(sheet.detent); return; }
  suppressClick = true; setTimeout(() => { suppressClick = false; }, 0);
  const [, vy] = vel2(s.samples), proj = sheetY.v + vy * 0.2;
  const hMed = sheetH('medium'), hLg = sheetH('large');
  const cands = [['medium', H - hMed], ['large', H - hLg]];
  if (building) cands.push(['compact', H - sheetH('compact')]);
  if (proj > H - hMed * 0.5 || vy > 1100) { closeSheet(); sheetY.vel = vy; return; }
  let best = cands[0]; for (const c of cands) if (Math.abs(c[1] - proj) < Math.abs(best[1] - proj)) best = c;
  setDetent(best[0], vy);
}
sheetEl.addEventListener('pointerup', sheetUp); sheetEl.addEventListener('pointercancel', sheetUp);
sheetEl.addEventListener('click', (e) => { if (suppressClick) { e.stopPropagation(); e.preventDefault(); } }, true);

// Station sheet content.
function renderStation(id, crossfade) {
  const st = ST[id], body = $('#stBody');
  const fill = () => {
    $('#stTitle').textContent = st.name; $('#stSub').textContent = st.who;
    const lv = st.lv, nxt = lv + 1, cost = st.cost[nxt - 1], can = nxt <= 5 && seeds >= cost;
    const thumb = nxt > 5 ? '' : st.art[nxt] ? `<div class="th"><img src="assets/${st.art[nxt]}.webp" alt=""></div>` : '<div class="th tbd">taslak<br>sanat yok</div>';
    body.innerHTML = building === id ? `<div class="dots">${dots(lv)}<span>İnşa ediliyor…</span></div>` :
      `<div class="dots">${dots(lv)}<span>Seviye ${lv} / 5</span></div>` +
      (nxt <= 5 ? `<div class="next more">${thumb}<div><b>Sıradaki: Seviye ${nxt}</b><span>${st.lvl[nxt - 1]}</span></div></div>
      <div class="rate more">Saatte ${st.rate[lv - 1]} → ${st.rate[nxt - 1]} çekirdek</div>
      <button class="cta" id="buildBtn" ${can ? '' : 'disabled'}>${can ? `<svg width="18" height="18" viewBox="0 0 24 24"><g transform="rotate(28 12 12)"><ellipse cx="12" cy="12" rx="6" ry="10" fill="currentColor"/></g></svg>İnşa et · ${fmt(cost)}` : `${fmt(cost - seeds)} çekirdek daha`}</button>` : '<p class="rate">Bu istasyon tamamlandı.</p>') +
      `<ul class="hist more">${st.lvl.map((t, i) => `<li><b>Seviye ${i + 1}</b>${t}</li>`).join('')}</ul>`;
    const b = $('#buildBtn'); if (b) b.addEventListener('click', () => build(id));
  };
  if (crossfade && !S.rm) { body.classList.add('fade'); setTimeout(() => { fill(); body.classList.remove('fade'); }, 110); } else fill();
}
const dots = (lv) => [1, 2, 3, 4, 5].map((i) => `<i class="${i <= lv ? 'on' : ''}"></i>`).join('');
function renderSeedsSheet() {
  $('#stTitle').textContent = 'Çekirdekler'; $('#stSub').textContent = 'Ada için, ekran süresi için değil';
  $('#stBody').innerHTML = `<div class="next"><div class="th"><svg width="40" height="40" viewBox="0 0 24 24"><g transform="rotate(28 12 12)"><ellipse cx="12" cy="12" rx="6" ry="10" fill="#5B4636"/><path d="M12 4v16" stroke="#F3E6D6" stroke-width="1.8" stroke-linecap="round"/></g></svg></div><div><b>${fmt(seeds)} çekirdek</b><span>Ada sen telefondan uzakken topladı.</span></div></div><div class="rate">Bugün +186 · Huzur ×1,6</div>`;
}

// ------------------------------------------------------------------ build moment
let seeds = 420, building = null;
function updateSeeds() { $('#seedN').textContent = fmt(seeds); $('#seedN2').textContent = fmt(seeds); }
function build(id) {
  const st = ST[id], nxt = st.lv + 1, cost = st.cost[nxt - 1];
  if (building || seeds < cost || !st.art[nxt]) return;
  building = id; seeds -= cost; updateSeeds();
  renderStation(id); setDetent('compact');
  moveCam(focusFr(id, true), 0.6, 0.1);
  const o = O[id];
  // Anticipation squash, then the swap hidden at the deepest point, then pop and sparkles.
  setTimeout(() => { if (!S.rm) anim(o.tf, [{ transform: 'scale(1,1)' }, { transform: 'scale(1.06,0.88)' }], null, null, { duration: 120, easing: 'cubic-bezier(.5,0,.9,.6)', fill: 'forwards' }); }, 300);
  setTimeout(() => {
    st.lv = nxt; swapArt(o, st.art[nxt]);
    haptic('orta darbe · takas');
    o.tf.getAnimations().forEach((a) => a.cancel());
    if (!S.rm) anim(o.tf, [{ transform: 'scale(1.06,0.88)' }, { transform: 'scale(1,1)' }], 0.55, 0.5);
    puffs(o); sparkles(o);
  }, 420);
  setTimeout(() => tag(o, `Seviye ${nxt}!`), 600);
  setTimeout(() => { hop(POFU, 12); if (!S.rm) face('excited', 1100); }, 720);
  const res = st.res && st.res !== 'pofu' ? O[st.res] : null;
  if (res) setTimeout(() => hop(res, 7), 840);
  setTimeout(() => haptic('başarı · .success'), 1020);
  setTimeout(() => { building = null; if (sheet.open && focus === id) { renderStation(id, true); setDetent('medium'); moveCam(focusFr(id), 0.6, 0.1); } }, 1750);
}
function swapArt(o, src) {
  // 120 ms cross-fade of the new art over the old, then the old set takes the new sources.
  const top = addImg(o.inner, src, BOX.st, ''); top.style.opacity = 0;
  top.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 120, fill: 'forwards' }).finished.then(() => {
    o.src = src; applyHaze(); const done = () => top.remove(); if (o.sharp.decode) o.sharp.decode().then(done, done); else setTimeout(done, 50);
  });
}
function puffs(o) {
  if (S.rm) return;
  for (let i = 0; i < 6; i++) {
    const p = el('i', 'puff', camEl); p.style.left = o.x + (i - 2.5) * 12 + 'px'; p.style.top = o.y + 4 + 'px';
    const dx = (i - 2.5) * 9;
    p.animate([{ transform: 'scale(.35)', opacity: 0.9 }, { transform: `translate(${dx}px,-10px) scale(1)`, opacity: 0 }], { duration: 650, easing: 'cubic-bezier(.2,.8,.2,1)' }).finished.then(() => p.remove());
  }
}
function sparkles(o) {
  if (S.rm) return;
  for (let i = 0; i < 7; i++) {
    const p = el('i', 'spark', camEl, '<svg viewBox="0 0 24 24" width="18" height="18"><path d="M12 1q1.2 9.8 11 11-9.8 1.2-11 11-1.2-9.8-11-11 9.8-1.2 11-11z" fill="#FFE7A0"/></svg>');
    p.style.left = o.x + 'px'; p.style.top = o.y - 50 + 'px';
    const a = -Math.PI / 2 + (i - 3) * 0.42, d = 46 + (i % 3) * 10;
    p.animate([{ transform: 'scale(.2)', opacity: 0 }, { transform: `translate(${Math.cos(a) * d * 0.5}px,${Math.sin(a) * d * 0.5}px) scale(.8)`, opacity: 1, offset: 0.3 }, { transform: `translate(${Math.cos(a) * d}px,${Math.sin(a) * d}px) scale(.3)`, opacity: 0 }], { duration: 800, delay: i * 30, easing: 'cubic-bezier(.2,.8,.2,1)' }).finished.then(() => p.remove());
  }
}
function tag(o, text) {
  const t = el('div', 'tag', ov); t.textContent = text; ANCH.push({ el: t, wx: o.x, wy: o.y - 110, dx: 0, dy: 0 }); render();
  if (!S.rm) t.animate([{ opacity: 0, scale: 0.6 }, { opacity: 1, scale: 1 }], { duration: ease(0.55, 0.5).ms, easing: ease(0.55, 0.5).css });
  setTimeout(() => t.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 300, fill: 'forwards' }).finished.then(() => t.remove()), 2600);
}

// ------------------------------------------------------------------ glass morph menus
let morph = null;
function openMorph(btn, panel, width) {
  if (morph) { const same = morph.panel === panel; closeMorph(); if (same) return; }
  closeSheet(); closePanel();
  const ar = app.getBoundingClientRect(), br = btn.getBoundingClientRect();
  const P6 = 6, right = br.right - ar.left + P6, top = br.top - ar.top - P6;
  panel.style.width = width + 2 * P6 + 'px'; panel.style.left = (right - width - 2 * P6) + 'px'; panel.style.top = top + 'px';
  panel.classList.add('open'); const h = panel.offsetHeight, w = width + 2 * P6;
  const from = [br.top - ar.top - top, w - (br.right - ar.left - (right - w)), h - (br.bottom - ar.top - top), br.left - ar.left - (right - w)];
  const to = [P6, P6, P6, P6];
  const r0 = br.height / 2;
  morph = { btn, panel, from, to, r0 };
  btn.style.opacity = 0; $('#scrim').classList.add('on'); kick();
  morphClip(panel, from, to, r0, 26, S.rm ? [0.2, 0] : [0.38, 0.18]);
  const mc = panel.querySelector('.mc');
  mc.animate([{ opacity: 0, transform: 'translateY(-4px)' }, { opacity: 1, transform: 'none' }], { duration: 160, delay: S.rm ? 0 : 90, fill: 'forwards', easing: 'ease-out' });
  haptic('seçim');
}
function morphClip(panel, from, to, r0, r1, [d, b]) {
  // Sample the spring into clip-path keyframes so the morph keeps a little liquid overshoot.
  const sp = ease(d, b), kf = [];
  for (let i = 0; i <= 30; i++) {
    const p = i === 30 ? 1 : sp.f((sp.ms / 1000) * i / 30);
    const ins = from.map((f, j) => Math.max(0, f + (to[j] - f) * p).toFixed(2) + 'px');
    kf.push({ clipPath: `inset(${ins.join(' ')} round ${(r0 + (r1 - r0) * clamp(p)).toFixed(2)}px)` });
  }
  panel.getAnimations().forEach((a) => a.cancel());
  return panel.animate(kf, { duration: sp.ms, easing: 'linear', fill: 'forwards' });
}
function closeMorph() {
  if (!morph) return; const m = morph; morph = null; $('#scrim').classList.remove('on'); kick();
  const mc = m.panel.querySelector('.mc'); mc.getAnimations().forEach((a) => a.cancel());
  mc.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 70, fill: 'forwards' });
  morphClip(m.panel, m.to, m.from, 26, m.r0, S.rm ? [0.2, 0] : [0.3, 0]).finished.then(() => {
    if (morph && morph.panel === m.panel) return;
    m.panel.classList.remove('open'); m.btn.style.opacity = '';
  });
}
$('#scrim').addEventListener('click', () => closeMorph());
$('#seedBtn').addEventListener('click', () => {
  if (S.menu === 'morph') openMorph($('#seedBtn'), $('#seedMorph'), 260);
  else { closeMorph(); if (sheet.open) closeSheet(); returnView = view; sheet.open = true; sheet.kind = 'seeds'; focus = null; renderSeedsSheet(); setDetent('medium'); haptic('seçim'); }
});
$('#moreBtn').addEventListener('click', () => openMorph($('#moreBtn'), $('#moreMorph'), 240));
$('#moreMorph').addEventListener('click', (e) => {
  const b = e.target.closest('button'); if (!b) return; const act = b.dataset.act; closeMorph();
  if (act === 'hits') { S.hits = !S.hits; hitsEl.style.display = S.hits ? '' : 'none'; renderPanel(); kick(); }
  if (act === 'theme') { const d = document.documentElement; const dark = d.dataset.theme ? d.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches; d.dataset.theme = dark ? 'light' : 'dark'; }
  if (act === 'panel') setTimeout(openPanel, 200);
});

// ------------------------------------------------------------------ segmented framing control
function updateSeg(n) { for (const b of document.querySelectorAll('#seg button')) b.setAttribute('aria-pressed', String(b.dataset.f === n)); }
for (const b of document.querySelectorAll('#seg button')) b.addEventListener('click', () => { onInput(); haptic('seçim'); goTo(b.dataset.f); });

// ------------------------------------------------------------------ idle life, blinks, returns
function scheduleBlink() {
  setTimeout(() => {
    if (!faceKind && !petting && !dozing && zOf(cam.l.v) > 0.6 && !document.hidden) face('breathe', 150);
    scheduleBlink();
  }, 3000 + Math.random() * 3000);
}
let idleCount = 0;
function onInput() { idleAt = now(); idleCount = 0; if (dozing && !petting) { /* any touch wakes him only if it is on him */ } }
setInterval(() => {
  // The world performs less the longer you watch: three idle beats, then only breathing and blinks.
  const t = (now() - idleAt) / 1000; const beats = [20, 45, 80];
  if (idleCount < 3 && t > beats[idleCount] && !sheet.open && !petting && !document.hidden) {
    const k = idleCount++;
    if (k === 0 || k === 2) yawn(); else hop(O.bunny, 5);
  }
}, 1000);
function yawn() {
  if (dozing) return; face('breathe', 1100);
  if (S.rm) return; pf.sy.to(1.06, 0.5, 0); pf.sx.to(0.97, 0.5, 0);
  setTimeout(() => { pf.sy.to(1, 0.9, 0.1); pf.sx.to(1, 0.9, 0.1); }, 520);
}
let hiddenAt = 0;
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { hiddenAt = now(); return; }
  if (hiddenAt && now() - hiddenAt > 30000) setTimeout(() => { glance(W / 2); face('breathe', 150); }, 250);
});
function playReturn(kind) {
  closePanel(); if (view !== 'home') goTo('home');
  setTimeout(() => {
    if (kind === 'proud') { holdFace(null); face('proud', 1800); hop(POFU, 14); say('Vazgeçtin! Başardık. Yani, çoğunu sen.'); }
    if (kind === 'worried') {
      face('worried', 2600); say('Bu uzun sürdü. İyi misin? Ben biraz sallantıdayım.');
      if (!S.rm) for (let i = 0; i < 6; i++) setTimeout(() => pf.sk.cfg(0.12, 0.3).push(i % 2 ? 40 : -40), i * 90);
    }
    if (kind === 'morning') {
      face('relieved', 1800); say('Günaydın. Ada bütün gece huzurluydu.');
      if (!S.rm) { pf.sy.to(1.07, 0.6, 0); setTimeout(() => pf.sy.to(1, 0.9, 0.12), 620); }
    }
  }, view === 'home' ? 250 : 900);
}

// ------------------------------------------------------------------ cloud pass (new island)
let cloud = null;
function cloudPass() {
  closePanel(); closeSheet(true); closeMorph();
  const c = $('#clouds'); c.innerHTML = ''; c.classList.add('on');
  const parts = [[-1, 0.18, 4.2], [1, 0.32, 4.6], [-1, 0.55, 4.4], [1, 0.75, 4.8]].map(([side, y, k]) => {
    const im = el('img', '', c); im.src = 'assets/cloud-b.webp'; im.alt = '';
    const w = 120 * k; Object.assign(im.style, { width: w + 'px', left: (W / 2 - w / 2) + 'px', top: (H * y - w * 0.2) + 'px' });
    return { im, side };
  });
  const isle = O.harbor; isle.arrive = 0;
  const anims = [];
  cloud = { anims, done: false };
  parts.forEach(({ im, side }, i) => anims.push(im.animate([{ transform: `translateX(${side * W}px)` }, { transform: `translateX(${side * W * 0.08}px)` }], { duration: 500, delay: i * 40, easing: 'cubic-bezier(.4,0,.9,.6)', fill: 'forwards' })));
  Promise.all(anims.map((a) => a.finished)).then(() => {
    if (!cloud) return;
    view = 'map'; focus = null; setCam(FR.map); updateSeg('map'); render();
    setTimeout(() => {
      if (!cloud) return;
      parts.forEach(({ im, side }, i) => anims.push(im.animate([{ transform: `translateX(${side * W * 0.08}px)` }, { transform: `translateX(${-side * W * 1.1}px)` }], { duration: 700, delay: i * 30, easing: 'cubic-bezier(.1,.6,.3,1)', fill: 'forwards' })));
      const d = isle.hop.animate([{ transform: 'translate(160px,30px)' }, { transform: 'none' }], { duration: 1600, easing: ease(0.9, 0.1).css, fill: 'backwards' });
      isle.arrive = 1; anims.push(d); kick();
      d.finished.then(() => { if (cloud) endCloud(true); });
    }, 150);
  });
}
function skipCloud() { if (!cloud) return; cloud.anims.forEach((a) => { try { a.finish(); } catch (e) { /* infinite */ } }); view = 'map'; setCam(FR.map); updateSeg('map'); endCloud(true); }
function endCloud(ok) {
  if (!cloud) return; cloud = null; O.harbor.arrive = 1; $('#clouds').classList.remove('on'); $('#clouds').innerHTML = '';
  if (ok) { haptic('başarı · .success'); toast('Bak hele: gece yeni bir ada yanaştı!'); } kick();
}

// ------------------------------------------------------------------ compare panel
const FX = [['parallax', 'a · Paralaks'], ['tilt', 'a · Cihaz eğimi'], ['haze', 'b · Hava perspektifi'], ['bokeh', 'c · Ön plan bokeh'], ['shadows', 'd · Temas gölgeleri'], ['tiltshift', 'e · Tilt-shift'], ['depthmap', 'f · Derinlik haritası'], ['dolly', 'g · Perspektif eğim']];
const OPTS = [
  { key: 'model', title: 'Yakınlaştırma modeli', items: [['A', 'A · Yalnız dokunma'], ['B', 'B · Serbest'], ['C', 'C · Kademeli', true]],
    note: { A: 'Çerçeveler yalnız düğmelerle ve dokunmayla değişir. Kıstırma sadece bir kısayol: eşik geçilince aynı hareket oynar.', B: 'Haritalar gibi: serbest kıstırma, kaydırma, momentum. Çerçeveler kaybolur, sanat çözünürlüğü açığa çıkar.', C: 'Kıstırma kamerayı üç çerçeve arasındaki rayda parmakla birlikte taşır; bırakınca hıza göre en yakın çerçeveye oturur. Sınırlarda lastik etkisi.' } },
  { key: 'blur', title: 'Alan derinliği', items: [['pre', 'Hazır bulanık katman', true], ['live', 'Canlı filtre'], ['none', 'Yok']],
    note: { pre: 'Her görselin iki bulanık kopyası boru hattında üretilir; çalışırken yalnızca saydamlık değişir. Kare başına filtre yok.', live: 'Karşılaştırma için: her nesneye CSS blur. Kamera hareketinde her karede yeniden hesaplanır; iPhone\'da FPS\'e bakın.', none: 'Bulanıklık yok: odak yalnız kamera ve karartmayla anlatılır.' } },
  { key: 'behind', title: 'Sayfanın arkasında dünya', items: [['dof', 'Odak (bulanık)', true], ['dim', 'Karartma'], ['scale', 'Küçültme']],
    note: { dof: 'Odaktaki istasyon keskin kalır, gerisi yumuşar. Büyük sayfada her şey derinleşir, hafifçe kararır.', dim: 'Klasik: dünya %22 kararır. Ucuz ama istasyon da kararır.', scale: 'iOS 13 kartı gibi dünya %94\'e küçülür. Düzenlediğin şeyi küçültür; önerilmez.' } },
  { key: 'menu', title: 'Çekirdek düğmesi açılınca', items: [['morph', 'Camdan biçim değiştir', true], ['sheet', 'Alt sayfa']],
    note: { morph: 'Cam düğme büyüyerek panele dönüşür (glassEffectID). Kısa, bir bakışlık bilgi için.', sheet: 'Aynı bilgi alt sayfada. Tek sayfa kuralı: istasyon sayfası açıksa kapanır.' } },
  { key: 'home', title: 'Ana ekranda Pofu ölçeği', items: [[38, '%38 (inceleme B)', true], [20, '%20 (ADR metni)']],
    note: { 38: 'İnceleme 01\'de ölçülen B: Pofu 154 pt. Ana ekran ile ada arasında ×2,3 adım.', 20: 'ADR-0018 metnindeki rakam. Ana ekran ile ada neredeyse aynı çerçeve olur (×1,2); kıstırma rayı kısalır.' } },
  { key: 'dof', title: 'Odak modeli', items: [['depth', 'Derinliğe göre (lens)', true], ['flat', 'Açık / kapalı (v1)']],
    note: { depth: 'Her nesnenin bir derinliği var; bulanıklık, odak düzlemine uzaklıkla orantılı artar, önde ve arkada. Odak değişince lens yeniden odaklanır (rack focus).', flat: 'v1: odaktaki nesne keskin, gerisi aynı derecede yumuşak.' } },
  { key: 'npc', title: 'Komşuya dokununca', items: [['card', 'Küçük kart + Tezgâha git', true], ['sheet', 'Doğrudan istasyon sayfası']],
    note: { card: 'Kamera komşuya hafifçe yaklaşır ve odaklanır; cam bir kartta repliği, istasyonu ve tek bir eylem. Dünya yerinde kalır.', sheet: 'Komşu, istasyonunun kısayolu olur: sayfa açılır. Hızlı ama komşu bir kişilik değil, bir düğme gibi hissedilir.' } },
  { key: 'rm', title: 'Hareketi azalt', items: [[false, 'Kapalı'], [true, 'Açık']],
    note: { false: 'Sistem ayarı da okunur.', true: 'Kamera yolculuğu yerine 200 ms kesme; sıçrama, ezilme, parçacık ve göz atma yok. Kıstırma parmağı izlemeye devam eder.' } },
];
function renderPanel() {
  const pc = $('#panelBody');
  pc.innerHTML = OPTS.map((o) => `<div class="opt"><h3>${o.title}</h3><div class="sg">${o.items.map(([v, label, rec]) => `<button data-k="${o.key}" data-v="${v}" aria-pressed="${String(S[o.key]) === String(v)}">${label}${rec ? '<span class="rec">öneri</span>' : ''}</button>`).join('')}</div><p>${o.note[String(S[o.key])]}</p></div>`).join('') +
    `<div class="opt"><h3>Derinlik teknikleri</h3><div class="sg multi">${FX.map(([k, label]) => `<button data-fx="${k}" aria-pressed="${S.fx[k]}">${label}</button>`).join('')}</div>
      <div class="sg" style="margin-top:8px"><button data-set="rec">Önerilen set</button><button data-set="all">Hepsi</button><button data-set="none">Hiçbiri</button></div>
      <p>a: katmanlar derinliğe göre kayar (sürükle; cihaz eğimi izin ister). b: uzaktakiler daha açık, serin, soluk. c: ana ekranda lensin önünde odak dışı yapraklar, Pofu'nun düzleminde keskin polen. d: her şeyin altında yumuşak gölge. e: ada görünümünde üst ve alt bant bulanık, minyatür etkisi. f: ada plakası WebGL ile piksel piksel derinlikle oynar. g: çerçeveler arası geçişte hafif perspektif eğimi.</p></div>` +
    `<div class="opt"><h3>Göster</h3><div class="sg"><button data-t="hits" aria-pressed="${S.hits}">Dokunma alanları</button><button data-t="haptics" aria-pressed="${S.haptics}">Dokunsal geri bildirim</button><button data-t="fps" aria-pressed="${S.fps}">FPS</button></div><p>Dokunsal geri bildirimler sol altta adıyla görünür (tarayıcı titreşim veremez).</p></div>` +
    `<div class="opt"><h3>Uygulamaya dönüş tepkisi</h3><div class="sg"><button data-r="proud">Direndin</button><button data-r="worried">Uzun oturum</button><button data-r="morning">Sakin gece sonrası sabah</button></div><p>Her açılışta en fazla bir tepki; ilk kareden 250 ms sonra. Dokunsal yok: pasif olaylar titremez.</p></div>` +
    `<div class="opt"><h3>Yeni ada (bulut geçişi)</h3><div class="sg"><button data-c="1">Bulut geçişini oynat</button></div><p>Günde en fazla bir kez. Dokununca atlanır.</p></div>` +
    `<div class="opt"><h3>Denemeler</h3><p>İki parmakla kıstır · boş çimene çift dokun · iki parmakla tek dokun (uzaklaş) · Pofu'ya dokun, art arda dokun, basılı tutup okşa · Mochi'ye ve Fındık'a dokun · istasyona dokun, sayfayı sürükle, arkadaki başka istasyona dokun · çay ocağı ve bahçe inşa edilebilir.</p></div>`;
}
$('#panelBody').addEventListener('click', (e) => {
  const b = e.target.closest('button'); if (!b) return;
  if (b.dataset.k) {
    const k = b.dataset.k, raw = b.dataset.v; const v = k === 'home' ? +raw : k === 'rm' ? raw === 'true' : raw;
    S[k] = v; app.classList.toggle('rm', S.rm);
    if (k === 'home' || k === 'model') { setTimeout(() => { if (!sheet.open) moveCam(framing(view), 0.6, 0.1); }, 0); }
    if (k === 'blur') for (const o of OBJ) applyBlur(o);
    if (k === 'menu') closeMorph();
    renderPanel(); kick();
  }
  if (b.dataset.t) { const t = b.dataset.t; S[t] = !S[t]; hitsEl.style.display = S.hits ? '' : 'none'; $('#fps').style.display = S.fps ? 'block' : 'none'; renderPanel(); kick(); }
  if (b.dataset.fx) { const k = b.dataset.fx; if (k === 'tilt') { enableTilt(!S.fx.tilt); return; } S.fx[k] = !S.fx[k]; applyFx(); renderPanel(); }
  if (b.dataset.set) { const on = b.dataset.set; for (const k in S.fx) if (k !== 'tilt') S.fx[k] = on === 'all' ? true : on === 'none' ? false : RECOMMENDED[k]; applyFx(); renderPanel(); }
  if (b.dataset.r) playReturn(b.dataset.r);
  if (b.dataset.c) cloudPass();
});
function openPanel() { closeMorph(); if (sheet.open) closeSheet(); renderPanel(); panelY.to(0, S.rm ? 0.25 : 0.42, 0); }
function closePanel() { panelY.to(H * 0.8 + 40, 0.36, 0); }
$('#tabBtn').addEventListener('click', () => { onInput(); openPanel(); });
$('#panelClose').addEventListener('click', closePanel);
// Drag the panel's grabber down to close it.
let pd = null;
panelEl.querySelector('.grab').parentElement.addEventListener('pointerdown', (e) => {
  if (e.target.closest('.pc') || e.target.closest('button')) return; pd = { y0: local(e)[1], v0: panelY.v };
  try { e.currentTarget.setPointerCapture(e.pointerId); } catch (err) { /* synthetic */ }
});
panelEl.addEventListener('pointermove', (e) => { if (!pd) return; panelY.set(Math.max(0, pd.v0 + local(e)[1] - pd.y0)); kick(); });
panelEl.addEventListener('pointerup', () => { if (!pd) return; const d = panelY.v; pd = null; if (d > 80) closePanel(); else panelY.to(0, 0.42, 0); });

// ------------------------------------------------------------------ boot
function boot() {
  measure(); buildWorld();
  for (const o of OBJ) O[o.id] = o; POFU = O.pofu;
  buildOverlays();
  setCam(framing('home')); sheetY.set(H + 24); panelY.set(H * 0.8 + 40);
  app.classList.toggle('rm', S.rm); hitsEl.style.display = 'none'; updateSeeds(); updateSeg('home');
  app.addEventListener('scroll', () => { app.scrollTop = 0; app.scrollLeft = 0; });
  applyFx(); render(); renderPofu(); scheduleBlink();
  // Decode every world image up front, off the main thread, so the first frame that shows a blur
  // variant does not stall on a synchronous decode (UIImage.preparingForDisplay() on iOS).
  for (const im of document.querySelectorAll('#world img')) if (im.decode) im.decode().catch(() => {});
  setTimeout(() => say('Sen yokken ada 186 çekirdek topladı.', 4200), 600);
  window.addEventListener('resize', () => { measure(); if (!sheet.open) setCam(framing(view)); else setDetent(sheet.detent); panelY.set(panelY.v > 10 ? H * 0.8 + 40 : 0); kick(); });
}
// Test hooks for tools/check.js (read-only state and a few drivers).
window.__pofu = {
  state: () => ({ view, focus, npc, z: zOf(cam.l.v), s: camS(), sheet: { ...sheet, y: sheetY.v }, seeds, building, faceKind, petting, dozing, run: run.n, morph: morph ? morph.panel.id : null, settings: { ...S }, H, W, idle: SPRINGS.every((s) => !s.on), blur: Object.fromEntries(OBJ.map((o) => [o.id, +o.bs.v.toFixed(2)])) }),
  screenOf: (id) => {
    if (id === 'pofu') { const [x, y] = toScreen(POFU_AT[0], POFU_AT[1] - 28); return { x, y }; }
    const o = O[id]; if (!o) return null;
    const [x, y] = toScreen(o.x, o.y - (o.kind === 'station' ? 40 : o.kind === 'res' ? 10 : 0)); return { x, y };
  },
  set: (k, v) => { S[k] = v; app.classList.toggle('rm', S.rm); renderPanel(); kick(); },
  hit: (x, y) => hitTest(x, y),
  fx: (k, v) => { S.fx[k] = v; applyFx(); renderPanel(); },
  preset: (name) => { for (const k in S.fx) if (k !== 'tilt') S.fx[k] = name === 'all' ? true : name === 'none' ? false : RECOMMENDED[k]; applyFx(); },
  orient: (g, b) => { onOrient({ gamma: g, beta: b }); },
  renderCost: (reset) => { const r = { n: RT.n, avg: RT.n ? +(RT.sum / RT.n).toFixed(2) : 0, max: +RT.max.toFixed(2) }; if (reset) { RT.n = 0; RT.sum = 0; RT.max = 0; } return r; },
  lens: () => ({ f: foc.f.v, dz: foc.dz.v, k: foc.k.v, tx: tilt.x.v, ty: tilt.y.v, gl: glReady }),
  // Frame-time bench: camera flights Home <-> Island every 0.9 s and a tilt sweep, for ms.
  bench: (ms = 3000) => new Promise((res) => {
    const times = []; let last = performance.now(); const t0 = last; let i = 0;
    const flip = setInterval(() => goTo(i++ % 2 ? 'home' : 'island'), 900);
    const tick = (t) => {
      times.push(t - last); last = t; const e = (t - t0) / 1000;
      dev.x = Math.sin(e * 2.2) * 0.8; dev.y = Math.cos(e * 1.7) * 0.5; kick();
      if (t - t0 < ms) requestAnimationFrame(tick);
      else { clearInterval(flip); dev.x = dev.y = 0; kick(); times.shift(); times.sort((a, b) => a - b); res({ fps: Math.round(times.length * 1000 / ms), p95: +times[Math.floor(times.length * 0.95)].toFixed(1), worst: +times[times.length - 1].toFixed(1) }); }
    };
    requestAnimationFrame(tick);
  }),
  toScreen: (x, y) => toScreen(x, y),
};
boot();
