"""Take M, round 4: one border of one width. The owner on round 3: "the border needs to blend way more evenly ...
they need to be of a similar ... width."

The whole border is drawn here, as one lead came that runs round the card. Above the join it is solid. At the join
its two rails part in a leaf tip with a solder knot, and the tier's glass fills between them, so the lead gives way
to glass gradually and the border never steps. Two versions (the owner then added, of an M15 Magic card: "It seems to flow in and like be connected almost ...
the bottom is wider and bigger, but it's not jarring"):
  near  below the join the border widens smoothly over 90 units from 31 (6.2 px at 112 px) to 46 (9.2 px), with 31
        units of glass; the stat discs float over the art, clear of the border
  flow  (recommended) from the tier's join the band widens smoothly, by the glass only, to 62 units (12.4 px) round
        the foot, as the Magic frame's foot is bigger but one piece with its sides; the stat discs sit on the band's
        lower corners. Glass is the generated strips (prompts-4.txt) laid along the band; lead is a cast H-section.
The bottom crest is gone in both (it made the glass wide).
Tiers: the glass climbs 60 units (12 px at 112) a tier, its pieces get shorter, and the colours are spread in value.

    python docs/workstreams/ui-ideation/frames/M/build4.py      (numpy, scipy, Pillow)
Writes r4-{near,flow}-*.png into /data/ui-ideation/frames/M/frames/ and frames4.js beside this file.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from build3 import CARD_A, DIST, XX, YY, P, W, H, PEWTER, GILT, IVORY, ramp  # noqa: E402

OUT = "/data/ui-ideation/frames/M/frames"
BAND = 31
RAIL_O, RAIL_I = 8, 7
JOIN = {1: 800, 2: 740, 3: 680, 4: 620, 5: 560, 6: 500}      # glass starts here on the long sides (card units)
PIECE = {1: 110, 2: 92, 3: 78, 4: 66, 5: 56, 6: 48}          # glass piece length along the border
GLASS = {  # (darker, lighter) pane colours per tier, spread in value so neighbours differ in greyscale too
    1: ((178, 174, 163), (218, 214, 202)),   # warm pearl
    2: ((84, 146, 22), (150, 198, 52)),      # leaf green
    3: ((40, 132, 232), (110, 182, 250)),    # sapphire, kept light
    4: ((96, 26, 158), (150, 62, 210)),      # violet, kept deep
    5: ((196, 120, 12), (240, 170, 44)),     # honey amber, darker than the gilt's highlight
    6: ((140, 18, 20), (206, 48, 30)),       # ruby, the deepest
}
DISC_C = {"near": ((116, 770), (444, 770)), "flow": ((74, 788), (486, 788))}
DISC_R, DISC_CAME = 54, 6
DR = (54, 59, 70, 75)   # ivory face | came | tier glass ring | outer came (units); 30 px across at 112 px
FLOW_MAX, FLOW_RAMP = 62, 190
SPELL_R = 238
SPELL_JOIN = {1: 62, 6: 112}                                   # glass arc, degrees each side of straight down


def card_s():
    """Distance along the border from the bottom point, the same on both halves (card units)."""
    x = np.where(XX <= 280, XX, 560 - XX); y = YY
    segs = [((280, 1000), (0, 830)), ((0, 830), (0, 170)), ((0, 170), (280, 0))]
    best_d = np.full(x.shape, 1e9); s = np.zeros(x.shape); acc = 0.0
    for (x0, y0), (x1, y1) in segs:
        L = math.hypot(x1 - x0, y1 - y0); ux, uy = (x1 - x0) / L, (y1 - y0) / L
        t = np.clip((x - x0) * ux + (y - y0) * uy, 0, L)
        d = np.hypot(x - (x0 + ux * t), y - (y0 + uy * t))
        m = d < best_d
        best_d = np.where(m, d, best_d); s = np.where(m, acc + t, s); acc += L
    return s


def smooth(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


RNG = np.random.default_rng(11)
NOISE = ndi.gaussian_filter(RNG.standard_normal((1400 * 2, 70 * 2)), (7, 1.6))
NOISE /= NOISE.std()


def border(s, d, s_join, tier, pal, version, mott=None, s_flow_top=517.6):
    """RGB and alpha of the whole border, from the distance along it (s) and in from the outer edge (d)."""
    below = np.clip((s_join - s), 0, None)                      # units below the join along the border
    open_ = smooth(below / 46)                                  # the leaf tip: glass opens over 46 units
    if version == "near":
        width = BAND + 15 * smooth(below / 90)
    else:  # flow: the came swells towards the foot, the same for every tier
        # the came swells only where the glass opens, so the extra width is always glass, never a fat lead pipe;
        # the swell starts at the leaf tip and reaches full width FLOW_RAMP units further down
        top = np.minimum(s_join, s_flow_top + 140)
        width = BAND + (FLOW_MAX - BAND) * smooth((top - s) / FLOW_RAMP)
    gw = np.maximum(width - RAIL_O - RAIL_I, 0) * open_
    g0, g1 = RAIL_O, RAIL_O + gw
    inside = d <= width
    rgb = np.zeros(s.shape + (3,)); a = np.zeros(s.shape)
    # lead: outer rail, inner rail; above the join they are one came (gw = 0 there)
    t_out = np.where(gw > 0.3, d / RAIL_O, d / width)
    t_in = (d - g1) / np.maximum(width - g1, 1e-3)
    is_glass = (d > g0) & (d < g1) & (gw > 0.3)
    lead_t = np.where(d <= g0, t_out, np.where(d >= g1, t_in, 0))
    lead_t = np.where(gw > 0.3, lead_t, d / width)
    pal = LEAD if pal is PEWTER else GOLD
    lead = lead_ramp(lead_t, pal)
    if mott is not None:
        lead = lead * (1 + 0.05 * mott)[..., None]
    rgb[:] = lead
    # glass: the tier's generated strip, laid along the border; it opens with the rails, so its panes taper in
    u = np.clip((d - g0) / np.maximum(gw, 1e-3), 0, 1)
    gref = (FLOW_MAX if version == "flow" else BAND + 15) - RAIL_O - RAIL_I
    if tier not in TEX:
        TEX[tier] = strip_texture(tier)
    th = TEX[tier][0].shape[0]
    m = is_glass
    gcol, seam = sample_glass(tier, s[m], u[m], th / gref)
    edge = np.array(pal["edge"], float) * 1.2
    gcol[seam] = edge
    rgb[m] = gcol
    a = np.clip((width + 0.5 - d) * P, 0, 1) * inside
    return rgb, a, width


def draw_disc(rgb, a, cx, cy, pal, xx, yy, k, tier):
    """One stat roundel: a clean ivory glass face, a came, a ring of the tier's own leaded glass, an outer came."""
    pal = LEAD if pal is PEWTER else GOLD
    d = np.hypot(xx - cx, yy - cy)
    reach = d <= DR[3] + 1
    # rings, outermost first
    ring = reach & (d >= DR[1]) & (d < DR[2])
    if ring.any():
        ang = np.arctan2(yy[ring] - cy, xx[ring] - cx)
        rm = (DR[1] + DR[2]) / 2
        if tier not in TEX:
            TEX[tier] = strip_texture(tier)
        th = TEX[tier][0].shape[0]
        gcol, seam = sample_glass(tier, (ang + np.pi) * rm + 900, (d[ring] - DR[1]) / (DR[2] - DR[1]), th / (DR[2] - DR[1]))
        gcol[seam] = np.array(pal["edge"], float) * 1.2
        rgb[ring] = gcol; a[ring] = 1
    for r0, r1 in ((DR[2], DR[3]), (DR[0], DR[1])):
        band = reach & (d >= r0 - 0.5) & (d <= r1 + 0.5)
        lit = -0.25 * ((yy[band] - cy) + (xx[band] - cx)) / (r1 * 1.4)
        c = lead_ramp((d[band] - r0) / (r1 - r0), pal, lit)
        kk = np.clip(np.minimum(d[band] - (r0 - 0.5), r1 + 0.5 - d[band]) * k, 0, 1)[:, None]
        rgb[band] = rgb[band] * (1 - kk) + c * kk
        a[band] = np.maximum(a[band], kk[:, 0])
    face = np.clip((DR[0] - d) * k + 0.5, 0, 1) * reach
    u = (xx - cx) / DR[0]; v = (yy - cy) / DR[0]
    sh = 1.02 - 0.12 * np.clip(np.hypot(u + 0.35, v + 0.4), 0, 1.6) ** 1.5
    fc = np.array(IVORY, float)[None, None] * sh[..., None]
    rgb[:] = rgb * (1 - face[..., None]) + fc * face[..., None]
    a[:] = np.maximum(a, face)


