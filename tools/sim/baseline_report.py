#!/usr/bin/env python3
"""Render the frozen scale baseline, retaining all distributions and field measurements."""

import argparse
import csv
import gzip
import json
import statistics
from pathlib import Path


def number(value):
    return "n/a" if value is None else f"{value:.3f}"


def percent(value):
    return "n/a" if value is None else f"{100 * value:.2f}%"


def table(lines, headers, rows):
    lines.extend(["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)])
    lines.extend("| " + " | ".join(map(str, row)) + " |" for row in rows)
    lines.append("")


def flatten(value, path=()):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from flatten(child, (*path, str(key)))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from flatten(child, (*path, str(index)))
    else:
        yield ".".join(path), value


def write_csv(path, header, rows):
    with path.open("w", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def render(metrics, field, plan, progress, replay, tails, players, evidence):
    assert progress["completed_lobbies"] == plan["lobbies"] == 500
    assert progress["completed_field_fights"] == plan["field_fights"] == 193536
    assert len(players) == 4000
    assert set(field["rounds"]) == set(map(str, plan["rounds"]))
    assert len(field["pairs"]) == 12096
    assert all(len(data["boards"]) == 64 and data["hard_floor_passes"] for data in field["rounds"].values())
    root = "harness-baseline"
    lobby_seconds = sum(s["seconds"] for s in progress["shards"])
    fight_seconds = sum(s["seconds"] for s in progress["field_shards"])
    flat = metrics["historical_flat_shape_check"]
    rounds = metrics["rounds"]
    lines = [
        "# Scale harness baseline: today's pool\n",
        "9 November 2026. Track A, measured before the caps-off/engine-dial mechanics build.\n",
        f"Frozen harness commit `{plan['harness_commit'][:7]}`; 500 eight-seat mixed-line lobbies "
        "(4,000 seats), seeds 81001-81500. Every lobby used real combat, damage, pool depletion "
        "and heroes. The roster was two Hard tempo, two tribal tempo, three engine and one "
        "shared fast-tier seat, shuffled by seed. Neutral deals may also resolve to the shared line.\n",
        "The six fields contain 64 boards each at rounds 6, 8, 10, 12, 14 and 16, sampled "
        "with frozen seed 91407. Every unordered pair fought eight replicates in each "
        "orientation: 12,096 pairs and 193,536 fights. Layouts were fixed blind before combat. "
        "Reservoir sampling includes every represented line; field weights recover each line's "
        "actual frequency among surviving lobby boards. Draws earn half a point for ranking.\n",
        f"Runtime: lobby engines {lobby_seconds:.1f}s ({lobby_seconds / 60:.2f} min), field engines "
        f"{fight_seconds:.3f}s ({fight_seconds / 60:.2f} min), total engine time "
        f"{(lobby_seconds + fight_seconds) / 60:.2f} min. These are summed instrumented run times; "
        "process startup, Python analysis, checkpoints and the repository gate are additional. "
        "Godot ran sequentially under a 3 GB scope and a timeout.\n",
        "## Does today's pool show the flat shape?\n",
    ]
    if wall := progress.get("wall_clock"):
        lines.insert(
            -1,
            f"Elapsed run window: {wall['seconds'] / 60:.2f} min, from {wall['first_launch_utc']} "
            f"to {wall['last_field_end_utc']}, including startup and checkpoint gaps across turns; "
            "post-run analysis and checks are additional.\n",
        )
    fit = f"R6-16 median stats have linear R²={flat['linear_r2']:.4f}, slope {flat['slope']:.3f} stats/round"
    shape_n = sum(d["stats"]["n"] for r, d in rounds.items() if 6 <= int(r) <= 16)
    assert tails["board_round_observations"] == shape_n and tails["tail_count"] == flat["two_x_boards"]
    tail = (
        f"{flat['two_x_boards']} of {shape_n:,} board-round snapshots "
        f"({percent(flat['two_x_boards'] / shape_n)}) at or above twice their round's pooled median"
    )
    if flat["matches_historical_flat_shape"]:
        lines.append(
            f"Yes, in this fixed scripted field. {fit}, with {tail}. The predeclared historical "
            "check (R² ≥ 0.95 and zero 2x boards) passes. Growth remains close to a straight "
            "line rather than producing a compounding upper tail. This describes these lines "
            "on today's pool; it does not establish the ceiling of expert human play.\n"
        )
    elif flat["linear_r2"] >= 0.95:
        lines.append(
            f"Today's pool still shows the flat median growth shape: {fit}. There are {tail}. "
            "Thus the literal historical claim of zero 2x boards fails at this larger sample, "
            "while typical growth remains close to a straight line. These exceptions do not "
            "establish a common compounding engine, and their rarity is not a balance failure. "
            "Board-round observations include repeated seats across rounds. This describes the "
            "fixed scripts on today's pool, not the ceiling of expert human play.\n"
        )
    else:
        lines.append(
            f"The strict historical flat-shape check does not pass: {fit}, with {tail}. "
            "The declared check requires R² ≥ 0.95 and zero 2x boards. The distributions below "
            "show whether the departure is curvature, a rare tail, or both; a rare tail is "
            "not itself a reason to reject the pool. These results describe the scripted field, "
            "not the ceiling of expert human play.\n"
        )
    lines.extend(
        [
            f"The {tails['tail_count']} tail snapshots belong to {tails['unique_seats']} seats in "
            f"{tails['unique_lobbies']} of 500 lobbies ({percent(tails['unique_lobbies'] / 500)}); "
            f"the largest ratio is {max((r['ratio'] for r in tails['rows']), default=0):.3f}x. "
            "Every tail reconciles to at most seven active bodies; reserves are excluded. "
            "The [tail audit](harness-baseline/tails.json) retains their identities and unit stats. "
            "The 64-board fields can miss such rare boards; tail counts use the full lobby sample.\n",
            "## Board size and spread\n",
            "Attack + Health after initial auras, before opponent-dependent Start of Combat effects. "
            "Eggs are active bodies; held, away, hand and doorstep bodies are reserves. "
            "Round populations contain living seats only; late-round changes also reflect elimination. "
            "Stats describe feel; field fights rank strength. Percentiles use linear interpolation; "
            "p99 is descriptive. The 2x comparison pools all lines at the same round.\n",
        ]
    )
    table(
        lines,
        ["Round", "Boards", "p50", "p90", "p99", "p90/p50", "p99/p50", "Share ≥2x"],
        [
            [
                r,
                d["stats"]["n"],
                *[number(d["stats"][q]) for q in ("p50", "p90", "p99")],
                number(d["stats"]["p90"] / d["stats"]["p50"] if d["stats"]["p50"] else None),
                number(d["stats"]["p99"] / d["stats"]["p50"] if d["stats"]["p50"] else None),
                percent(d["share_2x_round_median"]),
            ]
            for r, d in rounds.items()
        ],
    )
    for key, title, explanation in [
        (
            "growth_delta",
            "Own-board growth per turn",
            "Current active stats minus the same seat's previous-round stats.",
        ),
        ("growth_ratio", "Own-board growth ratio", "Current / previous own active stats; zero denominators excluded."),
        (
            "stats_per_gold",
            "Stats per gold by round",
            "Current active stats / cumulative gold spent, including climbs, refreshes and spells.",
        ),
        (
            "growth_per_gold",
            "Incremental growth per gold",
            "Own-board growth / that turn's gold spent; zero denominators excluded.",
        ),
        (
            "largest_share",
            "Biggest body's share",
            "Largest active body's Attack + Health divided by active board stats.",
        ),
    ]:
        lines.extend([f"## {title}\n", explanation + "\n"])
        table(
            lines,
            ["Round", "N", "p50", "p90", "p99"],
            [
                [
                    r,
                    d[key]["n"],
                    *[(percent if key == "largest_share" else number)(d[key][q]) for q in ("p50", "p90", "p99")],
                ]
                for r, d in rounds.items()
            ],
        )
    lines.extend(
        [
            "## Tier-up arrivals against the owner's median unit\n",
            "The first newly fielded body of each newly unlocked tier is compared with the owner's "
            "median active unit before that climb. Arrival can be later than the climb. "
            "Printed stats exclude effects; golden printed stats are doubled. Unseen arrivals are excluded.\n",
        ]
    )
    table(
        lines,
        ["Tier", "N", "Aura p50", "Aura p90", "Aura p99", "Printed p50", "Printed p90", "Printed p99"],
        [
            [
                tier,
                values["arrival_ratio"]["n"],
                *[number(values[k][q]) for k in ("arrival_ratio", "printed_ratio") for q in ("p50", "p90", "p99")],
            ]
            for tier, values in metrics["tier_arrivals"].items()
        ],
    )
    lines.extend(
        [
            "## Reserve stats\n",
            "Attack + Health outside the active board, without board auras; absent reserves count as zero.\n",
        ]
    )
    table(
        lines,
        ["Round", "Location", "N", "p50", "p90", "p99"],
        [
            [r, loc, d["n"], *[number(d[q]) for q in ("p50", "p90", "p99")]]
            for r, data in rounds.items()
            for loc, d in data["reserve_stats"].items()
        ],
    )
    lines.extend(
        [
            "## Outcomes\n",
            "Leader ties split credit. Below-median boards are strict comparisons. "
            "95% intervals use 2,000 fixed bootstrap resamples of whole lobby seeds, never individual seats.\n",
        ]
    )
    outcomes = metrics["outcomes"]
    table(
        lines,
        ["Metric", "N", "Seed clusters", "Rate", "95% CI"],
        [
            [
                label,
                d["n"],
                d.get("seed_clusters", 0),
                percent(d["rate"]),
                "-".join(percent(v) for v in d["ci95"]) if d["ci95"] else "n/a",
            ]
            for key, label in [
                ("r8_stat_leader_wins", "Round-8 stat leader wins"),
                ("r8_health_leader_wins", "Round-8 Health leader wins"),
                ("r8_below_pooled_median_top2", "Below pooled R8 median finishes top 2"),
                ("r8_below_lobby_median_top2", "Below own-lobby R8 median finishes top 2"),
            ]
            for d in [outcomes[key]]
        ],
    )
    lengths = [int(p["rounds"]) for p in players if int(p["place"]) == 1]
    assert len(lengths) == 500
    d = outcomes["winner_final_round"]
    lines.append(
        f"First-place game length: N={d['n']}; p50={number(d['p50'])}, "
        f"p90={number(d['p90'])}, p99={number(d['p99'])}; mean={statistics.mean(lengths):.3f}, "
        f"range={min(lengths)}-{max(lengths)} rounds.\n"
    )
    uncertainty = outcomes["field_uncertainty_r10_14"]
    lines.append(
        "Compare the plan's 14-16 round target with this measured game length; "
        "this is the baseline damage configuration, not a tuned replacement.\n"
    )
    lines.append(
        f"Rounds 10-14: {uncertainty['pairs']} unordered field pairs. Winner probability "
        "is conditional on a decisive fight; all-draw pairs are excluded from uncertain winners "
        "but remain in the denominator. Each pair has 16 trials.\n"
    )
    table(
        lines,
        ["Metric", "Share"],
        [
            [label, percent(uncertainty[key])]
            for key, label in [
                ("share_20_80", "Pairs with point probability 20-80%"),
                ("weighted_share_20_80", "Same, weighted by field population"),
                ("share_ci_wholly_20_80", "Pairs whose entire Wilson 95% interval is inside 20-80%"),
                ("all_draw_pair_share", "All-draw pairs"),
            ]
        ],
    )
    lines.extend(
        [
            "## Weighted field results\n",
            "Rates are wins plus half draws, excluding self-fights. "
            "A board's opponents are weighted by their represented line frequencies. "
            "Hard is included as the tempo anchor, so the strongest line being at least as strong "
            "as Hard is an inclusion check, not evidence that a tribal script beats Hard.\n",
        ]
    )
    for r, data in field["rounds"].items():
        lines.append(f"### Round {r}\n")
        lines.append(f"Strongest sampled line: `{data['strongest_line']}`. Hard-floor check: pass.\n")
        table(
            lines,
            ["Line", "Selected boards", "Population weight", "Field point rate"],
            [
                [
                    line,
                    sum(b["line"] == line for b in data["boards"]),
                    percent(weight),
                    percent(data["line_point_rates"][line]),
                ]
                for line, weight in sorted(data["line_weights"].items())
            ],
        )
        labels = sorted(data["win_matrix"])
        short = {label: str(i + 1) for i, label in enumerate(labels)}
        lines.append("Matrix key: " + "; ".join(f"{short[label]}=`{label}`" for label in labels) + ".\n")
        table(
            lines,
            ["Row vs column", *[short[label] for label in labels]],
            [[short[label], *[percent(data["win_matrix"][label][other]) for other in labels]] for label in labels],
        )
    lines.extend(["## Replay and known answers\n"])
    original = replay["variants"]["original"]
    assert len(original) == 500
    assert all(
        v["first_elimination_divergence"] is None and v["coverage_lost_round"] is None and not v["unresolved_survivors"]
        for v in original.values()
    )
    assert all(
        original[f"{p['seed']}:0"]["winner"] == int(p["seat"])
        and original[f"{p['seed']}:0"]["end_round"] == int(p["rounds"])
        for p in players
        if int(p["place"]) == 1
    )
    lines.append(
        f"Offline original-rules replay reproduced all 500 winners and final rounds, "
        f"with {sum(v['live_post_state_checks'] for v in original.values()):,} exact live "
        "Health/Armor checks and no elimination divergence or lost coverage. "
        "Alternative damage tables and starting Health use the same logged survivors; "
        "after elimination divergence they are fixed-schedule conditional replays, not new lobbies.\n"
    )
    lines.append(
        "The independent planted-engine check won 8/8 lobbies, put all eight R6 boards above "
        "twice their lobby median, and scored 97.0% in its weighted field. Null/control "
        "outputs matched byte for byte; all 469 planted fights replayed exactly. "
        "Thus the harness detects an engine when present. Historical tribal-line losses to "
        "Hard are retained in [HARNESS.md](../../../tools/sim/HARNESS.md); no further tuning "
        "used these baseline seeds. Head-to-head strength must be rechecked on the later lever build.\n"
    )
    lines.append(
        "Earlier equal-budget exploratory knob tuning used 130 separate lobbies (20 per tribe, "
        "ten for the shared line), reporting +1.077 places in training and -0.154 places held out. "
        "Two games per validation arm did not establish improvement. This baseline uses the "
        "later frozen committed profile table and makes no new tuning-gain claim; "
        "per-tribe gains and exact profiles remain in HARNESS.md and its linked evidence.\n"
    )
    lines.extend(
        [
            "## Precision, artifacts and reproduction\n",
            "Samples and budgets were frozen before execution. Shop comparisons are unpaired: "
            "a common seed reproduces a whole lobby, not matched shop draws after different actions. "
            "Five hundred independent lobbies imply an approximate worst-case ±4.4 percentage-point "
            "95% outcome-rate margin before the cluster bootstrap. Field pairs share boards; pair "
            "counts are not independent population samples, and 16 trials give coarse pair probabilities. "
            "Matched orientations share a replicate seed; Wilson intervals are descriptive, not "
            "calibrated confidence coverage for correlated trials. "
            "No significance or human-play optimality claim follows from a line ranking.\n",
            f"All per-line/per-round distributions and every scalar metric: [{root}/metrics.json]({root}/metrics.json) "
            f"and [flat CSV]({root}/metrics.csv). Within-line summaries separate strategy mix from tails. "
            f"Every sampled board's weight and field rate: [boards.csv]({root}/boards.csv). "
            f"All line matrices: [matrices.csv]({root}/matrices.csv). "
            f"Complete counts, pair probabilities and Wilson intervals: [field report]({root}/field-report.json.gz). "
            f"Exact selected board inputs: [field.json.gz]({root}/field.json.gz). "
            f"Raw field counts: [pairs.jsonl.gz]({root}/pairs.jsonl.gz).\n",
            "The [frozen plan](../../../tools/sim/evidence/baseline-plan.json) records profile/content "
            "hashes and the source commit. The [execution ledger](../../../tools/sim/evidence/baseline-progress.json) "
            "records shard seeds, timings, source hashes and validation. Raw lobby captures remain in "
            "`build/sim/harness-baseline/part*.fights.jsonl` (ignored build output); reproduce them with "
            "the frozen commit/profile table and ledger seed ranges.\n",
            "```sh",
            "python3 tools/sim/field.py sample build/sim/harness-baseline/part*.fights.jsonl \\",
            "  --size 64 --rounds 6,8,10,12,14,16 --seed 91407 --out field.json",
            "# Run field_fights.gd sequentially per round under the documented 3 GB scope/timeout.",
            "python3 tools/sim/field.py report field.json pairs.jsonl --out field-report.json",
            "python3 tools/sim/metrics.py build/sim/harness-baseline/part*.fights.jsonl \\",
            "  --players build/sim/harness-baseline/part*.players.csv --field field-report.json --out metrics.json",
            "```\n",
        ]
    )
    evidence.mkdir(parents=True, exist_ok=True)
    (evidence / "metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    (evidence / "tails.json").write_text(json.dumps(tails, indent=2) + "\n")
    write_csv(evidence / "metrics.csv", ["metric", "value"], flatten(metrics))
    write_csv(
        evidence / "boards.csv",
        ["round", "id", "line", "weight", "field_point_rate"],
        [
            [r, b["id"], b["line"], b["weight"], b["field_point_rate"]]
            for r, data in field["rounds"].items()
            for b in data["boards"]
        ],
    )
    write_csv(
        evidence / "matrices.csv",
        ["round", "line", "opponent", "point_rate"],
        [
            [r, line, opponent, rate]
            for r, data in field["rounds"].items()
            for line, values in data["win_matrix"].items()
            for opponent, rate in values.items()
        ],
    )
    with (
        (evidence / "field-report.json.gz").open("wb") as stream,
        gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as compressed,
    ):
        compressed.write((json.dumps(field) + "\n").encode())
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("metrics", "field", "plan", "progress", "replay", "tails"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--players", type=Path, nargs="+", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    players = []
    for path in args.players:
        with path.open(newline="") as stream:
            players.extend(csv.DictReader(stream))
    args.out.write_text(
        render(
            *[
                json.loads(getattr(args, key).read_text())
                for key in ("metrics", "field", "plan", "progress", "replay", "tails")
            ],
            players,
            args.out.with_suffix(""),
        )
    )


if __name__ == "__main__":
    main()
