"""Reads the mock-ups' CSS into plain values the Godot side can draw from, for pull_mockups.py.

Only the forms the mock-ups use are understood: px, em and % lengths, hex and rgba() colours,
var(--x), radial-gradient(), url() layers with a position and size, box-shadow and text-shadow
lists, filter functions, the font shorthand, solid borders, -webkit-text-stroke and polygon()
clip paths. A value in any other form stays as its source text, so nothing is guessed.

Lengths: a px or unitless length becomes a number; an em or % length stays a string such as
"0.06em" or "30%", for the Godot side to resolve against the font size or the box.
Colours become "#rrggbbaa".
"""

from __future__ import annotations

import re

NUM = r"-?(?:\d+\.?\d*|\.\d+)"
LENGTH = re.compile(rf"^({NUM})(px|em|%)?$")


def split_top(text: str, sep: str = ",") -> list[str]:
    """Splits on sep outside brackets."""
    parts: list[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(text):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif depth == 0 and (ch == sep or (sep == " " and ch.isspace())):
            parts.append(text[start:i])
            start = i + 1
    parts.append(text[start:])
    return [p.strip() for p in parts if p.strip()]


def rules(css: str) -> list[tuple[str, int, dict[str, tuple[str, int]]]]:
    """Each top-level rule as (selector, line, {property: (value, line)}). @media blocks are left out:
    the screens are drawn in the pages' dark scheme, as compare.py renders them."""
    out = []
    css = re.sub(r"/\*.*?\*/", lambda m: re.sub(r"[^\n]", " ", m.group(0)), css, flags=re.DOTALL)
    i = 0
    while i < len(css):
        brace = css.find("{", i)
        if brace < 0:
            break
        selector = css[i:brace].strip()
        if selector.startswith("@"):
            depth, j = 1, brace + 1
            while depth:
                depth += {"{": 1, "}": -1}.get(css[j], 0)
                j += 1
            i = j
            continue
        end = css.find("}", brace)
        body = css[brace + 1 : end]
        decls: dict[str, tuple[str, int]] = {}
        offset = brace + 1
        for decl in split_top(body, ";"):
            name, _, val = decl.partition(":")
            at = css.find(decl, offset)
            decls[name.strip()] = (" ".join(val.split()), css.count("\n", 0, at) + 1)
        for one in split_top(selector):
            out.append((one, css.count("\n", 0, brace) + 1, decls))
        i = end + 1
    return out


def resolve(value: str, variables: dict[str, str]) -> str:
    for _ in range(5):
        value = re.sub(r"var\((--[\w-]+)\)", lambda m: variables.get(m.group(1), m.group(0)), value)
    return value


def colour(text: str) -> str | None:
    text = text.strip()
    if text == "transparent":
        return "#00000000"
    m = re.fullmatch(r"#([0-9a-fA-F]{3,8})", text)
    if m:
        h = m.group(1)
        if len(h) in (3, 4):
            h = "".join(c * 2 for c in h)
        return "#" + (h + "ff" if len(h) == 6 else h).lower()
    m = re.fullmatch(r"rgba?\(([^)]*)\)", text)
    if m:
        parts = [float(p) for p in m.group(1).split(",")]
        a = parts[3] if len(parts) > 3 else 1.0
        return "#" + "".join(f"{round(v):02x}" for v in parts[:3]) + f"{round(a * 255):02x}"
    return None


def length(text: str) -> float | str | None:
    m = LENGTH.match(text.strip())
    if not m:
        return None
    unit = m.group(2)
    number = float(m.group(1))
    if unit in (None, "px"):
        return int(number) if number.is_integer() else number
    return f"{number:g}{unit}"


def lengths(text: str) -> object:
    parts = [length(p) for p in text.split()]
    if None in parts:
        return None
    return parts[0] if len(parts) == 1 else parts


def pct(text: str) -> float:
    return float(text.rstrip("%"))


def gradient(text: str) -> dict[str, object] | None:
    m = re.fullmatch(r"radial-gradient\((.*)\)", text)
    if not m:
        return None
    args = split_top(m.group(1))
    head = args[0]
    out: dict[str, object] = {"kind": "radial", "shape": "ellipse", "size": "farthest-corner", "at": [50.0, 50.0]}
    if colour(head.split()[0]) is None:
        args = args[1:]
        words = head.split()
        if "at" in words:
            k = words.index("at")
            out["at"] = [pct(words[k + 1]), pct(words[k + 2])]
            words = words[:k]
        if words and words[0] in ("ellipse", "circle"):
            out["shape"] = words.pop(0)
        if words:
            out["size"] = [pct(w) for w in words]
    stops: list[list[object]] = []
    for arg in args:
        words = split_top(arg, " ")
        c = colour(words[0])
        if c is None:
            return None
        positions = [pct(w) if w.endswith("%") else float(w) for w in words[1:]] or [None]
        stops.extend([c, p] for p in positions)
    out["stops"] = stops
    return out


def layer(text: str) -> dict[str, object] | None:
    g = gradient(text)
    if g:
        return g
    c = colour(text)
    if c:
        return {"kind": "colour", "colour": c}
    m = re.fullmatch(r"url\(assets/([^)]*)\)\s*(.*)", text)
    if m:
        out: dict[str, object] = {"kind": "image", "file": m.group(1), "position": [50.0, 50.0], "size": "auto"}
        pos, _, size = m.group(2).partition("/")
        if pos.strip() not in ("", "center"):
            return None
        size = size.strip()
        if size in ("cover", ""):
            out["size"] = size or "auto"
        else:
            words = size.split()
            if len(words) != 2 or words[1] != "auto":
                return None
            out["size"] = [pct(words[0]), "auto"]
        return out
    return None


def shadow(text: str) -> dict[str, object] | None:
    words = split_top(text, " ")
    inset = "inset" in words
    words = [w for w in words if w != "inset"]
    c = next((colour(w) for w in words if colour(w)), None)
    nums = [length(w) for w in words if colour(w) is None]
    if c is None or None in nums or not 2 <= len(nums) <= 4:
        return None
    nums += [0] * (4 - len(nums))
    return {"inset": inset, "x": nums[0], "y": nums[1], "blur": nums[2], "spread": nums[3], "colour": c}


def font(text: str) -> dict[str, object] | None:
    m = re.fullmatch(rf"(\d+) ({NUM}(?:px|em))(?:/({NUM}))? (.+)", text)
    if not m:
        return None
    family = "body" if "Alegreya Sans" in m.group(4) else "display"
    return {
        "weight": int(m.group(1)),
        "size": length(m.group(2)),
        "line_height": float(m.group(3)) if m.group(3) else None,
        "family": family,
    }


def parse(prop: str, raw: str, variables: dict[str, str]) -> object:
    """The value as the Godot side reads it, or the source text when its form is not understood."""
    text = resolve(raw, variables)
    parsed: object = None
    if prop in ("background",):
        layers = [layer(p) for p in split_top(text)]
        parsed = None if None in layers else layers
    elif prop in ("box-shadow", "text-shadow"):
        shadows = [shadow(p) for p in split_top(text)]
        parsed = None if None in shadows else shadows
    elif prop == "filter":
        fns = []
        for fn in re.findall(r"([\w-]+)\(((?:[^()]|\([^)]*\))*)\)", text):
            if fn[0] == "drop-shadow":
                fns.append({"fn": fn[0], **(shadow(fn[1]) or {})})
            else:
                fns.append({"fn": fn[0], "amount": float(fn[1])})
        parsed = fns
    elif prop == "font":
        parsed = font(text)
    elif prop in ("border", "-webkit-text-stroke"):
        if text == "0":
            return {"width": 0, "colour": "#00000000"}
        m = re.fullmatch(rf"({NUM}px)(?: solid)? (.+)", text)
        if m and colour(m.group(2)):
            parsed = {"width": length(m.group(1)), "colour": colour(m.group(2))}
    elif prop == "clip-path":
        m = re.fullmatch(r"polygon\((.*)\)", text)
        if m:
            parsed = [[pct(a) for a in p.split()] for p in split_top(m.group(1))]
    elif prop in ("color", "background-color", "stroke"):
        parsed = colour(text)
    elif prop == "background-blend-mode":
        parsed = split_top(text)
    else:
        parsed = lengths(text)
    return text if parsed is None else parsed
