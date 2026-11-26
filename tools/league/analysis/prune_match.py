#!/usr/bin/env python3
"""Apply the referee's retention policy to a completed, idle match."""
import argparse
import csv
import gzip
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from tempfile import TemporaryDirectory
from urllib.parse import quote

import marks
from cards import card_stats
from match_data import BANDS, Match, chosen_action, sale_eaters
from tribes import final_tribes


BUILD_LIMIT = 2_000_000
VERDICT = "verdict.jsonl"
CARD_REPORT = "card-report"  # written by tools/league/card_report.sh; small, and kept
READING_FILES = (
    "summary.json", "analysis.json", "library.json", "games.jsonl", "shops.jsonl", "decisions.jsonl",
    "cpu.jsonl", "events.jsonl",
)
TABLES = (
    ("cards.csv", ("team", "card", "round_band", "final_tribe", "purchases", "buyable_shops"), 4),
    ("tribes.csv", ("team", "final_tribe", "seats", "placement_sum", "wins", "top4"), 2),
)


def physical_path(path):
    absolute = Path(os.path.abspath(path))
    if Path(path).resolve() != absolute:
        raise ValueError(f"{absolute}: symbolic link in path")
    return absolute


def checked_entries(root):
    """Reject symlinks, other devices and special files before pruning."""
    device = root.stat().st_dev
    entries = sorted(root.rglob("*"))
    for entry in entries:
        if (entry.is_symlink() or entry.stat().st_dev != device
                or not (entry.is_file() or entry.is_dir())):
            raise ValueError(f"{entry}: unsupported file, symbolic link or device")
    return entries


def keep_only(root, files):
    checked_entries(root)
    manifests = {root / "summary.json", root / "summary.json.gz"}
    protected = files | manifests
    kept_dirs = {parent for path in files for parent in path.parents}
    for directory, folders, names, fd in os.fwalk(root, topdown=False):
        base = Path(directory)
        for name in names:
            if base / name not in protected:
                os.unlink(name, dir_fd=fd)
        for name in folders:
            if base / name not in kept_dirs:
                os.rmdir(name, dir_fd=fd)
    for manifest in sorted(manifests - files):
        manifest.unlink(missing_ok=True)


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


def card_report(root):
    return {path for path in (root / CARD_REPORT).rglob("*") if path.is_file()}


def climb(root, summary, verdict, cut_verified, ledger=marks.LEDGER):
    if verdict == "kept" and not cut_verified:
        raise ValueError("kept version: cut and verify its ghosts, then pass --cut-verified")
    if verdict == "kept" and not (root / CARD_REPORT / "cards.csv").is_file():
        raise ValueError("kept version: run tools/league/card_report.sh on the match first (it needs the records)")
    if verdict == "kept" and (waiting := marks.unheld(root / CARD_REPORT, ledger)):
        names = ", ".join(name for _, _, name, _ in waiting)
        raise ValueError(f"kept version: {len(waiting)} marks have no row in the ledger ({ledger}): {names}. "
                         "Add a row for each (python3 marks.py <match>/card-report lists them), then prune")
    files = {root / name for name in ("summary.json", "analysis.json", "timing.json")}
    if any(not path.is_file() for path in files):
        raise ValueError("climb requires summary.json, timing.json and analysis.json from league analyze")
    files |= card_report(root)
    score = json.loads((root / "analysis.json").read_bytes())["score"]
    gap, half_width = score["gap_red_minus_blue"], score["gap_ci95"]
    line = {
        "red": summary.get("red_label", summary["red"]),
        "blue": summary.get("blue_label", summary["blue"]),
        "seeds_sha256": summary["seeds_sha256"],
        "games": summary["games"],
        "gap_red_minus_blue": gap,
        "gap_ci95": [gap - half_width, gap + half_width],
        "verdict": verdict,
    }
    destination = root / VERDICT
    with TemporaryDirectory(dir=root, prefix=".prune-") as staging:
        staged = Path(staging) / VERDICT
        staged.write_text(json.dumps(line, separators=(",", ":")) + "\n", encoding="utf-8")
        staged.replace(destination)
    return files | {destination}


def gzip_copy(source, destination):
    with source.open("rb") as raw, destination.open("wb") as output:
        subprocess.run(["gzip", "-n", "-c"], stdin=raw, stdout=output, check=True)


