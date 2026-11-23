# Whole-project assessment, round 1 (2026-11-23)

Round 1 of 2 (founder-input 43). This round says where the project
stands, what stands between it and "perfect", the path I recommend, and
the questions the founder has to answer. Round 2 turns his answers into
the fixed order and the briefs. The founder's page, in Turkish, is
[assessment-2026-11-23-tr.md](assessment-2026-11-23-tr.md).

Basis: pofu `origin/main` a8d07c7e (#508), pofu-art `origin/main` e36b30a,
frames on `screenshots/main` (rendered from a1dd288, the last code
change). Two cheap agents gathered raw facts
(`docs/research/assessment-2026-11-23/` on the lead branch). Each claim
below is marked **[seen]** (I opened the file or the frame), **[raw]**
(taken from the raw files, not rechecked) or **[unknown]**.

## 1. The verdict in one page

Pofu is two products in one binary: a Screen Time gate and a painted
idle world. The world has had nearly all the attention for three weeks
and is, at its best, beautiful. The gate, which is the reason the app
exists, has never run on a phone.

1. **The app's real function is unproven.** `PofuLive` and its three
   extensions compile in CI and have 40 logic tests, but no device has
   ever run them [raw; no report exists]. The day-1 script holds 28
   device cases whose outcome nobody knows (does the shield redraw, can
   the extension write the App Group, how late does the shield return).
   This is the largest unknown in the project and it opens this week.
2. **Nothing the player can feel has changed since 11-17.** The last
   player-facing merge is #506. Since then: one design doc (#508), 190
   Codex concept jobs, no pick landed in the app. Nine pofu PRs and 59
   pofu-art PRs are open [raw].
3. **The surfaces he said he dislikes still ship unchanged** [seen in
   frames]: the station sheet ("nefret ettim", 11-17), the flat
   code-drawn stream board, Home's composition (the island in the upper
   half, more than half the screen cloud), thin menus.
4. **The world is a still picture.** Pofu never travels; residents are
   baked into the plate and only hop; two of ten residents have lines
   (three each); ambience is off by default; there is no music and Pofu
   has no voice in the bundle [seen in code].
5. **The concept method stalled the studio.** "No code until he picks"
   plus rounds of 88 and 102 images plus a founder in exam weeks gave a
   week with no decision. The rounds were also the wrong kind of
   picture, which is what his verdict says.

My recommendation: this week belongs to the gate on the real phone and
to the three disliked surfaces, in that order. The voyage and the
Gezgin as a system wait until those are done. Concepts shrink to one
phone page per topic, and UI is no longer asked of Codex at all.

## 2. Where it stands

### 2.1 Apple: what opens, and how ready we are

- **What opens** is the paid Apple Developer membership (docs say
  "expected after 2026-11-24") [seen: `docs/roadmap.md`,
  `docs/local/membership-day-1.md`]. With it, development builds may use
  Family Controls on day 1. TestFlight and the App Store need Apple's
  separate Family Controls (Distribution) approval for four bundle
  identifiers, which "reportedly takes weeks". Whether he has enrolled is
  **[unknown]**; no file says.
- **Built** [raw, spot-checked]: `LiveScreenTimeService`, the shield
  configuration, shield action and device-activity extensions, the
  permission and picker onboarding, the "Pofu'yla aç" notification path,
  the 3-minute quick look, the readout in Settings.
- **Not ready, found now:**
  - Day-1 case 10 cannot be run. It ends a pass early "in the Passes
    sheet", and that sheet has no opener in the shipped Home:
    `HomeView.swift:214,383,390` sit in `topBar`/`bottomActions`, drawn
    only when `FeatureFlags.worldHome` is false, and it is true [seen].
    `endPass` has no other caller [seen]. So on the live build a running
    pass can be neither seen nor ended from Home.
  - The same holds for `EarnSheet` (honor sessions): reachable from
    nowhere [seen].
  - The roadmap's day-1 checklist enables HealthKit and Associated
    Domains; no code or entitlement uses either [seen: `roadmap.md:162`].
    Enabling unused capabilities invites review questions.
  - The live build is a different bundle identifier from the free one,
    so his island starts again from day 1 on the live build [seen: day-1
    script, Part 2 step 6]. He should know before he installs.
  - `App/` and `Extensions/` have no test target [raw]. The extensions
    run in a few megabytes; only the device shows whether they survive.
