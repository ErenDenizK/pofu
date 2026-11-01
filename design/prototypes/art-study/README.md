# Art direction study page

A phone-friendly page (Turkish captions for the founder) comparing four
style-lock treatments of the same scene from art test 01: the island
take 1, çay ocağı L1 and L2, and Pofu. The reasoning, the measurements
and the recommendation are in
[`docs/design/art-direction-study.md`](../../../docs/design/art-direction-study.md).

- `index.html` and `assets/` are generated: do not edit them by hand.
- Rebuild (about three minutes, deterministic):

  ```sh
  python3 -I design/prototypes/art-study/tools/build.py
  ```

  It runs the presets in `tools/imagegen/style_lock.json` and writes the
  scenes, per-asset thumbnails, close-ups and `assets/metrics.json`.
- Sandbox-safe: relative paths, no query strings, no dialogs, UTF-8,
  `viewport-fit=cover`, no horizontal scroll at 375 px, about 0.8 MB.
