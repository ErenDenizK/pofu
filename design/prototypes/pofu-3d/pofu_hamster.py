"""Procedural 3D Pofu (plush hamster) for the 3D feasibility spike.

Builds the whole scene from nothing (no .blend, no textures, no assets):
body, fur, tuft, eyes, nose, mouth, ears, feet, studio, camera, and renders
one still with Cycles.

Run with the official `bpy` wheel (recommended, includes OpenImageDenoise):

    python pofu_hamster.py --state content --out renders/content.png

or with a Blender binary:

    blender -b -P pofu_hamster.py -- --state content --out content.png

Design notes
------------
* One analytic surface, P(d): the body is a deformed ellipsoid evaluated for
  unit directions d. The body mesh, the feature placement, and every fur root
  use the same function, so features always sit exactly on the body.
* Fur is generated strand by strand in numpy and written into a native hair
  `Curves` object. That gives us direct control over the things the states
  need (lift, combing, clumping into matted locks, length, color per strand)
  without particle-edit mode, which does not work reliably headless.
* Every expressive trait is a number in `STATES`, mirroring `PofuPose` in the
  character bible, so the same parameters could drive a rig later.

Coordinates: Z up, Pofu faces -Y (towards the camera), ground at z = 0,
body radius about 1 unit.
"""

import argparse
import math
import os
import sys
import time

import bpy
import numpy as np
from mathutils import Matrix, Vector, kdtree

# ---------------------------------------------------------------------------
# State presets (the PofuPose parameter model, 3D flavour)
# ---------------------------------------------------------------------------

BASE_POSE = dict(
    vitality=1.0,     # 0 = drained gray, 1 = full color
    fluff=1.0,        # 0 = matted, flat locks; 1 = airy, upright fur
    squash=0.0,       # <0 squashed down, >0 stretched up (volume preserving)
    melt=0.0,         # extra bottom-heaviness (wilting slump)
    hop=0.0,          # vertical lift off the floor (units)
    eye_mode="open",  # open | happy | sad
    eye_open=1.0,     # lid coverage for sad/tired eyes (1 = no lid)
    lid_tilt=0.0,     # >0 droops the outer corners (sad)
    gaze_y=0.0,       # pupil / highlight vertical offset (-1..1)
    sparkle=1.0,      # highlight size
    mouth="smile",    # smile | open | frown
    blush=0.55,       # cheek intensity
    tuft_perk=1.0,    # -1 flat and droopy .. 1 springy upright curl
    sparkles=False,   # floating stars (celebrating)
    backdrop="#E2D3F7",
)

STATES = {
    "content": dict(),
    "celebrating": dict(
        fluff=1.0, squash=0.06, hop=0.17, eye_mode="happy", mouth="open",
        blush=1.0, tuft_perk=1.0, sparkles=True, backdrop="#F6DDE6",
    ),
    "wilting": dict(
        vitality=0.18, fluff=0.0, squash=-0.10, melt=0.10, eye_mode="sad",
        eye_open=0.6, lid_tilt=0.65, gaze_y=-0.35, sparkle=0.55,
        mouth="frown", blush=0.12, tuft_perk=-1.0, backdrop="#E3E1E8",
    ),
}

# Base palette (sRGB hex; converted to linear for shading)
PALETTE = dict(
    cream="#FFF7EC",
    peach="#F2A27C",
    blush="#FF7C9A",
    nose="#EE8399",
    paw="#FFB0BC",
    ear_inner="#FFA9BA",
    eye="#160F0C",
    mouth_line="#5A2A2A",
    mouth_cavity="#7A1E2E",
    tongue="#F27A8E",
)


def srgb_to_linear(hex_color):
    """'#RRGGBB' -> linear RGB numpy array."""
    h = hex_color.lstrip("#")
    c = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def lin(name):
    return srgb_to_linear(PALETTE[name])


def saturate(col, k):
    """Push colors away from their luminance. The Chiang hair model's
    multiple scattering washes pale colors out, so strand colors are
    pre-saturated to land on the intended on-screen color."""
    lum = (col @ np.array([0.2126, 0.7152, 0.0722]))[..., None]
    return np.clip(lum + (col - lum) * k, 0.0, 1.0)


def hair_color(col):
    """Strand color that renders as `col` through the Chiang hair model,
    which desaturates and shifts warm colors towards yellow."""
    return saturate(col, 1.6) * np.array([1.0, 0.84, 0.92])


# ---------------------------------------------------------------------------
# Small math helpers
# ---------------------------------------------------------------------------

def normalize(v):
    v = np.asarray(v, dtype=float)
    return v / np.linalg.norm(v, axis=-1, keepdims=True)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def face_dir(az_deg, el_deg):
    """Unit direction from azimuth (0 = front, + = Pofu's left / viewer's
    right) and elevation (degrees)."""
    az, el = math.radians(az_deg), math.radians(el_deg)
    return np.array([math.sin(az) * math.cos(el),
                     -math.cos(az) * math.cos(el),
                     math.sin(el)])


def tangent_frame(d):
    """Two tangents orthogonal to unit vectors d (N,3)."""
    a = np.where(np.abs(d[:, 2:3]) < 0.9, [[0, 0, 1.0]], [[1.0, 0, 0]])
    t1 = normalize(np.cross(d, a))
    t2 = np.cross(d, t1)
    return t1, t2


def frame_matrix(outward, up=(0, 0, 1)):
    """Rotation whose local -Y points along `outward` and local Z is as
    close to `up` as possible (used for eyes, ears, lids)."""
    y = -normalize(outward)
    z = np.asarray(up, float)
    z = normalize(z - np.dot(z, y) * y)
    x = np.cross(y, z)
    return Matrix([[x[0], y[0], z[0]], [x[1], y[1], z[1]], [x[2], y[2], z[2]]])


# ---------------------------------------------------------------------------
# The body: one analytic surface shared by mesh, features, and fur
# ---------------------------------------------------------------------------

