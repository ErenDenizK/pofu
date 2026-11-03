#!/usr/bin/env python3
"""Archipelago economy simulation for Pofu: seeds as world material, care,

NOTE (2026-11-03): this script models the v2 scale (hundreds of seeds a day,
ladders up to tens of thousands). `PofuCore` now runs economy scale A (about
10-40 seeds a day, prices 5-200); the up-to-date simulation is the Swift
`GameScenarioTests` (typical archetype), which plays the real game model, and
docs/product/economy.md#economy-scale-a-small-numbers holds its table. The
behavior model below still describes the archetypes; do not read its seed
numbers as current.

calm, the breathing break, and idle stations across several islands.

Models docs/product/game-design.md (v2) and ADR-0015 to ADR-0017:

- **Seeds** (çekirdek) are world material only. They come from three
  sources: quiet time (Pofu gathers 1 per 10 quiet minutes, ADR-0014's
  rules), the stations' idle production times the calm multiplier (the
  residents work while no guarded app is open, night included), and a small
  capped gift per resisted reach. They buy station levels and nothing
  else; never screen time.
- **Pofu's wellbeing** (keyif, 5-100, never below 5): guarded-app time
  drains it, quiet time and calm nights heal it (from the bottom, one quiet
  hour lifts him a band; from "tired" up, 5 an hour), and each night he
  "sleeps it off" part of the way back to 60.
- **The calm multiplier** (huzur, x1.0 -> x2.0): grows with continuous calm
  waking time. A full open resets it to x1.0; a **quick check** (a pass of
  3 minutes or less) only halves the bonus, unless it follows another quick
  check within 20 minutes.
- **The breathing break:** once a day's guarded-app time reaches the
  threshold (60 min), every further open waits for a short breathing break
  with Pofu that the user starts with one tap (v2, founder decision of
  2026-11-01): 5 s for the 1st to 3rd over-limit open of the day, 10 s from
  the 4th on, never more. Some people decline ("Not now") or change their
  mind after the breath; that share is an assumption (BREATH_RESIST) and is
  varied in the sensitivity run.
- **The archipelago:** a home island with five stations revealed in stages,
  then four more islands, each with its own small loop and three stations,
  unlocked by tended days, calm nights, and progress.

Behavior (reaches, resisting, binge continuation, night sessions) uses the
archetypes of the first simulation, minute by minute, through the soft-gate
ladder pause -> intent -> care -> ask a friend on the fourth rapid reach.

Targets the tuning must meet:
  1. everyone builds something on day 1;
  2. nobody completes the home island before about day 40;
  3. heavy scrollers still progress (a second island within the first
     month, something built every week);
  4. scrolling visibly slows the world and visibly tires Pofu, never kills
     him, and a quiet day always helps.

Run (numpy and matplotlib from PyPI):

    python3 -I tools/sim/island_economy.py            # tables + charts
    python3 -I tools/sim/island_economy.py --runs 10 --no-charts
"""

from __future__ import annotations

import argparse
import math
import os
import random
from dataclasses import dataclass, field

DAYS = 90
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

# --- Seeds ------------------------------------------------------------------
QUIET_BLOCK_MIN = 10         # ADR-0014, unchanged: 1 seed per 10 quiet waking minutes ...
QUIET_DAILY_CAP = 48         # ... at most 48 a day ...
QUIET_NIGHT_BONUS = 10       # ... and +10 for a calm night
SKIP_SEEDS = 3               # a resisted reach adds a little (ADR-0015) ...
SKIP_SEEDS_CAP = 5           # ... for at most 5 skips a day (15 seeds)

# --- Care -------------------------------------------------------------------
HEALTH_START = 70.0
HEALTH_FLOOR = 5.0           # Pofu never dies (ADR-0017)
DRAIN_PER_MIN = 0.35
DRAIN_NIGHT_MULT = 2.0
DRAIN_ESCALATION = 1.25
DRAIN_PER_OPEN = 1.5
HEAL_PER_CALM_HOUR = 5.0     # from "tired" (25) up
CURLED_UP_BELOW = 12.0       # the two lowest bands heal band-relative (ADR-0017):
HEAL_SLEPT_ON_IT = 10.0
HEAL_PER_SKIP = 1.0
SKIP_HEAL_CAP = 6
UNWELL = 25.0


