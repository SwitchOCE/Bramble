"""Fail closed on missing, duplicate or undeclared real-seat capture rounds."""

import csv
import json
from collections import defaultdict


class TrajectoryError(ValueError):
    def __init__(self, errors):
        self.rejected_seeds = sorted({key[0] for key in errors})
        super().__init__("incomplete seat trajectories: " + "; ".join(f"{key}: {why}" for key, why in errors.items()))


def validate_rounds(declared, captured):
    expected, seen, errors = {}, defaultdict(set), {}
    for key, count in declared:
        if key in expected or count < 1:
            errors[key] = "duplicate seat or invalid declared played rounds"
        expected[key] = set(range(1, count + 1))
    groups = defaultdict(set)
    for seed, leg, seat in expected:
        groups[seed, leg].add(seat)
    for (seed, leg), seats in groups.items():
        if seats != set(range(8)):
            errors[seed, leg, -1] = "declared roster must contain exactly seats 0-7"
    for key, number in captured:
        if key not in expected:
            errors[key] = "captured undeclared seat"
        if number in seen[key]:
            errors[key] = f"duplicate round {number}"
        seen[key].add(number)
    for key, rounds in expected.items():
        if seen[key] != rounds:
            errors[key] = f"missing rounds {sorted(rounds - seen[key])}; unexpected rounds {sorted(seen[key] - rounds)}"
    if errors:
        raise TrajectoryError(errors)
    return {"seats": len(expected), "seat_rounds": sum(map(len, seen.values())), "seeds": len(groups)}


def validate_compact(games):
    declared, captured = [], []
    for game in games:
        seed, leg = int(game["seed"]), int(game.get("leg", 0))
        declared.extend(((seed, leg, int(p["seat"])), int(p["rounds"])) for p in game["players"])
        captured.extend(((seed, leg, int(row["seat"])), int(row["round"])) for row in game["rounds"])
    return validate_rounds(declared, captured)


def validate_native(capture, players):
    with players.open(newline="") as stream:
        declared = [
            ((int(p["seed"]), int(p.get("leg") or 0), int(p["seat"])), int(p["rounds"])) for p in csv.DictReader(stream)
        ]

    def frames():
        with capture.open() as stream:
            for raw in stream:
                record = json.loads(raw)
                for seat in record["input"]["player_ids"]:
                    if int(seat) >= 0:
                        yield (int(record["seed"]), int(record.get("leg", 0)), int(seat)), int(record["input"]["round"])

    return validate_rounds(declared, frames())