class Body:
    RADII = np.array([1.02, 0.99, 1.0])
    FLOOR_Z = -0.82      # where the round bottom flattens into a sitting base
    FLOOR_SOFT = 0.10

    def __init__(self, pose):
        self.pose = pose
        self.cheeks = [face_dir(s * 58, -18) for s in (-1, 1)]
        self.blush = [face_dir(s * 43, -11) for s in (-1, 1)]
        # Height offset so the flattened bottom touches z = 0.
        bottom = self._raw(np.array([[0.0, 0.0, -1.0]]))[0]
        self.lift = -bottom[2]

    def _raw(self, d):
        """Surface point for unit directions d, body-centred, unsquashed."""
        r = 1.0 / np.sqrt(((d / self.RADII) ** 2).sum(axis=1))
        # Cheek pouches: soft angular bumps low on the face sides.
        for c in self.cheeks:
            r += 0.05 * np.exp(-(1.0 - d @ c) / 0.05)
        p = d * r[:, None]
        # Bottom-heavy: widen the lower half (more when melting).
        bh = 0.03 + self.pose["melt"]
        widen = 1.0 + bh * (0.5 - 0.5 * np.clip(p[:, 2] / self.RADII[2], -1, 1))
        p[:, :2] *= widen[:, None]
        # Flat sitting base: smooth max of z and the floor plane.
        k, zf = self.FLOOR_SOFT, self.FLOOR_Z
        p[:, 2] = zf + k * np.logaddexp(0.0, (p[:, 2] - zf) / k)
        return p

    def surface(self, d):
        """World-space point for unit directions d (squash + hop applied)."""
        p = self._raw(d)
        p[:, 2] += self.lift
        s = 1.0 + self.pose["squash"]
        p[:, 2] *= s
        p[:, :2] /= math.sqrt(s)
        p[:, 2] += self.pose["hop"]
        return p

    def surface_frame(self, d, eps=1e-3):
        """Points, outward normals, and relative area elements."""
        d = normalize(d)
        t1, t2 = tangent_frame(d)
        p = self.surface(d)
        du = self.surface(normalize(d + eps * t1)) - self.surface(normalize(d - eps * t1))
        dv = self.surface(normalize(d + eps * t2)) - self.surface(normalize(d - eps * t2))
        n = np.cross(du, dv)
        area = np.linalg.norm(n, axis=1)
        n = n / area[:, None]
        center = np.array([0, 0, self.center_z()])
        flip = ((p - center) * n).sum(axis=1) < 0
        n[flip] *= -1
        return p, n, area

    def center_z(self):
        return (self.lift) * (1.0 + self.pose["squash"]) + self.pose["hop"]

    def at(self, az, el, offset=0.0):
        """Point and normal for one face-space direction."""
        p, n, _ = self.surface_frame(face_dir(az, el)[None, :])
        return p[0] + n[0] * offset, n[0]


# ---------------------------------------------------------------------------
# Fur color field (shared by fur strands and the skin underneath)
# ---------------------------------------------------------------------------

def fur_color(d, pose, blush_centers):
    """Linear RGB for unit directions d: cream base, golden-peach cap with a
    white forehead blaze, airbrushed blush, vitality desaturation."""
    x, y, z = d[:, 0], d[:, 1], d[:, 2]
    # Soft, slightly irregular boundary (cheap deterministic "noise").
    wob = (0.06 * np.sin(7.0 * x + 1.3) * np.sin(5.0 * y + 0.4)
           + 0.04 * np.sin(11.0 * z + 2.0 * x))
    cap = smoothstep(0.16, 0.32, 0.85 * z + 0.45 * y + 0.15 * np.abs(x) + wob)
    blaze = np.exp(-(x / 0.11) ** 2) * smoothstep(0.1, -0.5, y)
    cap *= 1.0 - blaze
    col = (lin("cream")[None, :] * (1 - cap[:, None])
           + lin("peach")[None, :] * cap[:, None])
    # Blush: airbrushed onto the cheek fur.
    b = np.zeros(len(d))
    for c in blush_centers:
        b = np.maximum(b, np.exp(-(1.0 - d @ c) / 0.03))
    b *= pose["blush"]
    col = col * (1 - 0.85 * b[:, None]) + lin("blush")[None, :] * (0.85 * b[:, None])
    # Vitality: drain towards a cool, slightly darker gray.
    v = pose["vitality"]
    lum = (col @ np.array([0.2126, 0.7152, 0.0722]))[:, None]
    gray = lum * np.array([[0.80, 0.81, 0.86]])
    col = col * v + gray * (1 - v)
    return col


# ---------------------------------------------------------------------------
# Scene and materials
# ---------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    return scene


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def principled(name, color, roughness=0.5, sheen=0.0, sss=0.0, coat=0.0,
               spec=0.5):
    mat, nt, out = new_material(name)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Sheen Weight"].default_value = sheen
    bsdf.inputs["Sheen Roughness"].default_value = 0.4
    bsdf.inputs["Subsurface Weight"].default_value = sss
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Specular IOR Level"].default_value = spec
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    return mat


def fur_material(name, pose):
    """Hair shader driven by the per-strand `fur_color` attribute, darker at
    the roots and lighter at the tips like real plush pile."""
    mat, nt, out = new_material(name)
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "fur_color"
    info = nt.nodes.new("ShaderNodeHairInfo")
    ramp = nt.nodes.new("ShaderNodeMapRange")
    ramp.inputs["To Min"].default_value = 0.82
    ramp.inputs["To Max"].default_value = 1.06
    nt.links.new(info.outputs["Intercept"], ramp.inputs["Value"])
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    nt.links.new(attr.outputs["Color"], mul.inputs[6])
    nt.links.new(ramp.outputs[0], mul.inputs[7])

    hair = nt.nodes.new("ShaderNodeBsdfHairPrincipled")
    hair.model = "CHIANG"
    hair.parametrization = "COLOR"
    nt.links.new(mul.outputs[2], hair.inputs["Color"])
    # Matted fur is a bit glossier/clumpier, airy fur is soft.
    hair.inputs["Roughness"].default_value = 0.36 - 0.1 * (1 - pose["fluff"])
    hair.inputs["Radial Roughness"].default_value = 0.5
    hair.inputs["IOR"].default_value = 1.55
    if "Coat" in hair.inputs:
        hair.inputs["Coat"].default_value = 0.1
    nt.links.new(hair.outputs[0], out.inputs[0])
    return mat


def skin_material(name):
    """Body surface under the fur: same color field, so gaps never show."""
    mat, nt, out = new_material(name)
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "fur_color"
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Sheen Weight"].default_value = 0.6
    nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    return mat