def heal_minute(health):
    """One observed calm waking minute (PofuCore `CareLedger.healMinute`).

    From "tired" up, a flat 5 an hour. In "curled up" (5-12) and "unwell"
    (12-25), 1/60 of the band's width, stopping at its upper edge, so one
    quiet hour lifts Pofu out of either band from anywhere in it
    (ADR-0017's "one quiet hour lifts him a band").
    """
    if health >= UNWELL:
        return min(100.0, health + HEAL_PER_CALM_HOUR / 60)
    lower, upper = (HEALTH_FLOOR, CURLED_UP_BELOW) if health < CURLED_UP_BELOW else (CURLED_UP_BELOW, UNWELL)
    return min(health + (upper - lower) / 60 * (1 + 1e-9), upper)
UNWELL_PRODUCTION = 0.6
NIGHT_RECOVERY = 0.3         # "sleeps it off": below 60, 30 % of the way back each night
RECOVERY_TARGET = 60.0

# --- Calm -------------------------------------------------------------------
CALM_STEP = 0.1
CALM_STEP_MIN = 20
CALM_MAX = 2.0
CALM_SLEEP_BONUS = 0.2
QUICK_PASS = 3               # a pass of <= 3 min is a quick check: halves the bonus
QUICK_CHAIN_MIN = 20         # a quick check within 20 min of the last one's end is a full open

# --- The breathing break ---------------------------------------------------------
BREATH_THRESHOLD = 60        # guarded-app minutes a day before every open needs a breath
BREATH_SECONDS = (5, 5, 5, 10)   # by over-limit open of the day; 10 s from the 4th on, never more
BREATH_CAP = 10              # seconds; no breath is ever longer
assert max(BREATH_SECONDS) <= BREATH_CAP
BREATH_RESIST = 0.2          # ASSUMPTION: share who don't open ("Not now" before, or "I'm good" after the breath)

# --- The archipelago -----------------------------------------------------------
# Home island stages: stage n needs HOME_STAGES[n] tended days.
HOME_STAGES = [0, 1, 4, 10, 24]


@dataclass(frozen=True)
class Island:
    key: str
    name: str
    tended: int              # tended days needed
    calm_nights: int = 0     # cumulative calm nights needed
    requires: tuple = ()     # (station id, level) that must be reached


ISLANDS = [
    Island("home", "Ayçiçeği (home)", 0),
    Island("harbor", "İskele (tea-and-bagel-cart harbor)", 8, requires=("teaStall", 3)),
    Island("stars", "Yıldız (night observatory)", 21, calm_nights=10),
    Island("hamam", "Kaplıca (hot-spring hamam)", 35, requires=("harbor_pier", 3)),
    Island("library", "Kitap (library, arrives with a season)", 50),
]

# Stations: (id, island, gate, base seeds/hour at L1, build cost).
# Home gate = home stage index; other islands: days after the island arrives.
STATIONS = [
    ("garden", "home", 0, 6, 0),           # Pofu's own; starts built
    ("teaStall", "home", 1, 5, 40),
    ("pond", "home", 2, 6, 160),
    ("workshop", "home", 3, 9, 500),
    ("windmill", "home", 4, 12, 1400),
    ("bagelCart", "harbor", 0, 8, 300),
    ("harbor_pier", "harbor", 3, 9, 550),
    ("lighthouse", "harbor", 7, 11, 1000),
    ("observatory", "stars", 0, 12, 2000),
    ("fireflies", "stars", 3, 11, 2400),
    ("hammock", "stars", 7, 13, 3000),
    ("spring", "hamam", 0, 13, 3600),
    ("bathhouse", "hamam", 3, 14, 4400),
    ("sherbet", "hamam", 7, 15, 5200),
    ("reading_tree", "library", 0, 14, 6000),
    ("bookhouse", "library", 3, 15, 7200),
    ("press", "library", 7, 16, 8400),
]
LEVELS = 5
COST_GROWTH = 2.2
RATE_GROWTH = 0.55
GARDEN_L2_COST = 30


