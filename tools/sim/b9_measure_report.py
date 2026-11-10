#!/usr/bin/env python3
"""Report a build 9 line-lobby preset sample, without fitting or changing rates."""

import argparse
import gzip
import json
import math
import statistics
from pathlib import Path

ENGINES = {
    "birds": "line_birds_homecoming",
    "fairies": "line_fairies_ring",
    "bog": "line_bog_court",
    "hunters": "line_hunters_open_season",
    "hedgerow": "line_hedgerow_supper",
    "oozes": "line_oozes_engine",
}


def quantiles(values, probabilities=(0.1, 0.5, 0.9)):
    ordered = sorted(values)
    if not ordered:
        return None
    out = []
    for probability in probabilities:
        at = (len(ordered) - 1) * probability
        lo, hi = math.floor(at), math.ceil(at)
        out.append(ordered[lo] + (ordered[hi] - ordered[lo]) * (at - lo))
    return out


def summarize(folder, preset="C", expected_seeds=None):
    summary = json.loads((folder / "summary.json").read_text())
    assert summary["passes"] and not summary["sim_job"]["dropped"]
    with gzip.open(folder / f"{preset}.lobbies.json.gz", "rt") as stream:
        games = json.load(stream)
    expected_seeds = list(range(2911001, 2911033)) if expected_seeds is None else expected_seeds
    assert sorted(game["seed"] for game in games) == expected_seeds
    by_line, assigned, caps = {}, {}, []
    for game in games:
        for player in game["players"]:
            assigned.setdefault(player["line"], set()).add((game["seed"], player["seat"]))
        for row in game["rounds"]:
            seat = by_line.setdefault(row["line"], {}).setdefault((game["seed"], row["seat"]), {})
            assert row["round"] not in seat
            seat[row["round"]] = row["stats"]
            for unit in row["units"]:
                if unit["attack"] >= 10**9 or unit["health"] >= 10**9:
                    caps.append(
                        {
                            "seed": game["seed"],
                            "seat": row["seat"],
                            "line": row["line"],
                            "round": row["round"],
                            "unit": unit,
                        }
                    )
    low, remainder = divmod(len(games) * 8, 12)
    assert len(assigned) == 12 and all(low <= len(seats) <= low + bool(remainder) for seats in assigned.values())
    lines = {}
    for line, seats in sorted(by_line.items()):
        r12 = [rs[12] for rs in seats.values() if 12 in rs]
        growth = [(rs[14] / rs[8]) ** (1 / 6) for rs in seats.values() if 8 in rs and 14 in rs and rs[8] > 0]
        late = [rs for rs in seats.values() if 12 in rs and 15 in rs]
        spread = quantiles(r12)
        lines[line] = {
            "r12": spread,
            "growth_r8_r14": quantiles(growth),
            "growth_n": len(growth),
            "assigned": len(assigned[line]),
            "alive_r12": len(r12),
            "alive_r12_share": len(r12) / len(assigned[line]),
            "r15_div_r12": statistics.median(rs[15] for rs in late) / statistics.median(rs[12] for rs in late)
            if late and statistics.median(rs[12] for rs in late) > 0
            else None,
            "r15_div_r12_seat_median": statistics.median(rs[15] / rs[12] for rs in late) if late else None,
            "late_n": len(late),
            "tail_flag": spread[2] > 10 * spread[1] if spread else None,
            "p10_low_flag": spread[0] < 0.25 * spread[1] if spread else None,
            "rounds": {
                str(r): {
                    "alive_n": sum(r in rs for rs in seats.values()),
                    "alive_share": sum(r in rs for rs in seats.values()) / len(assigned[line]),
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
    target = 1800 if preset == "C" else 900
    scale = {
        tribe: lines[line]["r12"] is not None and 0.75 * target <= lines[line]["r12"][1] <= 2 * target
        for tribe, line in ENGINES.items()
    }
    growth = {line: row["growth_r8_r14"] is not None and row["growth_r8_r14"][1] >= 1.3 for line, row in lines.items()}
    return {
        "preset": preset,
        "provisional_fit": True,
        "confirmation": lines,
        "decides": {
            "engine_r12_in_target_band": scale,
            "growth_at_least_1_3": growth,
            "scale_passes": all(scale.values()),
            "growth_passes": all(growth.values()),
        },
        "stat_cap_hits": caps,
        "sim_job": summary["sim_job"],
    }


def table(result):
    def spread(values):
        return " / ".join(f"{value:,.3f}" for value in values) if values else "—"

    rows = [
        "| Committed line | R12 A+H p10 / median / p90 | R8-R14 growth x/round p10 / median / p90 "
        "| Growth n | R15 ÷ R12 (n) | Alive R12 |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for line, row in result["confirmation"].items():
        late = f"{row['r15_div_r12']:.3f} ({row['late_n']})" if row["r15_div_r12"] is not None else "—"
        rows.append(
            f"| {line.removeprefix('line_')} | {spread(row['r12'])} | {spread(row['growth_r8_r14'])} "
            f"| {row['growth_n']} | {late} | {row['alive_r12']}/{row['assigned']} ({row['alive_r12_share']:.1%}) |"
        )
    return "\n".join(rows) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("result_dir", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--preset", choices=["B", "C"], default="C")
    parser.add_argument("--first-seed", type=int, default=2911001)
    parser.add_argument("--lobbies", type=int, default=64)
    args = parser.parse_args()
    result = summarize(
        args.result_dir, preset=args.preset, expected_seeds=list(range(args.first_seed, args.first_seed + args.lobbies))
    )
    args.out.write_text(json.dumps(result, indent=2, allow_nan=False) + "\n")
    print(table(result))


if __name__ == "__main__":
    main()
