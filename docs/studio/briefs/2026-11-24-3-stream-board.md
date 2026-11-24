builder

# Brief 3: the stream board in the dial-big direction (2026-11-24)

Stage 2.3 of `docs/design/assessment-2026-11-24-path.md`. The founder
picked the dial board (`x-board-dial-big` take 2, founder-input 44) and
liked the raised grass blocks and their textures (founder-input 43).
Today's board is flat cream tiles and grey channels on a lawn under a
lush painted waterfall: the board and its backdrop look like two games
(`path-game-flow-stage1`).

**Do not start until** pofu-art batch 158 (`batch-158-board-kit-v3`) is
delivered and the lead has named one take per piece in this brief's
hand-over. Do not build on stand-ins or on concept takes. Branch:
`feat/flow-dial-board`.

Every fact below is a lead. Open it before you build on it.

## The design

One rule turns his picture into a board that explains itself:

> **A piece that turns is a round dial set in its block. A piece that
> does not turn is a plain block.**

- Every cell is a raised block: a clipped grass top inside a rounded rim
  of pale warm stone. The block never rotates, so its light (from the
  upper left) is always right.
- A turnable piece (`FlowTileKind.isTurnable`: straight, bend, split)
  is a round disc inset in its block inside a stone ring. The disc
  carries the channel; a tap turns the disc, not the block. The disc is
  painted flat from straight above, so it can rotate freely.
- A fixed piece (source, mouth, wheel, gate, rock, grass) is a block
  with its feature painted on it. Nothing on it suggests it turns.
- Water is still drawn by code in the channels, as today. A dial's
  channel and its neighbours' channels must meet at the cell's edge at
  one width.
- Around the board: the calm backdrop from the kit (a rock and a narrow
  fall above, a round pool below, open sky and cloud). No cottage, no
  rainbow, no basins.
- The whole-screen reference is pofu-art
  `design/art/takes/batch-157-board-dial-big/` (`x4-board-big-dials` and
  `x4-board-big-flow`), once delivered; until then
  `batch-155-concept3-board/x3-board-dial-calm`. A reference shows the
  composition; the game's boards decide the pieces.

## What is there

- Pieces and which turn: `Packages/PofuKit/Sources/PofuGames/Flow/Core/FlowTile.swift:54-90`;
  the glyph table at `:148-153`. The eight boards
  (`Resources/flow-boards.json`) use every kind; the largest is 6 rows
  by 5 columns, the smallest 4 by 3.
- The ground switch: `Flow/Core/FlowGround.swift:8-20`, method A
  (keycaps) and method B (lawn, the default), and the art slots below
  it. Method A exists only for comparison frames.
- The drawing: `Flow/Scene/FlowArt.swift` (977 lines): the painted bank
  tiles, the blank stone with a carved channel (`stone`, `:294`), the
  water (`water`, `:461`), the lip kit, the spout, the pool slices, the
  9-slice edge. `Flow/Scene/FlowScene.swift` places and animates them.
- The layout: `Flow/Core/FlowLayout.swift`, cells of 44 pt or more.
- The frames: `PlayerPathScreenshotTests.swift:526`
  (`path-game-flow-stage1`, `-mid`, `-solved`, `-method-a`,
  `-method-b`).
- How earlier kit takes were brought into the bundle: the comments in
  `FlowArt.swift` name the batches (114, 130, 132, 135) and the sizes
  they were ingested at. Follow the same route for batch 158.

## What to build

1. Ingest the picked takes of batch 158 as bundle art, at the size a
   cell has on the phone (3x), with real alpha.
2. Draw the board from them by the rule above. A turn animates the disc
   only. A wet channel shows the code's water over the painted bed.
3. The backdrop and the pool come from the kit; the lip, the spout and
   the edge are kept only where the new picture still needs them, and
   deleted where it does not.
4. Delete what the new board replaces: the code-drawn tiles and their
   fallbacks, ground method A and its switch, the bundle files no
   longer loaded. A missing art file is now a test failure, not a
   silent fallback to a drawing.
5. Leave the game alone: the boards, the solver, the rules, the sounds,
   the HUD's content. The HUD stays native.

## Not yours

`PofuWorld`, `App/Home/` beyond what `CaglayanFlowView` needs, the
garden game.

## Acceptance, in frames at 1206 x 2622

- `path-game-flow-stage1`, `-mid`, `-solved`: at 1:1, the blocks, the
  backdrop and the pool share one light, one stone and one green; no
  seam between cells; a dial reads as round and its ring as part of the
  block; the water's width does not jump at a cell's edge.
- A new `path-game-flow-stage4`: the 6 by 5 board fits between the HUD
  and the controls with cells of 44 pt or more.
- A new `path-game-flow-turning`: one disc pinned mid-turn; the block
  under it has not moved and its light has not turned.
- `-method-a` and `-method-b` frames are removed.
- Then the founder plays one board on his phone; his word closes the
  step, not the frames.

Add `changes/feat-flow-dial-board.md`.

## Hand back

PR, CI state, the three 1:1 crops, the list of deleted files and art,
which kit pieces were missing or unusable (a new Codex row is the
lead's to write). At most 15 lines.
