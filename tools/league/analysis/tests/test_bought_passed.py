"""bought_passed: the grouped difference, the too-few rule and the tribe group."""
import gzip
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import bought_passed


def write_match(directory, games):
    """games: list of (place, tribes at end of round 1, bought card A in round 2?)."""
    directory = Path(directory)
    (directory / "summary.json").write_text(json.dumps({"red": "red", "blue": "blue", "red_label": "red-x"}))
    (directory / "library.json").write_text(json.dumps([
        {"id": "a", "tier": 3, "tribes": ["Badger"]}, {"id": "b", "tier": 1, "tribes": []}]))
    with open(directory / "games.jsonl", "w") as out, gzip.open(directory / "shops.jsonl.gz", "wt") as shops:
        for g, (place, tribes, bought) in enumerate(games):
            out.write(json.dumps({"game": g, "seats": [{"seat": 0, "colour": "red", "bot": "red", "place": place,
                                                         "rounds": [{"round": 1, "tribes": tribes}]}]}) + "\n")
            shops.write(json.dumps({
                "game": g, "seat": 0, "round": 2,
                "offers": [{"card": "a", "spell": False, "index": 0, "buyable": True},
                           {"card": "b", "spell": False, "index": 1, "buyable": False}],
                "bought": [{"card": "a", "spell": False, "index": 0}] if bought else []}) + "\n")


class BoughtPassed(unittest.TestCase):
    def rows(self, games):
        with tempfile.TemporaryDirectory() as directory:
            write_match(directory, games)
            return {(r["card"], r["bot"]): r for r in bought_passed.report([directory], resamples=50)}

    def test_difference_is_taken_inside_the_tribe_group(self):
        # In tribe: bought 2nd, passed 4th. Off tribe: bought 5th, passed 7th. Mixed together the raw
        # means would differ by more, because buying goes with being in tribe.
        games = ([(2, {"Badger": 4}, True)] * 150 + [(4, {"Badger": 4}, False)] * 50
                 + [(5, {"Badger": 1}, True)] * 50 + [(7, {"Badger": 1}, False)] * 150)
        row = self.rows(games)[("a", "all")]
        self.assertEqual((row["offered"], row["bought"], row["passed"]), (400, 200, 200))
        self.assertEqual(row["pick_rate"], 0.5)
        self.assertAlmostEqual(row["difference"], -2.0)
        self.assertEqual(row["groups"], 2)
        self.assertEqual(row["flag"], "better when bought")
        self.assertEqual(row["place_bought"] - row["place_passed"], 2.75 - 6.25)

    def test_too_few_passed_turns_gives_no_number(self):
        games = [(2, {"Badger": 4}, True)] * 300 + [(6, {"Badger": 4}, False)] * 20
        row = self.rows(games)[("a", "all")]
        self.assertEqual(row["status"], "too few")
        self.assertEqual(row["difference"], "")

    def test_a_card_that_was_not_buyable_is_not_an_observation(self):
        self.assertNotIn(("b", "all"), self.rows([(2, {}, True)] * 10))


if __name__ == "__main__":
    unittest.main()
