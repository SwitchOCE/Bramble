#!/usr/bin/env python3
"""Turns the bench's CSVs into the readable report and small summary CSVs next to it.

Usage: summarize_bench.py <csv dir> <report.md>. Every bar from docs/ideation/PLAN.md "Done means,
sharpened" gets a line saying PASS, FAIL or NOT RUN. Nothing here changes a number to fit a bar.
"""

from __future__ import annotations

import csv
import math
import sys
from collections import defaultdict
from pathlib import Path

Z = 1.96
SPREAD_LOW, SPREAD_HIGH = 0.06, 0.25
SPREAD_MIN_STRATEGIES = 5
SPREAD_GAMES = 2000
HARD_NAIVE_TOP4, HARD_NAIVE_WIN = 0.85, 0.45
PLACE_GAIN = 0.5
PHONE_FACTOR = 3.0
BOT_TURN_LIMIT_MS = 1000.0 / 7
BANKS = {12: (10, 14), 30: (25, 35), 60: (50, 70)}
# Active one-against-seven yardsticks: (the focus bot, the seven around it).
LADDER_SUITES = {
    "hard_naive": ("hard", "naive"),
    "hard_lobby_hard": ("hard", "hard, the varied lobby a player meets"),
}
# Above this overlap with any other strategy, a strategy isn't marked distinct.
OVERLAP_LIMIT = 0.6
# A card on at least this share of a strategy's final boards counts as a staple of it.
STAPLE_SHARE = 0.5
TOP_CARDS = 10


def load(folder: Path, suite: str, part: str) -> list[dict[str, str]]:
    path = folder / f"{suite}.{part}.csv"
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def rate_ci(hits: int, total: int) -> tuple[float, float]:
    """The rate and its 95% half-width (normal approximation; a lobby's seats aren't independent)."""
    if total == 0:
        return 0.0, 0.0
    rate = hits / total
    return rate, Z * math.sqrt(rate * (1 - rate) / total)


def mean_se(values: list[float]) -> tuple[float, float]:
    if not values:
        return 0.0, 0.0
    mean = sum(values) / len(values)
    if len(values) < 2:
        return mean, 0.0
    variance = sum((v - mean) ** 2 for v in values) / (len(values) - 1)
    return mean, math.sqrt(variance / len(values))


def pct(value: float) -> str:
    return f"{100 * value:.1f}%"


def verdict(ok: bool, close: bool = False) -> str:
    if close:
        return "**TOO CLOSE**"
    return "**PASS**" if ok else "**FAIL**"


def close_to(value: float, ci: float, bar: float) -> bool:
    """The bar sits inside the measurement's margin, so the run can't say which side it's on."""
    return abs(value - bar) <= ci


def spread_verdict(table: list[dict], enough_games: bool) -> tuple[bool, bool]:
    """(passes as measured, too close): too close if strategies whose margin crosses an edge could flip it."""

    def passes(rates: list[float]) -> bool:
        inside = sum(SPREAD_LOW <= rate <= SPREAD_HIGH for rate in rates)
        return enough_games and inside >= SPREAD_MIN_STRATEGIES and all(rate <= SPREAD_HIGH for rate in rates)

    def best(row: dict) -> float:
        """The rate within its margin nearest the band."""
        return min(
            max(row["win"], min(SPREAD_LOW, row["win"] + row["win_ci"])), max(SPREAD_HIGH, row["win"] - row["win_ci"])
        )

    def worst(row: dict) -> float:
        """The rate within its margin furthest from the band, if the margin crosses an edge."""
        if close_to(row["win"], row["win_ci"], SPREAD_HIGH):
            return row["win"] + row["win_ci"]
        if close_to(row["win"], row["win_ci"], SPREAD_LOW):
            return row["win"] - row["win_ci"]
        return row["win"]

    measured = passes([row["win"] for row in table])
    can_pass = passes([best(row) for row in table])
    can_fail = not passes([worst(row) for row in table])
    return measured, can_pass and can_fail


def focus_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    return [r for r in rows if r["focus"] == "1"]


def ladder_line(name: str, rows: list[dict[str, str]]) -> dict[str, float]:
    chosen = focus_rows(rows)
    places = [float(r["place"]) for r in chosen]
    wins = sum(1 for p in places if p == 1)
    top4 = sum(1 for p in places if p <= 4)
    mean, se = mean_se(places)
    win_rate, win_ci = rate_ci(wins, len(places))
    top_rate, top_ci = rate_ci(top4, len(places))
    return {
        "name": name,
        "games": len(places),
        "place": mean,
        "place_ci": Z * se,
        "win": win_rate,
        "win_ci": win_ci,
        "top4": top_rate,
        "top4_ci": top_ci,
    }