def eye_material(name, pose):
    """Glossy glass-like eye with a warm lower gradient and two painted
    highlights (designer-toy style). Object space: unit sphere, local -Y is
    the outward axis."""
    mat, nt, out = new_material(name)
    N = nt.nodes
    L = nt.links
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["Object"], sep.inputs[0])

    def math_node(op, a=None, b=None, va=0.0, vb=0.0):
        m = N.new("ShaderNodeMath")
        m.operation = op
        if a is not None:
            L.new(a, m.inputs[0])
        else:
            m.inputs[0].default_value = va
        if b is not None:
            L.new(b, m.inputs[1])
        else:
            m.inputs[1].default_value = vb
        return m.outputs[0]

    def spot(cx, cz, radius, soft=0.03):
        """1 inside a disc around (cx, cz) on the front of the eye."""
        dx = math_node("SUBTRACT", sep.outputs["X"], vb=cx)
        dz = math_node("SUBTRACT", sep.outputs["Z"], vb=cz)
        d2 = math_node("ADD", math_node("MULTIPLY", dx, dx),
                       math_node("MULTIPLY", dz, dz))
        d = math_node("SQRT", d2)
        ss = N.new("ShaderNodeMapRange")
        ss.interpolation_type = "SMOOTHSTEP"
        L.new(d, ss.inputs["Value"])
        ss.inputs["From Min"].default_value = radius
        ss.inputs["From Max"].default_value = radius - soft
        front = math_node("LESS_THAN", sep.outputs["Y"], vb=-0.2)
        return math_node("MULTIPLY", ss.outputs[0], front)

    gy = 0.35 * pose["gaze_y"]
    s = pose["sparkle"]
    h1 = spot(-0.36, 0.38 + gy, 0.25 * s, 0.05)
    h2 = spot(0.30, -0.26 + gy, 0.10 * s, 0.03)
    hl = math_node("MAXIMUM", h1, h2)

    # Base: almost black, with a warm brown glow at the bottom of the dome.
    glow = N.new("ShaderNodeMapRange")
    glow.interpolation_type = "SMOOTHSTEP"
    L.new(sep.outputs["Z"], glow.inputs["Value"])
    glow.inputs["From Min"].default_value = -0.05 + gy
    glow.inputs["From Max"].default_value = -0.85 + gy
    mix = N.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    L.new(glow.outputs[0], mix.inputs["Factor"])
    mix.inputs[6].default_value = (*lin("eye"), 1)
    mix.inputs[7].default_value = (0.075, 0.032, 0.016, 1)
    bsdf = N.new("ShaderNodeBsdfPrincipled")
    L.new(mix.outputs[2], bsdf.inputs["Base Color"])
    # Low reflectance: a fully glassy dome mirrors the bright pastel studio
    # and turns the eye milky gray. Painted highlights carry the sparkle.
    bsdf.inputs["Roughness"].default_value = 0.12
    bsdf.inputs["Specular IOR Level"].default_value = 0.2
    bsdf.inputs["Coat Weight"].default_value = 0.25
    bsdf.inputs["Coat Roughness"].default_value = 0.03
    em = N.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (1, 1, 1, 1)
    em.inputs["Strength"].default_value = 1.6
    ms = N.new("ShaderNodeMixShader")
    L.new(hl, ms.inputs[0])
    L.new(bsdf.outputs[0], ms.inputs[1])
    L.new(em.outputs[0], ms.inputs[2])
    L.new(ms.outputs[0], out.inputs[0])
    return mat


def lid_material(name, pose, outer_sign, color):
    """Felt eyelid that covers the top of the eye. Visible where
    z > line(x); the line drops towards the outer corner for a sad droop."""
    mat, nt, out = new_material(name)
    N, L = nt.nodes, nt.links
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["Object"], sep.inputs[0])
    # line(x) = z0 - tilt * outer_sign * x
    z0 = 1.0 - 2.0 * pose["eye_open"]
    mx = N.new("ShaderNodeMath")
    mx.operation = "MULTIPLY_ADD"
    L.new(sep.outputs["X"], mx.inputs[0])
    mx.inputs[1].default_value = -pose["lid_tilt"] * outer_sign
    mx.inputs[2].default_value = z0
    gt = N.new("ShaderNodeMath")
    gt.operation = "GREATER_THAN"
    L.new(sep.outputs["Z"], gt.inputs[0])
    L.new(mx.outputs[0], gt.inputs[1])
    felt = N.new("ShaderNodeBsdfPrincipled")
    felt.inputs["Base Color"].default_value = (*color, 1)
    felt.inputs["Roughness"].default_value = 0.85
    felt.inputs["Sheen Weight"].default_value = 0.8
    tr = N.new("ShaderNodeBsdfTransparent")
    ms = N.new("ShaderNodeMixShader")
    L.new(gt.outputs[0], ms.inputs[0])
    L.new(tr.outputs[0], ms.inputs[1])
    L.new(felt.outputs[0], ms.inputs[2])
    L.new(ms.outputs[0], out.inputs[0])
    return mat


# ---------------------------------------------------------------------------
# Geometry builders
# ---------------------------------------------------------------------------

def link(obj, parent):
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    return obj


def mesh_from_arrays(name, verts, faces):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], [tuple(f) for f in faces])
    me.update()
    return me


def uv_sphere(name, radius=1.0, segments=48, rings=24):
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings,
                              radius=radius)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    return me


def build_body(body, pose, root, mats):
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=6, radius=1.0)
    me = bpy.data.meshes.new("PofuBody")
    bm.to_mesh(me)
    bm.free()
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    d = normalize(co.reshape(-1, 3))
    p = body.surface(d)
    me.vertices.foreach_set("co", p.ravel())
    col = fur_color(d, pose, body.blush) * 0.82
    attr = me.color_attributes.new("fur_color", "FLOAT_COLOR", "POINT")
    rgba = np.concatenate([col, np.ones((len(col), 1))], axis=1)
    attr.data.foreach_set("color", rgba.ravel())
    for poly in me.polygons:
        poly.use_smooth = True
    me.update()
    me.materials.append(mats["skin"])
    return link(bpy.data.objects.new("PofuBody", me), root)


def place(obj, loc, rot=None, scale=(1, 1, 1)):
    m = Matrix.Translation(Vector(loc))
    if rot is not None:
        m = m @ rot.to_4x4()
    m = m @ Matrix.Diagonal((*scale, 1.0))
    obj.matrix_world = m
    return obj


