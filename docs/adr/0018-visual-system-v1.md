# 0018. Visual system v1: balanced diorama, Glass++, continuous camera

- **Status:** Accepted
- **Date:** 2026-11-01

## Context

[Design review 01](../design/review-01.md) put three concepts in front of
the founder, each with three alternatives: proportion (how big Pofu and the
world are on screen), UI language (how the interface relates to the painted
world), and choreography (how the camera moves between Home, an island, and
the map). The founder accepted every recommendation and added one
direction: the interface should not be "only glass". Icons, widgets, the
app icon, and the world must read as **one product**, and image generation
can produce icons as well as scenes.

That request collides with [design language §2 and §9](../design/design-language.md),
which ban illustration in chrome because raster controls break Dynamic
Type, localization, dark mode, VoiceOver, pressed states, and Liquid Glass,
and because AI-generated UI looks cheapest exactly there. Both concerns are
real. This ADR records the review decisions and the rules that let painted
art and native glass combine without those failures.

## Options considered

For the UI language (the only option set the founder extended):

1. **Native glass only** (review 01, alternative A). Legible, accessible,
   cheapest to build. Cons: on its own it reads like a utility app; the
   painted world and the interface feel like two products.
2. **Storybook craft** (B): paper, felt, and stitched custom controls. Warm,
   but every control is custom forever, it breaks at large Dynamic Type
   sizes, and it fights Liquid Glass.
3. **Diegetic UI** (C): the interface lives in the world as objects. Charming,
   but state stops being glanceable and accessibility needs a bespoke
   solution per object.
4. **Glass++**: native glass for every control's shape, behavior, and text,
   with painted art as the **content** of the frame: a painted domain icon
   family, two world indicators, painted widgets, and a layered painted app
   icon. Every painted icon has a vector twin for small sizes.

## Decision

1. **Proportion: balanced diorama (review B).** At Home, Pofu is about 20 %
   of the screen width and the visible world about 70 % of the height,
   between a 118 pt top chrome band and the bottom action band. The island
   view uses depth of field on the plates behind the focused station.
2. **UI language: Glass++ (option 4).** Its rules:
   - **Glass is always native.** No painted glass, painted button frames,
     painted bars, or painted sheets. Controls keep native shape, states,
     haptics, Dynamic Type, and VoiceOver.
   - **System actions use SF Symbols** (close, back, settings, share, more,
     add). Platform meaning beats brand flavor.
   - **Domain concepts get painted icons**: seeds, calm, wellbeing, each
     island, each station, residents, friends, the breathing break, and
     Pofu's moods. A painted icon may sit inside a native glass control or a
     list row at **28 pt or larger**, always next to a live text label or
     with an accessibility label.
   - **Below 28 pt** the same concept uses its **vector twin**: a custom SF
     Symbol traced by hand from the approved painted icon, so the family
     stays one family at every size.
   - **Two world indicators** repeat state that also has a native readout:
     the **seed jar** (fills as seeds are collected) and the **calm
     lantern** (glow 15 % → 100 % as calm goes ×1.0 → ×2.0). They are
     never controls and never the only path to the information; at most
     two per scene.
   - **Widgets** use painted plates and Pofu at 44 pt or larger, with live
     text; smaller sizes use the vector Pofu glyph.
   - **The app icon** is painted in separate layers (background, island,
     Pofu) and assembled in Icon Composer, so iOS applies Liquid Glass to
     it like any native icon.
   - Painted icons follow the art bible with a simplified-detail rule (one
     light direction, no fur detail below 60 pt, no outlines unless the art
     direction study decides otherwise) and must pass a legibility check at
     24, 30, and 60 pt before approval.
3. **Choreography: one continuous camera (review A).** Home, an island, and
   the map are three framings of one world; moves are springs between them.
   The **cloud pass** is reserved for a new island's arrival. Reduce Motion
   replaces camera moves with cross-fades.
4. **Pofu on the map** is a **30 pt vector pin**, not a tiny painted Pofu.
5. **Art production starts** with the first 8 images of
   [game design §15](../product/game-design.md), then a separate UI batch
   for Glass++ (domain icons, jar states, lantern, one widget, an app icon
   draft). The less contrasty island take from art test 01 is the style
   target.

## Consequences

- **Supersedes** two lines of the design language: "Icons in chrome are SF
  Symbols" becomes "system actions are SF Symbols; domain concepts are
  painted at 28 pt or larger with a vector twin below", and §2 gains the
  world-indicator rule. The image-dump test gains a sixth question: "If it
  shows state, where is its native twin?"
- **More art:** about 88 images for the world package plus roughly 30 for
  Glass++ (icon family, jar fill states, lantern layers, widget plates, app
  icon layers). The pipeline gains `icon__`, `ui__`, `widget__`, and
  `appicon__` kinds with a small-size legibility check.
- **More vector work:** every painted domain icon needs a hand-traced custom
  SF Symbol twin. That is the price of one family at every size; budget it
  per icon.
- **Risk:** painted icons can drift in style faster than scenes because they
  are small and numerous. Mitigation: icons are generated as edits of one
  approved icon sheet, and the batch is reviewed as a contact sheet at 30 pt
  on light and dark glass before any is approved.
- **Easier:** the world, the interface, widgets, and the App Store page now
  share one visual voice, which is the product's main differentiator against
  utility-looking screen-time apps.
- The order of work is in the [iteration plan](../design/iteration-plan.md).

## Amendment (2026-11-01): timing, after the decision audit

The [decision audit](../product/decision-audit.md) showed that the gate,
the core of the product, has not yet caught one real reach on the
founder's phone. The direction above stands; its **production waits**:

- **Now:** native glass and SF Symbols only. Proportion and the continuous
  camera apply when the home-island slice is built.
- **After the friends beta starts:** the painted domain icon family and
  vector twins, the seed jar and the calm lantern, painted widgets, and the
  layered app icon. When the jar is built, Home must also expose the seed
  count natively (accessibility value and the collect moment), since the
  seed pill is off Home (game design §5).
- This ADR also amends [ADR-0016](0016-pre-planned-idle-archipelago.md):
  Home is the balanced diorama, not Pofu up close.
