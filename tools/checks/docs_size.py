"""Limit documentation blobs introduced by an explicit commit range.

Usage: python3 tools/checks/docs_size.py --base COMMIT [--head COMMIT] [--root DIR]
Every version introduced in base..head is checked, including files later shrunk or
deleted. Without --head, also check staged, unstaged and untracked files. Limits
use decimal MB; the aggregate counts each introduced blob once. Exact paths in
tools/checks/docs_size_allowlist.txt are exempt from both limits.
"""

from __future__ import annotations

import argparse
import subprocess
from dataclasses import dataclass
from pathlib import Path

FILE_LIMIT = 2_000_000
TOTAL_LIMIT = 30_000_000
ALLOWLIST = "tools/checks/docs_size_allowlist.txt"


@dataclass(frozen=True)
class Blob:
    path: str
    oid: str
    size: int


def git(root: Path, *args: str) -> bytes:
    return subprocess.run(["git", *args], cwd=root, capture_output=True, check=True).stdout


def changed_blobs(raw: bytes) -> set[tuple[str, str]]:
    """Read Git's NUL-delimited raw diff; renames must be disabled by the caller."""
    result = set()
    records = iter(raw.split(b"\0"))
    for metadata in records:
        if not metadata.strip():
            continue
        _old_mode, mode, _old_oid, oid, _status = metadata.split()
        path = next(records).decode()
        if mode in (b"100644", b"100755"):
            result.add((path, oid.decode()))
    return result


def candidates(root: Path, base: str, head: str | None) -> list[Blob]:
    """Return every new docs blob, preserving paths for exact allowlist checks."""
    base = git(root, "rev-parse", "--verify", f"{base}^{{commit}}").decode().strip()
    tip = git(root, "rev-parse", "--verify", f"{head or 'HEAD'}^{{commit}}").decode().strip()
    # Exclude all objects reachable from the base, rather than only its endpoint
    # tree: reusing an existing blob does not add bytes to repository history.
    baseline = set(git(root, "rev-list", "--objects", "--no-object-names", base).decode().splitlines())
    versions = changed_blobs(
        git(
            root,
            "log",
            "--full-history",
            "-m",
            "--format=",
            "--raw",
            "-z",
            "--no-abbrev",
            "--no-renames",
            f"{base}..{tip}",
            "--",
            "docs/",
        )
    )
    sizes = {}
    if head is None:
        # Keep index versions independently of the worktree, including staged
        # additions whose worktree copy has since been shrunk or removed.
        versions.update(
            changed_blobs(
                git(root, "diff", "--cached", "--raw", "-z", "--no-abbrev", "--no-renames", tip, "--", "docs/")
            )
        )
        working = {
            path.decode()
            for command in (
                ("diff", "--name-only", "--no-renames", "-z", tip, "--", "docs/"),
                ("ls-files", "--others", "--exclude-standard", "-z", "--", "docs/"),
            )
            for path in git(root, *command).split(b"\0")
            if path
        }
        for path in working:
            local = root / path
            if local.is_file() and not local.is_symlink():
                oid = git(root, "hash-object", "--no-filters", "--", path).decode().strip()
                versions.add((path, oid))
                sizes[oid] = local.stat().st_size
    selected = sorted((path, oid) for path, oid in versions if oid not in baseline)
    for _path, oid in selected:
        if oid not in sizes:
            sizes[oid] = int(git(root, "cat-file", "-s", oid))
    return [Blob(path, oid, sizes[oid]) for path, oid in selected]


def violations(blobs: list[Blob], allowlist: set[str]) -> list[str]:
    counted = [blob for blob in blobs if blob.path not in allowlist]
    errors = [
        f"{blob.path} ({blob.oid[:12]}): {blob.size:,} bytes exceeds {FILE_LIMIT:,}"
        for blob in counted
        if blob.size > FILE_LIMIT
    ]
    total = sum({blob.oid: blob.size for blob in counted}.values())
    if total > TOTAL_LIMIT:
        errors.append(f"introduced docs blobs total {total:,} bytes exceeds {TOTAL_LIMIT:,}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True, help="explicit start of the inspected range; never inferred")
    parser.add_argument("--head")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    try:
        blobs = candidates(args.root, args.base, args.head)
        allowfile = args.root / ALLOWLIST
        allowlist = (
            {
                line.strip()
                for line in allowfile.read_text().splitlines()
                if line.strip() and not line.lstrip().startswith("#")
            }
            if allowfile.exists()
            else set()
        )
        if any(not p.startswith("docs/") or "*" in p or ".." in p.split("/") for p in allowlist):
            raise ValueError(f"{ALLOWLIST}: overrides must be exact docs/ paths")
        errors = violations(blobs, allowlist)
    except (subprocess.CalledProcessError, ValueError, OSError) as error:
        print(f"docs-size: {error}")
        return 2
    for error in errors:
        print(f"docs-size: {error}")
    if errors:
        print(f"Compress evidence or explicitly allow its exact path in {ALLOWLIST}.")
    else:
        print("docs-size: passed (2 MB per introduced blob; 30 MB total distinct introduced blobs)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
