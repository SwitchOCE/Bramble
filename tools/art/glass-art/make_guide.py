"""Draws the shape guide that is attached to every card-art prompt, and writes window.json for assemble.py.

The guide is a plain grey panel in the outline of the card's art window, grown a little so a picture that comes
back slightly small still fills the window. Run it again whenever WINDOW below changes:

    python tools/art/glass-art/make_guide.py
"""
import json
import math
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))

# The art window, in card units (card = 560 x 1000): the window of the guide the thin frames were drawn to
# (card frames session, 15 Nov 2026). The sharper frames' own windows sit 1.6 to 3.3 units inside it, except
# tier 5, whose upper sloping edges reach 5.2 units past it. A working spec, not locked.
WINDOW = [(280, 52.5), (529.1, 188.4), (529.1, 811.6), (280, 947.5), (30.9, 811.6), (30.9, 188.4)]
# Extra on every side, in card units, so the art reaches under the border. Codex returns the panel within about
# 7 canvas px (5 units). 12 leaves tier 5 a margin of 6.8 units and the other tiers 13.6 or more. At about 13 the
# art starts to show past the frame's outer edge on tiers 3 and 4. Measure again when the frame files change.
BLEED = 12
# Codex's portrait canvas, and where the card sits on it.
CANVAS = (1024, 1536)
SCALE = 1.44
ORIGIN = (108.8, 48)


def grow(poly, d):
    """Push every edge of a convex polygon outward by d."""
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)

    def normal(p, q):
        dx, dy = q[0] - p[0], q[1] - p[1]
        length = math.hypot(dx, dy)
        nx, ny = dy / length, -dx / length
        mx, my = (p[0] + q[0]) / 2 - cx, (p[1] + q[1]) / 2 - cy
        return (nx, ny) if nx * mx + ny * my > 0 else (-nx, -ny)

    out, n = [], len(poly)
    for k in range(n):
        a, b, c = poly[k - 1], poly[k], poly[(k + 1) % n]
        n1, n2 = normal(a, b), normal(b, c)
        bx, by = n1[0] + n2[0], n1[1] + n2[1]
        length = math.hypot(bx, by)
        bx, by = bx / length, by / length
        reach = d / (bx * n1[0] + by * n1[1])
        out.append((b[0] + bx * reach, b[1] + by * reach))
    return out


def main():
    art = grow(WINDOW, BLEED)
    on_canvas = [(ORIGIN[0] + SCALE * x, ORIGIN[1] + SCALE * y) for x, y in art]
    with open(os.path.join(HERE, "window.json"), "w") as f:
        json.dump({"canvas": CANVAS, "scale": SCALE, "origin": ORIGIN, "window": WINDOW, "bleed": BLEED,
                   "art": art, "art_on_canvas": on_canvas}, f, indent=1)
    s = 4  # draw big and shrink, for a smooth edge
    guide = Image.new("RGB", (CANVAS[0] * s, CANVAS[1] * s), (12, 12, 13))
    d = ImageDraw.Draw(guide)
    pts = [(x * s, y * s) for x, y in on_canvas]
    d.polygon(pts, fill=(120, 126, 134))
    d.line(pts + pts[:1], fill=(20, 16, 12), width=7 * s, joint="curve")
    guide.resize(CANVAS, Image.LANCZOS).save(os.path.join(HERE, "guide.png"), optimize=True)
    print("guide.png and window.json written; art area on the canvas:", [(round(x), round(y)) for x, y in on_canvas])


if __name__ == "__main__":
    main()
