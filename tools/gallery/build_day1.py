#!/usr/bin/env python3
"""Build the private owner gallery. Only Python's standard library and Pillow are needed."""

import argparse
import html
import json
import math
import re
import shutil
import sys
from pathlib import Path
from urllib.parse import quote, urlsplit

from PIL import Image, ImageDraw, ImageFont, ImageOps


CSS = """
:root { color-scheme: light; background: #f5f0e5; color: #302d25;
  font: 18px/1.65 system-ui, sans-serif; }
* { box-sizing: border-box; }
body { margin: 0; }
main { max-width: 1280px; margin: auto; padding: 36px 28px 80px; }
h1,h2,h3 { line-height: 1.2; text-wrap: balance; }
h1 { font-size: clamp(2rem,5vw,3.5rem); max-width: 24ch; margin: 0 0 2rem; }
h2 { font-size: clamp(1.55rem,3vw,2.15rem); margin: 3.5rem 0 1.2rem;
  padding-top: 1.3rem; border-top: 1px solid #d4cbb9; }
h3 { margin: 1.8rem 0 1rem; font-size: 1.3rem; }
p { max-width: 76ch; margin: 1rem 0; }
li { margin: .9rem 0; }
ol,ul { padding-left: 1.5rem; }
a { color: #38563b; text-underline-offset: .18em; overflow-wrap: anywhere; }
a:focus-visible,summary:focus-visible { outline: 3px solid #876127; outline-offset: 4px; }
figure { margin: 1.4rem 0; min-width: 0; }
figure a { display: block; }
img { display: block; width: 100%; height: auto; background: #e5ddcd; border-radius: 4px; }
figcaption { font-size: .83rem; line-height: 1.4; margin-top: .45rem; color: #5c574c; }
.pair,.grid { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap: 20px; }
.pair figure { margin: .5rem 0; }
.links { display: flex; flex-wrap: wrap; gap: .4rem 1rem; margin: 1rem 0; }
.links a { padding: .3rem 0; }
.option { margin: 2rem 0 3rem; }
details { border-top: 1px solid #d4cbb9; margin: 1.5rem 0; padding: .8rem 0; }
summary { cursor: pointer; padding: .4rem 0; font-weight: 650; }
.detail { font-size: .9rem; }
.detail .grid { grid-template-columns: repeat(3,minmax(0,1fr)); }
.table { overflow-x: auto; max-width: 100%; }
table { border-collapse: collapse; font-size: .85rem; }
th,td { text-align: left; padding: .6rem; border-bottom: 1px solid #d4cbb9; vertical-align: top; }
code { overflow-wrap: anywhere; }
@media(max-width: 700px) {
  main { padding: 24px 18px 60px; }
  .pair,.grid,.detail .grid { grid-template-columns: minmax(0,1fr); gap: 10px; }
  h2 { margin-top: 2.5rem; }
}
"""
MEDIA = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
GAMES = {"bazaar": "The Bazaar", "ori": "Ori", "battlegrounds": "Battlegrounds",
         "tft": "TFT", "everdell": "Everdell"}


def slug(value):
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def link(target, label):
    return f'<a href="{html.escape(quote(str(target), safe="/#"), quote=True)}">{html.escape(label)}</a>'


def inline(value):
    """Small, escaped Markdown subset; external/absolute links become plain labels."""
    tokens = re.compile(r"\[([^\]]+)\]\(([^)]+)\)|\*\*(.+?)\*\*|\*([^*]+)\*|`([^`]+)`")
    result, start = [], 0
    for match in tokens.finditer(value):
        result.append(html.escape(value[start:match.start()]))
        label, target, bold, emphasis, code = match.groups()
        if target is not None:
            url = urlsplit(target)
            result.append(link(target, label) if not (url.scheme or url.netloc or target.startswith("/"))
                          else html.escape(label))
        elif bold is not None:
            result.append(f"<strong>{inline(bold)}</strong>")
        elif emphasis is not None:
            result.append(f"<em>{inline(emphasis)}</em>")
        else:
            result.append(f"<code>{html.escape(code)}</code>")
        start = match.end()
    result.append(html.escape(value[start:]))
    return "".join(result)