def paired_head_to_head(rows: list[dict[str, str]]) -> tuple[list[float], dict[str, list[float]]]:
    """One observation per complete swapped seed, never eight independent seats.

    Positive gain means incumbent place minus candidate place (lower place is better).
    Reject broken/duplicated pairs rather than silently biasing the estimate.
    """
    pairs = defaultdict(list)
    labels = {(r["candidate"], r["incumbent"]) for r in rows}
    if len(labels) != 1:
        raise ValueError("head-to-head must contain one candidate/incumbent comparison")
    for row in rows:
        pairs[int(row["seed"])].append(row)
    gains, strategies = [], defaultdict(list)
    for seed, pair in sorted(pairs.items()):
        indexed = {(r["leg"], r["seat"]): r for r in pair}
        if len(pair) != 16 or len(indexed) != 16:
            raise ValueError(f"seed {seed}: need two complete eight-seat games")
        diffs = []
        strategy_places = defaultdict(lambda: defaultdict(list))
        for leg in ("0", "1"):
            game = [indexed[(leg, str(seat))] for seat in range(8)]
            sides = {side: [r for r in game if r["side"] == side] for side in ("candidate", "incumbent")}
            if any(len(side) != 4 for side in sides.values()):
                raise ValueError(f"seed {seed}: need four seats per side")
            diffs.append(sum(float(r["place"]) for r in sides["incumbent"]) / 4
                         - sum(float(r["place"]) for r in sides["candidate"]) / 4)
            for r in game:
                other = indexed[(str(1 - int(leg)), r["seat"])]
                if r["side"] == other["side"] or r["strategy"] != other["strategy"]:
                    raise ValueError(f"seed {seed}: sides must swap while seat strategies stay fixed")
                strategy_places[r["strategy"]][r["side"]].append(float(r["place"]))
        gains.append(sum(diffs) / 2)
        for strategy, sides in strategy_places.items():
            strategies[strategy].append(mean_se(sides["incumbent"])[0] - mean_se(sides["candidate"])[0])
    return gains, strategies


def paired_margin(values: list[float]) -> tuple[float, float]:
    """Two-sided Student t interval on seed clusters; no precision claim for n < 2."""
    mean, se = mean_se(values)
    if len(values) < 2:
        return mean, math.inf
    return mean, t95(len(values) - 1) * se


def t95(df: int) -> float:
    # Exact small-df critical values; asymptotic expansion thereafter (error < 0.00002 at df=31).
    small = [12.7062, 4.3027, 3.1824, 2.7764, 2.5706, 2.4469, 2.3646, 2.3060, 2.2622,
             2.2281, 2.2010, 2.1788, 2.1604, 2.1448, 2.1315, 2.1199, 2.1098, 2.1009,
             2.0930, 2.0860, 2.0796, 2.0739, 2.0687, 2.0639, 2.0595, 2.0555, 2.0518,
             2.0484, 2.0452, 2.0423]
    z = 1.959963984540054
    critical = (small[df - 1] if df <= 30 else
                z + (z**3 + z) / (4 * df) + (5*z**5 + 16*z**3 + 3*z) / (96*df**2)
                + (3*z**7 + 19*z**5 + 17*z**3 - 15*z) / (384*df**3))
    return critical



def projected_margin(values: list[float], count: int) -> float:
    """Projected 95% half-width at count independent seeds, assuming unchanged seed variance."""
    if len(values) < 2 or count < 2:
        return math.inf
    _, se = mean_se(values)
    return t95(count - 1) * se * math.sqrt(len(values) / count)


def comparison_verdict(kind: str, gains: list[float]) -> str:
    mean, margin = paired_margin(gains)
    if kind == "bookkeeping":
        return "PASS BOOKKEEPING" if gains and all(g == 0 for g in gains) else "FAIL BOOKKEEPING"
    if kind == "rng_aa":
        return "PASS A/A" if 0 < margin < math.inf and abs(mean) <= margin else "FAIL A/A"
    return "POSITIVE GAIN (fresh seeds and timing review required)" if mean - margin > 0 else "NO PROMOTION"

def head_to_head_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    out.append("## Paired head-to-head\n")
    rows = load(folder, "head_to_head", "players")
    out.append('"Clearly better" = positive gain whose 95% margin excludes 0, on fresh seeds, at no meaningful turn-time cost. '
               'Positive gain is incumbent minus candidate mean place. Each independent seed supplies '
               'the average of its two swapped games; the 95% margin uses Student t over seeds.\n')
    if not rows:
        out.append("NOT RUN.\n")
        return
    gains, strategies = paired_head_to_head(rows)
    mean, margin = paired_margin(gains)
    candidate, incumbent = rows[0]["candidate"], rows[0]["incumbent"]
    kind = rows[0].get("comparison", "bookkeeping" if candidate == incumbent else "promotion")
    if len({r.get("comparison", kind) for r in rows}) != 1:
        raise ValueError("mixed comparison kinds")
    result = comparison_verdict(kind, gains)
    out.append(f"{candidate} vs {incumbent}: **{result}**, gain {mean:+.3f} ±{margin:.3f} places "
               f"(95%, {len(gains)} paired seeds / {2*len(gains)} games; "
               f"seeds {min(int(r['seed']) for r in rows)}–{max(int(r['seed']) for r in rows)}).\n")
    if kind == "bookkeeping":
        out.append("Identical policies replay identical games with exchanged labels: exact cancellation "
                   "and a zero margin are expected. This checks pairing/labels, not empirical CI coverage.\n")
    if kind == "rng_aa":
        m200, m500 = projected_margin(gains, 200), projected_margin(gains, 500)
        out.append(f"Null noise: 95% margin at 200 seeds ±{m200:.3f}; projected at 500 ±{m500:.3f} "
                   "(same seed variance, not a measured 500-seed A/A). A single passing A/A is a "
                   "sanity check, not proof of 95% coverage. Margins describe precision, not a "
                   "guaranteed minimum detectable effect; turn-time review is also required for promotion.\n")
    out.append("| Strategy | Paired seeds | Place gain | 95% margin |")
    out.append("|---|---:|---:|---:|")
    table = []
    for name, values in sorted(strategies.items()):
        gain, ci = paired_margin(values)
        out.append(f"| {name} | {len(values)} | {gain:+.3f} | ±{ci:.3f} |")
        table.append({"strategy": name, "pairs": len(values), "gain": gain, "margin": ci})
    out.append("\nPer-strategy intervals are exploratory; no correction for multiple comparisons.\n")
    write_csv(csv_dir / "head_to_head.summary.csv", table)

