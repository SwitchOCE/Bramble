#!/usr/bin/env python3
"""Make a local-only comparison sheet from cached reference images and Bramble after."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("after", type=Path)
    parser.add_argument("references", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    panels = [
        ("Bramble after: combat", args.after),
        ("Battlegrounds: combat (2023 reference)", args.references / "bg-wiki-2/Combat_Phase.png"),
        ("Once Upon a Galaxy: combat", args.references / "galaxy-4/g4.jpg"),
        ("Hearthstone: action (App Store reference)", args.references / "hs-appstore-5/hs5.jpg"),
        ("TFT board: marketing overlay, phase uncertain", args.references / "tft-appstore-4/tft4.jpg"),
    ]
    width, height, caption = 1200, 780, 52
    sheet = Image.new("RGB", (width * 3, (height + caption) * 2), "#eee4c6")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("DejaVuSans.ttf", 28)
    for index, (title, path) in enumerate(panels):
        x, y = index % 3 * width, index // 3 * (height + caption)
        with Image.open(path) as original:
            image = ImageOps.contain(original.convert("RGB"), (width, height))
        sheet.paste(image, (x + (width - image.width) // 2, y + caption))
        draw.text((x + 12, y + 10), title, fill="#2d271c", font=font)
    draw.multiline_text(
        (width * 2 + 24, height + caption + 50),
        "Local review sheet only\n\n"
        "Same-phase primary comparison:\nBramble / Battlegrounds / Galaxy\n\n"
        "Secondary references:\nHearthstone effects / TFT board\n\n"
        "Source links and limits are in the\nBatch 1 evidence README.\n\n"
        "Third-party images stay outside git.",
        fill="#2d271c",
        font=font,
        spacing=12,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.output, quality=85, optimize=True)
    print(f"declutter: local-only comparison sheet {args.output}")


if __name__ == "__main__":
    main()
