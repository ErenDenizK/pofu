// Pofu Hub dictation worker: runs Whisper with Transformers.js (WebGPU when it works, WASM
// otherwise) off the main thread.
//
// The artifact sandbox only lets the page fetch its own origin, so nothing here talks to a CDN or to
// Hugging Face. Three things come from the artifact itself:
//   vendor/transformers.min.js   Transformers.js 3.8.1 (bundles ONNX Runtime Web), published next to this file
//   vendor/ort-wasm.js           ONNX Runtime's WebAssembly binary, gzip + base64 inside a JS module
//   /_blob/<id>           model files, stored once as artifact assets (base64 text chunks) by the
//                         installer in the page; a manifest in the db lists the chunk ids
// Model files are reassembled, checked against the SHA-256 of every chunk, and kept in this
// origin's Cache API, so each device downloads a model once.
//
// Messages in:  {id, type: 'load', manifest, device}   {id, type: 'transcribe', audio, language}
//               {id, type: 'evict', manifest}
// Messages out: {id, type: 'progress', ...}  {id, type: 'done', ...}  {id, type: 'error', message, code}

const ORIGIN = self.location.origin;
const MODEL_HOST = ORIGIN + '/_pofu_models/'; // never served; every file comes from the custom cache
const CACHE_NAME = 'pofu-dictation-v1';

let tf = null;          // the Transformers.js module
let current = null;     // {key, asr, device}

const post = (msg, transfer) => self.postMessage(msg, transfer || []);

