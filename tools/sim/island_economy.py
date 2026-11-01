#!/usr/bin/env python3
"""Island economy simulation for Pofu: care, calm and idle stations.

Models the founder's direction (docs/product/game-design.md):

- **Pofu's health** (0-100, never below 5): opening a guarded app drains it,
  quiet time and calm nights heal it. No price in coins.
- **The calm multiplier** (1.0x -> 2.0x): grows with continuous calm waking
  time, holds overnight, and resets to 1.0x when a guarded app opens.
  Resisting does not reset it.
- **Idle production:** stations on fixed slots make *goodies* (an in-world
  material) every minute, at their level's rate times the calm multiplier.
- **Pre-planned upgrades:** eight stations, five levels each, gated by
  island stages that grow with tended days.

Behavior (reaches, resisting, binge continuation, night sessions) uses the
same archetypes as before, minute by minute, with the soft-gate ladder
pause -> intent -> care step (-> ask a friend on the fourth rapid reach).

Targets the tuning must meet:
  1. everyone upgrades something on day 1;
  2. nobody completes the world before about day 45;
  3. scrolling visibly slows the world (through the multiplier) and visibly
     hurts Pofu, but never kills him, and a quiet day always helps.

Run (numpy, pandas, matplotlib from PyPI):

    python3 -I tools/sim/island_economy.py            # table + charts
    python3 -I tools/sim/island_economy.py --runs 10 --no-charts
"""

from __future__ import annotations

import argparse
import os
import random
from dataclasses import dataclass, field

DAYS = 60
MIN_PER_DAY = 1440           # minute 0 is 06:00
BED_START = 17 * 60          # 23:00
WAKE = 60                    # 07:00
NIGHT_SESSION_END = 18 * 60 + 30   # 00:30
HOME_VISITS = (2 * 60, 7 * 60, 14 * 60 + 30)  # 08:00, 13:00, 20:30
LADDER_COOLDOWN = 60
FREE_PASS = 5
EMERGENCY_PASS = 3
FRIEND_APPROVE_P = 0.5
FRIEND_PASS = 15
ESCALATION_WINDOW = 180

# --- Care (proposed) ---------------------------------------------------------
HEALTH_START = 70.0
HEALTH_FLOOR = 5.0           # Pofu never dies: deep sleep, curled up, always recoverable
DRAIN_PER_MIN = 0.35         # per minute of guarded-app time, daytime
DRAIN_NIGHT_MULT = 2.0       # inside bedtime, like night pricing in economy v0
DRAIN_ESCALATION = 1.25      # per earlier open in the last 3 h, like price escalation
DRAIN_PER_OPEN = 1.5         # the reach itself
HEAL_PER_CALM_HOUR = 5.0     # waking calm time
HEAL_SLEPT_ON_IT = 10.0      # a bedtime window without opens
HEAL_PER_SKIP = 1.0          # a resisted reach, at most SKIP_HEAL_CAP a day
SKIP_HEAL_CAP = 6
UNWELL = 25.0                # below this, residents stop to care for Pofu
UNWELL_PRODUCTION = 0.6
NIGHT_RECOVERY = 0.3          # each night, health below 60 moves 30 % of the way back to 60 ("sleeps it off")
RECOVERY_TARGET = 60.0

# --- Calm multiplier (proposed) ---------------------------------------------
CALM_STEP = 0.1              # +0.1x ...
CALM_STEP_MIN = 20           # ... per 20 continuous calm waking minutes
CALM_MAX = 2.0               # reached after 3 h 20 min
CALM_SLEEP_BONUS = 0.2       # a calm night adds +0.2x (within the cap)

# --- Island stages: tended days -> stage -------------------------------------
STAGES = [0, 1, 4, 10, 20, 34]   # stage n needs STAGES[n] tended days

# Stations: (id, name, stage, base rate goodies/hour at L1, build cost)
STATIONS = [
    ("garden", "Sunflower garden", 0, 6, 0),       # Pofu's own, starts at level 1
    ("cay", "Çay ocağı", 1, 5, 40),
    ("simit", "Simit stand", 2, 8, 250),
    ("pond", "Lily pond", 2, 4, 200),
    ("library", "Library", 3, 10, 700),
    ("workshop", "Workshop", 3, 10, 800),
    ("observatory", "Observatory", 4, 14, 1800),
    ("hamam", "Hamam", 5, 16, 2400),
]
LEVELS = 5
COST_GROWTH = 2.3            # each level costs 2.3x the previous
RATE_GROWTH = 0.55           # rate(L) = base x (1 + 0.55 (L-1))
GARDEN_L2_COST = 30          # the day-1 upgrade


