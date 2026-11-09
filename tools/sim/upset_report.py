"""Describe controlled winner reversals in a frozen diagnostic sample.

No lower-stat test or effect-event count is used as evidence of a cause. Flags
can overlap. Rates describe these selected board pairs and intervention seeds.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
from collections import Counter, defaultdict
from itertools import combinations
from pathlib import Path
from typing import Any

OUTCOME_KEYS = {
    f"{mask}.{layout}"
    for mask in ("intact", "masked")
    for layout in ("original", "a_alternate", "b_alternate", "coin_flipped")
}
FLAG_NAMES = (
    "answer_necessary",
    "answer_draw_transition",
    "placement_necessary",
    "placement_draw_transition",
    "first_attack_coin_necessary",
    "first_attack_coin_draw_transition",
    "other_rng_sensitive",
    "unexplained",
    "invariant",
)


def make_plan(field: dict[str, Any], field_sha256: str, seeds: list[str]) -> dict[str, Any]:
    """Freeze eight diagnostic pairs using IDs/line strata, without reading fight outcomes.

    Rank unordered cross-line pairs by SHA256 of
    ``upset-reader-v1|round|minid|maxid``. Within each round, choose Hard cross-line,
    then non-Hard cross-line, then (rounds 10/12 only) any remaining cross-line
    pair. Preserve source board ordering for the original A/B orientation.
    """
    if (
        not isinstance(field_sha256, str)
        or len(field_sha256) != 64
        or any(character not in "0123456789abcdef" for character in field_sha256)
    ):
        raise ValueError("field_sha256 must be the frozen field's lowercase SHA256")
    if not isinstance(seeds, list) or len(seeds) != 8:
        raise ValueError("freeze exactly eight distinct integer-string seeds")
    for seed in seeds:
        try:
            valid = isinstance(seed, str) and str(int(seed)) == seed and -(2**63) <= int(seed) < 2**63
        except ValueError:
            valid = False
        if not valid:
            raise ValueError("seeds must be canonical signed-64-bit integer strings")
    if len(set(seeds)) != 8:
        raise ValueError("freeze exactly eight distinct integer-string seeds")
    rounds = field.get("rounds")
    if not isinstance(rounds, dict):
        raise ValueError("field must contain rounds 10, 12 and 14")
    selected = []
    for round_number, strata in (
        (10, ("hard-cross", "nonhard-cross", "any-cross")),
        (12, ("hard-cross", "nonhard-cross", "any-cross")),
        (14, ("hard-cross", "nonhard-cross")),
    ):
        round_data = rounds.get(str(round_number))
        if not isinstance(round_data, dict) or not isinstance(round_data.get("boards"), list):
            raise ValueError(f"field missing boards for round {round_number}")
        boards = round_data["boards"]
        identifiers = set()
        for board in boards:
            if (
                not isinstance(board, dict)
                or not isinstance(board.get("id"), str)
                or not board["id"]
                or not isinstance(board.get("line"), str)
                or not board["line"]
            ):
                raise ValueError(f"round {round_number} boards need nonempty id and line")
            if board["id"] in identifiers:
                raise ValueError(f"duplicate board ID in round {round_number}")
            identifiers.add(board["id"])
        candidates = []
        for left, right in combinations(boards, 2):
            if left["line"] == right["line"]:
                continue
            low, high = sorted((left["id"], right["id"]))
            rank = hashlib.sha256(f"upset-reader-v1|{round_number}|{low}|{high}".encode()).hexdigest()
            has_hard = left["line"] == "hard" or right["line"] == "hard"
            candidates.append((rank, low, high, has_hard, left["id"], right["id"]))
        candidates.sort()
        used = set()
        for stratum in strata:
            eligible = [
                item
                for item in candidates
                if (item[1], item[2]) not in used and (stratum == "any-cross" or item[3] == (stratum == "hard-cross"))
            ]
            if not eligible:
                raise ValueError(f"round {round_number} has insufficient distinct {stratum} pairs")
            _, low, high, _, a, b = eligible[0]
            used.add((low, high))
            selected.append({"a": a, "b": b, "selection_stratum": stratum, "round": round_number})
    return {
        "version": 1,
        "purpose": "reader screening; no population-frequency or strength inference",
        "field_sha256": field_sha256,
        "selection": "hash-minimum cross-line pairs, strata by round and Hard presence, without fight outcomes",
        "selection_protocol": "upset-reader-v1|round|minid|maxid",
        "pairs": selected,
        "seeds": list(seeds),
        "orientations": 2,
        "expected_trials": 128,
        "expected_fights": 1024,
        "attribution": (
            "overlapping controlled winner reversals; unidentified residual retained; "
            "placement is combat-layout sensitivity, not optimal recruit legality"
        ),
    }


def _validate(rows: list[dict[str, Any]]) -> None:
    if not rows:
        raise ValueError("no controlled trials")
    seen = set()
    hashes: dict[str, set[str]] = {key: set() for key in ("field_sha256", "plan_sha256")}
    for row in rows:
        if row.get("version") != 1 or row.get("fights") != 8:
            raise ValueError("expected version 1 controlled trial with eight fights")
        a, b = row["a"], row["b"]
        if not isinstance(a, str) or not isinstance(b, str) or a == b:
            raise ValueError("distinct original board IDs required")
        if type(row["orientation"]) is not int or row["orientation"] not in (0, 1):
            raise ValueError("invalid orientation")
        orientation = row["orientation"]
        if row["side_board_ids"] != ([a, b] if orientation == 0 else [b, a]):
            raise ValueError("board orientation does not match original IDs")
        if not isinstance(row["seed"], str) or not row["seed"].lstrip("-").isdigit():
            raise ValueError("seed must be an explicit integer string")
        key = (a, b, row["seed"], orientation)
        if key in seen:
            raise ValueError("duplicate controlled trial")
        seen.add(key)
        for name in (*hashes, "baseline_input_sha256"):
            value = row[name]
            if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
                raise ValueError(f"invalid {name}")
            if name in hashes:
                hashes[name].add(value)
        if type(row["mask_supported"]) is not bool or row["mask_supported"] != (not row["mask_unsupported"]):
            raise ValueError("inconsistent mask support")
        if not isinstance(row["mask_manifest"], list):
            raise ValueError("missing explicit mask manifest")
        outcomes = row["outcomes"]
        if set(outcomes) != OUTCOME_KEYS:
            raise ValueError("missing or additional interventions")
        for outcome in outcomes.values():
            winner = outcome["winner"]
            if type(winner) is not int or winner not in (-1, 0, 1):
                raise ValueError("invalid canonical winner")
            raw_winner = outcome["result"]["winner"]
            expected = raw_winner if raw_winner == -1 or orientation == 0 else 1 - raw_winner
            if winner != expected:
                raise ValueError("winner was not mapped to original board IDs")
            if type(outcome["first_coin_eligible"]) is not bool:
                raise ValueError("missing first-attack coin eligibility")
            for name in ("first_side_original", "first_side_used"):
                if type(outcome[name]) is not int or outcome[name] not in (0, 1):
                    raise ValueError("invalid first-attack side")
        for mask in ("intact", "masked"):
            original, flipped = outcomes[f"{mask}.original"], outcomes[f"{mask}.coin_flipped"]
            if original["first_side_original"] != flipped["first_side_original"]:
                raise ValueError("coin flip did not preserve original RNG draw")
            eligible = original["first_coin_eligible"]
            if eligible != flipped["first_coin_eligible"]:
                raise ValueError("coin eligibility changed")
            expected = 1 - original["first_side_used"] if eligible else original["first_side_used"]
            if flipped["first_side_used"] != expected:
                raise ValueError("incorrect first-attack coin override")
            if not eligible and original != flipped:
                raise ValueError("ineligible coin intervention changed the fight")
        if set(row["layouts"]) != {a, b}:
            raise ValueError("layout metadata must use original board IDs")
        for layout in row["layouts"].values():
            mapping = layout["old_to_new"]
            if sorted(mapping) != list(range(7)) or any(mapping[slot] != slot for slot in layout["pinned_slots"]):
                raise ValueError("invalid layout map or moved Egg/Nest slot")
    if any(len(values) != 1 for values in hashes.values()):
        raise ValueError("mixed frozen plans or baseline fields")


def classify_trials(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Classify a win by same-input interventions; seed sensitivity holds first side fixed."""
    _validate(rows)
    rng_groups: dict[tuple[Any, ...], set[int]] = defaultdict(set)
    for row in rows:
        original = row["outcomes"]["intact.original"]
        key = (row["a"], row["b"], row["orientation"], original["first_side_used"])
        rng_groups[key].add(original["winner"])
    classified = []
    for row in rows:
        outcomes = row["outcomes"]
        original = outcomes["intact.original"]
        winner = original["winner"]
        flags: dict[str, bool | None] = dict.fromkeys(FLAG_NAMES)
        if winner >= 0:
            loser = 1 - winner
            masked = outcomes["masked.original"]["winner"]
            placement = [outcomes[f"intact.{name}_alternate"]["winner"] for name in ("a", "b")]
            coin = outcomes["intact.coin_flipped"]["winner"]
            supported = row["mask_supported"]
            flags["answer_necessary"] = masked == loser if supported else None
            flags["answer_draw_transition"] = masked == -1 if supported else None
            flags["placement_necessary"] = loser in placement
            flags["placement_draw_transition"] = -1 in placement
            flags["first_attack_coin_necessary"] = original["first_coin_eligible"] and coin == loser
            flags["first_attack_coin_draw_transition"] = original["first_coin_eligible"] and coin == -1
            key = (row["a"], row["b"], row["orientation"], original["first_side_used"])
            flags["other_rng_sensitive"] = len(rng_groups[key]) > 1
            resolved = any(flags[name] for name in FLAG_NAMES[:7])
            flags["unexplained"] = not resolved if supported else None
            flags["invariant"] = (
                all(item["winner"] == winner for item in outcomes.values()) and not flags["other_rng_sensitive"]
                if supported
                else None
            )
        classified.append(
            {
                "a": row["a"],
                "b": row["b"],
                "seed": row["seed"],
                "orientation": row["orientation"],
                "baseline_winner": winner,
                "mask_supported": row["mask_supported"],
                "flags": flags,
            }
        )
    return classified


