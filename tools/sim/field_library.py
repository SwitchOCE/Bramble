#!/usr/bin/env python3
"""Build persistent strong-field trajectories from all-line lobby fight captures.

python3 tools/sim/field_library.py build/sim/lines.fights.jsonl \\
    --source-commit HEAD --per-line 4 --out content/fields/baseline.json

Companion <prefix>.players.csv files supply the seat's hero identity. Content and
line profiles are read from the explicitly named source commit, never inferred
from the current checkout. Captures must have been produced on that source.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import random
import subprocess
from collections import defaultdict
from pathlib import Path

VERSION = 1
CONFIG_VERSION = 1
SEAT_KEYS = frozenset(("bots", "human_bot", "opponents", "field_library"))
SIDE_KEYS = ("board", "slots", "hero_effects", "fight_rules", "tier")


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git_output(*arguments, cwd=None):
    return subprocess.check_output(["git", *arguments], cwd=cwd)


def source_data(commit, *, cwd=None):
    revision = git_output("rev-parse", "--verify", f"{commit}^{{commit}}", cwd=cwd).decode().strip()
    files = git_output("ls-tree", "-r", "--name-only", revision, "content", cwd=cwd).decode().splitlines()
    hashes, heroes = {}, {}
    for name in files:
        path = Path(name)
        if path.suffix != ".json" or path.parent.as_posix() not in (
            "content/units",
            "content/spells",
            "content/heroes",
            "content/levers",
            "content/schema",
        ):
            continue
        raw = git_output("show", f"{revision}:{name}", cwd=cwd)
        hashes[name] = hashlib.sha256(raw).hexdigest()
        if path.parent.as_posix() == "content/heroes":
            hero = json.loads(raw)
            heroes[hero["id"]] = hero["name"]
    if not hashes or not heroes:
        raise ValueError("source commit needs units, spells and heroes")
    profiles = json.loads(git_output("show", f"{revision}:tools/sim/line_profiles.committed.json", cwd=cwd))
    return revision, hashes, heroes, profiles


def player_files(captures, explicit=None):
    if explicit:
        return sorted(set(explicit))
    result = []
    for capture in captures:
        suffix = ".fights.jsonl"
        if not capture.name.endswith(suffix):
            raise ValueError("capture names must end in .fights.jsonl, or provide --players")
        result.append(capture.with_name(capture.name[: -len(suffix)] + ".players.csv"))
    return sorted(set(result))


def load_heroes(paths):
    result = {}
    for path in paths:
        with path.open(newline="") as stream:
            for row in csv.DictReader(stream):
                if row["suite"] != "lines":
                    raise ValueError(f"{path}: only suite=lines seats are supported")
                key = (int(row["seed"]), int(row.get("leg", "0") or "0"), int(row["seat"]))
                if key in result:
                    raise ValueError(f"duplicate seat hero: {key}")
                if not row["hero"]:
                    raise ValueError(f"seat hero missing: {key}")
                result[key] = row["hero"]
    return result


def _gameplay_config(config):
    return {key: value for key, value in config.items() if key not in SEAT_KEYS}


def _side(fight, side):
    return {
        "board": fight["boards"][side],
        "slots": fight["slots"][side],
        "hero_effects": fight["hero_effects"][side],
        "fight_rules": fight["fight_rules"][side],
        "tier": fight["tiers"][side],
    }


def read_trajectories(captures, seat_heroes, hero_names):
    trajectories, config = {}, None
    seen_fights = set()
    for path in sorted(captures):
        with path.open() as stream:
            for raw in stream:
                record = json.loads(raw)
                if record.get("suite") != "lines":
                    raise ValueError("only all-line lobby captures (suite=lines) are supported")
                if record.get("test_cards"):
                    raise ValueError("synthetic test cards cannot enter a playable field library")
                fight = record["input"]
                if fight.get("version") != 1:
                    raise ValueError("unsupported fight capture version")
                if config is None:
                    config = fight["config"]
                elif _gameplay_config(config) != _gameplay_config(fight["config"]):
                    raise ValueError("captures have mixed gameplay configs")
                game = (int(record["seed"]), int(record["leg"]))
                number = int(fight["round"])
                if number <= 0:
                    raise ValueError("rounds must be positive")
                fight_key = (*game, number, *map(int, fight["player_ids"]))
                if fight_key in seen_fights:
                    raise ValueError(f"duplicate fight: {fight_key}")
                seen_fights.add(fight_key)
                for side, seat in enumerate(fight["player_ids"]):
                    seat = int(seat)
                    if seat < 0:
                        continue
                    key = (*game, seat)
                    snapshot = record["combat_start"][side]
                    if snapshot.get("layout") != "blind":
                        raise ValueError("field inputs need blind final layouts")
                    line = snapshot.get("policy")
                    if not isinstance(line, str) or not line:
                        raise ValueError(f"seat policy missing: {key}")
                    hero = seat_heroes.get(key)
                    if hero not in hero_names:
                        raise ValueError(f"seat hero missing or unknown in source content: {key}")
                    if key not in trajectories:
                        identity = ":".join(map(str, key))
                        trajectories[key] = {
                            "id": identity,
                            "hero": hero,
                            "name": f"{hero_names[hero]} ({identity})",
                            "line": line,
                            "rounds": {},
                        }
                    trajectory = trajectories[key]
                    if trajectory["line"] != line:
                        raise ValueError(f"seat changes line within a trajectory: {key}")
                    if str(number) in trajectory["rounds"]:
                        raise ValueError(f"duplicate board: {(*key, number)}")
                    value = _side(fight, side)
                    value["views"] = [None] * 7
                    for unit in snapshot.get("units", []):
                        if unit.get("active"):
                            value["views"][int(unit["slot"])] = unit
                    if len(value["board"]) != 7 or len(value["slots"]) != 7:
                        raise ValueError("boards and slots must contain seven explicit positions")
                    trajectory["rounds"][str(number)] = value
    if not trajectories:
        raise ValueError("captures contain no seat trajectories")
    for key, trajectory in trajectories.items():
        numbers = sorted(map(int, trajectory["rounds"]))
        if numbers != list(range(1, numbers[-1] + 1)):
            raise ValueError(f"incomplete/noncontiguous trajectory: {key}")
    return config, trajectories.values()


def build_library(captures, players, source, *, per_line=4, seed=91407):
    if per_line < 1:
        raise ValueError("per-line must be positive")
    revision, content_hashes, hero_names, profiles = source
    config, trajectories = read_trajectories(captures, load_heroes(players), hero_names)
    groups = defaultdict(list)
    for original in trajectories:
        trajectory = dict(original)
        line = trajectory.pop("line")
        if line != "hard" and line not in profiles:
            raise ValueError(f"unknown source line policy: {line}")
        groups[line].append(trajectory)
    lines = {}
    population = {}
    for line, candidates in sorted(groups.items()):
        population[line] = len(candidates)
        # Keep a maximum-coverage trajectory even when subsampling aggressively.
        candidates.sort(key=lambda value: (-len(value["rounds"]), value["id"]))
        selected = candidates[:1]
        generator = random.Random(int.from_bytes(hashlib.sha256(f"{seed}|{line}".encode()).digest()))
        selected.extend(generator.sample(candidates[1:], min(per_line - 1, len(candidates) - 1)))
        selected.sort(key=lambda value: value["id"])
        lines[line] = {"tribe": profiles.get(line, {}).get("tribe", ""), "trajectories": selected}
    return {
        "version": VERSION,
        "config_version": CONFIG_VERSION,
        "content_hashes": content_hashes,
        "source": {
            "commit": revision,
            "captures": [{"path": str(path), "sha256": sha256(path)} for path in sorted(captures)],
            "players": [{"path": str(path), "sha256": sha256(path)} for path in sorted(players)],
            "seed": seed,
            "per_line": per_line,
            "population_trajectories": population,
            "sampling": "one longest per line plus seeded uniform whole trajectories without replacement",
            "suite": "lines",
        },
        "config": config,
        "lines": lines,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", nargs="+", type=Path)
    parser.add_argument("--players", action="append", type=Path, help="companion CSV; repeat for shards")
    parser.add_argument("--source-commit", required=True, help="commit on which captures were generated")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--per-line", type=int, default=4)
    parser.add_argument("--seed", type=int, default=91407)
    args = parser.parse_args()
    try:
        source = source_data(args.source_commit)
        result = build_library(
            args.captures,
            player_files(args.captures, args.players),
            source,
            per_line=args.per_line,
            seed=args.seed,
        )
        output = canonical(result) + "\n"
        if len(output.encode()) >= 10_000_000:
            raise ValueError("library exceeds 10 MB; lower --per-line or split the source population")
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(output)
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        parser.error(str(error))
    count = sum(len(entry["trajectories"]) for entry in result["lines"].values())
    print(
        f"field_library: {len(result['lines'])} lines, {count} trajectories, {len(output.encode())} bytes -> {args.out}"
    )


if __name__ == "__main__":
    main()