def upgrade_cost(station, level_to):
    sid, _, _, _, build = station
    if sid == "garden":
        return 0 if level_to == 1 else round(GARDEN_L2_COST * COST_GROWTH ** (level_to - 2))
    return round(build * COST_GROWTH ** (level_to - 1))


def rate(station, level):
    return 0.0 if level == 0 else station[3] * (1 + RATE_GROWTH * (level - 1))


def island_cost(key):
    return sum(upgrade_cost(s, l) for s in STATIONS if s[1] == key for l in range(1, LEVELS + 1))


TOTAL_COST = sum(island_cost(i.key) for i in ISLANDS)
HOME_COST = island_cost("home")


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
    quick_p: float           # share of opens that are quick checks (<= 3 min)
    end_early_p: float = 0.1


def archetypes():
    def relapse(a, b, c):
        return lambda d: a(d) if d < 18 else (b(d) if d < 28 else c(d))
    return [
        Archetype("heavy", "Heavy scroller, improving", lambda d: lerp(3.0, 1.2, d / 45), lambda d: lerp(0.15, 0.55, d / 45),
                  lambda d: lerp(0.75, 0.40, d / 45), lambda d: lerp(0.60, 0.15, d / 45), 15, 0.2),
        Archetype("moderate", "Moderate", _c(1.5), lambda d: lerp(0.35, 0.50, d / 30), _c(0.5), _c(0.25), 15, 0.35),
        Archetype("disciplined", "Already disciplined", _c(0.6), _c(0.75), _c(0.2), _c(0.05), 10, 0.6, 0.3),
        Archetype("relapse", "Relapse and recover",
                  relapse(lambda d: lerp(1.6, 1.0, d / 17), _c(2.6), lambda d: lerp(1.6, 1.0, (d - 28) / 20)),
                  relapse(lambda d: lerp(0.40, 0.60, d / 17), _c(0.15), lambda d: lerp(0.40, 0.60, (d - 28) / 20)),
                  relapse(_c(0.45), _c(0.80), _c(0.45)), relapse(_c(0.2), _c(0.65), _c(0.2)), 15, 0.3),
        Archetype("monk", "Never opens (upper bound)", _c(0.3), _c(1.0), _c(0.0), _c(0.0), 10, 0.0, 0.0),
    ]


@dataclass
class DayLog:
    day: int
    feed_minutes: int = 0
    attempts: int = 0
    resisted: int = 0
    opens: int = 0
    quick: int = 0
    resets: int = 0
    halvings: int = 0
    breaths: int = 0
    breath_seconds: int = 0
    breath_resisted: int = 0
    seeds_quiet: float = 0.0
    seeds_stations: float = 0.0
    seeds_skips: float = 0.0
    spent: int = 0
    home_spent: int = 0
    upgrades: list = field(default_factory=list)
    islands: int = 1
    health_min: float = 100.0
    health_end: float = 0.0
    calm_avg: float = 0.0
    stage: int = 0
    trace: list = field(default_factory=list)


