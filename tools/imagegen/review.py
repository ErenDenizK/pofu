"""Contact sheets, the review file, and promotion of approved takes."""
from __future__ import annotations

import datetime as dt
import json
import shutil
from pathlib import Path

import numpy as np
import yaml
from PIL import Image, ImageDraw, ImageFont

import pipeline as pl

STATUS_COLORS = {"pass": (47, 143, 91), "warn": (217, 130, 43), "fail": (200, 56, 70), "none": (140, 130, 140)}
REVIEW_HEADER = """\
# Review for {batch}. Edited by people (or by Codex on the founder's word).
# For each job set `pick` to the take number to approve (1, 2, ...),
# `none` to reject every take (regenerate), or leave it null (undecided).
# Never approve a take whose QA is `fail` without writing why in `note`.
# Then run: python3 -I tools/imagegen/run.py promote --manifest {manifest}
"""


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    names = (["DejaVuSans-Bold.ttf", "Arial Bold.ttf", "Helvetica.ttc"] if bold else ["DejaVuSans.ttf", "Arial.ttf", "Helvetica.ttc"])
    dirs = ["/usr/share/fonts/truetype/dejavu", "/System/Library/Fonts/Supplemental", "/System/Library/Fonts", "/Library/Fonts"]
    for d in dirs:
        for n in names:
            p = Path(d) / n
            if p.exists():
                try:
                    return ImageFont.truetype(str(p), size)
                except OSError:
                    continue
    return ImageFont.load_default(size=size)


