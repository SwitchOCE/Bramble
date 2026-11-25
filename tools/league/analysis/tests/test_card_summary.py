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
    def rows(self, with_fights=True, left_out=False, fresh=False):
        with tempfile.TemporaryDirectory() as directory:
            match, report = Path(directory) / "match", Path(directory) / "report"
            match.mkdir()
            report.mkdir()
            library = [card("heir", "Badger", 3), card("stray", "Mouse"), card("dud", "Badger"),
                       card("rare", "Badger", 6), card("loner", ""), {"id": "spell", "name": "Spell", "tribes": [],
                                                                    "tier": 1, "spell": True, "token": False}]
            (match / "library.json").write_text(json.dumps(library))
            seat = {"bot": "red", "colour": "red", "main_tribe": "Badger", "place": 2,  # label from summary.json
                    "rounds": [{"round": 4, "board": [{"card": "heir"}, None]},
                               {"round": 5, "board": [{"card": "heir"}, {"card": "heir"}]},
                               {"round": 6, "board": []}]}
            (match / "games.jsonl").write_text(json.dumps({"game": 0, "seats": [seat]}) + "\n")
            (match / "summary.json").write_text(json.dumps({"summary": {"red": "red", "blue": "blue", "red_label": "red-1"}}))
            write(report / "bought_passed.csv", [
                bought("heir", 500, 0.95, 0.5, 0.1, "worth a look: worse when bought"),
                bought("stray", 500, 0.0), bought("dud", 500, 0.005), bought("rare", 20, 0.5),
                bought("loner", 500, 0.0), {**bought("heir", 900, 0.5), "bot": "all"}])
            if with_fights:
                text = {"card": "heir", "stage": "5-8", "status": "ok", "text_value": 0.27, "spreads": 6.1,
                        "pointer": "worth a look", "stat_worth": 2.5}
                write(report / "text_cards.csv", [text, {**text, "stage": "1-4", "status": "too few", "pointer": ""}])
                write(report / "stat_growth.csv", [{"card": "heir", "stage": "5-8", "status": "ok",
                                                    "stats_per_turn": 4.0, "look": "worth a look"}])
            if fresh:
                cell = {"card": "dud", "stage": "5-8", "boards": 400, "status": "ok", "fresh_value": 0.2,
                        "low": 0.15, "high": 0.25, "pointer": "worth a look", "reading": "has fight text worth"}
                write(report / "fresh_copy.csv", [cell, {**cell, "card": "heir"},
                                                  {**cell, "stage": "13+", "boards": 50, "status": "too few",
                                                   "fresh_value": "", "pointer": ""}])
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
        self.assertEqual((heir["stat worth 5-8"], heir["stat worth 1-4"]), ("2.5", ""))
        self.assertEqual((heir["bought-passed red-1"], heir["left out red-1"], heir["fight data"]), (0.4, 1.11, "yes"))

    def test_why_a_card_has_no_fight_data(self):
        rows = self.rows()
        self.assertEqual({name: rows[name]["fight data"] for name in ("stray", "dud", "rare", "loner")},
                         {"stray": "tribe not played", "dud": "offered and refused", "rare": "seldom offered",
                          "loner": "offered and refused"})
        self.assertEqual(rows["stray"]["worth a look"], "")

    def test_refusal_is_reported_whatever_the_fight_data(self):
        rows = self.rows()
        self.assertEqual({name: rows[name]["in the shop"] for name in ("heir", "stray", "dud", "rare", "loner")},
                         {"heir": "bought", "stray": "tribe not played", "dud": "refused", "rare": "seldom offered",
                          "loner": "refused"})

    def test_fresh_copy_columns_are_for_refused_cards_only(self):
        rows = self.rows(fresh=True)
        dud, heir, loner = rows["dud"], rows["heir"], rows["loner"]
        self.assertEqual((dud["fresh 5-8"], dud["fresh boards 5-8"], dud["fresh 13+"], dud["fresh boards 13+"]),
                         ("0.2", "400", "", "50"))
        self.assertEqual(dud["fresh reading"], "has fight text worth")
        self.assertIn("fresh copy (5-8)", dud["worth a look"])
        self.assertEqual((heir["fresh 5-8"], heir["fresh reading"]), ("", ""))  # bought: not read
        self.assertNotIn("fresh copy", heir["worth a look"])
        self.assertEqual(loner["fresh reading"], "no boards it fits")
        self.assertEqual(self.rows()["dud"]["fresh reading"], "not run")
        self.assertEqual(self.rows(with_fights=False)["dud"]["fresh reading"], "")

    def test_a_card_another_bot_buys_is_not_refused(self):
        plays = {"red-1": {"Mouse": 0.12}, "blue-1": {"Mouse": 0.01}}
        reading = lambda blue: card_summary.shop_reading(["Mouse"], {"red-1": (500, 0.0), "blue-1": blue}, plays)
        self.assertEqual((reading((500, 0.16)), reading((500, 0.0)), reading((50, 0.5))), ("bought", "refused", "refused"))
        self.assertEqual(card_summary.shop_reading(["Mouse"], {"red-1": (50, 0.0), "blue-1": (500, 0.0)}, plays), "seldom offered")

    def test_keyword_lines_mark_a_keyword_over_the_floor(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "keywords.csv"
            cell = lambda health, value, status="ok": {"keyword": "overrun", "stage": "5-8", "enemy_health": health,
                                                       "status": status, "keyword_value": value}
            write(path, [cell("all", 0.068), cell("low", 0.139), cell("high", 0.04),
                         {**cell("all", 0.005), "keyword": "cleave"}, {**cell("low", "", "too few"), "keyword": "cleave"}])
            self.assertEqual(list(card_summary.keyword_lines(path)), [
                "  keyword cleave, rounds 5-8: +0.005",
                "  keyword overrun, rounds 5-8: +0.068, +0.139 against low-Health boards, +0.040 against high  <- worth a look"])

    def test_a_match_without_records_says_so(self):
        self.assertEqual(self.rows(with_fights=False)["heir"]["fight data"], "no records")


if __name__ == "__main__":
    unittest.main()
