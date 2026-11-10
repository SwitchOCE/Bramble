#!/usr/bin/env python3
"""Report the fixed 32-lobby Stone Soup rollout, with explicit survival denominators."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_EXPECTED = ROOT / "docs/ideation/evidence/wave2b/oozes-final.jsonl"
ENGINE = "line_oozes_engine"
SOUP = "stone_soup"


def read_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def cohort_survival(seats: list[dict], through_round: int) -> dict:
    soup = [
        seat
        for seat in seats
        if seat["first_soup_fielded_round"] is not None and seat["first_soup_fielded_round"] <= through_round
    ]
    other = [seat for seat in seats if seat not in soup]
    result = {}
    for name, group in (("soup", soup), ("other_engine_seats", other)):
        out = sum(seat["out_before_r12"] for seat in group)
        result[name] = {"seats": len(group), "out": out, "rate": out / len(group) if group else None}
    result["cohort"] = f"Soup fielded by R{through_round}"
    return result


def summarize(records: list[dict], expected_seeds: list[int]) -> dict:
    seeds = [int(row["seed"]) for row in records]
    if len(expected_seeds) != 32 or len(set(expected_seeds)) != 32:
        raise ValueError("expected cohort must contain exactly 32 distinct seeds")
    if len(seeds) != 32 or len(set(seeds)) != 32 or set(seeds) != set(expected_seeds):
        raise ValueError("metrics must contain exactly the original 32 seeds, without duplicates")
    engines, all_seats = [], []
    round_rows: dict[int, list[dict]] = {n: [] for n in (6, 8, 10, 12, 14)}
    for record in sorted(records, key=lambda row: int(row["seed"])):
        shopping = record["shopping"]
        if len(shopping) != 8 or len({int(row["seat"]) for row in shopping}) != 8:
            raise ValueError("each lobby must contain eight distinct shopping seats")
        selected = [row for row in shopping if row["assigned_line"] == ENGINE]
        if len(selected) != 1:
            raise ValueError("exactly one engine seat required per lobby")
        engine = selected[0]
        seat = int(engine["seat"])
        snapshots = [row for row in record["pre_start"] if int(row["seat"]) == seat]
        by_round = {}
        for row in snapshots:
            number = int(row["round"])
            if number in by_round:
                raise ValueError("duplicate engine pre-start board in a round")
            by_round[number] = row
        soup_rounds = [number for number, row in by_round.items() if SOUP in row["cards"]]
        first = min(soup_rounds, default=None)
        elimination = engine["elimination_round"]
        elimination = int(elimination) if elimination is not None else None
        if elimination is not None and elimination < max(by_round, default=0):
            raise ValueError("board observed after seat elimination")
        summary = {
            "seed": int(record["seed"]),
            "seat": seat,
            "placement": int(engine["placement"]),
            "elimination_round": elimination,
            "first_soup_fielded_round": first,
            "soup_by_r6": first is not None and first <= 6,
            "soup_before_r12": first is not None and first < 12,
            "out_before_r12": elimination is not None and elimination < 12,
            "reached_r12": 12 in by_round,
            "soup_on_r12_board": SOUP in by_round.get(12, {}).get("cards", []),
        }
        for key in ("offers_by_card", "buys_by_card", "swallows_by_card", "nell_meals_by_card"):
            summary[key] = dict(engine[key])
        engines.append(summary)
        for row in shopping:
            all_seats.append({"seed": int(record["seed"]), **row})
        for number in round_rows:
            if number in by_round:
                round_rows[number].append(by_round[number])
    soup = [seat for seat in engines if seat["soup_before_r12"]]
    rest = [seat for seat in engines if not seat["soup_before_r12"]]
    early = sum(seat["soup_by_r6"] for seat in engines)
    soup_out = sum(seat["out_before_r12"] for seat in soup)
    rest_out = sum(seat["out_before_r12"] for seat in rest)
    soup_rate = soup_out / len(soup) if soup else None
    rest_rate = rest_out / len(rest) if rest else None
    r12 = [seat for seat in engines if seat["reached_r12"]]
    soup_r12 = sum(seat["soup_on_r12_board"] for seat in r12)
    bars = {
        "fielded_by_r6": {"count": early, "denominator": 32, "minimum": 20, "passes": early >= 20},
        "eliminated_before_r12": {
            "soup_cohort": {"seats": len(soup), "out": soup_out, "rate": soup_rate},
            "other_engine_seats": {"seats": len(rest), "out": rest_out, "rate": rest_rate},
            "passes": soup_rate is not None and rest_rate is not None and soup_rate <= rest_rate,
            "qualification": (
                "Descriptive ever-fielded-before-R12 cohorts; exposure is survival-dependent, "
                "not a causal survival estimate."
            ),
        },
        "soup_on_r12_engine_boards": {
            "count": soup_r12,
            "denominator": len(r12),
            "share": soup_r12 / len(r12) if r12 else None,
            "passes": bool(r12) and soup_r12 * 2 >= len(r12),
        },
    }
    rounds = {}
    for number, rows in round_rows.items():
        out = sum(seat["elimination_round"] is not None and seat["elimination_round"] < number for seat in engines)
        rounds[str(number)] = {
            "engine_boards_observed": len(rows),
            "engine_eliminated_before_round": out,
            "engine_without_board_not_eliminated": 32 - len(rows) - out,
            "survivor_median_active_stats": median([row["active_stats"] for row in rows]) if rows else None,
            "survivor_median_including_bellies": median([row["including_bellies"] for row in rows]) if rows else None,
            "soup_boards": sum(SOUP in row["cards"] for row in rows),
        }
    totals = {}
    for key in ("offers_by_card", "buys_by_card", "swallows_by_card", "nell_meals_by_card"):
        counts = Counter()
        for seat in engines:
            counts.update(seat[key])
        totals[key] = dict(sorted(counts.items()))
    return {
        "version": 1,
        "seed_count": 32,
        "seeds": sorted(seeds),
        "engine_seats": len(engines),
        "bars": bars,
        "all_bars_pass": all(row["passes"] for row in bars.values()),
        "cohort_sensitivity": {f"by_r{cutoff}": cohort_survival(engines, cutoff) for cutoff in (6, 10, 11)},
        "cohort_definition": (
            "Engine seats only. Soup cohort ever fielded Stone Soup in combat rounds 1-11; "
            "out before R12 means elimination round <12. R12 prevalence counts actual "
            "pre-start engine boards, not eliminated seats."
        ),
        "survival_definition": (
            "Medians describe observed surviving boards. Eliminations and non-eliminated missing "
            "boards are displayed beside each median; no survivor imputation."
        ),
        "rounds": rounds,
        "engine_card_totals": totals,
        "engine_seat_details": engines,
        "all_seat_details": all_seats,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("metrics", type=Path, nargs="+", help="one or more disjoint .line-metrics.jsonl shards")
    parser.add_argument("--expected", type=Path, default=DEFAULT_EXPECTED)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    records = [row for path in args.metrics for row in read_jsonl(path)]
    expected = [int(row["seed"]) for row in read_jsonl(args.expected)]
    report = summarize(records, expected)
    report["sources"] = {
        str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in [*args.metrics, args.expected]
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(
        json.dumps(
            {"bars": report["bars"], "rounds": report["rounds"], "all_bars_pass": report["all_bars_pass"]}, indent=2
        )
    )


if __name__ == "__main__":
    main()
