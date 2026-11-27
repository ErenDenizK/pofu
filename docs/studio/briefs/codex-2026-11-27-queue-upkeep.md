# Brief: Codex queue upkeep and refill (2026-11-27)

Role: `.claude/agents/builder.md`. Repository: `ErenDenizK/pofu-art`.
Do the work in your own worktree, on branch `queue/2026-11-27-upkeep`,
as one PR.

Why: Codex delivered faster than the queue was kept. Rows it has already
delivered still read READY, so it could run them again. Only D49 (186),
D50 (187) and D51 (188) are left, about 24 jobs, which is under two days.
The founder's rule is that Codex is never idle.

## 1. Move the delivered rows to `QUEUE-LOG.md`

Check every claim below against `design/art/takes/` on main first; a
false premise is a result.

These rows have takes on main: R1, R2, D44 (181), D46 (185), D47 (184),
D34 (171), D43 (180), D48 (183), D40 (177), D41 (178), D45 (182),
D52 to D55 (189 to 192) and D57 (194).
- Move each to the log with its PR number(s); `git log` on main finds
  them.
- Run `python3 -I tools/imagegen/check_takes.py` on each batch and log
  the bad count.

D42 is dropped (island-calendar C5), so it goes to the log as dropped.

Update the prose lines that count rows ("Rows D29 to D33 ...") so they
stay true.

## 2. Unblock the pier (D56)

Read D56's row: the erased plot crop joined the islet to the island.
Add a new row, ahead of D56, with its own manifest under
`tools/imagegen/manifest/`. It paints a bare crop of the pier's plot
that:
- keeps the water gap between the islet and the island;
- keeps the rope bridge;
- removes only the pier station.

Model it on batch 117's pier erase job and say in the prompt what that
job got wrong. Then D56 names this row's pick as its parent and becomes
READY behind it.

## 3. Refill with at least two days of work (about 40 or more jobs)

Rows come only from approved plans:
- pofu `docs/design/mainflow-plan-2026-11-26.md`;
- `docs/design/season-system-v1.md`;
- `docs/design/island-calendar-v1.md`;
- `docs/design/motion-vocabulary.md`;
- the music spec has no art.

Find what those plans still need painted and is not queued or
delivered. Candidates to check:
- the night relights of the four new plot ladders (as D51 does for the
  windmill);
- the Gezgin's leftovers named in the plans;
- characters' poses beyond 181 if a plan names them.

Do **not** queue:
- Çağlayan's production: card 4 is with the founder;
- the rest of autumn (S4): it waits for his look at the pilot.

Each new row:
- has its manifest (prompt, parents, checks), as the existing rows do;
- is EXPLORATION unless a plan says production;
- carries "run check_takes.py before every push".

Keep the order: step-1 rows first (D56's bare crop, then D56, then
D51), then the rest.

Run the repository's own checks on manifests, whatever `tools/imagegen`
offers (`--help`), and say which ones you ran.

## Hand-back

- PR number and head SHA; CI if any.
- The rows moved, with their bad counts.
- The new rows, each with its job count and the plan line it comes
  from.
- What you found a plan needs but left out, and why.

Do not merge. Never run `sync_to_art.py --prune`. Disk floor is 5 GB.
