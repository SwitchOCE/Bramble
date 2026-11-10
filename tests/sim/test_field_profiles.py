"""Field captures resolve merged line profiles from their source commit."""

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from field_library import gameplay_hash, read_trajectories, source_profiles


class SourceProfilesTest(unittest.TestCase):
    def test_source_commit_overrides_replace_legacy_tribe_and_keep_other_lines(self):
        files = {
            "tools/sim/line_profiles.committed.json": {
                "line_bog_engine": {"tribe": "Bog folk"},
                "line_hunters_engine": {"tribe": "Hunters"},
            },
            "tools/sim/lines/bog.json": {"bog_court": {"tribe": "bog"}},
        }

        def git(*args, cwd=None):
            self.assertEqual(cwd, "/source")
            if args[0] == "ls-tree":
                self.assertEqual(args[3], "frozen")
                return b"tools/sim/lines/bog.json\n"
            self.assertTrue(args[1].startswith("frozen:"))
            return json.dumps(files[args[1].split(":", 1)[1]]).encode()

        with patch("field_library.git_output", side_effect=git):
            profiles = source_profiles("frozen", cwd="/source")
        self.assertEqual(set(profiles), {"line_bog_court", "line_hunters_engine"})

        self.assertEqual(profiles["line_bog_court"]["tribe"], "Bog folk")

    def test_native_policy_pivot_keeps_the_starting_line(self):
        records = []
        for number, policy in ((1, "line_birds_tempo"), (2, "line_birds_homecoming")):
            records.append(
                {
                    "suite": "lines",
                    "seed": 71,
                    "leg": 0,
                    "input": {
                        "version": 1,
                        "config": {},
                        "round": number,
                        "player_ids": [0, -1],
                        "boards": [[None] * 7, [None] * 7],
                        "slots": [[[]] * 7, [[]] * 7],
                        "hero_effects": [[], []],
                        "fight_rules": [{}, {}],
                        "tiers": [1, 1],
                    },
                    "combat_start": [{"layout": "blind", "policy": policy, "starting_line": "line_birds_tempo"}, {}],
                }
            )
        metadata = {(71, 0, 0): {"hero": "hero", "finish_place": 1, "lobby_tribes": ["Birds"]}}
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "capture.jsonl"
            path.write_text("".join(json.dumps(row) + "\n" for row in records))
            _, trajectories = read_trajectories([path], metadata, {"hero": "Hero"})
        self.assertEqual(next(iter(trajectories))["line"], "line_birds_tempo")

    def test_fractional_gameplay_hash_matches_runtime_json_precision(self):
        expected = hashlib.sha256(b'{"share":0.333333333333333}').hexdigest()
        self.assertEqual(gameplay_hash({"share": 1 / 3}), expected)
