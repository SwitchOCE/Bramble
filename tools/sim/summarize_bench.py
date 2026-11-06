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
HARD_NORMAL_PLACE = 3.5
PLACE_GAIN = 0.5
PHONE_FACTOR = 3.0
BOT_TURN_LIMIT_MS = 1000.0 / 7
BANKS = {12: (10, 14), 30: (25, 35), 60: (50, 70)}


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


def verdict(ok: bool) -> str:
    return "**PASS**" if ok else "**FAIL**"


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
    ok = len(inside) >= SPREAD_MIN_STRATEGIES and not over and games >= SPREAD_GAMES
    out.append(
        f"{verdict(ok)} Bar: at least {SPREAD_MIN_STRATEGIES} strategies at 6-25% wins, none above 25%, "
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
    out.append(
        f"{verdict(caught)} A strategy that never climbs and fields 3 units won "
        f"{pct(planted['win'])}, average place {planted['place']:.2f} (best other: {min(others):.2f}, "
        f"worst other: {max(others):.2f}); the spread table would mark it NO.\n"
    )


def ladder_section(folder: Path, out: list[str], csv_dir: Path) -> None:
    out.append("## Skill ladder: one bot among seven\n")
    lines = {}
    for suite in ("hard_naive", "hard_easy", "hard_normal", "normal_easy", "normal_naive", "easy_naive"):
        rows = load(folder, suite, "players")
        if rows:
            lines[suite] = ladder_line(suite, rows)
    if "hard_naive" in lines:
        line = lines["hard_naive"]
        ok = line["top4"] >= HARD_NAIVE_TOP4 and line["win"] >= HARD_NAIVE_WIN
        out.append(
            f"{verdict(ok)} Hard among Naive: top 4 {pct(line['top4'])} (bar {pct(HARD_NAIVE_TOP4)}), "
            f"wins {pct(line['win'])} (bar {pct(HARD_NAIVE_WIN)}).\n"
        )
    if "hard_normal" in lines:
        line = lines["hard_normal"]
        out.append(
            f"{verdict(line['place'] <= HARD_NORMAL_PLACE)} Hard among Normal: average place "
            f"{line['place']:.2f} (bar {HARD_NORMAL_PLACE}).\n"
        )
    if "normal_easy" in lines:
        line = lines["normal_easy"]
        out.append(
            f"{verdict(line['place'] < 4.5)} Normal among Easy: average place {line['place']:.2f} "
            "(a ladder needs it under 4.5).\n"
        )
    out.append("| One of | Among seven | Games | Avg place (95%) | Win (95%) | Top 4 (95%) |")
    out.append("|---|---|---:|---:|---:|---:|")
    for suite, line in lines.items():
        one, seven = suite.split("_")
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
        f"{verdict(gain >= PLACE_GAIN)} One Hard bot among 7 Hard bots (all searching on the scouted "
        f"board): searching beats shuffled by {gain:.2f} of a place (95% CI ±{ci:.2f}, {pairs} seeds; "
        f"bar {PLACE_GAIN}).\n"
    )
    if rule:
        rule_gain, rule_ci, rule_pairs = paired_gain(search, rule)
        out.append(
            f"Searching beats the placing rule by {rule_gain:.2f} (±{rule_ci:.2f}, {rule_pairs} seeds). "
            "The position test measured +0.40 for a lone scout; this one has everyone scouting.\n"
        )
    out.append("| Arm | Avg place (95%) | Win | Top 4 |")
    out.append("|---|---:|---:|---:|")
    for name, rows in (("search", search), ("rule", rule), ("shuffled", shuffled)):
        if rows:
            line = ladder_line(name, rows)
            out.append(f"| {name} | {line['place']:.2f} ± {line['place_ci']:.2f} | {pct(line['win'])} | {pct(line['top4'])} |")
    out.append("")


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
    out.append(f"Game length: {mean_se([float(v) for v in lengths.values()])[0]:.1f} rounds on average, longest {max(lengths.values())}.\n")
    fights = sum(float(r["fights"]) for r in players)
    acorns = sum(float(r["acorns"]) for r in players)
    out.append(f"Acorns per fight, across all seats: {acorns / max(1.0, fights):.3f}.\n")
    table = []
    out.append("| Turn | Seats alive | Tier | Units | Avg unit (target 13/13 by turn 12) | Bank at start | Spent | Paid refreshes | Larder held |")
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
    out.append("Shops seen in a long turn (owner's aim: about 20-30 at a big bank). By rule is every coin on refreshes; observed is what Hard bots did with about that much.\n")
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
    for suite in ("place_search", "spread", "hard_normal", "normal_easy", "hard_naive"):
        for row in load(folder, suite, "turns"):
            groups[row["level"]].append(float(row["usec"]) / 1000.0)
    if not groups:
        out.append("NOT RUN\n")
        return
    out.append(
        f"Measured here, while other bench shards ran. Phone-speed core assumed {PHONE_FACTOR:.0f} times slower "
        "(an assumption: no device was tested). The limit is 7 bots in about 1 s.\n"
    )
    out.append("| Level | Turns | Mean ms | 95th pct ms | Worst ms | 7 bots on a phone, mean |")
    out.append("|---|---:|---:|---:|---:|---:|")
    for level in ("naive", "easy", "normal", "hard"):
        values = sorted(groups.get(level, []))
        if not values:
            continue
        mean = sum(values) / len(values)
        p95 = values[int(0.95 * (len(values) - 1))]
        phone = mean * PHONE_FACTOR * 7 / 1000.0
        out.append(f"| {level} | {len(values)} | {mean:.1f} | {p95:.1f} | {values[-1]:.1f} | {phone:.2f} s |")
    out.append("")


def write_csv(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow({k: round(v, 4) if isinstance(v, float) else v for k, v in row.items()})


def main() -> int:
    folder = Path(sys.argv[1])
    report = Path(sys.argv[2])
    csv_dir = report.parent / report.stem
    csv_dir.mkdir(parents=True, exist_ok=True)
    out = [
        "# Bench: latest run\n",
        "Written by `tools/sim/bench.sh`; reproduce with the same command and seed. Bars come from `docs/ideation/PLAN.md`. A strategy's result measures the bot as well as the game.\n",
    ]
    ladder_section(folder, out, csv_dir)
    spread_section(folder, out, csv_dir)
    plant_section(folder, out)
    placer_section(folder, out)
    tempo_section(folder, out, csv_dir)
    cards_section(folder, out, csv_dir)
    timing_section(folder, out)
    report.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
