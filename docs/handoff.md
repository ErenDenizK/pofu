# Lead session handoff

The lead session restarts daily to keep context small. Read this, CLAUDE.md
and `docs/product/founder-input.md`, then delete what is done.

## 2026-11-03 (from the 2026-11-02 session)

**First: the workflow optimization round** (founder: no new large round
before it). Opus plans, Sonnet implements:
1. Local Swift toolchain: try `swiftlang` from the Ubuntu 25.04 (plucky)
   archive (download.swift.org is blocked) so PofuCore and PofuGames logic
   tests run here; CI only for UI, builds and screenshots.
2. CI: run the screenshot and motion-beat jobs only when app or world code
   changes; cache SPM and DerivedData.
3. Remove merge hotspots: generate `design/art/harmony/manifest.json` in CI
   instead of committing it; CHANGELOG as per-PR fragment files; drop the
   Atlas build (Atlas and Pofu Hub are retired).
4. Agent rules are in CLAUDE.md (5.5 models, budgets, one PR per stream).

**Then review the overnight Codex output:** batches 12 (minigame art), 13
(UI rest), 14 (İskele), 15 (exploration: wonder-island concepts, residents,
sky map, app icon, key art, winter, onboarding). Check that pond-5-lit and
the four retained batch-11 UI takes were published. Decor bench (batch 08)
needs a re-run with the new guide check.

**Open founder decisions:** island plate v2 vs v3 (lead prefers v2); keep
the "no garden rounds at night" rule; Hub-era questions now answered in
chat: earned rounds, island materials, paywall cut point (beta data), UI
direction (B, hybrid). PRs #60 (monetization) and #64 (archipelago) await
his decision.

**Known gaps:** minigame has no sound, no VoiceOver play, no painted tiles
yet; nothing tuned on a device; Hub dictation never tested (Hub retired).
