#!/usr/bin/env python3
"""Pulls the glass mock-ups' own pieces into the Godot project, from one commit of the mock-ups branch.

    python3 tools/glass/pull_mockups.py                      # origin/design/glass-mockups as fetched now
    python3 tools/glass/pull_mockups.py --ref 8279442b       # any commit or branch name
    python3 tools/glass/pull_mockups.py --check              # only says whether assets/glass matches the ref

Run `git fetch origin` first to get the mock-ups' latest commit. Writes into assets/glass/:

- frames/tier1..6.webp   the six tier frames, as the mock-ups use them (560 x 1000)
- art/<name>.jpg         the card art cards.html shows (the art recipe's test set, not decided units)
- fonts/                 Alegreya and Alegreya Sans, the fonts the pages load from Google Fonts,
                         fetched from a pinned commit of github.com/google/fonts (OFL)
- card_data.json         assets/card-data.js as JSON: each tier's Attack and Health discs, the art polygon
- layout.json            every layout number, colour and font the Godot side reads, each with the file,
                         line and source text it came from
- source.json            the commit pulled and the SHA-256 of every file written

The frames and art import with mipmaps on, so they stay smooth when drawn small: a file new to
assets/glass needs `mipmaps/generate=true` in its .import file after Godot first imports it.
The mock-ups still show a hand of 10; the rule is 7 (rulebook 7.1.1), so the hand count is not pulled.

The stage.* values are a partial pull for the screens step (plan step 5): nothing reads them yet, and
that step reads, checks and completes them. Everything else in layout.json is read by src/glass.

Each layout number is read out of the mock-up's CSS or JS by a pattern below. When a pattern no longer
matches the source, the script stops and names it, so a changed mock-up never leaves a stale number.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "glass"
DEFAULT_REF = "origin/design/glass-mockups"
MOCKUPS = "docs/design/art-direction/mockups"

# The pages ask Google Fonts for Alegreya 700-900 and Alegreya Sans 400 and 700. The same families,
# from the google/fonts repository at a fixed commit, so a re-run gets the same bytes.
FONTS_COMMIT = "88c2351fb58bf5dfedb96934de48be9a606c7d2e"
FONTS = {
    "Alegreya[wght].ttf": "ofl/alegreya/Alegreya%5Bwght%5D.ttf",
    "AlegreyaSans-Regular.ttf": "ofl/alegreyasans/AlegreyaSans-Regular.ttf",
    "AlegreyaSans-Bold.ttf": "ofl/alegreyasans/AlegreyaSans-Bold.ttf",
    "Alegreya-OFL.txt": "ofl/alegreya/OFL.txt",
    "AlegreyaSans-OFL.txt": "ofl/alegreyasans/OFL.txt",
}
# The metrics recorded in layout.json for each font family the pages use.
FONT_FILES = {"display": "Alegreya[wght].ttf", "body": "AlegreyaSans-Regular.ttf"}

NUM = r"-?[\d.]+"
HEX = r"#[0-9a-fA-F]{3,8}"

# key prefix, mock-up file, pattern. Each named group becomes "<prefix>.<group>" in layout.json.
# Groups named *_json hold a JS array literal; *_hex, *_rgba, *_text and *_font stay strings; the rest are numbers.
PATTERNS: list[tuple[str, str, str]] = [
    # the card template (card.js, card.css)
    ("card.units", "card.js", rf"const U = \{{ w: (?P<w>{NUM}), h: (?P<h>{NUM}) \}}"),
    ("card.num", "card.js", rf"s\.length > 1 \? (?P<two_digit_scale>{NUM}) : (?P<one_digit_scale>{NUM})"),
    (
        "card.shadow",
        "card.css",
        rf"\.card\{{position:absolute;filter:drop-shadow\((?P<x>{NUM})p?x? (?P<y>{NUM})px (?P<blur>{NUM})px "
        r"rgba\((?P<colour_rgba>[^)]*)\)\)",
    ),
    (
        "card.num",
        "card.css",
        r"\.card \.num\{[^}]*?font-family:[^;]+;font-weight:(?P<weight>\d+);"
        rf"line-height:{NUM};color:(?P<colour_hex>{HEX});letter-spacing:(?P<letter_spacing_em>{NUM})em;",
    ),
    (
        "card.num",
        "card.css",
        rf"\.card \.num\{{[^}}]*?padding-top:(?P<padding_top_em>{NUM})em;"
        rf"text-shadow:0 0 (?P<glow_em>{NUM})em rgba\((?P<glow_rgba>[^)]*)\)",
    ),
    # the card sheet (cards.html): what the proof scene shows
    ("sheet", "cards.html", r"const ART = (?P<art_json>\[[^\]]*\]);"),
    ("sheet", "cards.html", r"const NUMS = (?P<numbers_json>\[\[.*?\]\]);"),
    ("sheet", "cards.html", r"const SIZES = (?P<sizes_json>\[\[.*?\]\]);"),
    ("sheet", "cards.html", rf"--page:(?P<page_hex>{HEX});--text:(?P<text_hex>{HEX});--muted:(?P<muted_hex>{HEX})\}}"),
    ("sheet", "cards.html", rf"body\{{padding:(?P<padding>{NUM})px\}}"),
    (
        "sheet.h1",
        "cards.html",
        rf"h1\{{font:(?P<weight>\d+) (?P<size>{NUM})px [^;]*;margin:0 0 (?P<margin_bottom>{NUM})px\}}",
    ),
    ("sheet.h1", "cards.html", r"<h1>(?P<label_text>[^<]*)</h1>"),
    (
        "sheet.p",
        "cards.html",
        rf"p\{{margin:0 0 (?P<margin_bottom>{NUM})px;color:var\(--muted\);font-size:(?P<size>{NUM})px\}}",
    ),
    ("sheet.p", "cards.html", r"<p>(?P<label_text>[^<]*)</p>"),
    (
        "sheet.h2",
        "cards.html",
        rf"h2\{{font:(?P<weight>\d+) (?P<size>{NUM})px [^;]*;"
        rf"margin:(?P<margin_top>{NUM})px 0 (?P<margin_bottom>{NUM})px\}}",
    ),
    (
        "sheet.row",
        "cards.html",
        rf"\.row\{{[^}}]*?gap:(?P<gap>{NUM})px;background:(?P<colour_hex>{HEX});padding:(?P<padding>{NUM})px;"
        rf"border-radius:(?P<radius>{NUM})px",
    ),
    # PARTIAL, for the screens step: nothing reads stage.* yet; that step reads and completes it.
    # the screens' shared look (stage.css)
    (
        "stage.colour",
        "stage.css",
        rf":root\{{--lead:(?P<lead_hex>{HEX});--ink:(?P<ink_hex>{HEX});--bone:(?P<bone_hex>{HEX});--go:(?P<go_hex>{HEX});",
    ),
    ("stage.font", "stage.css", r"--display:(?P<display_font>[^;]+);--body:(?P<body_font>[^;]+);"),
    (
        "stage",
        "stage.css",
        rf"#stage\{{position:absolute;left:0;top:0;width:(?P<width>{NUM})px;height:(?P<height>{NUM})px",
    ),
    ("stage.slot", "stage.css", r"\.slot\{[^}]*?clip-path:polygon\((?P<clip_text>[^)]*)\)"),
    ("stage.slot", "stage.css", rf"\.slot::after\{{content:\"\";position:absolute;inset:(?P<inset>{NUM})px"),
    (
        "stage.button",
        "stage.css",
        rf"\.btn\{{[^}}]*?height:(?P<height>{NUM})px;border:(?P<border>{NUM})px solid var\(--lead\);"
        rf"border-radius:(?P<radius>{NUM})px;\s*font:(?P<weight>\d+) (?P<size>{NUM})px var\(--display\)",
    ),
    (
        "stage.label",
        "stage.css",
        rf"\.lbl\{{[^}}]*?font:(?P<weight>\d+) (?P<size>{NUM})px var\(--display\);[^}}]*?"
        rf"-webkit-text-stroke:(?P<stroke>{NUM})px",
    ),
    # the recruit screen's geometry (recruit.html geom()): every size follows the card height H
    ("stage.recruit", "recruit.html", rf'const H = S\.size === "b" \? (?P<card_h>{NUM}) : (?P<card_h_small>{NUM})'),
    (
        "stage.recruit",
        "recruit.html",
        rf"const W = H \* (?P<card_w_per_h>{NUM}), g = (?P<gap>{NUM}), sg = (?P<spell_gap>{NUM});",
    ),
    ("stage.recruit", "recruit.html", rf"const roof = (?P<roof_per_h>{NUM}) \* H"),
    ("stage.recruit", "recruit.html", rf"let handShow = (?P<hand_show_per_h>{NUM}) \* H;"),
    ("stage.recruit", "recruit.html", rf"const handTop = 1080 - handShow, sill = handTop - (?P<sill_gap>{NUM});"),
    (
        "stage.recruit",
        "recruit.html",
        rf"const boardH = H \+ (?P<back_row_drop_per_h>{NUM}) \* H \+ (?P<back_row_gap>{NUM});",
    ),
    (
        "stage.recruit",
        "recruit.html",
        rf"const T1 = boardTop - (?P<transom_gap>{NUM}), T0 = T1 - (?P<transom_h>{NUM});",
    ),
    (
        "stage.recruit",
        "recruit.html",
        rf"const sideW = (?P<side_light_w>{NUM}), cL = 16 \+ sideW \+ (?P<centre_inset>{NUM})",
    ),
    ("stage.recruit", "recruit.html", rf"const bw = (?P<button_w>{NUM}), bxL = G\.shopL - (?P<button_gap>{NUM}) - bw"),
    ("stage.recruit", "recruit.html", rf"by2 = by1 \+ (?P<button_step>{NUM});"),
    ("stage.recruit", "recruit.html", rf"step = G\.W \* (?P<hand_step_per_w>{NUM})"),
    ("stage.recruit", "recruit.html", rf"G\.handTop \+ k \* k \* (?P<hand_drop_per_k2>{NUM})\)"),
    ("stage.recruit", "recruit.html", rf"rotate\(\$\{{\(k \* (?P<hand_turn_deg_per_k>{NUM})\)"),
]


def git(*args: str) -> bytes:
    return subprocess.run(["git", "-C", str(ROOT), *args], check=True, capture_output=True).stdout


def show(commit: str, rel: str) -> bytes:
    return git("show", f"{commit}:{MOCKUPS}/{rel}")


def value(name: str, raw: str) -> object:
    if name.endswith("_json"):
        return json.loads(raw)
    if name.endswith(("_hex", "_rgba", "_text", "_font")):
        return raw.strip()
    number = float(raw)
    return int(number) if number.is_integer() and "." not in raw else number


def layout(commit: str) -> dict[str, dict[str, object]]:
    texts: dict[str, str] = {}
    out: dict[str, dict[str, object]] = {}
    missing: list[str] = []
    for prefix, rel, pattern in PATTERNS:
        text = texts.setdefault(rel, show(commit, rel).decode())
        found = re.search(pattern, text, re.DOTALL)
        if not found:
            missing.append(f"{rel}: {prefix} /{pattern[:70]}/")
            continue
        line = text.count("\n", 0, found.start()) + 1
        excerpt = " ".join(found.group(0).split())
        for name, raw in found.groupdict().items():
            key = f"{prefix}.{re.sub(r'_(json|hex|rgba|text|font)$', '', name)}"
            if key in out:
                sys.exit(f"pull_mockups: {key} is read twice")
            out[key] = {"value": value(name, raw), "from": f"{rel}:{line}", "source": excerpt[:240]}
    if missing:
        sys.exit(
            "pull_mockups: these patterns no longer match the mock-ups; update PATTERNS:\n  " + "\n  ".join(missing)
        )
    return out


def card_data(commit: str) -> dict[str, object]:
    js = show(commit, "assets/card-data.js").decode()
    found = re.fullmatch(r"\s*window\.CARD_DATA = (\{.*\});\s*", js, re.DOTALL)
    if not found:
        sys.exit("pull_mockups: assets/card-data.js is no longer `window.CARD_DATA = {...};`")
    return json.loads(found.group(1))


def font_metrics(name: str, data: bytes) -> dict[str, dict[str, object]]:
    """A font's vertical metrics in em, as browsers lay out a line with line-height: normal.

    The OS/2 typo metrics when the font sets USE_TYPO_METRICS, else hhea. Browsers round the
    ascent, descent and line gap to whole pixels at each size; the Godot side does the same.
    """
    count = struct.unpack(">H", data[4:6])[0]
    tables = {}
    for i in range(count):
        tag, _, offset, _ = struct.unpack(">4sIII", data[12 + 16 * i : 28 + 16 * i])
        tables[tag] = offset
    upm = struct.unpack(">H", data[tables[b"head"] + 18 : tables[b"head"] + 20])[0]
    os2 = tables[b"OS/2"]
    use_typo = bool(struct.unpack(">H", data[os2 + 62 : os2 + 64])[0] & 128)
    if use_typo:
        ascent, descent, gap = struct.unpack(">hhh", data[os2 + 68 : os2 + 74])
        where = "OS/2 typo metrics (USE_TYPO_METRICS is set)"
    else:
        ascent, descent, gap = struct.unpack(">hhh", data[tables[b"hhea"] + 4 : tables[b"hhea"] + 10])
        where = "hhea metrics"
    values = {"ascent": ascent / upm, "descent": -descent / upm, "line_gap": gap / upm}
    return {
        f"font.{name}.{k}": {"value": v, "from": f"fonts/{FONT_FILES[name]}", "source": where}
        for k, v in values.items()
    }


def fetch_font(path: str) -> bytes:
    url = f"https://raw.githubusercontent.com/google/fonts/{FONTS_COMMIT}/{path}"
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def build(commit: str, keep_fonts: dict[str, bytes]) -> dict[str, bytes]:
    """Every file under assets/glass, as bytes, keyed by its path there."""
    files: dict[str, bytes] = {}
    for tier in range(1, 7):
        files[f"frames/tier{tier}.webp"] = show(commit, f"assets/frames/tier{tier}.webp")
    lay = layout(commit)
    for art in lay["sheet.art"]["value"]:  # type: ignore[union-attr]
        files[f"art/{art}.jpg"] = show(commit, f"assets/art/{art}.jpg")
    for name, path in FONTS.items():
        files[f"fonts/{name}"] = keep_fonts.get(name) or fetch_font(path)
    for family, file in FONT_FILES.items():
        lay.update(font_metrics(family, files[f"fonts/{file}"]))
    files["card_data.json"] = (json.dumps(card_data(commit), indent=1) + "\n").encode()
    files["layout.json"] = (json.dumps(lay, indent=1) + "\n").encode()
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--ref", default=DEFAULT_REF, help=f"commit or branch of the mock-ups (default {DEFAULT_REF})")
    parser.add_argument("--check", action="store_true", help="only report whether assets/glass matches the ref")
    args = parser.parse_args()
    commit = git("rev-parse", "--verify", f"{args.ref}^{{commit}}").decode().strip()
    date = git("show", "-s", "--format=%cI", commit).decode().strip()
    # Fonts come from a pinned commit; reuse the copies already here rather than download them again.
    keep = {n: (OUT / "fonts" / n).read_bytes() for n in FONTS if (OUT / "fonts" / n).exists()}
    files = build(commit, keep)
    source = {
        "mockups_commit": commit,
        "mockups_commit_date": date,
        "mockups_path": MOCKUPS,
        "fonts": f"github.com/google/fonts at {FONTS_COMMIT}",
        "remake": f"python3 tools/glass/pull_mockups.py --ref {commit}",
        "files": {k: hashlib.sha256(v).hexdigest() for k, v in sorted(files.items())},
    }
    files["source.json"] = (json.dumps(source, indent=1) + "\n").encode()
    changed = [k for k, v in files.items() if not (OUT / k).exists() or (OUT / k).read_bytes() != v]
    if args.check:
        state = "differs from" if changed else "matches"
        print(f"assets/glass {state} {commit[:10]}: {', '.join(changed) or 'no change'}")
        return 1 if changed else 0
    for rel in changed:
        (OUT / rel).parent.mkdir(parents=True, exist_ok=True)
        (OUT / rel).write_bytes(files[rel])
    print(f"pulled {commit[:10]} ({date}): {len(changed)} of {len(files)} files changed under assets/glass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
