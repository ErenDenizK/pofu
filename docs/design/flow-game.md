# The flow game (connect), and Çağlayan's play

**Status:** game-design note by the game designer for the lead, 2026-11-06. Closes the tracker's "no design note" for Çağlayan and the flow game. Sources: [game plan](../product/game-plan.md) §4-§5, [Book One island sheets](book-one-islands.md) §3 (Revontuli), §5 (Mehtap), §8-§9, [healing arc](island-healing-arc.md), `tools/imagegen/manifest/batch-43-caglayan-production.yaml` (the stages), [game design](../product/game-design.md) A1-A14, [Koke prototype](koke-prototype.md), and the garden in `Packages/PofuKit/Sources/PofuGames`.

## 1. The fantasy

**Turn the old stones until the water finds its way home.**

The feel is a plumber's puzzle made gentle: every tap turns one carved stone a quarter, and the water *moves at once* into whatever now connects, so the board is never a test you submit; it is a stream you watch grow. The pleasure is the pour: a stone clicks into line, water runs a tile further with a rising trickle, a wheel catches and turns, and the last connection floods the whole channel with a little rush and a splash in the pool. Damla the otter watches from the bank with her tea glass.

## 2. The rules

**Board: square, not hex.** Decided. On a phone in portrait, a square grid of at most 5 columns gives cells of about 70 pt (402 pt wide, 16 pt gutters), well above the 44 pt target; a hex grid at the same width gives smaller, staggered targets and six rotations a beginner cannot predict. Water reads naturally on a square grid: the falls are steps and channels, straight drops and right-angle turns, which is what the cliff in batch-43 paints. Four rotations are learnable in one tap. Boards are 3-5 columns by 4-7 rows, portrait, source at the top, pool at the bottom (water falls down, like the island).

**Tiles.** Each cell holds one tile; a tile has openings on some of its four sides (N, E, S, W).

| Tile | Openings | Rotates | Notes |
|---|---|---|---|
| Straight `│ ─` | 2, opposite | yes (2 distinct states) | a carved channel |
| Bend `└ ┌ ┐ ┘` | 2, adjacent | yes (4) | |
| Split `├ ┬ ┤ ┴` | 3 | yes (4) | one stream becomes two; the only way to feed two targets |
| Source `S` | 1 | no | the spring at the top; always wet |
| Mouth `P` | 1 | no | where the stream meets the pool; a target |
| Wheel `W` | 2, E-W | no | the mill wheel; a target: water must pass through it, and it turns while wet |
| Gate `G` | 2, as drawn | no | Damla's sluice: a fixed channel the player cannot turn; an anchor that tells the eye where the water must go |
| Rock `#` | 0 | no | a dry boulder |
| Grass `.` | 0 | no | empty bank |

No cross piece (two crossing streams on a 70 pt tile read as a muddle).

**The one verb: tap to rotate.** A tap turns a tile 90° clockwise with a stone click. No dragging, no tray, no placing: everything one thumb can do, everything VoiceOver can do with one action. Fixed tiles show a carved rim and give a soft "thunk" with no turn when tapped.

**Water.** After every tap the model recomputes the wet set: breadth-first from the source through every pair of facing openings. Water runs both ways along a channel (no gravity rule to learn). An opening that faces nothing spills a small, harmless dribble on the bank: information, not failure.

**Solved** = every mouth and every wheel is wet. Spills are allowed, unused tiles may sit anywhere. The board locks the instant it is solved (no "submit").

