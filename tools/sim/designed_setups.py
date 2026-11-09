#!/usr/bin/env python3
"""Explicit constructed boards, never inferred from bot strength or card budgets.

`screen --out designed.json` freezes the first factorial field. `board --round 12
--total 500 --bodies 7 --distribution carry --keywords shield cleave --answer
biggest --out setup.json` writes field.py's designed-input format. Totals include
all support and answer bodies. Keywords cost no stats: their count is reported.
"""

from __future__ import annotations

import argparse
import copy
import itertools
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAT_CLAMP = 1_000_000_000
TARGETS = {6: 52, 9: 150, 12: 500, 15: 1700}
KEYWORDS = {"shield", "damage_reduction", "cleave"}


def default_config():
    return json.loads((ROOT / "tools/sim/evidence/designed-config.json").read_text())


def _grant(keyword):
    filename = "scale_cleaver" if keyword == "cleave" else "scale_defender"
    definition = json.loads((ROOT / f"content/levers/{filename}.json").read_text())
    entry = next(entry for entry in definition["mechanics"] if entry["id"] == keyword)
    return {"entry": entry, "golden": False, "keyword": keyword, "combat_only": False}


def make_board(
    round_number,
    total,
    bodies=7,
    distribution="carry",
    keywords=(),
    answer="none",
    answer_percent=50,
    identifier=None,
    scale="typical",
    allow_clamp=False,
    config=None,
):
    if round_number not in TARGETS or type(round_number) is not int:
        raise ValueError("designed rounds are 6, 9, 12 and 15")
    if type(bodies) is not int or not 1 <= bodies <= 7 or type(total) is not int:
        raise ValueError("require integer total and 1..7 bodies")
    if distribution not in ("carry", "even") or answer not in ("none", "biggest", "percent"):
        raise ValueError("unknown distribution or answer")
    words = sorted(set(keywords))
    if not set(words) <= KEYWORDS:
        raise ValueError("unknown stat-holding keyword")
    if type(answer_percent) is not int or not 0 <= answer_percent <= 100:
        raise ValueError("answer percentage must be 0..100")
    answer_count = int(answer != "none")
    holders = bodies - answer_count
    if holders < 1 or total < holders * 2 + answer_count * 6:
        raise ValueError("total must fund positive stat holders and a printed 3/3 answer")
    available = total - answer_count * 6
    if distribution == "carry":
        allocated = [available - 2 * (holders - 1)] + [2] * (holders - 1)
    else:
        quotient, remainder = divmod(available, holders)
        allocated = [quotient + int(index < remainder) for index in range(holders)]
    values = copy.deepcopy(default_config() if config is None else config)
    values["scale_answer_percent"] = answer_percent
    board = [None] * 7
    keyword_bodies = 0
    clamped = []
    for index in range(bodies):
        is_answer = index >= holders
        size = 6 if is_answer else allocated[index]
        attack, health = size // 2, size - size // 2
        if max(attack, health) > STAT_CLAMP:
            if not allow_clamp:
                raise ValueError("requested body exceeds engine's 1-billion per-stat clamp")
            clamped.append({"slot": index, "requested_attack": attack, "requested_health": health})
            attack, health = min(attack, STAT_CLAMP), min(health, STAT_CLAMP)
        receives_keywords = not is_answer and (distribution == "even" or index == 0)
        grants = [_grant(word) for word in words] if receives_keywords else []
        keyword_bodies += int(bool(grants))
        board[index] = {
            "def_id": ("scale_biggest_answer" if answer == "biggest" else "scale_answer") if is_answer else "mouse",
            "golden": False,
            "attack": attack,
            "health": health,
            "iid": index + 1,
            "tribe_attack": 0,
            "tribe_health": 0,
            "grants": grants,
        }
    realized = sum(unit["attack"] + unit["health"] for unit in board if unit)
    label = identifier or f"{scale}-{distribution}-{'_'.join(words) or 'plain'}-{answer}"
    return {
        "id": f"r{round_number}:{label}",
        "round": round_number,
        "line": label,
        "layout": "blind",
        "board": board,
        "slots": [[] for _ in range(7)],
        "fight_rules": {
            "larder": 0,
            "goose": 0,
            "homecomings": 0,
            "back_row_first": False,
            "bands": [0] * 7,
            "ammo": [],
            "nests": [],
            "away_birds": [],
        },
        "hero_effects": [],
        "tier": 3 if round_number <= 9 else 5 if round_number == 12 else 6,
        "config": values,
        "design": {
            "scale": scale,
            "distribution": distribution,
            "target_total": total,
            "realized_total": realized,
            "bodies": bodies,
            "keywords": words,
            "answer": answer,
            "answer_percent": answer_percent if answer != "none" else None,
            "answer_stats_included": answer_count * 6,
            "keyword_bodies": keyword_bodies,
            "clamped": clamped,
            "stat_definition": "sum of Attack + Health before Start of Combat",
            "layout_rule": "stat holders first, 1/1 supports next, answer last; no scouting or search",
        },
    }