def upgrade_cost(station, level_to):
    """Cost to reach `level_to` (1 = build)."""
    sid, _, _, _, build = station
    if sid == "garden":
        return 0 if level_to == 1 else round(GARDEN_L2_COST * COST_GROWTH ** (level_to - 2))
    return round(build * COST_GROWTH ** (level_to - 1))


def rate(station, level):
    return 0.0 if level == 0 else station[3] * (1 + RATE_GROWTH * (level - 1))


TOTAL_COST = sum(upgrade_cost(s, l) for s in STATIONS for l in range(1, LEVELS + 1))


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def _c(v):
    return lambda d: v


@dataclass
class Archetype:
    key: str
    label: str
    reach_per_hour: callable
    resist_p: callable
    continue_p: callable
    night_p: callable
    open_minutes: int
    end_early_p: float = 0.1


def archetypes():
    def relapse(a, b, c):
        return lambda d: a(d) if d < 18 else (b(d) if d < 28 else c(d))
    return [
        Archetype("heavy", "Heavy scroller, improving", lambda d: lerp(3.0, 1.2, d / 45), lambda d: lerp(0.15, 0.55, d / 45),
                  lambda d: lerp(0.75, 0.40, d / 45), lambda d: lerp(0.60, 0.15, d / 45), 15),
        Archetype("moderate", "Moderate", _c(1.5), lambda d: lerp(0.35, 0.50, d / 30), _c(0.5), _c(0.25), 15),
        Archetype("disciplined", "Already disciplined", _c(0.6), _c(0.75), _c(0.2), _c(0.05), 10, 0.3),
        Archetype("relapse", "Relapse and recover",
                  relapse(lambda d: lerp(1.6, 1.0, d / 17), _c(2.6), lambda d: lerp(1.6, 1.0, (d - 28) / 20)),
                  relapse(lambda d: lerp(0.40, 0.60, d / 17), _c(0.15), lambda d: lerp(0.40, 0.60, (d - 28) / 20)),
                  relapse(_c(0.45), _c(0.80), _c(0.45)), relapse(_c(0.2), _c(0.65), _c(0.2)), 15),
        Archetype("monk", "Never opens (upper bound)", _c(0.3), _c(1.0), _c(0.0), _c(0.0), 10, 0.0),
    ]


@dataclass
class DayLog:
    day: int
    feed_minutes: int = 0
    attempts: int = 0
    resisted: int = 0
    opens: int = 0
    resets: int = 0
    produced: float = 0.0
    spent: int = 0
    upgrades: list = field(default_factory=list)
    health_min: float = 100.0
    health_end: float = 0.0
    calm_avg: float = 0.0       # waking-minute average
    calm_peak: float = 1.0
    stage: int = 0
    trace: list = field(default_factory=list)  # (minute, calm, health, app open) every 2 min


