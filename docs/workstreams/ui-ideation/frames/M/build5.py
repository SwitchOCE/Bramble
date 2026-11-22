"""Take M, round 5: the round-4 "flow" border, with its glass cut into panes and its lead cast.

Round 4's outline stays: one came, 31 units round the top and sides; at the tier's join its rails part in a leaf tip
and the glass opens between them, widening smoothly round the foot. What changes is the making:
  - Glass is cut, not tiled. Each tier has its own cutting pattern, laid out in band coordinates (s along the border
    from the foot point, v across the glass), so every pane fits the band and every pane is edged in lead. Patterns
    get richer by tier: long quarries; alternating wedges; chevrons pointing to the foot; chevrons split down the
    middle; leaves; leaves with jewels at their nodes. A keystone pane straddles the foot point, with a jewel from
    tier 3 up. Each pane takes its colour and streaks from one pane of the tier's generated strip (prompts-4.txt),
    with the strip's own lead painted out, so neighbouring panes differ as cut glass does.
  - Lead is cast: an H-section with broken highlights, a slight wobble in width, oxide patina in the low parts, and
    solder where every pane line meets a rail. Golden is the same shape in modelled gilt.
  - Tier 1 is clear antique glass, near colourless with a faint green, not grey.
  - The stat discs' rings are cut into eight panes with lead spokes, inside a heavier cast collar.
  - About an eighth more glass at the foot (68 units, was 62).

    python docs/workstreams/ui-ideation/frames/M/build5.py      (numpy, scipy, Pillow)
Writes r5-*.png into /data/ui-ideation/frames/M/frames/ and frames5.js beside this file.
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
from build3 import CARD_A, DIST, XX, YY, P, W, H, IVORY  # noqa: E402
from build4 import S_CARD, smooth, TONE  # noqa: E402

OUT = "/data/ui-ideation/frames/M/frames"
BAND, RAIL_O, RAIL_I = 31, 8, 7
FLOW_MAX, FLOW_RAMP = 68, 190
JOIN = {1: 800, 2: 740, 3: 680, 4: 620, 5: 560, 6: 500}
PANE = {1: 118, 2: 96, 3: 82, 4: 70, 5: 62, 6: 54}          # pane length along the band, units
LW = 3.4                                                     # lead between panes, units
DISC = ((74, 788), (486, 788))
DR = (54, 58, 70, 77)          # ivory face | came | cut tier-glass ring | cast collar (units)
SPELL_R = 238
SPELL_JOIN = {1: 62, 6: 112}
R = 4                          # band-map resolution, px per unit
VO = RAIL_O + 3                # band map starts this many units outside the glass, so solder can reach the rails

LEAD = dict(edge=(20, 21, 25), body=(74, 77, 84), light=(176, 180, 186), oxide=(150, 154, 152))
GOLD = dict(edge=(58, 32, 4), body=(190, 134, 34), light=(255, 244, 196), oxide=(150, 98, 24))

_rng = np.random.default_rng(5)
LOW = ndi.gaussian_filter(_rng.standard_normal((H, W)), 26.0); LOW /= LOW.std()
GRAIN = ndi.gaussian_filter(_rng.standard_normal((H, W)), 1.2); GRAIN /= GRAIN.std()
N1 = ndi.gaussian_filter1d(_rng.standard_normal(4000), 18); N1 /= N1.std()       # along-the-border noise, 1 per unit
N2 = ndi.gaussian_filter1d(_rng.standard_normal(4000), 5); N2 /= N2.std()


def along(n, s):
    return np.interp(np.abs(s), np.arange(len(n)), n)


# ---------------------------------------------------------------------------------------------------- lead
def lead_ramp(t, pal, hl_k=1.0, lit=0.0):
    """Across one came, t 0..1: rounded flanges, a groove, two highlights (the near one broken by hl_k)."""
    t = np.clip(t, 0, 1)
    flange = np.sin(np.pi * t) ** 0.6
    groove = 0.24 * np.exp(-((t - 0.5) / 0.10) ** 2)
    v = np.clip(flange - groove, 0, 1)
    hl = (0.85 * np.exp(-((t - 0.28) / 0.055) ** 2) * hl_k + 0.30 * np.exp(-((t - 0.72) / 0.06) ** 2)
          + 0.10 * np.exp(-((t - 0.5) / 0.25) ** 2))
    e, b, l = (np.array(pal[k], float) for k in ("edge", "body", "light"))
    c = e * (1 - v[..., None]) + b * v[..., None]
    h = np.clip(hl + lit, 0, 1)[..., None]
    c = c * (1 - h) + l * h
    return c, v


def patinate(c, v, pal, low, grain, k=1.0):
    """Oxide settles in the low parts of the came; casting leaves grain."""
    ox = np.clip(0.10 + 0.12 * low, 0, 0.35) * (1 - v) * k
    c = c * (1 - ox[..., None]) + np.array(pal["oxide"], float) * ox[..., None]
    return c * (1 + 0.045 * grain)[..., None]


# ---------------------------------------------------------------------------------------------------- glass material
def material(tier):
    """The tier's strip with its lead painted out, and its panes (centre, lightness, accent or not)."""
    im = np.asarray(Image.open(f"/data/bramble-art/uiid-frames/M/strip{tier}.png").convert("RGB")).astype(float)
    sat, gam = TONE.get(tier, (0.9, 1.0))
    lum = im @ np.array([0.299, 0.587, 0.114])
    im = np.clip(lum[..., None] + (im - lum[..., None]) * sat, 0, 255)
    im = 255 * (im / 255) ** gam
    dark = ndi.binary_dilation(im.max(-1) < 78, iterations=3)
    keep = ~dark
    out = im.copy()
    for sig in (4, 10, 28):
        w = ndi.gaussian_filter(keep.astype(float), sig)
        fill = np.stack([ndi.gaussian_filter(im[..., c] * keep, sig) for c in range(3)], -1) / np.maximum(w, 1e-6)[..., None]
        m = ~keep & (w > 0.05)
        out[m] = fill[m]
        keep = keep | m
    if tier == 1:   # clear antique glass: near colourless, faint green, its streaks kept as light and shade only
        l2 = out @ np.array([0.299, 0.587, 0.114])
        z = (l2 - l2.mean()) / l2.std()
        out = np.array([206, 218, 208], float)[None, None] * (1 + 0.075 * z)[..., None]
    lab, n = ndi.label(ndi.binary_erosion(~dark, iterations=6))
    panes = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        if sl is None:
            continue
        mm = lab[sl] == i
        if mm.sum() < 4000:
            continue
        ys, xs = np.nonzero(mm)
        cy, cx = ys.mean() + sl[0].start, xs.mean() + sl[1].start
        col = out[sl][mm].mean(0)
        panes.append(dict(c=(cx, cy), col=col, light=float(col @ np.array([0.299, 0.587, 0.114]))))
    cols = np.array([p["col"] for p in panes]); med = np.median(cols, 0)
    for p in panes:
        p["accent"] = bool(np.linalg.norm(p["col"] - med) > 85) and tier != 1
    main = sorted([p for p in panes if not p["accent"]], key=lambda p: p["light"])
    acc = [p for p in panes if p["accent"]] or main[-3:]
    half = max(1, len(main) // 2)
    return dict(img=out, dark=main[:half], light=main[half:] or main, accent=acc)


MAT = {}


def mat(tier):
    if tier not in MAT:
        MAT[tier] = material(tier)
    return MAT[tier]


def sample(img, x, y):
    return np.stack([ndi.map_coordinates(img[..., c], [y, x], order=1, mode="reflect") for c in range(3)], -1)


# ---------------------------------------------------------------------------------------------------- band geometry
def widths(s, s_join, s_flow_top):
    """Band width and glass width at distance s along the border (round 4's flow, with a rounder leaf tip)."""
    below = np.clip(s_join - s, 0, None)
    open_ = np.sqrt(smooth(below / 70))
    top = np.minimum(s_join, s_flow_top + 140)
    width = BAND + (FLOW_MAX - BAND) * smooth((top - s) / FLOW_RAMP)
    return width, np.maximum(width - RAIL_O - RAIL_I, 0) * open_


def cut_pattern(tier, s_join, s_flow_top):
    """The tier's cutting pattern as a band map: pane labels, lead, solder points, in (s, v) at R px per unit."""
    smax = s_join + 12
    S, V = int(smax * R) + 2, int((FLOW_MAX + VO) * R) + 2
    s_ax = np.arange(S) / R
    _, gw_ax = widths(s_ax, s_join, s_flow_top)
    gw = lambda s: float(np.interp(s, s_ax, gw_ax))
    img = Image.new("L", (S, V), 0); dr = ImageDraw.Draw(img)
    px = lambda s, v: (s * R, (v + VO) * R)
    solder, jewels = [], []
    L = PANE[tier]; lw = int(round(LW * R))

    def line(pts):
        dr.line([px(*p) for p in pts], fill=255, width=lw, joint="curve")

    def cross(sk, kind, k):
        G = gw(sk)
        if G < 4:
            return None
        us = np.linspace(-0.08, 1.08, 30)
        if kind == "straight":
            off = 0 * us
        elif kind == "slant":
            off = (-1) ** k * (us - 0.5) * G * 1.1
        else:  # chevron pointing to the foot
            off = np.abs(us - 0.5) * G * 1.25
        line([(sk + o, u * G) for o, u in zip(off, us)])
        solder.append((sk + off[2], 0.0)); solder.append((sk + off[-3], G))
        return sk + off[15]

    kind = {1: "straight", 2: "slant", 3: "chevron", 4: "chevron", 5: "chevron", 6: "chevron"}[tier]
    ks = []
    k, sk = 0, L * 0.55                      # the keystone straddles the foot point
    while sk < s_join - 10:
        apex = cross(sk, kind, k)
        if apex is not None:
            ks.append((sk, apex))
        k += 1; sk += L
    if tier == 4:   # each pane split down its middle
        for (s0, a0), (s1, a1) in zip(ks, ks[1:] + [(s_join, s_join)]):
            seg = [(s, 0.5 * gw(s)) for s in np.linspace(a0, min(a1, s_join - 30), 24) if gw(s) > 14]
            if len(seg) > 1:
                line(seg)
    if tier >= 5:   # a leaf in each pane, from apex to apex
        for (s0, a0), (s1, a1) in zip(ks, ks[1:]):
            t = np.linspace(0, 1, 30)
            ss = a0 + (a1 - a0) * t
            for sgn in (-1, 1):
                line([(s, gw(s) * (0.5 + sgn * 0.36 * math.sin(math.pi * tt))) for s, tt in zip(ss, t)])
        if tier == 6:
            for _, a in ks[:-1]:
                G = gw(a)
                if G > 12:
                    jewels.append((a, 0.5 * G, 0.2 * G))
    if tier >= 3:   # the keystone's jewel
        G = gw(0)
        jewels.append((0.0, 0.5 * G, {3: 0.24, 4: 0.26, 5: 0.28, 6: 0.30}[tier] * G))
    for (s, v, r) in jewels:
        x, y = px(s, v); rr = r * R
        dr.ellipse([x - rr, y - rr, x + rr, y + rr], fill=0)               # a jewel is one piece: clear the lines
        dr.ellipse([x - rr, y - rr, x + rr, y + rr], outline=255, width=lw)
    lead = np.asarray(img) > 127
    vv = (np.arange(V) / R - VO)[:, None]
    glass = (vv > 0) & (vv < gw_ax[None, :]) & (gw_ax[None, :] > 0.3)
    interior = glass & ~lead
    lab, n = ndi.label(interior)
    d_in = ndi.distance_transform_edt(interior) / R                    # glass: distance to its pane's edge
    d_lead = ndi.distance_transform_edt(lead) / R                      # lead: distance to the glass either side
    com = ndi.center_of_mass(interior, lab, range(1, n + 1))
    dmax = ndi.maximum(d_in, lab, range(1, n + 1))
    panes = []
    for i, (cy, cx) in enumerate(com):
        s_c, v_c = cx / R, cy / R - VO
        jw = any(math.hypot(s_c - s, v_c - v) < r * 0.85 for s, v, r in jewels)
        G = max(gw(s_c), 1e-3)
        leaf = tier >= 5 and abs(v_c / G - 0.5) < 0.16 and not jw
        panes.append(dict(s=s_c, v=v_c, dmax=float(dmax[i]), jewel=jw, leaf=leaf))
    # solder at every pane line's ends on the rails, and at jewel tops and bottoms where they touch other lead
    sp = np.ones((V, S), bool)
    for s, v in solder:
        x, y = px(s, v)
        if 0 <= x < S and 0 <= y < V:
            sp[int(y), int(x)] = False
    d_sol, (iy, ix) = ndi.distance_transform_edt(sp, return_indices=True)
    return dict(lab=lab, d_in=d_in, d_lead=d_lead, lead=lead, panes=panes, d_sol=d_sol / R,
                sol_ds=(np.arange(S)[None, :] - ix) / R, sol_dv=(np.arange(V)[:, None] - iy) / R, S=S, V=V)


def pane_source(tier, i, p):
    """Which strip pane a cut pane takes its glass from: neighbours alternate light and dark; leaves are light,
    every other leaf of tier 5 in its green accent; jewels take the accent glass."""
    m = mat(tier)
    if p["jewel"]:
        pool = m["accent"]
    elif p["leaf"]:
        pool = m["accent"] if (tier == 5 and i % 2 == 0) else m["light"]
    elif tier >= 5:
        pool = m["dark"]
    else:
        pool = m["light"] if i % 2 == 0 else m["dark"]
    return pool[(i * 7 + tier * 3) % len(pool)]["c"]


def band_lookup(pat, s, v):
    """Look up the band map at card positions (s, v); returns per-pixel arrays."""
    x = np.clip(np.abs(s) * R, 0, pat["S"] - 1); y = np.clip((v + VO) * R, 0, pat["V"] - 1)
    xi, yi = np.round(x).astype(int), np.round(y).astype(int)
    lin = lambda a: ndi.map_coordinates(a.astype(float), [y, x], order=1)
    return dict(lab=pat["lab"][yi, xi], d_in=lin(pat["d_in"]), d_lead=lin(pat["d_lead"]), lead=lin(pat["lead"]),
                d_sol=lin(pat["d_sol"]), sds=pat["sol_ds"][yi, xi], sdv=pat["sol_dv"][yi, xi])


# ---------------------------------------------------------------------------------------------------- the border
def border(s, d, tier, pal, s_join, s_flow_top, low, grain):
    width, gw = widths(s, s_join, s_flow_top)
    width = width + 0.35 * along(N1, s)                       # a cast came is never quite even
    g0, g1 = RAIL_O, RAIL_O + gw
    split = gw > 0.3
    t = np.where(split, np.where(d <= g0, d / RAIL_O, (d - g1) / np.maximum(width - g1, 1e-3)), d / width)
    hl_k = np.clip(0.75 + 0.35 * along(N2, s), 0.25, 1.2)    # the highlight breaks up along the came
    lead, v = lead_ramp(t, pal, hl_k)
    rgb = patinate(lead, v, pal, low, grain)
    a = np.clip((width + 0.5 - d) * P, 0, 1)

    pat = cut_pattern(tier, s_join, s_flow_top)
    near = (d < g1 + RAIL_I + 3) & (s < s_join + 12)
    idx = np.nonzero(near)
    q = band_lookup(pat, s[idx], d[idx] - g0)
    vg = d[idx] - g0
    in_glass = (vg > 0) & (vg < gw[idx]) & split[idx]
    m = mat(tier)
    out = rgb[idx].copy()
    # glass panes
    gi = in_glass & (q["lab"] > 0)
    labs = q["lab"][gi]
    src = np.array([pane_source(tier, j, pat["panes"][j - 1]) for j in range(1, len(pat["panes"]) + 1)] or [(0, 0)])
    pc = np.array([(p["s"], p["v"]) for p in pat["panes"]] or [(0, 0)])
    dmax = np.array([p["dmax"] for p in pat["panes"]] or [1.0])
    jew = np.array([p["jewel"] for p in pat["panes"]] or [False])
    MS = 1.7                                                   # strip px per card unit
    sx = src[labs - 1, 0] + (np.abs(s[idx][gi]) - pc[labs - 1, 0]) * MS
    sy = src[labs - 1, 1] + (vg[gi] - pc[labs - 1, 1]) * MS
    col = sample(m["img"], sx, sy)
    dn = q["d_in"][gi]
    edge = 0.80 + 0.20 * smooth(dn / 3.5)                    # glass darkens into the lead
    glow = 0.10 * smooth(dn / np.maximum(dmax[labs - 1], 1))  # and lifts towards each pane's middle
    col = col * edge[:, None]
    col = col + (255 - col) * glow[:, None]
    jj = jew[labs - 1]
    if jj.any():                                               # jewels: domed, with a spark
        r = dmax[labs - 1][jj]
        tt = np.clip(dn[jj] / np.maximum(r, 1), 0, 1)
        col[jj] = col[jj] * (0.70 + 0.45 * tt)[:, None]
    out[gi] = col
    # lead between panes: the same cast section, seen across the line
    li = in_glass & (q["lab"] == 0)
    tl = np.clip(q["d_lead"][li] / LW, 0, 0.5)
    cl, vl = lead_ramp(tl, pal, 0.8)
    out[li] = patinate(cl, vl, pal, low[idx][li], grain[idx][li])
    # solder blobs where pane lines meet the rails: low domes, brighter than the came
    rs = 2.6
    sb = (q["d_sol"] < rs) & (d[idx] < width[idx])
    if sb.any():
        tt = 1 - q["d_sol"][sb] / rs
        lit = 0.45 * np.clip(-(q["sds"][sb] + q["sdv"][sb]) / rs, -1, 1) * tt
        cs, _ = lead_ramp(0.18 + 0.32 * tt, pal, 0.0, lit + 0.12)
        kk = np.clip((rs - q["d_sol"][sb]) * P, 0, 1)[:, None]
        out[sb] = out[sb] * (1 - kk) + cs * kk
    rgb[idx] = out
    return rgb, a, width, gw


def solder_knot(rgb, a, xx, yy, cx, cy, pal, r=5.5):
    d = np.hypot(xx - cx, yy - cy)
    m = np.clip((r - d) * P + 0.5, 0, 1)
    lit = 0.5 * np.clip((-(xx - cx) - (yy - cy)) / r, -1, 1) * np.clip(1 - d / r, 0, 1)
    col, _ = lead_ramp(np.clip(0.2 + 0.3 * (1 - d / r), 0, 1), pal, 0.0, lit + 0.1)
    rgb[:] = rgb * (1 - m[..., None]) + col * m[..., None]
    a[:] = np.maximum(a, m)


def draw_disc(rgb, a, cx, cy, pal, tier, low, grain):
    """Stat roundel: ivory face, a came, a ring cut into eight panes of the tier's glass, a heavier cast collar."""
    r0 = DR[3] + 2
    y0, y1, x0, x1 = int((cy - r0) * P), int((cy + r0) * P), int((cx - r0) * P), int((cx + r0) * P)
    sl = (slice(max(y0, 0), min(y1, H)), slice(max(x0, 0), min(x1, W)))
    xx, yy = XX[sl], YY[sl]; c = rgb[sl]; al = a[sl]
    lo, gr = low[sl], grain[sl]
    d = np.hypot(xx - cx, yy - cy)
    ang = np.arctan2(yy - cy, xx - cx)
    m = mat(tier)
    # ring glass
    ring = (d >= DR[1]) & (d < DR[2])
    n = 8; off = math.pi / 8
    k = np.floor(((ang + math.pi - off) % (2 * math.pi)) / (2 * math.pi / n)).astype(int)
    a_c = (k + 0.5) * 2 * math.pi / n + off - math.pi
    rm = (DR[1] + DR[2]) / 2
    pools = [m["light"], m["dark"]]
    srcs = np.array([pools[i % 2][(i * 5 + tier) % len(pools[i % 2])]["c"] for i in range(n)])
    da = (ang - a_c + math.pi) % (2 * math.pi) - math.pi
    sx = srcs[k, 0] + da * rm * 1.7
    sy = srcs[k, 1] + (d - rm) * 1.7
    gcol = sample(m["img"], sx[ring], sy[ring])
    d_sp = np.abs(np.abs(da) - math.pi / n) * d                     # distance to the nearest spoke
    dn = np.minimum(np.minimum(d - DR[1], DR[2] - d), d_sp)[ring]
    gcol = gcol * (0.80 + 0.20 * smooth(dn / 3))[:, None]
    c[ring] = gcol; al[ring] = 1
    sp = ring & (d_sp < LW / 2)
    cl, vl = lead_ramp(0.5 - np.clip(d_sp[sp] / LW, 0, 0.5), pal, 0.8)
    c[sp] = patinate(cl, vl, pal, lo[sp], gr[sp])
    # came and collar
    for ra, rb in ((DR[2], DR[3]), (DR[0], DR[1])):
        band = (d >= ra - 0.5) & (d <= rb + 0.5)
        lit = -0.28 * ((yy[band] - cy) + (xx[band] - cx)) / (rb * 1.4)
        cc, vv = lead_ramp((d[band] - ra) / (rb - ra), pal, 1.0, lit)
        cc = patinate(cc, vv, pal, lo[band], gr[band])
        kk = np.clip(np.minimum(d[band] - (ra - 0.5), rb + 0.5 - d[band]) * P, 0, 1)[:, None]
        c[band] = c[band] * (1 - kk) + cc * kk
        al[band] = np.maximum(al[band], kk[:, 0])
    # solder where the spokes meet the collar
    for i in range(n):
        th = off + i * 2 * math.pi / n - math.pi
        for rr in (DR[2] + 0.5, DR[1] - 0.5):
            sx_, sy_ = cx + math.cos(th) * rr, cy + math.sin(th) * rr
            dd = np.hypot(xx - sx_, yy - sy_)
            mm = dd < 2.4
            if mm.any():
                tt = 1 - dd[mm] / 2.4
                cs, _ = lead_ramp(0.2 + 0.3 * tt, pal, 0.0, 0.15 * tt)
                c[mm] = c[mm] * (1 - tt[:, None] ** 0.3) + cs * tt[:, None] ** 0.3
    # face
    face = np.clip((DR[0] - d) * P + 0.5, 0, 1)
    u = (xx - cx) / DR[0]; v = (yy - cy) / DR[0]
    sh = 1.02 - 0.12 * np.clip(np.hypot(u + 0.35, v + 0.4), 0, 1.6) ** 1.5
    fc = np.array(IVORY, float)[None, None] * sh[..., None]
    c[:] = c * (1 - face[..., None]) + fc * face[..., None]
    al[:] = np.maximum(al, face)


# Mitre at the foot: measured to the nearest edge, the foot's centre line sits at s = 0.607 d, not 0, so the two
# mirrored halves would not meet. Shear the foot segments so the centre line is s = 0, fading out before the corner.
S_FOOT = S_CARD - 0.607 * DIST * (1 - smooth((S_CARD - 200) / 110))


def build_card(tier, golden):
    pal = GOLD if golden else LEAD
    s_join = 327.6 + (830 - JOIN[tier])
    rgb, a, width, gw = border(S_FOOT, DIST, tier, pal, s_join, 517.6, LOW, GRAIN)
    a = a * CARD_A
    for x in (RAIL_O + 3.5, 560 - RAIL_O - 3.5):
        solder_knot(rgb, a, XX, YY, x, JOIN[tier] + 2, pal)
    for cx, cy in DISC:
        draw_disc(rgb, a, cx, cy, pal, tier, LOW, GRAIN)
    return rgb, a * CARD_A


def build_spell(tier):
    S = SPELL_R * 2 * P
    yy, xx = np.mgrid[0:S, 0:S] / P
    c = SPELL_R
    r = np.hypot(xx - c, yy - c)
    d = SPELL_R - r
    s = np.radians(np.degrees(np.abs(np.arctan2(xx - c, yy - c)))) * SPELL_R
    s_join = math.radians(SPELL_JOIN[tier]) * SPELL_R
    low, grain = LOW[:S, :S], GRAIN[:S, :S]
    rgb, a, width, gw = border(s, d, tier, LEAD, s_join, math.radians(118) * SPELL_R, low, grain)
    a = a * np.clip((SPELL_R - r) * P + 0.5, 0, 1)
    for sgn in (-1, 1):
        th = s_join / SPELL_R + 2 / SPELL_R
        rr = SPELL_R - RAIL_O - 3.5
        solder_knot(rgb, a, xx, yy, c + sgn * math.sin(th) * rr, c + math.cos(th) * rr, LEAD)
    return rgb, a


def save(name, rgb, a):
    Image.fromarray(np.dstack([np.clip(rgb, 0, 255), np.clip(a * 255, 0, 255)]).astype(np.uint8), "RGBA").save(
        os.path.join(OUT, name + ".png"))


def main():
    only = sys.argv[1:]
    for t in range(1, 7):
        for golden in (False, True):
            name = f"r5-t{t}" + ("-gold" if golden else "")
            if only and name not in only:
                continue
            save(name, *build_card(t, golden))
    for t in (1, 6):
        if not only or f"r5-spell{t}" in only:
            save(f"r5-spell{t}", *build_spell(t))
    data = {"roundel": {"cx": [c[0] for c in DISC], "cy": DISC[0][1], "r": DR[0]}, "join": JOIN,
            "spell_window_frac": round((SPELL_R - BAND) / SPELL_R, 4)}
    with open(os.path.join(HERE, "frames5.js"), "w") as fh:
        fh.write("// written by build5.py (card units 560 x 1000)\n")
        fh.write("window.FRAMES5 = " + json.dumps(data, indent=1) + ";\n")


if __name__ == "__main__":
    main()
