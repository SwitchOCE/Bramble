"""check_units' parameter check: thresholds can't go below 1; a data step's numbers can."""

import unittest

from tools.checks import check_units


class CheckParamTest(unittest.TestCase):
    def test_threshold_of_zero_is_refused(self) -> None:
        self.assertIsNotNone(check_units.check_param("threshold", 0))
        self.assertIsNone(check_units.check_param("threshold", 1))

    def test_script_number_of_zero_is_refused(self) -> None:
        self.assertIsNotNone(check_units.check_param("number", 0))

    def test_data_step_number_may_be_negative(self) -> None:
        step = {"effect": "rule", "query": "income", "op": "add", "value": -1}
        self.assertEqual(check_units.check_step(step, "recruit", "cast", False), [])

    def test_data_step_threshold_of_zero_is_refused(self) -> None:
        step = {"effect": "summon", "unit": "x", "count": 0}
        self.assertTrue(check_units.check_step(step, "recruit", "cast", False))


if __name__ == "__main__":
    unittest.main()
