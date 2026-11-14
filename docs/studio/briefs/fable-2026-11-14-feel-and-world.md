# Fable brief: Pofu after the first phone session (2026-11-14)

Shown to the founder before it runs (his ask). Runs once the two fact files
below have landed.

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included;
its framing and options should not narrow your thinking. The founder wants
your creativity: if a question is badly posed, or a better approach exists
that nobody has named, say so and take it. Fixed: the product rules in
CLAUDE.md, and one decision: the UI stays in the glass skin.

## What the founder felt on his phone (views, not a work order)

1. Upgrades do not show: a station's name levels up, the object does not;
   the upgrade screen, its effects and the sheet's motion are weak; the
   code-drawn sunflower looks bad.
2. Camera: far (the Map, fine), mid (the whole island, today's fit, the
   ideal), near (a free zoom and pan right up to Pofu, residents and the
   details around them; the characters are the subject). Today near and
   far blend instead of moving as one camera; backdrop and lower clouds
   drift across islands and scenarios; small island clouds vanish when
   zooming out.
3. Minigames fit the theme but feel empty; their UI needs a pass; the
   flow game needs fully custom assets.
4. He likes Liquid Glass behaviour, e.g. holding a control to reveal a
   bar that jumps to any screen, ordered to the player's own islands.
5. Constant 120 fps; the phone warms after minutes on a still painting.
6. More music, sound and motion (sky, clouds, light); effects that show
   off the island.
7. How water and anything else should move (GIFs, shaders, other); some
   residents should hop now and then; where the motion systems went.

The side channel's reading (evidence to check): plates are one painting
per island level, so stations have no layer; some TimelineViews run
unbounded; a shader flow map over the painting with Codex-painted masks
likely beats GIFs; three coupled clusters: world presentation (camera,
upgrades, LOD, art resolution: the largest and riskiest), feel (motion,
effects, sound, music, heat: one power budget), and minigames with the
glass UI (more independent; `fable-2026-11-14-ui-grammar.md` exists and
is simpler now that glass is decided: fold it in or run it as written).

## What you read

- `docs/research/world-presentation-facts-2026-11-14.md` and
  `docs/research/feel-motion-facts-2026-11-14.md` (gathered for you).
- docs/now.md, docs/design/asset-system-v1.md §1-4, the ADRs they cite,
  pofu-art's QUEUE.md and QUEUE-LOG.md (Codex's real pace).
- Player-path frames at 1206 x 2622 through `tools/review/fetch_frames.sh`
  (never into the main `.git`); judge at 1:1 crops.

## What the founder asks of the plan

- **Mistakes must be rare; his bar is the screen.** Prove each large
  decision on screen cheaply before engineering: for example mock frames
  of two or three upgrade approaches at the three distances, made from
  existing paintings by script or by one small Codex pilot.
- **A guide to who does what:** what stays with you (judgement end to
  end), what goes to Opus (precise or first-of-kind building), Sonnet
  (recipes), Haiku (fact gathering), Codex (painting), with the order,
  what runs in parallel, and the cost in agent-days and Codex jobs.
- **Your passes:** one or several is your call; a triage and
  architecture pass first, then a deep world-presentation pass, is a
  suggestion to weigh. If facts are missing, name them for a cheap
  scout; do no grunt work.

## What you return (this pass)

A file `docs/design/feel-and-world-v1.md`, as a docs PR, not merged:
1. Triage of the seven points: what each really is, quick wins (heat may
   be one) versus decisions, and which cluster it belongs to.
2. The architecture: camera, layers and resolution, motion technique,
   power budget; each with the alternative set aside.
3. The on-screen proofs to make before engineering: what, by whom, how
   cheaply, and what the founder chooses between.
4. The plan and the guide (who, order, parallel, cost), and what your
   next pass, if any, would decide.
5. What only the founder can decide.
Hand back the PR link, 3 to 5 frame or crop paths, and at most 20 lines.
