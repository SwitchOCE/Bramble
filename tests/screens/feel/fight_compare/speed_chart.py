#!/usr/bin/env python3
"""Speed over time of each attacker in a comparison fight film (README.md beside this file).

Usage: speed_chart.py <film stem> [out.png] [--ymax PX_PER_S]
Reads <stem>.report.json and <stem>.cards.csv (written by fight_compare.gd when filmed with
tools/feel/film) and draws one panel per attack: the attacker's centre speed in film pixels a
second, frame by frame from 2 frames before the attack starts to 1 s after, with its contact
(red) and first burst (orange) marked and step changes as grey ticks. Pillow only.
"""

import argparse
import csv
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BEFORE = 2
AFTER = 60
PANEL_W, PANEL_H = 760, 250
PAD_L, PAD_R, PAD_T, PAD_B = 70, 16, 34, 40
INK, GRID, LINE = (40, 40, 40), (225, 225, 225), (30, 80, 160)
CONTACT, BURST, STEP = (200, 40, 40), (230, 140, 20), (160, 160, 160)


def load(stem: Path) -> tuple[dict, dict]:
    report = json.loads(stem.with_suffix(".report.json").read_text())
    centres: dict = {}
    steps: dict = {}
    with stem.with_suffix(".cards.csv").open() as f:
        for row in csv.DictReader(f):
            frame = int(row["frame"])
            centres[(frame, row["key"])] = (float(row["x"]), float(row["y"]))
            steps[frame] = int(row["step"])
    return report, {"centres": centres, "steps": steps}


def speeds(log: dict, key: str, first: int, last: int) -> list[tuple[int, float]]:
    out = []
    for frame in range(first, last + 1):
        a = log["centres"].get((frame - 1, key))
        b = log["centres"].get((frame, key))
        if a and b:
            out.append((frame, math.dist(a, b) * 60.0))
    return out


def panel(draw: ImageDraw.ImageDraw, ox: int, oy: int, attack: dict, log: dict, ymax: float, font, small) -> None:
    start = attack["start_frame"]
    first, last = start - BEFORE, min(attack["end_frame"], start + AFTER)
    pw, ph = PANEL_W - PAD_L - PAD_R, PANEL_H - PAD_T - PAD_B
    x0, y0 = ox + PAD_L, oy + PAD_T

    def px(frame: float) -> float:
        return x0 + (frame - first) / (start + AFTER - first) * pw

    def py(v: float) -> float:
        return y0 + ph - min(v, ymax) / ymax * ph

    title = "attack %d: %s -> %s  (slot %s -> %s)" % (
        attack["attack"],
        attack["attacker_card"],
        attack["target_card"],
        attack["from"][1],
        attack["to"][1],
    )
    draw.text((x0, oy + 8), title, fill=INK, font=font)
    for i in range(5):
        v = ymax * i / 4
        draw.line([(x0, py(v)), (x0 + pw, py(v))], fill=GRID)
        draw.text((ox + 6, py(v) - 8), "%d" % v, fill=INK, font=small)
    for f in range(0, AFTER + 1, 10):
        draw.line([(px(start + f), y0 + ph), (px(start + f), y0 + ph + 4)], fill=INK)
        draw.text((px(start + f) - 8, y0 + ph + 6), str(f), fill=INK, font=small)
    draw.text((x0 + pw - 210, y0 + ph + 22), "frames after the attack starts", fill=INK, font=small)
    last_step = None
    for frame in range(first, last + 1):
        step = log["steps"].get(frame)
        if last_step is not None and step != last_step:
            draw.line([(px(frame), y0), (px(frame), y0 + 10)], fill=STEP, width=2)
        last_step = step
    for name, colour in (("contact_frame", CONTACT), ("burst_frame", BURST)):
        frame = attack.get(name, -1)
        if first <= frame <= start + AFTER:
            draw.line([(px(frame), y0), (px(frame), y0 + ph)], fill=colour, width=2)
            label_y = y0 + 2 if name == "contact_frame" else y0 + 16
            draw.text((px(frame) + 3, label_y), name.replace("_frame", ""), fill=colour, font=small)
    points = [(px(f), py(v)) for f, v in speeds(log, attack["attacker"], first, last)]
    if len(points) > 1:
        draw.line(points, fill=LINE, width=2)
    for p in points:
        draw.ellipse([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], fill=LINE)
    draw.rectangle([x0, y0, x0 + pw, y0 + ph], outline=INK)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("stem", help="the film's stem (or its .mp4)")
    parser.add_argument("out", nargs="?", help="the chart (default: <stem>.speed.png)")
    parser.add_argument("--ymax", type=float, help="the y axis top in px/s (default: the top speed, rounded up)")
    opts = parser.parse_args()
    stem = Path(opts.stem)
    if stem.suffix == ".mp4":
        stem = stem.with_suffix("")
    out = Path(opts.out) if opts.out else stem.parent / (stem.name + ".speed.png")
    report, log = load(stem)
    attacks = report["attacks"]
    top = 0.0
    for a in attacks:
        for _, v in speeds(log, a["attacker"], a["start_frame"] - BEFORE, a["end_frame"]):
            top = max(top, v)
    ymax = opts.ymax if opts.ymax else math.ceil(top / 1000) * 1000
    cols = 2
    rows = math.ceil(len(attacks) / cols)
    head = 50
    image = Image.new("RGB", (cols * PANEL_W, head + rows * PANEL_H), "white")
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=16)
    small = ImageFont.load_default(size=12)
    draw.text(
        (12, 12),
        "Attacker speed, film px/s (%s, treatment: %s); y axis 0-%d; one dot per film frame (60 fps)"
        % (stem.name, report.get("treatment", "?"), ymax),
        fill=INK,
        font=ImageFont.load_default(size=20),
    )
    for i, attack in enumerate(attacks):
        panel(draw, (i % cols) * PANEL_W, head + (i // cols) * PANEL_H, attack, log, ymax, font, small)
    image.save(out)
    print("%s: %d attacks, top speed %.0f px/s" % (out, len(attacks), top))
    return 0


if __name__ == "__main__":
    sys.exit(main())
