# Docs map

One line per topic; the **canonical** doc comes first and wins where docs
disagree. Read the section you need, not whole docs. Retired material is in
[archive/](archive/README.md): history only, never build on it. Check links
with `python3 -I tools/docs/check_links.py`.

## Start here

- **Rules:** `CLAUDE.md` (lead and sub-agents), `AGENTS.md` (Codex), `CONTRIBUTING.md` (commits, branches, PRs).
- **Status and next steps:** `docs/tracker.md` and [roadmap.md](roadmap.md) (parallel tracks, no dated phases).
- **What is decided:** [product/decisions.md](product/decisions.md) (the register: founder-confirmed, lead, open, and corrections; wins over any doc until that doc is fixed).
- **Founder:** [product/founder-input.md](product/founder-input.md) (every message and how it was handled; standing decisions at the top).
- **Last sessions:** [handoff.md](handoff.md). **Decisions:** [adr/](adr/README.md) (immutable; status per ADR).
- **Pofu Hub:** frozen since 2026-11-03; chat is the channel for questions and status. Source `design/hub/index.html`.

## By topic

| Topic | Canonical | Supporting (older ones lose where they disagree) |
|---|---|---|
| Vision | [product/vision.md](product/vision.md) | |
| Book One story (islands, order, residents, Söz, finale) | [product/story-map/book-one.md](product/story-map/book-one.md) | [design/book-one-islands.md](design/book-one-islands.md) (layouts, stages, art) |
| Game: loop, days, games, screens | [product/game-plan.md](product/game-plan.md) | [game-design.md](product/game-design.md) (pillars, anti-addiction rules A1–A14; partly superseded), [minigames.md](product/minigames.md) (mechanics research) |
| Home growth | [product/home-progression.md](product/home-progression.md) | [home-layout.md](product/home-layout.md) (every slot), [design/island-healing-arc.md](design/island-healing-arc.md) |
| Economy (mirrors `PofuCore`) | [product/economy.md](product/economy.md) | |
| App vs game line | [product/app-game-boundary.md](product/app-game-boundary.md) | |
| Business | [product/monetization-v2.md](product/monetization-v2.md) | [research/monetization.md](research/monetization.md), [archive/monetization-v1.md](archive/monetization-v1.md) (market data, fair-lock test) |
| Gate (Screen Time) | [product/ux/gate-v2.md](product/ux/gate-v2.md) | [local/membership-day-1.md](local/membership-day-1.md) (day-1 script), [archive/information-architecture.md](archive/information-architecture.md) and [archive/user-flows.md](archive/user-flows.md) (superseded) |
| Experience, camera, menus | [design/experience-v1.md](design/experience-v1.md) | [interaction-spec.md](design/interaction-spec.md), [companion-motion.md](design/companion-motion.md), [ui-audit-2026-11-06.md](design/ui-audit-2026-11-06.md) |
| UI layers and skin | [design/ui-v3.md](design/ui-v3.md) (proposal), [design/ui-system-v2.md](archive/ui-system-v2.md) | [design-language.md](archive/design-language.md), [sound-identity.md](design/sound-identity.md) |
| Light, colour, sky | [design/colour-script.md](design/colour-script.md) | [light-and-shadow-v2.md](design/light-and-shadow-v2.md), [sky-and-weather-v1.md](design/sky-and-weather-v1.md), [look-dev.md](design/look-dev.md), [research/night-lighting-2d.md](research/night-lighting-2d.md), [research/look-lab.md](research/look-lab.md) (techniques tested against the concepts) |
| Art queue (Codex) | [design/art-production-plan.md](design/art-production-plan.md) | `AGENTS.md`, [art-pipeline.md](design/art-pipeline.md), [concept-inventory.md](design/concept-inventory.md) |
| Art rules | [design/art-bible.md](design/art-bible.md) | [art-direction-study.md](design/art-direction-study.md), [light-standard.md](design/light-standard.md), [sprite-vividness.md](design/sprite-vividness.md), [prompt-library.md](design/prompt-library.md) (v1 prompts; new prompts live in manifests) |
| Art in the app | [design/visual-system.md](design/visual-system.md) (how a Pofu screen is made; ADR-0023) | [asset-integration.md](design/asset-integration.md), [koke-prototype.md](design/koke-prototype.md) (first wonder island), [plate-islands.md](design/plate-islands.md) (plate-first spec, ADR-0022), [research/pale-assets.md](research/pale-assets.md) (why the game reads pale) |
| Brand and voice | [brand/pofu-voice.md](brand/pofu-voice.md) | [brand/character.md](brand/character.md) (personality; look superseded) |
| Story rules | [research/story-references.md](research/story-references.md#synthesis-the-story-rules-these-give-pofu) | [product/deep-lore.md](product/deep-lore.md) (writers only), [lore-bible.md](product/lore-bible.md) (draft), [story-delivery.md](product/story-delivery.md) (beat triggers), [narrative-craft.md](research/narrative-craft.md), [ai-story-methods.md](research/ai-story-methods.md) (the `pofu-story` skill), [story-tests/round-1.md](product/story-tests/round-1.md) |
| Story loops (paused) | [product/design-loop/README.md](product/design-loop/README.md) | [loop 1](product/design-loop/loop-1.md), [loop 2](product/design-loop/loop-2.md); the game plan wins |
| Research | [research/](research/) (check before researching again) | [apple-design-awards.md](research/apple-design-awards.md), [pro-game-craft.md](research/pro-game-craft.md) |
| Engineering | [development.md](development.md) | [development/rename-map.md](development/rename-map.md) (Turkish to English ids) |
| Free build (frozen) | [local/ucretsiz-kurulum.md](local/ucretsiz-kurulum.md) | no new features |
