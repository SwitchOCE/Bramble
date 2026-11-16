"""Puts recipe pictures into the game as unit card art: assets/units/<tribe>/<unit id>.jpg.

    python tools/art/glass-art/prep_units.py <tribe> <master.png>[=<unit id>] ...

Each master is a 1024 x 1536 Codex picture made by the card art recipe. It is moved into card space
with the recipe's one fixed crop (window.json: the card at its scale and origin on the canvas) and
saved at 560 x 1000, as the mock-ups' prep_assets.py does for assets/glass/art. The unit id is the
file name unless given after "=". Nothing is scaled or nudged by hand; a picture off the guide is
made again, not fitted. The game clips the art to the art window, so it is not masked here.
"""
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CARD = (560, 1000)


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    tribe, items = sys.argv[1], sys.argv[2:]
    spec = json.load(open(os.path.join(HERE, "window.json")))
    s, (ox, oy) = spec["scale"], spec["origin"]
    box = (round(ox), round(oy), round(ox + 560 * s), round(oy + 1000 * s))
    out = os.path.join(REPO, "assets", "units", tribe)
    os.makedirs(out, exist_ok=True)
    for item in items:
        path, _, unit = item.partition("=")
        unit = unit or os.path.splitext(os.path.basename(path))[0]
        im = Image.open(path).convert("RGB")
        if im.size != tuple(spec["canvas"]):
            sys.exit(f"{path}: {im.size}, expected {spec['canvas']}; remake it, don't fit it")
        im.crop(box).resize(CARD, Image.LANCZOS).save(os.path.join(out, unit + ".jpg"), quality=86)
        print(tribe, unit, "<-", path)


if __name__ == "__main__":
    main()
