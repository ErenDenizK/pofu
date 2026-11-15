# ui__ui-flow-stone-2

- **Approved:** lead pick of `x-flow-stone-c` take 2, batch `batch-114-flow-stone-v2` (pofu-art PR #81).
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission (chatgpt-plan).
- **Tool:** codex-cloud, an edit of `x-flow-stone-blank-t1` (batch 90 pilot).
- **Post-processing:** none. The take (webp, 1024x1024, sha256 `77510703697f140af80a5c17fdf51fc03bd77572aa40d26571396303d3cec1ba`) is saved losslessly as PNG; the app tints it in code.
- **Review note:** the stone runs full bleed with even light; on a 4x3 board with channels and random turns there is no seam, rim, gradient or cut moss. Chroma is about 20 percent below the straight tile.

## Prompt (manifest job `x-flow-stone-c`)

```text
- id: x-flow-stone-c
    kind: ui
    name: x-flow-stone-c
    size: 1024x1024
    canvas: 1024x1024
    transparent: false
    palettes: [world-foliage]
    edit_of: x-flow-stone-blank-t1
    chat: "Pofu · Flow game"
    acceptance: {exploration: true}
    notes: "v2 variant 2: one stone of the same family. Same checks as variant 1."
    prompt:
      - text: |
          Edit the attached game tile, a single slab of pale, softly worn stone
          seen straight from above. Keep its colour, brightness and painting
          style, and make it a different stone of the same family: the soft
          mottling is finer and more even, with two or three faint darker
          freckles, and there are two small soft tufts of moss, one in the lower
          half and one near the middle. The light is even and top-down across the
          whole square, with no brighter or darker side, no gradient, and no warm
          or orange band along any edge. The stone runs to all four edges, full
          bleed, edge to edge, with the same colour and brightness along every
          edge so that copies laid side by side show no seam. Every tuft of moss
          is at least 120 px from every edge, none touching or cut by an edge or
          a corner. The whole square is stone, with no channel, no groove, no
          water and no gap.
      - block: flow-stone-style-v1
      - block: edit-keep-v1
      - text: "AVOID: a rim light, an orange or warm band on any edge, a gradient across the tile, a bevel, a border, a frame, rounded corners, a margin, a vignette, a cast shadow, moss or grass touching or cut by an edge, a channel, a groove, a trench, water, cracks, rocks standing up, flowers, characters, text"
```
