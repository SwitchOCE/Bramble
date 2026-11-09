#!/usr/bin/env python3
"""Reproduce three historical analysis-only artifacts; never runs Godot or commits.

Subcommands: real-null, baseline-curvature, lever-reads. --out is required so the
committed historical reports are never overwritten implicitly. --verify-against
compares all values except measured elapsed_seconds. Baseline/raw null captures
remain under build/; qualification CSVs and archived null-field fights are tracked.
"""

from __future__ import annotations

import argparse
import gzip
import json
import statistics
import sys
import time
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from check_lines import line_breakdown
from check_plants import check
from evidence_io import read_json
from field import boards_from_capture, field_report
from lever_sweep import file_sha
from metrics import compact_boards, curvature_with_intervals


def round_medians(rows):
    return {
        str(number): {
            "boards": sum(row["round"] == number for row in rows),
            "median_stats": statistics.median(row["stats"] for row in rows if row["round"] == number),
        }
        for number in range(6, 17)
    }


def baseline_curvature():
    started = time.monotonic()
    progress_path = Path("tools/sim/evidence/baseline-progress.json")
    progress = read_json(progress_path)
    paths, hashes = [], {}
    for shard in progress["shards"]:
        name = shard["prefix"] + ".fights.jsonl"
        path = Path(name)
        checksum = file_sha(path)
        if checksum != shard["files"][name]["sha256"]:
            raise ValueError(f"original baseline capture changed: {name}")
        paths.append(path)
        hashes[name] = checksum
    rows, _ = compact_boards(boards_from_capture(paths), {})
    rows = [row for row in rows if 6 <= row["round"] <= 16]
    result = {
        "version": 1,
        "source": "fixed 500-lobby capped baseline, seeds 81001–81500",
        "source_progress_sha256": file_sha(progress_path),
        "capture_hashes_verified_against_progress": True,
        "capture_sha256": hashes,
        "board_round_observations": len(rows),
        "stats_phase_counts": dict(Counter(row["stats_phase"] for row in rows)),
        "rounds": round_medians(rows),
        "curvature_check": curvature_with_intervals(rows, 2000, 14519),
        "elapsed_seconds": time.monotonic() - started,
    }
    started = time.monotonic()
    before = [{**row, "stats": row["pre_start_stats"]} for row in rows]
    result["pre_start_comparison"] = {
        # Preserve the historical artifact's wording, not today's decision contract.
        "purpose": "Phase comparison with the historical baseline/report-review medians only; the active measurement contract uses after_start_effects.",
        "stats_phase": "combat_start after initial auras before Start of Combat effects",
        "rounds": round_medians(before),
        "curvature_check": curvature_with_intervals(before, 2000, 14519),
        "elapsed_seconds": time.monotonic() - started,
    }
    return result


def real_null():
    field = read_json("tools/sim/evidence/real-null-field.json.gz")
    pairs_path = Path("tools/sim/evidence/real-null-field-pairs.jsonl.gz")
    pairs_raw = gzip.decompress(pairs_path.read_bytes())
    pairs = [json.loads(row) for row in pairs_raw.splitlines()]
    null_field = field_report(field, pairs)
    result = check(
        Path("build/sim/review-fixes/reference"),
        Path("build/sim/review-fixes/null"),
        Path("build/sim/harness-plants/broken"),
        read_json("build/sim/harness-plants/report.json"),
        null_field,
    )
    files = {}
    for original, archive in [
        ("build/sim/followup-null/field.json", "tools/sim/evidence/real-null-field.json.gz"),
        ("build/sim/followup-null/pairs.jsonl", str(pairs_path)),
    ]:
        import hashlib

        raw = gzip.decompress(Path(archive).read_bytes())
        files[original] = {
            "sha256": hashlib.sha256(raw).hexdigest(),
            "archive": archive,
            "archive_sha256": file_sha(Path(archive)),
        }
    result["null_field_provenance"] = {
        "round": 6,
        "boards": 32,
        "replicates_per_orientation": 2,
        "fights": 1984,
        # Historical runtime, not a newly executed fight. This command is offline.
        "godot_fight_seconds": 14.118,
        "field_sample_seed": 91407,
        "files": files,
        "source_captures": {
            arm: file_sha(Path(f"build/sim/review-fixes/{arm}.fights.jsonl")) for arm in ["reference", "null"]
        },
    }
    return result


def lever_reads():
    gate = read_json("tools/sim/evidence/lever-build-strength-gate.json")
    plan = read_json("tools/sim/evidence/lever-build-strength-plan.json")
    profiles_path = Path(plan["profiles"])
    if file_sha(profiles_path) != plan["profiles_sha256"]:
        raise ValueError("historical committed profile table changed; use the recorded revision")
    result = {
        "decision_source": "ideation/main docs/ideation/DECISIONS.md: Harness follow-up review: calls (9 Nov 2026)",
        "general_reads_open": gate["passes"],
        "engine_tribe_interpretation": "losing line observations are lower bounds from weak play, never adverse content results; designed setups are the second source",
        "builds": {},
    }
    for name in gate["builds"]:
        path = Path(f"tools/sim/evidence/lever-build-heads/{name}-mixture.players.csv")
        metadata = read_json(path.with_name(name + "-mixture.run.json"))
        if file_sha(path) != metadata["players_sha256"]:
            raise ValueError("historical head-to-head player input changed")
        breakdown = line_breakdown(path, read_json(profiles_path))
        for values in breakdown["groups"].values():
            values["reading"] = (
                "lower_bound" if values["mean_place_gain"] <= 0 else "positive_observation_not_content_attribution"
            )
        result["builds"][name] = breakdown
    return result


def without_runtime(value):
    if isinstance(value, dict):
        return {key: without_runtime(child) for key, child in value.items() if key != "elapsed_seconds"}
    if isinstance(value, list):
        return [without_runtime(child) for child in value]
    return value


def main():
    import os

    os.chdir(ROOT)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", choices=["real-null", "baseline-curvature", "lever-reads"])
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--verify-against", type=Path)
    args = parser.parse_args()
    result = {"real-null": real_null, "baseline-curvature": baseline_curvature, "lever-reads": lever_reads}[
        args.artifact
    ]()
    if args.verify_against and without_runtime(result) != without_runtime(read_json(args.verify_against)):
        raise ValueError("reconstructed artifact differs beyond measured runtime")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"artifact": args.artifact, "verified": bool(args.verify_against), "out": str(args.out)}))


if __name__ == "__main__":
    main()
