#!/usr/bin/env python3
"""Check actual decoded halo pixels, not node properties. See taste-dupes.md for the run commands."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]
CANDIDATES = {
    "a_shop": (335, 245, 12, 150),
    "a_board": (85, 665, 12, 150),
    "a_hand": (335, 665, 12, 150),
    "b_shop": (1295, 245, 12, 150),
    "b_board": (1045, 665, 12, 150),
    "b_hand": (1295, 665, 12, 150),
}
SHOP = {"shop_triple": (1031, 189, 9, 150)}


def brightness(path: Path, rect: tuple[int, int, int, int]) -> list[float]:
    """Decode every frame, averaging BT.601 luma in the outside-left halo, excluding card art."""
    x, y, width, height = rect
    command = [
        "ffmpeg",
        "-v",
        "error",
        "-threads",
        "2",
        "-filter_threads",
        "1",
        "-i",
        str(path),
        "-vf",
        f"crop={width}:{height}:{x}:{y}:exact=1",
        "-f",
        "rawvideo",
        "-pix_fmt",
        "rgb24",
        "pipe:1",
    ]
    raw = subprocess.run(command, capture_output=True, check=True).stdout
    stride = width * height * 3
    if not raw or len(raw) % stride:
        raise ValueError(f"{path}: incomplete decoded frames")
    return [
        ImageStat.Stat(Image.frombytes("RGB", (width, height), raw[i : i + stride]).convert("L")).mean[0]
        for i in range(0, len(raw), stride)
    ]


def periods() -> list[float]:
    source = (ROOT / "src/glass/glass_duplicate_glow.gd").read_text()
    found = re.search(r"const PERIODS: Array\[float\] = (\[[^\n]+\])", source)
    if found is None:
        raise ValueError("missing pulse periods")
    return json.loads(found[1])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates", type=Path)
    parser.add_argument("--shop", type=Path)
    parser.add_argument("--normal-before", type=Path)
    parser.add_argument("--normal-after", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    report: dict = {"luma": "Pillow L / BT.601, 0-255", "regions": {}, "passed": True}
    for path, regions in [(args.candidates, CANDIDATES), (args.shop, SHOP)]:
        if path is None:
            continue
        for name, rect in regions.items():
            curve = brightness(path, rect)
            source = (ROOT / "src/glass/glass_duplicate_glow.gd").read_text()
            selected = re.search(r"const SELECTED: int = (\d+)", source)
            if selected is None:
                raise ValueError("missing selected pulse candidate")
            candidate = int(selected[1]) if name == "shop_triple" else int(name.startswith("b_"))
            period = periods()[candidate]
            # Frame 6 is after the five setup frames; sample a complete period from there.
            indices = [6 + round(period * 60 * phase / 4) for phase in range(5)]
            if indices[-1] >= len(curve):
                raise ValueError(f"{path}: too short for a complete pulse period")
            samples = [curve[i] for i in indices]
            passed = max(curve) - min(curve) > 1.0 and samples[0] - samples[2] > 1.0
            report["regions"][name] = {
                "file": str(path),
                "rect_xywh": rect,
                "frames": len(curve),
                "period_seconds": period,
                "min": min(curve),
                "max": max(curve),
                "sample_frames": indices,
                "samples": samples,
                "curve": curve,
                "passed": passed,
            }
            report["passed"] &= passed
    if args.normal_before is not None and args.normal_after is not None:
        before = Image.open(args.normal_before).convert("RGB")
        after = Image.open(args.normal_after).convert("RGB")
        equal = before.size == after.size and ImageChops.difference(before, after).getbbox() is None
        report["normal_card_pixel_identical"] = equal
        report["passed"] &= equal
    if not report["regions"]:
        raise ValueError("provide at least one film")
    args.out.write_text(json.dumps(report, indent=2) + "\n")
    summary = {key: value for key, value in report.items() if key != "regions"}
    summary["regions"] = {
        name: {key: value for key, value in region.items() if key != "curve"}
        for name, region in report["regions"].items()
    }
    print(json.dumps(summary, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
