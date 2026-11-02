// End-to-end dictation run with the real worker and a real Whisper model, in headless Chromium.
//
//   bash design/hub/tools/vendor-dictation.sh          (once: builds dictation/vendor/)
//   node design/hub/tools/dictation-e2e.js --model DIR --audio SPEECH.wav [--enc NAME --dec NAME]
//
// DIR is a Transformers.js model folder (config.json, generation_config.json,
// preprocessor_config.json, tokenizer.json, tokenizer_config.json, onnx/<encoder>, onnx/<decoder>).
// The script stores it the way the hub's installer does (base64 chunks of 15 MB in a fake asset
// store served at /_blob/<id>, a manifest in the mock db), then:
//   1. records live from Chromium's fake microphone, which plays SPEECH.wav once, and stops after it;
//   2. picks SPEECH.wav through "Ses dosyası seç" and waits for the transcript.
// It prints both transcripts, the timings and every request the page made, and fails if the page
// asks for anything outside its own origin. Nothing here is part of CI: model files are large.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const http = require('http');
const crypto = require('crypto');
const { installMock, sampleSeed } = require('./check.js');

const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d; };
const MODEL = arg('model'), AUDIO = arg('audio');
const ENC = arg('enc', 'encoder_model_quantized.onnx'), DEC = arg('dec', 'decoder_model_merged_quantized.onnx');
if (!MODEL || !AUDIO) { console.error('usage: --model DIR --audio SPEECH.wav'); process.exit(2); }
const ROOT = path.resolve(__dirname, '..');
const SKELETON_HEAD = '<!doctype html><html><head><meta charset=utf8><meta name=viewport content="width=device-width,initial-scale=1,viewport-fit=cover"><style>body{margin:0}</style></head><body>';
const DTYPE = { '': 'fp32', _fp16: 'fp16', _q4: 'q4', _q4f16: 'q4f16', _quantized: 'q8', _int8: 'int8', _uint8: 'uint8', _bnb4: 'bnb4' };

function storeModel() {
  const blobs = new Map(); const files = [];
  const names = ['config.json', 'generation_config.json', 'preprocessor_config.json', 'tokenizer.json', 'tokenizer_config.json', 'onnx/' + ENC, 'onnx/' + DEC];
  for (const name of names) {
    const buf = fs.readFileSync(path.join(MODEL, name)); const enc = name.endsWith('.onnx') ? 'b64' : 'raw'; const chunks = [];
    for (let i = 0; i < buf.length; i += 15000000) {
      const part = buf.subarray(i, i + 15000000); const id = crypto.randomBytes(16).toString('hex');
      blobs.set(id, enc === 'b64' ? Buffer.from(part.toString('base64')) : part);
      chunks.push({ id, size: part.length, sha256: crypto.createHash('sha256').update(part).digest('hex') });
    }
    files.push({ name, size: buf.length, enc, chunks });
  }
  const dt = (n, part) => DTYPE[n.slice(part.length, -'.onnx'.length)] || 'fp32';
  const manifest = { preset: 'small', modelId: 'pofu/whisper-small', version: 1, dtype: { encoder_model: dt(ENC, 'encoder_model'), decoder_model_merged: dt(DEC, 'decoder_model_merged') }, files, totalBytes: files.reduce((s, f) => s + f.size, 0), installedAt: new Date().toISOString() };
  return { blobs, manifest };
}

