"""Compressed evidence preserves historical bytes and rejects corrupt pointers."""

import gzip
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from evidence_io import FORMAT, json_bytes, json_sha, read_json, write_json
from field import load_designed, sample_field

ROOT = Path(__file__).resolve().parents[2]


class EvidenceIOTests(unittest.TestCase):
    def pointer(self, directory, raw=b'{"answer":42}\n'):
        source = directory / "input.json"
        archive = directory / "input.json.gz"
        with archive.open("wb") as output, gzip.GzipFile(fileobj=output, mode="wb", filename="", mtime=0) as stream:
            stream.write(raw)
        metadata = {
            "format": FORMAT,
            "archive": archive.name,
            "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            "uncompressed_sha256": hashlib.sha256(raw).hexdigest(),
            "uncompressed_bytes": len(raw),
        }
        source.write_text(json.dumps(metadata))
        return source, archive, metadata

    def test_plain_direct_gzip_and_verified_pointer_have_identical_data_hash(self):
        with tempfile.TemporaryDirectory() as temporary:
            source, archive, _ = self.pointer(Path(temporary))
            plain = Path(temporary) / "plain.json"
            plain.write_bytes(b'{"answer":42}\n')
            for path in [source, archive, plain]:
                self.assertEqual(read_json(path), {"answer": 42})
                self.assertEqual(json_sha(path), hashlib.sha256(plain.read_bytes()).hexdigest())
                self.assertEqual(json_bytes(path), plain.read_bytes())

    def test_compressed_writer_is_deterministic_and_roundtrips(self):
        with tempfile.TemporaryDirectory() as temporary:
            paths = [Path(temporary) / name for name in ["one.json.gz", "two.json.gz"]]
            for path in paths:
                write_json(path, {"boards": [1, 2], "none": None})
                self.assertEqual(read_json(path), {"boards": [1, 2], "none": None})
            self.assertEqual(paths[0].read_bytes(), paths[1].read_bytes())

    def test_each_pointer_integrity_field_is_enforced(self):
        mutations = {
            "archive_sha256": ("0" * 64, "compressed hash"),
            "uncompressed_sha256": ("0" * 64, "uncompressed hash"),
            "uncompressed_bytes": (0, "size"),
        }
        for key, (bad, error) in mutations.items():
            with self.subTest(key=key), tempfile.TemporaryDirectory() as temporary:
                source, _, metadata = self.pointer(Path(temporary))
                metadata[key] = bad
                source.write_text(json.dumps(metadata))
                with self.assertRaisesRegex(ValueError, error):
                    read_json(source)

    def test_pointer_does_not_follow_absolute_or_parent_paths(self):
        for name in ["../outside.json.gz", "/tmp/outside.json.gz", "folder/archive.json.gz", "not-gzip.json"]:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                source, _, metadata = self.pointer(Path(temporary))
                metadata["archive"] = name
                source.write_text(json.dumps(metadata))
                with self.assertRaisesRegex(ValueError, "sibling"):
                    read_json(source)

    def test_corrupt_gzip_payload_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            source, archive, metadata = self.pointer(Path(temporary))
            archive.write_bytes(b"not gzip")
            metadata["archive_sha256"] = hashlib.sha256(archive.read_bytes()).hexdigest()
            source.write_text(json.dumps(metadata))
            with self.assertRaises(gzip.BadGzipFile):
                read_json(source)

    def test_historical_designed_input_retains_frozen_hash_and_field(self):
        plan = json.loads((ROOT / "tools/sim/evidence/designed-first-plan.json").read_text())
        frozen = next(field for field in plan["fields"] if field["id"] == "screen")
        original_cwd = Path.cwd()
        # Frozen provenance paths are relative to the repository, as in the original run.
        import os

        try:
            os.chdir(ROOT)
            source = Path(frozen["input"])
            self.assertEqual(json_sha(source), frozen["input_sha256"])
            boards, weights = load_designed(source)
            field = sample_field(
                boards, tuple(frozen["rounds"]), frozen["boards_per_round"], 91407, line_weights=weights
            )
            self.assertEqual(hashlib.sha256((json.dumps(field) + "\n").encode()).hexdigest(), frozen["field_sha256"])
        finally:
            os.chdir(original_cwd)

    def test_designed_generator_can_write_gzip_for_existing_reader(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "setup.json.gz"
            subprocess.run(
                [sys.executable, str(ROOT / "tools/sim/designed_setups.py"), "board", "--out", str(output)],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
            boards, _ = load_designed(output)
            self.assertEqual(len(boards), 1)
            self.assertEqual(boards[0]["design"]["target_total"], 500)


if __name__ == "__main__":
    unittest.main()
