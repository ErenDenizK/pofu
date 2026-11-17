# The concept round: four topics as one design (2026-11-18)

**Status:** Fable's plan for the concept-first round (founder-input 40 and
41). No app code and no web prototype in this round. The Codex jobs are in
pofu-art PR #123 (batches 138 to 145, 88 jobs, rows D1 to D8 of its
`QUEUE.md`). Until the founder picks from the frames, no code is written on
a topic.

## 1. The one idea: a lid and a body

Everything the player loves in this world already has the same anatomy: **a
living lid on a soft body.** The home island is a lawn on a body of peach
rock. Nazlı is a patch of lawn on a body of cloud. The founder's drawing of
the stream board is the same thing in small: a lid of grass on a body of
stone. The four topics are one design if each of them keeps to it:

| Topic | The lid | The body | What grows |
|---|---|---|---|
| Home island and its stations | the lawn, and each station on its own small plot | peach rock | each station, upward |
| The stream board | grass on every block | stone sides and rim | water arrives; flowers open |
| The level-up panel | a thin crafted lip (stone and grass, or the station's own cloth) | glass | one level mark |
| The Gezgin | the patch on her back | cloud | one piece per healed island |

Two rules follow, and they are what makes the parts fit instead of each
being average on its own:

- **Glass carries words; crafted things carry the world.** A crafted part
  is always a piece of the lid (stone, grass, wood, cloth), never a painted
  button. This is the "blend" in one sentence, and it is the same on the
  board's controls, the panel and the island chooser.
- **Growth goes up and gets brighter; it never spreads.** A station, the
  Gezgin's patch and a level mark all grow the same way. This is why the
  windmill's ladder is good and the pond's was not.

## 2. Where the topics touch

- **Panel and stations.** The panel exists to get out of the way of the
  island growing, so the two are judged in one frame: batch 139 paints the
  panel over the island, batch 141 the island's own film.
- **Stations and the Gezgin.** The pier is a station and her berth. Where
  she lies at home (batch 143, `x-moor-*`) decides the pier's ladder and the
  first frame of every voyage (batch 140, `x-voy-a1`, `a3`).
- **Board and panel.** The board's block is also a candidate for the level
  mark (batch 145, `x-level-block`) and for the panel's lid (batch 139,
  `x-panel-card`). If he picks the block on the board, the other two follow.
- **Board and islands.** `x-board-isle` paints the board as a tiny island.
  If that wins, every island's minigame becomes a small island of its own
  place; the garden game is redrawn in the same grammar after the pick.
- **Chooser and Home.** The island chooser is Home seen from farther off,
  not another screen: the same sky, the same whale at the same pier.

## 3. What each concept must show for him to choose

| Topic | The choice | Frames | It is ready to pick when |
|---|---|---|---|
| 1 Board | square key, round dial, or a key that lifts to turn | 138: `key-fall`, `dial-fall`, `lift-fall` | which cells turn is clear without a word; blocks have height and one shared rim |
| | where the toy sits: waterfall, table, tiny island, basin | 138: `*-table`, `isle`, `pool-tray` | it reads as a toy on a surface, and the lawn and rocks are full |
| | how full a full board may be; lush or bold | 138: `*-big`; 144 | a cell is still a thumb wide on a 5 by 6 board |
| 2 Panel | how little panel, and where the crafted part lives | 139: `strip`, `card`, `sign`, `bubble`, `ladder` | the station is whole and unhidden; name, level, yield and one button, under a quarter of the screen |
| | the level mark; the menu ground; the effect language | 145; 139: `moment-*` | the mark reads as a count at 24 pt; glass sits well on the textured ground |
| 3 Voyage | his flow (a1 to a5) or the view from her back (b1, b2) | 140 | the chosen island is clear at a glance; the riders read at phone size |
| | her eyes, her levels, her mooring | 143 | no eye is large or staring; each level changes her outline or light; her back is level with the pier |
| 4 Stations | does the island grow as a whole under the rule | 141: `grow-1` to `5`, stress frames | every step is seen at phone size; no station is wider than at form 2 |
| | the pond's crown: willow, pavilion, lotus | 142; 141: `pond-*` | the shore never moves after form 2; no river, bridge or fountain |

## 4. Where I differ from what was proposed

- **Round or square.** A third answer is in the frames: the square key is
  lifted, turned and set down. It keeps the square's beauty and makes the
  turn honest. My pick until the frames say otherwise; it replaces my dial
  pick in `board-and-sheet-v1.md` (#507).
- **"She comes to the main island."** If she lives at Home's pier (his own
  idea in founder-input 39), she is already there: choosing an island cuts
  straight to the boarding. One trip less, and she is part of Home.
- **A flat row of islands.** Side by side is right for swiping; `x-voy-c-route`
  keeps the swipe but shows the islands in depth with a route of cloud from
  her to the chosen one, so the menu is the world.
- **The pond.** The overgrown pond was my own ladder (#503, section 5.3:
  a stream, a bridge, a pavilion on an islet). It is withdrawn. The rule in
  section 1 replaces it for every station, and every ladder is from now on
  reviewed in the whole island, not in a crop.
- **Her eyes.** The prototype failed because it showed her from the front.
  Besides better eyes, the camera never looks her in the face: side-on at
  the pier and in flight, from behind on her back.

## 5. Order, and what happens after

Codex runs D1 to D4 first (one batch per topic: 138 board, 139 panel, 140
voyage, 141 island), then D5 to D8 (142 pond, 143 Gezgin, 144 blocks, 145
materials). Batches are independent, so several can run at once.

The lead sends him, per topic, one sheet of the cropped frames with the
choices of section 3 named on it. After a pick: the picked frame becomes
the reference that every production job of that topic attaches; the topic
is built native and shown to him as a frame or a build. Not started before
the picks: ladders for the other six stations, the pier's forms, the
garden game's redraw, any board or panel code.