def build_eyes(body, pose, root, mats, features):
    """Eyes: glossy domes, or happy arcs, plus optional sad lids. Returns
    the lid frames so they can get a coat of fur."""
    r_eye = 0.16
    lids = []
    for side in (-1, 1):
        az, el = side * 28, -1.0
        p, n = body.at(az, el)
        outward = normalize(n + np.array([0, -0.25, 0]))
        center = p + n * 0.02
        if pose["eye_mode"] == "happy":
            # Closed eyes: keep fur short along the arc only, no bald socket.
            for q in build_happy_arc(body, root, mats, az, el, side):
                features.append(("sphere", q, 0.022))
            continue
        features.append(("sphere", center, r_eye * 1.05))
        rot = frame_matrix(outward)
        eye = link(bpy.data.objects.new(f"Eye.{side}", uv_sphere("eye")), root)
        place(eye, center, rot, (r_eye, r_eye * 0.82, r_eye * 1.04))
        eye.data.materials.append(mats["eye"])
        if pose["eye_mode"] == "sad":
            lid = link(bpy.data.objects.new(f"Lid.{side}", uv_sphere("lid")), root)
            place(lid, center, rot, (r_eye * 1.07, r_eye * 0.9, r_eye * 1.1))
            lid.data.materials.append(mats[f"lid{side}"])
            lids.append((center, rot, (r_eye * 1.07, r_eye * 0.9, r_eye * 1.1),
                         side, face_dir(az, el)))
    return lids


def build_lid_fur(pose, root, mats, lids, rng):
    """Short fur on the visible part of the sad lids. Bare felt lids read
    as smooth shells and the face as bored rather than sad (iteration log)."""
    z0 = 1.0 - 2.0 * pose["eye_open"]
    all_pts, all_col = [], []
    for center, rot, size, side, d_eye in lids:
        R, S = np.array(rot), np.array(size)
        q = normalize(rng.normal(size=(9000, 3)))
        visible = q[:, 2] > z0 - pose["lid_tilt"] * side * q[:, 0] + 0.04
        q = q[visible & (q[:, 1] < 0.35)]
        pos = (q * S) @ R.T + center
        nrm = normalize((q / S) @ R.T)
        down = np.array([0, 0, -1.0])
        comb = normalize(down - (nrm @ down)[:, None] * nrm + 1e-4)
        L = rng.uniform(0.022, 0.034, len(q))
        th0 = np.radians(rng.normal(55, 8, len(q)))
        th1 = np.radians(rng.normal(75, 6, len(q)))
        all_pts.append(strands_from_dirs(pos, nrm, comb, L, th0, th1, 5, rng,
                                         frizz=0.08, sag=0.1))
        c = hair_color(fur_color(d_eye[None, :], pose, []))[0]
        all_col.append(np.tile(c, (len(q), 1)) * rng.uniform(0.94, 1.04, (len(q), 1)))
    pts = np.concatenate(all_pts)
    col = np.concatenate(all_col)
    radii = np.outer(np.full(len(pts), 0.003), 1.0 - 0.7 * np.linspace(0, 1, 5))
    return make_curves("PofuLidFur", pts, radii, col, mats["fur"], root)


def polyline_curve(name, pts, radius, mat, root, taper=True):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = 6
    cu.use_fill_caps = True
    sp = cu.splines.new("NURBS")
    sp.points.add(len(pts) - 1)
    for i, q in enumerate(pts):
        sp.points[i].co = (*q, 1.0)
        if taper:
            t = i / (len(pts) - 1)
            sp.points[i].radius = 0.45 + 0.55 * math.sin(math.pi * t)
    sp.order_u = 4
    sp.use_endpoint_u = True
    cu.materials.append(mat)
    return link(bpy.data.objects.new(name, cu), root)


def face_curve(body, uv_pts, offset):
    """Map (azimuth, elevation) degree pairs onto the body surface."""
    d = np.array([face_dir(a, e) for a, e in uv_pts])
    p, n, _ = body.surface_frame(d)
    return p + n * offset


def build_happy_arc(body, root, mats, az, el, side):
    us = np.linspace(-1, 1, 15)
    pts = [(az + 9.5 * u, el - 1.5 + 6.5 * (1 - u * u)) for u in us]
    curve_pts = face_curve(body, pts, 0.035)
    polyline_curve(f"HappyEye.{side}", curve_pts, 0.019, mats["mouth_line"], root)
    return curve_pts


def build_nose(body, root, mats, features):
    p, n = body.at(0, -9.5, 0.025)
    nose = link(bpy.data.objects.new("Nose", uv_sphere("nose", segments=32,
                                                       rings=16)), root)
    place(nose, p, frame_matrix(n), (0.05, 0.035, 0.034))
    nose.data.materials.append(mats["nose"])
    features.append(("sphere", p, 0.05))


def build_mouth(body, pose, root, mats, features):
    v0 = -15.0
    if pose["mouth"] == "smile":
        # Hamster "ω" mouth with a short philtrum line from the nose.
        line = [(0, -11.5), (0, v0)]
        us = np.linspace(-1, 1, 21)
        w = [(7.0 * u, v0 - 2.6 * abs(math.sin(math.pi * u)) + 0.6 * u * u)
             for u in us]
        polyline_curve("Philtrum", face_curve(body, line, 0.03), 0.0075,
                       mats["mouth_line"], root, taper=False)
        polyline_curve("Mouth", face_curve(body, w, 0.03), 0.0085,
                       mats["mouth_line"], root)
        features.append(("cone", face_dir(0, v0 - 1.5), 9.0))
    elif pose["mouth"] == "frown":
        us = np.linspace(-1, 1, 15)
        f = [(4.5 * u, v0 - 1.0 + 1.6 * (1 - u * u)) for u in us]
        polyline_curve("Mouth", face_curve(body, f, 0.03), 0.0085,
                       mats["mouth_line"], root)
        features.append(("cone", face_dir(0, v0), 7.0))
    else:
        # Open "D" smile: a filled cavity with a tongue, set into the fur.
        ring = []
        for t in np.linspace(0, 1, 40):
            ang = math.pi * t
            ring.append((10.0 * math.cos(ang), v0 + 0.5 - 7.5 * math.sin(ang)))
        top = [(10.0 - 20.0 * t, v0 + 0.5 + 1.0 * math.sin(math.pi * t))
               for t in np.linspace(0, 1, 16)[1:-1]]
        outline = ring + top
        build_fan("MouthCavity", body, outline, (0, v0 - 3.5), 0.012,
                  mats["mouth_cavity"], root)
        tongue = [(5.2 * math.cos(a), v0 - 5.6 + 2.4 * math.sin(a))
                  for a in np.linspace(0, 2 * math.pi, 32)[:-1]]
        build_fan("Tongue", body, tongue, (0, v0 - 6.0), 0.018,
                  mats["tongue"], root)
        loop = outline + [outline[0]]
        polyline_curve("MouthRim", face_curve(body, loop, 0.014), 0.007,
                       mats["mouth_line"], root, taper=False)
        features.append(("cone", face_dir(0, v0 - 3.5), 12.0))