def spread_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    rows = load(folder, "spread", "players")
    out.append("## Win spread: pinned Hard bots in mixed lobbies\n")
    if not rows:
        out.append("NOT RUN\n")
        return
    table = spread_table(rows)
    games = len({r["seed"] for r in rows})
    inside = [row for row in table if SPREAD_LOW <= row["win"] <= SPREAD_HIGH]
    over = [row for row in table if row["win"] > SPREAD_HIGH]
    ok, close = spread_verdict(table, games >= SPREAD_GAMES)
    out.append(
        f"{verdict(ok, close)} Bar: at least {SPREAD_MIN_STRATEGIES} strategies at 6-25% wins, none above 25%, "
        f"{SPREAD_GAMES}+ games. Measured: {len(inside)} inside, {len(over)} above, {games} games.\n"
    )
    out.append("| Strategy | Seats | Win (95%) | Top 4 (95%) | Avg place | Tier 6 turn | Final units | In bar |")
    out.append("|---|---:|---:|---:|---:|---:|---:|---|")
    for row in table:
        status = "yes" if SPREAD_LOW <= row["win"] <= SPREAD_HIGH else "NO"
        out.append(
            f"| {row['strategy']} | {row['seats']} | {pct(row['win'])} ± {pct(row['win_ci'])} | "
            f"{pct(row['top4'])} ± {pct(row['top4_ci'])} | {row['place']:.2f} | {row['t6']:.1f} | "
            f"{row['units']:.1f} | {status} |"
        )
    out.append("")
    write_csv(csv_dir / "strategies.csv", table)


def spread_table(rows: list[dict[str, str]]) -> list[dict]:
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        groups[row["strategy"]].append(row)
    table = []
    for strategy, chosen in sorted(groups.items()):
        places = [float(r["place"]) for r in chosen]
        win, win_ci = rate_ci(sum(p == 1 for p in places), len(places))
        top, top_ci = rate_ci(sum(p <= 4 for p in places), len(places))
        reached = [float(r["tier6_turn"]) for r in chosen if r["tier6_turn"] != "0"]
        table.append(
            {
                "strategy": strategy,
                "seats": len(chosen),
                "win": win,
                "win_ci": win_ci,
                "top4": top,
                "top4_ci": top_ci,
                "place": mean_se(places)[0],
                "t6": mean_se(reached)[0],
                "units": mean_se([float(r["final_units"]) for r in chosen])[0],
            }
        )
    return table


def builds_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    """The build each unpinned or varied seat ended on: is the lobby really different builds?"""
    out.append("## Builds per seat, unpinned and varied bots\n")
    table = []
    for suite in ("hard_lobby_hard", "place_search"):
        groups: dict[tuple[str, str], list[float]] = defaultdict(list)
        for row in load(folder, suite, "players"):
            bot = row["bot"]
            if ":" in bot and ":varied" not in bot:
                continue
            seat = "the one bot" if row["focus"] == "1" else "the seven"
            groups[(seat, row["strategy"] or "none")].append(float(row["place"]))
        totals: dict[str, int] = defaultdict(int)
        for (seat, _build), places in groups.items():
            totals[seat] += len(places)
        for (seat, build), places in sorted(groups.items(), key=lambda item: (item[0][0], -len(item[1]))):
            table.append(
                {
                    "suite": suite,
                    "seat": seat,
                    "build": build,
                    "seats": len(places),
                    "share": len(places) / totals[seat],
                    "win": sum(p == 1 for p in places) / len(places),
                    "place": mean_se(places)[0],
                }
            )
    if not table:
        out.append("NOT RUN\n")
        return
    out.append("The build a seat followed when the game ended. Lobby seats are dealt theirs; unpinned bots choose.\n")
    out.append("| Suite | Seat | Build | Seats | Share | Win | Avg place |")
    out.append("|---|---|---|---:|---:|---:|---:|")
    for row in table:
        out.append(
            f"| {row['suite']} | {row['seat']} | {row['build']} | {row['seats']} | {pct(row['share'])} | "
            f"{pct(row['win'])} | {row['place']:.2f} |"
        )
    out.append("")
    write_csv(csv_dir / "builds.csv", table)


def board_shares(folder: Path) -> tuple[dict[str, dict[str, float]], dict[str, int]]:
    """Strategy -> card -> share of that strategy's final boards with the card, and seats per strategy."""
    seats: dict[str, int] = defaultdict(int)
    for row in load(folder, "spread", "players"):
        seats[row["strategy"]] += 1
    boards: dict[str, dict[str, set[tuple[str, str]]]] = defaultdict(lambda: defaultdict(set))
    for row in load(folder, "spread", "cards"):
        boards[row["strategy"]][row["card"]].add((row["seed"], row["seat"]))
    shares = {
        strategy: {card: len(keys) / seats[strategy] for card, keys in cards.items()}
        for strategy, cards in boards.items()
    }
    return shares, seats


def overlap(one: dict[str, float], other: dict[str, float]) -> float:
    """Weighted Jaccard of two strategies' final boards: 0 no card in common, 1 the same boards."""
    cards = set(one) | set(other)
    most = sum(max(one.get(c, 0.0), other.get(c, 0.0)) for c in cards)
    return sum(min(one.get(c, 0.0), other.get(c, 0.0)) for c in cards) / most if most else 0.0


