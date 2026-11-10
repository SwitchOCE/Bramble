"""Turn Godot's fixed-frame PNG sequence into a compact GIF and labelled contact sheet."""

import sys
from pathlib import Path

from PIL import Image, ImageDraw


def main():
    directory = Path(sys.argv[1])
    fps, count = int(sys.argv[2]), int(sys.argv[3])
    start = int((directory / "ready").read_text())
    paths = sorted((directory / "frames").glob("frame*.png"))[start : start + count]
    if len(paths) < count:
        raise ValueError(f"Movie produced {len(paths)} ready frames; expected {count}")
    # Keep every captured frame in the GIF; thumbnails bound memory even for a 60-second clip.
    images = []
    for path in paths:
        with Image.open(path) as image:
            image.thumbnail((640, 360))
            images.append(image.convert("RGB"))
    images[0].save(directory / "clip.gif", save_all=True, append_images=images[1:], duration=1000 / fps, loop=0)
    indices = sorted({round(i * (len(images) - 1) / 11) for i in range(12)})
    width, height = images[0].size
    sheet = Image.new("RGB", (width * 3, (height + 24) * ((len(indices) + 2) // 3)), "#202020")
    draw = ImageDraw.Draw(sheet)
    for cell, index in enumerate(indices):
        x, y = cell % 3 * width, cell // 3 * (height + 24)
        sheet.paste(images[index], (x, y))
        draw.text((x + 8, y + height + 4), f"{index / fps:.2f}s", fill="white")
    sheet.save(directory / "contact.png")
    print(directory / "contact.png")
    print(directory / "clip.gif")


if __name__ == "__main__":
    main()
