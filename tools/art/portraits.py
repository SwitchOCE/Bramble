#!/usr/bin/env python3
"""Export portrait masters to game JPEGs, and build contact sheets to check them by eye.

tools/art/portraits.py export <masters-dir> [<out-dir>]    512x512 JPEGs, quality 82
tools/art/portraits.py sheet <out.jpg> <cell-px> <columns> <image ...>
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 512
QUALITY = 82
LABEL_HEIGHT = 16


def export(masters: Path, out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    for master in sorted(masters.glob("*.png")):
        image = Image.open(master).convert("RGB")
        side = min(image.size)
        left = (image.width - side) // 2
        top = (image.height - side) // 2
        image = image.crop((left, top, left + side, top + side))
        image = image.resize((SIZE, SIZE), Image.LANCZOS)
        image.save(out / f"{master.stem}.jpg", quality=QUALITY, optimize=True, progressive=False)


def sheet(target: Path, cell: int, columns: int, images: list[Path]) -> None:
    rows = (len(images) + columns - 1) // columns
    canvas = Image.new("RGB", (columns * cell, rows * (cell + LABEL_HEIGHT)), "white")
    draw = ImageDraw.Draw(canvas)
    for index, path in enumerate(images):
        x = index % columns * cell
        y = index // columns * (cell + LABEL_HEIGHT)
        thumb = Image.open(path).convert("RGB").resize((cell - 2, cell - 2), Image.LANCZOS)
        canvas.paste(thumb, (x + 1, y + 1))
        draw.text((x + 3, y + cell + 1), path.stem, fill="black")
    canvas.save(target, quality=80, optimize=True)


def main() -> int:
    args = sys.argv[1:]
    if len(args) >= 2 and args[0] == "export":
        out = Path(args[2]) if len(args) > 2 else Path("assets/portraits")
        export(Path(args[1]), out)
        return 0
    if len(args) >= 5 and args[0] == "sheet":
        sheet(Path(args[1]), int(args[2]), int(args[3]), [Path(a) for a in args[4:]])
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