def overlap_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    shares, seats = board_shares(folder)
    out.append("## Are the strategies different boards?\n")
    if not shares:
        out.append("NOT RUN\n")
        return
    out.append(
        f"Overlap is the weighted Jaccard of two strategies' final boards: each card counts by the share of "
        f"boards it's on, 0 means no card in common, 1 the same boards. A strategy is marked distinct if its "
        f"overlap with every other is under {OVERLAP_LIMIT}, a limit chosen by hand.\n"
    )
    table = []
    for strategy in sorted(shares):
        closest = max((s for s in shares if s != strategy), key=lambda s: overlap(shares[strategy], shares[s]))
        value = overlap(shares[strategy], shares[closest])
        table.append({"strategy": strategy, "closest": closest, "overlap": value, "distinct": value < OVERLAP_LIMIT})
    out.append("| Strategy | Closest | Overlap | Distinct? |")
    out.append("|---|---|---:|---|")
    for row in table:
        out.append(
            f"| {row['strategy']} | {row['closest']} | {row['overlap']:.2f} | {'yes' if row['distinct'] else 'NO'} |"
        )
    out.append("")
    write_csv(csv_dir / "overlap.csv", table)
    top_cards_table(shares, seats, out, csv_dir)


def top_cards_table(shares: dict[str, dict[str, float]], seats: dict[str, int], out: list[str], csv_dir: Path) -> None:
    total = sum(seats.values())
    rows = []
    for card in {c for cards in shares.values() for c in cards}:
        per = [shares[s].get(card, 0.0) for s in shares]
        boards = sum(shares[s].get(card, 0.0) * seats[s] for s in shares)
        rows.append(
            {
                "card": card,
                "boards": round(boards),
                "share": boards / total,
                "staple_of": sum(v >= STAPLE_SHARE for v in per),
                "lowest": min(per),
                "highest": max(per),
            }
        )
    rows.sort(key=lambda row: -row["boards"])
    out.append(
        f"Top {TOP_CARDS} cards by final boards, of {total} seats. Staple of: strategies with the card on at least "
        f"{pct(STAPLE_SHARE)} of their final boards, of {len(shares)}.\n"
    )
    out.append("| Card | Boards | Share | Staple of | Lowest strategy | Highest strategy |")
    out.append("|---|---:|---:|---:|---:|---:|")
    for row in rows[:TOP_CARDS]:
        out.append(
            f"| {row['card']} | {row['boards']} | {pct(row['share'])} | {row['staple_of']} | "
            f"{pct(row['lowest'])} | {pct(row['highest'])} |"
        )
    out.append("")
    write_csv(csv_dir / "top_cards.csv", rows)


def stamps_section(folder: Path, out: list[str]) -> None:
    """A partial rerun mixes commits, and the report has to say so."""
    lines = []
    for path in sorted(folder.glob("*.stamp")):
        commit, games = path.read_text(encoding="utf-8").split()
        lines.append((path.stem, games, commit))
    if not lines:
        return
    out.append("## What ran on what code\n")
    if len({line[2] for line in lines}) > 1:
        out.append("**This report mixes commits.** Compare suites from different commits with care.\n")
    out.append("| Suite | Games | Commit |")
    out.append("|---|---:|---|")
    for suite, games, commit in lines:
        out.append(f"| {suite} | {games} | {commit} |")
    out.append("")


def plant_section(folder: Path, out: list[str]) -> None:
    rows = load(folder, "plant", "players")
    out.append("## Does the bench catch a bad bot?\n")
    if not rows:
        out.append("NOT RUN\n")
        return
    table = {row["strategy"]: row for row in spread_table(rows)}
    planted = table.get("plant_bad")
    if planted is None:
        out.append("**FAIL** The planted bot wasn't seated.\n")
        return
    others = [row["place"] for name, row in table.items() if name != "plant_bad"]
    caught = planted["win"] < SPREAD_LOW and planted["place"] > max(others)
    close = close_to(planted["win"], planted["win_ci"], SPREAD_LOW)
    out.append(
        f"{verdict(caught, close)} A strategy that never climbs and fields 3 units won "
        f"{pct(planted['win'])}, average place {planted['place']:.2f} (best other: {min(others):.2f}, "
        f"worst other: {max(others):.2f}); the spread table would mark it NO.\n"
    )


def ladder_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    out.append("## Bot yardstick: one best bot among seven\n")
    lines = {}
    for suite in LADDER_SUITES:
        rows = load(folder, suite, "players")
        if rows:
            lines[suite] = ladder_line(suite, rows)
    if "hard_naive" in lines:
        line = lines["hard_naive"]
        ok = line["top4"] >= HARD_NAIVE_TOP4 and line["win"] >= HARD_NAIVE_WIN
        close = close_to(line["top4"], line["top4_ci"], HARD_NAIVE_TOP4) or close_to(
            line["win"], line["win_ci"], HARD_NAIVE_WIN
        )
        out.append(
            f"{verdict(ok, close)} Best bot (Hard) among seven Naive: "
            f"top 4 {pct(line['top4'])} (bar {pct(HARD_NAIVE_TOP4)}), "
            f"wins {pct(line['win'])} (bar {pct(HARD_NAIVE_WIN)}).\n"
        )
    else:
        out.append("NOT RUN Best bot among seven Naive: top 4 at least 85%, wins at least 45%.\n")
    out.append("| One of | Among seven | Games | Avg place (95%) | Win (95%) | Top 4 (95%) |")
    out.append("|---|---|---:|---:|---:|---:|")
    for suite, line in lines.items():
        one, seven = LADDER_SUITES[suite]
        out.append(
            f"| {one} | {seven} | {line['games']} | {line['place']:.2f} ± {line['place_ci']:.2f} | "
            f"{pct(line['win'])} ± {pct(line['win_ci'])} | {pct(line['top4'])} ± {pct(line['top4_ci'])} |"
        )
    out.append("")
    write_csv(csv_dir / "ladder.csv", list(lines.values()))


