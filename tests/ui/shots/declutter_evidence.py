"""Read fresh JSON and losslessly compressed slim evidence reports."""

import gzip
import json
from pathlib import Path


def read_json(path: Path):
    if path.suffix == ".gz":
        with gzip.open(path, "rt") as stream:
            return json.load(stream)
    if path.exists():
        return json.loads(path.read_text())
    return read_json(Path(str(path) + ".gz"))


def original_image(path: Path) -> Path:
    """Prefer preserved capture pixels when rebuilding or comparing native sheets."""
    root = Path(__file__).resolve().parents[3]
    packet = root / "docs/ideation/evidence/declutter/batch2"
    resolved = path.absolute()
    if resolved.is_relative_to(packet):
        original = root / "build/declutter-b2-evidence/originals" / resolved.relative_to(packet)
        for candidate in (original.with_suffix(".png"), original):
            if candidate.exists():
                return candidate
    return path
