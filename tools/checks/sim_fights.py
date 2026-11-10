"""Job adapters for frozen fields and constructed setups; combat/readers stay in tools/sim.

Both kinds take ``input`` (a repository-relative JSON or JSON.gz path), preset,
rates, and the job's explicit seeds. ``field`` consumes field.py's sampled field
(rounds/boards/line_weights); ``designed`` consumes designed_setups.py's complete
boards/line_weights document, including current-card exports. Every seed fights
every within-round pair in both orientations. Seeds are actual combat RNG seeds,
not lobby counts or an implicit replicate prefix. No board state is reconstructed.
"""

from __future__ import annotations

import copy
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "sim"))

import designed_report  # noqa: E402
import field as field_reader  # noqa: E402
from evidence_io import read_json, write_json  # noqa: E402


def _input_path(config):
    value = config.get("input")
    if not isinstance(value, str) or not value:
        raise ValueError("field/designed needs input: a frozen harness input path")
    path = Path(value)
    return path if path.is_absolute() else ROOT / path


def _validate_document(document):
    # Reuse the harness's complete-state validator for sampled and designed inputs.
    with tempfile.TemporaryDirectory(prefix="bramble-sim-input-") as directory:
        path = Path(directory) / "input.json"
        write_json(path, document)
        return field_reader.load_designed(path)


def load_field(config):
    """Resolve preset/rates while preserving all authored or captured combat state."""
    source = read_json(_input_path(config))
    if config["kind"] == "designed":
        boards, weights = field_reader.load_designed(_input_path(config))
        result = {"version": 1, "rounds": {}, "source_mode": "designed_only"}
        result["weight_source"] = "explicit_designed_line_weights"
        test_cards = {}
        for number in weights:
            selected = [board for board in boards if board["round"] == int(number)]
            sampled = field_reader.sample_field(
                selected, (int(number),), len(selected), line_weights={number: weights[number]}
            )
            result["rounds"].update(sampled["rounds"])
            for card in sampled["test_cards"]:
                if card["id"] in test_cards and card != test_cards[card["id"]]:
                    raise ValueError("conflicting test-only card definitions across rounds")
                test_cards[card["id"]] = card
        result["test_cards"] = list(test_cards.values())
    else:
        result = copy.deepcopy(source)
        if not isinstance(result.get("rounds"), dict) or not result["rounds"]:
            raise ValueError("field input needs nonempty rounds")
        document = {
            "boards": [board for group in result["rounds"].values() for board in group["boards"]],
            "line_weights": {number: group["line_weights"] for number, group in result["rounds"].items()},
            "test_cards": result.get("test_cards", []),
        }
        _validate_document(document)
        for group in result["rounds"].values():
            counts = Counter(board["line"] for board in group["boards"])
            for board in group["boards"]:
                expected = group["line_weights"][board["line"]] / counts[board["line"]]
                if abs(board.get("weight", 0) - expected) > 1e-9:
                    raise ValueError("sampled field board weights disagree with its line weights")
    rates = read_json(ROOT / "content/pass3/rates.json")
    dials = {**rates["rates"], **rates["presets"][config["preset"]], **config.get("rates", {})}
    for number, group in result["rounds"].items():
        if len(group["boards"]) < 2:
            raise ValueError("every field round needs at least two boards")
        for board in group["boards"]:
            if board["round"] != int(number):
                raise ValueError("field board is stored under the wrong round")
            values = board["config"]
            values.update(dials)
            values["pass3_preset"] = config["preset"]
            # Captures freeze precise rates in an opaque map. Keep that map consistent
            # with explicit job overrides, rather than restoring captured old rates.
            exact = {key: values[key] for key in dials}
            if "pass3_text_defaults" in values:
                exact["pass3_text_defaults"] = values["pass3_text_defaults"]
            values["pass3_rates_exact_json"] = json.dumps(exact, sort_keys=True)
    return result


def validate(config):
    presets = read_json(ROOT / "content/pass3/rates.json")["presets"]
    if config.get("preset") not in presets:
        raise ValueError(f"preset must be one of {sorted(presets)}")
    if any(type(seed) is not int or not -(2**63) <= seed < 2**63 for seed in config["seeds"]):
        raise ValueError("fight seeds must be signed 64-bit integers")
    load_field(config)
    return config


def _pairs(field):
    return {
        (int(number), left["id"], right["id"])
        for number, group in field["rounds"].items()
        for left, right in combinations(group["boards"], 2)
    }


