#!/usr/bin/env python3
"""Combine the one shop-cycle rerun with retained pre-fix C/frozen measurements."""

import argparse
import copy
from pathlib import Path

from evidence_io import read_json
from quilboar_h1 import ARMS, ROOT, load_lobbies
from quilboar_h1_report import summarize, write_report


def combine(original, rerun):
    if set(rerun["arms"]) != {"B", "uncut"}:
        raise ValueError("one complete B/uncut rerun is required")
    if any(rerun["arms"][arm]["lobbies"] != ARMS[arm] for arm in ("B", "uncut")):
        raise ValueError("rerun lobby budget is incomplete")
    output = copy.deepcopy(original)
    for arm in ("B", "uncut"):
        output["arms"][arm] = copy.deepcopy(rerun["arms"][arm])
    output["criteria"]["accounting"]["arms"]["B"] = copy.deepcopy(rerun["criteria"]["accounting"]["arms"]["B"])
    output["criteria"]["accounting"]["deciding_arms"] = ["B"]
    output["criteria"]["accounting"]["passes"] = output["criteria"]["accounting"]["arms"]["B"]["passes"]
    output["criteria"]["accounting"]["arms"]["B"]["deciding"] = True
    output["criteria"]["accounting"]["arms"]["C"]["deciding"] = False
    output["criteria"]["fidelity"] = copy.deepcopy(rerun["criteria"]["fidelity"])
    output["arm_versions"] = {"B": "post-fix", "uncut": "post-fix", "C": "pre-fix", "uncut_frozen": "pre-fix"}
    output["cycle_fix_rerun"] = True
    output["qualification"] = (
        "One fixed-budget rerun: B150 and uncut100, with four shop-bought cycles separate from Created cards. "
        "C150 and frozen100 retain their original pre-fix results. Only post-fix B decides rerun accounting; "
        "fidelity uses post-fix uncut. Declared 11-cost paper denominators remain unchanged. "
        "The frozen arm is not a controlled size ablation against post-fix uncut; use the archived "
        "pre-fix uncut for that comparison. No further tuning follows an accounting failure."
    )
    output["measurement_selection"] = {
        "selected_lobbies": 500,
        "new_lobbies": 250,
        "original_acquired_lobbies": 500,
        "old_B_and_uncut": "superseded, never pooled with the post-fix arms",
        "original_report": "tools/sim/evidence/quilboar-h1/summary.json.gz",
        "native_content": "wave-1 Birds/Fairies plus four current legacy engine profiles",
        "native_rates": "committed tree defaults in all arms; C varies reference dials only",
    }
    output.pop("progress", None)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--folder", type=Path, default=ROOT / "build/quilboar-h1-cycle-fix/run")
    parser.add_argument("--original", type=Path, default=ROOT / "tools/sim/evidence/quilboar-h1/summary.json.gz")
    parser.add_argument("--out", type=Path, default=ROOT / "docs/ideation/reference/quilboar/h1")
    args = parser.parse_args()
    progress = read_json(args.folder / "progress.json")
    if progress["state"] != "complete" or progress["completed"] != {"B": 150, "uncut": 100}:
        raise ValueError("the 150+100 rerun is incomplete")
    rerun = summarize(load_lobbies(progress))
    output = combine(read_json(args.original), rerun)
    output["rerun_progress"] = progress
    write_report(output, args.out)


if __name__ == "__main__":
    main()
