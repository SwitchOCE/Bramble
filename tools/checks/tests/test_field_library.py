"""Field libraries preserve combat boundaries and sample complete persistent seats."""

import copy
import csv
import gzip
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.sim import field_library


class FieldLibraryTests(unittest.TestCase):
    def test_gzip_output_round_trips_and_is_deterministic(self):
        data = {"lines": {"probe": [1, 2, 3]}, "text": "Héllo"}
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "library.json.gz"
            raw_bytes, stored_bytes = field_library.write_library(path, data)
            first = path.read_bytes()
            self.assertEqual(json.loads(gzip.decompress(first)), data)
            self.assertEqual(stored_bytes, len(first))
            self.assertEqual(raw_bytes, len(gzip.decompress(first)))
            field_library.write_library(path, data)
            self.assertEqual(first, path.read_bytes())
            plain = Path(directory) / "library.json"
            field_library.write_library(plain, data)
            self.assertEqual(plain.read_bytes(), gzip.decompress(first))

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
        self.placements = {1: 1, 2: 2, 3: 6}
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
            writer = csv.DictWriter(stream, ["suite", "seed", "leg", "seat", "hero", "place", "lobby_tribes"])
            writer.writeheader()
            for seed in (1, 2, 3):
                writer.writerow(
                    {
                        "suite": "lines",
                        "seed": seed,
                        "leg": 0,
                        "seat": 0,
                        "hero": "frog",
                        "place": self.placements[seed],
                        "lobby_tribes": "Frogs+Birds",
                    }
                )

    def build(self, **kwargs):
        return field_library.build_library([self.capture], [self.players], self.source, **kwargs)

    def test_exact_inputs_hero_and_provenance_survive_serialization(self):
        library = json.loads(field_library.canonical(self.build(per_line=10)))
        self.assertEqual(library["version"], 2)
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
        self.assertEqual(trajectory["finish_place"], 1)
        self.assertEqual(trajectory["lobby_tribes"], ["Birds", "Frogs"])
        self.assertEqual(
            {key: trajectory["rounds"]["1"][key] for key in field_library.SIDE_KEYS},
            field_library._side(self.rows[0]["input"], 0),
        )
        self.assertEqual(len(trajectory["rounds"]["1"]["views"]), 7)

    def test_top4_source_filter_removes_lower_finishers_before_sampling(self):
        all_seats = self.build()
        winners = self.build(strength="top4")
        all_selected = all_seats["lines"]["line_frogs_tempo"]["trajectories"]
        selected = winners["lines"]["line_frogs_tempo"]["trajectories"]
        self.assertEqual(len(all_selected), 3)
        self.assertEqual([row["id"] for row in selected], ["1:0:0", "2:0:0"])
        self.assertTrue(all(row["finish_place"] <= 4 for row in selected))
        self.assertEqual(winners["source"]["strength_filter"], "top4")
        self.assertEqual(all_seats["source"]["strength_filter"], "all")
        self.placements = dict.fromkeys((1, 2, 3), 8)
        self.write()
        with self.assertRaisesRegex(ValueError, "no trajectories eligible"):
            self.build(strength="top4")

    def test_sampling_is_seeded_and_keeps_longest_coverage(self):
        self.placements = dict.fromkeys((1, 2, 3), 6)
        self.write()
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

    def test_a35_lobbies_reuse_real_captures_without_relabelling_the_suite(self):
        for row in self.rows:
            row["suite"] = "a35_run1"
        self.write()
        with self.players.open(newline="") as stream:
            reader = csv.DictReader(stream)
            columns = reader.fieldnames
            seats = list(reader)
        with self.players.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, columns)
            writer.writeheader()
            writer.writerows({**seat, "suite": "a35_run1"} for seat in seats)
        result = self.build(strength="top4")
        self.assertEqual(result["source"]["strength_filter"], "top4")
        self.assertTrue(result["lines"])
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

    def test_gameplay_manifest_ignores_presentation_but_keeps_mechanic_counter_names(self):
        original = {
            "id": "frog",
            "name": "Frog",
            "attack": 3,
            "text": "old",
            "details": "old",
            "golden_text": "old",
            "golden_details": "old",
            "overlay_text": {"any": "old"},
            "portrait_path": "old.png",
            "source": {"doc": "old"},
            "mechanics": [{"id": "effect", "name": "limited_buff", "limit": 1, "do": {"effect": "buff", "attack": 2}}],
        }
        changed = copy.deepcopy(original)
        for key in ("name", "text", "details", "golden_text", "golden_details", "portrait_path"):
            changed[key] = "new"
        changed["overlay_text"] = {"new": "copy"}
        changed["source"] = {"doc": "new"}
        self.assertEqual(field_library.gameplay_hash(original), field_library.gameplay_hash(changed))
        changed["mechanics"][0]["name"] = "a_different_counter"
        self.assertNotEqual(field_library.gameplay_hash(original), field_library.gameplay_hash(changed))
        changed = copy.deepcopy(original)
        changed["attack"] += 1
        self.assertNotEqual(field_library.gameplay_hash(original), field_library.gameplay_hash(changed))
        schema = {"keywords": {"Ring": "old"}, "size_cap_overlay": {"text_rules": ["old"], "unbounded": ["cap"]}}
        next_schema = copy.deepcopy(schema)
        next_schema["keywords"]["Ring"] = "new"
        next_schema["size_cap_overlay"]["text_rules"] = ["new"]
        self.assertEqual(
            field_library.gameplay_hash(schema, schema=True), field_library.gameplay_hash(next_schema, schema=True)
        )

    def test_sampling_keeps_strength_and_source_rotation_coverage(self):
        source = list(self.source)
        rows = []
        for seed in range(1, 13):
            row = self.fight(seed, 1)
            row["combat_start"][0]["policy"] = "line_frogs_tempo"
            rows.append(row)
        self.rows = rows
        self.capture.write_text("".join(json.dumps(row) + "\n" for row in rows))
        with self.players.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, ["suite", "seed", "leg", "seat", "hero", "place", "lobby_tribes"])
            writer.writeheader()
            for seed in range(1, 13):
                writer.writerow(
                    {
                        "suite": "lines",
                        "seed": seed,
                        "leg": 0,
                        "seat": 0,
                        "hero": "frog",
                        "place": 1 if seed <= 10 else 8,
                        "lobby_tribes": "Birds+Frogs",
                    }
                )
        library = field_library.build_library([self.capture], [self.players], source, per_line=1)
        selected = library["lines"]["line_frogs_tempo"]["trajectories"]
        self.assertEqual(sum(row["finish_place"] <= 4 for row in selected), 8)
        self.assertEqual(sum(row["finish_place"] > 4 for row in selected), 1)
        self.assertEqual(library["source"]["coverage"]["Birds+Frogs"], {"all": 9, "top4": 8})

    def test_rejects_invalid_source_placement(self):
        self.placements[1] = 0
        self.write()
        with self.assertRaisesRegex(ValueError, "placement"):
            self.build()

    def test_source_fingerprints_use_requested_git_commit(self):
        hero = b'{"id":"frog","name":"Frog King"}'
        files = (
            b"content/heroes/frog.json\ncontent/units/frog.json\ncontent/other.json\n"
            b"content/levers/engine.json\ncontent/schema/effects.json\ncontent/pass3/rates.json\n"
        )

        def git(*args, cwd=None):
            self.assertIsNone(cwd)
            if args[0] == "rev-parse":
                self.assertEqual(args[2], "baseline^{commit}")
                return ("c" * 40 + "\n").encode()
            if args[0] == "ls-tree":
                return b"" if args[-1] == "tools/sim/lines" else files
            if args[-1].endswith("line_profiles.committed.json"):
                return b'{"line_frogs_tempo":{"tribe":"Frogs"}}'
            if args[-1].endswith("heroes/frog.json"):
                return hero
            return b'{"id":"frog"}'

        with patch.object(field_library, "git_output", side_effect=git):
            revision, hashes, names, profiles = field_library.source_data("baseline")
        self.assertEqual(revision, "c" * 40)
        self.assertEqual(hashes["content/heroes/frog.json"], field_library.gameplay_hash(json.loads(hero)))
        self.assertNotIn("content/other.json", hashes)
        self.assertIn("content/levers/engine.json", hashes)
        self.assertIn("content/schema/effects.json", hashes)
        self.assertIn("content/pass3/rates.json", hashes)
        self.assertEqual(names, {"frog": "Frog King"})
        self.assertEqual(profiles["line_frogs_tempo"]["tribe"], "Frogs")
