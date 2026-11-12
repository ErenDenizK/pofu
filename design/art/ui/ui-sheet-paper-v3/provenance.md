# ui__sheet-paper-v3

- **Approved:** 2026-11-06T11:02:26+00:00 from batch `batch-61-ui-kit-v3`, job `ui-sheet-paper-v3`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:26:43+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-sheet-paper-v3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hardQA and root/independent native+locked/proper-alpha literal review34ad19fd; take1 wins normal lowest load0.2846 versus0.2973. The tall blank warmcream paper has a gently deckled lifted top edge, soft top corners, continuous side/top stitches and genuinely runs off bottom with no closed-card bottom rim. Real native1254square side-alpha gutters are disclosed, NOT falsely certified fullwidth: this is a sheet MATERIAL under the authored header trim-to-art-bounds/stretch workflow; untrimmed fullcanvas will not fill a hostsheet. Authored32pt caps/ship341 observed at341x220/440 preserve top and quietcenter without conspicuous seams, with stitch pitch stretch disclosed; no claimed lead capapproval or completed end-to-end integration. Sourcecaps/prompt/refs/QA/PNGpixels unchanged; no force or retry. Native654469PNG uses exactlosslessWebPdelivery undercap (preflight401314B), rawretained. Complete unchanged172source canonicalHmeasure/check required, all foreignmetadata restored and no fabricatedUIshard. Consumer full34plannedfamily stays byte-stable after first honey commit. Original2PNG/RGBA/QA/locked seals retained. auto-picked by QA; founder review pending.

## References

- `design/art/ui/ui-sheet-paper/ui-sheet-paper.png`: The earlier paper sheet (batch-13): the same cream paper, stitches and warm light; make the top edge a gently deckled (torn-soft) edge and the whole sheet a little thicker and warmer. Do not copy it exactly.
- `design/art/takes/batch-48-gate-scenes/x-gate-round-door/ui__x-gate-round-door--t1.webp`: The round door gate scene (take 1, the lead's pick; batch-58 repaints it as layers and does not block this batch): the material, light and finish of the honey wood plaques hanging on the rope at the bottom (and its warm paper-and-wood look). Take the material only; do not draw the door, the burrow, the rope or the scene.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint c6da6b4aeadafa8c)

```text
REFERENCES (attached, in this order):
1. The earlier paper sheet (batch-13): the same cream paper, stitches and warm light; make the top edge a gently deckled (torn-soft) edge and the whole sheet a little thicker and warmer. Do not copy it exactly.
2. The round door gate scene (take 1, the lead's pick; batch-58 repaints it as layers and does not block this batch): the material, light and finish of the honey wood plaques hanging on the rope at the bottom (and its warm paper-and-wood look). Take the material only; do not draw the door, the burrow, the rope or the scene.
3. The palette card for props: use only these colors (and mixes of them).

A tall sheet of thick handmade cream paper (#FBF1DE) seen straight on, filling the canvas from the left edge to the right edge and from near the top down past the bottom edge: its top corners softly rounded, the top edge gently deckled with a thin lifted lighter paper lip, a faint darker paper edge outside a thin row of small even warm-brown stitches running just inside the top and side edges. The middle is plain, flat, even cream paper with no stains and no fibres. Nothing written or drawn on it.

CRAFTED FACE: a painted surface for a control that the app slices and
stretches (the crafted skin of the Home A/B, ADR-0018 timing amendment).
Paint only the material, never the control's content: no text, no letters,
no numbers, no symbols, no icons, no glass, no frosted or transparent
parts. The face is lit from straight above, so the centre is perfectly flat
and even from left to right and top to bottom of its middle (no gradient
that would stretch badly, no spots, no texture that varies along the
width). Every rounded edge, lip and shadow sits inside the outer margin
that the slice caps will hold; the middle is a plain, calm area. A clean
silhouette on a transparent background, centered, with no ground shadow,
no cast shadow, no outline and no border. Material is matte-to-soft-gloss
clay glaze or paper, painted in the same soft, milky, high-key picture-book
style as the world's props.

STYLE: soft painterly 2D illustration from the same picture book as the
attached hamster: the same gentle airbrushed shading, the same light,
high-key values and the same milky pastel colors. Simple, rounded, chunky
shapes with few parts; fewer, larger shapes, because this is seen small on
a phone. Every material is painted matte, as a soft form with broad,
smooth value changes: wood without grain, metal without hammering or
reflections, glass as a soft tinted shape, cloth without weave. At most
one small, soft highlight per object; no glints, no shine. Colors are
muted and lifted toward cream; the darkest shadow is a warm mid-brown,
never near black. Warm diffused key light from the upper left, a faint
warm rim light along the right edge, soft ambient shadow only where forms
touch. Clean, calm, uncluttered. No outlines, no hard edges. No text, no
letters, no numbers, no logos, no watermark, no border, no frame, no
sticker outline.

AVOID: text, letters, numbers, symbols, icons, glass, frosted or transparent parts, a drop shadow or cast shadow on the ground, an outline, a border around the canvas, a background, gloss or specular glints, texture that varies along the width, pure black, neon or saturated colors, a 3D render look

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- pass: value_floor (lightness p5 87 (R1 59))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: palette_drift (mean dE 0.4, p95 0.8, off-palette 0.0%)