def build_fan(name, body, outline, center, offset, mat, root):
    pts = face_curve(body, [center] + list(outline), offset)
    n = len(outline)
    faces = [(0, 1 + i, 1 + (i + 1) % n) for i in range(n)]
    me = mesh_from_arrays(name, pts, faces)
    for p in me.polygons:
        p.use_smooth = True
    me.materials.append(mat)
    return link(bpy.data.objects.new(name, me), root)


def build_ears(body, pose, root, mats, features):
    ears = []
    for side in (-1, 1):
        az, el = side * 48, 52
        p, n = body.at(az, el, -0.02)
        outward = normalize(n * 0.6 + face_dir(side * 25, 0) * 0.4)
        rot = frame_matrix(outward)
        droop = 1.0 - 0.15 * (1 - pose["fluff"])
        ear = link(bpy.data.objects.new(f"Ear.{side}", uv_sphere("ear")), root)
        size = (0.2, 0.085, 0.19 * droop)
        place(ear, p + n * 0.16, rot, size)
        ear.data.materials.append(mats["ear_outer"])
        inner = link(bpy.data.objects.new(f"EarInner.{side}", uv_sphere("ear_in")), root)
        fwd = np.array(rot.col[1])  # local +Y (inward axis)
        place(inner, p + n * 0.17 - fwd * 0.03, rot,
              (size[0] * 0.58, size[1] * 0.6, size[2] * 0.55))
        inner.data.materials.append(mats["ear_inner"])
        features.append(("ellipsoid", (p + n * 0.16, rot, size)))
        ears.append((p + n * 0.16, rot, size, face_dir(az, el)))
    return ears


def build_ear_fur(pose, root, mats, ears, rng):
    """Short velvet pile on the ear backs and rims, leaving the pink inner
    ear bare, so the ears read as part of the plush instead of plastic."""
    all_pts, all_col = [], []
    for center, rot, size, d_body in ears:
        R, S = np.array(rot), np.array(size)
        q = normalize(rng.normal(size=(7000, 3)))
        inner = (q[:, 1] < 0) & ((q[:, 0] / 0.66) ** 2 + (q[:, 2] / 0.62) ** 2 < 1)
        q = q[~inner]
        pos = (q * S) @ R.T + center
        nrm = normalize((q / S) @ R.T)
        up = np.array([0, 0, 1.0])
        comb = normalize(up - (nrm @ up)[:, None] * nrm + 1e-4)
        L = rng.uniform(0.03, 0.05, len(q))
        th0 = np.radians(rng.normal(35, 8, len(q)))
        th1 = np.radians(rng.normal(60, 8, len(q)))
        all_pts.append(strands_from_dirs(pos - nrm * 0.004, nrm, comb, L, th0,
                                         th1, 7, rng, frizz=0.15, sag=0.1))
        c = hair_color(fur_color(d_body[None, :], pose, []))[0]
        all_col.append(np.tile(c, (len(q), 1)) * rng.uniform(0.94, 1.04, (len(q), 1)))
    pts = np.concatenate(all_pts)
    col = np.concatenate(all_col)
    radii = np.outer(np.full(len(pts), 0.0035), 1.0 - 0.7 * np.linspace(0, 1, 7))
    return make_curves("PofuEarFur", pts, radii, col, mats["fur"], root)


def build_feet(body, pose, root, mats, features):
    """Hind feet peeking out at the front of the sitting base, with three
    toe beans each so they read as feet rather than pills.

    Front paws held at the chest were tried and dropped (iteration 3): at
    app sizes they read as a second pair of blush cheeks."""
    for side in (-1, 1):
        p, n = body.at(side * 34, -62)
        loc = np.array([p[0] * 0.95, p[1] - 0.2, 0.065 + pose["hop"]])
        rot = frame_matrix(face_dir(side * 15, 0))
        foot = link(bpy.data.objects.new(f"Foot.{side}", uv_sphere("foot")), root)
        place(foot, loc, rot, (0.14, 0.19, 0.08))
        foot.data.materials.append(mats["paw"])
        R = np.array(rot)
        for tx in (-0.075, 0.0, 0.075):
            toe = link(bpy.data.objects.new(f"Toe.{side}", uv_sphere("toe", segments=24, rings=12)), root)
            tl = loc + R @ np.array([tx, -0.165 + 0.02 * abs(tx) / 0.075, 0.018])
            place(toe, tl, rot, (0.042, 0.04, 0.045))
            toe.data.materials.append(mats["paw"])
        features.append(("sphere", loc, 0.15))


def build_sparkles(root, center_z):
    """Little four-point stars around Pofu for celebrating (emissive)."""
    mat, nt, out = new_material("Sparkle")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (1.0, 0.86, 0.55, 1)
    em.inputs["Strength"].default_value = 2.2
    nt.links.new(em.outputs[0], out.inputs[0])
    spots = [(-1.3, 0.55, 0.17), (1.25, 0.85, 0.13), (-0.95, 1.25, 0.095),
             (1.45, 0.1, 0.085), (0.8, 1.4, 0.07)]
    for i, (x, dz, size) in enumerate(spots):
        verts, faces = [(0, 0, 0)], []
        for k in range(8):
            a = k * math.pi / 4
            r = size if k % 2 == 0 else size * 0.26
            verts.append((r * math.cos(a), 0, r * math.sin(a)))
        faces = [(0, 1 + k, 1 + (k + 1) % 8) for k in range(8)]
        ob = link(bpy.data.objects.new(f"Sparkle.{i}",
                                       mesh_from_arrays("sparkle", verts, faces)), root)
        ob.data.materials.append(mat)
        ob.location = (x, -0.6, center_z + dz)
        ob.rotation_euler = (0, math.radians(12 * i), 0)