def simulate(a: Archetype, rng: random.Random, resist_shift=0.0, loss_aversion=0.0, breath_resist=BREATH_RESIST,
             keep_trace_day=None):
    levels = {s[0]: 0 for s in STATIONS}
    levels["garden"] = 1
    arrived = {"home": 0}
    pantry = 0.0
    health = HEALTH_START
    calm = 1.0
    calm_run = 0
    quiet_run = 0
    opens_window: list[int] = []
    last_attempt = -10_000
    last_quick_end = -10_000
    rung = 0
    tended = 0
    calm_nights = 0
    logs = []
    for d in range(DAYS):
        log = DayLog(d)
        stage = max(i for i, need in enumerate(HOME_STAGES) if tended >= need)
        log.stage = stage
        for isl in ISLANDS:
            if isl.key in arrived:
                continue
            ok = tended >= isl.tended and calm_nights >= isl.calm_nights
            if isl.requires:
                ok = ok and levels[isl.requires[0]] >= isl.requires[1]
            if ok:
                arrived[isl.key] = d
        log.islands = len(arrived)

        def open_station(s):
            isl = s[1]
            if isl not in arrived:
                return False
            return s[2] <= stage if isl == "home" else d - arrived[isl] >= s[2]

        base = d * MIN_PER_DAY
        lam = a.reach_per_hour(d) / 60
        resist = max(0.0, min(1.0, a.resist_p(d) + resist_shift))
        cont = a.continue_p(d)
        night_session = rng.random() < a.night_p(d)
        night_at = rng.randint(BED_START + 5, NIGHT_SESSION_END) if night_session else None
        pass_until = -1
        pass_quick = False
        pending = None
        emergency_used = False
        skips_healed = 0
        skips_paid = 0
        quiet_today = 0
        over_limit_opens = 0
        calm_night = True
        calm_sum = 0.0
        waking = 0
        station_rate = sum(rate(s, levels[s[0]]) for s in STATIONS)

        def visit():
            nonlocal pantry, station_rate
            made = 0
            while made < 2:
                opts = [(upgrade_cost(s, levels[s[0]] + 1), s) for s in STATIONS
                        if open_station(s) and levels[s[0]] < LEVELS]
                if not opts:
                    break
                cost, s = min(opts, key=lambda x: x[0])
                if pantry < cost:
                    break
                pantry -= cost
                levels[s[0]] += 1
                log.spent += cost
                if s[1] == "home":
                    log.home_spent += cost
                log.upgrades.append(f"{s[0]} L{levels[s[0]]}")
                made += 1
            station_rate = sum(rate(s, levels[s[0]]) for s in STATIONS)

        for m in range(MIN_PER_DAY):
            t = base + m
            bedtime = m >= BED_START
            awake = (WAKE <= m < BED_START) or (night_session and BED_START <= m < NIGHT_SESSION_END + 30)
            in_pass = pass_until > t
            hf = UNWELL_PRODUCTION if health < UNWELL else 1.0
            if not in_pass:          # the residents work while you are away, not while you scroll
                prod = station_rate / 60 * calm * hf
                pantry += prod
                log.seeds_stations += prod
            if in_pass:
                log.feed_minutes += 1
                k = len([o for o in opens_window if o > t - ESCALATION_WINDOW]) - 1
                drain = DRAIN_PER_MIN * (DRAIN_NIGHT_MULT if bedtime else 1) * DRAIN_ESCALATION ** max(0, k)
                health = max(HEALTH_FLOOR, health - drain)
                calm_run = 0
                quiet_run = 0
                if bedtime:
                    calm_night = False
            elif not bedtime:
                calm_run += 1
                quiet_run += 1
                health = heal_minute(health)
                if calm_run % CALM_STEP_MIN == 0:
                    calm = min(CALM_MAX, round(calm + CALM_STEP, 2))
                if quiet_run % QUIET_BLOCK_MIN == 0 and quiet_today < QUIET_DAILY_CAP:
                    quiet_today += 1
                    pantry += 1
                    log.seeds_quiet += 1
            if not bedtime and m >= WAKE:
                calm_sum += calm
                waking += 1
            log.health_min = min(log.health_min, health)
            if keep_trace_day == d and m % 2 == 0:
                log.trace.append((m, calm, health, in_pass, pass_quick))
            if m in HOME_VISITS:
                visit()
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
            rung = min(rung + 1, 3) if t - last_attempt < LADDER_COOLDOWN else 0
            last_attempt = t
            p_res = resist + (0.15 if rung >= 2 else 0) + loss_aversion * (calm - 1.0)
            if bedtime:
                p_res = min(p_res, 0.3)

            def resisted():
                nonlocal skips_healed, skips_paid, health, pantry
                log.resisted += 1
                if skips_healed < SKIP_HEAL_CAP:
                    skips_healed += 1
                    health = min(100.0, health + HEAL_PER_SKIP)
                if skips_paid < SKIP_SEEDS_CAP:
                    skips_paid += 1
                    pantry += SKIP_SEEDS
                    log.seeds_skips += SKIP_SEEDS

            if rng.random() < min(1.0, p_res):
                resisted()
                continue
            quick = rng.random() < a.quick_p
            if quick:
                minutes = QUICK_PASS
            elif rung < 2:
                minutes = FREE_PASS
            elif rung == 2:
                minutes = a.open_minutes
            else:
                if rng.random() < FRIEND_APPROVE_P:
                    minutes = FRIEND_PASS
                elif not emergency_used:
                    emergency_used, minutes = True, EMERGENCY_PASS
                else:
                    resisted()
                    continue
            # the breathing break: every open once today's guarded time reaches the threshold
            if log.feed_minutes >= BREATH_THRESHOLD:
                secs = BREATH_SECONDS[min(over_limit_opens, len(BREATH_SECONDS) - 1)]
                over_limit_opens += 1
                log.breaths += 1
                log.breath_seconds += secs
                if rng.random() < breath_resist:
                    log.breath_resisted += 1
                    resisted()
                    continue
            if rng.random() < a.end_early_p:
                minutes = max(1, minutes // 3)
            log.opens += 1
            is_quick = minutes <= QUICK_PASS and t - last_quick_end > QUICK_CHAIN_MIN
            if is_quick:
                log.quick += 1
                if calm > 1.0:
                    log.halvings += 1
                calm = max(1.0, math.floor((1.0 + (calm - 1.0) / 2) * 10 + 1e-9) / 10)
                last_quick_end = t + minutes
            else:
                if calm > 1.0:
                    log.resets += 1
                calm = 1.0
                if minutes <= QUICK_PASS:
                    last_quick_end = t + minutes
            pass_quick = is_quick
            calm_run = 0
            quiet_run = 0
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
            pantry += QUIET_NIGHT_BONUS
            log.seeds_quiet += QUIET_NIGHT_BONUS
            calm_nights += 1
        log.calm_avg = calm_sum / max(1, waking)
        log.health_end = health
        tended += 1
        logs.append(log)
    return logs, levels, arrived


def summarize(logs, arrived):
    spent = home = 0
    first_up = None
    home_done = None
    pct, hpct, weeks_without = [], [], 0
    for lg in logs:
        spent += lg.spent
        home += lg.home_spent
        if lg.upgrades and first_up is None:
            first_up = lg.day + 1
        pct.append(spent / TOTAL_COST)
        hpct.append(home / HOME_COST)
        if home_done is None and home >= HOME_COST:
            home_done = lg.day + 1
    for w in range(len(logs) // 7):
        if not any(l.upgrades for l in logs[w * 7:(w + 1) * 7]):
            weeks_without += 1
    n = len(logs)

    def isl_day(k):
        return arrived[k] + 1 if k in arrived else None

    return {
        "first_upgrade": first_up, "home_done": home_done, "pct": pct, "hpct": hpct,
        "home30": hpct[29], "pct60": pct[59], "pct90": pct[-1],
        "harbor": isl_day("harbor"), "stars": isl_day("stars"), "hamam": isl_day("hamam"),
        "islands30": logs[29].islands, "islands60": logs[59].islands, "islands90": logs[-1].islands,
        "weeks_without": weeks_without,
        "calm": sum(l.calm_avg for l in logs) / n,
        "calm_wk1": sum(l.calm_avg for l in logs[:7]) / 7, "calm_last": sum(l.calm_avg for l in logs[-7:]) / 7,
        "resets": sum(l.resets for l in logs) / n, "halvings": sum(l.halvings for l in logs) / n,
        "breaths_wk1": sum(l.breaths for l in logs[:7]) / 7, "breaths_last": sum(l.breaths for l in logs[-7:]) / 7,
        "breath_sec_wk1": sum(l.breath_seconds for l in logs[:7]) / 7,
        "health_wk1": sum(l.health_end for l in logs[:7]) / 7, "health_last": sum(l.health_end for l in logs[-7:]) / 7,
        "health_min": min(l.health_min for l in logs),
        "unwell_days": sum(1 for l in logs if l.health_end < UNWELL),
        "feed_wk1": sum(l.feed_minutes for l in logs[:7]) / 7, "feed_last": sum(l.feed_minutes for l in logs[-7:]) / 7,
        "health": [l.health_end for l in logs],
        "seeds_day_wk1": sum(l.seeds_quiet + l.seeds_stations + l.seeds_skips for l in logs[:7]) / 7,
        "share_quiet": sum(l.seeds_quiet for l in logs[:7]) / max(1, sum(l.seeds_quiet + l.seeds_stations + l.seeds_skips for l in logs[:7])),
        "share_skips": sum(l.seeds_skips for l in logs[:7]) / max(1, sum(l.seeds_quiet + l.seeds_stations + l.seeds_skips for l in logs[:7])),
        "seeds30": sum(l.seeds_quiet + l.seeds_stations + l.seeds_skips for l in logs[:30]),
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
        rows = []
        for r in range(runs):
            logs, _, arrived = simulate(a, random.Random(seed * 1000 + r), **kw)
            rows.append(summarize(logs, arrived))
        out[a.key] = (a, rows)
    return out


def _day(rows, k):
    xs = [r[k] for r in rows]
    n = sum(1 for x in xs if x)
    if n == len(rows):
        return f"{median(xs):.0f}"
    return f"{median(xs):.0f} ({n}/{len(rows)})" if n else "—"


def tables(results, runs):
    g = lambda rows, k: median([r[k] for r in rows])
    L = ["| Archetype | First build (day) | Home island done (day) | Home at day 30 | İskele arrives | Yıldız arrives | Islands at day 60 / 90 | Archipelago at day 90 | Weeks without a build (of 12) |",
         "|" + "---|" * 9]
    for key, (a, rows) in results.items():
        L.append(f"| {a.label} | {g(rows, 'first_upgrade'):.0f} | {_day(rows, 'home_done')} | {g(rows, 'home30') * 100:.0f} % "
                 f"| day {_day(rows, 'harbor')} | day {_day(rows, 'stars')} | {g(rows, 'islands60'):.0f} / {g(rows, 'islands90'):.0f} "
                 f"| {g(rows, 'pct90') * 100:.0f} % | {g(rows, 'weeks_without'):.0f} |")
    L += ["", "| Archetype | Calm avg wk 1 → wk 13 | Resets / halvings per day | Breathing breaks/day wk 1 → wk 13 (seconds/day, wk 1) | Wellbeing wk 1 → wk 13 (lowest) | Unwell days | Feed min/day wk 1 → wk 13 | Seeds/day wk 1 | Wk 1 share from Pofu's quiet gathering / skips |",
          "|" + "---|" * 9]
    for key, (a, rows) in results.items():
        L.append(f"| {a.label} | {g(rows, 'calm_wk1'):.2f}× → {g(rows, 'calm_last'):.2f}× | {g(rows, 'resets'):.1f} / {g(rows, 'halvings'):.1f} "
                 f"| {g(rows, 'breaths_wk1'):.1f} → {g(rows, 'breaths_last'):.1f} ({g(rows, 'breath_sec_wk1'):.0f} s) | {g(rows, 'health_wk1'):.0f} → {g(rows, 'health_last'):.0f} ({g(rows, 'health_min'):.0f}) "
                 f"| {g(rows, 'unwell_days'):.0f} | {g(rows, 'feed_wk1'):.0f} → {g(rows, 'feed_last'):.0f} | {g(rows, 'seeds_day_wk1'):.0f} "
                 f"| {g(rows, 'share_quiet') * 100:.0f} % / {g(rows, 'share_skips') * 100:.0f} % |")
    L.append("")
    L.append(f"_Medians of {runs} runs, {DAYS} days. Home island = 5 stations × 5 levels, {HOME_COST:,} seeds; "
             f"archipelago = 5 islands, 17 stations, {TOTAL_COST:,} seeds. \"(n/N)\" = reached in n of N runs; — = in none._")
    return "\n".join(L)


# --- charts -----------------------------------------------------------------
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
        ax.plot(days, med, STYLES[k], color=PALETTE[k], linewidth=2, label=a.label)
        ends.append([med[-1], a.label, PALETTE[k]])
    return ends


def _labels(ax, ends, gap):
    # Several lines end at the same value (everyone finishes), so a legend
    # reads better than end labels here.
    leg = ax.legend(loc="center left", bbox_to_anchor=(1.01, 0.5), frameon=False, fontsize=8.5, handlelength=2.4)
    for t in leg.get_texts():
        t.set_color(INK)


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

    # 1. home island progress
    f, ax = fig()
    _labels(ax, _lines(ax, results, "hpct", 100), 6)
    for i, need in enumerate(HOME_STAGES[1:], start=2):
        ax.axvline(need + 1, color=GRID, linewidth=1, zorder=0)
        ax.text(need + 1.4, 97, f"stage {i}", color=MUTED, fontsize=7.5, rotation=90, va="top")
    ax.axvline(40, color=MUTED, linewidth=1, linestyle=(0, (2, 2)))
    ax.text(40.6, 3, "day 40 target", color=MUTED, fontsize=8)
    ax.set_xlim(1, DAYS)
    ax.set_ylim(0, 108)
    ax.set_xlabel("Day")
    ax.set_ylabel("Home island built (% of its upgrades)")
    ax.set_title("Pofu's home island by archetype (median, band = p10–p90)", loc="left", fontsize=11, color=INK)
    f.subplots_adjust(right=0.72, left=0.09, bottom=0.12, top=0.9)
    f.savefig(os.path.join(outdir, "island-progress.png"), facecolor=SURFACE)
    plt.close(f)

    # 2. archipelago progress
    f, ax = fig()
    _labels(ax, _lines(ax, results, "pct", 100), 5)
    ax.set_xlim(1, DAYS)
    ax.set_ylim(0, 100)
    ax.set_xlabel("Day")
    ax.set_ylabel("Archipelago built (% of all upgrades)")
    ax.set_title("The whole archipelago: a season-long horizon", loc="left", fontsize=11, color=INK)
    f.subplots_adjust(right=0.72, left=0.09, bottom=0.12, top=0.9)
    f.savefig(os.path.join(outdir, "island-archipelago.png"), facecolor=SURFACE)
    plt.close(f)

    # 3. wellbeing
    f, ax = fig()
    _labels(ax, _lines(ax, results, "health"), 5)
    ax.axhspan(0, UNWELL, color="#F3E4E8", zorder=0)
    ax.text(1.5, 13, "unwell: curled up, never gone", color=MUTED, fontsize=8)
    ax.axhline(HEALTH_FLOOR, color=MUTED, linewidth=0.8, linestyle=(0, (2, 2)))
    ax.set_xlim(1, DAYS)
    ax.set_ylim(0, 102)
    ax.set_xlabel("Day")
    ax.set_ylabel("Pofu's wellbeing at bedtime")
    ax.set_title("Pofu's wellbeing: scrolling tires him, quiet heals", loc="left", fontsize=11, color=INK)
    f.subplots_adjust(right=0.72, left=0.09, bottom=0.12, top=0.9)
    f.savefig(os.path.join(outdir, "island-health.png"), facecolor=SURFACE)
    plt.close(f)

    # 4. one day of calm (moderate)
    f, ax = fig(8, 3.4)
    xs = [6 + m / 60 for m, *_ in trace]
    ax.step(xs, [c for _, c, *_ in trace], where="post", color="#2F8F5B", linewidth=2)
    for m, c, h, p, q in trace:
        if p:
            ax.axvspan(6 + m / 60, 6 + (m + 2) / 60, color="#F2C14E" if q else "#C9B8F5", linewidth=0, zorder=0)
    ax.axvspan(23, 30, color="#EEEAF2", linewidth=0, zorder=0)
    ax.text(23.3, 1.93, "bedtime: holds", color=MUTED, fontsize=8)
    ax.set_xlim(6, 30)
    ax.set_ylim(0.9, 2.05)
    ax.set_xticks([6, 9, 12, 15, 18, 21, 24, 27, 30])
    ax.set_xticklabels(["06", "09", "12", "15", "18", "21", "00", "03", "06"])
    ax.set_ylabel("Calm multiplier")
    ax.set_title("One day, moderate player: violet = open (resets), honey = quick check (halves)", loc="left", fontsize=10, color=INK)
    f.subplots_adjust(left=0.09, right=0.98, bottom=0.12, top=0.88)
    f.savefig(os.path.join(outdir, "island-calm-day.png"), facecolor=SURFACE)
    plt.close(f)

    # 5. sensitivity: the breathing break's assumed effect on the heavy scroller
    f, (a1, a2) = plt.subplots(1, 2, figsize=(8, 3.4), dpi=110)
    f.patch.set_facecolor(SURFACE)
    labels = [f"{s * 100:.0f} %" for s, *_ in sens]
    for ax, idx, title, fmt, color in ((a1, 1, "Feed minutes a day, weeks 1–4", "{:.0f}", "#6C4FD8"),
                                       (a2, 2, "Breathing breaks a day, weeks 1–4", "{:.1f}", "#2F8F5B")):
        _style(ax)
        vals = [r[idx] for r in sens]
        ax.bar(range(len(vals)), vals, color=color, width=0.6, edgecolor=SURFACE, linewidth=2)
        for i, v in enumerate(vals):
            ax.text(i, v, fmt.format(v), ha="center", va="bottom", fontsize=8, color=INK)
        ax.set_xticks(range(len(vals)))
        ax.set_xticklabels(labels, fontsize=8.5)
        ax.set_xlabel("Share who don't open (heavy scroller)", fontsize=8.5)
        ax.set_title(title, loc="left", fontsize=10, color=INK)
        ax.set_yticks([])
        ax.spines["left"].set_visible(False)
    f.suptitle("The breathing break (5–10 s, started by the user): how much depends on the pause working", x=0.02, ha="left", fontsize=11, color=INK)
    f.subplots_adjust(left=0.03, right=0.98, bottom=0.2, top=0.8, wspace=0.12)
    f.savefig(os.path.join(outdir, "island-sensitivity.png"), facecolor=SURFACE)
    plt.close(f)


def breath_sensitivity(runs, seed=11):
    a = archetypes()[0]
    rows = []
    for br in (0.0, 0.1, 0.2, 0.35, 0.5):
        fs, bs = [], []
        for r in range(runs):
            logs, _, _ = simulate(a, random.Random(seed * 1000 + r), breath_resist=br)
            fs.append(sum(l.feed_minutes for l in logs[:28]) / 28)
            bs.append(sum(l.breaths for l in logs[:28]) / 28)
        rows.append((br, median(fs), median(bs)))
    return rows


def main():
    ap = argparse.ArgumentParser(description="Pofu archipelago economy simulation")
    ap.add_argument("--runs", type=int, default=30)
    ap.add_argument("--no-charts", action="store_true")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "..", "docs", "product", "assets"))
    args = ap.parse_args()

    print("Station ladders (cost to reach level 1..5; seeds/hour at level 1..5):")
    for s in STATIONS:
        print(f"  {s[1]:<8} {s[0]:<13} gate {s[2]}  cost {[upgrade_cost(s, l) for l in range(1, 6)]}  rate {[round(rate(s, l), 1) for l in range(1, 6)]}")
    for i in ISLANDS:
        print(f"  island {i.key:<8} {island_cost(i.key):>8,} seeds")
    print(f"  total {TOTAL_COST:,}\n")
    results = run(args.runs)
    print(tables(results, args.runs))
    print()
    la = run(max(10, args.runs // 2), loss_aversion=0.25)
    print("With a loss-aversion response (+0.25 resist probability per 1.0x of calm at stake):")
    for key, (a, rows) in la.items():
        print(f"  {a.label}: home done day {_day(rows, 'home_done')}, archipelago day 90 {median([r['pct90'] for r in rows]) * 100:.0f} %, "
              f"feed wk 13 {median([r['feed_last'] for r in rows]):.0f} min")
    print()
    sens = breath_sensitivity(max(10, args.runs // 2))
    print("| Breath resist (heavy) | Feed min/day, wk 1–4 | Breathing breaks/day, wk 1–4 |")
    print("|---|---|---|")
    for s, fm, b in sens:
        print(f"| {s * 100:.0f} % | {fm:.0f} | {b:.1f} |")
    print("\nOne heavy-scroller run, builds on days 1-3:")
    hl, _, _ = simulate(archetypes()[0], random.Random(1))
    for lg in hl[:3]:
        print(f"  day {lg.day + 1}: {', '.join(lg.upgrades) or '-'}")
    if not args.no_charts:
        logs, _, _ = simulate(next(x for x in archetypes() if x.key == "moderate"), random.Random(3), keep_trace_day=10)
        charts(results, logs[10].trace, sens, os.path.abspath(args.out))
        print("charts written to", os.path.abspath(args.out))


if __name__ == "__main__":
    main()
