#!/usr/bin/env python3
"""Pictures for agents who cannot hear: a piano roll of a tune, a spectrogram sheet of files.

    python3 -I tools/music/roll.py <tune.abc> <out.png>

The roll is pitch against time on the audition's own clock (the cells in the
director's order, with the pause between them), one colour a voice. Rows of
D major pentatonic are tinted, the lead's range (D4 to D6) is ruled, bar
lines are drawn, and percussion sits in a lane at the bottom. What to look
for: a lead that never rests (no white between its notes), never repeats (no
shape seen twice) or never moves (one flat line).
"""

from __future__ import annotations

import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    __package__ = "music"
    import music  # noqa: F401

from PIL import Image, ImageDraw, ImageFont

from . import abc

LOW, HIGH = 38, 88            # D2 to E6
ROW = 9                       # pixels a semitone
PX_PER_SECOND = 28
LEFT, TOP, LANE, BOTTOM, RIGHT = 46, 58, 30, 22, 16
PENTATONIC = {2, 4, 6, 9, 11}
LEAD_RANGE = (62, 86)
PERCUSSION = {"tok", "shaker"}
COLOURS = {
    "lead": [(232, 89, 12), (176, 42, 55)],
    "bed": [(116, 169, 216), (31, 78, 121)],
    "pulse": [(91, 168, 91), (122, 92, 62), (140, 140, 140)],
}


def _font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:               # Pillow before 10.1
        return ImageFont.load_default()


def voice_colours(tune: abc.Tune) -> dict[str, tuple[int, int, int]]:
    seen: dict[str, int] = {}
    out = {}
    for voice in tune.voices:
        shades = COLOURS[voice.stem]
        out[voice.id] = shades[seen.get(voice.stem, 0) % len(shades)]
        seen[voice.stem] = seen.get(voice.stem, 0) + 1
    return out


def piano_roll(tune: abc.Tune, out: Path | None = None) -> Image.Image:
    from .render import audition_layout
    layout = audition_layout(tune)
    seconds = layout[-1][2] + 1.0
    rows = HIGH - LOW + 1
    width = LEFT + int(seconds * PX_PER_SECOND) + RIGHT
    height = TOP + rows * ROW + LANE + BOTTOM
    image = Image.new("RGB", (width, height), (236, 236, 232))
    draw = ImageDraw.Draw(image)
    small, big = _font(11), _font(14)
    whole = tune.whole_seconds
    colours = voice_colours(tune)

    def x_of(t: float) -> int:
        return LEFT + int(round(t * PX_PER_SECOND))

    def y_of(midi: int) -> int:
        return TOP + (HIGH - midi) * ROW

    lane_top = TOP + rows * ROW + 4
    for name, start, end in layout:
        draw.rectangle([x_of(start), TOP, x_of(end), TOP + rows * ROW + LANE], fill=(255, 255, 255))
        for midi in range(LOW, HIGH + 1):
            if midi % 12 in PENTATONIC:
                draw.rectangle([x_of(start), y_of(midi), x_of(end), y_of(midi) + ROW - 1],
                               fill=(246, 243, 232))
        bars = int(round((end - start) / (float(tune.bar) * whole)))
        for bar in range(bars + 1):
            x = x_of(start + bar * float(tune.bar) * whole)
            draw.line([x, TOP, x, TOP + rows * ROW + LANE], fill=(200, 200, 200))
        draw.text((x_of(start) + 4, TOP - 17), f"cell {name}", fill=(40, 40, 40), font=small)
    for midi in range(LOW, HIGH + 1):
        if midi % 12 == 2:
            draw.line([LEFT, y_of(midi) + ROW, width - RIGHT, y_of(midi) + ROW], fill=(170, 170, 170))
            draw.text((6, y_of(midi) - 1), f"D{midi // 12 - 1}", fill=(60, 60, 60), font=small)
    for edge in (LEAD_RANGE[0] - 1, LEAD_RANGE[1]):
        y = y_of(edge)
        for x in range(LEFT, width - RIGHT, 8):
            draw.line([x, y, x + 3, y], fill=(232, 89, 12))

    lead_last = sorted(tune.voices, key=lambda v: v.stem == "lead")
    for voice in lead_last:
        colour = colours[voice.id]
        percussion = voice.instrument in PERCUSSION
        for name, start, _ in layout:
            for event in tune.cell(name).events(voice.id):
                x0 = x_of(start + float(event.start) * whole)
                x1 = x_of(start + float(event.end) * whole) - 2
                if percussion:
                    row = lane_top + (0 if voice.instrument == "tok" else 12)
                    draw.rectangle([x0, row, x0 + 3, row + 9], fill=colour)
                    continue
                for pitch in event.pitches:
                    if LOW <= pitch <= HIGH:
                        y = y_of(pitch)
                        draw.rectangle([x0, y + 1, max(x1, x0 + 2), y + ROW - 2], fill=colour,
                                       outline=(90, 30, 0) if voice.stem == "lead" else None)

    title = (f"{tune.title}   {tune.key.tonic} {tune.key.mode}   {tune.meter[0]}/{tune.meter[1]}   "
             f"{tune.bpm} beats a minute   order {' '.join(tune.order)}")
    draw.text((LEFT, 6), title, fill=(20, 20, 20), font=big)
    x = LEFT
    for voice in tune.voices:
        label = f"{voice.id} ({voice.instrument})"
        draw.rectangle([x, height - 16, x + 10, height - 6], fill=colours[voice.id])
        draw.text((x + 14, height - 18), label, fill=(40, 40, 40), font=small)
        x += 24 + int(draw.textlength(label, font=small))
    for second in range(0, int(seconds) + 1, 5):
        draw.text((x_of(second) + 2, TOP - 30), f"{second}s", fill=(120, 120, 120), font=small)
    if out is not None:
        image.save(out, optimize=True)
    return image


