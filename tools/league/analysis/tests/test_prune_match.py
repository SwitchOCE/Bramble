import gzip
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from behaviours import sale_counts
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
        with self.assertRaisesRegex(ValueError, "card_report.sh"):
            prune(self.match, "climb", verdict="kept", cut_verified=True)
        self.assertTrue(self.record.is_file())
        (self.match / "card-report").mkdir()
        (self.match / "card-report/cards.csv").write_text("card\n")
        prune(self.match, "climb", verdict="kept", cut_verified=True)
        self.assertEqual({p.name for p in self.match.iterdir()},
                         {"summary.json", "analysis.json", "timing.json", "verdict.jsonl", "card-report"})
        self.assertTrue((self.match / "card-report/cards.csv").is_file())
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

    def test_trim_preserves_only_remaining_board_sale_eaters(self):
        self.reading_logs()
        actions = [
            dict(type="sell", slot=0, card="gorger"),
            dict(type="sell", slot=1, card="granary-glutton"),
            dict(type="sell", hand=0, card="granary-glutton"),
            dict(type="sell", hand=1, card="gorger"),
        ]
        self.write("library.json", [
            dict(id="gorger", tribes=["Locust"], spell=False),
            dict(id="granary-glutton", tribes=["Locust"], spell=False),
        ])
        base = dict(game=0, seat=0, colour="red", bot="red", result="", board_n=7)
        self.write("decisions.jsonl",
                   dict(base, chosen=0, legal=actions),
                   dict(base, chosen=3, legal=actions),
                   dict(base, chosen=0, legal=actions, result="refused"))
        expected = sale_counts(Match(self.match))
        self.assertEqual(expected[0, "red"], dict(sells=2, full_board_sells=1,
                                                    sales_with_gorger=1, locust_sales_with_glutton=2))
        prune(self.match, "reading")
        kept = Match(self.match)
        self.assertEqual(sale_counts(kept), expected)
        board, hand, refused = kept.rows("decisions")
        self.assertEqual(board["sale_eaters"], ["granary-glutton"])
        self.assertEqual(hand["sale_eaters"], ["gorger", "granary-glutton"])
        self.assertNotIn("sale_eaters", refused)

    def test_reading_done_keeps_findings_summary_analysis_and_tables(self):
        self.reading_logs()
        finding = self.scratch / "findings.md"
        finding.write_text("## Finding\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "requires analysis.json"):
            prune(self.match, "reading-done", findings=[finding])
        self.assertTrue(self.record.is_file())
        self.write("analysis.json", {"games": 2})
        prune(self.match, "reading")
        prune(self.match, "reading-done", findings=[finding])
        self.assertEqual({str(path.relative_to(self.match)) for path in self.match.rglob("*") if path.is_file()},
                         {"summary.json", "analysis.json", "cards.csv", "tribes.csv", "findings/findings.md"})
        self.assertEqual((self.match / "analysis.json").read_text(), '{"games": 2}\n')
        self.assertEqual((self.match / "findings/findings.md").read_bytes(), finding.read_bytes())
        self.assertIn("red,acorn,1-3,(none),0,1", (self.match / "cards.csv").read_text())
        self.assertIn("blue,(none),1,2,0,1", (self.match / "tribes.csv").read_text())

    def test_old_build_merges_tables_and_enforces_shared_limit(self):
        self.reading_logs()
        self.write("analysis.json", {"games": 2})
        finding = self.scratch / "findings.md"
        finding.write_text("## Finding\n", encoding="utf-8")
        prune(self.match, "reading-done", findings=[finding])
        second = self.scratch / "second"
        shutil.copytree(self.match, second)
        archive = self.scratch / "archive"
        build = archive / self.rules
        self.assertEqual(prune(self.match, "old-build", archive_dir=archive), build)
        self.assertEqual(list(self.match.iterdir()), [])
        prior = {p.name: p.read_bytes() for p in build.iterdir()}
        with patch("prune_match.BUILD_LIMIT", sum(map(len, prior.values()))):
            with self.assertRaisesRegex(ValueError, "archive would be"):
                prune(second, "old-build", archive_dir=archive)
        self.assertTrue((second / "summary.json").is_file())
        self.assertEqual({p.name: p.read_bytes() for p in build.iterdir()}, prior)
        self.assertEqual(prune(second, "old-build", archive_dir=archive), build)
        self.assertEqual(list(second.iterdir()), [])
        self.assertTrue(all(p.is_file() for p in build.iterdir()))
        self.assertIn("red,acorn,1-3,(none),0,2", (build / "cards.csv").read_text())
        self.assertIn("blue,(none),2,4,0,2", (build / "tribes.csv").read_text())
        self.assertEqual(gzip.decompress((build / "second+findings.md.gz").read_bytes()), finding.read_bytes())
        self.assertTrue((build / "second.summary.json").is_file())
        self.assertFalse((build / "second.analysis.json").exists())
