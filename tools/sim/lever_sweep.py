#!/usr/bin/env python3
"""Run a frozen, sequential local lever sweep, stopping at bounded checkpoints.

The plan is data, never a tuning loop. ``fingerprint`` supplies the input hashes;
``prepare PLAN`` freezes a plan; ``run PLAN --max-seconds 2400`` resumes it. Run
the latter in a terminal/tmux if background execution is wanted. No daemon or
remote service is installed. Each invocation is limited to at most 45 minutes.
"""

from __future__ import annotations

import argparse
import csv
import fcntl
import hashlib
import json
import math
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time
from collections import Counter, defaultdict
from contextlib import suppress
from datetime import datetime, timezone
from itertools import groupby
from pathlib import Path

from check_lines import head_to_head, line_breakdown
from field import boards_from_capture, field_report, sample_field
from metrics import distribution, summarize
from replay_damage import replay_game

ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATHS = ["src", "content", "tools/sim/*.gd", "tools/sim/line_profiles.sweep.json"]
ROUNDS = [6, 8, 10, 12, 14, 16]
MAX_SECONDS = 45 * 60
GUARD_SECONDS = 15
CAPTURE_SUFFIXES = ("players.csv", "rounds.csv", "cards.csv", "turns.csv", "profile.csv", "fights.jsonl")


class SweepError(ValueError):
    """Invalid evidence or stale frozen inputs; do not continue automatically."""


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False).encode()


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def file_sha(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + f".tmp-{os.getpid()}")
    try:
        with temporary.open("w") as stream:
            json.dump(value, stream, indent=2, sort_keys=True, allow_nan=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def local_path(value, root=ROOT):
    path = (root / value).resolve()
    if not path.is_relative_to(root.resolve()):
        raise SweepError(f"path is outside the repository: {value}")
    return path


def source_manifest(root, patterns):
    """Hash matched names as well as bytes, so additions/deletions change the hash."""
    files = set()
    for pattern in patterns:
        if Path(pattern).is_absolute() or ".." in Path(pattern).parts:
            raise SweepError(f"invalid source path: {pattern}")
        matches = sorted(root.glob(pattern))
        if not matches:
            raise SweepError(f"source pattern matches nothing: {pattern}")
        for match in matches:
            candidates = match.rglob("*") if match.is_dir() else [match]
            for path in candidates:
                if path.is_file() and "__pycache__" not in path.parts:
                    if not path.resolve().is_relative_to(root.resolve()):
                        raise SweepError(f"source symlink escapes repository: {path}")
                    files.add(path)
    return {str(path.relative_to(root)): file_sha(path) for path in sorted(files)}


def git(root, *args):
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, check=False)
    if result.returncode:
        raise SweepError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout.strip()


def fingerprints(root=ROOT, patterns=None, profiles="tools/sim/line_profiles.sweep.json"):
    patterns = patterns or SOURCE_PATHS
    return {
        "source_commit": git(root, "rev-parse", "HEAD"),
        "source_paths": patterns,
        "source_fingerprint": digest(source_manifest(root, patterns)),
        "profiles": profiles,
        "profiles_sha256": file_sha(local_path(profiles, root)),
    }


def helper_manifest():
    return {path.name: file_sha(path) for path in sorted(Path(__file__).parent.glob("*.py"))}


def validate_plan(plan):
    if plan.get("version") != 1:
        raise SweepError("expected sweep plan version 1")
    for key in ("source_commit", "source_fingerprint", "source_paths", "profiles", "profiles_sha256"):
        if not plan.get(key):
            raise SweepError(f"missing frozen input: {key}")
    if not re.fullmatch(r"[0-9a-f]{40,64}", plan["source_commit"]):
        raise SweepError("source_commit must be a full commit hash")
    for key in ("source_fingerprint", "profiles_sha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", plan[key]):
            raise SweepError(f"{key} must be SHA-256")
    if not isinstance(plan["source_paths"], list) or any(not isinstance(value, str) for value in plan["source_paths"]):
        raise SweepError("source_paths must be a list of file/directory/glob strings")
    configs = plan.get("configs", [])
    if not configs:
        raise SweepError("the plan has no configurations")
    ids = set()
    for config in configs:
        name = config.get("id", "")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name) or name in ids:
            raise SweepError(f"invalid or duplicate configuration ID: {name}")
        ids.add(name)
        if config.get("lobbies") != 150:
            raise SweepError(f"{name}: fixed budget is 150 lobbies")
        if type(config.get("first_seed")) is not int or config["first_seed"] < 0:
            raise SweepError(f"{name}: first_seed must be a nonnegative integer")
        if config.get("field_size") not in (32, 64) or config.get("rounds") != ROUNDS or config.get("reps") != 8:
            raise SweepError(f"{name}: require field size 32/64, rounds {ROUNDS}, eight replicates per orientation")
        if not isinstance(config.get("overrides"), dict):
            raise SweepError(f"{name}: overrides must be a JSON object")
        if "plant_growth" in config["overrides"]:
            raise SweepError("synthetic planted units are outside this sweep")
        observed = config.get("observed_ids", config["overrides"].get("scale_levers", []))
        if not isinstance(observed, list) or any(not isinstance(value, str) for value in observed):
            raise SweepError(f"{name}: observed_ids must be content ID strings")
        comparison = config.get("head_to_head")
        if comparison:
            if comparison.get("independent_seeds") != 80 or comparison.get("chunk_seeds", 10) not in (10, 20):
                raise SweepError(f"{name}: head-to-head requires exactly 80 independent seeds in chunks of 10 or 20")
            if not comparison.get("candidate") or comparison.get("incumbent") != "hard_field":
                raise SweepError(f"{name}: require a predeclared candidate against hard_field")
            if type(comparison.get("first_seed")) is not int or comparison["first_seed"] < 0:
                raise SweepError(f"{name}: head-to-head first_seed must be a nonnegative integer")
        variants = config.get("damage_variants", {})
        if not isinstance(variants, dict) or "original" in variants:
            raise SweepError("damage_variants must map names to overrides, without replacing original")
        for variant in variants.values():
            if not isinstance(variant, dict) or variant.get("starting_health", 1) <= 0:
                raise SweepError("invalid offline damage variant")
        protected = bool(config["overrides"].get("scale_levers") or config["overrides"].get("scale_hero_spell_stats"))
        if protected and not config.get("requires_gate"):
            raise SweepError(f"{name}: lever/tribe reads require a predeclared positive build gate")
        gate = config.get("requires_gate")
        if gate and not (isinstance(gate, str) or (isinstance(gate, dict) and isinstance(gate.get("path"), str))):
            raise SweepError(f"{name}: requires_gate must be a path or {{path, key='passes', equals=true}}")
        if isinstance(gate, dict) and gate.get("equals", True) is not True:
            raise SweepError("build gates must require a true boolean")
    return plan


