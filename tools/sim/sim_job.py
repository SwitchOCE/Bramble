#!/usr/bin/env python3
"""Thin entry point for the Actions sim job (.github/workflows/sim.yml) and its local twin.

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

A chunk that fails is retried seed by seed. A seed that still fails is dropped and listed in the
results README with its reason; nothing is resampled.
"""

from __future__ import annotations

import argparse
import gzip
import json
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "sim"))

from evidence_io import read_json, write_json  # noqa: E402

KINDS = ("lines",)
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
    config = {**config, "seeds": seeds, "shards": min(shards, len(seeds)), "rates": rates}
    if kind == "lines":
        from quilboar_h1 import ARMS

        config.setdefault("suite", "quilboar_h1")
        if config["suite"] != "quilboar_h1":
            raise ValueError("kind lines supports suite quilboar_h1 (the harness with a compact reader)")
        if config.get("preset") not in ARMS:
            raise ValueError(f"preset must be one of {list(ARMS)}")
    return config


def shard_seeds(config, index):
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
    if config["preset"] in ("B", "C"):
        values["pass3_preset"] = config["preset"]
    values.update(config["rates"])
    return values


def bench(config, out_dir, first, count):
    prefix = out_dir / f"{config['preset']}-{first}"
    config_path = prefix.with_suffix(".config.json")
    config_path.write_text(json.dumps(game_config(config), indent=2, sort_keys=True) + "\n")
    args = [
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
    tick = time.monotonic()
    with prefix.with_suffix(".log").open("w") as log:
        code = subprocess.run(
            args, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=60 + SECONDS_PER_LOBBY_LIMIT * count
        ).returncode
    elapsed = time.monotonic() - tick
    if code != 0:
        raise RuntimeError(f"bench.gd exited {code} (log {prefix.with_suffix('.log').name})")
    return prefix, elapsed


def compact(config, prefix, first, count, elapsed):
    from quilboar_h1 import compact_chunk

    lobbies = compact_chunk(prefix, config["preset"], first, count, elapsed)
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


def shard(config, index, out_dir):
    work = out_dir / f"shard-{index}"
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


def merge(config, shards_dir, result_dir):
    from quilboar_h1_report import summarize

    lobbies, receipts = [], []
    for index in range(1, config["shards"] + 1):
        receipt_path = next(shards_dir.rglob(f"shard-{index}.receipt.json"), None)
        if receipt_path is None:
            raise ValueError(f"shard {index} left no receipt")
        receipts.append(read_json(receipt_path))
        lobbies += read_json(receipt_path.with_name(f"shard-{index}.lobbies.json.gz"))
    dropped = {seed: why for receipt in receipts for seed, why in receipt["dropped"].items()}
    got = sorted(game["seed"] for game in lobbies)
    if sorted(got + [int(s) for s in dropped]) != sorted(config["seeds"]):
        raise ValueError("merged lobbies don't cover the config's seeds exactly once")
    result_dir.mkdir(parents=True, exist_ok=True)
    lobbies.sort(key=lambda g: g["seed"])
    write_json(result_dir / f"{config['preset']}.lobbies.json.gz", lobbies)
    summary = summarize(lobbies) if lobbies else {}
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


def write_readme(config, summary, result_dir, commit, timing):
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
        print(json.dumps(line_table(summary), indent=1))
    else:
        tick = time.monotonic()
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            list(pool.map(lambda i: shard(config, i, args.out / "shards"), range(1, config["shards"] + 1)))
        commit = subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()
        summary, _ = merge(config, args.out / "shards", args.out / "result")
        write_readme(config, summary, args.out / "result", commit, f"{time.monotonic() - tick:.0f} s local")
        print(json.dumps(line_table(summary), indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
