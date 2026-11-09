#!/usr/bin/env python3
"""Archive complete H1 arms and their three-round accounting checkpoint, without Godot."""

import argparse
import json
import shutil
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from evidence_io import read_json, write_json  # noqa: E402
from lever_sweep import file_sha  # noqa: E402
from quilboar_h1 import ARMS  # noqa: E402
from quilboar_h1_report import QB, TRIBE_LINES, bootstrap, paper_reference, ratio_interval  # noqa: E402


def archive(arm, plan_path=None, run_folder=None, target_root=None):
    plan = read_json(plan_path or ROOT / "tools/sim/evidence/quilboar-h1-plan.json")
    progress = read_json((run_folder or ROOT / "build/quilboar-h1/run") / "progress.json")
    if progress["completed"][arm] != ARMS[arm]:
        raise ValueError("the arm's predeclared lobby budget is not complete")
    target = (target_root or ROOT / "tools/sim/evidence/quilboar-h1") / arm
    target.mkdir(parents=True, exist_ok=True)
    chunks, games = [], []
    for chunk in progress["chunks"]:
        if chunk["arm"] != arm:
            continue
        copied = dict(chunk)
        for field in ("compact", "capture", "players", "log"):
            source = ROOT / chunk[field]
            output = target / source.name
            if output.exists() and file_sha(output) != file_sha(source):
                raise ValueError("refusing to replace a frozen archive with different evidence: " + str(output))
            if not output.exists():
                shutil.copy2(source, output)
            copied[field] = str(output.relative_to(ROOT))
        games.extend(read_json(ROOT / copied["compact"]))
        chunks.append(copied)
    receipt = {
        "arm": arm,
        "lobbies": len(games),
        "source_commit": plan["source_commit"],
        "plan_sha256": progress["plan_sha256"],
        "chunks": chunks,
        "scope_seconds": sum(chunk["scope_seconds"] for chunk in chunks),
    }
    seeds = sorted(game["seed"] for game in games)
    rows = [{**row, "seed": game["seed"]} for game in games for row in game["rounds"] if row["line"] == QB]
    paper = paper_reference()["arms"][arm]["rounds"]
    checkpoint = {"arm": arm, "lobbies": len(games), "rounds": {}}
    for number in (9, 12, 15):
        selected = [r for r in rows if r["round"] == number]
        groups = {seed: [r["stats"] for r in selected if r["seed"] == seed] for seed in seeds}
        estimate = bootstrap(groups)
        expected = paper[str(number)]["stats"]
        checkpoint["rounds"][str(number)] = {
            "pre_start": estimate,
            "paper": expected,
            "real_div_paper": estimate["point"] / expected if estimate["point"] is not None else None,
            "median_bodies": statistics.median([len(r["units"]) for r in selected]) if selected else None,
            "median_tier": statistics.median([r["tier"] for r in selected]) if selected else None,
            "keystone_found_by_r12": sum(
                min(
                    (
                        r["keystone_found_round"]
                        for r in rows
                        if r["seed"] == seed and r.get("keystone_found_round") is not None
                    ),
                    default=99,
                )
                <= 12
                for seed in seeds
            )
            / len(seeds),
        }
    if arm == "uncut":
        all_rows = [{**row, "seed": game["seed"]} for game in games for row in game["rounds"]]
        values = {
            line: [r["stats"] for r in all_rows if r["line"] == line and r["round"] == 12]
            for line in (QB, *TRIBE_LINES)
        }
        qb = statistics.median(values[QB]) if values[QB] else None
        fidelity = {
            "lobbies": len(games),
            "quilboar_r12": qb,
            "quilboar_r12_survivors": len(values[QB]),
            "fidelity": {},
        }
        for line in TRIBE_LINES:
            median = statistics.median(values[line]) if values[line] else None
            ratio = qb / median if qb is not None and median else None
            fidelity["fidelity"][line] = {
                "median": median,
                "survivors": len(values[line]),
                "ratio": ratio,
                "passes": ratio is not None and ratio >= 4,
                **ratio_interval(all_rows, seeds, QB, line, 2000, 481516),
            }
        write_json(target / "fidelity-checkpoint.json", fidelity)
    write_json(target / "receipt.json", receipt)
    write_json(target / "accounting-checkpoint.json", checkpoint)
    print(json.dumps(checkpoint, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("arms", nargs="+", choices=list(ARMS))
    parser.add_argument("--plan", type=Path)
    parser.add_argument("--folder", type=Path)
    parser.add_argument("--target", type=Path)
    args = parser.parse_args()
    for selected_arm in args.arms:
        archive(selected_arm, args.plan, args.folder, args.target)
