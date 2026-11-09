#!/usr/bin/env python3
"""Report Step 3 B/C on the fixed shipped-control population; no new acceptance bars."""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

from evidence_io import read_json
from lever_sweep import ROOT, atomic_json, file_sha

SOURCE = "d5b5b4f8"
CONTROL = ROOT / "tools/sim/evidence/wave1-baseline-shipped.json"


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def load_setting(path):
    data = read_json(path)
    archive = Path(data["analysis_archive"]["path"])
    if not archive.is_absolute():
        archive = ROOT / archive
    if file_sha(archive) != data["analysis_archive"]["sha256"]:
        raise ValueError("changed sufficient analysis archive")
    analysis = read_json(archive)
    plan = analysis["plan"]
    for key in ("config", "rates", "source_commit"):
        if data[key] != plan[key]:
            raise ValueError("result disagrees with archived plan: " + key)
    data["selected_seeds"] = plan["seeds"]
    data["provenance"] = {
        "result_path": str(path),
        "result_sha256": file_sha(path),
        "config_sha256": digest(data["config"]),
        "rates_sha256": digest(data["rates"]),
        **{
            key: plan[key]
            for key in ("source_sha256", "measurement_script_sha256", "driver_sha256", "overrides")
            if key in plan
        },
    }
    field_players = [row for row in analysis["players"] if row["line"] == "hard_field"]
    if field_players and all("assigned_tribes" in row for row in field_players):
        data["noncommitted_tribe_drift"] = tribe_drift(field_players)
    data["round_fight_outcomes"] = {}
    for number in range(8, 15):
        rows = [r for r in analysis["boards"] if r["round"] == number]
        data["round_fight_outcomes"][str(number)] = {
            "fights": len(rows),
            "wins": sum(bool(r["fight_win"]) for r in rows),
            "draws": sum(bool(r["fight_draw"]) for r in rows),
        }
    return data


def tribe_drift(players):
    """Compare the seeded strategy's required tribe with last fight-start board majority."""
    rows = [row for row in players if row["line"] == "hard_field"]
    if len({(r["seed"], r["seat"]) for r in rows}) != len(rows):
        raise ValueError("duplicate noncommitted seat")
    for row in rows:
        if "assigned_build" not in row or "assigned_tribes" not in row:
            raise ValueError("missing noncommitted strategy assignment")
        if row["assigned_tribes"] is not None and not isinstance(row["assigned_tribes"], list):
            raise ValueError("invalid assigned tribes")
        if not row.get("final_tribe"):
            raise ValueError("missing last-fight board tribe")
    known = [r for r in rows if r["assigned_tribes"] is not None and r["assigned_build"]]
    assigned = [r for r in known if len(r["assigned_tribes"]) == 1]
    unassigned = [r for r in known if not r["assigned_tribes"]]
    multi = [r for r in known if len(r["assigned_tribes"]) > 1]
    different = [r for r in assigned if r["final_tribe"] != r["assigned_tribes"][0]]
    other = [r for r in different if r["final_tribe"] != "no_tribe"]
    return {
        "noncommitted_seats": len(rows),
        "unknown_assignment_seats": len(rows) - len(known),
        "assigned_tribal_seats": len(assigned),
        "unassigned_neutral_seats": len(unassigned),
        "multi_tribe_assignment_seats": len(multi),
        "different_final_label": len(different),
        "different_share_assigned": len(different) / len(assigned) if assigned else None,
        "different_share_all_noncommitted": len(different) / len(rows) if rows else None,
        "other_tribe_majority": len(other),
        "other_tribe_majority_share_assigned": len(other) / len(assigned) if assigned else None,
        "no_tribe_share_assigned": (len(different) - len(other)) / len(assigned) if assigned else None,
        "no_tribe_final": len(different) - len(other),
        "no_tribe_reasons": dict(
            Counter(r.get("no_tribe_reason", "unknown") for r in different if r["final_tribe"] == "no_tribe")
        ),
        "unassigned_final_tribes": dict(Counter(r["final_tribe"] for r in unassigned)),
        "transitions": [
            {"assigned_tribe": start, "final_tribe": final, "seats": count}
            for (start, final), count in sorted(
                Counter((r["assigned_tribes"][0], r["final_tribe"]) for r in assigned).items()
            )
        ],
    }


