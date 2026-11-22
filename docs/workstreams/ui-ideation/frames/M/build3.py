"""Take M, round 3: one master frame in code, with each tier's own generated glass fitted underneath.

What code draws, identical on every tier (the council's round-2 list):
- the upper came: one rounded pewter came (gilt on golden), 31 units wide, one highlight line, crisp edges, on the
  top slopes and down both sides to just above that tier's join. The apex is plain: no bead, no crest.
- one stat roundel: an ivory glass face (radius 58), a came round it, a ring of the tier's own glass, an outer came
  (radius 84), at the same two centres on every tier.
- the outline: every frame is clipped to the exact 0.56 hexagon.
What comes from the generated pictures (cut with tools/art/frame_cut.py, BG_DIST 14, WIN_DIST 24): the glass below the
join, its lead lines, the leaf tip and solder knot, and the bottom crest. They are moved, never redrawn:
- the lower part is stretched in y so the picture's roundels sit on the shared centre;
- each long side is stretched in y so the glass starts at JOIN[t] (40 units a tier);
- the picture's own lead is recoloured to the same pewter (normal cards), and tiers 1, 5 and 6 get the glass tint
  the council asked for (tier 1 warmer pearl, tier 5 deeper amber, tier 6 deeper ruby).

    python docs/workstreams/ui-ideation/frames/M/build3.py      (numpy, scipy, Pillow)
Writes r3-*.png into /data/ui-ideation/frames/M/frames/ and frames3.js beside this file.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fit  # noqa: E402
from fit import roundels  # noqa: E402
from fit2 import drawn_join  # noqa: E402

OUT = "/data/ui-ideation/frames/M/frames"
T = "/data/ui-ideation/tmp/frame-M"
SPELL_CUT = T + "/spell3"   # round-3 spell pictures cut by fit.cut_spell, kept apart from round 2's fitted files
P = 2                       # px per card unit; frames are 1120 x 2000
W, H = 560 * P, 1000 * P
SRC = {  # tier: (normal, golden) cut frames; the source with the least stretch to its join was chosen per tier
    1: (f"{T}/cut2/n/tier1-common.png", f"{T}/cut2/g/tier1-common.png"),
    2: (f"{T}/cut2/n/tier2-uncommon.png", f"{T}/cut2/g/tier2-uncommon.png"),
    3: (f"{T}/cut/normal/tier3-rare.png", f"{T}/cut/gold/tier3-rare.png"),        # round 1: its join needs no squeeze
    4: (f"{T}/cut2/n/tier4-epic.png", f"{T}/cut2/g/tier4-epic.png"),
    5: (f"{T}/cut3/n/tier5-legendary.png", f"{T}/cut3/g/tier5-legendary.png"),    # round 3: smaller roundels
    6: (f"{T}/cut2/n/tier6-mythic.png", f"{T}/cut2/g/tier6-mythic.png"),
}
JOIN = {1: 704, 2: 664, 3: 624, 4: 584, 5: 544, 6: 504}   # glass starts here on the long sides (units from top)
CX, CY = (111, 449), 766                                   # roundel centres, every tier
R_FACE, R_IN, R_RING, R_OUT = 58, 63, 79, 85              # ivory face | came | tier glass ring | outer came
BAND = 31                                                  # came width, units (about 6.2 px at 112 px wide)
S0, M = 215, 34
CARD = [(280, 0), (560, 170), (560, 830), (280, 1000), (0, 830), (0, 170)]

PEWTER = dict(edge=(26, 27, 31), body=(86, 89, 96), light=(184, 189, 197))
GILT = dict(edge=(92, 62, 18), body=(214, 172, 78), light=(255, 240, 196))
IVORY = (238, 229, 205)
GLASS_A = GLASS_B = np.array([150.0, 150.0, 150.0])


def card_mask(ss=4):
    m = Image.new("L", (W * ss // 2, H * ss // 2), 0)
    ImageDraw.Draw(m).polygon([(x * P * ss / 2, y * P * ss / 2) for x, y in CARD], fill=255)
    return np.asarray(m.resize((W, H), Image.LANCZOS)).astype(float) / 255


CARD_A = card_mask()
DIST = ndi.distance_transform_edt(np.pad(CARD_A > 0.5, 1))[1:-1, 1:-1] / P   # units from the outer edge
YY, XX = np.mgrid[0:H, 0:W] / P                           # unit coordinates of every pixel


def remap_rows(a, x0, x1, src_pts, dst_pts, y_from, y_to):
    out = a.copy()
    for yd in range(int(y_from * P), int(y_to * P)):
        ys = np.interp(yd / P, dst_pts, src_pts) * P
        y0 = int(np.floor(ys)); f = ys - y0; y1 = min(y0 + 1, H - 1)
        out[yd, x0:x1] = a[y0, x0:x1] * (1 - f) + a[y1, x0:x1] * f
    return out


def ramp(t, pal):
    """t in 0..1 across the came's width -> colour: dark edges, rounded body, one highlight line."""
    body = np.sin(np.pi * np.clip(t, 0, 1)) ** 0.7
    hl = np.exp(-((t - 0.40) / 0.055) ** 2)
    e, b, l = (np.array(pal[k], float) for k in ("edge", "body", "light"))
    c = e[None] * (1 - body[..., None]) + b[None] * body[..., None]
    return c * (1 - 0.85 * hl[..., None]) + l[None] * (0.85 * hl[..., None])


