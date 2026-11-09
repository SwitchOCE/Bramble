#!/usr/bin/env python3
"""Run the frozen first designed experiment; uses the harness lock, never commits.

Source /opt/bramble/env.sh, then python3 tools/sim/evidence/drivers/run_designed_first.py.
The committed plan fixes inputs, source fingerprint, fields, seeds and fight counts.
"""

import gzip
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from designed_report import markdown, summarize
from evidence_io import json_sha, write_json
from field import load_designed, sample_field
from lever_sweep import atomic_json, file_sha, git, jsonl, run_command, utc_now
from sweep_shards import fingerprints, godot_command


def main():
    import os

    os.chdir(ROOT)
    plan_path = ROOT / "tools/sim/evidence/designed-first-plan.json"
    plan = json.loads(plan_path.read_text())
    actual = fingerprints(ROOT, plan["profiles"])
    for key in ["source_fingerprint", "profiles_sha256"]:
        if plan[key] != actual[key]:
            raise ValueError(f"frozen {key} changed")
    git(ROOT, "merge-base", "--is-ancestor", plan["source_commit"], "HEAD")
    progress = {"version": 1, "plan_sha256": file_sha(plan_path), "started_at": utc_now(), "fields": {}}
    for spec in plan["fields"]:
        source, field_path = ROOT / spec["input"], ROOT / spec["field"]
        if json_sha(source) != spec["input_sha256"]:
            raise ValueError("designed input changed")
        if not field_path.exists():
            boards, weights = load_designed(source.relative_to(ROOT))
            field = sample_field(boards, tuple(spec["rounds"]), spec["boards_per_round"], 91407, line_weights=weights)
            field_path.parent.mkdir(parents=True, exist_ok=True)
            field_path.write_text(json.dumps(field) + "\n")
        if file_sha(field_path) != spec["field_sha256"]:
            raise ValueError("frozen field changed")
        name = spec["id"]
        trials = field_path.with_name(name + "-trials.jsonl")
        log = field_path.with_name(name + "-godot.log")
        if trials.exists():
            raise ValueError(f"existing trial output requires explicit review before reuse: {trials}")
        start = time.monotonic()
        print(utc_now(), "starting", name, spec["fights"], "fights", flush=True)
        run_command(
            godot_command("field_fights.gd", [str(field_path), str(trials), "64", "per_seed"], 1800, ROOT),
            log,
            1807,
            ROOT,
        )
        field = json.loads(field_path.read_text())
        report = summarize(field, list(jsonl(trials)), reps=64)
        if report["fights"] != spec["fights"]:
            raise ValueError("designed fight budget differs from frozen plan")
        report["provenance"] = {
            "plan_sha256": file_sha(plan_path),
            "field_sha256": file_sha(field_path),
            "trials_sha256": file_sha(trials),
            "log_sha256": file_sha(log),
            "elapsed_seconds": time.monotonic() - start,
        }
        suffix = ".json.gz" if name == "screen" else ".json"
        target = ROOT / f"tools/sim/evidence/designed-{name}-result{suffix}"
        write_json(target, report, indent=None)
        (ROOT / f"docs/ideation/evidence/designed-{name}.md").write_text(markdown(report))
        archive = ROOT / f"tools/sim/evidence/designed-{name}-trials.jsonl.gz"
        with archive.open("wb") as raw, gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=0) as stream:
            with trials.open("rb") as rows:
                import shutil

                shutil.copyfileobj(rows, stream)
        progress["fields"][name] = {
            **report["provenance"],
            "archive_sha256": file_sha(archive),
            "result_sha256": json_sha(target),
            "fights": report["fights"],
        }
        atomic_json(ROOT / "tools/sim/evidence/designed-first-progress.json", progress)
        print(utc_now(), "complete", name, report["provenance"]["elapsed_seconds"], flush=True)
    progress.update(state="complete", completed_at=utc_now())
    atomic_json(ROOT / "tools/sim/evidence/designed-first-progress.json", progress)


if __name__ == "__main__":
    main()
