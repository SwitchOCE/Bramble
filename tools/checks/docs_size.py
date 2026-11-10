"""Limit documentation blobs introduced by a commit range or the current worktree.

Usage: python3 tools/checks/docs_size.py [--base COMMIT] [--head COMMIT] [--root DIR]
The default base is the upstream merge-base, or the previous commit without an upstream. Without --head,
include staged, unstaged and untracked files. Limits use decimal MB. Exact paths in
 tools/checks/docs_size_allowlist.txt are exempt from both limits (one path per line).
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

FILE_LIMIT = 2_000_000
TOTAL_LIMIT = 30_000_000
ALLOWLIST = "tools/checks/docs_size_allowlist.txt"


def git(root: Path, *args: str) -> bytes:
    return subprocess.run(["git", *args], cwd=root, capture_output=True, check=True).stdout


def default_base(root: Path) -> str:
    try:
        return git(root, "merge-base", "HEAD", "@{upstream}").decode().strip()
    except subprocess.CalledProcessError:
        try:
            git(root, "rev-parse", "--verify", "HEAD^")
        except subprocess.CalledProcessError:
            return "HEAD"
        return "HEAD^"


def tree(root: Path, revision: str) -> dict[str, int]:
    result = {}
    for record in git(root, "ls-tree", "-rlz", revision, "--", "docs/").split(b"\0"):
        if record:
            metadata, path = record.split(b"\t", 1)
            mode, kind, _oid, size = metadata.split()
            if kind == b"blob" and mode != b"120000":
                result[path.decode()] = int(size)
    return result


def candidates(root: Path, base: str, head: str | None) -> tuple[dict[str, int], set[str]]:
    """Return changed files' maximum sizes, and paths absent from the base tree."""
    baseline = tree(root, base)
    tip = head or "HEAD"
    sizes = tree(root, tip)
    changed = {
        path.decode()
        for path in git(root, "diff", "--name-only", "--no-renames", "-z", base, tip, "--", "docs/").split(b"\0")
        if path
    }
    if head is None:
        staged = {
            p.decode()
            for p in git(root, "diff", "--cached", "--name-only", "--no-renames", "-z", "HEAD", "--", "docs/").split(
                b"\0"
            )
            if p
        }
        working = {
            p.decode()
            for command in (
                ("diff", "--name-only", "--no-renames", "-z", "HEAD", "--", "docs/"),
                ("ls-files", "--others", "--exclude-standard", "-z", "--", "docs/"),
            )
            for p in git(root, *command).split(b"\0")
            if p
        }
        changed.update(staged | working)
        for path in staged | working:
            sizes.pop(path, None)
            local = root / path
            if local.is_file() and not local.is_symlink():
                sizes[path] = local.stat().st_size
        # An oversized staged blob must not hide behind a smaller worktree copy.
        for record in git(root, "ls-files", "-s", "-z", "--", "docs/").split(b"\0"):
            if not record:
                continue
            metadata, encoded_path = record.split(b"\t", 1)
            path = encoded_path.decode()
            if path not in staged:
                continue
            mode, oid, stage = metadata.split()
            if stage == b"0" and mode != b"120000":
                size = int(git(root, "cat-file", "-s", oid.decode()))
                sizes[path] = max(sizes.get(path, 0), size)
    selected = {p: sizes[p] for p in changed if p in sizes}
    return selected, selected.keys() - baseline.keys()


def violations(sizes: dict[str, int], added: set[str], allowlist: set[str]) -> list[str]:
    counted = {p: size for p, size in sizes.items() if p not in allowlist}
    errors = [f"{p}: {size:,} bytes exceeds {FILE_LIMIT:,}" for p, size in sorted(counted.items()) if size > FILE_LIMIT]
    total = sum(size for p, size in counted.items() if p in added)
    if total > TOTAL_LIMIT:
        errors.append(f"new docs files total {total:,} bytes exceeds {TOTAL_LIMIT:,}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base")
    parser.add_argument("--head")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    try:
        sizes, added = candidates(args.root, args.base or default_base(args.root), args.head)
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
        errors = violations(sizes, added, allowlist)
    except (subprocess.CalledProcessError, ValueError, OSError) as error:
        print(f"docs-size: {error}")
        return 2
    for error in errors:
        print(f"docs-size: {error}")
    if errors:
        print(f"Compress evidence or explicitly allow its exact path in {ALLOWLIST}.")
    else:
        print("docs-size: passed (2 MB per changed file; 30 MB total new files)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