def trim_decisions(match, destination):
    with destination.open("wb") as target:
        command = ["gzip", "-n", "-c"]
        with subprocess.Popen(command, stdin=subprocess.PIPE, stdout=target) as gzip_process:
            for row in match.rows("decisions"):
                action = row["action"] = chosen_action(row)
                if "legal" in row and action["type"] == "sell" and not row["result"]:
                    row["sale_eaters"] = sale_eaters(row, action)
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
    return kept | card_report(root)


def read_table(path, columns, dimensions):
    with path.open(newline="", encoding="utf-8") as source:
        rows = csv.reader(source)
        if tuple(next(rows, ())) != columns:
            raise ValueError(f"{path}: unexpected CSV columns")
        return {tuple(row[:dimensions]): tuple(map(int, row[dimensions:])) for row in rows}


def match_tables(root):
    tables = [root / name for name, _, _ in TABLES]
    if all(path.is_file() for path in tables):
        return [read_table(root / name, columns, dimensions) for name, columns, dimensions in TABLES]
    if any(path.exists() for path in tables):
        raise ValueError(f"{root}: expected both retained tables")
    if not any((root / name).is_file() for name in ("games.jsonl", "games.jsonl.gz")):
        if any((root / name).exists() for name in ("records", "shops.jsonl", "shops.jsonl.gz")):
            raise ValueError(f"{root}: missing games log for the tables")
        return []

    match = Match(root)
    cards = {}
    for team, by_card in card_stats(match).items():
        for card, data in by_card.items():
            cards[team, card, "all", "all"] = data["buy"]["hits"], data["buy"]["count"]
            for band in BANDS:
                for tribe, stat in data["band_and_final_tribe"].get(band, {}).items():
                    cards[team, card, band, tribe] = stat["hits"], stat["count"]
    tribes = {}
    for team, by_tribe in final_tribes(match).items():
        for tribe, data in by_tribe.items():
            seats = data["share"]["hits"]
            place_sum = round(data["placement"]["mean"] * seats) if seats else 0
            tribes[team, tribe] = seats, place_sum, data["win"]["hits"], data["top4"]["hits"]
    return [cards, tribes]


def merge_tables(stage, tables):
    for (name, columns, dimensions), incoming in zip(TABLES, tables):
        path = stage / name
        totals = read_table(path, columns, dimensions) if path.exists() else {}
        for key, counts in incoming.items():
            if key in totals:
                counts = tuple(a + b for a, b in zip(totals[key], counts, strict=True))
            totals[key] = counts
        with path.open("w", newline="", encoding="utf-8") as target:
            writer = csv.writer(target, lineterminator="\n")
            writer.writerow(columns)
            writer.writerows((*key, *counts) for key, counts in sorted(totals.items()))


def finding_paths(root, supplied):
    paths = {}
    for path in (*sorted((root / "findings").glob("*")), *supplied):
        if not path.is_file():
            raise ValueError(f"{path}: expected a findings file")
        if path.name in paths and path.resolve() != paths[path.name].resolve():
            raise ValueError(f"{path.name}: findings must have distinct filenames")
        paths[path.name] = path
    return paths.values()


def write_summary(path, summary):
    path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


def copy_analysis(root, destination):
    plain = root / "analysis.json"
    compressed = root / "analysis.json.gz"
    if plain.is_file():
        shutil.copyfile(plain, destination)
    elif compressed.is_file():
        with gzip.open(compressed, "rb") as source, destination.open("wb") as target:
            shutil.copyfileobj(source, target)


def reading_done(root, summary, supplied):
    findings = finding_paths(root, supplied)
    if not findings:
        raise ValueError("reading-done requires a findings report (--finding FILE)")
    with TemporaryDirectory(dir=root, prefix=".prune-") as staging:
        stage = Path(staging)
        copy_analysis(root, stage / "analysis.json")
        if not (stage / "analysis.json").is_file():
            raise ValueError("reading-done requires analysis.json from league analyze; run it before reading prune")
        tables = match_tables(root)
        if not tables:
            raise ValueError("reading-done requires match logs or retained CSV tables")
        merge_tables(stage, tables)
        write_summary(stage / "summary.json", summary)
        (stage / "findings").mkdir()
        for path in findings:
            shutil.copyfile(path, stage / "findings" / path.name)
        files = set()
        for path in sorted(p for p in stage.rglob("*") if p.is_file()):
            destination = root / path.relative_to(stage)
            destination.parent.mkdir(exist_ok=True)
            path.replace(destination)
            files.add(destination)
        return files