def solder(rgb, a, xx, yy, cx, cy, pal, k, r=5.0):
    d = np.hypot(xx - cx, yy - cy)
    m = np.clip((r - d) * k + 0.5, 0, 1)
    t = np.clip(0.5 + 0.5 * (-(xx - cx) - (yy - cy)) / r, 0, 1)   # lit from the upper left
    pal = LEAD if pal is PEWTER else GOLD
    col = lead_ramp(np.clip(0.2 + 0.6 * t, 0, 1), pal)
    rgb[:] = rgb * (1 - m[..., None]) + col * m[..., None]
    a[:] = np.maximum(a, m)


# Cast lead, not a vector stroke: an H-section came (two rounded flanges with a groove between), lit from the upper
# left, with patina at two scales. Golden is modelled gilt with deep shadow and bright highlight, as wide as the lead.
LEAD = dict(edge=(22, 23, 27), body=(78, 80, 88), light=(170, 174, 182))
GOLD = dict(edge=(74, 42, 8), body=(206, 152, 46), light=(255, 238, 172))


def lead_ramp(t, pal, lit=0.0):
    t = np.clip(t, 0, 1)
    flange = np.sin(np.pi * t) ** 0.55
    groove = 0.20 * np.exp(-((t - 0.5) / 0.09) ** 2)
    hl = 0.75 * np.exp(-((t - 0.30) / 0.06) ** 2) + 0.35 * np.exp(-((t - 0.70) / 0.06) ** 2)
    v = np.clip(flange - groove, 0, 1)
    e, b, l = (np.array(pal[k], float) for k in ("edge", "body", "light"))
    c = e * (1 - v[..., None]) + b * v[..., None]
    h = np.clip(hl + lit, 0, 1)[..., None]
    return c * (1 - h) + l * h