def came_layer(pal, join_y):
    """RGBA of the upper came: full band above each side's join, fading out over 12 units just above the knot."""
    t = DIST / BAND
    rgb = ramp(t.ravel(), pal).reshape(H, W, 3)
    rng = np.random.default_rng(7)  # matte cast-metal mottling, the same on every tier
    mott = ndi.gaussian_filter(rng.standard_normal((H, W)), 5.0)
    rgb = rgb * (1 + 0.025 * mott / mott.std())[..., None]
    inside = (DIST <= BAND) & (CARD_A > 0)
    edge_aa = np.clip((BAND + 0.5 - DIST) * P, 0, 1)
    stop = np.where(XX < 280, join_y[0], join_y[1]) - 22         # the knot sits above the leaf tip
    fade = np.clip((stop - YY) / 12, 0, 1)
    a = fade * edge_aa * inside * CARD_A
    return rgb, a


def recolour_lead(rgb, alpha, pal):
    """The picture's own dark lead -> the same pewter, keeping its shading."""
    lum = rgb.mean(2); sat = rgb.max(2) - rgb.min(2)
    m = (alpha > 0.5) & (sat < 45) & (lum < 115)
    t = np.clip((lum - 12) / 100, 0, 1) ** 0.8
    e, b, l = (np.array(pal[k], float) for k in ("edge", "body", "light"))
    new = np.where(t[..., None] < 0.6, e + (b - e) * (t[..., None] / 0.6), b + (l - b) * ((t[..., None] - 0.6) / 0.4))
    out = rgb.copy(); out[m] = new[m]
    return out


def tint_glass(rgb, alpha, tier):
    lum = rgb.mean(2); sat = rgb.max(2) - rgb.min(2)
    g = (alpha > 0.5) & ((sat > 60) | (lum > 140)) & (YY > 450)
    out = rgb.copy()
    if tier == 1:
        out[g] = out[g] * np.array([1.0, 0.975, 0.92])          # warm pearl, not steel
    elif tier == 5:
        out[g] = out[g] * np.array([0.86, 0.76, 0.45])          # deep honey: darker and richer than the gilt
    elif tier == 6:
        out[g] = out[g] * np.array([0.86, 0.70, 0.75])          # deep ruby: darker again than tier 5
    return out


def lead_tier1(rgb, a, pal):
    """Tier 1's glass came as one plate per slope: cut each lower slope into three panes with fine lead."""
    for (x0, y0, x1, y1) in ((0, 830, 280, 1000), (560, 830, 280, 1000)):
        L = math.hypot(x1 - x0, y1 - y0); ux, uy = (x1 - x0) / L, (y1 - y0) / L; nx, ny = -uy, ux
        for f in (0.38, 0.70):
            px, py = x0 + ux * L * f, y0 + uy * L * f
            # distance of every pixel from the line through (px, py) along the normal, within 46 units of the edge
            along = (XX - px) * ux + (YY - py) * uy
            m = (np.abs(along) < 1.6) & (DIST < 46) & (a > 0.5)
            rgb[m] = np.array(pal["edge"], float) * 1.5
    return rgb


def circle_aa(cx, cy, r):
    d = np.hypot(XX - cx, YY - cy)
    return np.clip((r - d) * P + 0.5, 0, 1), d


