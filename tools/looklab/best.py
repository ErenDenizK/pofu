#!/usr/bin/env python3
"""Look lab: the winners of experiments 1 to 4 combined, per light state, beside the references.

The pipeline, in the order a runtime would run it (lab home scene, `home-lab.json`):

  1. raw art composite (sky gradient of the state, cloud sea, plate, sprites back to front)
  2. AO + contact shadows from the layered depth (relight.ao / relight.contact)  [bakeable]
  3. relight rig from normals: day/golden/rain ratio rig; night delit + sources   [rig: runtime]
  4. fitted grade: Reinhard per material (sky, sea, lawn, earth; sprites half way) toward the
     state's references, baked into one 17^3 LUT per layer group (grade.material_transfer,
     grade.lut_from_pairs). Sliced-OT LUTs on the whole island washed it out (look-lab.md) [LUT: baked]
  5. depth haze on the backdrop and far plane (atmos.haze), bloom on emissives at night

  python3 -I tools/looklab/best.py SHOTS_DIR OUT.jpg [--depth-model M.onnx] [--cells colour-script.json]

SHOTS_DIR: the feat/concept-match screenshots (`concept-<state>-home.jpg`), shown as "game now".
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import atmos as at  # noqa: E402
import depth as dp  # noqa: E402
import grade as gr  # noqa: E402
import lab  # noqa: E402
import lookdev as ld  # noqa: E402
import nightlab as nl  # noqa: E402
import relight as rl  # noqa: E402
import scene as sc_mod  # noqa: E402

STATES = ["day", "golden", "night", "rain"]
RAIN_SKY = ("#A59EBB", "#C9C3D8")  # concept-match's light-rain sky, lilac-grey


def pipeline(s, state: str, cells: dict, nrm, occl, model, lut_strength: float = 1.0) -> tuple[np.ndarray, dict]:
    hour = {"rain": "day"}.get(state, state)
    cell = cells[hour]
    info = {}
    if state == "night":
        sky = nl.night_sky(cell, (s.w, s.h), nl.PARAMS)
        lit, em = rl.relight_night(s, nrm, rl.NIGHT_RIG, occl, sky)
    else:
        z, hz = (RAIN_SKY if state == "rain" else (cell["sky"]["zenith"], cell["sky"]["horizon"]))
        sky = s.sky(ld.hex_rgb(z), ld.hex_rgb(hz))
        rig = {"day": rl.DAY_RIG, "golden": rl.GOLDEN_RIG, "rain": rl.RAIN_RIG}[state]
        sdir = (0.8, 0.6) if state == "golden" else (-0.6, 0.8)
        cont = rl.contact(s.depth, s.ids, sdir=sdir) * (0.3 if state == "rain" else 1.0)
        lit = rl.relight_day(s.raw(sky), nrm, rig, occl, cont, s.ids < 2)
        em = None
    info["relit"] = lit
    # Fitted grade: material-wise transfer toward the references (sky, sea, lawn, earth; sprites
    # half way), baked into one LUT per layer group (backdrop, plate, sprites), masks exact from ids.
    refs = [lab.load_rgb(p, 768) for p in lab.REF[state]]
    tgt_mats = [gr.ref_materials(r, dp.masks_from_depth(dp.monocular(r, model))) for r in refs]
    lawn = (s.ids == 2) & s.lawn
    src_mats = {"sky": s.ids == 0, "sea": s.ids == 1, "lawn": lawn, "earth": (s.ids == 2) & ~lawn, "sprites": s.ids >= 3}
    moved = gr.material_transfer(lit, src_mats, refs, tgt_mats)
    out = lit.copy()
    for group in (s.ids < 2, s.ids == 2, s.ids >= 3):
        lut = gr.lut_from_pairs(lit, moved, group)
        ident = np.stack(np.meshgrid(*[np.linspace(0, 1, lut.shape[0])] * 3, indexing="ij"), -1)
        lut = ident + lut_strength * (lut - ident)
        out[group] = gr.apply_lut(lit[group][:, None, :], lut)[:, 0, :]
    info["graded"] = out
    # Atmosphere: the backdrop and the cloud sea take haze, the island keeps its crispness.
    hz_col = np.asarray(lab.load_rgb(lab.REF[state][0], 256)[:20].reshape(-1, 3).mean(0))
    out = at.haze(out, s.depth, hz_col, keep=(s.ids == 0).astype(float))
    if em is not None:
        out = at.bloom(out, em)
    return np.clip(out, 0, 1), info


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("shots", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--depth-model")
    ap.add_argument("--cells", type=Path, default=ld.SCRIPT)
    ap.add_argument("--json", type=Path)
    ap.add_argument("--frames", type=Path, help="also save each best frame as <dir>/best-<state>.png")
    a = ap.parse_args(argv)
    model = dp.model_path(a.depth_model)
    if not model:
        raise SystemExit("best.py fits the grade with region masks from the monocular model: pass --depth-model")
    s = sc_mod.Scene()
    cells = ld.load_cells(a.cells)
    nrm = rl.plate_normals(s, rl.normals_by_id(s.depth, s.ids))
    occl = rl.ao(s.depth, s.ids, s.ground, cross_only=True)
    lookdev_frames, _ = ld.render_scene(s.spec, cells)
    by_hour = dict(zip(ld.HOURS, lookdev_frames))
    rows, labels, readout = [], [], {}
    for st in STATES:
        ref = lab.ref_stats(st)
        best, info = pipeline(s, st, cells, nrm, occl, model)
        if a.frames:
            a.frames.mkdir(parents=True, exist_ok=True)
            lab.to_img(best).save(a.frames / f"best-{st}.png")
        shot = lab.load_rgb(a.shots / f"concept-{st}-home.jpg")
        r = {"game_now": lab.compare(lab.stats(shot, "home"), ref),
             "relit": lab.compare(lab.stats(info["relit"], "lab"), ref),
             "best": lab.compare(lab.stats(best, "lab"), ref), "reference_bf": lab.ref_bf(ref)}
        row = [(lab.to_img(shot), "game now (Home)\n" + lab.fmt(r["game_now"]))]
        if st in by_hour:
            r["lab_game_light"] = lab.compare(lab.stats(by_hour[st], "lab"), ref)
            row.append((lab.to_img(by_hour[st]), "same scene, game light now\n" + lab.fmt(r["lab_game_light"])))
        else:
            row.append((lab.to_img(info["relit"]), "same scene, relit only (no rain grade in lookdev)\n" + lab.fmt(r["relit"])))
        row.append((lab.to_img(best), "best pipeline\n" + lab.fmt(r["best"])))
        row.append((lab.to_img(lab.load_rgb(lab.REF[st][0], 1200)), f"reference {lab.REF[st][0].parent.name}\nb/f {r['reference_bf']}"))
        rows.append(row)
        labels.append(st)
        readout[st] = r
        print(st, {k: lab.fmt(v) for k, v in r.items() if isinstance(v, dict)})
    lab.sheet(rows, a.out, "Best pipeline: AO + contact, light rig, per-material LUTs, haze, bloom (lab home scene)",
              cell_h=360, row_labels=labels)
    if a.json:
        a.json.write_text(json.dumps(readout, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
