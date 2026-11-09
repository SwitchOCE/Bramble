#!/usr/bin/env python3
"""Equal-budget line knob tuning against a frozen all-line field, followed by held-out gain.

Without --run, write only the pre-sized plan. Godot jobs are sequential, memory capped,
and time limited. Each candidate gets a private alias so opponents retain original knobs.
"""

from __future__ import annotations

import argparse
import copy
import csv
import json
import math
import random
import statistics
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROFILES = ROOT / "tools/sim/line_profiles.json"


def variants(profile: dict, count: int, rng: random.Random) -> list[dict]:
    result = [copy.deepcopy(profile)]
    for _ in range(count):
        entry = copy.deepcopy(profile)
        shift = rng.choice([-1, 0, 1])
        entry["climb_schedule"] = [max(2, int(turn) + shift) for turn in entry["climb_schedule"]]
        entry["priority_weight"] *= rng.choice([0.5, 1.0, 1.5])
        entry["save_threshold"] = rng.choice([0, 2, 4]) if entry["engine"] else 0
        result.append(entry)
    return result


def run_case(table: dict, profile: dict, folder: Path, first: int, games: int, limit: int) -> dict:
    folder.mkdir(parents=True, exist_ok=True)
    isolated = copy.deepcopy(table)
    isolated["tune_candidate"] = profile
    profile_path = folder / "profiles.json"
    profile_path.write_text(json.dumps(isolated, indent=2) + "\n")
    prefix = folder / "bench"
    command = [
        "bash",
        "-c",
        'source /opt/bramble/env.sh\nexec systemd-run --user --scope -p MemoryMax=3G timeout "$@"',
        "tune-lines",
        str(limit),
        "godot",
        "--headless",
        "-s",
        "res://tools/sim/bench.gd",
        "--",
        "suite=line_tune",
        "candidate=tune_candidate",
        f"games={games}",
        f"first_seed={first}",
        f"lines={profile_path}",
        f"out={prefix}",
    ]
    started = time.monotonic()
    log = folder / "godot.log"
    with log.open("w") as output:
        subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, check=True, timeout=limit + 30)
    text = log.read_text()
    if "SCRIPT ERROR" in text or "\nERROR:" in text:
        raise RuntimeError(f"Godot logged errors: {log}")
    with Path(f"{prefix}.players.csv").open(newline="") as stream:
        rows = [row for row in csv.DictReader(stream) if row["focus"] == "1"]
    if len(rows) != games or len({row["seed"] for row in rows}) != games:
        raise ValueError(f"incomplete candidate observations: {prefix}")
    places = [int(row["place"]) for row in rows]
    return {
        "mean_place": statistics.mean(places),
        "places": places,
        "lobbies": games,
        "seed_range": [first, first + games - 1],
        "seconds": time.monotonic() - started,
        "fallbacks": sum(row["strategy"] != "tune_candidate" for row in rows),
    }