def draw_roundels(rgb, a, pal, src_rgb, src_a):
    for cx in CX:
        outer, d = circle_aa(cx, CY, R_OUT)
        # ring of the tier's glass, drawn here for every tier: eight panes of one glass, lit from the upper left,
        # each pane a shade apart, divided by fine lead
        ring = (d >= R_IN - 1) & (d < R_RING + 1)
        ang = (np.degrees(np.arctan2(YY - CY, XX - cx)) + 360 + 22.5) % 360
        seg = np.floor(ang / 45).astype(int)
        rr = np.clip((d - R_IN) / (R_RING - R_IN), 0, 1)
        lit = 0.92 + 0.22 * np.sin(np.pi * rr) - 0.10 * ((YY - CY) + 0.6 * (XX - cx)) / R_OUT
        shade = 1 + 0.06 * np.sin(seg * 2.4)
        base = (GLASS_A + GLASS_B) / 2
        col = base[None, None] * (lit * shade)[..., None]
        rgb[ring] = col[ring]
        a[ring] = 1
        line = ring & (np.abs((ang % 45) - 22.5) > 21.2)
        rgb[line] = np.array(pal["edge"], float) * 1.4
        # outer came r R_RING..R_OUT and inner came r R_FACE..R_IN, same ramp as the upper came
        for r0, r1 in ((R_RING, R_OUT), (R_FACE, R_IN)):
            band = (d >= r0 - 0.5) & (d < r1 + 0.5)
            t = np.clip((d - r0) / (r1 - r0), 0, 1)
            c = ramp(t[band], pal)
            k = np.clip(np.minimum(d - (r0 - 0.5), (r1 + 0.5) - d)[band] * P, 0, 1)[:, None]
            rgb[band] = rgb[band] * (1 - k) + c * k
            a[band] = np.maximum(a[band], k[:, 0])
        # ivory glass face: a soft radial light and two faint streaks, no gold
        face, _ = circle_aa(cx, CY, R_FACE)
        u = (XX - cx) / R_FACE; v = (YY - CY) / R_FACE
        shade = 1.0 - 0.10 * np.hypot(u + 0.3, v + 0.35) + 0.035 * np.sin(9 * (u - v))
        fc = np.array(IVORY, float)[None, None] * shade[..., None]
        k = face[..., None]
        rgb[:] = rgb * (1 - k) + fc * k
        a[:] = np.maximum(a, face)
    return rgb, a


def build(tier, normal_path, gold_path):
    n = np.asarray(Image.open(normal_path).convert("RGBA")).astype(float)
    g = np.asarray(Image.open(gold_path).convert("RGBA")).astype(float)
    rd = roundels(normal_path)
    cy_src = (rd["attack"]["cy"] + rd["health"]["cy"]) / 2
    # 1. lower part: put the picture's roundels on the shared centre
    y0 = 640
    n = remap_rows(n, 0, W, [y0, cy_src, 1000], [y0, CY, 1000], y0, 1000)
    g = remap_rows(g, 0, W, [y0, cy_src, 1000], [y0, CY, 1000], y0, 1000)
    # 2. each long side: put the join on JOIN[tier]
    ya = CY - R_OUT - 4
    joins = []
    for side in (0, 1):
        x0, x1 = (0, 130 * P) if side == 0 else (W - 130 * P, W)
        yt = JOIN[tier]
        for _ in range(3):  # the measure moves a little when the glass is stretched, so settle it
            yc = drawn_join(n.astype(np.uint8), side)
            if abs(yc - yt) < 2 or yt - M >= ya - 8 or yc - M >= ya - 8:
                break
            n = remap_rows(n, x0, x1, [S0, yc - M, ya], [S0, yt - M, ya], S0, ya)
            g = remap_rows(g, x0, x1, [S0, yc - M, ya], [S0, yt - M, ya], S0, ya)
        joins.append(drawn_join(n.astype(np.uint8), side))
    out = {}
    for key, arr, pal in ((f"r3-t{tier}", n, PEWTER), (f"r3-t{tier}-gold", g, GILT)):
        rgb, a = arr[..., :3].copy(), arr[..., 3] / 255
        if pal is PEWTER:
            rgb = recolour_lead(rgb, a, PEWTER)
        rgb = tint_glass(rgb, a, tier)
        src_rgb, src_a = rgb.copy(), a.copy()
        # the window edge above the join is the came's own inner edge: clear the picture's lead beyond it
        upper = (YY < np.where(XX < 280, joins[0], joins[1]) - 30) | ((XX > 140) & (XX < 420) & (YY < 400))
        a = np.where(upper & (DIST > BAND), 0, a)
        crgb, ca = came_layer(pal, joins)
        rgb = rgb * (1 - ca[..., None]) + crgb * ca[..., None]
        a = np.maximum(a, ca)
        global GLASS_A, GLASS_B
        if pal is PEWTER:  # the normal card's glass; the golden card uses the same two colours
          gl = src_rgb[(src_a > 0.9) & (YY > 820) & (np.abs(XX - 280) > 60) & (DIST < 40)]
          gs = gl.max(1) - gl.min(1); gm = gl.mean(1)
          gl = gl[(gs > 60) | (gm > 150)] if tier != 1 else gl[gm > 140]
          lum = gl.mean(1)
          GLASS_A = np.median(gl[lum <= np.median(lum)], axis=0)
          GLASS_B = np.median(gl[lum > np.median(lum)], axis=0)
        if tier == 1:
            rgb = lead_tier1(rgb, a, pal)
        rgb, a = draw_roundels(rgb, a, pal, src_rgb, src_a)
        a = a * CARD_A
        im = np.dstack([np.clip(rgb, 0, 255), np.clip(a * 255, 0, 255)]).astype(np.uint8)
        Image.fromarray(im, "RGBA").save(os.path.join(OUT, key + ".png"))
        out[key] = {"joins": [round(j, 1) for j in joins]}
    return out


