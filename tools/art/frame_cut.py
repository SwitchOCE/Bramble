"""Cut Codex frame images into one frame per tier, in card space, with a clear window.

Usage: python frame_cut.py <sheet.png> <slots.json> <out_dir>
       python frame_cut.py - <slots.json> <out_dir>      (each slot names its own image in "sheet")

The input is a Codex frame image drawn over an outline guide: either six cards on one sheet, or
one card per image. slots.json holds each card's tier and its x, y, w, h on its image (and, in
the second form, the image's path in "sheet"). Any card size works. For each tier it writes:
  tier<N>-<name>.png         1120 x 2000 RGBA (the 560 x 1000 card spec doubled),
                             window and outside transparent, lead kept
  tier<N>-<name>-padded.png  the same with a 120 px margin on every side (1360 x 2240),
                             card top-left at (120, 120), the card's own outer glow kept
  preview-white.jpg, preview-magenta.jpg   all cards over white and over magenta, to check the cut

How the cut works (needs numpy, scipy, Pillow):
- Background and window are found by colour distance from the image's background and from
  the window's own fill, measured at the image's native resolution.
- The frame is the largest connected piece of non-background; loose specks are dropped.
- The outer edge is the guide's card outline, fitted to where Codex actually drew the card (best
  overlap over shifts of up to 6 px and scales of 96.5% to 101%, at a 560 px reference size),
  drawn anti-aliased at full size and pulled in slightly so it lands on the outer lead.
  Straight edges, no glow, no fuzz.
- The window is the piece of window colour connected to the card's centre, with small holes
  filled and near-black fuzz at its edge taken in. Petals and jewels that reach into the window
  stay part of the frame. Its outline is smoothed at full size, so it isn't stair-stepped.
- Soft edge pixels take the colour of the nearest solid frame pixel, so no dark background shows
  through as a fringe.
- The padded version keeps glow only within a short distance of the card's own outline, so the
  neighbouring cards on a sheet never leak in.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

NAMES = ['common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic']
PAD = 120                 # margin in card-space px
BG_DIST = 22              # colour distance (sum of |dR|+|dG|+|dB|) that still counts as background
WIN_DIST = 16             # ... as window fill
FUZZ_DIST = 40            # dark fuzz at the outer edge this close to the background is removed
WIN_FUZZ_DIST = 30        # ... the same at the window edge (lower: the inner lead is close to the window colour)
EDGE_SMOOTH = 4           # card-space px of smoothing on the window's outline
EDGE_INSET = 2            # card-space px the outer edge is pulled in from the fitted outline
# The next three are px for a card 560 px tall in its image; they scale with the card.
GLOW_REACH = 10           # px outside the frame where glow may stay (padded version)
OUTLINE_SLACK = 3         # px the frame may sit outside the guide's outline
OUTER = [(280, 0), (560, 170), (560, 830), (280, 1000), (0, 830), (0, 170)]  # card outline, 560 x 1000 units


def _largest(mask):
    lab, n = ndi.label(mask)
    if n == 0:
        return mask
    sizes = ndi.sum(mask, lab, range(1, n + 1))
    return lab == (int(np.argmax(sizes)) + 1)


def _component_at(mask, y, x):
    lab, _ = ndi.label(mask)
    return lab == lab[y, x] if lab[y, x] else np.zeros_like(mask)


def _up(mask_f, size, soften=1.2):
    im = Image.fromarray(np.clip(mask_f * 255, 0, 255).astype(np.uint8)).resize(size, Image.LANCZOS)
    return np.asarray(im.filter(ImageFilter.GaussianBlur(soften))).astype(float) / 255


def _smooth_edge(mask, size):
    """Scale a mask to card space with a smooth outline: blur, re-threshold, then a one-pixel soft
    edge. Removes the stair-steps and the noise of the source."""
    up = Image.fromarray((mask * 255).astype(np.uint8)).resize(size, Image.BILINEAR)
    up = up.filter(ImageFilter.GaussianBlur(EDGE_SMOOTH))
    hard = (np.asarray(up) > 127).astype(np.uint8) * 255
    return np.asarray(Image.fromarray(hard).filter(ImageFilter.GaussianBlur(1.0))).astype(float) / 255


def _poly_mask(size, origin, k, dx, dy, sc):
    """The card outline as a boolean mask: the guide outline at k image px per card unit, scaled
    about the card's centre by sc, shifted by (dx, dy), with the card's corner at origin."""
    W, H = size; im = Image.new('L', (W, H), 0)
    cxu, cyu = 280, 500
    pts = [(origin + dx + (cxu + (x - cxu) * sc) * k, origin + dy + (cyu + (y - cyu) * sc) * k) for x, y in OUTER]
    ImageDraw.Draw(im).polygon(pts, fill=255)
    return np.asarray(im) > 0


def _poly_alpha(size, pad, dx, dy, sc, k, ss=4):
    """The same outline at card-space resolution (k card-space px per card unit), pulled in by
    EDGE_INSET and anti-aliased by drawing at ss times and shrinking."""
    W, H = size; im = Image.new('L', (W * ss, H * ss), 0)
    cxu, cyu = 280, 500
    inset = EDGE_INSET / k  # card units
    pts = []
    for x, y in OUTER:
        # pull each vertex towards the centre by the inset (approximate offset for a convex hexagon)
        vx, vy = x - cxu, y - cyu; d = (vx * vx + vy * vy) ** .5
        x2, y2 = x - vx / d * inset * 1.15, y - vy / d * inset * 1.15
        pts.append(((pad + dx + (cxu + (x2 - cxu) * sc) * k) * ss, (pad + dy + (cyu + (y2 - cyu) * sc) * k) * ss))
    ImageDraw.Draw(im).polygon(pts, fill=255)
    return np.asarray(im.resize((W, H), Image.LANCZOS)).astype(float) / 255


def _load_padded(path, p0=100):
    """The image padded with its own background, so cards near its edge can be cut with a margin."""
    a0 = np.asarray(Image.open(path).convert('RGB'))
    bg = np.median(np.concatenate([a0[:4].reshape(-1, 3), a0[-4:].reshape(-1, 3)]), 0)
    a = np.empty((a0.shape[0] + 2 * p0, a0.shape[1] + 2 * p0, 3), np.uint8)
    a[:] = bg.astype(np.uint8); a[p0:-p0, p0:-p0] = a0
    return a, bg


def cut_one(a, bg, s, p0=100):
    """Cut one card from a padded image. Returns (card, padded) as RGBA images."""
    r = s['h'] / 560                      # this card's size relative to the 560 px reference
    n = lambda v: max(1, int(round(v * r)))
    scale = 2000 / s['h']                 # image px -> card-space px
    m = PAD / scale
    size = (1120 + 2 * PAD, 2000 + 2 * PAD)
    box = tuple(int(round(v)) + p0 for v in (s['x'] - m, s['y'] - m, s['x'] + s['w'] + m, s['y'] + s['h'] + m))
    sub = a[box[1]:box[3], box[0]:box[2]].astype(int); H, W, _ = sub.shape
    cy, cx = int(H * .45), W // 2
    wcol = np.median(sub[cy - 4:cy + 4, cx - 4:cx + 4].reshape(-1, 3), 0)

    # this card only: keep to its own box (+ a little) so neighbours never count
    own = np.zeros((H, W), bool); mm = int(round(m)); g = n(14)
    own[max(0, mm - g):H - mm + g, max(0, mm - g):W - mm + g] = True

    non_bg = ndi.binary_opening((np.abs(sub - bg).sum(2) > BG_DIST) & own, iterations=n(1))
    card_solid = ndi.binary_fill_holes(_largest(non_bg))             # frame + window + glow, no specks

    win = _component_at((np.abs(sub - wcol).sum(2) < WIN_DIST) & card_solid, cy, cx)
    win = ndi.binary_fill_holes(ndi.binary_closing(win, iterations=n(2)))
    win = ndi.binary_opening(win, iterations=n(1))
    # take in near-black fuzz at the window edge: dark pixels touching the window, short of the lead
    fuzz = (np.abs(sub - wcol).sum(2) < WIN_FUZZ_DIST) & ndi.binary_dilation(win, iterations=n(3))
    win = ndi.binary_opening(win | fuzz, iterations=n(1))

    # rough frame, used only to fit the card's outline
    k = s['w'] / 560
    outside = _component_at((np.abs(sub - bg).sum(2) < FUZZ_DIST) | ~own, 0, 0)
    near_guide = ndi.binary_dilation(_poly_mask((W, H), m, k, 0, 0, 1.0), iterations=n(OUTLINE_SLACK + 3))
    rough = card_solid & near_guide & ~outside

    # fit the guide's outline to where Codex drew the card, on a copy at the 560 px reference size
    Ws, Hs = int(round(W / r)), int(round(H / r))
    rough_s = np.asarray(Image.fromarray(rough.astype(np.uint8) * 255).resize((Ws, Hs), Image.NEAREST)) > 0
    best = (-1, 0, 0, 1.0)
    for sc in (0.965, 0.97, 0.975, 0.98, 0.985, 0.99, 0.995, 1.0, 1.005, 1.01):
        for dy in range(-6, 7):
            for dx in range(-6, 7):
                pm = _poly_mask((Ws, Hs), m / r, k / r, dx, dy, sc)
                iou = (pm & rough_s).sum() / max(1, (pm | rough_s).sum())
                if iou > best[0]:
                    best = (iou, dx, dy, sc)
    iou, dx, dy, sc = best
    dx, dy = dx * r, dy * r

    # the outer edge is that straight outline, drawn smooth at card-space resolution
    outer_u = _poly_alpha(size, PAD, dx * scale, dy * scale, sc, s['w'] * scale / 560)
    win_u = _smooth_edge(win, size)
    alpha_card = outer_u * (1 - win_u)

    big = Image.fromarray(a.astype(np.uint8)).crop(box).resize(size, Image.LANCZOS)
    rgb = np.asarray(big).astype(float)

    # glow (padded version only): bright pixels just outside this card's outline
    near = ndi.binary_dilation(_poly_mask((W, H), m, k, dx, dy, sc), iterations=n(GLOW_REACH)) & own
    glow_u = _up(near.astype(float), size, soften=6) * np.clip((rgb.mean(2) - (bg.mean() + 6)) * 4, 0, 255) / 255
    alpha_pad = np.maximum(alpha_card, glow_u * (1 - outer_u))

    # colour at the soft edges: use the nearest solid frame colour, not the dark background behind it
    solid = alpha_card > 0.97
    _, (iy, ix) = ndi.distance_transform_edt(~solid, return_indices=True)
    clean = rgb[iy, ix]
    edge = (alpha_card > 0) & ~solid
    rgb_card = np.where(edge[..., None], clean, rgb)
    rgb_pad = np.where((edge & (glow_u < 0.05))[..., None], clean, rgb)

    def rgba(rgb_arr, alpha):
        im = Image.fromarray(np.clip(rgb_arr, 0, 255).astype(np.uint8)).convert('RGBA')
        im.putalpha(Image.fromarray((np.clip(alpha, 0, 1) * 255).astype(np.uint8)))
        return im
    card = rgba(rgb_card, alpha_card).crop((PAD, PAD, PAD + 1120, PAD + 2000))
    xs = np.where(win_u[PAD + 1000, PAD:PAD + 1120] > .5)[0]
    t = s['tier']
    print('tier %d %s: outline fit IoU %.3f, card %.0f px tall (x%.2f to card space), window sides %.1f and %.1f'
          % (t, NAMES[t - 1], iou, s['h'], scale, xs.min() / 2, xs.max() / 2))
    return card, rgba(rgb_pad, alpha_pad)


def cut(sheet, slots, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    cache, cards = {}, []
    for s in slots:
        path = s.get('sheet', sheet)
        if path not in cache:
            cache[path] = _load_padded(path)
        a, bg = cache[path]
        card, padded = cut_one(a, bg, s)
        t = s['tier']
        card.save(os.path.join(out_dir, 'tier%d-%s.png' % (t, NAMES[t - 1])))
        padded.save(os.path.join(out_dir, 'tier%d-%s-padded.png' % (t, NAMES[t - 1])))
        cards.append(card)
    for name, col in (('white', (255, 255, 255, 255)), ('magenta', (200, 60, 160, 255))):
        prev = Image.new('RGBA', (len(cards) * 410 + 10, 740), (17, 18, 20, 255))
        for i, c in enumerate(cards):
            th = c.resize((400, 714), Image.LANCZOS); b = Image.new('RGBA', th.size, col)
            b.alpha_composite(th); prev.alpha_composite(b, (10 + i * 410, 13))
        prev.convert('RGB').save(os.path.join(out_dir, 'preview-%s.jpg' % name), quality=90)


if __name__ == '__main__':
    cut(sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3])