def strip_texture(tier):
    """The tier's glass strip: its four bands cut out and laid end to end, with a lead joint at every seam."""
    im = np.asarray(Image.open(f"/data/bramble-art/uiid-frames/M/strip{tier}.png").convert("RGB")).astype(float)
    h, w, _ = im.shape
    bands = []
    for i in range(4):
        y0, y1 = int(i * h / 4) + 10, int((i + 1) * h / 4) - 10
        bands.append(im[y0:y1, 12:w - 12])
    th = min(b.shape[0] for b in bands)
    tex = np.concatenate([b[:th] for b in bands], axis=1)
    lum = tex @ np.array([0.299, 0.587, 0.114])
    sat = TONE.get(tier, (0.9, 1.0))
    tex = lum[..., None] + (tex - lum[..., None]) * sat[0]
    tex = 255 * (np.clip(tex, 0, 255) / 255) ** sat[1]
    return tex, bands[0].shape[1]


TONE = {3: (0.82, 1.12), 4: (0.82, 1.10), 6: (0.9, 1.06)}   # (saturation, gamma): sapphire and violet came out neon


TEX = {}


def sample_glass(tier, s, u, kx):
    """Glass colour at distance s along the border and fraction u across the glass."""
    if tier not in TEX:
        TEX[tier] = strip_texture(tier)
    tex, bw = TEX[tier]
    th, tw = tex.shape[:2]
    x = (np.abs(s) * kx) % tw
    y = np.clip(u, 0, 1) * (th - 1)
    out = np.stack([ndi.map_coordinates(tex[..., c], [y, x], order=1, mode="wrap") for c in range(3)], -1)
    seam = (np.minimum(x % bw, bw - (x % bw)) < 1.4 * kx) | (np.abs(s) < 1.2)
    return out, seam


