#!/usr/bin/env python3
"""Offline H1 measurements and the two predeclared reference usability criteria."""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
import random
import statistics
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QB = "line_quilboar_engine"
TRIBE_LINES = (
    "line_birds_homecoming",
    "line_fairies_ring",
    "line_bog_engine",
    "line_hedgerow_engine",
    "line_hunters_engine",
    "line_oozes_engine",
)
ACCOUNTING_ROUNDS = (9, 12, 15)
ARMS = ("B", "C", "uncut", "uncut_frozen")


def line_name(value):
    if value == "line_birds_engine":
        return "line_birds_homecoming"
    if value == "line_fairies_engine":
        return "line_fairies_ring"
    if value in ("birds_homecoming", "fairies_ring"):
        return "line_" + value
    if value in ("quilboar_choose_one", "line_quilboar_choose_one"):
        return QB
    return value


def percentile(values, q):
    values = sorted(values)
    if not values:
        return None
    position = (len(values) - 1) * q
    lo, hi = math.floor(position), math.ceil(position)
    return values[lo] + (values[hi] - values[lo]) * (position - lo)


def paper_reference():
    """Load the committed paper with its final six-gold cycling assumption, unchanged math."""
    path = ROOT / "docs/ideation/reference/quilboar/model/presets3.py"
    spec = importlib.util.spec_from_file_location("quilboar_h1_paper", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    out = {}
    for arm in ARMS:
        preset = "uncut" if arm == "uncut_frozen" else arm
        dials = {**module.P[preset], "cycle_cost": 6.0}
        if arm == "uncut_frozen":
            dials.update(size_off=True, rational_off=True)
        rows = module.run("typical", dials)
        out[arm] = {
            "dials": dials,
            "rounds": {str(r): {"stats": row["board"], "gem_size": row["S"]} for r, row in rows.items()},
        }
    return {
        "source": str(path.relative_to(ROOT)),
        "counting": "Attack plus Health of the recruit board before combat; Quilboar needs no body-count conversion.",
        "arrivals": "Paper arrivals are scripted, not shopped; Phase 1 lacks the paper's early Roadboar Gems.",
        "cycle_cost": 6.0,
        "arms": out,
    }


def bootstrap(groups, statistic=statistics.median, *, replicates=2000, seed=481516):
    """Resample whole declared lobby seeds, retaining empty eliminated clusters."""
    keys = sorted(groups)
    values = [v for key in keys for v in groups[key]]
    if not values:
        return {
            "point": None,
            "ci95": None,
            "n": 0,
            "seed_clusters": len(keys),
            "valid_draws": 0,
        }
    rng = random.Random(seed)
    estimates = []
    for _ in range(replicates):
        selected = rng.choices(keys, k=len(keys))
        sample = [v for key in selected for v in groups[key]]
        if sample:
            estimates.append(statistic(sample))
    return {
        "point": statistic(values),
        "ci95": [percentile(estimates, 0.025), percentile(estimates, 0.975)] if estimates else None,
        "n": len(values),
        "seed_clusters": len(keys),
        "seed_clusters_with_observations": sum(bool(groups[key]) for key in keys),
        "valid_draws": len(estimates),
    }


def summarize_round(rows, seeds, replicates, bootstrap_seed):
    def measure(field, statistic=statistics.median):
        groups = {seed: [] for seed in seeds}
        for row in rows:
            if row.get(field) is not None:
                groups[row["seed"]].append(row[field])
        return bootstrap(groups, statistic, replicates=replicates, seed=bootstrap_seed)

    return {
        "pre_start": measure("stats"),
        "p90": measure("stats", lambda xs: percentile(xs, 0.9)),
        "post_start": measure("post_start_stats"),
        "biggest_unit_share": measure("largest_share"),
        "post_start_biggest_unit_share": measure("post_start_largest_share"),
    }


def growth(rows, seeds, replicates, bootstrap_seed):
    groups = {seed: defaultdict(list) for seed in seeds}
    for row in rows:
        if row["round"] in (8, 14):
            groups[row["seed"]][row["round"]].append(row["stats"])

    def estimate(selected):
        ends = {r: [v for seed in selected for v in groups[seed][r]] for r in (8, 14)}
        if not ends[8] or not ends[14] or statistics.median(ends[8]) <= 0:
            return None
        return (statistics.median(ends[14]) / statistics.median(ends[8])) ** (1 / 6)

    rng = random.Random(bootstrap_seed)
    draws = [value for _ in range(replicates) if (value := estimate(rng.choices(seeds, k=len(seeds)))) is not None]
    return {
        "point": estimate(seeds),
        "ci95": [percentile(draws, 0.025), percentile(draws, 0.975)] if draws else None,
        "formula": "(pooled_survivor_median_R14 / pooled_survivor_median_R8) ** (1/6)",
        "phase": "pre-start",
        "valid_draws": len(draws),
        "qualification": "Descriptive survivor-population growth, not within-player compounding; no pass/fail bar.",
    }


def ratio_interval(rows, seeds, numerator_line, denominator_line, replicates, bootstrap_seed):
    seeds = sorted(seeds)
    groups = {seed: defaultdict(list) for seed in seeds}
    for row in rows:
        if row["round"] == 12 and row["line"] in (numerator_line, denominator_line):
            groups[row["seed"]][row["line"]].append(row["stats"])
    rng = random.Random(bootstrap_seed)
    draws = []
    for _ in range(replicates):
        selected = rng.choices(seeds, k=len(seeds))
        numerator = [v for seed in selected for v in groups[seed][numerator_line]]
        denominator = [v for seed in selected for v in groups[seed][denominator_line]]
        if numerator and denominator and statistics.median(denominator) > 0:
            draws.append(statistics.median(numerator) / statistics.median(denominator))
    return {
        "ci95": [percentile(draws, 0.025), percentile(draws, 0.975)] if draws else None,
        "valid_draws": len(draws),
    }


def _combine_verdict(values):
    values = list(values)
    return False if False in values else (True if values and all(v is True for v in values) else None)


def summarize(lobbies, *, smoke=False, replicates=2000, bootstrap_seed=481516):
    """The input is a list of completed per-lobby records; an incomplete run remains descriptive."""
    if not lobbies:
        raise ValueError("no completed lobbies")
    if any(game["arm"] not in ARMS for game in lobbies):
        raise ValueError("unknown H1 arm")
    identities = [(game["arm"], game["seed"]) for game in lobbies]
    if len(set(identities)) != len(identities):
        raise ValueError("duplicate arm/seed")
    paper = paper_reference()
    arms = {}
    for arm in ARMS:
        games = [game for game in lobbies if game["arm"] == arm]
        if not games:
            continue
        seeds = sorted(game["seed"] for game in games)
        rows = [
            {**row, "seed": game["seed"], "line": line_name(row["line"])} for game in games for row in game["rounds"]
        ]
        players = [
            {**row, "seed": game["seed"], "line": line_name(row["line"])} for game in games for row in game["players"]
        ]
        if len({(row["seed"], row["seat"], row["round"]) for row in rows}) != len(rows):
            raise ValueError("duplicate seat-round")
        lines = {}
        for line in sorted({line_name(entry["line"]) for game in games for entry in game["roster"]}):
            chosen = [row for row in rows if row["line"] == line]
            finishes = [row for row in players if row["line"] == line]
            by_round = {
                str(r): summarize_round(
                    [row for row in chosen if row["round"] == r],
                    seeds,
                    replicates,
                    bootstrap_seed,
                )
                for r in sorted({row["round"] for row in rows} | set(ACCOUNTING_ROUNDS) | {8, 14})
            }
            placements = {seed: [p["place"] for p in finishes if p["seed"] == seed] for seed in seeds}
            commits = {seed: [] for seed in seeds}
            found = {seed: [] for seed in seeds}
            for game in games:
                own = [row for row in chosen if row["seed"] == game["seed"]]
                commit = [
                    row["commit_round"]
                    for row in own
                    if row.get("commit_round") is not None and row["commit_round"] > 0
                ]
                if commit:
                    commits[game["seed"]] = [min(commit)]
                keystones = [
                    row["keystone_found_round"]
                    for row in own
                    if row.get("keystone_found_round") is not None and row["keystone_found_round"] > 0
                ]
                if line == QB:
                    found[game["seed"]] = [int(bool(keystones) and min(keystones) <= 12)]
            lines[line] = {
                "rounds": by_round,
                "placement": bootstrap(
                    placements,
                    statistics.mean,
                    replicates=replicates,
                    seed=bootstrap_seed,
                ),
                "first_place": bootstrap(
                    {seed: [int(v == 1) for v in vs] for seed, vs in placements.items()},
                    statistics.mean,
                    replicates=replicates,
                    seed=bootstrap_seed,
                ),
                "top4": bootstrap(
                    {seed: [int(v <= 4) for v in vs] for seed, vs in placements.items()},
                    statistics.mean,
                    replicates=replicates,
                    seed=bootstrap_seed,
                ),
                "commit_round": bootstrap(commits, replicates=replicates, seed=bootstrap_seed),
                "keystone_found_by_r12": bootstrap(found, statistics.mean, replicates=replicates, seed=bootstrap_seed),
                "growth_r8_r14": growth(chosen, seeds, replicates, bootstrap_seed),
            }
        leaders = {seed: [] for seed in seeds}
        for game in games:
            r8 = [row for row in rows if row["seed"] == game["seed"] and row["round"] == 8]
            winners = {p["seat"] for p in players if p["seed"] == game["seed"] and p["place"] == 1}
            if r8:
                best = max(row["stats"] for row in r8)
                tied = {row["seat"] for row in r8 if row["stats"] == best}
                leaders[game["seed"]] = [len(tied & winners) / len(tied)]
        arms[arm] = {
            "lobbies": len(games),
            "seeds": seeds,
            "seconds": sum(game["elapsed_seconds"] for game in games),
            "seconds_per_lobby": statistics.mean(game["elapsed_seconds"] for game in games),
            "lines": lines,
            "round8_leader_win_rate": bootstrap(leaders, statistics.mean, replicates=replicates, seed=bootstrap_seed),
            "leader_ties": "A tied leader is chosen uniformly; each tied eventual winner contributes 1/tied_leaders.",
            "all_seat_growth_r8_r14": growth(rows, seeds, replicates, bootstrap_seed),
        }
    accounting = {}
    for arm in ("B", "C"):
        checks = {}
        for r in ACCOUNTING_ROUNDS:
            observed = (
                arms.get(arm, {}).get("lines", {}).get(QB, {}).get("rounds", {}).get(str(r), {}).get("pre_start", {})
            )
            expected = paper["arms"][arm]["rounds"][str(r)]["stats"]
            point = observed.get("point")
            ratio = point / expected if point is not None else None
            checks[str(r)] = {
                "real": point,
                "real_ci95": observed.get("ci95"),
                "paper": expected,
                "real_div_paper": ratio,
                "ratio_ci95": [v / expected for v in observed["ci95"]] if observed.get("ci95") else None,
                "passes": None if smoke or ratio is None else 0.5 <= ratio <= 2,
                "boards": observed.get("n", 0),
            }
        accounting[arm] = {
            "rounds": checks,
            "passes": _combine_verdict(check["passes"] for check in checks.values()),
        }
    uncut = arms.get("uncut", {}).get("lines", {})
    qb = uncut.get(QB, {}).get("rounds", {}).get("12", {}).get("pre_start", {}).get("point")
    fidelity = {}
    for line in TRIBE_LINES:
        other = uncut.get(line, {}).get("rounds", {}).get("12", {}).get("pre_start", {}).get("point")
        ratio = qb / other if qb is not None and other else None
        uncut_games = [game for game in lobbies if game["arm"] == "uncut"]
        uncut_rows = [
            {**row, "seed": game["seed"], "line": line_name(row["line"])}
            for game in uncut_games
            for row in game["rounds"]
        ]
        interval = (
            ratio_interval(
                uncut_rows,
                [game["seed"] for game in uncut_games],
                QB,
                line,
                replicates,
                bootstrap_seed,
            )
            if uncut_games
            else {"ci95": None, "valid_draws": 0}
        )
        fidelity[line] = {
            "quilboar": qb,
            "other": other,
            "ratio": ratio,
            **interval,
            "passes": None if smoke or ratio is None else ratio >= 4,
        }
    for arm, result in arms.items():
        result["paper_comparison"] = {}
        for r in ACCOUNTING_ROUNDS:
            observed = result["lines"].get(QB, {}).get("rounds", {}).get(str(r), {}).get("pre_start", {})
            expected = paper["arms"][arm]["rounds"][str(r)]["stats"]
            real = observed.get("point")
            result["paper_comparison"][str(r)] = {
                "real": real,
                "paper": expected,
                "real_div_paper": real / expected if real is not None else None,
                "ratio_ci95": [v / expected for v in observed["ci95"]] if observed.get("ci95") else None,
            }
    return {
        "version": 1,
        "smoke": smoke,
        "qualification": "Exploratory smoke: point ratios are data only; usability verdicts withheld."
        if smoke
        else "Only accounting and fidelity decide reference usability; all other measurements are descriptive.",
        "population": "Surviving committed seats, grouped by assigned starting line; eliminated seats are not imputed as zero.",
        "commit_definition": "Quilboar: first native commit condition; other fixed line seats are assigned from R1, not an observed player decision.",
        "counting": "Pre-start active-board Attack+Health; hand, sky and Belly reserves excluded. Post-start values reported separately.",
        "bootstrap": {
            "replicates": replicates,
            "seed": bootstrap_seed,
            "method": "95% percentile whole-lobby seed bootstrap, retaining eliminated empty clusters",
        },
        "paper": paper,
        "arms": arms,
        "criteria": {
            "accounting": {
                "bounds": [0.5, 2],
                "rounds": [9, 12, 15],
                "arms": accounting,
                "passes": _combine_verdict(v["passes"] for v in accounting.values()),
            },
            "fidelity": {
                "minimum_ratio": 4,
                "round": 12,
                "comparisons": fidelity,
                "passes": _combine_verdict(v["passes"] for v in fidelity.values()),
            },
        },
    }


def _number(value, digits=2):
    return "—" if value is None else f"{value:,.{digits}f}"


def _estimate(measure, digits=1):
    point = _number(measure.get("point"), digits)
    interval = measure.get("ci95")
    return point + (f" [{_number(interval[0], digits)}, {_number(interval[1], digits)}]" if interval else "")


def write_report(data, out):
    """Write one metrics format (JSON), with a human-readable Markdown rendering beside it."""
    out = Path(out).with_suffix("")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.with_suffix(".json").write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    text = [
        "# Quilboar H1 reference lobbies",
        "",
        data["qualification"],
        "",
        data["population"],
        data["counting"],
        data["commit_definition"],
        "",
        "Intervals are whole-seed bootstrap 95% intervals. Same seed labels across arms do not imply paired shop draws: policies, fights and pool depletion diverge.",
        "",
        "## Accounting",
        "",
        "| Arm | Round | Real median [95% interval] | Paper | Real / paper | Pass |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for arm, result in data["criteria"]["accounting"]["arms"].items():
        for r, row in result["rounds"].items():
            text.append(
                f"| {arm} | {r} | {_estimate({'point': row['real'], 'ci95': row['real_ci95']})} | {_number(row['paper'], 0)} | {_number(row['real_div_paper'])}× | {row['passes'] if row['passes'] is not None else 'not evaluated'} |"
            )
    text += [
        "",
        "## Fidelity: uncut R12",
        "",
        "| Other line | Quilboar median | Other median | Ratio | Pass |",
        "|---|---:|---:|---:|---|",
    ]
    for line, row in data["criteria"]["fidelity"]["comparisons"].items():
        text.append(
            f"| {line} | {_number(row['quilboar'], 0)} | {_number(row['other'], 0)} | {_estimate({'point': row['ratio'], 'ci95': row.get('ci95')})}× | {row['passes'] if row['passes'] is not None else 'not evaluated'} |"
        )
    text += [
        "",
        "## Uncut paper comparison (descriptive)",
        "",
        "| Arm | Round | Real median | Paper | Real / paper [95% interval] |",
        "|---|---:|---:|---:|---:|",
    ]
    for arm in ("uncut", "uncut_frozen"):
        for r, row in data["arms"].get(arm, {}).get("paper_comparison", {}).items():
            text.append(
                f"| {arm} | {r} | {_number(row['real'], 0)} | {_number(row['paper'], 0)} | {_estimate({'point': row['real_div_paper'], 'ci95': row['ratio_ci95']})}× |"
            )
    text += ["", "## Descriptive measurements", ""]
    for arm, result in data["arms"].items():
        text += [
            f"### {arm}",
            "",
            f"{result['lobbies']} lobbies, {_number(result['seconds_per_lobby'])} seconds/lobby. Pre-start R8–R14 growth: {_estimate(result['all_seat_growth_r8_r14'], 3)}×/round. R8 leader win rate: {_estimate(result['round8_leader_win_rate'], 3)}.",
            "",
            "| Line | Mean place | First-place rate | Top-4 rate | Commit round | Keystone by R12 |",
            "|---|---:|---:|---:|---:|---:|",
        ]
        for line, values in result["lines"].items():
            text.append(
                f"| {line} | {_estimate(values['placement'])} | {_estimate(values['first_place'], 3)} | {_estimate(values['top4'], 3)} | {_estimate(values['commit_round'])} | {_estimate(values['keystone_found_by_r12'], 3)} |"
            )
        text += [
            "",
            "| Line | Round | Pre-start median [95% interval] | Pre-start p90 | Post-start median | Biggest unit share |",
            "|---|---:|---:|---:|---:|---:|",
        ]
        for line, values in result["lines"].items():
            for r, row in sorted(values["rounds"].items(), key=lambda entry: int(entry[0])):
                text.append(
                    f"| {line} | {r} | {_estimate(row['pre_start'])} | {_estimate(row['p90'])} | {_estimate(row['post_start'])} | {_estimate(row['biggest_unit_share'], 3)} |"
                )
    text += [
        "",
        "Paper uses the committed typical arrivals and final 6-gold cycle cost. No counting conversion is needed for Quilboar. Phase 1 omits the paper's early Roadboar Gems. The uncut-frozen arm holds size at +1/+1 and chooses Gem-producing modes rationally; its paper trajectory is available in the JSON and is descriptive only.",
        "",
    ]
    out.with_suffix(".md").write_text("\n".join(text))
    return out.with_suffix(".json"), out.with_suffix(".md")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", type=Path, nargs="+")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()
    games = [json.loads(path.read_text()) for path in args.inputs]
    write_report(summarize(games, smoke=args.smoke), args.out)


if __name__ == "__main__":
    main()
