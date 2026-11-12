# State files

Machine-readable truth about what exists, so no agent has to guess or
re-read the chat. Plate-first (ADR-0022): one painted picture per island state.

- `plates.yaml`: every island x stage x time (day, golden, night) x weather
  (clear, rain) cell: `painted` (take path or null), `lead_pick` (take
  number), `in_app`, `founder_ok`. `root_time` names the hour of the island's
  picked root. Paint order is the next null `painted` cell (standing work in
  [the queue](https://github.com/ErenDenizK/pofu-art/blob/main/QUEUE.md#the-queue)).
- Checked by `python3 -I tools/state/check_plates.py` (paths and picks exist; each island also has a `sky_sets:` row per light, ADR-0025);
  it runs in the Python CI job.

## Who updates

- **Lead:** `lead_pick` and `painted` when it picks a take; `in_app` when a
  plate ships in the app.
- **Codex:** never edits this file; it only paints the next null cell.
- **Founder:** `founder_ok`, by saying so; the lead writes it.

## The four Fable checkpoints

The consultant model (Fable) is used only here; its usage draws on its own
and on the shared weekly limit (100% Fable is about 50% of a week).

1. The character harmony sheet, before scaling characters.
2. The first non-home island fully in the app.
3. Store screenshots and the first-run experience.
4. The pre-launch whole-game sheet (also a route review).
