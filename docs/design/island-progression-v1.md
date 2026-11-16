# Island progression v1: the voyage, the whale and big steps

Fable, 2026-11-16, for the brief
`docs/studio/briefs/fable-2026-11-16-island-progression.md`. Status:
**proposal**. Nothing here is built except the check tool and the
prototype. The decisions that change the system are in section 10, for the
founder.

- Touch prototype (open it on the phone):
  <https://claude.ai/artifact/5tytV7pXyX2GdMWHdTCqwt> (private; the lead
  shares it). Source: [island-progression/prototype/](island-progression/prototype/index.html).
- Frames at device size: [island-progression/frames/](island-progression/frames/).
- Art asks: [island-progression/art-asks.md](island-progression/art-asks.md).
- The measure as a tool: `tools/art/big_step_check.py`.
- Proposed ADR: [0028](../adr/0028-the-far-view-is-a-voyage.md).

Words: **Sefer** is the proposed far view (in code, `voyage`). A **form** is
a station level that has its own name and shape. IL is the island level.

## 0. The whole proposal on one page

Three causes sit under the founder's three complaints, and each has one
answer.

| He said | Cause | Answer |
|---|---|---|
| The main island is too high, 60% of the screen is cloud, the islands are far from the thumb | A flat island in a tall screen covers a quarter of it. A far view that holds every island in one still frame must shrink them all. | **The far view becomes a voyage.** One island ahead at 300 pt, the next ones at the edges, Nazlı large in the foreground, the verb at the bottom. The world moves under her when you drag. |
| The islands in the background are almost invisible; we have no solution for the world between islands | Nazlı is the road in the story and a 108 pt decoration in the app. The space between islands has nobody in it. | **Nazlı gets her job.** She arrives in three beats, moors under Home's harbor, carries the duo, and grows with each island. Home's sky shows the player's own islands at 80 to 110 pt. |
| Each upgrade must feel big, not "a little flower beside it"; island and stations must be one thing | The ladder was written as ornaments, and a station's picture is painted apart from the island it stands on. | **Five named forms per station, each passing a measured test**, painted in place on the island's own picture and cut from it, last form first. |