# ---------------------------------------------------------------------------
# Fur
# ---------------------------------------------------------------------------

def strands_from_dirs(roots, normals, combs, lengths, th0, th1, K, rng,
                      frizz, sag):
    """Grow K-point strands: each one leaves the surface at angle th0 from
    the normal (towards its comb direction) and bends to th1 at the tip."""
    t = np.linspace(0.0, 1.0, K)
    theta = th0[:, None] + (th1 - th0)[:, None] * t[None, :] ** 1.3
    seg = (normals[:, None, :] * np.cos(theta)[..., None]
           + combs[:, None, :] * np.sin(theta)[..., None])
    seg[..., 2] -= sag * t[None, :]
    seg = normalize(seg)
    step = (lengths / (K - 1))[:, None, None]
    pts = np.concatenate([roots[:, None, :],
                          roots[:, None, :] + np.cumsum(seg[:, :-1] * step, axis=1)],
                         axis=1)
    # Frizz: smooth low-frequency wiggle that grows towards the tip.
    ph = rng.uniform(0, 2 * np.pi, (len(roots), 1, 3))
    fq = rng.uniform(1.5, 3.5, (len(roots), 1, 3))
    wig = np.sin(fq * np.pi * t[None, :, None] + ph) * t[None, :, None]
    pts += wig * (frizz * lengths)[:, None, None]
    return pts


def clump(pts, frac, amount, power, rng):
    """Pull strand tips towards the nearest guide strand (fluffy locks when
    small, matted clumps when large)."""
    n = len(pts)
    if amount <= 0:
        return pts
    guides = np.flatnonzero(rng.random(n) < frac)
    tree = kdtree.KDTree(len(guides))
    for gi, idx in enumerate(guides):
        tree.insert(pts[idx, 0], gi)
    tree.balance()
    nearest = np.array([guides[tree.find(pts[i, 0])[1]] for i in range(n)])
    K = pts.shape[1]
    w = amount * np.linspace(0, 1, K) ** power
    target = pts[nearest] + (pts[:, :1] - pts[nearest, :1]) * 0.15
    return pts + w[None, :, None] * (target - pts)


def collide(pts, features):
    """Push strand points out of eyes, nose, paws, and ears."""
    flat = pts.reshape(-1, 3)
    for f in features:
        if f[0] == "sphere":
            c, r = np.asarray(f[1]), f[2]
            v = flat - c
            dist = np.linalg.norm(v, axis=1)
            m = (dist < r) & (dist > 1e-6)
            flat[m] = c + v[m] / dist[m, None] * r
        elif f[0] == "ellipsoid":
            c, rot, size = f[1]
            R = np.array(rot)
            S = np.array(size) * 1.08
            q = ((flat - c) @ R) / S
            dist = np.linalg.norm(q, axis=1)
            m = (dist < 1.0) & (dist > 1e-6)
            q[m] = q[m] / dist[m, None]
            flat[m] = (q[m] * S) @ R.T + c
    flat[:, 2] = np.maximum(flat[:, 2], 0.004)
    return flat.reshape(pts.shape)


def make_curves(name, pts, radii, colors, mat, root):
    n, K, _ = pts.shape
    cv = bpy.data.hair_curves.new(name)
    cv.add_curves([K] * n)
    cv.position_data.foreach_set("vector", pts.astype(np.float32).ravel())
    rad = cv.attributes.get("radius") or cv.attributes.new("radius", "FLOAT", "POINT")
    rad.data.foreach_set("value", radii.astype(np.float32).ravel())
    col = cv.attributes.new("fur_color", "FLOAT_COLOR", "CURVE")
    rgba = np.concatenate([colors, np.ones((n, 1))], axis=1).astype(np.float32)
    col.data.foreach_set("color", rgba.ravel())
    cv.materials.append(mat)
    return link(bpy.data.objects.new(name, cv), root)


def build_fur(body, pose, root, mats, features, density, rng):
    fl = pose["fluff"]
    n_target = int(340_000 * density)
    cand = normalize(rng.normal(size=(int(n_target * 1.6), 3)))
    p, n, area = body.surface_frame(cand)
    keep = rng.random(len(cand)) < area / area.max()
    d, p, n = cand[keep][:n_target], p[keep][:n_target], n[keep][:n_target]

    front = face_dir(0, -5)
    ang_front = np.arccos(np.clip(d @ front, -1, 1))

    # --- length field --------------------------------------------------
    L = np.full(len(d), 0.17) * (0.75 + 0.25 * fl)
    L *= rng.uniform(0.75, 1.2, len(d))
    face = np.exp(-(ang_front / 0.62) ** 2)
    L *= 1.0 - 0.62 * face                       # short velvety face
    for c in body.cheeks:                        # fluffy cheek pouches
        L *= 1.0 + 0.35 * np.exp(-(1.0 - d @ c) / 0.03) * fl
    L *= 0.55 + 0.45 * smoothstep(-0.95, -0.55, d[:, 2])   # short underside

    # Keep feature areas clear: drop roots inside, shorten fur around.
    keep = np.ones(len(d), bool)
    for f in features:
        if f[0] == "sphere":
            dist = np.linalg.norm(p - f[1], axis=1) - f[2]
            keep &= dist > 0.0
            L *= 0.35 + 0.65 * smoothstep(0.0, 0.12, dist)
        elif f[0] == "cone":
            a = np.degrees(np.arccos(np.clip(d @ f[1], -1, 1)))
            keep &= a > f[2] * 0.75
            L *= 0.3 + 0.7 * smoothstep(f[2] * 0.75, f[2] * 2.2, a)
    d, p, n, L = d[keep], p[keep], n[keep], L[keep]
    ang_front = ang_front[keep]

    # --- comb direction field ------------------------------------------
    # Face fur flows away from the nose; body fur flows down and back.
    nose = face_dir(0, -9)
    f_face = normalize(d - nose * 0.9)
    f_body = normalize(np.array([0, 0.45, -1.0])[None, :] + 0.35 * d * [1, 1, 0])
    wf = np.exp(-(ang_front / 0.7) ** 2)[:, None]
    flow = wf * f_face + (1 - wf) * f_body
    flow = flow - (flow * n).sum(1, keepdims=True) * n
    flow = normalize(flow + 1e-6)
    # Per-strand random swirl around the normal for a soft, organic pile.
    t1 = np.cross(n, flow)
    a = rng.normal(0, 0.45 + 0.25 * fl, len(d))[:, None]
    comb = normalize(flow * np.cos(a) + t1 * np.sin(a))

    # --- lift: airy plush stands up, matted fur lies flat -------------
    th0 = np.radians(rng.normal(28 + 44 * (1 - fl), 8 - 3 * (1 - fl), len(d)))
    th1 = np.radians(rng.normal(62 + 24 * (1 - fl), 10 - 5 * (1 - fl), len(d)))
    K = 7
    pts = strands_from_dirs(p - n * 0.01, n, comb, L, th0, th1, K, rng,
                            frizz=0.05 + 0.10 * fl, sag=0.25 + 0.6 * (1 - fl))
    # Airy fur: faint locks. Matted fur: flat, elongated locks lying along
    # the comb (strong round clumps read as lumpy and unhealthy, see log).
    pts = clump(pts, frac=1 / 40 if fl > 0.5 else 1 / 70,
                amount=0.25 + 0.3 * (1 - fl), power=1.2, rng=rng)
    pts = collide(pts, features)

    col = hair_color(fur_color(d, pose, body.blush))
    col *= rng.uniform(0.94, 1.04, (len(d), 1))
    t = np.linspace(0, 1, K)
    radii = np.outer(np.full(len(d), 0.0034), 1.0 - 0.75 * t)
    return make_curves("PofuFur", pts, radii, col, mats["fur"], root)


