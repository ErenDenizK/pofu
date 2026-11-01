#!/usr/bin/env python3
"""Build the art-direction study page (docs/design/art-direction-study.md).

Takes the founder's art test 01 (island take 1, cay ocagi L1 and L2) and
R1, runs the four style-lock presets from tools/imagegen/style_lock.json
over them, composes the same scene for every treatment, and writes
`assets/*.webp`, `assets/metrics.json` and `index.html`.

    python3 -I design/prototypes/art-study/tools/build.py

Deterministic: same inputs and presets, same output. About three minutes.
"""
from __future__ import annotations

import html
import json
import os
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
PAGE = HERE.parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT / "tools" / "imagegen"))
import style_lock as sl  # noqa: E402

TEST = ROOT / "design" / "art" / "tests" / "2026-11-01"
SOURCES = {
    "island": TEST / "world__island-main-s_take1.png",
    "cay1": TEST / "station__cay-1_take1.png",
    "cay2": TEST / "station__cay-2_take1.png",
    "pofu": ROOT / "design" / "art" / "masters" / "pofu-hamster-base-v1" / "pofu-hamster-base.png",
}
OUT = PAGE / "assets"

# Treatment -> preset per asset. Pofu keeps R1 under the recommendation
# (char-guard is a no-op on R1); A, B and C are applied to everything so the
# study shows what each treatment would do to the hero too.
TREATMENTS = {
    "orig": {"label": "Orijinal", "presets": {}},
    "a": {"label": "A · Uyumla", "presets": {k: "harmonize" for k in SOURCES}},
    "b": {"label": "B · Guaj sadeleştirme", "presets": {k: "gouache" for k in SOURCES}},
    "c": {"label": "C · Masal kitabı düz", "presets": {k: "storybook" for k in SOURCES}},
    "d": {"label": "Yumuşak kilit", "presets": {"island": "soft-lock", "cay1": "soft-lock", "cay2": "soft-lock", "pofu": "char-guard"}},
}

SKY = [(0.0, "#BFE1F0"), (0.55, "#E6F2EE"), (1.0, "#FCEBDD")]


