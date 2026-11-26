"""marks: which of a card report's marks the ledger holds, and which rows have waited too long."""
import datetime
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import marks


def row(subject, measures, state="new", since="2026-11-25", kind="card"):
    return f"{subject},{kind},{subject.title()},{measures},2026-11-25,a match,{state},the referee,{since},,a note\n"


class Ledger(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.dir = Path(scratch.name)
        (self.dir / "cards.csv").write_text(
            "card,name,worth a look\n"
            "heir,Heir,pick rate (blue-1); text (1-4); text (5-8)\n"
            "cub,Cub,growth (5-8)\n"
            "plain,Plain,\n")
        (self.dir / "keywords.csv").write_text(
            "keyword,stage,enemy_health,status,keyword_value\n"
            "overrun,5-8,all,ok,0.068\noverrun,5-8,low,ok,0.139\ncleave,5-8,all,ok,0.005\nfury,1-4,all,too few,\n")
        self.ledger = self.dir / "marks.csv"

    def write(self, *rows):
        self.ledger.write_text(",".join(marks.COLUMNS) + "\n" + "".join(rows))

    def test_a_mark_is_held_when_its_row_lists_the_measure(self):
        self.write()
        self.assertEqual([(s, k, m) for s, k, _, m in marks.unheld(self.dir, self.ledger)],
                         [("cub", "card", ["growth"]), ("heir", "card", ["pick rate", "text"]),
                          ("overrun", "keyword", ["keyword off"])])
        # An explained card marked again by the same measure stays closed; a new measure on it is a new mark.
        self.write(row("heir", "text", "explained"), row("cub", "growth"), row("overrun", "keyword off", kind="keyword"))
        self.assertEqual([(s, m) for s, _, _, m in marks.unheld(self.dir, self.ledger)], [("heir", ["pick rate"])])
        self.assertEqual(marks.main([str(self.dir), "--ledger", str(self.ledger)]), 1)
        # A mark no test can read yet is held, and never stale: it waits on no one.
        self.write(row("heir", "text; pick rate", "cannot be read"), row("cub", "growth"), row("overrun", "keyword off", kind="keyword"))
        self.assertEqual(marks.unheld(self.dir, self.ledger), [])
        self.write(row("heir", "text; pick rate"), row("cub", "growth"), row("overrun", "keyword off", kind="keyword"))
        self.assertEqual(marks.main([str(self.dir), "--ledger", str(self.ledger)]), 0)
        # A changed card that is marked on the new build is not held: it goes back to the owner.
        self.write(row("heir", "text; pick rate", "changed"), row("cub", "growth"), row("overrun", "keyword off", kind="keyword"))
        self.assertEqual([(s, m) for s, _, _, m in marks.unheld(self.dir, self.ledger)], [("heir", ["pick rate", "text"])])

    def test_rows_that_wait_too_long_are_stale(self):
        self.write(row("heir", "text", "new", "2026-11-25"), row("cub", "growth", "with the owner", "2026-11-25"),
                   row("old", "text", "explained", "2026-11-01"), row("done", "text", "changed", "2026-11-25"),
                   row("picked", "text", "change picked", "2026-11-25"),
                   row("unread", "text", "cannot be read", "2026-11-01"))
        names = lambda day: [r["subject"] for r, _ in marks.stale(self.ledger, datetime.date.fromisoformat(day))]
        self.assertEqual((names("2026-11-25"), names("2026-11-26"), names("2026-11-28")),
                         ([], ["heir"], ["heir", "cub", "done", "picked"]))

    def test_a_missing_ledger_is_an_error_not_an_empty_one(self):
        with self.assertRaisesRegex(ValueError, "no ledger"):
            marks.stale(self.dir / "nowhere.csv", datetime.date(2026, 11, 26))

    def test_the_repo_s_own_ledger_reads(self):
        rows = marks.read_ledger(marks.LEDGER)
        self.assertTrue(all(row["since"] and row["holder"] or row["state"] in ("explained", "cannot be read", "measured again")
                            for row in rows.values()))

    def test_an_unknown_state_is_refused(self):
        self.write(row("heir", "text", "parked"))
        with self.assertRaisesRegex(ValueError, "parked"):
            marks.read_ledger(self.ledger)


if __name__ == "__main__":
    unittest.main()
