#!/usr/bin/env python3
"""Sample weighted blind fields from live fight captures and report round-robin results."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
from collections import Counter, defaultdict
from pathlib import Path

ROUNDS = (6, 8, 10, 12, 14, 16)


def boards_from_capture(paths, require_blind=True):
    seen = set()
    for path in sorted(paths):
        with path.open() as stream:
            for raw in stream:
                record = json.loads(raw)
                fight = record["input"]
                for side, seat in enumerate(fight["player_ids"]):
                    if int(seat) < 0:
                        continue
                    key = (record["seed"], record["leg"], int(seat), int(fight["round"]))
                    if key in seen:
                        raise ValueError(f"duplicate board: {key}")
                    seen.add(key)
                    snapshot = record["combat_start"][side]
                    if require_blind and snapshot.get("layout") != "blind":
                        raise ValueError("field inputs must be captured with a blind final layout")
                    yield {
                        "id": ":".join(map(str, key)),
                        "seed": key[0],
                        "leg": key[1],
                        "seat": key[2],
                        "round": key[3],
                        "line": snapshot.get("policy", snapshot.get("line", "unknown")),
                        "layout": snapshot.get("layout", "unlabelled"),
                        "board": fight["boards"][side],
                        "slots": fight["slots"][side],
                        "fight_rules": fight["fight_rules"][side],
                        "hero_effects": fight["hero_effects"][side],
                        "tier": fight["tiers"][side],
                        "config": fight["config"],
                        "combat_start": snapshot,
                        "test_cards": record.get("test_cards", []),
                    }


def quotas(counts: dict, size: int) -> dict:
    if sum(counts.values()) < size or len(counts) > size:
        raise ValueError("not enough boards, or field smaller than the number of represented lines")
    if "hard" not in counts:
        raise ValueError("Hard tempo anchor is absent")
    total = sum(counts.values())
    allocated = dict.fromkeys(counts, 1)
    while sum(allocated.values()) < size:
        eligible = [key for key in counts if allocated[key] < counts[key]]
        chosen = max(sorted(eligible), key=lambda key: size * counts[key] / total - allocated[key])
        allocated[chosen] += 1
    return allocated


def sample_field(boards, rounds=ROUNDS, size=64, seed=91407):
    counts = defaultdict(Counter)
    reservoirs = defaultdict(list)
    streams = {}
    test_cards = {}
    for board in boards:
        for card in board.get("test_cards", []):
            if card["id"] in test_cards and test_cards[card["id"]] != card:
                raise ValueError("conflicting test-only card definitions")
            test_cards[card["id"]] = card
        number, line = board["round"], board["line"]
        if number not in rounds:
            continue
        key = (number, line)
        if key not in streams:
            streams[key] = random.Random(int.from_bytes(hashlib.sha256(f"{seed}|{number}|{line}".encode()).digest()))
        counts[number][line] += 1
        count = counts[number][line]
        reservoir = reservoirs[key]
        if len(reservoir) < size:
            reservoir.append(board)
        else:
            index = streams[key].randrange(count)
            if index < size:
                reservoir[index] = board
    result = {"version": 1, "sample_seed": seed, "size": size, "rounds": {}, "test_cards": list(test_cards.values())}
    for number in rounds:
        allocation = quotas(counts[number], size)
        total = sum(counts[number].values())
        selected = []
        for line, count in sorted(allocation.items()):
            chosen = streams[number, line].sample(reservoirs[number, line], count)
            for original in chosen:
                board = dict(original)
                board["weight"] = counts[number][line] / total / count
                selected.append(board)
        result["rounds"][str(number)] = {
            "boards": selected,
            "population_counts": dict(counts[number]),
            "sample_counts": allocation,
            "line_weights": {line: count / total for line, count in counts[number].items()},
        }
    return result


def wilson(wins, total):
    if not total:
        return None
    z = 1.959963984540054
    p = wins / total
    denominator = 1 + z * z / total
    middle = (p + z * z / (2 * total)) / denominator
    spread = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total * total)) / denominator
    return [middle - spread, middle + spread]


def field_report(field: dict, pairs):
    indexed = {board["id"]: board for round_data in field["rounds"].values() for board in round_data["boards"]}
    scores, mass = defaultdict(float), defaultdict(float)
    matrix_scores, matrix_mass = defaultdict(float), defaultdict(float)
    seen, pair_rows = set(), []
    for pair in pairs:
        a, b = indexed[pair["a"]], indexed[pair["b"]]
        number = int(pair["round"])
        identity = tuple(sorted((a["id"], b["id"])))
        if identity in seen or a["round"] != b["round"] or number != a["round"] or a["id"] == b["id"]:
            raise ValueError("duplicate, self, or cross-round pair")
        seen.add(identity)
        total = pair["trials"]
        if total <= 0 or pair["wins_a"] + pair["wins_b"] + pair["draws"] != total:
            raise ValueError("incomplete fight counts")
        score = (pair["wins_a"] + 0.5 * pair["draws"]) / total
        for left, right, point in [(a, b, score), (b, a, 1 - score)]:
            scores[left["id"]] += right["weight"] * point
            mass[left["id"]] += right["weight"]
            key = (number, left["line"], right["line"])
            weight = left["weight"] * right["weight"]
            matrix_scores[key] += weight * point
            matrix_mass[key] += weight
        decisive = pair["wins_a"] + pair["wins_b"]
        pair_rows.append(
            {
                **pair,
                "p_win_a": pair["wins_a"] / decisive if decisive else None,
                "p_win_a_ci95": wilson(pair["wins_a"], decisive),
                "pair_weight": a["weight"] * b["weight"],
            }
        )
    expected = sum(len(data["boards"]) * (len(data["boards"]) - 1) // 2 for data in field["rounds"].values())
    if len(seen) != expected:
        raise ValueError(f"need complete round robins: {len(seen)} of {expected} pairs")
    report = {"version": 1, "rounds": {}, "pairs": pair_rows}
    for key, data in field["rounds"].items():
        number = int(key)
        boards = [
            {
                "id": b["id"],
                "line": b["line"],
                "weight": b["weight"],
                "field_point_rate": scores[b["id"]] / mass[b["id"]],
            }
            for b in data["boards"]
        ]
        lines = sorted(data["line_weights"])
        line_rates = {}
        for line in lines:
            line_rates[line] = sum(matrix_scores[number, line, other] for other in lines) / sum(
                matrix_mass[number, line, other] for other in lines
            )
        if "hard" not in line_rates:
            raise ValueError("missing Hard anchor")
        report["rounds"][key] = {
            "boards": boards,
            "line_weights": data["line_weights"],
            "line_point_rates": line_rates,
            "win_matrix": {
                line: {
                    other: matrix_scores[number, line, other] / matrix_mass[number, line, other]
                    if matrix_mass[number, line, other]
                    else None
                    for other in lines
                }
                for line in lines
            },
            "strongest_line": max(line_rates, key=line_rates.get),
            "hard_floor_passes": max(line_rates.values()) >= line_rates["hard"],
        }
    return report


def file_sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    sample = commands.add_parser("sample")
    sample.add_argument("captures", type=Path, nargs="+")
    sample.add_argument("--out", type=Path, required=True)
    sample.add_argument("--size", type=int, default=64)
    sample.add_argument("--rounds", default=",".join(map(str, ROUNDS)))
    sample.add_argument("--seed", type=int, default=91407)
    report = commands.add_parser("report")
    report.add_argument("field", type=Path)
    report.add_argument("pairs", type=Path)
    report.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "sample":
        result = sample_field(
            boards_from_capture(args.captures), tuple(map(int, args.rounds.split(","))), args.size, args.seed
        )
        result["sources"] = {str(path): file_sha(path) for path in args.captures}
    else:
        with args.pairs.open() as stream:
            result = field_report(json.loads(args.field.read_text()), (json.loads(line) for line in stream))
    args.out.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
