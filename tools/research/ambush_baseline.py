#!/usr/bin/env python3
"""Export the frozen brief-6 content, without changing tracked content or Git history.

Run: python3 tools/research/ambush_baseline.py
Then: godot --headless -s res://tools/checks/power_check.gd -- --cards res://build/ambush-baseline
Only reads ref 2e0b9081 and writes .gd/.json files beneath ignored build/ambush-baseline.
The current combat core loads these historical scripts for the old full-card comparison.
"""

import subprocess
from pathlib import Path

REF = "2e0b9081"
TRIBES = ("mouse", "pigeon", "shared")
ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "build" / "ambush-baseline"


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def main() -> None:
    paths = git("ls-tree", "-r", "--name-only", REF, "--", *(f"src/content/{t}" for t in TRIBES))
    copied = 0
    for name in paths.decode().splitlines():
        source = Path(name)
        if source.suffix not in {".gd", ".json"}:
            continue
        relative = source.relative_to("src/content")
        if relative.parts[0] not in TRIBES or ".." in relative.parts:
            raise ValueError(f"unexpected source path: {name}")
        data = git("show", f"{REF}:{name}")
        if len(data) > 256 * 1024:
            raise ValueError(f"expected small content file: {name}")
        if source.suffix == ".gd":
            for tribe in TRIBES:
                data = data.replace(
                    f"res://src/content/{tribe}/".encode(),
                    f"res://build/ambush-baseline/{tribe}/".encode(),
                )
        target = DEST / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        copied += 1
    print(f"Exported {copied} files from {REF} to {DEST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
