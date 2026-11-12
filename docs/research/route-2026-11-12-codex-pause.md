# Route for the Codex pause (2026-11-12)

**Status:** advice by Fable 5.2 for the lead and the founder. Nothing here
is decided until they accept it. Base: `origin/main` at `c75c60b1` (#404,
#411 merged). Written late on Thursday 2026-11-12.

**What I looked at.** The CI frames on `screenshots/fix-home-night-characters`
(`a5ec125`, the newest frames of code that is on `main`) and
`screenshots/feat-painted-sky-everywhere` (`c230dfb`, PR #408), as 1:1 crops
of the 1206 x 2622 PNGs and as native 460 x 1000 JPEGs; the shipped Koke
asset on a contrasting ground; the `DemoRunTests` log of the tester's 21
days; the code where a frame raised a question; `docs/state/plates.yaml`;
`pofu-art` at `1de780a` (queue, reviews and the picked takes of batches 76,
78 and 81); `docs/now.md`, `docs/studio.md` and the founder log on the #403
branch. What I did not check is in section 8.

## 1. The answer in short

1. **The painted Home is good enough to be judged as a user would judge
   it. Almost everything the player travels to from Home is not.** The
   look chapter is nearly done for Home, and about half done for the path.
2. **The studio has been looking at the wrong frames.** Most CI frames of
   Home (`01-` to `13-`, `sky-*`, `weather-*`, `shadow-*`, `life-*`) are
   rendered with the paintings switched off
   (`Tests/WorldScreenshots/WorldScreenshotTests.swift:238`,
   `look.homePlates = false`). They show a world the demo no longer shows.
   Five visible breaks sit outside the frames that were being judged.
3. **Not "try it now" for the judged trial, and not a long wait either.**
   Two dates: a ten-minute device check of Home on Friday 2026-11-13 (the
   painted world has never run on a phone), and the judged trial on
   **Monday 2026-11-16, evening**. The date is fixed and the scope flexes:
   whatever is not accepted by Sunday 18:00 is hidden, never shown half
   done.
4. **One rule carries the week:** in the demo nothing code-drawn and no
   old sprite stands in for a painted thing. A missing painting is hidden
   or borrowed, as `demo-one-world-v1` D1 already does for the hours.
5. **The work is five builds and one proof,** all from art in hand: the
   Map on the painted sky, Çağlayan as a full frame at every hour, Koke's
   healed frame cleaned, the visitors and gifts in their painted art, the
   interface speaking one language, and a frame set of what the player
   really sees.
6. **The App desk reopens on Tuesday 2026-11-17,** not after the 24th: it
   needs no art, and one product rule there is unverified (section 5.3).

## 2. Where the build stands, as a player sees it

Each row is a frame I opened. "Branch" is the `screenshots/` branch.

| Screen | What the frame shows | Verdict | Frame (branch) |
|---|---|---|---|
| Home by day, IL1 to IL7 | One painting per level, crisp at 1:1; Pofu, Mochi and Fındık sit in it; the bottom band reads cleanly ("Bugün 2/4 · 15 dk", the next-goal line) | **Good.** The standard for everything else | `home-plate-full-l1-day`, `-l2-day`, `-l5-day` (fix-home-night-characters) |
| Home at night, IL2 to IL9 | Painted nights with lit doors and lamps; the characters hold one tone | **Good.** Small continuity slips between levels (the wheel's sunflower comes and goes, the stall changes design, IL5 has a warm pool before the lamps) | `home-plate-full-l2-night`, `-l5-night`, `-l7-night` |
| A build on Home | "Seviye 5!" tag, stars, a soft dust column | Good | `home-plate-full-life-build-l5` |
| The daily visitor and the parcel | A flat dark green blob and a flat box on a painted lawn: code stand-ins (`PofuWorld/Layout/VisitorStage.swift:16-17`) | **Breaks the painting** every day a visitor comes | `home-plate-full-life-visitor-l5` |
| The gifts from Koke and Çağlayan | A flat green bush and a faint ghost of a fountain | **Breaks the painting** from day 10 on | `home-plate-full-life-gifts-l5` |
| **The Map** | The old world: a pale code sky, flat grey clouds, sprite isles, a blurred yellow "İskele", Koke and Çağlayan as unlabelled thumbnails with a boxy fringe, the lower 60% empty; at night a flat grey slab. On a painted Home the old sprite island shows as a lavender ghost behind the painting | **The worst screen on the path, and nobody's list had it.** The player crosses it on every trip. #408 keeps it by design ("the code sky is still drawn on the Map and in flights") | `caglayan-map`, `integration-map-night` (feat-painted-sky-everywhere) |
| The harbor stop | A blurred pale disc with two smeared figures under Pofu's rumour line | **Looks like a placeholder.** Both rumours (days 5 and 11) are told here | `koke-rumour-harbor`, `harbor-sky-rumour-day` (feat-painted-sky-everywhere) |
| Koke, stages 0 to 3 | On the painted sky (#408) the grey bear greens stage by stage; it reads as one arc. Soft, small in the frame, the lower 45% is cloud sea | **Acceptable** once #408 merges with its night fix | `koke-stage-0` to `-3` (feat-painted-sky-everywhere) |
| **Koke healed, stage 4** | A stair-stepped pale block with petals around the bear, on day and golden skies. The shipped asset carries a piece of its source background: `world-koke-island-4.png` (716 x 477) on a blue ground shows it plainly | **Broken at the island's payoff moment** | `koke-stage-4`, `koke-sky-s4-golden` (feat-painted-sky-everywhere) |
| Koke at night | Noon-lit island on a night sky, a hard line across the cloud sea | Broken; the #408 fix round is on it | `koke-stage0-2230` |
| Çağlayan by day | Painted, on its own sky set; the best of the wonder frames | **Good** | `caglayan-plate-full-s0-day`, `-s2-day`, `-s4-day` |
| **Çağlayan at night and in rain** | The landscape painting is a band across the middle; above it flat navy or grey, below it a flat lavender slab with a hard edge | **Reads as unfinished** on every night visit from day 12, and in rain once healed | `caglayan-plate-full-s3-night`, `-s4-rain` |
| Station sheet, Settings | Clean paper sheets, one style | Good | `17-sheet-station-v3-day-medium`, `16-menu-settings-v3-day` |
| Today sheet | The header is a flat vector sun, tree and disc; it says "Kavanozda 0 tohum" while Home says "çekirdek" | Placeholder art; two words for one thing (`App/Resources/Localizable.xcstrings:2958` against `PofuWorld/Resources/Localizable.xcstrings:779`) | `15-menu-today-v3-day` |
| Garden game | Painted board, characters, a warm result card | **Good** | `20-garden-midround-light`, `24-garden-set-end-light` |
| Flow game | Works and reads; the empty channels and junctions are plain brown strips beside painted stones; the caption sits far below the board | Acceptable, a step under the garden | `41-flow-stage1-mid`, `44-flow-stage4-solved` |
| The gate, the shield replica | A painted lawn with Pofu and two clear buttons; a clean replica | Good | `20-gate-1200`, `06-shield-replica-light` |
| The breath | Pofu on a flat green disc between white blobs | Placeholder art | `breath-1-in` |
| A pan to the island's right side | The sky's far isles double in a lighter vertical band, and a white strip runs down the right edge; another frame has a dark band on the left | **Suspected** edge of the painting under a pan (section 8) | `levelup-0ms-1200`, `levelup-900ms-2230`, `visitor-quiet-day` |

What a player would say after 21 days: the island I live on is lovely, and
the game around it (collect, build, garden, the gate) works; the moment I
leave Home I am in an older, rougher game, and my reward for healing Koke
has a hole in it.

**The game itself** (the `DemoRunTests` log): the tester reaches IL7 on day
16, Koke heals on day 10, Çağlayan on day 16. From day 8 the run gains
exactly one station level a day, and days 17 to 21 hold nothing new but
Çağlayan's free play. A player who only presses "Next day" stops at IL3 on
day 4 and stays there. The run has a beginning and a middle and no end.

### Premises I found false or stale

1. *"The look chapter is nearly done in code; the visible gaps are the
   harbor isle, Koke 0 to 2, Koke 4's halo and the follow-ups."* The Map
   and the flights are the old world by #408's own design, Çağlayan's
   non-day frames are letterboxed, and the visitors and gifts are
   stand-ins. Koke 0 to 2, on the other hand, read better on the painted
   sky than the list suggests.
2. *The CI frames show the build.* Most Home frames show the sprite
   island. `screenshots/main` is also older than today's five merges.
3. *"Koke stage 1 alone" is ready to ingest.* Its own review says to check
   the arc only once stages 0 and 2 land, because it is brighter than its
   old neighbours (`pofu-art` `batch-81-koke-final-colour/koke-island-1-v2/review.yaml`).
4. `docs/state/plates.yaml` on `main` has no cell for Çağlayan's golden,
   night and rain sky masters, which are picked in `pofu-art`
   (`batch-76-redo-picks`, take 1 of each).
5. `founder_ok` is `null` in every cell of `plates.yaml`, and the painted
   world has not run on a phone: his last device session was 2026-11-05,
   on the sprite world.

## 3. The bar

"A whole, polished build he can judge as a user" is five tests. A feature
count is not among them, and neither is full content.

| # | Test | Today | Gap |
|---|---|---|---|
| B1 | **No frame breaks the painting.** On the tester's path, days 1 to 21, at 09:00 and 23:00, every frame of Home, the Map, a flight, Koke and Çağlayan is painted, full height, with no stand-in, no seam and no halo | Home passes | The Map and flights, the harbor stop, Koke 4, Çağlayan's nights and rain, visitors, gifts, the pan edge |
| B2 | **Every tap answers, and the next thing to do is on screen** | Mostly (game-solid, #405) | A met goal shows no line; Koke and Çağlayan have no name or state on screen; the Map's wonder isles have no label |
| B3 | **One voice.** One word per thing, one sheet style, no placeholder picture | Sheets and games pass | "tohum" and "çekirdek"; the Today header; the breath's disc |
| B4 | **It runs like a finished app on his phone:** no hitch on a crossfade or a level-up, no heat, a relaunch restores the day | Unknown since 2026-11-05 | A device check, then fixes |
| B5 | **The session has a shape:** a first minute that needs no explaining, and a last day that feels like an arrival | Onboarding exists in the old look and is in no CI frame; days 17 to 21 are flat | Look at onboarding once and fix only what is broken; one closing beat on day 21 from lines and art in hand |

B1 is the largest gap and almost all of it closes with art in hand.

## 4. Decisions, each with the alternative set aside

| # | Decision | Set aside |
|---|---|---|
| R1 | **Two dates.** A device check of Home on Friday 11-13; the judged trial on Monday 11-16, evening | "Try it now" as the trial: five breaks he would meet in the first ten minutes each cost a day or two, and he can meet the build for the first time only once. Waiting until everything is done (about 11-20): he asked not to wait long |
| R2 | **The date holds; the scope flexes.** Cut line Sunday 11-15, 18:00 | Slip the trial until the Map is done |
| R3 | **Nothing stands in for a painting.** A visitor, gift, stop or light without painted art is hidden or borrowed | Show stand-ins and explain them: he asked to judge as a user |
| R4 | **The Map keeps its one camera and is drawn from the paintings:** the painted sky stays on at every distance, Home is its own island cut from the level's painting, Koke and Çağlayan are their stage art with clean edges and a name | A destination sheet in place of the Map (cheaper, but it gives up the one-camera world of experience v1 §1); leaving the Map as it is |
| R5 | **The harbor is not a separate stop in the painted world.** The painted Home already holds the harbour islet from IL3; the rumours are told at Home with the islet in frame | Keep the sprite isle (`demo-one-world-v1` D9); retarget the camera onto the islet now (it sits at the painting's right edge, where the pan question of section 8 is open) |
| R6 | **Koke's stages 0 to 2 stay as they are; stage 1 v2 waits for batch-82.** No repaint in code | Ingest stage 1 alone (brighter than its neighbours); desaturate a stage 0 out of stage 1 v2 by script (thrown away the day batch-82 lands) |
| R7 | **Çağlayan's night, golden and rain come from the picked portrait masters of batch-76;** stages 0 to 3 at night are their own islands over that night sky | Wait for a portrait night per stage; keep the flat bands |
| R8 | **No new look engineering this week:** no golden per level, no sky set per night, no weather on plates | Keep widening the look while art is paused: that is the "let's just try" work he ruled out |
| R9 | **The App desk reopens on Tuesday 11-17,** starting with the seeds check (section 5.3) | Keep it paused until after the 24th: it is the one desk that never needed Codex |
| R10 | **The player-path frames become the Look desk's evidence;** sprite-fixture frames are renamed so no reviewer mistakes them | Keep judging from the mixed set |

**Only the founder can decide:** whether he does the ten-minute device
check on Friday (R1), and whether Monday evening suits him. Everything
else is the lead's.

## 5. Where the weight goes while art is paused

### 5.1 Finish with the art in hand

| Work | Art it uses | Why it lasts |
|---|---|---|
| The Map and flights on the painted sky (R4, R5) | Home's sky sets and level paintings, Koke's and Çağlayan's stage art, all shipped | The Map stays in the game; every later island joins the same painted Map |
| Çağlayan full-frame at every hour (R7) | `pofu-art` `batch-76-redo-picks`: `x-caglayan-sky-night-v2`, `-golden-v2`, `-rain-v2`, take 1 each | These are the island's final sky masters |
| Koke healed, clean edges | The stage 4 take already in the repository, re-matted by script | A clean matte is needed whatever paints Koke next |
| Visitors and gifts in painted art | `batch-78-plate-life`: parcel t1, moss t2, fountain t1 (soften its five hard droplets by script), Gezgin t1, Damla t1 (erase the two pairs of motion strokes by a scripted mask) | Final art for the living layer |
| #408 (Koke at night) and #412 (IL1 night) | In flight | Close the look spec |

Sumi's take reads as Damla's twin by its own review, so Sumi waits for
batch-83 and is hidden until then (R3).

### 5.2 Cut or hide

- The harbor stop and its sprite isle (R5).
- Any visitor with no painted art: that day is a quiet day or a parcel
  day. A rule in the visitor draw, not seven stand-ins.
- Çağlayan's painted rain and golden, if the full-frame build misses the
  cut line: borrow the day painting with code rain streaks (D2 of the look
  spec), and the night for golden (D4).
- Koke stage 1 v2 (R6), decor parcels (already off), the style picker.
- The sprite-fixture frames from every review sheet (R10).

### 5.3 The code and app work that was waiting

In order, from Tuesday 11-17:

1. **Seeds and screen time, checked in the app, not only in the engine.**
   `game-solid-v1` §3 says `Economy.purchaseUnlock` has no caller outside
   tests; the tracker still says the gate lets seeds buy minutes; and
   `App/Home/HomeView.swift:116-120` presents an Earn sheet and a Passes
   sheet whose header describes "price rules" and a refund. One scout
   pass, then a fix or a deletion, before membership day.
2. The interface in one voice, beyond the trial's fixes: night variants
   of the paper sheets (`batch-77` `ui-*-night`, approved), the flow
   junctions composed from the straight tile's own pixels (generated
   junctions failed twice), sounds for the visitor, the gift and Koke's
   waking, the haptics table.
3. Onboarding in the gate's look, then the Door spec (one Fable or Opus
   spec pass, as planned on 2026-11-12).
4. Performance on the device after the trial's readings; the week page
   note; the widget extension (buildable without the membership).
5. Tools: port `pofu-art`'s QA and `run.py` fixes into `tools/imagegen`
   before any full sync, so the factory restarts on fixed tools.

### 5.4 The queue for Codex's return

The lead writes these rows and manifests now and runs
`python3 -I tools/art/check_queue.py` on them, so that "çalış" works on
the first day. Order by what the trial build hides.

| Order | Batch | Jobs | Unhides |
|---|---|---|---|
| 1 | `batch-82-koke-redo` (exists) | 2 + 1 promote | Koke 0 to 2 at final colour, and stage 1 v2 |
| 2 | `batch-83-visitor-edits` (exists; drop Damla if the scripted erase passed the critic) | 1 or 2 | Sumi |
| 3 | Visitors for the residents the demo hides, in batch-78's method | one per hidden resident | Every weekday's visitor |
| 4 | Koke at phone resolution: a portrait sky master and five stage plates, as Çağlayan has (the shipped stage 4 is 716 px wide on a 1206 px screen) | about 6, after a 2-job pilot | A soft, small Koke |
| 5 | Home continuity edits from the follow-ups list (the wheel's sunflower at IL3 to IL6, IL5's early warm pool, the whale at IL2 night) | about 6 | Level-to-level slips |
| 6 | Home golden hour, IL1 to IL7 | 7 | The "golden borrows the night" rule |
| 7 | A painted breath room and a painted harbor close-up, only if the code versions fail their critic | 1 to 2 | |

If the plan that returns is smaller, run Demand only, in this order, and
leave Stock until Demand is empty. Make the first job on return the
smallest one, as a check that the tools still work. Add one line at the top of `pofu-art`
`QUEUE.md` now: paused since 2026-11-12, rows stay READY.

## 6. The route

At most three builders at once; one Swift build at a time; each PR at
most three pushes. "Eye" means a critic at 1:1 crops, then the lead's one
look. Frame names in **bold** are new and are rendered at 1206 x 2622 PNG.

### Friday 11-13

| # | Step | Who (model, effort) | Done when |
|---|---|---|---|
| 0 | Merge #412 on green, #408 after its night fix and one look at `koke-sky-s2-night`, then #403. Set the `now.md` goal to "trial build, Monday 11-16" and the Route line to this file | Lead | `main` carries all three |
| 1 | Facts: (a) can a drag pan the Island stop while Home is painted, and does a build pan to its station there (`IslandSceneModel.pan(to:)`, `CameraRig.panDrag`); (b) which residents can visit in days 1 to 21 and which have a shipped painted asset; (c) where the Today header and the breath's disc are drawn; (d) can any screen reachable in either build spend seeds on minutes; (e) how the frame meter is switched on from the phone | Scout (Haiku, low) | Each answered yes or no with file and line |
| 2 | **Device check, ten minutes, Home only** (his choice): install `main`, switch the frame meter on, press Next day five times, Night once, build twice. Five answers: smooth or not; warm or not; are the characters large enough; do day and night colours look right on the real screen; anything broken | Founder | Five lines in the founder log |
| 3 | **The Map is painted** (R4, R5) | Builder (Opus, high), one owner, eye | **`map-plate-l2-day`, `-l5-day`, `-l7-night`**, **`flight-home-koke-mid`**: no code sky, no sprite isle, no ghost behind Home, a name on every stop; `DemoRunTests` green with the rumour days unchanged |
| 4 | **Çağlayan is a full frame at every hour** (R7) | Builder (Opus, high), eye | `caglayan-plate-full-s0-night` to `-s4-night`, `-s4-golden`, `-s4-rain`: painted from top to bottom, no flat band, no hard horizontal edge at 1:1; `plates.yaml` `sky_sets` filled; a flat-band rule added to `tools/plate/screen_check.py` |
| 5 | **Koke healed, clean** | Builder (Opus, medium), eye | `koke-stage-4`, `koke-sky-s4-golden` and one night frame: no pale block or fringe at 1:1; a check that fails on opaque source-background pixels outside the silhouette, run over all five stages |

### Saturday 11-14

| # | Step | Who (model, effort) | Done when |
|---|---|---|---|
| 6 | **Visitors and gifts in painted art;** unpainted visitors hidden (R3) | Builder (Sonnet, medium; recipe: the plate-life PR and `tools/art/ingest.py`) | `home-plate-full-life-visitor-l5`, `-gifts-l5`: no code stand-in; `somethingNewOnScreenEveryThreeDays` and `everyDayIsTended` green; a test that a resident without art never visits |
| 7 | **The player-path frames** (R10): the tester's 21 days as the player meets them, with the paintings on: Home at 09:00 and 23:00 for each day's level, the Map, each Koke and Çağlayan visit, the sheets, the games, the onboarding screens; one contact sheet per week. Sprite-fixture frames get a `sprite-` prefix | Builder (Sonnet, medium), tests | **`path-d01-0900`** to **`path-d21-2300`** on the screenshots branch; no path frame is rendered with `homePlates = false` |
| 8 | **One voice:** one word for the seed; the Today header is a live crop of the island's painting; a met goal says the level is ready; Koke and Çağlayan show their name and state; the flow caption moves up; the breath sits on the gate's painted lawn; the pan is clamped to the painting if step 1 (a) says yes | Builder (Sonnet, medium), screenshots | The named frames; `15-menu-today-v3-day` shows the painting; no "tohum" left where the jar is meant |

### Sunday 11-15

| # | Step | Who (model, effort) | Done when |
|---|---|---|---|
| 9 | Three critics on the week sheets and their 1:1 crops, each blind to the others: art (against Home at IL5 day), player (would I know what to do), contrarian (the worst five frames) | Critics (Opus, medium) | Three defect lists |
| 10 | One fix round on what the critics rank first; the closing beat for day 21 if it fits in lines and art in hand (story desk, `pofu-story`) | The same builders, continued | The path frames re-rendered |
| 11 | **Cut line, 18:00.** Hide what is not accepted (section 5.2). One look at the three sheets. Record the Rehearsal path (CI `beats` label) | Lead | `main` green; the recording committed; a five-line note for the founder in Turkish: what to try, what is hidden and why |

### Monday 11-16, evening: the trial

He installs `main` and plays days 1 to 21 through the Prova panel, with
"Ada ortamı" switched on. Nothing is asked of him while he plays. After
it the lead logs his words and brings them, with the path frames, to one
Fable pass that writes the next route.

### Tuesday 11-17 to Tuesday 11-24

His fix list first; then section 5.3 in order. The membership arrives
with the seeds check done and the gate's first day rehearsed.

**If a step fails.** Step 3 not accepted by Sunday noon: the trial ships
with the Map as it is, and the note names it as the one old screen. Step
4: borrow (section 5.2). Step 5: if the matte cannot part the petals from
the bear, a hand-drawn polygon mask committed as a file and applied by
script. Step 2 reports heat or stutter: one builder moves to performance
at once, ahead of step 8.

## 7. The studio while Codex is down

1. **The art-reviewer has no deliveries;** its eye is the frame critic's
   this week. No new role.
2. **Editing art by script is now routine work,** so it needs one rule:
   the picked take is never overwritten, the edit is a script in
   `tools/`, and the state table says the cell is edited in code. Then
   Codex later repaints from a true record.
3. **The desk table's "truth" for Look** should read "the player-path
   frames" once step 7 lands. This is a change to `studio.md`, so it
   goes to the founder first.
4. **The factory's rule "Codex never idles" is suspended;** the desk row
   in `now.md` should say paused, with the queue kept ready (section 5.4).
5. **The chapter is "Trial build 1"** with a cut line and a date. A
   chapter with a cut line is new here, and it is what stops polishing
   from having no end.
6. **Fable next at the trial's feedback,** not before: the route above
   is routine briefs from here.

## 8. What I did not check

- Whether a player can reach the pan that shows the painting's edge. The
  three frames are fixtures with a held pan; step 1 (a) settles it.
- The Map build's size. I read where the painting fades with distance
  (`PofuWorld/Plate/PlateHomeViews.swift:46-52`) and #408's description,
  not the camera code. It is the largest step and the one most likely to
  meet the cut line.
- Onboarding, the Prova panel's sheet, the weekly recap and the care
  beat: no frame of them is on the screenshots branches I opened.
- Sharpness of Koke's stages 0 to 3 at 1:1: the frames are 460 px wide.
- Performance, memory and app size on a phone. Nobody has: that is
  step 2.
- The picked Çağlayan sky masters at 1:1. I read their reviews only.
