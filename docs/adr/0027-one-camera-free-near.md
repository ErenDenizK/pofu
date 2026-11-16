# 0027. One camera: the Map, mid and a free near

- **Status:** Accepted
- **Date:** 2026-11-16
- **Supersedes:** [0018](0018-visual-system-v1.md)'s framing names (Map, Island, Home) and
  [0019](0019-home-cluster-and-wonder-islands.md)'s "there is still no free camera"

## Context

The rail had three stops: the Map, the Island (the island panned sideways at ×1.0, no chrome)
and Home (×1.40 with the chrome, the island wider than the screen). On Home the player never
saw the whole island he grows, and the Island and Home stops were two near-identical framings
of one place. The world presentation spec (WP7, decision D4) and the match proof
(`docs/design/assets/world-concepts/match-mid.jpg`, `match-near.jpg`) frame Home whole and let
the player pinch in close to Pofu, which the old "no free camera" rule did not allow.

## Decision

- **One camera with a depth function** (WP2, `DepthLayer`): every backdrop layer draws at the
  camera pulled toward a reference pose by its depth `k`. The reference is Home's stop, mid.
- **Three framings: `map`, `mid`, `near`** (`WorldFraming`, raw values 0, 1, 2).
  - **Map** (z 0): the tier frame of `world-map.json` (`MapSlots`, Home alone until Koke opens).
  - **Mid** (z 1): Home's stop and every island's own stop. The level-10 island box fitted to
    378 pt across on iPhone 17 (×1.145), its centre on row 383; a young island narrower than
    0.72 of the width fits to 0.72. The chrome shows here.
  - **Near** (z above 1.12, which is 1.25 × the mid scale, up to the limit at z 2, 7.4 pt a
    unit): a free range. It rests at 4.5 pt a unit (z 1.73).
- **The rail:** `ln s` is linear in z on each segment. From the Map to mid the look and the
  anchor interpolate with the same fraction; past mid the look stays the island's and the anchor
  eases from row 383 to the screen's middle (437) as the chrome fades.
- **Release:** below z 0.5 the camera lands on the Map, from 0.5 to 1.12 on mid, and above 1.12
  it stays where the fingers (and their projected velocity) leave it. Rubber bands: 0.85 × the
  Map's scale and 1.12 × the near limit.
- **A pinch zooms about the fingers:** the world point under them stays under them, at every z.
- **The chrome fades** from opacity 1 to 0 between 1.05 and 1.25 × the mid scale.
- **Near is free:** a one-finger drag pans on both axes while the screen's centre stays inside
  the island box grown 10 %; past it a 30 pt rubber band. A double tap on a character rests near
  on him: his feet at 0.60 of the height, 0.12 of the width away from the side he faces (less
  where the bounds stop it). Only the one control shows, and it goes back to mid.
- **Numbers are data:** `world-map.json` `mid` and `near`.

## Consequences

- Home opens on the whole island; one pinch runs from the Map to Pofu's face.
- The Island stop's horizontal pan, its snap points and the establishing shot retire (mid shows
  the whole island). `holdPan` and `establish` stay as no-op shims for their callers.
- Depth layers, the lens and the far sky still read the older rail positions
  (`CameraRig.layerPosition`: the Map-to-mid segment spans their 0 to 2), so mid draws as Home
  did and near draws as Home until WP11 gives near its own lens.
- Undoing this means restoring two stops and their framing maths: days, hence this record.
