Role: `.claude/agents/builder.md`

# Builder brief: fit the flow board kit v2 into the stream game (2026-11-16)

## Goal

The stream game's board (Flow, ground B, the default since #501) takes its
pieces from the art Codex painted in the scene's own colour, and the code
grades that made old art belong go away. This is the "small code pass" that
`docs/design/minigames-overhaul-v1.md` (section 4) plans after batch 135.

## The art (pofu-art `origin/main`, read with `git show`, never copy the repo)

Picks recorded in each job's `review.yaml` under
`design/art/takes/batch-135-flow-kit-v2/` and
`design/art/takes/batch-132-flow-board-edge-v2/`. The reviewer's fit
numbers, measured at cell 264 px on the method-b frame (check them; they
are leads):

| Piece | Pick | Fit |
|---|---|---|
| water (135) | t2 | Hue matches the pool (181 vs 180); about 8% too saturated: desaturate about 10% at ingest, then drop `waterTint`. The code mirrors each cell and uses a middle crop, so wrap seams do not matter; a crop near 0.30 matches the pool's ripple size. |
| lip kit (135) | t1 | 2172 x 724. Pieces at source x 75-446, 503-1080, 1124-1651, 1707-2098; stone bottom y 467. One scale = cell / 528 (the spillway's width); the spillway centred on the spring's column; the run squeezed to one cell per column (x 0.91). Lip height cell x 0.36 instead of the fixed 30 pt. The ends are 0.7 cell wide and break the gutter: crop each to its outer stone. The water sheet hangs about 0.1 cell over the spring cell. |
| spout (135) | t1 | Scale so its channel (145 px in the source) equals the stream's width (about 0.5): about 1.3 cells wide, 1.1 tall. The wet state sits 18 px left of the dry one: anchor each by its channel centre. Its closed top rim (source y 110-190) goes under the mouth tile; the drain ring comes off last-row mouths. |
| rocks (135) | t1 | Colour equals the backdrop's boulders: `rockTint` goes. All four paint their own shade: `rockCutHasPaintedShade` covers all four. All four are large: `rockCutFill` from 0.72 to about 0.62. |
| edge (132) | t1 | Delivered at 1254 px, not 1024. 9-slice at 190 px of 1254 (centre rect 0.152, 0.152, 0.696, 0.696); stretch the sides, never tile. The rect sits about 10 source px inside the canvas. At draw scale 0.6 (curb about 60 px). The lip ends' outer stones sit over the top corner knobs. |
| lawn | none yet | Redo queued (batch 136). Keep `lawnTint` and today's lawn; leave a one-line seam for swapping the file. |

The grades named above live in
`Packages/PofuKit/Sources/PofuGames/Flow/Scene/FlowArt.swift` (`lawnTint`,
`rockTint`, `waterTint`, `rockCutFill`) and `Flow/Core/FlowGround.swift`
(`rockCutHasPaintedShade`).

## One decision is yours, from frames

The spout pours past the pool the code draws into the backdrop's own pool,
so two pools show. If the backdrop's pool sits under the spout at device
size, remove the code-drawn pool; if not, keep it and end the spout on it.
Say which, with the crop.

## Acceptance

- Ground B frames `path-game-flow-*` at 1206 x 2622: the spillway over the
  spring's column, spouts on the last-row mouths, no grade left on water and
  rocks, the edge's corners whole. Judged in 1:1 crops beside today's
  frames: no pasted edge, halo, or colour step between a piece and the
  scene.
- Ground A (`POFU_FLOW_GROUND=keycaps`) still builds and renders.
- Tests through `tools/swift/test-linux.sh`; a `changes/<branch>.md` line.
- Art enters the app the way the earlier flow art did (find it from #489
  and #501; `tools/assets/integrate.py` clears before it writes: check
  `git status` for deletions after any run).

Branch `feat/flow-kit-v2-fit` in your own worktree from `origin/main`. At
most three pushes. Open the PR; do not merge. Hand back: the PR, before and
after crops at 1:1 (paths), the pool decision, what you saw that is still
wrong.
