# Brief: PR 2a + 2b, the Gezgin moored at Home (2026-11-27)

Role: `.claude/agents/builder.md`. Main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main) section 4 D5-D7 and
section 6 rows **2a** and **2b** are your spec. Two PRs, in order:
2a `docs/adr-0028-voyage` (the ADR as D5, rewritten to his fi 40/43/44
answers: she stays moored while the player chooses; closes #503's ADR
draft) and 2b `feat/gezgin-moored` (she is moored at the pier at her
level, asleep at night; a tap wakes her with a line and a cue; before she
arrives, her shadow crosses the cloud; the sky set's baked whale goes).
2b may open while 2a is in review.

Art on pofu-art main: batch 160 (her three levels, asleep and awake, cut
out), 171 (front views), 172 (lantern, map scale, night mooring at
Home), 164 (`x5-gez-moor-home-lv1` t1 is the row's reference), 180 (tail
piece and shadow). Judge at 1:1; QA auto-picks unless they fail; record
picks. D6: one cut-out per level and state, moved by code (bob, landing
squash, eyes by swapping asleep/awake, tail sway). D7: her level is data
in `world-map.json`. Pofu never stands behind anything taller than
himself (fi 44); she is never shown from behind.

Acceptance: frames `path-gezgin-moored-l1..l3`, `-night`, `-shadow`; 1:1
crops show no halo; her lines written natively in Turkish and English
(`pofu-story` skill for her voice). Label `screens`; frames only via
`tools/review/fetch_frames.sh`; `changes/feat-gezgin-moored.md`. Another
builder runs 1c (owns `stations` in `plate-home.json`): edit only
`mooring` there. Disk is tight: one full worktree at most. Swift tests via
`tools/swift/test-linux.sh` only. At most 3 pushes per PR after it opens.

Hand back once CI and frames are in: both PR links, CI, a sheet + 1:1
crops (paths), defects still visible. At most 15 lines.
