"""Cut a six-card frame sheet into one frame per tier, in card space, with a clear window.

Usage: python frame_cut.py <sheet.png> <slots.json> <out_dir>

The sheet is a Codex frame sheet drawn over a six-slot layout guide; slots.json holds each
slot's x, y, w, h on the 1024 x 1536 sheet. For each tier it writes:
  tier<N>-<name>.png         1120 x 2000 RGBA (the 560 x 1000 card spec doubled),
                             window and outside transparent, lead kept
  tier<N>-<name>-padded.png  the same with a 120 px margin on every side (1360 x 2240),
                             card top-left at (120, 120), the card's own outer glow kept
  preview-white.jpg, preview-magenta.jpg   all six over white and over magenta, to check the cut
and prints each tier's window in 560 x 1000 card units.

How the cut works (needs numpy, scipy, Pillow):
- Background and window are found by colour distance from the sheet's background and from
  the window's own fill, measured on the sheet at its native resolution.
- The frame is the largest connected piece of non-background; loose specks are dropped.
- The outer edge is the guide's card outline, fitted to where Codex actually drew the card (best
  overlap over shifts of up to 6 px and scales of 96.5% to 101%), drawn anti-aliased at full size and
  pulled in slightly so it lands on the outer lead. Straight edges, no glow, no fuzz.
- The window is the piece of window colour connected to the card's centre, with small holes
  filled. Petals and jewels that reach into the window stay part of the frame.
- The window mask is opened and closed to remove one-pixel spikes, then scaled up and softened by
  about a pixel so its edge is smooth, not stair-stepped.
- Soft edge pixels take the colour of the nearest solid frame pixel, so no dark background shows
  through as a fringe.
- The padded version keeps glow only within a short distance of the card's own outline, so the
  neighbouring cards on the sheet never leak in.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

NAMES = ['common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic']
PAD = 120                 # margin in card-space px
SCALE = 2000 / 560        # slot px -> card-space px (slot height 560)
BG_DIST = 22              # colour distance (sum of |dR|+|dG|+|dB|) that still counts as background
WIN_DIST = 16             # ... as window fill
GLOW_REACH = 10           # slot px outside the frame where glow may stay (padded version)
FUZZ_DIST = 40            # dark fuzz at an edge this close to the background or window is removed
WIN_FUZZ_DIST = 30        # ... the same at the window edge (lower: the inner lead is close to the window colour)
EDGE_SMOOTH = 4           # card-space px of smoothing on the window's outline
EDGE_INSET = 2            # card-space px the outer edge is pulled in from the fitted outline
OUTLINE_SLACK = 3         # slot px the frame may sit outside the guide's outline
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
    """Scale a slot-resolution mask to card space with a smooth outline: blur, re-threshold, then a
    one-pixel soft edge. Removes the stair-steps and the noise of the low-resolution source."""
    up = Image.fromarray((mask * 255).astype(np.uint8)).resize(size, Image.BILINEAR)
    up = up.filter(ImageFilter.GaussianBlur(EDGE_SMOOTH))
    hard = (np.asarray(up) > 127).astype(np.uint8) * 255
    return np.asarray(Image.fromarray(hard).filter(ImageFilter.GaussianBlur(1.0))).astype(float) / 255


def _poly_mask(size, origin, k, dx, dy, sc):
    """The card outline as a boolean mask at slot resolution: guide outline scaled by k (slot px per
    card unit) about the card's centre by sc, shifted by (dx, dy), with the card's corner at origin."""
    W, H = size; im = Image.new('L', (W, H), 0)
    cxu, cyu = 280, 500
    pts = [(origin + dx + (cxu + (x - cxu) * sc) * k, origin + dy + (cyu + (y - cyu) * sc) * k) for x, y in OUTER]
    ImageDraw.Draw(im).polygon(pts, fill=255)
    return np.asarray(im) > 0


def _poly_alpha(size, pad, _unused, dx, dy, sc, k, ss=4):
    """The same outline at card-space resolution, anti-aliased by drawing at ss times and shrinking."""
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


def cut(sheet, slots, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    a0 = np.asarray(Image.open(sheet).convert('RGB'))
    bg = np.median(np.concatenate([a0[:4].reshape(-1, 3), a0[-4:].reshape(-1, 3)]), 0)
    p0 = 100  # pad the sheet with its own background so edge slots can be cropped with a margin
    a = np.empty((a0.shape[0] + 2 * p0, a0.shape[1] + 2 * p0, 3), np.uint8); a[:] = bg.astype(np.uint8); a[p0:-p0, p0:-p0] = a0
    src, m = Image.fromarray(a).copy(), PAD / SCALE
    size = (1120 + 2 * PAD, 2000 + 2 * PAD)
    cards = []
    for s in slots:
        t = s['tier']
        box = tuple(int(round(v)) + p0 for v in (s['x'] - m, s['y'] - m, s['x'] + s['w'] + m, s['y'] + s['h'] + m))
        sub = a[box[1]:box[3], box[0]:box[2]].astype(int); H, W, _ = sub.shape
        cy, cx = int(H * .45), W // 2
        wcol = np.median(sub[cy - 4:cy + 4, cx - 4:cx + 4].reshape(-1, 3), 0)

        # this card only: keep to the slot (+ a little) so neighbours never count
        own = np.zeros((H, W), bool)
        mm = int(round(m)); own[max(0, mm - 14):H - mm + 14, max(0, mm - 14):W - mm + 14] = True

        non_bg = (np.abs(sub - bg).sum(2) > BG_DIST) & own
        non_bg = ndi.binary_opening(non_bg, iterations=1)
        card_solid = ndi.binary_fill_holes(_largest(non_bg))             # frame + window + glow, no specks

        win = _component_at((np.abs(sub - wcol).sum(2) < WIN_DIST) & card_solid, cy, cx)
        win = ndi.binary_closing(win, iterations=2)
        win = ndi.binary_fill_holes(win)
        win = ndi.binary_opening(win, iterations=1)
        # take in near-black fuzz at the window edge: dark pixels touching the window, short of the lead
        fuzz = (np.abs(sub - wcol).sum(2) < WIN_FUZZ_DIST) & ndi.binary_dilation(win, iterations=3)
        win = ndi.binary_opening(win | fuzz, iterations=1)

        # rough frame, used only to fit the card's outline: everything solid within a few px of the
        # guide's outline, minus dark fuzz connected to the background
        poly0 = _poly_mask((W, H), m, s['w'] / 560, 0, 0, 1.0)
        outside = _component_at((np.abs(sub - bg).sum(2) < FUZZ_DIST) | ~own, 0, 0)
        rough = card_solid & ndi.binary_dilation(poly0, iterations=OUTLINE_SLACK + 3) & ~outside

        # fit the guide's outline to where Codex drew the card: best overlap over shifts of up to 6 px and scales of 96.5% to 101%
        best = (-1, 0, 0, 1.0)
        for sc in (0.965, 0.97, 0.975, 0.98, 0.985, 0.99, 0.995, 1.0, 1.005, 1.01):
            for dy in range(-6, 7):
                for dx in range(-6, 7):
                    pm = _poly_mask((W, H), m, s['w'] / 560, dx, dy, sc)
                    iou = (pm & rough).sum() / max(1, (pm | rough).sum())
                    if iou > best[0]:
                        best = (iou, dx, dy, sc)
        _, dx, dy, sc = best

        # the outer edge is that straight outline, drawn smooth at card-space resolution and pulled
        # in by EDGE_INSET px so it lands on the outer lead, not just past it
        outer_u = _poly_alpha(size, PAD, SCALE * s['w'] / 560 * (560 / s['w']) * (s['w'] / 560),
                              dx * SCALE, dy * SCALE, sc, s['w'] * SCALE / 560)
        win_u = _smooth_edge(win, size)
        alpha_card = outer_u * (1 - win_u)

        big = src.crop(box).resize(size, Image.LANCZOS)
        rgb = np.asarray(big).astype(float)

        # glow (padded version only): bright pixels just outside this card's outline
        near = ndi.binary_dilation(_poly_mask((W, H), m, s['w'] / 560, dx, dy, sc), iterations=GLOW_REACH) & own
        lum = rgb.mean(2)
        glow_u = _up(near.astype(float), size, soften=6) * np.clip((lum - (bg.mean() + 6)) * 4, 0, 255) / 255
        alpha_pad = np.maximum(alpha_card, glow_u * (1 - outer_u) )

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
        rgba(rgb_pad, alpha_pad).save(os.path.join(out_dir, f'tier{t}-{NAMES[t-1]}-padded.png'))
        card = rgba(rgb_card, alpha_card).crop((PAD, PAD, PAD + 1120, PAD + 2000))
        card.save(os.path.join(out_dir, f'tier{t}-{NAMES[t-1]}.png'))
        cards.append(card)
        print(f'tier {t} {NAMES[t-1]}: outline fit IoU {best[0]:.3f}, shift ({dx}, {dy}) slot px, scale {sc}')

        w2 = _up(win.astype(float), size)[PAD:PAD + 2000, PAD:PAD + 1120] > .5
        xs = np.where(w2[1000])[0]
        print(f'tier {t} {NAMES[t-1]}: window sides {xs.min()/2} and {xs.max()/2}')
    for name, col in (('white', (255, 255, 255, 255)), ('magenta', (200, 60, 160, 255))):
        prev = Image.new('RGBA', (6 * 400 + 70, 740), (17, 18, 20, 255))
        for i, c in enumerate(cards):
            th = c.resize((400, 714), Image.LANCZOS); b = Image.new('RGBA', th.size, col)
            b.alpha_composite(th); prev.alpha_composite(b, (10 + i * 410, 13))
        prev.convert('RGB').save(os.path.join(out_dir, f'preview-{name}.jpg'), quality=90)


if __name__ == '__main__':
    cut(sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3])
