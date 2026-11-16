#!/usr/bin/env python3
"""Makes the STAND-IN card art for a unit with no picture yet: a plain glass panel in its
tribe's colour, quarry panes in lead, in card space (560 x 1000, like assets/units).

    python3 tools/game/stand_in_panels.py        writes assets/game/stand-in/<tribe>.jpg

The colours are the flow's stand-ins, not decided tribe colours. A tribe folder with no entry
here gets `neutral`. Nothing here is decided for the real game.
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "game" / "stand-in"
SIZE = (560, 1000)
PANE = 112  # quarry diamond width
LEAD = (34, 30, 28)
# STAND-IN tribe colours (folder name -> RGB), picked to tell the tribes apart.
COLOURS: dict[str, tuple[int, int, int]] = {
    "badger": (92, 106, 122),
    "mouse": (178, 136, 76),
    "pigeon": (104, 138, 176),
    "locust": (140, 134, 46),
    "thorn": (112, 60, 92),
    "neutral": (122, 118, 108),
}


def panel(colour: tuple[int, int, int], seed: int) -> Image.Image:
    rng = random.Random(seed)
    w, h = SIZE
    img = Image.new("RGB", SIZE, LEAD)
    draw = ImageDraw.Draw(img)
    half = PANE // 2
    tall = int(PANE * 1.5) // 2
    for row in range(-1, h // tall + 2):
        for col in range(-1, w // PANE + 2):
            cx = col * PANE + (half if row % 2 else 0)
            cy = row * tall
            # light falls from the top: panes lower down are a little darker
            shade = 1.12 - 0.35 * (cy / h) + rng.uniform(-0.09, 0.09)
            fill = tuple(max(0, min(255, int(c * shade))) for c in colour)
            diamond = [(cx, cy - tall), (cx + half, cy), (cx, cy + tall), (cx - half, cy)]
            draw.polygon(diamond, fill=fill, outline=LEAD, width=7)
    return img.filter(ImageFilter.GaussianBlur(0.8))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (name, colour) in enumerate(sorted(COLOURS.items())):
        panel(colour, i).save(OUT / f"{name}.jpg", quality=85)
        print(f"wrote {OUT / name}.jpg")


if __name__ == "__main__":
    main()
