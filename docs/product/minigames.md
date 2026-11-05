# Island Minigames: Proven Mechanics, Pofu's Spice

> **Superseded in part (2026-11-05):** three engines only (place, connect, recall), per [game plan §5](game-plan.md#5-the-three-games); the station-island archipelago it builds on is retired ([ADR-0019](../adr/0019-home-cluster-and-wonder-islands.md)). The mechanics research still holds.

Status: **proposed**, with a vertical slice in code (`PofuGames`, the
Ayçiçeği garden). Builds on the archipelago system proposal
(`docs/archive/archipelago-system.md` on the unmerged `docs/archipelago-system`
branch; §4: rounds of 30–90 s, sets of five, no failure, small yields) and the
[UI system v2](../design/ui-system-v2.md) (the game layer is crafted;
pause is native glass).

## 0. The answer

The founder (2026-11-02, translated): *"The minigame must be a real
minigame, something that has genuinely caught on and is fun. It doesn't
matter if it's a copy — if needed let it be Block Blast — something proven
fun, built professionally, with our own spice. Quality, harmony, elegance
and playfulness matter."*

**Ayçiçeği's game is a block puzzle** (the 1010! / Block Blast family):
drag plots of sprouts from a wooden tray onto an 8 × 8 garden bed; a full
row or column **blooms into sunflowers**, whose seeds arc into **Pofu's
cheek pouches** while Mochi hops and Fındık rolls. It is the most proven
one-thumb casual mechanic of the decade, it fits a 60-second round with a
natural end, and its art is cheap. Its stickiness is real, so Pofu keeps
the mechanic and drops the engine of compulsion: **a round is a bag of 18
plots, not "until you lose"; there is no score and no best; it pays 2–5
seeds; five rounds make a set; rounds are earned by resisting reaches.**

This replaces the archipelago doc's "Mochi's tea orders (Serve)" for
Ayçiçeği; Serve moves to a later island (§8).

## 1. Proven mechanics compared

Scores 1–5 (5 best for Pofu). "Session fit" is how naturally a 30–90 s
round with a kind ending falls out of the rules. "Risk" is addiction risk
**as usually shipped** (5 = lowest risk).

| Mechanic (exemplars) | Fun, first minute | Depth over weeks | Session fit | One thumb | Art cost | Risk | Notes |
|---|---|---|---|---|---|---|---|
| **Block puzzle** (1010!, Block Blast, Woodoku) | 5 | 4 | 4 (a bag of N pieces ends it) | 5 | 5 (tiles + one bloom) | 2 | Instantly readable; every placement is a small decision; line clears are the most satisfying "pop" in casual games. Sticky because of endless mode + score chase + near-misses |
| **Merge-drop** (Suika, 2048) | 5 | 3 | 2 (ends only on overflow; a round is minutes) | 5 | 4 | 2 | Physics merges are hilarious, but a round has no natural length and skill is shallow; 2048 is dry |
| **Match-3** (Candy Crush, Royal Match) | 4 | 4 (only with levels) | 4 (move limits) | 5 | 1 (needs hundreds of authored levels, boosters, specials) | 1 | The genre's fun is built on level design and monetized frustration; the most expensive to make well |
| **Sort puzzles** (Water/Ball Sort, Goods sort) | 3 | 2 | 4 | 5 | 4 | 3 | Calm and finite, but solved rather than played; repetitive after a week |
| **Wordle-style daily** | 4 | 3 | 5 (one a day) | 4 (keyboard) | 5 | 5 | Wonderful ritual, but one puzzle a day cannot be a round you earn several times; language-bound (TR and EN need two dictionaries) |
| **Tile-matching** (Mahjong solitaire, Triple Tile / Tile Busters) | 4 | 3 | 4 | 5 | 3 (a tile set per island) | 3 | A strong candidate for a later island; the "slot bar fills up" fail state must be removed |

**Why the block puzzle wins for Ayçiçeği.** It scores highest on fun ×
fit × cost, it has depth without levels (the generator is the level
designer), it is readable in one round without text (archipelago rule 2),
and its single "pop" (a full line) maps perfectly onto Pofu's world: a
garden row that blooms. Its one weak score, risk, is the part we control
by design (§4).

**Copying, honestly.** Game mechanics are not protected by copyright;
trade dress is. We take the rules (grid, tray of three, line clears,
combos) and nothing of Block Blast's look: no glossy bevelled jewel
blocks, no dark blue board, no fonts, sounds, piece colours, score
displays or "Good/Great/Excellent" words. Ours are clay garden plots with
sprouts on a soil bed with a peach-stone rim, a honey-wood tray, painted
sunflowers and our own characters.

## 2. Pofu's spice

| Proven element | Pofu's version |
|---|---|
| Blocks | **Plots of sprouts**: clay tiles glazed in six garden colours (sage, honey, terracotta, lilac, mint, rose), each with an embossed sprout; a shape always wears the same glaze |
| Board | **The garden bed**: soil cells in a sunken bed with a peach clay rim (sampled from the garden station's art) |
| Line clear | **A bloom**: the row's sprouts burst into sunflowers (the painted heads from garden level 1), sweeping out from where the plot landed, petals flying, one pentatonic kalimba note per step |
| Score | **Seeds into Pofu's cheeks**: half the blooms release a seed that arcs into Pofu's mouth; he gulps; his cheeks widen and blush with the round's yield (the cheek-pouch idea, ui-system-v2 §5.2.1) |
| Combo | **Warmer and warmer**: bigger overshoot, more petals, higher notes, words warming from honey to coral to violet ("Çifte çiçek!", "Bahar geldi!", "Kombo ×3"); Mochi hops at every bloom, Fındık rolls up like a hedgehog at a double bloom or a combo, Pofu hops at a combo of three |
| Game over | **Harvest**: when the bag is empty or nothing fits ("Tarh doldu!"), every remaining sprout blooms row by row and the card comes. Never "game over" |
| Next game | **"Sonraki tur"** inside a set; after five rounds the primary is **"Bugünlük yeter"**, and another set is plain text only if earned rounds are banked |

## 3. Rules of a round

- 8 × 8 bed, a tray of three plots, pieces never rotate (the genre's
  pace depends on it). A new tray is dealt when all three are planted.
- 39 shapes in 13 families (single to 3 × 3), picked by family weight so
  an eight-orientation family is not eight times as common.
- **A round is a bag of 18 plots** (six trays, about 45–75 s at the
  genre's 2.5–4 s a placement). It ends when the bag is empty, or kindly
  earlier when nothing in the tray fits.
- **Fair generator** (`PieceGenerator`, tested): every tray has a plot
  that fits (a single sprout always does, since a full row clears);
  mercy weights shift to small plots as the bed fills past 45 %; a
  helping hand includes a blooming plot 35 % of the time when one exists;
  no tray repeats a shape. Seeded (SplitMix64): a round replays from its
  seed.
- **Combo**: consecutive blooming placements, cooling after three quiet
  placements.
- **Forgiving snap**: the rounded cell if it fits, else the nearest
  fitting origin within 0.9 cells; a ghost shows where it lands and the
  cells of every line it would bloom glow honey and breathe.

## 4. Healthy by design: why Block Blast is sticky, and why this is not

| Block Blast's hook | Effect | Pofu |
|---|---|---|
| Endless mode: play until you jam | Sessions have no end but failure; "one more" after each loss | A bag of 18 plots; the round ends whole, and a jam is a harvest, not a loss |
| A score and a best score | A number to beat, forever | No score, no best, no leaderboard (A22). The yield is 2–5 seeds, capped |
| Near-miss jams | The loss feels unfair and almost won: replay | No loss to almost avoid; the generator is kind when crowded |
| Instant restart | Zero friction into the next game | "Sonraki tur" is a deliberate tap on a card; no countdown, no auto-start (A23); after five, "Bugünlük yeter" is the primary |
| Unlimited plays | Play is free and infinite | Rounds are **earned** by resisting reaches (archipelago §4.2): 2 a day baseline, +1 per resisted reach (6 max), at most 12 played a day; the cap drops automatically if play looks like a new reflex (A26) |
| Ads and revives between games | Monetized frustration | None, ever |

Upper bound: 12 rounds × 75 s ≈ 15 minutes a day; a typical day is one
set (about 5 minutes), inside the archipelago's revised guardrail A10′.
A round is also offered once as the substitute right after a resisted
reach (A25), which is where a satisfying 60 seconds does the most good.

## 5. Yield, calibrated

`SeedYield`: 2 seeds for playing (no failure), +1 at 3 lines bloomed,
+1 at 7, +1 for a good round (a double bloom or a combo of 4), at most 5.

A Python twin of the rules simulated 300 rounds per player:

| Player | Mean seeds | Distribution (2/3/4/5) | Lines | Ended full |
|---|---|---|---|---|
| Greedy expert (the autoplayer) | 4.1 | 0 / 21 % / 48 % / 31 % | 6.1 | 0 % |
| Random placement | 2.5 | 66 % / 20 % / 14 % / 0 % | 1.7 | 72 % |

Archipelago §7.3 expects about 4 a round; a real player lands between
the two. The rival schedule ([3, 6] lines, combo 3) paid the expert 5
in 74 % of rounds: no headroom, so it was rejected. `GardenRoundTests` asserts
the autoplayer's mean stays in 3.3–4.8.

Seeds go into Pofu's cheek pouch ("+3 yanaklarına") and are credited
through `RoundLedger` in `PofuCore` (`WorldClock.playRound`): the yield
(capped at 5) lands in the pouch as `SeedPouch.rounds` and reaches the jar
with the next Collect. The ledger banks rounds: 2 a day for everyone, +1
per resisted reach (at most 6 a day), at most 12 played a day, none at
night (A21); unplayed rounds never expire. The Rehearsal entry plays the
rounds earned so far.

## 6. Engine: SpriteKit, in a new `PofuGames` module

**SpriteKit**, embedded in SwiftUI. Reasons:

- A real game loop: frame-locked `update`, 120 Hz on ProMotion
  (`preferredFramesPerSecond = 120`, `CADisableMinimumFrameDurationOnPhone`),
  nodes, textures, actions with custom timing functions, cheap
  particles. SwiftUI `Canvas` + `TimelineView` could draw it, but hit
  testing, z-ordering, per-node tweens and pause/slow motion would all be
  hand-rolled.
- Zero dependencies, ships with iOS, and its rendering is Metal. The
  island (`PofuWorld`) stays SwiftUI; the game is a separate surface, so
  the two engines never share a frame.
- Rejected: **SwiftUI only** (above), **Metal directly** (weeks for no
  visible gain at this scale), **Unity/Godot** (a second app runtime,
  tens of MB, a bridge to SwiftUI and the economy: wrong for a 60-second
  round).

The scene is hosted in our own `UIViewRepresentable` around `SKView`
rather than `SpriteView`, to set the frame rate and sibling-order
rendering and to give the model the view for pausing and snapshots.

**Shape.** `PofuGames/Core` is pure and runs in `swift test` on macOS:
`GardenBoard` (a 64-bit bitboard), `PieceShape`/`PieceCatalog`,
`PieceGenerator`, `GardenRound` (the state machine), `GardenSet`,
`SeedYield`, `GardenAutoplayer`, `GardenLayout`. `PofuGames/Feel` holds
the tunables (`GardenFeel`), easings (`GameEasing`), `ShakeBudget` and
the sound cues (`GardenSoundCue`, `PentatonicLadder`). `Scene` and `UI`
are iOS only. One scene clock (advanced in `update`, scaled by `speed`)
drives every delay, so pausing the view pauses everything and slow
motion is exact.

## 7. Feel ("juice")

| Moment | What happens | Numbers (`GardenFeel`) |
|---|---|---|
| Pick up | The plot grows from tray scale 0.52 to 1 with a small overshoot, a shadow appears under it, light haptic | 0.12 s, `outBack(1.2)` |
| Drag | It floats `1.6 cells + half its height` above the finger, follows with exponential smoothing (stiffness 38/s) and tilts slightly with motion; Pofu leans toward it | — |
| Snap | Ghost at 42 % on the landing cells; honey glow breathing on every line it would bloom; a selection tick per new cell, at most every 60 ms | glow 0.5↔0.8, 0.42 s `inOutSine` |
| Drop | Tiles glide to their cells, then one decaying squash (1.14 × 0.86 → 0.96 × 1.05 → 1), crumbs kick out from the bottom edge, medium haptic | 0.07 s `outCubic`, squash 0.2 s |
| Miss | Back to its slot with a soft overshoot | 0.24 s `outBack(1.1)` |
| Bloom | Cells pop into sunflowers sweeping out from the drop (Chebyshev distance), overshoot rising with the combo, 3–7 petals each, a sparkle every third; one rigid haptic for the whole bloom, stronger with lines and combo | stagger 0.045 s/step, pop 0.24 s `outBack(1.7→2.8)`, hold 0.26 s |
| Seeds | Every other bloom releases a seed on a quadratic arc into Pofu's mouth; he gulps (squash, soft haptic, rationed to one per 0.14 s); the HUD counts up when they land | 0.5 s `inQuad` |
| Words | "Çifte çiçek!" (2 lines), "Bahar geldi!" (3+), "Kombo ×N" (2+), warming with the combo | pop 0.3 s `outBack(2.2)` |
| Shake | Only for a double bloom or a combo of 3; ≤ 4 pt; never within 1.2 s of the last; never with Reduce Motion | 6 steps × 32 ms |
| Deal | New plots pop into the tray one by one | 0.3 s `outBack(1.4)`, stagger 0.07 s |
| Round end | Every remaining sprout blooms row by row, the residents cheer, then the paper card with Pofu peeking, cheeks as wide as the yield, "+N yanaklarına" counting up, success haptic | — |

**Sound.** `GardenSoundCue` hooks are called on every moment above; the
default player is silent until `PofuAudio` exists (sound identity §5).
Blooms climb **D major pentatonic** (`PentatonicLadder`), one note per
sweep step, starting higher with the combo, capped two octaves up.

**Reduce Motion.** No shake, no hops or rolls, no squash, no arcs (seeds
fade at Pofu), blooms fade in place, words fade; the haptics stay.

**Easings** are pure functions (`GameEasing`, tested) applied as
SpriteKit timing functions, so a SwiftUI twin can use the same curves.

## 8. Other islands: a different proven mechanic each

Each island borrows a different proven verb, skinned in its own world,
with the same rules: earned rounds, a natural end, a small yield, no
failure, no score.

| Island | Proven mechanic | Pofu's spice |
|---|---|---|
| **Ayçiçeği** | Block puzzle (1010!, Block Blast) | Garden plots bloom into sunflowers; seeds to Pofu's cheeks |
| **İskele** | Sort puzzle (Goods sort, Ball Sort) | Sort parcels, simit and tea crates onto the vapur's shelves by colour before it sails; the round ends when the ferry horn blows (a fixed number of moves) |
| **Çağlayan** | Path-connect (Flow Free, Pipe) | Rotate travertine channels so leaf boats reach the pools; a solved pool lights the waterfall |
| **Kaplıca** | Serve and remember (the archipelago's "tea orders", Cooking Fever without timers) | Mochi's tea and the spring's visitors' orders, by memory, no clock |
| **Yıldız** | Connect-the-dots / one-line drawing | Draw a constellation in one stroke; it becomes the star's story |
| **Koke** | Tile-matching (Mahjong solitaire, Triple Tile) without the fail bar | Rake and match moss stones in threes; the garden grows greener with the micro-season |
| **Çanlar** | Simon / rhythm echo | Ring back the bell phrase, in the island's mode |
| **Çömlek** | Merge (Suika, Merge Mansion) | Merge clay into larger pots on the wheel; a round is a fixed lump of clay |
| **Emanet** | Daily deduction (Wordle-style) | One "who lost this?" a day from three clues; the rare once-a-day island |

**Tuning.** Every number above lives in `PofuTuning`'s `tuning.json`
under `garden` (`TuningValues.Garden`, read through `GardenFeel`). In
Rehearsal mode the Ayar panel's **Bahçe** section changes them while the
game plays (an "Ayar" pill sits over the garden), and "Dışa aktar"
exports the changes for the agent to commit as new defaults.

## 9. What is built, and what is next

Built in this slice: the rules and their tests, the SpriteKit scene with
the juice above, the crafted HUD and cards, the glass pause, Turkish
copy, the Rehearsal entry ("Bahçede oyna" in the Prova panel, five
rounds), and simulator screenshots (mid-round, bloom, combo, round end,
set end, a slow-motion bloom sequence).

Feel round 2 added: every feel number in the Ayar panel; larger tray
plots with no dead band under the bed; a glow that adds light; more and
larger seeds with a "+1" that arcs to the seed plate; Pofu's painted
cheeks-puff pose (batch 06) fading in with the yield; the round ledger
and crediting; the harvest-to-card screenshots and the `07-garden-round`
motion beat.

Next, in order: tune feel on the founder's iPhone with Ayar; the painted
art below; the "Oyna" door on Ayçiçeği; `PofuAudio` behind the cues;
VoiceOver play (§10).

### Art queue: painted tiles for the garden

The game's surfaces are drawn stand-ins. Art bible, crafted layer
(ui-system-v2 §3.1), transparent PNG, no text, no ground shadow:

| # | Asset | Size (master → in game) | Notes |
|---|---|---|---|
| 1 | `game-plot-tile` ×6 glazes (sage, honey, terracotta, lilac, mint, rose) | 512² → 41 pt | One clay tile with a soft top light and a darker lip, a small sprout embossed; one master, the glazes as edits so they match |
| 2 | `game-soil-cell` | 512² → 41 pt | Empty soil mound with two crumbs; must read darker than any glaze |
| 3 | `game-bed-rim` | 9-slice, 1024² | The peach clay stone rim of the garden station, as a frame |
| 4 | `game-bloom` ×3 variants | 512² → 44 pt | Sunflower heads facing slightly left, front, right; one with a bee-size gap in the petals; replaces the cut from garden L1 |
| 5 | `game-combo-stamp` | 512² → 120 pt | A round paper stamp with a sunflower, blank centre for the live word ("Çifte çiçek!", "Kombo ×3") |
| 6 | `game-seed` | 256² → 18–28 pt | The painted seed (the vector twin stays below 28 pt) |
| 7 | `ui-game-tray` | 9-slice | Honey-wood tray (already listed in ui-system-v2 §D) |

## 10. Self-critique

- **No one has played it.** Everything here was tuned without a device;
  feel lives in the hand, and the first 30 minutes on the iPhone will
  move half the numbers in `GardenFeel`.
- **The plots are drawn, not painted.** Clay tiles from Core Graphics
  are clean but read "vector" beside painted Pofu; the art bible wants
  painted faces with live state on top.
- **Pofu's cheeks are a crossfade**, base to the cheeks-puff pose; a
  real puff (squash into the pose, a gulp frame) needs the rig.
- **Silent.** Half of a bloom's satisfaction is sound.
- **VoiceOver cannot play.** Dragging has no accessible alternative yet
  (select a plot, then a cell, with the preview spoken); rule 5 of the
  archipelago's games is not met.
- **Stickiness is reduced, not removed.** A satisfying 60 seconds is
  still a pull; A26's automatic step-down and the measurement in
  archipelago §6.3 must ship before the friends beta, not after.
