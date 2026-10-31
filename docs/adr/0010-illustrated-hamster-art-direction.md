# 0010. Illustrated hamster art direction

- **Status:** Accepted (motion system pending validation)
- **Date:** 2026-10-31
- **Supersedes:** [0006](0006-code-native-companion-rendering.md)

## Context

Three rendering pipelines were explored for Pofu
([character-exploration.md](../brand/character-exploration.md)):

1. **Code-native vector rig** (ADR-0006, prototype v0.1). The geometry and
   motion worked, but the founder found the character species-less, and the
   code-drawn face too simple next to professional illustration.
2. **Procedural 3D plush** (Blender feasibility spike, PR #6). Premium
   designer-toy quality and perfect consistency, but slow to iterate (minutes
   per frame) and limited to 2.5D or pre-rendered motion in the app.
3. **AI-generated 2D illustration.** The founder generated a species lineup
   with GPT Image ([concept](../brand/assets/concepts/species-lineup-gpt-image.jpg)).
   The soft storybook style was received with strong enthusiasm, for the
   character and for the rest of the app's visual assets.

The founder also proposed a disciplined production workflow: settle the
design on one or two images first, then produce variants, rather than
rendering every option in every technique.

## Decision

1. **Species:** Pofu is a **round, very fluffy hamster**, with creamy white
   and golden-peach fur, a curl tuft, big glossy eyes, blush cheeks, and tiny
   paws ([concept](../brand/assets/concepts/hamster-gpt-image.png)). The
   hamster wheel represents doomscrolling; the cheek pouches visibly store
   earned energy.
2. **Visual source of truth:** **AI-assisted 2D illustration** in the soft
   storybook style. Production is governed by an art bible (style anchor,
   palette lock, reference images, and image editing for variants instead
   of fresh generations) and post-processed by an asset pipeline.
   Illustration is used deliberately (character, scenes, badges, onboarding,
   empty states), while chrome and controls stay native.
3. **Motion:** a hybrid system on top of the stills:
   - procedural and shader-based motion for continuous life and vitality;
   - expression variants edited from one base image for the face;
   - AI-generated video only for a few hero moments.

   The concrete system is validated by the companion motion spike before
   it becomes binding.
4. **Species as data:** the pipeline treats species as a parameter. Launch
   ships the hamster only. Bunny, kitten, and chinchilla are candidates for
   collectible "Pofu friends" after launch (unlocked through Plus or
   milestones; to be decided with monetization).
5. **3D is parked, not discarded.** The Blender spike is kept as a reference
   for marketing renders and as a possible "3D for control, illustration for
   style" pipeline, where 3D renders give pose control and image models apply
   the illustrated style.

## Consequences

- The founder becomes the operator of image generation; the agent owns the
  art bible, prompts, the acceptance checklist, the pipeline, and
  integration.
- Character consistency depends on process discipline, so the art bible is
  binding for every generated asset.
- Purely AI-generated art has weak copyright protection. Mitigations:
  documented human curation and editing, and a registered name and logo.
- The vector rig remains useful as a motion-parameter reference
  (`docs/brand/character.md`); its rendering code is no longer the shipping
  path.