async function loadLibrary() {
  if (tf) return tf;
  tf = await import('./vendor/transformers.min.js');
  const { default: wasmB64 } = await import('./vendor/ort-wasm.js');
  const gz = b64ToBytes(wasmB64);
  const wasm = await new Response(new Blob([gz]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();
  const onnx = tf.env.backends.onnx;
  onnx.wasm.wasmBinary = wasm;
  onnx.wasm.numThreads = 1; // no cross-origin isolation in the artifact frame, so no threads
  // An object without `mjs` makes ORT use the glue bundled in transformers.min.js, and its presence
  // keeps Transformers.js from pointing ORT at a CDN; `wasmBinary` means the URL is never fetched.
  onnx.wasm.wasmPaths = { wasm: ORIGIN + '/_pofu_ort/unused.wasm' };
  tf.env.allowLocalModels = false;
  tf.env.allowRemoteModels = true;
  tf.env.remoteHost = MODEL_HOST;
  tf.env.remotePathTemplate = '{model}/';
  tf.env.useBrowserCache = false;
  tf.env.useCustomCache = true;
  tf.env.customCache = { match: () => undefined, put: async () => {} };
  return tf;
}

function b64ToBytes(s) {
  if (typeof Uint8Array.fromBase64 === 'function') return Uint8Array.fromBase64(s);
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function sha256Hex(bytes) {
  const d = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return Array.from(d, (b) => b.toString(16).padStart(2, '0')).join('');
}

async function openCache() {
  try { return await caches.open(CACHE_NAME); } catch { return null; }
}

// One file of the manifest: {name, size, enc: 'b64'|'raw', chunks: [{id, sha256, size}]}
async function assemble(file, onBytes) {
  const out = new Uint8Array(file.size);
  let at = 0;
  for (const c of file.chunks) {
    let res;
    for (let attempt = 0; ; attempt++) {
      try {
        res = await fetch('/_blob/' + c.id, { credentials: 'same-origin' });
        if (res.ok) break;
        if (res.status === 404) throw Object.assign(new Error('missing chunk ' + c.id), { code: 'missing_chunk' });
      } catch (e) { if (e.code === 'missing_chunk' || attempt >= 2) throw e; }
      if (attempt >= 2) throw Object.assign(new Error('chunk ' + c.id + ' answered ' + (res && res.status)), { code: 'fetch_failed' });
      await new Promise((r) => setTimeout(r, 800 * (attempt + 1)));
    }
    const bytes = file.enc === 'raw' ? new Uint8Array(await res.arrayBuffer()) : b64ToBytes(await res.text());
    if (bytes.length !== c.size) throw Object.assign(new Error('chunk ' + c.id + ' has ' + bytes.length + ' bytes, expected ' + c.size), { code: 'corrupt' });
    if (c.sha256 && (await sha256Hex(bytes)) !== c.sha256) throw Object.assign(new Error('chunk ' + c.id + ' failed its checksum'), { code: 'corrupt' });
    out.set(bytes, at); at += bytes.length; onBytes(bytes.length);
  }
  if (at !== file.size) throw Object.assign(new Error(file.name + ' is incomplete'), { code: 'corrupt' });
  return out;
}

function makeCache(manifest, report) {
  const base = MODEL_HOST + manifest.modelId + '/';
  const byName = new Map(manifest.files.map((f) => [f.name, f]));
  const counted = new Set(); // Transformers.js asks for some files twice; count each once
  return {
    async match(key) {
      const url = typeof key === 'string' ? key : key && key.url;
      if (!url || !url.startsWith(base)) return undefined;
      const name = decodeURIComponent(url.slice(base.length));
      const file = byName.get(name);
      if (!file) return undefined; // optional file: Transformers.js then gets a same-origin 404
      const cache = await openCache();
      const cacheKey = base + name + '?v=' + (file.chunks[0] && file.chunks[0].sha256 || file.size);
      if (cache) {
        try {
          const hit = await cache.match(cacheKey);
          if (hit) { if (!counted.has(name)) { counted.add(name); report.cached(file.size); } return hit; }
        } catch { /* cache unreadable */ }
      }
      counted.add(name);
      const bytes = await assemble(file, (n) => report.bytes(n));
      const headers = { 'content-type': 'application/octet-stream', 'content-length': String(bytes.length) };
      if (cache) {
        try {
          await cache.put(cacheKey, new Response(bytes, { headers }));
          const hit = await cache.match(cacheKey);
          if (hit) return hit;
        } catch { /* quota or private mode: keep it in memory for this load */ }
      }
      return new Response(bytes, { headers });
    },
    async put() {},
  };
}

async function load(id, manifest, wantDevice) {
  const key = manifest.modelId + '|' + manifest.version + '|' + wantDevice;
  if (current && current.key === key) return { device: current.device, cached: true };
  if (current) { try { await current.asr.dispose(); } catch { /* ignore */ } current = null; }
  const t = await loadLibrary();
  const total = manifest.files.reduce((s, f) => s + f.size, 0);
  let fetched = 0, fromCache = 0, last = 0;
  const report = {
    bytes(n) {
      fetched += n;
      const now = Date.now();
      if (now - last > 120) { last = now; post({ id, type: 'progress', phase: 'download', loaded: fetched + fromCache, total }); }
    },
    cached(n) { fromCache += n; post({ id, type: 'progress', phase: 'download', loaded: fetched + fromCache, total, cached: true }); },
  };
  t.env.customCache = makeCache(manifest, report);
  const tryDevice = async (device) => {
    post({ id, type: 'progress', phase: 'init', device });
    return t.pipeline('automatic-speech-recognition', manifest.modelId, { device, dtype: manifest.dtype });
  };
  let asr, device = wantDevice;
  try {
    asr = await tryDevice(device);
  } catch (e) {
    if (device !== 'webgpu' || (e && (e.code === 'corrupt' || e.code === 'missing_chunk'))) throw e;
    device = 'wasm';
    asr = await tryDevice(device);
  }
  // Warm up once, so the first real segment does not pay for shader compilation.
  post({ id, type: 'progress', phase: 'warmup', device });
  await asr(new Float32Array(16000), { language: 'turkish', task: 'transcribe' });
  current = { key, asr, device };
  return { device, downloaded: fetched, fromCache };
}

// Whisper sometimes falls into a loop (one letter or a few words over and over until the token
// limit). Detect it and decode once more with repeated 4-grams banned.
const looped = (t) => /(\S)\1{5,}/u.test(t) || /(\S.{1,40}?)(?:\s*\1){4,}/u.test(t);

async function transcribe(audio, language) {
  if (!current) throw Object.assign(new Error('model not loaded'), { code: 'not_loaded' });
  const seconds = audio.length / 16000;
  // About 9 tokens a second is generous for fast Turkish speech; the cap also bounds a loop's cost.
  const opts = { task: 'transcribe', return_timestamps: false, max_new_tokens: Math.min(440, Math.ceil(seconds * 9) + 20) };
  if (language && language !== 'auto') opts.language = language;
  const t0 = performance.now();
  let text = ((await current.asr(audio, opts)) || {}).text || '';
  let retried = false;
  if (looped(text)) {
    retried = true;
    const again = ((await current.asr(audio, { ...opts, no_repeat_ngram_size: 4 })) || {}).text || '';
    if (!looped(again) || again.length < text.length) text = again;
  }
  return { text, retried, ms: Math.round(performance.now() - t0), device: current.device };
}

async function evict(manifest) {
  const cache = await openCache();
  if (!cache) return { evicted: 0 };
  let n = 0;
  for (const req of await cache.keys()) {
    if (!manifest || req.url.includes('/' + manifest.modelId + '/')) { await cache.delete(req); n++; }
  }
  if (current && (!manifest || current.key.startsWith(manifest.modelId + '|'))) { try { await current.asr.dispose(); } catch { /* ignore */ } current = null; }
  return { evicted: n };
}

// What this worker may do here: compile WebAssembly (the frame's CSP could forbid it), reach WebGPU,
// open the Cache API. The page stores the answer so the lead can read it from the db.
async function probe() {
  const r = {};
  try { new WebAssembly.Module(new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0])); r.wasm = true; } catch (e) { r.wasm = String((e && e.message) || e).slice(0, 160); }
  try { r.webgpu = !!(self.navigator && navigator.gpu && await navigator.gpu.requestAdapter()); } catch { r.webgpu = false; }
  try { await caches.open(CACHE_NAME); r.cache = true; } catch (e) { r.cache = String((e && e.message) || e).slice(0, 120); }
  return r;
}

self.onmessage = async (e) => {
  const { id, type } = e.data || {};
  try {
    let result;
    if (type === 'load') { result = await load(id, e.data.manifest, e.data.device); }
    else if (type === 'transcribe') result = await transcribe(e.data.audio, e.data.language);
    else if (type === 'evict') result = await evict(e.data.manifest);
    else if (type === 'probe') result = await probe();
    else throw new Error('unknown message ' + type);
    post({ id, type: 'done', ...result });
  } catch (err) {
    post({ id, type: 'error', message: String((err && err.message) || err), code: (err && err.code) || 'failed' });
  }
};