def archive(root, summary, archive_dir, supplied):
    rules_hash = summary["rules_hash"]
    if not re.fullmatch("[0-9a-f]{64}", rules_hash):
        raise ValueError("summary.json: invalid rules hash")
    build = physical_path(archive_dir / rules_hash)
    if root == build or root in build.parents or build in root.parents:
        raise ValueError("the match and build archive must be separate directories")
    backup = root / ".previous-build-archive"
    if backup.exists():
        raise ValueError(f"{backup}: interrupted archive publication; check the archive and backup before pruning")
    label = quote(root.name, safe="")
    manifest = f"{label}.summary.json"
    if build.exists():
        if any(p.is_dir() for p in checked_entries(build)):
            raise ValueError(f"{build}: expected a flat build archive")
        if (build / manifest).exists():
            raise ValueError(f"{build}: match name already archived: {root.name}")
    findings = finding_paths(root, supplied)
    with TemporaryDirectory(dir=root, prefix=".prune-") as staging:
        stage = Path(staging) / "build"
        if build.exists():
            shutil.copytree(build, stage)
        else:
            stage.mkdir()
        merge_tables(stage, match_tables(root))
        write_summary(stage / manifest, summary)
        if (root / VERDICT).is_file():
            with (stage / "verdicts.jsonl").open("a", encoding="utf-8") as out:
                for line in (root / VERDICT).read_text(encoding="utf-8").splitlines():
                    out.write(json.dumps(dict(json.loads(line), match=root.name), separators=(",", ":")) + "\n")
        for path in findings:
            name = f"{label}+{quote(path.name, safe='')}.gz"
            gzip_copy(path, stage / name)
        total = sum(p.stat().st_size for p in stage.iterdir())
        if total > BUILD_LIMIT:
            raise ValueError(f"{build}: archive would be {total:,} bytes (limit {BUILD_LIMIT:,}). "
                             "The source match and existing archive are intact.")
        # Keep the previous archive inside the match until the replacement is published.
        build.parent.mkdir(parents=True, exist_ok=True)
        try:
            if build.exists():
                build.rename(backup)
            stage.rename(build)
        except BaseException:
            if backup.exists() and not build.exists():
                backup.rename(build)
            raise
    return build


def prune(root, kind, *, verdict=None, cut_verified=False, archive_dir=None, findings=(), ledger=marks.LEDGER):
    root = physical_path(root)
    checked_entries(root)
    summary = read_summary(root)
    destination = root
    if kind == "climb":
        if verdict not in ("kept", "rejected"):
            raise ValueError("climb requires --verdict kept or rejected")
        files = climb(root, summary, verdict, cut_verified, ledger)
    elif kind == "reading":
        files = reading(root, summary)
    elif kind == "reading-done":
        files = reading_done(root, summary, findings)
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
    keep_only(root, files)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("match", type=Path)
    parser.add_argument("--kind", required=True, choices=("climb", "reading", "reading-done", "field", "old-build"))
    parser.add_argument("--verdict", choices=("kept", "rejected"), help="referee decision for climb")
    parser.add_argument("--cut-verified", action="store_true", help="confirm ghost cut and verify passed")
    parser.add_argument("--archive-dir", type=Path, help="parent of the per-build archives")
    parser.add_argument("--ledger", type=Path, default=marks.LEDGER, help="the ledger of marks a kept version is checked against")
    parser.add_argument("--finding", type=Path, action="append", default=[], help="findings report to keep, repeatable")
    args = parser.parse_args()
    if args.verdict and args.kind != "climb":
        parser.error("--verdict applies to climb")
    if args.archive_dir and args.kind != "old-build":
        parser.error("--archive-dir applies to old-build")
    if args.finding and args.kind not in ("reading-done", "old-build"):
        parser.error("--finding applies to reading-done and old-build")
    try:
        kept = prune(args.match, args.kind, verdict=args.verdict, cut_verified=args.cut_verified,
                     archive_dir=args.archive_dir, findings=args.finding, ledger=args.ledger)
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
