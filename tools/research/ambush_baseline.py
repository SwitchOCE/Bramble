#!/usr/bin/env python3
"""Export the frozen brief-6 content, without changing tracked content or Git history.

Run: python3 tools/research/ambush_baseline.py
Then: godot --headless -s res://tools/checks/power_check.gd -- --cards res://build/ambush-baseline
For the quarter version: python3 tools/research/ambush_baseline.py --quarter
Then use -- --cards res://build/ambush-quarter with the same Godot driver.
Reads only fixed refs: original 2e0b9081, quarter 20e85db2. Writes .gd/.json files only
under the selected ignored build directory; it never deletes existing files.
The current combat core loads these scripts for reproducible historical comparisons.
"""

import argparse
import subprocess
from pathlib import Path

TRIBES = ("mouse", "pigeon", "shared")
ROOT = Path(__file__).resolve().parents[2]


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quarter", action="store_true", help="export frozen quarter-Attack content")
    args = parser.parse_args()
    ref = "20e85db2" if args.quarter else "2e0b9081"
    destination = "ambush-quarter" if args.quarter else "ambush-baseline"
    dest = ROOT / "build" / destination
    paths = git("ls-tree", "-r", "--name-only", ref, "--", *(f"src/content/{t}" for t in TRIBES))
    copied = 0
    for name in paths.decode().splitlines():
        source = Path(name)
        if source.suffix not in {".gd", ".json"}:
            continue
        relative = source.relative_to("src/content")
        if relative.parts[0] not in TRIBES or ".." in relative.parts:
            raise ValueError(f"unexpected source path: {name}")
        data = git("show", f"{ref}:{name}")
        if len(data) > 256 * 1024:
            raise ValueError(f"expected small content file: {name}")
        if source.suffix == ".gd":
            for tribe in TRIBES:
                data = data.replace(
                    f"res://src/content/{tribe}/".encode(),
                    f"res://build/{destination}/{tribe}/".encode(),
                )
        target = dest / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        copied += 1
    print(f"Exported {copied} files from {ref} to {dest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
