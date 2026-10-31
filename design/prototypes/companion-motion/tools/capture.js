// Deterministic frame capture of the motion proof with Playwright.
//
//   node tools/capture.js stills OUT_DIR    labelled key poses (for the strip)
//   node tools/capture.js sequence OUT_DIR  a scripted 12 s performance at 20 fps
//
// Requires Playwright with Chromium. Uses SwiftShader (software WebGL), so
// it runs headless on any Linux box.
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const mode = process.argv[2] || 'stills';
const out = process.argv[3] || '/tmp/pofu-frames';
const size = Number(process.argv[4] || 420);

(async () => {
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: size, height: size }, deviceScaleFactor: 1 });
  page.on('console', (m) => console.log('console:', m.text()));
  page.on('pageerror', (e) => console.log('pageerror:', e.message));
  const url = 'file://' + path.resolve(__dirname, '..', 'index.html') + '?capture=1';
  await page.goto(url);
  await page.evaluate((s) => {
    const c = document.getElementById('stage');
    c.width = s; c.height = s; c.style.width = s + 'px'; c.style.height = s + 'px';
  }, size);
  await page.waitForFunction(() => window.pofu && window.pofu.ready);
  const err = await page.textContent('#error');
  if (err) console.log('page error:', err);
  // Read pixels straight from the canvas (preserveDrawingBuffer is on).
  const shot = async (name) => {
    const url = await page.evaluate(() => document.getElementById('stage').toDataURL('image/png'));
    fs.writeFileSync(path.join(out, name + '.png'), Buffer.from(url.split(',')[1], 'base64'));
  };
  const run = (fn, arg) => page.evaluate(fn, arg);

  if (mode === 'stills') {
    // Each still starts from the same settled idle state.
    const reset = async (o = {}) => {
      await page.reload();
      await page.evaluate((s) => {
        const c = document.getElementById('stage');
        c.width = s; c.height = s; c.style.width = s + 'px'; c.style.height = s + 'px';
      }, size);
      await page.waitForFunction(() => window.pofu && window.pofu.ready);
      await run((o) => { pofu.set(Object.assign({ nextBlink: 1e9, nextEarFlick: 1e9, nextGlance: 1e9 }, o)); pofu.advance(1.2); }, o);
    };
    await reset(); await shot('01-idle');
    await reset(); await run(() => { pofu.advance(0.7); }); await shot('02-inhale');
    await reset(); await run(() => { pofu.triggerBlink(); pofu.advance(0.09); }); await shot('03-blink');
    await reset(); await run(() => { pofu.tap(300, 330); pofu.advance(0.08); }); await shot('04-tap-squish');
    await reset({ energyTarget: 1 }); await run(() => { pofu.advance(1.5); }); await shot('05-energy-full');
    await reset({ energyTarget: 0, vitalityTarget: 0.45 }); await run(() => { pofu.motion.vitality.x = 0.45; pofu.advance(2); }); await shot('06-vitality-mid');
    await reset({ energyTarget: 0, vitalityTarget: 0.05 }); await run(() => { pofu.motion.vitality.x = 0.05; pofu.advance(2); }); await shot('07-vitality-low');
    await reset(); await run(() => { pofu.celebrate(); pofu.advance(0.1); }); await shot('08-hop-anticipate');
    await reset(); await run(() => { pofu.celebrate(); pofu.advance(0.3); }); await shot('09-hop-air');
    await reset(); await run(() => { pofu.celebrate(); pofu.advance(0.62); }); await shot('10-hop-land');
    await reset(); await run(() => { pofu.set({ pointer: [520, 120] }); pofu.advance(1.2); }); await shot('11-look-right');
    await reset({ energyTarget: 0.6 }); await run(() => { document.getElementById('fields').checked = true; pofu.advance(1); }); await shot('12-fields');
  } else {
    // A scripted performance: idle, blink, look around, tap, feed x3, celebrate, wilt, recover.
    const fps = 20, total = 13;
    const script = [
      [1.0, () => pofu.triggerBlink()],
      [1.8, () => pofu.set({ pointer: [560, 140] })],
      [3.0, () => pofu.set({ pointer: [-60, 200] })],
      [4.0, () => pofu.set({ pointer: null })],
      [4.4, () => pofu.tap(300, 340)],
      [5.4, () => pofu.feed()],
      [6.0, () => pofu.feed()],
      [6.6, () => pofu.feed()],
      [7.6, () => pofu.celebrate()],
      [9.6, () => pofu.set({ vitalityTarget: 0.05, energyTarget: 0.1 })],
      [11.8, () => pofu.set({ vitalityTarget: 0.85 })],
    ];
    await run(() => pofu.set({ nextBlink: 2.6, nextEarFlick: 3.2, follow: true }));
    let t = 0, i = 0, frame = 0;
    const evs = script.map(([at, fn]) => [at, fn.toString()]);
    while (t < total) {
      while (i < evs.length && evs[i][0] <= t) {
        await page.evaluate(`(${evs[i][1]})()`);
        i++;
      }
      await run((dt) => pofu.advance(dt, 120), 1 / fps);
      t += 1 / fps;
      await shot('f' + String(frame++).padStart(4, '0'));
    }
  }
  await browser.close();
})();
