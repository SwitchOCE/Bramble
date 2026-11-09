#!/usr/bin/env python3
"""Frozen H1 plan, resumable detached sim driver and four-lobby runtime smoke."""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import json
import re
import shlex
import time
from collections import Counter, defaultdict
from pathlib import Path

from evidence_io import read_json, write_json
from lever_sweep import ROOT, atomic_json, file_sha, run_command, source_manifest

ARMS = {"B": 150, "C": 150, "uncut": 100, "uncut_frozen": 100}
LINES = (
    "line_quilboar_engine",
    "line_birds_homecoming",
    "line_fairies_ring",
    "line_bog_engine",
    "line_hedgerow_engine",
    "line_hunters_engine",
    "line_oozes_engine",
    "hard",
)
TRIBES = dict(
    zip(LINES, ("quilboar", "Birds", "Fairies", "Bog folk", "Hedgerow folk", "Hunters", "Oozes", ""), strict=True)
)
BASE_CONFIG = {
    "pass3_content": True,
    "pass3_loop_guards": True,
    "reference_quilboar": True,
    "card_size_caps": False,
    "card_rate_limits": False,
    "scale_hero_spell_stats": True,
    "ask_for_kin": False,
    "tribes_per_lobby": 0,
    "damage_mode": "v05",
}
SOURCES = [
    "src",
    "content",
    "tools/sim/*.gd",
    "tools/sim/lines/*.json",
    "tools/sim/line_profiles.committed.json",
    "tools/sim/quilboar*.py",
    "docs/ideation/reference/quilboar/model/*.py",
    "project.godot",
    "tools/versions.env",
    "tools/sim/evidence/drivers/run_quilboar_h1.sh",
]


def seal_sources():
    return source_manifest(ROOT, SOURCES)


def config_for(arm):
    if arm not in ARMS:
        raise ValueError("unknown H1 arm")
    return {
        **BASE_CONFIG,
        "quilboar_ref_preset": "uncut" if arm == "uncut_frozen" else arm,
        "reference_quilboar_freeze_size": arm == "uncut_frozen",
    }


def plan(path, first_seed=2911001, chunk=5):
    if path.exists():
        raise ValueError("refusing to overwrite a frozen H1 plan")
    document = {
        "version": 1,
        "first_seed": first_seed,
        "chunk": chunk,
        "arms": {arm: {"lobbies": count, "config": config_for(arm)} for arm, count in ARMS.items()},
        "smoke": {arm: 2910001 + i for i, arm in enumerate(ARMS)},
        "lines": LINES,
        "source_sha256": seal_sources(),
        "source_commit": run_git("rev-parse", "HEAD"),
        "created_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "accounting_rounds": [9, 12, 15],
        "accounting_bounds": [0.5, 2],
        "fidelity_minimum": 4,
        "native_tribe_rates": "unchanged committed tree defaults in all four arms; C changes reference dials only",
        "roster": "one of each named engine line plus one normal Hard anchor; seed-shuffled seats; all seven tribes",
        "line_versions": ("Birds/Fairies designer wave-1 files; four other tribes' committed legacy engine profiles"),
        "sampling": (
            "Surviving committed boards only, pre-Start of Combat A+H. No zero imputation. Post-start beside it."
        ),
        "rng": (
            "Same seed IDs and roster across full arms; shop streams are not keyed by (seat,round,roll). "
            "Treat comparisons as unpaired, not synchronized counterfactual shops."
        ),
        "runtime_ceiling_seconds": 5400,
    }
    atomic_json(path, document)
    return document


def run_git(*arguments):
    import subprocess

    return subprocess.check_output(["git", "-C", str(ROOT), *arguments], text=True).strip()


