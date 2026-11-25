"""Checks card-art pictures against the shape guide and shows each one on the game's card, with no fitting by hand.

For each PNG in the art folder it:
  1. measures how far the panel's edges are from the guide's (the check);
  2. moves the picture into card space (560 x 1000) with the recipe's one fixed crop, as prep_units.py does;
  3. draws a preview of the game's card over it: the lead outline, the part of the picture the card shows,
     and where the Attack and Health discs sit (empty: the game draws the numbers).

    python tools/art/glass-art/assemble.py <art folder> <out folder>

It writes <name>.png (the card at 4 times game size, 560 x 1000), <name>-game.png (140 x 250, the size
it is in the game) and sheet.jpg (every card at twice game size). The card's numbers are read from the
game's own layout file, assets/glass/l1/layout.json, so the preview follows the game. It is an outline
for judging the art, not the game's look: the lead is flat, with no gradient, bevel, slab or light.

Run make_guide.py first if window.json is missing.
"""
import argparse
import glob
import json
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, HERE)
from make_guide import grow  # noqa: E402

LAYOUT = os.path.join(REPO, "assets", "glass", "l1", "layout.json")
CARD = (560, 1000)    # card space: the art file's size
K = 4                 # preview scale: 4 preview px per game px (a 140 x 250 card becomes 560 x 1000)
SUPER = 4             # drawn this much bigger and shrunk, for smooth edges
TOLERANCE = 12        # canvas px a panel edge may sit from the guide's before the picture is flagged
MARK = (255, 0, 255)
LEAD = (35, 39, 38)   # the middle of the game's lead gradient
GROUND = (14, 18, 17)
DISC = (230, 214, 180)
RIM = (28, 32, 31)
RIM_LINE = (85, 91, 88)


def outside_of_panel(im):
    """Mask of the near-black ground round the panel, found by flood fill from the four corners."""
    c = im.copy()
    w, h = c.size
    for seed in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        if c.getpixel(seed) != MARK:
            ImageDraw.floodfill(c, seed, MARK, thresh=42)
    r, g, b = c.split()
    hit = lambda want: (lambda v: 255 if v == want else 0)
    return ImageChops.darker(ImageChops.darker(r.point(hit(255)), b.point(hit(255))), g.point(hit(0)))


def card_spec():
    """The game card's numbers, in game px, from the L1 layout file."""
    raw = json.load(open(LAYOUT))
    n = lambda key: raw[key]["value"]
    w, h = n("card.w"), n("card.h")
    rise = w * math.tan(math.radians(n("board.point_angle"))) / 2
    outline = [(w / 2, 0), (w, rise), (w, h - rise), (w / 2, h), (0, h - rise), (0, rise)]
    r = n("card.stat.d") / 2
    discs = [(n("card.stat.%s.x" % s) + r, n("card.stat.%s.y" % s) + r) for s in ("attack", "health")]
    return {
        "size": (w, h),
        "outline": outline,
        "window": grow(outline, -n("card.lead.width")),
        "crop": (n("card.art.x"), n("card.art.y"), n("card.art.x") + n("card.art.w"), n("card.art.y") + n("card.art.h")),
        "discs": discs,
        "r": r,
        "rim": n("card.stat.rim"),
        "line": n("card.stat.outline"),
    }


def preview(card_art, spec):
    """The card at K times game size: lead outline, the art in the window, the two discs."""
    w, h = spec["size"]
    s = K * SUPER
    size = (round(w * s), round(h * s))
    pts = lambda poly: [(x * s, y * s) for x, y in poly]
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(out).polygon(pts(spec["outline"]), fill=LEAD)
    window = Image.new("L", size, 0)
    ImageDraw.Draw(window).polygon(pts(spec["window"]), fill=255)
    art = card_art.crop(spec["crop"]).resize(size, Image.LANCZOS)
    ground = Image.new("RGB", size, GROUND)
    ground.paste(art, (0, 0))
    out.paste(ground, (0, 0), window)
    d = ImageDraw.Draw(out)
    r, rim, line = spec["r"], spec["rim"], spec["line"]
    for cx, cy in spec["discs"]:
        for radius, colour in ((r + rim + line, RIM_LINE), (r + rim, RIM), (r, DISC)):
            d.ellipse([(cx - radius) * s, (cy - radius) * s, (cx + radius) * s, (cy + radius) * s], fill=colour)
    return out.resize((round(w * K), round(h * K)), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("art")
    ap.add_argument("out")
    a = ap.parse_args()
    spec_path = os.path.join(HERE, "window.json")
    if not os.path.exists(spec_path):
        sys.exit("window.json is missing: run make_guide.py first")
    window = json.load(open(spec_path))
    w, h = window["canvas"]
    s, (ox, oy) = window["scale"], window["origin"]
    box = tuple(round(v) for v in (ox, oy, ox + CARD[0] * s, oy + CARD[1] * s))  # where the card sits on Codex's canvas
    card = card_spec()
    # Measure the guide picture the same way as the art, so the guide itself reads 0 on every side.
    # (Its dark outline counts as ground in the flood fill, as a picture's outer lead line does.)
    gb = ImageChops.invert(outside_of_panel(Image.open(os.path.join(HERE, "guide.png")).convert("RGB"))).getbbox()
    os.makedirs(a.out, exist_ok=True)
    flagged, made = 0, []
    for path in sorted(glob.glob(os.path.join(a.art, "*.png"))):
        name = os.path.splitext(os.path.basename(path))[0]
        im = Image.open(path).convert("RGB")
        if im.size != (w, h):
            im = im.resize((w, h), Image.LANCZOS)
        pb = ImageChops.invert(outside_of_panel(im)).getbbox()
        off = [pb[i] - gb[i] for i in range(4)]
        ok = all(abs(v) <= TOLERANCE for v in off)
        flagged += 0 if ok else 1
        print("%-12s left %+d, top %+d, right %+d, bottom %+d px  %s" % (name, off[0], off[1], off[2], off[3], "ok" if ok else "OFF THE GUIDE: make it again"))
        big = preview(im.crop(box).resize(CARD, Image.LANCZOS), card)
        big.save(os.path.join(a.out, name + ".png"))
        big.resize(tuple(round(v) for v in card["size"]), Image.LANCZOS).save(os.path.join(a.out, name + "-game.png"))
        made.append(big)
    if made:
        cw, ch = (round(v * 2) for v in card["size"])
        gap = 20
        sheet = Image.new("RGB", (gap + len(made) * (cw + gap), ch + 2 * gap), (24, 26, 27))
        for i, big in enumerate(made):
            small = big.resize((cw, ch), Image.LANCZOS)
            sheet.paste(small, (gap + i * (cw + gap), gap), small)
        sheet.save(os.path.join(a.out, "sheet.jpg"), quality=88)
    print("%d picture(s) off the guide" % flagged)


if __name__ == "__main__":
    main()
