# Codex art line: raw production history (batch 60 to 120)

Sources: pofu-art `origin/main` (fetched 2026-11-15, 9633f18) and the `origin/art/batch-*` branches of the open PRs (the lead's `lead_review` text sits on those branches, not on main); pofu `origin/main` 83e2e394. PR numbers are pofu-art unless marked "pofu". Shipping check: `git grep "batch-NN-" origin/main -- design/art` (provenance.md/meta.json) and `docs/state/plates.yaml` in pofu.
Counts in "delivered" come from the PR's pulse line `Factory: ... n/m delivered`. Verdicts are the `lead_review` field; "auto" = only the QA auto-pick exists (no lead_review).

## 1. Batches

Shipped column: **S** = something is in pofu provenance; **plates.yaml** = cited as the source of a painted plate cell (not a provenance.md hit); **no** = no hit for the batch name in pofu `design/art/**` or `docs/state/plates.yaml`.

| Batch | Kind | Jobs | Delivered | PR (state) | Lead verdict, one line | Shipped |
|---|---|---|---|---|---|---|
| 60 earth-face | production | 3 | dropped | none | DROPPED, collage era (QUEUE-LOG row 0-e) | 3 provenance files name it (collage-era) |
| 61 ui-kit-v3 | production | 34 | 23 day pieces picked | pofu #392 | 23 day pieces picked; stamps t1, tab ribbon t3 promoted; 7 night pieces redone in 77 (QUEUE-LOG 0-u) | S (24 provenance files) |
| 62 breath-room | production | 10 | done | n/a | picks: halo, spark, petals; scene obsolete (Door retires the breath room) | S (3 files) |
| 63 empty-states | exploration | 9 | 9/9 | #9 open | 9 picked, "never produced" (asset-system-v1 s3 row 10) | no |
| 64 flow-pieces | production | 23 | 24 per log | pofu #392 | splash 1 promoted; bend, split, gate, wheel, frame, water redone in 77 | S (8 files) |
| 65 growth-pieces | production | 15 | delivery #350 not merged | n/a | obsolete, collage era, DROPPED | no |
| 66 home-flow | exploration | 16 | done | pofu #359 (merged) | root `x-home-flow-final-rich` t1 picked as master | S + plates.yaml (15) |
| 67-70 caglayan / revontuli / emanet / mehtap flow | exploration | 9 each | done | pofu #327 line | stage-4 roots picked, stages 0-3, bares as edits of root | S (1 each) + plates.yaml (9 each) |
| 71 home-redo | exploration | 3 | done | pofu #366 (merged) | redo of rejected il1 / bare / rain | plates.yaml (1) |
| 72 home-night | exploration | 8 | done | pofu #367 (merged) | night edits IL2-9 | plates.yaml (7) |
| 73 islands-states | exploration | 24 | done | pofu #369 (merged) | golden, rain, night per island | plates.yaml (15) |
| 74 redo-states | exploration | 11 | done | pofu #386 (merged) | redo of rejects of 71-73 (bare-v3, il1-v3, night fog...) | plates.yaml (8) |
| 75 portrait-islands | exploration | 16 | done | pofu #386 (merged) | sky-set masters; edits used the unpicked Caglayan t2 (QUEUE-LOG 0-h3) | plates.yaml (13) |
| 76 redo-picks | exploration | 5 | 5/5 | #1, #2 closed unmerged; #13 merged | all 5 picked, with warm/lift notes for the colour fit | plates.yaml (6) |
| 77 redo-61-65 | production | 19 (27 per PR) | 16/27, 11 skipped | #14 merged | 7 night UI recolours approved (`--force`, edit_structure "false fail"); frame t2 ship at 240 px caps; split/wheel no ship; dribble 2-4 not generated | S: 3 of 7 night pieces (bubble, card-linen, face-disc) |
| 78 plate-life | production | 6 | 5/6 | #18 merged | fountain t1 re-promoted; gezgin t1 `--force`; Damla t1 needs stroke erase; Sumi t1 needs fur/lid edit | S: parcel, fountain, moss-lawn, damla, gezgin. Sumi: no |
| 79 flow-redo | production | 5 (12 per PR) | 12/12 | #25 merged | dribble 2-4 picked (t1/t2/t2); split and wheel "No ship", both narrowed the groove | no hit for "batch-79" |
| 80 home-il1-night | exploration | 1 | 1/1 | #23 merged | t2 picked, cool the grass in the fit | plates.yaml (1) |
| 81 koke-final-colour | production | 3 | 2/3 | #24 merged | stage 1 t1 ship; stage 0 greyed whole island, no ship; stage 2 lime moss, no ship | no |
| 82 koke-redo | production | 2 + promote | 0/3, 2 skipped | #28 closed (403 records), #33 open | Skip both: t1 changes composition/scale, t2 desaturates; nothing promoted | no |
| 83 visitor-edits | production | 1 | 1/1 | #32 open | auto: t1 (harmony 72.6 vs 70.5), promoted in pofu-art; no lead review | no (no `visitor-sumi` in pofu masters) |
| 84 hidden-visitors | production | 4 | 1/4, 1 skipped | #36 open | auto: Yosun t2 (t1 fail); Boncuk both takes fail palette_drift; Tuli, Nane not run | no |
| 85 koke-phone-pilot | exploration | 2 | PR says 0/2; reviews list 2 picks | #37 open | auto picks only (tight t2, portrait t1) | no |
| 86 home-continuity | exploration | 7 | 7/7 | #35 open | auto picks, all QA warn | no |
| 87 home-golden | exploration | 7 | 7/7 | #38 open | auto picks, "pink-lilac and peach golden"; no lead review | no |
| 88 duo-icons-pilot | exploration | 2 | 2/2 | #40 open | recipe A (sheet attached) wins, line ~1/4 heavier; recipe B loses | no |
| 89 emoji-pilot | exploration | 2 | 2/2 | #42 open | Pofu t1 on-model, calm/happy/sleepy/worried read at 20 pt; Mochi t2 3 of 6 blur | no |
| 90 flow-stone-pilot | exploration | 2 | 2/2 | #41 open | right material but orange rim, light fall, half-clumps; sheet grid = "pillowed slabs"; not ready | no |
| 91 door-pilot | exploration | 3 | 3/3 | #43 open | night t2, pier root t1 (sky "pink-lilac candy"), hourglass t1 (no value range); none ready | no |
| 92 widget-pilot | exploration | 1 | 1/1 | #44 open | t2 picked, reads as the door in a second | no |
| 93-103 home golden/night cells (il1-il9, bare) | production (plate cells) | 1 each, 11 | 5/11 (93, 96, 98, 101, 102 delivered) | #53-#63 open | none reviewed by lead; QUEUE.md step 6: "batches 93 to 103 mostly failed QA" | no |
| 104 home-bare-night | production (plate cell) | 1 | 0/1 | #66 open | skipped, 4 takes failed palette_drift | no |
| 105 emoji-volume | production | 5 | 3/5 | #69 open | auto only: mochi/simit/goat t2; pofu skipped (master 919 KB lossless), findik fails detail_budget | no |
| 106 duo-icons-volume | production | 2 | 0/2 | #70 open | skipped, both sheets fail detail_budget (10.6/10.1, 8.0/8.6 vs R1 5.3) | no |
| 107 near-dressing-pilot | exploration | 3 | 3/3 | #71 open | all three t1 over QA's t2; tufts end in a flat "shelf" base | no (pofu spec s7: ingest "when the lead records a pick") |
| 108 station-erase-pilot | exploration | 2 | 0/2, 2 skipped | #72 open | all 4 takes erase the station but re-render the whole plate; paste back one take through a feathered mask | no |
| 109 cloud-kit-pilot | exploration | 2 | 1/2 | #73 open | lip t2 (wrap by script, seam limit "ill-posed"); tower: neither, "mushroom cloud" | no |
| 110 near-patch-pilot | exploration | 1 | 0/1 | #74 open | t4 picked (sparse lawn; takes 1-2 "wallpaper"); pale ring removed by edge decontamination | no (spec s7 lists "pick 4") |
| 111 world-home-props | exploration | 1 sheet | 0/1 | #76 open | t1 picked; reads as plate; QA skip was pale fringe/specks | no |
| 112 world-concept-frames | exploration | 8 | 8/8 | #78 open | map-locked t1, mid-locked t1, near-locked t2, storyboard t1, near-free t1 picked; map-free and mid-free "Not shown" | no (used by pofu `tools/proof/concept_fit.py`, PR #472, not the app) |
| 113 key-island-pilot | exploration | 1 | 1/1 | #79 open | No pick: key colour fails A, B, C; network matte passes | no |
| 114 flow-stone-v2 | exploration | 4 | 4/4 | #81 merged | `x-flow-stone-c` t1 "ready to ship"; d (unrotated only) and even (fallback); b no pick | **S**: `ui-flow-stone`, `ui-flow-stone-2` (c t1, c t2); pofu #476 |
| 115 cloud-tower-v2 | exploration | 1 | 1/1 | #83 open | t1 picked, mushroom gone, a broad haystack | no |
| 116 home-mist-clear | exploration | 2 | 2/2 | #84 open | both t1 accepted: network matte passes M1-M6, M11 | no |
| 117 station-erase-volume | exploration | 20 | 19/20 | #85 open | 17 picks "for paste-back" with hand fixes; l01-night, l04-night, l08-day "not reviewed at 1:1"; l05-night skip note wrong | no |
| 118 cloud-forms | exploration | 2 | 2/2 | #88 open | auto picks only (forms t2, bank t1); no lead review | no |
| 119 near-lawn-and-foreground | exploration | 3 | 2/3 | #89 open | auto only; lawn tile skipped (seam 2.23 / 2.06 vs 2.0, daisies repeat) | no |
| 120 far-isles-haze | exploration | 2 | 2/2 | #90 open | auto only (isles t1, whale t2) | no |
| 121 flow-banks-ab, 122 far-camera-ui | exploration | 7, 3 | not run | none (queue PR #91) | READY rows 0-d1, 0-d2 | no |

Also run on the same loop: Stock reruns `batch-31` v1-v4 (#6, #19, #45, #86), `22` v1-v3 (#7, #20, #46), `23` v1-v3 (#8, #21, #52), `25` v1-v3 (#12, #39, #47), `26` v1-v3 (#10, #48, #49), `27` v1-v3 (#11, #50, #51); all open, unreviewed.

## 2. Methods

**Worked**
- Recolour edit of a picked day piece for night UI: 7 of 7 got lead picks (batch 77 reviews, "even cocoa face ... on the day outline"), but QA fails `edit_structure` every time ("a light-to-dark recolor always inverts the parent's light structure"), so each needed `--force`. Only 3 of 7 have provenance in pofu.
- Whole object per job, edit of a picked parent, small change: batch 78 (parcel, fountain, moss); 83 Sumi (fur and lids, harmony 72.6); 116 mist clear (M1-M6, M11 pass on the network matte; the parent failed M11).
- Plate edit then paste-back of only the erased region through a feathered mask: lead picks per job in 108 and 117 (e.g. 108 tea: "leaves no seam at 1:1 or at 2.5x"). Every take re-renders the whole plate (108: mean 2.8/255 outside the box by the lead, 5.1-5.3 by Codex; pixel-stable limit 1.5).
- Attaching the shipped sheet as style (batch 88 recipe A) beat describing it in words (recipe B drifts heavier).
- Locked concept paint-overs (112): `concept_fit` (pofu #472) shows islands and controls within 1 px for map-locked, mid-locked, near-locked t2; near-locked t1 moved the back control 34 px.
- Style-lock pilots that fix the contract first: 114 c tiled "no seam, rim, gradient or cut moss at 1:1 (wrap step 0.3/0.5 L)".
- Separate one-stone edits of a picked blank (114, after 90's grid failed): c is the strongest; b, d, even still show rotation seams.

**Failed**
- Edit meant to keep pixels: 108 (4/4 takes per job fail the pixel-stable check), 113 (only about 18 percent of parent pixels unchanged, per its review note), 82 (t1 "changes composition and scale", t2 desaturates; 0/3, both redo jobs skipped).
- Key colour (113): 0.04 % / 0.00 % of the field within 4 of #00FF00; field mean (4,249,8) and (10,248,10); edge p95 14-41 px off the source; the lighthouse beam blends into the green. Network matte of the same plate passes M1-M6, M11 (116 confirms on il1/il2). Lead also notes the premise was wrong: il9 is level 9, not level 1.
- Sheets as a grid: 90's 2x2 came back as "four pillowed slabs with bevelled, shaded edges"; 105/106 sheets: emoji-findik and both duo sheets fail `detail_budget`; 111's sheet had fringe and specks in all 4 takes, yet the lead picked t1 as plate-true.
- Junction pieces that must meet at the pixel: batch 79 split and wheel "No ship" (groove narrowed, hard emit box leaves 28 px notch); batch 77 split (north branch 150 px vs 300), wheel (70 px channel vs 300). asset-system-v1 s4.1: "flow junction tiles failed twice and were withdrawn."
- Seam checks on smooth or textured art: 109 lip 4/4 takes fail (3.32 to 10.79 vs limit 1.5), lead calls the limit "ill-posed for smooth cloud" and wraps by script; 114's manual 2x2/rotation check fails the 1.5x threshold for all 8 takes (b/c/d/even) while the lead's 4x3 board look passes c; 119 lawn tile fails (2.23, 2.06 vs 2.0). The wrap script the manifest names does not exist in pofu-art (PR #89 body).
- Golden / night edits as production plate cells (93-103, 104): 4 skipped for palette_drift or chroma_ceiling after a retry round; 87's exploration of the same cells ends "pink-lilac and peach".
- Prompt paraphrase: PRs #69, #70, #72, #76 note "the built-in image tool received an operator paraphrase / adaptation of the manifest prompt".

**Style blocks**
- `prop-style-v2` (tools/imagegen/blocks/prop-style-v2.txt:11) says "a faint warm rim light along the right edge". 90's lead review: "the style block's warm rim paints an orange band about 15 px wide down the right edge" (the stone job uses `prop-style-v2` per batch-90 manifest grep). `style-anchor-v1` has the same rim line (blocks/style-anchor-v1.txt:5). batch 114's manifest asked for "even top-down light and no rim" (QUEUE.md row 0-b1); its `x-flow-stone-even` t2 then has rim and light fall gone (edges within 1 % chroma) but wrap steps 1.3 to 2.4 L (lead review).
- `prop-style-v2` asks for "warm diffused key light from the upper left" (blocks/prop-style-v2.txt:10-11); 114 b, from the same style, keeps "a left-to-right light fall of about 6 L".
- Cloud and plate looks: 115 notes "glossy and strongly airbrushed rather than matte clay" (PR #83); 109 tower read as a mushroom because the prompt asked for a column wider toward the top.

## 3. Consistency problems (with source)
- Light: 90 stone luminance 233 to 207 top to bottom; 114 b 6 L left-to-right fall; 117 `l01/l02-day` takes' lawns "yellower than this misty parent" with a box seam; 94 t3/t4 "too close to daylight"; 76 colour fit notes (Emanet night L 64 under the night median band).
- Palette drift: 81 stage 0 earth peach (248,201,160) to grey (185,181,179); 81 stage 2 moss 97 % lime, chroma p95 69 vs 51; 91 pier root sky chroma p95 59 vs 51; 87 golden = pink-lilac; 84 Boncuk both takes fail palette_drift; 103 grass "too yellow"; 116 palette drift 11.5-35.5 % off palette (PR #84).
- Repetition: 110 t1/t2 "repeat a yellow fan-tuft pattern like wallpaper"; 119 lawn tile repeats daisies in 2x2; 114 d centre patch "repeats as a grid rhythm".
- Scale: 84 Yosun size vs Mochi flagged (PR #36); 112 map-free repaints Home "at about 1.9 times the guide's size"; near-free Pofu 2.3x; 78 moss is small on its canvas; 112 free takes composed for 1024 px, not the middle 706 px.
- Takes that redrew the subject: 91 night t1 moved both wall pebbles and added a third (lead picked t2); 94 t1/t2 added a moon and stars copied from the light references; 95 t2 "adds a whale copied from the light reference"; 120 isles t2 "adds an unrequested windmill"; 75 Caglayan t2 "paints a second Caglayan in the sky" (QUEUE-LOG 0-h3); 108 t4 adds a flower clump, t1 erases hilltop flowers; 117 takes erase path lanterns and the rope bridge (8 of 20 lead notes ask for a hand paste-back of a lantern, bridge post or left-rim daisies); 112 near-locked t2 paints out the island rim and doors "as lawn".
- Refusals and tool errors: PR #28 "HTTP 403 Forbidden" from the built-in image tool for batch-82 stage 0 and stage 2; batch-77 dribble 2-4 "Not generated (a concurrent request was refused)" (review.yaml status skipped); `emoji-pofu` rejected on the upload cap, not content. No content refusal is recorded elsewhere in the reviews read.

## 4. Queue mechanics
- Empty queue: PR #52 "next: standing plate work"; PR #85 "next: queue exhausted"; PR #90 and others "next: stock". The line then ran the standing plate cells 93-103 in one evening (PRs #53-#63 opened 2026-11-14 17:46 to 19:06, 8-10 min apart; 6 of 11 skipped). PR #64 paused that step at 20:23 ("batches 93 to 103 mostly failed QA", QUEUE.md step 6).
- Plan expiry: Codex paused 2026-11-12, resumed 2026-11-14 (QUEUE.md header; asset-system-v1 s4.1).
- Number collision: `batch-104` was used by the home-bare-night delivery (#66); the flow-stone v2 manifest was also 104, so Codex "skipped" row 0-b1 as owned by an open PR; renamed to 114 in PR #80. Branch `art/batch-104-flow-stone-v2` still exists.
- Rows run 3-4 times: Stock `-v2`/`-v3` loop (QUEUE.md step 4): batch-31 four times (v1-v4), 22/23/25/26/27 three times each. `batch-27-ui-materials` v2 and v3 both 0/10 delivered, 10 skipped each (#50, #51); `batch-26 v3` 3/10 (#49).
- Stale rows: QUEUE.md (2026-11-14 resume text) still shows READY for 83-92 and 105-120 whose PRs are open or delivered; pofu build-spec s7: "rows 0-b4 to 0-b8 ... still read READY though they were delivered". A stale pushed branch `art/batch-82-koke-redo` (closed PR #28) is called out in QUEUE.md return-queue item 2.
- Stalled/partial: PR #36 (batch 84) "1/4 delivered | next: batch-84-hidden-visitors", "will be updated as the remaining jobs finish"; branch holds only Yosun, last commit 2026-11-14 11:40; Tuli and Nane have no review.yaml, Boncuk no review.yaml either (skip in PR body only). PR #37 (85) pulse says 0/2 while reviews list picks.
- Missing tool: PR #84: `tools/art/matte_check.py` not in pofu-art, so M2/M11 not run by Codex; PR #89: no half-offset crossfade script. Manifests of 93-103 are not on main (only the branches).
- Upload limits: AGENTS.md:202-206 "connector ... cuts files at 768 KB, silently"; rule 600 KB. Hits: `emoji-pofu` skipped (lossless master 919,288 B, PNG 1,370,217 B; PR #69); batch 119 takes recompressed to q85 (PR #89); gate door delivered at half scale (asset-system-v1 s3, QUEUE-LOG 0-q #308); `files over 600 KB are delivered at half scale` (asset-system-v1 s4.1).
- Stalls from outside: 2026-11-12 pofu-art builder's `merge_pull_request` refused by the classifier (pofu friction.md); `sync_to_art.py` has no path filter (friction.md 2026-11-12); AGENTS.md lead note: tool defects 1-4 (plan counts WebP takes, ingest keeps take numbers, auto-pick order, open-PR ownership).
- Throughput: batch 87 (7 jobs, 14 takes) to 92 PRs opened 11:32 to 12:55 on 2026-11-14; 105-120 span 11:10 on 11-15 to 18:19 (PR times above).

## 5. Delivered, not reviewed or not used
- No `lead_review` and open PR: #32 (83), #36 (84), #37 (85), #35 (86), #38 (87), #53-#63 (93-103), #66 (104), #69 (105), #70 (106), #88 (118), #89 (119), #90 (120), and the Stock variations #6-#8, #10-#12, #19-#21, #39, #45-#52, #86. #33 (82) has a skip verdict.
- Reviewed, picks recorded, not ingested (pofu spec s7, build-spec s6.2): #71 (107, three picks), #72 (108 via paste-back), #73 (109 lip pick 2), #74 (110 pick 4), #76 (111 pick 1), #78 (112 picks, used only by proof tools), #83 (115 pick 1), #84 (116 two picks), #85 (117, 17 of 20 picks). Spec s7 states "whether those pick: values are the lead's or Codex's own I did not check"; on the branches 107-113, 114, 116 and 117 carry `lead_review`.
- Reviewed, nothing usable: #79 (113 key colour), #72 (108 as shipped art), #73 (109 tower), #41 (90 not ready for volume), #43 (91 "not ready to layer").
- Mixed: #81 merged and shipped as `ui-flow-stone` (c t1, t2) in pofu; #18 merged, 5 masters in pofu; Sumi (batch 83) promoted in pofu-art only.
- Waiting on art not yet delivered: build-spec s7 lists 118, 120, 119 as READY rows that wait; they are now delivered with auto picks only (#88, #89, #90).
