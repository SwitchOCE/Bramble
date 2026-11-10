#!/usr/bin/env python3
"""Orchestration and report handling for the Actions sim job and its local twin.

    python3 tools/sim/sim_job.py matrix <config.json>                       shard numbers, as JSON
    python3 tools/sim/sim_job.py shard <config.json> <i> <out_dir>          run shard i (from 1)
    python3 tools/sim/sim_job.py merge <config.json> <shards_dir> <result_dir>
    python3 tools/sim/sim_job.py local <config.json> <out_dir> [--jobs J]   every shard here, then merge

A config (sim/<id>.json on an ideation/sim/<id> branch):
    {"kind": "lines", "suite": "quilboar_h1", "preset": "B",
     "seeds": [2911001, ...] | "first_seed": 2911001, "lobbies": 32,
     "rates": {"bog_soak_keep": 3}, "shards": 8}

kind "lines" runs the committed-line lobbies of tools/sim/quilboar_h1.py: the same bench.gd entry
point, compacted by that harness's compact_chunk into *.lobbies.json.gz, and summarized by
quilboar_h1_report.summarize. "preset" is that harness's arm (B, C, uncut, uncut_frozen) and also
sets pass3_preset for B and C. "rates" are GameConfig overrides of content/pass3/rates.json dials.
Seeds are dealt round-robin across shards, so each shard gets a similar mix.

kind "soak" runs tools/checks/soak.sh on contiguous seed blocks, one per shard:
    {"kind": "soak", "preset": "B", "first_seed": 1, "lobbies": 200, "shards": 8,
     "library": "", "synthetic": 0}
"preset" is a rates.json preset; "library" a field library for the field games (skipped and
counted without one); "synthetic" extra synthetic-card games, run on shard 1 and counted
separately. The merge sums games, the mix, violations (each distinct line once, with its count)
and crashes, and exits 1 after writing the results if there were any.

A chunk that fails is retried seed by seed. Persistent failures are recorded and fail the run;
nothing is resampled. Orchestration lives outside the measurement harness.
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools" / "sim"))

from evidence_io import read_json, write_json  # noqa: E402

KINDS = ("lines", "soak", "field", "designed")
MAX_SHARDS = 8
CHUNK = 4
SECONDS_PER_LOBBY_LIMIT = 300


def load_config(path):
    config = read_json(path)
    kind = config.get("kind")
    if kind not in KINDS:
        raise ValueError(f"kind must be one of {KINDS}, got {kind!r}")
    if "seeds" in config:
        seeds = [int(s) for s in config["seeds"]]
    else:
        seeds = list(range(int(config["first_seed"]), int(config["first_seed"]) + int(config["lobbies"])))
    if not seeds or len(set(seeds)) != len(seeds):
        raise ValueError("seeds must be a non-empty list without repeats")
    if "lobbies" in config and int(config["lobbies"]) != len(seeds):
        raise ValueError(f"lobbies is {config['lobbies']} but {len(seeds)} seeds are listed")
    shards = int(config.get("shards", MAX_SHARDS))
    if not 1 <= shards <= MAX_SHARDS:
        raise ValueError(f"shards must be 1 to {MAX_SHARDS} (GitHub Free allows 20 concurrent jobs in all)")
    rates = config.get("rates", {})
    if not isinstance(rates, dict):
        raise ValueError("rates must be an object of dial: value")
    if not isinstance(config.get("recruit_trace", False), bool):
        raise ValueError("recruit_trace must be a boolean")
    config = {**config, "seeds": seeds, "shards": min(shards, len(seeds)), "rates": rates}
    if kind == "soak":
        presets = read_json(ROOT / "content/pass3/rates.json")["presets"]
        if config.get("preset") not in presets:
            raise ValueError(f"preset must be one of {sorted(presets)}")
        if seeds != list(range(seeds[0], seeds[0] + len(seeds))):
            raise ValueError("a soak's seeds must be one contiguous range")
        config.setdefault("library", "")
        config["synthetic"] = int(config.get("synthetic", 0))
        if config["synthetic"] < 0:
            raise ValueError("synthetic must be nonnegative")
    if kind == "lines":
        from quilboar_h1 import ARMS

        config.setdefault("suite", "quilboar_h1")
        if config["suite"] not in ("quilboar_h1", "ooze_probe", "a35_run1"):
            raise ValueError("kind lines supports suite quilboar_h1 (the harness with a compact reader)")
        if config.get("preset") not in ARMS:
            raise ValueError(f"preset must be one of {list(ARMS)}")
    if kind in ("field", "designed"):
        from tools.checks import sim_fights

        config = sim_fights.validate(config)
    return config


def shard_seeds(config, index):
    if config["kind"] == "soak":
        size, extra = divmod(len(config["seeds"]), config["shards"])
        start = (index - 1) * size + min(index - 1, extra)
        return sorted(config["seeds"])[start : start + size + (index <= extra)]
    return config["seeds"][index - 1 :: config["shards"]]


def runs(seeds):
    """Contiguous seed runs, for bench.gd's first_seed + games."""
    out = []
    for seed in sorted(seeds):
        if out and seed == out[-1][0] + out[-1][1] and out[-1][1] < CHUNK:
            out[-1][1] += 1
        else:
            out.append([seed, 1])
    return out


