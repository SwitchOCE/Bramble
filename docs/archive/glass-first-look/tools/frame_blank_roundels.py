"""Paint the numerals out of a frame set's Attack and Health roundels, so the game can draw its own.

Usage: python frame_blank_roundels.py <frames_dir>

Works on the output of frame_cut.py: tier<N>-<name>.png (1120 x 2000) and tier<N>-<name>-padded.png
(the same card at (120, 120) on 1360 x 2240). Edits both in place and writes roundels.json: for each
tier, the centre and radius of the gold disc in each roundel, in card-space px (1120 x 2000) and in
card units (560 x 1000), which is where the game draws Attack (left) and Health (right).

How: each disc is found as the gold region near the expected roundel position. Inside it, the dark
numeral (plus a few px around it, for its soft edge) is replaced by the disc's own surrounding colour,
filled in with a normalised blur, so the disc keeps its glow and shading and shows no ghost of the
number. The ring and the frame are not touched.
"""
import glob, json, os, re, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

PAD = 120
EXPECTED = [(224, 1560), (896, 1560)]   # roundel centres from the guide, card-space px
SEARCH = 200                            # px around the expected centre to look for the disc
DARK_LUM = 140                          # numeral pixels are darker than this (the disc is about 180)
GROW = 14                               # px the numeral mask is grown to take its soft edge and bevel halo
FILL_SIGMA = 24                         # px of blur used to fill the numeral from the disc around it
INNER = 0.94                            # only pixels within this share of the disc's radius are touched
CORE_IN, CORE_OUT = 0.72, 0.88          # share of the radius fully smoothed, and where smoothing fades out


def find_disc(rgb, alpha, cx0, cy0):
    y0, x0 = cy0 - SEARCH, cx0 - SEARCH
    sub = rgb[y0:cy0 + SEARCH, x0:cx0 + SEARCH].astype(int); al = alpha[y0:cy0 + SEARCH, x0:cx0 + SEARCH]
    r, g, b = sub[..., 0], sub[..., 1], sub[..., 2]
    gold = (r > 180) & (g > 130) & (b < 170) & (r - b > 60) & (al > 200)
    lab, n = ndi.label(gold)
    if n == 0:
        raise ValueError('no gold disc near (%d, %d)' % (cx0, cy0))
    centre = lab[SEARCH - 40:SEARCH + 40, SEARCH - 40:SEARCH + 40].ravel()
    c = np.bincount(centre[centre > 0]).argmax() if (centre > 0).any() else 1
    comp = ndi.binary_fill_holes(lab == c)
    ys, xs = np.where(comp)
    cy, cx = (ys.min() + ys.max()) / 2 + y0, (xs.min() + xs.max()) / 2 + x0
    rad = ((xs.max() - xs.min()) + (ys.max() - ys.min())) / 4
    return cx, cy, rad


def blank(rgb, cx, cy, rad):
    """Return rgb with the numeral inside the disc at (cx, cy, rad) painted out."""
    H, W, _ = rgb.shape
    yy, xx = np.mgrid[0:H, 0:W]
    inside = (xx - cx) ** 2 + (yy - cy) ** 2 <= (rad * INNER) ** 2
    lum = rgb.astype(float).mean(2)
    numeral = ndi.binary_dilation((lum < DARK_LUM) & inside, iterations=GROW) & inside
    good = inside & ~numeral
    f = rgb.astype(float)
    w = ndi.gaussian_filter(good.astype(float), FILL_SIGMA)
    fill = np.stack([ndi.gaussian_filter(f[..., i] * good, FILL_SIGMA) for i in range(3)], -1) / np.maximum(w, 1e-6)[..., None]
    # The numeral's bevel leaves a faint halo past any tight mask, so the whole middle of the disc
    # takes the smooth fill, fading back to the original glass towards the rim.
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / rad
    radial = np.clip((CORE_OUT - d) / (CORE_OUT - CORE_IN), 0, 1)
    soft = np.maximum(ndi.gaussian_filter(numeral.astype(float), 1.5), radial) * inside
    return (f * (1 - soft[..., None]) + fill * soft[..., None]).clip(0, 255).astype(np.uint8)


def run(folder):
    out = {}
    for path in sorted(glob.glob(os.path.join(folder, 'tier[1-6]-*.png'))):
        if path.endswith('-padded.png'):
            continue
        tier = int(re.search(r'tier(\d)', os.path.basename(path)).group(1))
        card = np.asarray(Image.open(path).convert('RGBA'))
        rgb, alpha = card[..., :3].copy(), card[..., 3]
        discs = [find_disc(rgb, alpha, *e) for e in EXPECTED]
        for cx, cy, rad in discs:
            rgb = blank(rgb, cx, cy, rad)
        Image.fromarray(np.dstack([rgb, alpha])).save(path)

        ppath = path[:-4] + '-padded.png'
        if os.path.exists(ppath):
            p = np.asarray(Image.open(ppath).convert('RGBA'))
            prgb = p[..., :3].copy()
            for cx, cy, rad in discs:
                prgb = blank(prgb, cx + PAD, cy + PAD, rad)
            Image.fromarray(np.dstack([prgb, p[..., 3]])).save(ppath)

        out['tier%d' % tier] = {
            side: {'centre_px': [round(cx, 1), round(cy, 1)], 'radius_px': round(rad, 1),
                   'centre_units': [round(cx / 2, 1), round(cy / 2, 1)], 'radius_units': round(rad / 2, 1)}
            for side, (cx, cy, rad) in zip(('attack', 'health'), discs)}
        print('tier %d: attack disc %s, health disc %s' % (tier, out['tier%d' % tier]['attack'], out['tier%d' % tier]['health']))
    with open(os.path.join(folder, 'roundels.json'), 'w') as fh:
        json.dump({'card_px': [1120, 2000], 'card_units': [560, 1000],
                   'note': 'Gold disc of each roundel; the padded files are offset by (120, 120) px.', **out}, fh, indent=1)


if __name__ == '__main__':
    run(sys.argv[1])
