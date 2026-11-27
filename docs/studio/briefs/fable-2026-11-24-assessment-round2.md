# Fable brief: whole-project assessment, round 2 of 2 (2026-11-24)

Round 1 is yours: `docs/design/assessment-2026-11-23.md` and its Turkish
page, merged in #509. The founder answered and approved every pick
(founder-input 44). This round sets the path. Everything you read is
evidence, not authority, including this brief and your own round 1.

## His answers (from the side channel, verbatim; Turkish)

> Kurucu Fable'ın tüm önerilerini onayladı.
> 1) Apple üyeliği: başvuru muhtemelen hafta sonuna doğru (~27 Kasım), belki yarın. Belli değil; öneri aynen: üyelik aktif olduğu ilk gün Mac başında 1-2 saat, TestFlight/Family Controls başvurusu da aynı gün.
> 2) Sıra: evet (kapı → üç ekran → hareket ve ses → Sefer ve müzik).
> 3) board-dial: kurucu hangi take olduğunu bilmiyor; Fable'ın önerisi (dial-big) geçerli.
> 4–9) Fable'ın önerileri aynen onaylandı: küçük cam kart (iki hâli uygulamada, telefona); ada seçme hem Gezgin'e dokunarak hem sağ alt düğme, Sefer'le; Pofu kendinden yüksek şeyin arkasında durmaz; onur seansı ("Kazan") çıkar, açık izin ana ekranda küçük cam hap; karakterler noktalar arasında zıplayarak; ortam sesi varsayılan açık, Pofu'nun sesi şimdi, müzik sonra.
> 10) Onaylandı, bir ekle: UI gerçekte uygulamada denenir; ama görsel etmenler (bütün ekran kompozisyonu ve tek tek parçalar: malzeme, doku, ikon, süsleme) Codex'le prototiplenebilir ki kurucu görebilsin. Bu bir ek iş değil; görebilmek için yöntem olarak onaylı.

## What moved since round 1

- **Stage 0 is in flight**, so don't duplicate it. A builder is on
  `feat/day1-pass-pill`, with its brief at
  `docs/studio/briefs/stage0-day1-pass-pill.md` (lead branch). It covers
  the pass pill on Home, the honor session cut, and the corrected day-1
  script.
- **A scout answered your round-1 gap:** which Home states fall back to
  the sprite island, the walk-loop cost, and CI job timing. See
  `docs/research/assessment-2026-11-23/scout-sprite-fallback.md` on the
  lead branch `claude/exciting-cori-1t8br2`, worktree
  `/home/user/wt/lead-docs`.
- **Codex delivered round 3 and the 152 rerun**, all merged. The sheets
  are pofu-art `design/review/concept-round-3/{1-gezgin,2-tahta-bloklar,3-pofu-arkada}.jpg`.
  - The quiet dial board was painted from `x-board-dial-fall`, because it
    was queued before his answer. He has since taken your pick,
    `dial-big`.
  - **Codex's queue is now empty.** The line should not stay idle.
- The lead branch holds `docs/now.md` and founder-input through 44.

## The job

1. **The final path.** Write the stages, their order and their
   acceptance:
   - the device days, with whatever the membership date makes certain or
     uncertain;
   - the three surfaces (the station card's two native glass variants,
     the board in the dial-big direction with the painted blocks, the
     Home composition);
   - life and sound (the hops, the resident lines, ambience on, Pofu's
     voice);
   - then the voyage with the Gezgin, and music.
   Say what is stopped or held, and what the lead may decide alone.
2. **The division of work, at most 2-3 Claude agents at once.** For
   every Claude job that comes next, write a brief the lead can hand to
   an agent as is: the role on its first line, facts with `path:line`,
   acceptance in frames. Put them in `docs/studio/briefs/` on your
   branch. Order them. The first two should be ready to start the
   moment stage 0 merges.
3. **Codex, now.**
   - Use his point 10 as the method: Codex may prototype visual factors
     (a whole screen's composition, single parts: material, texture,
     icon, ornament) so he can see them, while interfaces are really
     tried in the app.
   - Write the next Codex manifests and queue rows in a pofu-art PR,
     enough to keep the line busy through the device days.
   - Each job must serve a step in your path: for example the dial-big
     board, the block set's missing members, the station card's
     ornaments and level marks, the Gezgin's three levels as the source
     for in-app art.
   - Keep concepts simple and calm, in the concept-art feel he asked
     for. At most two concept jobs generate at once (quota).
4. **A short Turkish page for him:**
   - the path in a few lines;
   - what he will see and when;
   - anything that truly needs his decision, which should be little,
     since he answered round 1.

## Rules

- Your own pofu worktree and branch (e.g. `design/assessment-round2`)
  and your own pofu-art worktree for the manifests.
- One pofu PR and one pofu-art PR, opened with
  `mcp__github__create_pull_request`; `gh pr create` fails here.
- No app code.
- Cheap sub-agents only for gaps, at most one at once: the builder is
  running.
- Frames come only through `tools/review/fetch_frames.sh`.
- Validate every manifest with
  `python3 -I tools/imagegen/run.py plan --manifest <file>`.

## Hand back

At most 30 lines: the links, the path in five lines, the briefs in order,
the Codex rows, and anything that needs the founder (in Turkish, your
pick first).
