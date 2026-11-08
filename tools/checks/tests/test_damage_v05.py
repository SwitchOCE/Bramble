"""Decision-critical boundaries of the preregistered damage experiment."""

import unittest

from tools.sim.summarize_damage_v05 import evaluate, qualifying, summarize


def rows(start, results):
    return [{"round": start + index, "result": result} for index, result in enumerate(results)]


def metrics():
    baseline = {
        "streak_elimination_median": 10,
        "game_length_median": 16,
        "first_elimination_median": 9,
        "performance_share": 0.3,
        "comeback_rate": 0.2,
        "base_changes": 10,
        "health": 40,
    }
    result = {"baseline": baseline}
    for arm in "ABCDE":
        result[arm] = dict(baseline, streak_elimination_median=12, first_elimination_median=10)
    return result


class DamageExperimentTests(unittest.TestCase):
    def test_early_streak_boundary_and_draw_break(self):
        self.assertTrue(qualifying(rows(6, ["loss"] * 5)))
        self.assertFalse(qualifying(rows(7, ["loss"] * 5)))
        self.assertFalse(qualifying(rows(3, ["loss"] * 4 + ["tie", "loss"])))
        self.assertTrue(qualifying(rows(1, ["win"] + ["loss"] * 5)))

    def test_censoring_bottom_two_ties_and_attribution(self):
        players = []
        for seat in range(8):
            last = 10 if seat < 3 else 4
            rounds = [
                {
                    "round": number,
                    "health": 3 if seat < 3 else -1,
                    "result": "loss" if number <= 5 and seat != 1 else "win",
                }
                for number in range(1, last + 1)
            ]
            players.append(
                {"seat": seat, "place": [5, 6, 1, 2, 3, 4, 7, 8][seat], "alive": seat == 2, "rounds": rounds}
            )
        game = {
            "rounds": 10,
            "players": players,
            "starting_health": 40,
            "base_schedule": [1, 1, 2],
            "fights": [{"charges": [{"damage": 10, "performance": 3, "effective": 5}]}],
        }
        result = summarize([game])
        self.assertEqual(result["qualifying_players"], 2)
        self.assertEqual(result["qualifying_censored"], 1)
        self.assertEqual(result["streak_elimination_median"], 10.5, "winner is censored at final round + 1")
        self.assertEqual(result["first_elimination_median"], 4)
        self.assertEqual(result["bottom_two_players"], 2)
        self.assertEqual(result["comebacks"], 0, "seat-ID tie-break excludes the eventual winner")
        self.assertEqual(result["damage_total"], 10)
        self.assertEqual(result["performance_total"], 3)
        self.assertEqual(result["effective_damage_total"], 5)
        self.assertAlmostEqual(result["effective_performance_share"], 0.3)

    def test_inclusive_thresholds_and_simple_schedule_tie(self):
        result = metrics()
        result["B"].update(performance_share=0.25, game_length_median=15, base_changes=2)
        result["C"].update(performance_share=0.45, game_length_median=17, base_changes=2)
        result["D"].update(base_changes=1, health=48)
        result["E"].update(base_changes=1, health=40)
        self.assertEqual(evaluate(result), "E", "simplicity first, then 40 Health")
        for arm in "ABCDE":
            self.assertEqual(result[arm]["targets_met"], 5)
        result["D"]["health"] = 40
        self.assertEqual(evaluate(result), "D", "alphabetical final tie-break")

    def test_failures_do_not_pass_on_rounding(self):
        result = metrics()
        result["A"].update(
            performance_share=0.249999,
            game_length_median=17.5,
            comeback_rate=0.199999,
            streak_elimination_median=11.5,
            first_elimination_median=9.5,
        )
        evaluate(result)
        self.assertEqual(result["A"]["targets_met"], 0)


if __name__ == "__main__":
    unittest.main()
