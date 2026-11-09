#!/usr/bin/env python3
"""Offline report for the frozen wave-1 accounting check; no new gameplay bars."""

import argparse
import csv
import hashlib
import re
import statistics
from collections import Counter
from pathlib import Path

from evidence_io import read_json, write_json
from lever_sweep import ROOT, atomic_json, file_sha
from wave1_accounting import LINES, ROUNDS, measurements

PAPER_REFERENCE = ROOT / "tools/sim/evidence/wave1-accounting-paper.json"

PIECES = (
    "old_moth_annis",
    "cluricaun",
    "lob_lie_by_the_fire",
    "silky",
    "fairy_monarch",
    "queen_of_elfland",
    "cradle_fetch",
    "mrs_stork",
    "mr_redbreast",
    "mother_goose",
    "great_lump",
)


def load_paper_reference(path=PAPER_REFERENCE):
    """Keep the published denominator paired with the archived accounting run."""
    return read_json(path)


def diagnostic(rows):
    if not rows:
        return {"boards": 0}
    present = Counter()
    for row in rows:
        present.update({u["def_id"] for u in row["units"] if u["active"]})
    rings = [sum(int(effect.get("count", 0)) for slot in row["slots"] for effect in slot) for row in rows]
    return {
        "boards": len(rows),
        "tier_median": statistics.median(r["tier"] for r in rows),
        "tier6_share": sum(r["tier"] == 6 for r in rows) / len(rows),
        "ring_size_median": statistics.median(r["ring_size"] for r in rows),
        "rings_median": statistics.median(rings),
        "homecomings_median": statistics.median(r["homecomings"] for r in rows),
        "largest_share_median": statistics.median(r["largest_share"] for r in rows),
        "active_piece_presence": {
            name: {"boards": present[name], "share": present[name] / len(rows)} for name in PIECES
        },
    }


def compare(real, paper, reconciled):
    result = {}
    for number in map(str, ROUNDS):
        median = real["rounds"][number]["median"]
        interval = real["rounds"][number]["ci95"]
        expected, diagnostic = paper[number]["pre_start"], reconciled[number]["pre_start"]
        result[number] = {
            "real": median,
            "real_ci95": interval,
            "paper_pre_start": expected,
            "real_div_paper": median / expected if median is not None else None,
            "ratio_ci95": [v / expected for v in interval] if interval else None,
            "built_timing_paper_pre_start": diagnostic,
            "real_div_built_timing_paper": median / diagnostic if median is not None else None,
            "built_timing_ratio_ci95": [v / diagnostic for v in interval] if interval else None,
        }
    point = result["12"]["real_div_paper"]
    result["r12_inside_0_5_to_2"] = 0.5 <= point <= 2 if point is not None else None
    return result


def summarize(rows, seeds, paper, replicates=2000, bootstrap_seed=19014531):
    lines = {}
    for line in LINES:
        selected = [row for row in rows if row["line"] == line]
        real = measurements(selected, seeds, replicates, bootstrap_seed)
        name = line.removeprefix("line_")
        real["comparison"] = compare(
            real, paper["authored_paper_pre_start"][name], paper["built_timing_reconciliation"][name]
        )
        real["r12_diagnostics"] = diagnostic([r for r in selected if r["round"] == 12])
        real["post_start_medians_for_context"] = {
            str(r): statistics.median(values)
            if (
                values := [
                    row["post_start_stats"]
                    for row in selected
                    if row["round"] == r and row["post_start_stats"] is not None
                ]
            )
            else None
            for r in ROUNDS
        }
        real["config_sensitive_r12_call"] = line == "line_birds_homecoming"
        lines[line] = real
    for line in LINES:
        survivors = {row["seed"] for row in rows if row["line"] == line and row["round"] == 12}
        seen = {seed: set() for seed in survivors}
        for row in rows:
            if row["line"] == line and row["seed"] in survivors and row["round"] <= 12:
                seen[row["seed"]].update(u["def_id"] for u in row["units"] if u["active"])
        lines[line]["r12_diagnostics"]["seen_on_board_r8_through_r12_among_r12_survivors"] = {
            card: sum(card in ids for ids in seen.values()) / len(seen) if seen else None for card in PIECES
        }
    committed = [row for row in rows if row["line"] in LINES]
    largest = min(
        LINES,
        key=lambda line: (
            lines[line]["comparison"]["12"]["real_div_paper"]
            if lines[line]["comparison"]["12"]["real_div_paper"] is not None
            else float("inf")
        ),
    )
    return {
        "lines": lines,
        "largest_r12_shortfall_line": largest,
        "preliminary_all_seat_growth": measurements(rows, seeds, replicates, bootstrap_seed)["preliminary_growth"],
        "preliminary_committed_only_growth": measurements(committed, seeds, replicates, bootstrap_seed)[
            "preliminary_growth"
        ],
        "growth_qualification": "Preliminary pre-start pooled-survivor median growth, not within-player compounding. Includes Hard for all-seat estimate; committed-only and per-line figures are separate. No growth pass/fail for this accounting step.",
        "sole_criterion": "Each written line real R12 median / paper pre-start board inside inclusive [0.5, 2]. Intervals reported; no additional bars.",
        "population": "Committed seat of each assigned line only for line comparisons. Original tempo seat identity retained after its R7 switch. Surviving boards at each round; no zero imputation for eliminated seats.",
        "uncertainty": "95% percentile bootstrap of all predeclared independent lobby seeds, including eliminated empty clusters; all seats/rounds kept together. Paper is a fixed authored plan, not estimated data.",
    }