def hex_rgb(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def to_img(rgba: np.ndarray) -> Image.Image:
    return Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")


def crop_bbox(im: Image.Image) -> Image.Image:
    a = im.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    return im.crop(a.getbbox())


def sky(w: int, h: int) -> Image.Image:
    t = np.linspace(0, 1, h)[:, None]
    stops = [(p, hex_rgb(c)) for p, c in SKY]
    col = np.zeros((h, 3))
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        m = (t[:, 0] >= p0) & (t[:, 0] <= p1)
        u = ((t[m, 0] - p0) / (p1 - p0))[:, None]
        col[m] = c0 * (1 - u) + c1 * u
    arr = np.repeat(col[:, None, :], w, axis=1)
    return Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")


def contact_shadow(canvas: Image.Image, cx: float, cy: float, rx: float, ry: float, opacity: float = 0.22) -> None:
    """The app draws contact shadows (art bible section 9); the study does too."""
    layer = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(layer).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=int(255 * opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(ry * 0.6))
    shade = Image.new("RGBA", canvas.size, (92, 110, 64, 0))
    shade.putalpha(layer)
    canvas.alpha_composite(shade)


def place(canvas: Image.Image, im: Image.Image, width: float, cx: float, bottom: float) -> None:
    im = crop_bbox(im)
    h = im.height * width / im.width
    im = im.resize((int(round(width)), int(round(h))), Image.Resampling.LANCZOS)
    canvas.alpha_composite(im, (int(round(cx - im.width / 2)), int(round(bottom - im.height))))


def compose(layers: dict[str, Image.Image], w: int = 1080, h: int = 1250, widen: float = 1.0) -> Image.Image:
    """The study scene. `widen` is the island preview's horizontal stretch:
    the island keeps its vertical scale, so the lawn rows stay put."""
    c = sky(w, h)
    island = crop_bbox(layers["island"])
    iw = 900 * widen
    ih = island.height * 900 / island.width
    top = 430
    c.alpha_composite(island.resize((int(round(iw)), int(round(ih))), Image.Resampling.LANCZOS),
                      (int(round(w / 2 - iw / 2)), top))
    lawn_back = top + 150  # back row of the lawn (island 900 px wide)
    lawn_mid = top + 200   # where Pofu sits
    spread = 250 * (1 + (widen - 1) * 1.5)
    for key, cx in (("cay2", w / 2 - spread), ("cay1", w / 2 + spread + 5)):
        contact_shadow(c, cx, lawn_back + 2, 100, 18)
        place(c, layers[key], 240, cx, lawn_back + 6)
    contact_shadow(c, w / 2, lawn_mid + 2, 120, 20, 0.28)
    place(c, layers["pofu"], 300, w / 2, lawn_mid + 8)
    return c.convert("RGB")


def island_target_preview(rgba: np.ndarray) -> np.ndarray:
    """A deformation mock of the corrected island: wider, shallower earth.

    Not art: it only shows the founder the proportions the corrected prompt
    asks for (earth body about 40 % of the width instead of 70 %).
    """
    im = crop_bbox(to_img(rgba))
    w, h = im.size
    arr = np.asarray(im)
    green = (arr[..., 1].astype(int) - arr[..., 0].astype(int) > 12) & (arr[..., 3] > 128)
    rows = np.where(green[:, int(w * 0.3):int(w * 0.7)].any(axis=1))[0]
    rim = int(rows.max()) + 1 if len(rows) else int(h * 0.45)
    top = im.crop((0, 0, w, rim))
    body = im.crop((0, rim, w, h))
    body = body.resize((w, max(1, int(body.height * 0.55))), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (w, rim + body.height), (0, 0, 0, 0))
    out.alpha_composite(body, (0, rim - 2))
    out.alpha_composite(top, (0, 0))
    return np.asarray(out, dtype=np.float64) / 255.0


def thumb(im: Image.Image, box: int, bg: str = "#E9F1F2") -> Image.Image:
    im = crop_bbox(im)
    s = box / max(im.size)
    im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.Resampling.LANCZOS)
    pad = int(box * 0.06)
    canvas = Image.new("RGBA", (box + 2 * pad, box + 2 * pad), bg)
    canvas.alpha_composite(im, ((canvas.width - im.width) // 2, (canvas.height - im.height) // 2))
    return canvas.convert("RGB")


def crop_detail(rgba: np.ndarray, frac_box: tuple[float, float, float, float], size: int = 420) -> Image.Image:
    im = to_img(rgba)
    w, h = im.size
    x0, y0, x1, y1 = frac_box
    c = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
    c = c.resize((size, int(size * c.height / c.width)), Image.Resampling.LANCZOS)
    bg = Image.new("RGBA", c.size, "#E9F1F2")
    bg.alpha_composite(c)
    return bg.convert("RGB")


def save_webp(im: Image.Image, name: str, q: int = 82) -> str:
    path = OUT / f"{name}.webp"
    im.save(path, "WEBP", quality=q, method=6)
    return path.name


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    presets = sl.load_presets()
    src = {k: sl.load_rgba(p) for k, p in SOURCES.items()}
    results: dict[str, dict[str, np.ndarray]] = {}
    metrics: dict[str, dict[str, dict]] = {}
    for t, spec in TREATMENTS.items():
        results[t] = {}
        metrics[t] = {}
        for k, arr in src.items():
            preset = spec["presets"].get(k)
            cache = Path(os.environ["ART_STUDY_CACHE"]) / f"{t}-{k}.npy" if os.environ.get("ART_STUDY_CACHE") else None
            if cache and cache.exists():
                out = np.load(cache)
            else:
                out = sl.apply_lock(arr, presets[preset]) if preset else arr
                if cache:
                    cache.parent.mkdir(parents=True, exist_ok=True)
                    np.save(cache, out)
            results[t][k] = out
            metrics[t][k] = sl.measure(out)
            print(t, k, preset, metrics[t][k], flush=True)

    files: dict[str, str] = {}
    for t in TREATMENTS:
        layers = {k: to_img(v) for k, v in results[t].items()}
        files[f"scene-{t}"] = save_webp(compose(layers), f"scene-{t}", 84)
        for k in SOURCES:
            files[f"{k}-{t}"] = save_webp(thumb(layers[k], 340), f"{k}-{t}", 84)
    # Target proportions (a mock on top of the recommendation).
    target = dict(results["d"])
    target["island"] = island_target_preview(results["d"]["island"])
    files["scene-target"] = save_webp(compose({k: to_img(v) for k, v in target.items()}, widen=1.12), "scene-target", 84)
    # Detail crops: the copper teapot and the lawn edge, before and after.
    for t in ("orig", "a", "b", "c", "d"):
        files[f"zoom-copper-{t}"] = save_webp(crop_detail(results[t]["cay1"], (0.2, 0.15, 0.6, 0.5)), f"zoom-copper-{t}", 86)
        files[f"zoom-lawn-{t}"] = save_webp(crop_detail(results[t]["island"], (0.05, 0.15, 0.4, 0.55)), f"zoom-lawn-{t}", 86)
    (OUT / "metrics.json").write_text(json.dumps(metrics, indent=1) + "\n", encoding="utf-8")

    fonts = OUT / "fonts"
    fonts.mkdir(exist_ok=True)
    for f in ("nunito-latin-wght-normal.woff2", "nunito-latin-ext-wght-normal.woff2", "OFL.txt"):
        shutil.copy(ROOT / "design" / "prototypes" / "ux" / "assets" / "fonts" / f, fonts / f)

    (PAGE / "index.html").write_text(render_html(metrics), encoding="utf-8")
    total = sum(p.stat().st_size for p in PAGE.rglob("*") if p.is_file() and "tools" not in p.parts)
    print(f"page weight {total / 1e6:.2f} MB")
    return 0


# ---------------------------------------------------------------------------
# HTML (Turkish captions for the founder)
# ---------------------------------------------------------------------------

ASSET_LABEL = {"island": "Ada (take 1)", "cay1": "Çay ocağı L1", "cay2": "Çay ocağı L2", "pofu": "Pofu (R1)"}
VERDICT = {
    "orig": "Ada ve Pofu yumuşak; ocak ise koyu, çok doygun ve parlak bakır: “mobil oyun render’ı”. Göz önce ocağa gidiyor, Pofu’ya değil.",
    "a": "Renk ve ışık birleşti, ama doku aynı kaldı: dövme bakır, ahşap damarı ve parlamalar hâlâ “AI” diye bağırıyor. Pofu değişmiyor (iyi).",
    "b": "Detay gitti ama yerine “filtre” izi geldi: lekeli bantlar, çamurlu geçişler. Pofu’nun tüyü keçe gibi oldu; büyüsü kayboldu.",
    "c": "En tutarlı dünya, ama başka bir oyun: Pofu’nun göz parıltısı ve tüyü gidiyor, ocak oyuncak çıkartmaya dönüyor. Bu stil filtreyle değil, baştan çizimle olur.",
    "d": "Pofu aynen kalıyor; ocak ve ada onun ışığına, değerlerine ve doygunluğuna çekiliyor. Mikro doku yarıya iniyor, şekil ve malzeme okunuyor. Dünya tek elden çıkmış gibi.",
}


def fmt_row(t: str, k: str, m: dict) -> str:
    v = m[t][k]
    return (f"<td>{v['L_p5']:.0f}</td><td>{v['L_p50']:.0f}</td><td>{v['C_p50']:.0f}</td>"
            f"<td>{v['C_p95']:.0f}</td><td>{v['detail']:.1f}</td>")


def render_html(m: dict) -> str:
    e = html.escape
    tabs = "".join(
        f'<a class="chip" href="#s-{t}">{e(spec["label"])}</a>' for t, spec in TREATMENTS.items())
    scenes = []
    for t, spec in TREATMENTS.items():
        rec = ' rec' if t == "d" else ''
        scenes.append(f'''
<section class="card{rec}" id="s-{t}">
  <h2>{e(spec["label"])}{' <span class="badge">öneri</span>' if t == "d" else ''}</h2>
  <img class="scene" src="assets/scene-{t}.webp" width="1080" height="1250" alt="{e(spec['label'])}: ada, çay ocağı L1 ve L2, Pofu" loading="lazy">
  <p>{e(VERDICT[t])}</p>
  <div class="thumbs">{''.join(f'<figure><img src="assets/{k}-{t}.webp" width="380" height="380" alt="{e(ASSET_LABEL[k])}" loading="lazy"><figcaption>{e(ASSET_LABEL[k])}</figcaption></figure>' for k in SOURCES)}</div>
</section>''')
    def zoom(kind: str, what: str) -> str:
        fig = lambda t: (f'<figure><img src="assets/zoom-{kind}-{t}.webp" alt="{what} yakın: {e(TREATMENTS[t]["label"])}" '
                         f'loading="lazy"><figcaption>{e(SHORT[t])}</figcaption></figure>')
        return (f'<div class="zoom2">{fig("orig")}{fig("d")}</div>'
                f'<div class="zoom3">{fig("a")}{fig("b")}{fig("c")}</div>')

    def table(k: str) -> str:
        rows = [f'<tr class="ref"><th>Pofu (hedef)</th>{fmt_row("orig", "pofu", m)}</tr>']
        for t in TREATMENTS:
            rows.append(f'<tr{" class=hl" if t == "d" else ""}><th>{e(SHORT[t])}</th>{fmt_row(t, k, m)}</tr>')
        return (f'<h3>{e(ASSET_LABEL[k])}</h3><table><thead><tr><th></th><th>Koyu uç</th><th>Orta ton</th>'
                f'<th>Doy.</th><th>Doy. üst</th><th>Detay</th></tr></thead><tbody>{"".join(rows)}</tbody></table>')

    return PAGE_TEMPLATE.format(tabs=tabs, scenes="".join(scenes), zoom=zoom("copper", "Bakır demlik"),
                                lawn=zoom("lawn", "Çim kenarı"), table=table("cay1") + table("island"))


SHORT = {"orig": "Orijinal", "a": "A · Uyumla", "b": "B · Guaj", "c": "C · Düz", "d": "Öneri"}


PAGE_TEMPLATE = """<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Pofu · Sanat yönü çalışması</title>
<style>
@font-face {{ font-family: "Nunito"; font-weight: 200 1000; font-display: swap;
  src: url("assets/fonts/nunito-latin-wght-normal.woff2") format("woff2");
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD; }}
@font-face {{ font-family: "Nunito"; font-weight: 200 1000; font-display: swap;
  src: url("assets/fonts/nunito-latin-ext-wght-normal.woff2") format("woff2");
  unicode-range: U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF; }}
:root {{
  --cream: #FFF8F2; --peach: #FDEDE5; --ink: #2A2130; --ink-2: #4E424B; --ink-3: #665962;
  --violet: #6C4FD8; --violet-soft: #EEE9FF; --hair: rgba(42,33,48,.10);
  --font: "Nunito", ui-rounded, "SF Pro Rounded", system-ui, sans-serif;
}}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html {{ -webkit-text-size-adjust: 100%; scroll-behavior: smooth; }}
body {{ font-family: var(--font); color: var(--ink); background: var(--cream); line-height: 1.5;
  padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);
  overflow-x: hidden; -webkit-font-smoothing: antialiased; }}
main {{ max-width: 760px; margin: 0 auto; padding: 20px 16px 64px; }}
header h1 {{ font-size: 28px; line-height: 1.15; font-weight: 850; letter-spacing: -.01em; }}
header p {{ color: var(--ink-2); margin-top: 8px; font-size: 16px; }}
.chips {{ position: sticky; top: 0; z-index: 2; display: flex; gap: 8px; overflow-x: auto; padding: 12px 0;
  margin: 12px -16px 0; padding-left: 16px; padding-right: 16px; background: rgba(255,248,242,.92);
  -webkit-backdrop-filter: blur(10px); backdrop-filter: blur(10px); scrollbar-width: none; }}
.chips::-webkit-scrollbar {{ display: none; }}
.chip {{ flex: none; text-decoration: none; color: var(--ink); background: #fff; border: 1px solid var(--hair);
  border-radius: 999px; padding: 8px 14px; font-weight: 750; font-size: 14px; white-space: nowrap; }}
.card {{ background: #fff; border-radius: 24px; padding: 16px; margin-top: 16px; border: 1px solid var(--hair); }}
.card.rec {{ border: 2px solid var(--violet); }}
.card h2 {{ font-size: 20px; font-weight: 850; margin-bottom: 10px; }}
.card p {{ color: var(--ink-2); margin-top: 12px; font-size: 16px; }}
.badge {{ font-size: 12px; vertical-align: middle; background: var(--violet); color: #fff; border-radius: 999px; padding: 3px 9px; margin-left: 6px; }}
img {{ display: block; max-width: 100%; height: auto; }}
.scene {{ width: 100%; border-radius: 16px; }}
.thumbs {{ display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px; margin-top: 12px; }}
@media (max-width: 480px) {{ .thumbs {{ grid-template-columns: repeat(2, minmax(0, 1fr)); }} }}
figure {{ margin: 0; }}
figure img {{ border-radius: 12px; width: 100%; }}
figcaption {{ font-size: 12px; color: var(--ink-3); margin-top: 4px; text-align: center; }}
.zoom2 {{ display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; margin-top: 10px; }}
.zoom3 {{ display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; margin-top: 8px; }}
h3 {{ font-size: 17px; font-weight: 800; margin-top: 16px; }}
table {{ border-collapse: collapse; font-size: 13px; width: 100%; margin-top: 6px; font-variant-numeric: tabular-nums; table-layout: fixed; }}
th, td {{ padding: 6px 4px; border-bottom: 1px solid var(--hair); text-align: right; }}
th:first-child {{ text-align: left; width: 30%; }}
thead th {{ color: var(--ink-3); font-weight: 750; font-size: 11px; line-height: 1.2; vertical-align: bottom; hyphens: auto; }}
.summary {{ background: var(--violet-soft); border: 0; }}
.summary ol {{ margin: 6px 0 0 20px; color: var(--ink); }}
.summary li {{ margin-top: 6px; }}
.summary a {{ color: var(--violet); font-weight: 800; }}
tr.ref th, tr.ref td {{ background: var(--peach); font-weight: 800; }}
tr.hl th, tr.hl td {{ background: var(--violet-soft); font-weight: 800; }}
ul {{ margin: 10px 0 0 20px; color: var(--ink-2); }}
li {{ margin-top: 6px; }}
.note {{ font-size: 13px; color: var(--ink-3); margin-top: 10px; }}
</style>
</head>
<body>
<main>
<header>
  <h1>Pofu’nun dünyası “AI” gibi durmasın</h1>
  <p>Aynı sahne, orijinal ve dört farklı işlem: senin seçtiğin yumuşak ada (take 1), çay ocağı L1 ve L2, ve Pofu. Hepsi aynı kaynak görsellerden; sadece “stil kilidi” adımı değişiyor. Yeni görsel üretilmedi.</p>
</header>
<section class="card summary">
  <h2>Kısa cevap</h2>
  <ol>
    <li><b>Yumuşak kilit</b> (<a href="#s-d">Öneri</a>): Pofu’ya dokunma; ada ve ocakları onun açıklığına, doygunluğuna ve ışığına çek, ince dokuyu yarıya indir.</li>
    <li><b>Asıl düzeltme kaynakta:</b> yeni prompt blokları mat, sade ve alçak kameralı çizim istiyor. Kilit sadece son rötuş.</li>
    <li><b>Daha düz stile filtreyle geçilmez</b> (B ve C): “filtre” gibi görünüyor ve Pofu’nun büyüsünü öldürüyor.</li>
  </ol>
</section>
<nav class="chips">{tabs}<a class="chip" href="#s-zoom">Yakın plan</a><a class="chip" href="#s-numbers">Ölçümler</a><a class="chip" href="#s-target">Hedef ada</a></nav>
{scenes}
<section class="card" id="s-zoom">
  <h2>Yakın plan: “AI izi” nerede?</h2>
  <p>Dövme bakır, her kıvrımda parlayan noktalar, her yüzeyde aynı yoğunlukta doku: insan ressam bunları bu boyutta çizmez, model hep çizer. 130 pt’lik bir ocakta bu doku telefonda kıpır kıpır gürültüye dönüşür.</p>
  <h3>Bakır demlik</h3>
  {zoom}
  <h3>Çim kenarı</h3>
  {lawn}
</section>
<section class="card" id="s-numbers">
  <h2>Ölçümler: hedef Pofu</h2>
  <p>Açıklık 0 (siyah) ile 100 (beyaz) arası. Doy. = doygunluk (renk yoğunluğu); kilitli paletimizin en doygun rengi 49. “Detay”, nesne telefondaki boyutuna küçültülünce kalan ince doku.</p>
  {table}
  <p class="note">Ocak orijinalde Pofu’dan çok daha koyu (koyu uç 27’ye karşı 59) ve neredeyse iki kat doygun. Öneri onu palet aralığına çekiyor ve ince dokuyu Pofu’nun seviyesine indiriyor; şekil ve malzeme ayrımı kalıyor.</p>
</section>
<section class="card" id="s-target">
  <h2>Hedef ada oranı (önizleme)</h2>
  <img class="scene" src="assets/scene-target.webp" width="1080" height="1250" alt="Daha geniş çimli, daha sığ toprak gövdeli ada önizlemesi" loading="lazy">
  <p>Bu bir çizim değil, sadece oran taslağı: çim daha geniş, toprak gövde yarı yarıya sığ. Gerçek düzeltme yeni prompt ile gelecek (ada ve ocaklar için kamera da aynı açıya iniyor).</p>
</section>
<section class="card">
  <h2>Sırada ne var</h2>
  <ul>
    <li><b>Yeni promptlar hazır:</b> ada (daha geniş, daha sığ, adaçayı yeşili), çay ocağı L1–L5, ayçiçeği bahçesi L1–L2, simit arabası, Mochi ve 12 arayüz görseli. Hepsi bu sayfadaki yumuşak kilide göre yazıldı.</li>
    <li><b>Üretim henüz başlamadı:</b> önce senin hesap kararın (kendi ChatGPT planın Codex ile ya da kendi API anahtarın) ve 7 günlük deneme bitecek. Üretim yalnızca senin kendi hesabında yapılır; her görselin kaydında hesap sahibi yazar.</li>
    <li><b>Sen seçersin:</b> her parti için tek bir “temas sayfası” (contact sheet); beğendiğin denemenin numarasını söylemen yeterli.</li>
    <li><b>Tek ince ayar kuralı:</b> kilidin hiçbir ayarı, önce/sonra karşılaştırması olmadan değişmez.</li>
  </ul>
</section>
</main>
</body>
</html>
"""

if __name__ == "__main__":
    sys.exit(main())