def stage_plan(plan):
    """The fixed budgets are expanded before execution, independently of outcomes."""
    stages = []
    for config in plan["configs"]:
        name = config["id"]
        for offset in range(0, config["lobbies"], 50):
            stages.append(
                {
                    "id": f"{name}/lobbies-{offset:03}",
                    "config": name,
                    "kind": "lobbies",
                    "first_seed": config["first_seed"] + offset,
                    "count": 50,
                    "estimate_seconds": 180,
                    "timeout_seconds": 420,
                }
            )
        stages.append(
            {"id": f"{name}/sample", "config": name, "kind": "sample", "estimate_seconds": 45, "timeout_seconds": 180}
        )
        fights = config["field_size"] * (config["field_size"] - 1) // 2 * 2 * config["reps"]
        estimate = math.ceil(fights * 0.0076 * 1.35 + 20)
        for number in config["rounds"]:
            stages.append(
                {
                    "id": f"{name}/field-r{number:02}",
                    "config": name,
                    "kind": "field",
                    "round": number,
                    "estimate_seconds": estimate,
                    "timeout_seconds": estimate * 2,
                }
            )
        comparison = config.get("head_to_head")
        if comparison:
            chunk = comparison.get("chunk_seeds", 10)
            for offset in range(0, 80, chunk):
                estimate = math.ceil(chunk * 2 * 8.5 * 1.25 + 20)
                stages.append(
                    {
                        "id": f"{name}/head-{offset:03}",
                        "config": name,
                        "kind": "head",
                        "first_seed": comparison["first_seed"] + offset,
                        "count": chunk,
                        "estimate_seconds": estimate,
                        "timeout_seconds": estimate * 2,
                    }
                )
        stages.append(
            {
                "id": f"{name}/analysis",
                "config": name,
                "kind": "analysis",
                "estimate_seconds": 180,
                "timeout_seconds": 600,
            }
        )
    return stages


def csv_rows(path):
    with Path(path).open(newline="") as stream:
        return list(csv.DictReader(stream))


def jsonl(path):
    with Path(path).open() as stream:
        for raw in stream:
            if not raw.strip():
                raise SweepError(f"blank/incomplete JSONL record in {path}")
            yield json.loads(raw)


def validate_players(path, first_seed, count, head=False, candidate=None, incumbent="hard"):
    rows = csv_rows(path)
    expected = {
        (seed, leg, seat)
        for seed in range(first_seed, first_seed + count)
        for leg in range(2 if head else 1)
        for seat in range(8)
    }
    keys = [(int(row["seed"]), int(row.get("leg", 0)), int(row["seat"])) for row in rows]
    if len(keys) != len(set(keys)) or set(keys) != expected:
        raise SweepError(f"duplicate, missing or unexpected player/seed/leg in {path}")
    for seed in range(first_seed, first_seed + count):
        for leg in range(2 if head else 1):
            places = sorted(
                int(row["place"]) for row in rows if int(row["seed"]) == seed and int(row.get("leg", 0)) == leg
            )
            if places != list(range(1, 9)):
                raise SweepError(f"incomplete placements for seed {seed}, leg {leg}")
    if head:
        return head_to_head(
            Path(path),
            {
                "candidate": candidate,
                "incumbent": incumbent,
                "independent_seeds": count,
                "seed_range": [first_seed, first_seed + count - 1],
            },
        )
    return rows


def validate_capture(path, first_seed, count, players_path=None, expected_overrides=None, expected_test_cards=None):
    rounds, fights, lobbies = defaultdict(list), set(), set()
    end_health = defaultdict(dict)
    for row in jsonl(path):
        seed, leg, number = int(row["seed"]), int(row["leg"]), int(row["round"])
        if not first_seed <= seed < first_seed + count or leg != 0:
            raise SweepError("unexpected seed/leg or synthetic card in capture")
        if row.get("test_cards", []) != (expected_test_cards or []):
            raise SweepError("synthetic cards differ from the explicit test-only definition allowlist")
        if expected_overrides is not None and any(
            row["input"]["config"].get(key) != value for key, value in expected_overrides.items()
        ):
            raise SweepError("captured game configuration differs from frozen overrides")
        seats = [int(value) for value in row["players"]]
        identity = (seed, leg, number, tuple(sorted(seats)))
        if identity in fights:
            raise SweepError("duplicate fight capture")
        fights.add(identity)
        rounds[seed, number].append((seats, int(row["alive_before"])))
        for side, seat in enumerate(seats):
            if seat >= 0:
                end_health[seed, number][seat] = row["health_after"][side]
        lobbies.add(seed)
    if lobbies != set(range(first_seed, first_seed + count)):
        raise SweepError("missing lobby capture")
    for (seed, number), values in rounds.items():
        seats = [seat for pair, _ in values for seat in pair if seat >= 0]
        if len(seats) != len(set(seats)) or any(alive != len(seats) for _, alive in values):
            raise SweepError(f"incomplete or duplicate fight round at seed {seed}, round {number}")
    for seed in lobbies:
        numbers = sorted(number for game_seed, number in rounds if game_seed == seed)
        if numbers != list(range(1, max(numbers) + 1)) or sum(len(pair) for pair, _ in rounds[seed, 1]) != 8:
            raise SweepError(f"incomplete initial/intermediate rounds at seed {seed}")
        if sum(health > 0 for health in end_health[seed, max(numbers)].values()) > 1:
            raise SweepError(f"capture ends before the lobby resolves at seed {seed}")
    if players_path is not None:
        winners = {int(row["seed"]): int(row["rounds"]) for row in csv_rows(players_path) if int(row["place"]) == 1}
        if any(
            max(number for game_seed, number in rounds if game_seed == seed) != winners.get(seed) for seed in lobbies
        ):
            raise SweepError("capture final rounds differ from completed player output")


