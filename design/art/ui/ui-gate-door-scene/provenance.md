# ui__gate-door-scene

- **Approved:** 2026-11-06T16:09:23+00:00 from batch `batch-58-gate-round-door`, job `gate-door-scene`, take t2
  of 1 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T09:56:15+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-gate-door-scene.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1536 take; the master and raw are delivered at x0.5 (512x768, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** retained take 2; author-authorized palette_drift-only force; full native QA remains fail. Lead-selected retained original take 2. Queue row 0-r authorizes palette_drift only; row 0-q authors deliver.scale=0.5 after PR308 native-cap exclusion. Full native QA remains fail solely palette_drift; original source, native locked pixels, account, timestamps and four exhausted historical root ordinals remain unchanged. No current root generation or retry. Official512x768 delivery viewed and content verified; founder review pending.

## References

- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The home island's round door, earth bank and soft painting.

## Prompt (fingerprint 445c351da4b04101)

```text
REFERENCES (attached, in this order):
1. The home island's round door, earth bank and soft painting.

A full portrait phone screen for a cozy mobile game, painted, no
text: we stand right in front of a little round wooden door set in
a warm earth bank under a grassy lawn edge with small flowers. The
door is swung wide open toward us on the right; the round doorway
is empty and glows with warm honey lamplight from a cozy burrow
inside (a tiny lamp, a teacup on a small table, a rug, a shelf with
a plant), a place where a small round hamster could stand. Above
the bank, a calm blue-hour sky with a few soft clouds and stars
fills the top third. Below the doorway, three blank wooden plaques
hang on a short rope swag from the door frame, one larger in the
middle, two smaller at the sides. Grass and small flowers frame
the bottom edge.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.

AVOID: any character or animal, text, letters, numbers, icons, a phone frame, UI chrome

Output: one image, opaque, full bleed, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1024x1536)
- warn: chroma_ceiling (chroma p95 61 (R1 51))
- pass: value_floor (lightness p5 48 (R1 59))
- pass: detail_budget (detail at display size 2.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.6)
- fail: palette_drift (mean dE 8.7, p95 23.8, off-palette 28.3% (top: #4466BB (2.7%), #7788CC (2.4%)))
