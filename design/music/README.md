# design/music

The score and what was rendered from it. The system is
[docs/design/music-system-v1.md](../../docs/design/music-system-v1.md); the
tools and the notation are [tools/music](../../tools/music/README.md).

- `score/motif.abc`: the Pofu motif, four notes (D F# B A).
- `score/home/day-a.abc`, `day-b.abc`, `day-c.abc`: three candidates for
  Home's day tune. The one the founder picks becomes `day.abc`.
- `audition/`: one file a candidate, with its piano roll, `levels.json`
  (what the meter read) and `spectrograms.png`. Made by
  `python3 -I tools/music/render.py audition`; never edited by hand.

| Listen | Tune | In a line |
|---|---|---|
| `audition/home-day-a.m4a` | A, "Sunny step" | 4/4 at 96. The bouncy one: two short steps and a long note, keys on the off beats, a wood tok |
| `audition/home-day-b.m4a` | B, "Rocking boat" | 6/8 at 92. The lilting one: long-short, long-short, two-bar phrases that each end on a breath |
| `audition/home-day-c.m4a` | C, "Petals down" | 4/4 at 88. The gentle one: it starts high and falls, and the motif answers from below; no tok |

Each file is the tune's four cells in the director's order (A, A2, B, END)
with two seconds of silence between them; in the app the pause is 4 to 12
seconds of the island's own air. Mono AAC at 64 kbit/s, as the app will
ship. All three are in D Ionian on the kalimba, with a pad and a bass under
them and felt keys as the pulse.
