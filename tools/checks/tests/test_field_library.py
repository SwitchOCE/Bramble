"""Field libraries preserve combat boundaries and sample complete persistent seats."""

import copy
import csv
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.sim import field_library


class FieldLibraryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.capture = self.directory / "baseline.fights.jsonl"
        self.players = self.directory / "baseline.players.csv"
        self.source = (
            "a" * 40,
            {"content/heroes/frog.json": "b" * 64},
            {"frog": "Frog King"},
            {"line_frogs_tempo": {"tribe": "Frogs"}},
        )
        self.rows = [self.fight(seed, number) for seed, end in [(1, 2), (2, 4), (3, 3)] for number in range(1, end + 1)]
        self.write()

    @staticmethod
    def fight(seed, number):
        spec = {
            "def_id": "frog",
            "attack": 2 * number,
            "health": 5 + seed,
            "golden": False,
            "iid": 123,
            "tribe_attack": 0,
            "tribe_health": 0,
            "grants": [{"entry": {"id": "taunt"}, "golden": False}],
            "held": [{"def_id": "fly", "attack": 3, "health": 7, "golden": True}],
        }
        return {
            "seed": seed,
            "leg": 0,
            "suite": "lines",
            "test_cards": [],
            "input": {
                "version": 1,
                "config": {"starting_health": 40, "bots": [f"seat-{seed}"], "human_bot": "line"},
                "round": number,
                "player_ids": [0, -1],
                "boards": [[spec, None, None, None, None, None, None], [None] * 7],
                "slots": [[[], [], [{"id": "ring", "attack": 3}], [], [], [], []], [[] for _ in range(7)]],
                "hero_effects": [[{"id": "frog_hero", "amount": 2}], []],
                "fight_rules": [{"larder": 12, "back_row_first": True, "nests": [{"slot": 4, "spec": spec}]}, {}],
                "tiers": [number, 1],
            },
            "combat_start": [{"policy": "line_frogs_tempo", "layout": "blind"}, {}],
        }

    def write(self):
        self.capture.write_text("".join(json.dumps(row) + "\n" for row in self.rows))
        with self.players.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, ["suite", "seed", "leg", "seat", "hero"])
            writer.writeheader()
            for seed in (1, 2, 3):
                writer.writerow({"suite": "lines", "seed": seed, "leg": 0, "seat": 0, "hero": "frog"})

    def build(self, **kwargs):
        return field_library.build_library([self.capture], [self.players], self.source, **kwargs)

    def test_exact_inputs_hero_and_provenance_survive_serialization(self):
        library = json.loads(field_library.canonical(self.build(per_line=10)))
        self.assertEqual(library["version"], 1)
        self.assertEqual(library["config_version"], 1)
        self.assertEqual(library["content_hashes"], self.source[1])
        self.assertEqual(library["source"]["commit"], "a" * 40)
        self.assertEqual(library["source"]["captures"][0]["sha256"], field_library.sha256(self.capture))
        line = library["lines"]["line_frogs_tempo"]
        self.assertEqual(line["tribe"], "Frogs")
        self.assertEqual(len(line["trajectories"]), 3)
        trajectory = line["trajectories"][0]
        self.assertEqual(trajectory["id"], "1:0:0")
        self.assertEqual(trajectory["hero"], "frog")
        self.assertEqual(trajectory["name"], "Frog King (1:0:0)")
        self.assertEqual(
            {key: trajectory["rounds"]["1"][key] for key in field_library.SIDE_KEYS},
            field_library._side(self.rows[0]["input"], 0),
        )
        self.assertEqual(len(trajectory["rounds"]["1"]["views"]), 7)

    def test_sampling_is_seeded_and_keeps_longest_coverage(self):
        first = self.build(per_line=2, seed=7)
        self.assertEqual(first, self.build(per_line=2, seed=7))
        trajectories = first["lines"]["line_frogs_tempo"]["trajectories"]
        self.assertEqual(len(trajectories), 2)
        self.assertIn("2:0:0", [value["id"] for value in trajectories])
        only = self.build(per_line=1)["lines"]["line_frogs_tempo"]["trajectories"]
        self.assertEqual(only[0]["id"], "2:0:0")
        self.assertEqual(list(only[0]["rounds"]), ["1", "2", "3", "4"])

    def test_rejects_mixed_gameplay_configs_but_accepts_seat_order_changes(self):
        self.assertEqual(len(self.build()["lines"]["line_frogs_tempo"]["trajectories"]), 3)
        self.rows[-1]["input"]["config"]["starting_health"] = 100
        self.write()
        with self.assertRaisesRegex(ValueError, "mixed gameplay configs"):
            self.build()

    def test_rejects_duplicate_and_missing_rounds(self):
        original = copy.deepcopy(self.rows)
        for rows in (original + original[:1], original[1:]):
            self.rows = rows
            self.write()
            with self.assertRaises(ValueError):
                self.build()

    def test_rejects_synthetic_nonblind_and_other_suite_inputs(self):
        for key, value in (("test_cards", [{"id": "plant"}]), ("suite", "spread")):
            with self.subTest(key=key):
                original = copy.deepcopy(self.rows)
                self.rows[0][key] = value
                self.write()
                with self.assertRaises(ValueError):
                    self.build()
                self.rows = original
        self.rows[0]["combat_start"][0]["layout"] = "scouted"
        self.write()
        with self.assertRaisesRegex(ValueError, "blind"):
            self.build()

    def test_rejects_missing_hero_and_line_changes(self):
        source = list(self.source)
        source[2] = {}
        with self.assertRaisesRegex(ValueError, "hero missing"):
            field_library.build_library([self.capture], [self.players], source)
        self.rows[1]["combat_start"][0]["policy"] = "hard"
        self.write()
        with self.assertRaisesRegex(ValueError, "changes line"):
            self.build()

    def test_companion_csv_inference_and_explicit_names(self):
        self.assertEqual(field_library.player_files([self.capture]), [self.players])
        self.assertEqual(field_library.player_files([Path("odd")], [self.players]), [self.players])
        with self.assertRaisesRegex(ValueError, "capture names"):
            field_library.player_files([Path("odd")])

    def test_source_fingerprints_use_requested_git_commit(self):
        hero = b'{"id":"frog","name":"Frog King"}'
        files = b"content/heroes/frog.json\ncontent/units/frog.json\ncontent/other.json\n"

        def git(*args, cwd=None):
            self.assertIsNone(cwd)
            if args[0] == "rev-parse":
                self.assertEqual(args[2], "baseline^{commit}")
                return ("c" * 40 + "\n").encode()
            if args[0] == "ls-tree":
                return files
            if args[-1].endswith("line_profiles.committed.json"):
                return b'{"line_frogs_tempo":{"tribe":"Frogs"}}'
            if args[-1].endswith("heroes/frog.json"):
                return hero
            return b'{"id":"frog"}'

        with patch.object(field_library, "git_output", side_effect=git):
            revision, hashes, names, profiles = field_library.source_data("baseline")
        self.assertEqual(revision, "c" * 40)
        self.assertEqual(hashes["content/heroes/frog.json"], hashlib.sha256(hero).hexdigest())
        self.assertNotIn("content/other.json", hashes)
        self.assertEqual(names, {"frog": "Frog King"})
        self.assertEqual(profiles["line_frogs_tempo"]["tribe"], "Frogs")
