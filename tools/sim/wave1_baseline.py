#!/usr/bin/env python3
"""Reusable, source-pinned five-tribe baseline; prepare/run/report commands never push or merge."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import shlex
import shutil
import statistics
import subprocess
import tarfile
import time
from collections import Counter
from pathlib import Path

from evidence_io import read_json, write_json
from lever_sweep import ROOT, atomic_json, file_sha, run_command, source_manifest
from metrics import percentile
from wave1_accounting import LINES, measurements

SOURCE_PATTERNS = [
    "src",
    "content",
    "tools/sim/*.gd",
    "tools/sim/lines/*.json",
    "tools/sim/line_profiles.committed.json",
    "project.godot",
    "tools/versions.env",
]
SIM_LOCK = "/tmp/bramble-harness-godot.lock"
OTHER_GODOT_LOCK = "/tmp/bramble-godot.lock"
SCRIPT = "tools/sim/wave1_baseline.gd"
COMPATIBILITY_MANIFEST = "measurement-compatibility.json"
HARNESS_OVERLAYS = (
    SCRIPT,
    "tools/sim/bench_suites.gd",
    "tools/sim/line_policies.gd",
    "tools/sim/line_brain.gd",
    "tools/sim/committed_line_brain.gd",
    "tools/sim/line_profiles.committed.json",
)


def gd_function(source, name):
    start = source.index("static func " + name + "(")
    end = source.find("\n\nstatic func ", start + 1)
    return source[start : end if end >= 0 else len(source)]


def adapt_archived_bot_pass3(native, harness):
    """Import only line-flight/court hooks; every other native function stays byte-identical."""
    adapted = native.replace(gd_function(native, "best_flight"), gd_function(harness, "best_flight"), 1)
    old = 'var court: bool = str(value.strategy.get("id", "")) in ["fairies_rainbow", "fairies_help"]'
    for name, indent in (("arrange", "\t"), ("play_slot", "\t\t")):
        native_function = gd_function(adapted, name)
        harness_function = gd_function(harness, name)
        marker = indent + "var court: bool = (\n"
        start = harness_function.index(marker)
        end = harness_function.index("\n" + indent + ")", start) + len("\n" + indent + ")")
        replacement = harness_function[start:end]
        if indent + old in native_function:
            changed = native_function.replace(indent + old, replacement, 1)
        elif replacement in native_function:
            changed = native_function
        else:
            raise ValueError("unrecognized archived BotPass3 court adapter: " + name)
        adapted = adapted.replace(native_function, changed, 1)
    return adapted


def overlay_measurement_harness(target):
    records = []
    paths = [*HARNESS_OVERLAYS, *(str(p.relative_to(ROOT)) for p in sorted((ROOT / "tools/sim/lines").glob("*.json")))]
    for relative in paths:
        source, destination = ROOT / relative, target / relative
        before = file_sha(destination) if destination.exists() else None
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        records.append(
            {
                "path": relative,
                "operation": "copy",
                "source_path": str(source),
                "destination_path": str(destination),
                "source_sha256": file_sha(source),
                "destination_before_sha256": before,
                "destination_sha256": file_sha(destination),
            }
        )
    relative = "src/core/bots/bot_pass3.gd"
    source, destination = ROOT / relative, target / relative
    if destination.exists():
        before = file_sha(destination)
        destination.write_text(adapt_archived_bot_pass3(destination.read_text(), source.read_text()))
        records.append(
            {
                "path": relative,
                "operation": "line_policy_adapter",
                "source_path": str(source),
                "destination_path": str(destination),
                "source_sha256": file_sha(source),
                "destination_before_sha256": before,
                "destination_sha256": file_sha(destination),
                "source_functions": ["best_flight", "arrange:line_court", "play_slot:line_court"],
            }
        )
    return {
        "version": 1,
        "purpose": "Current measurement lines on source-pinned native game; no combat/content/Bog policy replacement.",
        "harness_commit": git(ROOT, "rev-parse", "HEAD"),
        "files": records,
    }


def git(tree, *args):
    return subprocess.check_output(["git", "-C", str(tree), *args], text=True).strip()


def validate_banned_cards(value, tree=ROOT):
    """Validate source IDs before Godot; newly merged named lines need no driver code."""
    if not isinstance(value, dict):
        raise ValueError("banned_cards: expected an object of canonical starting lines to card lists")
    tree = Path(tree)
    profiles = read_json(tree / "tools/sim/line_profiles.committed.json")
    for path in sorted((tree / "tools/sim/lines").glob("*.json")):
        table = read_json(path)
        replaced_tribes = {str(entry["tribe"]).lower().split()[0] for entry in table.values()}
        profiles = {
            name: entry
            for name, entry in profiles.items()
            if str(entry["tribe"]).lower().split(" ")[0] not in replaced_tribes
        }
        profiles.update({name if name.startswith("line_") else "line_" + name: entry for name, entry in table.items()})
    units = {read_json(path)["id"] for path in (tree / "content/units").glob("*.json")}
    for line, cards in value.items():
        if not isinstance(line, str) or line not in profiles:
            raise ValueError("banned_cards: unknown canonical starting line " + str(line))
        if not isinstance(cards, list):
            raise ValueError("banned_cards." + line + ": expected a card list")
        if any(not isinstance(card, str) or card not in units for card in cards):
            raise ValueError("banned_cards." + line + ": unknown source card ID")
        if len(set(cards)) != len(cards):
            raise ValueError("banned_cards." + line + ": duplicate card ID")
    return {line: list(cards) for line, cards in value.items()}


def validate_banned_roster(bans, starting_lines=LINES):
    """A recognized source profile is not necessarily seated in this measurement."""
    unseated = sorted(line for line, cards in bans.items() if cards and line not in starting_lines)
    if unseated:
        raise ValueError("banned_cards: nonempty ban targets an unseated starting line: " + ", ".join(unseated))


def validate_ban_audit(audit, line, banned):
    if not isinstance(audit, dict):
        raise ValueError("missing banned-card audit")
    if audit.get("starting_line") != line or audit.get("banned_cards") != banned:
        raise ValueError("banned-card audit policy mismatch")
    if (
        audit.get("owned_banned") != []
        or audit.get("played_banned") != []
        or audit.get("acquired_banned", []) != []
        or audit.get("failure") != ""
    ):
        raise ValueError("banned-card policy violation: " + str(audit))


def preset_overrides(preset, supplied=None):
    if preset == "shipped":
        overrides = {}
    elif preset == "checkpoint":
        overrides = {"card_size_caps": False, "card_rate_limits": False}
    elif supplied is None:
        raise ValueError("named nonbaseline presets require explicit --overrides JSON; values are never invented")
    else:
        overrides = {}
    overrides.update(supplied or {})
    forbidden = {"human_bot", "bots", "players", "tribes_per_lobby"} & overrides.keys()
    if forbidden:
        raise ValueError("measurement owns roster and five-tribe rotation: " + ", ".join(sorted(forbidden)))
    return overrides


def target_tree(source_tree, commit, output):
    """An explicit other commit gets its own archive; the source worktree is untouched."""
    source_tree = Path(source_tree).resolve()
    resolved = git(source_tree, "rev-parse", f"{commit or 'HEAD'}^{{commit}}")
    if source_tree == ROOT.resolve() and resolved == git(source_tree, "rev-parse", "HEAD"):
        target = source_tree
    else:
        target = output / ("source-" + resolved[:12])
        target.mkdir(parents=True, exist_ok=False)
        archive = output / "source.tar"
        with archive.open("wb") as stream:
            subprocess.run(["git", "-C", str(source_tree), "archive", resolved], stdout=stream, check=True)
        with tarfile.open(archive) as stream:
            stream.extractall(target, filter="data")
        archive.unlink()
        atomic_json(output / COMPATIBILITY_MANIFEST, overlay_measurement_harness(target))
    return target, resolved


def godot_command(tree, mode, plan_path, output, seconds=300, do_import=False):
    if mode == "run" and do_import:
        raise ValueError("imports must be separate shared-lock calls before simulation")
    lock = SIM_LOCK if mode == "run" else OTHER_GODOT_LOCK
    invoke = ["godot", "--headless", "--path", str(tree)]
    shell = ". /opt/bramble/env.sh && "
    if do_import:
        shell += shlex.join([*invoke, "--editor", "--import"]) + " && "
    shell += "exec " + shlex.join([*invoke, "-s", "res://" + SCRIPT, "--", mode, str(plan_path), str(output)])
    return [
        "flock",
        "-w",
        "1800",
        lock,
        "systemd-run",
        "--user",
        "--scope",
        "-q",
        "-p",
        "MemoryMax=3G",
        "timeout",
        "--kill-after=5s",
        str(seconds),
        "bash",
        "-c",
        shell,
    ]


def prepare(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    plan_path = output / "plan.json"
    if plan_path.exists():
        raise ValueError("refusing to overwrite frozen plan")
    target, commit = target_tree(args.source_tree, args.commit, output)
    supplied = read_json(args.overrides) if args.overrides else None
    overrides = preset_overrides(args.preset, supplied)
    bans = validate_banned_cards(read_json(args.banned_cards) if getattr(args, "banned_cards", None) else {}, target)
    validate_banned_roster(bans)
    candidates = list(range(args.first_seed, args.first_seed + args.candidates))
    probe_plan = output / "probe-plan.json"
    atomic_json(probe_plan, {"seeds": candidates, "overrides": overrides, "banned_cards": bans})
    probe_path = output / "probe.json"
    if args.probe:
        shutil.copyfile(args.probe, probe_path)
    else:
        run_command(
            godot_command(target, "probe", probe_plan, probe_path, 180, True), output / "probe.log", 2100, target
        )
    probe = read_json(probe_path)
    eligible, excluded = probe["eligible_seeds"], probe["excluded_seeds"]
    if sorted(eligible + excluded) != candidates or len(set(eligible + excluded)) != len(candidates):
        raise ValueError("probe does not partition the declared candidates")
    if probe["config"]["tribes_per_lobby"] != 5:
        raise ValueError("probe did not use shipped five-tribe rotation")
    for key, value in overrides.items():
        if probe["config"].get(key) != value:
            raise ValueError("probe override mismatch: " + key)
    for seed in candidates:
        tribes = probe["tribes"][str(seed)]
        expected = "Birds" in tribes and "Fairies" in tribes
        if len(tribes) != 5 or (seed in eligible) != expected:
            raise ValueError("probe eligibility does not match actual rotation")
    if not eligible:
        raise ValueError("no eligible lobbies")
    all_eligible = list(eligible)
    maximum = args.max_lobbies
    if maximum is not None:
        if maximum < 1:
            raise ValueError("--max-lobbies must be positive")
        eligible = eligible[:maximum]
    plan = {
        "version": 1,
        "preset": args.preset,
        "execution": {"simulation_lock": SIM_LOCK, "other_godot_lock": OTHER_GODOT_LOCK},
        "source_tree": str(args.source_tree.resolve()),
        "source_commit": commit,
        "runtime_tree": str(target),
        "measurement_script_sha256": file_sha(ROOT / SCRIPT),
        "measurement_compatibility": (
            read_json(output / COMPATIBILITY_MANIFEST)
            if (output / COMPATIBILITY_MANIFEST).exists()
            else {"version": 1, "files": [], "purpose": "Current harness tree; no archive overlay required."}
        ),
        "source_sha256": source_manifest(target, SOURCE_PATTERNS),
        "driver_sha256": file_sha(Path(__file__)),
        "overrides": overrides,
        "banned_cards": bans,
        "config": probe["config"],
        "rates": probe["rates"],
        "candidate_seeds": candidates,
        "seeds": eligible,
        "eligible_seeds": all_eligible,
        "unused_eligible_seeds": all_eligible[len(eligible) :],
        "excluded_seeds": excluded,
        "tribes": probe["tribes"],
        "chunk": args.chunk,
        "bootstrap_replicates": 2000,
        "bootstrap_seed": 19014531,
        "output": str(output),
        "probe_sha256": file_sha(probe_path),
        "population": "Five-tribe lobbies conditioned on including Birds and Fairies; one committed seat per written line plus four blind Hard seats. Other three tribes follow the actual seeded game rotation. Not the unconditional shipped lobby population.",
        "pairing": "Same eligible seed set across cap settings; shop comparisons are unpaired because purchases and pool use desynchronize draws.",
    }
    atomic_json(plan_path, plan)
    print(
        json.dumps(
            {"plan": str(plan_path), "lobbies": len(eligible), "excluded": len(excluded), "source_commit": commit}
        )
    )


def parse_peat_diagnostic(record):
    """One real seat-fight per row, including absent cards and zero-output cards."""
    if record.get("version") != 1 or int(record["round"]) < 1 or len(record["sides"]) != 2:
        raise ValueError("invalid peat diagnostic")
    rows = []
    for side, entry in enumerate(record["sides"]):
        seat = int(entry["seat"])
        if seat != int(record["player_ids"][side]):
            raise ValueError("peat diagnostic seat mismatch")
        if seat < 0:
            continue
        if not 0 <= seat < 8 or entry["line"] not in (*LINES, "hard_field"):
            raise ValueError("invalid peat diagnostic seat/line")
        seen = set()
        for key, definition in (("king_instances", "peat_king"), ("cutter_instances", "peat_cutter")):
            for unit in entry[key]:
                uid = int(unit["uid"])
                if uid in seen or unit["def_id"] != definition or int(unit["owner_side"]) != side:
                    raise ValueError("invalid peat source attribution")
                seen.add(uid)
                if int(unit["raises"]) < 0 or int(unit["gold"]) < 0:
                    raise ValueError("negative peat output")
                if not unit["eligible"] and (unit["raises"] or unit["gold"]):
                    raise ValueError("ineligible peat source produced output")
        planned, credited = int(entry["planned_all_gold"]), int(entry["credited_all_gold"])
        delta = int(entry["gold_next_turn_after"]) - int(entry["gold_next_turn_before"])
        cutter = sum(int(u["gold"]) for u in entry["cutter_instances"])
        if (
            planned != credited
            or delta != credited + int(entry["early_spoils_gold"])
            or cutter != int(entry["credited_cutter_gold"])
            or cutter + int(entry["other_cutter_gold"]) > credited
        ):
            raise ValueError("peat next-turn gold did not reconcile")
        rows.append(
            {
                "seed": int(record["seed"]),
                "round": int(record["round"]),
                "side": side,
                "ghost_opponent": int(record["player_ids"][1 - side]) < 0,
                **entry,
            }
        )
    return rows


def contamination_summary(attempted, dropped):
    return {
        "attempted_trials": attempted,
        "dropped_trials": len(dropped),
        "dropped_share": len(dropped) / attempted if attempted else 0.0,
        "dropped_seeds": sorted(dropped),
        "passed": len(dropped) * 100 <= attempted * 2,
    }


def chunk_records(path):
    with Path(path).open() as stream:
        for raw in stream:
            yield json.loads(raw)


def parse_chunk(path, seeds, expected_config, *, with_diagnostics=False, banned_cards=None, with_drops=False):
    bans = banned_cards or {}
    validate_banned_roster(bans)
    dropped = set()
    for record in chunk_records(path):
        seed = int(record["seed"])
        if seed not in seeds:
            raise ValueError("unexpected seed")
        if record["type"] == "ban_violation":
            dropped.add(seed)
        snapshots = record.get("sides", []) if record["type"] == "peat_diagnostic" else record.get("combat_start", [])
        for snapshot in snapshots:
            line = snapshot.get("line", snapshot.get("starting_line"))
            if bans.get(line):
                try:
                    validate_ban_audit(snapshot.get("ban_audit"), line, bans[line])
                except ValueError as error:
                    if "policy violation:" not in str(error):
                        raise
                    dropped.add(seed)
    boards, players, seen, got = [], [], set(), set()
    diagnostics, diagnostic_seen = [], set()
    for record in chunk_records(path):
        seed = int(record["seed"])
        if seed in dropped:
            continue
        if record["type"] == "peat_diagnostic":
            for row in parse_peat_diagnostic(record):
                if bans.get(row["line"]):
                    validate_ban_audit(row.get("ban_audit"), row["line"], bans[row["line"]])
                identity = seed, row["seat"], row["round"]
                if identity in diagnostic_seen:
                    raise ValueError("duplicate peat seat-fight")
                diagnostic_seen.add(identity)
                diagnostics.append(row)
            continue
        if record["type"] == "lobby":
            if seed in got or len(record["players"]) != 8:
                raise ValueError("duplicate or incomplete lobby")
            got.add(seed)
            if len(record["tribes"]) != 5 or not {"Birds", "Fairies"} <= set(record["tribes"]):
                raise ValueError("missing tribe or wrong rotation size")
            if bans and record.get("banned_cards") != bans:
                raise ValueError("lobby banned-card policy mismatch")
            starting = [name.split(":")[0] for name in record["starting_lines"]]
            if Counter(starting) != Counter({**dict.fromkeys(LINES, 1), "hard_field": 4}):
                raise ValueError("wrong roster")
            for entry in record["players"]:
                seat = int(entry.get("seat", entry.get("player_id")))
                turns = entry["rounds"]
                players.append(
                    {
                        "seed": seed,
                        "seat": seat,
                        "line": starting[seat],
                        "final_line": record["final_lines"][seat],
                        "place": int(entry.get("place", entry.get("placement"))),
                        "rounds": len(turns) if isinstance(turns, list) else int(turns),
                        **{
                            key: entry[key]
                            for key in (
                                "assigned_build",
                                "assigned_tribes",
                                "final_tribe",
                                "plurality_tribe",
                                "plurality_share",
                                "no_tribe_reason",
                            )
                            if key in entry
                        },
                    }
                )
            continue
        fight = record["input"]
        for key in ("tribes_per_lobby", "card_size_caps", "card_rate_limits", "pass3_content", "pass3_loop_guards"):
            if fight["config"][key] != expected_config[key]:
                raise ValueError("wrong fight config: " + key)
        winner = int(record["result"]["winner"])
        for side, seat in enumerate(fight["player_ids"]):
            if int(seat) < 0:
                continue
            number = int(fight["round"])
            identity = seed, int(seat), number
            if identity in seen or not 8 <= number <= 14:
                raise ValueError("duplicate or out-of-range board")
            seen.add(identity)
            snapshot = record["combat_start"][side]
            starting = snapshot["starting_line"]
            current = snapshot["current_line"]
            if bans.get(starting):
                validate_ban_audit(snapshot.get("ban_audit"), starting, bans[starting])
            if starting in LINES and current not in (
                {starting, "line_birds_homecoming"} if starting == "line_birds_tempo" else {starting}
            ):
                raise ValueError("committed line fell back")
            boards.append(
                {
                    "seed": seed,
                    "seat": int(seat),
                    "round": number,
                    "line": starting,
                    "current_line": current,
                    "stats": snapshot["active_stats"],
                    "post_start_stats": record["after_start_effects"][side]["active_stats"],
                    "largest_share": snapshot["largest_share"],
                    "tier": fight["tiers"][side],
                    "fight_win": winner == side,
                    "fight_draw": winner < 0,
                    **({"ban_audit": snapshot["ban_audit"]} if bans.get(starting) else {}),
                }
            )
    if got != set(seeds) - dropped:
        raise ValueError("missing completed lobby")
    places = {(p["seed"], p["seat"]): p["place"] for p in players}
    for board in boards:
        board["place"] = places[board["seed"], board["seat"]]
    if with_diagnostics:
        expected = {(p["seed"], p["seat"], number) for p in players for number in range(1, p["rounds"] + 1)}
        if diagnostic_seen != expected:
            raise ValueError("missing/out-of-range all-round peat diagnostics")
        labels = {(p["seed"], p["seat"]): p["line"] for p in players}
        if any(row["line"] != labels[row["seed"], row["seat"]] for row in diagnostics):
            raise ValueError("peat starting line mismatch")
        result = (boards, players, diagnostics)
    else:
        result = (boards, players)
    return (*result, sorted(dropped)) if with_drops else result


def run(plan_path):
    plan = read_json(plan_path)
    output, target = Path(plan["output"]), Path(plan["runtime_tree"])
    bans = validate_banned_cards(plan.get("banned_cards", {}), target)
    validate_banned_roster(bans)
    progress_path = output / "progress.json"
    status = (
        read_json(progress_path)
        if progress_path.exists()
        else {"plan_sha256": file_sha(plan_path), "state": "running", "completed_lobbies": 0, "chunks": []}
    )
    if status["plan_sha256"] != file_sha(plan_path):
        raise ValueError("progress belongs to another plan")
    try:
        for offset in range(status["completed_lobbies"], len(plan["seeds"]), plan["chunk"]):
            if source_manifest(target, SOURCE_PATTERNS) != plan["source_sha256"]:
                raise ValueError("source changed during frozen run")
            if file_sha(Path(__file__)) != plan["driver_sha256"]:
                raise ValueError("measurement driver changed during frozen run")
            seeds = plan["seeds"][offset : offset + plan["chunk"]]
            prefix = output / f"chunk-{offset:04d}"
            invocation = prefix.with_suffix(".plan.json")
            atomic_json(invocation, {"seeds": seeds, "overrides": plan["overrides"], "banned_cards": bans})
            raw = prefix.with_suffix(".jsonl")
            status.update(state="running", active_seeds=seeds)
            atomic_json(progress_path, status)
            tick = time.monotonic()
            run_command(
                godot_command(target, "run", invocation, raw, max(240, len(seeds) * 15)),
                prefix.with_suffix(".log"),
                2300,
                target,
            )
            boards, players, diagnostics, dropped = parse_chunk(
                raw, seeds, plan["config"], with_diagnostics=True, banned_cards=bans, with_drops=True
            )
            compact = prefix.with_suffix(".analysis.json.gz")
            write_json(
                compact,
                {"boards": boards, "players": players, "peat_diagnostics": diagnostics, "dropped_seeds": dropped},
            )
            archive = prefix.with_suffix(".jsonl.gz")
            checksum = hashlib.sha256()
            with (
                raw.open("rb") as source,
                archive.open("wb") as destination,
                gzip.GzipFile(fileobj=destination, mode="wb", filename="", mtime=0, compresslevel=3) as zipped,
            ):
                while block := source.read(1024 * 1024):
                    checksum.update(block)
                    zipped.write(block)
            raw.unlink()
            status["chunks"].append(
                {
                    "seeds": seeds,
                    "lobbies": len(seeds) - len(dropped),
                    "dropped_seeds": dropped,
                    "seconds": time.monotonic() - tick,
                    "analysis": str(compact),
                    "analysis_sha256": file_sha(compact),
                    "capture": str(archive),
                    "capture_sha256": checksum.hexdigest(),
                    "capture_gzip_sha256": file_sha(archive),
                }
            )
            status.update(completed_lobbies=offset + len(seeds))
            status["contamination"] = contamination_summary(
                status["completed_lobbies"],
                {seed for chunk in status["chunks"] for seed in chunk.get("dropped_seeds", [])},
            )
            atomic_json(progress_path, status)
        status.update(state="complete", active_seeds=[])
        atomic_json(progress_path, status)
        if not status["contamination"]["passed"]:
            raise ValueError("contaminated trials exceed 2%: " + str(status["contamination"]))
    except BaseException as error:
        status.update(state="failed", error=str(error))
        atomic_json(progress_path, status)
        raise


def report(plan_path, result_path, markdown_path):
    plan = read_json(plan_path)
    progress = read_json(Path(plan["output"]) / "progress.json")
    if progress["state"] not in ("complete", "failed") or progress["completed_lobbies"] != len(plan["seeds"]):
        raise ValueError("complete fixed run required")
    boards, players, covered, diagnostics, dropped = [], [], [], [], set()
    for chunk in progress["chunks"]:
        path = Path(chunk["analysis"])
        if file_sha(path) != chunk["analysis_sha256"]:
            raise ValueError("analysis archive changed")
        data = read_json(path)
        boards.extend(data["boards"])
        players.extend(data["players"])
        diagnostics.extend(data.get("peat_diagnostics", []))
        covered.extend(chunk["seeds"])
        dropped.update(chunk.get("dropped_seeds", []))
    if covered != plan["seeds"]:
        raise ValueError("missing/duplicate seeds")
    accepted_plan = {**plan, "seeds": [seed for seed in plan["seeds"] if seed not in dropped]}
    result = (
        analyze(boards, players, accepted_plan)
        if accepted_plan["seeds"]
        else {"growth": {}, "lines": {}, "report_only": {}, "survival": "No accepted trials.", "starting_labels": ""}
    )
    result["contamination"] = contamination_summary(len(plan["seeds"]), dropped)
    if diagnostics:
        result["report_only"]["peat"] = peat_measurements(diagnostics)
    result.update(
        plan_sha256=file_sha(plan_path),
        source_commit=plan["source_commit"],
        preset=plan["preset"],
        config=plan["config"],
        rates=plan["rates"],
        banned_cards=plan.get("banned_cards", {}),
        population=plan["population"],
        pairing=plan["pairing"],
        lobbies=len(accepted_plan["seeds"]),
        excluded_candidates=len(plan["excluded_seeds"]),
        chunk_wall_seconds=sum(c["seconds"] for c in progress["chunks"]),
    )
    archive = result_path.with_suffix(".boards.json.gz")
    write_json(
        archive,
        {
            "boards": boards,
            "players": players,
            "peat_diagnostics": diagnostics,
            "plan": accepted_plan,
            "attempted_plan": plan,
            "progress": progress,
        },
    )
    result["analysis_archive"] = {"path": str(archive), "sha256": file_sha(archive)}
    atomic_json(result_path, result)
    markdown_path.write_text(markdown(result))
    if not result["contamination"]["passed"]:
        raise ValueError("contaminated trials exceed 2%: " + str(result["contamination"]))


def analyze(boards, players, plan):
    seeds = plan["seeds"]
    result = {
        "growth": {},
        "lines": {},
        "report_only": {},
        "deciding_measures": [
            "pre-start pooled lobby median geometric growth R8–R14",
            "realized committed R12 median with seed interval",
        ],
        "survival": "Round summaries contain surviving seats only, with counts and R14 survival reported. No zero imputation. Whole-lobby seed bootstrap retains empty/eliminated clusters.",
        "starting_labels": "All line grouping uses immutable starting line; final line is retained separately.",
    }
    for name, selected in [("all_seats", boards), ("committed_seats", [r for r in boards if r["line"] in LINES])]:
        stats = measurements(selected, seeds, plan["bootstrap_replicates"], plan["bootstrap_seed"])
        result["growth"][name] = {
            "rounds": stats["rounds"],
            **stats["preliminary_growth"],
            "bootstrap": stats["bootstrap"],
        }
    for line in LINES:
        selected = [r for r in boards if r["line"] == line]
        stats = measurements(selected, seeds, plan["bootstrap_replicates"], plan["bootstrap_seed"])
        r12 = [r for r in selected if r["round"] == 12]
        r14 = [r for r in selected if r["round"] == 14]
        seats = [p for p in players if p["line"] == line]
        median = stats["rounds"]["12"]["median"]
        result["lines"][line] = {
            **stats["rounds"]["12"],
            "rounds": stats["rounds"],
            "growth": stats["preliminary_growth"],
            "p90_r12": percentile([r["stats"] for r in r12], 0.9),
            "share_2x_line_median_r12": sum(r["stats"] >= 2 * median for r in r12) / len(r12) if r12 else None,
            "lobby_win_rate": sum(p["place"] == 1 for p in seats) / len(seats),
            "r14_alive": len(r14),
            "r14_alive_share": len(r14) / len(seeds),
            "final_line_counts": dict(Counter(p["final_line"] for p in seats)),
            "fight_win_rate_r8_r14": sum(r["fight_win"] for r in selected) / len(selected) if selected else None,
        }
    for number in range(8, 15):
        data = [r["stats"] for r in boards if r["round"] == number]
        med = statistics.median(data) if data else None
        result["report_only"][str(number)] = {
            "boards": len(data),
            "p50": med,
            "p90": percentile(data, 0.9),
            "share_2x_lobby_median": sum(x >= 2 * med for x in data) / len(data) if data else None,
        }
    result["report_only"]["r14_alive_all_seats"] = sum(r["round"] == 14 for r in boards)
    result["report_only"]["r14_alive_all_seats_share"] = sum(r["round"] == 14 for r in boards) / (8 * len(seeds))
    return result


def peat_measurements(rows):
    def card_summary(selected, card, output):
        key = card + "_instances"
        present = [r for r in selected if r[key]]
        instances = [u for r in present for u in r[key]]
        eligible = [u for u in instances if u["eligible"]]
        totals = [sum(int(u[output]) for u in r[key]) for r in present]
        total = sum(totals)
        return {
            "card_present_fights": len(present),
            "eligible_card_present_fights": sum(any(u["eligible"] for u in r[key]) for r in present),
            "starting_board_present_fights": sum(any(u["starting_board"] for u in r[key]) for r in present),
            "entered_only_card_present_fights": sum(not any(u["starting_board"] for u in r[key]) for r in present),
            "starting_board_instances": sum(bool(u["starting_board"]) for u in instances),
            "entered_during_combat_instances": sum(not u["starting_board"] for u in instances),
            "instances": len(instances),
            "eligible_instances": len(eligible),
            "golden_instances": sum(bool(u["golden"]) for u in instances),
            "copied_instances": sum(bool(u["copied"]) for u in instances),
            "zero_output_card_present_fights": sum(value == 0 for value in totals),
            "output_total": total,
            "output_per_card_present_fight": total / len(present) if present else None,
            "output_per_eligible_instance_fight": total / len(eligible) if eligible else None,
            "raises_for_opponent": sum(int(u["raises_for_opponent"]) for u in instances) if card == "king" else None,
        }

    def summarize(selected):
        return {
            "real_seat_fights": len(selected),
            "ghost_opponent_fights": sum(r["ghost_opponent"] for r in selected),
            "peat_king": card_summary(selected, "king", "raises"),
            "peat_cutter": card_summary(selected, "cutter", "gold"),
            "other_body_king_ability_raises": sum(int(r["other_king_raises"]) for r in selected),
            "other_body_cutter_ability_gold": sum(int(r["other_cutter_gold"]) for r in selected),
            "all_sources_credited_next_turn_gold": sum(int(r["credited_all_gold"]) for r in selected),
        }

    return {
        "scope": "All rounds, all real seats, including ghost-opponent fights; descriptive only.",
        "denominator": (
            "One card-present seat-fight includes zero outputs and every native card body that started on board "
            "or entered during combat. Instances count distinct combat uid per fight; eligible instances had "
            "the native pass3 ability when observed. Golden and combat-copied bodies each count as one instance. "
            "Off-board hand, away and held cards count only if they enter. Starting-board presence is also retained."
        ),
        "attribution": (
            "Only successful pass3_bog:king triggers on peat_king bodies count as raises; only exact gold_next_turn "
            "carry operations immediately following pass3_bog:cutter triggers on peat_cutter bodies count as Cutter "
            "gold. Ability outputs on other bodies are separate. Original starting-side ownership is retained through "
            "Changeling swaps; King raises delivered to the opponent are reported separately. Native simultaneous-death "
            "Sink witnesses count, as in the source mechanics."
        ),
        "gold_stage": (
            "Cutter gold is actual credited next-turn gold after session carry, reconciled per fight against all gold "
            "carry plus separate early spoils. Target RecruitCarry adds gold without a carry cap. This does not measure "
            "later income, spending or whether an eliminated seat reaches its next turn."
        ),
        "rounds": {
            str(number): summarize([r for r in rows if int(r["round"]) == number])
            for number in sorted({int(r["round"]) for r in rows})
        },
        "all_rounds": summarize(rows),
    }


def markdown(result):
    fmt = lambda x: f"{x:.3f}" if x is not None else "unknown"
    percent = lambda x: f"{x:.1%}" if x is not None else "unknown"
    interval = lambda x: f"[{x[0]:.3f}, {x[1]:.3f}]" if x else "unknown"
    lines = [
        f"# Wave 1 five-tribe baseline: {result['preset']}",
        "",
        result["population"],
        "",
        result["pairing"],
        "",
        f"{result['lobbies']} accepted lobbies; source `{result['source_commit']}`; execution wall {result['chunk_wall_seconds']:.1f}s.",
        "",
        "Contamination: "
        + json.dumps(result.get("contamination", contamination_summary(result["lobbies"], set())), sort_keys=True),
        "",
        "Only growth and realized committed R12 medians decide this step. Other numbers below are reported, not pass/fail.",
        "",
        "| Population | Pre-start R8–R14 growth | Seed 95% interval |",
        "|---|---:|---|",
    ]
    for name, row in result["growth"].items():
        lines.append(f"| {name} | {fmt(row['point'])} | {interval(row['ci95'])} |")
    lines += [
        "",
        "| Starting line | R12 median [seed 95% interval] | R12 survivors | p90 | ≥2× line median | Lobby wins | Fight wins R8–14 | R14 alive |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for name, row in result["lines"].items():
        lines.append(
            f"| {name} | {fmt(row['median'])} {interval(row['ci95'])} | {row['boards']} | {fmt(row['p90_r12'])} | {percent(row['share_2x_line_median_r12'])} | {row['lobby_win_rate']:.1%} | {percent(row['fight_win_rate_r8_r14'])} | {row['r14_alive']}/{result['lobbies']} ({row['r14_alive_share']:.1%}) |"
        )
    lines += ["", result["survival"], "", result["starting_labels"], ""]
    peat = result["report_only"].get("peat")
    if peat:
        lines += [peat["scope"], "", peat["denominator"], "", peat["attribution"], "", peat["gold_stage"], ""]
        for card, label, output in (
            ("peat_king", "Peat King", "Peatlings raised"),
            ("peat_cutter", "Peat Cutter", "Gold credited next turn"),
        ):
            lines += [
                f"{label} by round (report only).",
                "",
                "| Round | Card-present fights | Zero-output fights | Eligible instances | Golden instances | "
                f"{output} | Per card-present fight | Per eligible instance-fight |",
                "|---|---:|---:|---:|---:|---:|---:|---:|",
            ]
            for number, summary in [*peat["rounds"].items(), ("All", peat["all_rounds"])]:
                row = summary[card]
                lines.append(
                    f"| {number} | {row['card_present_fights']} | {row['zero_output_card_present_fights']} | "
                    f"{row['eligible_instances']} | {row['golden_instances']} | {row['output_total']} | "
                    f"{fmt(row['output_per_card_present_fight'])} | "
                    f"{fmt(row['output_per_eligible_instance_fight'])} |"
                )
            lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    prep = sub.add_parser("prepare")
    prep.add_argument("--source-tree", type=Path, default=ROOT)
    prep.add_argument("--commit")
    prep.add_argument("--preset", required=True)
    prep.add_argument("--overrides", type=Path)
    prep.add_argument("--banned-cards", type=Path, help="JSON canonical starting-line to source-card-ID lists")
    prep.add_argument("--output", type=Path, required=True)
    prep.add_argument("--probe", type=Path)
    prep.add_argument("--first-seed", type=int, default=1901001)
    prep.add_argument("--candidates", type=int, default=640)
    prep.add_argument("--chunk", type=int, default=20)
    prep.add_argument(
        "--max-lobbies", type=int, help="Presized prefix of eligible accounting seeds; no outcome-based extensions"
    )
    execute = sub.add_parser("run")
    execute.add_argument("--plan", type=Path, required=True)
    summarize = sub.add_parser("report")
    summarize.add_argument("--plan", type=Path, required=True)
    summarize.add_argument("--out", type=Path, required=True)
    summarize.add_argument("--markdown", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args)
    elif args.command == "run":
        run(args.plan)
    else:
        report(args.plan, args.out, args.markdown)


if __name__ == "__main__":
    main()