def load_run(plan_path, progress_path):
    plan, progress = read_json(plan_path), read_json(progress_path)
    if progress["plan_sha256"] != file_sha(plan_path) or progress["state"] != "complete":
        raise ValueError("complete frozen run required")
    seeds = list(range(plan["first_seed"], plan["first_seed"] + plan["games"]))
    covered, rows, seat_labels = [], [], []
    player_hashes = {}
    for chunk in progress["chunks"]:
        if file_sha(ROOT / chunk["capture"]) != chunk["capture_gzip_sha256"]:
            raise ValueError("changed full fight capture archive")
        path = ROOT / chunk["compact"]
        if file_sha(path) != chunk["compact_sha256"]:
            raise ValueError("changed compact capture")
        covered.extend(range(chunk["first_seed"], chunk["first_seed"] + chunk["lobbies"]))
        rows.extend(read_json(path))
        players_path = ROOT / chunk["players"]
        player_hashes[chunk["players"]] = file_sha(players_path)
        with players_path.open() as stream:
            players = list(csv.DictReader(stream))
        if len(players) != chunk["lobbies"] * 8:
            raise ValueError("incomplete starting/final seat labels")
        for player in players:
            starting = player["bot"].split(":")[0]
            seat_labels.append(
                {
                    "seed": int(player["seed"]),
                    "seat": int(player["seat"]),
                    "starting_line": starting,
                    "final_line": player["strategy"],
                }
            )
    if covered != seeds or progress["completed_lobbies"] != plan["games"]:
        raise ValueError("incomplete or duplicate seed coverage")
    keys = [(r["seed"], r["seat"], r["round"]) for r in rows]
    if len(keys) != len(set(keys)):
        raise ValueError("duplicate board observations")
    labels = {(label["seed"], label["seat"]): label for label in seat_labels}
    if len(labels) != len(seeds) * 8 or any(
        row["line"] != labels[row["seed"], row["seat"]]["starting_line"] for row in rows
    ):
        raise ValueError("capture/CSV starting-line labels disagree")
    return plan, progress, seeds, rows, seat_labels, player_hashes