- **The long pole** is not ours: Distribution approval. Filing it on
  day 1 costs ten minutes and saves weeks later.

### 2.2 The product loop

- The gate's rule holds in code: no caller buys minutes [seen; raw
  grep]. The pay-for-minutes functions (`purchaseUnlock`, `quote`,
  `grantEmergencyPass` and others) are dead but still compiled and
  tested [raw]. `docs/tracker.md` still says seeds buy minutes: the doc
  is wrong, the code is right.
- Earning is quiet time, rounds and (orphaned) honor sessions. Stations
  and island levels 1-10 work.
- The player's 21 days are rendered as `path-dNN` frames in CI, which is
  the right instrument and should stay the judge.

### 2.3 The look, from real frames

- **Home at level 10 is the project's best asset** [seen at 1:1]: dense,
  warm, coherent. **Home at level 1** shows a ragged matte at the
  island's upper-left edge [seen at 1:1].
- **Composition:** at 09:00 on day 1 the island sits roughly between 35% and 60%
  of the screen's height; below it is cloud down to the chrome. The Map
  frame is emptier still: one cloud, a small island, empty lower half
  [seen]. His 11-16 complaint stands.
- **Station sheet:** name, five pots, one rate line, one button, a large
  empty cream panel covering half the island [seen]. Unchanged since he
  rejected it.
- **Stream board:** flat cream tiles and grey channels on a lawn, under
  a lush painted waterfall; the board and its backdrop look like two
  games [seen at 1:1].
- **Garden game:** holds together; a wall of brown.
- **Today sheet:** one card, one line, mostly empty [seen].
- **Pofu at the near lens** reads well [seen at 1:1]. His bundled body
  is still `pofu-hamster.png`, 522 x 496, called "the bundled
  placeholder" in the code [seen]. It holds at today's sizes; it is a
  risk for anything larger (the gate, stickers, the App Store).
- **Pofu behind things:** in `path-stall-pofu-behind` Pofu stands behind
  the tea stall and only his ears show above the teapot [seen at 1:1].
  This answers his question from the app, not from a concept: behind a
  tall station he is lost; behind a low one such as the pond he is not.

### 2.4 Life, story and sound

- Pofu stands at one spot and reacts; the camera moves, he does not
  [raw]. Residents on the painted Home are part of the painting; the
  walk system (`ResidentLife`) still runs each frame and its result is
  discarded [seen: `IslandScene.swift:484,723`]. Hops exist
  (`PlateHops`).
- Lines: `residentLines` returns text for Mochi and Fındık only [seen].
  The content library (47 moments, 40 character files) is validated in
  CI and loaded by no Swift code [raw].
- Sound: 20 cue kinds and four ambience beds exist. Ambience is **off by
  default** (`SoundSettings.isAmbienceOn = false`) [seen], so a new
  player hears a silent island. No music. Five Pofu voice proofs sit in
  `design/sound/proof/`, unbundled [raw].
- Visitors: the ledger, schedule and arrival styles are built [raw].

### 2.5 Technical state

Healthy: about 1,660 tests, CI green on the last 15 main runs (10
passes, 5 superseded), warnings as errors, one TODO in all Swift [raw].

Debt and risk, in order of what can hurt:

1. No device truth for the gate (above).
2. Two Home renderers both live: the painted plate, and the older sprite
   island as the fallback for any level, hour or weather with no painted
   state [seen: `HomePlate.resolve`]. Every fallback is a look change
   the player can hit. Which states still fall back today is
   **[unknown]** and is a cheap scout job.
3. Dead paths that still compile and confuse every agent who reads
   them: the `!worldHome` Home, `EarnSheet`, pay-for-minutes, the
   discarded resident walk, flow ground method A.
4. `IslandScene.swift` 2,564 lines, `IslandSceneModel.swift` 1,650,
   `AppModel.swift` 1,331 [raw]. Not urgent; they make every world
   change slower and riskier.
5. CI: the macOS job runs 44-46 minutes against a 45-minute timeout
   [raw]. One slow day turns green into red.
6. Heat and frame pacing on the phone: 11 `TimelineView`s, one of them
   on the plain `.animation` schedule [seen by count; not profiled]; the moving pond and the
   120 Hz pinch have never been measured on the device [raw].
7. Repository weight: pofu is about 17.6 GiB by the API, the
   screenshots branch 785 MB, 142 remote branches; this machine has
   5.7 GB free [seen].
