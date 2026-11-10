#!/usr/bin/env python3
"""Prepare or run four isolated Pot Luck policy arms; gameplay sources stay unchanged.

Prepare after committing common fixes. Run with the same explicit --commit and --out.
Only `run` starts Godot; --detach launches a detached outer runner with its own log.
"""

import argparse
import copy
import hashlib
import json
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

try:
    from .wave2b_growth_report import load_records, load_strategies, summarize
except ImportError:
    from wave2b_growth_report import load_records, load_strategies, summarize

ARMS = ("control", "A", "B", "AB")
TEMPO = "line_oozes_tempo"
SEED_FILE = "docs/ideation/evidence/wave2b/oozes-summary.json"


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, allow_nan=False) + "\n", encoding="utf-8")


def head(root):
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()


def source_manifest(root, excluded=None):
    root = Path(root).resolve()
    excluded = Path(excluded).resolve() if excluded else None
    paths = [root / "project.godot", root / SEED_FILE]
    for directory in ("src", "content", "tools/sim"):
        paths.extend(
            path
            for path in (root / directory).rglob("*")
            if path.is_file() and path.suffix in {".gd", ".py", ".json", ".sh"}
        )
    return {
        str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(paths)
        if path.is_file() and (excluded is None or not path.is_relative_to(excluded))
    }


def arm_policy(original, arm):
    result = copy.deepcopy(original)
    tempo = result[TEMPO]
    if arm in ("A", "AB"):
        tempo["save_threshold"], tempo["save_until"] = 3, 10
    if arm in ("B", "AB"):
        key = "priority" if "priority" in tempo else "buy_priority"
        priority = tempo[key]
        priority.remove("little_dollop")
        priority.insert(3, "little_dollop")
    return result


def prepare(root, out, commit):
    if head(root) != commit:
        raise ValueError("HEAD differs from the required full commit SHA")
    if out.exists():
        raise ValueError(f"output already exists: {out}; choose a fresh directory")
    expected = json.loads((root / SEED_FILE).read_text())["seeds"]
    if len(expected) != 32 or len(set(expected)) != 32 or expected[0] != 280001:
        raise ValueError("historical seed list must contain the 32 distinct source seeds from 280001")
    original = json.loads((root / "tools/sim/lines/oozes.json").read_text())
    tempo = original[TEMPO]
    priority = tempo.get("priority", tempo.get("buy_priority"))
    if (tempo["save_threshold"], tempo["save_until"], priority.index("little_dollop")) != (0, 0, 12):
        raise ValueError("control is not the declared save0/until0/Dollop-rank13 route")
    out.mkdir(parents=True)
    for arm in ARMS:
        folder = out / arm
        folder.mkdir()
        shutil.copytree(root / "tools/sim/lines", folder / "lines")
        write_json(folder / "lines/oozes.json", arm_policy(original, arm))
    write_json(out / "config.json", {"pass3_preset": "B"})
    manifest = source_manifest(root, out)
    plan = {
        "commit": commit,
        "source_manifest": manifest,
        "config_sha256": hashlib.sha256((out / "config.json").read_bytes()).hexdigest(),
        "expected_seeds": expected,
        "arms": list(ARMS),
        "dollop_rank": 4,
        "reading": (
            "B promotes Dollop for early R1-4 availability; static rank4 is a declared intervention, "
            "not an exact paper order."
        ),
        "policy_hashes": {
            arm: {
                str(path.relative_to(out / arm / "lines")): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in sorted((out / arm / "lines").rglob("*.json"))
            }
            for arm in ARMS
        },
    }
    write_json(out / "plan.json", plan)
    return plan


def verify_pin(root, out, plan):
    if head(root) != plan["commit"]:
        raise ValueError("source HEAD changed; aborting")
    current = source_manifest(root, out)
    if current != plan["source_manifest"]:
        changed = sorted(
            key
            for key in current.keys() | plan["source_manifest"].keys()
            if current.get(key) != plan["source_manifest"].get(key)
        )
        raise ValueError(f"source files changed; aborting: {changed}")
    if hashlib.sha256((out / "config.json").read_bytes()).hexdigest() != plan["config_sha256"]:
        raise ValueError("prepared B config changed")
    for arm, hashes in plan["policy_hashes"].items():
        current_hashes = {
            str(path.relative_to(out / arm / "lines")): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted((out / arm / "lines").rglob("*.json"))
        }
        if hashes != current_hashes:
            raise ValueError(f"prepared policy directory changed: {arm}")


def exact_seeds(records, expected):
    actual = [record["seed"] for record in records]
    if actual != expected:
        raise ValueError(f"scanner seed list mismatch: expected {expected}; got {actual}")


def command(root, out, arm, games, env_script, godot, pilot=False):
    prefix = out / arm / ("pilot" if pilot else "bench")
    return [
        "bash",
        "-c",
        'set -e\nsource "$1"\nshift\nexec "$@"',
        "potluck-arm",
        str(env_script),
        "flock",
        "/tmp/bramble-harness-godot.lock",
        "systemd-run",
        "--user",
        "--scope",
        "-q",
        "-p",
        "MemoryMax=3G",
        godot,
        "--headless",
        "--path",
        str(root),
        "-s",
        "res://tools/sim/wave2b_lines.gd",
        "--",
        "suite=lines",
        "tribe=Oozes",
        f"games={games}",
        "first_seed=280001",
        f"out={prefix}",
        f"lines={out / arm / 'lines'}",
        "capture=on",
        f"config={out / 'config.json'}",
    ]