def markdown(report):
    fmt = lambda x: f"{x:.3f}" if x is not None else "unknown"
    interval = lambda bounds: f"[{fmt(bounds[0])}, {fmt(bounds[1])}]" if bounds else "unknown"
    text = [
        "# Wave 1 accounting check",
        "",
        "Current wave-1 combat, pass 3 on, size/rate caps off, loop guards on, archived captured dials and the fixed published paper denominator. No new gameplay bars.",
        "",
        f"{report['lobbies']} independent fresh lobbies, seeds {report['first_seed']}–{report['last_seed']}. One seat per written line and four blind Hard seats; all tribes available, real heroes/fights/damage/elimination/shared pool. Four timing-pilot lobbies are excluded.",
        "",
        "This accounting run used all six tribes (`tribes_per_lobby=0`) and both caps off, rather than shipped `full_game()`'s five tribes and caps on, to keep all four committed lines eligible in every lobby; Homecoming's 0.44× R12 call is config-sensitive because six-tribe shops offer Birds less often.",
        "",
        f"Godot simulation time: {report['godot_simulation_seconds']:.1f} s. Chunk execution wall time: {report['chunk_wall_seconds']:.1f} s (includes startup, locking, compression and validation). The full gate uses the same worker's harness lock, so its time can appear as waiting in one chunk. No concurrent Godot processes from this worker.",
        "",
        report["population"],
        "",
        report["uncertainty"],
        "",
        "The only criterion is the R12 real/paper ratio inside 0.5–2×. The point is classified; intervals are reported, without an extra confidence-bound gate.",
        "",
        "| Line | Round | Real pre-start median [seed 95% interval] | Boards | Paper pre-start | Real / paper [95% interval] | R12 inside 0.5–2× |",
        "|---|---:|---|---:|---:|---|---|",
    ]
    for name, line in report["lines"].items():
        for r in map(str, ROUNDS):
            row = line["comparison"][r]
            decision = str(line["comparison"]["r12_inside_0_5_to_2"]) if r == "12" else "—"
            if r == "12" and name == "line_birds_homecoming":
                decision += " (config-sensitive)"
            text.append(
                f"| {name.removeprefix('line_')} | {r} | {fmt(row['real'])} {interval(row['real_ci95'])} | {line['rounds'][r]['boards']} | {fmt(row['paper_pre_start'])} | {fmt(row['real_div_paper'])} {interval(row['ratio_ci95'])} | {decision} |"
            )
    text.extend(
        [
            "",
            "## Counting and built-dial reconciliation",
            "",
            report["paper"]["conversion"]["birds"],
            "",
            report["paper"]["conversion"]["fairies"],
            "",
            "Bird paper figures were rerun with the built h/s/k/f/g/egg values and fights disabled. Fairy figures were rerun with Fetch 0.5, guards on and the built Lob/Monarch/Queen values. The original Fairy `.out.txt` is absent; current source is rerun and hashed.",
            "",
            "Two intentional timing changes have no equivalent original CLI dial: One Swallow is one turn in the build but two in the paper script; Cluricaun adds +1 Ring size at tier-up in the build but every third rainbow-complete End of Turn in the paper. The authored denominator above preserves those old algorithms rather than hiding the difference. A separately labelled timing reconciliation applies only these two built events to the same authored arrivals and budgets; it is not a Godot reproduction.",
            "",
            "| Line | Round | Built-timing paper | Real / built-timing paper |",
            "|---|---:|---:|---:|",
        ]
    )
    for name, line in report["lines"].items():
        for r in map(str, ROUNDS):
            c = line["comparison"][r]
            text.append(
                f"| {name.removeprefix('line_')} | {r} | {fmt(c['built_timing_paper_pre_start'])} | {fmt(c['real_div_built_timing_paper'])} |"
            )
    text.extend(
        [
            "",
            "## Preliminary pre-start growth",
            "",
            report["growth_qualification"],
            "",
            "| Population | R8–R14 geometric growth per round [95% seed interval] |",
            "|---|---|",
        ]
    )
    for label, growth in [
        ("All eight seats", report["preliminary_all_seat_growth"]),
        ("Committed seats only", report["preliminary_committed_only_growth"]),
        *[(name.removeprefix("line_"), line["preliminary_growth"]) for name, line in report["lines"].items()],
    ]:
        text.append(f"| {label} | {fmt(growth['point'])} {interval(growth['ci95'])} |")
    text.extend(
        [
            "",
            "## Accounting diagnostics",
            "",
            "| Line | R12 survivors / lobbies | Tier 6 | Median Ring size | Median Rings | Annis present | Cluricaun present | Monarch present | Queen present |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for name, line in report["lines"].items():
        d = line["r12_diagnostics"]
        p = d["active_piece_presence"]
        text.append(
            f"| {name.removeprefix('line_')} | {d['boards']}/{report['lobbies']} | {d['tier6_share']:.1%} | {fmt(d['ring_size_median'])} | {fmt(d['rings_median'])} | {p['old_moth_annis']['share']:.1%} | {p['cluricaun']['share']:.1%} | {p['fairy_monarch']['share']:.1%} | {p['queen_of_elfland']['share']:.1%} |"
        )
    text.extend(
        [
            "",
            f"Largest measured R12 shortfall: **{report['largest_r12_shortfall_line']}**. Interpret engine availability and Ring size/count against the authored state; these lobbies do not execute the paper's guaranteed arrivals, purchases and spell/thank/tithe sequences. Partial prose execution in the shared Hard adapters, real shop supply, pool competition and survival selection can all contribute. This measures these scripts against their accounting plan, not an isolated causal estimate of card balance.",
            "",
            "Exact source/config/model hashes, conversions, per-line diagnostics and archive provenance are in `tools/sim/evidence/wave1-accounting-results.json` and its plan/paper/progress files. Raw captures remain under `build/sim/wave1-accounting/run/` as gzip JSONL. Post-start medians are included beside pre-start in the JSON for context.",
            "",
        ]
    )
    largest = report["largest_r12_shortfall_line"]
    if largest.startswith("line_fairies"):
        actual = report["lines"][largest]["r12_diagnostics"]
        expected = report["paper"]["authored_paper_pre_start"][largest.removeprefix("line_")]["12"]
        seen = actual["seen_on_board_r8_through_r12_among_r12_survivors"]
        text.extend(
            [
                f"For {largest}, R12 median Ring size is {fmt(actual['ring_size_median'])} versus paper {fmt(expected['ring_size'])}, "
                f"and median Ring count {fmt(actual['rings_median'])} versus paper {fmt(expected['rings'])}. "
                f"{actual['tier6_share']:.1%} of its R12 survivors have reached tier 6. "
                f"Among those survivors, Lob was seen on board during R8–R12 in {seen['lob_lie_by_the_fire']:.1%} "
                f"and Silky in {seen['silky']:.1%}. These are observed-presence windows, not lifetime purchase or thank counts. "
                "The likely large gap is failure to realize the paper's accumulated Rings/Ring size and engine sequence under actual shops and these scripts. "
                "The timing-reconciled denominator above shows whether the two known paper/build timing changes explain the R12 gap.",
                "",
            ]
        )
    return "\n".join(text)


def project_rows(rows):
    """Small sufficient analysis rows; full fight inputs stay in hashed local archives."""
    return [
        {
            **{key: value for key, value in row.items() if key not in ("units", "slots")},
            "units": [{"active": True, "def_id": unit["def_id"]} for unit in row["units"] if unit["active"]],
            "slots": [[{"count": sum(int(effect.get("count", 0)) for slot in row["slots"] for effect in slot)}]],
        }
        for row in rows
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", type=Path, default=ROOT / "tools/sim/evidence/wave1-accounting-plan.json")
    parser.add_argument("--progress", type=Path, default=ROOT / "build/sim/wave1-accounting/run/progress.json")
    parser.add_argument("--out", type=Path, default=ROOT / "tools/sim/evidence/wave1-accounting-results.json")
    parser.add_argument("--markdown", type=Path, default=ROOT / "docs/ideation/evidence/wave1-accounting.md")
    parser.add_argument(
        "--archived", type=Path, help="Rebuild from committed sufficient analysis rows, no local captures"
    )
    args = parser.parse_args()
    if args.archived:
        archive = args.archived
        saved = read_json(args.archived)
        plan = read_json(args.plan)
        if saved["plan_sha256"] != file_sha(args.plan):
            raise ValueError("archived rows belong to another plan")
        progress, rows = saved["progress"], saved["rows"]
        seeds = list(range(plan["first_seed"], plan["first_seed"] + plan["games"]))
        labels, player_hashes = saved["seat_labels"], saved["player_csv_sha256"]
        progress_sha = saved["progress_sha256"]
        execution_logs = saved["execution_logs"]
    else:
        plan, progress, seeds, rows, labels, player_hashes = load_run(args.plan, args.progress)
        progress_sha = file_sha(args.progress)
        execution_logs = {
            chunk["players"].removesuffix(".players.csv") + ".log": (
                ROOT / (chunk["players"].removesuffix(".players.csv") + ".log")
            ).read_text()
            for chunk in progress["chunks"]
        }
        archive = ROOT / "tools/sim/evidence/wave1-accounting-boards.json.gz"
        write_json(
            archive,
            {
                "plan_sha256": file_sha(args.plan),
                "progress_sha256": progress_sha,
                "progress": progress,
                "rows": project_rows(rows),
                "execution_logs": execution_logs,
                "seat_labels": labels,
                "player_csv_sha256": player_hashes,
                "scope": "Sufficient analysis rows only, not refight inputs. Original full capture hashes and local paths are in progress.",
            },
        )
    paper = load_paper_reference()
    result = summarize(rows, seeds, paper, plan["bootstrap_replicates"], plan["bootstrap_seed"])
    result.update(
        paper=paper,
        lobbies=len(seeds),
        first_seed=seeds[0],
        last_seed=seeds[-1],
        chunk_wall_seconds=sum(chunk["seconds"] for chunk in progress["chunks"]),
        plan_sha256=file_sha(args.plan),
        progress_sha256=progress_sha,
        report_source_sha256=file_sha(Path(__file__)),
    )
    result["analysis_archive"] = {
        "path": str(archive.relative_to(ROOT)) if archive.is_relative_to(ROOT) else str(archive),
        "sha256": file_sha(archive),
    }
    result["godot_simulation_seconds"] = sum(
        float(re.search(r"bench: wave1_accounting .* in ([0-9.]+) s", log).group(1)) for log in execution_logs.values()
    )
    result["execution_log_sha256"] = {
        path: hashlib.sha256(text.encode()).hexdigest() for path, text in execution_logs.items()
    }
    labels_path = ROOT / "tools/sim/evidence/wave1-accounting-seat-labels.json.gz"

    write_json(labels_path, labels)
    result["seat_labels"] = {
        "path": str(labels_path.relative_to(ROOT)),
        "sha256": file_sha(labels_path),
        "records": len(labels),
        "starting_source": "players.csv bot / capture assigned_line",
        "final_source": "players.csv strategy (never used for accounting grouping)",
        "player_csv_sha256": player_hashes,
        "committed_transitions": dict(
            Counter(
                label["starting_line"] + " -> " + label["final_line"]
                for label in labels
                if label["starting_line"] in LINES
            )
        ),
    }
    atomic_json(args.out, result)
    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.markdown.write_text(markdown(result))


if __name__ == "__main__":
    main()