8. Docs: `tracker.md` and `roadmap.md` are stale and in places false
   (seeds buying minutes, "all growth pieces are stand-ins", the last
   phone test). Either they are corrected or they are archived; a false
   doc is worse than none.

### 2.6 The production line

- Codex delivered 175 of 190 concept jobs; batch 152 (the block set,
  the part he liked most) delivered nothing on quota [raw]. Six PR
  bodies since 11-15 mention quota or rate limits: "unlimited" is not
  what the line shows.
- Every take in both rounds carries `qa: warn` and none `fail` [raw]. A
  gate that says the same thing about 400 images tells us nothing; the
  QA numbers are tuned for plates, not for concepts.
- Round 2 has no review sheet. In a sample of twelve round-2
  `contact.jpg` files, two show a different job than their folder
  (`x2-panel-tag` shows strip-max, `x2-panel-bubble-mill` shows
  strip-mill) [seen]. The takes themselves are in the right folders.
- `QUEUE.md` still lists D9-D16 as READY though seven are merged [raw].
- `tools/art/sync_to_art.py --prune` would delete 66 manifests that
  exist only in pofu-art (88 in pofu, 154 in pofu-art) [seen: counts
  and the prune code]. Nobody should run `--prune` until the manifests
  are copied back or the prune is limited to code.
- 59 open pofu-art PRs, most superseded [raw].

## 3. The four topics and the two rounds

**Why the rounds missed.** He asked for concept art: a simple picture of
an idea. He got finished marketing frames, every one at full polish,
full saturation and full prop density, in four sheets up to 5,600 px
tall. Three causes: the image model's default register is "finished";
the prompts described whole screens with every element; and nothing
limited the count. Round 2 was queued the same day as round 1's sheets,
before he had spoken, so it could not learn from him. At least 10 of
its 87 delivered jobs go against what he then said (four voyages seen
from her back, her back model, Gezgin levels 4-7, a table board).

**Status by topic, against his verdict:**

| Topic | He said | What we have | State |
|---|---|---|---|
| Stream board | dial t2 best; key-big good; no table; blocks and textures liked | Round 1 has three "dial" jobs (big, fall, table), so "dial t2" is one of two takes: see question 3. Block set 144 liked; its production round 152 delivered nothing. | Direction nearly chosen. One ambiguity. Needs blocks, not more boards. |
| Level panel | no ladder; no second list of levels; a small glass card with a small design; Codex glass looks fake, test in the app | `x2-panel-pill` and `x2-panel-tag` (round 2) are already close to "a small object by the station". | Stop asking Codex. Build two native variants in real glass; Codex paints only the small level mark. |
| Voyage and Gezgin | A2 row makes sense; never from behind; level 1 must be a whale with a tail, fluffy; 2-3 levels; mooring matters | `x2-voy-row-big` refines A2. `x2-gez-model-front` is already a fluffy whale with a tail. Levels 1-7 exist; he wants 2-3. | Enough to pick from. The system itself (voyage code) is large and should wait. |
| Island and stations | step by step not bad; unsure of the pond; is Pofu visible behind front objects | Windmill progression approved earlier; pond variants in 142 and 150. | The pond needs his eye on 3 frames, not more variants. The occlusion question is answered in 2.3. |

**Round 3 (in flight).** Small and safe; let it run, with three notes.
(1) "Pofu behind the pond" cannot be answered by a painting; the app
answers it (2.3). Keep at most one job there or drop it. (2) The most
valuable Codex job is not in it: rerun batch 152, the blocks. (3) Before
anything new is generated, show him one phone page per topic cut from
rounds 1 and 2 as they stand; several of his round-1 objections are
already answered in round 2 and he has not seen it.

**How concepts should run from now on.**

- One phone page per topic, six frames at most, each named, the lead's
  pick marked. More than that is not a choice, it is homework.
