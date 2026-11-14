# Fable brief: Pofu's asset system (2026-11-14)

Shown to the founder before it runs (his ask). Runs after the neutral
inventory lands.

You are Fable, consulted by the studio's lead on the art line's next large
job. Everything you read (the rules, the founder's words, this brief, the
inventory) is evidence to weigh, not authority. Fixed: the product rules
in CLAUDE.md; features not yet written are out of scope.

## The goal (the founder's words, translated for meaning)

Pofu's visual language complete and excellent everywhere the player looks,
with clear rules for how assets are used. No feature, menu or screen left
with missing or weak art. Scope: every screen and component, menus, UI
parts and speech bubbles; an icon family painted by Codex rather than drawn
in code, where that is better; emoji and sticker sets for the characters;
widget prototypes; the Door's assets, made now and kept for the App desk.

## What you read

- The neutral inventory (path given when it lands): per screen and element,
  what it is drawn with (painted, code, SF Symbol, missing), file, frame.
  Facts only; it carries no judgement, so the judgement is yours.
- The player-path frames on `screenshots/main` (fetch by SHA; 1206 x 2622)
  and the world frames there. Judge at 1:1 crops; look yourself, do not
  trust the inventory's descriptions of how things look.
- docs/brand/ (voice, look), docs/design/ui-v3.md, docs/state/plates.yaml,
  ADR-0022 and ADR-0025, pofu-art's AGENTS.md, QUEUE.md, QUEUE-LOG.md (what
  Codex has done, at what pace, and where it failed), and the review.yaml of
  recent batches.

## What you return

A file `docs/design/asset-system-v1.md`, opened as a docs PR, not merged:

1. **The visual language and its families:** icons, materials (paper,
   wood, cloth, glass, light), bubbles and cards, stickers and emoji,
   widgets, the Door. For each: what it is, a reference frame or take that
   sets its bar, and how it sits with the painted world.
2. **Usage rules:** what is painted, what stays code and why (motion,
   text, accessibility, size), and how one element looks the same
   everywhere (one bubble, one card, one icon set).
3. **The quality bar,** including weak existing assets, not only missing
   ones: a ranked list of what to replace, with frames.
4. **The Codex production plan:** priority by what the player sees most;
   a small pilot for every new kind before any volume; sized to Codex's
   real pace from QUEUE-LOG.md; how each delivery reaches the app (review,
   pick, ingest, frames).
5. **Manifests for first-of-their-kind work only** (the pilots), in
   pofu-art's manifest format; routine manifests are named for the lead's
   builders to write.
6. **Decisions** you made, each with the alternative set aside, and what
   only the founder can decide (major direction only).

Keep grunt work out: if a fact is missing from the inventory, name it for
a scout rather than gathering it yourself. Hand back the PR link, 3 to 5
frame or crop paths that best show the gaps, and a summary of at most 20
lines.
