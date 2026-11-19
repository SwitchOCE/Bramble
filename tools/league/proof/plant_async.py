#!/usr/bin/env python3
"""Prove Rust reports a swapped run and rejects changed bytes before turn one."""

import json
import shutil
import subprocess
import sys
from pathlib import Path


def check(bin_path, record, store, message):
    result = subprocess.run(
        [bin_path, "replay", "--record", record, "--ghost-store", store],
        capture_output=True,
        text=True,
        check=False,
    )
    print(result.stderr.strip())
    if result.returncode != 1 or result.stderr.strip() != message:
        sys.exit(f"expected replay to fail with {message!r}")


def first_payload(path):
    run = json.loads(path.read_bytes())
    payload = next(turn["payload"] for turn in run["turns"] if turn["turn"] == 1)
    del payload["id"]
    return payload


def main():
    bin_path, store, out = map(Path, sys.argv[1:])
    records = sorted((out / "async-godot").glob("*.jsonl"))
    if not records:
        sys.exit("no Godot async records for the planted checks")
    record = records[0]
    header_line, body = record.read_bytes().split(b"\n", 1)
    header = json.loads(header_line)
    run_files = {path.stem: path for path in (store / "runs").glob("*/*.json")}
    live_ids = {entry["id"] for entry in header["runs"]}
    spare_ids = sorted(run_files.keys() - live_ids)
    if not spare_ids:
        sys.exit("need a spare run for the planted swap")
    spare_id = spare_ids[0]
    spare_payload = first_payload(run_files[spare_id])
    seat = next(
        (entry for entry in header["runs"] if first_payload(run_files[entry["id"]]) != spare_payload),
        None,
    )
    if seat is None:
        sys.exit("the spare run needs a different turn-one payload")
    original_id = seat["id"]
    seat["id"] = spare_id
    planted = out / "async-planted"
    planted.mkdir(exist_ok=True)
    swapped = planted / "swapped.jsonl"
    swapped.write_bytes(json.dumps(header).encode() + b"\n" + body)
    check(bin_path, swapped, store, "first differing turn 1: fight boards differ")

    changed_store = planted / "store"
    shutil.copytree(store, changed_store, dirs_exist_ok=True)
    changed = changed_store / run_files[original_id].relative_to(store)
    # A change to whitespace keeps the JSON valid and changes exactly one byte.
    content = changed.read_bytes()
    assert content.endswith(b"\n")
    changed.write_bytes(content[:-1] + b" ")
    check(bin_path, record, changed_store, f"first differing turn 0: run {original_id}: SHA-256 mismatch")
    print("async-planted: swap and byte change caught")


if __name__ == "__main__":
    main()
