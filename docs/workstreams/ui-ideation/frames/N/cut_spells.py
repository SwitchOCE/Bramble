"""Cut take N's round spell frames: outer circle and window circle found from the picture, both made clear.

    python cut_spells.py <in.png> <out.png> [cx cy R r_win]

The card is the largest non-background blob; its outer circle is fitted from the blob's extent, the window is
the dark slate area connected to the centre. Out: 1000 x 1000 RGBA, circle filling it, glow dropped.
"""
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

src, dst = sys.argv[1], sys.argv[2]
if len(sys.argv) == 7:
    pass
im = Image.open(src).convert("RGB")
a = np.asarray(im).astype(int)
bg = np.median(np.concatenate([a[:20].reshape(-1, 3), a[-20:].reshape(-1, 3)]), 0)
# lead is brighter than the background; glow is reddish, so use brightness of the min channel for the rim
diff = np.abs(a - bg).sum(2)
solid = diff > 60
lab, n = ndi.label(solid)
sizes = ndi.sum(solid, lab, range(1, n + 1))
card = ndi.binary_fill_holes(lab == (np.argmax(sizes) + 1))
ys, xs = np.where(card)
# fit the circle on the upper half only (no glow up there)
top = ys.min()
cx = (xs[ys < top + 40].mean())
left, right = xs.min(), xs.max()
cx = (left + right) / 2 if abs((left + right) / 2 - cx) < 10 else cx
# radius from the top edge: the top of the circle is not touched by glow
r_top = None
upper = card[: int(top + 0.5 * (ys.max() - top))]
uy, ux = np.where(upper)
cy_guess = top + (right - left) / 2
R = (right - left) / 2
cy = top + R
# window: dark slate connected to the image centre; its centre is the card's centre
h, w = card.shape
c = a[h // 2 - 5:h // 2 + 5, w // 2 - 5:w // 2 + 5].reshape(-1, 3)
wcol = np.median(c, 0)
win = np.abs(a - wcol).sum(2) < 30
lab, _ = ndi.label(win)
win = ndi.binary_fill_holes(lab == lab[h // 2, w // 2])
wy, wx = np.where(win)
cx, cy = (wx.max() + wx.min()) / 2, (wy.max() + wy.min()) / 2
r_win = ((wx.max() - wx.min()) + (wy.max() - wy.min())) / 4
# outer radius from the top of the card (no glow up there)
R = cy - top
if len(sys.argv) == 7:  # fit from another take of the same guide: cx cy R r_win
    cx, cy, R, r_win = (float(v) for v in sys.argv[3:7])
print(f"outer centre ({cx:.1f}, {cy:.1f}) r {R:.1f}; window r {r_win:.1f} ({r_win / R:.3f} of outer)")

S = 4
size = 1000
k = size / (2 * R)
crop = im.crop((int(cx - R), int(cy - R), int(cx + R), int(cy + R))).resize((size, size), Image.LANCZOS)
mask = Image.new("L", (size * S, size * S), 0)
d = ImageDraw.Draw(mask)
inset = 3 * S
d.ellipse((inset, inset, size * S - inset, size * S - inset), fill=255)
mask = mask.resize((size, size), Image.LANCZOS)
# the window: slate-coloured pixels connected to the centre, inside the window circle plus a margin, so an
# ornament that reaches into the window stays part of the frame
ca = np.asarray(crop).astype(int)
yy, xx = np.mgrid[0:size, 0:size]
inside = (xx - size / 2) ** 2 + (yy - size / 2) ** 2 < (r_win * k + 8) ** 2
slate = (np.abs(ca - wcol).sum(2) < 45) & inside
lab, _ = ndi.label(slate)
win_m = ndi.binary_fill_holes(lab == lab[size // 2, size // 2])
win_m = ndi.binary_dilation(win_m, iterations=2) & inside
win_img = Image.fromarray((win_m * 255).astype(np.uint8)).resize((size * 2, size * 2), Image.BILINEAR).resize((size, size), Image.LANCZOS)
mask = Image.fromarray((np.asarray(mask).astype(float) * (1 - np.asarray(win_img) / 255)).astype(np.uint8))
out = crop.convert("RGBA")
out.putalpha(mask)
out.save(dst)