def combine_csv(paths, output):
    header = None
    with output.open("w", newline="") as stream:
        for path in paths:
            with path.open(newline="") as source:
                reader = csv.reader(source)
                columns = next(reader)
                if header is None:
                    header = columns
                    writer = csv.writer(stream)
                    writer.writerow(header)
                if columns != header:
                    raise SweepError("CSV shard headers differ")
                writer.writerows(reader)


def adoption_report(captures, cards, observed_ids):
    """Observed owned bodies are exposure, not a reconstruction of shop offers."""
    result = {
        name: {
            "active_board_rounds": 0,
            "owned_board_rounds": 0,
            "active_copies": 0,
            "owned_copies": 0,
            "final_card_rows": 0,
            "legacy_unknown_origin_copy_observations": 0,
            "retention_same_iid_next_own_round": {"eligible": 0, "retained": 0, "censored": 0, "rate": None},
        }
        for name in observed_ids
    }
    seats, lobbies = defaultdict(set), defaultdict(set)
    active_seats, active_lobbies = defaultdict(set), defaultdict(set)
    board_counts = Counter()
    total_boards, all_seats, all_lobbies = 0, set(), set()
    acquired = defaultdict(dict)
    previous = {}
    inventory_boards = 0

    def censor(inventory):
        for unit in inventory.values():
            if unit["def_id"] in result:
                result[unit["def_id"]]["retention_same_iid_next_own_round"]["censored"] += 1

    for board in boards_from_capture(captures):
        total_boards += 1
        seat = (board["seed"], board["leg"], board["seat"])
        lobby = seat[:2]
        all_seats.add(seat)
        all_lobbies.add(lobby)
        snapshot = board["combat_start"]
        # Combat views are presentation records. Slots identify active bodies;
        # recruit inventory is authoritative for ownership, IID and origin.
        active_views = {}
        for index, unit in enumerate(snapshot["units"]):
            if unit["active"]:
                identity = ("slot", unit["slot"]) if "slot" in unit else ("view", index)
                active_views[identity] = unit
        active = Counter(unit["def_id"] for unit in active_views.values())
        inventory = None
        if "recruit_units" in snapshot:
            inventory_boards += 1
            inventory = {}
            for unit in snapshot["recruit_units"]:
                iid = unit.get("iid")
                if type(iid) not in (int, str) or iid == "":
                    raise SweepError("recruit inventory is missing an IID")
                if iid in inventory and any(inventory[iid].get(key) != unit.get(key) for key in ("def_id", "origin")):
                    raise SweepError("conflicting duplicate recruit IID")
                inventory[iid] = unit
            owned = Counter(unit["def_id"] for unit in inventory.values())
            for iid, unit in inventory.items():
                name = unit["def_id"]
                if name in result:
                    identity = (*lobby, iid)
                    origin = unit.get("origin") or "unknown"
                    old_origin = acquired[name].get(identity)
                    if old_origin is not None and old_origin != origin:
                        raise SweepError("recruit origin changed for the same observed IID")
                    acquired[name][identity] = origin
        else:
            owned = Counter(unit["def_id"] for unit in snapshot["units"])
            for name in observed_ids:
                result[name]["legacy_unknown_origin_copy_observations"] += owned[name]
        old = previous.get(seat)
        if old is not None:
            old_round, old_inventory = old
            if inventory is None or board["round"] != old_round + 1:
                censor(old_inventory)
            else:
                for iid, unit in old_inventory.items():
                    if unit["def_id"] in result:
                        retention = result[unit["def_id"]]["retention_same_iid_next_own_round"]
                        retention["eligible"] += 1
                        retention["retained"] += iid in inventory
        if inventory is None:
            previous.pop(seat, None)
        else:
            previous[seat] = (board["round"], inventory)
        board_counts.update(active)
        for name in observed_ids:
            value = result[name]
            value["active_board_rounds"] += bool(active[name])
            value["owned_board_rounds"] += bool(owned[name])
            value["active_copies"] += active[name]
            value["owned_copies"] += owned[name]
            if owned[name]:
                seats[name].add(seat)
                lobbies[name].add(lobby)
            if active[name]:
                active_seats[name].add(seat)
                active_lobbies[name].add(lobby)
    for _, inventory in previous.values():
        censor(inventory)
    for path in cards:
        for row in csv_rows(path):
            if row["card"] in result:
                result[row["card"]]["final_card_rows"] += 1
    for name, value in result.items():
        origins = Counter(acquired[name].values())
        retention = value["retention_same_iid_next_own_round"]
        retention["rate"] = retention["retained"] / retention["eligible"] if retention["eligible"] else None
        value.update(
            owned_seats=len(seats[name]),
            owned_lobbies=len(lobbies[name]),
            active_seats=len(active_seats[name]),
            active_lobbies=len(active_lobbies[name]),
            active_board_round_share=value["active_board_rounds"] / total_boards if total_boards else None,
            observed_unused=value["owned_copies"] == 0 and value["final_card_rows"] == 0,
            acquired_unique_iids=len(acquired[name]) if inventory_boards else None,
            bought_unique=origins["bought"] if inventory_boards else None,
            created_unique=sum(count for origin, count in origins.items() if origin not in ("bought", "unknown"))
            if inventory_boards
            else None,
            unknown_origin_unique=origins["unknown"] if inventory_boards else None,
            unique_origin_counts=dict(origins),
        )
    return {
        "method": "Prefer recruit inventory for owned bodies and distinct observed IIDs; "
        "IIDs are namespaced by seed and leg. Origin=bought separates bought "
        "from created bodies. Legacy combat views have unknown origin and unavailable acquisition counts. "
        "Only captured acquisitions are observable; full roll offers are not logged, "
        "so no conditional buy rate is estimated.",
        "retention_method": "Same IID in the next consecutive own round's inventory, across any owned location; "
        "last observations, gaps and missing inventory are censored. "
        "This is body retention, including transformations.",
        "board_rounds": total_boards,
        "inventory_board_rounds": inventory_boards,
        "legacy_unknown_origin_board_rounds": total_boards - inventory_boards,
        "seats": len(all_seats),
        "lobbies": len(all_lobbies),
        "content_active_copy_counts": dict(board_counts),
        "levers": result,
    }


