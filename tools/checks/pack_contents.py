"""Checks that an exported pack holds the project's data, not just its scenes and scripts.

  python3 tools/checks/pack_contents.py <listing> <project dir>

<listing> is the pack's file list, one res-relative path per line (tools/checks/pck_files.gd
prints it). <project dir> is the project that was exported: a clean copy of a commit (scripts/build_windows.sh
makes one with git archive). Every file in it outside the export preset's excluded folders and
hidden folders such as .godot must reach the pack:
  - data files the game reads as raw text (JSON, CSV, TXT) must be in the pack as they are
    (export_presets.cfg names them in include_filter, so this checks that stays true);
  - an imported file (art, fonts) must have its .import file and an imported copy it names;
  - the main scene must be there, and nothing from the development-only folders.
Exit 0 when all of that holds; otherwise prints each missing file and exits 1.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Mirrors exclude_filter in export_presets.cfg: these folders never ship.
EXCLUDED_DIRS = ("tests/", "tools/", "scripts/", "docs/", "build/", "addons/gut/")
# Read with FileAccess at run time, so they must be packed byte for byte.
RAW_DATA = {".json", ".csv", ".txt"}
MAIN_SCENE = re.compile(r"^src/main/main\.tscn(\.remap)?$")
DEST_FILES = re.compile(r"^dest_files=\[(.*)\]", re.MULTILINE)


def project_files(project: Path) -> list[str]:
    """Every file in the project, as res-relative paths."""
    return [p.relative_to(project).as_posix() for p in project.rglob("*") if p.is_file()]


def shipped(path: str) -> bool:
    """A path the export should carry: inside a folder, and not in an excluded one."""
    return "/" in path and not path.startswith(EXCLUDED_DIRS) and not path.startswith(".")


def missing_files(listing: set[str], project: Path, files: list[str]) -> list[str]:
    problems = []
    if not any(MAIN_SCENE.match(p) for p in listing):
        problems.append("the main scene (src/main/main.tscn)")
    problems += [f"{p} (development-only folder)" for p in sorted(listing) if p.startswith(EXCLUDED_DIRS)]
    for path in sorted(f for f in files if f and shipped(f)):
        if Path(path).suffix.lower() in RAW_DATA and path not in listing:
            problems.append(f"{path} (data file)")
        elif path.endswith(".import"):
            if path not in listing:
                problems.append(f"{path} (import record)")
            text = (project / path).read_text(encoding="utf-8")
            match = DEST_FILES.search(text)
            dests = re.findall(r'"res://([^"]+)"', match.group(1)) if match else []
            if dests and not any(d in listing for d in dests):
                problems.append(f"{path.removesuffix('.import')} (imported copy {dests[0]})")
    return problems


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[2])
        return 2
    listing = {line.strip() for line in Path(argv[0]).read_text(encoding="utf-8").splitlines() if line.strip()}
    project = Path(argv[1])
    problems = missing_files(listing, project, project_files(project))
    for problem in problems:
        print(f"pack lacks {problem}")
    if problems:
        return 1
    data = sum(1 for p in listing if Path(p).suffix.lower() in RAW_DATA)
    print(f"pack ok: {len(listing)} files, {data} data files, main scene, no development folders")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
