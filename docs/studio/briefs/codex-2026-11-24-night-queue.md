# Brief: a long Codex queue for the night (2026-11-24)

The founder approved this (founder-input 45): he is asleep. Codex's
queue (rows D20 to D23, batches 157 to 160, 30 jobs) ends in a few
hours. Before it does, add enough new rows that the line runs until
morning without a new "çalış". If a job hits the quota wall, Codex
records it and moves to the next row; it does not wait.

## What the work must serve

The path is `docs/design/assessment-2026-11-24-path.md` on pofu main,
section 4 especially. Read it first. Every batch serves one named step
of it.

The method is the founder's point 10. Codex paints what he needs to see:
- single parts (material, texture, icon, ornament, blocks, the Gezgin);
- where a step needs it, a whole screen's composition.

Codex never paints glass or working interface: the interface is tried in
the app. Keep the concept-art feel calm and simple, with fewer things in
frame. He disliked "cafcaflı" (flashy).

Candidates. Take, drop or replace them by your judgement; aim for about
40-60 jobs in 4-6 batches:
1. **The station card's ornaments for every station** (stage 2.1).
   Batch 159 paints the level mark and two ornaments as samples. Extend
   the ornaments to every station on the home plate (find them in
   pofu's `PofuWorld` station list), as clean cut-outs on a plain or
   alpha ground, small enough to sit on a glass card's edge.
2. **The board kit for the other islands** (stage 2.3, later boards).
   Batch 152 painted single blocks in the Koke, Emanet, Mehtap and
   Revontuli materials. Batch 158 paints the home kit from above on
   alpha. Paint the same kit pieces in those islands' materials, top
   view, matching 158's camera and scale.
3. **The Gezgin's mooring at every island** (stage 4 spec). The
   founder: "her adada nerede bağlandığı önemli". Use batch 160's levels
   (via `approved:` with the QA auto-pick as the parent) and edit them
   onto each island's shipped plate at a sensible berth. Front and
   three-quarter views only, never from behind.
4. **Menu grounds** (the founder's words, fi 40: a gradient through one
   colour fitting the theme, if needed a pattern behind, and a real,
   high-resolution texture on top). Paint a few full-bleed grounds as
   textures only, with no UI on them, for Settings and the card's
   backdrop.
5. Anything else a path step needs that you find while reading.

## How

- Use your own pofu-art worktree:
  `git -C /home/user/pofu-art fetch origin && git -C /home/user/pofu-art worktree add /home/user/wt/art-night -b art/night-queue-1124 origin/main`.
- Follow `AGENTS.md` and `QUEUE.md`. Batches 157-160 are the nearest
  examples. The next free batch number is 161.
- Validate each manifest with
  `python3 -I tools/imagegen/run.py plan --manifest <file>` (exit 0).
- Add the Demand rows after D23, in your order, all READY, with row
  fallbacks.
- In the Demand intro, state the night rule: at most two concept jobs at
  once; on a quota wall, record the skip and go on to the next row.
- Open one PR in pofu-art.

## Hand back

The PR link, one line per batch with what it serves, and what you
dropped. At most 15 lines.
