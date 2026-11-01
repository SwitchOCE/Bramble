"""Build a Once Upon a Galaxy card library from the official Galaxy Guide.

Source: https://guide.galaxy.fun/cards/ (Million Dreams Games' official card
database). The list page embeds name, type, factions, rules text, rarity, set,
pool and active/inactive flags for every card. Each card's own page adds
attack/health and the set name. Nothing here needs a login or an API key.

Run from the repo root:

    python -I tools/research/build_galaxy_library.py            # use cache
    python -I tools/research/build_galaxy_library.py --refresh  # re-download

Raw downloads are cached under tools/research/.cache/galaxy/ (git-ignored).
Outputs: docs/research/galaxy/data/cards.json, cards.csv and card-list.md.

A second, optional pass cross-references the fan wiki
(https://onceuponagalaxy.wiki.gg, MediaWiki API) for Golden ability text and
flags stat disagreements. Skip it with --no-wiki.

Standard library only.
"""

import argparse
import csv
import html
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

BASE = "https://guide.galaxy.fun"
LIST_URL = BASE + "/cards/"
USER_AGENT = "BrambleResearch/1.0 (design research; contact via repo owner)"
DELAY_SECONDS = 0.3

REPO = Path(__file__).resolve().parents[2]
CACHE = REPO / "tools" / "research" / ".cache" / "galaxy"
OUT_DIR = REPO / "docs" / "research" / "galaxy" / "data"

SET_NAMES = {"1": "Galaxy", "2": "Candylar", "3": "Mythbound", "4": "Chromaria"}
KEYWORDS = [
    "Recruit", "Farewell", "Hunt", "Support", "Sneak", "Ranged", "Quest",
    "Treasure Hoard", "Treasure Find", "Chance Encounter", "Prophecy",
    "Supersweet", "Sweeten", "Summon", "Transform", "Golden", "Silver",
    "Slot", "Paint", "Boon", "Cursed", "Banish",
]
CSV_FIELDS = [
    "name", "key", "type", "rarity", "attack", "health", "factions",
    "keywords", "text", "golden_text_wiki", "set", "set_name", "pool", "token", "status", "cid",
    "url",
]


def fetch(url: str, cache_file: Path, refresh: bool) -> str:
    """Return the page body, downloading it only if not cached."""
    if cache_file.exists() and not refresh:
        return cache_file.read_text(encoding="utf-8")
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode("utf-8", errors="replace")
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(body, encoding="utf-8")
    time.sleep(DELAY_SECONDS)
    return body


