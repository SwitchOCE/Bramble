import gzip
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cards import card_stats
from match_data import Match
from prune_match import prune
from tribes import tribe_stats


class Pruning(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.scratch = Path(scratch.name)
        self.match = self.scratch / "match"
        self.match.mkdir()
        self.rules = "a" * 64
        self.write("summary.json", dict(
            schema=1, complete=True, inline_reports=True, mode="async", rules_hash=self.rules,
            red="red", blue="blue", red_label="candidate", blue_label="incumbent",
            games=2, seeds_sha256="b" * 64, gap_red_minus_blue=-1,
        ))
        (self.match / "records").mkdir()
        self.record = self.match / "records/game-00000.jsonl"
        self.record.write_bytes(b'{"op":"header","format":4}\n')

    def write(self, name, *entries):
        (self.match / name).write_text("".join(json.dumps(row) + "\n" for row in entries), encoding="utf-8")

    def reading_logs(self):
        self.write("library.json", [dict(id="acorn", tribes=["Mouse"], spell=False)])
        self.write("games.jsonl", *(dict(
            game=i, swapped=bool(i), red_seats=[] if i else [0], fights=[],
            seats=[dict(seat=0, colour=team, bot=team, place=i + 1, main_tribe=None, pivots=[],
                        commit_round=None, final_board=[], rounds=[dict(
                            round=1, tribes={}, board=[], tier=1, board_attack=0, board_health=0,
                            gold_left=1, gold_from_cards=0,
                        )])],
        ) for i, team in enumerate(("red", "blue"))))
        identity = dict(game=0, seat=0, round=1, colour="red", bot="red")
        self.write("shops.jsonl", dict(identity, offers=[dict(card="acorn", buyable=True, spell=False)],
                                       bought=[], values=[["acorn", 2]], strategy="collect"))
        self.write("decisions.jsonl", dict(
            identity, result="", chosen=1, legal=[dict(type="end_turn"), dict(type="pick", card="acorn")],
            discover_options=["acorn"], strategy="collect",
        ))

    def test_kept_climb_requires_cut_and_records_verdict(self):
        self.write("analysis.json", dict(
            games=2, seed_pairs=1, bots=dict(red="red", blue="blue"),
            score=dict(gap_red_minus_blue=-1, gap_ci95=0),
        ))
        self.write("timing.json", {"seconds": 2})
        with self.assertRaisesRegex(ValueError, "--cut-verified"):
            prune(self.match, "climb", verdict="kept")
        self.assertTrue(self.record.is_file())
        prune(self.match, "climb", verdict="kept", cut_verified=True)
        self.assertEqual({p.name for p in self.match.iterdir()},
                         {"summary.json", "analysis.json", "timing.json", "verdict.jsonl"})
        verdict = (self.match / "verdict.jsonl").read_text()
        self.assertEqual(len(verdict.splitlines()), 1)
        self.assertEqual(json.loads(verdict)["red"], "candidate")
        self.assertEqual(json.loads(verdict)["gap_ci95"], [-1, -1])

    def test_reading_keeps_choices_and_raw_record(self):
        self.reading_logs()
        self.write("reports.jsonl", {"debug": True})
        record = self.record.read_bytes()
        original = Match(self.match)
        cards, tribes = card_stats(original), tribe_stats(original)
        prune(self.match, "reading")
        kept = Match(self.match)
        self.assertEqual(cards, card_stats(kept))
        self.assertEqual(tribes, tribe_stats(kept))
        self.assertFalse(kept.has_log("reports"))
        row, = kept.rows("decisions")
        self.assertNotIn("legal", row)
        self.assertNotIn("chosen", row)
        self.assertEqual(row["action"]["card"], "acorn")
        self.assertEqual(gzip.decompress(self.record.with_suffix(".jsonl.gz").read_bytes()), record)
        decisions = self.match / "decisions.jsonl.gz"
        first = decisions.read_bytes()
        prune(self.match, "reading")
        self.assertEqual(decisions.read_bytes(), first)

    def test_field_refuses_unverified_cut_and_symlinks(self):
        outside = self.scratch / "outside"
        outside.mkdir()
        protected = outside / "protected"
        protected.write_bytes(b"keep")
        with self.assertRaisesRegex(ValueError, "--cut-verified"):
            prune(self.match, "field")
        self.assertTrue(self.record.is_file())
        (self.match / "records/linked").symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symbolic link"):
            prune(self.match, "field", cut_verified=True)
        self.assertEqual(protected.read_bytes(), b"keep")
        self.assertTrue(self.record.is_file())

    def test_old_build_publishes_tables_and_enforces_shared_limit(self):
        self.reading_logs()
        archive = self.scratch / "archive"
        finding = self.scratch / "findings.md"
        finding.write_text("## Finding\n" + "x" * 1500, encoding="utf-8")
        build = archive / self.rules
        build.mkdir(parents=True)
        previous = build / "previous.md"
        previous.write_bytes(b"a" * 1000)
        prune(self.match, "reading")
        with patch("prune_match.BUILD_LIMIT", 2500):
            with self.assertRaisesRegex(ValueError, "archive would be"):
                prune(self.match, "old-build", archive_dir=archive, findings=[finding])
        self.assertTrue(self.record.with_suffix(".jsonl.gz").is_file())
        self.assertFalse((build / "match").exists())
        self.assertEqual(prune(self.match, "old-build", archive_dir=archive, findings=[finding]), build)
        self.assertEqual(list(self.match.iterdir()), [])
        self.assertIn("red,acorn,1-3,(none),0,1", (build / "match/cards.csv").read_text())
        self.assertIn("blue,(none),1,1,2.0,0,1", (build / "match/tribes.csv").read_text())
        self.assertEqual((build / "match/findings/findings.md").read_bytes(), finding.read_bytes())
        self.assertEqual(previous.stat().st_size, 1000)