def simulate(a: Archetype, rng: random.Random, resist_shift=0.0, loss_aversion=0.0, keep_trace_day=None):
    levels = {s[0]: 0 for s in STATIONS}
    levels["garden"] = 1
    pantry = 0.0
    health = HEALTH_START
    calm = 1.0
    calm_run = 0
    opens_window: list[int] = []
    last_attempt = -10_000
    rung = 0
    tended = 0
    logs = []
    for d in range(DAYS):
        log = DayLog(d)
        stage = max(i for i, need in enumerate(STAGES) if tended >= need)
        log.stage = stage
        base = d * MIN_PER_DAY
        lam = a.reach_per_hour(d) / 60
        resist = max(0.0, min(1.0, a.resist_p(d) + resist_shift))
        cont = a.continue_p(d)
        night_session = rng.random() < a.night_p(d)
        night_at = rng.randint(BED_START + 5, NIGHT_SESSION_END) if night_session else None
        pass_until = -1
        pending = None
        emergency_used = False
        skips_healed = 0
        calm_night = True
        calm_sum = 0.0
        waking = 0

        def visit():
            nonlocal pantry
            made = 0
            while made < 2:
                opts = [(upgrade_cost(s, levels[s[0]] + 1), s) for s in STATIONS
                        if s[2] <= stage and levels[s[0]] < LEVELS]
                if not opts:
                    break
                cost, s = min(opts, key=lambda x: x[0])
                if pantry < cost:
                    break
                pantry -= cost
                levels[s[0]] += 1
                log.spent += cost
                log.upgrades.append(f"{s[0]} L{levels[s[0]]}")
                made += 1

        for m in range(MIN_PER_DAY):
            t = base + m
            bedtime = m >= BED_START
            awake = (WAKE <= m < BED_START) or (night_session and BED_START <= m < NIGHT_SESSION_END + 30)
            in_pass = pass_until > t
            # production (24 h), times calm, reduced while Pofu is unwell
            hf = UNWELL_PRODUCTION if health < UNWELL else 1.0
            prod = sum(rate(s, levels[s[0]]) for s in STATIONS) / 60 * calm * hf
            pantry += prod
            log.produced += prod
            # care and calm
            if in_pass:
                log.feed_minutes += 1
                k = len([o for o in opens_window if o > t - ESCALATION_WINDOW]) - 1
                drain = DRAIN_PER_MIN * (DRAIN_NIGHT_MULT if bedtime else 1) * DRAIN_ESCALATION ** max(0, k)
                health = max(HEALTH_FLOOR, health - drain)
                calm_run = 0
                if bedtime:
                    calm_night = False
            elif not bedtime:
                calm_run += 1
                health = min(100.0, health + HEAL_PER_CALM_HOUR / 60)
                if calm_run % CALM_STEP_MIN == 0:
                    calm = min(CALM_MAX, round(calm + CALM_STEP, 2))
            if not bedtime and m >= WAKE:
                calm_sum += calm
                waking += 1
            log.calm_peak = max(log.calm_peak, calm)
            log.health_min = min(log.health_min, health)
            if keep_trace_day == d and m % 2 == 0:
                log.trace.append((m, calm, health, in_pass))
            if m in HOME_VISITS:
                visit()
            # reaches
            reach = False
            if not in_pass:
                if pending is not None and t >= pending:
                    reach, pending = True, None
                elif awake and not bedtime and rng.random() < lam:
                    reach = True
                elif night_at is not None and m == night_at:
                    reach = True
            if not reach:
                continue
            log.attempts += 1
            if t - last_attempt < LADDER_COOLDOWN:
                rung = min(rung + 1, 3)
            else:
                rung = 0
            last_attempt = t
            p_res = resist + (0.15 if rung >= 2 else 0) + loss_aversion * (calm - 1.0)
            if bedtime:
                p_res = min(p_res, 0.3)
            if rng.random() < min(1.0, p_res):
                log.resisted += 1
                if skips_healed < SKIP_HEAL_CAP:
                    skips_healed += 1
                    health = min(100.0, health + HEAL_PER_SKIP)
                continue
            if rung < 2:
                minutes = FREE_PASS
            elif rung == 2:
                minutes = a.open_minutes
            else:  # fourth rapid reach: a friend, else the emergency pass, else resisted
                if rng.random() < FRIEND_APPROVE_P:
                    minutes = FRIEND_PASS
                elif not emergency_used:
                    emergency_used, minutes = True, EMERGENCY_PASS
                else:
                    log.resisted += 1
                    continue
            if rng.random() < a.end_early_p:
                minutes = max(1, minutes // 3)
            log.opens += 1
            if calm > 1.0:
                log.resets += 1
            calm = 1.0
            calm_run = 0
            opens_window.append(t)
            opens_window[:] = [o for o in opens_window if o > t - ESCALATION_WINDOW]
            health = max(HEALTH_FLOOR, health - DRAIN_PER_OPEN)
            pass_until = t + minutes
            if rng.random() < cont:
                pending = pass_until + rng.randint(0, 3)
        if health < RECOVERY_TARGET:
            health += NIGHT_RECOVERY * (RECOVERY_TARGET - health)
        if calm_night:
            health = min(100.0, health + HEAL_SLEPT_ON_IT)
            calm = min(CALM_MAX, round(calm + CALM_SLEEP_BONUS, 2))
        log.calm_avg = calm_sum / max(1, waking)
        log.health_end = health
        tended += 1
        logs.append(log)
    return logs, levels


def summarize(logs):
    spent = 0
    first_up = None
    done = None
    pct = []
    for lg in logs:
        spent += lg.spent
        if lg.upgrades and first_up is None:
            first_up = lg.day + 1
        pct.append(spent / TOTAL_COST)
        if done is None and spent >= TOTAL_COST:
            done = lg.day + 1
    return {
        "first_upgrade": first_up, "done": done, "pct30": pct[29], "pct60": pct[-1], "pct": pct,
        "calm": sum(l.calm_avg for l in logs) / len(logs),
        "calm_wk1": sum(l.calm_avg for l in logs[:7]) / 7, "calm_last": sum(l.calm_avg for l in logs[-7:]) / 7,
        "resets": sum(l.resets for l in logs) / len(logs),
        "health_wk1": sum(l.health_end for l in logs[:7]) / 7, "health_last": sum(l.health_end for l in logs[-7:]) / 7,
        "health_min": min(l.health_min for l in logs),
        "unwell_days": sum(1 for l in logs if l.health_end < UNWELL),
        "feed_wk1": sum(l.feed_minutes for l in logs[:7]) / 7, "feed_last": sum(l.feed_minutes for l in logs[-7:]) / 7,
        "health": [l.health_end for l in logs],
        "produced": sum(l.produced for l in logs),
    }


def median(xs):
    xs = sorted(x for x in xs if x is not None)
    if not xs:
        return None
    n = len(xs)
    return xs[n // 2] if n % 2 else (xs[n // 2 - 1] + xs[n // 2]) / 2


def run(runs, seed=7, **kw):
    out = {}
    for a in archetypes():
        rows = [summarize(simulate(a, random.Random(seed * 1000 + r), **kw)[0]) for r in range(runs)]
        out[a.key] = (a, rows)
    return out


def table(results, runs):
    L = ["| Archetype | First upgrade (day) | World done (day) | World at day 30 | World at day 60 | Calm avg wk 1 → wk 9 | Resets/day | Pofu's health wk 1 → wk 9 (lowest) | Unwell days | Feed min/day wk 1 → wk 9 |",
         "|" + "---|" * 10]
    for key, (a, rows) in results.items():
        done = [r["done"] for r in rows]
        n = sum(1 for x in done if x)
        dt = f"{median(done):.0f}" if n == len(rows) else (f"{median(done):.0f} ({n}/{len(rows)} runs)" if n else "not by 60")
        g = lambda k: median([r[k] for r in rows])
        L.append(f"| {a.label} | {g('first_upgrade'):.0f} | {dt} | {g('pct30') * 100:.0f} % | {g('pct60') * 100:.0f} % "
                 f"| {g('calm_wk1'):.2f}× → {g('calm_last'):.2f}× | {g('resets'):.1f} | {g('health_wk1'):.0f} → {g('health_last'):.0f} ({g('health_min'):.0f}) "
                 f"| {g('unwell_days'):.0f} | {g('feed_wk1'):.0f} → {g('feed_last'):.0f} |")
    L.append("")
    L.append(f"_Medians of {runs} runs, 60 days. World = all 8 stations at level 5, {TOTAL_COST:,} goodies in total._")
    return "\n".join(L)


# --- charts -----------------------------------------------------------------
# Categorical palette validated with the dataviz validator; direct labels and
# line styles are the secondary encoding.
PALETTE = {"heavy": "#6C4FD8", "moderate": "#D9822B", "disciplined": "#2F8F5B", "relapse": "#3E7CB1", "monk": "#C2457A"}
STYLES = {"heavy": "-", "moderate": "-", "disciplined": "-", "relapse": "--", "monk": ":"}
INK, MUTED, GRID, SURFACE = "#2A1F2D", "#66555F", "#E9E2E6", "#FCFCFB"


def _style(ax):
    ax.set_facecolor(SURFACE)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color("#CFC3CB")
    ax.tick_params(colors=MUTED, labelsize=9)
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)


def _lines(ax, results, key, scale=1.0):
    import numpy as np
    days = np.arange(1, DAYS + 1)
    ends = []
    for k, (a, rows) in results.items():
        m = np.array([r[key] for r in rows]) * scale
        med = np.median(m, axis=0)
        ax.fill_between(days, np.percentile(m, 10, axis=0), np.percentile(m, 90, axis=0), color=PALETTE[k], alpha=0.10, linewidth=0)
        ax.plot(days, med, STYLES[k], color=PALETTE[k], linewidth=2)
        ends.append([med[-1], a.label, PALETTE[k]])
    return ends


def _labels(ax, ends, gap):
    ends.sort(reverse=True)            # stack downward from the highest so labels never leave the plot
    for i in range(1, len(ends)):
        ends[i][0] = min(ends[i][0], ends[i - 1][0] - gap)
    for y, label, color in ends:
        ax.text(DAYS + 1.2, y, label, color=INK, fontsize=8.5, va="center")
        ax.plot([DAYS + 0.2, DAYS + 0.9], [y, y], color=color, linewidth=2)


def charts(results, trace, sens, outdir):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    os.makedirs(outdir, exist_ok=True)
    plt.rcParams.update({"font.family": "DejaVu Sans", "text.color": INK, "axes.labelcolor": MUTED})

    def fig(w=8.0, h=4.4):
        f, ax = plt.subplots(figsize=(w, h), dpi=110)
        f.patch.set_facecolor(SURFACE)
        _style(ax)
        return f, ax

    # 1. world progress
    f, ax = fig()
    _labels(ax, _lines(ax, results, "pct", 100), 6)
    for i, need in enumerate(STAGES[1:], start=2):
        ax.axvline(need + 1, color=GRID, linewidth=1, zorder=0)
        ax.text(need + 1.3, 103, f"stage {i}", color=MUTED, fontsize=7.5)
    ax.axvline(45, color=MUTED, linewidth=1, linestyle=(0, (2, 2)))
    ax.text(45.5, 3, "day 45 target", color=MUTED, fontsize=8)
    ax.set_xlim(1, DAYS)
    ax.set_ylim(0, 108)
    ax.set_xlabel("Day")
    ax.set_ylabel("World built (% of all upgrades)")
    ax.set_title("The island by archetype (median, band = p10–p90)", loc="left", fontsize=11, color=INK)
    f.subplots_adjust(right=0.72, left=0.09, bottom=0.12, top=0.9)
    f.savefig(os.path.join(outdir, "island-progress.png"), facecolor=SURFACE)
    plt.close(f)

    # 2. Pofu's health
    f, ax = fig()
    _labels(ax, _lines(ax, results, "health"), 5)
    ax.axhspan(0, UNWELL, color="#F3E4E8", zorder=0)
    ax.text(1.5, 13, "unwell: curled up, never gone", color=MUTED, fontsize=8)
    ax.axhline(HEALTH_FLOOR, color=MUTED, linewidth=0.8, linestyle=(0, (2, 2)))
    ax.set_xlim(1, DAYS)
    ax.set_ylim(0, 102)
    ax.set_xlabel("Day")
    ax.set_ylabel("Pofu's health at bedtime")
    ax.set_title("Pofu's health: scrolling drains, quiet heals", loc="left", fontsize=11, color=INK)
    f.subplots_adjust(right=0.72, left=0.09, bottom=0.12, top=0.9)
    f.savefig(os.path.join(outdir, "island-health.png"), facecolor=SURFACE)
    plt.close(f)

    # 3. one day of the calm multiplier (moderate player)
    f, ax = fig(8, 3.4)
    xs = [6 + m / 60 for m, *_ in trace]
    ax.step(xs, [c for _, c, *_ in trace], where="post", color="#2F8F5B", linewidth=2)
    for m, c, h, p in trace:
        if p:
            ax.axvspan(6 + m / 60, 6 + (m + 2) / 60, color="#C9B8F5", linewidth=0, zorder=0)
    ax.axvspan(23, 30, color="#EEEAF2", linewidth=0, zorder=0)
    ax.text(23.3, 1.93, "bedtime: holds", color=MUTED, fontsize=8)
    ax.set_xlim(6, 30)
    ax.set_ylim(0.9, 2.05)
    ax.set_xticks([6, 9, 12, 15, 18, 21, 24, 27, 30])
    ax.set_xticklabels(["06", "09", "12", "15", "18", "21", "00", "03", "06"])
    ax.set_ylabel("Calm multiplier")
    ax.set_title("One day, moderate player: calm grows, an open resets it (violet = app open)", loc="left", fontsize=10.5, color=INK)
    f.subplots_adjust(left=0.09, right=0.98, bottom=0.12, top=0.88)
    f.savefig(os.path.join(outdir, "island-calm-day.png"), facecolor=SURFACE)
    plt.close(f)

    # 4. sensitivity: resist more -> calmer, faster world
    f, (a1, a2) = plt.subplots(1, 2, figsize=(8, 3.4), dpi=110)
    f.patch.set_facecolor(SURFACE)
    labels = [f"{s * 100:+.0f} pp".replace("+0 pp", "±0") for s, *_ in sens]
    for ax, idx, title, fmt, color in ((a1, 1, "Average calm multiplier (days 1–30)", "{:.2f}×", "#2F8F5B"),
                                       (a2, 2, "Goodies made, days 1–30", "{:,.0f}", "#6C4FD8")):
        _style(ax)
        vals = [r[idx] for r in sens]
        ax.bar(range(len(vals)), vals, color=color, width=0.6, edgecolor=SURFACE, linewidth=2)
        for i, v in enumerate(vals):
            ax.text(i, v, fmt.format(v), ha="center", va="bottom", fontsize=8, color=INK)
        ax.set_xticks(range(len(vals)))
        ax.set_xticklabels(labels, fontsize=8.5)
        ax.set_xlabel("Moderate player: resist probability shift", fontsize=8.5)
        ax.set_title(title, loc="left", fontsize=10, color=INK)
        ax.set_yticks([])
        ax.spines["left"].set_visible(False)
    f.suptitle("Scrolling visibly slows the island", x=0.02, ha="left", fontsize=11, color=INK)
    f.subplots_adjust(left=0.03, right=0.98, bottom=0.2, top=0.8, wspace=0.12)
    f.savefig(os.path.join(outdir, "island-sensitivity.png"), facecolor=SURFACE)
    plt.close(f)


def sensitivity(runs, seed=11):
    a = next(x for x in archetypes() if x.key == "moderate")
    rows = []
    for shift in (-0.2, -0.1, 0.0, 0.1, 0.2, 0.3):
        cs, ws = [], []
        for r in range(runs):
            logs, _ = simulate(a, random.Random(seed * 1000 + r), resist_shift=shift)
            cs.append(sum(l.calm_avg for l in logs[:30]) / 30)
            ws.append(sum(l.produced for l in logs[:30]))
        rows.append((shift, median(cs), median(ws)))
    return rows


def main():
    ap = argparse.ArgumentParser(description="Pofu island economy simulation")
    ap.add_argument("--runs", type=int, default=40)
    ap.add_argument("--no-charts", action="store_true")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "..", "docs", "product", "assets"))
    args = ap.parse_args()

    print("Station ladder (cost to reach level 1..5; goodies/hour at level 1..5):")
    for s in STATIONS:
        print(f"  {s[1]:<17} stage {s[2] + 1}  cost {[upgrade_cost(s, l) for l in range(1, 6)]}  rate {[round(rate(s, l), 1) for l in range(1, 6)]}")
    print(f"  total {TOTAL_COST}\n")
    results = run(args.runs)
    print(table(results, args.runs))
    print()
    la = run(max(10, args.runs // 2), loss_aversion=0.25)
    print("With a loss-aversion response (+0.25 resist probability per 1.0x of calm at stake):")
    for key, (a, rows) in la.items():
        print(f"  {a.label}: world at day 60 {median([r['pct60'] for r in rows]) * 100:.0f} %, "
              f"calm {median([r['calm'] for r in rows]):.2f}x, feed wk 9 {median([r['feed_last'] for r in rows]):.0f} min")
    print()
    sens = sensitivity(max(10, args.runs // 2))
    print("| Resist shift (moderate) | Avg calm, days 1–30 | Goodies made, days 1–30 |")
    print("|---|---|---|")
    for s, c, w in sens:
        print(f"| {s * 100:+.0f} pp | {c:.2f}× | {w:,.0f} |")
    print("\nOne heavy-scroller run, upgrades on days 1-3:")
    hl, _ = simulate(archetypes()[0], random.Random(1))
    for lg in hl[:3]:
        print(f"  day {lg.day + 1}: {', '.join(lg.upgrades) or '-'}")
    if not args.no_charts:
        logs, _ = simulate(next(x for x in archetypes() if x.key == "moderate"), random.Random(3), keep_trace_day=10)
        charts(results, logs[10].trace, sens, os.path.abspath(args.out))
        print("charts written to", os.path.abspath(args.out))


if __name__ == "__main__":
    main()
