scout

# Scout brief: when does Home still draw the sprite island? (2026-11-24)

Answer with file and line, from `origin/main` of pofu (read with `git
show`/`git grep` in `/home/user/pofu`; no builds, no checkouts there).

1. Home has two renderers: the painted plates and the older sprite
   island (`IslandScene`). List every state in which Home falls back to
   the sprite island: island levels, unlock stages, night/time of day,
   other islands (Koke, Çağlayan, others), missing assets, flags, the
   Map, previews. For each, the condition in code.
2. The walk loop: `IslandScene.swift` ~723 computes `residentSteps`
   every frame while the plate discards it. Is that work done on the
   plate path at all? What does it cost per frame, by reading the code?
3. CI timing: from `gh api` REST on ErenDenizK/pofu, the duration of
   each job, in the last five successful runs on main. Mark the jobs
   that come near the 45-minute timeout.

Write the answers to
`/home/user/wt/lead-docs/docs/research/assessment-2026-11-23/scout-sprite-fallback.md`
(do not commit it). At most 80 lines. Hand back three lines.
