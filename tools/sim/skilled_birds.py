#!/usr/bin/env python3
"""Freeze a small native-rules flight check and report it without a runaway threshold.

prepare is filesystem/git only. Simulations use the harness lock; checks use the shared lock.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import itertools
import json
import re
import shutil
import statistics
import subprocess
import tarfile
from collections import Counter, defaultdict
from pathlib import Path

ROUNDS = (10, 12, 14, 16)
LINES = (
    "line_birds_homecoming",
    "line_birds_tempo",
    "line_fairies_ring",
    "line_fairies_court",
)
HELPERS = ("skilled_birds.gd", "skilled_birds_brain.gd")
HUMANS = (
    (
        "tester_a",
        "origin/ideation/c-funprobe-a",
        "docs/ideation/evidence/fun-probe/tester-a/game1-birds-log.txt",
    ),
    (
        "tester_c",
        "origin/ideation/c-funprobe-c",
        "docs/ideation/evidence/fun-probe/tester-c/game1-birds.log",
    ),
)
PHASE_NOTE = (
    "PRE_START means combat_start after initial auras and before Start of Combat text. "
    "Human review logs and POST_FIGHT mean GameLog.record_round's post-fight live RecruitUnit board: "
    "away Birds and their Eggs are absent, temporary combat layers may differ, and combat carry is applied. "
    "Only POST_FIGHT bot rows share the human recording phase; human examples are two selected wins, not a sample."
)
SCOPE_NOTE = (
    "The aggressive arm changes only the flight decision inside the existing committed bot turn: "
    "largest legal flier at the first flight decision each turn, bypassing danger/score/home-minimum/from-round/omen/allowlist gates for that carry only. Subsequent flight decisions use the native policy. "
    "It obeys HeldUnits.flies, pending-choice restrictions and native RecruitRules.sell, trips, return guards, "
    "pool purchases, heroes, fights, damage and eliminations. The forced carry leaves its native Egg, "
    "where applicable; other flights retain native policy guards. All shop, economy and placement policies remain native. "
    "This probes one skilled decision, not optimal human play. No runaway cutoff or gameplay pass/fail bar is defined."
)


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def dump(path, value):
    Path(path).write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def git(tree, *args):
    return subprocess.check_output(["git", "-C", str(tree), *args], text=True).strip()


def method_body(text, name):
    match = re.search(
        rf"^func {re.escape(name)}\([^\n]*\).*?:\n(.*?)(?=^func |\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError("missing method: " + name)
    return "\n".join(
        line.strip() for line in match[1].splitlines() if line.strip() and not line.lstrip().startswith("#")
    )


def verify_native_flow(tree, helper_dir=None):
    helper_dir = Path(helper_dir or Path(__file__).parent)
    native = method_body((Path(tree) / "src/core/bots/bot_brain.gd").read_text(), "_smart_turn")
    candidate = method_body((helper_dir / "skilled_birds_brain.gd").read_text(), "_smart_turn")
    expected = native.replace("BotHeld.fly_turn(_player, _rules, value, _round_now)", "_flight_turn()")
    if expected != candidate:
        raise ValueError("candidate turn flow differs from native beyond flight call")
    return hashlib.sha256(native.encode()).hexdigest()


def parse_human(text):
    in_human = False
    rows = []
    for line in text.splitlines():
        if line.startswith("You:"):
            in_human = True
            continue
        if in_human and line and not line.startswith(" "):
            break
        if not in_human:
            continue
        match = re.match(r"\s+R(\d+) T(\d+) (\w+) spent (\d+): (.*)", line)
        if not match:
            continue
        units = [
            {
                "slot": slot,
                "name": name.lstrip("*"),
                "golden": name.startswith("*"),
                "attack": int(attack),
                "health": int(health),
                "stats": int(attack) + int(health),
            }
            for slot, name, attack, health in re.findall(r"([FB][1-4]) (.*?) (\d+)/(\d+)(?=, [FB][1-4] |$)", match[5])
        ]
        total = sum(unit["stats"] for unit in units)
        biggest = max(units, key=lambda unit: unit["stats"], default=None)
        rows.append(
            {
                "round": int(match[1]),
                "tier": int(match[2]),
                "stats": total,
                "biggest": biggest,
                "biggest_share": biggest["stats"] / total if total else None,
                "phase": "post_fight_live_recruit",
            }
        )
    if not rows:
        raise ValueError("no human rounds")
    return rows


def human_examples(tree):
    out = []
    for label, ref, path in HUMANS:
        raw = subprocess.check_output(["git", "-C", str(tree), "show", f"{ref}:{path}"], text=True)
        rows = parse_human(raw)
        by_round = {row["round"]: row for row in rows}
        expected = {12: 772, 14: 2085} if label == "tester_a" else {12: 459, 14: 883}
        if any(by_round[number]["stats"] != total for number, total in expected.items()):
            raise ValueError("human reference totals changed")
        out.append(
            {
                "label": label,
                "ref": ref,
                "commit": git(tree, "rev-parse", ref),
                "path": path,
                "lobby_tribes": next(
                    line.split(": ", 1)[1].split(", ") for line in raw.splitlines() if line.startswith("Lobby tribes:")
                ),
                "game_log_source_blob": git(tree, "rev-parse", f"{ref}:src/core/game_log.gd"),
                "blob": git(tree, "rev-parse", f"{ref}:{path}"),
                "rows": [by_round.get(number, {"round": number, "missing": True}) for number in ROUNDS],
            }
        )
    return out


def largest(units):
    if not units:
        return None
    unit = max(units, key=lambda row: int(row["attack"]) + int(row["health"]))
    return {key: unit[key] for key in ("def_id", "attack", "health", "golden") if key in unit} | {
        "stats": int(unit["attack"]) + int(unit["health"])
    }


def records(path):
    opener = gzip.open if str(path).endswith(".gz") else open
    with opener(path, "rt") as stream:
        for raw in stream:
            if raw.strip():
                yield json.loads(raw)


def parse_capture(path, seeds, arm):
    rows, flights, lobbies = [], [], {}
    seen = set()
    for record in records(path):
        seed = int(record["seed"])
        if seed not in seeds or record["arm"] != arm:
            raise ValueError("unexpected seed or arm")
        kind = record["type"]
        if kind == "lobby":
            if seed in lobbies:
                raise ValueError("duplicate lobby")
            if len(record["tribes"]) != 5 or not {"Birds", "Fairies"} <= set(record["tribes"]):
                raise ValueError("wrong five-tribe population")
            starting = [name.split(":")[0] for name in record["starting_lines"]]
            if Counter(starting) != Counter({**dict.fromkeys(LINES, 1), "hard_field": 4}):
                raise ValueError("wrong roster")
            config, rates = record["config"], record["rates"]
            if not all(
                config[key]
                for key in (
                    "card_size_caps",
                    "card_rate_limits",
                    "pass3_content",
                    "pass3_loop_guards",
                )
            ):
                raise ValueError("wrong shipped caps/content/guards")
            if rates["birds_homecoming_multiplier"] != 2 or rates["birds_golden_homecoming_multiplier"] != 2:
                raise ValueError("Birds dials changed")
            if len(record["summary"]["players"]) != 8:
                raise ValueError("missing players")
            lobbies[seed] = record
            for player in record["summary"]["players"]:
                seat = int(player["player_id"])
                for logged in player["rounds"]:
                    number = int(logged["round"])
                    if number not in ROUNDS:
                        continue
                    units = [unit for unit in logged["board"] if unit is not None]
                    biggest = largest(units)
                    total = sum(int(unit["attack"]) + int(unit["health"]) for unit in units)
                    rows.append(
                        {
                            "phase": "post_fight_live_recruit",
                            "arm": arm,
                            "seed": seed,
                            "seat": seat,
                            "line": starting[seat],
                            "round": number,
                            "stats": total,
                            "biggest": biggest,
                            "largest_share": biggest["stats"] / total if total and biggest else 0,
                            "largest_away": None,
                            "health_after_fight": logged["health"],
                        }
                    )
        elif kind == "flight_turn":
            flights.append(record)
        elif kind == "fight":
            number = int(record["input"]["round"])
            if number not in ROUNDS:
                continue
            for side, raw_seat in enumerate(record["input"]["player_ids"]):
                seat = int(raw_seat)
                if seat < 0:
                    continue
                identity = seed, seat, number
                if identity in seen:
                    raise ValueError("duplicate combat board")
                seen.add(identity)
                snapshot = record["combat_start"][side]
                active = [unit for unit in snapshot["units"] if unit.get("active", False)]
                away = [unit for unit in snapshot["units"] if unit.get("location") == "away"]
                total = sum(int(unit["attack"]) + int(unit["health"]) for unit in active)
                if total != snapshot["active_stats"]:
                    raise ValueError("active stats count mismatch")
                rows.append(
                    {
                        "phase": "pre_start_initial_auras",
                        "arm": arm,
                        "seed": seed,
                        "seat": seat,
                        "line": snapshot["starting_line"],
                        "round": number,
                        "stats": total,
                        "biggest": largest(active),
                        "largest_share": snapshot["largest_share"],
                        "largest_away": largest(away),
                        "away_stats": sum(int(unit["attack"]) + int(unit["health"]) for unit in away),
                        "health_before_fight": snapshot["health_before_fight"],
                        "hero": snapshot["hero"],
                    }
                )
        elif kind != "outcome":
            raise ValueError("unknown capture record type")
    if set(lobbies) != set(seeds):
        raise ValueError("capture lacks complete declared lobbies")
    return rows, flights, lobbies


def median(values):
    values = list(values)
    return statistics.median(values) if values else None


def summarize(rows, expected):
    out = {
        "n": len(rows),
        "missing": expected - len(rows),
        "median_stats": median(row["stats"] for row in rows),
    }
    for key in ("largest_share", "away_stats"):
        out["median_" + key] = median(row[key] for row in rows if key in row)
    for kind in ("biggest", "largest_away"):
        entries = [row[kind] for row in rows if row.get(kind)]
        out[kind] = {
            "n": len(entries),
            **{"median_" + key: median(entry[key] for entry in entries) for key in ("attack", "health", "stats")},
        }
    if rows:
        ordered = sorted(rows, key=lambda row: (row["stats"], row["seed"], row["seat"]))
        out["median_board_example"] = ordered[(len(ordered) - 1) // 2]
        out["max_board_example"] = ordered[-1]
    return out


def flight_summary(flights):
    out = {}
    for line in LINES[:2]:
        selected = [row for row in flights if row["starting_line"] == line]
        metrics = {
            "player_turns": len(selected),
            "eligible_turns": 0,
            "carry_chosen_turns": 0,
            "native_would_choose_carry_turns": 0,
            "flights": 0,
            "homecomings": sum(int(row["homecomings"]) for row in selected),
        }
        denials = Counter()
        by_round = defaultdict(lambda: Counter())
        for turn in selected:
            decisions = turn["decisions"]
            metrics["flights"] += sum(bool(d.get("flew")) for d in decisions)
            if not decisions or int(decisions[0]["biggest_legal_slot"]) < 0:
                continue
            first = decisions[0]
            metrics["eligible_turns"] += 1
            metrics["carry_chosen_turns"] += bool(first["carry_chosen"])
            metrics["native_would_choose_carry_turns"] += first["native_chosen_slot"] == first["biggest_legal_slot"]
            carry = next(c for c in first["candidates"] if c["slot"] == first["biggest_legal_slot"])
            denials.update(carry["legacy_denials"])
            by_round[str(turn["round"])].update({"eligible_turns": 1, "carry_chosen_turns": int(first["carry_chosen"])})
        out[line] = metrics | {
            "carry_legacy_denials_at_first_decision": dict(denials),
            "rounds": {key: dict(value) for key, value in by_round.items()},
        }
    return out


def growth_summary(rows):
    out = {}
    for phase in ("pre_start_initial_auras", "post_fight_live_recruit"):
        out[phase] = {}
        for line in LINES:
            selected = [row for row in rows if row["phase"] == phase and row["line"] == line]
            intervals = []
            for earlier, later in itertools.pairwise(ROUNDS):
                left = {(row["seed"], row["seat"]): row["stats"] for row in selected if row["round"] == earlier}
                right = {(row["seed"], row["seat"]): row["stats"] for row in selected if row["round"] == later}
                paired = [right[key] / left[key] for key in left.keys() & right.keys() if left[key] > 0]
                left_median, right_median = (
                    median(left.values()),
                    median(right.values()),
                )
                ratio = right_median / left_median if left_median and right_median is not None else None
                intervals.append(
                    {
                        "from_round": earlier,
                        "to_round": later,
                        "n_earlier": len(left),
                        "n_later": len(right),
                        "population_median_ratio": ratio,
                        "population_median_per_round": ratio ** (1 / (later - earlier)) if ratio is not None else None,
                        "same_survivor_pairs": len(paired),
                        "median_same_survivor_ratio": median(paired),
                    }
                )
            out[phase][line] = intervals
    return out


def prepare(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    commit = git(args.source_tree, "rev-parse", f"{args.commit}^{{commit}}")
    target = output / ("source-" + commit[:12])
    target.mkdir()
    archive = output / "source.tar"
    with archive.open("wb") as stream:
        subprocess.run(
            ["git", "-C", str(args.source_tree), "archive", commit],
            stdout=stream,
            check=True,
        )
    with tarfile.open(archive) as stream:
        stream.extractall(target, filter="data")
    archive.unlink()
    flow_sha = verify_native_flow(target)
    for name in HELPERS:
        shutil.copyfile(Path(__file__).with_name(name), target / "tools/sim" / name)
    probe = json.loads(args.probe.read_text())
    seeds = probe["eligible_seeds"][: args.n]
    if len(seeds) != args.n or len(set(seeds)) != args.n:
        raise ValueError("probe has too few unique eligible seeds")
    for seed in seeds:
        tribes = probe["tribes"][str(seed)]
        if len(tribes) != 5 or not {"Birds", "Fairies"} <= set(tribes):
            raise ValueError("probe eligibility mismatch")
    plan = {
        "version": 1,
        "source_commit": commit,
        "runtime_tree": str(target),
        "seeds": seeds,
        "n_per_arm": args.n,
        "rates": probe["rates"],
        "config": probe["config"],
        "native_tree_ids": {
            part: git(args.source_tree, "rev-parse", f"{commit}:{part}") for part in ("src", "content")
        },
        "arms": ["control", "aggressive"],
        "sample_frozen_before_run": True,
        "probe_sha256": sha(args.probe),
        "tribes": {str(seed): probe["tribes"][str(seed)] for seed in seeds},
        "native_smart_turn_sha256": flow_sha,
        "helpers": {name: sha(Path(__file__).with_name(name)) for name in HELPERS},
        "driver_sha256": sha(__file__),
        "phase_note": PHASE_NOTE,
        "scope_note": SCOPE_NOTE,
        "pairing": "Same predeclared eligible seeds and seats in two separate arms; divergent actions consume shops/pools differently, so not matched shop luck.",
        "stopping": "Run native games to completion; observe through R16. No forced continuation, sample extension, tuning, or new gameplay threshold.",
        "human_examples": human_examples(args.source_tree),
    }
    dump(output / "plan.json", plan)
    for arm in plan["arms"]:
        dump(output / (arm + "-plan.json"), {"arm": arm, "seeds": seeds})
    print(
        json.dumps(
            {
                "plan": str(output / "plan.json"),
                "runtime_tree": str(target),
                "n_per_arm": len(seeds),
            }
        )
    )


def report(args):
    plan = json.loads(args.plan.read_text())
    groups, flight_groups, lobbies_out, growth = {}, {}, {}, {}
    all_rows = []
    for arm in plan["arms"]:
        path = args.control if arm == "control" else args.aggressive
        rows, flights, lobbies = parse_capture(path, plan["seeds"], arm)
        for seed, captured in lobbies.items():
            if captured["rates"] != plan["rates"]:
                raise ValueError("captured native rates differ from frozen probe")
            if captured["tribes"] != plan["tribes"][str(seed)]:
                raise ValueError("captured tribe draw differs from frozen probe")
        all_rows.extend(rows)
        flight_groups[arm] = flight_summary(flights)
        growth[arm] = growth_summary(rows)
        lobbies_out[arm] = {
            str(seed): {
                "rounds": row["summary"]["rounds"],
                "players": [
                    {key: player[key] for key in ("player_id", "placement", "hero", "health", "tier")}
                    for player in row["summary"]["players"]
                ],
            }
            for seed, row in lobbies.items()
        }
        for phase in ("pre_start_initial_auras", "post_fight_live_recruit"):
            groups.setdefault(phase, {})[arm] = {
                line: {
                    str(number): summarize(
                        [
                            row
                            for row in rows
                            if row["phase"] == phase and row["line"] == line and row["round"] == number
                        ],
                        plan["n_per_arm"],
                    )
                    for number in ROUNDS
                }
                for line in LINES
            }
    result = {
        "plan": plan,
        "phase_note": PHASE_NOTE,
        "scope_note": SCOPE_NOTE,
        "human_examples": plan["human_examples"],
        "groups": groups,
        "flights": flight_groups,
        "growth": growth,
        "lobbies": lobbies_out,
        "raw_sha256": {
            "control": sha(args.control),
            "aggressive": sha(args.aggressive),
        },
    }
    dump(args.output, result)
    dump(args.output.with_suffix(".boards.json"), all_rows)
    args.output.with_suffix(".md").write_text(markdown(result))
    print(json.dumps({"report": str(args.output), "boards": len(all_rows)}))


def fmt(value, digits=1):
    return "missing" if value is None else f"{value:,.{digits}f}"


def markdown(result):
    lines = [
        "# Current-value Birds flight check",
        "",
        SCOPE_NOTE,
        "",
        PHASE_NOTE,
        "",
        (
            f"Frozen N={result['plan']['n_per_arm']} lobbies per arm; source `{result['plan']['source_commit']}`. "
            "Two separate arms keep the four written lines and four Hard seats, actual five-tribe rotation including Birds and Fairies. "
            "Later rows contain survivors. Missing rows are reported, not continued artificially."
        ),
        "",
        "## Two provided human examples (post-fight live recruit boards)",
        "",
        "| Example | Round | Board A+H | Biggest unit | A/H | Board share |",
        "|---|---:|---:|---|---:|---:|",
    ]
    for human in result["human_examples"]:
        for row in human["rows"]:
            biggest = row.get("biggest")
            if not biggest:
                lines.append(f"| {human['label']} | {row['round']} | missing | | | |")
                continue
            lines.append(
                f"| {human['label']} | {row['round']} | {row['stats']:,} | {biggest['name']} | "
                f"{biggest['attack']}/{biggest['health']} | {row['biggest_share']:.1%} |"
            )
    for phase, arms in result["groups"].items():
        lines += [
            "",
            f"## {phase}",
            "",
            (
                "Largest A/H are component medians across each board's largest active unit; "
                "they need not describe one observed unit. Exact median-board and maximum-board examples are in the JSON. "
                "SKY refers to reserve Birds away, excluded from active board totals."
            ),
            "",
            "| Arm | Starting line | Round | n / missing | Median board A+H | Largest A/H | Largest share | Largest SKY A/H |",
            "|---|---|---:|---:|---:|---:|---:|---:|",
        ]
        for arm, groups in arms.items():
            for line, rounds in groups.items():
                for number, group in rounds.items():
                    biggest, sky = group["biggest"], group["largest_away"]
                    share = group["median_largest_share"]
                    lines.append(
                        f"| {arm} | {line} | {number} | {group['n']} / {group['missing']} | "
                        f"{fmt(group['median_stats'])} | {fmt(biggest['median_attack'])}/{fmt(biggest['median_health'])} | "
                        f"{fmt(100 * share) + '%' if share is not None else 'missing'} | "
                        f"{(fmt(sky['median_attack']) + '/' + fmt(sky['median_health'])) if sky['n'] else ('none' if group['n'] else 'missing')} |"
                    )
    lines += [
        "",
        "## Flight implementation check",
        "",
        (
            "Counts of legal opportunities and legacy denials use "
            "the first flight decision of each player turn, so repeated loop checks do not inflate them."
        ),
        "",
        "| Arm | Starting line | Eligible turns | Carry chosen | Native would choose carry | Flights | Homecomings |",
        "|---|---|---:|---:|---:|---:|---:|",
    ]
    denial_lines = []
    for arm, groups in result["flights"].items():
        for line, group in groups.items():
            lines.append(
                f"| {arm} | {line} | {group['eligible_turns']} | {group['carry_chosen_turns']} | "
                f"{group['native_would_choose_carry_turns']} | {group['flights']} | {group['homecomings']} |"
            )
            denial_lines.append(
                f"\n{arm} {line} carry legacy-denial counts: `{json.dumps(group['carry_legacy_denials_at_first_decision'], sort_keys=True)}`\n"
            )
    lines.extend(denial_lines)
    lines += [
        "",
        "## Descriptive growth",
        "",
        "Population ratios compare survivor-only medians; same-survivor ratios retain only seats observed at both rounds. No threshold is applied.",
        "",
        "| Phase | Arm | Starting line | Rounds | Median ratio | Per-round factor | Same-survivor median ratio (n) |",
        "|---|---|---|---:|---:|---:|---:|",
    ]
    for arm, phases in result.get("growth", {}).items():
        for phase, groups in phases.items():
            for line, intervals in groups.items():
                for interval in intervals:
                    lines.append(
                        f"| {phase} | {arm} | {line} | {interval['from_round']}–{interval['to_round']} | "
                        f"{fmt(interval['population_median_ratio'], 3)} | {fmt(interval['population_median_per_round'], 3)} | "
                        f"{fmt(interval['median_same_survivor_ratio'], 3)} ({interval['same_survivor_pairs']}) |"
                    )
    lines += [
        "",
        (
            "This is a descriptive trajectory check. The tables supply no automatic 'runaway round'. "
            "Interpret the round-by-round levels and changes beside the two human trajectories, survival, and flight coverage. "
            "Poor engine assembly remains a limitation of the inherited bot shopping policy."
        ),
        "",
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    prep = commands.add_parser("prepare")
    prep.add_argument("--source-tree", type=Path, required=True)
    prep.add_argument("--commit", required=True)
    prep.add_argument(
        "--probe",
        type=Path,
        required=True,
        help="native eligible-seed probe JSON; prepare never starts Godot",
    )
    prep.add_argument("--n", type=int, choices=range(16, 33), default=32)
    prep.add_argument("--output", type=Path, required=True)
    prep.set_defaults(function=prepare)
    rep = commands.add_parser("report")
    rep.add_argument("--plan", type=Path, required=True)
    rep.add_argument("--control", type=Path, required=True)
    rep.add_argument("--aggressive", type=Path, required=True)
    rep.add_argument("--output", type=Path, required=True)
    rep.set_defaults(function=report)
    args = parser.parse_args()
    args.function(args)


if __name__ == "__main__":
    main()