def markdown(source):
    """Render headings, paragraphs, lists and the evidence indexes' simple tables."""
    source = re.sub(r"<!--.*?-->", "", source, flags=re.S)
    result, paragraph, rows = [], [], []
    list_kind = None

    def flush():
        if paragraph:
            result.append("<p>" + inline(" ".join(paragraph)) + "</p>")
            paragraph.clear()
        if rows:
            cells = []
            for i, row in enumerate(rows):
                if re.fullmatch(r"[\s|:\-]+", row):
                    continue
                tag = "th" if i == 0 else "td"
                cells.append("<tr>" + "".join(f"<{tag}>{inline(c.strip())}</{tag}>"
                                            for c in row.strip("|").split("|")) + "</tr>")
            result.append('<div class="table"><table>' + "".join(cells) + "</table></div>")
            rows.clear()

    for line in source.splitlines() + [""]:
        line = line.strip()
        heading = re.match(r"^(#{1,6}) (.+)$", line)
        item = re.match(r"^(?:([-*]) |\d+\. )(.+)$", line)
        if not item and list_kind and line:
            result.append(f"</{list_kind}>")
            list_kind = None
        if heading:
            flush()
            level, title = len(heading[1]), heading[2]
            result.append(f'<h{level} id="{slug(title)}">{inline(title)}</h{level}>')
        elif item:
            flush()
            kind = "ul" if item[1] else "ol"
            if list_kind != kind:
                if list_kind:
                    result.append(f"</{list_kind}>")
                result.append(f"<{kind}>")
                list_kind = kind
            result.append(f"<li>{inline(item[2])}</li>")
        elif line.startswith("|"):
            if paragraph:
                flush()
            rows.append(line)
        elif not line:
            flush()
        else:
            paragraph.append(line)
    if list_kind:
        result.append(f"</{list_kind}>")
    return "\n".join(result)


def document(title, body):
    return ('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{html.escape(title)}</title><style>{CSS}</style></head>'
            f'<body><main>{body}</main></body></html>\n')


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == content:
        return
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(content, encoding="utf-8")
    temporary.replace(path)


