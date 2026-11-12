# AGENTS.md: the art factory moved

The Codex image-generation workflow (Factory mode, the queue, `tools/imagegen` runs and
delivery PRs) lives in the private repository **`ErenDenizK/pofu-art`** (ADR-0026). Its
`AGENTS.md` is the brief Codex reads; its `QUEUE.md` is the queue.

- **Codex must not open art PRs in this repository.** Open a Codex environment on
  `pofu-art` and paste the start message from that repository's `README.md`.
- Anything else you do here follows [`CLAUDE.md`](CLAUDE.md) and
  [`CONTRIBUTING.md`](CONTRIBUTING.md); never push to `main`.
- Past art (takes, contact sheets, deliveries) stays in this repository's history untouched;
  the lead brings picks back with `tools/art/ingest.py`.
