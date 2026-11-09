"""Read plain/gzipped JSON and verified pointers to exact historical JSON bytes.

Pointer paths are local sibling archives. json_sha hashes the uncompressed data,
so storage compression does not silently change a frozen input's content hash.
"""

from __future__ import annotations

import gzip
import hashlib
import json
from pathlib import Path

FORMAT = "bramble-json-archive-v1"


def json_bytes(path):
    path = Path(path)
    raw = path.read_bytes()
    if path.suffix == ".gz":
        return gzip.decompress(raw)
    document = json.loads(raw)
    if not isinstance(document, dict) or document.get("format") != FORMAT:
        return raw
    name = document.get("archive")
    if not isinstance(name, str) or Path(name).name != name or not name.endswith(".gz"):
        raise ValueError("JSON archive pointer must name a sibling .gz file")
    packed = (path.parent / name).read_bytes()
    if hashlib.sha256(packed).hexdigest() != document.get("archive_sha256"):
        raise ValueError("JSON archive compressed hash mismatch")
    data = gzip.decompress(packed)
    if type(document.get("uncompressed_bytes")) is not int or len(data) != document["uncompressed_bytes"]:
        raise ValueError("JSON archive uncompressed size mismatch")
    if hashlib.sha256(data).hexdigest() != document.get("uncompressed_sha256"):
        raise ValueError("JSON archive uncompressed hash mismatch")
    return data


def json_sha(path):
    return hashlib.sha256(json_bytes(path)).hexdigest()


def read_json(path):
    return json.loads(json_bytes(path))


def write_json(path, value, *, indent=2):
    path = Path(path)
    raw = (json.dumps(value, indent=indent, allow_nan=False) + "\n").encode()
    if path.suffix == ".gz":
        with path.open("wb") as target, gzip.GzipFile(fileobj=target, mode="wb", filename="", mtime=0) as stream:
            stream.write(raw)
    else:
        path.write_bytes(raw)