def spell(name, tier):
    """The round spell: the generated glass arc, the same came above it, clipped to the circle."""
    src = np.asarray(Image.open(os.path.join(SPELL_CUT, name + ".png")).convert("RGBA")).astype(float)
    S = src.shape[0]; R = S / 2; k = R / 238                    # px per unit in the spell image
    yy, xx = np.mgrid[0:S, 0:S]
    d = np.hypot(xx - R + 0.5, yy - R + 0.5) / k                # units from the centre
    ang = np.degrees(np.arctan2(xx - R + 0.5, yy - R + 0.5))    # 0 = straight down
    rgb, a = src[..., :3].copy(), src[..., 3] / 255
    lum = rgb.mean(2); sat = rgb.max(2) - rgb.min(2)
    lead = (a > 0.5) & (sat < 45) & (lum < 115)
    t0 = np.clip((lum - 12) / 100, 0, 1)
    e, b = np.array(PEWTER["edge"], float), np.array(PEWTER["body"], float)
    rgb[lead] = (e + (b - e) * t0[..., None])[lead]
    # where the glass starts: the widest angle from the bottom with glass in the band
    band = (d > 214) & (d < 234)
    glassy = band & (a > 0.5) & (np.abs(ang) < 150) & ((sat > 90) | ((lum > 165) & (sat < 40)))
    reach = np.abs(ang[glassy]).max() if glassy.any() else 60
    t = np.clip((238 - d) / BAND, 0, 1)
    crgb = ramp(t.ravel(), PEWTER).reshape(S, S, 3)
    stop = reach - 9                                           # end just past the knot
    fade = np.clip((np.abs(ang) - stop) / 6, 0, 1)
    ca = fade * np.clip((BAND + 0.5 - (238 - d)) * k, 0, 1) * (d <= 238)
    if tier == 6:
        tint = (a > 0.5) & (sat > 60)
        rgb[tint] = rgb[tint] * np.array([0.86, 0.70, 0.75])
    a = np.where((np.abs(ang) > stop) & (238 - d > BAND), 0, a)  # window edge above the join = the came's edge
    rgb = rgb * (1 - ca[..., None]) + crgb * ca[..., None]
    a = np.maximum(a, ca) * np.clip((238 - d) * k + 0.5, 0, 1)
    Image.fromarray(np.dstack([np.clip(rgb, 0, 255), a * 255]).astype(np.uint8), "RGBA").save(
        os.path.join(OUT, "r3-" + name + ".png"))
    return {"r_window_frac": round((238 - BAND) / 238, 4), "glass_reach_deg": round(float(reach), 1)}


def main():
    data = {"roundel": {"cx": CX, "cy": CY, "r": R_FACE}}
    for t, (n, g) in SRC.items():
        data.update(build(t, n, g))
    os.makedirs(SPELL_CUT, exist_ok=True)
    fit.OUT = SPELL_CUT
    for name, t in (("spell1", 1), ("spell6", 6)):
        fit.cut_spell(name)
        data["r3-" + name] = spell(name, t)
    with open(os.path.join(HERE, "frames3.js"), "w") as fh:
        fh.write("// written by build3.py: one roundel for every tier (card units 560 x 1000), joins per frame\n")
        fh.write("window.FRAMES3 = " + json.dumps(data, indent=1) + ";\n")
    print(json.dumps(data))


if __name__ == "__main__":
    main()