def tuft_centerline(base, perk, samples=48):
    """Centerline of the signature curl. It rises from the crown and curls
    sideways (towards the viewer's right) so it reads from the front, like
    the 2D rig. perk = -1 flops it over with gravity."""
    side = normalize(np.array([0.93, -0.36, 0.0]))   # curl direction
    up = np.array([0.0, 0.0, 1.0])
    s = np.linspace(0, 1, samples)
    upright = (perk + 1) / 2
    a0 = math.radians(-28 * upright + 75 * (1 - upright))
    curl = math.radians(255 * upright + 60 * (1 - upright))
    length = 1.0 * upright + 0.75 * (1 - upright)
    ang = a0 + curl * s ** 1.7
    ds = (1.0 - 0.45 * s) * length / samples
    dirs = (np.cos(ang)[:, None] * up + np.sin(ang)[:, None] * side)
    dirs[:, 2] -= (1 - upright) * 1.1 * s            # gravity when wilting
    dirs = normalize(dirs)
    pts = base + np.cumsum(dirs * ds[:, None], axis=0)
    pts = np.vstack([base, pts[:-1]])
    binormal = normalize(np.cross(side, up))          # curl plane normal
    return pts, dirs, binormal


def build_tuft(body, pose, root, mats, rng):
    """A thick, tapering lock of long fur swept along the centerline with a
    moving cross-section frame, so it stays full through the curl instead
    of collapsing into a thin loop."""
    base, n = body.at(0, 82, -0.06)
    center, tang, B = tuft_centerline(base, pose["tuft_perk"])
    K = len(center)
    M = normalize(np.cross(B, tang))                  # in-plane normal (K,3)
    s = np.linspace(0, 1, K)
    count = 14000
    r = np.sqrt(rng.random(count))
    a = rng.uniform(0, 2 * np.pi, count)
    u, v = r * np.cos(a), r * np.sin(a)
    wb = 0.095 * (1 - s) ** 0.9 + 0.008               # depth half-width
    wm = 0.14 * (1 - s) ** 1.1 + 0.008                # in-plane half-width
    pts = (center[None] + u[:, None, None] * (wb[:, None] * B)[None]
           + v[:, None, None] * (wm[:, None] * M)[None])
    ph = rng.uniform(0, 2 * np.pi, (count, 1, 3))
    amp = 0.018 + 0.05 * (rng.random(count) < 0.08)   # a few flyaways
    pts += (amp[:, None, None] * np.sin(3 * np.pi * s[None, :, None] + ph)
            * s[None, :, None])
    # Each strand ends somewhere along the outer part of the lock.
    end = 1.0 - 0.6 * rng.random(count) ** 1.5
    idx = s[None, :] * end[:, None] * (K - 1)
    i0 = np.floor(idx).astype(int)
    i1 = np.minimum(i0 + 1, K - 1)
    w = (idx - i0)[..., None]
    rows = np.arange(count)[:, None]
    pts = pts[rows, i0] * (1 - w) + pts[rows, i1] * w
    tuft_color = hair_color(fur_color(np.array([[0.0, 0.25, 1.0]]), pose, []))[0]
    col = np.tile(tuft_color, (count, 1)) * rng.uniform(0.93, 1.05, (count, 1))
    radii = np.outer(np.full(count, 0.0042), 1.0 - 0.75 * s)
    return make_curves("PofuTuft", pts, radii, col, mats["fur"], root)


# ---------------------------------------------------------------------------
# Studio: backdrop, lights, camera, world
# ---------------------------------------------------------------------------

