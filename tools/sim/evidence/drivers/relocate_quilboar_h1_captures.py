#!/usr/bin/env python3
"""Move H1 full captures to gitignored build/, preserving provenance and compact evidence."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from checkpoint_quilboar_h1 import CAPTURE_STORAGE, verify_capture  # noqa: E402
from evidence_io import read_json, write_json  # noqa: E402


def relocate():
    evidence = ROOT / "tools/sim/evidence"
    cache = ROOT / "build/quilboar-h1-captures"
    roots = sorted(path for path in evidence.glob("quilboar-h1*") if path.is_dir())
    documents = {
        path: read_json(path)
        for root in roots
        for path in root.rglob("*")
        if path.name in {"progress.json", "receipt.json", "summary.json.gz"}
    }

    def chunks(value):
        if isinstance(value, dict):
            if "capture" in value:
                yield value
            for child in value.values():
                yield from chunks(child)
        elif isinstance(value, list):
            for child in value:
                yield from chunks(child)

    records = [entry for document in documents.values() for entry in chunks(document)]
    files = {path.relative_to(evidence) for root in roots for path in root.rglob("*.fights.jsonl.gz")}
    files.update(path.relative_to(cache) for path in cache.rglob("*.fights.jsonl.gz"))
    names = {path.name: path for path in files}
    if len(names) != len(files):
        raise ValueError("ambiguous capture names")
    total = 0
    for relative in sorted(files):
        old, local = evidence / relative, cache / relative
        entries = [entry for entry in records if Path(entry["capture"]).name == relative.name]
        if not entries:
            raise ValueError("capture has no committed provenance: " + str(relative))
        for path in (old, local):
            if path.exists():
                for entry in entries:
                    verify_capture({**entry, "capture": str(path.relative_to(ROOT))})
        if old.exists():
            local.parent.mkdir(parents=True, exist_ok=True)
            if local.exists():
                old.unlink()  # Both copies verified against the same recorded hashes.
            else:
                old.rename(local)
        total += local.stat().st_size
    for path, document in documents.items():
        changed = False
        for entry in chunks(document):
            relative = names.get(Path(entry["capture"]).name)
            if relative is None:
                raise ValueError("recorded capture has no local bytes during relocation")
            local = str((cache / relative).relative_to(ROOT))
            if entry["capture"] != local or entry.get("capture_storage") != CAPTURE_STORAGE:
                entry.update(capture=local, capture_storage=CAPTURE_STORAGE)
                changed = True
        if changed:
            write_json(path, document)
    print(f"{len(files)} captures, {total:,} bytes: {CAPTURE_STORAGE}; all hashes verified")


if __name__ == "__main__":
    relocate()
