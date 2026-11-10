#!/usr/bin/env python3
"""Recompute the build 8 fit and confirmation from sim-run.sh's compact lobby captures."""

import argparse
import gzip
import json
import math
import statistics
from pathlib import Path

ENGINE = {
    "birds": "line_birds_homecoming",
    "fairies": "line_fairies_ring",
    "bog": "line_bog_court",
    "hunters": "line_hunters_open_season",
    "hedgerow": "line_hedgerow_supper",
    "oozes": "line_oozes_engine",
}


def quantiles(values, qs=(0.1, 0.5, 0.9)):
    values = sorted(values)
    if not values:
        return None
    result = []
    for q in qs:
        position = (len(values) - 1) * q
        low, high = math.floor(position), math.ceil(position)
        result.append(values[low] + (values[high] - values[low]) * (position - low))
    return result


def load(folder):
    summary = json.loads((folder / "summary.json").read_text())
    assert summary["passes"] and not summary["sim_job"]["dropped"]
    with gzip.open(folder / "B.lobbies.json.gz", "rt") as stream:
        lobbies = json.load(stream)
    assert sorted(game["seed"] for game in lobbies) == list(range(2911001, 2911033))
    rows = {}
    assigned = {}
    for game in lobbies:
        for player in game["players"]:
            assigned.setdefault(player["line"], set()).add((game["seed"], player["seat"]))
        for row in game["rounds"]:
            key = (game["seed"], row["seat"])
            by_seat = rows.setdefault(row["line"], {}).setdefault(key, {})
            assert row["round"] not in by_seat
            by_seat[row["round"]] = row["stats"]
    assert len(assigned) == 12 and all(21 <= len(ids) <= 22 for ids in assigned.values())
    return rows, assigned


def fit(arms):
    result = {}
    for tribe, line in ENGINE.items():
        common = set.intersection(*(set(key for key, rounds in arm[0][line].items() if 12 in rounds) for arm in arms))
        assert common, line
        points = [statistics.median(arm[0][line][key][12] for key in common) for arm in arms]
        logs = [math.log(value) for value in points]
        slope = sum((t - 1.5) * value for t, value in enumerate(logs)) / 5.0
        intercept = statistics.mean(logs) - 1.5 * slope
        raw = (math.log(900) - intercept) / slope if slope > 0 else None
        chosen = 3.0 if raw is None else min(3.0, max(0.0, math.ceil(raw * 4 - 1e-9) / 4))
        result[tribe] = {
            "engine_line": line,
            "common_r12_seats": len(common),
            "points": points,
            "all_alive_points": [quantiles([rs[12] for rs in arm[0][line].values() if 12 in rs])[1] for arm in arms],
            "log_intercept": None if tribe == "oozes" else intercept,
            "log_slope": None if tribe == "oozes" else slope,
            "raw_t": None if tribe == "oozes" else raw,
            "chosen_t": 0.0 if tribe == "oozes" else chosen,
            "weak_responding": tribe != "oozes" and (raw is None or raw > 3),
            "fixed_b": tribe == "oozes",
        }
    return result


def confirmation(arm, baseline):
    result = {}
    for line, seats in sorted(arm[0].items()):
        r12 = [rounds[12] for rounds in seats.values() if 12 in rounds]
        growth = [(rs[14] / rs[8]) ** (1 / 6) for rs in seats.values() if 8 in rs and 14 in rs and rs[8] > 0]
        late = [rs for rs in seats.values() if 12 in rs and 15 in rs]
        old_seats = baseline[0][line]
        common = [key for key in seats if 12 in seats[key] and 12 in old_seats.get(key, {})]
        old_p10 = quantiles([old_seats[key][12] for key in common])[0] if common else None
        new_p10 = quantiles([seats[key][12] for key in common])[0] if common else None
        spread = quantiles(r12)
        result[line] = {
            "r12": spread,
            "growth_r8_r14": quantiles(growth),
            "growth_n": len(growth),
            "alive_r12": len(r12),
            "assigned": len(arm[1][line]),
            "alive_r12_share": len(r12) / len(arm[1][line]),
            "r15_div_r12": statistics.median(rs[15] for rs in late) / statistics.median(rs[12] for rs in late)
            if late
            else None,
            "r15_div_r12_seat_median": statistics.median(rs[15] / rs[12] for rs in late) if late else None,
            "late_n": len(late),
            "tail_flag": spread[2] > 10 * spread[1],
            "p10_low_flag": spread[0] < 0.25 * spread[1],
            "p10_regression_flag": new_p10 < old_p10 if common else None,
            "baseline_common_p10": old_p10,
            "confirm_common_p10": new_p10,
            "baseline_common_n": len(common),
            "rounds": {
                str(r): {
                    "alive_n": sum(r in rs for rs in seats.values()),
                    "alive_p10_p25_p50_p75_p90": quantiles(
                        [rs[r] for rs in seats.values() if r in rs], (0.1, 0.25, 0.5, 0.75, 0.9)
                    ),
                    "r14_cohort_p10_p25_p50_p75_p90": quantiles(
                        [rs[r] for rs in seats.values() if r in rs and 14 in rs], (0.1, 0.25, 0.5, 0.75, 0.9)
                    ),
                }
                for r in range(6, 16)
            },
        }
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sim-root", type=Path, default=Path("build/sim"))
    parser.add_argument("--confirmation", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    arms = [load(args.sim_root / f"a35-run1-t{t}-20261110") for t in range(4)]
    result = {"fits": fit(arms)}
    if args.confirmation:
        result["confirmation"] = confirmation(load(args.confirmation), arms[0])
        result["missed_675"] = [tribe for tribe, line in ENGINE.items() if result["confirmation"][line]["r12"][1] < 675]
    args.out.write_text(json.dumps(result, indent=2, allow_nan=False) + "\n")


if __name__ == "__main__":
    main()
