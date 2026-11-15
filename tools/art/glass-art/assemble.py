"""Checks card-art pictures against the shape guide and builds finished cards, with no fitting by hand.

For each PNG in the art folder it:
  1. measures how far the panel's edges are from the guide's (the check);
  2. moves the picture into card space (1120 x 2000) with one fixed crop;
  3. keeps the art window plus its bleed, and lays a frame on top.

    python tools/art/glass-art/assemble.py <art folder> <out folder> [--tiers 1,6] [--frames <folder>]

Run make_guide.py first if window.json is missing. Frames default to docs/design/art-direction/frame-lab/final.
"""
import argparse
import glob
import json
import os
import sys

from PIL import Image, ImageChops, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
TIERS = ["tier1-common", "tier2-uncommon", "tier3-rare", "tier4-epic", "tier5-legendary", "tier6-mythic"]
CARD = (1120, 2000)   # card space: the 560 x 1000 spec doubled
TOLERANCE = 9         # canvas px a panel edge may sit from the guide's before the picture is flagged;
                      # tier 5's top corners have 9.8 px of art to spare
MARK = (255, 0, 255)


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


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("art")
    ap.add_argument("out")
    ap.add_argument("--tiers", default="1,2,3,4,5,6")
    ap.add_argument("--frames", default=os.path.join(REPO, "docs", "design", "art-direction", "frame-lab", "final"))
    a = ap.parse_args()
    spec_path = os.path.join(HERE, "window.json")
    if not os.path.exists(spec_path):
        sys.exit("window.json is missing: run make_guide.py first")
    spec = json.load(open(spec_path))
    w, h = spec["canvas"]
    s, (ox, oy) = spec["scale"], spec["origin"]
    box = tuple(round(v) for v in (ox, oy, ox + 560 * s, oy + 1000 * s))  # where the card sits on Codex's canvas
    art_area = Image.new("L", CARD, 0)
    ImageDraw.Draw(art_area).polygon([(x * 2, y * 2) for x, y in spec["art"]], fill=255)
    # Measure the guide picture the same way as the art, so the guide itself reads 0 on every side.
    # (Its dark outline counts as ground in the flood fill, as a picture's outer lead line does.)
    gb = ImageChops.invert(outside_of_panel(Image.open(os.path.join(HERE, "guide.png")).convert("RGB"))).getbbox()
    tiers = [int(t) for t in a.tiers.split(",")]
    frames = {t: Image.open(os.path.join(a.frames, TIERS[t - 1] + ".png")).convert("RGBA") for t in tiers}
    os.makedirs(a.out, exist_ok=True)
    flagged = 0
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
        art = im.crop(box).resize(CARD, Image.LANCZOS)
        for t in tiers:
            card = Image.new("RGBA", CARD, (13, 17, 15, 255))
            card.paste(art, (0, 0), art_area)
            card.alpha_composite(frames[t])
            card.convert("RGB").save(os.path.join(a.out, "%s-t%d.jpg" % (name, t)), quality=90)
    print("%d picture(s) off the guide" % flagged)


if __name__ == "__main__":
    main()
