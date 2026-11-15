"""Cut a six-card frame sheet into one frame per tier, in card space, with a clear window.

Usage: python frame_cut.py <sheet.png> <slots.json> <out_dir>

The sheet is a Codex frame sheet drawn over a six-slot layout guide; slots.json holds each
slot's x, y, w, h on the 1024 x 1536 sheet. For each tier it writes:
  tier<N>-<name>.png         1120 x 2000 RGBA (the 560 x 1000 card spec doubled),
                             window and outside transparent, lead kept
  tier<N>-<name>-padded.png  the same with a 120 px margin on every side (1360 x 2240),
                             card top-left at (120, 120), outer glow kept
  preview-cut.jpg            all six over magenta, to check the cut
and prints each tier's window in 560 x 1000 card units.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

NAMES = ['common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic']
PAD = 120                 # margin in card-space px
SCALE = 2000 / 560        # slot px -> card-space px (slot height 560)


def _flood(mask, seeds):
    im = Image.fromarray(mask.astype(np.uint8) * 255).copy()   # copy: fromarray images ignore floodfill
    for s in seeds:
        if im.getpixel(s) == 255:
            ImageDraw.floodfill(im, s, 128)
    return np.array(im) == 128


def cut(sheet, slots, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    a0 = np.asarray(Image.open(sheet).convert('RGB'))
    bg = np.median(np.concatenate([a0[:4].reshape(-1, 3), a0[-4:].reshape(-1, 3)]), 0).astype(np.uint8)
    p0 = 100   # pad the sheet with its own background so edge slots can be cropped with a margin
    a = np.empty((a0.shape[0] + 2 * p0, a0.shape[1] + 2 * p0, 3), np.uint8); a[:] = bg; a[p0:-p0, p0:-p0] = a0
    src, ai, m = Image.fromarray(a).copy(), a.astype(int), PAD / SCALE
    size = (1120 + 2 * PAD, 2000 + 2 * PAD)
    cards = []
    for s in slots:
        t = s['tier']
        box = tuple(int(round(v)) + p0 for v in (s['x'] - m, s['y'] - m, s['x'] + s['w'] + m, s['y'] + s['h'] + m))
        sub = ai[box[1]:box[3], box[0]:box[2]]; H, W, _ = sub.shape
        cw = sub[int(H * .45) - 3:int(H * .45) + 3, W // 2 - 3:W // 2 + 3].reshape(-1, 3).mean(0)
        win = _flood(np.abs(sub - cw).sum(2) < 10, [(W // 2, int(H * .45))])
        out = _flood(np.abs(sub - bg.astype(int)).sum(2) < 12,
                     [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1), (W // 2, 0), (W // 2, H - 1)])
        big = src.crop(box).resize(size, Image.LANCZOS)
        up = lambda mk: np.asarray(Image.fromarray((mk * 255).astype(np.uint8)).resize(size, Image.BILINEAR)) / 255
        win_u, out_u = up(win), up(out)
        glow = np.clip((np.asarray(big).astype(int).mean(2) - 24) * 5, 0, 255) / 255
        padded = big.convert('RGBA')
        padded.putalpha(Image.fromarray(((1 - win_u) * np.where(out_u > .5, glow, 1) * 255).astype(np.uint8)))
        padded.save(os.path.join(out_dir, f'tier{t}-{NAMES[t-1]}-padded.png'))
        card = big.convert('RGBA')
        card.putalpha(Image.fromarray(((1 - np.maximum(win_u, out_u)) * 255).astype(np.uint8)))
        card = card.crop((PAD, PAD, PAD + 1120, PAD + 2000)); card.save(os.path.join(out_dir, f'tier{t}-{NAMES[t-1]}.png'))
        cards.append(card)
        w2 = win_u[PAD:PAD + 2000, PAD:PAD + 1120] > .5
        col, row = np.where(w2[:, 560])[0], np.where(w2[1000])[0]
        print(f'tier {t} {NAMES[t-1]}: window top {col.min()/2}, bottom {col.max()/2}, sides {row.min()/2} and {row.max()/2}')
    prev = Image.new('RGBA', (6 * 400 + 70, 740), (17, 18, 20, 255))
    for i, c in enumerate(cards):
        th = c.resize((400, 714), Image.LANCZOS); bgm = Image.new('RGBA', th.size, (200, 60, 160, 255))
        bgm.alpha_composite(th); prev.alpha_composite(bgm, (10 + i * 410, 13))
    prev.convert('RGB').save(os.path.join(out_dir, 'preview-cut.jpg'), quality=88)


if __name__ == '__main__':
    cut(sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3])
