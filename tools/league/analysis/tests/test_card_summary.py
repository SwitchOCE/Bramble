"""card_summary: one row per card from the report tables, with marks and the no-data reason."""
import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import card_summary


def write(path, rows):
    with open(path, "w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def card(name, tribe, tier=1):
    return {"id": name, "name": name.title(), "tribes": [tribe] if tribe else [], "tier": tier,
            "spell": False, "token": False}


def bought(name, offered, rate, difference="", typical="", flag=""):
    return {"card": name, "bot": "red-1", "offered": offered, "pick_rate": rate,
            "difference": difference, "typical": typical, "flag": flag}


class CardSummary(unittest.TestCase):
    def rows(self, with_fights=True, left_out=False):
        with tempfile.TemporaryDirectory() as directory:
            match, report = Path(directory) / "match", Path(directory) / "report"
            match.mkdir()
            report.mkdir()
            library = [card("heir", "Badger", 3), card("stray", "Mouse"), card("dud", "Badger"),
                       card("rare", "Badger", 6), card("loner", ""), {"id": "spell", "name": "Spell", "tribes": [],
                                                                    "tier": 1, "spell": True, "token": False}]
            (match / "library.json").write_text(json.dumps(library))
            seat = {"label": "red-1", "bot": "red", "colour": "red", "main_tribe": "Badger", "place": 2,
                    "rounds": [{"round": 4, "board": [{"card": "heir"}, None]},
                               {"round": 5, "board": [{"card": "heir"}, {"card": "heir"}]},
                               {"round": 6, "board": []}]}
            (match / "games.jsonl").write_text(json.dumps({"game": 0, "seats": [seat]}) + "\n")
            write(report / "bought_passed.csv", [
                bought("heir", 500, 0.95, 0.5, 0.1, "worth a look: worse when bought"),
                bought("stray", 500, 0.0), bought("dud", 500, 0.005), bought("rare", 20, 0.5),
                bought("loner", 500, 0.0), {**bought("heir", 900, 0.5), "bot": "all"}])
            if with_fights:
                text = {"card": "heir", "stage": "5-8", "status": "ok", "text_value": 0.27, "spreads": 6.1,
                        "pointer": "worth a look"}
                write(report / "text_cards.csv", [text, {**text, "stage": "1-4", "status": "too few", "pointer": ""}])
                write(report / "stat_growth.csv", [{"card": "heir", "stage": "5-8", "status": "ok",
                                                    "stats_per_turn": 4.0, "look": "worth a look"}])
            path = None
            if left_out:
                path = report / "left_out.csv"
                write(path, [{"card": "heir", "bot": "red", "colour": "red", "diff_mean": "1.1090"}])
            return {r["card"]: r for r in card_summary.summary(match, report, path)}

    def test_measures_marks_and_boards_holding_the_card(self):
        rows = self.rows(left_out=True)
        self.assertNotIn("spell", rows)
        heir = rows["heir"]
        self.assertEqual(heir["worth a look"], "pick rate (red-1); bought against passed (red-1: worse when bought); "
                                               "text (5-8); growth (5-8)")
        self.assertEqual((heir["held red-1 1-4"], heir["held red-1 5-8"], heir["held red-1 9-12"]), (1.0, 0.5, ""))
        self.assertEqual((heir["text 5-8"], heir["text 1-4"], heir["growth 5-8"]), ("0.27", "", "4.0"))
        self.assertEqual((heir["bought-passed red-1"], heir["left out red-1"], heir["fight data"]), (0.4, 1.11, "yes"))

    def test_why_a_card_has_no_fight_data(self):
        rows = self.rows()
        self.assertEqual({name: rows[name]["fight data"] for name in ("stray", "dud", "rare", "loner")},
                         {"stray": "tribe not played", "dud": "offered and refused", "rare": "seldom offered",
                          "loner": "offered and refused"})
        self.assertEqual(rows["stray"]["worth a look"], "")

    def test_a_match_without_records_says_so(self):
        self.assertEqual(self.rows(with_fights=False)["heir"]["fight data"], "no records")


if __name__ == "__main__":
    unittest.main()
