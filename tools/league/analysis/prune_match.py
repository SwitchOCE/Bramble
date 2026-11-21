#!/usr/bin/env python3
"""Apply the referee's retention policy to a completed, idle match."""
import argparse
from contextlib import contextmanager
import csv
import fcntl
import gzip
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
from tempfile import TemporaryDirectory

from cards import card_stats
from match_data import BANDS, Match, chosen_action
from tribes import final_tribes


BUILD_LIMIT = 2_000_000
VERDICT = "verdict.jsonl"
READING_FILES = (
    "summary.json", "library.json", "games.jsonl", "shops.jsonl", "decisions.jsonl",
    "cpu.jsonl", "events.jsonl",
)


def physical_path(path):
    absolute = Path(os.path.abspath(path))
    if Path(path).resolve() != absolute:
        raise ValueError(f"{absolute}: symbolic link in path")
    return absolute


@contextmanager
def lock_directory(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield fd
    finally:
        os.close(fd)


def checked_entries(root):
    """Reject indirect paths and nested mounts before touching a tree's files."""
    device = root.stat().st_dev
    mountinfo = Path("/proc/self/mountinfo")
    mounts = set()
    if mountinfo.is_file():
        for line in mountinfo.read_text().splitlines():
            mount = line.split()[4]
            mounts.add(Path(re.sub(r"\\([0-7]{3})", lambda m: chr(int(m[1], 8)), mount)))
    if root in mounts:
        raise ValueError(f"{root}: mount point")
    entries = sorted(root.rglob("*"))
    for entry in entries:
        if (entry.is_symlink() or entry in mounts or entry.stat().st_dev != device
                or not (entry.is_file() or entry.is_dir())):
            raise ValueError(f"{entry}: unsupported file, symbolic link or mount")
    return entries


def keep_only(root, root_fd, files):
    checked_entries(root)
    manifests = {root / "summary.json", root / "summary.json.gz"}
    protected = files | manifests
    kept_dirs = {parent for path in files for parent in path.parents}
    for directory, folders, names, fd in os.fwalk(".", topdown=False, dir_fd=root_fd):
        base = root / directory
        for name in names:
            if base / name not in protected:
                os.unlink(name, dir_fd=fd)
        for name in folders:
            if base / name not in kept_dirs:
                os.rmdir(name, dir_fd=fd)
    # Leave a completion marker in place until a partially pruned match can be retried safely.
    for manifest in sorted(manifests - files):
        try:
            os.unlink(manifest.name, dir_fd=root_fd)
        except FileNotFoundError:
            pass


def read_summary(root):
    plain = root / "summary.json"
    if plain.is_file():
        summary = json.loads(plain.read_bytes())
    else:
        with gzip.open(root / "summary.json.gz", "rb") as source:
            summary = json.load(source)
    if summary.get("schema") != 1 or summary.get("complete") is not True:
        raise ValueError(f"{root}: expected a completed schema 1 match")
    return summary


def climb(root, summary, verdict, cut_verified):
    if verdict == "kept" and not cut_verified:
        raise ValueError("kept version: cut and verify its ghosts, then pass --cut-verified")
    analysis = json.loads((root / "analysis.json").read_bytes())
    timing = root / "timing.json"
    score = analysis["score"]
    gap, half_width = score["gap_red_minus_blue"], score["gap_ci95"]
    games = summary["games"]
    if (not timing.is_file() or analysis["games"] != games or analysis["seed_pairs"] != (games + 1) // 2
            or any(analysis["bots"].get(team) != summary[team] for team in ("red", "blue"))
            or not math.isfinite(gap) or not math.isfinite(half_width) or half_width < 0
            or (games % 2 == 0 and not math.isclose(gap, summary["gap_red_minus_blue"], abs_tol=1e-9))):
        raise ValueError("need timing.json and current analysis.json from league analyze")
    line = {
        "red": summary.get("red_label", summary["red"]),
        "blue": summary.get("blue_label", summary["blue"]),
        "seeds_sha256": summary["seeds_sha256"],
        "games": games,
        "gap_red_minus_blue": gap,
        "gap_ci95": [gap - half_width, gap + half_width],
        "verdict": verdict,
    }
    destination = root / VERDICT
    if destination.exists() and json.loads(destination.read_bytes()) != line:
        raise ValueError("existing verdict disagrees with this result")
    with TemporaryDirectory(dir=root, prefix=".prune-") as staging:
        staged = Path(staging) / VERDICT
        staged.write_text(json.dumps(line, separators=(",", ":")) + "\n", encoding="utf-8")
        staged.replace(destination)
    return {root / name for name in ("summary.json", "analysis.json", "timing.json", VERDICT)}


def gzip_copy(source, destination):
    with source.open("rb") as raw, destination.open("wb") as output:
        subprocess.run(["gzip", "-n", "-c"], stdin=raw, stdout=output, check=True)


def trim_decisions(match, destination):
    with destination.open("wb") as target:
        command = ["gzip", "-n", "-c"]
        with subprocess.Popen(command, stdin=subprocess.PIPE, stdout=target) as gzip_process:
            for row in match.rows("decisions"):
                row["action"] = chosen_action(row)
                row.pop("legal", None)
                row.pop("chosen", None)
                line = json.dumps(row, separators=(",", ":"), ensure_ascii=False)
                gzip_process.stdin.write(line.encode() + b"\n")
            gzip_process.stdin.close()
            if gzip_process.wait():
                raise subprocess.CalledProcessError(gzip_process.returncode, command)


def reading(root, summary):
    match = Match(root)
    if (not summary.get("inline_reports") or not match.has_log("decisions")) and any(
            match.has_log(n) for n in ("reports", "discovers")):
        raise ValueError("analysis still uses standalone logs. Keep the match intact for reading or archive it as old-build")
    names = [Path(name) for name in READING_FILES]
    names.extend(p.relative_to(root) for p in (root / "records").glob("game-*.jsonl"))
    names.extend(p.relative_to(root).with_suffix("") for p in (root / "records").glob("game-*.jsonl.gz")
                 if not p.with_suffix("").exists())
    kept = set()
    with TemporaryDirectory(dir=root, prefix=".prune-") as staging:
        pending = []
        for name in names:
            plain = root / name
            compressed = plain.with_name(plain.name + ".gz")
            if not (plain.is_file() or compressed.is_file()):
                continue
            kept.add(compressed)
            staged = Path(staging) / name.with_name(name.name + ".gz")
            staged.parent.mkdir(parents=True, exist_ok=True)
            if name.name == "decisions.jsonl":
                trim_decisions(match, staged)
            elif compressed.is_file():
                continue
            else:
                gzip_copy(plain, staged)
            pending.append((staged, compressed))
        for staged, destination in pending:
            staged.replace(destination)
    return kept


def write_tables(root, stage):
    match = Match(root)
    cards = card_stats(match)
    with (stage / "cards.csv").open("w", newline="", encoding="utf-8") as target:
        writer = csv.writer(target, lineterminator="\n")
        writer.writerow(("team", "card", "round_band", "final_tribe", "purchases", "buyable_shops"))
        for team, by_card in cards.items():
            for card, data in sorted(by_card.items()):
                writer.writerow((team, card, "all", "all", data["buy"]["hits"], data["buy"]["count"]))
                for band in BANDS:
                    for tribe, stat in sorted(data["band_and_final_tribe"].get(band, {}).items()):
                        writer.writerow((team, card, band, tribe, stat["hits"], stat["count"]))
    with (stage / "tribes.csv").open("w", newline="", encoding="utf-8") as target:
        writer = csv.writer(target, lineterminator="\n")
        writer.writerow(("team", "final_tribe", "seats", "total_seats", "mean_place", "wins", "top4"))
        for team, tribes in final_tribes(match).items():
            for tribe, data in sorted(tribes.items()):
                writer.writerow((team, tribe, data["share"]["hits"], data["share"]["count"],
                                 data["placement"]["mean"], data["win"]["hits"], data["top4"]["hits"]))


def archive(root, summary, archive_dir, findings):
    rules_hash = summary["rules_hash"]
    if not re.fullmatch("[0-9a-f]{64}", rules_hash):
        raise ValueError("summary.json: invalid rules hash")
    build = physical_path(archive_dir / rules_hash)
    if root == build or root in build.parents or build in root.parents:
        raise ValueError("the match and build archive must be separate directories")
    if len({path.name for path in findings}) != len(findings):
        raise ValueError("findings must have distinct filenames")
    if any(not path.is_file() for path in findings):
        raise ValueError("--finding must name a regular file")

    build.mkdir(parents=True, exist_ok=True)
    destination = build / root.name
    with lock_directory(build):
        existing_bytes = sum(p.stat().st_size for p in checked_entries(build) if p.is_file())
        if destination.exists():
            if read_summary(destination) != summary or any(
                    not (destination / "findings" / p.name).is_file()
                    or (destination / "findings" / p.name).read_bytes() != p.read_bytes()
                    for p in findings):
                raise ValueError(f"{destination}: archive entry differs from this match or its findings")
            if any((root / ("games.jsonl" + suffix)).is_file() for suffix in ("", ".gz")) and not all(
                    (destination / name).is_file() for name in ("cards.csv", "tribes.csv")):
                raise ValueError(f"{destination}: archive entry is missing tables")
            if existing_bytes > BUILD_LIMIT:
                raise ValueError(f"{build}: existing archive exceeds {BUILD_LIMIT:,} bytes")
            return build
        findings_bytes = sum(path.stat().st_size for path in findings)
        with TemporaryDirectory(dir=root, prefix=".prune-") as staging:
            stage = Path(staging) / "match"
            stage.mkdir()
            (stage / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
            if (root / VERDICT).is_file():
                shutil.copyfile(root / VERDICT, stage / VERDICT)
            if any((root / ("games.jsonl" + suffix)).is_file() for suffix in ("", ".gz")):
                write_tables(root, stage)
            elif any(p.name in ("records", "shops.jsonl", "shops.jsonl.gz") for p in root.iterdir()):
                raise ValueError("missing games log for archive tables")
            total = existing_bytes + findings_bytes + sum(p.stat().st_size for p in stage.iterdir())
            if total > BUILD_LIMIT:
                raise ValueError(f"{build}: archive would be {total:,} bytes (limit {BUILD_LIMIT:,})")
            if findings:
                out = stage / "findings"
                out.mkdir()
                for path in findings:
                    shutil.copyfile(path, out / path.name)
                copied_bytes = sum(p.stat().st_size for p in out.iterdir())
                if total - findings_bytes + copied_bytes > BUILD_LIMIT:
                    raise ValueError(f"{build}: findings changed size and would exceed {BUILD_LIMIT:,} bytes")
            # Publish the complete entry before removing any source file.
            stage.rename(destination)
    return build


def prune(root, kind, *, verdict=None, cut_verified=False, archive_dir=None, findings=()):
    root = physical_path(root)
    with lock_directory(root) as root_fd:
        checked_entries(root)
        summary = read_summary(root)
        destination = root
        if kind == "climb":
            if verdict not in ("kept", "rejected"):
                raise ValueError("climb requires --verdict kept or rejected")
            files = climb(root, summary, verdict, cut_verified)
        elif kind == "reading":
            files = reading(root, summary)
        elif kind == "field":
            if not cut_verified:
                raise ValueError("field: cut and verify the ghosts, then pass --cut-verified")
            files = {root / "summary.json"}
        elif kind == "old-build":
            if archive_dir is None:
                raise ValueError("old-build requires --archive-dir")
            destination = archive(root, summary, Path(archive_dir), findings)
            files = set()
        else:
            raise ValueError(f"unknown match kind {kind}")
        if any(not path.is_file() for path in files):
            raise ValueError("missing file on the keep list")
        keep_only(root, root_fd, files)
        return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("match", type=Path)
    parser.add_argument("--kind", required=True, choices=("climb", "reading", "field", "old-build"))
    parser.add_argument("--verdict", choices=("kept", "rejected"), help="referee decision for climb")
    parser.add_argument("--cut-verified", action="store_true", help="confirm ghost cut and verify passed")
    parser.add_argument("--archive-dir", type=Path, help="parent of the per-build archives")
    parser.add_argument("--finding", type=Path, action="append", default=[], help="findings report to archive; repeatable")
    args = parser.parse_args()
    if args.verdict and args.kind != "climb":
        parser.error("--verdict applies to climb")
    if (args.archive_dir or args.finding) and args.kind != "old-build":
        parser.error("--archive-dir and --finding apply to old-build")
    try:
        kept = prune(args.match, args.kind, verdict=args.verdict, cut_verified=args.cut_verified,
                     archive_dir=args.archive_dir, findings=args.finding)
        print(f"Kept in {kept}")
        total = 0
        for path in sorted(kept.rglob("*")):
            if path.is_file():
                size = path.stat().st_size
                print(f"{size:>10,} B  {path.relative_to(kept)}")
                total += size
        print(f"{total:>10,} B  total")
    except (KeyError, TypeError, ValueError, OSError, subprocess.SubprocessError) as exc:
        parser.exit(1, f"prune_match: {exc}\n")


if __name__ == "__main__":
    main()
