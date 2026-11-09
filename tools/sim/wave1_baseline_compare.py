#!/usr/bin/env python3
"""Compare two completed five-tribe baselines; deciding measures stay growth and R12 size."""

import argparse
from pathlib import Path

from evidence_io import read_json
from lever_sweep import ROOT, atomic_json, file_sha

HUMAN_EXAMPLES = {
    "tester_a": {"round12": 772, "round14": 2085, "ref": "origin/ideation/c-funprobe-a"},
    "tester_c": {"round12": 459, "round14": 883, "ref": "origin/ideation/c-funprobe-c"},
}


def combine(shipped, checkpoint):
    if shipped["source_commit"] != checkpoint["source_commit"] or shipped["rates"] != checkpoint["rates"]:
        raise ValueError("baseline settings must measure the same source and dials")
    if shipped.get("selected_seeds") != checkpoint.get("selected_seeds"):
        raise ValueError("baseline settings must use the identical fixed seed list")
    if shipped["lobbies"] != checkpoint["lobbies"]:
        raise ValueError("baseline settings must have the same fixed sample size")
    if shipped["config"]["tribes_per_lobby"] != 5 or checkpoint["config"]["tribes_per_lobby"] != 5:
        raise ValueError("both settings require five tribes")
    for key in ("card_size_caps", "card_rate_limits"):
        if shipped["config"][key] is not True or checkpoint["config"][key] is not False:
            raise ValueError("caps settings are reversed or mislabeled")
    result = {
        "settings": {"shipped": shipped, "checkpoint": checkpoint},
        "human_examples": HUMAN_EXAMPLES,
        "human_scope": "Two current-value playtest examples, verified against the supplied review logs; not a skilled-player population estimate.",
        "deciding_measures": ["pre-start median growth R8–R14", "realized committed R12 median with seed interval"],
        "no_other_bars": True,
    }
    result["human_comparison"] = {}
    for name, data in result["settings"].items():
        median = data["lines"]["line_birds_homecoming"]["median"]
        result["human_comparison"][name] = {
            "homecoming_r12_median": median,
            "human_a_div_script_median": 772 / median,
            "human_c_div_script_median": 459 / median,
        }
    return result


