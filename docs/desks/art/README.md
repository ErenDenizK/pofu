# Art desk: charter

**For:** every painted thing. Codex paints in the private repository
`ErenDenizK/pofu-art` under its own `AGENTS.md` and never works in this
one. The slow side of this line has always been the review, never the
painting.

**Read before any work:** this page and `pofu-art/QUEUE.md`. The queue
is this desk's plan; [plan.md](plan.md) holds only what the queue cannot.

## Truth

| What | Where |
|---|---|
| What can be painted now | `pofu-art/QUEUE.md` (Demand, Standing work, Blocked) |
| What was painted | `pofu-art/QUEUE-LOG.md`, `design/art/takes/<batch>/` |
| What is in the app | `docs/state/plates.yaml`, `docs/state/assets.yaml` |
| The look's rules | `docs/design/art-bible.md`; what can move: `docs/design/motion-vocabulary.md` |

## How work is made

- **A row is a manifest and a line in the queue.** The manifest
  (`tools/imagegen/manifest/<batch>.yaml`) holds each job's prompt,
  parents and checks; `python3 -I tools/imagegen/run.py plan --manifest
  <file>` must pass before the row is READY. Rows never say stop, wait
  or ask: they give an order of work, a fallback for each failure and a
  provisional pick.
- **A motion sheet before paint.** A manifest for a place, a prop or a
  character says what moves and by which verb of the motion vocabulary,
  and what is at rest. Water is painted calm; a part that turns is
  painted alone, flat from the front, evenly lit.
- **A new method starts with a pilot of two to five jobs** judged in
  the app. More than twenty jobs on a new method is a premise gate.
- **The queue holds two nights of work,** counted in jobs. Demand is
  what the app waits for; Standing work is what the app will use as
  delivered. Twelve hours without a Codex commit while READY rows exist
  is a row in `docs/studio/friction.md` with its cause.
- **A delivery of takes merges without a look.** Takes are never
  promoted, so merging decides nothing; a look is needed to pick. Picks
  are made when the step that uses them starts.
- **A delivery review is a routine:** an art-reviewer records the picks
  in `pofu-art`; a Sonnet builder ingests them (`tools/art/ingest.py`),
  updates `docs/state/plates.yaml` and renders the in-app frames; a
  critic looks; the lead looks once.
- **Editing art by script:** the picked take is never overwritten; the
  edit is a script in `tools/`, and `plates.yaml` says the cell is
  edited in code, so Codex can later repaint from a true record.

## Accepted by

The lead's picks, on in-app frames at 1:1; then his phone.

## Never

- Paint an interface: glass, a panel, a card, a button, text.
- Paint motion: foam, spray, motion lines, a thing caught mid-move.
- Raise the art account: art runs on the founder's uncle's ChatGPT plan
  with permission, recorded truthfully in provenance. Decided.

## Who works it

Codex paints (the founder starts it with "çalış"; the queue's "How to
work it" is its whole loop). The lead or a spec agent writes rows. An
art-reviewer (Opus) picks. A builder (Sonnet) ingests.
