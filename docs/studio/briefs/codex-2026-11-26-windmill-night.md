# Brief: Codex row for the windmill's night looks and level 1 (2026-11-26)

Role: `.claude/agents/builder.md`. PR 1b (pofu #521, merged) put the
windmill's day looks 2 to 5 on the island. Three gaps remain; one
Demand row, one manifest (next free batch number on pofu-art main),
inserted right after D45 in Demand, one pofu-art PR, not merged:

1. **Night relights** of looks 2 to 5 (plan row C5; batch 134 picks:
   w2 t2, w3 t1, w4 t1, w5 t1): edits of those takes, lit windows and
   lanterns, the same silhouette, night light matching the shipped
   night plates.
2. **A level 1 look**, day and night: the empty plot with a millstone
   and a small wooden wind wheel, in the same frame and scale as
   batch 134's plot paintings (batch 134's level 1 had no usable take).
3. **Island level 8's erased base** (the windmill first appears there):
   check `design/art/takes/batch-117-station-erase-volume/*l08*`
   review.yaml picks. The windmill builder found none usable; the art
   review recorded day L8 pick 1 (new) and night L8 pick 1. If a pick
   exists, say so and add nothing; if not, add an erase job as an edit
   of the shipped IL8 day plate by batch 117's prompt, keeping the pier's
   bridge, gap and islet rim.

Validate with `python3 -I tools/imagegen/run.py plan --manifest <file>`
(exit 0). Disk is tight: sparse worktree, remove it when done. Hand
back: PR link, row, jobs, and the l08 finding. At most 8 lines.
