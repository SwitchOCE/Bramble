#!/usr/bin/env python3
"""Pulls the glass mock-ups' own pieces into the Godot project, from one commit of the mock-ups branch.

    python3 tools/glass/pull_mockups.py                      # origin/design/glass-mockups as fetched now
    python3 tools/glass/pull_mockups.py --ref 8279442b       # any commit or branch name
    python3 tools/glass/pull_mockups.py --check              # only says whether assets/glass matches the ref

Run `git fetch origin` first to get the mock-ups' latest commit. Writes into assets/glass/:

- frames/tier1..6.webp   the six tier frames, as the mock-ups use them (560 x 1000)
- art/<name>.jpg         the card art cards.html and recruit.html show (the art recipe's test set, not
                         decided units)
- portraits/<name>.jpg   the hero portraits the screens show (stand-ins)
- ui/<file>              the window's stone and field, the pane glass, the roundels and the tribe
                         emblems: every assets/ui file the screens' CSS and JS name
- fonts/                 Alegreya and Alegreya Sans, the fonts the pages load from Google Fonts,
                         fetched from a pinned commit of github.com/google/fonts (OFL)
- card_data.json         assets/card-data.js as JSON: each tier's Attack and Health discs, the art polygon
- layout.json            every layout number, colour and font the Godot side reads, each with the file,
                         line and source text it came from
- source.json            the commit pulled and the SHA-256 of every file written

The frames and art import with mipmaps on, so they stay smooth when drawn small: a file new to
assets/glass needs `mipmaps/generate=true` in its .import file after Godot first imports it.
The mock-ups still show a hand of 10; the rule is 7 (rulebook 7.1.1), so the hand count is not pulled.

layout.json holds three kinds of entry, each saying where it came from:

- card.*, sheet.*, stage.*: numbers read out of the mock-ups' JS and CSS by PATTERNS and LINES below.
  stage.recruit.geom is recruit.html's own geom() run with node for the chosen version (the page's
  defaults: 250 px cards, spells above, slopes matched to the cards), so the screen's geometry is the
  page's formula, not a copy of it. stage.icon.* are the buttons' SVG icons.
- css/<file>/<selector>/<property>: every declaration of the CSS rules the screens draw (CSS_RULES),
  as tools/glass/css_values.py reads them; "source" keeps the CSS text.
- font.*: the fonts' vertical metrics.

When a pattern no longer matches the source, or a listed CSS rule is gone, the script stops and names
it, so a changed mock-up never leaves a stale number. It needs node to run geom().
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

import css_values

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
    # the screens' shared look: the stage's size; its colours are css/stage/:root
    (
        "stage",
        "stage.css",
        rf"#stage\{{position:absolute;left:0;top:0;width:(?P<width>{NUM})px;height:(?P<height>{NUM})px",
    ),
]

# Literal source lines: each {name} is a number read out (a name used twice must hold the same number
# both times), {name_hex} a colour, and {*} any text, such as a stand-in name the view state supplies.
LINES: list[tuple[str, str, str]] = [
    # recruit.html: the page's defaults pick the chosen version, which geom() is run for
    (
        "stage.recruit",
        "recruit.html",
        'const S = { size: Q.get("size") || "b", spells: Q.get("spells") || "above", sp: Q.get("sp") || "match",',
    ),
    ("stage.recruit", "recruit.html", 'const H = S.size === "b" ? {card_h} : {*}, G = geom('),
    (
        "stage.recruit.spell",
        "recruit.html",
        "const gx = G.shopL + (k + {first_gap}) * (G.W + G.g) - G.g / 2, "
        "bottom = G.shopTop + {drop_per_h} * H - {lift};",
    ),
    (
        "stage.recruit.button",
        "recruit.html",
        "const bw = {w}, bxL = G.shopL - {gap} - bw, bxR = G.shopL + G.shopW + {gap}, "
        "by1 = G.shopTop + H / 2 - {up}, by2 = by1 + {step};",
    ),
    ("stage.recruit.board", "recruit.html", "backY = by + {back_drop_per_h} * H + {back_gap};"),
    ("stage.recruit.hand", "recruit.html", "step = G.W * {step_per_w}, hx = 960 - G.W / 2, hw = step * (N - 1) + G.W;"),
    ("stage.recruit.hand", "recruit.html", "el = put(c, hx + k * step, G.handTop + k * k * {drop_per_k2});"),
    ("stage.recruit.hand", "recruit.html", "el.style.transform = `rotate(${(k * {turn_deg_per_k}).toFixed(2)}deg)`;"),
    (
        "stage.recruit.hand_label",
        "recruit.html",
        '<div class="lbl" style="font-size:{size}px;color:{colour_hex}">Hand ${HAND.length}/10</div>`), '
        "960 - hw / 2 - {left}, G.handTop + {down}));",
    ),
    ("stage.recruit.end", "recruit.html", "const eX = 1904 - {margin} - {port_room} - {inset};"),
    (
        "stage.recruit.end",
        "recruit.html",
        '<div class="lbl endlbl" style="font-size:{label_size}px">End turn</div>`), '
        "eX - {label_left}, 1080 - {label_up}));",
    ),
    (
        "stage.recruit.end",
        "recruit.html",
        '<div class="port endturn" style="width:{port}px;height:{port}px;'
        'background-image:url(assets/portraits/{*}.jpg)"></div>`), eX, 1080 - {port_up}));',
    ),
    ("stage.recruit.end", "recruit.html", '<div class="hp">{*}</div>`), eX - {hp_left}, 1080 - {hp_up}));'),
    ("stage.recruit.leaderboard", "recruit.html", 'if (S.lb === "1") leaderboard(st, G, {top}, {step});'),
    # stage.js: the stone window
    ("stage.stone", "stage.js", "const ysSide = {side_arch_start};"),
    (
        "stage.stone",
        "stage.js",
        "const L = [[{margin}, {margin} + G.sideW, ysSide, {side_arch_top}], [G.cL, G.cR, G.ys, {centre_arch_top}], "
        "[1904 - G.sideW, 1904, ysSide, {side_arch_top}]];",
    ),
    (
        "stage.stone.arch",
        "stage.js",
        "C${x0},${f(ys - {k_start} * h)} ${f(xm - {k_mid} * w)},${f(ya + {k_top} * h)} ${xm},${ya} "
        "C${f(xm + {k_mid} * w)},${f(ya + {k_top} * h)} ${x1},${f(ys - {k_start} * h)} ${x1},${ys}",
    ),
    ("stage.stone", "stage.js", 'width="{tile}" height="{tile}"><image href="assets/ui/stone.jpg"'),
    (
        "stage.stone.sill",
        "stage.js",
        '<stop offset="0" stop-color="{top_hex}" stop-opacity="{top_opacity}"/><stop offset="{a}" stop-color="#000" '
        'stop-opacity="0"/><stop offset="{b}" stop-color="#000" stop-opacity="{b_opacity}"/><stop offset="1" '
        'stop-color="#000" stop-opacity="{end_opacity}"/>',
    ),
    ("stage.stone", "stage.js", 'fill-rule="evenodd" fill="{shade_hex}" fill-opacity="{shade_opacity}"/>'),
    (
        "stage.stone.lead",
        "stage.js",
        '<path d="${holes}" stroke="{outer_hex}" stroke-width="{outer_w}"/><path d="${holes}" stroke="{inner_hex}" '
        'stroke-width="{inner_w}"/>',
    ),
    (
        "stage.stone.lead",
        "stage.js",
        '<path d="${holes}" stroke="{dash_hex}" stroke-width="{inner_w}" stroke-dasharray="{dash_on} {dash_off}"/>'
        '<path d="${holes}" stroke="{tick_hex}" stroke-width="{inner_w}" stroke-dasharray="{tick_on} {tick_off}"/>',
    ),
    ("stage.stone.edge", "stage.js", '<path d="${holes}" fill="none" stroke="{colour_hex}" stroke-width="{w}"/>'),
    (
        "stage.stone.highlight",
        "stage.js",
        '<path d="${holes}" fill="none" stroke="{colour_hex}" stroke-opacity="{opacity}" stroke-width="{w}" '
        'transform="translate({x},{y})"/>',
    ),
    # stage.js: the Ring slot's words, the hero on the left, the leaderboard, the hover detail
    ("stage.slot", "stage.js", 'style="font-size:${(G.H * {ring_text_per_h}).toFixed(0)}px"'),
    ("stage.hero", "stage.js", 'st.append(place(html(`<div class="lbl">${turnLabel}</div>`), {turn_x}, {turn_y}));'),
    (
        "stage.hero",
        "stage.js",
        '<div class="lbl" style="font-size:{name_size}px">{*}</div>`), {name_x}, 1080 - {name_up}));',
    ),
    (
        "stage.hero",
        "stage.js",
        '<div class="port hero" style="width:{port}px;height:{port}px;background-image:url(assets/portraits/{*}.jpg)">'
        "</div>`), {port_x}, 1080 - {port_up}));",
    ),
    ("stage.hero", "stage.js", '<div class="hp">{*}</div>`), {hp_x}, 1080 - {hp_up}));'),
    ("stage.hero.chip", "stage.js", '.png)"></div>`), {x}, 1080 - {up} + i * {step}));'),
    ("stage.hero.chip", "stage.js", '<div class="chipv">${v}</div>`), {count_x}, 1080 - {count_up} + i * {step}));'),
    (
        "stage.leaderboard",
        "stage.js",
        '<div id="lbpane" style="width:{pane_w}px;height:${LOBBY.length * step + {pane_extra}}px"></div>`), '
        "px - {pane_left}, top - {pane_up}));",
    ),
    ("stage.leaderboard", "stage.js", "const y = top + {row_down} + i * step"),
    (
        "stage.leaderboard",
        "stage.js",
        '<div class="port" style="width:{port}px;height:{port}px;background-image:url(assets/portraits/${p.p}.jpg)">'
        "</div>`), px - {port_left}, y));",
    ),
    ("stage.leaderboard", "stage.js", '<div class="hp">${p.hp}</div>`), px + {hp_right}, y + {hp_down}));'),
    ("stage.leaderboard", "stage.js", '<div class="pl">${i + 1}</div>`), px - {place_left}, y + {place_down}));'),
    ("stage.tip", "stage.js", "const big = {big_per_h} * H, bigW = big * 0.56;"),
    ("stage.tip", "stage.js", "let tx = mx + {gap}, ty = my - big / 2;"),
    ("stage.tip", "stage.js", "if (tx + bigW + {flip_room} > {flip_edge}) tx = mx - {gap} - bigW - {flip_back};"),
    ("stage.tip", "stage.js", "ty = Math.max({top_min}, Math.min({bottom_max} - big, ty));"),
    (
        "stage.tip",
        "stage.js",
        "show(el, parseFloat(el.style.left) + G.W * {pin_x_per_w}, parseFloat(el.style.top) + H * {pin_y_per_h});",
    ),
    # card.js: the stand-in spell's cost number
    ("stage.spell", "card.js", 'c.style.fontSize = (h * (spell === "hex" ? {cost_per_h} : {*})).toFixed(1) + "px";'),
]

# The CSS rules the screens draw. Every declaration of each is pulled as css/<file>/<selector>/<property>.
CSS_RULES: dict[str, list[str]] = {
    "stage.css": [
        ":root",
        "#field",
        "#light",
        "#vig",
        ".slot",
        ".slot::after",
        ".slot.ring::after",
        ".slot .rt",
        ".slot .rt small",
        ".chip",
        ".chipv",
        ".card.hot",
        ".btn",
        ".btn svg",
        ".btn.gold",
        ".btn.gold b",
        ".btn.gold svg",
        ".btn .pip",
        ".btn.freeze svg",
        ".lbl",
        ".hp",
        ".hero",
        ".endturn",
        ".endlbl",
        "#lbpane",
        ".lb .port",
        ".lb .hp",
        ".lb .pl",
        ".lb .next .port",
        ".lb .you .port",
        "#tip",
        "#tip .txt",
        "#tip .n",
        "#tip .m",
        "#tip .r",
    ],
    "card.css": [".card .spell-lead", ".card .cost", ".card.hexsp .art", ".card.hexsp .cost"],
}


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
    lines = [(prefix, rel, line_pattern(template)) for prefix, rel, template in LINES]
    for prefix, rel, pattern in PATTERNS + lines:
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
                # One number named in two places must hold the same value in both; the first is kept.
                if out[key]["value"] != value(name, raw):
                    sys.exit(f"pull_mockups: {key} is read twice, with different values")
                continue
            out[key] = {"value": value(name, raw), "from": f"{rel}:{line}", "source": excerpt[:240]}
    if missing:
        sys.exit(
            "pull_mockups: these patterns no longer match the mock-ups; update PATTERNS:\n  " + "\n  ".join(missing)
        )
    return out


def line_pattern(template: str) -> str:
    """A LINES template as a pattern: the text literal, each {name} a named group (JS's own ${...} is text)."""
    out = ""
    seen: set[str] = set()
    for piece in re.split(r"((?<!\$)\{[\w*]+\})", template):
        name = piece[1:-1] if piece.startswith("{") and piece.endswith("}") else None
        if name is None:
            out += re.escape(piece)
        elif name == "*":
            out += r'[^<"]*?'
        elif name in seen:
            out += f"(?P={name})"
        else:
            seen.add(name)
            kind = HEX if name.endswith("_hex") else NUM
            out += f"(?P<{name}>{kind})"
    return out


def css(commit: str) -> dict[str, dict[str, object]]:
    out: dict[str, dict[str, object]] = {}
    variables: dict[str, str] = {}
    for rel, selectors in CSS_RULES.items():
        found = {sel: (line, decls) for sel, line, decls in css_values.rules(show(commit, rel).decode())}
        if ":root" in found:
            variables.update({k: v for k, (v, _) in found[":root"][1].items()})
        missing = [s for s in selectors if s not in found]
        if missing:
            sys.exit(f"pull_mockups: {rel} no longer has the rules {missing}; update CSS_RULES")
        for sel in selectors:
            for prop, (raw, line) in found[sel][1].items():
                out[f"css/{rel.removesuffix('.css')}/{sel}/{prop}"] = {
                    "value": css_values.parse(prop, raw, variables),
                    "from": f"{rel}:{line}",
                    "source": f"{prop}:{raw}"[:240],
                }
    return out


def geom(commit: str, card_h: float) -> dict[str, dict[str, object]]:
    """recruit.html's geom() for the chosen version, run with node."""
    text = show(commit, "recruit.html").decode()
    start = text.find("function geom(")
    if start < 0:
        sys.exit("pull_mockups: recruit.html has no function geom()")
    depth = 0
    end = text.index("{", start)
    while True:
        depth += {"{": 1, "}": -1}.get(text[end], 0)
        if depth == 0:
            break
        end += 1
    call = f"geom({card_h:g}, true, true)"
    script = f"{text[start : end + 1]}\nprocess.stdout.write(JSON.stringify({call}));"
    try:
        done = subprocess.run(["node", "-e", script], capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"pull_mockups: could not run recruit.html's geom() with node: {error}")
    return {
        "stage.recruit.geom": {
            "value": json.loads(done.stdout),
            "from": f"recruit.html:{text.count(chr(10), 0, start) + 1}",
            "source": f"{call} run with node: spells above, slopes matched to the cards",
        }
    }


def icons(commit: str) -> dict[str, dict[str, object]]:
    """The buttons' SVG icons (stage.js ICON), as SVG text."""
    text = show(commit, "stage.js").decode()
    block = re.search(r"const ICON = \{(.*?)\n\};", text, re.DOTALL)
    if not block:
        sys.exit("pull_mockups: stage.js has no const ICON = {...};")
    out: dict[str, dict[str, object]] = {}
    for m in re.finditer(r"(\w+): '(<svg[^']*</svg>)'", block.group(1)):
        line = text.count("\n", 0, block.start(1) + m.start()) + 1
        out[f"stage.icon.{m.group(1)}"] = {"value": m.group(2), "from": f"stage.js:{line}", "source": m.group(1)}
    if set(out) != {f"stage.icon.{n}" for n in ("gold", "tier", "refresh", "freeze")}:
        sys.exit(f"pull_mockups: stage.js's icons are now {sorted(out)}")
    return out


def referenced(commit: str, folder: str) -> list[str]:
    """Every file in assets/<folder> the recruit screen names, with those named through a template:
    art through A("..."), portraits through LOBBY's p: "...", tribe emblems through tr-${t}."""
    names: set[str] = set()
    for rel in ("stage.css", "card.css", "stage.js", "recruit.html"):
        text = show(commit, rel).decode()
        names.update(re.findall(rf"assets/{folder}/([\w.-]+\.(?:jpg|png|webp))", text))
        if folder == "art":
            names.update(f"{n}.jpg" for n in re.findall(r'\bA\("([\w-]+)"\)', text))
        elif folder == "portraits":
            names.update(f"{n}.jpg" for n in re.findall(r'\{ p: "(\w+)"', text))
        elif folder == "ui":
            for pair in re.findall(r'\[\["(\w+)", "[^"]*"\], \["(\w+)", "[^"]*"\]\]\.forEach', text):
                names.update(f"tr-{n}.png" for n in pair)
    return sorted(names)


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
    lay.update(css(commit))
    lay.update(geom(commit, float(lay["stage.recruit.card_h"]["value"])))  # type: ignore[arg-type]
    lay.update(icons(commit))
    arts = {f"{a}.jpg" for a in lay["sheet.art"]["value"]}  # type: ignore[union-attr]
    for art in sorted(arts | set(referenced(commit, "art"))):
        files[f"art/{art}"] = show(commit, f"assets/art/{art}")
    for folder in ("portraits", "ui"):
        for name in referenced(commit, folder):
            files[f"{folder}/{name}"] = show(commit, f"assets/{folder}/{name}")
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