def damage_report(captures, players, variants):
    output = {
        "method": "Fixed historical fights and recruit deltas. Changed eliminations make later matchups, "
        "buys and pool evolution conditional. This cannot determine new pairings.",
        "variants": {},
    }
    seen = set()
    winners = {(int(row["seed"]), int(row.get("leg", 0))): row for row in players if int(row["place"]) == 1}
    for name in {"original": {}, **variants}:
        output["variants"][name] = {"games": {}, "summary": {}}
    for path in captures:
        for key, values in groupby(jsonl(path), key=lambda row: (int(row["seed"]), int(row["leg"]))):
            if key in seen:
                raise SweepError("duplicate or split lobby capture")
            seen.add(key)
            records = list(values)
            for name, variant in {"original": {}, **variants}.items():
                replay = replay_game(records, variant)
                if name == "original":
                    winner = winners[key]
                    if replay["winner"] != int(winner["seat"]) or replay["end_round"] != int(winner["rounds"]):
                        raise SweepError(f"original replay winner/length differs at {key}")
                output["variants"][name]["games"][f"{key[0]}:{key[1]}"] = replay
    for name, value in output["variants"].items():
        games = list(value["games"].values())
        covered = [game for game in games if game["end_round"] is not None and game["coverage_lost_round"] is None]
        faithful = [game for game in covered if game["first_elimination_divergence"] is None]
        value["summary"] = {
            "lobbies": len(games),
            "live_post_state_checks": sum(game["live_post_state_checks"] for game in games),
            "original_validated": name == "original",
            "elimination_divergence_games": sum(game["first_elimination_divergence"] is not None for game in games),
            "coverage_lost_games": sum(game["coverage_lost_round"] is not None for game in games),
            "unresolved_games": sum(bool(game["unresolved_survivors"]) for game in games),
            "first_divergence_round": distribution(
                [
                    game["first_elimination_divergence"]
                    for game in games
                    if game["first_elimination_divergence"] is not None
                ]
            ),
            "covered_resolved_end_round": distribution([game["end_round"] for game in covered]),
            "covered_resolved_14_16": sum(14 <= game["end_round"] <= 16 for game in covered),
            "unchanged_elimination_end_round": distribution([game["end_round"] for game in faithful]),
            "length_interpretation": (
                "Covered resolved ends only; ends after divergence remain conditional, not new-game lengths."
            ),
        }
    return output


def run_command(argv, log, timeout_seconds, cwd=ROOT):
    """Terminate only our own process group; wait/lock time is also bounded."""
    with log.open("w") as stream:
        process = subprocess.Popen(argv, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=timeout_seconds)
        except BaseException as error:
            with suppress(ProcessLookupError):
                os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            if isinstance(error, subprocess.TimeoutExpired):
                raise SweepError(f"stage timed out after {timeout_seconds}s; see {log}") from None
            raise
    if code:
        raise SweepError(f"stage command exited {code}; see {log}")
    problem = re.search(r"SCRIPT ERROR:|Parse Error:|(?:^|\n)ERROR:", log.read_text(errors="replace"))
    if problem:
        raise SweepError(f"stage logged a Godot error despite exit zero; see {log}")


def godot_command(script, arguments, timeout_seconds, root=ROOT):
    command = [
        "flock",
        "-w",
        str(timeout_seconds),
        "/tmp/bramble-godot.lock",
        "systemd-run",
        "--user",
        "--scope",
        "-p",
        "MemoryMax=3G",
        "timeout",
        "--signal=TERM",
        "--kill-after=5s",
        f"{timeout_seconds}s",
        "godot",
        "--headless",
        "--path",
        str(root),
        "-s",
        f"res://tools/sim/{script}",
        "--",
        *arguments,
    ]
    return ["bash", "-c", ". /opt/bramble/env.sh && exec " + shlex.join(command)]


