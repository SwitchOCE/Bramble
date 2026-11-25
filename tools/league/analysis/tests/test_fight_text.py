"""fight_text: the text-off table, the pointer inside one stage, the Health thirds and the swing shares."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import fight_text


def obs(card, tier, stage, value, n=250, health=10):
    return [{"card": card, "tier": tier, "stage": stage, "game": g, "round": 9, "position": "a",
             "score_recorded": 0.5 + value, "score_off": 0.5, "dealt_recorded": 3.0, "dealt_off": 1.0,
             "result_changed": value != 0, "enemy_median_health": health} for g in range(n)]


class FightText(unittest.TestCase):
    def test_pointer_compares_with_the_median_two_tiers_up_in_the_same_stage(self):
        rows = (obs("strong-3", 3, "9-12", 0.30) + obs("plain-3", 3, "9-12", 0.02)
                + obs("a-5", 5, "9-12", 0.10) + obs("b-5", 5, "9-12", 0.12) + obs("few-5", 5, "9-12", 0.9, n=50)
                + obs("late-5", 5, "13+", 0.50))
        table = {(r["stage"], r["card"]): r for r in fight_text.text_table(rows)}
        strong = table[("9-12", "strong-3")]
        self.assertEqual((strong["text_value"], strong["damage_change"], strong["n"]), (0.3, 2.0, 250))
        self.assertEqual(strong["pointer"], "text fights above its tier")
        self.assertEqual(table[("9-12", "plain-3")]["pointer"], "")
        self.assertEqual(table[("9-12", "few-5")]["status"], "too few")
        self.assertEqual(table[("9-12", "few-5")]["text_value"], "")
        self.assertEqual(table[("9-12", "a-5")]["tier_median"], 0.11)

    def test_interval_is_grouped_by_game(self):
        rows = [{"game": g, "v": v} for g, v in ((0, 1.0), (0, 1.0), (1, 0.0), (1, 0.0))]
        mean, low, high, n = fight_text.clustered(rows, lambda r: r["v"])
        self.assertEqual((mean, n), (0.5, 4))
        self.assertAlmostEqual(high - mean, 1.96 * (2 * 2) ** 0.5 / 4)

    def test_keyword_split_by_enemy_health_thirds(self):
        rows = []
        for i, health in enumerate((4, 10, 20)):
            for r in obs("x", 4, "5-8", 0.3 - 0.1 * i, health=health):
                rows.append(dict(r, keyword="badger_overrun", game=r["game"] + 1000 * i))
        table = {r["enemy_health"]: r for r in fight_text.keyword_table(rows, fight_text.thirds(rows))}
        self.assertEqual([table[k]["keyword_value"] for k in ("low", "middle", "high")], [0.3, 0.2, 0.1])
        self.assertEqual(table["all"]["n"], 750)

    def test_swing_shares(self):
        swings = [{"stage": "9-12", "card": "the-oakfeller", "kills": k, "whole_board": w, "enemy_standing": s}
                  for k, w, s in ((0, False, 5), (2, False, 5), (3, True, 3), (1, True, 1))]
        row = fight_text.swing_table(swings)[0]
        self.assertEqual((row["card"], row["attacks"], row["kills_2_plus"], row["kills_3_plus"],
                          row["whole_board"], row["whole_board_of_3_plus"]), ("all", 4, 0.5, 0.25, 0.5, 0.25))


if __name__ == "__main__":
    unittest.main()
