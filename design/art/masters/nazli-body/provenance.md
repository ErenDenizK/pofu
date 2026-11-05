# char__nazli-body

- **Approved:** 2026-11-05T23:15:33+00:00 from batch `batch-37-nazli-rig-pilot`, job `nazli-body`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:14:09+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `nazli-body.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent original and official locked review confirms take2 faces the camera in three-quarter view with the near eye and far eye edge visible, a tired kind heavy-lidded face, faint smile and blush. Smooth grey-blue back fades to cream belly; bare body recedes upper right from head lower left. The tail stock ends in a soft rounded tip; no fins, flukes, island patch, pier, rope, clouds, other characters, fur or Pofu curl. Faint ribbed rounded unlit paper-lantern skin scar is not a bulb or floating object. Take1 is excluded by canonical hard ground_line82.6percent; take2 has no hard failures, ground_line85.8percent and light/Harmony46.3 remain advisory warnings. No extra retry, invented halo check or manual geometry cleanup: sampled surrounding bright RGB is alpha0 and absent in the official locked composite. Stable consumer links truthfully name all five existing planned rig asset nodes in this first commit, preserving consumer bytes for later job receipts. Founder review pending.

## References

- `design/art/takes/batch-34-islands-in-game/x-gezgin-f1-harbor/plate__x-gezgin-f1-harbor--t1.webp`: The approved Nazlı (Gezgin form 1): copy the whale only: her colors, soft rounded shape, tired kind eye, faint smile, cream belly, and the faint paper-lantern scar. Ignore the pier, the characters, the island patch and the clouds. Turn her three-quarter toward the camera.

## Prompt (fingerprint 77542e96252d0f01)

```text
REFERENCES (attached, in this order):
1. The approved Nazlı (Gezgin form 1): copy the whale only: her colors, soft rounded shape, tired kind eye, faint smile, cream belly, and the faint paper-lantern scar. Ignore the pier, the characters, the island patch and the clouds. Turn her three-quarter toward the camera.

Nazlı, a humble, tired, gentle cloud-whale, as a game sprite on a
transparent background, in a three-quarter view turned toward the
camera: her rounded head is in front at the lower left, her big
kind face looking out of the picture, and her long body recedes
back to the upper right. Her face is fully visible and unobstructed:
the nearer eye is large, soft and heavy-lidded, the farther eye is
just visible beyond the bridge of her brow, a faint gentle smile, a
pink blush on the cheek. Grey-blue on the back fading to cream on
the belly, a little thin and pale, a low head. On the upper flank
behind the head, a faint pale scar in her skin shaped like a small
unlit paper lantern (a rounded lantern with ribs and a tiny cap and
handle; never a light bulb).

IN THIS IMAGE LEAVE OUT, to be added as separate layers: NO flippers
or fins of any kind (the sides of the body are smooth), NO tail
flukes (the tapering tail stock ends in a soft rounded tip), NO
mossy island patch (her back is bare, smooth and clean, with no
bench, post, hook or grass). Her whole body fits in the canvas,
about 85 percent of its width, centered, with transparent empty
space around it. No pier, no rope, no clouds, no characters, no
ground, no shadow.

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

AVOID: a pier, ropes, clouds or a sea, characters, a light bulb, a frightening mouth, teeth, her face hidden or turned away, fins, flukes, an island on her back, text, letters, a floor, a ground shadow, outlines

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 16 (R1 51))
- warn: light_values (day/subject: L p2 71 (at most 22), p98 95 (at least 90), spread 23 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 84 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.63 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.0 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- pass: palette_drift (mean dE 1.4, p95 3.1, off-palette 0.0%)
- warn: ground_line (feet at 85.8% of the height (contract 88%))
- warn: harmony (harmony score 46 against the char reference (outliers: C_p95, L_p2, detail, tint_b))