- Codex paints things: blocks, the whale, island steps, small marks,
  textures. Codex does not paint interfaces. Interface variants are
  built natively behind a developer switch, in real glass, and he sees
  them on his phone. This is his own conclusion ("uygulamada test
  edilmeli") and it does not break "no HTML prototypes".
- "No code until he picks" applies to large systems (the voyage), not
  to surfaces he has already rejected. For those, the cheapest honest
  picture is the app itself.

## 4. The path I recommend

Three stages. The order is the recommendation; round 2 fixes the
detail after his answers.

**Stage 0, before the membership (now to about 11-25): make day 1
runnable.**
- Give a running pass a place in the world Home: a small glass pill
  that shows the app and the minutes left, tap to end. This fixes case
  10 and is the first piece of his "glass object" language.
- Decide the honor session (question 7) and delete what is cut.
- Correct the day-1 script (case 10, the capability list, the progress
  reset note). Prepare the Distribution request text.
- Housekeeping the lead can do alone: close or merge the nine pofu PRs,
  close superseded pofu-art PRs, fix `QUEUE.md`, mark `tracker.md` and
  `roadmap.md` stale at the top or correct them.

**Stage 1, the device days (about 11-25 to 11-27): the gate is real.**
- He enrolls, files the Distribution request the same day, builds
  `PofuLive`, and runs the cases. The lead sits with him through the
  side channel; one builder is on call for fixes only.
- Every case's result goes into the report. Until this is done nothing
  else outranks a failed case.
- In parallel, one lane that does not touch the gate: the station card
  as two native glass variants, and the block set from Codex (152).

**Stage 2, after the gate holds: the three surfaces, then life.**
1. Station card: he picks on the phone; the loser is deleted.
2. Stream board in the chosen direction with painted blocks.
3. Home composition: the island lower and larger at the resting
   distance, per unlock stage. This is layout work on the existing
   plates, no new art.
4. Life: Pofu changes spot by hopping between a few places; residents
   hop and now and then swap places; three lines for each of the other
   eight residents; ambience on by default; Pofu's voice in the bundle.
5. Then, and only then: the voyage and the Gezgin as a system, and
   music.

**Stopped or held:** new concept rounds beyond round 3; the voyage in
code (#503 stays a proposal); batches 136 and 137 stay held; no new
far-screen work.

**Who does what.**

| Who | Work |
|---|---|
| Founder | Enroll; one or two hours at the Mac for day 1; answer section 5; look at one page per topic. |
| Lead | Day-1 support and report; PR and queue housekeeping; the docs; briefs from round 2. |
| Builder A (Opus) | Stage 0 fixes, then on call for device fixes. |
| Builder B (Sonnet or Opus) | The station card's two native variants; later the board. |
| Scout (Haiku or Sonnet) | Which Home states still fall back to the sprite island; CI job timing. |
| Codex | Batch 152 rerun (blocks); round 3 as written; later the three Gezgin levels and the level mark. |
| Fable | Round 2; the station card's spec; a frame review after the device days. |

Two or three agents at once is enough for all of this.

## 5. Questions for the founder

Each with my pick. Turkish wording is in the founder's page.

1. **Membership.** Has enrollment started, and which day can he give
   one to two hours at the Mac? *Pick: the first day it is active;
   file the Distribution request the same day.*
2. **Order.** Gate on the device first, then the three disliked
   surfaces, then life, then the voyage and music. *Pick: yes.*
3. **Which "dial t2".** `x-board-dial-big` t2 or `x-board-dial-fall`
   t2 (picture in the founder's page). *Pick: dial-big t2, the calmer
   one, with the raised blocks he liked from 144.*
4. **Level panel.** A small glass card that hangs by the station, or a
   panel from the bottom. *Pick: the small card by the station, two
   native variants on his phone; nothing from the bottom.*
5. **Opening the island choice.** By tapping the Gezgin, or a button at
   the bottom right. *Pick: both; the Gezgin is the door, the button
   stays as the plain way in. To be built with the voyage, not now.*
6. **Pofu behind things.** *Pick: Pofu never stands behind anything
   taller than himself; the pond stays in front because it is low. No
   outlines or see-through tricks.*
7. **Honor sessions and the pass.** The earn sheet and the passes sheet
   cannot be opened today. *Pick: cut the honor session; show the pass
   as a small glass pill on Home.*
8. **Movement.** *Pick: hops between a few spots for Pofu and the
   residents; no walk cycles from Codex.*
9. **Sound.** *Pick: ambience on by default and Pofu's voice now; music
   after the gate and the three surfaces, discussed with him then.*
10. **Concepts.** *Pick: one phone page per topic, six frames at most;
    Codex paints objects, interfaces are tried in the app.*

## 6. What round 2 needs

- His answers to section 5.
- The day-1 report if it exists by then, or at least the enrollment
  date.
- The scout's list of Home states that fall back to the sprite island.
- Round 3's delivery and the 152 rerun, as one page per topic.