def gain(before: dict, after: dict) -> dict:
    # Independent samples; no covariance benefit from using equal seed numbers.
    left, right = before["places"], after["places"]
    difference = statistics.mean(left) - statistics.mean(right)
    standard_error = math.sqrt(statistics.variance(left) / len(left) + statistics.variance(right) / len(right))
    return {
        "places": difference,
        "normal_ci95": [difference - 1.96 * standard_error, difference + 1.96 * standard_error],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profiles", type=Path, default=DEFAULT_PROFILES)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--trials", type=int, default=3, help="additional trials per profile, plus its original")
    parser.add_argument("--games-per-trial", type=int, default=2)
    parser.add_argument("--validation-games", type=int, default=4)
    parser.add_argument("--first-seed", type=int, default=31001)
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--run", action="store_true")
    parser.add_argument("--resume", action="store_true", help="reuse complete profiles after checking plan and inputs")
    args = parser.parse_args()
    args.out = args.out.resolve()
    if args.trials < 1 or args.games_per_trial < 2 or args.validation_games < 2:
        parser.error("need at least one extra trial and two games per training/validation sample")
    table = json.loads(args.profiles.read_text())
    tribes = {}
    for profile in table.values():
        tribe = profile["tribe"]
        tribes[tribe] = tribes.get(tribe, 0) + 1
    if any(count != 2 for tribe, count in tribes.items() if tribe):
        parser.error("equal budgets require exactly two profiles per tribe")
    per_profile = (args.trials + 1) * args.games_per_trial + 2 * args.validation_games
    plan = {
        "shop_comparisons": "unpaired",
        "objective": "mean placement of one candidate against seven frozen line seats",
        "trials_per_profile_including_original": args.trials + 1,
        "games_per_trial": args.games_per_trial,
        "validation_games_per_arm": args.validation_games,
        "lobbies_per_tribe": 2 * per_profile,
        "lobbies_total": len(table) * per_profile,
        "seed_range": [args.first_seed, args.first_seed + len(table) * per_profile - 1],
        "interval": "held-out unpaired normal 95% CI; exploratory at small n, not a promotion gate",
    }
    args.out.mkdir(parents=True, exist_ok=True)
    if args.resume and json.loads((args.out / "plan.json").read_text()) != plan:
        raise ValueError("resume plan differs; use a new output directory")
    (args.out / "plan.json").write_text(json.dumps(plan, indent=2) + "\n")
    print(json.dumps(plan, indent=2), flush=True)
    if not args.run:
        return
    started = time.monotonic()
    next_seed = args.first_seed
    rng = random.Random(819)
    selected = copy.deepcopy(table)
    reports = json.loads((args.out / "progress.json").read_text()) if args.resume else {}
    reused = []
    for profile_id, original in table.items():
        entries = variants(original, args.trials, rng)
        if profile_id in reports:
            saved = reports[profile_id]
            previous = json.loads((args.out / profile_id / "trial-0/profiles.json").read_text())
            if (
                previous["tune_candidate"] != original
                or saved["selected_profile"] != entries[saved["selected_trial"]]
                or saved["training"][0]["seed_range"][0] != next_seed
                or saved["validation_selected"]["seed_range"][1] != next_seed + per_profile - 1
            ):
                raise ValueError(f"resume inputs differ: {profile_id}")
            selected[profile_id] = saved["selected_profile"]
            next_seed += per_profile
            reused.append(profile_id)
            continue
        training = []
        for index, entry in enumerate(entries):
            folder = args.out / profile_id / f"trial-{index}"
            training.append(run_case(table, entry, folder, next_seed, args.games_per_trial, args.timeout))
            next_seed += args.games_per_trial
        best = min(range(len(entries)), key=lambda index: training[index]["mean_place"])
        selected[profile_id] = entries[best]
        validation = []
        for label, entry in [("original", original), ("selected", entries[best])]:
            validation.append(
                run_case(table, entry, args.out / profile_id / label, next_seed, args.validation_games, args.timeout)
            )
            next_seed += args.validation_games
        reports[profile_id] = {
            "tribe": original["tribe"],
            "training": training,
            "selected_trial": best,
            "training_gain_places": training[0]["mean_place"] - training[best]["mean_place"],
            "validation_original": validation[0],
            "validation_selected": validation[1],
            "held_out_gain": gain(*validation),
            "selected_profile": entries[best],
        }
        print(profile_id, json.dumps(reports[profile_id]["held_out_gain"]), flush=True)
        (args.out / "progress.json").write_text(json.dumps(reports, indent=2) + "\n")
    active_seconds = sum(
        case["seconds"]
        for report in reports.values()
        for case in [*report["training"], report["validation_original"], report["validation_selected"]]
    )
    result = {
        "plan": plan,
        "seconds": active_seconds,
        "this_invocation_seconds": time.monotonic() - started,
        "reused_profiles": reused,
        "profiles": reports,
    }
    (args.out / "report.json").write_text(json.dumps(result, indent=2) + "\n")
    (args.out / "selected-profiles.json").write_text(json.dumps(selected, indent=2) + "\n")


if __name__ == "__main__":
    main()
