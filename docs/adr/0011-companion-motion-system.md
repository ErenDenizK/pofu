# 0011. Companion motion system

- **Status:** Accepted (pending on-device validation)
- **Date:** 2026-11-01
- **Amends:** [0010](0010-illustrated-hamster-art-direction.md) (motion clause)

## Context

ADR-0010 made AI-assisted illustration the visual source of truth and left
the motion system to a spike. Two facts changed the plan:

- **Sora is discontinued.** The consumer app closed on 2026-04-26 and the
  API shut down on 2026-09-24, so ChatGPT Pro offers no AI video.
- **The founder has no budget for third-party video tools now** (Higgsfield,
  Seedance, Kling). They remain a distant option only.

The companion motion spike (PR #9,
[companion-motion.md](../design/companion-motion.md)) proved a still-based
system in a WebGL prototype and in Swift. The Swift code builds in CI but
has not been run on a device yet.

## Decision

Pofu's motion comes from one illustrated still plus code:

1. **Procedural motion on the still.** Ground-anchored breathing, sway,
   squash and stretch, hops with anticipation and landing, lean, and
   gaze-following are driven by springs at 60 fps. Every frame uses the same
   pixels, so the character cannot drift.
2. **One deformation shader** (SwiftUI `distortionEffect` with a Metal
   function and a pure-SwiftUI fallback) drives:
   - cheek pouches that fill with energy;
   - the dent when the user taps Pofu;
   - follow-through on the tuft and ears;
   - ripples through the fur;
   - the vitality grade.
3. **Continuous vitality without state images.** Saturation, tint, fur
   crispness, posture, droop, breathing rate, and lids are all derived from
   vitality (0 to 1).
4. **Faces from edited variants of the base image.** Each variant is aligned
   to the base, and only a feathered face region is composited over it, so
   nothing outside that region can drift. Blinks reveal the eyes-closed
   variant through lid masks.
5. **Discrete actions as GPT Image sprite sheets.** Celebration, yawn, and
   gulp are each generated as one sprite sheet from a single prompt (3×2 or
   2×2 when shown large). Frames are aligned and checked for drift by the
   asset pipeline, then played at about 10 fps over the live body layer.
6. **No AI video and no Live2D or Spine rigging in v1.**

## Consequences

- The founder's asset list is small and concrete: a base image, five or six
  face and cheek edits of that base, and one sprite sheet per action (see
  section 5 of the motion spec).
- Production art must be at least about 720 px wide for @3x display; the
  current placeholder (522 px) is not.
- Turning, walking, and props are out of scope until sprite sheets or an
  animator justify them.
- On-device validation decides the details: performance of the shader,
  the look of lids and cheeks, and the feel of the springs.