class Gallery:
    def __init__(self, root, references):
        self.root, self.references = root, references
        self.missing = set()
        manifest = root / "layouts/manifest.json"
        self.manifest = json.loads(manifest.read_text()) if manifest.exists() else {}
        self.notes = self.read("layouts/notes.md")
        self.critic = self.read("layouts/critic.md")
        # Directory discovery also picks up options arriving before a manifest update.
        folders = root / "layouts"
        available = {p.name for p in folders.iterdir()
                     if p.is_dir() and any(p.glob("recruit_*.jpg"))} if folders.exists() else set()
        self.options = [slug(name) for name in re.findall(r"^## (.+)$", self.notes, re.M)
                        if slug(name) in available]
        self.options += sorted(available.difference(self.options))
        self.busy = self.reference_frame("busy", "main-play-busy--*.jpg")
        self.fight = self.reference_frame("fight", "fight--*.jpg")

    def read(self, relative):
        path = self.root / relative
        return path.read_text(encoding="utf-8") if path.exists() else ""

    def reference_frame(self, key, pattern):
        source = self.manifest.get("sources", {}).get(key, {}).get("file", "")
        name = Path(source).name if source else ""
        folder = self.references / "bazaar"
        candidates = sorted(folder.glob(pattern))
        # Prefer the exact, reviewed Steam captures used by the breakdown and layouts.
        if not name:
            name = next((p.name for p in candidates if "steam-trailer" in p.name),
                        candidates[0].name if candidates else "missing.jpg")
        return Path("ref/bazaar") / name

    def figure(self, relative, caption):
        path = self.root / relative
        if not path.is_file():
            self.missing.add(str(relative))
            return ""
        with Image.open(path) as image:
            width, height = image.size
        url = html.escape(quote(str(relative)), quote=True)
        return (f'<figure><a href="{url}"><img src="{url}" alt="{html.escape(caption, quote=True)}" '
                f'width="{width}" height="{height}" loading="lazy" decoding="async"></a>'
                f'<figcaption>{html.escape(caption)}</figcaption></figure>')

    def pair(self, left, right, first, second="The Bazaar"):
        return '<div class="pair">' + self.figure(left, first) + self.figure(right, second) + '</div>'

    def copy_references(self):
        for game in GAMES:
            source = self.references / game
            if not (source / "sheet.jpg").exists():
                self.missing.add(f"reference sheet: {game}")
                continue
            destination = self.root / "ref" / game
            destination.mkdir(parents=True, exist_ok=True)
            for path in sorted(source.iterdir()):
                if path.is_file() and (path.suffix.lower() in MEDIA or path.name == "index.md"):
                    target = destination / path.name
                    if not target.exists() or target.read_bytes() != path.read_bytes():
                        shutil.copy2(path, target)
            body = link("../../index.html#detail", "Detail")
            if (source / "index.md").exists():
                body += markdown((source / "index.md").read_text())
            for path in sorted(destination.iterdir()):
                if path.suffix.lower() in MEDIA:
                    # Figure paths here are relative to this index, not the main page.
                    figure = self.figure(path.relative_to(self.root), path.stem.replace("--", " · "))
                    body += figure.replace(f"ref/{game}/", "")
            write(destination / "index.html", document(GAMES[game], body))

    @staticmethod
    def section(source, name):
        for match in re.finditer(r"^#{1,4}\s+(.+?)\s*\n(.*?)(?=^#{1,4}\s|\Z)", source, re.M | re.S):
            if slug(match[1]) == slug(name):
                return match[2].strip()
        return ""

    def option_name(self, option):
        for match in re.finditer(r"^## (.+)$", self.notes, re.M):
            if slug(match[1]) == option:
                return match[1]
        return option.replace("-", " ").title()

    def layouts(self):
        result = []
        for option in self.options:
            name = self.option_name(option)
            result.append(f'<article class="option"><h3>{html.escape(name)}</h3>')
            notes = self.section(self.notes, name)
            for field in ("Idea", "Depth", "Cost"):
                match = re.search(r"\*\*" + field + r":\*\*\s*(.*?)(?=\s*\*\*|\n\n|\Z)", notes, re.S)
                if match:
                    result.append(markdown(f"**{field}:** {match[1].strip()}"))
                else:
                    self.missing.add(f"{name}: {field} notes")
            result.append(self.pair(f"layouts/{option}/recruit_1920x1080.jpg", self.busy,
                                    f"{name} · recruit · PC"))
            result.append(self.pair(f"layouts/{option}/fight_1920x1080.jpg", self.fight,
                                    f"{name} · fight · PC"))
            critic = self.section(self.critic, name)
            if critic:
                result.append(markdown(critic))
            else:
                match = re.search(r"\*\*Fresh critic:\*\*\s*(.*?)(?=\n\n|\Z)", notes, re.S)
                if match:
                    result.append(markdown("**Fresh critic:** " + match[1]))
                self.missing.add(f"layouts/critic.md: {name}")
            result.append("</article>")
        if not self.options:
            self.missing.add("layout options")
        return "\n".join(result)

    def library(self, folder, title):
        paths = sorted((self.root / folder).rglob("*"))
        images = [p for p in paths if p.is_file() and p.suffix.lower() in MEDIA]
        return (f'<details><summary>{html.escape(title)}</summary><div class="grid">' +
                "".join(self.figure(p.relative_to(self.root), p.relative_to(self.root / folder).as_posix())
                        for p in images) + '</div></details>')

    def detail(self):
        body = '<div class="detail"><p>' + link("breakdown/bazaar.html", "The Bazaar breakdown") + '</p>'
        body += '<div class="grid">'
        for game, name in GAMES.items():
            if (self.root / "ref" / game / "sheet.jpg").exists():
                body += '<div>' + self.figure(f"ref/{game}/sheet.jpg", name)
                body += link(f"ref/{game}/index.html", f"{name} · every frame and index") + '</div>'
        body += '</div>'
        body += self.library("ours", "Bramble · every screen · PC and phone")
        body += self.library("layouts", "Layouts · every still · PC and phone")
        body += self.library("clips", "Clips · recruit and fight")
        body += self.library("backdrops", "Backdrops · PC and phone")
        body += self.library("breakdown", "The Bazaar · comparisons and zone maps")
        body += '<p>' + link("options-contact.jpg", "Layout options · contact sheet") + '</p></div>'
        return body

    def marker(self, marker):
        ours = "ours/recruit_1920x1080.jpg"
        if marker.startswith("picture: our recruit screen at PC"):
            return self.pair(ours, self.busy, "Bramble · recruit · PC")
        if marker.startswith("picture: our fight at PC"):
            return self.pair("ours/combat_mid_1920x1080.jpg", self.fight, "Bramble · fight · PC")
        if marker.startswith("link row:"):
            return ('<div class="links">' + link("#bramble-pc", "Every PC screen") +
                    link("#bramble-phone", "Every phone screen") + '</div>')
        pictures = {
            "picture: our recruit screen": (ours, "Bramble · recruit · PC"),
            "picture: our recruit, phone size": ("ours/recruit_1688x780.jpg", "Bramble · recruit · phone"),
            "picture: recruit with a card selected, phone size":
                ("ours/recruit_select_1688x780.jpg", "Bramble · card selected · phone"),
            "picture: our fight, PC size": ("ours/combat_mid_1920x1080.jpg", "Bramble · fight · PC"),
            "picture: the backdrop contact sheet": ("backdrops/sheet.jpg", "Painted backdrops"),
            "clip: one recruit turn": ("clips/recruit-phone.gif", "Recruit turn · phone"),
            "clip: one fight": ("clips/fight-phone.gif", "Fight · phone"),
        }
        if marker in pictures:
            return self.figure(*pictures[marker])
        if marker == "picture: our recruit beside the Bazaar zone map":
            return self.pair(ours, "breakdown/bazaar-zones-main-play-busy.jpg",
                             "Bramble · recruit · PC", "The Bazaar · busy play · zone map")
        if marker.startswith("the layout options:"):
            return self.layouts()
        if marker.startswith("links:"):
            return self.detail()
        raise ValueError(f"Unknown picture marker: {marker}")

    def page(self):
        text = re.sub(r"<!--.*?-->", "", self.read("text.md"), flags=re.S)
        # Markers inside numbered items must keep their figure inside that list item.
        placeholders = []
        def replace(match):
            placeholders.append(self.marker(match[1]))
            return f"GALLERYMEDIA{len(placeholders) - 1}END"
        text = re.sub(r"\*\[([^\]]+)\]\*", replace, text)
        text = re.sub(r"(?m)^(GALLERYMEDIA\d+END)$", r"\n\1\n", text)
        body = markdown(text)
        for i, picture in enumerate(placeholders):
            token = f"GALLERYMEDIA{i}END"
            body = body.replace(f"<p>{token}</p>", picture).replace(token, picture)
        # The link row opens the same full library at the relevant size.
        for size, suffix in (("pc", "1920x1080"), ("phone", "1688x780")):
            figures = "".join(self.figure(p.relative_to(self.root), p.stem)
                              for p in sorted((self.root / "ours").glob(f"*_{suffix}.jpg")))
            anchor = f'<details id="bramble-{size}"><summary>Bramble · {size.upper() if size == "pc" else size} screens</summary><div class="grid">{figures}</div></details>'
            body = body.replace('<div class="detail">', '<div class="detail">' + anchor, 1)
        return document("Bramble, look and feel: day 1", body)

    def contact(self):
        tiles = [(self.root / f"layouts/{option}/recruit_1920x1080.jpg", self.option_name(option))
                 for option in self.options]
        tiles.append((self.root / self.busy, "The Bazaar"))
        tiles = [(path, name) for path, name in tiles if path.exists()]
        if not tiles:
            raise ValueError("No layout or Bazaar images for contact sheet")
        width, padding, gap = 1600, 28, 24
        tile_width = (width - padding * 2 - gap) // 2
        image_height, label_height = round(tile_width * 9 / 16), 110
        row_height = image_height + label_height + gap
        sheet = Image.new("RGB", (width, padding * 2 + math.ceil(len(tiles) / 2) * row_height - gap), "#f5f0e5")
        draw = ImageDraw.Draw(sheet)
        try:
            font = ImageFont.truetype("DejaVuSans-Bold.ttf", 46)
        except OSError:
            font = ImageFont.load_default(size=46)
        for i, (path, name) in enumerate(tiles):
            x, y = padding + i % 2 * (tile_width + gap), padding + i // 2 * row_height
            # Wrap rather than shrink option labels, so names remain legible in chat.
            words, lines = name.split(), [""]
            for word in words:
                candidate = (lines[-1] + " " + word).strip()
                if draw.textlength(candidate, font=font) > tile_width and lines[-1]:
                    lines.append(word)
                else:
                    lines[-1] = candidate
            draw.multiline_text((x, y), "\n".join(lines), font=font, fill="#302d25", spacing=2)
            with Image.open(path) as source:
                image = ImageOps.contain(source.convert("RGB"), (tile_width, image_height), Image.Resampling.LANCZOS)
            sheet.paste(image, (x + (tile_width - image.width) // 2, y + label_height))
        temporary = self.root / "options-contact.jpg.tmp"
        sheet.save(temporary, format="JPEG", quality=90, optimize=True)
        temporary.replace(self.root / "options-contact.jpg")

    def build(self):
        if not (self.root / "text.md").is_file():
            raise ValueError(f"Missing page text: {self.root / 'text.md'}")
        self.copy_references()
        breakdown = self.read("breakdown/bazaar.md")
        if breakdown:
            write(self.root / "breakdown/bazaar.html", document("The Bazaar breakdown",
                  link("../index.html#detail", "Detail") + markdown(breakdown)))
        self.contact()
        page = self.page()
        if len(page.encode("utf-8")) >= 1_000_000:
            raise ValueError("HTML and CSS exceed 1 MB")
        write(self.root / "index.html", page)
        print(f"Built {self.root / 'index.html'} ({len(page.encode('utf-8')):,} bytes); {len(self.options)} options")
        print(f"Built {self.root / 'options-contact.jpg'}")
        for missing in sorted(self.missing):
            print(f"Not available yet: {missing}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("/data/bramble-gallery/loop1"))
    parser.add_argument("--references", type=Path, default=Path("/data/bramble-reference"))
    args = parser.parse_args()
    Gallery(args.root.resolve(), args.references.resolve()).build()


if __name__ == "__main__":
    main()