What it costs: one new screen in place of the Map (the camera rail, the
cloud kit and every island's art are reused), a rig view for art that
already ships, and an art batch about the size of the one on hold.

## 1. What is wrong, measured

All numbers are from `screenshots/main` at 2a0a630 (402 x 874 pt) and from
the art repository; the method is in
`docs/research/island-progression-2026-11-16/art/frames.md`.

**The Map.** On day 13 Home is 221 pt wide, Köke 145 pt, Çağlayan 131 pt.
63% of the cloud sea holds nothing, and the lowest 23% of the screen, where
the thumb rests, is bare cloud. When Köke appears Home shrinks by 20%. On
day 1 the Map shows Home alone. Book One has eleven places; the frame was
laid out for six. No arrangement of a still frame fixes this, because the
two things asked of it pull apart on a tall screen: a picture with depth
makes far things small, and a board with large targets has no depth.

**Home.** The island covers rows 0.33 to 0.57. Rows 0.57 to 0.72 are empty
cloud. The far isles in the sky are 28 to 50 pt and are not the player's
islands: they are four generic isles and the grown whale, baked into the sky
from day 1 (which also shows the finale's whale on the first day).

**Station levels.** I ran the new check on the tea stall's five looks, the
lead's own picks from batch 123:

| Step | New area outside the old outline | Overlap of the two shapes | Verdict |
|---|---|---|---|
| 1 to 2 | 10.9% | 0.88 | touch |
| 2 to 3 | 0.9% | 0.97 | touch |
| 3 to 4 | 1.5% | 0.97 | touch |
| 4 to 5 | 5.1% | 0.91 | touch |

Not one step is a big step. This is not a painting fault. The ladder in
`home-progression.md` section 4.2 asks for it: "lily pads", "a flag",
"window boxes", "string lights". The founder's sentence describes the
specification.

**Healing stages.** The same tool on Çağlayan's shipped day plates: the
steps change 19%, 21%, 28% and 8% of the picture. The last step, which
should be the grandest, is the smallest.

**The whale.** No code moves her except a glide across Home's sky. Travel is
a camera flight. The five rig parts ship in the app and nothing draws them.

## 2. Sefer: the far view is a voyage

See `frames/sefer-pair.jpg`, `frames/map-today-vs-sefer.jpg` and the
prototype.

### 2.1 The frame

One composition, the same on the first voyage and with eleven islands, so
no step of the game needs a new layout.

| Band (pt, of 874) | What | Size |
|---|---|---|
| 0 to 230 | Sky. Status bar, one glass control top left (home). Calm on purpose. | |
| 150 to 262 | Far lane: what else is known of the ring, in haze | 48 to 104 pt each |
| 271 | Horizon (0.31 of the height) | |
| 340 to 528 | The island ahead, on its cloud bed | 300 pt wide, foot at 528 |
| 330 to 474 | The neighbours, one each side, cut by the screen edge | 236 pt wide, 56 pt or more showing |
| 563 to 762 | Nazlı with Pofu and Mochi on her back, in the near cloud | 330 pt wide |
| 772 | Page dots | |
| 792 to 848 | Glass bar: the island's name, one line of state, the honey verb | verb 94 x 44 pt |

Against today: the destination is 300 pt (131 to 221 today), every control
that matters is in the lower 35% of the screen, and no row band taller than
40 pt below the horizon is without a subject.

The route is a line of slots 235 pt apart. Home is slot 0. The main road
runs to the right, in story order (Çağlayan, Revontuli, Emanet, Mehtap).
Fillers drift in on the left (Köke, Çanlar, Martı Kayası, Fanus, Pervane,
Çömlek), in the order they arrive. An island never changes its slot (the
anchor rule). The next main island that is announced but not open is a
cloud tower with a shape inside; beyond it there is nothing.

An island off centre by `d` slots draws at scale `1 - 0.213 * min(|d|, 1)`
with its foot at `528 - 54 * min(|d|, 1)` pt and slightly paler. These are
the prototype's numbers.

### 2.2 The hand

| Gesture | Result |
|---|---|
| Drag sideways anywhere | The world slides under Nazlı, one to one. She swims: tail and fin speed up, she turns to face the way she goes. Release snaps to the nearest island; a flick moves one island, never more. |
| Tap a neighbour or a far isle | She glides there (0.6 s a slot, 1.4 s at most). |
| Tap the island ahead, or the verb ("İn") | She noses in, the camera pushes to that island's mid stop, she moors. 1.1 s. |
| Tap the home control | She glides to Home. |
| Pinch out from mid, or tap Nazlı at her mooring | Opens Sefer with the island you were on ahead. |

When Sefer opens she is already turning toward the island where something
waits (a healing step, a visitor, a new stage). That is the story's "Nazlı
sessiz olan yere gider" as a mechanic, and it means the usual trip is one
drag or none, then one tap.

The verb is the only honey button. It reads "İn"; on Home "Eve in"; on a
veiled tower it is disabled and the state line says why, with no timer.

VoiceOver: the route is one adjustable element (swipe up and down changes
the island, the value is its name and state); the verb is a button. Reduce
Motion: islands cross-fade between slots and Nazlı only breathes.

### 2.3 The camera

The rail of ADR-0027 keeps three stops. The stop at z 0 is Sefer in place of
the Map; mid and near do not change. A flight between islands is now a
ride: leave mid, slide along the route, arrive at mid. Travel from the
long-press menu of the place control still works and plays the same ride.
The long-press menu can later become the glass bar of island medallions the
founder asked for (2026-11-14); it is the quick way, Sefer is the way with
the picture.

### 2.4 What the prototype shows and does not

It is built from shipped art by script, so it proves layout, sizes, touch
and the rig, not final painting. Known flaws: the cloud sea is one layer
tiled three times (a faint seam), Pofu and Mochi are upscaled sprites, the
puffs hide Nazlı's mouth, and her tail is the small pilot tail. At 1:1 the
rig body is clean at 330 pt.

## 3. Home: Nazlı at the harbor, the player's islands in the sky

See `frames/home-pair.jpg` (today on the left).

- **Nazlı moors under the harbor islet**, in the empty band (rows 0.58 to
  0.70, right side), 196 pt wide, face to the camera and clear of the pier
  (the founder's note of 2026-11-05). Tapping her opens Sefer. At night she
  sleeps there. This is the foreground the frame lacks, and it puts the way
  out of Home under the thumb.
- **The sky shows the player's world.** The far lane holds the islands he
  knows, cut from each island's own plate at its current stage, 80 to 110 pt
  wide, in haze: fillers on the left, the main road on the right, the next
  one a cloud tower. Grey while asleep, alive once healed, so the sky is a
  record of what he did. Tapping one opens Sefer facing it. No new painting:
  a script scales and hazes the plates that ship.
- **The baked whale and the four generic isles leave Home's sky** in the
  same change. She cannot be in the sky and at the harbor, and the grown
  form should not be seen before the finale.

## 4. Nazlı

### 4.1 How she arrives

The dates follow the catalog in code (the harbor on tended day 3, Köke's
rumour on day 5, its arrival on day 6). Lines are for the `pofu-story`
skill; only the beats are fixed here.

| Day | Beat | On screen |
|---|---|---|
| 3, evening | **İz** (the trace) | Once, a whale-sized shadow passes under the cloud below Home, left to right, 6 s. Cloud rises where it passed. Nothing to tap. |
| 4 | **Yanaşır** (she moors) | She is asleep at the harbor with a rope round its post; Yosun sits on her bench with a letter addressed "Bekçi'ye". A tap: one eye opens and closes. No voyage yet. |
| 5 | **İlk sefer** (first voyage) | Mochi has packed. Pofu stands at the front and wants the helm. Sefer opens by itself; she drifts left, not where the player drags, to a cloud tower with a shape in it. This is Köke's rumour. |
| 6 | | The veil parts on arrival. "İn" works. From now on she answers the hand. |

Before day 4 there is no far view and no control for it. Her arrival is
what opens the world, as the story map says ("Artık adalara gidilebilir").

### 4.2 Her body as a flying creature

The pilot rig (batch 37) has a body, a tail, fins, a back patch and closed
eyes on one registered canvas. For flight she needs these parts, each on
its own layer of one canvas, so code can move them:

| Part | Moves how |
|---|---|
| Body | Bob 4 pt over 5 s; pitch up to 3 degrees with speed; squash 4% on a turn |
| Tail stock and fluke (two pieces) | Two-bone sway: 4 degrees at rest, 13 at speed, the fluke a quarter cycle behind |
| Near fin, far fin | Flap at half the tail's rate, 5 to 15 degrees; spread flat when she stops |
| Eyes: open, half, closed, glad | Blink every 3 to 6 s; half-lidded while tired (form 1, early); look toward the island ahead |
| Belly mist | A soft cloud skirt where she meets the sea; trails behind at speed |
| Blow | A cloud ring on departure; a small rainbow in it after an island heals |
| Back patch and its pieces | One layer per piece (4.3), so each can arrive on its own |
| Hook, lantern (unlit, lit), rope | The rope shows only when moored |
| Riders | Two sockets: Pofu at the front of the patch, Mochi on the bench |

She faces the way she travels; the art is mirrored. The lantern scar moves
from her flank to the middle of her back beside the hook in the next rig
pass, so the mirror is true.

States: asleep at the mooring, idle, swimming, turning, arriving, glad,
singing (form 2 only).

### 4.3 Her levels

She grows with the bond, never by spending (story map). Each level is an
island's piece, and by the measure of section 5.1 each must also change her
outline or her light, so I pair every canonical piece with one large effect.

| Level | When | The piece (canon) | The big change |
|---|---|---|---|
| 1 Yorgun | she arrives | bench, post, empty hook, grass tuft | half-lidded eyes; she sleeps often |
| 2 Evin toprağı | the pier is first built (her berth) | a young sunflower in a mound of Home's soil | the patch doubles; her eyes open fully from here on |
| 3 Su | Çağlayan blooms | pool and waterfall | water falls from her flank; mist trails in flight |
| 4 Işık | Revontuli blooms | aurora jar | at night an aurora ribbon follows her on the route, as bright as the player's calm nights |
| 5 Posta | Emanet blooms | teal plank | a planked deck with Yosun's letterbox and a pennant mast |
| 6 Ay | Mehtap blooms | moon stone | her belly glows at night and lights the cloud under her |
| Form 2 | the finale | Ihlamur's lantern, lit | the grove grows over every piece, she sings the four notes, a fifth larger; she moors lit every night |

The pier is her berth, so the pier's forms (5.3) are where she and Home's
growth meet.

## 5. Growth: island and stations as one

### 5.1 The measure of a big upgrade

A level is what the player paid for. It must read at a glance with the
whole island on screen, where a station is about 50 pt wide. Six rules; the
first two are numbers a script checks, the rest are for the brief and the
eye.

1. **Outline.** New mass outside the old outline is at least a quarter of
   the old area, and the two shapes overlap by no more than 0.80.
2. **Reach.** The new mass stands above or beside the old one: the box
   grows 15% or more one way.
3. **A new kind of thing** at every level, never more of the same: an
   object, then a shelter, then a yard, then a storey with light, then a
   crown that moves.
4. **The ground changes with it.** The plot under and round the station is
   part of the form: bare, trodden, paved, bordered.
5. **It spills.** Something outside the plot changes too: a path reaches
   it, a resident starts work there, a light is seen from Sefer.
6. **It has a name.** The station is called something else afterwards, and
   the change can be said in three words.

`tools/art/big_step_check.py` implements 1 and 2 for cut-outs and a
changed-area test for whole plates. Anything that fails is a touch:
welcome inside a form, never a level. The thresholds are my judgement,
set so that a second storey or a yard passes and a pot, a fringe of
flowers or a redrawn edge fails; the pilot should move them if the eye
disagrees.

### 5.2 Five levels stay; they become five forms

The costs, caps and the 1,950 seeds of `ArchipelagoCatalog.standard` do not
change, so the economy and its tests are untouched. About forty purchases
over the first five weeks is one visible change a day, which is the pace
the founder asked for; the fault was their size, not their number.

What changes is what a level is:

| Form | Kind | Light, life | The player sees |
|---|---|---|---|
| 1 | an object on bare ground | | "it is here" |
| 2 | a shelter: it gets a roof or a body | idle motion | the first building |
| 3 | a yard: it spreads over the ground | a resident works there | a place, not a thing |
| 4 | a storey or a tower | lit at night | it breaks the skyline |
| 5 | a crown that moves | signature motion, seen from Sefer | the island's landmark |

The station sheet shows the form's name and five pips, not "Seviye 3 / 5".

### 5.3 The forms, by name

Names are Turkish, written as names; English names are written separately
when the English catalog is.

| Station | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Bahçe | **Tarh**: three sunflowers | **Bostan**: fenced beds, a scarecrow | **Çardak**: a vine arch over a bench, beds doubled | **Sera**: a small glasshouse, lit | **Dev Ayçiçeği**: taller than the mill, it follows the sun |
| Çay | **Semaver**: a samovar on a crate | **Çay Ocağı**: the stall with its awning | **Çay Bahçesi**: tables under a pergola | **Çayhane**: a tiled house with a chimney | **Teras Çayhane**: a roof terrace, lantern strings, steam |
| Gölet | **Gölcük**: a ring of stones | **Gölet**: twice as wide, tall reeds | **Kayıklı Gölet**: a deck, a rowing boat, a stream across the lawn | **Köprülü Gölet**: an arched bridge with lanterns | **Nilüfer Gölü**: a pavilion on an islet; the water falls off the island's edge |
| Atölye | **Tezgâh**: a bench under a lean-to | **Atölye**: the shed | **Avlulu Atölye**: a yard, an anvil, a cart | **İki Katlı Atölye**: an upper floor, a smoking chimney | **Çark Evi**: a great wheel turns on its front (Pofu's wheel, grown) |
| Değirmen | **Rüzgâr Gülü**: a wind wheel on a post | **Değirmen**: the stone tower, bare sails | **Yelkenli Değirmen**: cloth sails turning, a sack store | **Fırınlı Değirmen**: a bakery wing with an oven chimney | **Büyük Değirmen**: twice the height, a gallery, lanterns on the sail tips |
| Simit | **Simit Tablası**: a tray on a stand | **Simit Arabası**: the cart and its umbrella | **Simit Tezgâhı**: a stall with ring poles and a bench | **Simit Fırını**: a stone oven kiosk, glowing | **Köşe Fırını**: a corner bakery under a great turning simit |
| İskele | **İskele**: planks and posts | **Fenerli İskele**: longer, a lantern, Nazlı's post | **Rıhtım**: an L-shaped quay with a booth | **Liman**: a gate arch, a bell, lit | **Nazlı'nın Limanı**: a cloud berth with a bell tower |
| Fener | **Fener Direği**: a lantern on a tall post | **Fener Kulesi**: the striped tower, dark | **Balkonlu Fener**: taller, a gallery, the keeper's hut | **Yanan Fener**: the lamp is lit; the beam sweeps | **Büyük Fener**: a crystal lamp; healed islands answer its beam on Sefer |

Two cautions. The fountain in Home's pond is Çağlayan's gift in the story
map, so no pond form uses one. And every form 5 here is larger than what
the level 10 plate paints, on purpose: the finished island is a new
painting (5.5).

### 5.4 Island levels

The ten painted grounds stay as the island's own ladder, and each level
gets a name the card shows in place of "Ada 6":

1 İlk Filiz · 2 Patika · 3 Liman · 4 Su · 5 İskele · 6 Işıklar ·
7 Çiçek Yolu · 8 Değirmen Tepesi · 9 Tepe Yolu · 10 Tam Çiçek.

The rule for an island level is the same measure at island scale: the
island's own body changes (the harbor joins, a mound rises, the rim
flowers, the hill grows), and a plot opens as prepared ground with stakes
and a sign. The ground never paints a station: stations are forms the
player buys. From the plate sheet, levels 2, 4 and 6 are the weak steps
(a path, a hollow, lamps); they should be checked with the tool in plate
mode on the erased bases and repainted if they fail.

So the picture is always: the ground of the island's level, plus each
station at the form the player bought. One system, two inputs.

### 5.5 How the forms are painted: cut from the island's own picture

The standalone cut-outs (batches 123, 129) come out 55% more saturated than
the plate, need a contact shadow added, and do not arrive at the plate's
own station. That is the collage again. The founder's idea, one picture cut
into pieces, is the fix, with two changes of method:

1. **In place.** Each form is painted on a crop of the island's erased
   base, enlarged about 2.5 times, so the light, the perspective, the grass
   and the contact are the island's. The crop is the plot: the station and
   the ground round it.
2. **Last form first.** Form 5 is painted first, as the best picture the
   station can be. Forms 4 to 1 are edits that take whole masses away. This
   is the order that worked for the healing arcs (batches 67 to 70), it
   makes every step large by construction, and it ends at a humble form 1
   in the same hand.

A script cuts each form from its crop against the bare crop, feathers the
ground edge, and writes the cut-out the compositor already draws
(`StationLooks`). `big_step_check.py` and `matte_check.py` gate it.

Pilot first, on two stations that differ: the windmill (tall) and the pond
(flat, all ground). It passes if, in an in-app frame at mid and near, the
forms show no pasted edge in 1:1 crops and every step is big. If it fails,
the fallback is the batch 129 method with section 5.3 as its content.

Tam Çiçek (island level 10, every station at form 5) then gets one new
whole-island painting that the eight form-5 crops are checked against.

### 5.6 The moment

2.6 s, skippable, calm: a cloud puff covers the plot, the camera pushes in
0.4 s, the new form lands with a short squash, residents turn to it, the
new name appears ("Çay Bahçesi"), and the camera pulls back so the whole
island is seen with the change in it. The reveal that merged in #500 is the
base for this.

## 6. The other islands

The healing arcs are sound in idea. Two changes: run the plate check on
every arc and repaint the steps that fail, the last step first (Çağlayan 3
to 4 changes 8% of the picture); and treat the island's gift to Home and
its piece on Nazlı's back as the fifth step, shown in a short ride home, so
an island's end is seen in three places.

Progress between islands is the route itself: the door rule of the story
map decides when the next tower appears, and the tower's shape is the
rumour.

## 7. What is retired, what is kept

| Retired | Kept and reused |
|---|---|
| The Map as a still frame: tiers, tier frames, cloud towers in slots, the WP12 reveals as specified | The camera rail and its three stops (ADR-0027) |
| The far-camera interface variants of batch 122 and question 3 of the UI grammar | The cloud kit and cloud floor (they become the sea Nazlı swims in) |
| The whale and generic isles baked into Home's sky | Every island plate, the erased bases, the compositor, the reveal |
| "Seviye n / 5" and "Ada n" as names | The costs, caps and island level rules in `PofuCore` |
| Standalone station cut-outs, if the pilot passes | Map order A's idea that Home is the centre: Home is slot 0 |

## 8. Build order

Each line is one pull request for a builder; none needs art that does not
ship, except G3 and N1.

| | Work | Needs |
|---|---|---|
| V1 | `voyage.json` and `VoyageLayout` (slots, scale and foot by offset, bands): pure layout with tests on Linux | |
| V2 | `NazliRig`: the five shipped parts, code motion, facing, riders | |
| V3 | Sefer at the far stop: route, drag and snap, glass bar and verb, VoiceOver, Reduce Motion | V1, V2 |
| V4 | Boarding and landing between mid and Sefer; rides replace flights | V3 |
| V5 | Home: Nazlı moored, the player's islands in the sky, the baked whale and isles removed | V2 |
| V6 | Her arrival: the three beats, lines from `pofu-story` | V5 |
| G1 | Form names in the catalog and strings; the sheet and cards show names | |
| G2 | The check in the art review (`big_step_check.py`, done) | |
| G3 | The pilot's forms in the app, judged in frames | art |
| N1 | Rig pass 2 and the back pieces | art |

V1 to V5 give the founder the new far view and Home on his phone with no
new painting. G1 is small and independent.

## 9. Risks

- **A side-scrolling route may feel like a menu, not a world.** The
  foreground whale, the parallax sea and the far lane are what make it a
  place; if the prototype in his hand still feels like a carousel, the
  fallback is the same frame with the route curved in depth.
- **In-place painting may drift.** That is what the two-station pilot is
  for; the fallback is named in 5.5.
- **Form 5 may crowd the island.** Each plot has a fixed box; the new Tam
  Çiçek painting is the test of whether eight crowns fit.
- **The thresholds of the measure are mine.** They separate the cases I
  tested; the pilot is their first real use.

## 10. Decisions for the founder

In Turkish, one line each, my pick first.

1. **Harita yerine Sefer.** Uzak görünüm durağan harita olmasın; Nazlı'nın
   sırtında, adaların önünden kayarak geçtiğimiz bir yolculuk ekranı olsun
   (prototip telefonda denenebilir). Diğer seçenek: haritayı düzeltmeye
   devam.
2. **Nazlı oyuna üç adımda girsin ve evde limanın altında dursun.** 3. gün
   gölgesi, 4. gün uyurken yanaşır, 5. gün ilk sefer. Gökteki hazır balina
   ve genel adacıklar kalkar; gökte oyuncunun kendi adaları görünür. Diğer
   seçenek: gökteki balina kalsın.
3. **Her seviye adı olan bir "biçim" olsun.** Beş seviye ve fiyatlar aynı
   kalır; her seviyede istasyonun adı ve silueti değişir (Semaver, Çay
   Ocağı, Çay Bahçesi, Çayhane, Teras Çayhane). Diğer seçenek: daha az ama
   daha büyük seviye (üç).
4. **"Büyük adım" ölçüsü kural olsun.** Eski siluetin dışına en az dörtte
   bir yeni kütle gelmeyen değişiklik seviye sayılmaz, süs sayılır; bunu
   bir araç ölçer. Diğer seçenek: yalnızca gözle karar.
5. **İstasyonlar adanın kendi resminden, yerinde boyanıp kesilsin; en
   güzel hâl önce.** Önce değirmen ve göletle denenir. Diğer seçenek:
   129'daki ayrı ayrı boyama, yeni içerikle.
6. **Nazlı her ana adadan büyük bir değişiklik alsın** (şelale, aurora
   izi, güverte, ay ışığı), finalde ikinci biçim. Diğer seçenek: yalnızca
   küçük hatıralar.
