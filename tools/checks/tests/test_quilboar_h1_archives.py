"""Full captures stay local; missing bytes are allowed, missing hashes and corruption are not."""
import gzip
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

DRIVERS = Path(__file__).resolve().parents[2] / "sim/evidence/drivers"
sys.path.insert(0, str(DRIVERS))
import checkpoint_quilboar_h1 as archive_driver  # noqa: E402


class QuilboarH1ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.root_patch = patch.object(archive_driver, "ROOT", self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.raw = b'{"fight":"synthetic"}\n'
        self.compressed = gzip.compress(self.raw, mtime=0)
        self.chunk = {
            "arm": "B", "first_seed": 1, "lobbies": 1, "scope_seconds": 1,
            "capture": "run/B-1.fights.jsonl.gz",
            "capture_sha256": hashlib.sha256(self.raw).hexdigest(),
            "capture_gzip_sha256": hashlib.sha256(self.compressed).hexdigest(),
        }
        self.evidence = self.root / "tools/sim/evidence/quilboar-h1/B/B-1.fights.jsonl.gz"
        self.local = self.root / "build/quilboar-h1-captures/quilboar-h1/B/B-1.fights.jsonl.gz"

    def _put_source(self):
        source = self.root / self.chunk["capture"]
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(self.compressed)
        return source

    def test_missing_capture_is_not_in_git_with_both_hashes_recorded(self):
        self.assertFalse(archive_driver.verify_capture(self.chunk))
        copied = archive_driver.archive_capture(self.chunk, self.evidence)
        self.assertEqual(copied["capture_storage"], "not in git, hash recorded")
        self.assertEqual(copied["capture"], str(self.local.relative_to(self.root)))
        self.assertEqual(copied["capture_sha256"], self.chunk["capture_sha256"])
        self.assertEqual(copied["capture_gzip_sha256"], self.chunk["capture_gzip_sha256"])
        self.assertFalse(self.local.exists())

    def test_available_capture_is_verified_and_copied_only_into_build(self):
        self._put_source()
        copied = archive_driver.archive_capture(self.chunk, self.evidence)
        self.assertTrue(archive_driver.verify_capture(copied))
        self.assertEqual(self.local.read_bytes(), self.compressed)
        self.assertFalse(self.evidence.exists())

    def test_corrupt_compressed_or_raw_capture_still_fails(self):
        source = self._put_source()
        source.write_bytes(b"corrupt")
        with self.assertRaisesRegex(ValueError, "changed compressed"):
            archive_driver.verify_capture(self.chunk)
        source.write_bytes(self.compressed)
        with self.assertRaisesRegex(ValueError, "changed decompressed"):
            archive_driver.verify_capture({**self.chunk, "capture_sha256": "0" * 64})

    def test_missing_capture_without_hashes_is_an_error(self):
        for field in ("capture_sha256", "capture_gzip_sha256"):
            missing = dict(self.chunk)
            missing.pop(field)
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "capture hash"):
                archive_driver.verify_capture(missing)

    def test_conflicting_local_capture_is_not_overwritten(self):
        source = self._put_source()
        self.local.parent.mkdir(parents=True)
        self.local.write_bytes(b"conflict")
        with self.assertRaisesRegex(ValueError, "changed compressed"):
            archive_driver.archive_capture(self.chunk, self.evidence)
        self.assertEqual(self.local.read_bytes(), b"conflict")
        self.assertEqual(source.read_bytes(), self.compressed)

    def test_checkpoint_succeeds_without_full_capture(self):
        folder = self.root / "run"
        folder.mkdir()
        for field in ("compact", "players", "log"):
            self.chunk[field] = f"run/B-1.{field}.json"
            (self.root / self.chunk[field]).write_text(
                json.dumps([{"seed": 1, "rounds": []}]) if field == "compact" else ""
            )
        (folder / "progress.json").write_text(json.dumps({
            "completed": {"B": 1}, "chunks": [self.chunk], "plan_sha256": "c" * 64,
        }))
        plan = self.root / "plan.json"
        plan.write_text(json.dumps({"source_commit": "fixture"}))
        target = self.evidence.parents[1]
        with patch.object(archive_driver, "ARMS", {"B": 1}), patch("builtins.print"):
            archive_driver.archive("B", plan, folder, target)
        receipt = json.loads((target / "B/receipt.json").read_text())
        self.assertEqual(receipt["lobbies"], 1)
        self.assertEqual(receipt["chunks"][0]["capture_storage"], "not in git, hash recorded")
        self.assertEqual(receipt["chunks"][0]["capture_sha256"], self.chunk["capture_sha256"])
        self.assertFalse(self.local.exists())


if __name__ == "__main__":
    unittest.main()
