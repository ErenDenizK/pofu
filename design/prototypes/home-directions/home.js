// Shared builder for the Home direction mockups. Each page defines
// DIRECTION = { id, title, kicker, presets: [{ id, label, state }], world(state), layout(state), notes }
// and calls mount(DIRECTION). Query: ?preset=<id>&bare=1&labels=0
'use strict';

const Q = new URLSearchParams(location.search);

const ICON = {
  seed: (s = 22) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" aria-hidden="true"><g transform="rotate(28 12 12)"><path d="M12 2.5c3.6 0 6 4.6 6 10.2 0 5-2.6 8.8-6 8.8s-6-3.8-6-8.8C6 7.1 8.4 2.5 12 2.5z" fill="#F5B83D"/><path d="M12 2.5c3.6 0 6 4.6 6 10.2 0 5-2.6 8.8-6 8.8" fill="#D9932A" opacity=".55"/><path d="M12 3.6v17.2M9 5.5c-.8 3-.9 9 .4 14.2M15 5.5c.8 3 .9 9-.4 14.2" stroke="#7A4A12" stroke-width="1.3" fill="none" stroke-linecap="round" opacity=".75"/></g></svg>`,
  gear: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="3.2"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>`,
  ticket: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M3 8.5V6.8C3 6.4 3.4 6 3.8 6h16.4c.4 0 .8.4.8.8v1.7a3.5 3.5 0 0 0 0 7v1.7c0 .4-.4.8-.8.8H3.8c-.4 0-.8-.4-.8-.8v-1.7a3.5 3.5 0 0 0 0-7z"/><path d="M15 6.5v11" stroke-dasharray="2 2.2"/></svg>`,
  chev: `<svg class="chev" width="10" height="16" viewBox="0 0 10 16" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M2 2l6 6-6 6"/></svg>`,
  signal: (c) => `<svg width="18" height="12" viewBox="0 0 18 12" fill="${c}"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>`,
  wifi: (c) => `<svg width="17" height="12" viewBox="0 0 17 12" fill="${c}"><path d="M8.5 2.3c2.4 0 4.6.9 6.2 2.5l1.2-1.2A10.4 10.4 0 0 0 8.5.6 10.4 10.4 0 0 0 1.1 3.6l1.2 1.2a8.7 8.7 0 0 1 6.2-2.5zm0 3.4c1.5 0 2.8.6 3.8 1.5l1.2-1.2a7 7 0 0 0-10 0l1.2 1.2c1-.9 2.3-1.5 3.8-1.5zm0 3.4c.6 0 1.1.2 1.5.6L8.5 11.2 7 9.7c.4-.4.9-.6 1.5-.6z"/></svg>`,
  battery: (c) => `<svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="${c}" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2.5" fill="${c}"/><path d="M25 4.5v4a2.2 2.2 0 0 0 0-4z" fill="${c}" opacity=".45"/></svg>`,
  leaf: `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 19c0-8 5-14 15-14 0 10-6 15-14 15"/><path d="M5 19l7-7"/></svg>`,
};

function beadsHTML(list) {
  return `<div class="beads" role="img" aria-label="${list.filter((b) => b === 'S').length} of ${list.length} reaches skipped">${list.map((b) => `<span class="bead ${b === 'S' ? 's' : 'o'}"></span>`).join('')}</div>`;
}

function pofuHTML({ x, y, w, cheeks = false, id = 'pofu' }) {
  // x = center, y = feet line (in screen points)
  const h = w * (492 / 520);
  return `<div class="pofu ${cheeks ? 'cheeks' : ''}" id="${id}" role="img" aria-label="Pofu" style="left:${x}px;top:${y - h * 0.985}px;width:${w}px">
    <div class="shadow"></div>
    <div class="body"><img src="assets/pofu.webp" alt=""><div class="bulge l"><img src="assets/pofu.webp" alt=""></div><div class="bulge r"><img src="assets/pofu.webp" alt=""></div></div>
  </div>`;
}

function chromeHTML(s, o = {}) {
  const dark = !!s.dark;
  const c = dark ? '#fff' : '#2A1F2D';
  const beads = s.beads || 'SSOSSOSOOSS';
  const skips = [...beads].filter((b) => b === 'S').length;
  return `
  <div class="status"><span>9:41</span><div class="island"></div><span class="icons">${ICON.signal(c)}${ICON.wifi(c)}${ICON.battery(c)}</span></div>
  <div class="topbar">
    <button class="glass pill press" aria-label="${s.seeds} seeds">${ICON.seed(22)}<span class="num">${s.seeds}</span></button>
    <span class="spacer"></span>
    <button class="glass circle press" aria-label="Friends"><span class="avatar">D</span></button>
    <button class="glass circle press" aria-label="Settings">${ICON.gear}</button>
  </div>
  ${s.quiet ? `<div class="glass quiet"><span class="dot"></span>${s.quiet}</div>` : ''}
  ${s.collect ? `<div class="bubble has-action" style="top:${o.bubbleTop - 30}px">${s.collectLine || `I saved ${s.collect} seeds while you were away.`}<button class="collect press">${ICON.seed(18)}Collect ${s.collect}</button></div>`
    : s.bubble ? `<div class="bubble" style="top:${o.bubbleTop}px">${s.bubble}</div>` : ''}
  <div class="bottom">
    ${o.today === false ? '' : `<button class="today press" aria-label="Today">
      <div class="grow"><div class="big">${skips} of ${beads.length} skipped<small>today</small></div>${beadsHTML([...beads])}</div>${ICON.chev}
    </button>`}
    <div class="actions">
      <button class="glass prominent primary press">Fill my cheeks</button>
      <button class="glass secondary press" aria-label="Passes">${ICON.ticket}</button>
    </div>
  </div>`;
}

function mount(D) {
  const presetId = Q.get('preset') || D.presets[0].id;
  const preset = D.presets.find((p) => p.id === presetId) || D.presets[0];
  const s = preset.state;
  if (Q.get('bare') === '1') document.body.classList.add('bare');
  if (Q.get('labels') === '0') document.body.classList.add('hide-labels');
  const L = D.layout(s);
  const screen = document.getElementById('screen');
  screen.className = `${s.dark ? 'on-dark' : ''} grade-${s.grade || 'day'} ${s.vit ? 'vit-' + s.vit : ''}`;
  screen.innerHTML = `<div class="world" aria-hidden="true">${D.world(s)}</div>
    ${pofuHTML({ x: L.pofuX, y: L.pofuY, w: L.pofuW, cheeks: !!s.collect })}
    ${D.overlay ? D.overlay(s) : ''}
    ${chromeHTML(s, L)}
    <div class="standin">${D.standin}</div>`;
  const p = screen.querySelector('#pofu');
  p.addEventListener('click', () => { p.classList.remove('tap'); void p.offsetWidth; p.classList.add('tap'); });
  const panel = document.getElementById('panel');
  if (panel) {
    panel.innerHTML = `<nav><a href="index.html">All directions</a><a href="a-meadow.html">A</a><a href="b-island.html">B</a><a href="c-burrow.html">C</a></nav>
      <div class="kicker">${D.kicker}</div><h1>${D.title}</h1>
      <h2>States</h2><div class="states">${D.presets.map((p) => `<a class="${p.id === preset.id ? 'on' : ''}" href="?preset=${p.id}">${p.label}</a>`).join('')}</div>
      <p style="margin-top:12px"><b>${preset.label}.</b> ${preset.note || ''}</p>
      ${D.notes}`;
  }
  document.title = `Pofu Home · ${D.title} · ${preset.label}`;
}
