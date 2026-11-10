"""Tests for tools/checks/test_shards.py: every test script runs in exactly one shard of the
sharded gate, and a script with no recorded time still runs."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.checks import test_shards

SCRIPTS = [
    "tests/core/test_a.gd",
    "tests/core/test_b.gd",
    "tests/core/deep/test_c.gd",
    "tests/sim/test_d.gd",
    "tests/ui/test_e.gd",
    "tests/ui/test_f.gd",
    "tests/ui/test_g.gd",
]
NOT_TESTS = ["tests/core/helper.gd", "tests/fixtures/board.gd", "tests/core/test_notes.md", "src/test_src.gd"]
TIMES = {"res://" + s: t for s, t in zip(SCRIPTS, [120.0, 90.0, 60.0, 30.0, 20.0, 5.0, 1.0], strict=True)}


class TestShardsTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        config = {"dirs": ["res://tests"], "include_subdirs": True, "prefix": "test_", "suffix": ".gd"}
        (self.root / ".gutconfig.json").write_text(json.dumps(config))
        for rel in SCRIPTS + NOT_TESTS:
            (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
            (self.root / rel).write_text("extends GutTest\n")
        self.all = test_shards.discover(self.root)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_discover_finds_only_gut_test_scripts(self) -> None:
        self.assertEqual(self.all, sorted("res://" + s for s in SCRIPTS))

    def test_every_script_in_exactly_one_shard_and_union_is_everything(self) -> None:
        for n in (1, 2, 3, 4, 7, 9):
            shards = test_shards.assign(self.all, TIMES, n)
            self.assertEqual(len(shards), n)
            flat = [s for shard in shards for s in shard]
            self.assertEqual(len(flat), len(set(flat)), f"a script is in two shards (n={n})")
            self.assertEqual(sorted(flat), self.all, f"union differs from the full set (n={n})")

    def test_new_script_lands_somewhere_and_known_scripts_stay(self) -> None:
        before = test_shards.assign(self.all, TIMES, 3)
        new = "res://tests/core/test_new.gd"
        after = test_shards.assign([*self.all, new], TIMES, 3)
        self.assertEqual(sum(s == new for shard in after for s in shard), 1)
        for old, cur in zip(before, after, strict=True):
            self.assertEqual([s for s in cur if s != new], old)

    def test_no_times_at_all_still_covers_everything(self) -> None:
        shards = test_shards.assign(self.all, {}, 4)
        self.assertEqual(sorted(s for shard in shards for s in shard), self.all)
        self.assertTrue(all(shards), "an empty shard with 7 scripts over 4 shards")

    def test_balanced_by_time(self) -> None:
        loads = [sum(TIMES[s] for s in shard) for shard in test_shards.assign(self.all, TIMES, 2)]
        self.assertEqual(sorted(loads), [156.0, 170.0])

    def test_parse_shard(self) -> None:
        self.assertEqual(test_shards.parse_shard("2/4"), (2, 4))
        for bad in ("0/4", "5/4", "4", "a/b", "1/0"):
            with self.assertRaises(ValueError):
                test_shards.parse_shard(bad)

    def test_times_from_junit_merges_shard_files_and_inner_classes(self) -> None:
        xml = '<testsuites><testsuite name="tests/core/test_a.gd" time="2.5"/>{}</testsuites>'
        (self.root / "1.xml").write_text(xml.format('<testsuite name="res://tests/core/test_a.gd.Inner" time="1"/>'))
        (self.root / "2.xml").write_text(xml.format("").replace("test_a", "test_b"))
        times = test_shards.times_from_junit([self.root / "1.xml", self.root / "2.xml"])
        self.assertEqual(times, {"res://tests/core/test_a.gd": 3.5, "res://tests/core/test_b.gd": 2.5})

    def test_committed_times_cover_the_real_suite(self) -> None:
        # Not required for correctness (new scripts get a default weight), but a stale file means
        # unbalanced shards: refresh it with `test_shards.py times build/check/gut.xml`.
        times = test_shards.load_times()
        scripts = test_shards.discover()
        missing = [s for s in scripts if s not in times]
        self.assertLessEqual(len(missing) * 4, len(scripts), f"{len(missing)} scripts have no time: {missing[:5]}")


if __name__ == "__main__":
    unittest.main()
