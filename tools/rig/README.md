# Pofu's rig (`tools/rig`)

Turns the rig parts Codex delivers (batch 06: edits of R1 that change one
region) into the composites the app will draw, so a pilot is reviewed as
expressions, not as loose images. Why a rig:
[art production plan](../../docs/design/art-production-plan.md#pofus-reactions-are-a-rig).

| File | What |
|---|---|
| `rig.json` | Regions drawn once on R1 (ellipses in R1 pixels), layer order, the expressions (layer → part), and the pilot list. Tune here, not in code. |
| `rig.py` | Masks, compositing, seam scores, the contact sheet, the CLI |
| `tests/` | The compositor on a synthetic hamster |

## How it composites

1. Start from the clean plate (`pofu-rig-clean`: no ears, no front paws).
   Until it exists, R1 stands in and the sheet says so.
2. For each layer in order (`fur`, `paws`, `cheeks`, `ears`, `mouth`,
   `eyes`): take the expression's part, or R1 for the regions the plate
   lacks (`restore`: ears and paws).
3. Mask: `region` layers use their ellipses, feathered; `envelope` layers
   use where the part differs from what is already composited, inside the
   ellipses (paws and pouches change shape, drooped ears move), feathered.
4. Composite with `over`. The ear flick rotates each ear about its pivot,
   to prove the plate holds behind it.

Each layer gets a **seam score**: the mean ΔE between the part and what it
lands on, in the feather ring. Above `seam_warn` (6) the sheet marks it;
look there first. The neutral rig is also compared with R1 (mean ΔE,
target below 1): if it is higher, the clean plate drifted.

## Commands

```sh
python3 -I tools/rig/rig.py preview          # build/rig/regions.jpg: the regions on R1
python3 -I tools/rig/rig.py sheet            # build/rig/rig-contact.jpg: the pilot's expressions
python3 -I tools/rig/rig.py sheet --all      # every expression in rig.json
python3 -I tools/rig/rig.py compose happy    # build/rig/happy.png
python3 -I -m pytest -q tools/rig/tests
```

Parts are read from `design/art/masters/<name>/<name>.png` (or its
lossless `.webp` twin). To review a pilot before it merges, check out the
art branch's master folders first (AGENTS.md step 2).

## Reviewing pilot 2 (`batch-06-pofu-rig-pilot`)

Run `sheet` and check, at full size and in the face crop: no halo or step
at any mask edge (seam scores low), happy and sleepy eyes sit exactly in
R1's sockets, the pout reads playful, the full pouches bulge past the
outline without a seam at the jaw, the ear-flick row shows fur (not a hole)
behind the ears, and the neutral rig matches R1. If a region needs a bigger
or smaller envelope, change `rig.json`; if a part is off model, the
follow-up batch's prompt changes before it opens.
