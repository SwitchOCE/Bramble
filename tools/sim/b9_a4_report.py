"""Same-seat A4 distributions and predeclared extreme-miss diagnostics; never refit."""

import gzip
import json
import statistics
from collections import defaultdict

import b9_measure_report as measurement


def seat_data(folder, preset):
    with gzip.open(folder / f"{preset}.lobbies.json.gz", "rt") as stream:
        games = json.load(stream)
    seats, winners = defaultdict(dict), {}
    for game in games:
        for player in game["players"]:
            winners[game["seed"], player["seat"]] = player["place"] == 1
        for row in game["rounds"]:
            seats[row["line"]].setdefault((game["seed"], row["seat"]), {})[row["round"]] = row["stats"]
    return games, seats, winners


def windows(seats):
    result = {}
    for name, start, end in [("r6_r11", 6, 11), ("r11_r15", 11, 15)]:
        values = [
            (rs[end] / rs[start]) ** (1 / (end - start))
            for rs in seats.values()
            if start in rs and end in rs and rs[start] > 0
        ]
        result[name] = {"p10_median_p90": measurement.quantiles(values), "n": len(values)}
    return result


def magnitude(seats):
    # Fix every line to its R15 survivors for BOTH R14 and R15.
    cohort = {line: [rs for rs in group.values() if 14 in rs and 15 in rs] for line, group in seats.items()}
    out = {}
    for number in (14, 15):
        medians = {line: statistics.median(rs[number] for rs in group) for line, group in cohort.items() if group}
        if len(medians) < 2:
            out[str(number)] = {"ratio": None, "complete": False, "fires_10x": None}
            continue
        best = max(medians, key=medians.get)
        others = statistics.median(v for line, v in medians.items() if line != best)
        ratio = medians[best] / others if others > 0 else None
        tribe_best = {}
        for line, value in medians.items():
            tribe = line.split("_")[1]
            tribe_best[tribe] = max(tribe_best.get(tribe, 0), value)
        tribe_ratios = {}
        for tribe, value in tribe_best.items():
            denominator = (
                statistics.median(v for other, v in tribe_best.items() if other != tribe) if len(tribe_best) > 1 else 0
            )
            tribe_ratios[tribe] = value / denominator if denominator > 0 else None
        out[str(number)] = {
            "line": best,
            "ratio": ratio,
            "fires_10x": ratio >= 10 if ratio is not None else None,
            "line_medians": medians,
            "tribe_best_medians": tribe_best,
            "tribe_ratios": tribe_ratios,
            "cohort_n": {line: len(group) for line, group in cohort.items()},
            "complete": len(medians) == 12,
        }
    return out


def snowballs(games, winners):
    eligible, runaway, early_eligible, early_credit = 0, [], 0, 0.0
    for game in games:
        early = [row for row in game["rounds"] if row["round"] == 8]
        if early:
            early_eligible += 1
            high = max(row["stats"] for row in early)
            tied = [row for row in early if row["stats"] == high]
            early_credit += sum(winners[game["seed"], row["seat"]] for row in tied) / len(tied)
        late = sorted((row for row in game["rounds"] if row["round"] == 14), key=lambda r: r["stats"], reverse=True)
        if len(late) < 2 or late[1]["stats"] <= 0:
            continue
        eligible += 1
        ratio = late[0]["stats"] / late[1]["stats"]
        if ratio >= 10 and winners[game["seed"], late[0]["seat"]]:
            runaway.append({"seed": game["seed"], "seat": late[0]["seat"], "line": late[0]["line"], "ratio": ratio})
    return {
        "r8_leader_win_rate": early_credit / early_eligible if early_eligible else None,
        "r8_lobbies": early_eligible,
        "runaway_proxy_lobbies": runaway,
        "eligible_r14_lobbies": eligible,
        "runaway_proxy_share": len(runaway) / eligible if eligible else None,
        "most_lobbies_proxy": len(runaway) / eligible > 0.5 if eligible else None,
    }


