import copy
import itertools
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from field import REQUIRED_CONFIG_KEYS, boards_from_capture, field_report, load_designed, quotas, sample_field


class FieldTests(unittest.TestCase):
    def boards(self):
        return [
            {"id": str(i), "round": 6, "line": "hard" if i < 80 else "tribal" if i < 99 else "rare"} for i in range(100)
        ]

    def test_stratified_reservoir_is_repeatable_and_preserves_population_weights(self):
        field = sample_field(self.boards(), (6,), 8)
        self.assertEqual(field, sample_field(self.boards(), (6,), 8))
        data = field["rounds"]["6"]
        self.assertEqual(len(data["boards"]), 8)
        self.assertEqual(data["sample_counts"], {"hard": 4, "rare": 1, "tribal": 3})
        self.assertEqual(data["line_weights"], {"hard": 0.8, "tribal": 0.19, "rare": 0.01})
        self.assertAlmostEqual(sum(b["weight"] for b in data["boards"]), 1)
        for line, weight in data["line_weights"].items():
            self.assertAlmostEqual(sum(b["weight"] for b in data["boards"] if b["line"] == line), weight)
            self.assertTrue(
                all(b["weight"] == weight / data["sample_counts"][line] for b in data["boards"] if b["line"] == line)
            )

    def test_equal_line_quotas_use_four_or_five_of_each_line_for_64_boards(self):
        counts = {"hard": 10000, **{f"line_{i:02}": 100 + i for i in range(13)}}
        allocation = quotas(counts, 64)
        self.assertEqual(sum(allocation.values()), 64)
        self.assertEqual(sorted(allocation.values()), [4] * 6 + [5] * 8)
        self.assertEqual(allocation, quotas(dict(reversed(list(counts.items()))), 64))
        self.assertEqual(quotas({"hard": 10000, "a": 1, "b": 100}, 10), {"a": 1, "b": 5, "hard": 4})

    def test_missing_hard_and_insufficient_fields_fail(self):
        with self.assertRaises(ValueError):
            quotas({"tribal": 100}, 64)
        with self.assertRaises(ValueError):
            quotas({"hard": 2}, 64)

    def test_known_winner_and_null_draws_are_descriptive_not_a_hard_strength_gate(self):
        field = sample_field(self.boards(), (6,), 4)
        pairs = []
        for a, b in itertools.combinations(field["rounds"]["6"]["boards"], 2):
            hard_a, hard_b = a["line"] == "hard", b["line"] == "hard"
            pairs.append(
                {
                    "round": 6,
                    "a": a["id"],
                    "b": b["id"],
                    "wins_a": 2 if hard_a and not hard_b else 0,
                    "wins_b": 2 if hard_b and not hard_a else 0,
                    "draws": 2 if hard_a == hard_b else 0,
                    "trials": 2,
                }
            )
        report = field_report(field, pairs)
        self.assertIsNone(report["rounds"]["6"]["hard_floor_passes"])
        self.assertTrue(report["rounds"]["6"]["field_includes_hard"])
        self.assertIn("not_a_strength_gate", report["rounds"]["6"]["hard_floor_status"])
        self.assertEqual(report["rounds"]["6"]["strongest_line"], "hard")
        self.assertEqual(report["rounds"]["6"]["win_matrix"]["hard"]["tribal"], 1)
        self.assertTrue(any(p["p_win_a"] is None for p in report["pairs"]))
        with self.assertRaises(ValueError):
            field_report(field, pairs[:-1])
        with self.assertRaises(ValueError):
            field_report(field, [*pairs, pairs[0]])

    def skill_field(self, size, *, constant_hard=False):
        boards = [
            {"id": f"{line}:{i}", "round": 6, "line": line, "skill": 0.5 if constant_hard and line == "hard" else i % 2}
            for line in ("hard", "tribal")
            for i in range(size)
        ]
        field = sample_field(boards, (6,), 2 * size)
        pairs = []
        for a, b in itertools.combinations(field["rounds"]["6"]["boards"], 2):
            wins = round(10 * (0.5 + 0.4 * (a["skill"] - b["skill"])))
            pairs.append(
                {"round": 6, "a": a["id"], "b": b["id"], "wins_a": wins, "wins_b": 10 - wins, "draws": 0, "trials": 10}
            )
        return field, pairs

    def test_cluster_intervals_are_seeded_and_do_not_treat_trials_as_boards(self):
        field, pairs = self.skill_field(4)
        first = field_report(field, pairs, bootstrap_replicates=400, bootstrap_seed=71)
        second = field_report(field, pairs, bootstrap_replicates=400, bootstrap_seed=71)
        self.assertEqual(first, second)
        more_trials = [
            {**pair, **{key: pair[key] * 1000 for key in ("wins_a", "wins_b", "draws", "trials")}} for pair in pairs
        ]
        repeated = field_report(field, more_trials, bootstrap_replicates=400, bootstrap_seed=71)
        self.assertEqual(first["rounds"], repeated["rounds"])
        self.assertEqual(
            first["uncertainty"]["resampling_unit"],
            "whole board, shared across all opponent results and both endpoints",
        )
        self.assertFalse(first["uncertainty"]["fight_trials_resampled"])
        self.assertIn("conditional", first["uncertainty"]["scope"])
        for interval in first["rounds"]["6"]["line_uncertainty"].values():
            self.assertEqual(interval["selected_boards"], 4)
            self.assertTrue(interval["very_low_n"])
            self.assertEqual(interval["valid_bootstrap_replicates"], 400)
            self.assertLess(interval["ci95"][0], interval["ci95"][1])

    def test_cluster_intervals_include_opponent_board_variation(self):
        field, pairs = self.skill_field(6, constant_hard=True)
        report = field_report(field, pairs, bootstrap_replicates=500)
        interval = report["rounds"]["6"]["line_point_rate_ci95"]["hard"]
        # Every Hard board is identical. Its interval is still wide because the
        # opposing endpoint is resampled too, rather than fixing the opponents.
        self.assertLess(interval[0], 0.49)
        self.assertGreater(interval[1], 0.51)

    def test_fewer_independent_boards_have_wider_intervals(self):
        widths = []
        for size in (2, 16):
            field, pairs = self.skill_field(size)
            result = field_report(field, pairs, bootstrap_replicates=1000, bootstrap_seed=32)["rounds"]["6"]
            interval = result["line_point_rate_ci95"]["hard"]
            widths.append(interval[1] - interval[0])
            self.assertEqual(result["line_uncertainty"]["hard"]["very_low_n"], size == 2)
        self.assertGreater(widths[0], widths[1] * 1.5)

    def test_one_board_cannot_estimate_own_line_variation(self):
        field = sample_field(self.boards(), (6,), 3)
        pairs = [
            {"round": 6, "a": a["id"], "b": b["id"], "wins_a": 0, "wins_b": 0, "draws": 10, "trials": 10}
            for a, b in itertools.combinations(field["rounds"]["6"]["boards"], 2)
        ]
        result = field_report(field, pairs, bootstrap_replicates=30)["rounds"]["6"]
        for interval in result["line_uncertainty"].values():
            self.assertEqual(interval["selected_boards"], 1)
            self.assertTrue(interval["very_low_n"])
            self.assertFalse(interval["own_line_variation_estimable"])

    def designed_document(self):
        # Explicit state, including held bodies and nonvisible rule state.
        unit = {
            "def_id": "wick",
            "golden": False,
            "attack": 7,
            "health": 9,
            "iid": 1,
            "tribe_attack": 2,
            "tribe_health": 3,
        }
        unit["held"] = [{**unit, "iid": 2, "hex": 4}]
        unit["lifetime_payments"] = {"paid_moss": 12}
        config = dict.fromkeys(REQUIRED_CONFIG_KEYS, 0)
        for key in (
            "scale_levers",
            "base_damage_by_turn",
            "income_by_turn",
            "upgrade_costs",
            "pool_copies_by_tier",
            "shop_units_by_tier",
            "damage_cap_by_turn",
            "bots",
            "shop_tier_odds",
            "shop_spells_by_tier",
            "spell_copies_by_tier",
            "opening_spells",
        ):
            config[key] = []
        for key in (
            "card_size_caps",
            "card_rate_limits",
            "scale_engine_self",
            "scale_hero_spell_stats",
            "round_toll",
            "early_spoils",
            "ask_for_kin",
            "last_blow",
            "last_stand",
            "spells_in_shop",
            "hero_choice",
        ):
            config[key] = False
        config.update(
            damage_mode="v05",
            pool_filter="slice",
            human_bot="",
            scale_engine_tribe="Hedgerow folk",
            attack_limit=200,
            trigger_limit_combat=10000,
        )
        board = {
            "id": "owner-a",
            "round": 6,
            "line": "owner",
            "layout": "blind",
            "board": [unit] + [None] * 6,
            "slots": [[{"name": "Ring", "attack": 3, "health": 2}]] + [[] for _ in range(6)],
            "fight_rules": {
                "larder": 4,
                "back_row_first": True,
                "bands": [1, 0, 0, 0, 0, 0, 0],
                "ammo": [5],
                "nests": [{"slot": 1, "spec": copy.deepcopy(unit)}],
                "goose": 2,
                "away_birds": ["redwing"],
                "homecomings": 1,
            },
            "hero_effects": [{"trigger": "on_friendly_death", "do": {"effect": "summon", "unit": "mouse"}}],
            "tier": 4,
            "config": config,
            "combat_start": {"active_stats": 16, "custom_metadata": "preserved"},
            "after_start_effects": {"active_stats": 21, "units": []},
        }
        return {"boards": [board, {**copy.deepcopy(board), "id": "owner-b"}], "line_weights": {"6": {"owner": 1.0}}}

    def load_document(self, document):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "designed.json"
            path.write_text(json.dumps(document))
            return load_designed(path)

    def test_designed_full_state_preserved_and_no_hard_required(self):
        document = self.designed_document()
        boards, weights = self.load_document(document)
        field = sample_field(boards, (6,), 2, line_weights=weights)
        self.assertEqual(field["source_mode"], "designed_only")
        self.assertEqual(field["weight_source"], "explicit_designed_line_weights")
        for actual in field["rounds"]["6"]["boards"]:
            for key, value in document["boards"][0].items():
                if key != "id":
                    self.assertEqual(actual[key], value)
            self.assertEqual(actual["provenance"]["kind"], "designed")
            self.assertEqual(actual["weight"], 0.5)
        a, b = field["rounds"]["6"]["boards"]
        report = field_report(
            field,
            [{"round": 6, "a": a["id"], "b": b["id"], "wins_a": 0, "wins_b": 0, "draws": 2, "trials": 2}],
            bootstrap_replicates=20,
        )
        self.assertFalse(report["rounds"]["6"]["field_includes_hard"])

    def test_designed_weights_are_explicit_not_board_count_shares(self):
        document = self.designed_document()
        document["boards"].append({**copy.deepcopy(document["boards"][0]), "id": "other", "line": "other"})
        document["line_weights"]["6"] = {"owner": 0.1, "other": 0.9}
        boards, weights = self.load_document(document)
        field = sample_field(boards, (6,), 3, line_weights=weights)
        self.assertEqual(field["rounds"]["6"]["line_weights"], {"owner": 0.1, "other": 0.9})
        self.assertEqual(
            {board["line"]: board["weight"] for board in field["rounds"]["6"]["boards"]}, {"owner": 0.05, "other": 0.9}
        )

    def test_designed_missing_state_or_weights_is_rejected(self):
        for key in ("slots", "fight_rules", "hero_effects", "tier", "config", "board", "line_weights"):
            document = self.designed_document()
            del (document if key == "line_weights" else document["boards"][0])[key]
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.load_document(document)
        for path in (("config", "attack_limit"), ("fight_rules", "nests"), ("board", 0, "tribe_health")):
            document = self.designed_document()
            value = document["boards"][0]
            for key in path[:-1]:
                value = value[key]
            del value[path[-1]]
            with self.subTest(path=path), self.assertRaises(ValueError):
                self.load_document(document)
        for weights in ({"owner": 0.5}, {"owner": -1}, {"missing": 1}, {"owner": float("nan")}):
            document = self.designed_document()
            document["line_weights"]["6"] = weights
            with self.subTest(weights=weights), self.assertRaises(ValueError):
                self.load_document(document)

    def test_designed_malformed_state_and_mixed_rules_are_rejected(self):
        changes = (
            ("slots", []),
            ("board", [None]),
            ("hero_effects", None),
            ("layout", "counter"),
            ("tier", 0),
            ("round", 6.5),
        )
        for key, value in changes:
            document = self.designed_document()
            document["boards"][0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.load_document(document)
        for value in (None, "200", True):
            document = self.designed_document()
            document["boards"][0]["config"]["attack_limit"] = value
            with self.subTest(attack_limit=value), self.assertRaises(ValueError):
                self.load_document(document)
        document = self.designed_document()
        document["boards"][1]["config"]["attack_limit"] += 1
        with self.assertRaisesRegex(ValueError, "mixed designed fight configs"):
            self.load_document(document)

    def test_designed_does_not_fabricate_an_optional_snapshot(self):
        document = self.designed_document()
        for board in document["boards"]:
            del board["combat_start"]
            del board["after_start_effects"]
        boards, weights = self.load_document(document)
        field = sample_field(boards, (6,), 2, line_weights=weights)
        self.assertTrue(
            all(
                "combat_start" not in board and "after_start_effects" not in board
                for board in field["rounds"]["6"]["boards"]
            )
        )

    def test_designed_cli_accepts_no_captures_and_rejects_mixing_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            path, output = Path(directory) / "designed.json", Path(directory) / "field.json"
            path.write_text(json.dumps(self.designed_document()))
            command = [
                sys.executable,
                str(Path(__file__).resolve().parents[2] / "tools/sim/field.py"),
                "sample",
                "--designed",
                str(path),
                "--rounds",
                "6",
                "--size",
                "2",
                "--out",
                str(output),
            ]
            process = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(process.returncode, 0, process.stderr)
            self.assertEqual(json.loads(output.read_text())["source_mode"], "designed_only")
            process = subprocess.run([*command, str(path)], capture_output=True, text=True)
            self.assertNotEqual(process.returncode, 0)
            self.assertIn("cannot be mixed", process.stderr)

    def test_capture_retains_post_start_snapshot_and_old_capture_fallback(self):
        original = self.designed_document()["boards"][0]
        record = {
            "seed": 17,
            "leg": 0,
            "input": {
                "player_ids": [0, -1],
                "round": 6,
                "boards": [original["board"], []],
                "slots": [original["slots"], []],
                "fight_rules": [original["fight_rules"], {}],
                "hero_effects": [original["hero_effects"], []],
                "tiers": [4, 4],
                "config": original["config"],
            },
            "combat_start": [{**original["combat_start"], "layout": "blind", "policy": "hard"}, {}],
            "after_start_effects": [original["after_start_effects"], {}],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.jsonl"
            for has_post_start in (True, False):
                if not has_post_start:
                    del record["after_start_effects"]
                path.write_text(json.dumps(record) + "\n")
                board = next(boards_from_capture([path]))
                self.assertEqual(board["combat_start"]["active_stats"], 16)
                self.assertEqual(
                    board["after_start_effects"], original["after_start_effects"] if has_post_start else None
                )

    def test_starting_line_survives_a_tempo_switch_and_hard_keeps_its_anchor(self):
        original = self.designed_document()["boards"][0]
        record = {
            "seed": 17,
            "leg": 0,
            "input": {
                "player_ids": [0, 1],
                "round": 8,
                "boards": [original["board"], original["board"]],
                "slots": [original["slots"], original["slots"]],
                "fight_rules": [original["fight_rules"], original["fight_rules"]],
                "hero_effects": [[], []],
                "tiers": [4, 4],
                "config": original["config"],
            },
            "combat_start": [
                {
                    **original["combat_start"],
                    "layout": "blind",
                    "policy": "line_birds_homecoming",
                    "assigned_line": "line_birds_tempo",
                },
                {**original["combat_start"], "layout": "blind", "policy": "hard", "assigned_line": "hard_field"},
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.jsonl"
            path.write_text(json.dumps(record) + "\n")
            boards = list(boards_from_capture([path]))
        self.assertEqual(boards[0]["line"], "line_birds_tempo")
        self.assertEqual(boards[0]["current_line"], "line_birds_homecoming")
        self.assertEqual(boards[1]["line"], "hard")
        record["combat_start"][0]["starting_line"] = "line_birds_tempo"
        record["combat_start"][0]["assigned_line"] = "line_tempo"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.jsonl"
            path.write_text(json.dumps(record) + "\n")
            board = next(boards_from_capture([path]))
        self.assertEqual(board["line"], "line_birds_tempo", "resolved initial line beats a roster alias")
