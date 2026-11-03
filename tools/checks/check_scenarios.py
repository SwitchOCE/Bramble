#!/usr/bin/env python3
"""Validates the sandbox scenario files in content/scenarios/ (SPEC section 7, ScenarioLibrary).

Checks every *.json file: id matches the file name, title/watch/note are text, entry is a library
entry number, units and boards name units that exist in content/units, slots are F1-F4/B1-B3, unit
entries have only known keys with sane values, both boards hold a unit, seed/tiers/expect are well
formed. The Godot loader checks the same things; this runs without Godot in the content step.

Usage: python3 tools/checks/check_scenarios.py [scenarios dir] [units dir]. Exit 0 = valid.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

SCENARIOS_DIR = Path("content/scenarios")
UNITS_DIR = Path("content/units")
SLOTS = {"F1", "F2", "F3", "F4", "B1", "B2", "B3"}
UNIT_KEYS = {"def_id", "attack", "health", "golden", "display_name"}
TOP_KEYS = {"id", "title", "entry", "units", "watch", "note", "seed", "tiers", "boards", "expect"}


def is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def check_unit(where: str, unit: object, unit_ids: set[str]) -> list[str]:
    if not isinstance(unit, dict):
        return [f"{where}: must be a unit object"]
    problems = [f"{where}: unknown key {key}" for key in unit if key not in UNIT_KEYS]
    if unit.get("def_id") not in unit_ids:
        problems.append(f"{where}: unknown unit {unit.get('def_id')}")
    if "attack" in unit and not (is_int(unit["attack"]) and unit["attack"] >= 0):
        problems.append(f"{where}: attack must be an integer >= 0")
    if "health" in unit and not (is_int(unit["health"]) and unit["health"] >= 1):
        problems.append(f"{where}: health must be an integer >= 1")
    if "golden" in unit and not isinstance(unit["golden"], bool):
        problems.append(f"{where}: golden must be true or false")
    if "display_name" in unit and not (isinstance(unit["display_name"], str) and unit["display_name"]):
        problems.append(f"{where}: display_name must be text")
    return problems


def check_scenario(path: Path, data: object, unit_ids: set[str]) -> list[str]:
    if not isinstance(data, dict):
        return [f"{path}: not a JSON object"]
    problems = [f"{path}: unknown key {key}" for key in data if key not in TOP_KEYS]
    if data.get("id") != path.stem:
        problems.append(f"{path}: id doesn't match the file name")
    for key in ("title", "watch"):
        if not (isinstance(data.get(key), str) and data[key]):
            problems.append(f"{path}: {key} must be text")
    if "note" in data and not isinstance(data["note"], str):
        problems.append(f"{path}: note must be text")
    if not (is_int(data.get("entry")) and data["entry"] >= 1):
        problems.append(f"{path}: entry must be a library entry number")
    units = data.get("units")
    if not (isinstance(units, list) and units and all(unit in unit_ids for unit in units)):
        problems.append(f"{path}: units must list existing unit ids")
    if "seed" in data and not is_int(data["seed"]):
        problems.append(f"{path}: seed must be an integer")
    tiers = data.get("tiers", [1, 1])
    if not (isinstance(tiers, list) and len(tiers) == 2 and all(is_int(t) and 1 <= t <= 6 for t in tiers)):
        problems.append(f"{path}: tiers must be two tiers 1-6")
    expect = data.get("expect", [])
    if not (isinstance(expect, list) and all(isinstance(e, dict) and "type" in e for e in expect)):
        problems.append(f"{path}: expect must be a list of event objects with a type")
    boards = data.get("boards")
    if not isinstance(boards, dict) or set(boards) != {"mine", "theirs"}:
        return [*problems, f"{path}: boards must be {{mine, theirs}}"]
    for side, board in boards.items():
        if not (isinstance(board, dict) and board):
            problems.append(f"{path}: boards.{side} must hold at least one unit")
            continue
        for slot, unit in board.items():
            if slot not in SLOTS:
                problems.append(f"{path}: boards.{side}: unknown slot {slot}")
            problems.extend(check_unit(f"{path}: boards.{side}.{slot}", unit, unit_ids))
    return problems


def main(argv: list[str]) -> int:
    scenarios_dir = Path(argv[1]) if len(argv) > 1 else SCENARIOS_DIR
    units_dir = Path(argv[2]) if len(argv) > 2 else UNITS_DIR
    unit_ids = {path.stem for path in units_dir.glob("*.json")}
    files = sorted(scenarios_dir.glob("*.json"))
    problems: list[str] = []
    for path in files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            problems.append(f"{path}: JSON error: {error}")
            continue
        problems.extend(check_scenario(path, data, unit_ids))
    for problem in problems:
        print(problem)
    print(f"check_scenarios: {len(files)} files, {len(problems)} problem(s)")
    return 1 if problems or not files else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
