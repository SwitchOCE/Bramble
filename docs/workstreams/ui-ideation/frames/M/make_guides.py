"""Take M's shape guides for the frame pass (stage 1). Thin grey lines on near-black, no fills, on Codex's
1024 x 1536 canvas, card placed as in frame-lab/guides/single-0.56-thin.png (x 106, y 43, 1.45 px per unit).

Writes into /data/bramble-art/uiid-frames/M/guide/:
  tier1-r2.png ..         round 2: the same with the join moved (JOIN_Y2) and drawn bold
  tier1.png .. tier6.png  card outline, today's window line, two fixed roundels, and the join ticks for that tier
  spell1.png, spell6.png  round spell: outer and inner ring circles and the join ticks
  today-tier1.png ..      today's frame of that tier, placed on the same canvas, on charcoal (glass reference only)
  guides.json             every number used, in card units (card 560 x 1000)

    python docs/workstreams/ui-ideation/frames/M/make_guides.py
"""
import json
import math
import os

from PIL import Image, ImageDraw

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 5))
OUT = "/data/bramble-art/uiid-frames/M/guide"
CANVAS = (1024, 1536)
ORIGIN = (106.0, 43.0)
S = 1.45  # canvas px per card unit
BG = (16, 17, 19)
LINE = (150, 150, 150)

CARD = [(280, 0), (560, 170), (560, 830), (280, 1000), (0, 830), (0, 170)]
WINDOW = [(280, 52.5), (529.1, 188.4), (529.1, 811.6), (280, 947.5), (30.9, 811.6), (30.9, 188.4)]  # today's art window
ROUNDELS = [(111, 766), (449, 766)]  # one position for every tier (today's six vary by a few units)
ROUNDEL_R = 78  # outer edge of the ring; the cream disc inside is about 62
JOIN_Y = {1: 690, 2: 664, 3: 638, 4: 612, 5: 586, 6: 560}  # where the glass begins on the two long sides
# Round 2: bigger steps (round 1's 26-unit steps were ignored and too small to read at 112 px); bolder ticks
# that run out past the card edge, so they cannot be mistaken for anything else. Files tier1-r2.png .. tier6-r2.png.
JOIN_Y2 = {1: 720, 2: 688, 3: 656, 4: 624, 5: 592, 6: 560}
FLEURON_TOP = {1: 947.5, 2: 925, 3: 910, 4: 898, 5: 888, 6: 878}  # highest point the bottom crest may reach
SPELL_R, SPELL_BAND = 238, 31
SPELL_JOIN_DEG = {1: 55, 6: 80}  # glass arc, each side of straight down

TODAY = {1: "tier1-common", 2: "tier2-uncommon", 3: "tier3-rare", 4: "tier4-epic", 5: "tier5-legendary", 6: "tier6-mythic"}


def c(p):
    return (ORIGIN[0] + S * p[0], ORIGIN[1] + S * p[1])


def draw_tier(t, joins=None, suffix="", tick=1, reach=0):
    joins = joins or JOIN_Y
    k = 4
    im = Image.new("RGB", (CANVAS[0] * k, CANVAS[1] * k), BG)
    d = ImageDraw.Draw(im)
    w = 2 * k
    for poly in (CARD, WINDOW):
        pts = [(x * k, y * k) for x, y in map(c, poly)]
        d.line(pts + pts[:1], fill=LINE, width=w, joint="curve")
    for cx, cy in ROUNDELS:
        (px, py), r = c((cx, cy)), ROUNDEL_R * S
        d.ellipse([(px - r) * k, (py - r) * k, (px + r) * k, (py + r) * k], outline=LINE, width=w)
    y = joins[t]
    for x0, x1 in ((0 - reach, 30.9), (529.1, 560 + reach)):
        (ax, ay), (bx, by) = c((x0, y)), c((x1, y))
        d.line([(ax * k, ay * k), (bx * k, by * k)], fill=LINE, width=w * tick)
    im.resize(CANVAS, Image.LANCZOS).save(os.path.join(OUT, f"tier{t}{suffix}.png"), optimize=True)


def draw_spell(t):
    k = 4
    im = Image.new("RGB", (CANVAS[0] * k, CANVAS[1] * k), BG)
    d = ImageDraw.Draw(im)
    w = 2 * k
    cx, cy = c((280, 500))
    for r in (SPELL_R, SPELL_R - SPELL_BAND):
        r *= S
        d.ellipse([(cx - r) * k, (cy - r) * k, (cx + r) * k, (cy + r) * k], outline=LINE, width=w)
    a = math.radians(SPELL_JOIN_DEG[t])
    for sgn in (-1, 1):
        ang = math.pi / 2 + sgn * a  # measured from +x, y down: pi/2 is straight down
        p = [(cx + math.cos(ang) * r * S, cy + math.sin(ang) * r * S) for r in (SPELL_R, SPELL_R - SPELL_BAND)]
        d.line([(p[0][0] * k, p[0][1] * k), (p[1][0] * k, p[1][1] * k)], fill=LINE, width=w)
    im.resize(CANVAS, Image.LANCZOS).save(os.path.join(OUT, f"spell{t}.png"), optimize=True)


def place_today(t):
    src = Image.open(os.path.join(REPO, "docs/design/art-direction/frame-lab/final", TODAY[t] + ".png")).convert("RGBA")
    src = src.resize((round(560 * S), round(1000 * S)), Image.LANCZOS)
    im = Image.new("RGBA", CANVAS, (40, 42, 46, 255))
    im.alpha_composite(src, (round(ORIGIN[0]), round(ORIGIN[1])))
    im.convert("RGB").save(os.path.join(OUT, f"today-tier{t}.png"), optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    for t in range(1, 7):
        draw_tier(t)
        draw_tier(t, JOIN_Y2, "-r2", tick=3, reach=24)
        place_today(t)
    for t in (1, 6):
        draw_spell(t)
    with open(os.path.join(OUT, "guides.json"), "w") as f:
        json.dump({"canvas": CANVAS, "origin": ORIGIN, "px_per_unit": S, "card": CARD, "window": WINDOW,
                   "roundels": ROUNDELS, "roundel_r": ROUNDEL_R, "join_y": JOIN_Y, "join_y_r2": JOIN_Y2, "fleuron_top": FLEURON_TOP,
                   "spell_r": SPELL_R, "spell_band": SPELL_BAND, "spell_join_deg": SPELL_JOIN_DEG}, f, indent=1)
    print("written to", OUT)


if __name__ == "__main__":
    main()
