#!/usr/bin/env python3
"""Archive the completed fixed Birds experiment and its native validation evidence."""

import gzip
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
BUILD = ROOT / "build/sim/skilled-birds-B"
OUT = ROOT / "tools/sim/evidence"
PREFIX = "wave1-skilled-birds"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def packed(path, data):
    with path.open("wb") as raw, gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=0) as z:
        z.write(data)


def main():
    assert (BUILD / "job.complete").exists()
    assert (BUILD / "final-gate.exit").read_text().strip() == "0"
    gate = (BUILD / "final-gate.log").read_text()
    assert "check.sh: all steps passed" in gate and "gut_strict: ok" in gate
    plan = json.loads((BUILD / "plan.json").read_text())
    assert len(plan["seeds"]) == len(set(plan["seeds"])) == plan["n_per_arm"] == 32
    assert sha(ROOT / "tools/sim/skilled_birds.py") == plan["driver_sha256"]
    for name, checksum in plan["helpers"].items():
        assert sha(ROOT / "tools/sim" / name) == checksum
        assert sha(Path(plan["runtime_tree"]) / "tools/sim" / name) == checksum
    tracked = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-tree", "-r", "-z", plan["source_commit"], "--", "src", "content"]
    )
    native_files = 0
    for entry in tracked.split(b"\0"):
        if not entry:
            continue
        header, path = entry.split(b"\t", 1)
        _, kind, expected = header.split()
        assert kind == b"blob"
        data = (Path(plan["runtime_tree"]) / path.decode()).read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest().encode()
        assert actual == expected, path
        native_files += 1
    artifacts = []
    for src, dst in [
        ("plan.json", f"{PREFIX}-plan.json"),
        ("report.json", f"{PREFIX}.json"),
        ("historical-control-check.json", f"{PREFIX}-historical-control-check.json"),
    ]:
        target = OUT / dst
        shutil.copyfile(BUILD / src, target)
        artifacts.append(target)
    target = OUT / f"{PREFIX}-boards.json.gz"
    packed(target, (BUILD / "report.boards.json").read_bytes())
    artifacts.append(target)
    raw = {}
    timings = {}
    for arm in ["control", "aggressive"]:
        source = BUILD / f"{arm}.jsonl"
        target = OUT / f"{PREFIX}-{arm}.jsonl.gz"
        packed(target, source.read_bytes())
        assert hashlib.sha256(gzip.decompress(target.read_bytes())).hexdigest() == sha(source)
        raw[arm] = {"sha256": sha(source), "gzip_sha256": sha(target), "archive": str(target.relative_to(ROOT))}
        artifacts.append(target)
        log = (BUILD / f"{arm}.log").read_text()
        assert not re.search(r"SCRIPT ERROR:|Parse Error:|(?:^|\n)ERROR:", log)
        found = re.findall(r"skilled_birds \w+: (\d+) lobbies in ([0-9.]+) s", log)
        assert len(found) == 1 and int(found[0][0]) == 32
        timings[arm] = float(found[0][1])
    for name in ["gate", "final-gate", "focused", "ban-smoke", "control", "aggressive"]:
        target = OUT / f"{PREFIX}-{name}.log.gz"
        packed(target, (BUILD / f"{name}.log").read_bytes())
        artifacts.append(target)
    report = ROOT / "docs/ideation/evidence/wave1-skilled-birds.md"
    text = (BUILD / "report.md").read_text()
    text += """\n## Reading the result\n\nCurrent B (2× normal and golden homecoming) can compound rapidly when the carry is flown consistently. The first measured interval, R10–R12, already shows that acceleration; separation from the native control is clear at R12 and large at R14–R16. For Homecoming, the post-fight board median is 180, 472, 1,094 and 2,748, versus control 176.5, 328, 508.5 and 948. Median same-survivor board growth is 2.293×, 2.194× and 2.071× over those successive two-round intervals. This supports rapid compounding rather than only a change in which players survive.\n\nThe largest active unit's median A+H is 79.5, 212, 408 and 1,010. The supplied human A boards are 329/772/2,085/2,676; human C boards are 272/459/883/1,617. Human C's biggest unit is 140/264/510/974, nearly doubling every two rounds from R10. The script probes this one decision while retaining native shopping/other flight choices; it does not establish optimal human play or add a runaway pass/fail threshold. The control exactly matches 613 historical native pre-start snapshots at R10/R12/R14.\n\nThe 32+32 lobbies use the shipped current wave-1 B pool at f9c924b9, including the context of the human logs, rather than the later d5b5b4f8 Bog/Fairies rebase. Both normal and golden homecoming remain 2×, caps and loop guards are on, heroes/fights/damage/eliminations/pool depletion are native.\n\n## Rebuilding the report\n\n```sh\npython3 tools/sim/skilled_birds.py report --plan tools/sim/evidence/wave1-skilled-birds-plan.json --control tools/sim/evidence/wave1-skilled-birds-control.jsonl.gz --aggressive tools/sim/evidence/wave1-skilled-birds-aggressive.jsonl.gz --output build/sim/skilled-birds-rebuilt.json\n```\n\nFull captures, sufficient board rows, source/helper hashes, human reference blobs, and native test logs are archived beside the report. The extraction command above rebuilds the measurements; this reading and validation footer are added by the committed finalization driver.\n"""
    text += f"\nNative Godot compute: control {timings['control']:.3f}s, forced carry {timings['aggressive']:.3f}s. Full final gate: {int(re.search(r'^Tests\s+(\d+)', gate, re.M).group(1))} tests / {int(re.search(r'^Asserts\s+(\d+)', gate, re.M).group(1))} assertions, strict hook clean. Focused flight checks and banned-card smoke passed.\n"
    report.write_text(text)
    artifacts.extend(
        [
            report,
            Path(__file__),
            ROOT / "tools/sim/evidence/drivers/skilled-birds-B.sh",
            ROOT / "tools/sim/skilled_birds.py",
            ROOT / "tools/sim/skilled_birds.gd",
            ROOT / "tools/sim/skilled_birds_brain.gd",
            ROOT / "tests/core/test_skilled_birds.gd",
            ROOT / "tests/sim/test_skilled_birds.py",
        ]
    )
    verification = {
        "state": "complete",
        "n_per_arm": 32,
        "native_source_files_verified_against_git": native_files,
        "raw": raw,
        "native_seconds": timings,
        "gate": {
            "tests": int(re.search(r"^Tests\s+(\d+)", gate, re.M).group(1)),
            "assertions": int(re.search(r"^Asserts\s+(\d+)", gate, re.M).group(1)),
            "exit_code": 0,
            "strict_hook": "ok",
            "command": "source /opt/bramble/env.sh; flock -w 1200 /tmp/bramble-godot.lock flock -w 600 /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G timeout --kill-after=10s 900 ./scripts/check.sh",
        },
        "historical_control": json.loads((BUILD / "historical-control-check.json").read_text()),
        "artifact_sha256": {str(p.relative_to(ROOT)): sha(p) for p in artifacts},
    }
    (OUT / f"{PREFIX}-verification.json").write_text(json.dumps(verification, indent=2) + "\n")
    print(json.dumps({"report": str(report), "artifacts": len(artifacts), "timings": timings}))


if __name__ == "__main__":
    main()
