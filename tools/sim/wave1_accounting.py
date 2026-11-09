#!/usr/bin/env python3
"""Fixed-seed wave-1 accounting run. Detached/resumable; one bounded Godot per chunk."""

import argparse
import csv
import gzip
import hashlib
import json
import random
import shlex
import statistics
import time
from collections import Counter, defaultdict
from pathlib import Path

from evidence_io import read_json, write_json
from lever_sweep import ROOT, atomic_json, file_sha, run_command, source_manifest
from metrics import percentile

LINES = ("line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court")
ROUNDS = (8, 10, 12, 14)
CONFIG = {
    "pass3_content": True,
    "pass3_loop_guards": True,
    "card_size_caps": False,
    "card_rate_limits": False,
    "tribes_per_lobby": 0,
}
SOURCES = [
    "src",
    "content",
    "tools/sim/*.gd",
    "tools/sim/lines/*.json",
    "tools/sim/line_profiles.committed.json",
    "project.godot",
    "tools/versions.env",
]


def seal_sources():
    return source_manifest(ROOT, SOURCES)


def plan(path, games=640, first_seed=1901001, chunk=20):
    if path.exists():
        raise ValueError("refusing to overwrite a frozen plan")
    pilot = ROOT / "build/sim/wave1-accounting/pilot.log"
    document = {
        "version": 1,
        "games": games,
        "first_seed": first_seed,
        "chunk": chunk,
        "lines": list(LINES),
        "hard_seats": 4,
        "hard_policy": "hard_field: blind Hard recruitment",
        "config": CONFIG,
        "rounds": list(ROUNDS),
        "bootstrap_replicates": 2000,
        "bootstrap_seed": 19014531,
        "source_sha256": seal_sources(),
        "driver_sha256": file_sha(Path(__file__)),
        "created_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "pilot": {"excluded_seeds": [1900001, 1900004], "games": 4, "seconds": 10.6, "log_sha256": file_sha(pilot)},
        "expected_sim_seconds": games * 10.6 / 4,
        "sampling": "One of each committed line plus four blind Hard seats, shuffled independently per seed. All six tribes available; real fights, heroes, finite pool, damage and elimination. Comparisons to fixed authored paper, no shop pairing.",
    }
    atomic_json(path, document)
    return document


def compact_capture(path, first_seed, count):
    rows, seen = [], set()
    rosters = defaultdict(Counter)
    with path.open() as stream:
        for raw in stream:
            record = json.loads(raw)
            seed = record["seed"]
            if not first_seed <= seed < first_seed + count:
                raise ValueError("capture seed outside chunk")
            fight = record["input"]
            for key, expected in CONFIG.items():
                if fight["config"][key] != expected:
                    raise ValueError("wrong runtime configuration: " + key)
            for side, seat in enumerate(fight["player_ids"]):
                if int(seat) < 0:
                    continue
                number = int(fight["round"])
                identity = seed, int(seat), number
                if identity in seen:
                    raise ValueError("duplicate real seat capture")
                seen.add(identity)
                snapshot = record["combat_start"][side]
                assigned = snapshot["assigned_line"]
                if assigned not in (*LINES, "hard_field"):
                    raise ValueError("unexpected assigned policy")
                if number == 1:
                    rosters[seed][assigned] += 1
                allowed = {assigned}
                if assigned == "line_birds_tempo" and number >= 7:
                    allowed.add("line_birds_homecoming")
                if assigned in LINES and str(snapshot["line"]) not in allowed:
                    raise ValueError("committed seat fell back or changed line")
                if 8 <= number <= 14:
                    after = record.get("after_start_effects")
                    rules = fight["fight_rules"][side]
                    rows.append(
                        {
                            "seed": seed,
                            "seat": int(seat),
                            "round": number,
                            "line": assigned,
                            "actual_policy": snapshot["policy"],
                            "stats": snapshot["active_stats"],
                            "post_start_stats": after[side]["active_stats"] if after else None,
                            "tier": fight["tiers"][side],
                            "largest_share": snapshot["largest_share"],
                            "gold_spent": snapshot["gold_spent_game"],
                            "units": snapshot["units"],
                            "ring_size": rules["ring_size"],
                            "slots": fight["slots"][side],
                            "homecomings": rules["homecomings"],
                        }
                    )
    expected_roster = Counter({**dict.fromkeys(LINES, 1), "hard_field": 4})
    if set(rosters) != set(range(first_seed, first_seed + count)) or any(
        r != expected_roster for r in rosters.values()
    ):
        raise ValueError("lobby did not run the declared committed/Hard roster")
    return rows


