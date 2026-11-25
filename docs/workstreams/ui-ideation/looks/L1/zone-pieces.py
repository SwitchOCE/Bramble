#!/usr/bin/env python3
"""Cut the painted zone pieces (prompts-5.txt) out of their flat grounds and save them where screen.html reads them.

usage: zone-pieces.py            (reads /data/bramble-art/uiid-looks/L1/l1z-*.png, writes /data/ui-ideation/looks/L1/pieces/)
Prints, for the arch, where its opening sits inside the trimmed piece (the ARCH_PIECE numbers in screen.html).
"""
import os
from PIL import Image, ImageDraw

SRC = "/data/bramble-art/uiid-looks/L1/"
OUT = "/data/ui-ideation/looks/L1/pieces/"


def key_out(im, seeds, thresh):
    """Flood-fill from each seed, turning the connected flat ground transparent."""
    im = im.convert("RGBA")
    marker = (255, 0, 255, 0)
    for s in seeds:
        if im.getpixel(s)[3] == 0:
            continue
        ImageDraw.floodfill(im, s, marker, thresh=thresh)
    return im


def corners(im, inset=3):
    w, h = im.size
    return [(inset, inset), (w - 1 - inset, inset), (inset, h - 1 - inset), (w - 1 - inset, h - 1 - inset)]


def trim(im):
    box = im.getchannel("A").getbbox()
    return im.crop(box), box


def save(im, name, width):
    w, h = im.size
    im = im.resize((width, round(h * width / w)), Image.LANCZOS)
    im.save(OUT + name)
    print(name, im.size, os.path.getsize(OUT + name) // 1024, "KB")


def arch():
    im = Image.open(SRC + "l1z-arch.png")
    w, h = im.size
    im = key_out(im, corners(im) + [(w // 2, 3)], 40)
    im, box = trim(im)
    w, h = im.size
    # the opening: flood from the middle, then measure what that removed
    before = im.getchannel("A")
    im = key_out(im, [(w // 2, h // 2)], 60)
    after = im.getchannel("A")
    diff = Image.eval(Image.merge("L", [before]), lambda v: v).point(lambda v: v)
    hole = Image.new("L", im.size, 0)
    bp, ap, hp = before.load(), after.load(), hole.load()
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if bp[x, y] and not ap[x, y]:
                hp[x, y] = 255
    l, t, r, b = hole.getbbox()
    print("ARCH_PIECE = { l: %.3f, t: %.3f, w: %.3f, h: %.3f }  (piece %dx%d, opening %dx%d, ratio %.3f)" % (
        l / w, t / h, (r - l) / w, (b - t) / h, w, h, r - l, b - t, (r - l) / (b - t)))
    save(im, "l1z-arch.png", 520)


def on_black(name, width, thresh=28, extra=(), top_only=False):
    im = Image.open(SRC + name)
    im = key_out(im, (corners(im)[:2] if top_only else corners(im)) + list(extra), thresh)
    im, _ = trim(im)
    save(im, name, width)


def frame(name, width):
    """A frame on black with a black opening: cut both away, and print where the opening sits."""
    im = Image.open(SRC + name)
    im = key_out(im, corners(im), 22)
    im, _ = trim(im)
    w, h = im.size
    before = im.getchannel("A")
    im = key_out(im, [(w // 2, h // 2)], 22)
    after = im.getchannel("A")
    hole = Image.new("L", im.size, 0)
    bp, ap, hp = before.load(), after.load(), hole.load()
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if bp[x, y] and not ap[x, y]:
                hp[x, y] = 255
    l, t, r, b = hole.getbbox()
    print("%s opening = { l: %.3f, t: %.3f, w: %.3f, h: %.3f }  (piece %dx%d)" % (name, l / w, t / h, (r - l) / w, (b - t) / h, w, h))
    save(im, name, width)


def tile(name):
    im = Image.open(SRC + name).convert("RGB")
    im = im.resize((488, 732), Image.LANCZOS)
    out = name.replace(".png", ".jpg")
    im.save(OUT + out, quality=90)
    print(out, im.size)


def head_glass(hue, rim=13):
    """The window head with the column's own glass in it: the stone arch from the painted head, the panes from the
    column tile, so the lead lattice runs unbroken from the head into the lights below (owner, 25 Nov).
    The tile is drawn on screen from y = 244, so the head shows the tile's last 488 rows (of 732, at 2x)."""
    from PIL import ImageFilter
    head = Image.open(OUT + "l1z-head-%s.png" % hue).convert("RGBA").resize((488, 488), Image.LANCZOS)
    tile = Image.open(OUT + "l1z-quarry-%s.jpg" % hue).convert("RGBA").crop((0, 244, 488, 732))
    a = head.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    inner = a.filter(ImageFilter.MinFilter(2 * rim + 1)).filter(ImageFilter.GaussianBlur(1.2))
    out = head.copy()
    out.paste(tile, (0, 0), inner)
    out.putalpha(head.getchannel("A"))
    out.save(OUT + "l1z-headglass-%s.png" % hue)
    print("l1z-headglass-%s.png" % hue, out.size)


if __name__ == "__main__":
    for f, fn in [("l1z-arch.png", arch),
                  ("l1z-quarry-slate.png", lambda: tile("l1z-quarry-slate.png")),
                  ("l1z-quarry-moss.png", lambda: tile("l1z-quarry-moss.png")),
                  ("l1z-head-slate.png", lambda: on_black("l1z-head-slate.png", 488, thresh=36, top_only=True)),
                  ("l1z-head-moss.png", lambda: on_black("l1z-head-moss.png", 488, thresh=36, top_only=True)),
                  ("l1z-hanger.png", lambda: on_black("l1z-hanger.png", 400, thresh=14)),
                  ("l1z-board.png", lambda: on_black("l1z-board.png", 420)),
                  ("l1z-health.png", lambda: on_black("l1z-health.png", 460)),
                  ("l1h-heart.png", lambda: on_black("l1h-heart.png", 320)),
                  ("l1h-hero-frame.png", lambda: frame("l1h-hero-frame.png", 520)),
                  ("l1h-end-swords.png", lambda: on_black("l1h-end-swords.png", 340)),
                  ("l1h-end-ring.png", lambda: frame("l1h-end-ring.png", 340)),
                  ("l1h-end-shield.png", lambda: on_black("l1h-end-shield.png", 340)),
                  ("l1h-end-bell.png", lambda: on_black("l1h-end-bell.png", 340, thresh=16)),
                  ("l1s-rosette-stone.png", lambda: on_black("l1s-rosette-stone.png", 184, thresh=20)),
                  ("l1s-rosette-gilt.png", lambda: on_black("l1s-rosette-gilt.png", 184, thresh=20)),
                  ("l1s-lantern-dark.png", lambda: on_black("l1s-lantern-dark.png", 176, thresh=10)),
                  ("l1s-lantern-lit.png", lambda: on_black("l1s-lantern-lit.png", 176, thresh=10))]:
        if os.path.exists(SRC + f):
            fn()
        else:
            print("missing", f)
    for hue in ("slate", "moss"):
        head_glass(hue)
