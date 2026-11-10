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
    "woodland-table": ("Woodland Table", "Large pieces on a single illuminated stump top.", "mosswood-mist"),
    "sidecar-market": ("Sidecar Market", "Shop left; formation right; opposing ranks face across the gap.", "weald-glow"),
    "rootbridge-diorama": ("Rootbridge Diorama", "Perspective woodland stage; distant pieces retain their size floor.", "fen-wisplight"),
    "bazaar-stack": ("Bazaar Stack", "Merchant above, formation central, hero and actions in one bottom bar.", "highcrown-rays"),
}
INK = (37, 33, 24, 255)
CREAM = (245, 235, 207, 255)
FONT = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
BOLD = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")


def font(size, bold=False):
    return ImageFont.truetype(str(BOLD if bold else FONT), size)


def cover(image, size):
    return ImageOps.fit(image, size, Image.Resampling.LANCZOS)


def perspective_plane(texture, corners, size):
    """Map one bitmap onto a plane; coefficients map output pixels back to source UVs."""
    source = [(0, 0), (texture.width, 0), (texture.width, texture.height), (0, texture.height)]
    matrix = []
    for (x, y), (u, v) in zip(corners, source):
        matrix.append([x, y, 1, 0, 0, 0, -u*x, -u*y, u])
        matrix.append([0, 0, 0, x, y, 1, -v*x, -v*y, v])
    for column in range(8):
        pivot = max(range(column, 8), key=lambda row: abs(matrix[row][column]))
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        value = matrix[column][column]
        matrix[column] = [n/value for n in matrix[column]]
        for row in range(8):
            if row != column:
                factor = matrix[row][column]
                matrix[row] = [a-factor*b for a, b in zip(matrix[row], matrix[column])]
    coefficients = [row[-1] for row in matrix]
    return texture.transform(size, Image.Transform.PERSPECTIVE, coefficients, Image.Resampling.BICUBIC)


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

    def surface(self, box, moss=True, radius=32, thickness=22):
        """A painted stump/plank surface, softly lit at its centre; never felt."""
        x, y, w, h = map(round, box)
        shadow = Image.new("RGBA", self.im.size)
        ImageDraw.Draw(shadow).rounded_rectangle((x-8, y+10, x+w+12, y+h+35), radius, fill=(8, 18, 12, 155))
        self.im = Image.alpha_composite(self.im, shadow.filter(ImageFilter.GaussianBlur(18)))
        d = ImageDraw.Draw(self.im)
        d.rounded_rectangle((x, y+thickness, x+w, y+h+thickness), radius,
                            fill=(65, 45, 30), outline=(37, 31, 23), width=4)
        material = cover(Image.open(ROOT / "tools/mockup/art/woodland-top.jpg").convert("RGBA"), (w, h))
        if not moss:
            material = ImageEnhance.Color(material).enhance(.75)
        mask = Image.new("L", (w, h))
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, w-1, h-1), radius, fill=255)
        material.putalpha(mask)
        self.im.alpha_composite(material, (x, y))
        # Quiet rim, no high-contrast inlay competing with Ink-B silhouettes.
        d = ImageDraw.Draw(self.im)
        d.rounded_rectangle((x+2, y+2, x+w-2, y+h-2), radius, outline=(60, 49, 31), width=4)
        d.rounded_rectangle((x+7, y+6, x+w-7, y+h-7), max(8, radius-5), outline=(156, 132, 82), width=2)

    def light_pool(self, center, radius=(600, 400), strength=40):
        layer = Image.new("RGBA", self.im.size)
        x, y = center
        rx, ry = radius
        ImageDraw.Draw(layer).ellipse((x-rx, y-ry, x+rx, y+ry), fill=(255, 222, 150, strength))
        self.im = Image.alpha_composite(self.im, layer.filter(ImageFilter.GaussianBlur(100)))

    def tile(self, group, key, x, y, face=210, lift=0):
        # Face means the real CardView rectangle, excluding its projecting badges and shadow.
        # Phone 210 * 780 / 1080 = 151.7 px. Shop footprint is >= build-8's 270 px on PC.
        manifest = self.rec if group == "recruit" else self.fight
        if key not in manifest:
            # Empty combat positions expose the wood, rather than permanent slot markers.
            return
        piece, _bbox, native = self.part(group, key)
        width = piece.width * face / (native[0]-64)
        is_attacker = group == "fight" and self.fight.get("attacker_key") == key
        self.paste(group, key, x, y-lift-(16 if is_attacker else 0), width=width, shadow=12)
        self.placements[-1]["face_width"] = face
        self.placements[-1]["role"] = "shop" if key.startswith(("shop_", "spell_")) else "hand" if key.startswith("hand_") else "board"

    def lobby(self, vertical=False):
        if vertical:
            for i in range(8):
                self.paste("recruit", f"lobby_{i}", 12, 105+i*106, width=84)
        else:
            for i in range(8):
                self.paste("recruit", f"lobby_{i}", self.cx-410+i*105, 10, width=84)

    def shop_row(self, center, y=67):
        # Large art fills the merchant zone. Only badge margins overlap, never portrait faces.
        for i in range(6):
            self.tile("recruit", f"shop_{i}" if i<5 else "spell_0", center-850+i*284, y, face=270)

    def rank(self, center, y, front, group="recruit", side=1, face=210, pitch=247):
        count = 4 if front else 3
        width = 267 * face / 240
        left = center - ((count-1)*pitch+width)/2
        for i in range(count):
            slot = i if front else i+4
            key = f"board_{slot}" if group == "recruit" else f"side_{side}_slot_{slot}"
            self.tile(group, key, left+i*pitch, y, face=face)

    def hand(self, center, y, width=1540, pouch=False):
        count = len([k for k in self.rec if k.startswith("hand_")])
        if pouch:
            left = center-240
            self.surface((left-12, y-12, 494, 435), moss=False, radius=28, thickness=15)
            # Same full-size cards as the board, stacked like build 8's full hand. Upper cards
            # paint last, exposing every lower numeric foot; tap expands the selected tile.
            for i in reversed(range(count)):
                self.tile("recruit", f"hand_{i}", left+(i%2)*245, y+(i//2)*46, face=210)
        else:
            self.surface((center-width/2-12, y-10, width+24, 232), moss=False, radius=26, thickness=12)
            pitch = (width-234)/max(1, count-1)
            for i in range(count):
                self.tile("recruit", f"hand_{i}", center-width/2+i*pitch, y, face=210)

    def actions(self, x, y, width=310):
        self.paste("recruit", "gold", x+25, y, width=width-50)
        self.paste("recruit", "tier", x+32, y+108, height=30)
        self.paste("recruit", "round", x+(125 if width>=260 else 72), y+109, height=28 if width>=260 else 24)
        self.paste("recruit", "tier_up", x, y+163, width=width)
        if width>=260:
            self.paste("recruit", "refresh", x+4, y+282, width=width/2-12)
            self.paste("recruit", "freeze", x+width/2+8, y+282, width=width/2-12)
            self.paste("recruit", "end_turn", x, y+378, width=width)
        else:
            self.paste("recruit", "refresh", x+8, y+265, width=width-16)
            self.paste("recruit", "freeze", x+8, y+371, width=width-16)
            self.paste("recruit", "end_turn", x, y+482, width=width)

    def fight_controls(self, x, y):
        self.paste("fight", "pause", x, y, width=78)
        self.paste("fight", "speed", x+92, y, width=78)

    def foliage(self):
        sprite_path = ROOT / "tools/mockup/art/foreground.png"
        if not sprite_path.exists():
            return
        plants = Image.open(sprite_path).convert("RGBA")
        # Foreground is restricted to non-interactive screen corners. It overlaps the table's
        # outer edge but is kept away from every tile and button.
        plants = plants.resize((245, 245), Image.Resampling.LANCZOS)
        layer = Image.new("RGBA", self.im.size)
        layer.alpha_composite(plants, (-75, 860))
        right = ImageOps.mirror(plants)
        layer.alpha_composite(right, (round(self.w)-170, 860))
        canopy = plants.rotate(180)
        layer.alpha_composite(canopy, (-90, -120))
        layer.alpha_composite(ImageOps.mirror(canopy), (round(self.w)-155, -120))
        alpha = layer.getchannel("A")
        d = ImageDraw.Draw(alpha)
        for item in self.placements:
            x, y = item["xy"]
            l, t, r, b = item["bbox"]
            d.rectangle((x-12,y-12,x+(r-l)*item["ratio"]+12,y+(b-t)*item["ratio"]+12), fill=0)
        layer.putalpha(alpha)
        self.im = Image.alpha_composite(self.im, layer)

    def woodland(self):
        center = self.cx+32
        if self.state == "recruit":
            self.surface((center-880, 49, 1760, 1005), thickness=28)
            self.light_pool((center-100, 490), (700, 440), 28)
            self.lobby(vertical=True)
            self.shop_row(center, 62)
            self.rank(center-215, 405, True)
            self.rank(center-215, 630, False)
            self.paste("recruit", "hero", self.cx-815, 570, width=122)
            self.actions(self.cx+618, 393, width=308)
            self.hand(self.cx-110, 850, width=1400)
        else:
            center = self.cx+15
            self.surface((center-545, 43, 1090, 943), thickness=30)
            self.light_pool((center, 510), (500, 440), 28)
            self.lobby(vertical=True)
            self.rank(center, 62, False, "fight", 0)
            self.rank(center, 289, True, "fight", 0)
            self.rank(center, 524, True, "fight", 1)
            self.rank(center, 752, False, "fight", 1)
            self.paste("fight", "hero_0", center-722, 135, width=132)
            self.paste("fight", "hero_1", center-722, 750, width=132)
            self.fight_controls(center+620, 916)
        self.paste("recruit", "gear", self.w-95, 8, width=64)

    def sidecar(self):
        if self.state == "recruit":
            offset = self.cx-960
            self.surface((123+offset, 33, 1772, 1010), thickness=30)
            self.light_pool((self.cx, 530), (840, 450), 24)
            left = 145+offset
            for i in range(6):
                self.tile("recruit", f"shop_{i}" if i<5 else "spell_0", left+(i%2)*304, 42+(i//2)*336, face=270)
            center = self.cx+467
            self.rank(center, 252, True, pitch=235)
            self.rank(center, 506, False, pitch=235)
            self.paste("recruit", "hero", center-56, 109, width=84)
            self.hand(center, 808, width=930)
            self.actions(766+offset, 176, width=170)
        else:
            center = self.cx
            self.surface((center-558, 62, 1116, 940), thickness=30)
            self.light_pool((center, 530), (570, 460), 24)
            for side in range(2):
                for front in (True, False):
                    count = 4 if front else 3
                    x = center-275 if side==0 and front else center-525 if side==0 else center+20 if front else center+270
                    for i in range(count):
                        slot = i if front else i+4
                        self.tile("fight", f"side_{side}_slot_{slot}", x, 85+i*227+(0 if front else 113), face=210)
            self.paste("fight", "hero_0", center-745, 440, width=138)
            self.paste("fight", "hero_1", center+623, 440, width=138)
            self.fight_controls(center-85, 986)
        self.lobby(vertical=True)
        self.paste("recruit", "gear", self.w-95, 8, width=64)

    def stage(self):
        # Perspective is carried by the world mesh and projected contacts, while billboard
        # scaling has a floor. No distant gameplay tile is made smaller to sell the depth.
        far = 550 if self.state == "fight" else 625
        near = 700 if self.state == "fight" else 878
        corners = [(self.cx-far, 180), (self.cx+far, 180), (self.cx+near, 1015), (self.cx-near, 1015)]
        shadow = Image.new("RGBA", self.im.size)
        ImageDraw.Draw(shadow).polygon([(x+8,y+25) for x,y in corners], fill=(5,17,13,170))
        self.im = Image.alpha_composite(self.im, shadow.filter(ImageFilter.GaussianBlur(23)))
        texture = Image.open(ROOT/"tools/mockup/art/woodland-top.jpg").convert("RGBA")
        # A real projective warp: the grain converges with the mesh, as in Godot's UV mapping.
        paint = perspective_plane(texture, corners, self.im.size)
        mask = Image.new("L", self.im.size)
        ImageDraw.Draw(mask).polygon(corners, fill=255)
        paint.putalpha(mask)
        d = ImageDraw.Draw(self.im)
        d.polygon([corners[2],corners[3],(corners[3][0],1051),(corners[2][0],1051)], fill=(65,47,31), outline=INK, width=4)
        self.im = Image.alpha_composite(self.im, paint)
        d = ImageDraw.Draw(self.im)
        d.line(corners+[corners[0]], fill=(132,111,67), width=6)
        for x in [-520,-260,0,260,520]:
            d.line([(self.cx+x*.71,180),(self.cx+x,1015)], fill=(101,84,51), width=2)
        self.light_pool((self.cx,575),(630,410),30)

    def diorama(self):
        self.stage()
        self.lobby(vertical=True)
        if self.state == "recruit":
            self.surface((self.cx-845, 48, 1740, 315), moss=False, thickness=38)
            self.shop_row(self.cx+12, 59)
            center = self.cx-115
            self.rank(center, 405, True, face=210, pitch=251)
            self.rank(center+5, 630, False, face=210, pitch=276)
            self.paste("recruit", "hero", self.cx-815, 570, width=128)
            self.actions(self.cx+634, 391, width=292)
            self.hand(self.cx-130, 850, width=1400)
        else:
            self.rank(self.cx, 61, False, "fight", 0, face=210, pitch=247)
            self.rank(self.cx, 287, True, "fight", 0, face=210, pitch=247)
            self.rank(self.cx, 518, True, "fight", 1, face=215, pitch=258)
            self.rank(self.cx, 754, False, "fight", 1, face=220, pitch=267)
            self.paste("fight", "hero_0", self.cx-735, 215, width=130)
            self.paste("fight", "hero_1", self.cx-810, 788, width=145)
            self.fight_controls(self.cx+660, 945)
        self.paste("recruit", "gear", self.w-95, 8, width=64)

    def bottom_bar(self):
        self.surface((132, 967, self.w-160, 94), moss=False, radius=26, thickness=10)
        hero_center = self.cx+24
        self.paste("recruit", "hero", hero_center-57, 872, width=114)
        self.paste("recruit", "gold", 180, 981, width=190)
        self.paste("recruit", "tier_up", 411, 985, width=215)
        self.paste("recruit", "refresh", 654, 983, width=130)
        self.paste("recruit", "freeze", 790, 983, width=120)
        self.paste("recruit", "end_turn", self.w-360, 970, width=300)
        self.paste("recruit", "tier", hero_center+135, 997, height=30)
        self.paste("recruit", "round", hero_center+214, 997, height=28)

    def bazaar(self):
        center = self.cx-100
        self.lobby(vertical=True)
        if self.state == "recruit":
            # One coherent counter: raised merchant lip, central formation and slim hero bar.
            self.surface((self.cx-837, 45, 1772, 900), thickness=30)
            self.surface((self.cx-821, 48, 1738, 315), moss=False, thickness=25)
            self.light_pool((center,520),(720,410),26)
            self.shop_row(self.cx+24, 59)
            self.rank(center-5, 405, True, pitch=240)
            self.rank(center-5, 635, False, pitch=240)
            self.hand(self.cx+690, 424, pouch=True)
            self.bottom_bar()
        else:
            center = self.cx+12
            self.surface((center-540, 44, 1080, 912), thickness=28)
            self.light_pool((center,500),(500,410),28)
            self.rank(center, 60, False, "fight", 0)
            self.rank(center, 282, True, "fight", 0)
            self.rank(center, 508, True, "fight", 1)
            self.rank(center, 730, False, "fight", 1)
            self.surface((132, 974, self.w-160, 86), moss=False, radius=24, thickness=10)
            self.paste("fight", "hero_0", center-715, 128, width=132)
            self.paste("fight", "hero_1", center-44, 980, width=80)
            self.fight_controls(self.w-278, 980)
        self.paste("recruit", "gear", self.w-95, 8, width=64)

    def save(self):
        getattr(self, {"woodland-table": "woodland", "sidecar-market": "sidecar", "rootbridge-diorama": "diorama", "bazaar-stack": "bazaar"}[self.option])()
        self.foliage()
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
        (dest / f"{stem}.json").write_text(json.dumps({"logical_size": self.logical_size, "placements": self.placements, "revision": "large-tiles-woodland"}, indent=2))
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
        critique = re.search(r"\*\*Tradeoffs:\*\* (.+)", option_notes)
        critic_text = f'<p><strong>Tradeoffs:</strong> {html.escape(critique.group(1))}</p>' if critique else ""
        sections.append(f'<section><h2>{name}</h2><p>{html.escape(idea)}</p>{critic_text}<div class="grid">{images}</div></section>')
    (out / "index.html").write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bramble · Layout options</title><style>body{margin:0;background:#14221d;color:#f0e7ce;font:18px/1.5 system-ui}main{max-width:1500px;margin:auto;padding:24px}h1,h2{line-height:1.1}h2{font-size:36px}section{margin:55px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}a{color:#d9ca94}figure{margin:0}img{width:100%;display:block}figcaption{padding:8px 0;color:#c7c9b3}p{max-width:70ch}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><main>
<h1>Bramble · Layout options</h1><p>Static layout concepts using real Godot tiles, portraits and controls. Painted worlds are concepts. Tap a still to open it at native size. No motion-dependent depth.</p>
<p><a href="sheet.jpg">Open the Bazaar comparison sheet</a> · <a href="notes.md">Option details and tradeoffs</a></p>'''
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
                    if native.exists() and native.stat().st_mtime >= target.with_suffix(".json").stat().st_mtime:
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
        "method": "Real Godot widgets; generated woodland material and foliage; projective plane, shadows and a native tile-size floor",
        "motion": "None: all depth is visible in stills", "combat_event_index": json.loads((args.assets / "fight/parts.json").read_text())["event_index"]}, indent=2))
    print(f"Wrote {len(manifest)} native-size stills, comparison sheet and gallery to {args.out}")


if __name__ == "__main__":
    main()