def make_document(boards):
    if not boards or len({board["id"] for board in boards}) != len(boards):
        raise ValueError("designed board ids must be nonempty and unique")
    lines = {}
    for board in boards:
        lines.setdefault(str(board["round"]), set()).add(board["line"])
    return {
        "version": 1,
        "boards": boards,
        "line_weights": {number: {line: 1 / len(names) for line in sorted(names)} for number, names in lines.items()},
        "construction": "explicit fixed setups; weights are equal setup weights, not estimates of lobby frequencies",
    }


def generate_screen():
    boards = []
    for number, scale, distribution, keyword, answer in itertools.product(
        [9, 12, 15],
        ["typical", "strong"],
        ["carry", "even"],
        [None, "shield", "damage_reduction", "cleave"],
        ["none", "biggest"],
    ):
        total = TARGETS[number] * (14 if scale == "strong" else 10) // 10
        boards.append(
            make_board(
                number,
                total,
                distribution=distribution,
                keywords=[keyword] if keyword else [],
                answer=answer,
                scale=scale,
            )
        )
    return make_document(boards)


def boundary_screen():
    # Literal owner example is per-stat. 2.1B cannot be represented by this engine;
    # preserve requested/realized budgets explicitly instead of changing its clamp.
    boards = []
    for distribution, bodies, total in [("even", 3, 3_000_000_000), ("carry", 1, 4_200_000_000)]:
        boards.append(
            make_board(
                15,
                total,
                bodies=bodies,
                distribution=distribution,
                identifier=f"boundary-{distribution}-plain",
                scale="boundary",
                allow_clamp=True,
            )
        )
        # An answer costs one slot and its printed stats in addition to the quoted stat bodies.
        boards.append(
            make_board(
                15,
                total + 6,
                bodies=bodies + 1,
                distribution=distribution,
                answer="biggest",
                identifier=f"boundary-{distribution}-answer",
                scale="boundary",
                allow_clamp=True,
            )
        )
    return make_document(boards)


def owner_analogue():
    """Preserve the quoted 500:2100 per-stat ratio below the engine clamp."""
    boards = []
    for distribution, bodies, total in [("even", 3, 3000), ("carry", 1, 4200)]:
        for answer in ["none", "biggest"]:
            extra = int(answer != "none")
            boards.append(
                make_board(
                    15,
                    total + 6 * extra,
                    bodies=bodies + extra,
                    distribution=distribution,
                    answer=answer,
                    identifier=f"analogue-{distribution}-{answer}",
                    scale="boundary",
                )
            )
    return make_document(boards)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["screen", "boundary", "analogue", "board"])
    parser.add_argument("--round", type=int, default=12, dest="round_number")
    parser.add_argument("--total", type=int)
    parser.add_argument("--bodies", type=int, default=7)
    parser.add_argument("--distribution", choices=["carry", "even"], default="carry")
    parser.add_argument("--keywords", nargs="*", choices=sorted(KEYWORDS), default=[])
    parser.add_argument("--answer", choices=["none", "biggest", "percent"], default="none")
    parser.add_argument("--answer-percent", type=int, default=50)
    parser.add_argument("--allow-clamp", action="store_true")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "screen":
        document = generate_screen()
    elif args.command == "boundary":
        document = boundary_screen()
    elif args.command == "analogue":
        document = owner_analogue()
    else:
        total = TARGETS[args.round_number] if args.total is None else args.total
        document = make_document(
            [
                make_board(
                    args.round_number,
                    total,
                    args.bodies,
                    args.distribution,
                    args.keywords,
                    args.answer,
                    args.answer_percent,
                    allow_clamp=args.allow_clamp,
                )
            ]
        )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(document, indent=2) + "\n")
    print(json.dumps({"boards": len(document["boards"]), "out": str(args.out)}))


if __name__ == "__main__":
    main()
