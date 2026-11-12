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

## Who updates

- **Lead:** `lead_pick` and `painted` when it picks a take. `in_app` is
  not typed by hand: `check_plates.py` compares it with what the app's
  plate files ship and fails when they differ.
- **Codex:** never edits this file; it only paints the next null cell.
- **Founder:** `founder_ok`, by saying so; the lead writes it.

## The consultant model

When Fable is used, and its allowance: [studio.md](../studio.md) §8.
