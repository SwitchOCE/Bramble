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
