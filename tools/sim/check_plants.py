#!/usr/bin/env python3
"""Known answers: real inert null/reference bodies agree; a planted engine dominates.

The first prefix must contain bench_reference, not an empty no-intervention arm.
Cross-arm comparisons normalize only the two control ids/policy labels and omit
only the top-level events_sha256. Each arm must also pass exact refight separately:
raw event hashes differ because definition ids are included in combat events.
"""

import argparse
import csv
import json
import statistics
from itertools import zip_longest
from pathlib import Path

from field import boards_from_capture

CONTROL_NAMES = {"bench_null": "bench_reference", "plant_null": "plant_reference"}


def _normalise(value):
    if isinstance(value, str):
        return CONTROL_NAMES.get(value, value)
    if isinstance(value, list):
        return [_normalise(item) for item in value]
    if isinstance(value, dict):
        return {_normalise(key): _normalise(item) for key, item in value.items()}
    return value


def _normalise_record(record):
    # Do not discard outcomes, seeds, RNG state, config, snapshots or any other hash.
    return _normalise({key: value for key, value in record.items() if key != "events_sha256"})


def _contains_unit(value, card_id):
    if isinstance(value, dict):
        return value.get("def_id") == card_id or any(_contains_unit(item, card_id) for item in value.values())
    if isinstance(value, list):
        return any(_contains_unit(item, card_id) for item in value)
    return False


def _inert_card(card, card_id):
    return (
        card.get("id") == card_id
        and card.get("attack") == 1
        and card.get("health") == 1
        and card.get("tier") == 1
        and card.get("set") == "slice"
        and card.get("text") == ""
        and card.get("golden_text") == ""
        and card.get("mechanics") == []
        and card.get("keywords") == []
        and card.get("tribes") == []
        and type(card.get("pool")) is bool
    )


def _csv_rows(prefix, part):
    with Path(f"{prefix}.{part}.csv").open(newline="") as stream:
        return list(csv.reader(stream))


def compare_null(reference, null):
    """Compare complete deterministic outputs and prove both real controls were exercised."""
    exact = {
        f"{part}.csv": _normalise(_csv_rows(reference, part)) == _normalise(_csv_rows(null, part))
        for part in ("players", "rounds", "cards")
    }
    validation = {
        arm: {
            "captured_fights": 0,
            "inert_definition_in_every_record": True,
            "present_in_fight_input": False,
            "event_hash_in_every_record": True,
        }
        for arm in ("reference", "null")
    }
    fights_equal = True
    with Path(f"{reference}.fights.jsonl").open() as ref_stream, Path(f"{null}.fights.jsonl").open() as null_stream:
        # Stream captures: full lobby event-boundary records can be large.
        for ref_line, null_line in zip_longest(ref_stream, null_stream):
            records = []
            for arm, line, card_id in (("reference", ref_line, "bench_reference"), ("null", null_line, "bench_null")):
                if line is None:
                    records.append(None)
                    continue
                record = json.loads(line)
                records.append(record)
                state = validation[arm]
                state["captured_fights"] += 1
                definitions = [card for card in record.get("test_cards", []) if card.get("id") == card_id]
                state["inert_definition_in_every_record"] &= len(definitions) == 1 and _inert_card(
                    definitions[0], card_id
                )
                state["present_in_fight_input"] |= _contains_unit(record.get("input", {}), card_id)
                digest = record.get("events_sha256")
                state["event_hash_in_every_record"] &= (
                    isinstance(digest, str) and len(digest) == 64 and all(char in "0123456789abcdef" for char in digest)
                )
            fights_equal &= all(record is not None for record in records) and (
                _normalise_record(records[0]) == _normalise_record(records[1])
            )
    exact["fights.jsonl"] = fights_equal
    valid = all(
        state["captured_fights"] > 0
        and state["inert_definition_in_every_record"]
        and state["present_in_fight_input"]
        and state["event_hash_in_every_record"]
        for state in validation.values()
    )
    return {"null_exact": exact, "null_validation": validation, "passes": all(exact.values()) and valid}


def check(control, null, broken, field):
    comparison = compare_null(control, null)
    with Path(f"{broken}.players.csv").open(newline="") as stream:
        planted = [row for row in csv.DictReader(stream) if row["seat"] == "0"]
    by_game = {}
    for board in boards_from_capture([Path(f"{broken}.fights.jsonl")]):
        if board["round"] == 6:
            by_game.setdefault(board["seed"], []).append(board)
    tails = []
    for boards in by_game.values():
        median = statistics.median(b["combat_start"]["active_stats"] for b in boards)
        tails.extend(b["combat_start"]["active_stats"] >= 2 * median for b in boards if b["line"] == "plant_engine")
    rates = [row["line_point_rates"]["plant_engine"] for row in field["rounds"].values()]
    win_rate = sum(int(row["place"]) == 1 for row in planted) / len(planted) if planted else 0
    return {
        "null_exact": comparison["null_exact"],
        "null_validation": comparison["null_validation"],
        "broken_lobbies": len(planted),
        "broken_win_rate": win_rate,
        "round6_planted_boards": len(tails),
        "round6_tail_boards": sum(tails),
        "field_point_rates": rates,
        "passes": comparison["passes"]
        and len(planted) >= 8
        and len(tails) == len(planted)
        and all(tails)
        and win_rate >= 0.75
        and bool(rates)
        and min(rates) >= 0.8,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["control", "null", "broken"]:
        parser.add_argument(name, type=Path)
    parser.add_argument("--field", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    report = check(args.control, args.null, args.broken, json.loads(args.field.read_text()))
    args.out.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report["passes"] else 1)


if __name__ == "__main__":
    main()
