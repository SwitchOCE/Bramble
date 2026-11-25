"""Measure how much of each card slot is border glass (not window, not outside).

Usage: python frame_measure.py <sheet.png> <slots.json>
Prints, per tier, the border's share of the card's bounding box and its side width as a share of card width.
"""
import json, sys
import numpy as np
from PIL import Image, ImageDraw

def _flood(mask, seeds):
    im = Image.fromarray(mask.astype(np.uint8) * 255).copy()
    for s in seeds:
        if im.getpixel(s) == 255:
            ImageDraw.floodfill(im, s, 128)
    return np.array(im) == 128

def measure(sheet, slots):
    a = np.asarray(Image.open(sheet).convert('RGB')).astype(int)
    bg = np.median(np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3)]), 0)
    out = []
    for s in slots:
        x0, y0, x1, y1 = int(s['x']), int(s['y']), int(s['x'] + s['w']), int(s['y'] + s['h'])
        sub = a[y0:y1, x0:x1]; H, W, _ = sub.shape
        cw = sub[int(H * .45) - 3:int(H * .45) + 3, W // 2 - 3:W // 2 + 3].reshape(-1, 3).mean(0)
        win = _flood(np.abs(sub - cw).sum(2) < 10, [(W // 2, int(H * .45))])
        outside = _flood(np.abs(sub - bg).sum(2) < 12, [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)])
        border = ~(win | outside)
        row = win[H // 2]; xs = np.where(row)[0]
        side = (xs.min() + (W - 1 - xs.max())) / 2 / W if len(xs) else float('nan')
        out.append({'tier': s['tier'], 'border_share': round(float(border.mean()), 4), 'side': round(float(side), 4)})
    return out

if __name__ == '__main__':
    for r in measure(sys.argv[1], json.load(open(sys.argv[2]))):
        print(r)