def compact_chunk(prefix, arm, first, count, elapsed):
    with prefix.with_suffix(".players.csv").open() as stream:
        players = list(csv.DictReader(stream))
    grouped_players = defaultdict(list)
    for player in players:
        line = player["bot"].split(":")[0]
        grouped_players[int(player["seed"])].append(
            {
                "seat": int(player["seat"]),
                "line": line,
                "final_line": player["strategy"],
                "assigned_tribe": TRIBES[line],
                "final_tribe": player["final_tribe"],
                "place": int(player["place"]),
                "rounds": int(player["rounds"]),
                "hero": player["hero"],
            }
        )
    seeds = list(range(first, first + count))
    if sorted(grouped_players) != seeds:
        raise ValueError("incomplete seed coverage")
    for seed in seeds:
        if Counter(p["line"] for p in grouped_players[seed]) != Counter(LINES):
            raise ValueError("wrong H1 roster")
    rows, seen, commits, keystones = defaultdict(list), set(), {}, {}
    with prefix.with_suffix(".fights.jsonl").open() as stream:
        for raw in stream:
            record = json.loads(raw)
            seed, fight = int(record["seed"]), record["input"]
            for key, expected in config_for(arm).items():
                if fight["config"][key] != expected:
                    raise ValueError("wrong runtime configuration: " + key)
            for side, seat in enumerate(fight["player_ids"]):
                seat, number = int(seat), int(fight["round"])
                if seat < 0:
                    continue
                identity = seed, seat, number
                if identity in seen:
                    raise ValueError("duplicate real board capture")
                seen.add(identity)
                before = record["combat_start"][side]
                after = record["after_start_effects"][side]
                line = before["assigned_line"]
                if line not in LINES:
                    raise ValueError("unexpected assigned line")
                key = seed, seat
                if line != "line_quilboar_engine" or before["committed"]:
                    commits.setdefault(key, number)
                inventory = before["recruit_units"]
                if any(u["def_id"] == "qb_turbo_hogrider" for u in inventory):
                    keystones.setdefault(key, number)
                active = [u for u in before["units"] if u["active"]]
                rows[seed].append(
                    {
                        "seed": seed,
                        "seat": seat,
                        "round": number,
                        "line": line,
                        "starting_line": before["starting_line"],
                        "current_line": before["current_line"],
                        "stats": before["active_stats"],
                        "post_start_stats": after["active_stats"],
                        "largest_share": before["largest_share"],
                        "post_start_largest_share": after["largest_share"],
                        "gold_spent": before["gold_spent_game"],
                        "health": before["health"],
                        "units": [
                            {
                                "id": u["def_id"],
                                "attack": u["attack"],
                                "health": u["health"],
                                "active": True,
                                "slot": u["slot"],
                            }
                            for u in active
                        ],
                        "tier": int(fight["tiers"][side]),
                        "gem_size": [before["gem_attack_halves"], before["gem_health_halves"]],
                        "commit_round": commits.get(key),
                        "keystone_found_round": keystones.get(key),
                    }
                )
    output = []
    for seed in seeds:
        if Counter(r["line"] for r in rows[seed] if r["round"] == 1) != Counter(LINES):
            raise ValueError("missing starting board capture")
        roster = [
            {"seat": p["seat"], "line": p["line"], "assigned_tribe": p["assigned_tribe"]} for p in grouped_players[seed]
        ]
        output.append(
            {
                "arm": arm,
                "seed": seed,
                "elapsed_seconds": elapsed / count,
                "config": config_for(arm),
                "roster": roster,
                "rounds": rows[seed],
                "players": grouped_players[seed],
            }
        )
    return output


def simulate(document, folder, arm, first, count):
    folder.mkdir(parents=True, exist_ok=True)
    prefix = folder / f"{arm}-{first}"
    config_path = prefix.with_suffix(".config.json")
    atomic_json(config_path, config_for(arm))
    args = [
        "godot",
        "--headless",
        "-s",
        "res://tools/sim/bench.gd",
        "--",
        "suite=quilboar_h1",
        f"games={count}",
        f"first_seed={first}",
        "capture=on",
        f"config={config_path}",
        f"out={prefix}",
    ]
    shell = ". /opt/bramble/env.sh && exec /usr/bin/time -f h1_scope_seconds=%e " + shlex.join(
        ["timeout", "--kill-after=5s", "600", *args]
    )
    command = [
        "flock",
        "-w",
        "600",
        "/tmp/bramble-harness-godot.lock",
        "systemd-run",
        "--user",
        "--scope",
        "-q",
        "-p",
        "MemoryMax=3G",
        "bash",
        "-c",
        shell,
    ]
    if seal_sources() != document["source_sha256"]:
        raise ValueError("runtime sources changed after plan was frozen")
    tick = time.monotonic()
    run_command(command, prefix.with_suffix(".log"), 1220)
    wall = time.monotonic() - tick
    log = prefix.with_suffix(".log").read_text()
    match = re.search(r"h1_scope_seconds=([0-9.]+)", log)
    if not match:
        raise ValueError("missing scope runtime measurement")
    elapsed = float(match[1])
    lobbies = compact_chunk(prefix, arm, first, count, elapsed)
    output = prefix.with_suffix(".lobbies.json.gz")
    write_json(output, lobbies)
    raw = prefix.with_suffix(".fights.jsonl")
    archive = prefix.with_suffix(".fights.jsonl.gz")
    digest = hashlib.sha256()
    with (
        raw.open("rb") as source,
        archive.open("wb") as target,
        gzip.GzipFile(fileobj=target, mode="wb", filename="", mtime=0, compresslevel=3) as compressed,
    ):
        while block := source.read(1024 * 1024):
            digest.update(block)
            compressed.write(block)
    raw.unlink()
    return {
        "arm": arm,
        "first_seed": first,
        "lobbies": count,
        "scope_seconds": elapsed,
        "wall_seconds_including_lock_wait": wall,
        "compact": str(output.relative_to(ROOT)),
        "compact_sha256": file_sha(output),
        "capture": str(archive.relative_to(ROOT)),
        "capture_sha256": digest.hexdigest(),
        "capture_gzip_sha256": file_sha(archive),
        "players": str(prefix.with_suffix(".players.csv").relative_to(ROOT)),
        "log": str(prefix.with_suffix(".log").relative_to(ROOT)),
    }


