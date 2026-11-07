#!/usr/bin/env python3
"""Fails when a toolchain pin drifts from tools/versions.env, the one place versions are pinned.

Checks:
- scripts/cloud-setup.sh carries a verbatim copy of tools/versions.env between its markers
  (the script is pasted into the cloud environment UI, so it cannot read the repo copy);
- project.godot's config/features names the pinned Godot major.minor;
- the vendored GUT (addons/gut/plugin.cfg) is the pinned version;
- no script, workflow or setup doc spells out a pinned value itself instead of reading the file.

Usage: python3 tools/checks/versions.py [repo root]. Exit 0 = no drift, 1 = drift (listed).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

VERSIONS = Path("tools/versions.env")
SETUP_SCRIPT = Path("scripts/cloud-setup.sh")
BEGIN_MARKER = "# >>> tools/versions.env"
END_MARKER = "# <<< tools/versions.env"
# Files that must read pins from tools/versions.env rather than repeat them.
NO_LITERAL_PINS = ("scripts", ".github", ".claude", "docs/CLOUD_SETUP.md", "export_presets.cfg")
# Keys whose values are distinctive enough to search for as literals.
LITERAL_KEYS = (
    "GODOT_VERSION",
    "GODOT_LINUX_SHA512",
    "GODOT_TEMPLATES_SHA512",
    "GUT_VERSION",
    "GDTOOLKIT_VERSION",
    "RUFF_VERSION",
    "ANDROID_CMDLINE_TOOLS_BUILD",
    "ANDROID_CMDLINE_TOOLS_SHA256",
    "ANDROID_BUILD_TOOLS",
)


def parse_env(text: str) -> dict[str, str]:
    """KEY=VALUE lines; blank lines and # comments are skipped."""
    pins: dict[str, str] = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, sep, value = line.partition("=")
        if not sep:
            raise ValueError(f"not KEY=VALUE: {line!r}")
        pins[key.strip()] = value.strip()
    return pins


def setup_block(text: str) -> str | None:
    """The lines between the versions markers in the setup script, or None if absent."""
    lines = text.splitlines(keepends=True)
    try:
        start = next(i for i, line in enumerate(lines) if line.startswith(BEGIN_MARKER))
        end = next(i for i, line in enumerate(lines) if line.startswith(END_MARKER))
    except StopIteration:
        return None
    return "".join(lines[start + 1 : end]) if end > start else None


def literal_hits(root: Path, pins: dict[str, str]) -> list[str]:
    """Pinned values spelled out in files that should read tools/versions.env."""
    values = {key: pins[key] for key in LITERAL_KEYS if key in pins}
    files: list[Path] = []
    for entry in NO_LITERAL_PINS:
        path = root / entry
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            files.extend(p for p in sorted(path.rglob("*")) if p.is_file())
    hits: list[str] = []
    for path in files:
        rel = path.relative_to(root).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if rel == SETUP_SCRIPT.as_posix():
            block = setup_block(text) or ""
            text = text.replace(block, "")
        for key, value in values.items():
            if re.search(rf"(?<![\w.]){re.escape(value)}(?![\w.])", text):
                hits.append(f"{rel} spells out {key}={value}; read it from {VERSIONS.as_posix()}")
    return hits


def check(root: Path) -> list[str]:
    """Every drift problem found under root, as one line each."""
    problems: list[str] = []
    versions_text = (root / VERSIONS).read_text(encoding="utf-8")
    pins = parse_env(versions_text)

    setup_text = (root / SETUP_SCRIPT).read_text(encoding="utf-8")
    block = setup_block(setup_text)
    if block is None:
        problems.append(f"{SETUP_SCRIPT.as_posix()} lacks the '{BEGIN_MARKER}' ... '{END_MARKER}' block")
    elif block != versions_text:
        problems.append(
            f"{SETUP_SCRIPT.as_posix()}: the block between its markers differs from {VERSIONS.as_posix()}; "
            "paste the file in again, then re-paste the script into the cloud environment"
        )

    godot = pins.get("GODOT_VERSION", "")
    major_minor = ".".join(godot.split(".")[:2])
    features = re.search(r"^config/features=PackedStringArray\((.*)\)$", _read(root, "project.godot"), re.M)
    if not features or f'"{major_minor}"' not in features.group(1):
        problems.append(f'project.godot config/features does not name "{major_minor}" (GODOT_VERSION={godot})')

    gut = re.search(r'^version="([^"]+)"$', _read(root, "addons/gut/plugin.cfg"), re.M)
    if not gut or gut.group(1) != pins.get("GUT_VERSION"):
        found = gut.group(1) if gut else "none"
        problems.append(f"addons/gut is GUT {found}, tools/versions.env pins {pins.get('GUT_VERSION')}")

    problems.extend(literal_hits(root, pins))
    return problems


def _read(root: Path, rel: str) -> str:
    path = root / rel
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path(__file__).resolve().parents[2]
    problems = check(root)
    for line in problems:
        print(f"versions: {line}")
    if problems:
        return 1
    print("versions: ok (no drift from tools/versions.env)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
