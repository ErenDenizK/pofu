# Brief: step 1's art redos for Codex (2026-11-26)

Role: `.claude/agents/builder.md`. Step 1 of the main-flow plan (pofu
`docs/design/mainflow-plan-2026-11-26.md`) needs Home with every station
erased, and golden plates, for every island level. The review of the old
deliveries (pofu-art #85 batch 117 and #38 batch 87 merged 11-26 with
picks in review.yaml; #61/#62 closed) left these gaps. One Demand row,
one manifest (next free batch number on pofu-art main, likely 182),
inserted FIRST in Demand (step 1 waits on it), one PR, not merged.

Jobs (edits, 2 takes each, deliver scale 1.0, never 0.5):
1. Erase every station from L1 day and L2 day, as edits of the plates
   the app ships now: `batch-116-home-mist-clear` x-home-l1-day-clear t1
   and x-home-l2-day-clear t1 (batch 117 edited the older misty plates;
   follow batch 117's erase prompt otherwise).
2. Golden relights of those same two clear plates (IL1, IL2), by batch
   87's relight prompt.
3. Golden IL8 and IL9 as relights of the shipped IL8/IL9 day plates, by
   batch 87's prompt (batches 101/102 came back half size with a grey-pink
   veil: say warm low sun, no veil, no haze).
4. Mist-clear edits of the IL3 day and night plates (white mist painted
   over the harbour islet in batch-66 il3 t1), by batch 116's prompt.
Every erase keeps the pier's rope bridge, the gap and the islet rim as
they are (batch 117's pier erases filled the gap). Check every parent
path on main; validate with `python3 -I tools/imagegen/run.py plan
--manifest <file>` (exit 0).

Hand back: PR link, the row, job count, anything that did not hold. At
most 10 lines.
