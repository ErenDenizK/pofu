// Renders the review's labeled stand-in sprites (islands, stations, residents, clouds, Pofu's
// code faces) from the island-game prototype's own drawing code, so the review and the
// prototype share one stand-in vocabulary. Output: transparent PNGs in a scratch folder;
// tools/painterly.py then softens them and writes WebP into ../assets.
//
//   node tools/render-standins.js <outdir>
//
// Pofu himself is production art (R1). Everything else drawn here is a stand-in until the
// GPT Image vignettes of game-design.md section 15 exist.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT = path.resolve(process.argv[2] || path.join(__dirname, '..', 'build'));
const GAME_DIR = path.resolve(__dirname, '..', '..', 'island-game');
const http = require('http');
// Served over HTTP: a file:// page taints its canvases, so they could not be exported.
function serve() {
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.woff2': 'font/woff2' };
  const srv = http.createServer((req, res) => {
    const f = path.join(GAME_DIR, path.normalize(decodeURIComponent(req.url.split('#')[0])).replace(/^(\.\.[/\\])+/, ''));
    if (!f.startsWith(GAME_DIR) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream' });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise((r) => srv.listen(0, '127.0.0.1', () => r(srv)));
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const srv = await serve();
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 402, height: 874 } });
  await page.goto(`http://127.0.0.1:${srv.address().port}/index.html#bare`);
  await page.waitForFunction(() => window.G && pofuImg.complete && bunnyImg.complete);
  const shots = await page.evaluate(() => {
    G.fastForward(20);
    S.emotion = null; S.night = false; S.popT = null;
    const out = {};
    // Render f() in world units x0..x1, y0..y1 at K device pixels per unit.
    const grab = (name, [x0, y0, x1, y1], K, f) => {
      const cv = document.createElement('canvas');
      cv.width = Math.round((x1 - x0) * K); cv.height = Math.round((y1 - y0) * K);
      const c = cv.getContext('2d');
      c.setTransform(K, 0, 0, K, -x0 * K, -y0 * K);
      f(c);
      out[name] = { data: cv.toDataURL('image/png'), box: [x0, y0, x1, y1] };
    };
    const T = 0;
    // The home island, large stage, with its back terrace: lawn empty (stations are separate sprites).
    grab('isle-home', [-182, -106, 182, 182], 4, (c) => { islandBody(c, 0, 0, 172, 56, 150, true); terrace(c, T); });
    // Stations (world units, the prototype's 1.3 vignette scale included), feet at (0, 0).
    const st = (name, id, L) => grab(name, [-60, -112, 60, 20], 5, (c) => { c.scale(1.3, 1.3); softShadow(c, 0, 1, 32, 8, 0.18); DRAW[id](c, L, T); });
    st('st-garden-3', 'garden', 3); st('st-garden-4', 'garden', 4);
    st('st-cay-2', 'cay', 2); st('st-cay-3', 'cay', 3);
    st('st-pond-2', 'pond', 2); st('st-workshop-2', 'workshop', 2); st('st-windmill-2', 'windmill', 2);
    // The hedgehog resident (stand-in); Mochi is concept art and is copied as is.
    grab('res-hog', [-14, -22, 14, 4], 8, (c) => critter(c, 'hog', 0, 0, T, 1.35));
    // The other islands, as on the map.
    for (const id of ['harbor', 'stars', 'hamam', 'library']) {
      const isle = isleById[id], rx = isle.rx;
      S.arrived[id] = id === 'harbor' ? 9 : 0;
      grab('isle-' + id, [-rx - 22, -rx * 0.95, rx + 22, rx * 1.12], 3, (c) => isleContent(c, isle, T, 0, 0, id === 'harbor'));
    }
    // Clouds.
    grab('cloud-a', [-40, -26, 40, 18], 6, (c) => cloud(c, 0, 0, 18, 1));
    grab('cloud-b', [-60, -34, 60, 22], 5, (c) => { cloud(c, -14, 0, 22, 1); cloud(c, 22, 4, 16, 1); });
    // Pofu's faces: R1 with the prototype's code face overlays (stand-ins for the face-edit kit).
    for (const kind of ['breathe', 'proud', 'excited', 'pout', 'jealous', 'unwell', 'worried', 'smug', 'relieved']) {
      S.emotion = { kind, t0: -99999, until: 1e12 };
      breathPhase = 0;
      grab('pofu-' + kind, [-132, -250, 132, 14], 2, (c) => drawPofuAt(c, 0, 0, 240, 0, kind));
    }
    return out;
  });
  const meta = {};
  for (const [name, { data, box }] of Object.entries(shots)) {
    fs.writeFileSync(path.join(OUT, name + '.png'), Buffer.from(data.split(',')[1], 'base64'));
    meta[name] = box;
  }
  fs.writeFileSync(path.join(OUT, 'boxes.json'), JSON.stringify(meta, null, 1));
  console.log('rendered', Object.keys(shots).length, 'sprites to', OUT);
  await browser.close();
  srv.close();
})();