def paired_gain(a: list[dict[str, str]], b: list[dict[str, str]]) -> tuple[float, float, int]:
    """Mean of b's place minus a's, paired by seed; positive means a placed better."""
    places_a = {r["seed"]: float(r["place"]) for r in focus_rows(a)}
    places_b = {r["seed"]: float(r["place"]) for r in focus_rows(b)}
    diffs = [places_b[s] - places_a[s] for s in places_a if s in places_b]
    mean, se = mean_se(diffs)
    return mean, Z * se, len(diffs)


def placer_section(folder: Path, out: list[str]) -> None:
    out.append("## Does placing matter with everyone scouting?\n")
    search = load(folder, "place_search", "players")
    shuffled = load(folder, "place_shuffled", "players")
    rule = load(folder, "place_rule", "players")
    if not search or not shuffled:
        out.append("NOT RUN\n")
        return
    gain, ci, pairs = paired_gain(search, shuffled)
    out.append(
        f"{verdict(gain >= PLACE_GAIN, close_to(gain, ci, PLACE_GAIN))} One Hard bot among 7 Hard bots (all searching on the scouted "
        f"board): searching beats shuffled by {gain:.2f} of a place (95% CI ±{ci:.2f}, {pairs} seeds; "
        f"bar {PLACE_GAIN}).\n"
    )
    big = load(folder, "place_big", "players")
    if big:
        big_gain, big_ci, big_pairs = paired_gain(big, search)
        out.append(
            f"With 200 fights a turn, which no phone can afford, search beats Hard's budget by {big_gain:.2f} "
            f"(±{big_ci:.2f}, {big_pairs} seeds): what a bigger budget or faster fights could buy.\n"
        )
    if rule:
        rule_gain, rule_ci, rule_pairs = paired_gain(search, rule)
        out.append(
            f"Searching beats the placing rule by {rule_gain:.2f} (±{rule_ci:.2f}, {rule_pairs} seeds). "
            "The position test measured +0.40 for a lone scout; this one has everyone scouting.\n"
        )
    blind_lines(folder, search, shuffled, out)
    out.append("| Arm | Avg place (95%) | Win | Top 4 |")
    out.append("|---|---:|---:|---:|")
    for name, rows in (("search 200", big), ("search", search), ("rule", rule), ("shuffled", shuffled)):
        if rows:
            line = ladder_line(name, rows)
            out.append(
                f"| {name} | {line['place']:.2f} ± {line['place_ci']:.2f} | {pct(line['win'])} | {pct(line['top4'])} |"
            )
    out.append("")


def blind_lines(folder: Path, search: list[dict[str, str]], shuffled: list[dict[str, str]], out: list[str]) -> None:
    """The scouting rule judged: the same Hard family, same seeds, with scouting removed."""
    alone = load(folder, "blind_alone", "players")
    lobby = load(folder, "blind_lobby", "players")
    random_arm = load(folder, "blind_shuffled", "players")
    if alone:
        gain, ci, pairs = paired_gain(search, alone)
        out.append(
            f"No scouting, one seat among 7 who scout: seeing the board is worth {gain:.2f} of a place to the "
            f"seat that has it (±{ci:.2f}, {pairs} seeds).\n"
        )
    if lobby and random_arm:
        gain, ci, pairs = paired_gain(lobby, random_arm)
        with_rule, with_ci, _ = paired_gain(search, shuffled)
        out.append(
            f"No scouting for anyone: placing by rule beats shuffled by {gain:.2f} (±{ci:.2f}, {pairs} seeds), "
            f"against {with_rule:.2f} (±{with_ci:.2f}) with everyone scouting. The difference is what the rule "
            "adds to placing.\n"
        )
    for name, rows in (("everyone scouts", search), ("nobody scouts", lobby)):
        if rows:
            lengths: dict[str, int] = {}
            for row in rows:
                lengths[row["seed"]] = max(lengths.get(row["seed"], 0), int(row["rounds"]))
            out.append(f"Game length, {name}: {mean_se([float(v) for v in lengths.values()])[0]:.1f} rounds.\n")


def cards_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    rows = load(folder, "spread", "cards")
    players = load(folder, "spread", "players")
    out.append("## Cards and heroes in the mixed lobbies\n")
    if not rows or not players:
        out.append("NOT RUN\n")
        return
    seats = len(players)
    wins = sum(1 for r in players if r["place"] == "1")
    baseline = wins / seats
    groups: dict[str, set[tuple[str, str]]] = defaultdict(set)
    tiers: dict[str, int] = {}
    winners: dict[str, int] = defaultdict(int)
    for row in rows:
        key = (row["seed"], row["seat"])
        if key in groups[row["card"]]:
            continue
        groups[row["card"]].add(key)
        tiers[row["card"]] = int(row["tier"])
        if row["place"] == "1":
            winners[row["card"]] += 1
    tier_seen: dict[int, list[int]] = defaultdict(lambda: [0, 0])
    for card, keys in groups.items():
        tier_seen[tiers[card]][0] += len(keys)
        tier_seen[tiers[card]][1] += winners[card]
    table = []
    for card, keys in groups.items():
        win, ci = rate_ci(winners[card], len(keys))
        seen = tier_seen[tiers[card]]
        tier_rate = seen[1] / seen[0] if seen[0] else 0.0
        table.append(
            {
                "card": card,
                "tier": tiers[card],
                "pick": len(keys) / seats,
                "win_on_final": win,
                "ci": ci,
                "tier_average": tier_rate,
                "lift": win - tier_rate,
            }
        )
    table.sort(key=lambda row: -row["lift"])
    out.append(
        f"Share of final boards with the card, and the win rate of those boards. Later cards sit on "
        f"survivors' boards, so read each against its tier's average. Overall win rate per seat: {pct(baseline)}.\n"
    )
    out.append("| Card | Tier | On final boards | Win when on it (95%) | Tier average | Lift |")
    out.append("|---|---:|---:|---:|---:|---:|")
    for row in table:
        out.append(
            f"| {row['card']} | {row['tier']} | {pct(row['pick'])} | {pct(row['win_on_final'])} ± {pct(row['ci'])} | "
            f"{pct(row['tier_average'])} | {100 * row['lift']:+.1f} |"
        )
    out.append("")
    write_csv(csv_dir / "cards.csv", table)
    heroes_section(players, out, csv_dir)