def game_config(config):
    from quilboar_h1 import config_for

    values = dict(config_for(config["preset"]))
    if config["suite"] == "a35_run1":
        values["reference_quilboar"] = False
    if config["preset"] in ("B", "C"):
        values["pass3_preset"] = config["preset"]
    values.update(config["rates"])
    return values


def check_godot_log(log):
    """Use the gate's strict hook, including its shared allowlist, without copying regexes."""
    checked = subprocess.run(
        [
            "bash",
            "-c",
            '. "$1"; godot_log_init "$2"; godot_log_problems "$3"',
            "sim-log-check",
            str(ROOT / "scripts/godot_log.sh"),
            str(log.parent),
            str(log),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if checked.returncode not in (0, 1) or checked.stderr:
        raise RuntimeError(f"could not check Godot log {log.name}: {checked.stderr}")
    if checked.stdout:
        raise RuntimeError(f"Godot log problems in {log.name}: {checked.stdout.strip()}")


def bench(config, out_dir, first, count):
    prefix = out_dir / f"{config['preset']}-{first}"
    config_path = prefix.with_suffix(".config.json")
    config_path.write_text(json.dumps(game_config(config), indent=2, sort_keys=True) + "\n")
    args = [
        "scripts/godot_slot.sh",
        "godot",
        "--headless",
        "-s",
        "res://tools/sim/bench.gd",
        "--",
        f"suite={config['suite']}",
        f"games={count}",
        f"first_seed={first}",
        "capture=on",
        f"config={config_path}",
        f"out={prefix}",
    ]
    if config.get("recruit_trace", False):
        args.append("recruit_trace=on")
    if os.environ.get("BRAMBLE_SLOT_HELD"):
        args = args[1:]
    tick = time.monotonic()
    with prefix.with_suffix(".log").open("w") as log:
        code = subprocess.run(
            args,
            cwd=ROOT,
            stdout=log,
            stderr=subprocess.STDOUT,
            env={**os.environ, "GODOT_SLOT_CLASS": "worker"},
            timeout=60 + SECONDS_PER_LOBBY_LIMIT * count,
        ).returncode
    elapsed = time.monotonic() - tick
    if code != 0:
        raise RuntimeError(f"bench.gd exited {code} (log {prefix.with_suffix('.log').name})")
    check_godot_log(prefix.with_suffix(".log"))
    return prefix, elapsed


def compact(config, prefix, first, count, elapsed):
    from quilboar_h1 import compact_chunk

    lobbies = compact_chunk(
        prefix,
        config["preset"],
        first,
        count,
        elapsed,
        ooze_probe=config["suite"] == "ooze_probe",
        a35_run1=config["suite"] == "a35_run1",
    )
    for lobby in lobbies:
        lobby["rates_overrides"] = config["rates"]
    return lobbies


def run_chunk(config, out_dir, first, count):
    """Compact lobbies for one contiguous run, and the seeds dropped with their reasons."""
    try:
        prefix, elapsed = bench(config, out_dir, first, count)
        return compact(config, prefix, first, count, elapsed), {}
    except (RuntimeError, ValueError, KeyError, OSError, subprocess.TimeoutExpired) as error:
        if count == 1:
            return [], {first: str(error)}
    lobbies, dropped = [], {}
    for seed in range(first, first + count):
        got, lost = run_chunk(config, out_dir, seed, 1)
        lobbies += got
        dropped.update(lost)
    return lobbies, dropped


def soak_shard(config, index, work):
    """One soak.sh run over this shard's block; the receipt holds its parsed report lines."""
    seeds = shard_seeds(config, index)
    log = work / "soak.log"
    args = [
        "scripts/godot_slot.sh",
        "tools/checks/soak.sh",
        str(len(seeds)),
        "--preset",
        config["preset"],
        "--first-seed",
        str(seeds[0]),
    ]
    args += ["--log", str(log)]
    if config["library"]:
        args += ["--library", config["library"]]
    if index == 1 and config["synthetic"]:
        args += ["--synthetic", str(config["synthetic"])]
    if os.environ.get("BRAMBLE_SLOT_HELD"):
        args = args[1:]
    tick = time.monotonic()
    if not config["library"] and all(seed % 5 == 4 for seed in seeds) and not (index == 1 and config["synthetic"]):
        # No lobby is assigned to execute. Avoid the standalone checker's legitimate
        # "no fights ran" failure; merge still requires a played game across the run.
        report = (
            f"soak: games {len(seeds)} (seeds {seeds[0]}-{seeds[-1]}), played 0\n"
            f"soak: mix {{}}; field skipped {len(seeds)} (no library); synthetic games 0\n"
            "soak: synthetic violations 0\nsoak: violations 0\n"
        )
        log.write_text(report)
        done = subprocess.CompletedProcess(args, 0, stdout=report, stderr="")
    else:
        done = subprocess.run(
            args, cwd=ROOT, capture_output=True, text=True, env={**os.environ, "GODOT_SLOT_CLASS": "worker"}
        )
    report = done.stdout.splitlines()
    (work / "soak.out").write_text(done.stdout + done.stderr)

    def number(prefix, pattern):
        for line in report:
            if line.startswith(prefix):
                return int(re.search(pattern, line)[1])
        return None

    mix = next((line for line in report if line.startswith("soak: mix ")), "")
    return {
        "shard": index,
        "seeds": seeds,
        "exit": done.returncode,
        "reported_games": number("soak: games ", r"games (\d+)"),
        "played": number("soak: games ", r"played (\d+)"),
        "field_skipped": number("soak: mix ", r"field skipped (\d+)"),
        "synthetic": number("soak: mix ", r"synthetic games (\d+)"),
        "mix": json.loads(re.search(r"mix (\{.*?\});", mix)[1]) if mix else {},
        "violations": number("soak: violations ", r"violations (\d+)"),
        "violation_lines": [line.removeprefix("soak: VIOLATION ") for line in report if "soak: VIOLATION " in line],
        "synthetic_violations": number("soak: synthetic violations ", r"violations (\d+)"),
        "synthetic_violation_lines": [
            line.removeprefix("soak: SYNTHETIC VIOLATION ") for line in report if "SYNTHETIC VIOLATION " in line
        ],
        "crashes": [line for line in report if line.startswith("soak: CRASH")],
        "log_problems": "soak: log problems:" in report,
        "dropped": {},
        "seconds": round(time.monotonic() - tick, 1),
    }


def shard(config, index, out_dir):
    work = out_dir / f"shard-{index}"
    if config["kind"] in ("field", "designed"):
        from tools.checks import sim_fights

        work.mkdir(parents=True, exist_ok=True)
        tick = time.monotonic()
        seeds = shard_seeds(config, index)
        records, detail = sim_fights.shard(config, seeds, work)
        receipt = {
            **detail,
            "shard": index,
            "seeds": seeds,
            "dropped": {},
            "seconds": round(time.monotonic() - tick, 1),
        }
        write_json(out_dir / f"shard-{index}.receipt.json", receipt)
        write_json(out_dir / f"shard-{index}.lobbies.json.gz", records)
        return receipt
    if config["kind"] == "soak":
        work.mkdir(parents=True, exist_ok=True)
        receipt = soak_shard(config, index, work)
        write_json(out_dir / f"shard-{index}.receipt.json", receipt)
        write_json(out_dir / f"shard-{index}.lobbies.json.gz", [])
        return receipt
    work.mkdir(parents=True, exist_ok=True)
    tick = time.monotonic()
    lobbies, dropped = [], {}
    for first, count in runs(shard_seeds(config, index)):
        got, lost = run_chunk(config, work, first, count)
        lobbies += got
        dropped.update(lost)
    write_json(out_dir / f"shard-{index}.lobbies.json.gz", sorted(lobbies, key=lambda g: g["seed"]))
    receipt = {
        "shard": index,
        "seeds": shard_seeds(config, index),
        "dropped": {str(k): v for k, v in sorted(dropped.items())},
        "seconds": round(time.monotonic() - tick, 1),
    }
    write_json(out_dir / f"shard-{index}.receipt.json", receipt)
    # Raw captures stay out of git: gzip them for the workflow artifact.
    for raw in work.glob("*.fights.jsonl"):
        with raw.open("rb") as source, gzip.open(raw.with_suffix(".jsonl.gz"), "wb", compresslevel=3) as target:
            shutil.copyfileobj(source, target)
        raw.unlink()
    return receipt


def merge_soak(config, receipts, result_dir):
    from collections import Counter

    validate_receipts(config, receipts)
    problems = []
    for r in receipts:
        count_fields = ("reported_games", "played", "field_skipped", "synthetic", "violations", "synthetic_violations")
        if any(type(r.get(key)) is not int or r[key] < 0 for key in count_fields):
            problems.append(f"shard {r['shard']}: missing or invalid totals")
            continue
        assigned = len(r["seeds"])
        skipped = sum(seed % 5 == 4 for seed in r["seeds"]) if not config["library"] else 0
        synthetic = config["synthetic"] if r["shard"] == 1 else 0
        if (
            r["reported_games"] != assigned
            or r["played"] + r["field_skipped"] != assigned
            or r["field_skipped"] != skipped
        ):
            problems.append(f"shard {r['shard']}: played/skipped do not reconcile with assigned seeds")
        if r["synthetic"] != synthetic:
            problems.append(f"shard {r['shard']}: synthetic count differs from config")
        if not isinstance(r.get("mix"), dict) or sum(r["mix"].values()) != r["played"]:
            problems.append(f"shard {r['shard']}: mix does not reconcile with played games")
        expected_mix = Counter(
            "other" if seed % 5 == 3 else "field" if seed % 5 == 4 else "preset"
            for seed in r["seeds"]
            if config["library"] or seed % 5 != 4
        )
        if r["mix"] != dict(expected_mix):
            problems.append(f"shard {r['shard']}: mix differs from assigned seeds")
        if r["exit"] != 0 and not r["violations"] and not r["synthetic_violations"] and not r["crashes"]:
            problems.append(f"shard {r['shard']}: unexplained exit {r['exit']}")
    lines = Counter(line for r in receipts for line in r["violation_lines"])
    crashes = [f"shard {r['shard']}: {c}" for r in receipts for c in r["crashes"]]
    crashes += [
        f"shard {r['shard']}: exit {r['exit']}" for r in receipts if r["exit"] not in (0, 1) and not r["crashes"]
    ]
    mix = Counter()
    for r in receipts:
        mix.update(r["mix"])
    summary = {
        "kind": "soak",
        "preset": config["preset"],
        "games": len(config["seeds"]),
        "played": sum(r["played"] or 0 for r in receipts),
        "mix": dict(sorted(mix.items())),
        "field_skipped": sum(r["field_skipped"] or 0 for r in receipts),
        "synthetic": sum(r["synthetic"] or 0 for r in receipts),
        "violations": sum(r["violations"] or 0 for r in receipts),
        "distinct_violations": dict(lines.most_common()),
        "violation_lines_capped": any((r["violations"] or 0) > len(r["violation_lines"]) for r in receipts),
        "synthetic_violations": sum(r["synthetic_violations"] or 0 for r in receipts),
        "synthetic_violation_lines": dict(
            Counter(line for r in receipts for line in r["synthetic_violation_lines"]).most_common()
        ),
        "crashes": crashes,
        "log_problems": [r["shard"] for r in receipts if r["log_problems"]],
        "report_problems": problems,
        "sim_job": {
            "config": {k: v for k, v in config.items() if k != "seeds"},
            "seeds": [config["seeds"][0], config["seeds"][-1]],
            "shard_seconds": {r["shard"]: r["seconds"] for r in receipts},
            "dropped": {},
        },
    }
    # The real lobbies decide; synthetic-card games are reported beside them.
    summary["passes"] = (
        summary["played"] > 0
        and not summary["violations"]
        and not crashes
        and not summary["log_problems"]
        and not problems
    )
    write_json(result_dir / "summary.json", summary)
    return summary


def validate_receipts(config, receipts):
    """Reject duplicate, missing, reassigned or incomplete shard receipts."""
    if sorted(r["shard"] for r in receipts) != list(range(1, config["shards"] + 1)):
        raise ValueError("receipts must cover every shard exactly once")
    for receipt in receipts:
        if receipt.get("seeds") != shard_seeds(config, receipt["shard"]):
            raise ValueError(f"shard {receipt['shard']}: assigned seeds differ from config")


def merge(config, shards_dir, result_dir):
    from quilboar_h1_report import summarize

    lobbies, receipts = [], []
    for index in range(1, config["shards"] + 1):
        paths = list(shards_dir.rglob(f"shard-{index}.receipt.json"))
        if len(paths) != 1:
            raise ValueError(f"shard {index}: expected one receipt, found {len(paths)}")
        receipt_path = paths[0]
        receipts.append(read_json(receipt_path))
        lobbies += read_json(receipt_path.with_name(f"shard-{index}.lobbies.json.gz"))
    result_dir.mkdir(parents=True, exist_ok=True)
    validate_receipts(config, receipts)
    if config["kind"] == "soak":
        return merge_soak(config, receipts, result_dir), receipts
    dropped = {seed: why for receipt in receipts for seed, why in receipt["dropped"].items()}
    got = sorted(game["seed"] for game in lobbies)
    if sorted(got + [int(s) for s in dropped]) != sorted(config["seeds"]):
        raise ValueError("merged lobbies don't cover the config's seeds exactly once")
    result_dir.mkdir(parents=True, exist_ok=True)
    lobbies.sort(key=lambda g: g["seed"])
    write_json(result_dir / f"{config['preset']}.lobbies.json.gz", lobbies)
    if config["kind"] in ("field", "designed"):
        from tools.checks import sim_fights

        summary = sim_fights.summarize(config, lobbies)
    else:
        summary = summarize(lobbies) if lobbies else {}
    summary["passes"] = bool(lobbies) and not dropped
    summary["sim_job"] = {
        "config": {k: v for k, v in config.items() if k != "seeds"},
        "seeds": config["seeds"],
        "dropped": dropped,
        "shard_seconds": {r["shard"]: r["seconds"] for r in receipts},
    }
    write_json(result_dir / "summary.json", summary)
    return summary, receipts


def line_table(summary):
    """Per-line R12 pre-start median and R8-R14 growth, for the README and parity checks."""
    rows = {}
    for arm, data in summary.get("arms", {}).items():
        for line, values in data["lines"].items():
            r12 = values["rounds"].get("12", {}).get("pre_start", {})
            rows[f"{arm} {line}"] = {
                "r12_median": r12.get("point"),
                "r12_boards": r12.get("n", 0),
                "growth_r8_r14": values["growth_r8_r14"]["point"],
            }
    return rows


def soak_readme(config, summary, commit, timing):
    verdict = "PASS" if summary["passes"] else "FAIL"
    lines = [
        f"- Commit: `{commit}`",
        f"- Kind: soak, preset {config['preset']}, library {config['library'] or 'none'}",
        f"- Timing: {timing}",
        "",
        f"**Verdict: {verdict}.** {summary['violations']} violations, {len(summary['crashes'])} crashes, "
        f"log problems in shards {summary['log_problems'] or 'none'}.",
        f"- Report problems: {summary['report_problems'] or 'none'}",
        "",
        f"- Games: {summary['games']} seeds, {summary['played']} played; mix {summary['mix']}; "
        f"field games skipped (no library) {summary['field_skipped']}; synthetic games {summary['synthetic']} "
        "(separate).",
        "",
        "Distinct violation lines (count across shards; a directed check repeats once per shard):",
        "",
    ]
    lines += [f"- {n}x `{line}`" for line, n in summary["distinct_violations"].items()] or ["- none"]
    lines += [f"- crash: {c}" for c in summary["crashes"]]
    lines += ["", f"Synthetic-card games: {summary['synthetic_violations']} violations (reported, not the verdict)."]
    lines += [f"- {n}x `{line}`" for line, n in summary["synthetic_violation_lines"].items()]
    if summary["violation_lines_capped"]:
        lines.append("- (soak.gd prints at most 50 violation lines per shard; totals above are complete)")
    return lines


def write_readme(config, summary, result_dir, commit, timing):
    if config["kind"] == "soak":
        lines = [f"# Sim run `{result_dir.name}`", "", *soak_readme(config, summary, commit, timing)]
        lines += ["", "Raw logs are the workflow run's `sim-raw-<i>` artifacts (7 days)."]
        (result_dir / "README.md").write_text("\n".join(lines) + "\n")
        return
    if config["kind"] in ("field", "designed"):
        lines = [
            f"# Sim run `{result_dir.name}`",
            "",
            f"- Commit: `{commit}`",
            f"- Config: `{json.dumps(config, sort_keys=True)}`",
            f"- Timing: {timing}",
            f"- Verdict: {'PASS' if summary['passes'] else 'FAIL'}; dropped trials: {summary['sim_job']['dropped']}",
            "",
            "Summary uses the existing field/designed harness readers. Compact records retain "
            "each seed's pair results; raw native fight outputs remain workflow artifacts (7 days).",
        ]
        (result_dir / "README.md").write_text("\n".join(lines) + "\n")
        return
    lines = [
        f"# Sim run `{result_dir.name}`",
        "",
        f"- Commit: `{commit}`",
        f"- Kind: {config['kind']}, suite {config.get('suite')}, preset {config.get('preset')}",
        f"- Lobbies: {len(config['seeds'])} seeds over {config['shards']} shards; rates overrides: "
        + (json.dumps(config["rates"], sort_keys=True) if config["rates"] else "none"),
        f"- Timing: {timing}",
        f"- Dropped trials: {len(summary['sim_job']['dropped'])}",
    ]
    lines += [f"  - seed {seed}: {why}" for seed, why in sorted(summary["sim_job"]["dropped"].items())]
    lines += [
        "",
        "Files: `summary.json` (quilboar_h1_report.summarize, plus `sim_job`), "
        f"`{config.get('preset')}.lobbies.json.gz` (compact per-lobby records). Raw fight captures are "
        "the workflow run's artifacts (7 days).",
        "",
        "| Line | R12 pre-start median | R12 boards | Growth R8-R14 |",
        "|---|---:|---:|---:|",
    ]
    for name, row in line_table(summary).items():
        growth = "-" if row["growth_r8_r14"] is None else f"{row['growth_r8_r14']:.4f}"
        lines.append(f"| {name} | {row['r12_median']} | {row['r12_boards']} | {growth} |")
    (result_dir / "README.md").write_text("\n".join(lines) + "\n")


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("matrix").add_argument("config", type=Path)
    one = sub.add_parser("shard")
    one.add_argument("config", type=Path)
    one.add_argument("index", type=int)
    one.add_argument("out", type=Path)
    both = sub.add_parser("merge")
    both.add_argument("config", type=Path)
    both.add_argument("shards", type=Path)
    both.add_argument("result", type=Path)
    both.add_argument("--commit", default="")
    both.add_argument("--timing", default="")
    here = sub.add_parser("local")
    here.add_argument("config", type=Path)
    here.add_argument("out", type=Path)
    here.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args(argv)
    config = load_config(args.config)
    if args.command == "matrix":
        print(json.dumps(list(range(1, config["shards"] + 1))))
    elif args.command == "shard":
        if not 1 <= args.index <= config["shards"]:
            parser.error("shard index out of range")
        print(json.dumps(shard(config, args.index, args.out)))
    elif args.command == "merge":
        summary, _ = merge(config, args.shards, args.result)
        write_readme(config, summary, args.result, args.commit, args.timing)
        if config["kind"] == "soak":
            print((args.result / "README.md").read_text())
            return 0 if summary["passes"] else 1
        print(json.dumps(line_table(summary), indent=1))
        return 0 if summary["passes"] else 1
    else:
        if not 1 <= args.jobs <= 3:
            parser.error("local --jobs must be 1 to 3 (three shared Godot slots)")
        if args.jobs > 1 and os.environ.get("BRAMBLE_SLOT_HELD"):
            parser.error("parallel local jobs must acquire their own slots; omit the outer slot wrapper")
        tick = time.monotonic()
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            list(pool.map(lambda i: shard(config, i, args.out / "shards"), range(1, config["shards"] + 1)))
        commit = subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()
        summary, _ = merge(config, args.out / "shards", args.out / "result")
        write_readme(config, summary, args.out / "result", commit, f"{time.monotonic() - tick:.0f} s local")
        print((args.out / "result" / "README.md").read_text())
        return 0 if summary.get("passes", True) else 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
