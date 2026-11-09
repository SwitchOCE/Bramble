#!/usr/bin/env python3
"""Explicit constructed boards, never inferred from bot strength or card budgets.

`screen --out designed.json` freezes the first factorial field. `board --round 12
--total 500 --bodies 7 --distribution carry --keywords shield cleave --answer
biggest --out setup.json` writes field.py's designed-input format. Totals include
all support and answer bodies. Keywords cost no stats: their count is reported.

`real --out recipes.json` writes the eight committed-line/payoff recipes. Run
`export_real_designed.gd -- recipes.json designed-input.json` under the harness
lock to materialize real cards through the current configured library and the
game's PlayerState combat boundary. No shop attainability is inferred.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import itertools
import json
from pathlib import Path

from evidence_io import write_json

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


def real_card_recipes(lines_dir=None):
    """Constructed model states; the adapter supplies current library text and specs.

    These are not claims that shops achieve these states by the named round.
    Ring/body budgets follow the pass 3 typical models; their neutral placeholders
    become real answers selected from the committed line's priority list.
    """
    directory = ROOT / "tools/sim/lines" if lines_dir is None else Path(lines_dir)
    profiles, hashes = {}, {}
    for path in sorted(directory.glob("*.json")):
        profiles.update(json.loads(path.read_text()))
        label = str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)
        hashes[label] = hashlib.sha256(path.read_bytes()).hexdigest()
    for name in ("birds_homecoming", "fairies_ring"):
        if name not in profiles:
            raise ValueError(f"missing committed line {name}")

    def body(card, stats=None, **state):
        return {"def_id": card, **({"stats": list(stats)} if stats is not None else {}), **state}

    birds = {
        8: [
            body("one_swallow", (2, 4)),
            body("mr_redbreast", (8, 10)),
            body("mrs_jay", (14, 14)),
            body("mrs_dunnock", (2, 3)),
            body("tom_tit", (3, 4)),
            body("jack_daw", (3, 4)),
            body("mrs_stork", (4, 7)),
        ],
        10: [
            body("mr_redbreast", (22, 24)),
            body("mrs_jay", (32, 32)),
            body("mrs_jay", (16, 16)),
            body("tom_tit", (9, 10)),
            body("jack_daw", (9, 10)),
            body("mrs_stork", (10, 13)),
            body("cuckoo", (10, 13)),
        ],
        12: [
            body("great_lump"),
            body("mrs_jay", (78, 78)),
            body("mr_redbreast", (50, 54)),
            body("mrs_jay", (34, 34)),
            body("mrs_stork", (15, 19)),
            body("tom_tit", (14, 16)),
            body("old_tern", (10, 12)),
        ],
    }
    skies = {
        8: [body("chiffchaff", (6, 8), nest=-1), body("mrs_jay", (6, 6), nest=-1)],
        10: [
            body("chiffchaff", (19, 23), nest=-1),
            body("one_swallow", (2, 4), nest=-1),
            body("old_tern", (5, 6), nest=-1),
        ],
        12: [
            body("chiffchaff", (78, 94), nest=0),
            body("one_swallow", (8, 13), nest=-1),
            body("mother_goose", nest=-1),
        ],
    }
    fairies = {
        8: [
            "old_moth_annis",
            "cluricaun",
            "lob_lie_by_the_fire",
            "hedge_witch",
            "changeling",
            "sally_spore",
            "hob_in_the_hearth",
        ],
        10: ["old_moth_annis", "cradle_fetch", "cluricaun", "hedge_witch", "belladonna", "silky", "hob_in_the_hearth"],
        12: [
            "old_moth_annis",
            "cradle_fetch",
            "cluricaun",
            "will_o_the_wisp",
            "belladonna",
            "fairy_monarch",
            "hob_in_the_hearth",
        ],
    }
    recipes = []
    for number in (8, 10, 12):
        for name, units in (("birds_homecoming", birds[number]), ("fairies_ring", [body(c) for c in fairies[number]])):
            profile = profiles[name]
            priority = profile.get("buy_priority", profile.get("priority", []))
            used = [entry["def_id"] for entry in units] + (
                [entry["def_id"] for entry in skies[number]] if name == "birds_homecoming" else []
            )
            if not set(used) <= set(priority):
                raise ValueError(f"constructed {name} has cards absent from its priority list")
            tier = max(int(key[1:]) for key, turn in profile["climb"].items() if turn <= number)
            recipe = {
                "id": f"r{number}:real-{name}",
                "line": name,
                "round": number,
                "tier": tier,
                "units": units,
                "source_line": name,
                "profile_priority": priority,
                "source": f"docs/ideation/content/pass3/{profile['tribe']}-pass3.md",
            }
            if name == "birds_homecoming":
                recipe.update(
                    away=skies[number],
                    tribe_bonus=1,
                    assumptions=(
                        "Typical model raw body budgets plus one tribe bonus. "
                        "Away birds land in two rounds; only R12 Chiffchaff owns an occupied Nest. "
                        "No recruit history is inferred."
                    ),
                )
            else:
                recipe.update(
                    rings=[1, 1, 1, 1, {8: 13, 10: 23, 12: 33}[number], 2, 4],
                    ring_size={8: 1, 10: 4, 12: 6}[number],
                    assumptions=(
                        "Typical model Ring counts/size; real printed bodies. "
                        "Neutral placeholders become the line's Witch and Changeling. "
                        "No achieved shop history is inferred."
                    ),
                )
            recipes.append(recipe)
    granny = [
        body("sixpenny_pie", (47, 47), held=[body("mouse"), body("mouse")]),
        body("granny_stir_up", (44, 43)),
        body("moss_ooze", (43, 43)),
        body("elder_ooze", (44, 44)),
        body("stone_soup", (42, 41)),
        body("bubble_and_squeak", (145, 145), held=[body("mouse")]),
        body("dishwater_nell", (41, 40)),
    ]
    recipes.append(
        {
            "id": "r12:real-granny-pot-luck",
            "line": "granny_pot_luck",
            "round": 12,
            "tier": 6,
            "units": granny,
            "source": "docs/ideation/content/pass3/oozes-pass3.md#non-carry-route-pot-luck",
            "assumptions": (
                "Documented R12 Pot Luck outer bodies; unspecified three meals are printed Mice. "
                "Current library text governs Granny and reserves, including unmerged Ooze designs."
            ),
        }
    )
    omen = copy.deepcopy(birds[12])
    omen[3] = body("seven_whistlers")
    recipes.append(
        {
            "id": "r12:real-seven-whistlers-omen",
            "line": "seven_whistlers_omen",
            "round": 12,
            "tier": 6,
            "units": omen,
            "source": "docs/ideation/content/pass3/birds-pass3.md",
            "assumptions": (
                "Homecoming R12 bodies with the second Jay replaced by Whistlers: "
                "exactly seven distinct Birds home, none away. "
                "Constructed omen turn, not a sampled shop outcome."
            ),
        }
    )
    return {
        "version": 1,
        "kind": "real_card_recipes",
        "boards": recipes,
        "line_files_sha256": hashes,
        "construction": "explicit pass 3 modeled snapshots; not observed frequencies or achieved-by-round histories",
    }


def real_field(document):
    """All generated boards grouped by round, for a small designed-only smoke."""
    rounds = {}
    for board in document["boards"]:
        rounds.setdefault(str(board["round"]), {"boards": [], "line_weights": {}})["boards"].append(board)
    for group in rounds.values():
        names = sorted({board["line"] for board in group["boards"]})
        group["line_weights"] = {name: 1 / len(names) for name in names}
    return {"version": 1, "rounds": rounds, "construction": document["construction"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["screen", "boundary", "analogue", "board", "real"])
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
    if args.command == "real":
        document = real_card_recipes()
    elif args.command == "screen":
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
    write_json(args.out, document)
    print(json.dumps({"boards": len(document["boards"]), "out": str(args.out)}))


if __name__ == "__main__":
    main()