def markdown(result):
    interval = lambda x: f"[{x[0]:.3f}, {x[1]:.3f}]" if x else "unknown"
    number = lambda x: f"{x:.3f}" if x is not None else "unknown"
    text = [
        "# Wave 1 shipped-config baseline",
        "",
        "The deciding measures are pre-start lobby growth R8–R14 and each starting line’s realized committed R12 median with a whole-seed 95% interval. P90, tails, wins and R14 survival are reported only.",
        "",
        "Both settings use five tribes, current unchanged wave-1 rates, four committed line seats and four blind Hard seats. Seeds are the same presized eligible prefix of the original 640 accounting seeds, conditioned on Birds and Fairies both appearing in the native five-tribe draw. This is a calibration population, not an estimate of unconditional shipped lobbies.",
        "",
        "Shipped uses `full_game()` with caps on; checkpoint changes only `card_size_caps=false` and `card_rate_limits=false`. Source and preset/config hashes are recorded with each result. Common seeds ensure reproducibility; shop luck is unpaired because purchases and shared-pool use desynchronize draws.",
        "",
        "| Setting | Lobbies | Population | R8 median | R14 median | Growth/round [95% seed interval] |",
        "|---|---:|---|---:|---:|---|",
    ]
    for name, data in result["settings"].items():
        for population, row in data["growth"].items():
            text.append(
                f"| {name} | {data['lobbies']} | {population} | {number(row['rounds']['8']['median'])} | {number(row['rounds']['14']['median'])} | {number(row['point'])} {interval(row['ci95'])} |"
            )
    text += ["", "| Setting | Starting line | R12 median [95% seed interval] | R12 survivors |", "|---|---|---|---:|"]
    for name, data in result["settings"].items():
        for line, row in data["lines"].items():
            text.append(
                f"| {name} | {line.removeprefix('line_')} | {number(row['median'])} {interval(row['ci95'])} | {row['boards']} |"
            )
    text += [
        "",
        "B’s 900 is the future realized-board reference; these current-value medians provide the control. No extra band or tail bar is introduced.",
        "",
    ]
    for name, row in result["human_comparison"].items():
        text.append(
            f"Homecoming ({name}) has a realized R12 median of {row['homecoming_r12_median']:.1f}, versus the two human Birds games’ 459 and 772 ({row['human_c_div_script_median']:.2f}× and {row['human_a_div_script_median']:.2f}× that script median); the human R14 boards were 883 and 2,085. These are two user-reported examples, not a player-population estimate."
        )
    text += [
        "",
        "Tester C has 459/883 at R12/R14; tester A has 772/2,085. These supplied figures sum the post-fight review-log board stats, while harness medians use pre-start combat snapshots; the comparison is contextual, not a matched-phase estimate of skill. Human logs: `origin/ideation/c-funprobe-a` and `origin/ideation/c-funprobe-c`, under `docs/ideation/evidence/fun-probe/tester-{a,c}/*birds*`. Birds dials remain unchanged. The later skilled-play check will use current values; the former Birds C tail check is superseded.",
        "",
        "## Reported distributions and outcomes",
        "",
        "| Setting | Starting line | R12 p90 | ≥2× own line median | Lobby firsts | Combat wins R8–R14 | Alive before R14 |",
        "|---|---|---:|---:|---:|---:|---:|",
    ]
    for name, data in result["settings"].items():
        for line, row in data["lines"].items():
            text.append(
                f"| {name} | {line.removeprefix('line_')} | {row['p90_r12']:.1f} | {row['share_2x_line_median_r12']:.1%} | {row['lobby_win_rate']:.1%} | {row['fight_win_rate_r8_r14']:.1%} | {row['r14_alive']}/{data['lobbies']} ({row['r14_alive_share']:.1%}) |"
            )
    text += [
        "",
        "| Setting | Round | All-seat p90 | ≥2× pooled round median | Surviving boards |",
        "|---|---:|---:|---:|---:|",
    ]
    for name, data in result["settings"].items():
        for r in range(8, 15):
            row = data["report_only"][str(r)]
            text.append(f"| {name} | {r} | {row['p90']:.1f} | {row['share_2x_lobby_median']:.1%} | {row['boards']} |")
    text += [
        "",
        "Round medians contain survivors only. The bootstrap resamples whole lobby seeds, preserving seats and empty/eliminated clusters; these curves do not establish within-player compounding. “Alive at R14” means present before the R14 fight. Combat win rates are strict wins (draws are not wins), including real seats paired with ghosts.",
        "",
        "The source/preset runner is `tools/sim/wave1_baseline.py`. Another commit is copied with `git archive` under `build/`; another worktree is never imported or played in place. Future presets require explicit override JSON instead of invented dial values. Plans, progress, source/config/rate hashes and sufficient analysis archives accompany the results.",
        "",
    ]
    return "\n".join(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--shipped", type=Path, default=ROOT / "tools/sim/evidence/wave1-baseline-shipped.json")
    parser.add_argument("--checkpoint", type=Path, default=ROOT / "tools/sim/evidence/wave1-baseline-checkpoint.json")
    parser.add_argument("--out", type=Path, default=ROOT / "tools/sim/evidence/wave1-baseline-comparison.json")
    parser.add_argument("--markdown", type=Path, default=ROOT / "docs/ideation/evidence/wave1-shipped-baseline.md")
    args = parser.parse_args()
    settings = []
    for path in (args.shipped, args.checkpoint):
        data = read_json(path)
        archive = Path(data["analysis_archive"]["path"])
        if not archive.is_absolute():
            archive = ROOT / archive
        if file_sha(archive) != data["analysis_archive"]["sha256"]:
            raise ValueError("changed sufficient analysis archive")
        data["selected_seeds"] = read_json(archive)["plan"]["seeds"]
        settings.append(data)
    result = combine(*settings)
    result["result_sha256"] = {
        str(args.shipped): file_sha(args.shipped),
        str(args.checkpoint): file_sha(args.checkpoint),
    }
    atomic_json(args.out, result)
    args.markdown.write_text(markdown(result))


if __name__ == "__main__":
    main()