async function main() {
  const { blobs, manifest } = storeModel();
  const page = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const requests = [];
  const srv = http.createServer((req, res) => {
    const u = decodeURIComponent(req.url.split('?')[0]); requests.push(u);
    if (u === '/' || u === '/index.html') { res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }); res.end(SKELETON_HEAD + page + '</body></html>'); return; }
    if (u.startsWith('/dictation/') && !u.includes('..') && fs.existsSync(path.join(ROOT, u))) { res.writeHead(200, { 'content-type': 'text/javascript' }); res.end(fs.readFileSync(path.join(ROOT, u))); return; }
    const m = u.match(/^\/_blob\/([0-9a-f]{32})$/);
    if (m && blobs.has(m[1])) { res.writeHead(200, { 'content-type': 'text/plain' }); res.end(blobs.get(m[1])); return; }
    res.writeHead(404); res.end();
  });
  await new Promise((r) => srv.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch({ args: ['--use-fake-device-for-media-stream', '--use-fake-ui-for-media-stream', '--use-file-for-fake-audio-capture=' + path.resolve(AUDIO) + '%noloop'] });
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, permissions: ['microphone'] });
  await ctx.route(/fonts\.(googleapis|gstatic)\.com/, (r) => r.fulfill({ status: 200, contentType: 'text/css', body: '' }));
  const p = await ctx.newPage();
  const outside = [];
  p.on('request', (r) => { const u = r.url(); if (!u.startsWith(base) && !/fonts\.(googleapis|gstatic)/.test(u)) outside.push(u); });
  p.on('console', (m) => { if (m.type() === 'error') console.log('[console error]', m.text().slice(0, 300)); });
  const seed = sampleSeed(); seed['dictation/small'] = manifest;
  await p.addInitScript(installMock, { seed, assets: true });
  await p.goto(base + '/'); await p.waitForTimeout(600);
  const q1 = p.locator('article[data-qid="q-shield-tone"]');
  const waitDone = async (label) => {
    const t0 = Date.now(); let last = '';
    for (;;) {
      await p.waitForTimeout(250);
      const t = await q1.locator('.dict-title').textContent().catch(() => '');
      const sub = await q1.locator('.dict .dict-msg, .dict .dict-sub').allTextContents().catch(() => []);
      const line = t + ' | ' + sub.join(' | ');
      if (line !== last) { console.log(`  [${label} ${((Date.now() - t0) / 1000).toFixed(1)} s] ${line.slice(0, 160)}`); last = line; }
      if (t === 'Hazır' || t === 'Metin çıkmadı' || /durdu|bozuk|açılamadı|okunamadı|yetmedi/.test(t)) return { title: t, secs: (Date.now() - t0) / 1000 };
      if (Date.now() - t0 > 15 * 60e3) return { title: 'timeout', secs: 900 };
    }
  };

  console.log('1. Live microphone (fake device plays the file once, from the first recording)');
  await q1.locator('.micbtn').click();
  const dur = Number(arg('seconds', '0')) || 0;
  const wavSecs = (() => { // walk the RIFF chunks: ffmpeg puts a LIST chunk before "data"
    const b = fs.readFileSync(AUDIO); const byteRate = b.readUInt32LE(28);
    for (let at = 12; at + 8 <= b.length; at += 8 + b.readUInt32LE(at + 4) + (b.readUInt32LE(at + 4) & 1)) {
      if (b.toString('ascii', at, at + 4) === 'data') return b.readUInt32LE(at + 4) / byteRate;
    }
    return 30;
  })();
  await p.waitForTimeout(Math.ceil((dur || wavSecs + 1.5) * 1000));
  await q1.locator('.dict .btn.stop').click();
  const r2 = await waitDone('live');
  const liveText = await q1.locator('textarea').inputValue();
  const kept = await p.evaluate(() => [...window.__mock.blobs.values()].map((b) => b.type + ' ' + b.size));
  console.log(`   ${r2.title} in ${r2.secs.toFixed(1)} s after Bitir\n   TEXT: ${liveText}\n   kept: ${kept.join(', ') || 'nothing'}`);

  console.log('2. File path');
  const [fc] = await Promise.all([p.waitForEvent('filechooser'), (async () => {
    await q1.locator('textarea').fill('');
    await q1.locator('.dict .btn', { hasText: 'Kapat' }).click().catch(() => {});
    // Take the file path the way a refused microphone would.
    await p.evaluate(() => { const D = window.__pofuDictation; D.dict.micDenied = true; });
    await q1.locator('.micbtn').click(); await p.waitForTimeout(200);
    await q1.locator('.dict .btn', { hasText: 'Ses dosyası seç' }).click();
  })()]);
  await fc.setFiles(path.resolve(AUDIO));
  const r1 = await waitDone('file');
  const fileText = await q1.locator('textarea').inputValue();
  console.log(`   ${r1.title} in ${r1.secs.toFixed(1)} s\n   TEXT: ${fileText}`);

  console.log('requests:', [...new Set(requests.filter((r) => !r.startsWith('/_blob/')))].join(' '));
  console.log(outside.length ? 'FAIL outside requests: ' + outside.join(' ') : 'PASS no request left the page origin');
  await browser.close(); srv.close();
  process.exit(outside.length || r1.title !== 'Hazır' || r2.title !== 'Hazır' ? 1 : 0);
}
main().catch((e) => { console.error(e); process.exit(1); });
