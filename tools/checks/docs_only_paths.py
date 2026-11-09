"""Which changes need the Godot steps of the gate (used by check.sh --docs-only).

    python3 tools/checks/docs_only_paths.py <base-commit> [repo-root]

Collects every path changed since <base-commit>, committed, staged, unstaged or untracked, and
prints each one that needs the Godot steps, with the reason. Exits 1 if any does, 0 if none do.

A path needs the Godot steps when it is outside docs/, when it is a .gdignore under docs/
(removing one makes Godot import that folder), or when the game code or the GUT tests read it
through a res://docs/ path (fixtures, engine.md and the like). Renames count on both sides, so
a file moved from src/ into docs/ still counts as a src/ change.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

READ_BY = ("src/**/*.gd", "tests/**/test_*.gd", "tools/checks/**/*.gd")
RES_DOCS = re.compile(r"res://(docs/[^\"'\s]*)")


def changed_paths(root: Path, base: str) -> set[str]:
    """Paths changed since base: commits, the index, the working tree and untracked files."""
    commands = (
        ["git", "diff", "-z", "--name-only", "--no-renames", base, "HEAD"],
        ["git", "diff", "-z", "--name-only", "--no-renames", "HEAD"],
        ["git", "diff", "-z", "--name-only", "--no-renames", "--cached", "HEAD"],
        ["git", "ls-files", "-z", "--others", "--exclude-standard"],
    )
    paths: set[str] = set()
    for command in commands:
        out = subprocess.run(command, cwd=root, capture_output=True, text=True, check=True).stdout
        paths.update(p for p in out.split("\0") if p)
    return paths


def docs_read_by_code(root: Path) -> set[str]:
    """Every docs/ path or folder prefix that gated GDScript names as res://docs/..."""
    found: set[str] = set()
    for pattern in READ_BY:
        for script in root.glob(pattern):
            text = script.read_text(encoding="utf-8", errors="replace")
            found.update(match.group(1) for match in RES_DOCS.finditer(text))
    return found


def needs_godot(path: str, read_by_code: set[str]) -> str | None:
    """The reason this path needs the Godot steps, or None if docs-only checks are enough."""
    if not path.startswith("docs/"):
        return "outside docs/"
    if path.rsplit("/", 1)[-1] == ".gdignore":
        return "a .gdignore (it controls what Godot imports)"
    for prefix in sorted(read_by_code):
        if path.startswith(prefix):
            return f"read by the game or tests (res://{prefix})"
    return None


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    root = Path(argv[2]) if len(argv) > 2 else Path.cwd()
    read_by_code = docs_read_by_code(root)
    flagged = []
    for path in sorted(changed_paths(root, argv[1])):
        reason = needs_godot(path, read_by_code)
        if reason is not None:
            flagged.append(f"{path}: {reason}")
    print("\n".join(flagged))
    return 1 if flagged else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
