#!/usr/bin/env python3
"""The ledger of marks: which cards and keywords a card report marked, and who holds each.

    python3 marks.py REPORT_DIR [--ledger FILE]   marks in a card report that the ledger does not hold
    python3 marks.py --stale [--ledger FILE] [--today YYYY-MM-DD]   rows nobody has acted on

The ledger is docs/workstreams/balance/marks.csv, one row per marked card or keyword. A mark is
"held" when the ledger has a row for the subject that lists the measure. A card marked again by
a measure its row already lists stays as it is; a new measure on it is a new mark.
Exits 1 when it prints any mark or row, so a gate can use it. Who acts on a mark:
docs/workstreams/balance/plan.md.
"""
import argparse
import csv
import datetime
import sys
from pathlib import Path

from card_summary import KEYWORD_FLOOR, table

LEDGER = Path(__file__).resolve().parents[3] / "docs/workstreams/balance/marks.csv"
COLUMNS = ("subject", "kind", "name", "measures", "first_marked", "state", "holder", "since", "note")
STATES = ("new", "explained", "with the owner", "held by the owner", "change picked", "changed", "measured again")
STALE_DAYS = {"new": 1, "with the owner": 3}  # days in a state before the morning check says so


def measures(text):
    """'text (5-8); growth (13+)' -> {'text', 'growth'}: the measure, without stage or bot."""
    return {part.split(" (")[0].strip() for part in text.split(";") if part.strip()}


def report_marks(report):
    """subject -> (kind, name, measures) for every card and keyword the report marks."""
    marks = {}
    for row in table(Path(report) / "cards.csv"):
        if row["worth a look"]:
            marks[row["card"]] = ("card", row["name"], measures(row["worth a look"]))
    for row in table(Path(report) / "keywords.csv"):
        if row["status"] == "ok" and row["enemy_health"] == "all" and float(row["keyword_value"]) >= KEYWORD_FLOOR:
            marks[row["keyword"]] = ("keyword", row["keyword"], {"keyword off"})
    return marks


def read_ledger(path):
    rows = table(Path(path))
    for row in rows:
        if row["state"] not in STATES:
            raise ValueError(f"{path}: {row['subject']}: state {row['state']!r} is not one of {', '.join(STATES)}")
    return {row["subject"]: row for row in rows}


def unheld(report, ledger):
    """[(subject, kind, name, measures not in the ledger)], for marks the ledger does not hold."""
    held = read_ledger(ledger)
    out = []
    for subject, (kind, name, marked) in sorted(report_marks(report).items()):
        missing = marked - measures(held[subject]["measures"]) if subject in held else marked
        if missing:
            out.append((subject, kind, name, sorted(missing)))
    return out


def stale(ledger, today):
    """Rows in a state that waits on someone, for longer than STALE_DAYS."""
    out = []
    for row in read_ledger(ledger).values():
        limit = STALE_DAYS.get(row["state"])
        if limit is None:
            continue
        days = (today - datetime.date.fromisoformat(row["since"])).days
        if days > limit:
            out.append((row, days))
    return out


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("report", nargs="?")
    parser.add_argument("--ledger", default=LEDGER)
    parser.add_argument("--stale", action="store_true")
    parser.add_argument("--today", type=datetime.date.fromisoformat, default=datetime.date.today())
    args = parser.parse_args(argv)
    if args.stale == bool(args.report):
        parser.error("give a report folder, or --stale")
    if args.stale:
        rows = stale(args.ledger, args.today)
        for row, days in rows:
            print(f"{row['name']} ({row['kind']}): {row['state']} for {days} days, held by {row['holder']}. "
                  f"Marked by {row['measures']}. {row['note']}")
        return 1 if rows else 0
    rows = unheld(args.report, args.ledger)
    if rows:
        print(f"{len(rows)} marks are not in the ledger ({args.ledger}). Each needs a row, and whoever ran this "
              "report owns it until it is explained or with the owner:")
        for subject, kind, name, missing in rows:
            print(f"  {kind} {subject} ({name}): {'; '.join(missing)}")
    else:
        print("every mark is in the ledger")
    return 1 if rows else 0


if __name__ == "__main__":
    sys.exit(main())
