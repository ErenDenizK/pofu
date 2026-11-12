# Tracker snapshots of 2026-11-10 and 2026-11-12 (archived)

Archived 2026-11-12: superseded by [now.md](../now.md), the one status page kept by hand.
These were the "Current" blocks of the [tracker](../tracker.md). History only.

## 2026-11-12, the lead's state analysis

State of every island picture: [`docs/state/plates.yaml`](../state/plates.yaml).
Art factory: [pofu-art](https://github.com/ErenDenizK/pofu-art) (ADR-0026).

**Finding: the work drifted to one track.** Since 2026-11-07, 68 PRs merged:
18 features, all look and plate work (plate-first, home states, character
light, HEIC, sky sets, isle motion, Çağlayan's sky); the rest art and docs.
No game or app track moved, though every founder question (Q-1 to Q-15) was
answered on 2026-11-07:

- **The Door** (top design priority): not started (no `DoorScene`).
- **Onboarding** in the gate's look: not started; needed before a beta.
- **UI v3 wave 3**, the two-tone icons (Q-14, Q-15 answered): not started.
- **Game flow audit** (days 1-21, no dead day): not started.
- **Koke integration, residents wave 3, decor spots, visible home growth**:
  not moved.
- **Device:** the founder has not tested since 2026-11-05; the sky motion
  (#382, #384) has never run on a device.
- **Corrections:** the gate fix shipped (#321: seeds never buy minutes);
  Emanet, Mehtap and Revontuli are not in the app (their sky masters wait
  for their islands); this tracker and the roadmap were stale.

**Rebalance (2026-11-12 to the membership, ~2026-11-24):**

1. Foreground, one track at a time with Sonnet builders: a device build and
   checklist for the founder; the Door scene and onboarding (one spec, the
   first-run checkpoint below); UI v3 wave 3 and icons; the flow audit test.
2. Background: Codex runs the factory (batch-76, then the redo of 61-65);
   the lead reviews in rounds and ships Çağlayan golden and night and home
   bare from it. No new plate or sky engineering until the foreground moves.
3. Fable 5.2 once, at a checkpoint that earns it: the Door and onboarding
   spec (checkpoint 3, first-run experience), briefed by goal
   ([playbook §3.1](../playbook.md#31-the-consultant-model)).

_Previous snapshot (2026-11-10):_


State of every island picture: [`docs/state/plates.yaml`](../state/plates.yaml).

1. **Home plate is in the app** (final, day, clear); the home states (levels, golden, night, rain) follow it.
2. **Phase-2 takes are merged** (batches 66 to 70); the lead's picks are in each `review.yaml`.
3. **Redo batch-71** (il1, bare, rain) is READY; the batch-66 versions are rejected.
4. **Runtime station:** working on the Home states and character harmony (Pofu and residents against the plate).
5. **Queue refilled:** collage-era rows are DROPPED; READY batch-72 (home night, 8) and batch-73 (islands states, 24); standing work is the next null cell of the state table.
6. **Still open:** the gate fix, the founder's 15 questions ([register](../product/decisions.md) §10), the device check.
