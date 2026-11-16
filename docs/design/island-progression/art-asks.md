# Art asks for island progression v1

For the lead to turn into manifests and queue. Design:
[../island-progression-v1.md](../island-progression-v1.md). Order of work:
A, then B; C and D after the founder's answers. Batch 129's rework stays
blocked until pilot A is judged; if A passes, 129 is dropped.

House rules that apply to every job (from `QUEUE.md`): one object per
picture, paint only what is named, the size and place asked for, edits keep
what is there.

## A. Plot pilot: the windmill and the pond, in place, last form first (10 jobs)

Why: proves section 5.5. Two stations that differ: one tall, one flat and
all ground.

Preparation by script (no generation): from Home's erased base at island
level 10, day (`batch 117`), cut each station's plot with the ground round
it (about 1.6 times the station's widest form) and enlarge it to 1536 x
1536. Attach to form 5: this bare crop, and the same crop of the level 10
plate as the identity reference (role: style and position only).

| Job | Edit of | Paint |
|---|---|---|
| `x-plot-windmill-5` | the bare windmill crop | **Büyük Değirmen**: the stone mill at twice the plate mill's height, a wooden gallery round its middle, four cloth sails with a small lantern at each tip, a bakery wing with an oven chimney on its right, a paved yard with sacks. It stands on the crop's own grass in the crop's light. |
| `x-plot-windmill-4` | windmill-5 | Remove the upper half of the tower, the gallery and the sail lanterns: **Fırınlı Değirmen**, the mill at the plate's height with the bakery wing and its chimney. |
| `x-plot-windmill-3` | windmill-4 | Remove the bakery wing and its paving: **Yelkenli Değirmen**, cloth sails, a small open sack store, a trodden path. |
| `x-plot-windmill-2` | windmill-3 | Remove the cloth from the sails and the sack store: **Değirmen**, the bare stone tower with plank sails on plain grass. |
| `x-plot-windmill-1` | windmill-2 | Remove the tower: **Rüzgâr Gülü**, a small wind wheel on a wooden post beside one millstone on the grass. |
| `x-plot-pond-5` | the bare pond crop | **Nilüfer Gölü**: a wide lily lake that reaches the island's edge and spills over it in a thin fall, a small roofed pavilion on an islet, an arched wooden bridge to it, lanterns on the bridge, a deck with a rowing boat. No fountain. |
| `x-plot-pond-4` | pond-5 | Remove the pavilion and its islet and the fall at the edge: **Köprülü Gölet**, the bridge now crosses the pond's narrow end. |
| `x-plot-pond-3` | pond-4 | Remove the bridge and lanterns: **Kayıklı Gölet**, the deck, the boat, and a stream that runs across the lawn into the pond. |
| `x-plot-pond-2` | pond-3 | Remove the deck, the boat and the stream; the pond half as wide, with tall reeds on one side: **Gölet**. |
| `x-plot-pond-1` | pond-2 | Remove the reeds; a small ring of pale stones with clear water: **Gölcük**. |

Review, in this order:

1. `python3 -I tools/art/big_step_check.py` on the cut forms, lowest first:
   every step BIG.
2. In place: each form pasted through its feathered plot mask onto the
   base, in a 1206 x 2622 frame at mid and at near, beside the plate's own
   station at 1:1: no pasted edge, chroma within 15% of the plate with no
   grade.
3. The ladder: what remains after each removal has not moved (the foot
   within 10 px on the 1536 crop).
4. `tools/art/matte_check.py --kind look` on each cut.

## B. Nazlı, rig pass 2 (about 14 jobs)

Why: section 4.2. She is seen at 330 pt on Sefer, the largest character on
any screen. Parent: `nazli-body` (batch 37), same three-quarter view, same
1536 x 1024 canvas so parts register.

- Body with the lantern scar moved to the middle of her back beside the
  hook (so mirroring her is true), no fins, no tail.
- Tail stock and fluke as two pieces, the fluke the size of batch 22's
  form 1 (the pilot tail is too small to read as the thing that drives her).
- Near fin, far fin, each whole to its shoulder.
- Eyes: open (rested), half (tired), closed, glad.
- Belly mist skirt, soft, wider than the body.
- Blow: a cloud ring; the same with a small rainbow.
- Back patch level 1 (as shipped), then one piece each as its own layer:
  the soil mound with a young sunflower; the pool and the fall down her
  flank (with a flow strip for the app's water); the aurora jar on the
  bench post; the teal plank deck with a letterbox and a pennant mast; the
  moon stone.
- Hook, lantern unlit, lantern lit, mooring rope.

Review: parts register within 1 px on the body; each back piece passes
`big_step_check.py` against the patch before it (the deck and the fall
must; the jar and the stone are judged by their light, in a night frame).

## C. After the founder's answers

- **Sefer target frame** (2 takes): a paint-over of
  `frames/sefer-1.webp`, nothing moved, for the sea, the haze and the light
  only, as batch 112 did for the Map.
- **The other six stations**, as pilot A, with section 5.3 as content
  (30 jobs).
- **Tam Çiçek, new** (day, golden, night): the level 10 base with all
  eight form-5 crops in place as the layout, painted as one picture.
- **Night forms**: the same crops at night with their lights, forms 4 and
  5 first.

## D. Later

- Nazlı form 2 as a rig on the same parts.
- Repaints of the healing steps that fail the plate check (Çağlayan 3 to 4
  first).
- Island grounds for levels 2, 4 and 6 if they fail the plate check.
