# Docs index

The map of current documents. `CLAUDE.md` is the agent's entry point.
**Where docs disagree, the first doc in a row wins.** Retired material is in
[archive/](archive/README.md): history only, never build on it.

| Area | Read | Status |
|---|---|---|
| Direction | [roadmap.md](roadmap.md) (status, tracks, weekly rhythm), [product/vision.md](product/vision.md), [product/founder-input.md](product/founder-input.md) (his direction and standing decisions), [handoff.md](handoff.md) (the lead's last two sessions) | current |
| Decisions | [adr/](adr/README.md) (immutable; amendments listed per ADR) | current |
| **Game** | [product/game-plan.md](product/game-plan.md) (canonical: the loop, day by day, Book One, three games, social, screens), [product/home-progression.md](product/home-progression.md) (island level and caps, ladders, residents, decor, materials, seasons, mastery), [product/home-layout.md](product/home-layout.md) (every slot of Ayçiçeği and the harbor, reveals, the showcase list), [product/economy.md](product/economy.md) (mirrors `PofuCore`), [product/app-game-boundary.md](product/app-game-boundary.md) | proposal, canonical |
| Game (older, partly superseded) | [product/game-design.md](product/game-design.md) (pillars, anti-addiction rules A1–A14), [product/minigames.md](product/minigames.md) (mechanics research) | reference |
| Business | [product/monetization-v2.md](product/monetization-v2.md) (one membership; the gate always free), [archive/monetization-v1.md](archive/monetization-v1.md) (v1: market data, fair-lock test) | proposal |
| Gate and UX | [product/ux/gate-v2.md](product/ux/gate-v2.md), [local/membership-day-1.md](local/membership-day-1.md), [product/ux/information-architecture.md](product/ux/information-architecture.md) and [user-flows.md](product/ux/user-flows.md) (partly superseded) | current |
| Look and feel | [design/experience-v1.md](design/experience-v1.md) (one camera and place control, light field, frame policy, menus, shield, launch, visitors, fullness), [design/ui-system-v2.md](design/ui-system-v2.md) (UI layers, `PofuSkin`), [design/design-language.md](design/design-language.md), [design/interaction-spec.md](design/interaction-spec.md), [design/look-dev.md](design/look-dev.md), [design/companion-motion.md](design/companion-motion.md), [design/sound-identity.md](design/sound-identity.md), [design/asset-integration.md](design/asset-integration.md) (which approved masters are in the app) | current |
| Art | [design/art-production-plan.md](design/art-production-plan.md) (the Codex queue and backlog), `AGENTS.md` (Codex), [design/art-bible.md](design/art-bible.md), [design/art-direction-study.md](design/art-direction-study.md), [design/art-pipeline.md](design/art-pipeline.md), [design/light-standard.md](design/light-standard.md), [design/sprite-vividness.md](design/sprite-vividness.md), [design/prompt-library.md](design/prompt-library.md) | current |
| Brand | [brand/pofu-voice.md](brand/pofu-voice.md), [brand/character.md](brand/character.md) (partly superseded) | current |
| Story | [research/story-references.md](research/story-references.md#synthesis-the-story-rules-these-give-pofu) (the story rules: main islands, fillers, Gezgin, the duo), [product/deep-lore.md](product/deep-lore.md) (the hidden history; writers only), [product/lore-bible.md](product/lore-bible.md) (draft for human spice), [product/story-delivery.md](product/story-delivery.md) (beat triggers), [research/narrative-craft.md](research/narrative-craft.md), [research/ai-story-methods.md](research/ai-story-methods.md) (the `pofu-story` skill), [product/story-tests/round-1.md](product/story-tests/round-1.md) | draft |
| Story (older, partly superseded) | [product/design-loop/README.md](product/design-loop/README.md) (paused), [loop 1](product/design-loop/loop-1.md) (constellations, the Bekçi spine), [loop 2](product/design-loop/loop-2.md) (cluster atmospheres, the hour rule) | reference |
| Research | [research/](research/) (check before researching again), [research/apple-design-awards.md](research/apple-design-awards.md), [research/pro-game-craft.md](research/pro-game-craft.md) | reference |
| Engineering | [development.md](development.md), [development/rename-map.md](development/rename-map.md) (Turkish to English identifiers), `CONTRIBUTING.md` | current |
| Free build | [local/ucretsiz-kurulum.md](local/ucretsiz-kurulum.md) (Turkish, Rehearsal mode; no new features) | frozen |
| History | [archive/](archive/README.md) (iteration plan, review 01, decision audit, vertical slice, playable build v1, archipelago system, island curation, older explorations) | historical |

Check links with `python3 -I tools/docs/check_links.py`.