def run(path, folder, smoke=False, arms=None):
    document = read_json(path)
    folder.mkdir(parents=True, exist_ok=True)
    progress_path = folder / "progress.json"
    progress = (
        read_json(progress_path)
        if progress_path.exists()
        else {
            "plan_sha256": file_sha(path),
            "state": "running",
            "smoke": smoke,
            "completed": dict.fromkeys(ARMS, 0),
            "chunks": [],
        }
    )
    if progress["plan_sha256"] != file_sha(path) or progress["smoke"] != smoke:
        raise ValueError("progress belongs to another frozen run")
    try:
        for arm in arms or ARMS:
            total = 1 if smoke else document["arms"][arm]["lobbies"]
            start = document["smoke"][arm] if smoke else document["first_seed"]
            for offset in range(progress["completed"][arm], total, document["chunk"]):
                count = min(document["chunk"], total - offset)
                progress.update(state="running", active_arm=arm, active_first_seed=start + offset)
                atomic_json(progress_path, progress)
                entry = simulate(document, folder, arm, start + offset, count)
                progress["chunks"].append(entry)
                progress["completed"][arm] += count
                atomic_json(progress_path, progress)
        progress.update(state="complete", active_arm=None)
        if smoke:
            times = {entry["arm"]: entry["scope_seconds"] / entry["lobbies"] for entry in progress["chunks"]}
            projected = sum(times[arm] * ARMS[arm] for arm in ARMS)
            progress["timing"] = {
                "seconds_per_lobby_by_arm": times,
                "mean_seconds_per_lobby": sum(times.values()) / len(times),
                "projected_full_seconds_conservative": projected,
                "within_90_minutes": projected <= 5400,
            }
        atomic_json(progress_path, progress)
    except Exception as error:
        progress.update(state="failed", error=str(error))
        atomic_json(progress_path, progress)
        raise
    return progress


def load_lobbies(progress):
    result = []
    for chunk in progress["chunks"]:
        path = ROOT / chunk["compact"]
        if file_sha(path) != chunk["compact_sha256"]:
            raise ValueError("changed compact evidence")
        result.extend(read_json(path))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["plan", "smoke", "run", "report"])
    parser.add_argument("--plan", type=Path, default=ROOT / "tools/sim/evidence/quilboar-h1-plan.json")
    parser.add_argument("--folder", type=Path)
    parser.add_argument("--arms", nargs="+", choices=list(ARMS))
    parser.add_argument("--out", type=Path, default=ROOT / "docs/ideation/reference/quilboar/h1")
    args = parser.parse_args()
    folder = args.folder or ROOT / "build/quilboar-h1" / ("smoke" if args.command == "smoke" else "run")
    if args.command == "plan":
        plan(args.plan)
    elif args.command in ["smoke", "run"]:
        run(args.plan, folder, args.command == "smoke", args.arms)
    else:
        from quilboar_h1_report import summarize, write_report

        progress = read_json(folder / "progress.json")
        report = summarize(load_lobbies(progress), smoke=progress["smoke"])
        report["progress"] = progress
        write_report(report, args.out)


if __name__ == "__main__":
    main()
