"""Hybrid-pipeline proof: render Pofu as separate transparent layers.

Renders three RGBA layers of one state with correct mutual occlusion
(holdouts), which an app could animate independently in SwiftUI:

* body  - body, fur, ears, feet, nose, mouth (no tuft, no eyes)
* tuft  - the signature curl only (rotates on a spring about its root)
* eyes  - eye domes only (swap or scale for blinks)

It also writes the tuft root's pixel position, which is the pivot for the
tuft rotation in-app.

    python render_layers.py --state content --outdir renders/layers
"""

import argparse
import importlib.util
import json
import os
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("pofu", os.path.join(HERE, "pofu_hamster.py"))
pofu = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pofu)

LAYERS = {
    "body": lambda name: not (name.startswith("PofuTuft") or name.startswith("Eye.")),
    "tuft": lambda name: name.startswith("PofuTuft"),
    "eyes": lambda name: name.startswith("Eye."),
}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", default="content")
    ap.add_argument("--outdir", default="layers")
    ap.add_argument("--res", type=int, default=512)
    ap.add_argument("--samples", type=int, default=64)
    args = ap.parse_args(argv)
    os.makedirs(args.outdir, exist_ok=True)

    scene = pofu.reset_scene()
    pose = pofu.build(args.state)
    pofu.build_studio(scene, pose, 0, args.res, args.samples, preview=False)
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.objects["Backdrop"].hide_render = True

    character = [o for o in scene.objects if o.parent and o.parent.name == "PofuRoot"]
    for layer, wanted in LAYERS.items():
        for o in character:
            # Everything that is not in this layer still occludes it.
            o.is_holdout = not wanted(o.name)
        scene.render.filepath = os.path.abspath(os.path.join(args.outdir, f"{args.state}_{layer}.png"))
        bpy.ops.render.render(write_still=True)
        print(f"[layers] wrote {scene.render.filepath}")

    # Pivot for the tuft spring: where the curl leaves the head.
    body = pofu.Body(pose)
    base, _ = body.at(0, 82, 0.05)
    uv = world_to_camera_view(scene, scene.camera, Vector(base))
    pivot = {"x": uv.x * args.res, "y": (1 - uv.y) * args.res}
    with open(os.path.join(args.outdir, f"{args.state}_pivots.json"), "w") as f:
        json.dump({"tuft": pivot, "resolution": args.res}, f, indent=2)
    print("[layers] tuft pivot", pivot)


if __name__ == "__main__":
    main()
