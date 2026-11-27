# Gather brief: the main flow today, raw facts (2026-11-26)

Role: `.claude/agents/scout.md`. You collect raw facts for Fable, who
next plans the path to a flawless main flow. You do not judge, propose or
rank. Every line carries evidence: `path:line`, a commit, a PR number, or
a command and its output. A claim you could not check is UNCHECKED.

Read `origin/main` of ErenDenizK/pofu (`/home/user/pofu`: `git show`,
`git grep`; no checkouts, no builds, no pushes) and pofu-art main
(`/home/user/pofu-art`, same way). The 11-23 gather
(`docs/research/assessment-2026-11-23/raw-app-and-code.md` and
`raw-art-and-line.md` in `/home/user/wt/lead-docs`) is the baseline:
report what changed since and what it got wrong, do not repeat it.

For each part of the main flow the founder named, list: what exists in
code (files, flags, tests, frame tests), what art is shipped vs only
delivered as takes in pofu-art, what is code-drawn placeholder, what the
docs say is planned but not built, and open issues/PRs about it:
1. camera (map, near lens, pinch, transitions);
2. Home and station levels, objects that grow on the island, overall
   island progression (how a level is earned, what changes on screen);
3. Home themes;
4. travel between islands; the Gezgin at every stage;
5. islands on the map / in the voyage, visual state;
6. characters: movement, animation, interaction;
7. what makes it feel alive (water, ambience, sound, weather, time);
8. menus (Settings, Today, cards, onboarding).
Also: islands planned and approved (which, with which art ready); the
mini-games (Flow board etc.) and how much effort went to them (PRs and
pofu-art batches since 11-10).

Write `/home/user/wt/lead-docs/docs/research/mainflow-2026-11-26/raw-mainflow.md`
(do not commit). Hand back the path and a 10-line summary.
