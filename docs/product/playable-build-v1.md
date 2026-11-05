# Playable build v1

**Why:** the founder tested the free Rehearsal build on 2026-11-05: it
stutters and heats the phone, nothing is playable without the developer
menu, taps do nothing, the world stays night, the icon is a placeholder
(founder-input, 2026-11-05). Root causes are known (two code audits);
this is the plan for the next build he installs.

## Root causes

| Symptom | Cause |
|---|---|
| Not playable, taps dead | `FeatureFlags.worldHome = false`: the old Home ran, with `onBuild: nil`; stations are hit-testable only in the island framing; the garden game is reachable only from Rehearsal |
| Always night | Dark appearance forces 82 % night into the world light and sky; plates are graded only by a Metal shader with no fallback |
| Heat and stutter | the garden SKView at 120 fps even when idle, glass over live scenes, an uncapped island timeline, a per-frame blurred light Canvas, two grade passes, always-on companion and home-object timelines |
| Placeholder icon | a flat lavender gradient |

## The build (two PRs, then one install)

1. **Performance** (`perf/smooth-home-and-garden`): 60 fps caps, pause
   when settled or not playing, cached light beams, one grade pass, no
   glass over live scenes, audio engine stops when idle.
2. **Playable** (`feat/playable-build-v1`): the world home on; tap a
   station or "+" on the map or island to build or upgrade; the garden
   game from its station sheet and from Home; a Today sheet; day and night
   follow the clock (not dark mode); the developer panel collapsed in a
   corner; the Pofu-face app icon (light, dark, tinted); consistent sheet
   and cover transitions.

Then: screenshots of each screen in day and night to the founder, and a
one-line install note. Next after this: the harbor as a walkable scene,
upgrade art for every level as Codex delivers it, the map with rumours.
