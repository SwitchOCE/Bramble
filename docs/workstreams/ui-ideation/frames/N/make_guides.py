"""Take N's outline guides for the frame pass: thin lines on black, one per tier, plus a spell guide.

Card units: 560 x 1000. The card sits on Codex's 1024 x 1536 canvas at 1.44 times with its top-left at
(108.8, 48), the same placement as the card-art guide (tools/art/glass-art/window.json), so frame and art share
one coordinate frame.

    python docs/workstreams/ui-ideation/frames/N/make_guides.py /data/bramble-art/uiid-frames/N/guide
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

CANVAS = (1024, 1536)
SCALE = 1.44
ORIGIN = (108.8, 48)
S = 4  # supersample

OUTER = [(280, 0), (560, 170), (560, 830), (280, 1000), (0, 830), (0, 170)]
# Today's art window above the join; unchanged, so art painted to today's window still fits there.
WIN_TOP = [(30.9, 188.4), (280, 52.5), (529.1, 188.4)]
BASE_X = 30.9        # window side edge, the same as today's all the way down
BASE_CORNER_Y = 795  # window lower corners (today: 811.6)
BASE_POINT_Y = 905   # window bottom point (today: 947.5; today's tiers 2-6 accents already cover to 820-880)
RIM = 9              # outer lead came, all round
ROUNDELS = [((110, 780), 60), ((450, 780), 60)]
# Where the glass base starts on each side (its tip), per tier: the base climbs a little as the tier rises.
TIP = {1: 700, 2: 685, 3: 670, 4: 655, 5: 640, 6: 620}
TIP_LOW = 720        # the low-base alternates
# Highest the ornament at the bottom point may rise into the window, per tier.
CREST = {1: 905, 2: 893, 3: 881, 4: 869, 5: 857, 6: 845}
BEAD_R = 11


def c(p):
    return ((ORIGIN[0] + SCALE * p[0]) * S, (ORIGIN[1] + SCALE * p[1]) * S)


def bead_positions(tier):
    """Pale glass beads = tier count, on the two bottom chevrons of the base, mirror-symmetric."""
    # Along the chevron band centre line, from beside the roundel towards the point.
    def on_left(t):  # t in 0..1 along left chevron band centre, from x=172 to x=250
        x = 172 + t * 78
        # band centre: halfway between outer edge and window edge at this x
        y_outer = 830 + (x / 280) * 170
        y_win = BASE_CORNER_Y + ((x - BASE_X) / (280 - BASE_X)) * (BASE_POINT_Y - BASE_CORNER_Y)
        return (x, (y_outer + y_win) / 2)
    pairs = tier // 2
    pts = []
    for k in range(pairs):
        t = 0.5 if pairs == 1 else k / (pairs - 1)
        x, y = on_left(t)
        pts += [(x, y), (560 - x, y)]
    if tier % 2:
        pts.append((280, (1000 + BASE_POINT_Y) / 2 + 4))
    return pts


def window_poly(tip):
    left_down = [(30.9, 188.4), (30.9, BASE_CORNER_Y)]
    point = [(280, BASE_POINT_Y)]
    right_up = [(560 - x, y) for x, y in left_down]
    return [(280, 52.5)] + right_up + point + left_down[::-1]


def join_lines(tip):
    """The top edge of the glass base on each side: from the inside of the outer rim at the tip, slanting down
    to the window edge, so the glass is a wedge that thickens downward."""
    l = [(RIM, tip), (30.9, tip + 40)]
    r = [(560 - RIM, tip), (529.1, tip + 40)]
    return l, r


def draw_card(tier, tip, beads=True, crest=True):
    im = Image.new("RGB", (CANVAS[0] * S, CANVAS[1] * S), (17, 18, 21))
    d = ImageDraw.Draw(im)
    w_main, w_thin = 3 * S, 2 * S
    col_main, col_thin = (175, 175, 178), (130, 130, 134)
    o = [c(p) for p in OUTER]
    d.line(o + o[:1], fill=col_main, width=w_main, joint="curve")
    w = [c(p) for p in window_poly(tip)]
    d.line(w + w[:1], fill=col_thin, width=w_thin, joint="curve")
    for line in join_lines(tip):
        d.line([c(p) for p in line], fill=col_thin, width=w_thin)
    for (cx, cy), r in ROUNDELS:
        x0, y0 = c((cx - r, cy - r))
        x1, y1 = c((cx + r, cy + r))
        d.ellipse((x0, y0, x1, y1), outline=col_main, width=w_thin)
    if beads:
        for bx, by in bead_positions(tier):
            x0, y0 = c((bx - BEAD_R, by - BEAD_R))
            x1, y1 = c((bx + BEAD_R, by + BEAD_R))
            d.ellipse((x0, y0, x1, y1), outline=col_main, width=w_thin)
    if crest and CREST[tier] < BASE_POINT_Y:
        # A short arc above the window's bottom point: the ornament there stays below it.
        cy = CREST[tier]
        pts = [c((280 + dx, cy + (dx / 60) ** 2 * 14)) for dx in range(-60, 61, 4)]
        d.line(pts, fill=col_thin, width=w_thin)
    return im.resize(CANVAS, Image.LANCZOS)


def draw_spell(tier_arc_deg=55):
    """Round spell: outer circle, inner window circle, and the two radial lines where the glass arc starts.
    The glass fills the ring below them (the lower third of the ring)."""
    im = Image.new("RGB", (CANVAS[0] * S, CANVAS[1] * S), (17, 18, 21))
    d = ImageDraw.Draw(im)
    cx, cy, R, r = 280, 500, 280, 250
    for rad, col in ((R, (175, 175, 178)), (r, (130, 130, 134))):
        x0, y0 = c((cx - rad, cy - rad))
        x1, y1 = c((cx + rad, cy + rad))
        d.ellipse((x0, y0, x1, y1), outline=col, width=3 * S)
    # glass arc from 30 degrees below horizontal on each side, down round the bottom (the lower third of the ring)
    for sgn in (-1, 1):
        a = math.radians(30)
        p_out = (cx + sgn * (R - RIM) * math.cos(a), cy + (R - RIM) * math.sin(a))
        p_in = (cx + sgn * r * math.cos(a + 0.12), cy + r * math.sin(a + 0.12))
        d.line([c(p_out), c(p_in)], fill=(130, 130, 134), width=2 * S)
    return im.resize(CANVAS, Image.LANCZOS)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for t in range(1, 7):
        draw_card(t, TIP[t]).save(os.path.join(out, f"guide-t{t}.png"), optimize=True)
    draw_card(3, TIP_LOW).save(os.path.join(out, "guide-low-t3.png"), optimize=True)
    draw_card(6, TIP_LOW).save(os.path.join(out, "guide-low-t6.png"), optimize=True)
    draw_spell().save(os.path.join(out, "guide-spell.png"), optimize=True)
    geo = {"card_units": [560, 1000], "canvas": CANVAS, "scale": SCALE, "origin": ORIGIN, "outer": OUTER,
           "rim": RIM, "roundels": ROUNDELS, "tip": TIP, "tip_low": TIP_LOW, "crest": CREST, "bead_r": BEAD_R,
           "beads": {t: bead_positions(t) for t in range(1, 7)},
           "window": {t: window_poly(TIP[t]) for t in range(1, 7)},
           "spell": {"centre": [280, 500], "outer_r": 280, "window_r": 250, "glass_from_deg_below_horizontal": 30}}
    with open(os.path.join(out, "geometry.json"), "w") as f:
        json.dump(geo, f, indent=1)
    print("written to", out)


if __name__ == "__main__":
    main()
