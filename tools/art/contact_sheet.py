#!/usr/bin/env python3
"""Compare a portrait folder with current art at exactly 150px, grouped by tribe.

python tools/art/contact_sheet.py assets/portraits_inkglow \
  --fallbacks assets/ui/portraits_inkglow --out build/inkglow-contact.png

Only reads content metadata. Writes one PNG plus a JSON index of image positions.
Requires Pillow. Unknown identities and missing originals fail instead of being skipped.
"""
import argparse
import json
from pathlib import Path
import textwrap

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
TRIBES = ["Fairies", "Oozes", "Hedgerow folk", "Hunters", "Bog folk", "Birds", "Neutral"]
FALLBACKS = {"fairies": "Fairies", "oozes": "Oozes", "hedgerow": "Hedgerow folk",
             "hunters": "Hunters", "bog": "Bog folk", "birds": "Birds", "neutral": "Neutral"}
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ART = 150
PAIR = 334
ROW = 208
GAP = 16


def font(size):
    for path in [ROOT / "assets/fonts/AlegreyaSans-Regular.ttf",
                 Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def catalog(content):
    result = {}
    for folder, default_kind in [("units", "unit"), ("heroes", "hero"), ("spells", "spell")]:
        for path in sorted((content / folder).glob("*.json")):
            data = json.loads(path.read_text())
            if not isinstance(data, dict) or "id" not in data:
                continue
            identity = data["id"]
            if identity in result:
                raise ValueError(f"ambiguous content identity: {identity}")
            result[identity] = {"name": data.get("name", identity),
                                "kind": data.get("kind", default_kind),
                                "tribes": data.get("tribes", [])}
    return result


def pictures(folder):
    if not folder.is_dir():
        raise ValueError(f"not a portrait folder: {folder}")
    return sorted(p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in EXTENSIONS)


def original_for(folder, identity):
    matches = [p for p in pictures(folder) if p.stem == identity]
    if len(matches) != 1:
        raise ValueError(f"expected one current portrait for {identity} in {folder}; got {len(matches)}")
    return matches[0]


def thumbnail(path):
    with Image.open(path) as source:
        # Fit without stretching; composite any alpha onto the sheet's neutral paper.
        rgba = ImageOps.fit(source.convert("RGBA"), (ART, ART), Image.Resampling.LANCZOS)
        base = Image.new("RGBA", rgba.size, "#e8e0ce")
        return Image.alpha_composite(base, rgba).convert("RGB")


def make_sheet(args):
    metadata = catalog(args.content)
    entries = []
    seen = set()
    sources = [(args.folder, False)]
    if args.fallbacks:
        sources.append((args.fallbacks, True))
    for folder, fallback in sources:
        for path in pictures(folder):
            identity = path.stem
            key = (fallback, identity)
            if key in seen:
                raise ValueError(f"duplicate portrait: {identity}")
            seen.add(key)
            if fallback:
                if identity not in FALLBACKS:
                    raise ValueError(f"unknown tribe fallback: {identity}")
                tribe = FALLBACKS[identity]
                entry = {"name": tribe + " fallback", "kind": "fallback", "tribes": [tribe]}
                current = original_for(args.current_fallbacks, identity)
            else:
                if identity not in metadata:
                    raise ValueError(f"no content metadata for portrait: {identity}")
                entry = metadata[identity].copy()
                tribe = (entry["tribes"] or ["Neutral"])[0]
                tribe = "Fairies" if tribe == "Hive" else tribe
                current = original_for(args.current, identity)
            if tribe not in TRIBES:
                raise ValueError(f"unknown tribe {tribe} for {identity}")
            entries.append(dict(entry, id=identity, tribe=tribe, current=str(current), repaint=str(path)))
    if not entries:
        raise ValueError("no portrait images found")
    entries.sort(key=lambda e: (TRIBES.index(e["tribe"]), e["kind"], e["name"].casefold(), e["id"]))
    groups = [(tribe, [e for e in entries if e["tribe"] == tribe]) for tribe in TRIBES]
    groups = [(tribe, group) for tribe, group in groups if group]
    height = 82 + sum(34 + ((len(group) + args.columns - 1) // args.columns) * ROW for _, group in groups)
    width = GAP + args.columns * (PAIR + GAP)
    sheet = Image.new("RGB", (width, height), "#e8e0ce")
    draw = ImageDraw.Draw(sheet)
    draw.text((GAP, 10), f"Bramble portrait review — {len(entries)} images", font=font(25), fill="#302d28")
    draw.text((GAP, 43), "Current left / repaint right • each portrait 150px • first listed tribe; untribed assets under Neutral", font=font(17), fill="#514d43")
    y = 82
    for tribe, group in groups:
        draw.rectangle((0, y, width, y + 27), fill="#cbbfa6")
        draw.text((GAP, y + 2), f"{tribe} ({len(group)})", font=font(21), fill="#302d28")
        y += 34
        for index, entry in enumerate(group):
            x = GAP + index % args.columns * (PAIR + GAP)
            top = y + index // args.columns * ROW
            for position, key in [(x, "current"), (x + 166, "repaint")]:
                sheet.paste(thumbnail(entry[key]), (position, top))
            label = f"{entry['name']} · {entry['kind']}"
            for line, text in enumerate(textwrap.wrap(label, width=46)[:2]):
                draw.text((x, top + 153 + line * 17), text, font=font(16), fill="#302d28")
            draw.text((x, top + 188), entry["id"], font=font(12), fill="#645b4e")
            entry["current_rect"] = [x, top, ART, ART]
            entry["repaint_rect"] = [x + 166, top, ART, ART]
        y += ((len(group) + args.columns - 1) // args.columns) * ROW
    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.out)
    args.out.with_suffix(".json").write_text(json.dumps({"portrait_width": ART, "size": sheet.size,
                                                        "count": len(entries), "entries": entries}, indent=2) + "\n")
    print(f"Saved {args.out}: {len(entries)} pairs at {ART}px; {width}x{height}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--fallbacks", type=Path, help="optional repainted tribe fallback folder")
    parser.add_argument("--current", type=Path, default=ROOT / "assets/portraits")
    parser.add_argument("--current-fallbacks", type=Path, default=ROOT / "assets/ui/portraits")
    parser.add_argument("--content", type=Path, default=ROOT / "content")
    parser.add_argument("--columns", type=int, default=4, help="portrait pairs per row (default 4)")
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    if args.columns < 1:
        parser.error("--columns must be positive")
    try:
        make_sheet(args)
    except (ValueError, OSError, json.JSONDecodeError) as error:
        parser.exit(1, f"contact sheet: {error}\n")


if __name__ == "__main__":
    main()
