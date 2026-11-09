#!/usr/bin/env python3
"""Conditional designed-board win rates with independent paired-seed intervals.

Every independent seed contributes both orientations. Hoeffding's bound treats
that pair as one bounded observation, not two independent fights. Intervals cover
combat RNG for these exact boards/layouts, not a population of player boards.
"""

from __future__ import annotations

import argparse
import json
import math
from itertools import combinations
from pathlib import Path


def interval(mean, independent_seeds, alpha=0.05):
    if independent_seeds <= 0 or not 0 < alpha < 1:
        raise ValueError("positive independent-seed count and alpha in (0,1) required")
    radius = math.sqrt(math.log(2 / alpha) / (2 * independent_seeds))
    return [max(0.0, mean - radius), min(1.0, mean + radius)]


def _design(board):
    design = board.get("design")
    if not isinstance(design, dict):
        raise ValueError("each board needs explicit design metadata")
    required = ("scale", "distribution", "keywords", "answer", "target_total", "realized_total", "bodies")
    if any(key not in design for key in required):
        raise ValueError("incomplete design metadata")
    if not isinstance(design["keywords"], list) or any(not isinstance(k, str) for k in design["keywords"]):
        raise ValueError("design keywords must be a list of strings")
    for key in ("target_total", "realized_total", "bodies"):
        if type(design[key]) is not int or design[key] <= 0:
            raise ValueError(f"design {key} must be a positive integer")
    return design


def summarize(field, rows, reps=64):
    if type(reps) is not int or reps < 1:
        raise ValueError("reps must be a positive integer")
    if not isinstance(field.get("rounds"), dict) or not field["rounds"]:
        raise ValueError("field needs nonempty rounds")
    expected, boards = {}, {}
    for number, data in field["rounds"].items():
        if not isinstance(data.get("boards"), list) or len(data["boards"]) < 2:
            raise ValueError("each round needs at least two boards")
        ids = []
        for board in data["boards"]:
            identifier = board.get("id")
            if not isinstance(identifier, str) or not identifier or (int(number), identifier) in boards:
                raise ValueError("board IDs must be unique nonempty strings within each round")
            _design(board)
            boards[int(number), identifier] = board
            ids.append(identifier)
        for a, b in combinations(ids, 2):
            expected[int(number), a, b] = {}
    for row in rows:
        if type(row.get("round")) is not int:
            raise ValueError("round must be an integer")
        if not isinstance(row.get("a"), str) or not isinstance(row.get("b"), str):
            raise ValueError("pair board IDs must be strings")
        key = (row["round"], row["a"], row["b"])
        if key not in expected:
            raise ValueError("unexpected pair or orientation")
        rep = row.get("replicate")
        if type(rep) is not int or not 0 <= rep < reps or rep in expected[key]:
            raise ValueError("duplicate or invalid replicate")
        seed = row.get("seed")
        try:
            canonical_seed = isinstance(seed, str) and str(int(seed)) == seed and -(2**63) <= int(seed) < 2**63
        except ValueError:
            canonical_seed = False
        if not canonical_seed:
            raise ValueError("seed must be a canonical signed-64-bit integer string")
        for name in ("wins_a", "wins_b", "draws", "trials"):
            if type(row.get(name)) is not int or not 0 <= row[name] <= 2:
                raise ValueError("outcomes must be integer paired-orientation counts")
        if row["trials"] != 2 or row["wins_a"] + row["wins_b"] + row["draws"] != 2:
            raise ValueError("each independent seed must contain exactly both orientations")
        expected[key][rep] = row
    pairs, indexed = [], {}
    for (number, a, b), observations in expected.items():
        if set(observations) != set(range(reps)):
            raise ValueError("missing replicate; complete frozen round robin required")
        if len({row["seed"] for row in observations.values()}) != reps:
            raise ValueError("independent seeds must be distinct within a pair")
        count = 2 * reps
        wins_a = sum(row["wins_a"] for row in observations.values())
        wins_b = sum(row["wins_b"] for row in observations.values())
        draws = sum(row["draws"] for row in observations.values())
        result = {
            "round": number,
            "a": a,
            "b": b,
            "independent_seeds": reps,
            "fights": count,
            "wins_a": wins_a,
            "wins_b": wins_b,
            "draws": draws,
            "win_rate_a": wins_a / count,
            "win_rate_b": wins_b / count,
            "win_rate_a_ci95": interval(wins_a / count, reps),
            "win_rate_b_ci95": interval(wins_b / count, reps),
            "point_rate_a": (wins_a + 0.5 * draws) / count,
            "point_rate_a_ci95": interval((wins_a + 0.5 * draws) / count, reps),
            "draw_rate": draws / count,
        }
        pairs.append(result)
        indexed[number, a, b] = result
        indexed[number, b, a] = {
            **result,
            "a": b,
            "b": a,
            "wins_a": wins_b,
            "wins_b": wins_a,
            "win_rate_a": result["win_rate_b"],
            "win_rate_b": result["win_rate_a"],
            "win_rate_a_ci95": result["win_rate_b_ci95"],
            "win_rate_b_ci95": result["win_rate_a_ci95"],
            "point_rate_a": (wins_b + 0.5 * draws) / count,
            "point_rate_a_ci95": interval((wins_b + 0.5 * draws) / count, reps),
        }
    groups, boundary = {}, []
    for number, data in field["rounds"].items():
        for carry in data["boards"]:
            cd = carry["design"]
            if cd["distribution"] != "carry":
                continue
            for wide in data["boards"]:
                wd = wide["design"]
                if wd["distribution"] != "even":
                    continue
                result = indexed[int(number), carry["id"], wide["id"]]
                if cd["scale"] == "boundary" or wd["scale"] == "boundary":
                    boundary.append({"carry": carry["id"], "wide": wide["id"], **result})
                    continue
                if (
                    cd["scale"] != wd["scale"]
                    or sorted(cd["keywords"]) != sorted(wd["keywords"])
                    or cd["target_total"] != wd["target_total"]
                    or cd["realized_total"] != wd["realized_total"]
                ):
                    continue
                key = (int(number), cd["scale"], tuple(sorted(cd["keywords"])), cd["target_total"])
                entry = groups.setdefault(
                    key,
                    {
                        "round": int(number),
                        "scale": cd["scale"],
                        "keywords": list(key[2]),
                        "total": key[3],
                        "comparisons": {},
                    },
                )
                combo = f"carry={cd['answer']};wide={wd['answer']}"
                if combo in entry["comparisons"]:
                    raise ValueError("ambiguous duplicate designed matchup")
                entry["comparisons"][combo] = {
                    "carry": carry["id"],
                    "wide": wide["id"],
                    "carry_win_rate": result["win_rate_a"],
                    "ci95": result["win_rate_a_ci95"],
                    "draw_rate": result["draw_rate"],
                }
    return {
        "version": 1,
        "interval_method": "two-sided 95% distribution-free Hoeffding bound on independent paired-seed observations",
        "interval_scope": "conditional combat-RNG uncertainty for these exact boards and blind layouts; not board-population uncertainty",
        "orientation_dependency": "two orientations share one seed and count as one bounded observation",
        "limitations": "Conservative intervals remain nonzero-width at 0/1. Fixed boards are designed examples, not representative frequencies; keywords are not gold-cost matched. Requested and realized totals expose the engine stat clamp. Per-pair intervals are not simultaneous family bounds.",
        "replicates_per_pair": reps,
        "pairs": pairs,
        "fights": sum(pair["fights"] for pair in pairs),
        "matched_carry_vs_even": [groups[key] for key in sorted(groups)],
        "boundary_comparisons": boundary,
        "board_designs": [
            {"round": number, "id": identifier, **board["design"]} for (number, identifier), board in boards.items()
        ],
    }


