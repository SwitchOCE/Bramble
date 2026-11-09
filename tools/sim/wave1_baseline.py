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


def git(tree, *args):
    return subprocess.check_output(["git", "-C", str(tree), *args], text=True).strip()


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
        helper = target / SCRIPT
        helper.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / SCRIPT, helper)
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
    candidates = list(range(args.first_seed, args.first_seed + args.candidates))
    probe_plan = output / "probe-plan.json"
    atomic_json(probe_plan, {"seeds": candidates, "overrides": overrides})
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
        "source_sha256": source_manifest(target, SOURCE_PATTERNS),
        "driver_sha256": file_sha(Path(__file__)),
        "overrides": overrides,
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


def parse_chunk(path, seeds, expected_config):
    boards, players, seen, got = [], [], set(), set()
    for raw in Path(path).read_text().splitlines():
        record = json.loads(raw)
        seed = int(record["seed"])
        if seed not in seeds:
            raise ValueError("unexpected seed")
        if record["type"] == "lobby":
            if seed in got or len(record["players"]) != 8:
                raise ValueError("duplicate or incomplete lobby")
            got.add(seed)
            if len(record["tribes"]) != 5 or not {"Birds", "Fairies"} <= set(record["tribes"]):
                raise ValueError("missing tribe or wrong rotation size")
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
                }
            )
    if got != set(seeds):
        raise ValueError("missing completed lobby")
    places = {(p["seed"], p["seat"]): p["place"] for p in players}
    for board in boards:
        board["place"] = places[board["seed"], board["seat"]]
    return boards, players


def run(plan_path):
    plan = read_json(plan_path)
    output, target = Path(plan["output"]), Path(plan["runtime_tree"])
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
            atomic_json(invocation, {"seeds": seeds, "overrides": plan["overrides"]})
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
            boards, players = parse_chunk(raw, seeds, plan["config"])
            compact = prefix.with_suffix(".analysis.json.gz")
            write_json(compact, {"boards": boards, "players": players})
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
                    "lobbies": len(seeds),
                    "seconds": time.monotonic() - tick,
                    "analysis": str(compact),
                    "analysis_sha256": file_sha(compact),
                    "capture": str(archive),
                    "capture_sha256": checksum.hexdigest(),
                    "capture_gzip_sha256": file_sha(archive),
                }
            )
            status.update(completed_lobbies=offset + len(seeds))
            atomic_json(progress_path, status)
        status.update(state="complete", active_seeds=[])
        atomic_json(progress_path, status)
    except BaseException as error:
        status.update(state="failed", error=str(error))
        atomic_json(progress_path, status)
        raise


def report(plan_path, result_path, markdown_path):
    plan = read_json(plan_path)
    progress = read_json(Path(plan["output"]) / "progress.json")
    if progress["state"] != "complete" or progress["completed_lobbies"] != len(plan["seeds"]):
        raise ValueError("complete fixed run required")
    boards, players, covered = [], [], []
    for chunk in progress["chunks"]:
        path = Path(chunk["analysis"])
        if file_sha(path) != chunk["analysis_sha256"]:
            raise ValueError("analysis archive changed")
        data = read_json(path)
        boards.extend(data["boards"])
        players.extend(data["players"])
        covered.extend(chunk["seeds"])
    if covered != plan["seeds"]:
        raise ValueError("missing/duplicate seeds")
    result = analyze(boards, players, plan)
    result.update(
        plan_sha256=file_sha(plan_path),
        source_commit=plan["source_commit"],
        preset=plan["preset"],
        config=plan["config"],
        rates=plan["rates"],
        population=plan["population"],
        pairing=plan["pairing"],
        lobbies=len(plan["seeds"]),
        excluded_candidates=len(plan["excluded_seeds"]),
        chunk_wall_seconds=sum(c["seconds"] for c in progress["chunks"]),
    )
    archive = result_path.with_suffix(".boards.json.gz")
    write_json(archive, {"boards": boards, "players": players, "plan": plan, "progress": progress})
    result["analysis_archive"] = {"path": str(archive), "sha256": file_sha(archive)}
    atomic_json(result_path, result)
    markdown_path.write_text(markdown(result))


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
        f"{result['lobbies']} lobbies; source `{result['source_commit']}`; execution wall {result['chunk_wall_seconds']:.1f}s.",
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
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    prep = sub.add_parser("prepare")
    prep.add_argument("--source-tree", type=Path, default=ROOT)
    prep.add_argument("--commit")
    prep.add_argument("--preset", required=True)
    prep.add_argument("--overrides", type=Path)
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
