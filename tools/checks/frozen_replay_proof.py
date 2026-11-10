#!/usr/bin/env python3
"""Prove frozen replay fidelity, then compare every old/current structured value.

Run under one worker Godot slot (imports and captures run sequentially):
  source /opt/bramble/env.sh
  export XDG_DATA_HOME="$PWD/build/replay-proof/xdg/data"
  export XDG_CONFIG_HOME="$PWD/build/replay-proof/xdg/config"
  export XDG_STATE_HOME="$PWD/build/replay-proof/xdg/state"
  GODOT_SLOT_CLASS=worker scripts/godot_slot.sh python3 tools/checks/frozen_replay_proof.py

The baseline is the merged runtime before the presentation additions, not a new
fixture. Its raw canonical full-game bytes and raw combat JSON must reproduce
the existing fixture hashes/strings before any presentation fields are removed.
Projection omits only three ring_dance snapshot keys and aliases the one exact
Pass reminder edit in combat unit snapshot keyword_text entries. No other keys,
values, array order or reminder text are ignored; frozen fixtures are never written.
All large raw captures stay in ignored build/replay-proof for local inspection.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import shutil
import subprocess
import tarfile
from collections import Counter
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRESENTATION_KEYS = {"moved_count", "from_ring", "to_ring"}
FROZEN_PASS = "Pass X: your last unit, other than this, gains X"
CURRENT_PASS = "Pass X: your rightmost unit, other than this, gains X."
CAPTURE = Path("tools/checks/frozen_replay_capture.gd")


def run(command: list[str], log: Path) -> None:
    with log.open("w") as stream:
        result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=300)
    text = log.read_text()
    if result.returncode or "SCRIPT ERROR" in text or "ERROR:" in text:
        raise RuntimeError(f"failed ({result.returncode}): {' '.join(command)}; see {log}")


def strip(value: object, removed: Counter[str]) -> object:
    if isinstance(value, list):
        return [strip(item, removed) for item in value]
    if isinstance(value, dict):
        out = {}
        for key, item in value.items():
            if value.get("type") == "ring_dance" and key in PRESENTATION_KEYS:
                removed[key] += 1
            else:
                out[key] = strip(item, removed)
                if key == "keyword_text" and "uid" in value and "def_id" in value:
                    for entry in out[key]:
                        if entry.get("keyword") == "Pass" and entry.get("text") == CURRENT_PASS:
                            entry["text"] = FROZEN_PASS
                            removed["exact_pass_reminder_substitutions"] += 1
        return out
    return value


def differences(old: object, new: object, path: str = "$") -> list[str]:
    if isinstance(old, dict) and isinstance(new, dict):
        out = [f"{path}.{key}: removed" for key in sorted(old.keys() - new.keys())]
        out += [f"{path}.{key}: added" for key in sorted(new.keys() - old.keys())]
        for key in sorted(old.keys() & new.keys()):
            out += differences(old[key], new[key], f"{path}.{key}")
            if len(out) >= 20:
                break
        return out[:20]
    if isinstance(old, list) and isinstance(new, list):
        if len(old) != len(new):
            return [f"{path}: length {len(old)} != {len(new)}"]
        out = []
        for index, (before, after) in enumerate(zip(old, new, strict=True)):
            out += differences(before, after, f"{path}[{index}]")
            if len(out) >= 20:
                break
        return out[:20]
    return [] if old == new else [f"{path}: {old!r} != {new!r}"]


def counts(actual: dict, suite: str) -> dict[str, int]:
    if suite == "field":
        fights = actual["fights"]
        return {
            "fights": len(fights),
            "inputs": len(fights),
            "results": len(fights),
            "events": sum(len(fight["result"]["events"]) for fight in fights),
            "carry": sum(len(fight["result"]["carry"]) for fight in fights),
            "standing_rows": len(actual["standings"]),
            "game_log_keys": len(actual["game_log"]),
        }
    return {
        "fights": 1,
        "fixture_inputs": 1,
        "results": 1,
        "events": len(actual["events"]),
        "carry": len(actual["carry"]),
    }


def verify(work: Path, baseline: str) -> dict:
    # The identical harness must consume byte-identical frozen inputs on both runtimes.
    input_paths = (
        "tests/fixtures/field/normal-067429a3.json",
        "tests/fixtures/field/content-0946909.json",
        "tests/core/data/pass3_pool_replay.json",
        "tests/core/data/pass3_legacy_replay.json",
        str(CAPTURE),
    )
    for path in input_paths:
        assert (ROOT / path).read_bytes() == (work / "baseline" / path).read_bytes(), path
    old = json.loads((work / "old.json").read_text())
    new = json.loads((work / "current.json").read_text())
    field = json.loads((ROOT / "tests/fixtures/field/normal-067429a3.json").read_text())
    fixtures = {"field": field["games"]}
    for suite in ("pool", "legacy"):
        fixtures[suite] = json.loads((ROOT / f"tests/core/data/pass3_{suite}_replay.json").read_text())["cases"]
    report = {
        "baseline_runtime": baseline,
        "field_fixture_source": "067429a3",
        "pool_fixture_source": "f574eaf",
        "legacy_fixture_source": "c74c2b9",
        "frozen_fixtures_modified": False,
        "archived_current_inputs_and_capture_harness_byte_identical": True,
        "ignored_keys_only_on_ring_dance": sorted(PRESENTATION_KEYS),
        "exact_pass_reminder_alias": {
            "scope": "combat unit snapshot keyword_text entries (uid + def_id), keyword=Pass",
            "frozen_text": FROZEN_PASS,
            "current_text": CURRENT_PASS,
            "presentation_source": "content/schema/effects.json:936",
            "reason": "Only reminder wording changed; targeting, applied stats and all gameplay data remain compared.",
        },
        "compared": "all inputs, results, carry, every ordered event, standings and complete game log",
        "records": [],
    }
    # Validate every old raw output before normalizing any current output.
    for suite, entries in fixtures.items():
        assert len(old[suite]) == len(new[suite]) == len(entries), suite
        for previous, current, frozen in zip(old[suite], new[suite], entries, strict=True):
            assert previous["seed"] == current["seed"] == frozen["seed"]
            if suite == "field":
                assert json.loads(previous["canonical"]) == previous["actual"]
                digest = hashlib.sha256(previous["canonical"].encode()).hexdigest()
                assert digest == frozen["sha256"], f"baseline field seed {frozen['seed']} hash"
                assert len(previous["actual"]["fights"]) == frozen["fight_count"]
            else:
                assert previous["serialized"] == frozen["result"], f"baseline {suite} seed {frozen['seed']} bytes"
                assert json.loads(previous["serialized"]) == previous["actual"]
    for suite in fixtures:
        for case_index, (previous, current) in enumerate(zip(old[suite], new[suite], strict=True)):
            removed: Counter[str] = Counter()
            old_removed: Counter[str] = Counter()
            before = strip(deepcopy(previous["actual"]), old_removed)
            assert not old_removed, "presentation keys must be newly added"
            after = strip(deepcopy(current["actual"]), removed)
            diff = differences(before, after)
            assert not diff, f"{suite} seed {previous['seed']}:\n" + "\n".join(diff)
            report["records"].append(
                {
                    "suite": suite,
                    "case_index": case_index,
                    "seed": int(previous["seed"]),
                    "old_raw_sha256": hashlib.sha256(
                        previous.get("canonical", previous.get("serialized", "")).encode()
                    ).hexdigest(),
                    "old_raw_matches_frozen": True,
                    "complete_structures_equal_after_strip": True,
                    **counts(previous["actual"], suite),
                    "presentation_projection_counts": dict(sorted(removed.items())),
                }
            )
    totals: Counter[str] = Counter()
    projection: Counter[str] = Counter()
    for record in report["records"]:
        projection.update(record["presentation_projection_counts"])
        for key in ("fights", "inputs", "fixture_inputs", "results", "events", "carry", "standing_rows"):
            totals[key] += record.get(key, 0)
    report["totals"] = dict(sorted(totals.items()))
    report["totals"]["complete_game_logs"] = len(old["field"])
    report["presentation_projection_totals"] = dict(sorted(projection.items()))
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", default="bc9ee571")
    parser.add_argument("--compare-only", action="store_true")
    parser.add_argument("--summary", action="store_true", help="print compact proof output for commit messages")
    args = parser.parse_args()
    work = ROOT / "build/replay-proof"
    work.mkdir(parents=True, exist_ok=True)
    if not args.compare_only:
        archive = work / "baseline"
        if archive.exists():
            shutil.rmtree(archive)
        archive.mkdir()
        paths = ["project.godot", "icon.svg", "src", "content", "tests", "tools", "addons", "assets"]
        data = subprocess.check_output(["git", "archive", args.baseline, *paths], cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(data)) as tree:
            tree.extractall(archive, filter="data")
        (archive / CAPTURE).write_text((ROOT / CAPTURE).read_text())
        for label, project in (("old", archive), ("current", ROOT)):
            run(
                ["godot", "--headless", "--path", str(project), "--editor", "--import"],
                work / f"{label}-import.log",
            )
            run(
                [
                    "godot",
                    "--headless",
                    "--path",
                    str(project),
                    "--script",
                    f"res://{CAPTURE}",
                    "--",
                    str(work / f"{label}.json"),
                ],
                work / f"{label}-capture.log",
            )
    report = verify(work, args.baseline)
    (work / "proof.json").write_text(json.dumps(report, indent=2) + "\n")
    if args.summary:
        total = report["totals"]
        projection = report["presentation_projection_totals"]
        print(f"BASELINE {args.baseline}: raw frozen fidelity PASS (4 field, 8 pool, 12 legacy)")
        print("IDENTICAL: fixture input bytes and capture harness")
        print(f"PROJECTION: ring_dance only moved_count/from_ring/to_ring ({projection['moved_count']} snapshots)")
        print(
            "PROJECTION: exact mandated Pass reminder alias in unit keyword_text "
            f"({projection['exact_pass_reminder_substitutions']} occurrences)"
        )
        print(f"COMPARE: all {len(report['records'])} complete cases PASS; all other values/order retained")
        print(
            f"COVERAGE: {total['fights']} fights/results, {total['inputs']} game inputs + "
            f"{total['fixture_inputs']} fixed inputs, {total['events']} ordered events, "
            f"{total['carry']} carry entries, {total['standing_rows']} standings rows, "
            f"{total['complete_game_logs']} complete game logs"
        )
        print("FROZEN FIXTURES: unchanged; no hashes re-frozen")
    else:
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