S_CARD = card_s()
_r = np.random.default_rng(7)
MOTT = ndi.gaussian_filter(_r.standard_normal((H, W)), 22.0); MOTT /= MOTT.std()
_g = ndi.gaussian_filter(_r.standard_normal((H, W)), 1.3); MOTT = 0.7 * MOTT + 0.5 * _g / _g.std()


def build_card(tier, version, golden):
    pal = GILT if golden else PEWTER
    s_join = 327.6 + (830 - JOIN[tier])
    rgb, a, width = border(S_CARD, DIST, s_join, tier, pal, version, MOTT)
    a = a * CARD_A
    for side in (0, 1):  # the knots where the rails part
        x = RAIL_O + 3.5 if side == 0 else 560 - RAIL_O - 3.5
        solder(rgb, a, XX, YY, x, JOIN[tier] + 2, pal, P)
    for cx, cy in DISC_C[version]:
        draw_disc(rgb, a, cx, cy, pal, XX, YY, P, tier)
    a = a * CARD_A
    return rgb, a


def build_spell(tier, version):
    S = SPELL_R * 2 * P
    yy, xx = np.mgrid[0:S, 0:S] / P
    c = SPELL_R
    r = np.hypot(xx - c, yy - c)
    d = SPELL_R - r
    ang = np.degrees(np.abs(np.arctan2(xx - c, yy - c)))        # 0 = straight down
    s = np.radians(ang) * SPELL_R
    s_join = math.radians(SPELL_JOIN[tier]) * SPELL_R
    rgb, a, width = border(s, d, s_join, tier, PEWTER, version, s_flow_top=math.radians(118) * SPELL_R)
    a = a * np.clip((SPELL_R - r) * P + 0.5, 0, 1)
    for sgn in (-1, 1):
        th = math.radians(SPELL_JOIN[tier]) + 2 / SPELL_R
        rr = SPELL_R - RAIL_O - 3.5
        solder(rgb, a, xx, yy, c + sgn * math.sin(th) * rr, c + math.cos(th) * rr, PEWTER, P)
    return rgb, a


def save(name, rgb, a):
    Image.fromarray(np.dstack([np.clip(rgb, 0, 255), np.clip(a * 255, 0, 255)]).astype(np.uint8), "RGBA").save(
        os.path.join(OUT, name + ".png"))


def main():
    data = {"roundel": {v: {"cx": [c[0] for c in DISC_C[v]], "cy": DISC_C[v][0][1], "r": DISC_R} for v in DISC_C},
            "join": JOIN, "band": BAND, "spell_window_frac": {}}
    for version in ("near", "flow"):
        for t in range(1, 7):
            for golden in (False, True):
                rgb, a = build_card(t, version, golden)
                save(f"r4-{version}-t{t}" + ("-gold" if golden else ""), rgb, a)
        for t in (1, 6):
            rgb, a = build_spell(t, version)
            save(f"r4-{version}-spell{t}", rgb, a)
        data["spell_window_frac"][version] = round((SPELL_R - BAND) / SPELL_R, 4)
    with open(os.path.join(HERE, "frames4.js"), "w") as fh:
        fh.write("// written by build4.py: one roundel for every tier and version (card units 560 x 1000)\n")
        fh.write("window.FRAMES4 = " + json.dumps(data, indent=1) + ";\n")
    print(json.dumps(data))


if __name__ == "__main__":
    main()
