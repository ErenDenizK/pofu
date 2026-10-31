# 0006. Code-native companion rendering

- **Status:** Superseded by [0010](0010-illustrated-hamster-art-direction.md)
- **Date:** 2026-10-31

## Context

The companion character is the emotional core of the product and must express
many states (thriving, tired, wilting, sleeping, celebrating, meditating,
asking "do you really need this?") with fluid transitions and reactions to
touch. The project has no illustrator or animator. The founder is open to
AI image tools (for example Nano Banana, Higgsfield, ChatGPT image generation).

## Options considered

1. **AI-generated raster images.** Fast, beautiful stills. Keeping a
   character consistent across dozens of poses is hard, the result cannot be
   animated between states, purely AI-generated art has weak copyright
   protection, and the visual style tends to look like everyone else's
   AI-generated mascot.
2. **Rive state machines.** Industry-leading interactive animation with a
   native iOS runtime. Requires an animator working in the Rive editor; the AI
   agent cannot author `.riv` files.
3. **Code-native vector rig.** The character is constructed from parametric
   vector shapes in SwiftUI (Canvas, Shape, TimelineView) with explicit
   parameters for every expressive feature (eye openness, mouth curve, posture,
   color vitality, fluff). States are parameter sets; transitions are springs
   between them.

## Decision

- The **companion** is a code-native vector rig (option 3). AI tools may be
  used for concept exploration and the character sheet, but the shipped
  character is drawn in code.
- **Environments** (backgrounds, scenes, themes) are layered illustrations,
  AI-assisted and hand-refined, composed in parallax.
- Revisit Rive (option 2) when there is budget for a professional animator.

## Consequences

- Infinite expressive states and smooth, physically based transitions; the
  character can react to every interaction.
- The character is fully owned intellectual property, consistent everywhere,
  and tiny in size. The same rig renders in widgets and Live Activities.
- The design must suit a shape-based construction: bold, simple silhouettes
  rather than intricate detail. This constraint shapes the character concept.
