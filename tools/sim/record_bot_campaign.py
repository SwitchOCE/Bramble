#!/usr/bin/env python3
"""Record completed, fixed-size bot experiments; optionally commit only their evidence.

Usage: record_bot_campaign.py <campaign-dir> [--commit]
The campaign must provide aa/result.json, saving/result.json and candidate-ready.json.
A source/branch/clean-tree guard prevents a delayed job from editing a different checkout state.
The complete report is always written under the campaign directory, even if that guard fails.
"""

from __future__ import annotations

import argparse
import json
import math
import subprocess
from pathlib import Path


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def report(aa: dict, saving: dict, ready: dict) -> str:
    if aa["paired_seeds"] != 200 or saving["paired_seeds"] != 500:
        raise ValueError("refusing to report incomplete fixed-size experiments")
    for row in (aa, saving):
        if not math.isfinite(row["margin_95"]):
            raise ValueError("non-finite uncertainty")
    if aa["margin_95"] <= 0:
        raise ValueError("stochastic A/A must have a nonzero margin")
    lines = [
        "## Completed stochastic A/A and first saving candidate",
        "",
        f"Frozen candidate source `{ready['source_revision']}` over `8c78def`; official Godot 4.7.2 release runtime, "
        "20 search fights, CPUs 0–1. Both seed ranges were declared before evaluation; neither was used for tuning.",
        "",
        "| Experiment | Paired seeds / games | Place gain ±95% margin | Verdict |",
        "|---|---:|---:|---|",
    ]
    for row in (aa, saving):
        lines.append(
            f"| {row['candidate']} vs hard | {row['paired_seeds']} / {row['games']} | "
            f"{row['gain']:+.4f} ±{row['margin_95']:.4f} | {row['verdict']} |"
        )
    lines += [
        "",
        f"Observed stochastic-null 200-seed margin: **±{aa['margin_200']:.4f} places**. "
        f"Projected 500-seed margin: **±{aa['margin_500']:.4f}**, assuming unchanged independent-seed variance. "
        f"The saving candidate's actual 500-seed margin is **±{saving['margin_95']:.4f}**. "
        "These are precision measures, not guaranteed detection thresholds. Candidate-dependent variance and "
        "the required 0.15 mean gain also matter. One passing A/A is not a study of CI coverage.",
        "",
        "| Experiment / policy | Bot turns | Mean ms | p95 ms |",
        "|---|---:|---:|---:|",
    ]
    for row in (aa, saving):
        for policy, timing in row["turns"].items():
            lines.append(
                f"| {row['name']} / {policy} | {timing['n']} | {timing['mean_ms']:.2f} | {timing['p95_ms']:.2f} |"
            )
    if "wall_seconds_per_game" in saving:
        seconds = saving["wall_seconds_per_game"]
        lines += [
            "",
            f"Saving trial full-game cost: {seconds:.2f} summed shard-wall seconds per game "
            f"(about {seconds * 2000 / 3600:.2f} core-hours for 2,000 such head-to-head games "
            "at the same load; this is a projection, not a spread run).",
        ]
    lines += [
        "",
        "The AA ran alongside development checks; its times include contention. The saving experiment uses "
        "the same immutable release pack for both arms. Release timings must not be compared directly with "
        "the earlier editor profiling figures. No real device was measured.",
        "",
        f"Calibration passed: **{aa['verdict'] == 'PASS A/A'}**. "
        "The saving implementation remains a tools-only candidate pending review; no player-facing bot was replaced.",
        "",
        f"AA players SHA-256: `{aa['players_sha256']}`. Saving players SHA-256: `{saving['players_sha256']}`.",
        f"Candidate PCK SHA-256: `{ready['runtime']['godot-release.pck']}`. "
        "Raw CSVs and generated per-strategy reports remain under `build/sim/yardstick-v2/`.",
    ]
    return "\n".join(lines) + "\n"


def source_is_unchanged(root: Path, source: str) -> bool:
    if git(root, "branch", "--show-current") != "ideation/bots":
        return False
    ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", source, "HEAD"], cwd=root, check=False)
    if ancestor.returncode:
        return False
    paths = ["src", "content", "tools", "tests", "scripts", "project.godot", "export_presets.cfg"]
    return not git(root, "diff", "--name-only", source, "HEAD", "--", *paths) and not git(root, "status", "--porcelain")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("campaign", type=Path)
    parser.add_argument("--commit", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    folder = args.campaign.resolve()
    aa = json.loads((folder / "aa/result.json").read_text(encoding="utf-8"))
    saving = json.loads((folder / "saving/result.json").read_text(encoding="utf-8"))
    ready = json.loads((folder / "candidate-ready.json").read_text(encoding="utf-8"))
    text = report(aa, saving, ready)
    (folder / "campaign-report.md").write_text(text, encoding="utf-8")
    if not source_is_unchanged(root, ready["source_revision"]):
        raise SystemExit(
            "Report saved in campaign directory; branch/source/checkout changed, tracked evidence untouched"
        )
    target = root / "docs/ideation/evidence/bots-yardstick.md"
    existing = target.read_text(encoding="utf-8")
    if "## Completed stochastic A/A and first saving candidate" in existing:
        raise SystemExit("Completed report already recorded")
    target.write_text(existing.rstrip() + "\n\n" + text, encoding="utf-8")
    if args.commit:
        subprocess.run(
            [
                "git",
                "commit",
                "--only",
                "-m",
                "Record stochastic A/A and 500-seed saving candidate result",
                "--",
                str(target),
            ],
            cwd=root,
            check=True,
        )
    print(text)


if __name__ == "__main__":
    main()
