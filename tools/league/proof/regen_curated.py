#!/usr/bin/env python3
"""Regenerate curated fight fixtures from Godot after importing the project."""

import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
FIXTURES = {
    "badger_fights.jsonl": "fight_run.gd",
    "rework_fights.jsonl": "rework_fight_vectors.gd",
}


def read_rows(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def dump_rows(rows):
    return "".join(json.dumps(row, separators=(",", ":"), ensure_ascii=False) + "\n" for row in rows)


def regenerate(fixture, runner, work, rewrite_traces):
    rows = read_rows(fixture)
    cases = work / f"{fixture.stem}.cases.jsonl"
    result_file = work / f"{fixture.stem}.out.jsonl"
    log = work / f"{fixture.stem}.log"
    cases.write_text(
        dump_rows({key: value for key, value in row.items() if not key.startswith("expected_")} for row in rows),
        encoding="utf-8",
    )
    subprocess.run(
        [
            "timeout",
            "-k",
            "10",
            "600",
            os.environ.get("GODOT", "godot"),
            "--headless",
            "--log-file",
            str(log),
            "-s",
            f"res://tools/league/gd/{runner}",
            "--",
            f"cases={cases}",
            f"out={result_file}",
        ],
        cwd=REPO,
        check=True,
        stdout=subprocess.DEVNULL,
    )
    results = read_rows(result_file)
    if len(rows) != len(results):
        raise ValueError(f"{fixture.name}: expected {len(rows)} results, got {len(results)}")
    hashes_changed = 0
    traces_changed = 0
    for row, result in zip(rows, results, strict=True):
        label = f"{fixture.name} id {row['id']}"
        if row["id"] != result.get("id"):
            raise ValueError(f"{label}: result id {result.get('id')}")
        if "hash" not in result:
            raise ValueError(f"{label}: rejected: {result.get('error')}")
        if row.get("trace") or "expected_trace" in row:
            if not isinstance(result.get("trace"), list):
                raise ValueError(f"{label}: missing event trace")
            if row.get("expected_trace") != result["trace"]:
                print(f"{label}: TRACE CHANGED")
                traces_changed += 1
                row["expected_trace"] = result["trace"]
        if row.get("expected_hash") != result["hash"]:
            hashes_changed += 1
            row["expected_hash"] = result["hash"]
    if traces_changed and not rewrite_traces:
        raise ValueError(f"{fixture.name}: use --rewrite-traces to accept changed traces")
    print(f"{fixture.name}: {len(rows)} cases, {hashes_changed} hashes and {traces_changed} traces updated")
    return dump_rows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rewrite-traces", action="store_true", help="accept changed event traces")
    args = parser.parse_args()
    fixtures = REPO / "tools/league/bramble-fight/tests/fixtures"
    try:
        with tempfile.TemporaryDirectory(prefix="regen-curated-") as work:
            updated = {
                fixtures / name: regenerate(fixtures / name, runner, Path(work), args.rewrite_traces)
                for name, runner in FIXTURES.items()
            }
        for path, rows in updated.items():
            path.write_text(rows, encoding="utf-8")
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"regen_curated: {error}\n")


if __name__ == "__main__":
    main()
