#!/usr/bin/env python3
"""Verify and archive the fixed Step 3 B/C measurements, without another Godot run."""

import gzip
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from lever_sweep import source_manifest
from wave1_baseline import SOURCE_PATTERNS

BUILD = ROOT / "build/sim/wave1-rebase"
EVIDENCE = ROOT / "tools/sim/evidence"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text())


def archive(path, data):
    with path.open("wb") as destination, gzip.GzipFile(fileobj=destination, mode="wb", filename="", mtime=0) as stream:
        stream.write(data)


def main():
    assert (BUILD / "job.complete").exists()
    assert (BUILD / "gate.exit").read_text().strip() == "0"
    gate = (BUILD / "gate.log").read_text()
    assert "check.sh: all steps passed" in gate
    assert "gut_strict: ok (no risky or pending tests)" in gate
    counter = (BUILD / "counter-check.log").read_text()
    assert "PEAT_COUNTER_KNOWN_ANSWER_PASS" in counter
    alias_check = (BUILD / "line-compatibility-check.log").read_text()
    assert "MEASUREMENT_LINE_ARCHIVE_COMPATIBILITY_PASS" in alias_check
    reuse = read(BUILD / "probe-reuse.json")
    expected = read(EVIDENCE / "wave1-baseline-shipped-plan.json")["seeds"]
    artifacts = []
    timing = {}
    logs = []
    for label in ["B", "C"]:
        out = BUILD / label
        plan, progress = read(out / "plan.json"), read(out / "progress.json")
        assert plan["seeds"] == expected and len(expected) == 320
        assert progress["state"] == "complete" and progress["completed_lobbies"] == 320
        assert progress["plan_sha256"] == sha(out / "plan.json")
        assert [seed for chunk in progress["chunks"] for seed in chunk["seeds"]] == expected
        assert plan["source_commit"].startswith("d5b5b4f8")
        assert plan["overrides"] == {"pass3_preset": label}
        assert plan["config"]["card_size_caps"] and plan["config"]["card_rate_limits"]
        assert source_manifest(Path(plan["runtime_tree"]), SOURCE_PATTERNS) == plan["source_sha256"]
        assert sha(ROOT / "tools/sim/wave1_baseline.gd") == plan["measurement_script_sha256"]
        assert sha(ROOT / "tools/sim/wave1_baseline.py") == plan["driver_sha256"]
        compatibility = read(out / "measurement-compatibility.json")
        assert compatibility == plan["measurement_compatibility"]
        for entry in compatibility["files"]:
            assert sha(Path(entry["source_path"])) == entry["source_sha256"]
            assert sha(Path(entry["destination_path"])) == entry["destination_sha256"]
        assert sha(out / "probe.json") == reuse["presets"][label]["reused_probe_sha256"]
        old_runtime = Path(reuse["presets"][label]["old_runtime_tree"])
        new_runtime = Path(reuse["presets"][label]["new_runtime_tree"])
        assert old_runtime.resolve() != new_runtime.resolve()
        assert new_runtime.resolve() == Path(plan["runtime_tree"]).resolve()
        for name, checksum in reuse["presets"][label]["unchanged_dependency_sha256"].items():
            assert sha(old_runtime / name) == sha(new_runtime / name) == checksum
        native_seconds = 0.0
        for chunk in progress["chunks"]:
            assert sha(Path(chunk["analysis"])) == chunk["analysis_sha256"]
            capture = Path(chunk["capture"])
            assert sha(capture) == chunk["capture_gzip_sha256"]
            checksum = hashlib.sha256()
            with gzip.open(capture, "rb") as stream:
                while block := stream.read(1024 * 1024):
                    checksum.update(block)
            assert checksum.hexdigest() == chunk["capture_sha256"]
            name = Path(chunk["analysis"]).name.split(".")[0] + ".log"
            log = (out / name).read_text()
            matches = re.findall(r"wave1_baseline: (\d+) lobbies in ([0-9.]+) s", log)
            assert len(matches) == 1 and int(matches[0][0]) == chunk["lobbies"]
            native_seconds += float(matches[0][1])
            logs.extend([f"===== {label}/{name} =====\n", log])
        for name in ["plan", "probe", "progress", "measurement-compatibility"]:
            dest = EVIDENCE / f"wave1-rebase-{label}-{name}.json"
            shutil.copyfile(out / f"{name}.json", dest)
            artifacts.append(dest)
        result_path = EVIDENCE / f"wave1-rebase-{label}.json"
        result = read(result_path)
        analysis_path = ROOT / result["analysis_archive"]["path"]
        assert sha(analysis_path) == result["analysis_archive"]["sha256"]
        with gzip.open(analysis_path, "rt") as stream:
            analysis = json.load(stream)
        assert analysis["plan"] == plan and analysis["progress"] == progress
        assert len([row for row in analysis["players"] if row["line"] == "hard_field"]) == 1280
        assert len(analysis["peat_diagnostics"]) == sum(row["rounds"] for row in analysis["players"])
        artifacts.extend([result_path, analysis_path, ROOT / f"docs/ideation/evidence/wave1-rebase-{label}.md"])
        timing[label] = {
            "lobbies": 320,
            "godot_seconds": round(native_seconds, 3),
            "accepted_chunk_wall_seconds": round(sum(c["seconds"] for c in progress["chunks"]), 3),
        }
    for name, data in [
        ("gate", gate),
        ("counter-check", counter),
        ("line-compatibility-check", alias_check),
        ("execution", "".join(logs)),
    ]:
        path = EVIDENCE / f"wave1-rebase-{name}.log.gz"
        archive(path, data.encode())
        artifacts.append(path)
    reuse_path = EVIDENCE / "wave1-rebase-probe-reuse.json"
    shutil.copyfile(BUILD / "probe-reuse.json", reuse_path)
    artifacts.append(reuse_path)
    rejected = BUILD / "rejected-unconfigured-line-policy"
    history_log = EVIDENCE / "wave1-rebase-rejected-attempt.log.gz"
    archive(
        history_log,
        (
            (rejected / "reason.json").read_text()
            + "\n"
            + (rejected / "job.log").read_text()
            + "\n"
            + (rejected / "B/chunk-0000.log").read_text()
        ).encode(),
    )
    artifacts.append(history_log)
    supervisor_log = EVIDENCE / "wave1-rebase-preflight-supervisor.log.gz"
    archive(supervisor_log, (BUILD / "corrected-preflight-supervisor.log").read_bytes())
    artifacts.append(supervisor_log)
    artifacts.extend(
        [
            Path(__file__),
            ROOT / "tools/sim/evidence/drivers/wave1-rebase.sh",
            ROOT / "tools/sim/evidence/drivers/wave1-rebase-corrected.sh",
            ROOT / "tools/sim/evidence/drivers/wave1-rebase-resume.sh",
            ROOT / "tools/sim/evidence/drivers/recover-wave1-rebase-chunk.py",
            ROOT / "tools/sim/evidence/drivers/check_wave1_archive_lines.gd.txt",
            ROOT / "tools/sim/evidence/drivers/check_peat_counter.gd.txt",
            EVIDENCE / "wave1-rebase-B-overrides.json",
            EVIDENCE / "wave1-rebase-C-overrides.json",
            EVIDENCE / "wave1-rebase-comparison.json",
            ROOT / "docs/ideation/evidence/wave1-rebase.md",
        ]
    )
    verification = {
        "source_commit": plan["source_commit"],
        "state": "complete",
        "lobbies_per_preset": 320,
        "same_shipped_control_seeds": True,
        "caps": "on",
        "measurement_compatibility": "Recorded current measurement-line overlay; native game/content and Bog policy retained. All four aliases checked natively.",
        "probe_reuse": "Prior validated probes; all native draw/config/content dependency hashes unchanged.",
        "timing": timing,
        "execution_history": {
            "rejected_unconfigured_line_attempt": "Zero accepted lobbies; current measurement line compatibility was then added and plans freshly prepared.",
            "corrected_preflight_supervisor": "Native checks passed; shell stopped after an in-flight metadata wording edit. Frozen plans continued with the recorded resume driver; zero lobbies were admitted before continuation.",
            "bounded_supervisor_expiry": "B320/C200 were admitted at expiry. A finished 20-lobby C chunk was validated and recovered without replay; only the remaining100 C seeds were simulated. Recovered chunk wall time includes its admission wait.",
        },
        "gate": {
            "command": "source /opt/bramble/env.sh; flock -w 1200 /tmp/bramble-godot.lock flock -w 300 /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G timeout --kill-after=10s 900 ./scripts/check.sh",
            "exit_code": 0,
            "tests": int(re.search(r"^Tests\s+(\d+)", gate, re.M).group(1)),
            "assertions": int(re.search(r"^Asserts\s+(\d+)", gate, re.M).group(1)),
            "strict_hook": "ok",
        },
        "counter_check": "normal/golden raises, zero outputs, native attribution, final-batch witnesses, exact fight/event/carry/RNG parity",
        "python_harness_log": "build/sim/wave1-rebase/python-final.log",
        "artifact_sha256": {str(p.relative_to(ROOT)): sha(p) for p in artifacts},
    }
    (EVIDENCE / "wave1-rebase-verification.json").write_text(json.dumps(verification, indent=2) + "\n")
    print(json.dumps(timing, indent=2))


if __name__ == "__main__":
    main()
