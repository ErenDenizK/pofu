# State files

Machine-readable truth about what exists, so no agent has to guess or
re-read the chat. Plate-first (ADR-0022): one painted picture per island state.

- `plates.yaml`: every island x stage x time (day, golden, night) x weather
  (clear, rain) cell: `painted` (take path or null), `lead_pick` (take
  number), `in_app`, `founder_ok`. `root_time` names the hour of the island's
  picked root. Paint order is the next null `painted` cell (standing work in
  [the queue](https://github.com/ErenDenizK/pofu-art/blob/main/QUEUE.md#how-to-work-it)).
- Checked by `python3 -I tools/state/check_plates.py` (paths and picks exist; each island also has a `sky_sets:` row per light, ADR-0025);
  it runs in the Python CI job.
- `assets.yaml`: every asset hook the code asks for (`PofuKitArt`,
  `PofuPaint`, `Sticker`) with its state, `unpainted` < `painted` <
  `picked` < `in_repo` < `in_bundle` < `in_frame` ([asset system v1](../design/asset-system-v1.md)
  section 2.4), its master and why it is not in a frame yet. Checked by
  `python3 -I tools/state/check_assets.py`: a hook without a row fails, and
  `in_bundle` is derived from the bundle. The lead sets `in_frame` after a
  1:1 crop of a device-size frame.

## Who updates

- **Lead:** `lead_pick` and `painted` when it picks a take. `in_app` is
  not typed by hand: `check_plates.py` compares it with what the app's
  plate files ship and fails when they differ.
- **Codex:** never edits this file; it only paints the next null cell.
- **Founder:** `founder_ok`, by saying so; the lead writes it.

## The consultant model

When Fable is used, and its allowance: [studio.md](../studio.md) §8.