def field_dominance(field):
    rounds = field["rounds"]
    candidates = set(rounds.get("12", {}).get("line_point_rates", {})) & set(
        rounds.get("14", {}).get("line_point_rates", {})
    )
    dominant = [
        line for line in sorted(candidates) if all(rounds[str(r)]["line_point_rates"][line] >= 0.8 for r in (12, 14))
    ]
    return {
        "lines_at_least_80pct_r12_and_r14": dominant,
        "complete": len(candidates) == 12,
        "flag": bool(dominant) if len(candidates) == 12 else None,
    }


def report(root, manifest):
    output = {
        "dry_run": manifest["dry_run"],
        "source_commit": manifest["source_commit"],
        "decisions_evaluated": not manifest["dry_run"],
        "manifest": manifest,
        "presets": {},
    }
    for preset, run in manifest["presets"].items():
        folder = root / preset / "lobbies/result"
        config = run["config"]
        seeds = list(range(config["first_seed"], config["first_seed"] + config["lobbies"]))
        result = measurement.summarize(folder, preset=preset, expected_seeds=seeds)
        games, seats, winners = seat_data(folder, preset)
        for line, rows in seats.items():
            result["confirmation"][line]["growth_windows"] = windows(rows)
        result["magnitude_r14_r15"] = magnitude(seats)
        result["snowballs"] = snowballs(games, winners)
        result["field"] = json.loads((root / preset / "field-report.json").read_text())
        result["field_dominance"] = field_dominance(result["field"])
        result["extreme_misses"] = {
            "outside_order_of_magnitude": any(
                v.get("fires_10x")
                or any(
                    ratio is not None and (ratio < 0.1 or ratio >= 10) for ratio in v.get("tribe_ratios", {}).values()
                )
                for v in result["magnitude_r14_r15"].values()
            ),
            "one_line_wins_regardless_proxy": result["field_dominance"]["flag"],
            "runaway_snowballs_in_most_lobbies_proxy": result["snowballs"]["most_lobbies_proxy"],
        }
        output["presets"][preset] = result
    return output


def spread(values, digits=2):
    return " / ".join(f"{value:,.{digits}f}" for value in values) if values else "—"


