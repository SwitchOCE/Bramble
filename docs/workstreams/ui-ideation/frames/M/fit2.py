"""Take M, round 2: put every join exactly where the design says, by code.

The image tool drew the glass, lead, roundels and crest well but placed the join by its own judgement twice. Here the
cut frames (tools/art/frame_cut.py, BG_DIST 14, WIN_DIST 24; one slot per picture at x 106, y 43, w 812, h 1450)
are remapped: on each long side, a vertical strip of the border is stretched or squeezed (piecewise linear in y,
nothing else moves) so the glass starts at JOIN[t]. The lead above it is uniform along the side, so the stretch
does not show. The golden picture of each tier gets the same move as its normal one, so the pair stays matched.

    python docs/workstreams/ui-ideation/frames/M/fit2.py      (needs numpy, scipy, Pillow)
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fit import roundels, cut_spell, OUT  # noqa: E402

CUT = "/data/ui-ideation/tmp/frame-M/cut2"
HERE = os.path.dirname(os.path.abspath(__file__))
P = 2  # card px per unit (frames are 1120 x 2000)
# Where the glass starts on the long sides, card units from the top. Tier 1 stays beside its roundels (it cannot
# go lower); each tier above climbs 30 units, about 6 px at 112 px wide. Tier 6's glass covers the lowest 45%.
JOIN = {1: 704, 2: 674, 3: 644, 4: 614, 5: 584, 6: 554}
S0 = 215      # top of the straight sides (pure lead above the join)
M = 34        # rows above the drawn join that travel with it (the solder knot and leaf tip)
STRIP = 130   # strip width in units from each outer edge; the roundels lie below A, so it never touches them


def drawn_join(a, side):
    """First row (units) where tier glass shows in the border band of one side."""
    xs = slice(6, 50) if side == 0 else slice(1070, 1114)
    band = a[400:1700, xs, :3].astype(int)
    sat = band.max(2) - band.min(2)
    lum = band.mean(2)
    score = ((sat > 100) | (lum > 150)).mean(1)
    return (int(np.argmax(score > 0.3)) + 400) / P


def remap(a, side, yc, yt, ya):
    """Move the join from yc to yt on one side; rows below ya stay where they are."""
    out = a.copy()
    xs = slice(0, STRIP * P) if side == 0 else slice(1120 - STRIP * P, 1120)
    src_pts = [S0, yc - M, ya]
    dst_pts = [S0, yt - M, ya]
    for yd in range(int(S0 * P), int(ya * P)):
        ys = np.interp(yd / P, dst_pts, src_pts) * P
        y0 = int(np.floor(ys)); f = ys - y0
        out[yd, xs] = (a[y0, xs] * (1 - f) + a[min(y0 + 1, a.shape[0] - 1), xs] * f)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    data, report = {}, {}
    for t in range(1, 7):
        n = [f for f in glob.glob(f"{CUT}/n/tier{t}-*.png") if "padded" not in f][0]
        g = [f for f in glob.glob(f"{CUT}/g/tier{t}-*.png") if "padded" not in f][0]
        an = np.asarray(Image.open(n).convert("RGBA")).astype(float)
        ag = np.asarray(Image.open(g).convert("RGBA")).astype(float)
        rd = roundels(n)
        ya = min(rd["attack"]["cy"] - 1.32 * rd["attack"]["r"], rd["health"]["cy"] - 1.32 * rd["health"]["r"]) - 4
        yt = JOIN[t]
        report[t] = {"drawn": [], "target": yt, "roundel_top": round(ya, 1)}
        for side in (0, 1):
            yc = drawn_join(an.astype(np.uint8), side)
            report[t]["drawn"].append(yc)
            if abs(yc - yt) < 2 or yt - M >= ya - 8 or yc - M >= ya - 8:
                continue  # already there, or (tier 1) beside the roundel where no strip can move
            an = remap(an, side, yc, yt, ya)
            ag = remap(ag, side, yc, yt, ya)
        for key, arr in ((f"t{t}", an), (f"t{t}-gold", ag)):
            path = os.path.join(OUT, key + ".png")
            Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(path)
            data[key] = roundels(path)
        report[t]["after"] = [drawn_join(an.astype(np.uint8), s) for s in (0, 1)]
    for s in ("spell1", "spell6"):
        data[s] = cut_spell(s)
    with open(os.path.join(HERE, "frames.js"), "w") as fh:
        fh.write("// written by fit2.py: roundel discs in card units (560 x 1000); spell window radius as a share\n")
        fh.write("window.FRAMES = " + json.dumps(data, indent=1) + ";\n")
    with open(os.path.join(HERE, "joins.json"), "w") as fh:
        json.dump(report, fh, indent=1)
    for t, r in report.items():
        print(t, r)


if __name__ == "__main__":
    main()
