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
        "the historical 0.15 mean-gain rule also mattered in that trial. One passing A/A is not a study of CI coverage.",
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


def timing_acceptable(result: dict, candidate: str) -> bool:
    """Predeclared practical limit; descriptive timing comparison, not a speed significance test."""
    timings = result.get("turns", {})
    if candidate not in timings or "hard" not in timings:
        return False
    for metric in ("mean_ms", "p95_ms"):
        candidate_time = timings[candidate][metric]
        incumbent_time = timings["hard"][metric]
        if not (math.isfinite(candidate_time) and math.isfinite(incumbent_time)):
            return False
        if incumbent_time <= 0 or candidate_time > 1.05 * incumbent_time:
            return False
    return True


def trial_report(result: dict, ready: dict) -> str:
    if result["paired_seeds"] != 500 or result["games"] != 1000:
        raise ValueError("refusing a partial 500-pair candidate result")
    gain, margin = result["gain"], result["margin_95"]
    if not math.isfinite(gain) or not math.isfinite(margin) or margin < 0:
        raise ValueError("invalid candidate uncertainty")
    calibration = ready["calibration"]
    aa_passed = (
        calibration["paired_seeds"] == 200
        and 0 < calibration["margin_95"] < math.inf
        and abs(calibration["gain"]) <= calibration["margin_95"]
    )
    timing_ok = timing_acceptable(result, ready["candidate"])
    clears_bar = aa_passed and gain - margin > 0 and timing_ok
    failures = 0 if clears_bar else ready["previous_failures"] + 1
    verdict = "MEETS NUMERICAL BAR; REVIEW PENDING" if clears_bar else "NO PROMOTION"
    first = ready["first_seed"]
    last = first + result["paired_seeds"] - 1
    lines = [
        f"## Bot candidate {ready['candidate']} ({first}–{last})",
        "",
        f"Trial {ready.get('trial_number', ready['previous_failures'] + 1)}, frozen source `{ready['source_revision']}` "
        f"on baseline `{ready['base_revision']}`. {ready.get('description', 'Carrier replacement candidate.')}",
        "",
        f"**{verdict}: {gain:+.4f} ±{margin:.4f} places** (two-sided 95% Student-t over "
        "500 paired seeds / 1,000 games). Positive means incumbent place minus candidate place. "
        "All seeds were fixed before evaluation; no early stopping or tuning on these outcomes.",
        "",
        f"Consecutive failed promotions: **{failures}**.",
    ]
    if failures >= 2:
        lines += ["**Stop rule reached: two consecutive failures. No third candidate is queued.**"]
    else:
        lines += [
            "No further candidate is queued by this run. No player-facing policy is replaced automatically."
        ]
    lines += [
        "",
        f"Stochastic A/A: {calibration['gain']:+.4f} ±{calibration['margin_95']:.4f} "
        "on 200 paired seeds. "
        f"Turn-time condition passed: **{timing_ok}** (predeclared maximum 5% mean and p95 overhead).",
        "",
        "| Policy | Turns | Mean ms | p95 ms |",
        "|---|---:|---:|---:|",
    ]
    for policy, timing in result["turns"].items():
        lines.append(f"| {policy} | {timing['n']} | {timing['mean_ms']:.2f} | {timing['p95_ms']:.2f} |")
    if "wall_seconds_per_game" in result:
        seconds = result["wall_seconds_per_game"]
        lines += [
            "",
            f"Cost: {seconds:.2f} summed shard-wall seconds per game; approximately "
            f"{seconds * 2000 / 3600:.2f} core-hours for 2,000 such head-to-head games at the same load. "
            "This is a projection, not a spread run. Release timings include any competing work; "
            "no phone was timed. Both arms use the same immutable Godot release pack and 20-fight budget.",
        ]
    lines += [
        "",
        f"Player CSV SHA-256: `{result['players_sha256']}`. "
        f"Runtime PCK SHA-256: `{ready['runtime']['godot-release.pck']}`. "
        f"Raw CSVs and per-strategy summaries remain under `{ready.get('artifact_dir', 'build/sim/carrier-upgrade/')}`.",
    ]
    return "\n".join(lines) + "\n"


def source_is_unchanged(root: Path, source: str) -> bool:
    if git(root, "branch", "--show-current") != "ideation/bots":
        return False
    ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", source, "HEAD"], cwd=root, check=False)
    if ancestor.returncode:
        return False
    paths = ["src", "content", "tools", "tests", "scripts", "project.godot", "export_presets.cfg"]
    return not git(root, "diff", "--name-only", source, "HEAD", "--", *paths) and not git(
        root, "status", "--porcelain"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("campaign", type=Path)
    parser.add_argument("--commit", action="store_true")
    parser.add_argument("--trial", action="store_true", help="record one later 500-pair candidate")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    folder = args.campaign.resolve()
    ready = json.loads((folder / "candidate-ready.json").read_text(encoding="utf-8"))
    if args.trial:
        result = json.loads((folder / "result.json").read_text(encoding="utf-8"))
        text = trial_report(result, ready)
    else:
        aa = json.loads((folder / "aa/result.json").read_text(encoding="utf-8"))
        saving = json.loads((folder / "saving/result.json").read_text(encoding="utf-8"))
        text = report(aa, saving, ready)
    (folder / "campaign-report.md").write_text(text, encoding="utf-8")
    if not source_is_unchanged(root, ready["source_revision"]):
        raise SystemExit(
            "Report saved in campaign directory; branch/source/checkout changed, tracked evidence untouched"
        )
    target = root / "docs/ideation/evidence/bots-yardstick.md"
    existing = target.read_text(encoding="utf-8")
    if text.splitlines()[0] in existing:
        raise SystemExit("Completed report already recorded")
    target.write_text(existing.rstrip() + "\n\n" + text, encoding="utf-8")
    if args.commit:
        subprocess.run(
            [
                "git",
                "commit",
                "--only",
                "-m",
                f"Record completed {ready['candidate']} 500-seed candidate result"
                if args.trial
                else "Record stochastic A/A and 500-seed saving candidate result",
                "--",
                str(target),
            ],
            cwd=root,
            check=True,
        )
    print(text)


if __name__ == "__main__":
    main()
