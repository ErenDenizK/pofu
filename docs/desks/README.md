# Desks

A desk is one line of the studio's work, with its own truth, its own
way of being accepted and its own book. The book is two files, and an
agent working a desk reads them and nothing else of the studio:

- `README.md`, the **charter**: what the desk is for, where its truth
  lives, how its work is made and accepted, what it must never do, and
  what the founder judges. It changes rarely. At most 80 lines.
- `plan.md`, the **plan**: `Now` (at most three rows that can start or
  are in flight), `Next`, `Later`, `Asks` (what another desk or the
  founder owes it), `Decided` (the last ten decisions, each with its
  date). At most 60 lines. Its first line is the desk's pulse: a date
  and what the player would notice.

The **record** is not kept by hand. Every user-visible change already
adds a line in `changes/<branch>.md`; that line starts with its desk in
brackets (`[music] Home has a day tune`), and
`python3 -I tools/studio/pulse.py` groups them by desk.

Three rules keep the books true:

1. **A plan row moves in the pull request that does its work.** The
   builder who merges `feat/music-score` moves MU1 from `Now` to the
   record in that PR, as an art delivery moves its queue row.
2. **A desk writes in its own book.** What it needs from another desk
   is one row under that desk's `Asks`, never an edit to its plan.
3. **The route orders the desks.** The cross-desk order is the plan of
   record named in `docs/now.md` (today
   `docs/design/mainflow-plan-2026-11-26.md`). A desk's plan says what
   is next *for that desk*; the route says whose turn the Swift lane is.

Work that crosses desks carries one tag (`#newyear`) in every plan it
touches; the board groups by tag, so a chapter is seen whole.

## The desks

| Desk | Its truth | Lane | Accepted by | Book |
|---|---|---|---|---|
| **Game** (rules, economy, days, the games' logic) | `PofuCore` and its tests; `DemoRunTests` | Swift | tests, then a recording | to write |
| **World** (islands on screen: plates, light, sky, motion, camera, the calendar) | the player-path frames (1206 x 2622) against the approved reference | Swift | a critic, the lead, then his phone | [world/](world/README.md) |
| **Art** (the factory) | `pofu-art/QUEUE.md`, `docs/state/plates.yaml` | Codex | the lead's picks | [art/](art/README.md) |
| **Music** (music, ambience, cues) | `design/music/score/`, the rendered stems, `PofuSound` and its tests | Python, then Swift | the lint and tests, then his ear | [music/](music/README.md) |
| **Story** (lines, letters, the book) | `docs/product/story-map/book-one.md`; the `pofu-story` skill | words | he reads the Turkish on his phone | to write |
| **App** (menus, onboarding, Settings, the gate and Screen Time, the widget) | `App/`, the CI screenshots | Swift | screenshots, then his phone | to write |
| **Release** (membership, TestFlight, the store page, pricing) | the real store page and the real build | words, then his accounts | he sees the real page | dormant until the membership opens |
| **Studio** (how all of this runs) | `docs/studio.md`, `tools/studio/` | words, Python | the pulse, the session cost, the friction log | `docs/studio.md` is its charter |

A book marked "to write" is written the first time its desk is worked
after this page merges, from the row above and the desk's canonical
docs in `docs/README.md`; until then that row is its charter.

## Lanes

A desk runs when its lane is free, not when the lead has attention.

| Lane | Limit | Why |
|---|---|---|
| Swift | one build at a time | two builds run out of memory (`CLAUDE.md`) |
| Python and data | no limit but disk | music renders, art ingests, tools: no Swift build |
| Codex | its quota | the art line; the queue holds two nights of work |
| Words | none | story, specs, docs |
| His eyes and ears | three cards a day | a picture or a sound, a default, a time |

So the studio at full stretch is one Swift builder, one or two agents
in the other lanes, Codex, and at most three things waiting for him.
