"""combat: every body that joins a fight, totalled by kind, cause and card."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import combat


def game(*fights):
    return {"fights": [{"fights": list(fights)}]}


class Joined(unittest.TestCase):
    def test_totals_by_kind_cause_and_card(self):
        molt = {"kind": "return", "source": "molt", "card": "adder", "count": 2}
        pip = {"kind": "summon", "source": None, "card": "pip", "count": 1}
        totals = combat.joined_totals([game({"joined": [[molt, pip], [molt]]}), game({"joined": [[], []]})])
        self.assertEqual(dict(totals), {("return", "molt", "adder"): 4, ("summon", combat.NONE, "pip"): 1})

    def test_a_log_without_the_field_gives_no_table(self):
        self.assertIsNone(combat.joined_totals([game({"summons": [[], []]})]))


if __name__ == "__main__":
    unittest.main()
