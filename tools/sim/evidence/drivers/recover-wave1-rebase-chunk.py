#!/usr/bin/env python3
"""Admit one fully finished orphaned chunk after supervisor expiry; never simulates."""

import argparse
import gzip
import hashlib
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from evidence_io import read_json, write_json
from lever_sweep import atomic_json, file_sha, source_manifest
from wave1_baseline import SOURCE_PATTERNS, parse_chunk


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", type=Path, required=True)
    args = parser.parse_args()
    plan = read_json(args.plan)
    out, target = Path(plan["output"]), Path(plan["runtime_tree"])
    progress_path = out / "progress.json"
    status = read_json(progress_path)
    assert status["plan_sha256"] == file_sha(args.plan)
    assert source_manifest(target, SOURCE_PATTERNS) == plan["source_sha256"]
    assert file_sha(ROOT / "tools/sim/wave1_baseline.py") == plan["driver_sha256"]
    offset = status["completed_lobbies"]
    seeds = plan["seeds"][offset : offset + plan["chunk"]]
    assert seeds and status["active_seeds"] == seeds
    prefix = out / f"chunk-{offset:04d}"
    invocation = prefix.with_suffix(".plan.json")
    assert read_json(invocation) == {"seeds": seeds, "overrides": plan["overrides"]}
    log = prefix.with_suffix(".log").read_text()
    assert not re.search(r"SCRIPT ERROR:|Parse Error:|(?:^|\n)ERROR:", log)
    finished = re.findall(r"wave1_baseline: (\d+) lobbies in ([0-9.]+) s", log)
    assert len(finished) == 1 and int(finished[0][0]) == len(seeds)
    raw = prefix.with_suffix(".jsonl")
    boards, players, diagnostics = parse_chunk(raw, seeds, plan["config"], with_diagnostics=True)
    compact = prefix.with_suffix(".analysis.json.gz")
    write_json(compact, {"boards": boards, "players": players, "peat_diagnostics": diagnostics})
    archive = prefix.with_suffix(".jsonl.gz")
    checksum = hashlib.sha256()
    with (
        raw.open("rb") as source,
        archive.open("wb") as dest,
        gzip.GzipFile(fileobj=dest, mode="wb", filename="", mtime=0, compresslevel=3) as zipped,
    ):
        while block := source.read(1024 * 1024):
            checksum.update(block)
            zipped.write(block)
    status["chunks"].append(
        {
            "seeds": seeds,
            "lobbies": len(seeds),
            "seconds": time.time() - invocation.stat().st_mtime,
            "analysis": str(compact),
            "analysis_sha256": file_sha(compact),
            "capture": str(archive),
            "capture_sha256": checksum.hexdigest(),
            "capture_gzip_sha256": file_sha(archive),
            "recovered_after_supervisor_timeout": True,
            "wall_timing_scope": "Invocation file mtime through validated recovery admission; includes orphan/recovery wait.",
        }
    )
    status.update(state="paused", completed_lobbies=offset + len(seeds), active_seeds=[])
    status.pop("error", None)
    atomic_json(progress_path, status)
    raw.unlink()
    print(f"Recovered {len(seeds)} complete lobbies; total {status['completed_lobbies']}/{len(plan['seeds'])}")


if __name__ == "__main__":
    main()