def heroes_section(players: list[dict[str, str]], out: list[str], csv_dir: Path) -> None:
    offered: dict[str, int] = defaultdict(int)
    picked: dict[str, int] = defaultdict(int)
    wins: dict[str, int] = defaultdict(int)
    places: dict[str, list[float]] = defaultdict(list)
    for row in players:
        for hero in row["offered"].split("+"):
            if hero:
                offered[hero] += 1
        hero = row["hero"]
        if hero:
            picked[hero] += 1
            wins[hero] += row["place"] == "1"
            places[hero].append(float(row["place"]))
    table = []
    for hero in sorted(picked, key=lambda name: -wins[name] / picked[name]):
        win, ci = rate_ci(wins[hero], picked[hero])
        table.append(
            {
                "hero": hero,
                "picked_when_offered": picked[hero] / max(1, offered[hero]),
                "games": picked[hero],
                "win": win,
                "ci": ci,
                "place": mean_se(places[hero])[0],
            }
        )
    out.append("| Hero | Picked when offered | Games | Win (95%) | Avg place |")
    out.append("|---|---:|---:|---:|---:|")
    for row in table:
        out.append(
            f"| {row['hero']} | {pct(row['picked_when_offered'])} | {row['games']} | {pct(row['win'])} ± "
            f"{pct(row['ci'])} | {row['place']:.2f} |"
        )
    out.append("")
    write_csv(csv_dir / "heroes.csv", table)