_HEAT = [(0, 0, 4), (60, 15, 110), (150, 40, 120), (230, 90, 60), (252, 200, 100), (252, 253, 191)]


def spectrogram_sheet(paths: list[Path], out: Path, top_hz: float = 8000.0) -> Image.Image:
    """0 to 8 kHz of each file, one strip a file: clicks are vertical lines, harshness is a bright top."""
    import numpy as np
    from scipy import signal

    from .band import SR, sound
    heat = np.array(_HEAT, dtype=float)
    strips = []
    for path in paths:
        x = np.mean(sound.read_audio(path), axis=0)
        f, _, s = signal.spectrogram(x, SR, nperseg=2048, noverlap=1024)
        db = 10 * np.log10(s[f <= top_hz] + 1e-14)
        level = np.clip((db + 130) / 80, 0, 1)[::-1] * (len(heat) - 1)
        low = np.clip(level.astype(int), 0, len(heat) - 2)
        rgb = heat[low] + (heat[low + 1] - heat[low]) * (level - low)[..., None]
        strip = Image.fromarray(rgb.astype("uint8")).resize((1200, 160), Image.BILINEAR)
        strips.append((path.name, strip))
    sheet = Image.new("RGB", (1200, 182 * len(strips)), (20, 20, 20))
    draw = ImageDraw.Draw(sheet)
    for i, (name, strip) in enumerate(strips):
        sheet.paste(strip, (0, 182 * i + 20))
        draw.text((6, 182 * i + 3), f"{name}   0 to {top_hz / 1000:g} kHz", fill=(230, 230, 230),
                  font=_font(12))
    sheet = sheet.quantize(48)          # a small file: this is for eyes, not for measuring
    sheet.save(out, optimize=True)
    return sheet


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 2:
        print(__doc__)
        return 2
    piano_roll(abc.load(args[0]), Path(args[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
