# Archive

Documents whose decision is made or whose role ended. Kept as history; do
not build on them, and do not load them unless you need the reasoning. The
current set is in the [docs map](../README.md). To archive a doc: `git mv`
it here, add a two-line "Archived YYYY-MM-DD: superseded by X" header, fix
every link (`python3 -I tools/docs/check_links.py`), and add a row below.

| File | Why archived | Superseded by |
|---|---|---|
| [character-exploration.md](character-exploration.md) | Species and style options, decided 2026-10-31 | [ADR-0010](../adr/0010-illustrated-hamster-art-direction.md) |
| [naming-exploration.md](naming-exploration.md) | Name options, decided | [ADR-0007](../adr/0007-product-name-pofu.md) |
| [home-directions.md](home-directions.md) | Three Home directions after the room failed | [game design](../product/game-design.md), [ADR-0016](../adr/0016-pre-planned-idle-archipelago.md), [ADR-0018](../adr/0018-visual-system-v1.md) |
| [local-agent.md](local-agent.md) | Brief for a local Mac Claude session; the founder no longer runs one (2026-11-02) | `CLAUDE.md`, [membership day 1](../local/membership-day-1.md) |
| [local-reports/](local-reports/) | The local agent's three reports of 2026-11-01 (environment, iOS 27 import, simulator run) | [platform constraints](../research/platform-constraints.md), [gate v2](../product/ux/gate-v2.md) |
| [iteration-plan.md](iteration-plan.md) | Stage G then W work order of 2026-11-02; overtaken by the playable build and experience v1 (housekeeping 2026-11-05) | [roadmap](../roadmap.md) |
| [review-01.md](review-01.md) | Proportion, UI language and choreography review of 2026-11-01, decided | [ADR-0018](../adr/0018-visual-system-v1.md), [UI system v2](ui-system-v2.md), [experience v1](../design/experience-v1.md) |
| [decision-audit.md](decision-audit.md) | Red-team review of 2026-11-01; its findings are folded into ADR amendments | [ADRs](../adr/README.md), [roadmap](../roadmap.md) |
| [vertical-slice.md](vertical-slice.md) | Vertical slice v0 plan (2026-11-04), built and tested by the founder | [playable build v1](playable-build-v1.md), [experience v1](../design/experience-v1.md) |
| [playable-build-v1.md](playable-build-v1.md) | Plan after the founder's slice test (2026-11-05), built (#166, #167, #174) | [experience v1](../design/experience-v1.md), [roadmap](../roadmap.md) |
| [archipelago-system.md](archipelago-system.md) | The station-island archipelago (Yıldız, Kaplıca, Kitap as more stations), retired in game plan §2 and in code (#182) | [game plan](../product/game-plan.md), [home progression](../product/home-progression.md), [ADR-0019](../adr/0019-home-cluster-and-wonder-islands.md) |
| [island-curation.md](island-curation.md) | Island arcs, order and verdicts of 2026-11-03; the order and the main/filler split changed | [game plan §4](../product/game-plan.md#4-book-one-the-islands-rising-curve), [story references](../research/story-references.md#synthesis-the-story-rules-these-give-pofu), [deep lore §6](../product/deep-lore.md) |
| [handoff-2026-11.md](handoff-2026-11.md) | Lead handoffs older than the last two entries | [handoff](../handoff.md) |
| [roadmap-2026-11-02.md](roadmap-2026-11-02.md) | The phase roadmap before the 2026-11-05 rebuild | [roadmap](../roadmap.md) |
| [monetization-v1.md](monetization-v1.md) | The 2026-11-02 monetization proposal; its recommendation and prices were replaced after the game became compact (archived 2026-11-06). v2 still cites its market data and fair-lock test (§6) | [monetization v2](../product/monetization-v2.md) |
| [ui-critique-01.md](ui-critique-01.md) and [ui-critique-01/](ui-critique-01/) | The 2026-11-02 critique of the game screen and its mockups, decided (archived 2026-11-06) | [UI system v2](ui-system-v2.md), [experience v1](../design/experience-v1.md) |
