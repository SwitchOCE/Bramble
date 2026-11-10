#!/usr/bin/env python3
"""Check the gallery contract and the bounds/identity of every real widget placement."""
import hashlib
import json
from pathlib import Path

from PIL import Image

from layouts import OPTIONS, ROOT, SIZES

out = ROOT / "build/layouts"
manifest = json.loads((out / "manifest.json").read_text())
assert len(manifest["stills"]) == len(OPTIONS) * 2 * len(SIZES)
for still in manifest["stills"]:
    path = out / still["file"]
    with Image.open(path) as im:
        assert im.size == tuple(still["size"]), path
        im.verify()
    assert hashlib.sha256(path.read_bytes()).hexdigest() == still["sha256"], path
    plan = json.loads(path.with_suffix(".json").read_text())
    width, height = plan["logical_size"]
    for part in plan["placements"]:
        x, y = part["xy"]
        left, top, right, bottom = part["bbox"]
        w, h = (right - left) * part["ratio"], (bottom - top) * part["ratio"]
        assert x >= 0 and y >= 0 and x + w <= width + 1 and y + h <= height + 1, (path, part["key"], x, y, w, h)
        if "face_width" in part:
            native_face = part["face_width"] * still["size"][1] / 1080
            assert native_face >= 150, (path, part["key"], native_face)
            if part["role"] == "shop" and still["size"][0] == 1920:
                assert part["face_width"] >= 270, (path, part["key"], part["face_width"])
    if still["state"] == "recruit":
        keys = [part["key"] for part in plan["placements"]]
        assert all(f"shop_{i}" in keys for i in range(5)), path
        assert "spell_0" in keys, path
        assert all(f"board_{i}" in keys for i in range(7)), path
        assert all(f"lobby_{i}" in keys for i in range(8)), path
        assert all(k in keys for k in ("gold", "tier_up", "refresh", "freeze", "end_turn")), path
        assert len([k for k in keys if k.startswith("hand_")]) == 10, path
    else:
        assert all(k in [p["key"] for p in plan["placements"]] for k in ("hero_0", "hero_1", "pause", "speed")), path
for key in OPTIONS:
    with Image.open(out / key / "reader_1688x780.jpg") as im:
        assert im.size == (1688, 780)
        im.verify()
assert (out / "sheet.jpg").is_file()
assert (out / "index.html").is_file()
assert "Fresh critic" not in (ROOT / "docs/ideation/ui/layouts.md").read_text()
assert all((ROOT / "tools/mockup/art" / file).is_file() for file in ("woodland-top.jpg", "foreground.png"))
print("PASS: sixteen stills, four reader studies, native tile-size floors, checksums, widget bounds and required controls")
