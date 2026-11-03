#!/usr/bin/env python3
"""Validates the prototype's unit files in content/units/ against docs/prototype/SPEC.md ("Unit files").

Checks every *.json file: required fields and their types, tier 1-6, known mechanic ids with exactly
the parameters the spec lists for them, known tribes, unique ids, and that death_summon names a unit
that exists. The mechanic table here must match the spec's mechanic table.

Usage: python3 tools/checks/check_units.py [units dir]. Exit 0 = all valid, 1 = problems (listed).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

UNITS_DIR = Path("content/units")
TRIBES = {"Fairies", "Oozes", "Hedgerow folk", "Hunters", "Birds", "Bog folk", "Hive"}
ROW_HINTS = {"front", "back", None}
SOURCE_KINDS = {"library", "filler", "token"}
FAST_ACTIONS = {"refresh", "buy", "sell"}

# Mechanic id -> {parameter: kind}. Kinds: "number" doubles on golden, "threshold" keeps its value,
# "unit" is a unit id, "tribe" a tribe name, "action" a Fast action, "bool" a flag.
MECHANICS: dict[str, dict[str, str]] = {
    "nightshade_mark": {"count": "number"},
    "nightshade_on_hit": {},
    "bristle": {"n": "number"},
    "death_summon": {"unit": "unit", "count": "threshold"},
    "hunker": {},
    "survive_buff_behind": {"attack": "number"},
    "shell": {"n": "threshold"},
    "mire": {},
    "bystander": {"attack": "number", "health": "number"},
    "grant_first_bite_in_front": {},
    "quick_while_undamaged": {},
    "peck": {"strikes": "threshold"},
    "on_attack_buff_tribe": {"tribe": "tribe", "attack": "number"},
    "swarm": {},
    "both_ends": {"attack": "number", "health": "number", "prick": "number"},
    "bide_slumber": {"attack": "number", "health": "number"},
    "whistle": {},
    "mark": {"damage": "number"},
    "fast": {"action": "action", "turns": "threshold", "feast_attack": "number", "feast_health": "number"},
}

# Field -> allowed Python types (None means JSON null is allowed).
FIELDS: dict[str, tuple[type | None, ...]] = {
    "id": (str,),
    "name": (str,),
    "tier": (int,),
    "attack": (int,),
    "health": (int,),
    "tribes": (list,),
    "text": (str,),
    "golden_text": (str,),
    "mechanics": (list,),
    "keywords": (list,),
    "row_hint": (str, None),
    "pool": (bool,),
    "priority": (int, None),
    "skeleton": (bool,),
    "source": (dict,),
}


def type_ok(value: object, allowed: tuple[type | None, ...]) -> bool:
    if value is None:
        return None in allowed
    if isinstance(value, bool) and bool not in allowed:
        return False
    return any(t is not None and isinstance(value, t) for t in allowed)


def check_param(kind: str, value: object) -> str | None:
    if kind in {"number", "threshold"}:
        ok = isinstance(value, int) and not isinstance(value, bool) and value >= 1
        return None if ok else "must be an integer of at least 1"
    if kind == "bool":
        return None if isinstance(value, bool) else "must be true or false"
    if kind == "tribe":
        return None if value in TRIBES else f"unknown tribe {value!r}"
    if kind == "action":
        return None if value in FAST_ACTIONS else f"must be one of {sorted(FAST_ACTIONS)}"
    if kind == "unit":
        return None if isinstance(value, str) and value else "must be a unit id"
    return f"unknown parameter kind {kind}"


def check_unit(path: Path, unit: object) -> list[str]:
    if not isinstance(unit, dict):
        return [f"{path.name}: top level must be an object"]
    problems: list[str] = []
    for field, allowed in FIELDS.items():
        if field not in unit:
            problems.append(f"{path.name}: missing field '{field}'")
        elif not type_ok(unit[field], allowed):
            problems.append(f"{path.name}: field '{field}' has the wrong type")
    for field in unit:
        if field not in FIELDS:
            problems.append(f"{path.name}: unknown field '{field}'")
    if problems:
        return problems
    if unit["id"] != path.stem:
        problems.append(f"{path.name}: id '{unit['id']}' must match the file name")
    if not 1 <= unit["tier"] <= 6:
        problems.append(f"{path.name}: tier {unit['tier']} is outside 1-6")
    if unit["attack"] < 0 or unit["health"] < 1:
        problems.append(f"{path.name}: attack must be >= 0 and health >= 1")
    problems += [f"{path.name}: unknown tribe {t!r}" for t in unit["tribes"] if t not in TRIBES]
    if unit["row_hint"] not in ROW_HINTS:
        problems.append(f"{path.name}: row_hint must be front, back or null")
    if unit["source"].get("kind") not in SOURCE_KINDS:
        problems.append(f"{path.name}: source.kind must be one of {sorted(SOURCE_KINDS)}")
    if unit["source"].get("kind") == "library" and not isinstance(unit["source"].get("entry"), int):
        problems.append(f"{path.name}: a library unit needs source.entry (the library entry number)")
    for mech in unit["mechanics"]:
        problems += [f"{path.name}: {p}" for p in check_mechanic(mech)]
    return problems


def check_mechanic(mech: object) -> list[str]:
    if not isinstance(mech, dict) or "id" not in mech:
        return ["each mechanic must be an object with an 'id'"]
    params = MECHANICS.get(mech["id"])
    if params is None:
        return [f"unknown mechanic id {mech['id']!r}"]
    problems: list[str] = []
    given = {k for k in mech if k != "id"}
    problems += [f"mechanic {mech['id']}: missing parameter '{p}'" for p in sorted(set(params) - given)]
    problems += [f"mechanic {mech['id']}: unknown parameter '{p}'" for p in sorted(given - set(params))]
    for name, kind in params.items():
        if name in mech and (error := check_param(kind, mech[name])):
            problems.append(f"mechanic {mech['id']}: '{name}' {error}")
    return problems


def main(argv: list[str]) -> int:
    units_dir = Path(argv[1]) if len(argv) > 1 else UNITS_DIR
    files = sorted(units_dir.glob("*.json"))
    if not files:
        print(f"check_units: no unit files in {units_dir}")
        return 1
    problems: list[str] = []
    units: dict[str, dict] = {}
    for path in files:
        try:
            unit = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            problems.append(f"{path.name}: invalid JSON ({error})")
            continue
        found = check_unit(path, unit)
        problems += found
        if not found:
            units[unit["id"]] = unit
    for unit in units.values():
        for mech in unit["mechanics"]:
            if mech["id"] == "death_summon" and mech["unit"] not in units:
                problems.append(f"{unit['id']}.json: death_summon names unknown unit {mech['unit']!r}")
    for line in problems:
        print(line)
    pool = [u for u in units.values() if u["pool"]]
    by_tier = [sum(1 for u in pool if u["tier"] == t) for t in range(1, 7)]
    print(f"check_units: {len(files)} files, {len(pool)} pool units by tier {by_tier}, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
