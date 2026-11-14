# tools/proof

One-off proofs that answer a design question with pictures, run by script from the shipped assets and
never committed as outputs.

- `station_looks.py`: proof 1 of `docs/design/feel-and-world-v1.md`. Cuts the tea stall's and the garden's
  painted looks out of the Home plates, composites each into another plate (richer on early, humbler on late,
  day and night) and renders stills at far (0.76), island fit (0.9 widths) and a 2.7 near cap.
  `python3 -I tools/proof/station_looks.py build OUT_DIR` (needs `pip install -r tools/plate/requirements.txt`).