def clean(text: str) -> str:
    """Strip tags and entities, turning <br> into ' / '."""
    text = re.sub(r"<br\s*/?>", " / ", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def parse_list(page: str) -> list[dict]:
    cards = []
    for m in re.finditer(r"<db-card(.*?)>", page, re.S):
        attrs = dict(re.findall(r'data-card-([a-z-]+)(?:="([^"]*)")?', m.group(1)))
        if "key" not in attrs:
            continue
        cards.append({
            "name": html.unescape(attrs.get("name", "")),
            "key": attrs["key"],
            "type": attrs.get("type", ""),
            "rarity": attrs.get("rarity", ""),
            "factions": attrs.get("factions", "").split(),
            "text": clean(attrs.get("text", "")),
            "set": attrs.get("set", ""),
            "pool": attrs.get("pool", ""),
            "token": attrs.get("token") == "true",
            "inactive": attrs.get("inactive") == "true",
            "cid": attrs.get("cid", ""),
        })
    return cards


def parse_detail(page: str) -> dict:
    out = {}
    m = re.search(r'data-stat-atk="(-?\d+)"\s+data-stat-hp="(-?\d+)"', page)
    if m:
        out["attack"], out["health"] = int(m.group(1)), int(m.group(2))
    rules = {}
    for r in re.finditer(r'<tr data-rules="([^"]+)">.*?<td[^>]*>(.*?)</td>', page, re.S):
        rules[r.group(1)] = clean(r.group(2))
    if rules:
        out["rules"] = rules
    m = re.search(r'<tbody class="meta">.*?<td>\s*(.*?)</td>', page, re.S)
    if m:
        out["set_line"] = clean(m.group(1))
    return out


WIKI_API = "https://onceuponagalaxy.wiki.gg/api.php"
WIKI_CATEGORIES = ["Characters", "Spells", "Treasures", "Captains"]


def wiki_get(params: dict, cache_file: Path, refresh: bool) -> dict:
    query = "&".join(f"{k}={urllib.parse.quote(str(v))}" for k, v in params.items())
    return json.loads(fetch(f"{WIKI_API}?{query}&format=json", cache_file, refresh))


def wiki_infoboxes(refresh: bool) -> dict:
    """Map lower-cased page title -> infobox fields from the community wiki.

    The wiki (onceuponagalaxy.wiki.gg) is fan-maintained and can lag the
    official guide, but it records Golden ability text, which the guide's
    card pages do not show as text.
    """
    titles = []
    for cat in WIKI_CATEGORIES:
        cont, n = None, 0
        while True:
            params = {"action": "query", "list": "categorymembers",
                      "cmtitle": f"Category:{cat}", "cmlimit": "500", "cmtype": "page"}
            if cont:
                params["cmcontinue"] = cont
            d = wiki_get(params, CACHE / "wiki" / f"cat_{cat}_{n}.json", refresh)
            titles += [m["title"] for m in d["query"]["categorymembers"]]
            cont = d.get("continue", {}).get("cmcontinue")
            n += 1
            if not cont:
                break
    titles = sorted(set(titles))
    boxes = {}
    for i in range(0, len(titles), 50):
        batch = titles[i:i + 50]
        d = wiki_get({"action": "query", "prop": "revisions", "rvprop": "content|timestamp",
                      "rvslots": "main", "titles": "|".join(batch)},
                     CACHE / "wiki" / f"pages_{i // 50:03d}.json", refresh)
        for page in d["query"]["pages"].values():
            revs = page.get("revisions")
            if not revs:
                continue
            text = revs[0]["slots"]["main"].get("*", "")
            m = re.search(r"\{\{\s*\w+ Infobox(.*?)\n\}\}", text, re.S)
            if not m:
                continue
            fields = {}
            for f in re.finditer(r"^[ \t]*\|[ \t]*([a-z_0-9]+)[ \t]*=[ \t]*(.*)$", m.group(1), re.M):
                val = re.sub(r"<!--.*?-->", "", f.group(2))
                val = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", val).strip()
                if val:
                    fields[f.group(1)] = val
            fields["_timestamp"] = revs[0]["timestamp"]
            fields["_title"] = page["title"]
            boxes[re.sub(r"\s*\((character|spell|treasure|captain)\)$", "", page["title"], flags=re.I).lower()] = fields
    return boxes


def wiki_summary(fields: dict) -> dict:
    out = {"page": "https://onceuponagalaxy.wiki.gg/wiki/" + fields["_title"].replace(" ", "_"),
           "edited": fields["_timestamp"][:10]}
    for k in ("attack", "health"):
        if fields.get(k, "").lstrip("-").isdigit():
            out[k] = int(fields[k])
    gold = [f"{fields.get(t, '')} -- {fields[g]}".strip(" -")
            for t, g in (("ability_type", "ability_description_gold"),
                         ("ability_2_type", "ability_2_description_gold")) if fields.get(g)]
    if gold:
        out["golden_text"] = " / ".join(gold)
    return out


def keywords_in(text: str) -> list[str]:
    found = []
    for kw in KEYWORDS:
        if re.search(r"\b" + re.escape(kw) + r"\b", text, re.I):
            found.append(kw)
    return found


def write_markdown(cards: list[dict], path: Path, built: str) -> None:
    """Write a browsable Markdown listing of every card, grouped by type."""
    def cell(v):
        return str(v if v is not None else "").replace("|", "\\|").replace("\n", " ")
    lines = [
        "# Once Upon a Galaxy card list (generated)",
        "",
        f"Generated {built} by `tools/research/build_galaxy_library.py` from the official "
        f"[Galaxy Guide card database]({LIST_URL}). Do not edit by hand; re-run the script.",
        "",
        "Status `removed` means the guide marks the card inactive (rotated out). "
        "Pool: `shared` = in every game, `collectible` = only via a captain's 12-card deck, "
        "`token` = created by effects only. Stats are Bronze; Silver is +1/+1, Golden +2/+2.",
        "",
    ]
    titles = {"captain": "Captains", "character": "Characters", "spell": "Spells", "treasure": "Treasures"}
    for t, title in titles.items():
        group = [c for c in cards if c["type"] == t]
        lines += [f"## {title} ({len(group)})", ""]
        if t == "character":
            lines += ["| Name | Rarity | A/H | Factions | Text | Pool | Set | Status |", "|---|---|---|---|---|---|---|---|"]
            for c in group:
                lines.append(f"| {cell(c['name'])} | {c['rarity']} | {c['attack']}/{c['health']} | "
                             f"{' '.join(c['factions'])} | {cell(c['text'])} | {c['pool']} | {c['set_name']} | {c['status']} |")
        else:
            lines += ["| Name | Rarity | Text | Pool | Set | Status |", "|---|---|---|---|---|---|"]
            for c in group:
                lines.append(f"| {cell(c['name'])} | {c['rarity']} | {cell(c['text'])} | {c['pool']} | {c['set_name']} | {c['status']} |")
        lines.append("")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--refresh", action="store_true", help="re-download everything")
    ap.add_argument("--no-details", action="store_true", help="skip per-card pages")
    ap.add_argument("--no-wiki", action="store_true", help="skip the community-wiki cross-reference")
    args = ap.parse_args()

    page = fetch(LIST_URL, CACHE / "cards_list.html", args.refresh)
    cards = parse_list(page)
    seen, unique = set(), []
    for c in cards:  # the list page can repeat a card in more than one section
        if (c["key"], c["type"]) in seen:
            continue
        seen.add((c["key"], c["type"]))
        unique.append(c)
    cards = unique
    print(f"{len(cards)} cards on the list page", file=sys.stderr)

    for i, c in enumerate(cards, 1):
        c["url"] = f"{BASE}/cards/{c['key']}/"
        c["set_name"] = SET_NAMES.get(c["set"], c["set"])
        c["status"] = "removed" if c["inactive"] else "current"
        c["attack"] = c["health"] = None
        if not args.no_details:
            try:
                detail = parse_detail(fetch(c["url"], CACHE / "cards" / f"{c['key']}.html", args.refresh))
            except Exception as exc:  # keep going; record the failure
                print(f"  detail failed for {c['key']}: {exc}", file=sys.stderr)
                detail = {}
            c.update({k: v for k, v in detail.items() if k in ("attack", "health", "rules", "set_line")})
            rules = detail.get("rules", {})
            if rules.get("default") and len(rules.get("default")) > len(c["text"]):
                c["text"] = rules["default"]
            # keep extra rules rows (e.g. per-version text) only when they add something
            extra = {k: v for k, v in rules.items() if v != c["text"]}
            if extra:
                c["rules"] = extra
            else:
                c.pop("rules", None)
        c["keywords"] = keywords_in(c["text"])
        if i % 100 == 0:
            print(f"  {i}/{len(cards)}", file=sys.stderr)

    if not args.no_wiki:
        try:
            boxes = wiki_infoboxes(args.refresh)
        except Exception as exc:
            print(f"wiki cross-reference skipped: {exc}", file=sys.stderr)
            boxes = {}
        matched = 0
        for c in cards:
            fields = boxes.get(c["name"].lower())
            if not fields:
                continue
            matched += 1
            c["wiki"] = wiki_summary(fields)
            w = c["wiki"]
            if c["attack"] is not None and "attack" in w and (w["attack"], w.get("health")) != (c["attack"], c["health"]):
                c["wiki"]["stats_differ"] = True
        print(f"wiki cross-reference: {matched}/{len(cards)} matched", file=sys.stderr)

    order = {"captain": 0, "character": 1, "spell": 2, "treasure": 3}
    rank = {"Common": 1, "Uncommon": 2, "Rare": 3, "Epic": 4, "Legendary": 5, "Secret Rare": 6}
    cards.sort(key=lambda c: (order.get(c["type"], 9), rank.get(c["rarity"], 0), c["name"].lower()))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    meta = {
        "source": LIST_URL,
        "built": time.strftime("%Y-%m-%d"),
        "count": len(cards),
        "notes": "Silver = base +1/+1, Golden = base +2/+2 (per the guide's own card viewer script).",
    }
    (OUT_DIR / "cards.json").write_text(
        json.dumps({"meta": meta, "cards": cards}, indent=1, ensure_ascii=False), encoding="utf-8")
    with open(OUT_DIR / "cards.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CSV_FIELDS, extrasaction="ignore")
        w.writeheader()
        for c in cards:
            row = dict(c)
            row["factions"] = " ".join(c["factions"])
            row["keywords"] = "; ".join(c["keywords"])
            row["golden_text_wiki"] = c.get("wiki", {}).get("golden_text", "")
            w.writerow(row)
    write_markdown(cards, OUT_DIR / "card-list.md", meta["built"])
    print(f"wrote {len(cards)} cards to {OUT_DIR}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
