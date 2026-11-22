"""Take M, stage 2: gather the cut frames, cut the two round spells, measure every roundel, write frames.js.

The unit frames are cut first with tools/art/frame_cut.py (one slot per picture at x 106, y 43, w 812, h 1450;
tier 2 golden needs BG_DIST 14, its window is close to the background colour). Their cards go in CUT below.

    python docs/workstreams/ui-ideation/frames/M/fit.py
"""
import json
import os
import shutil

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

SRC = "/data/bramble-art/uiid-frames/M"
CUT = "/data/ui-ideation/tmp/frame-M/cut/final"
OUT = "/data/ui-ideation/frames/M/frames"
HERE = os.path.dirname(os.path.abspath(__file__))
SPELL_C, SPELL_R = (512.0, 768.0), 238 * 1.45  # spell circle on the 1024 x 1536 canvas (make_guides.py)


def cut_spell(name):
    a = np.asarray(Image.open(os.path.join(SRC, name + ".png")).convert("RGB")).astype(int)
    h, w, _ = a.shape
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.hypot(xx - SPELL_C[0], yy - SPELL_C[1])
    # fit the outer radius: where the drawn ring ends going outward
    bg = np.median(a[:40, :40].reshape(-1, 3), axis=0)
    far = np.abs(a - bg).sum(2) > 30
    rs = np.arange(int(SPELL_R) - 40, int(SPELL_R) + 30)
    cover = [far[(d >= r - 0.5) & (d < r + 0.5)].mean() for r in rs]
    r_out = next(r for r, c in zip(rs[::-1], cover[::-1]) if c > 0.6) + 1
    win = np.asarray(Image.open(os.path.join(SRC, name + ".png")).convert("RGB")).astype(int)
    wcol = np.median(win[740:800, 490:530].reshape(-1, 3), axis=0)
    winmask = (np.abs(win - wcol).sum(2) < 18) & (d < r_out)
    lab, _ = ndi.label(winmask)
    winmask = lab == lab[int(SPELL_C[1]), int(SPELL_C[0])]
    winmask = ndi.binary_fill_holes(winmask)
    winmask = ndi.binary_erosion(winmask, iterations=2)
    alpha = np.clip(r_out - d + 0.5, 0, 1) * (1 - ndi.gaussian_filter(winmask.astype(float), 1.0))
    rgba = np.dstack([a, (alpha * 255).astype(int)]).astype(np.uint8)
    box = (int(SPELL_C[0] - r_out), int(SPELL_C[1] - r_out), int(SPELL_C[0] + r_out), int(SPELL_C[1] + r_out))
    im = Image.fromarray(rgba, "RGBA").crop(box).resize((952, 952), Image.LANCZOS)
    im.save(os.path.join(OUT, name + ".png"))
    # the window's radius, in the 952 px image, for clipping spell art
    r_win = np.sqrt(winmask.sum() / np.pi) * 952 / (2 * r_out)
    return {"r_window_frac": round(float(r_win / 476), 4)}


def roundels(path):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    disc = (r > 215) & (g > 165) & (b < 175) & (r - b > 70) & (al > 200)
    disc[:1300] = False  # roundels are in the lower part (card px, 1120 x 2000)
    out = {}
    for side, sl in (("attack", slice(0, 560)), ("health", slice(560, 1120))):
        m = np.zeros_like(disc)
        m[:, sl] = disc[:, sl]
        lab, n = ndi.label(m)
        if not n:
            continue
        sizes = ndi.sum(m, lab, range(1, n + 1))
        comp = ndi.binary_fill_holes(lab == (int(np.argmax(sizes)) + 1))
        ys, xs = np.nonzero(comp)
        out[side] = {"cx": round(xs.mean() / 2, 1), "cy": round(ys.mean() / 2, 1),
                     "r": round(np.sqrt(comp.sum() / np.pi) / 2, 1)}  # card units
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    data = {}
    for f in sorted(os.listdir(CUT)):
        shutil.copy(os.path.join(CUT, f), os.path.join(OUT, f))
        data[f[:-4]] = roundels(os.path.join(OUT, f))
    for s in ("spell1", "spell6"):
        data[s] = cut_spell(s)
    with open(os.path.join(HERE, "frames.js"), "w") as fh:
        fh.write("// written by fit.py: roundel discs in card units (560 x 1000); spell window radius as a share\n")
        fh.write("window.FRAMES = " + json.dumps(data, indent=1) + ";\n")
    for k, v in data.items():
        print(k, v)


if __name__ == "__main__":
    main()