class Sweep:
    def __init__(self, plan_path, root=ROOT):
        self.root = Path(root).resolve()
        self.plan_path = Path(plan_path).resolve()
        self.plan = validate_plan(json.loads(self.plan_path.read_text()))
        self.output = local_path(self.plan.get("output_root", "build/sim/lever-sweep"), self.root)
        self.report = local_path(self.plan.get("report", "docs/ideation/evidence/lever-sweep.md"), self.root)
        self.status_path = self.output / "status.json"
        self.lock_path = self.output / "plan.lock.json"
        self.stages = stage_plan(self.plan)
        self.configs = {config["id"]: config for config in self.plan["configs"]}
        self.status = None

    def verify_inputs(self):
        plan = self.plan
        if digest(json.loads(self.plan_path.read_text())) != digest(plan):
            raise SweepError("plan changed during this invocation")
        if file_sha(local_path(plan["profiles"], self.root)) != plan["profiles_sha256"]:
            raise SweepError("profile table differs from the frozen plan")
        manifest = source_manifest(self.root, plan["source_paths"])
        if digest(manifest) != plan["source_fingerprint"]:
            raise SweepError("source/content fingerprint differs from the frozen plan")
        if self.lock_path.exists():
            frozen = json.loads(self.lock_path.read_text())
            if frozen.get("plan_sha256") != digest(plan):
                raise SweepError("plan changed since prepare; use a new output_root")
            if (
                frozen.get("controller_sha256") != file_sha(Path(__file__))
                or frozen.get("analysis_helpers") != helper_manifest()
            ):
                raise SweepError("controller/analysis helpers changed since prepare; use a new output_root")
            profile = self.output / "inputs/profiles.json"
            if profile.exists() and file_sha(profile) != plan["profiles_sha256"]:
                raise SweepError("frozen override/profile copy changed")
            for config in plan["configs"]:
                override = self.output / "inputs" / f"{config['id']}.json"
                if override.exists() and override.read_bytes() != canonical(config["overrides"]) + b"\n":
                    raise SweepError("frozen override/profile copy changed")
        # Evidence-only checkpoint commits may advance HEAD. Runtime bytes must still match.
        git(self.root, "merge-base", "--is-ancestor", plan["source_commit"], "HEAD")
        return manifest

    def prepare(self):
        manifest = self.verify_inputs()
        frozen = {
            "version": 1,
            "plan_sha256": digest(self.plan),
            "plan": self.plan,
            "source_files": manifest,
            "controller_sha256": file_sha(Path(__file__)),
            "analysis_helpers": helper_manifest(),
        }
        self.output.mkdir(parents=True, exist_ok=True)
        if self.lock_path.exists():
            if json.loads(self.lock_path.read_text()) != frozen:
                raise SweepError("plan, controller or analysis helpers changed since prepare; use a new output_root")
            if not self.status_path.exists():
                raise SweepError("frozen plan exists but status checkpoint is missing")
            self.status = json.loads(self.status_path.read_text())
            if self.status.get("plan_sha256") != frozen["plan_sha256"]:
                raise SweepError("status belongs to a different plan")
        else:
            if self.status_path.exists():
                raise SweepError("status exists without a frozen plan")
            atomic_json(self.lock_path, frozen)
            self.status = {
                "version": 1,
                "plan_sha256": frozen["plan_sha256"],
                "created_at": utc_now(),
                "stages": {},
                "state": "prepared",
            }
            self.save()
        inputs = self.output / "inputs"
        inputs.mkdir(exist_ok=True)
        profile = inputs / "profiles.json"
        self.frozen_input(profile, local_path(self.plan["profiles"], self.root).read_bytes())
        for config in self.plan["configs"]:
            self.frozen_input(inputs / f"{config['id']}.json", canonical(config["overrides"]) + b"\n")
        return self.status

    @staticmethod
    def frozen_input(path, content):
        if path.exists():
            if path.read_bytes() != content:
                raise SweepError(f"frozen override/profile copy changed: {path}")
        else:
            path.write_bytes(content)

    def save(self):
        self.status["updated_at"] = utc_now()
        atomic_json(self.status_path, self.status)

    def completed(self, stage):
        checkpoint = self.status["stages"].get(stage["id"], {})
        if checkpoint.get("state") != "complete":
            return False
        for relative, checksum in checkpoint["outputs"].items():
            path = self.output / relative
            if not path.is_file() or file_sha(path) != checksum:
                raise SweepError(f"completed stage evidence changed: {path}")
        return True

    def stage_dir(self, stage_id):
        checkpoint = self.status["stages"].get(stage_id, {})
        if checkpoint.get("state") != "complete":
            raise SweepError(f"required stage is incomplete: {stage_id}")
        return self.output / checkpoint["directory"]

    def lobby_paths(self, config, suffix):
        return [
            self.stage_dir(f"{config['id']}/lobbies-{offset:03}") / f"bench.{suffix}"
            for offset in range(0, config["lobbies"], 50)
        ]

    def execute(self, stage, folder, timeout_seconds):
        config = self.configs[stage["config"]]
        kind, name = stage["kind"], config["id"]
        if kind in ("lobbies", "head"):
            prefix = folder / "bench"
            arguments = [
                f"suite={'lines' if kind == 'lobbies' else 'head_to_head'}",
                f"games={stage['count']}",
                f"first_seed={stage['first_seed']}",
                f"out={prefix}",
                f"lines={self.output / 'inputs/profiles.json'}",
                f"config={self.output / 'inputs' / (name + '.json')}",
                f"capture={'on' if kind == 'lobbies' else 'off'}",
            ]
            comparison = config.get("head_to_head", {})
            if kind == "head":
                arguments += [f"candidate={comparison['candidate']}", f"incumbent={comparison['incumbent']}"]
            run_command(
                godot_command("bench.gd", arguments, timeout_seconds, self.root),
                folder / "godot.log",
                timeout_seconds + 2,
                self.root,
            )
            validate_players(
                folder / "bench.players.csv",
                stage["first_seed"],
                stage["count"],
                kind == "head",
                comparison.get("candidate"),
                comparison.get("incumbent", "hard"),
            )
            for suffix in CAPTURE_SUFFIXES:
                if (suffix != "fights.jsonl" or kind == "lobbies") and not (folder / f"bench.{suffix}").is_file():
                    raise SweepError(f"missing bench output: {suffix}")
            if kind == "lobbies":
                validate_capture(
                    folder / "bench.fights.jsonl",
                    stage["first_seed"],
                    stage["count"],
                    folder / "bench.players.csv",
                    config["overrides"],
                )
        elif kind == "sample":
            captures = self.lobby_paths(config, "fights.jsonl")
            field = sample_field(
                boards_from_capture(captures),
                tuple(config["rounds"]),
                config["field_size"],
                config.get("field_seed", 91407),
            )
            field["sources"] = {str(path.relative_to(self.root)): file_sha(path) for path in captures}
            atomic_json(folder / "field.json", field)
            for number in config["rounds"]:
                one_round = {**field, "rounds": {str(number): field["rounds"][str(number)]}}
                atomic_json(folder / f"field-r{number:02}.json", one_round)
        elif kind == "field":
            source = self.stage_dir(f"{name}/sample") / f"field-r{stage['round']:02}.json"
            shutil.copyfile(source, folder / "field.json")
            pairs = folder / "pairs.jsonl"
            run_command(
                godot_command(
                    "field_fights.gd",
                    [str(folder / "field.json"), str(pairs), str(config["reps"])],
                    timeout_seconds,
                    self.root,
                ),
                folder / "godot.log",
                timeout_seconds + 2,
                self.root,
            )
            field = json.loads(source.read_text())
            records = list(jsonl(pairs))
            if any(row["trials"] != 2 * config["reps"] for row in records):
                raise SweepError("field replicate budget differs from frozen plan")
            atomic_json(folder / "field-report.json", field_report(field, records))
        elif kind == "analysis":
            # A separate process bounds CPU/memory-heavy Python analysis by the same deadline.
            run_command(
                [
                    sys.executable,
                    str(Path(__file__).resolve()),
                    "analyze",
                    str(self.plan_path),
                    "--config",
                    name,
                    "--out",
                    str(folder),
                ],
                folder / "analysis.log",
                timeout_seconds,
                self.root,
            )
        else:
            raise SweepError(f"unknown stage: {kind}")

    def analyze(self, name, folder):
        config = self.configs[name]
        captures = self.lobby_paths(config, "fights.jsonl")
        players = [row for path in self.lobby_paths(config, "players.csv") for row in csv_rows(path)]
        field = {"version": 1, "rounds": {}, "pairs": []}
        for number in config["rounds"]:
            partial = json.loads((self.stage_dir(f"{name}/field-r{number:02}") / "field-report.json").read_text())
            field["rounds"].update(partial["rounds"])
            field["pairs"].extend(partial["pairs"])
        atomic_json(folder / "field-report.json", field)
        catalog = {
            data["id"]: data
            for path in (self.root / "content/units").glob("*.json")
            if (data := json.loads(path.read_text()))
        }
        measurements = summarize(boards_from_capture(captures), players, catalog, field)
        measurements["provenance"] = {
            "plan_sha256": digest(self.plan),
            "source_commit": self.plan["source_commit"],
            "source_fingerprint": self.plan["source_fingerprint"],
            "config": config,
        }
        atomic_json(folder / "metrics.json", measurements)
        observed = config.get("observed_ids", config["overrides"].get("scale_levers", []))
        atomic_json(
            folder / "adoption.json", adoption_report(captures, self.lobby_paths(config, "cards.csv"), observed)
        )
        if config.get("damage_variants"):
            atomic_json(folder / "damage-replay.json", damage_report(captures, players, config["damage_variants"]))
        comparison = config.get("head_to_head")
        if comparison:
            chunk = comparison.get("chunk_seeds", 10)
            paths = [self.stage_dir(f"{name}/head-{offset:03}") / "bench.players.csv" for offset in range(0, 80, chunk)]
            combined = folder / "head.players.csv"
            combine_csv(paths, combined)
            check_plan = {**comparison, "seed_range": [comparison["first_seed"], comparison["first_seed"] + 79]}
            check = head_to_head(combined, check_plan)
            check["profiles_validated"] = True
            check["breakdown"] = line_breakdown(
                combined, json.loads(local_path(self.plan["profiles"], self.root).read_text())
            )
            check["fixed_budget_note"] = (
                "A false superiority test is a finding; no extra seeds or tuning are permitted."
            )
            atomic_json(folder / "head-to-head.json", check)

    def check_gate(self, config):
        gate = config.get("requires_gate")
        if not gate:
            return
        spec = {"path": gate} if isinstance(gate, str) else gate
        path = local_path(spec["path"], self.root)
        if not path.is_file():
            raise SweepError(f"{config['id']}: required positive build gate is missing: {path}")
        value = json.loads(path.read_text())
        for key in spec.get("key", "passes").split("."):
            if not isinstance(value, dict) or key not in value:
                raise SweepError(f"{config['id']}: gate has no {spec.get('key', 'passes')} condition")
            value = value[key]
        if value is not True:
            raise SweepError(f"{config['id']}: required build gate has not passed")
        provenance = {"path": spec["path"], "sha256": file_sha(path), "condition": spec.get("key", "passes")}
        recorded = self.status.setdefault("gates", {}).get(config["id"])
        if recorded and recorded != provenance:
            raise SweepError(f"{config['id']}: build gate changed since the first stage")
        self.status["gates"][config["id"]] = provenance

    def run(self, max_seconds=2400, deadline=None, max_stages=None, scope="all"):
        if not 1 <= max_seconds <= MAX_SECONDS:
            raise SweepError("max-seconds must be between 1 and 2700 (45 minutes)")
        end = time.monotonic() + max_seconds
        if deadline:
            stamp = datetime.fromisoformat(deadline.replace("Z", "+00:00"))
            if stamp.tzinfo is None:
                raise SweepError("deadline must include a timezone")
            end = min(end, time.monotonic() + stamp.timestamp() - time.time())
        self.output.mkdir(parents=True, exist_ok=True)
        with (self.output / "run.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise SweepError("another local sweep controller is running") from None
            self.prepare()
            completed_now = 0
            self.status.update(state="running", invocation_started_at=utc_now(), invocation_max_seconds=max_seconds)
            self.save()
            for stage in self.stages:
                config = self.configs[stage["config"]]
                if scope == "caps-only" and not set(config["overrides"]).issubset(
                    {"card_size_caps", "card_rate_limits"}
                ):
                    continue
                if self.completed(stage):
                    continue
                remaining = end - time.monotonic() - GUARD_SECONDS
                if remaining < stage["estimate_seconds"] or (max_stages is not None and completed_now >= max_stages):
                    self.status.update(
                        state="checkpoint",
                        stop_reason="deadline/stage budget; next stage was not started",
                        next_stage=stage["id"],
                    )
                    self.save()
                    self.write_report()
                    return self.status
                self.verify_inputs()
                try:
                    self.check_gate(config)
                except SweepError as error:
                    self.status.update(state="checkpoint", stop_reason=str(error), next_stage=stage["id"])
                    self.save()
                    self.write_report()
                    raise
                previous = self.status["stages"].get(stage["id"], {})
                attempt = previous.get("attempt", 0) + 1
                folder = self.output / stage["id"] / f"attempt-{attempt:03}"
                folder.mkdir(parents=True, exist_ok=False)
                checkpoint = {
                    "state": "running",
                    "attempt": attempt,
                    "directory": str(folder.relative_to(self.output)),
                    "started_at": utc_now(),
                    "stage": stage,
                }
                self.status["stages"][stage["id"]] = checkpoint
                self.save()
                started = time.monotonic()
                timeout_seconds = max(1, min(stage["timeout_seconds"], int(remaining) - 7))
                print(f"{utc_now()} starting {stage['id']} (timeout {timeout_seconds}s)", flush=True)
                try:
                    self.execute(stage, folder, timeout_seconds)
                    self.verify_inputs()
                    checkpoint.update(
                        state="complete",
                        finished_at=utc_now(),
                        elapsed_seconds=time.monotonic() - started,
                        outputs={
                            str(path.relative_to(self.output)): file_sha(path)
                            for path in sorted(folder.rglob("*"))
                            if path.is_file()
                        },
                    )
                    completed_now += 1
                    self.save()
                    self.write_report()
                except BaseException as error:
                    checkpoint.update(
                        state="incomplete",
                        finished_at=utc_now(),
                        error=str(error),
                        elapsed_seconds=time.monotonic() - started,
                    )
                    self.status.update(state="checkpoint", stop_reason=f"incomplete stage: {stage['id']}")
                    self.save()
                    self.write_report()
                    raise
            all_complete = all(
                self.status["stages"].get(stage["id"], {}).get("state") == "complete" for stage in self.stages
            )
            self.status.update(state="complete" if all_complete else "checkpoint", completed_scope=scope)
            if all_complete:
                self.status["completed_at"] = utc_now()
            self.status.pop("next_stage", None)
            self.status.pop("stop_reason", None)
            self.save()
            self.write_report()
            return self.status

    def link(self, path, label):
        return f"[{label}]({os.path.relpath(path, self.report.parent)})"

    def write_report(self):
        def fmt(value):
            return f"{value:.3f}" if value is not None else "n/a"

        lines = [
            "# Lever sweep",
            "",
            "Predeclared real-shop, real-pool mixed lobbies; no forced synthetic units. "
            "Stats measure feel; placements and repeated blind field fights measure outcomes. "
            "Late rounds contain survivors only. No results change budgets, policies or overrides.",
            "",
            f"Source `{self.plan['source_commit']}`; fingerprint `{self.plan['source_fingerprint']}`.",
            "",
            self.link(self.plan_path, "Frozen plan")
            + " · "
            + self.link(self.lock_path, "Input provenance")
            + " · "
            + self.link(self.status_path, "Atomic execution checkpoint"),
            "",
            f"Controller state: **{self.status['state']}**. Updated {self.status['updated_at']}.",
            "",
            "| Configuration | Completed stages | State | Measurements |",
            "|---|---:|---|---|",
        ]
        for config in self.plan["configs"]:
            name = config["id"]
            stages = [stage for stage in self.stages if stage["config"] == name]
            complete = sum(self.status["stages"].get(stage["id"], {}).get("state") == "complete" for stage in stages)
            final = self.status["stages"].get(f"{name}/analysis", {})
            ready = final.get("state") == "complete"
            link = (
                self.link(self.stage_dir(f"{name}/analysis") / "metrics.json", "Full metrics JSON")
                if ready
                else "pending"
            )
            lines.append(f"| {name} | {complete}/{len(stages)} | {'complete' if ready else 'pending'} | {link} |")
        for config in self.plan["configs"]:
            name = config["id"]
            if self.status["stages"].get(f"{name}/analysis", {}).get("state") != "complete":
                continue
            folder = self.stage_dir(f"{name}/analysis")
            result = json.loads((folder / "metrics.json").read_text())
            lines += [
                "",
                f"## {name}",
                "",
                f"150 independent lobbies, seeds {config['first_seed']}-{config['first_seed'] + 149}; "
                f"{config['field_size']} weighted boards at each of R6/8/10/12/14/16, "
                "eight replicates per orientation.",
                "",
                self.link(folder / "metrics.json", "Complete pooled/within-line metrics and tier arrivals")
                + " · "
                + self.link(folder / "field-report.json", "Board point rates, line weights and win matrices")
                + " · "
                + self.link(folder / "adoption.json", "Content exposure/adoption"),
                "",
                "| Round | Boards | S1 p50 | p90 | p99 | Share >=2x median | Largest-share p50 "
                "| Stats/gold p50 | Growth/gold p50 |",
                "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
            ]
            for number, values in result["rounds"].items():
                stats = values["stats"]
                cells = [
                    number,
                    str(stats["n"]),
                    fmt(stats["p50"]),
                    fmt(stats["p90"]),
                    fmt(stats["p99"]),
                    fmt(values["share_2x_round_median"]),
                    fmt(values["largest_share"]["p50"]),
                    fmt(values["stats_per_gold"]["p50"]),
                    fmt(values["growth_per_gold"]["p50"]),
                ]
                lines.append("| " + " | ".join(cells) + " |")
            lines += [
                "",
                "| Tier | Arrivals | Arrival ratio p50/p90/p99 | Printed ratio p50/p90/p99 |",
                "|---|---:|---|---|",
            ]
            for tier, values in result["tier_arrivals"].items():
                ratios = [
                    " / ".join(fmt(values[key][q]) for q in ("p50", "p90", "p99"))
                    for key in ("arrival_ratio", "printed_ratio")
                ]
                lines.append(f"| {tier} | {values['arrival_ratio']['n']} | {' | '.join(ratios)} |")
            lines += ["", "| Outcome | Rate / p50 | 95% interval / p90,p99 |", "|---|---:|---|"]
            for key, value in result["outcomes"].items():
                if "rate" in value:
                    interval = " / ".join(fmt(v) for v in value["ci95"]) if value["ci95"] else "n/a"
                    lines.append(f"| {key} | {fmt(value['rate'])} | {interval} |")
                elif key == "winner_final_round":
                    lines.append(
                        f"| Winner final round | {fmt(value['p50'])} | {fmt(value['p90'])}, {fmt(value['p99'])} |"
                    )
                else:
                    for subkey, number in value.items():
                        lines.append(f"| {key}: {subkey} | {fmt(number)} | — |")
            lines += [
                "",
                "R8 tied leaders split credit. Outcome intervals bootstrap whole independent seeds. "
                "Comeback rows use below-pooled and below-lobby R8 medians. Pair uncertainty excludes all-draw pairs.",
                "",
            ]
            adoption = json.loads((folder / "adoption.json").read_text())
            lines += [
                "| Lever ID | Active board-rounds | Owned seats/lobbies | Unique IIDs all/bought/created/unknown "
                "| Next-round retained/eligible | Final card rows | Unused observed |",
                "|---|---:|---:|---:|---:|---:|---|",
            ]
            for lever, values in adoption["levers"].items():
                counts = " / ".join(
                    str(values[key]) if values[key] is not None else "unknown"
                    for key in ("acquired_unique_iids", "bought_unique", "created_unique", "unknown_origin_unique")
                )
                retained = values["retention_same_iid_next_own_round"]
                lines.append(
                    f"| {lever} | {values['active_board_rounds']} | {values['owned_seats']}/{values['owned_lobbies']} "
                    f"| {counts} | {retained['retained']}/{retained['eligible']} "
                    f"| {values['final_card_rows']} | {values['observed_unused']} |"
                )
            lines += ["", adoption["method"], "", adoption["retention_method"]]
            if (folder / "head-to-head.json").exists():
                head = json.loads((folder / "head-to-head.json").read_text())
                lines += [
                    "",
                    self.link(
                        folder / "head-to-head.json", "Fixed head-to-head and exploratory per-line/tribe diagnostics"
                    ),
                    "",
                    f"{head['candidate']} versus {head['incumbent']}: 80 independent seeds, 160 seat-swapped lobbies. "
                    f"Place gain {fmt(head['mean_place_gain'])}, 95% CI {fmt(head['ci95'][0])}-{fmt(head['ci95'][1])}; "
                    f"superiority test **{'passes' if head['passes'] else 'does not pass'}**. "
                    "Two legs are seat controls, not paired shop RNG; seed is the cluster. "
                    "The fixed sample is never extended.",
                ]
            if (folder / "damage-replay.json").exists():
                replay = json.loads((folder / "damage-replay.json").read_text())
                lines += [
                    "",
                    self.link(folder / "damage-replay.json", "Full offline damage replay, validation and coverage"),
                    "",
                    replay["method"],
                    "",
                    "| Variant | Validated checks | Diverged | Lost coverage | Unresolved | Covered resolved "
                    "| End p50/p90/p99 (conditional after divergence) |",
                    "|---|---:|---:|---:|---:|---:|---|",
                ]
                for variant, data in replay["variants"].items():
                    values = data["summary"]
                    length = values["covered_resolved_end_round"]
                    percentiles = " / ".join(fmt(length[q]) for q in ("p50", "p90", "p99"))
                    lines.append(
                        f"| {variant} | {values['live_post_state_checks']} | {values['elimination_divergence_games']} "
                        f"| {values['coverage_lost_games']} | {values['unresolved_games']} "
                        f"| {length['n']} | {percentiles} |"
                    )
                lines += [
                    "",
                    "Original rules must reproduce live damage, Health/Armor, winner and length. "
                    "Only covered, resolved replay ends enter lengths; "
                    "changed-elimination trajectories remain conditional. "
                    "Unresolved survivors are never assigned finishes or game lengths.",
                ]
        self.report.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.report.with_name(self.report.name + f".tmp-{os.getpid()}")
        temporary.write_text("\n".join(lines) + "\n")
        temporary.replace(self.report)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    fingerprint = commands.add_parser("fingerprint")
    fingerprint.add_argument("--paths", nargs="+", default=SOURCE_PATHS)
    fingerprint.add_argument("--profiles", default="tools/sim/line_profiles.sweep.json")
    for command in ("prepare", "run", "status", "analyze"):
        subparser = commands.add_parser(command)
        subparser.add_argument("plan", type=Path)
        if command == "run":
            subparser.add_argument("--max-seconds", type=int, default=2400)
            subparser.add_argument("--deadline", help="absolute ISO-8601 UTC/offset deadline")
            subparser.add_argument("--max-stages", type=int)
            subparser.add_argument("--scope", choices=("all", "caps-only"), default="all")
        elif command == "analyze":
            subparser.add_argument("--config", required=True)
            subparser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "fingerprint":
            print(json.dumps(fingerprints(patterns=args.paths, profiles=args.profiles), indent=2))
            return
        sweep = Sweep(args.plan)
        if args.command == "run":
            status = sweep.run(args.max_seconds, args.deadline, args.max_stages, args.scope)
            print(json.dumps({key: value for key, value in status.items() if key != "stages"}, indent=2))
        elif args.command == "analyze":
            sweep.prepare()
            sweep.analyze(args.config, args.out)
        else:
            status = sweep.prepare()
            print(json.dumps({"status": status, "planned_stages": sweep.stages}, indent=2))
    except (SweepError, OSError, KeyError, json.JSONDecodeError) as error:
        print(f"lever_sweep: {error}", file=sys.stderr)
        raise SystemExit(2) from None


if __name__ == "__main__":
    main()
