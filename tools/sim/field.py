#!/usr/bin/env python3
"""Sample equally stratified blind fields and describe weighted round-robin results.

Designed-only input: ``sample --designed setups.json --rounds 6 --size 8 --out field.json``.
The JSON object must contain ``boards`` (complete captured-style per-side records)
and explicit ``line_weights`` by round, e.g. ``{"6": {"owner_setup": 1.0}}``.
Designed boards cannot be mixed with lobby captures. Neither combat snapshots nor
missing fight state are reconstructed from unit names or visible statistics.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
from collections import Counter, defaultdict
from pathlib import Path

ROUNDS = (6, 8, 10, 12, 14, 16)
# Designed inputs must specify the complete current GameConfig, rather than
# acquiring changing replay defaults. Captured inputs keep their original config.
REQUIRED_CONFIG_KEYS = frozenset(
    [
        "card_size_caps",
        "card_rate_limits",
        "scale_levers",
        "scale_engine_percent",
        "scale_engine_flat",
        "scale_engine_self",
        "scale_engine_tribe",
        "scale_answer_percent",
        "scale_economy_cap",
        "scale_hero_spell_stats",
        "scale_hero_spell_percent",
        "players",
        "starting_health",
        "damage_mode",
        "base_damage_by_turn",
        "max_rounds",
        "income_by_turn",
        "unit_cost",
        "sell_bought",
        "sell_created",
        "refresh_base_cost",
        "refresh_first_step_after",
        "refresh_step_length",
        "freeze_toggles_per_turn",
        "upgrade_costs",
        "upgrade_discount_per_turn",
        "pool_copies_by_tier",
        "shop_units_by_tier",
        "hand_limit",
        "damage_cap_by_turn",
        "damage_cap_off_at_alive",
        "hero_damage_floor",
        "round_toll",
        "early_spoils",
        "ask_for_kin",
        "last_blow",
        "last_stand",
        "survivor_damage_divisor",
        "attack_limit",
        "trigger_limit_combat",
        "trigger_limit_action",
        "pool_filter",
        "bots",
        "human_bot",
        "shop_tier_odds",
        "shop_spells_by_tier",
        "spell_copies_by_tier",
        "spells_in_shop",
        "hero_choice",
        "heroes_offered",
        "discover_options",
        "opening_spells",
        "opening_rounds",
        "tribes_per_lobby",
        "lobby_tribe_min_units",
    ]
)
REQUIRED_FIGHT_RULES = frozenset(
    ("larder", "back_row_first", "bands", "ammo", "nests", "goose", "away_birds", "homecomings")
)
CONFIG_BOOL_KEYS = frozenset(
    [
        "card_size_caps",
        "card_rate_limits",
        "scale_engine_self",
        "scale_hero_spell_stats",
        "round_toll",
        "early_spoils",
        "ask_for_kin",
        "last_blow",
        "last_stand",
        "spells_in_shop",
        "hero_choice",
    ]
)
CONFIG_ARRAY_KEYS = frozenset(
    [
        "scale_levers",
        "base_damage_by_turn",
        "income_by_turn",
        "upgrade_costs",
        "pool_copies_by_tier",
        "shop_units_by_tier",
        "damage_cap_by_turn",
        "bots",
        "shop_tier_odds",
        "shop_spells_by_tier",
        "spell_copies_by_tier",
        "opening_spells",
    ]
)
CONFIG_STRING_KEYS = frozenset(("damage_mode", "pool_filter", "human_bot", "scale_engine_tribe"))


def _required(record, keys, context):
    if not isinstance(record, dict):
        raise ValueError(f"{context} must be an object")
    missing = set(keys) - record.keys()
    if missing:
        raise ValueError(f"{context} missing required fields: {', '.join(sorted(missing))}")


def _unit_spec(spec, context):
    _required(spec, ("def_id", "golden", "attack", "health", "iid", "tribe_attack", "tribe_health"), context)
    if not isinstance(spec["def_id"], str) or not spec["def_id"] or type(spec["golden"]) is not bool:
        raise ValueError(f"{context} needs a unit id and explicit golden state")
    for key in ("attack", "health", "iid", "tribe_attack", "tribe_health"):
        if type(spec[key]) is not int:
            raise ValueError(f"{context}.{key} must be an integer")
    if "held" in spec:
        if not isinstance(spec["held"], list):
            raise ValueError(f"{context}.held must be an array")
        for index, held in enumerate(spec["held"]):
            _unit_spec(held, f"{context}.held[{index}]")


def load_designed(path):
    """Read explicit designed-only populations; retain every supplied state field."""
    document = json.loads(path.read_text())
    _required(document, ("boards", "line_weights"), "designed input")
    if not isinstance(document["boards"], list) or not document["boards"]:
        raise ValueError("designed boards must be a nonempty array")
    if not isinstance(document["line_weights"], dict) or not document["line_weights"]:
        raise ValueError("designed line_weights must be explicit weights by round")
    test_cards = document.get("test_cards", [])
    if not isinstance(test_cards, list):
        raise ValueError("designed test_cards must be an array")
    boards, seen, configs = [], set(), {}
    provenance = {"kind": "designed", "path": str(path), "sha256": file_sha(path)}
    for index, original in enumerate(document["boards"]):
        context = f"designed boards[{index}]"
        _required(
            original,
            ("round", "line", "layout", "board", "slots", "fight_rules", "hero_effects", "tier", "config"),
            context,
        )
        if type(original["round"]) is not int or original["round"] <= 0:
            raise ValueError(f"{context}.round must be a positive integer")
        if not isinstance(original["line"], str) or not original["line"] or original["layout"] != "blind":
            raise ValueError(f"{context} needs a line and layout=blind")
        if type(original["tier"]) is not int or not 1 <= original["tier"] <= 6:
            raise ValueError(f"{context}.tier must be an integer from 1 to 6")
        if not isinstance(original["board"], list) or len(original["board"]) != 7:
            raise ValueError(f"{context}.board must contain seven explicit slots")
        for slot, spec in enumerate(original["board"]):
            if spec is not None:
                _unit_spec(spec, f"{context}.board[{slot}]")
        slots = original["slots"]
        if (
            not isinstance(slots, list)
            or len(slots) != 7
            or any(not isinstance(row, list) or any(not isinstance(effect, dict) for effect in row) for row in slots)
        ):
            raise ValueError(f"{context}.slots must contain seven arrays of effect objects")
        effects = original["hero_effects"]
        if not isinstance(effects, list) or any(not isinstance(effect, dict) for effect in effects):
            raise ValueError(f"{context}.hero_effects must be an explicit array of effect objects")
        rules = original["fight_rules"]
        _required(rules, REQUIRED_FIGHT_RULES, f"{context}.fight_rules")
        for name in ("larder", "goose", "homecomings"):
            if type(rules[name]) is not int:
                raise ValueError(f"{context}.fight_rules.{name} must be an integer")
        if type(rules["back_row_first"]) is not bool:
            raise ValueError(f"{context}.fight_rules.back_row_first must be a boolean")
        if (
            not isinstance(rules["bands"], list)
            or len(rules["bands"]) != 7
            or any(type(n) is not int for n in rules["bands"])
        ):
            raise ValueError(f"{context}.fight_rules.bands must contain seven integers")
        for name in ("ammo", "nests", "away_birds"):
            if not isinstance(rules[name], list):
                raise ValueError(f"{context}.fight_rules.{name} must be an array")
        for nest in rules["nests"]:
            _required(nest, ("slot", "spec"), f"{context}.fight_rules.nests entry")
            if type(nest["slot"]) is not int or not 0 <= nest["slot"] < 7:
                raise ValueError(f"{context}.fight_rules.nests.slot must be a board slot")
            _unit_spec(nest["spec"], f"{context}.fight_rules.nests.spec")
        _required(original["config"], REQUIRED_CONFIG_KEYS, f"{context}.config")
        for name in REQUIRED_CONFIG_KEYS:
            expected = (
                bool
                if name in CONFIG_BOOL_KEYS
                else list
                if name in CONFIG_ARRAY_KEYS
                else str
                if name in CONFIG_STRING_KEYS
                else int
            )
            if type(original["config"][name]) is not expected:
                raise ValueError(f"{context}.config.{name} must be {expected.__name__}")
        # FieldCombat permits bot seat metadata to differ, but fight rules must agree.
        config = {k: v for k, v in original["config"].items() if k not in ("bots", "human_bot")}
        number = original["round"]
        if number in configs and configs[number] != config:
            raise ValueError(f"mixed designed fight configs for round {number}")
        configs[number] = config
        if "combat_start" in original and not isinstance(original["combat_start"], dict):
            raise ValueError(f"{context}.combat_start must be an object if supplied")
        if (
            "after_start_effects" in original
            and original["after_start_effects"] is not None
            and not isinstance(original["after_start_effects"], dict)
        ):
            raise ValueError(f"{context}.after_start_effects must be an object or null if supplied")
        board = dict(original)
        board.setdefault("id", f"designed:{index}")
        if not isinstance(board["id"], str) or not board["id"] or board["id"] in seen:
            raise ValueError("designed board ids must be unique nonempty strings")
        seen.add(board["id"])
        board["provenance"] = provenance
        if not isinstance(board.get("test_cards", []), list):
            raise ValueError(f"{context}.test_cards must be an array")
        board["test_cards"] = test_cards + board.get("test_cards", [])
        boards.append(board)
    represented = defaultdict(set)
    for board in boards:
        represented[str(board["round"])].add(board["line"])
    if set(document["line_weights"]) != set(represented):
        raise ValueError("designed line_weights must cover exactly the supplied rounds")
    for number, lines in represented.items():
        _validate_line_weights(document["line_weights"][number], lines, number)
    return boards, document["line_weights"]


def _validate_line_weights(weights, lines, number):
    if not isinstance(weights, dict) or set(weights) != set(lines):
        raise ValueError(f"line_weights must cover exactly the represented lines for round {number}")
    if any(type(value) not in (int, float) or not math.isfinite(value) or value <= 0 for value in weights.values()):
        raise ValueError("line_weights must be finite and positive")
    if not math.isclose(sum(weights.values()), 1.0, abs_tol=1e-9):
        raise ValueError("line_weights must sum to one; they are not inferred from designed board counts")


def boards_from_capture(paths, require_blind=True):
    seen = set()
    for path in sorted(paths):
        with path.open() as stream:
            for raw in stream:
                record = json.loads(raw)
                fight = record["input"]
                for side, seat in enumerate(fight["player_ids"]):
                    if int(seat) < 0:
                        continue
                    key = (record["seed"], record["leg"], int(seat), int(fight["round"]))
                    if key in seen:
                        raise ValueError(f"duplicate board: {key}")
                    seen.add(key)
                    snapshot = record["combat_start"][side]
                    if require_blind and snapshot.get("layout") != "blind":
                        raise ValueError("field inputs must be captured with a blind final layout")
                    yield {
                        "id": ":".join(map(str, key)),
                        "seed": key[0],
                        "leg": key[1],
                        "seat": key[2],
                        "round": key[3],
                        "line": snapshot.get("policy", snapshot.get("line", "unknown")),
                        "layout": snapshot.get("layout", "unlabelled"),
                        "board": fight["boards"][side],
                        "slots": fight["slots"][side],
                        "fight_rules": fight["fight_rules"][side],
                        "hero_effects": fight["hero_effects"][side],
                        "tier": fight["tiers"][side],
                        "config": fight["config"],
                        "combat_start": snapshot,
                        "after_start_effects": record["after_start_effects"][side]
                        if record.get("after_start_effects")
                        else None,
                        "test_cards": record.get("test_cards", []),
                    }


def quotas(counts: dict, size: int, require_hard=True) -> dict:
    if type(size) is not int or size < 2 or not counts or any(type(n) is not int or n < 1 for n in counts.values()):
        raise ValueError("field needs positive population counts and at least two boards")
    if sum(counts.values()) < size or len(counts) > size:
        raise ValueError("not enough boards, or field smaller than the number of represented lines")
    if require_hard and "hard" not in counts:
        raise ValueError("Hard tempo anchor is absent")
    allocated = dict.fromkeys(sorted(counts), 1)
    while sum(allocated.values()) < size:
        eligible = [key for key in counts if allocated[key] < counts[key]]
        chosen = min(eligible, key=lambda key: (allocated[key], key))
        allocated[chosen] += 1
    return allocated


def sample_field(boards, rounds=ROUNDS, size=64, seed=91407, *, line_weights=None):
    counts = defaultdict(Counter)
    reservoirs = defaultdict(list)
    streams = {}
    test_cards = {}
    for board in boards:
        for card in board.get("test_cards", []):
            if card["id"] in test_cards and test_cards[card["id"]] != card:
                raise ValueError("conflicting test-only card definitions")
            test_cards[card["id"]] = card
        number, line = board["round"], board["line"]
        if number not in rounds:
            continue
        key = (number, line)
        if key not in streams:
            streams[key] = random.Random(int.from_bytes(hashlib.sha256(f"{seed}|{number}|{line}".encode()).digest()))
        counts[number][line] += 1
        count = counts[number][line]
        reservoir = reservoirs[key]
        if len(reservoir) < size:
            reservoir.append(board)
        else:
            index = streams[key].randrange(count)
            if index < size:
                reservoir[index] = board
    result = {
        "version": 1,
        "sample_seed": seed,
        "size": size,
        "rounds": {},
        "test_cards": list(test_cards.values()),
        "sampling_method": "equal_line_strata_capped_by_availability",
        "source_mode": "designed_only" if line_weights is not None else "captured_population",
        "weight_source": "explicit_designed_line_weights"
        if line_weights is not None
        else "source_population_line_fractions",
    }
    for number in rounds:
        allocation = quotas(counts[number], size, require_hard=line_weights is None)
        total = sum(counts[number].values())
        weights = {line: count / total for line, count in counts[number].items()}
        if line_weights is not None:
            weights = line_weights.get(str(number), line_weights.get(number))
            _validate_line_weights(weights, counts[number], number)
        selected = []
        for line, count in sorted(allocation.items()):
            chosen = streams[number, line].sample(reservoirs[number, line], count)
            for original in chosen:
                board = dict(original)
                board["weight"] = weights[line] / count
                selected.append(board)
        result["rounds"][str(number)] = {
            "boards": selected,
            "population_counts": dict(counts[number]),
            "sample_counts": allocation,
            "line_weights": weights,
        }
    return result


def wilson(wins, total):
    if not total:
        return None
    z = 1.959963984540054
    p = wins / total
    denominator = 1 + z * z / total
    middle = (p + z * z / (2 * total)) / denominator
    spread = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total * total)) / denominator
    return [middle - spread, middle + spread]


def _percentile(values, fraction):
    values = sorted(values)
    index = (len(values) - 1) * fraction
    lower = int(index)
    return values[lower] + (values[min(lower + 1, len(values) - 1)] - values[lower]) * (index - lower)


def board_cluster_intervals(boards, pairs, replicates, seed):
    """Stratified vertex bootstrap of both endpoints of the observed fight matrix.

    One multiplicity per board is shared by all of its opponent results, whether
    it appears as A or B. Pair weights are multiplied by BOTH multiplicities.
    Original self edges remain absent: no unobserved clone-vs-clone fights are
    invented. Fight trials are held fixed, never resampled as independent units.
    """
    if type(replicates) is not int or replicates < 2:
        raise ValueError("board bootstrap needs at least two replicates")
    lines = sorted({board["line"] for board in boards})
    line_index = {line: index for index, line in enumerate(lines)}
    board_index = {board["id"]: index for index, board in enumerate(boards)}
    groups = [[index for index, board in enumerate(boards) if board["line"] == line] for line in lines]
    edges = []
    for pair in pairs:
        a, b = board_index[pair["a"]], board_index[pair["b"]]
        edges.append(
            (
                a,
                b,
                line_index[boards[a]["line"]],
                line_index[boards[b]["line"]],
                boards[a]["weight"] * boards[b]["weight"],
                (pair["wins_a"] + 0.5 * pair["draws"]) / pair["trials"],
            )
        )
    rng = random.Random(seed)
    draws = [[] for _ in lines]
    for _ in range(replicates):
        multiplicities = [0] * len(boards)
        for group in groups:
            for _ in group:
                multiplicities[group[rng.randrange(len(group))]] += 1
        scores, masses = [0.0] * len(lines), [0.0] * len(lines)
        for a, b, left, right, weight, point in edges:
            weighted = weight * multiplicities[a] * multiplicities[b]
            if not weighted:
                continue
            scores[left] += weighted * point
            scores[right] += weighted * (1 - point)
            masses[left] += weighted
            masses[right] += weighted
        for index in range(len(lines)):
            if masses[index]:
                draws[index].append(scores[index] / masses[index])
    return {
        line: {
            "ci95": [_percentile(draws[index], 0.025), _percentile(draws[index], 0.975)] if draws[index] else None,
            "selected_boards": len(groups[index]),
            "low_n": len(groups[index]) < 10,
            "very_low_n": len(groups[index]) < 5,
            "own_line_variation_estimable": len(groups[index]) > 1,
            "valid_bootstrap_replicates": len(draws[index]),
        }
        for index, line in enumerate(lines)
    }


def field_report(field: dict, pairs, *, bootstrap_replicates=1000, bootstrap_seed=91407):
    indexed = {board["id"]: board for round_data in field["rounds"].values() for board in round_data["boards"]}
    scores, mass = defaultdict(float), defaultdict(float)
    matrix_scores, matrix_mass = defaultdict(float), defaultdict(float)
    seen, pair_rows = set(), []
    round_pairs = defaultdict(list)
    for pair in pairs:
        a, b = indexed[pair["a"]], indexed[pair["b"]]
        number = int(pair["round"])
        identity = tuple(sorted((a["id"], b["id"])))
        if identity in seen or a["round"] != b["round"] or number != a["round"] or a["id"] == b["id"]:
            raise ValueError("duplicate, self, or cross-round pair")
        seen.add(identity)
        round_pairs[number].append(pair)
        total = pair["trials"]
        if total <= 0 or pair["wins_a"] + pair["wins_b"] + pair["draws"] != total:
            raise ValueError("incomplete fight counts")
        score = (pair["wins_a"] + 0.5 * pair["draws"]) / total
        for left, right, point in [(a, b, score), (b, a, 1 - score)]:
            scores[left["id"]] += right["weight"] * point
            mass[left["id"]] += right["weight"]
            key = (number, left["line"], right["line"])
            weight = left["weight"] * right["weight"]
            matrix_scores[key] += weight * point
            matrix_mass[key] += weight
        decisive = pair["wins_a"] + pair["wins_b"]
        pair_rows.append(
            {
                **pair,
                "p_win_a": pair["wins_a"] / decisive if decisive else None,
                "p_win_a_ci95": wilson(pair["wins_a"], decisive),
                "pair_weight": a["weight"] * b["weight"],
            }
        )
    expected = sum(len(data["boards"]) * (len(data["boards"]) - 1) // 2 for data in field["rounds"].values())
    if len(seen) != expected:
        raise ValueError(f"need complete round robins: {len(seen)} of {expected} pairs")
    report = {
        "version": 1,
        "rounds": {},
        "pairs": pair_rows,
        "source_mode": field.get("source_mode", "captured_population"),
        "weight_source": field.get("weight_source", "source_population_line_fractions"),
        "uncertainty": {
            "method": "stratified_two_way_endpoint_board_bootstrap_percentile",
            "confidence": 0.95,
            "bootstrap_replicates": bootstrap_replicates,
            "bootstrap_seed": bootstrap_seed,
            "resampling_unit": "whole board, shared across all opponent results and both endpoints",
            "scope": (
                "descriptive conditional field uncertainty; not policy, lobby-seed, or independent-fight inference"
            ),
            "self_pairs": "unobserved original self pairs excluded, including repeated draws of the same board",
            "fight_trials_resampled": False,
            "low_n_threshold": 10,
            "very_low_n_threshold": 5,
            "low_n_caution": (
                "Few boards give unstable intervals; one board cannot estimate its own line's board variation. "
                "More fight trials do not repair this."
            ),
        },
    }
    for key, data in field["rounds"].items():
        number = int(key)
        boards = [
            {
                "id": b["id"],
                "line": b["line"],
                "weight": b["weight"],
                "field_point_rate": scores[b["id"]] / mass[b["id"]],
            }
            for b in data["boards"]
        ]
        lines = sorted(data["line_weights"])
        line_rates = {}
        for line in lines:
            line_rates[line] = sum(matrix_scores[number, line, other] for other in lines) / sum(
                matrix_mass[number, line, other] for other in lines
            )
        round_seed = int.from_bytes(hashlib.sha256(f"{bootstrap_seed}|{number}".encode()).digest())
        intervals = board_cluster_intervals(data["boards"], round_pairs[number], bootstrap_replicates, round_seed)
        report["rounds"][key] = {
            "boards": boards,
            "line_weights": data["line_weights"],
            "line_point_rates": line_rates,
            "line_point_rate_ci95": {line: result["ci95"] for line, result in intervals.items()},
            "line_sample_sizes": {line: result["selected_boards"] for line, result in intervals.items()},
            "line_uncertainty": intervals,
            "win_matrix": {
                line: {
                    other: matrix_scores[number, line, other] / matrix_mass[number, line, other]
                    if matrix_mass[number, line, other]
                    else None
                    for other in lines
                }
                for line in lines
            },
            "strongest_line": max(line_rates, key=line_rates.get),
            "field_includes_hard": "hard" in line_rates,
            # Retain the key for old readers without claiming the tautological
            # max(including Hard) comparison establishes a strength gate.
            "hard_floor_passes": None,
            "hard_floor_status": "not_a_strength_gate; use fresh held-out head-to-head evidence",
        }
    return report


def file_sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    sample = commands.add_parser("sample")
    sample.add_argument("captures", type=Path, nargs="*")
    sample.add_argument(
        "--designed", type=Path, help="designed-only JSON with complete boards and explicit per-round line_weights"
    )
    sample.add_argument("--out", type=Path, required=True)
    sample.add_argument("--size", type=int, default=64)
    sample.add_argument("--rounds", default=",".join(map(str, ROUNDS)))
    sample.add_argument("--seed", type=int, default=91407)
    report = commands.add_parser("report")
    report.add_argument("field", type=Path)
    report.add_argument("pairs", type=Path)
    report.add_argument("--out", type=Path, required=True)
    report.add_argument("--bootstrap-replicates", type=int, default=1000)
    report.add_argument("--bootstrap-seed", type=int, default=91407)
    args = parser.parse_args()
    if args.command == "sample":
        if bool(args.captures) == bool(args.designed):
            parser.error("sample needs captures OR --designed; designed and lobby populations cannot be mixed")
        weights = None
        if args.designed:
            boards, weights = load_designed(args.designed)
        else:
            boards = boards_from_capture(args.captures)
        result = sample_field(
            boards, tuple(map(int, args.rounds.split(","))), args.size, args.seed, line_weights=weights
        )
        result["sources"] = {
            str(path): file_sha(path) for path in ([args.designed] if args.designed else args.captures)
        }
    else:
        with args.pairs.open() as stream:
            result = field_report(
                json.loads(args.field.read_text()),
                (json.loads(line) for line in stream),
                bootstrap_replicates=args.bootstrap_replicates,
                bootstrap_seed=args.bootstrap_seed,
            )
    args.out.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
