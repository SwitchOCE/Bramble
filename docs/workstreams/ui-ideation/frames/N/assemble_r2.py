"""Take N, round 2: make the six frames agree where the image tool did not.

    python assemble_r2.py <cut-r2 dir> <out dir>

Input: the cut frames (tools/art/frame_cut.py output, 1120 x 2000 RGBA, card px = 2 x card units) in
<cut-r2>/normal and <cut-r2>/golden. For each set it writes tier1..6 to <out>/<set>/:
- Upper lead: one master (tier 4 of the same set) above y = 590 units for every tier, blended into the tier's own
  picture over 590-630. Below that, the master's plain side lead (its 520-590 band, repeated) lies under each
  tier's own picture, so every tier has the same lead weight and the glass rises out of it.
- Stat roundels: one stamp, cut from tier 2's roundel (the cleanest), recoloured to each tier's own glass and laid
  at one centre and one size on every tier, covering whatever the tier had there.
"""
import colorsys
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

NAMES = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
U = 2  # card px per unit
SEAM0, SEAM1, SIDE_TO = 590, 630, 760
SIDE_X = 52                       # units from each side that count as side lead
CENTRES = [(108, 784), (452, 784)]  # roundel centres, units
R_STD = 64                        # roundel outer radius, units (covers every tier's own roundel)
SRC = {"normal": ((109.1, 783.9), 51.1), "golden": ((108.5, 784.6), 52.1)}  # tier 2's ivory disc, units
SRC_RING = 1.24                   # tier 2's roundel outer radius / its ivory disc radius


def load(d, t):
    return np.asarray(Image.open(os.path.join(d, f"tier{t}-{NAMES[t - 1]}.png")).convert("RGBA")).astype(float) / 255


def over(top, bottom):
    a_t, a_b = top[..., 3:4], bottom[..., 3:4]
    a = a_t + a_b * (1 - a_t)
    rgb = (top[..., :3] * a_t + bottom[..., :3] * a_b * (1 - a_t)) / np.maximum(a, 1e-6)
    return np.concatenate([rgb, a], 2)


def mix(a, b, w):
    """Blend two RGBA images (premultiplied), weight w for b."""
    pa, pb = a[..., :3] * a[..., 3:4], b[..., :3] * b[..., 3:4]
    al = a[..., 3:4] * (1 - w) + b[..., 3:4] * w
    rgb = (pa * (1 - w) + pb * w) / np.maximum(al, 1e-6)
    return np.concatenate([rgb, al], 2)


def tier_glass_colour(img):
    """Median hue, saturation and value of the tier's saturated base glass."""
    reg = img[1500:1950, 200:920]
    rgb = reg[..., :3][reg[..., 3] > 0.9]
    hsv = np.array([colorsys.rgb_to_hsv(*p) for p in rgb[:: max(1, len(rgb) // 4000)]])
    sat = hsv[hsv[:, 1] > 0.35]
    if len(sat) < 200:  # grey tier
        return None, 0.04, float(np.median(hsv[:, 2]))
    h = sat[:, 0]
    # circular median of hue
    ang = np.angle(np.mean(np.exp(2j * np.pi * h))) / (2 * np.pi) % 1
    return float(ang), float(np.median(sat[:, 1])), float(np.median(sat[:, 2]))


def recolour(stamp, src_hsv, dst_hsv, ivory_r_px, centre_px):
    """Move the ring's coloured glass from the source tier's colour to the destination's; leave the ivory
    disc and the lead alone."""
    out = stamp.copy()
    H, W = stamp.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    rr = np.hypot(xx - centre_px[0], yy - centre_px[1])
    rgb = stamp[..., :3]
    mx, mn = rgb.max(2), rgb.min(2)
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    ring = (rr > ivory_r_px * 1.03) & (s > 0.12)
    h_d, s_d, v_d = dst_hsv
    h_s, s_s, v_s = src_hsv
    ys, xs = np.where(ring)
    for y, x in zip(ys, xs):
        h, sv, v = colorsys.rgb_to_hsv(*rgb[y, x])
        if h_d is None:
            nh, ns = h, 0.05
        else:
            nh = (h + (h_d - h_s)) % 1
            ns = min(1, sv * s_d / max(s_s, 1e-3))
        nv = min(1, v * v_d / max(v_s, 1e-3))
        out[y, x, :3] = colorsys.hsv_to_rgb(nh, ns, nv)
    return out


def make_stamp(t2, set_name):
    (cx, cy), r = SRC[set_name]
    R = r * SRC_RING
    box = [int(round((cx - R) * U)), int(round((cy - R) * U)), int(round((cx + R) * U)), int(round((cy + R) * U))]
    crop = t2[box[1]:box[3], box[0]:box[2]].copy()
    size = 2 * R_STD * U
    im = Image.fromarray((crop * 255).astype(np.uint8), "RGBA").resize((size, size), Image.LANCZOS)
    st = np.asarray(im).astype(float) / 255
    # a clean circular edge
    m = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(m).ellipse((2, 2, size * 4 - 2, size * 4 - 2), fill=255)
    m = np.asarray(m.resize((size, size), Image.LANCZOS)).astype(float) / 255
    st[..., 3] = m
    ivory_r_px = r / R * R_STD * U
    return st, ivory_r_px


def main():
    src, dst = sys.argv[1], sys.argv[2]
    for set_name in ("normal", "golden"):
        d = os.path.join(src, set_name)
        os.makedirs(os.path.join(dst, set_name), exist_ok=True)
        master = load(d, 4)
        t2 = load(d, 2)
        stamp, ivory_r_px = make_stamp(t2, set_name)
        src_hsv = tier_glass_colour(t2)
        H = master.shape[0]
        rows = np.arange(H)[:, None, None] / U
        w_own = np.clip((rows - SEAM0) / (SEAM1 - SEAM0), 0, 1)
        # plain lead sides for the master, all the way down: the sides are vertical from 170 to 830 units, so
        # the side strips at 520-590 (plain lead on every tier) are repeated downward to 830
        lead_master = np.zeros_like(master)
        band = master[520 * U:590 * U]
        for y0 in range(SEAM0 * U, 830 * U, band.shape[0]):
            h = min(band.shape[0], 830 * U - y0)
            for xs in (slice(0, SIDE_X * U), slice(1120 - SIDE_X * U, 1120)):
                lead_master[y0:y0 + h, xs] = band[:h, xs]
        # fade it out over the bottom corners' slope, where each tier's own glass takes over
        fade = np.clip((830 - rows) / 40, 0, 1)
        lead_master[..., 3:4] *= fade
        for t in range(1, 7):
            own = load(d, t)
            out = mix(master, own, w_own)                  # master on top, the tier's own below the seam
            out = over(out, lead_master)  # plain lead sides under the tier's own picture
            st = recolour(stamp, src_hsv, tier_glass_colour(own), ivory_r_px, (stamp.shape[1] / 2, stamp.shape[0] / 2)) if t != 2 else stamp
            for cx, cy in CENTRES:
                x0, y0 = int(round((cx - R_STD) * U)), int(round((cy - R_STD) * U))
                h, w = st.shape[:2]
                out[y0:y0 + h, x0:x0 + w] = over(st, out[y0:y0 + h, x0:x0 + w])
            Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA").save(
                os.path.join(dst, set_name, f"tier{t}-{NAMES[t - 1]}.png"))
            print(set_name, t, "done")


if __name__ == "__main__":
    main()
