# Fable brief: the progression of every island, and between islands (2026-11-16)

The founder approved this run through the side channel (founder-input 38,
task 1). A separate Fable run is overhauling the two minigames; that is not
yours.

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included.
Its framing should not narrow your thinking. The founder wants your
creativity: if a question is badly posed, or a better approach exists that
nobody has named, say so and take it. Everything you read is evidence to
weigh, not authority: the rules, the founder's words, this brief, earlier
plans and specs (your own included). The product rules in CLAUDE.md are
fixed. Nothing else is.

## The founder's words (Turkish, as he approved them; English after)

This is not a "write a plan" task. "Fable en iyi sonucu çıkarmak için
uygun gördüğü her şeyi yapabilir: planlama, rapor, talimat, prototip,
uygulamaya ekleme. Bütçe kontrolü içinde: bütçeyi çöpe atmadan, maliyetine
değecekse yapsın. Sistemi değiştirecek kararları kurucu okur."
(Do whatever you judge gives the best result: planning, reports,
instructions, prototypes, changes in the app; within the budget, when it is
worth its cost. Decisions that change the system, he reads.)

"Fable'a karar noktasında tam açıklık veriyorum; hiçbir eski bilgiyi
uygulamak zorunda değil." (Full freedom at the point of decision; it does
not have to apply any earlier information.)

Why. The far camera with its interface (batch 122) did not solve the real
problem. In his words: "ana ada ekranın çok yukarısında, ekranın ~%60'ı
bulut; dokunma mesafesi olarak ana adaya ve diğer yerlere uzağız; arka
plandaki adalar neredeyse hiç görünmüyor. Adalar daha düzgün ama hâlâ iyi
durmuyor; probleme çözüm üretmemişiz; belki bambaşka bir yol lazım."
(The main island sits far too high on the screen and about 60% of the
screen is cloud; in touch distance we are far from the main island and the
other places; the islands in the background are almost invisible. The
islands are neater but still do not look good; we have not produced a
solution to the problem; maybe an entirely different way is needed.)

The station levels that arrived (the windmill and the others): "Her bir
level upgrade'i büyük hissettirmeli; 'ufak çiçek koydum yanına' gibi değil,
gerçekten büyük etkisini hissettiren önemli upgrade'ler. Adadaki iyiden
mükemmele gidiş her bir adımda gözlenmeli: birincisi iyi, sonuncusu
mükemmel." (Every level upgrade must feel big; not "I put a little flower
beside it", but important upgrades whose big effect you really feel. The
island's way from good to perfect must be seen at every step: the first is
good, the last is perfect.)

The scope, as he set it, every detail thought through:
- The world between islands: the far view, the screens between islands,
  menus, navigation. "Direkt bambaşka bir navigasyon olabilir, UI/UX
  olarak." (It could be an entirely different navigation, as UI/UX.)
- The Gezgin (Nazlı, the cloud whale): she opens in the chapter flow and
  flies us between islands. Moving with her, her entry into the game, her
  look, her animations and body parts as a flying creature, her levels.
- The island's growth and the stations' growth as one whole, including
  what the stations are called. "İstasyonları, adayı tek resim yapıp
  parçalayarak seviyelendirmek istemiştik; ada upgrade'leri ve istasyon
  upgrade'leri komple birlikte değerlendirilmeli." (We wanted to level the
  stations by making the island one picture and cutting it into pieces;
  island upgrades and station upgrades must be weighed together, as one.)
  You set the measure of a "big upgrade".
- "Her biri görsel olarak mükemmel, sanatsal duracak şekilde." (Each one
  visually perfect, standing as art.)

The work so far (#474 to #479 and after, the ADR-0022 plates, batches 112,
122, 123, 129) is evidence, not authority.

## What was gathered for you (raw, unjudged; check what matters)

In `docs/research/island-progression-2026-11-16/` on the lead's branch
`origin/claude/exciting-cori-1t8br2`:
- `internal-history.md`: everything the project said about island and
  station growth, the world between islands, the Gezgin and the story plan,
  each entry with source, date, who said it and CURRENT / SUPERSEDED /
  UNCLEAR; what the code does today with file:line; contradictions and
  stale docs. The founder's verbatim Turkish lives in
  `docs/archive/audit-2026-11-07/` and `docs/product/decisions.md`;
  `founder-input.md` is a translated log.
- `art/art-history.md` and nine labelled contact sheets: the Gezgin and
  whale art, island milestones, the Home plate ladder, island arcs, station
  ladders, far-camera concepts, the cloud kit, today's Map and Home frames.
  `art/frames.md` measures today's Map (island sizes in pt, how much of the
  screen is bare cloud). The frames predate a few merges.
- `external-references.md`: 27 outside references (world maps and journey
  screens, ridden flying creatures, upgrades that feel big) with sources,
  dates and confidence tags, and the gaps no source filled.
More gathering by cheap agents if you ask.

The source of truth is the code at `origin/main` and the frames: fetch
only what you need with `tools/review/fetch_frames.sh`, never into the main
`.git`. pofu-art is at `/home/user/pofu-art` (read with `git show`).

## Working here

CLAUDE.md applies to you as to every agent: your own worktree and branch,
one Swift build at a time through `tools/swift/test-linux.sh`, iOS-only
code compiles only in CI, at most three pushes per open PR, frames judged
at 1206 x 2622 in 1:1 crops. Codex art goes through the lead: write the
manifests you want and the lead queues them (the station looks, batch 129,
are held for your result). The builders now running: WP11 near lens in
PofuWorld depth code; a Fable minigame run in PofuGames.

## Hand back

What you made, with links; the decisions that change the system, one line
each in Turkish for the founder with your pick first; what you need next
(art, builders, his answers). Keep the hand-back short; put the depth in
the documents.