def peat_rates(data):
    return data.get("peat_rates") or data["report_only"].get("peat")


def combine(b, c, control_seeds):
    for label, data in (("B", b), ("C", c)):
        if not data["source_commit"].startswith(SOURCE):
            raise ValueError("Step 3 requires source " + SOURCE)
        seeds = data.get("selected_seeds")
        if seeds != control_seeds or len(seeds) != 320 or len(set(seeds)) != 320 or data["lobbies"] != 320:
            raise ValueError("Step 3 requires the identical 320 shipped-control seeds")
        config = data["config"]
        if config.get("tribes_per_lobby") != 5 or any(
            config.get(key) is not True for key in ("card_size_caps", "card_rate_limits")
        ):
            raise ValueError("Step 3 requires five tribes and both shipped caps on")
        if config.get("pass3_preset") != label:
            raise ValueError("mislabeled pass3_preset")
        overrides = data.get("provenance", {}).get("overrides", {})
        if overrides != {"pass3_preset": label}:
            raise ValueError("Step 3 requires only the authored pass3_preset override")
        if data.get("noncommitted_tribe_drift", {}).get("noncommitted_seats") != 1280:
            raise ValueError("missing full noncommitted tribe assignment diagnostic")
        if not peat_rates(data):
            raise ValueError("missing report-only Peat measurements")
    if b["source_commit"] != c["source_commit"]:
        raise ValueError("B/C must measure the same source")
    for key in b["config"].keys() | c["config"].keys():
        if b["config"].get(key) == c["config"].get(key) or key == "pass3_preset":
            continue
        if not all(key in d["rates"] and d["config"].get(key) == d["rates"][key] for d in (b, c)):
            raise ValueError("unrelated B/C config difference: " + key)
    return {
        "settings": {"B": b, "C": c},
        "deciding_measures": [
            "pre-start median growth R8–R14 (all and committed seats)",
            "realized committed R12 per-line median with whole-seed 95% intervals",
        ],
        "no_other_bars": True,
        "scope": "Step 3 committed-line calibration only; not all-Hard or field-best gate evidence.",
        "content_context": "Wave-1 re-base plus Bog fixes, with pass-2 Hunters and free-splashing anchors; not the later merged wave2a head.",
    }


