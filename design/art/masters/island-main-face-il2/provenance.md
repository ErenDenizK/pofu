# world__island-main-face-il2

- **Approved:** 2026-11-06T10:39:23+00:00 from batch `batch-60-earth-face`, job `island-main-face-il2`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:18:51+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `island-main-face-il2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and literal region manual review. Select take2 under all constraints: take1 cannot satisfy native lossless upload cap (PNG994504bytes, method6 default losslessWebP697264, maximum effort lossless683864, all over614400); take2 exact native1536x1024 losslessWebP481778 fits. All experiments retained with identicalRGBA; no resize,quantization,lossy master,threshold/profile change or extra retry. Preserve recognizable parent lawn/earth outline and bands,Pofu door and four roots; add only second softrose inset round door near60percent earth width at comparable height, crossbar round window,tulip teacup sign, matching rim/recess light. Root independent proper-alpha review accepts take2. Tiny exterioralpha5to7 or nearby pebbles on take1 are NOT invented hard gates; local smallstone rim is requested. Generic LIGHT warnings advisory, no new global pixel-correlation threshold or false literal pixelidentity certification. Only this twoasset home family is prelinked once; all unrelated consumer lore/unlock/links preserved. True IL6 waits official promotion,Harmony and uploaddecode receipt. All source PNGs/callbacks/QA/locked preserved unchanged.

## References

- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/masters/door-mochi/door-mochi.png`: Mochi's door design: its rose colour, round shape and small tulip-glass sign; paint it INTO the earth, not pasted.

## Prompt (fingerprint d6e3e35926866c51)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. Mochi's door design: its rose colour, round shape and small tulip-glass sign; paint it INTO the earth, not pasted.

Edit the attached floating island: paint a second small round door
into its earth body, set into the earth exactly like the existing
round wooden door on the left, at the same height, at about 60
percent of the earth body's width from its left edge. This door is
painted a soft rose with a small round window and a tiny sign with
a tulip-shaped tea glass, as in the attached door design, framed by
the same rim of small stones, with the same soft shadow inside its
recess and the same light as the rest of the earth. Everything else
stays exactly as it is.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a pasted-on look, a different light or texture, a frame of another style, moving or resizing anything, characters, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 28 (R1 51))
- warn: light_values (day/subject: L p2 62 (at most 22), p98 92 (at least 90), spread 30 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 84 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.45 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 2.0 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 4.9, off-palette 0.1% (top: #888877 (0.1%), #888866 (0.0%)))
- pass: depth_ratio (earth depth / width 0.25 (at most 0.32))
- pass: lawn_chroma (lawn chroma p95 19 (palette meadow 38))
- pass: harmony (harmony score 74 against the world reference (outliers: C_p95))
- pass: edit_silhouette (99% of the parent's shape kept)
- pass: edit_stability (97% of the parent level unchanged)
- pass: edit_chroma (chroma x1.02 of the parent level (drift compounds along a chain))
