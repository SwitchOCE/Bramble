#!/usr/bin/env python3
"""Verify and archive the two completed frozen wave-1 baseline runs offline."""

import gzip
import hashlib
import json
import re
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[4]
build = root / "build/sim/wave1-shipped-baseline"
evidence = root / "tools/sim/evidence"
assert (build / "final-gate.exit").read_text().strip() == "0"
log = (build / "final-gate.log").read_bytes()
text = log.decode()
assert "All steps passed" in text or "all steps passed" in text.lower()
archive = evidence / "wave1-baseline-final-gate.log.gz"
with archive.open("wb") as destination, gzip.GzipFile(fileobj=destination, mode="wb", filename="", mtime=0) as zipped:
    zipped.write(log)
p = evidence / "wave1-baseline-verification.json"
d = json.loads(p.read_text())
d.setdefault("gate_previous", d["gate"])
d["gate"] = {
    "command": (
        "source /opt/bramble/env.sh; flock -w 900 /tmp/bramble-godot.lock "
        "flock -w 300 /tmp/bramble-harness-godot.lock systemd-run --user --scope -q "
        "-p MemoryMax=3G timeout --kill-after=10s 900 ./scripts/check.sh"
    ),
    "exit_code": 0,
    "all_steps_passed": True,
    "archive": str(archive.relative_to(root)),
    "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
}
d["gate"]["tests"] = int(re.search(r"^Tests\s+(\d+)", text, re.M).group(1))
d["gate"]["assertions"] = int(re.search(r"^Asserts\s+(\d+)", text, re.M).group(1))
assert "gut_strict: ok (no risky or pending tests)" in text
d["gate"]["strict_hook"] = "ok (no risky or pending tests)"
print(text[-2500:])
p.write_text(json.dumps(d, indent=2) + "\n")

build = root / "build/sim/wave1-shipped-baseline"
evidence = root / "tools/sim/evidence"


def read(p):
    return json.loads(p.read_text())


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


plans = {}
timings = {}
logparts = []
artifacts = []
for setting in ("shipped", "checkpoint"):
    out = build / setting
    plan = read(out / "plan.json")
    progress = read(out / "progress.json")
    plans[setting] = plan
    assert progress["state"] == "complete" and progress["completed_lobbies"] == len(plan["seeds"]) == 320
    assert progress["plan_sha256"] == sha(out / "plan.json")
    assert [s for c in progress["chunks"] for s in c["seeds"]] == plan["seeds"]
    assert len(set(plan["seeds"])) == 320
    assert (out / "plan.json").read_bytes() == (evidence / f"wave1-baseline-{setting}-plan.json").read_bytes()
    native_seconds = 0.0
    for chunk in progress["chunks"]:
        assert sha(Path(chunk["analysis"])) == chunk["analysis_sha256"]
        capture = Path(chunk["capture"])
        assert sha(capture) == chunk["capture_gzip_sha256"]
        assert hashlib.sha256(gzip.decompress(capture.read_bytes())).hexdigest() == chunk["capture_sha256"]
        prefix = Path(chunk["analysis"]).name.split(".")[0]
        log = (out / f"{prefix}.log").read_text()
        matches = re.findall(r"wave1_baseline: (\d+) lobbies in ([0-9.]+) s", log)
        assert len(matches) == 1 and int(matches[0][0]) == chunk["lobbies"]
        native_seconds += float(matches[0][1])
        logparts.extend([f"===== {setting}/{prefix}.log =====\n", log])
    copied = evidence / f"wave1-baseline-{setting}-progress.json"
    shutil.copyfile(out / "progress.json", copied)
    result_path = evidence / f"wave1-baseline-{setting}.json"
    result = read(result_path)
    assert result["lobbies"] == 320 and result["plan_sha256"] == sha(out / "plan.json")
    assert result["source_commit"] == plan["source_commit"]
    archive = Path(result["analysis_archive"]["path"])
    if not archive.is_absolute():
        archive = root / archive
    assert sha(archive) == result["analysis_archive"]["sha256"]
    archived = json.loads(gzip.decompress(archive.read_bytes()))
    assert archived["plan"] == plan and archived["progress"] == progress
    timings[setting] = {
        "lobbies": 320,
        "chunks": len(progress["chunks"]),
        "godot_seconds": round(native_seconds, 3),
        "chunk_wall_seconds": round(sum(c["seconds"] for c in progress["chunks"]), 3),
    }
    artifacts.extend(
        [
            copied,
            result_path,
            archive,
            evidence / f"wave1-baseline-{setting}-plan.json",
            root / f"docs/ideation/evidence/wave1-baseline-{setting}.md",
        ]
    )
