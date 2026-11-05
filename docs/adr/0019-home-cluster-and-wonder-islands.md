# 0019. Home cluster and wonder islands: station islands retired

- **Status:** Accepted
- **Date:** 2026-11-05
- **Amends:** [0016](0016-pre-planned-idle-archipelago.md) (the island list, what an island is, and the island framing)

## Context

ADR-0016 planned an archipelago in which every further island repeats the
home template: three stations, one resident, one ritual (Yıldız, Kaplıca,
Kitap). By 2026-11-05 three things had changed:

- **Seeds.** Ayçiçeği and İskele together cost 2,788 seeds to finish, more
  than a typical user earns in 60 days (about 1,700). A second seed sink is
  not needed in Book One ([game plan §2](../product/game-plan.md#2-structure-two-layers)).
- **Feel.** The founder rejected islands that are "more stations" as
  copy-feel; he asked for a rising curve of hand-made islands, main-story
  islands and fillers, and a home that grows on many axes at once
  ([founder input](../product/founder-input.md)).
- **Code.** `PofuCore` already moved: island level 1 to 10 with station
  caps, the harbor on tended day 3, and the station islands retired with
  their ids kept for old saves (#182).

## Options considered

1. **Keep station islands** next to the story islands. More seed sink and
   art reuse; dilutes every new island and repeats the home loop.
2. **Retire them; home is the only economy, islands are story.** One place
   to grow, islands that each feel new; the home must carry long-term
   growth on its own (island level, residents, decor, mastery, seasons).

## Decision

Option 2.

- **The home cluster** (Ayçiçeği and the İskele harbor) is the only seed
  economy. Its growth is the island level (1 to 10) that caps station
  levels, residents, decor sets, materials, the full bloom and mastery
  ([home progression](../product/home-progression.md),
  [home layout](../product/home-layout.md)).
- **Wonder islands** are hand-made and few: main-story islands that move
  Book One, and fillers that drift in on a random day and never gate the
  story or home. They pay in gifts to home, residents, stamps and story,
  never in seeds. Gezgin (the whale Nazlı) carries the player between them.
- **Yıldız, Kaplıca and Kitap are retired** as station islands: Yıldız's
  role passes to Mehtap; Kaplıca and Kitap are parked. `RetiredIds` keeps
  old saves decoding.
- **The island framing pans** along the camera rail
  ([experience v1 §1](../design/experience-v1.md#1-navigation-and-camera-one-camera-one-control));
  there is still no free camera and no placement.

ADR-0016 still holds for fixed slots, five designed levels per station,
idle production with no storage cap, timers or deadline, the anti-addiction rules
and pure SwiftUI rendering. Its "Plus sells variety, never progress" clause
stands until a monetization ADR replaces it;
[monetization v2](../product/monetization-v2.md) is the open proposal.

## Consequences

- Each new island needs its own idea, art and beats instead of a template;
  fewer islands, each more expensive and more memorable.
- The home must hold interest after Book One by itself: island level,
  residents and their relationships, decor and seasons carry that load.
- The [archipelago system](../archive/archipelago-system.md) and
  [island curation](../archive/island-curation.md) proposals are archived;
  the [game plan](../product/game-plan.md) is the source of truth.