def markdown(report):
    lines = [
        "# First designed field",
        "",
        report["interval_method"] + ".",
        "",
        report["interval_scope"] + ". " + report["orientation_dependency"] + ".",
        "",
        report["limitations"],
        "",
        f"{report['fights']:,} fights; {report['replicates_per_pair']} independent seeds per pair, both orientations.",
        "",
        "Cells show carry strict-win rate [95% interval]; draws count separately, not as wins.",
        "",
        "| Round | Scale | Total | Keywords | Neither answer | Wide answer only | Carry answer only | Both answers |",
        "|---|---|---:|---|---|---|---|---|",
    ]
    for row in report["matched_carry_vs_even"]:
        cells = []
        for carry, wide in [("none", "none"), ("none", "biggest"), ("biggest", "none"), ("biggest", "biggest")]:
            value = row["comparisons"].get(f"carry={carry};wide={wide}")
            if value is None:
                cells.append("—")
                continue
            lo, hi = value["ci95"]
            cell = f"{value['carry_win_rate']:.1%} [{lo:.1%}, {hi:.1%}]"
            if value["draw_rate"]:
                cell += f"; draws {value['draw_rate']:.1%}"
            cells.append(cell)
        lines.append(
            f"| {row['round']} | {row['scale']} | {row['total']:,} | {', '.join(row['keywords']) or 'none'} | "
            + " | ".join(cells)
            + " |"
        )
    if report["boundary_comparisons"]:
        lines += [
            "",
            "## Clamp-boundary comparisons",
            "",
            "Requested values above the per-stat engine maximum are not literal realizations. See board_designs in the JSON for requested and realized totals.",
            "",
            "| Carry | Wide | Carry win rate | 95% interval | Draws |",
            "|---|---|---:|---|---:|",
        ]
        for value in report["boundary_comparisons"]:
            lo, hi = value["win_rate_a_ci95"]
            lines.append(
                f"| {value['carry']} | {value['wide']} | {value['win_rate_a']:.1%} | [{lo:.1%}, {hi:.1%}] | {value['draw_rate']:.1%} |"
            )
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("field", type=Path)
    parser.add_argument("trials", type=Path)
    parser.add_argument("--reps", type=int, default=64)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--markdown", type=Path)
    args = parser.parse_args()
    with args.trials.open() as stream:
        report = summarize(
            json.loads(args.field.read_text()), (json.loads(line) for line in stream if line.strip()), args.reps
        )
    args.out.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    if args.markdown:
        args.markdown.write_text(markdown(report))
    print(json.dumps({"pairs": len(report["pairs"]), "fights": report["fights"]}))


if __name__ == "__main__":
    main()