def _quantile(values: list[float], fraction: float) -> float:
    position = (len(values) - 1) * fraction
    low = int(position)
    high = min(low + 1, len(values) - 1)
    return values[low] + (values[high] - values[low]) * (position - low)


def upset_report(
    rows: list[dict[str, Any]], *, bootstrap_replicates: int = 2000, bootstrap_seed: int = 731
) -> dict[str, Any]:
    if bootstrap_replicates < 0:
        raise ValueError("bootstrap_replicates must be nonnegative")
    trials = classify_trials(rows)
    board_ids = sorted({row[name] for row in rows for name in ("a", "b")})
    intervals: dict[str, list[float]] = {name: [] for name in FLAG_NAMES}
    rng = random.Random(bootstrap_seed)
    # Shared endpoint weights keep all seeds/orientations and every appearance of a
    # board together. Sparse selected edges can leave some resamples with no fights.
    for _ in range(bootstrap_replicates):
        weights = Counter(rng.choices(board_ids, k=len(board_ids)))
        numerators: Counter[str] = Counter()
        denominators: Counter[str] = Counter()
        for trial in trials:
            weight = weights[trial["a"]] * weights[trial["b"]]
            for name, value in trial["flags"].items():
                if value is not None:
                    denominators[name] += weight
                    numerators[name] += weight * int(value)
        for name in FLAG_NAMES:
            if denominators[name]:
                intervals[name].append(numerators[name] / denominators[name])
    totals = {}
    for name in FLAG_NAMES:
        eligible = [trial for trial in trials if trial["flags"][name] is not None]
        count = sum(bool(trial["flags"][name]) for trial in eligible)
        values = sorted(intervals[name])
        totals[name] = {
            "count": count,
            "denominator_baseline_wins": len(eligible),
            "rate": count / len(eligible) if eligible else None,
            "selected_board_ci95": [_quantile(values, 0.025), _quantile(values, 0.975)] if values else None,
            "valid_bootstrap_replicates": len(values),
        }
    pairs = {(row["a"], row["b"]) for row in rows}
    complete = len(pairs) == 8 and len(rows) == 128
    expected_seeds = {row["seed"] for row in rows}
    complete = (
        complete
        and len(expected_seeds) == 8
        and all(
            {(row["seed"], row["orientation"]) for row in rows if (row["a"], row["b"]) == pair}
            == {(seed, orientation) for seed in expected_seeds for orientation in (0, 1)}
            for pair in pairs
        )
    )
    return {
        "version": 1,
        "scope": "controlled diagnostic sample; no population upset-frequency or optimal-placement claim",
        "cause_definition": "same-input/RNG winner reversal under a declared intervention; flags overlap",
        "answer_scope": "joint class on both sides; does not attribute the win to the winner's own answer card",
        "other_rng_scope": "different seeds with the same initial attack side; includes later and effect RNG",
        "field_sha256": rows[0]["field_sha256"],
        "plan_sha256": rows[0]["plan_sha256"],
        "complete_frozen_design": complete,
        "trials": len(rows),
        "fights": sum(row["fights"] for row in rows),
        "selected_pairs": len(pairs),
        "selected_boards": len(board_ids),
        "baseline_wins": sum(trial["baseline_winner"] >= 0 for trial in trials),
        "baseline_draws": sum(trial["baseline_winner"] < 0 for trial in trials),
        "first_attack_coin_eligible_baseline_wins": sum(
            row["outcomes"]["intact.original"]["winner"] >= 0
            and row["outcomes"]["intact.original"]["first_coin_eligible"]
            for row in rows
        ),
        "unsupported_mask_trials": sum(not row["mask_supported"] for row in rows),
        "attribution": totals,
        "uncertainty": {
            "scope": "conditional sensitivity to the selected boards and fixed seeds; not population inference",
            "resampling_unit": "whole board, shared across all opponents, seeds, orientations and interventions",
            "fight_trials_resampled": False,
            "bootstrap_replicates": bootstrap_replicates,
            "bootstrap_seed": bootstrap_seed,
            "very_low_n": len(board_ids) < 20,
            "limitations": (
                "eight purposively selected diagnostic pairs; sparse-edge resamples may have no eligible wins"
            ),
        },
        "per_trial": trials,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("trials", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--bootstrap-replicates", type=int, default=2000)
    parser.add_argument("--bootstrap-seed", type=int, default=731)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.trials.read_text().splitlines() if line.strip()]
    report = upset_report(rows, bootstrap_replicates=args.bootstrap_replicates, bootstrap_seed=args.bootstrap_seed)
    args.out.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