def checker(w: int, h: int, cell: int = 16) -> Image.Image:
    yy, xx = np.mgrid[0:h, 0:w]
    c = ((yy // cell + xx // cell) % 2).astype(np.uint8)
    arr = np.where(c[..., None] == 0, np.array([238, 236, 240]), np.array([226, 223, 230])).astype(np.uint8)
    return Image.fromarray(arr, "RGB").convert("RGBA")


def tile(img: Image.Image | None, size: int) -> Image.Image:
    t = checker(size, size)
    if img is None:
        return t
    im = img.convert("RGBA").copy()
    im.thumbnail((size - 12, size - 12), Image.Resampling.LANCZOS)
    t.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    return t


def icon_strip(img: Image.Image, height: int) -> Image.Image:
    """The icon at 24, 30 and 60 pt (@3x shown at @1x) on light and dark glass."""
    from qa import GLASS, ICON_POINTS
    w = 2 * sum(p + 10 for p in ICON_POINTS) + 10
    strip = Image.new("RGBA", (w, height), (255, 255, 255, 255))
    x = 6
    for glass in ("light", "dark"):
        for p in ICON_POINTS:
            bg = Image.new("RGBA", (p + 8, p + 8), GLASS[glass] + (255,))
            ic = img.convert("RGBA").resize((p * 3, p * 3), Image.Resampling.LANCZOS).resize((p, p), Image.Resampling.LANCZOS)
            bg.alpha_composite(ic, (4, 4))
            strip.alpha_composite(bg, (x, (height - bg.height) // 2))
            x += p + 10
    return strip


def contact_sheet(rows: list[dict], title: str, out: Path, tile_px: int = 300) -> Path:
    """rows: [{job, kind, parent: Image|None, takes: [{n, image, status, lines}]}]"""
    max_takes = max([len(r["takes"]) for r in rows] + [1])
    label_w = 300
    cols = 1 + max_takes  # parent column + takes
    row_h = tile_px + 118
    W = label_w + cols * (tile_px + 12) + 12
    H = 90 + len(rows) * (row_h + 14) + 20
    sheet = Image.new("RGBA", (W, H), (255, 250, 245, 255))
    d = ImageDraw.Draw(sheet)
    d.text((20, 20), title, font=font(30, True), fill=(42, 33, 48))
    d.text((20, 58), f"{dt.datetime.now():%Y-%m-%d %H:%M} · locked takes on a checkerboard · parent level at left",
           font=font(16), fill=(102, 89, 98))
    y = 90
    f_small, f_mid, f_bold = font(14), font(16), font(20, True)
    for r in rows:
        d.rounded_rectangle((10, y, W - 10, y + row_h), radius=18, fill=(255, 255, 255), outline=(230, 222, 228))
        d.text((24, y + 16), r["job"], font=f_bold, fill=(42, 33, 48))
        d.text((24, y + 44), r["kind"], font=f_mid, fill=(102, 89, 98))
        for i, line in enumerate(r.get("notes", [])[:6]):
            d.text((24, y + 74 + i * 20), line[:34], font=f_small, fill=(102, 89, 98))
        x = label_w
        sheet.alpha_composite(tile(r.get("parent"), tile_px), (x, y + 12))
        d.text((x + 8, y + tile_px + 18), "parent" if r.get("parent") is not None else "no parent", font=f_small, fill=(102, 89, 98))
        x += tile_px + 12
        for t in r["takes"]:
            sheet.alpha_composite(tile(t["image"], tile_px), (x, y + 12))
            color = STATUS_COLORS.get(t["status"], STATUS_COLORS["none"])
            d.rounded_rectangle((x + 8, y + 20, x + 92, y + 48), radius=14, fill=color)
            d.text((x + 18, y + 24), f"t{t['n']} {t['status']}", font=font(16, True), fill=(255, 255, 255))
            for i, line in enumerate(t.get("lines", [])[:4]):
                d.text((x + 6, y + tile_px + 18 + i * 19), line[:44], font=f_small, fill=(70, 60, 70))
            if t.get("icon_strip") is not None:
                strip = t["icon_strip"]
                sheet.alpha_composite(strip, (x + tile_px - strip.width - 4, y + tile_px - strip.height + 8))
            x += tile_px + 12
        y += row_h + 14
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(out, optimize=True)
    return out


def small_copy(sheet: Path, out: Path, max_w: int = 1800) -> Path:
    """A committable copy (JPEG, about 0.5-1.5 MB) for the PR."""
    with Image.open(sheet) as im:
        im = im.convert("RGB")
        if im.width > max_w:
            im = im.resize((max_w, round(im.height * max_w / im.width)), Image.Resampling.LANCZOS)
        out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out, "JPEG", quality=82, optimize=True, progressive=True)
    return out


# ---------------------------------------------------------------------------
# The review file
# ---------------------------------------------------------------------------

def load_review(path: Path) -> dict:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text(encoding="utf-8")) or {}


def update_review(path: Path, batch: str, manifest_rel: str, takes_by_job: dict[str, list[dict]], sheet_rel: str) -> dict:
    """Merge fresh QA results into the review file without touching decisions."""
    data = load_review(path)
    jobs = data.get("jobs") or {}
    for job_id, takes in takes_by_job.items():
        entry = jobs.get(job_id) or {"pick": None, "note": ""}
        entry["takes"] = {f"t{t['n']}": {"qa": t["status"], "summary": t.get("summary", "")} for t in takes}
        entry.setdefault("pick", None)
        entry.setdefault("note", "")
        jobs[job_id] = {"pick": entry["pick"], "note": entry["note"], "takes": entry["takes"],
                        **({"approved": entry["approved"]} if entry.get("approved") else {})}
    data = {"batch": batch, "contact_sheet": sheet_rel, "jobs": jobs}
    save_review(path, data, manifest_rel)
    return data


def save_review(path: Path, data: dict, manifest_rel: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(REVIEW_HEADER.format(batch=data["batch"], manifest=manifest_rel)
                    + yaml.safe_dump(data, sort_keys=False, allow_unicode=True, width=100), encoding="utf-8")


def decisions(review: dict) -> dict[str, int | str | None]:
    out = {}
    for job_id, entry in (review.get("jobs") or {}).items():
        pick = (entry or {}).get("pick")
        if isinstance(pick, str) and pick.strip().lower().lstrip("t").isdigit():
            pick = int(pick.strip().lower().lstrip("t"))
        out[job_id] = pick
    return out


# ---------------------------------------------------------------------------
# Promotion
# ---------------------------------------------------------------------------

def provenance_md(job: pl.Job, meta: dict) -> str:
    refs = "\n".join(f"- `{a['path']}`: {a['role']}" for a in meta["attachments"]) or "- none"
    qa_lines = "\n".join(f"- {c['status']}: {c['check']} ({c['message']})" for c in meta["qa"]["checks"])
    return f"""# {job.asset}

- **Approved:** {meta['approved_at']} from batch `{meta['batch']}`, job `{job.id}`, take t{meta['take']}
  of {meta['takes_considered']} considered.
- **Generating account:** {meta.get('account', {}).get('owner') or 'UNKNOWN (do not ship)'}
  ({meta.get('account', {}).get('kind') or 'kind unknown'}).
- **Tool:** {meta['generation'].get('backend') or 'unknown'}{(', model ' + meta['generation']['model']) if meta['generation'].get('model') else ''};
  generated {meta['generation'].get('generated_at') or 'unknown'}.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, {('registration ' + json.dumps(meta['registration']) + ', ') if meta.get('registration') else ''}{('alignment to the parent level ' + json.dumps(meta['alignment']) + ', ') if meta.get('alignment') else ''}style lock preset `{meta['style_lock']['preset']}` (style_lock.json v{meta['style_lock']['version']}).
- **Files:** `{Path(meta.get('raw') or 'raw.webp').name}` is the take as generated ({meta.get('raw_encoding') or 'as generated'}), kept so the look can be re-locked; `{Path(meta['image']).name}` is the locked master the app and later edits use.
{('- **Soft delivery:** QA and the pick ran on the full ' + 'x'.join(map(str, meta['deliver']['original_size'])) + ' take; the master and raw are delivered at x' + str(meta['deliver']['scale']) + ' (' + 'x'.join(map(str, meta['deliver']['delivered_size'])) + ', Lanczos, lossless) to stay under the upload cap. Logical size = the original size.' + chr(10)) if meta.get('deliver') else ''}- **Review note:** {meta.get('note') or '(none)'}

## References

{refs}

## Prompt (fingerprint {meta['fingerprint']})

```text
{meta['prompt'].rstrip()}
```

## QA at approval

{qa_lines}
"""
