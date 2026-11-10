#!/usr/bin/env python3
"""Reproducible, static layout studies made with real Godot widget captures.

Only surfaces, contact shadows and light are drawn here. No unit, portrait, badge,
button or card text is painted or substituted. All geometry is reproducible with
Godot Polygon2D/Control nodes; the diorama uses a pinhole projection and billboards.
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import math
import random
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
SIZES = [(1920, 1080), (1688, 780)]
OPTIONS = {
    "woodland-table": ("Woodland Table", "One surface; a stable central stack.", "mosswood-mist"),
    "sidecar-market": ("Sidecar Market", "Shop left; formation right; opposing ranks face across the gap.", "weald-glow"),
    "rootbridge-diorama": ("Rootbridge Diorama", "A perspective stage with upright pieces and a distant merchant.", "fen-wisplight"),
}
INK = (37, 33, 24, 255)
CREAM = (245, 235, 207, 255)
FONT = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
BOLD = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")


def font(size, bold=False):
    return ImageFont.truetype(str(BOLD if bold else FONT), size)


def cover(image, size):
    return ImageOps.fit(image, size, Image.Resampling.LANCZOS)


class Study:
    def __init__(self, option, state, size, assets, out, draw_nodes=True):
        self.option, self.state, self.size = option, state, size
        self.assets, self.out = assets, out
        self.scale = size[1] / 1080
        self.w = size[0] / self.scale
        self.cx = self.w / 2
        self.logical_size = (round(self.w), 1080)
        backdrop = ROOT / f"docs/ideation/ui/backdrops/backdrop-{OPTIONS[option][2]}.jpg"
        self.im = cover(Image.open(backdrop).convert("RGBA"), self.logical_size)
        # Still layers, not parallax: dark nearby framing and a quiet distant opening.
        shade = Image.new("RGBA", self.im.size)
        d = ImageDraw.Draw(shade)
        for y in range(1080):
            a = round(18 + 38 * (y / 1080) ** 2)
            d.line((0, y, self.im.width, y), fill=(20, 36, 30, a))
        self.im = Image.alpha_composite(self.im, shade)
        self.placements = []
        self.draw_nodes = draw_nodes
        self.bases = None
        self.parts = {}
        self.rec = json.loads((assets / "recruit/parts.json").read_text())
        self.fight = json.loads((assets / "fight/parts.json").read_text())

    def part(self, group, key):
        cache_key = (group, key)
        if cache_key not in self.parts:
            im = Image.open(self.assets / group / f"{key}.png").convert("RGBA")
            bbox = im.getchannel("A").point(lambda v: 255 if v > 5 else 0).getbbox()
            assert bbox, cache_key
            self.parts[cache_key] = (im.crop(bbox), bbox, im.size)
        return self.parts[cache_key]

    def paste(self, group, key, x, y, width=None, height=None, shadow=0, rotation=0):
        piece, bbox, native_size = self.part(group, key)
        ratio = (width / piece.width) if width else (height / piece.height)
        target = (round(piece.width * ratio), round(piece.height * ratio))
        tile = piece.resize(target, Image.Resampling.LANCZOS)
        # Rotation is an ordinary Control transform. Card faces are never perspective-warped.
        if rotation:
            tile = tile.rotate(rotation, Image.Resampling.BICUBIC, expand=True)
        if shadow:
            layer = Image.new("RGBA", self.im.size)
            sd = ImageDraw.Draw(layer)
            sd.ellipse((x + 10, y + target[1] - 13, x + target[0] + shadow, y + target[1] + 18), fill=(5, 15, 12, 100))
            self.im = Image.alpha_composite(self.im, layer.filter(ImageFilter.GaussianBlur(10)))
        if self.draw_nodes:
            self.im.alpha_composite(tile, (round(x), round(y)))
        self.placements.append({"group": group, "key": key, "xy": [x, y], "ratio": ratio,
                                "bbox": bbox, "native_size": native_size, "rotation": rotation})
        return target

    def surface(self, box, moss=True, radius=38, thickness=25):
        x, y, w, h = box
        sh = Image.new("RGBA", self.im.size)
        sd = ImageDraw.Draw(sh)
        sd.rounded_rectangle((x - 8, y + 16, x + w + 18, y + h + 48), radius, fill=(9, 20, 14, 130))
        self.im = Image.alpha_composite(self.im, sh.filter(ImageFilter.GaussianBlur(22)))
        d = ImageDraw.Draw(self.im)
        d.rounded_rectangle((x, y + thickness, x + w, y + h + thickness), radius, fill=(66, 45, 26), outline=INK, width=5)
        d.rounded_rectangle((x, y, x + w, y + h), radius, fill=(161, 122, 68), outline=INK, width=5)
        d.rounded_rectangle((x + 8, y + 5, x + w - 8, y + h - 8), radius - 5,
                            outline=(211, 179, 116), width=3)
        rng = random.Random(42)
        for row in range(5):
            yy = y + 10 + row * (h - 20) / 4
            points = [(x + 15 + i * (w - 30) / 20, yy + math.sin(i * .6 + row) * 3 + rng.random() * 2) for i in range(21)]
            d.line(points, fill=(116, 84, 46, 100), width=2)
        if moss:
            d.rounded_rectangle((x + 22, y + 20, x + w - 22, y + h - 20), radius - 12,
                                fill=(62, 85, 66), outline=(42, 53, 36), width=3)
            d.rounded_rectangle((x + 27, y + 25, x + w - 27, y + h - 25), radius - 15,
                                outline=(99, 114, 77), width=2)

    def pad(self, x, y, width, height):
        d = ImageDraw.Draw(self.im)
        d.rounded_rectangle((x - 5, y + 7, x + width + 5, y + height + 11), 17,
                            fill=(41, 61, 45), outline=(91, 106, 71), width=2)

    def card(self, group, key, x, y, width, height=None, lift=0):
        if height is None:
            height = width * .91
        self.pad(x, y, width, height)
        if key not in (self.rec if group == "recruit" else self.fight):
            return
        # Mid-fight carries the captured state; a lifted active piece is a positional study.
        is_attacker = group == "fight" and self.fight.get("attacker_key") == key
        self.paste(group, key, x, y - lift - (26 if is_attacker else 0), width=width,
                   shadow=18 if self.option == "rootbridge-diorama" else 6)

    def lobby(self, vertical=False):
        if vertical:
            x, y = 55, 154
            self.surface((x - 5, y - 22, 126, 787), moss=True, radius=44, thickness=12)
            for i in range(8):
                self.paste("recruit", f"lobby_{i}", x + 9, y + i * 95, width=98)
        else:
            x = self.cx - 500
            self.surface((x - 20, 18, 1040, 115), moss=True, radius=48, thickness=10)
            for i in range(8):
                self.paste("recruit", f"lobby_{i}", x + 8 + i * 125, 30, width=106)

    def hand(self, center, y, width=920):
        count = len([k for k in self.rec if k.startswith("hand_")])
        self.surface((center - width / 2 - 20, y - 12, width + 40, 121), moss=False, radius=24, thickness=12)
        tile_w = min(92, (width - 18 * (count - 1)) / count)
        pitch = min(tile_w + 18, (width - tile_w) / max(1, count - 1))
        left = center - (pitch * (count - 1) + tile_w) / 2
        for i in range(count):
            self.paste("recruit", f"hand_{i}", left + i * pitch, y, width=tile_w)

    def actions(self, x, y):
        self.paste("recruit", "gold", x + 22, y, width=218)
        self.paste("recruit", "tier", x + 40, y + 110, height=34)
        self.paste("recruit", "round", x + 111, y + 111, height=30)
        self.paste("recruit", "tier_up", x, y + 175, width=260)
        self.paste("recruit", "refresh", x + 10, y + 292, width=240)
        self.paste("recruit", "freeze", x + 10, y + 415, width=240)
        self.paste("recruit", "end_turn", x - 5, 899, width=270)

    def fight_controls(self, x, y):
        self.surface((x - 15, y - 10, 215, 107), moss=True, radius=40, thickness=10)
        self.paste("fight", "pause", x, y, width=82)
        self.paste("fight", "speed", x + 102, y, width=82)

    def woodland(self):
        center = self.cx + 10
        self.lobby(vertical=True)
        self.surface((center - 640, 201 if self.state == "recruit" else 167, 1280, 776 if self.state == "recruit" else 810))
        if self.state == "recruit":
            for i in range(6):
                key = f"shop_{i}" if i < 5 else "spell_0"
                self.paste("recruit", key, center - 563 + i * 190, 245, width=169)
            d = ImageDraw.Draw(self.im)
            d.line((center - 606, 464, center + 606, 464), fill=(151, 144, 95), width=2)
            for i in range(4):
                self.card("recruit", f"board_{i}", center - 373 + i * 195, 500, 161)
            for i in range(3):
                self.card("recruit", f"board_{i + 4}", center - 275 + i * 195, 699, 161)
            self.paste("recruit", "hero", center - 603, 654, width=114)
            self.hand(center, 917)
            self.actions(center + 666, 242)
        else:
            for side in range(2):
                for row in range(2):
                    front = row == (1 if side == 0 else 0)
                    count = 4 if front else 3
                    y = (215 if side == 0 else 604) + row * 179
                    for i in range(count):
                        key = f"side_{side}_slot_{i if front else i + 4}"
                        self.card("fight", key, center - (count * 181 - 31) / 2 + i * 181, y, 150)
                self.paste("fight", f"hero_{side}", center - 595, 253 if side == 0 else 745, width=122)
            self.fight_controls(center + 676, 902)
        self.paste("recruit", "gear", self.w - 109, 48, width=76)

    def sidecar(self):
        self.lobby()
        # Rank rotation is deliberate and shared by recruit and fight: four front pieces in
        # the inward column, three back pieces in the outward column. Nothing changes rules.
        board_center = self.cx + 370
        self.surface((board_center - 237, 196, 488, 718), radius=36)
        for front in (True, False):
            count = 4 if front else 3
            x = board_center - 195 if front else board_center + 35
            for i in range(count):
                y = 227 + i * 164 + (0 if front else 82)
                slot = i if front else i + 4
                self.card("recruit" if self.state == "recruit" else "fight",
                          f"board_{slot}" if self.state == "recruit" else f"side_1_slot_{slot}", x, y, 150)
        if self.state == "recruit":
            left = self.cx - 700
            self.surface((left, 245, 535, 610), moss=False, thickness=35)
            for i in range(6):
                key = f"shop_{i}" if i < 5 else "spell_0"
                self.paste("recruit", key, left + 52 + (i % 2) * 238, 277 + (i // 2) * 184, width=171)
            self.paste("recruit", "gold", left + 150, 155, width=215)
            self.paste("recruit", "tier_up", left - 3, 908, width=225)
            self.paste("recruit", "refresh", left + 217, 917, width=147)
            self.paste("recruit", "freeze", left + 377, 917, width=147)
            self.paste("recruit", "hero", board_center + 300, 642, width=118)
            self.hand(board_center - 5, 941, width=870)
            self.paste("recruit", "end_turn", board_center + 300, 813, width=240)
            self.paste("recruit", "tier", left + 26, 195, height=34)
            self.paste("recruit", "round", left + 383, 190, height=30)
        else:
            enemy_center = self.cx - 370
            self.surface((enemy_center - 251, 196, 488, 718), radius=36)
            for front in (True, False):
                count = 4 if front else 3
                x = enemy_center + 45 if front else enemy_center - 185
                for i in range(count):
                    y = 227 + i * 164 + (0 if front else 82)
                    slot = i if front else i + 4
                    self.card("fight", f"side_0_slot_{slot}", x, y, 150)
            self.paste("fight", "hero_0", self.cx - 825, 485, width=122)
            self.paste("fight", "hero_1", self.cx + 699, 485, width=122)
            self.fight_controls(self.cx - 92, 948)
        self.paste("recruit", "gear", self.w - 109, 48, width=76)

    def project(self, x, z):
        # Pinhole projection of a horizontal plane. z=0 is the near edge; z=1 the far edge.
        # In Godot this is a Camera3D viewing a flat mesh, with Sprite3D billboards for tiles.
        k = 1 / (1 + .68 * z)
        return self.cx + x * k, 1000 - 720 * z * k * 1.68, k

    def stage(self):
        far_l = self.project(-735, 1)[:2]
        far_r = self.project(735, 1)[:2]
        near_l = self.project(-735, 0)[:2]
        near_r = self.project(735, 0)[:2]
        corners = [far_l, far_r, near_r, near_l]
        sh = Image.new("RGBA", self.im.size)
        ImageDraw.Draw(sh).polygon([(x + 12, y + 35) for x, y in corners], fill=(7, 20, 19, 160))
        self.im = Image.alpha_composite(self.im, sh.filter(ImageFilter.GaussianBlur(24)))
        d = ImageDraw.Draw(self.im)
        d.polygon([near_l, near_r, (near_r[0] + 3, 1045), (near_l[0] - 3, 1045)], fill=(75, 54, 35), outline=INK, width=5)
        d.polygon(corners, fill=(131, 109, 72), outline=INK, width=5)
        inner = [self.project(x, z)[:2] for x, z in [(-695, .97), (695, .97), (695, .03), (-695, .03)]]
        d.polygon(inner, fill=(60, 88, 77), outline=(187, 169, 115), width=3)
        for x in (-490, -245, 0, 245, 490):
            d.line([self.project(x, 1)[:2], self.project(x, 0)[:2]], fill=(82, 104, 84), width=2)
        for z in (.22, .48, .75):
            d.line([self.project(-695, z)[:2], self.project(695, z)[:2]], fill=(82, 104, 84), width=2)

    def depth_rank(self, group, side, front, z):
        count = 4 if front else 3
        for i in range(count):
            x, y, k = self.project((i - (count - 1) / 2) * 245, z)
            width = 205 * k
            key = f"board_{i if front else i + 4}" if group == "recruit" else f"side_{side}_slot_{i if front else i + 4}"
            # Contact footprints lie on the plane. Upright, empty card-shaped panels would
            # incorrectly hover above the far edge and make the perspective ambiguous.
            d = ImageDraw.Draw(self.im)
            d.ellipse((x - width * .45, y - width * .10, x + width * .45, y + width * .13),
                      fill=(42, 65, 55), outline=(109, 124, 87), width=2)
            if key in (self.rec if group == "recruit" else self.fight):
                lift = 26 if group == "fight" and self.fight.get("attacker_key") == key else 0
                self.paste(group, key, x - width / 2, y - width * .88 - lift, width=width, shadow=24)

    def diorama(self):
        self.lobby()
        self.stage()
        if self.state == "recruit":
            self.surface((self.cx - 535, 195, 1070, 219), moss=False, radius=32, thickness=38)
            for i in range(6):
                self.paste("recruit", f"shop_{i}" if i < 5 else "spell_0", self.cx - 490 + i * 171, 214, width=141)
            self.depth_rank("recruit", 1, True, .45)
            self.depth_rank("recruit", 1, False, .14)
            self.paste("recruit", "hero", self.cx - 639, 710, width=129, shadow=30)
            self.hand(self.cx, 944, width=925)
            self.actions(self.cx + 666, 282)
        else:
            self.depth_rank("fight", 0, False, .93)
            self.depth_rank("fight", 0, True, .69)
            self.depth_rank("fight", 1, True, .34)
            self.depth_rank("fight", 1, False, .06)
            self.paste("fight", "hero_0", self.cx - 490, 309, width=108, shadow=24)
            self.paste("fight", "hero_1", self.cx - 659, 773, width=143, shadow=35)
            self.fight_controls(self.cx + 640, 890)
        # The original painting already has foreground silhouettes. Bring only its extreme
        # corners in front of the near rim, a static occlusion layer with no extra generation.
        paint = cover(Image.open(ROOT / "docs/ideation/ui/backdrops/backdrop-fen-wisplight.jpg").convert("RGBA"), self.im.size)
        mask = Image.new("L", self.im.size)
        md = ImageDraw.Draw(mask)
        md.polygon([(0, 865), (175, 1005), (320, 1080), (0, 1080)], fill=255)
        md.polygon([(self.w, 865), (self.w - 160, 1015), (self.w - 290, 1080), (self.w, 1080)], fill=255)
        paint.putalpha(mask.filter(ImageFilter.GaussianBlur(2)))
        self.im = Image.alpha_composite(self.im, paint)
        self.paste("recruit", "gear", self.w - 109, 48, width=76)

    def save(self):
        getattr(self, {"woodland-table": "woodland", "sidecar-market": "sidecar", "rootbridge-diorama": "diorama"}[self.option])()
        # All source paintings were image-generated, so every still carries the concept label.
        d = ImageDraw.Draw(self.im)
        d.rounded_rectangle((20, 22, 179, 69), 14, fill=(24, 42, 35, 235))
        d.text((37, 29), "concept", font=font(28), fill=CREAM)
        dest = self.out / self.option
        dest.mkdir(parents=True, exist_ok=True)
        stem = f"{self.state}_{self.size[0]}x{self.size[1]}"
        if not self.draw_nodes:
            self.im.save(dest / f"{stem}_base.png")
            return None
        self.im = self.im.resize(self.size, Image.Resampling.LANCZOS)
        self.im.convert("RGB").save(dest / f"{stem}.jpg", quality=94, subsampling=0)
        # A placement manifest lets the table option also be rendered as actual Godot nodes.
        (dest / f"{stem}.json").write_text(json.dumps({"logical_size": self.logical_size, "placements": self.placements}, indent=2))
        return {"option": self.option, "state": self.state, "size": list(self.size),
                "file": f"{self.option}/{stem}.jpg", "concept": True}


def sheet(out, references):
    margin, gap, cell_w = 28, 20, 760
    cell_h = round(cell_w * 1080 / 1920)
    row_h = 98 + 54 + cell_h + 32
    result = Image.new("RGB", (2 * margin + 2 * cell_w + gap, row_h * len(OPTIONS) * 2 + 70), (20, 34, 29))
    d = ImageDraw.Draw(result)
    d.text((margin, 13), "BRAMBLE  /  LAYOUT STUDIES", font=font(35, True), fill=(222, 214, 183))
    for row, (key, (name, _idea, _backdrop)) in enumerate(OPTIONS.items()):
        for index, (state, ref_key, label) in enumerate([("recruit", "busy", "Recruit"), ("fight", "fight", "Mid-fight")]):
            y = 70 + (row * 2 + index) * row_h
            d.rectangle((0, y, result.width, y + 88), fill=(44, 65, 49))
            d.text((margin, y + 6), f"{name} / {label}", font=font(60, True), fill=(247, 236, 202))
            y += 98
            d.text((margin, y), f"Bramble · {label}", font=font(31, True), fill=(229, 225, 207))
            d.text((margin + cell_w + gap, y), f"The Bazaar · {label}", font=font(31, True), fill=(229, 225, 207))
            y += 54
            result.paste(Image.open(out / key / f"{state}_1920x1080.jpg").resize((cell_w, cell_h), Image.Resampling.LANCZOS), (margin, y))
            result.paste(cover(Image.open(references[ref_key]), (cell_w, cell_h)), (margin + cell_w + gap, y))
            y += cell_h
    result.save(out / "sheet.jpg", quality=94, subsampling=0)


def gallery(out):
    sections = []
    notes = (ROOT / "docs/ideation/ui/layouts.md").read_text()
    for key, (name, idea, _) in OPTIONS.items():
        images = "".join(f'<a href="{key}/{state}_{w}x{h}.jpg"><figure><img loading="lazy" src="{key}/{state}_{w}x{h}.jpg"><figcaption>{state.capitalize()} · {w} × {h}</figcaption></figure></a>'
                         for w, h in SIZES for state in ("recruit", "fight"))
        images += f'<a href="{key}/reader_1688x780.jpg"><figure><img loading="lazy" src="{key}/reader_1688x780.jpg"><figcaption>Phone · tap reader open</figcaption></figure></a>'
        option_notes = notes.split(f"## {name}\n", 1)[1].split("\n## ", 1)[0]
        critique = re.search(r"\*\*Fresh critic:\*\* (.+)", option_notes)
        critic_text = f'<p><strong>Fresh critic:</strong> {html.escape(critique.group(1))}</p>' if critique else ""
        sections.append(f'<section><h2>{name}</h2><p>{html.escape(idea)}</p>{critic_text}<div class="grid">{images}</div></section>')
    (out / "index.html").write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bramble · Layout options</title><style>body{margin:0;background:#14221d;color:#f0e7ce;font:18px/1.5 system-ui}main{max-width:1500px;margin:auto;padding:24px}h1,h2{line-height:1.1}h2{font-size:36px}section{margin:55px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}a{color:#d9ca94}figure{margin:0}img{width:100%;display:block}figcaption{padding:8px 0;color:#c7c9b3}p{max-width:70ch}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><main>
<h1>Bramble · Layout options</h1><p>Static layout concepts using real Godot tiles, portraits and controls. Painted worlds are concepts. Tap a still to open it at native size. No motion-dependent depth.</p>
<p><a href="sheet.jpg">Open the Bazaar comparison sheet</a> · <a href="notes.md">Option details and fresh critic notes</a></p>'''
        + "".join(sections) + '</main></html>')


def readers(out, assets):
    source = Image.open(assets / "recruit/reader.png").convert("RGBA")
    source = source.crop(source.getchannel("A").getbbox())
    source = source.resize((340, round(source.height * 340 / source.width)), Image.Resampling.LANCZOS)
    for key in OPTIONS:
        im = Image.open(out / key / "recruit_1688x780.jpg").convert("RGBA")
        layer = Image.new("RGBA", im.size)
        ImageDraw.Draw(layer).rounded_rectangle((175, 148, 535, 158 + source.height), 20, fill=(6, 16, 10, 180))
        im = Image.alpha_composite(im, layer.filter(ImageFilter.GaussianBlur(16)))
        im.alpha_composite(source, (170, 140))
        im.convert("RGB").save(out / key / "reader_1688x780.jpg", quality=94, subsampling=0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, default=ROOT / "build/layout-parts")
    parser.add_argument("--out", type=Path, default=ROOT / "build/layouts")
    parser.add_argument("--references", type=Path, default=Path("/data/bramble-reference/bazaar"))
    parser.add_argument("--finalize", action="store_true", help="Use the Godot table renders, then rebuild sheet and checksums")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    manifest = []
    for option in OPTIONS:
        for state in ("recruit", "fight"):
            for size in SIZES:
                stem = f"{state}_{size[0]}x{size[1]}"
                if args.finalize:
                    target = args.out / option / f"{stem}.jpg"
                    native = target.with_suffix(".png")
                    if native.exists():
                        Image.open(native).convert("RGB").save(target, quality=94, subsampling=0)
                    manifest.append({"option": option, "state": state, "size": list(size),
                                     "file": f"{option}/{stem}.jpg", "concept": True})
                else:
                    manifest.append(Study(option, state, size, args.assets, args.out).save())
                    if option == "woodland-table" and state == "recruit":
                        Study(option, state, size, args.assets, args.out, draw_nodes=False).save()
    refs = {"busy": args.references / "main-play-busy--steam-trailer-0028.jpg",
            "fight": args.references / "fight--steam-trailer-0034.jpg"}
    readers(args.out, args.assets)
    sheet(args.out, refs)
    gallery(args.out)
    for entry in manifest:
        entry["renderer"] = "rearranged real Godot nodes" if entry["option"] == "woodland-table" and entry["state"] == "recruit" else "transparent real Godot widget captures recomposed in Pillow"
        entry["sha256"] = hashlib.sha256((args.out / entry["file"]).read_bytes()).hexdigest()
    (args.out / "manifest.json").write_text(json.dumps({"stills": manifest,
        "sources": {"busy": {"file": str(refs["busy"]), "source": "https://store.steampowered.com/app/1617400/", "timestamp": "00:01:33.000"},
                    "fight": {"file": str(refs["fight"]), "source": "https://store.steampowered.com/app/1617400/", "timestamp": "00:01:44.500"}},
        "method": "Godot alpha widget captures; scripted surfaces, shadows and pinhole projection; source paintings are concepts",
        "motion": "None: all depth is visible in stills", "combat_event_index": json.loads((args.assets / "fight/parts.json").read_text())["event_index"]}, indent=2))
    print(f"Wrote {len(manifest)} native-size stills, comparison sheet and gallery to {args.out}")


if __name__ == "__main__":
    main()