assert plans["shipped"]["seeds"] == plans["checkpoint"]["seeds"]
assert plans["shipped"]["rates"] == plans["checkpoint"]["rates"]
assert (
    plans["shipped"]["source_commit"]
    == plans["checkpoint"]["source_commit"]
    == "f9c924b9bc1fff68509b55666268ebd81d71664f"
)
assert read(evidence / "wave1-baseline-verification.json")["gate"]["exit_code"] == 0
logpath = evidence / "wave1-baseline-execution.log.gz"
with logpath.open("wb") as destination, gzip.GzipFile(fileobj=destination, mode="wb", filename="", mtime=0) as zipped:
    zipped.write("".join(logparts).encode())
artifacts.extend(
    [
        logpath,
        evidence / "wave1-baseline-comparison.json",
        root / "docs/ideation/evidence/wave1-shipped-baseline.md",
        evidence / "wave1-baseline-lock-revision.json",
        evidence / "wave1-baseline-lock-history.json.gz",
        evidence / "drivers/wave1-shipped-resume.sh",
        evidence / "wave1-baseline-gate.log.gz",
        evidence / "wave1-baseline-final-gate.log.gz",
        Path(__file__).resolve(),
        evidence / "drivers/wave1-shipped-baseline.sh",
    ]
)
verification_path = evidence / "wave1-baseline-verification.json"
verification = read(verification_path)
verification["measurement_scope"] = (
    "Complete fixed five-tribe calibration baseline: shipped and checkpoint each completed the same "
    "320 eligible original seeds with unchanged current rates and frozen game source. Only growth and "
    "realized committed R12 median with whole-seed intervals are deciding measures."
)
verification["measurement"] = {
    "state": "complete",
    "same_seeds": True,
    "unique_seeds_per_setting": 320,
    "settings": timings,
    "eligible_candidates": 421,
    "excluded_candidates": 219,
    "unused_eligible_candidates": 101,
    "timing_scope": (
        "Godot seconds sum the 16 native chunk-log timings per setting; accepted chunk wall seconds also "
        "include lock queueing, parsing and archival, but exclude the interrupted queued lock attempt before migration."
    ),
    "capture_hashes_verified": True,
    "analysis_hashes_verified": True,
    "plan_copies_byte_identical": True,
}
verification["artifact_sha256"] = {str(p.relative_to(root)): sha(p) for p in artifacts}
verification_path.write_text(json.dumps(verification, indent=2) + "\n")
method = root / "docs/ideation/evidence/wave1-baseline-method.md"
text = method.read_text().split("\n## Completed measurement\n", 1)[0]
text += """
## Completed measurement

Both fixed settings completed all 320 planned eligible lobbies on the frozen game
source. The archived progress lists every accepted chunk and its capture hashes;
all analysis archives, full capture hashes, seed coverage and byte-identical plan
copies were checked before the final comparison. The verification JSON records
the final artifact hashes and the passed 1,896-test / 42,407-assertion full gate
plus 163 Python harness tests after the execution-only lock revision.

"""
for s, t in timings.items():
    text += (
        f"{s.capitalize()}: {t['godot_seconds']:.3f} s native Godot execution; "
        f"{t['chunk_wall_seconds']:.3f} s accepted chunk wall time, including shared-lock "
        "queueing before the approved lock revision and excluding its interrupted queued attempt.\n\n"
    )
text += """`wave1-baseline-execution.log.gz` archives the per-chunk native timing logs.
The approved split-lock revision and the original plans/accepted progress are
retained in `wave1-baseline-lock-revision.json` and its hashed history archive.
No seed, dial, game-source or deciding-measure change accompanied that revision.
"""
method.write_text(text)
verification["artifact_sha256"][str(method.relative_to(root))] = sha(method)
verification["finalization_driver"] = "tools/sim/evidence/drivers/finalize-wave1-baselines.py"
verification_path.write_text(json.dumps(verification, indent=2) + "\n")
print(json.dumps(timings, indent=2))