def run(path):
    document = read_json(path)
    folder = ROOT / "build/sim/wave1-accounting/run"
    folder.mkdir(parents=True, exist_ok=True)
    progress_path = folder / "progress.json"
    status = (
        read_json(progress_path)
        if progress_path.exists()
        else {"plan_sha256": file_sha(path), "state": "running", "completed_lobbies": 0, "chunks": []}
    )
    if status["plan_sha256"] != file_sha(path):
        raise ValueError("progress belongs to another plan")
    config_path = folder / "config.json"
    atomic_json(config_path, document["config"])
    started = time.monotonic()
    try:
        for offset in range(status["completed_lobbies"], document["games"], document["chunk"]):
            if seal_sources() != document["source_sha256"] or file_sha(Path(__file__)) != document["driver_sha256"]:
                raise ValueError("runtime sources changed during frozen run")
            count = min(document["chunk"], document["games"] - offset)
            first = document["first_seed"] + offset
            prefix = folder / f"chunk-{offset:04d}"
            arguments = [
                "godot",
                "--headless",
                "-s",
                "res://tools/sim/bench.gd",
                "--",
                "suite=wave1_accounting",
                f"games={count}",
                f"first_seed={first}",
                "capture=on",
                f"config={config_path}",
                f"out={prefix}",
            ]
            shell = ". /opt/bramble/env.sh && exec " + shlex.join(arguments)
            command = [
                "flock",
                "-w",
                "600",
                "/tmp/bramble-harness-godot.lock",
                "systemd-run",
                "--user",
                "--scope",
                "-q",
                "-p",
                "MemoryMax=3G",
                "timeout",
                "--kill-after=5s",
                "240",
                "bash",
                "-c",
                shell,
            ]
            tick = time.monotonic()
            status.update(state="running", active_first_seed=first, active_count=count)
            atomic_json(progress_path, status)
            run_command(command, prefix.with_suffix(".log"), 850)
            with prefix.with_suffix(".players.csv").open() as stream:
                players = list(csv.DictReader(stream))
            if len(players) != count * 8 or {int(p["seed"]) for p in players} != set(range(first, first + count)):
                raise ValueError("incomplete lobby player records")
            capture = prefix.with_suffix(".fights.jsonl")
            rows = compact_capture(capture, first, count)
            compact = prefix.with_suffix(".boards.json.gz")
            write_json(compact, rows)
            archive = prefix.with_suffix(".fights.jsonl.gz")
            capture_sha = hashlib.sha256()
            with (
                capture.open("rb") as source,
                archive.open("wb") as target,
                gzip.GzipFile(fileobj=target, mode="wb", filename="", mtime=0, compresslevel=3) as output,
            ):
                while block := source.read(1024 * 1024):
                    capture_sha.update(block)
                    output.write(block)
            entry = {
                "first_seed": first,
                "lobbies": count,
                "seconds": time.monotonic() - tick,
                "boards": len(rows),
                "compact": str(compact.relative_to(ROOT)),
                "compact_sha256": file_sha(compact),
                "capture": str(archive.relative_to(ROOT)),
                "capture_sha256": capture_sha.hexdigest(),
                "capture_gzip_sha256": file_sha(archive),
                "players": str(prefix.with_suffix(".players.csv").relative_to(ROOT)),
            }
            capture.unlink()
            status["chunks"].append(entry)
            status.update(completed_lobbies=offset + count, elapsed_this_invocation=time.monotonic() - started)
            atomic_json(progress_path, status)
        status.update(state="complete", active_count=0)
        atomic_json(progress_path, status)
    except BaseException as error:
        status.update(state="failed", error=str(error))
        atomic_json(progress_path, status)
        raise


def measurements(rows, seeds, replicates=2000, bootstrap_seed=19014531):
    """Whole-lobby seed bootstrap, including seeds whose seats died before an endpoint."""
    groups = {seed: defaultdict(list) for seed in seeds}
    for row in rows:
        groups[row["seed"]][row["round"]].append(row["stats"])
    values = {r: [v for seed in seeds for v in groups[seed][r]] for r in ROUNDS}
    medians = {r: statistics.median(v) if v else None for r, v in values.items()}
    rng = random.Random(bootstrap_seed)
    draws, growth = defaultdict(list), []
    for _ in range(replicates):
        selected = rng.choices(seeds, k=len(seeds))
        sample = {r: [v for seed in selected for v in groups[seed][r]] for r in ROUNDS}
        middle = {r: statistics.median(v) if v else None for r, v in sample.items()}
        for r in ROUNDS:
            if middle[r] is not None:
                draws[r].append(middle[r])
        if middle[8] and middle[14]:
            growth.append((middle[14] / middle[8]) ** (1 / 6))
    interval = lambda numbers: [percentile(numbers, 0.025), percentile(numbers, 0.975)] if numbers else None
    return {
        "rounds": {
            str(r): {
                "median": medians[r],
                "ci95": interval(draws[r]),
                "boards": len(values[r]),
                "seed_clusters_with_observations": sum(bool(groups[s][r]) for s in seeds),
                "valid_bootstrap_draws": len(draws[r]),
            }
            for r in ROUNDS
        },
        "preliminary_growth": {
            "formula": "(median_R14/median_R8)**(1/6)",
            "point": (medians[14] / medians[8]) ** (1 / 6) if medians[8] and medians[14] else None,
            "ci95": interval(growth),
        },
        "bootstrap": {
            "seed_clusters": len(seeds),
            "replicates": replicates,
            "rng_seed": bootstrap_seed,
            "method": "percentile whole-lobby seed bootstrap, retaining eliminated empty clusters",
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["plan", "run"])
    parser.add_argument("--plan", type=Path, default=ROOT / "tools/sim/evidence/wave1-accounting-plan.json")
    args = parser.parse_args()
    if args.command == "plan":
        print(json.dumps(plan(args.plan), indent=2))
    else:
        run(args.plan)


if __name__ == "__main__":
    main()
