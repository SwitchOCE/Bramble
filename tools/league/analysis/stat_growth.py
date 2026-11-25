"""Permanent stats a unit gains per turn it is held, per card, from a match's records.

Definitions: docs/workstreams/card-power/definitions.md ("Stat growth"). Every board in a record's
`fight_boards` lists each unit with its uid and its permanent gains (`stats.perm_attack`,
`stats.perm_health`). A unit seen on the same player's board on two turns in a row, with the same
uid and golden flag, gives one observation: what it gained in between. `above_mates` takes off the
average gain of the other units on the same board that turn, so a buff that hits the whole board
is not credited to the card.

usage: stat_growth.py <match dir>... --out <growth.csv>
"""
import argparse
import csv
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

STAGES = ("1-4", "5-8", "9-12", "13+")
MIN_OBSERVATIONS = 200
LOOK_SPREADS = 3.0
LOOK_FLOOR = 3.0  # at least three permanent stats a turn, however tight the table is
MIN_TIER_CARDS = 5


def stage(turn):
    return STAGES[min((turn - 1) // 4, 3)]


def boards(record):
    """Yield (turn, player id, {uid: (card, golden, perm attack, perm health)}) for every board."""
    with open(record) as stream:
        for line in stream:
            if '"fight_boards"' not in line:
                continue
            row = json.loads(line)
            for player in row["players"]:
                units = {}
                for unit in player["board"]:
                    if unit:
                        stats = unit.get("stats") or {}
                        units[unit["uid"]] = (unit["def"], bool(unit.get("golden")),
                                              stats.get("perm_attack", 0), stats.get("perm_health", 0))
                yield row["turn"], player["id"], units


def observations(record, game):
    """One row per unit held across two turns in a row: its gain, and its board-mates' mean gain."""
    last = {}
    for turn, player, units in boards(record):
        before = last.get(player)
        last[player] = (turn, units)
        if before is None or before[0] != turn - 1:
            continue
        gains = {}
        for uid, (card, golden, attack, health) in units.items():
            old = before[1].get(uid)
            if old and old[0] == card and old[1] == golden:
                gains[uid] = (card, golden, attack - old[2], health - old[3], attack + health)
        total = sum(g[2] + g[3] for g in gains.values())
        for uid, (card, golden, d_attack, d_health, held) in gains.items():
            mates = (total - d_attack - d_health) / (len(gains) - 1) if len(gains) > 1 else 0.0
            yield {"game": game, "stage": stage(turn), "card": card, "golden": golden,
                   "attack": d_attack, "health": d_health, "mates": mates, "held": held}


def clustered(rows, value):
    per_game = defaultdict(lambda: [0.0, 0])
    for row in rows:
        cell = per_game[row["game"]]
        cell[0] += value(row)
        cell[1] += 1
    n = sum(c[1] for c in per_game.values())
    mean = sum(c[0] for c in per_game.values()) / n
    games = len(per_game)
    if games < 2:
        return mean, None, None
    spread = sum((c[0] - mean * c[1]) ** 2 for c in per_game.values())
    half = 1.96 * math.sqrt(spread * games / (games - 1)) / n
    return mean, mean - half, mean + half


def middle_and_spread(values):
    middle = statistics.median(values)
    return middle, 1.4826 * statistics.median(abs(v - middle) for v in values)


def table(rows, tiers):
    cells = defaultdict(list)
    for row in rows:
        if not row["golden"]:  # a golden unit doubles its numbers; keep the plain copies comparable
            cells[(row["stage"], row["card"])].append(row)
    out = []
    for (stage_name, card), obs in sorted(cells.items(), key=lambda kv: (STAGES.index(kv[0][0]), kv[0][1])):
        n = len(obs)
        enough = n >= MIN_OBSERVATIONS
        gain, low, high = clustered(obs, lambda r: r["attack"] + r["health"])
        above, above_low, _ = clustered(obs, lambda r: r["attack"] + r["health"] - r["mates"])
        show = lambda x, d=2: round(x, d) if enough and x is not None else ""
        out.append({"stage": stage_name, "card": card, "tier": tiers.get(card, ""), "n": n,
                    "status": "ok" if enough else "too few",
                    "attack_per_turn": show(statistics.fmean(r["attack"] for r in obs)),
                    "health_per_turn": show(statistics.fmean(r["health"] for r in obs)),
                    "stats_per_turn": show(gain), "low": show(low), "high": show(high),
                    "above_mates": show(above), "above_low": show(above_low), "share_growing": show(sum(r["attack"] + r["health"] > 0 for r in obs) / n),
                    "perm_stats_held": show(statistics.fmean(r["held"] for r in obs), 1),
                    "spreads": "", "tier_spreads": "", "look": ""})
    for stage_name in STAGES:
        here = [r for r in out if r["stage"] == stage_name and r["status"] == "ok"]
        if len(here) < 4:
            continue
        middle, spread = middle_and_spread([r["above_mates"] for r in here])
        for r in here:
            if spread:
                r["spreads"] = round((r["above_mates"] - middle) / spread, 1)
                if (r["spreads"] >= LOOK_SPREADS and r["above_low"] != "" and r["above_low"] > middle
                        and r["stats_per_turn"] >= LOOK_FLOOR):
                    r["look"] = "worth a look"
        # Against its own tier (the owner's framing): raw growth, among cards of the same tier.
        by_tier = defaultdict(list)
        for r in here:
            by_tier[r["tier"]].append(r)
        for cards in by_tier.values():
            if len(cards) < MIN_TIER_CARDS:
                continue
            middle, spread = middle_and_spread([r["stats_per_turn"] for r in cards])
            for r in cards:
                if spread:
                    r["tier_spreads"] = round((r["stats_per_turn"] - middle) / spread, 1)
                    if r["tier_spreads"] >= LOOK_SPREADS and r["low"] > middle and r["stats_per_turn"] >= LOOK_FLOOR:
                        r["look"] = "worth a look"
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("match", nargs="+")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    rows, tiers = [], {}
    for tag, directory in enumerate(args.match):
        directory = Path(directory)
        tiers.update({c["id"]: c["tier"] for c in json.loads((directory / "library.json").read_text())})
        for record in sorted((directory / "records").glob("game-*.jsonl")):
            rows.extend(observations(record, (tag, record.stem)))
    result = table(rows, tiers)
    with open(args.out, "w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(result[0]))
        writer.writeheader()
        writer.writerows(result)
    print(f"{len(rows)} unit-turns, {sum(r['status'] == 'ok' for r in result)} cells with a number, "
          f"{sum(bool(r['look']) for r in result)} worth a look -> {args.out}")


if __name__ == "__main__":
    main()
