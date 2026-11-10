#!/usr/bin/env python3
"""Build persistent strong-field trajectories from all-line lobby fight captures.

python3 tools/sim/field_library.py build/sim/lines.fights.jsonl \\
    --source-commit HEAD --per-line 64 --strength top4 --out content/fields/baseline.json.gz

Companion <prefix>.players.csv files supply the seat's hero identity.
Use --strength top4 for a winners-only future shipped library; the default all
keeps lower finishers for analysis and the runtime strength dial. Content and
line profiles are read from the explicitly named source commit, never inferred
from the current checkout. Captures must have been produced on that source.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import itertools
import json
import random
import subprocess
from collections import defaultdict
from pathlib import Path

VERSION = 2
CONFIG_VERSION = 1
SEAT_KEYS = frozenset(("bots", "human_bot", "opponents", "field_library", "field_strength"))
SIDE_KEYS = ("board", "slots", "hero_effects", "fight_rules", "tier")
CAPTURE_SUITES = ("lines", "a35_run1")
CONTENT_FOLDERS = ("units", "spells", "heroes", "levers", "schema", "pass3")
DISPLAY_KEYS = frozenset(
    (
        "text",
        "golden_text",
        "details",
        "golden_details",
        "overlay_text",
        "mechanic_text",
        "text_rules",
        "source",
        "_comment",
    )
)


def gameplay(value, *, root=True, schema=False):
    """Strip presentation metadata; nested mechanic names remain gameplay counter IDs."""
    if isinstance(value, list):
        return [gameplay(item, root=False) for item in value]
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            if key in DISPLAY_KEYS or "portrait" in key.lower():
                continue
            if root and (key == "name" or (schema and key == "keywords")):
                continue
            result[key] = gameplay(item, root=False)
        return result
    if isinstance(value, float):
        # Godot's default JSON.stringify uses 15 significant digits for nonintegral
        # numbers. Match runtime gameplay hashes, including thirds in current rates.
        value = float(format(value, ".15g"))
        return int(value) if value.is_integer() else value
    return value


def gameplay_hash(value, *, schema=False):
    return hashlib.sha256(canonical(gameplay(value, schema=schema)).encode()).hexdigest()


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
        if path.suffix != ".json" or path.parent.as_posix() not in {f"content/{folder}" for folder in CONTENT_FOLDERS}:
            continue
        raw = git_output("show", f"{revision}:{name}", cwd=cwd)
        hashes[name] = gameplay_hash(json.loads(raw), schema=path.parent.name == "schema")
        if path.parent.as_posix() == "content/heroes":
            hero = json.loads(raw)
            heroes[hero["id"]] = hero["name"]
    if not hashes or not heroes:
        raise ValueError("source commit needs units, spells and heroes")
    return revision, hashes, heroes, source_profiles(revision, cwd=cwd)


def source_profiles(revision, *, cwd=None):
    profiles = json.loads(git_output("show", f"{revision}:tools/sim/line_profiles.committed.json", cwd=cwd))
    paths = git_output("ls-tree", "-r", "--name-only", revision, "tools/sim/lines", cwd=cwd).decode().splitlines()
    tribe_names = {entry["tribe"].lower().split(" ")[0]: entry["tribe"] for entry in profiles.values()}
    for path in sorted(paths):
        if not path.endswith(".json"):
            continue
        table = json.loads(git_output("show", f"{revision}:{path}", cwd=cwd))
        tribes = {entry["tribe"].lower().split(" ")[0] for entry in table.values()}
        profiles = {key: entry for key, entry in profiles.items() if entry["tribe"].lower().split(" ")[0] not in tribes}
        profiles.update(
            {
                key if key.startswith("line_") else "line_" + key: {
                    **entry,
                    "tribe": tribe_names.get(entry["tribe"].lower().split(" ")[0], entry["tribe"]),
                }
                for key, entry in table.items()
            }
        )
    return profiles


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


def load_seats(paths):
    result = {}
    for path in paths:
        with path.open(newline="") as stream:
            for row in csv.DictReader(stream):
                if row["suite"] not in CAPTURE_SUITES:
                    raise ValueError(f"{path}: only all-line lobby seats are supported")
                key = (int(row["seed"]), int(row.get("leg", "0") or "0"), int(row["seat"]))
                if key in result:
                    raise ValueError(f"duplicate seat hero: {key}")
                if not row["hero"]:
                    raise ValueError(f"seat hero missing: {key}")
                place = int(row["place"])
                if not 1 <= place <= 8:
                    raise ValueError(f"invalid source placement: {key}")
                raw_tribes = row["lobby_tribes"]
                tribes = sorted(set(raw_tribes.split("+"))) if raw_tribes else []
                if any(not value.strip() for value in tribes):
                    raise ValueError(f"invalid source lobby tribes: {key}")
                result[key] = {"hero": row["hero"], "finish_place": place, "lobby_tribes": tribes}
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


def read_trajectories(captures, source_seats, hero_names):
    trajectories, config = {}, None
    seen_fights = set()
    for path in sorted(captures):
        with path.open() as stream:
            for raw in stream:
                record = json.loads(raw)
                if record.get("suite") not in CAPTURE_SUITES:
                    raise ValueError("only all-line lobby captures (lines/a35_run1) are supported")
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
                    policy = snapshot.get("policy")
                    # Ordinary Hard keeps its aggregate label; committed lines retain their
                    # initial identity even when native play pivots (for example Birds tempo).
                    line = "hard" if policy == "hard" else snapshot.get("starting_line", policy)
                    if not isinstance(line, str) or not line:
                        raise ValueError(f"seat policy missing: {key}")
                    metadata = source_seats.get(key, {})
                    hero = metadata.get("hero")
                    if hero not in hero_names:
                        raise ValueError(f"seat hero missing or unknown in source content: {key}")
                    if key not in trajectories:
                        identity = ":".join(map(str, key))
                        trajectories[key] = {
                            "id": identity,
                            "hero": hero,
                            "name": f"{hero_names[hero]} ({identity})",
                            "line": line,
                            "finish_place": metadata["finish_place"],
                            "lobby_tribes": metadata["lobby_tribes"],
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


def build_library(captures, players, source, *, per_line=64, seed=91407, strength="all"):
    if per_line < 1:
        raise ValueError("per-line must be positive")
    if strength not in ("all", "top4"):
        raise ValueError("strength must be all or top4")
    revision, content_hashes, hero_names, profiles = source
    config, trajectories = read_trajectories(captures, load_seats(players), hero_names)
    # Sample independently per lobby rotation and strength stratum. A global per-line cap can
    # erase an entire rotation's winners and make an otherwise valid lobby impossible to deal.
    groups = defaultdict(list)
    for original in trajectories:
        if strength == "top4" and original["finish_place"] > 4:
            continue
        trajectory = dict(original)
        line = trajectory.pop("line")
        if line != "hard" and line not in profiles:
            raise ValueError(f"unknown source line policy: {line}")
        key = (line, tuple(trajectory["lobby_tribes"]), trajectory["finish_place"] <= 4)
        groups[key].append(trajectory)
    if not groups:
        raise ValueError(f"captures contain no trajectories eligible for strength={strength}")
    chosen, population = defaultdict(list), defaultdict(int)
    all_by_rotation = defaultdict(list)
    for (line, rotation, top4), candidates in sorted(groups.items()):
        population[line] += len(candidates)
        candidates.sort(key=lambda value: (-len(value["rounds"]), value["id"]))
        selected = candidates[:1]
        label = f"{seed}|{line}|{'+'.join(rotation)}|{top4}"
        generator = random.Random(int.from_bytes(hashlib.sha256(label.encode()).digest()))
        selected.extend(generator.sample(candidates[1:], min(per_line - 1, len(candidates) - 1)))
        chosen[line].extend(selected)
        all_by_rotation[rotation].extend((line, item) for item in candidates)
    # Preserve eight winners per source rotation when the captures have them, even under a
    # smaller requested per-line sample. Seven rivals plus the independent ghost need eight.
    selected_ids = {item["id"] for values in chosen.values() for item in values}
    for _rotation, candidates in sorted(all_by_rotation.items()):
        winners = [(line, item) for line, item in candidates if item["finish_place"] <= 4]
        winners.sort(key=lambda pair: (-len(pair[1]["rounds"]), pair[1]["id"]))
        present = sum(item["id"] in selected_ids for _, item in winners)
        for line, item in winners:
            if present >= 8:
                break
            if item["id"] not in selected_ids:
                chosen[line].append(item)
                selected_ids.add(item["id"])
                present += 1
    lines = {}
    coverage = defaultdict(lambda: {"all": 0, "top4": 0})
    for line, selected in sorted(chosen.items()):
        selected.sort(key=lambda value: value["id"])
        lines[line] = {"tribe": profiles.get(line, {}).get("tribe", ""), "trajectories": selected}
        for item in selected:
            counts = coverage["+".join(item["lobby_tribes"])]
            counts["all"] += 1
            counts["top4"] += item["finish_place"] <= 4
    return {
        "version": VERSION,
        "config_version": CONFIG_VERSION,
        "content_hashes": content_hashes,
        "manifest": "gameplay-v1",
        "source": {
            "commit": revision,
            "captures": [{"path": str(path), "sha256": sha256(path)} for path in sorted(captures)],
            "players": [{"path": str(path), "sha256": sha256(path)} for path in sorted(players)],
            "seed": seed,
            "strength_filter": strength,
            "per_line_per_rotation_stratum": per_line,
            "population_trajectories": dict(sorted(population.items())),
            "coverage": dict(sorted(coverage.items())),
            "sampling": (
                "per line/lobby rotation/top4 stratum: one longest plus seeded uniform whole "
                "trajectories without replacement; retain at least eight winners where available"
            ),
            "suite": "lines",
        },
        "config": config,
        "lines": lines,
    }


def write_library(path, data):
    """Use deterministic standard gzip for .gz; retain JSON for diagnostic fixtures."""
    raw = (canonical(data) + "\n").encode()
    encoded = gzip.compress(raw, mtime=0) if path.suffix == ".gz" else raw
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded)
    return len(raw), len(encoded)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", nargs="+", type=Path)
    parser.add_argument("--players", action="append", type=Path, help="companion CSV; repeat for shards")
    parser.add_argument("--source-commit", required=True, help="commit on which captures were generated")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument(
        "--per-line", type=int, default=64, help="sample cap per line, source lobby rotation and top4/all-other stratum"
    )
    parser.add_argument(
        "--minimum-top4",
        type=int,
        default=8,
        help="refuse source rotations without enough distinct top4 seats (0 disables)",
    )
    parser.add_argument("--seed", type=int, default=91407)
    parser.add_argument(
        "--strength",
        choices=("all", "top4"),
        default="all",
        help="source trajectory filter before sampling; use top4 for future shipped libraries",
    )
    args = parser.parse_args()
    try:
        source = source_data(args.source_commit)
        result = build_library(
            args.captures,
            player_files(args.captures, args.players),
            source,
            per_line=args.per_line,
            seed=args.seed,
            strength=args.strength,
        )
        rotation_tribes = sorted({entry["tribe"] for entry in source[3].values() if entry["tribe"]})
        wanted = result["config"].get("tribes_per_lobby", 0)
        expected = (
            [""]
            if wanted == 0
            else [
                "+".join(tribes)
                for tribes in itertools.combinations(rotation_tribes, min(wanted, len(rotation_tribes)))
            ]
        )
        for rotation in expected:
            count = result["source"]["coverage"].get(rotation, {}).get("top4", 0)
            if count < args.minimum_top4:
                raise ValueError(f"source lobby {rotation!r} has only {count} top4 trajectories; capture more lobbies")
        raw_bytes, stored_bytes = write_library(args.out, result)
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        parser.error(str(error))
    count = sum(len(entry["trajectories"]) for entry in result["lines"].values())
    print(
        f"field_library: {len(result['lines'])} lines, {count} trajectories, "
        f"{raw_bytes} JSON bytes, {stored_bytes} stored bytes -> {args.out}"
    )


if __name__ == "__main__":
    main()
