# Brief: safe Codex work from the founder's round-1 and round-2 verdicts (2026-11-23)

Codex has been idle since 11-19. Fill its queue with a few concept jobs
that follow only from what the founder has already said, so they stay
useful whatever the coming assessment decides. You write manifests and
queue rows in pofu-art; Codex generates later. No app code.

## The founder's verdict on the concept rounds (verbatim, Turkish)

"Her şey çok cafcaflı, extravaganza çizilmiş. Önce gerçekten konsept art
hissiyle, daha simple bir vizyon sunmasını istemiştim."
- Dere tahtası: en güzeli board-dial t2; oyun dünyasıyla mini oyunu
  harmanlıyor. board-key big de güzel. table güzel değil. pool-tray'den
  emin değil. Blok konsepti ve dokular beğenildi.
- Seviye paneli: ladder olmasın; seviyeler altta bir kez daha
  sıralanmasın. Bubble mı alttan bir panel mi, emin değil. Kafasındaki:
  card gibi cam bir obje, kenarında ya da üstünde ufak bir tasarım.
  Codex'in cam arayüzü uydurma duruyor, bu yüzden uygulamada test
  edilmeli. Menüler genel olarak güzel değil.
- Yolculuk ve Gezgin: A2 (row) mantıklı. Gezgin'i arkadan görmek güzel
  değil. Gezgin'in ilk seviyesi balinaya benzemiyor: kuyruğu olsun,
  pofuduk olsun. 2-3 seviye yeter. Her adada nerede bağlandığı önemli.
- Ada ve istasyonlar: adım adım büyüme fena değil. Gölet için emin
  değil. Gölet gibi adanın önündeki şeylerin arkasında Pofu kalırsa
  görülebilecek mi?

(In short: everything was drawn too flashy; he wanted a simpler
concept-art feel. Liked: the dial board's second take, the big key
board, the blocks and textures. Not liked: the table, the ladder panel,
seeing the Gezgin from behind, menus in general; the glass UI from
Codex looks fake and belongs in the app, not in Codex. The Gezgin's
first level must read as a whale: a tail, fluffy; two or three levels
are enough; where she moors on each island matters. Is Pofu visible
when he stands behind things at the island's front, like the pond?)

Names: round 1 is pofu-art batches 138-145 (`x-...` jobs; `board-dial`
is `x-board-dial-*` in batch 138, "t2" its second take; `board-key big`
is `x-board-key-big`; A2 row is `x-voy-a2-row` in batch 140). Round 2 is
146-153 (`x2-...`). Look at the takes before you write a prompt that
leans on them (`git show origin/main:<path> > /tmp/...` and view; keep to
a few images, at small size).

## What to write

At most four concept batches, about 6-10 jobs each, simple concept-art
feel: calm, readable, fewer things in frame, the island and Pofu's real
look kept (edit from the shipped plate or the approved takes where you
can; `R1` is the Pofu master). Candidates, take or drop by your eye:

1. **The Gezgin, two or three levels.** A whale at level 1 (a tail, soft
   and fluffy, Pofu-world proportions, gentle eyes: closed or bead, never
   heavy half-lids), then two bigger steps. Front and three-quarter, no
   back views. Plus where she moors at the home island (the A2 row voyage
   frame as context).
2. **The board, simpler.** The dial board t2 and the big key board as
   the two directions, quieter: fewer props, the blocks and textures
   kept; one frame each in the game's world as he saw it blended.
3. **Pofu behind the front of the island.** The shipped plate with Pofu
   standing behind the pond (and one other front station) at a low and a
   high level, to show whether he stays readable. A concept question,
   not final art.
4. The re-run of batch 152 (missing block pieces, delivered nothing on
   quota) needs no new manifest: say in its queue row that it reruns
   as is, if that is right after you check it.

No panel or menu concepts: he said the glass UI belongs in the app.

## How

- Your own pofu-art worktree:
  `git -C /home/user/pofu-art worktree add /home/user/wt/art-round3 -b art/concept-round3 origin/main`
  (identity: `git config user.name "Eren Deniz Kuyucaklıoğlu"`,
  `user.email "109629701+ErenDenizK@users.noreply.github.com"`).
- Follow pofu-art `AGENTS.md` and `QUEUE.md` for the manifest and row
  format; batches 146-153 are the nearest examples. Next free batch
  numbers start at 154. Validate each manifest with
  `python3 -I tools/imagegen/run.py plan --manifest <file>` (exit 0).
- Queue rows in `QUEUE.md` Demand, READY, in your order, at most two
  concept jobs running at once as the existing rows say.
- One PR in pofu-art to `main`, via `mcp__github__create_pull_request`
  (`gh pr create` fails here). Commit trailer and PR footer as the lead's
  system gives them to you; no model names. The lead reviews and merges.

## Hand back

PR link, the batches with one line each, and anything you dropped and
why. At most 15 lines.