def tempo_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    rounds = load(folder, "spread", "rounds")
    players = load(folder, "spread", "players")
    out.append("## Pace and economy\n")
    if not rounds:
        out.append("NOT RUN\n")
        return
    per_round: dict[int, list[dict[str, str]]] = defaultdict(list)
    for row in rounds:
        per_round[int(row["round"])].append(row)
    t6 = [float(r["tier6_turn"]) for r in players if r["tier6_turn"] != "0"]
    at_t6 = [float(r["bought_at_t6"]) for r in players if r["tier6_turn"] != "0"]
    earliest = min(t6) if t6 else 0
    out.append(
        f"Tier 6: {len(t6)} of {len(players)} seats reach it, on average turn {mean_se(t6)[0]:.1f}, "
        f"earliest {earliest:.0f} (target: turn 8 at the earliest for economy); {mean_se(at_t6)[0]:.1f} units bought by then.\n"
    )
    lengths = {}
    for row in players:
        lengths[row["seed"]] = max(lengths.get(row["seed"], 0), int(row["rounds"]))
    out.append(
        f"Game length: {mean_se([float(v) for v in lengths.values()])[0]:.1f} rounds on average, longest {max(lengths.values())}.\n"
    )
    fights = sum(float(r["fights"]) for r in players)
    acorns = sum(float(r["acorns"]) for r in players)
    out.append(f"Acorns per fight, across all seats: {acorns / max(1.0, fights):.3f}.\n")
    table = []
    out.append(
        "| Turn | Seats alive | Tier | Units | Avg unit (target 13/13 by turn 12) | Bank at start | Spent | Paid refreshes | Larder held |"
    )
    out.append("|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for number in sorted(per_round):
        chosen = per_round[number]
        count = len(chosen)
        units = sum(int(r["units"]) for r in chosen)
        line = {
            "turn": number,
            "seats": count,
            "tier": sum(int(r["tier"]) for r in chosen) / count,
            "units": units / count,
            "unit_attack": sum(int(r["attack"]) for r in chosen) / max(1, units),
            "unit_health": sum(int(r["health"]) for r in chosen) / max(1, units),
            "bank": sum(int(r["bank"]) for r in chosen) / count,
            "spent": sum(int(r["spent"]) for r in chosen) / count,
            "refreshes": sum(int(r["paid_refreshes"]) for r in chosen) / count,
            "larder": sum(int(r["larder"]) for r in chosen) / count,
        }
        table.append(line)
        out.append(
            f"| {number} | {count} | {line['tier']:.1f} | {line['units']:.1f} | "
            f"{line['unit_attack']:.1f}/{line['unit_health']:.1f} | {line['bank']:.1f} | {line['spent']:.1f} | "
            f"{line['refreshes']:.1f} | {line['larder']:.1f} |"
        )
    out.append("")
    write_csv(csv_dir / "rounds.csv", table)
    banks_section(rounds, out)


def shops_by_rule(bank: int) -> int:
    """Shops seen with nothing but refreshes: 1 gold for 15, then +1 per 5 (4.4.2-4.4.3)."""
    shops = 1
    paid = 0
    while True:
        cost = 1 if paid < 15 else 2 + (paid - 15) // 5
        if bank < cost:
            return shops
        bank -= cost
        paid += 1
        shops += 1


def banks_section(rounds: list[dict[str, str]], out: list[str]) -> None:
    out.append(
        "Shops seen in a long turn (owner's aim: about 20-30 at a big bank). By rule is every coin on refreshes; observed is what Hard bots did with about that much.\n"
    )
    out.append("| Bank | Shops by rule | Observed turns | Shops observed |")
    out.append("|---:|---:|---:|---:|")
    for bank, (low, high) in BANKS.items():
        chosen = [int(r["paid_refreshes"]) + 1 for r in rounds if low <= int(r["bank"]) <= high]
        observed = f"{sum(chosen) / len(chosen):.1f}" if chosen else "none"
        out.append(f"| {bank} | {shops_by_rule(bank)} | {len(chosen)} | {observed} |")
    out.append("")


def timing_section(folder: Path, out: list[str]) -> None:
    out.append("## Time per bot turn\n")
    groups: dict[str, list[float]] = defaultdict(list)
    for suite in ("head_to_head", "place_search", "spread", "hard_lobby_hard", "hard_naive"):
        for row in load(folder, suite, "turns"):
            groups[row["level"]].append(float(row["usec"]) / 1000.0)
    if not groups:
        out.append("NOT RUN\n")
        return
    out.append(
        f"Measured here, while other bench shards ran. Phone-speed core assumed {PHONE_FACTOR:.0f} times slower "
        "(an assumption: no device was tested). The limit is 7 bots in about 1 s.\n"
    )
    lobby_turns(folder, out)
    out.append("| Level | Turns | Mean ms | 95th pct ms | Worst ms | 7 bots on a phone, mean |")
    out.append("|---|---:|---:|---:|---:|---:|")
    for level in sorted(groups):
        values = sorted(groups[level])
        mean = sum(values) / len(values)
        p95 = values[int(0.95 * (len(values) - 1))]
        phone = mean * PHONE_FACTOR * 7 / 1000.0
        out.append(f"| {level} | {len(values)} | {mean:.1f} | {p95:.1f} | {values[-1]:.1f} | {phone:.2f} s |")
    out.append("")


def lobby_turns(folder: Path, out: list[str]) -> None:
    """What the player waits for: all the bots' turns in one round, added up."""
    totals: dict[tuple[str, str, str], float] = defaultdict(float)
    for suite in ("spread", "place_search"):
        for row in load(folder, suite, "turns"):
            totals[(suite, row["seed"], row["round"])] += float(row["usec"]) / 1000.0
    if not totals:
        return
    values = sorted(totals.values())
    mean = sum(values) / len(values)
    p95 = values[int(0.95 * (len(values) - 1))]
    out.append(
        f"A whole lobby's turn, all Hard: mean {mean:.0f} ms, 95th percentile {p95:.0f} ms, worst {values[-1]:.0f} ms here; "
        f"on the assumed phone core mean {mean * PHONE_FACTOR / 1000:.2f} s, 95th percentile {p95 * PHONE_FACTOR / 1000:.2f} s.\n"
    )


def write_csv(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow({k: round(v, 4) if isinstance(v, float) else v for k, v in row.items()})


FREE_CHOICE_TRIBES = ("Birds", "Bog folk", "Fairies", "Hedgerow folk", "Hunters", "Oozes", "no_tribe")


def cluster_ratio_ci(rows: list[dict], numerator, denominator, bounds) -> tuple | None:
    """95% t interval using lobby-clustered ratio residuals (delta method)."""
    clusters = defaultdict(lambda: [0.0, 0.0])
    for index, row in enumerate(rows):
        key = row.get("seed", str(index))
        clusters[key][0] += numerator(row)
        clusters[key][1] += denominator(row)
    total = sum(pair[1] for pair in clusters.values())
    informative = sum(b > 0 for _, b in clusters.values())
    if not total or informative < 2:
        return None
    ratio = sum(pair[0] for pair in clusters.values()) / total
    if bounds == (0, 1) and ratio in (0, 1):
        # At a boundary the delta method collapses. Treat each informative lobby as
        # one conservative score trial rather than claiming zero uncertainty.
        edge = Z**2 / (informative + Z**2)
        return (0.0, edge) if ratio == 0 else (1.0 - edge, 1.0)
    n = len(clusters)
    se = math.sqrt(n / (n - 1) * sum((a - ratio * b) ** 2 for a, b in clusters.values())) / total
    margin = t95(n - 1) * se
    return max(bounds[0], ratio - margin), min(bounds[1], ratio + margin)


def free_choice_rates(rows: list[dict[str, str]]) -> list[dict]:
    """All-seat and offered-seat pick rates; outcomes condition on majority label."""
    groups: dict[str, list[int]] = defaultdict(list)
    for row in rows:
        groups[row["final_tribe"]].append(int(row["place"]))
    tribes = list(FREE_CHOICE_TRIBES) + sorted(set(groups) - set(FREE_CHOICE_TRIBES))
    rates = []
    for tribe in tribes:

        def picked(row):
            return row["final_tribe"] == tribe

        def offered(row):
            # Missing column is old evidence: conditional picks cannot be reconstructed.
            return "lobby_tribes" in row and (not row["lobby_tribes"] or tribe in row["lobby_tribes"].split("+"))

        eligible = sum(offered(row) for row in rows) if tribe != "no_tribe" else 0
        selected = groups[tribe]
        rate = {
            "tribe": tribe,
            "seats": len(selected),
            "pick_rate": len(selected) / len(rows) if rows else 0.0,
            "lobby_seats": eligible,
            "lobby_pick_rate": sum(picked(r) and offered(r) for r in rows) / eligible if eligible else None,
            "avg_place": sum(selected) / len(selected) if selected else None,
            "first_rate": selected.count(1) / len(selected) if selected else None,
        }
        metrics = {
            "pick_rate": (picked, lambda r: 1, (0, 1)),
            "lobby_pick_rate": (lambda r: picked(r) and offered(r), offered, (0, 1)),
            "avg_place": (lambda r: int(r["place"]) if picked(r) else 0, picked, (1, 8)),
            "first_rate": (lambda r: picked(r) and r["place"] == "1", picked, (0, 1)),
        }
        for metric, (numerator, denominator, bounds) in metrics.items():
            ci = cluster_ratio_ci(rows, numerator, denominator, bounds) if rate[metric] is not None else None
            rate[metric + "_low"] = ci[0] if ci else None
            rate[metric + "_high"] = ci[1] if ci else None
        rates.append(rate)
    return rates


def no_tribe_rates(rows: list[dict[str, str]]) -> list[dict]:
    groups = defaultdict(list)
    for row in rows:
        if row["final_tribe"] == "no_tribe":
            groups[(row.get("no_tribe_reason", "unknown"), row.get("plurality_tribe", "unknown"))].append(row)
    total = sum(map(len, groups.values()))
    return [
        {
            "reason": reason,
            "plurality": plurality,
            "seats": len(group),
            "share_of_no_tribe": len(group) / total,
            "mean_plurality_share": sum(float(r.get("plurality_share", 0)) for r in group) / len(group),
            "avg_place": sum(int(r["place"]) for r in group) / len(group),
            "first_rate": sum(r["place"] == "1" for r in group) / len(group),
        }
        for (reason, plurality), group in sorted(groups.items())
    ]


def free_choice_section(folder: Path, out: list[str], suite: str = "free_choice") -> None:
    out.append(f"## Free-choice final boards: {suite}\n")
    rows = load(folder, suite, "players")
    if not rows:
        out.append("NOT RUN\n")
        return
    rates = free_choice_rates(rows)
    write_csv(folder / f"{suite}.summary.csv", rates)
    out.append(
        "Eight seats per lobby; zero tribe priors, no routes. Majority and plurality exclude all tokens; "
        "neutral non-token slots count. Away Birds/Bellies add none. Plurality ties retain every leader. "
        "Pick uses all seats; lobby pick uses seats where the tribe was offered. Outcomes condition on "
        "majority label. 95% t intervals use lobby-clustered ratio residuals; exploratory, no multiple-"
        "comparison correction. Boundary rates use a conservative Wilson bound with one trial per informative lobby; fewer than two informative lobbies have no interval. Sparse results need more lobbies. "
        "Other hints (flight, larder, spells, heroes, placement) and live mechanic evaluation remain. "
        + (
            "Buy/keep hints remain: pick measures the policy as well as cards.\n"
            if suite == "free_choice"
            else "Buy/keep hints are bypassed, including text_value; generic text fallback is 1.5 × tier.\n"
        )
    )
    out.extend(
        [
            "| Tribe | Seats | Pick (95%) | Lobby pick (95%) | Mean place (95%) | First (95%) |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for rate in rates:
        cells = []
        for metric in ("pick_rate", "lobby_pick_rate", "avg_place", "first_rate"):
            value, low, high = (rate[metric + suffix] for suffix in ("", "_low", "_high"))
            fmt = (lambda v: f"{v:.2f}") if metric == "avg_place" else (lambda v: f"{100 * v:.2f}%")
            cell = fmt(value) if value is not None else "—"
            if low is not None:
                cell += f" [{fmt(low)}, {fmt(high)}]"
            cells.append(cell)
        out.append(f"| {rate['tribe']} | {rate['seats']} | " + " | ".join(cells) + " |")
    breakdown = no_tribe_rates(rows)
    write_csv(folder / f"{suite}.no_tribe.csv", breakdown)
    out.extend(
        [
            "",
            "no_tribe breakdown (plurality share uses eligible slots):\n",
            "| Reason | Plurality | Seats | Share of no_tribe | Mean plurality share | Mean place | First |",
            "|---|---|---:|---:|---:|---:|---:|",
        ]
    )
    for row in breakdown:
        out.append(
            f"| {row['reason']} | {row['plurality']} | {row['seats']} | "
            f"{pct(row['share_of_no_tribe'])} | {pct(row['mean_plurality_share'])} | "
            f"{row['avg_place']:.2f} | {pct(row['first_rate'])} |"
        )
    out.append("")


def main() -> int:
    folder = Path(sys.argv[1])
    report = Path(sys.argv[2])
    csv_dir = folder
    out = [
        "# Bench: latest run\n",
        "Written by `tools/sim/bench.sh`; reproduce with the same command and seed. Bars come from `docs/ideation/PLAN.md`; TOO CLOSE means the bar sits inside the measurement's 95% margin. A strategy's result measures the bot as well as the game. Bot-or-game reading: `bench-reading.md`.\n",
    ]
    free_choice_section(folder, out)
    free_choice_section(folder, out, "free_choice_plain")
    head_to_head_section(folder, out, csv_dir)
    ladder_section(folder, out, csv_dir)
    builds_section(folder, out, csv_dir)
    spread_section(folder, out, csv_dir)
    overlap_section(folder, out, csv_dir)
    plant_section(folder, out)
    placer_section(folder, out)
    tempo_section(folder, out, csv_dir)
    cards_section(folder, out, csv_dir)
    timing_section(folder, out)
    stamps_section(folder, out)
    report.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