def _check_rows(field, rows, seeds):
    expected = {(number, a, b, seed) for number, a, b in _pairs(field) for seed in seeds}
    seen = set()
    for row in rows:
        seed_text = row.get("seed", "")
        if not isinstance(seed_text, str) or str(int(seed_text)) != seed_text:
            raise ValueError("noncanonical combat seed in fight output")
        key = row["round"], row["a"], row["b"], int(seed_text)
        if key not in expected or key in seen:
            raise ValueError("unexpected or duplicate pair/seed in fight output")
        if any(type(row.get(key)) is not int or not 0 <= row[key] <= 2 for key in ("wins_a", "wins_b", "draws")):
            raise ValueError("invalid paired-orientation fight counts")
        if row.get("trials") != 2 or sum(row[key] for key in ("wins_a", "wins_b", "draws")) != 2:
            raise ValueError("each seed must contain both fight orientations")
        seen.add(key)
    if seen != expected:
        raise ValueError("incomplete pair/seed coverage in fight output")


def shard(config, seeds, work):
    work.mkdir(parents=True, exist_ok=True)
    field = load_field(config)
    field_path, seeds_path = work / "field.json", work / "seeds.json"
    output_path, log_path = work / "pairs.jsonl", work / "field.log"
    write_json(field_path, field)
    # JSON strings retain all 64 bits in Godot's JSON parser.
    write_json(seeds_path, [str(seed) for seed in seeds])
    args = [
        "godot",
        "--headless",
        "-s",
        "res://tools/sim/field_fights.gd",
        "--",
        str(field_path),
        str(output_path),
        str(len(seeds)),
        "per_seed",
        str(seeds_path),
    ]
    if not os.environ.get("BRAMBLE_SLOT_HELD"):
        args = [str(ROOT / "scripts/godot_slot.sh"), *args]
    with log_path.open("w") as stream:
        done = subprocess.run(
            args,
            cwd=ROOT,
            stdout=stream,
            stderr=subprocess.STDOUT,
            env={**os.environ, "GODOT_SLOT_CLASS": "worker"},
            timeout=int(config.get("timeout", 1800)),
        )
    if done.returncode:
        raise RuntimeError(f"field_fights.gd exited {done.returncode}; see {log_path}")
    if re.search(r"(^|\W)(?:ERROR|WARNING|SCRIPT ERROR|Parse Error)[: ]|handle_crash", log_path.read_text(), re.M):
        raise RuntimeError(f"field_fights.gd logged a problem; see {log_path}")
    rows = [json.loads(line) for line in output_path.read_text().splitlines() if line.strip()]
    _check_rows(field, rows, seeds)
    records = [{"seed": seed, "pairs": [row for row in rows if row["seed"] == str(seed)]} for seed in seeds]
    return records, {
        "input_sha256": hashlib.sha256(_input_path(config).read_bytes()).hexdigest(),
        "fights": 2 * len(rows),
    }


def summarize(config, records):
    field = load_field(config)
    if sorted(record["seed"] for record in records) != sorted(config["seeds"]):
        raise ValueError("fight records do not cover the configured seeds exactly once")
    rows = [row for record in records for row in record["pairs"]]
    for record in records:
        if any(row["seed"] != str(record["seed"]) for row in record["pairs"]):
            raise ValueError("pair seed disagrees with its compact record")
    _check_rows(field, rows, config["seeds"])
    # Aggregate only transport counts; the harness owns all weighting/statistics.
    aggregates = {
        key: {"round": key[0], "a": key[1], "b": key[2], "wins_a": 0, "wins_b": 0, "draws": 0, "trials": 0}
        for key in _pairs(field)
    }
    for row in rows:
        target = aggregates[row["round"], row["a"], row["b"]]
        for name in ("wins_a", "wins_b", "draws", "trials"):
            target[name] += row[name]
    report = field_reader.field_report(field, [aggregates[key] for key in sorted(aggregates)])
    report.update(kind=config["kind"], preset=config["preset"], fights=2 * len(rows), passes=True)
    if config["kind"] == "designed" and all(
        "distribution" in board.get("design", {}) for group in field["rounds"].values() for board in group["boards"]
    ):
        indexes = {seed: index for index, seed in enumerate(config["seeds"])}
        paired = [{**row, "replicate": indexes[int(row["seed"])]} for row in rows]
        report["constructed_comparisons"] = designed_report.summarize(field, paired, len(config["seeds"]))
    return report
