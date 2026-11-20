#!/usr/bin/env python3
"""Mutate live game fight boards and retain only Godot-validated cases.

Python 3 stdlib only. See FORMAT.md for the restoration contract and commands.
"""

import argparse
import collections
import concurrent.futures
import copy
import hashlib
import json
import random
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TRIBES = ("badger", "locust", "mouse", "pigeon", "thorn")
KEYWORDS = ("taunt", "divine_shield", "windfury", "reborn", "venomous", "stealth", "cleave", "pigeon_guard_post")
KINDS = ("swap", "golden", "slot_keyword", "slot_renown", "heap", "hand")


def dump(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def cards_from_content():
    cards, tribes = {}, {}
    for tribe in TRIBES:
        for card in json.loads((ROOT / "src/content" / tribe / "units.json").read_text())["cards"]:
            if card.get("kind", "unit") == "unit":
                cards[card["id"]] = card
                tribes[card["id"]] = tribe
    return cards, tribes


def units(payload):
    return [unit for key in ("board", "hand") for unit in payload[key] if unit is not None]


def is_live_record(header):
    if not header:
        return False
    return header.get("format") == 3 or (
        header.get("format") == 4 and header.get("mode") == "live" and header.get("runs") == []
    )


def load_records(directories, card_tribes, manifest=None):
    """Snapshot complete lines of growing files; a saved manifest reuses the same prefixes."""
    if manifest:
        sources = json.loads(manifest.read_text())["sources"]
    else:
        files = sorted({path.resolve() for directory in directories for path in directory.rglob("*.jsonl")})
        sources = [{"path": str(path), "limit": path.stat().st_size} for path in files]
    buckets = {tribe: collections.defaultdict(list) for tribe in TRIBES}
    all_payloads, donors = [], []
    skipped = collections.Counter()
    used_sources = []
    for source in sources:
        path = Path(source["path"])
        digest = hashlib.sha256()
        consumed = 0
        header = None
        file_payloads = []
        with path.open("rb") as stream:
            while consumed < source["limit"]:
                line = stream.readline(source["limit"] - consumed)
                if not line.endswith(b"\n"):
                    skipped["unfinished trailing record line"] += 1
                    break
                digest.update(line)
                consumed += len(line)
                try:
                    entry = json.loads(line)
                except (ValueError, UnicodeDecodeError):
                    skipped["invalid record JSON"] += 1
                    continue
                if entry.get("op") == "header":
                    header = entry
                if not is_live_record(header):
                    continue
                if entry.get("op") != "fight_boards":
                    continue
                for payload in entry["players"]:
                    if payload["id"] < 0:
                        skipped["ghost payload"] += 1
                        continue
                    item = {"payload": payload, "turn": entry["turn"], "path": str(path)}
                    file_payloads.append(item)
        actual_hash = digest.hexdigest()
        if manifest and (consumed != source["limit"] or actual_hash != source["sha256"]):
            raise ValueError(f"source prefix changed: {path}")
        if is_live_record(header):
            used_sources.append(
                {
                    "path": str(path),
                    "limit": consumed,
                    "sha256": actual_hash,
                    "seed": header["seed"],
                    "build": header["build"],
                }
            )
        for item in file_payloads:
            all_payloads.append(item)
            payload = item["payload"]
            donors.extend(unit for unit in units(payload) if unit["def"] in card_tribes)
            containing = {card_tribes[unit["def"]] for unit in units(payload) if unit["def"] in card_tribes}
            for tribe in sorted(containing):
                buckets[tribe][item["turn"]].append(item)
    if any(not buckets[tribe] for tribe in TRIBES):
        raise ValueError("records must contain all five tribes")
    if len({item["path"] for item in all_payloads}) < 2:
        raise ValueError("at least two source records are required")
    return buckets, donors, used_sources, skipped, len(all_payloads)


class Generator:
    def __init__(self, seed, buckets, donors, cards):
        self.rng = random.Random(seed)
        self.buckets = buckets
        self.turns = {tribe: sorted(buckets[tribe]) for tribe in TRIBES}
        self.donors = donors
        self.cards = cards
        self.card_ids = sorted(cards)
        self.reserve = [unit for unit in donors if self.is_reserve(unit)]
        if not self.reserve:
            raise ValueError("records have no Reserve hand/board donor units")

    def is_reserve(self, unit):
        card = self.cards[unit["def"]]
        return "pigeon_reserve" in card.get("keywords", []) or any(
            effect.get("mechanic") == "pigeon_reserve" for effect in card.get("effects", [])
        )

    def pick(self, tribe):
        turn = self.rng.choice(self.turns[tribe])
        return self.rng.choice(self.buckets[tribe][turn])

    def case(self, case_id):
        rng = self.rng
        source_a = self.pick(TRIBES[case_id % len(TRIBES)])
        # Pair across records and turns; never replay an original pairing unchanged.
        for _ in range(1000):
            source_b = self.pick(rng.choice(TRIBES))
            if source_a["path"] != source_b["path"] and source_a["turn"] != source_b["turn"]:
                break
        else:
            raise ValueError("cannot find two records with distinct turns")
        a, b = (copy.deepcopy(source["payload"]) for source in (source_a, source_b))
        changes = [f"pair:a={source_a['path']}@{source_a['turn']};b={source_b['path']}@{source_b['turn']}"]
        if a["id"] == b["id"]:
            b["id"] = (a["id"] + 1) % 8
            changes.append(f"player_id:b={b['id']}")
        # Rotate the required mutation and sample extra categories independently.
        chosen = {KINDS[case_id % len(KINDS)]}
        chosen.update(kind for kind in KINDS if rng.random() < 0.45)
        for kind in KINDS:
            if kind not in chosen:
                continue
            if kind == "swap":
                ai = [i for i, unit in enumerate(a["board"]) if unit]
                bi = [i for i, unit in enumerate(b["board"]) if unit]
                if ai and bi:
                    i, j = rng.choice(ai), rng.choice(bi)
                    a["board"][i], b["board"][j] = b["board"][j], a["board"][i]
                    changes.append(f"swap:a.board[{i}]<->b.board[{j}]")
                else:
                    side, owner = rng.choice((("a", a), ("b", b)))
                    i = rng.randrange(7)
                    owner["board"][i] = copy.deepcopy(rng.choice(self.donors))
                    changes.append(f"swap:{side}.board[{i}]=record_donor")
            elif kind == "golden":
                side, owner = rng.choice((("a", a), ("b", b)))
                available = units(owner)
                if not available:
                    owner["board"][0] = copy.deepcopy(rng.choice(self.donors))
                    available = units(owner)
                unit = rng.choice(available)
                unit["golden"] = not unit["golden"]
                # Omitted base layers are recomputed from card + golden by restore_unit.
                # Explicit recorded base overrides and all other deltas stay explicit.
                changes.append(f"golden:{side}:{unit['def']}={unit['golden']}")
            elif kind == "slot_keyword":
                side, owner = rng.choice((("a", a), ("b", b)))
                i = rng.randrange(7)
                slot = owner["slots"][i]
                keyword = rng.choice(KEYWORDS)
                if keyword in slot["keywords"]:
                    slot["keywords"].remove(keyword)
                    changes.append(f"slot_keyword:{side}[{i}]-{keyword}")
                else:
                    slot["keywords"].append(keyword)
                    changes.append(f"slot_keyword:{side}[{i}]+{keyword}")
            elif kind == "slot_renown":
                side, owner = rng.choice((("a", a), ("b", b)))
                i = rng.randrange(7)
                renown = rng.choice([n for n in range(4) if n != owner["slots"][i].get("renown", 0)])
                owner["slots"][i]["renown"] = renown
                changes.append(f"slot_renown:{side}[{i}]={renown}")
            elif kind == "heap":
                side, owner = rng.choice((("a", a), ("b", b)))
                heap = owner["heaps"].setdefault("thorn_compost", {"entries": [], "_next_n": 1})
                entries = heap["entries"]
                if entries and rng.random() < 0.5:
                    count = rng.randint(1, len(entries))
                    for _ in range(count):
                        entries.pop(rng.randrange(len(entries)))
                    changes.append(f"heap:{side}:remove={count}")
                else:
                    count = rng.randint(1, 20)
                    for _ in range(count):
                        card_id = rng.choice(self.card_ids)
                        entries.append({"id": card_id, "tier": self.cards[card_id]["tier"], "n": heap["_next_n"]})
                        heap["_next_n"] += 1
                    changes.append(f"heap:{side}:add={count}")
            elif kind == "hand":
                side, owner = rng.choice((("a", a), ("b", b)))
                hand = owner["hand"]
                if hand and (len(hand) >= 7 or rng.random() < 0.5):
                    count = rng.randint(1, len(hand))
                    for _ in range(count):
                        hand.pop(rng.randrange(len(hand)))
                    changes.append(f"hand:{side}:remove={count}")
                else:
                    count = rng.randint(1, 7 - len(hand))
                    for _ in range(count):
                        # Reserve is drawn from real snapshots, including its stat deltas.
                        hand.append(copy.deepcopy(rng.choice(self.reserve)))
                    changes.append(f"hand:{side}:add_reserve={count}")
        uid = 1
        for owner in (a, b):
            for unit in units(owner):
                unit["uid"] = uid
                uid += 1
        changes.append("uid:renumber_board_then_hand_a_then_b")
        return {
            "id": case_id,
            "game_seed": str(rng.randrange(-(2**63), 2**63)),
            "round": rng.choice((source_a["turn"], source_b["turn"])),
            "a": a,
            "b": b,
            "mutations": changes,
            "trace": ["uses"],
        }


def run_shard(cases, output, first, count, seconds, godot):
    command = [
        "timeout",
        "-k",
        "10",
        str(seconds),
        godot,
        "--headless",
        "--log-file",
        str(output.with_suffix(".godot.log")),
        "-s",
        "res://tools/league/gd/fight_run.gd",
        "--",
        f"cases={cases}",
        f"out={output}",
        f"first={first}",
        f"count={count}",
    ]
    started = time.monotonic()
    with output.with_suffix(".stdout").open("w") as log:
        result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    log_text = output.with_suffix(".stdout").read_text()
    if result.returncode or re.search(r"(?:SCRIPT ERROR|ERROR:|WARNING:)", log_text):
        raise RuntimeError(f"runner failed ({result.returncode}); see {output.with_suffix('.stdout')}")
    timing = re.search(r"elapsed_us=(\d+)", log_text)
    if timing is None:
        raise RuntimeError(f"runner has no completion marker: {output}")
    return {
        "first": first,
        "count": count,
        "elapsed_us": int(timing[1]),
        "wall_seconds": time.monotonic() - started,
        "output": str(output),
    }


def cover(case, card_tribes, generator, coverage):
    payloads = (case["a"], case["b"])
    all_units = [unit for owner in payloads for unit in units(owner)]
    containing = {card_tribes[unit["def"]] for unit in all_units if unit["def"] in card_tribes}
    coverage["tribes"].update(containing)
    coverage["mutations"].update({change.split(":", 1)[0] for change in case["mutations"]})
    for change in case["mutations"]:
        for name, fragment in (
            ("heap_add", ":add="),
            ("heap_remove", ":remove="),
            ("hand_add_reserve", ":add_reserve="),
            ("hand_remove", ":remove="),
        ):
            if change.startswith(name.split("_", 1)[0] + ":") and fragment in change:
                coverage["operations"][name] += 1
    flags = {
        "golden_units": any(unit["golden"] for unit in all_units),
        "nonempty_heaps": any(heap["entries"] for owner in payloads for heap in owner["heaps"].values()),
        "nonempty_hands": any(owner["hand"] for owner in payloads),
        "reserve_hands": any(
            generator.is_reserve(unit) for owner in payloads for unit in owner["hand"] if unit["def"] in generator.cards
        ),
        "slot_keywords": any(slot["keywords"] for owner in payloads for slot in owner["slots"]),
        "slot_renown": any(slot.get("renown", 0) for owner in payloads for slot in owner["slots"]),
    }
    coverage["features"].update(name for name, present in flags.items() if present)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--records", type=Path, nargs="+", default=[Path(f"/home/alex/league/records/gd/c{i}") for i in range(3)]
    )
    parser.add_argument("--count", type=int, default=100000)
    parser.add_argument("--seed", type=int, default=20261118)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--results", type=Path, help="default: gd.jsonl next to cases")
    parser.add_argument("--jobs", type=int, choices=range(1, 9), default=3)
    parser.add_argument("--timeout", type=int, default=14400, help="seconds per Godot process")
    parser.add_argument("--batch-size", type=int, default=100000)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--manifest", type=Path, help="reuse source prefixes from a previous report")
    args = parser.parse_args()
    if args.count < 1 or args.batch_size < 1 or args.timeout < 1:
        parser.error("count, batch-size and timeout must be positive")
    args.out = args.out.resolve()
    args.results = (args.results or args.out.with_name("gd.jsonl")).resolve()
    if args.out == args.results:
        parser.error("out and results must differ")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.results.parent.mkdir(parents=True, exist_ok=True)
    work = args.out.parent / (args.out.stem + ".work")
    work.mkdir(exist_ok=True)
    cards, card_tribes = cards_from_content()
    buckets, donors, sources, skipped, payload_count = load_records(args.records, card_tribes, args.manifest)
    generator = Generator(args.seed, buckets, donors, cards)
    report = {
        "seed": args.seed,
        "requested": args.count,
        "sources": sources,
        "source_payloads": payload_count,
        "source_skipped": dict(skipped),
        "source_buckets": {
            tribe: {str(turn): len(items) for turn, items in sorted(turns.items())} for tribe, turns in buckets.items()
        },
    }
    report_path = args.out.with_suffix(".report.json")
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"sources={len(sources)} payloads={payload_count}; writing {report_path}", flush=True)
    coverage = {
        name: collections.Counter()
        for name in ("tribes", "features", "mutations", "operations", "uses")
    }
    accepted = attempted = batch = 0
    rejected = collections.Counter()
    timings = []
    started = time.monotonic()
    with (
        args.out.open("w") as cases_out,
        args.results.open("w") as results_out,
        (work / "rejected.jsonl").open("w") as rejects_out,
    ):
        while accepted < args.count:
            size = min(args.batch_size, args.count - accepted)
            candidates = work / f"batch-{batch}.cases.jsonl"
            with candidates.open("w") as stream:
                for case_id in range(attempted, attempted + size):
                    stream.write(dump(generator.case(case_id)) + "\n")
            shards = []
            # Even with jobs=1 a process never exceeds 35,000 cases.
            shard_size = min(35000, (size + args.jobs - 1) // args.jobs)
            with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as executor:
                pending = []
                for first in range(0, size, shard_size):
                    output = work / f"batch-{batch}.first-{first}.gd.jsonl"
                    pending.append(
                        executor.submit(
                            run_shard,
                            candidates,
                            output,
                            first,
                            min(shard_size, size - first),
                            args.timeout,
                            args.godot,
                        )
                    )
                for future in pending:
                    shard = future.result()
                    shards.append(shard)
                    timings.append(shard)
            with candidates.open() as candidate_stream:
                for shard in sorted(shards, key=lambda value: value["first"]):
                    lines = 0
                    with Path(shard["output"]).open() as result_stream:
                        for line in result_stream:
                            case_line = next(candidate_stream)
                            case, result = json.loads(case_line), json.loads(line)
                            if result["id"] != case["id"]:
                                raise ValueError(f"case/result ids differ: {case['id']}, {result['id']}")
                            lines += 1
                            if "error" in result:
                                rejected[result["error"]] += 1
                                rejects_out.write(dump({"case": case, "error": result["error"]}) + "\n")
                                continue
                            if hashlib.sha256(result["state"].encode()).hexdigest() != result["hash"]:
                                raise ValueError(f"runner state/hash disagree: {case['id']}")
                            if not isinstance(result.get("trace"), list):
                                raise ValueError(f"runner missing uses trace: {case['id']}")
                            coverage["uses"].update(event["key"] for event in result["trace"])
                            cases_out.write(case_line)
                            results_out.write(line)
                            cover(case, card_tribes, generator, coverage)
                            accepted += 1
                    if lines != shard["count"]:
                        raise ValueError(f"incomplete runner output: {shard['output']}")
            attempted += size
            batch += 1
            cases_out.flush()
            results_out.flush()
            print(f"accepted={accepted} attempted={attempted} rejected={dict(rejected)}", flush=True)
            if attempted > max(1000, args.count * 2):
                raise RuntimeError("too many rejected candidates; inspect rejected.jsonl")
    elapsed = time.monotonic() - started
    total_us = sum(item["elapsed_us"] for item in timings)
    report.update(
        {
            "accepted": accepted,
            "attempted": attempted,
            "rejected": dict(rejected),
            "coverage": {name: dict(sorted(counts.items())) for name, counts in coverage.items()},
            "shards": timings,
            "wall_seconds": elapsed,
            "runner_elapsed_us": total_us,
            "runner_us_per_fight": total_us / attempted,
        }
    )
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(
        dump(
            {
                key: report[key]
                for key in ("accepted", "attempted", "rejected", "coverage", "wall_seconds", "runner_us_per_fight")
            }
        ),
        flush=True,
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, StopIteration) as error:
        print(f"make_cases: {error}", file=sys.stderr)
        sys.exit(1)