def run_process(root, out, plan, arm, args, pilot=False):
    verify_pin(root, out, plan)
    name = "pilot" if pilot else "bench"
    argv = command(root, out, arm, 2 if pilot else 32, args.env_script, args.godot, pilot)
    meta = {
        "commit": plan["commit"],
        "arm": arm,
        "pilot": pilot,
        "command": argv,
        "started_unix": time.time(),
        "status": "running",
    }
    path = out / arm / f"{name}.exit.json"
    write_json(path, meta)
    started = time.monotonic()
    with (out / arm / f"{name}.log").open("w", encoding="utf-8") as log:
        result = subprocess.run(argv, cwd=root, stdout=log, stderr=subprocess.STDOUT, check=False)
    meta.update(
        exit_code=result.returncode,
        seconds=time.monotonic() - started,
        status="complete" if result.returncode == 0 else "failed",
    )
    try:
        verify_pin(root, out, plan)
        if result.returncode:
            raise ValueError(f"{arm} {name} exited {result.returncode}; inspect its log")
        records = load_records([out / arm / f"{name}.line-metrics.jsonl"])
        exact_seeds(records, plan["expected_seeds"][:2] if pilot else plan["expected_seeds"])
    except (OSError, ValueError) as error:
        meta.update(status="invalid", error=str(error))
        write_json(path, meta)
        raise
    write_json(path, meta)
    print(f"{arm} {name}: {meta['seconds']:.1f}s; exit={result.returncode}", flush=True)
    return records, meta


def comparison(reports, seats=32):
    output = {}
    for arm, report in reports.items():
        line = report["lines"][TEMPO]
        output[arm] = {
            "primary_matched_r14_median_growth": line["paired_r14_survivors"]["metrics"]["active_stats"][
                "matched_medians_growth"
            ],
            "median_individual_growth_diagnostic": line["paired_r14_survivors"]["metrics"]["active_stats"][
                "median_individual_growth"
            ],
            "survivor_median_growth": line["endpoint_growth"]["active_stats"],
            "survivor_counts": line["survivor_counts"],
            "r14_share_observed": line["survivor_counts"]["r14"] / seats,
            "r12": line["rounds"]["12"],
            "paired_raw_rows": line["paired_r14_survivors"]["raw_rows"],
        }
    return {
        "counting": (
            "R14 share means observed entering the R14 bell, not inferred final winners. Primary growth "
            "uses each arm's own matched R8/R14 cohort; arms can have different survivors. All arms use "
            "the same 32 source seeds. Individual growth is diagnostic."
        ),
        "arms": output,
    }


def run(root, out, args):
    plan = json.loads((out / "plan.json").read_text())
    if args.commit != plan["commit"]:
        raise ValueError("--commit differs from prepared plan")
    verify_pin(root, out, plan)
    pilot, meta = run_process(root, out, plan, "control", args, pilot=True)
    # Pilot elapsed time includes harness lock waiting; conservative projection is intentional.
    projection = max(meta["seconds"], sum(row.get("seconds", 0) for row in pilot)) * 64
    write_json(
        out / "projection.json",
        {"projected_four_arm_minutes": projection / 60, "pilot_seconds": meta["seconds"], "limit_minutes": 60},
    )
    print(f"Projected four-arm time: {projection / 60:.1f} minutes", flush=True)
    if projection > 3600:
        raise ValueError("projection exceeds 60 minutes; report timing and stop before full arms")
    reports = {}
    for arm in ARMS:
        records, _meta = run_process(root, out, plan, arm, args)
        reports[arm] = summarize(records, load_strategies(root / "content/bots/strategies"))
        write_json(out / arm / "growth-report.json", reports[arm])
        write_json(out / "comparison.json", comparison(reports))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "run"))
    parser.add_argument("--commit", required=True, help="Full final pinned SHA; never inferred")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--env-script", type=Path, default=Path("/opt/bramble/env.sh"))
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--detach", action="store_true")
    args = parser.parse_args()
    root, out = args.root.resolve(), args.out.resolve()
    try:
        if args.action == "prepare":
            if args.detach:
                raise ValueError("--detach applies only to run")
            prepare(root, out, args.commit)
            print(f"Prepared four full policy directories at {out}; no Godot started.")
        elif args.detach:
            argv = [sys.executable, str(Path(__file__).resolve()), *[arg for arg in sys.argv[1:] if arg != "--detach"]]
            with (out / "runner.log").open("a", encoding="utf-8") as log:
                process = subprocess.Popen(
                    argv,
                    cwd=root,
                    stdin=subprocess.DEVNULL,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    start_new_session=True,
                )
            write_json(out / "runner.pid.json", {"pid": process.pid, "command": shlex.join(argv)})
            print(f"Detached runner pid={process.pid}; log={out / 'runner.log'}")
        else:
            run(root, out, args)
    except (OSError, ValueError, KeyError) as error:
        if out.is_dir():
            write_json(out / "runner.error.json", {"error": str(error), "time_unix": time.time()})
        parser.error(str(error))


if __name__ == "__main__":
    main()
