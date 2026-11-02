"""Encode the motion beats for phones and index the screenshots branch.

    python3 -I encode-beats.py <motion-beats artifact> <out folder> <repo> <branch>

Each raw simulator recording (`raw/<beat>.mov`) becomes `beats/<beat>.mp4`:
H.264 High, yuv420p, 30 fps, 720 px wide, faststart, no audio, at most
10 s and 8 MB (re-encoded at a lower quality until it fits), plus a poster
frame `beats/<beat>.jpg`. Then `README.md` lists every clip with its size
and a raw link that plays in Safari on an iPhone, and the screenshots.
"""

import pathlib
import subprocess
import sys

MAX_BYTES = 8 * 1024 * 1024
MAX_SECONDS = 10


def encode(src: pathlib.Path, dst: pathlib.Path) -> None:
    for crf in (23, 26, 29, 32, 35):
        subprocess.run(
            [
                "ffmpeg", "-loglevel", "error", "-y", "-i", str(src),
                "-t", str(MAX_SECONDS),
                "-vf", "fps=30,scale=720:-2:flags=lanczos,format=yuv420p",
                "-c:v", "libx264", "-profile:v", "high", "-preset", "slow", "-crf", str(crf),
                "-movflags", "+faststart", "-an", str(dst),
            ],
            check=True,
        )
        if dst.stat().st_size <= MAX_BYTES:
            return
    sys.exit(f"{dst.name} is still over {MAX_BYTES} bytes")


def poster(src: pathlib.Path, dst: pathlib.Path) -> None:
    subprocess.run(
        [
            "ffmpeg", "-loglevel", "error", "-y", "-ss", "1", "-i", str(src),
            "-frames:v", "1", "-vf", "scale=360:-2", "-q:v", "4", str(dst),
        ],
        check=True,
    )


def duration(path: pathlib.Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    return float(out or 0)


def main() -> None:
    src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    repo, branch = sys.argv[3], sys.argv[4]
    titles = {}
    tsv = src / "beats.tsv"
    if tsv.exists():
        for line in tsv.read_text().splitlines():
            parts = line.split("\t")
            if len(parts) >= 2:
                titles[parts[0]] = parts[1]

    raws = sorted((src / "raw").glob("*.mov"))
    if not raws:
        sys.exit("no recordings in the motion-beats artifact")
    beats = out / "beats"
    beats.mkdir(parents=True, exist_ok=True)
    raw_base = f"https://github.com/{repo}/raw/{branch}"
    rows = []
    for raw in raws:
        mp4 = beats / f"{raw.stem}.mp4"
        encode(raw, mp4)
        poster(mp4, beats / f"{raw.stem}.jpg")
        size = mp4.stat().st_size
        rows.append(
            f"| [{raw.stem}]({raw_base}/beats/{raw.stem}.mp4) | {titles.get(raw.stem, '')} "
            f"| {duration(mp4):.1f} s | {size / 1024 / 1024:.2f} MB |"
        )
        print(f"{mp4.name}: {size} bytes")

    shots = sorted(p.name for p in out.glob("*.jpg"))
    lines = [
        f"# Review media for `{branch.removeprefix('screenshots/')}`",
        "",
        "Rendered by CI in the iOS simulator. Tap a clip to play it (Safari plays the raw MP4).",
        "Recordings on CI machines drop frames: judge choreography and timing, not smoothness.",
        "",
        "## Motion beats",
        "",
        "| Clip | Beat | Length | Size |",
        "|---|---|---|---|",
        *rows,
        "",
        "## Screenshots",
        "",
        *[f"- [{name}]({name})" for name in shots],
        "",
    ]
    (out / "README.md").write_text("\n".join(lines))


if __name__ == "__main__":
    main()
