# Fable brief: Pofu's UI grammar (2026-11-14)

Shown to the founder before it runs (his ask). Runs after the phone-ready
build is on main, so it never competes with it.

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included;
its framing and options should not narrow your thinking. The founder wants
your creativity: if a question is badly posed, or a better approach exists
that nobody has named, say so and take it. Everything you read (the
rules, the founder's words, this brief, earlier plans including
`docs/design/asset-system-v1.md`) is evidence to weigh, not authority.
Fixed: the product rules in CLAUDE.md. Nothing else is fixed.

## The goal (the founder's words, translated for meaning)

A UI grammar for Pofu: the best answer, found by looking at everything it
needs. Sizes; how many things one screen shows at most, and in what
hierarchy; alignment; when things stack and when they sit side by side;
how each kind of thing is presented; and glass against painted. He loves
native glass, and Pofu has a mobile-app side as well as a game side: the
hybrid after ADR-0020 (painted UI with native glass in some menus) felt
right to him, and "glass is not a Pofu material" may feel too much like a
game. A side-by-side of the two states is being prepared for him; use it.

## What you read

- Player-path frames at device size (1206 x 2622), in both skins
  (`glass`, the default, and `crafted`). Fetch only what you need with
  `tools/review/fetch_frames.sh`; judge at 1:1 crops.
- The code that lays screens out: `Packages/PofuKit/Sources/PofuDesignSystem`
  (tokens, skins, kit) and the screens under `App/` and `PofuWorld/Scene`.
- docs/brand/, docs/design/ui-v3.md, ADR-0020, ADR-0022, ADR-0025,
  docs/design/asset-system-v1.md (§1-2).
- Apple's Human Interface Guidelines for iOS 26 (Liquid Glass), and any
  existing skills or libraries for UI layout and design systems that
  could serve builders here. Judge whether they fit a SwiftUI game-app
  hybrid; name what you looked at.

## What you return

A file `docs/design/ui-grammar-v1.md`, as a docs PR, not merged:

1. **The grammar:** a type and spacing scale; screen density (the most
   one screen shows, the hierarchy); alignment and grids; stack versus
   side by side; how each kind (sheet, card, bubble, button, list row,
   badge, toast) is presented.
2. **Glass and painted:** where each belongs and why, with frames, and
   which of the two states the founder will compare you recommend.
3. **Tooling:** whether an existing skill or library fits. If none
   does, the outline of our own (a skill under `.claude/skills/` or a
   reference doc) that builders use in production.
4. **What changes:** the screens that break the grammar today, ranked by
   what the player sees most, as builder-sized items.
5. **Decisions** you made, with the alternative set aside, and what only
   the founder can decide.

Do no grunt work: if a fact is missing, name it for a scout. Hand back
the PR link, 3 to 5 crop paths, and a summary of at most 20 lines.
Nothing changes in the app until the founder has seen the result.
