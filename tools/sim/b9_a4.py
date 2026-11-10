#!/usr/bin/env python3
"""Bounded local A4: line lobbies, captured-state field fights and reused top-four libraries.

Default is a two-lobby smoke per preset. Full execution requires --full and an explicit
--source-commit matching HEAD; only run it after the orchestrator supplies the merged commit.
"""

import argparse
import csv
import gzip
import hashlib
import json
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools/sim"))

import b9_a4_report  # noqa: E402
import field  # noqa: E402
from evidence_io import read_json, write_json  # noqa: E402

from tools.checks.sim_job import check_godot_log  # noqa: E402

CONFIGS = ROOT / "docs/ideation/evidence/b9-measure/a4/configs"
ROUNDS = (10, 12, 14)


def revision():
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def run(command, log):
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w") as stream:
        subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, check=True)


def collect_captures(lobby_dir, output, source):
    """Join transport shards, preserving original suites, seeds, seat ids and capture records."""
    output.mkdir(parents=True, exist_ok=True)
    captures = sorted((lobby_dir / "shards").glob("shard-*/*.fights.jsonl.gz"))
    players = sorted((lobby_dir / "shards").glob("shard-*/*.players.csv"))
    if not captures or len(captures) != len(players):
        raise ValueError("incomplete native captures or companion player files")
    capture_path = output / "lines.fights.jsonl"
    with capture_path.open("wb") as target:
        for path in captures:
            with gzip.open(path, "rb") as stream:
                shutil.copyfileobj(stream, target)
    players_path = output / "lines.players.csv"
    writer, seen = None, set()
    with players_path.open("w", newline="") as target:
        for path in players:
            with path.open(newline="") as stream:
                reader = csv.DictReader(stream)
                if writer is None:
                    writer = csv.DictWriter(target, reader.fieldnames)
                    writer.writeheader()
                for row in reader:
                    key = row["seed"], row["leg"], row["seat"]
                    if key in seen:
                        raise ValueError(f"duplicate source player: {key}")
                    seen.add(key)
                    writer.writerow(row)
    if revision() != source:
        raise ValueError("HEAD changed while capturing; source provenance is not reliable")
    write_json(
        output / "source.json",
        {
            "source_commit": source,
            "sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in [capture_path, players_path]},
        },
    )
    return capture_path


def sample_field(capture, output):
    """One seeded board per represented line keeps the round robin at <=22 fights per line."""
    boards = list(field.boards_from_capture([capture]))
    result = {
        "version": 1,
        "rounds": {},
        "test_cards": [],
        "source_mode": "captured_population",
        "weight_source": "equal_committed_lines",
    }
    missing = {}
    all_lines = sorted({board["line"] for board in boards})
    for number in ROUNDS:
        represented = sorted({b["line"] for b in boards if b["round"] == number})
        missing[str(number)] = sorted(set(all_lines) - set(represented))
        if len(represented) < 2:
            continue
        weights = {str(number): dict.fromkeys(represented, 1 / len(represented))}
        sampled = field.sample_field(boards, (number,), len(represented), seed=91407, line_weights=weights)
        group = sampled["rounds"][str(number)]
        assert max(Counter(b["line"] for b in group["boards"]).values()) == 1
        assert 2 * (len(group["boards"]) - 1) <= 40
        result["rounds"][str(number)] = group
    write_json(output, result)
    return missing


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--full", action="store_true")
    parser.add_argument("--source-commit")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source = revision()
    if args.full and not args.source_commit:
        parser.error("full A4 requires the orchestrator's merged --source-commit")
    if args.source_commit:
        requested = subprocess.check_output(["git", "rev-parse", args.source_commit], cwd=ROOT, text=True).strip()
        if requested != source:
            parser.error("checkout must be on the requested source commit")
    dirty = subprocess.check_output(
        ["git", "status", "--porcelain", "--", "src", "tools/sim", "content"], cwd=ROOT, text=True
    )
    if dirty:
        parser.error("commit gameplay and pipeline changes before capturing")
    if args.out.exists() and any(args.out.iterdir()):
        parser.error("refusing to overwrite an existing run; choose an empty output directory")
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=True)
    mode = "full" if args.full else "dry"
    manifest = {
        "source_commit": source,
        "dry_run": not args.full,
        "jobs": 3,
        "field_tool": "tools/sim/field_fights.gd",
        "library_tool": "tools/sim/recapture_field.sh --reuse-captures --strength top4",
        "presets": {},
    }
    for preset in ("B", "C"):
        output = args.out / preset
        output.mkdir()
        config = CONFIGS / f"{preset}-{mode}.json"
        run(
            [sys.executable, "tools/sim/sim_job.py", "local", str(config), str(output / "lobbies"), "--jobs", "3"],
            output / "lobbies.log",
        )
        capture = collect_captures(output / "lobbies", output / "captures", source)
        sampled_path = output / "field.json"
        missing = sample_field(capture, sampled_path)
        pairs_path = output / "field-pairs.jsonl"
        sampled = read_json(sampled_path)
        if sampled["rounds"]:
            run(
                [
                    "scripts/godot_slot.sh",
                    "godot",
                    "--headless",
                    "-s",
                    "res://tools/sim/field_fights.gd",
                    "--",
                    str(sampled_path),
                    str(pairs_path),
                    "1",
                    "aggregate",
                ],
                output / "field.log",
            )
            check_godot_log(output / "field.log")
            pairs = [json.loads(line) for line in pairs_path.read_text().splitlines()]
            field_result = field.field_report(sampled, pairs, bootstrap_replicates=200)
        else:
            pairs_path.write_text("")
            field_result = {"rounds": {}}
        write_json(output / "field-report.json", {**field_result, "missing_lines": missing})
        library = output / f"checkpoint-{preset}.json.gz"
        run(
            [
                "tools/sim/recapture_field.sh",
                "--reuse-captures",
                "--capture-dir",
                str(output / "captures"),
                "--source-commit",
                source,
                "--strength",
                "top4",
                "--out",
                str(library),
            ],
            output / "library.log",
        )
        # Confirm that checkpoint testers can open this exact source/config bundle.
        run(
            [
                "scripts/godot_slot.sh",
                "godot",
                "--headless",
                "-s",
                "res://tools/sim/profile_field_load.gd",
                "--",
                f"library={library}",
            ],
            output / "library-load.log",
        )
        check_godot_log(output / "library-load.log")
        manifest["presets"][preset] = {
            "config": read_json(config),
            "library": str(library),
            "library_sha256": hashlib.sha256(library.read_bytes()).hexdigest(),
            "field_pair_count": len(pairs_path.read_text().splitlines()),
        }
    write_json(args.out / "manifest.json", manifest)
    result = b9_a4_report.report(args.out, manifest)
    write_json(args.out / "report.json", result)
    (args.out / "README.md").write_text(b9_a4_report.markdown(result))
    print(args.out / "README.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