def markdown(result):
    def num(value):
        return "unknown" if value is None else f"{value:.3f}"

    def pct(value):
        return "unknown" if value is None else f"{value:.1%}"

    def ci(value):
        return "unknown" if not value else f"[{num(value[0])}, {num(value[1])}]"

    lines = [
        "# Wave 1 Step 3 rebase: authored B/C, shipped caps on",
        "",
        "The two deciding measures are pre-start median growth R8–R14 (all seats and committed seats) and each committed starting line’s realized R12 median with a whole-seed 95% interval. All other measures below are report only; no new bars are introduced.",
        "",
        "Both presets use source `d5b5b4f8`, five tribes, both shipped caps on, four committed line seats and four blind Hard seats, on the identical 320 selected seeds from the [prior shipped control](wave1-shipped-baseline.md). Lobbies are conditioned on Birds and Fairies appearing in the native five-tribe draw, not unconditional shipped lobbies. Common seeds reproduce the sample; purchases and shared-pool use desynchronize shop luck, so shops are unpaired.",
        "",
        "These are the actual measured authored B/C rates, including C’s Birds dials. The separate Step 4 current-Birds 2× skilled-play check is not this C setting. This report does not establish all-Hard or field-best gate results.",
        "",
        "Source context: this run measures the wave-1 re-base plus Bog fixes with **pass-2 Hunters and free-splashing anchors**. The later merged wave2a head, with pass-3 Hunters and the narrowed pin filter, is a separate measurement.",
        "",
        "| Preset | Population | R8 median | R14 median | Growth/round [95% seed interval] |",
        "|---|---|---:|---:|---|",
    ]
    for label, data in result["settings"].items():
        for population, row in data["growth"].items():
            lines.append(
                f"| {label} | {population} | {num(row['rounds']['8']['median'])} | {num(row['rounds']['14']['median'])} | {num(row['point'])} {ci(row['ci95'])} |"
            )
    lines += ["", "| Preset | Starting line | R12 median [95% seed interval] | R12 survivors |", "|---|---|---|---:|"]
    for label, data in result["settings"].items():
        for line, row in data["lines"].items():
            lines.append(
                f"| {label} | {line.removeprefix('line_')} | {num(row['median'])} {ci(row['ci95'])} | {row['boards']} |"
            )
    lines += [
        "",
        "Round summaries contain survivors only, without zero imputation. Bootstrap sampling resamples whole lobby seeds, retaining eliminated empty clusters; these population curves do not establish within-player compounding. The prior control’s Birds Homecoming R12 median was 311 versus human examples 459/772. Human figures sum post-fight review-log stats while harness snapshots are pre-start; that comparison is context, not a matched-phase skill estimate.",
        "",
        "## Report-only distributions and outcomes",
        "",
        "| Preset | Line | R12 p90 | ≥2× own line median | Lobby firsts | Combat wins R8–R14 | Alive before R14 |",
        "|---|---|---:|---:|---:|---:|---:|",
    ]
    for label, data in result["settings"].items():
        for line, row in data["lines"].items():
            lines.append(
                f"| {label} | {line.removeprefix('line_')} | {num(row['p90_r12'])} | {pct(row['share_2x_line_median_r12'])} | {pct(row['lobby_win_rate'])} | {pct(row['fight_win_rate_r8_r14'])} | {row['r14_alive']}/{data['lobbies']} ({pct(row['r14_alive_share'])}) |"
            )
    lines += [
        "",
        "| Preset | Round | All-seat p90 | ≥2× pooled round median | Surviving boards | Strict wins / seat-fights |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for label, data in result["settings"].items():
        for number in range(8, 15):
            row = data["report_only"][str(number)]
            fight = data["round_fight_outcomes"][str(number)]
            lines.append(
                f"| {label} | {number} | {num(row['p90'])} | {pct(row['share_2x_lobby_median'])} | {row['boards']} | {fight['wins']}/{fight['fights']} |"
            )
    for label, data in result["settings"].items():
        report = data["report_only"]
        lines += [
            "",
            f"{label}: all-seat alive before R14: {report['r14_alive_all_seats']}/{data['lobbies'] * 8} ({pct(report['r14_alive_all_seats_share'])}).",
        ]
    lines += [
        "",
        "## Report-only noncommitted tribe drift",
        "",
        "Assigned tribe is the single `needs_tribes` entry of the concrete strategy dealt by the seeded `hard_field:varied` resolver at session creation. These Hard strategies are pinned; final strategy ID is not board composition. Final tribe uses the existing BenchTribes classifier on the last fight-start board: a unique tribe occupying strictly more than half the non-token slots. Neutral non-token units remain in the denominator; goldens count once, while tokens, away Birds and Belly contents do not add slots.",
        "",
        "The assigned-tribal denominator excludes neutral strategies with no required tribe, any multi-tribe assignment, and unknown assignments. “Not retaining assigned majority” means a different final label and includes `no_tribe`; the positive other-tribe majority and no-majority counts are separated. The all-seat share uses all 1,280 noncommitted seats, with unassigned seats retained in that denominator but never counted as a tribal mismatch. These are descriptive outcomes, without a new bar.",
        "",
        "| Preset | All noncommitted N | Assigned tribal N | Unassigned neutral N | Multi-tribe N | Unknown N | Not retaining assigned majority / assigned | Different / all noncommitted | Other-tribe majority / assigned | No tribe majority / assigned |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for label, data in result["settings"].items():
        drift = data["noncommitted_tribe_drift"]
        lines.append(
            f"| {label} | {drift['noncommitted_seats']} | {drift['assigned_tribal_seats']} | {drift['unassigned_neutral_seats']} | {drift['multi_tribe_assignment_seats']} | {drift['unknown_assignment_seats']} | {drift['different_final_label']} ({pct(drift['different_share_assigned'])}) | {pct(drift['different_share_all_noncommitted'])} | {drift['other_tribe_majority']} ({pct(drift['other_tribe_majority_share_assigned'])}) | {drift['no_tribe_final']} ({pct(drift['no_tribe_share_assigned'])}) |"
        )
    for label, data in result["settings"].items():
        drift = data["noncommitted_tribe_drift"]
        lines += [
            "",
            f"{label} unassigned neutral final labels: `{json.dumps(drift['unassigned_final_tribes'], sort_keys=True)}`. Assigned-tribal no-majority reasons: `{json.dumps(drift['no_tribe_reasons'], sort_keys=True)}`.",
            "",
        ]
    lines += ["| Preset | Assigned tribe | Final board tribe | Seats |", "|---|---|---|---:|"]
    for label, data in result["settings"].items():
        for row in data["noncommitted_tribe_drift"]["transitions"]:
            lines.append(f"| {label} | {row['assigned_tribe']} | {row['final_tribe']} | {row['seats']} |")
    lines += [
        "",
        "Wins exclude draws and include real seats paired with ghosts. Alive before R14 means present before its fight.",
        "",
        "## Report-only Peat rates",
        "",
    ]
    for label, data in result["settings"].items():
        peat = peat_rates(data)
        lines += [
            f"### {label}",
            "",
            *[peat[key] for key in ("scope", "denominator", "attribution", "gold_stage")],
            "",
            "| Round | Card / output | Card-present fights N | Zero-output share | Eligible instance-fights N | Output total | Mean / card-present fight | Mean / eligible instance-fight |",
            "|---|---|---:|---:|---:|---:|---:|---:|",
        ]
        for number, summary in [
            *sorted(peat["rounds"].items(), key=lambda item: int(item[0])),
            ("All", peat["all_rounds"]),
        ]:
            for card, name in (
                ("peat_king", "Peat King / raises"),
                ("peat_cutter", "Peat Cutter / credited next-turn gold"),
            ):
                row = summary[card]
                n = row["card_present_fights"]
                zero = row["zero_output_card_present_fights"] / n if n else None
                lines.append(
                    f"| {number} | {name} | {n} | {pct(zero)} | {row['eligible_instances']} | {row['output_total']} | {num(row['output_per_card_present_fight'])} | {num(row['output_per_eligible_instance_fight'])} |"
                )
        lines.append("")
    lines += [
        "## Resolved rates and provenance",
        "",
        "Config differences are restricted to `pass3_preset` and resolved rate-derived values. Full configs, rates, source manifests, archive references and computed hashes are retained in the comparison JSON. The source was archived for measurement; no other worktree is imported or played in place.",
        "",
        "| Rate | B | C |",
        "|---|---:|---:|",
    ]
    b, c = result["settings"]["B"], result["settings"]["C"]
    for key in sorted(b["rates"].keys() | c["rates"].keys()):
        lines.append(f"| `{key}` | {b['rates'].get(key, 'absent')} | {c['rates'].get(key, 'absent')} |")
    for label, data in result["settings"].items():
        provenance = data["provenance"]
        lines += [
            "",
            f"{label}: source `{data['source_commit']}`; plan SHA-256 `{data['plan_sha256']}`; config SHA-256 `{provenance['config_sha256']}`; resolved-rates SHA-256 `{provenance['rates_sha256']}`; result SHA-256 `{provenance['result_sha256']}`; analysis archive `{data['analysis_archive']['path']}` SHA-256 `{data['analysis_archive']['sha256']}`.",
        ]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--b", type=Path, required=True)
    parser.add_argument("--c", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--markdown", type=Path, default=ROOT / "docs/ideation/evidence/wave1-rebase.md")
    args = parser.parse_args()
    control = load_setting(CONTROL)
    result = combine(load_setting(args.b), load_setting(args.c), control["selected_seeds"])
    result["control"] = {
        "path": str(CONTROL),
        "sha256": file_sha(CONTROL),
        "analysis_archive": control["analysis_archive"],
    }
    atomic_json(args.out, result)
    args.markdown.write_text(markdown(result))


if __name__ == "__main__":
    main()