def markdown(result):
    rows = [
        "# Build 9 A4 measurement",
        "",
        "**DRY RUN ONLY: plumbing verification, not balance evidence.**"
        if result["dry_run"]
        else "Final merged-source A4; no refit.",
        "",
        f"Source: `{result['source_commit']}`. Both presets use matched lobby seeds and the a35_run1 roster.",
        "",
        "## Method and assumptions (C8)",
        "",
        "B and provisional C came from log-linear fits to realized engine R12 medians on the frozen run-1 "
        "cross-arm cohorts; "
        "integer/fractional values snap upward and card limits apply. C targets 1,800. Endpoints, shared "
        "scaling and Soup changed, "
        "so the old fits are estimates. This run measures the merged content and never refits.",
        "",
        "All totals are active pre-Start-of-Combat A+H. R12 uses surviving seats; growth R8-R14 uses the "
        "same R14-surviving seats "
        "with positive R8 totals, per-seat sixth-root ratios. Early/late growth similarly fixes survivors "
        "at each window end. "
        "R15/R12 divides medians of identical R15 survivors. Quantiles interpolate at (n-1)q. Survival "
        "counts and cohort n remain visible.",
        "",
        "R14 and R15 order-of-magnitude reads use each line's identical R15-surviving cohort, and compare "
        "the best line median "
        "with the unweighted median of the other line medians. The trigger is >=10x. Missing cohorts are "
        "explicitly incomplete.",
        "",
        "Field fights reuse tools/sim/field_fights.gd on complete captured states and blind placer layouts "
        "at R10/R12/R14. "
        "A seeded representative is sampled uniformly within each surviving committed line. One board per "
        "line gives equal line weight, "
        "excludes own-line opponents, and runs every cross-line pair in both orientations: at most 22 "
        "fights per line per round, "
        "below the 40 cap. Draws count half. This small first read has one board per line; it cannot "
        "estimate within-line board variation. "
        "Missing lines are recorded. Its 80%-at-both-R12/R14 dominance flag is a proxy, not proof of "
        "outcomes for every player choice.",
        "",
        "The three v3 extreme misses are (1) a tribe's best line outside an order of magnitude of the others, "
        "(2) one line winning whatever the player chooses, and (3) runaway snowballs in most lobbies. "
        "For (3), the predeclared diagnostic proxy is a >=10x R14 lead over the runner-up that eventually wins, "
        "in >50% of lobbies with two positive R14 boards. R8-leader win rate is reported beside it. "
        "These proxies require judgment; a dry run evaluates no deciding bar.",
        "",
        "Libraries use the same native captures via recapture_field.sh --reuse-captures --strength top4; "
        "no additional lobby or balance arm is needed. Source commit and capture hashes are sealed.",
        "",
    ]
    for preset, data in result["presets"].items():
        rows += [
            f"## Preset {preset}",
            "",
            measurement.table(data),
            "",
            f"Growth >=1.3 all lines: {data['decides']['growth_passes']}; "
            f"engine R12 target band: {data['decides']['scale_passes']} "
            "(B band reported; C band 1,350-3,600 decides only on the full run).",
            "",
            "| Line | R6-R11 growth p10 / median / p90 (n) | R11-R15 growth p10 / median / p90 (n) |",
            "|---|---:|---:|",
        ]
        for line, row in data["confirmation"].items():
            a, b = row["growth_windows"]["r6_r11"], row["growth_windows"]["r11_r15"]
            rows.append(
                f"| {line.removeprefix('line_')} | {spread(a['p10_median_p90'])} ({a['n']}) | "
                f"{spread(b['p10_median_p90'])} ({b['n']}) |"
            )
        for start, end in ((6, 11), (11, 15)):
            rows += [
                "",
                f"### R{start}-R{end} active totals, p10 / median / p90 [share alive]",
                "",
                "| Line | " + " | ".join(f"R{r}" for r in range(start, end + 1)) + " |",
                "|---|" + "---:|" * (end - start + 1),
            ]
            for line, row in data["confirmation"].items():
                values = []
                for r in range(start, end + 1):
                    q = row["rounds"][str(r)]["alive_p10_p25_p50_p75_p90"]
                    alive = row["rounds"][str(r)]["alive_share"]
                    values.append((spread([q[0], q[2], q[4]], 0) if q else "—") + f" [{alive:.0%}]")
                rows.append(f"| {line.removeprefix('line_')} | " + " | ".join(values) + " |")
        rows += ["", "### Field first read", "", "| Line | R10 | R12 | R14 |", "|---|---:|---:|---:|"]
        for line in data["confirmation"]:
            points = [
                data["field"]["rounds"].get(str(r), {}).get("line_point_rates", {}).get(line) for r in (10, 12, 14)
            ]
            rows.append(
                f"| {line.removeprefix('line_')} | "
                + " | ".join(f"{v:.1%}" if v is not None else "missing" for v in points)
                + " |"
            )
        rows += [
            "",
            f"Order-of-magnitude: `{json.dumps(data['magnitude_r14_r15'])}`.",
            "",
            f"Extreme diagnostics: `{json.dumps(data['extreme_misses'])}`.",
            "",
            f"R8 leader wins: {data['snowballs']['r8_leader_win_rate']}; "
            f"runaway proxy: {data['snowballs']['runaway_proxy_share']}.",
            "",
            f"Missing field lines: `{json.dumps(data['field']['missing_lines'])}`.",
            "",
            f"Captured active-unit stat-ceiling hits: {len(data['stat_cap_hits'])}; "
            "per-line R6-R15 survival, low-tail and >10x p90 flags, and every cap hit are in report.json.",
            "",
        ]
    return "\n".join(rows)
