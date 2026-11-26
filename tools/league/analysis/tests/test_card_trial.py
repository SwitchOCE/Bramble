from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import card_trial
from card_without import Refused
from test_card_without import write_match

TRIAL = {"field_rules_hash": "r" * 64, "card_data": "/scratch",
         "changes": {"files": ["src/content/badger/units.json"],
                     "cards": [{"id": "sword-heir", "changed": {"health": {"was": 9, "now": 5}}}]}}


class CardTrial(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.dir = Path(scratch.name)
        self.base = write_match(self.dir / "base", [1, 2, 3, 4, 5, 6])

    def trial(self, name, places, **kw):
        kw.setdefault("rules", "t" * 64)
        return write_match(self.dir / name, places, extra={"trial_rules": TRIAL}, **kw)

    def test_place_with_the_change_minus_without(self):
        worse = self.trial("worse", [2, 2, 5, 4, 6, 6])
        rows = {r["colour"]: r for r in card_trial.table(self.base, [worse])}
        self.assertAlmostEqual(rows["red"]["diff_mean"], (1 + 2 + 1) / 3)
        self.assertEqual(rows["blue"]["diff_mean"], 0)
        self.assertEqual(rows["red"]["changes"], "sword-heir health 9->5")
        self.assertEqual(rows["red"]["trial"], "worse")

    def test_refuses_what_is_not_a_trial_of_this_baseline(self):
        plain = write_match(self.dir / "plain", [1] * 6, rules="t" * 64)
        with self.assertRaises(Refused):
            card_trial.table(self.base, [plain])
        own_rules = self.trial("own", [1] * 6, rules="r" * 64)
        with self.assertRaises(Refused):
            card_trial.table(self.base, [own_rules])
        other_field = write_match(self.dir / "field", [1] * 6, rules="t" * 64,
                                  extra={"trial_rules": dict(TRIAL, field_rules_hash="x" * 64)})
        with self.assertRaises(Refused):
            card_trial.table(self.base, [other_field])
        secret = self.trial("secret", [1] * 6, secret="cd" * 32)
        with self.assertRaises(Refused):
            card_trial.table(self.base, [secret])
        granted = write_match(self.dir / "granted", [1] * 6, rules="t" * 64,
                              extra={"trial_rules": TRIAL, "grant": {"card": "a"}})
        with self.assertRaises(Refused):
            card_trial.table(self.base, [granted])
        # A trial is never a baseline, nor a control.
        t = self.trial("t", [1] * 6)
        with self.assertRaises(Refused):
            card_trial.table(t, [self.trial("t2", [1] * 6)])
        with self.assertRaises(Refused):
            card_trial.table(self.base, [], [t])

    def test_control(self):
        rerun = write_match(self.dir / "rerun", [1, 2, 3, 4, 5, 7])
        row = [r for r in card_trial.table(self.base, [], [rerun]) if r["colour"] == "blue"][0]
        self.assertAlmostEqual(row["diff_mean"], 1 / 3)
        self.assertEqual(row["trial"], "(control)")


if __name__ == "__main__":
    unittest.main()