**Undo:** one button, steps back the last tap (a stack of the board's taps). There is no reset button: undo to the start is the reset.

**No fail state, no clock.** No move limit, no timer, no score, no stars, no "par". Leaving mid-board saves the board as it is; it resumes the same day or any later day.

**Hints:** after **20 s without a tap**, Damla (Pofu on Revontuli and Mehtap, where she is not) points at one tile: the turnable tile nearest the wet frontier whose rotation differs from the nearest solution, with a faint ghost of its right rotation. Another 20 s, another tile. Unlimited and free; a hint never solves the board for you and never costs anything.

## 3. Puzzles per stage

**A round** is 1-3 small boards played back to back, aimed at 60-90 s (median 90 s, A10). Çağlayan's island rules hold: a visit plays one round, the round advances one stage, at most one stage a day, only on a day with a resisted reach (Koke prototype §1). The round counts as one of the day's rounds (game plan §5). When the stage is done the island says "all caught up" (A1) for that day. After stage 4 the island keeps its game (register G4, open question Q-6): earned rounds pay its material, free play beyond that pays nothing, and there is no extra board to grind for seeds (seeds are never paid by islands, G7).

**Difficulty is taps and choices, not size.** About 2.5-3.5 s per tap (look, turn, watch) means a board of 12 taps is about 35-45 s.

| Stage | Stream on the island | Boards | Sizes | New idea | Taps (intended) |
|---|---|---|---|---|---|
| 1 | the left steps | 2 | 3×4, 4×4 | turning; Damla shows the first tap | 4, 6 |
| 2 | the second stream; pool half full | 2 | 4×5, 4×5 | the split; the gate | 10, 10 |
| 3 | the third; the wheel turns | 2 | 4×5, 5×5 | the wheel as a target; decoys | 9, 11 |
| 4 | the full falls (signature) | 2 | 5×5, 5×6 | everything; two mouths and a wheel | 12, 14 |

(Width × height: columns × rows.)

**Reuse is a skin plus one twist** (Book One sheets §8: each reuse adds one twist; never more than 5 columns, at most 7 rows):

| Island | Skin | Twist | Boards |
|---|---|---|---|
| Revontuli (stages 1-4) | light: ice prisms and lantern chains, sauna as source, lanterns as targets | the **prism** is the split, re-drawn (light splits into two beams); the long board of stage 4 (5×7) feeds three lanterns and the post | 4: one per stage |
| Mehtap (stages 1-3) | moon thread: thread segments in the night sky, stars as targets | the targets are **stars that must all be joined** (several mouths, no wheel); stage 3 is two boards ("the last five trails") | 4: 1, 1, 2 |

**Book One ships 16 hand-made boards:** Çağlayan 8, Revontuli 4, Mehtap 4. No generator: 16 boards are a weekend of authoring, each can carry a story shape (the left steps, the two arms of the pool), and a generator would cost more than all 16 together. Book Two reconsiders.

### Four example boards (one per stage)

Glyphs: `│ ─ └ ┌ ┐ ┘ ├ ┬ ┤ ┴` turnable; `S` source (opens S), `P` mouth (opens N), `W` wheel (opens E-W), `G` gate (fixed `│`), `#` rock, `.` grass. Rows top to bottom, `rNcM` = row N, column M from 0. One clockwise tap maps `│→─→│`, `└→┌→┐→┘→└`, `├→┬→┤→┴→├`.

**Stage 1, board 1 (3×4): the first bend.** 4 taps (the minimum).

```
start        solved       taps
S # .        S # .        r1c0 ┘→└ (1)
┘ └ #        └ ┐ #        r1c1 └→┌→┐ (2)
# ─ ─        # │ ─        r2c1 ─→│ (1)
# P #        # P #        r2c2 is a decoy
```

The source already wets `r1c0` at the start, so the first tap visibly moves water; Damla's paw shows that first tap.

**Stage 2 (4×5): the split and the gate.** 10 taps (the minimum).

```
start          solved         taps
# S # #        # S # #        r1c0 ┘→└→┌ (2)   r2c2 ┐→┘→└ (2)
┘ ┤ ┌ #        ┌ ┴ ┐ #        r1c1 ┤→┴ (1)     r2c3 └→┌→┐ (2)
─ ─ ┐ └        │ ─ └ ┐        r1c2 ┌→┐ (1)     r3c3 ─→│ (1)
G ┐ │ ─        G ┐ │ │        r2c0 ─→│ (1)
P # # P        P # # P        decoys: r2c1, r3c1, r3c2
```

The split under the spring must be `┴` (it is the only rotation with N, E and W); the left arm drops through the gate, the right arm jogs out to the cliff edge.

**Stage 3 (5×5): the wheel.** 11 taps (the minimum).

```
start            solved           taps
# # # S #        # # # S #        r1c1 ┘→└→┌ (2)   r3c1 ┐→┘→└ (2)
# ┘ │ ┌ ├        # ┌ ─ ┘ ├        r1c2 │→─ (1)     r3c3 │→─ (1)
┐ ─ ┬ ┐ │        ┐ │ ┬ ┐ │        r1c3 ┌→┐→┘ (2)   r3c4 └→┌→┐ (2)
│ ┐ W │ └        │ └ W ─ ┐        r2c1 ─→│ (1)
# # ─ # P        # # ─ # P        decoys: r1c4 r2c0 r2c2 r2c3 r2c4 r3c0 r4c2
```

The mouth can only be fed from the west (a bend cannot pass N-S), so the water must loop left and come back through the wheel. The tempting right-hand split (`r1c4`) leads nowhere: the board teaches that a split is not always the answer.

**Stage 4 (5×6): the full falls.** 14 taps (the minimum).

```
start            solved           taps
# # S # #        # # S # #        r1c1 └→┌ (1)     r3c0 └→┌ (1)
# └ ┬ ┌ #        # ┌ ┴ ┐ #        r1c2 ┬→┤→┴ (2)   r3c1 ┐→┘ (1)
# ─ ├ ┘ ┌        # │ ├ └ ┐        r1c3 ┌→┐ (1)     r3c4 ─→│ (1)
└ ┐ │ ┬ ─        ┌ ┘ │ ┬ │        r2c1 ─→│ (1)     r4c2 ┘→└→┌ (2)
G # ┘ W ┌        G # ┌ W ┘        r2c3 ┘→└ (1)     r4c4 ┌→┐→┘ (2)
P # P # #        P # P # #        r2c4 ┌→┐ (1)     decoys: r2c2 r3c2 r3c3
```

The spring splits at once; the left arm steps down through the gate to the left mouth, the right arm runs out to the edge, back through the wheel and down into the centre mouth. Two mouths and a turning wheel: the whole waterfall in one picture.

Each tap count above is the board's true minimum (checked with an exhaustive search while writing this note); the solver test (§6) keeps it so for every shipped board.

## 4. Rewards

- **No seeds.** Islands never pay seeds (Book One sheets §0, Koke prototype §1); a round on a wonder island pays that island's progress instead of the garden's 2-5 seeds (game plan §5). Nothing in [economy](../product/economy.md) changes.
- **The island changes:** solving the round advances Çağlayan one stage (batch-43): 1 the left steps run, 2 two streams and the pool half full, first warm light, 3 three streams and the wheel turns, 4 the full falls and the rainbow (the signature), then the gift at home (game plan day 14; the map: "Evdeki havuzun çeşmesi akar", the home pool's fountain runs).
- **The end-of-round moment** (about 6 s, no button needed until the end): the last tap → water rushes through the whole channel (1.2 s) → the board's stones slide away and the camera is back on the island → the stage's 3-6 s eased reveal (the new stream pours down the plate in the same path shape as the last board, which is the point) → Damla's beat (one line; stage 4 wordless) → one "Tamam". No score, no time, no "next".
- Between boards inside a round: a 1 s pour and splash, then the next board slides up. No result screen in between.

## 5. Juice and accessibility

**Water:** a code-drawn ribbon along each wet tile's channel centreline, advancing at about 8 tiles a second from the newly connected tile, with a scrolling highlight; spills are a 0.6 s dribble sprite on the bank edge. The wheel's paddles turn while wet (art: 1 frame, code rotates it).

**Haptics** (reuse `GardenHaptics` levels): a tap = soft click; a new tile wetted = light; a wheel or mouth reached = medium; solved = the garden's success pattern; a tap on a fixed tile = none.

**Sound** (reuse `GameSound`): a stone click per tap; a trickle per newly wet tile, pitched up one step per tile in the same pour (a rising run, the pour you can hear); a wheel creak that settles into a slow loop; a splash at a mouth; the full pour at solve. All under the sound identity's quiet ceiling; the game is fully playable muted.

**Colour-blind safe:** wet vs dry is shown by **shape and motion** first (the water ribbon fills the channel and moves; dry channels are empty grooves), colour second. Targets are distinct shapes (mouth, wheel), not colours. Checked with a greyscale screenshot.

**One-handed:** the board sits in the lower two thirds; undo and hint at the bottom corners; nothing needs a second finger or a drag.

**VoiceOver:** each tile is an element: "Bend, opens north and east, dry, row 2 column 1"; the default action turns it and announces the new openings and anything newly wet ("Water reaches the wheel"). The board has a rotor summary ("2 of 3 targets wet"). Undo and hint are buttons; the hint is also spoken. Reduce Motion: the pour becomes a crossfade.

## 6. Engine plan for `PofuGames`

**Pure model** (`Core/`, Linux-tested, no UIKit):

- `FlowDirection` (OptionSet N/E/S/W, `rotatedClockwise`), `FlowTileKind` (`straight, bend, split, source, mouth, wheel, gate, rock, grass`), `FlowTile` (kind, rotation 0-3, `isFixed`, `openings`).
- `FlowBoard` (width, height, tiles; `rotate(at:)`; parse from and print to the glyph rows above).
- `FlowSolver`: `wet(board) -> Set<Cell>` (BFS over facing openings), `isSolved`, `spills`, and `minimumTaps(board)` (backtracking over turnable tiles' distinct rotations, pruned by a partial flow check; boards ≤ 35 cells and ≤ 16 turnable tiles are instant).
- `FlowHint.next(board) -> Cell?` (nearest-to-frontier tile that differs from the nearest solution).
- `FlowRound` (the round's boards, current index, undo stack, `tap`, `undo`, `ending`), a value type like `GardenRound`, saved mid-round.

**Puzzle format:** one bundled `Resources/flow-boards.json`: `{id, island, stage, order, skin, rows: ["# S # #", ...]}` in the glyph notation, so a board is readable and diffable in review. `content/` stays the art pipeline's. **Hand-made, 16 boards**, no generator.

**Tests:** rotation (four taps = identity; straights have two states); the BFS on fixtures (a split feeds both arms; a spill never counts); every shipped board parses, is not solved at the start, is solvable, and its minimum taps sit in the stage's band (§3 table ± 1); every board has exactly one source and at least one target; the hint is always a turnable tile on some solution; undo restores the exact board; the round advances the island only when every board is solved.

**Views:** `FlowGameView` (SwiftUI shell: Damla or Pofu in the corner, undo, hint, the pour-out) + `FlowScene` (SpriteKit, like `GardenScene`: tiles as sprites, water as code-drawn paths) + `FlowGameModel` (bridges, owns the frame policy). **Battery:** the scene is paused when settled (0 Hz); it unpauses only for a turn, a pour or a wheel spin, and the wheel stops being animated 4 s after its last change (a still image of a turning wheel, motion-blurred, is drawn instead). Thermal 30 fps, as the garden.

**Skins:** `FlowSkin` (water, light, thread) maps tile kinds to art ids and sound sets; the model never knows the skin.

**How the island invokes it** (like Koke, Koke prototype §2): `WonderIslandID.caglayan`; `CaglayanScene` in `PofuWorld` shows the plate for the stage and Damla; tapping the dry steps or Damla on a day that can advance opens the round as a full-screen cover (as the garden opens from the station sheet's Play); finishing it sends `tendedWonder(.caglayan)`, which `WorldClock` already routes to `WonderIslands.advance`. On other days Damla's line says the water will wait for a quiet day.

## 7. Art list for Codex (`batch-64-flow-pieces`, proposal)

Square tiles, 256 × 256, top-down at a slight tilt to match the plate, soft painted stone, the water channel as an empty groove (code fills it).

| Id | What |
|---|---|
| `flow-tile-straight`, `-bend`, `-split` | carved cream stone, groove only, one orientation each (code rotates) |
| `flow-tile-gate` | stone with a wooden sluice board, carved rim |
| `flow-tile-source` | a spring mouth in mossy rock |
| `flow-tile-mouth` | the channel's end where it meets the pool |
| `flow-wheel` | the mill wheel, top-down, one frame |
| `flow-rock`, `flow-grass` | boulder, grass bank (2 variants each) |
| `flow-frame-caglayan` | the board's surround: cliff lip at the top, pool rim at the bottom |
| `flow-splash`, `flow-dribble` | small water sprites, 4 frames each |
| `damla-point` | a rig edit of `damla` (batch-43 canvas): paw pointing |

**Code draws:** the water ribbon and its highlight, wet darkening of the stone, rotation, the wheel's spin, the hint ghost, the pour-out, the board slide. Light and thread skins (`flow-prism`, `flow-chain`, `flow-thread`) are already listed in batches 53 and 55.

## 8. Open risks

1. **Too easy to be satisfying, or too fiddly to be cozy.** Test: the four boards above as a code prototype with grey tiles, five people, timed; pass if each board is 15-50 s and nobody uses more than two hints.
2. **"Water runs both ways" breaks the falling-water fantasy.** Test: in the same session ask "did anything look wrong?"; if water climbing back up a channel is noticed, animate wet ribbons from the source outward only (the rule stays).
3. **The skins feel like a repeat** (Book One sheets §3.5). Test: the prism board on Çağlayan's engine, as planned there; keep it only if a tester notices the difference.
