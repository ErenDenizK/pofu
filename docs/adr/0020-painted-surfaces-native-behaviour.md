# 0020. Painted surfaces, native behaviour

- **Status:** Accepted
- **Date:** 2026-11-06
- **Amends:** [0018](0018-visual-system-v1.md) (rule "Glass is always native": no painted button frames, bars or sheets)

## Context

ADR-0018 kept every control native glass so the interface would never look
like a skin. By 2026-11-06 the founder judged the result generic: "every UI,
menu, pop-up and component must look, feel and be used wonderfully, as the
world's best designer would do it" and the gate and the break must be a wow.
The painted gate (#265) and its plaque buttons were the first screen he
liked. The [UI v3 review](../design/ui-v3.md) grades most system-styled
screens C or D against the painted ones.

## Decision

**Surfaces may be painted; behaviour stays native.**

1. Buttons, sheets, cards, chips, toasts, bubbles and headers may use
   painted materials (paper, wood plaques, clay, wax seals) from one
   material family ([UI v3](../design/ui-v3.md) §5), drawn as 9-slice or
   resizable art, never as fixed-size pictures of text.
2. Behaviour is native and unchanged: hit targets ≥ 44 pt, Dynamic Type
   (layouts reflow, never clip), VoiceOver labels and traits, Reduce Motion,
   Increase Contrast (a flat high-contrast fallback per material), system
   sheet detents and gestures, keyboard and focus.
3. System surfaces we do not own stay system: Apple's shield template,
   Settings rows (with a painted header and icons only), share sheets,
   alerts for destructive or permission flows.
4. Every painted state exists: rest, pressed, disabled, focused, and day and
   night variants; text is always live text, never painted.

## Consequences

- A component kit v3 in `PofuDesignSystem` and Codex batches for its
  materials (UI v3 §5-§6).
- ADR-0018's other rules stand (the diorama look, the colour script, the
  vector twins of painted icons).
- Risk: a skinned look. Guard: one material family, native behaviour, and
  the lead's screenshot review of every wave.