def build_studio(scene, pose, view_az, res, samples, preview, thick=False):
    # Cyclorama: flat floor bending into a back wall.
    prof = []
    for y in np.linspace(-14, 3, 40):
        prof.append((y, 0.0))
    for a in np.linspace(0, math.pi / 2, 24)[1:]:
        prof.append((3 + 4 * math.sin(a), 4 - 4 * math.cos(a)))
    for z in np.linspace(5, 16, 6):
        prof.append((7.0, z))
    xs = np.linspace(-16, 16, 3)
    verts = [(x, y, z) for (y, z) in prof for x in xs]
    faces = []
    for i in range(len(prof) - 1):
        for j in range(len(xs) - 1):
            a = i * len(xs) + j
            faces.append((a, a + 1, a + 1 + len(xs), a + len(xs)))
    me = mesh_from_arrays("Backdrop", verts, faces)
    for p in me.polygons:
        p.use_smooth = True
    me.materials.append(principled("Backdrop", srgb_to_linear(pose["backdrop"]),
                                   roughness=0.9, spec=0.2))
    scene.collection.objects.link(bpy.data.objects.new("Backdrop", me))

    def area(name, loc, size, power, color=(1, 1, 1), target=(0, 0, 0.9)):
        ld = bpy.data.lights.new(name, "AREA")
        ld.shape = "DISK"
        ld.size = size
        ld.energy = power
        ld.color = color
        ob = bpy.data.objects.new(name, ld)
        ob.location = loc
        direction = Vector(target) - Vector(loc)
        ob.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(ob)

    area("Key", (-3.4, -3.6, 4.0), 4.0, 1300, (1.0, 0.94, 0.86))
    area("Fill", (4.2, -3.2, 1.4), 4.0, 170, (0.92, 0.94, 1.0))
    area("RimL", (-2.6, 3.0, 3.0), 2.0, 420, (1.0, 0.96, 0.92))
    area("RimR", (2.8, 2.6, 2.6), 2.0, 380, (0.95, 0.95, 1.0))
    area("Top", (0, 0.5, 6.0), 5.0, 150)

    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*srgb_to_linear(pose["backdrop"]), 1)
    bg.inputs["Strength"].default_value = 0.25
    scene.world = world

    cam_d = bpy.data.cameras.new("Camera")
    cam_d.lens = 66
    cam_d.dof.use_dof = True
    cam_d.dof.aperture_fstop = 2.8
    cam = bpy.data.objects.new("Camera", cam_d)
    cam.location = (0, -6.4, 1.75)
    target = Vector((0, 0, 1.02))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam_d.dof.focus_distance = (Vector((0, -1.0, 1.0)) - cam.location).length
    scene.collection.objects.link(cam)
    scene.camera = cam

    r = scene.render
    r.resolution_x = r.resolution_y = res
    r.resolution_percentage = 100
    r.image_settings.file_format = "PNG"
    r.image_settings.color_mode = "RGB"
    r.film_transparent = False
    cy = scene.cycles
    cy.device = "CPU"
    cy.samples = samples
    cy.use_adaptive_sampling = True
    cy.adaptive_threshold = 0.02 if preview else 0.01
    cy.use_denoising = True
    cy.denoiser = "OPENIMAGEDENOISE"
    cy.max_bounces = 12
    cy.diffuse_bounces = 3
    cy.glossy_bounces = 4
    cy.transmission_bounces = 8
    cy.transparent_max_bounces = 16
    cy.sample_clamp_indirect = 4.0
    cy.blur_glossy = 0.5
    # Ribbons (camera-facing strips) look softer and whiter for plush pile
    # than true 3D tubes, and render faster. THICK resolved every strand as
    # coarse gray wire at 1024 px (see iteration log).
    scene.cycles_curves.shape = "THICK" if thick else "RIBBONS"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Base Contrast"
    scene.view_settings.exposure = 0.32
    r.threads_mode = "FIXED"
    r.threads = os.cpu_count() or 4


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def build(state, view_az=0.0, density=1.0, seed=7):
    pose = dict(BASE_POSE)
    pose.update(STATES[state])
    rng = np.random.default_rng(seed)
    body = Body(pose)

    root = bpy.data.objects.new("PofuRoot", None)
    bpy.context.scene.collection.objects.link(root)

    skin_col = fur_color(np.array([[0.0, -0.3, 0.6]]), pose, [])[0]
    mats = dict(
        fur=fur_material("Fur", pose),
        skin=skin_material("Skin"),
        eye=eye_material("Eye", pose),
        nose=principled("Nose", lin("nose"), roughness=0.45, sheen=0.4, sss=0.1),
        paw=principled("Paw", lin("paw"), roughness=0.55, sheen=0.6, sss=0.15),
        ear_outer=principled("EarOuter", fur_color(np.array([[0.6, 0.2, 0.75]]),
                                                    pose, [])[0] * 0.95,
                             roughness=0.8, sheen=1.0),
        ear_inner=principled("EarInner", lin("ear_inner") * (0.6 + 0.4 * pose["vitality"]),
                             roughness=0.6, sheen=0.6, sss=0.2),
        mouth_line=principled("MouthLine", lin("mouth_line"), roughness=0.5),
        mouth_cavity=principled("MouthCavity", lin("mouth_cavity"), roughness=0.6),
        tongue=principled("Tongue", lin("tongue"), roughness=0.4, sss=0.2),
    )
    for side in (-1, 1):
        mats[f"lid{side}"] = lid_material(f"Lid{side}", pose, side, skin_col * 0.68)

    features = []
    build_body(body, pose, root, mats)
    lids = build_eyes(body, pose, root, mats, features)
    build_nose(body, root, mats, features)
    build_mouth(body, pose, root, mats, features)
    ears = build_ears(body, pose, root, mats, features)
    build_feet(body, pose, root, mats, features)
    if pose["sparkles"]:
        build_sparkles(root, body.center_z())
    t = time.time()
    build_fur(body, pose, root, mats, features, density, rng)
    build_tuft(body, pose, root, mats, rng)
    build_ear_fur(pose, root, mats, ears, rng)
    if lids:
        build_lid_fur(pose, root, mats, lids, rng)
    print(f"[pofu] fur generated in {time.time() - t:.1f}s")
    root.rotation_euler = (0, 0, math.radians(view_az))
    return pose


def parse_args():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--state", default="content", choices=sorted(STATES))
    ap.add_argument("--out", default="pofu.png")
    ap.add_argument("--res", type=int, default=1024)
    ap.add_argument("--samples", type=int, default=128)
    ap.add_argument("--density", type=float, default=1.0,
                    help="fur strand density multiplier")
    ap.add_argument("--view", type=float, default=0.0,
                    help="turntable angle in degrees (0 = front)")
    ap.add_argument("--thick", action="store_true",
                    help="render hair as 3D tubes instead of ribbons")
    ap.add_argument("--preview", action="store_true",
                    help="looser adaptive sampling for fast look-dev")
    ap.add_argument("--save-blend", default="")
    return ap.parse_args(argv)


def main():
    args = parse_args()
    t0 = time.time()
    scene = reset_scene()
    pose = build(args.state, args.view, args.density)
    build_studio(scene, pose, args.view, args.res, args.samples, args.preview,
                 args.thick)
    t_build = time.time() - t0
    scene.render.filepath = os.path.abspath(args.out)
    t1 = time.time()
    bpy.ops.render.render(write_still=True)
    t_render = time.time() - t1
    print(f"[pofu] state={args.state} view={args.view} res={args.res} "
          f"samples={args.samples} build={t_build:.1f}s render={t_render:.1f}s "
          f"-> {args.out}")
    if args.save_blend:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.save_blend))


if __name__ == "__main__":
    main()
