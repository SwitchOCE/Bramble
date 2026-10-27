#!/usr/bin/env python3
"""Build Bramble's Hearthstone Battlegrounds content library from HearthstoneJSON.

Usage (from the repo root):

    python -I tools/research/build_bg_library.py              # monthly history sample
    python -I tools/research/build_bg_library.py --every-build  # diff every build (slow, ~1 GB download)
    python -I tools/research/build_bg_library.py --refresh      # re-fetch the build list

Standard library only. Raw downloads are cached under tools/research/.cache/
(git-ignored). Historical builds are reduced to small "slim" snapshots after
download and the raw file is deleted, unless --keep-raw is given; the newest
build is always kept raw.

Outputs:
    docs/research/battlegrounds/data/*.json, minions.csv
    docs/research/battlegrounds/content-library.md

How pool membership is read from a build (the "era" of the build):
    flag       Feb 2022 onwards. Cards carry isBattlegroundsPoolMinion.
    techlevel  Nov 2020 to Jan 2022. Only pool minions carry techLevel, and every
               one of them links to a golden version. Exact.
    heuristic  Dec 2019 to Oct 2020. techLevel is also on tokens and goldens.
               Pool = techLevel minions that are not golden (no
               battlegroundsNormalDbfId, id not TB_BaconUps_*) and not on the
               curated ERA_A_NOT_POOL list below.
    none       Nov 2019 builds export no techLevel at all; they are skipped.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import datetime as dt
import email.utils
import json
import re
import statistics
import sys
import time
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / "tools" / "research" / ".cache"
RAW_DIR = CACHE / "raw"
SLIM_DIR = CACHE / "slim"
OUT_DIR = ROOT / "docs" / "research" / "battlegrounds" / "data"
DOC_PATH = ROOT / "docs" / "research" / "battlegrounds" / "content-library.md"

API = "https://api.hearthstonejson.com/v1"
COMMITS_API = "https://api.github.com/repos/HearthSim/hsdata/commits?per_page=100&page={page}"
USER_AGENT = "bramble-research/1.0 (+stdlib urllib)"

SLIM_VERSION = 2
FIRST_TIER_BUILD = 38377  # first build that exports techLevel (Dec 2019)

# Era A (heuristic) builds put techLevel on tokens too. These cards carry
# techLevel in Dec 2019 - Oct 2020 builds but were never buyable from the
# Tavern. Checked against hearthstone.wiki.gg (Battlegrounds token pages and the
# "Battlegrounds/Removed card" list). Reported in the doc.
ERA_A_NOT_POOL = {
    49278: "Guard Bot (token)",
    48842: "Microbot (token)",
    48885: "Jo-E Bot (token)",
    49168: "Robosaur (token)",
    2779: "Imp (token)",
    40425: "Tabbycat (token)",
    41839: "Rat (token)",
    53013: "Vault Safe (token)",
    53202: "Hench-Clan Squire (token)",
    1078: "Murloc Scout (token)",
    1624: "Hyena (token)",
    204: "Snake (token)",
    1006: "Finkle Einhorn (token)",
    39161: "Big Bad Wolf (token)",
    38735: "Spider (token)",
    471: "Damaged Golem (token)",
    59202: "Amalgam (hero power token)",
    57652: "Amalgam Explorer (hero power token)",
    50359: "Ironhide Runt (token)",
    41523: "Primalfin (token)",
    41067: "Plant (token)",
    62216: "Treasure Chest (token)",
    62213: "Sky Pirate (token)",
    64040: "Water Droplet (token)",
    1098: "Emperor Cobra, classic EX1_170 (not in any 2019-2020 Tavern list; "
          "a separate Battlegrounds Emperor Cobra was added in Nov 2022)",
}

# Mechanics that are display noise rather than rules keywords.
NOISE_MECHANICS = {"TRIGGER_VISUAL", "InvisibleDeathrattle", "AI_MUST_PLAY", "TAG_ONE_TURN_EFFECT"}
KEYWORD_NAMES = {
    "TAUNT": "Taunt", "DIVINE_SHIELD": "Divine Shield", "WINDFURY": "Windfury",
    "MEGA_WINDFURY": "Mega-Windfury", "POISONOUS": "Poisonous", "VENOMOUS": "Venomous",
    "REBORN": "Reborn", "STEALTH": "Stealth", "RUSH": "Rush", "CHARGE": "Charge",
    "MAGNETIC": "Magnetic", "BATTLECRY": "Battlecry", "DEATHRATTLE": "Deathrattle",
    "AVENGE": "Avenge", "START_OF_COMBAT": "Start of Combat", "BACON_RALLY": "Rally",
    "BACON_SPELLCRAFT_ID": "Spellcraft", "CHOOSE_ONE": "Choose One", "DISCOVER": "Discover",
    "END_OF_TURN_TRIGGER": "End of Turn", "AURA": "Aura", "OVERKILL": "Overkill",
    "FRENZY": "Frenzy", "ADAPT": "Adapt", "IMMUNE": "Immune", "CLEAVE": "Cleave",
    "LIFESTEAL": "Lifesteal", "SPELLPOWER": "Spell Damage",
}
# Keywords that are pure static abilities. A minion whose text is only these
# words is "keyword_only" (vanilla plus a keyword) for budgeting.
STATIC_KEYWORD_WORDS = [
    "Mega-Windfury", "Divine Shield", "Windfury", "Poisonous", "Venomous", "Reborn",
    "Stealth", "Taunt", "Rush", "Charge", "Magnetic", "Cleave", "Lifesteal", "Immune",
]
TRIBE_NAMES = {
    "MECHANICAL": "Mech", "MURLOC": "Murloc", "DEMON": "Demon", "BEAST": "Beast",
    "DRAGON": "Dragon", "PIRATE": "Pirate", "ELEMENTAL": "Elemental", "QUILBOAR": "Quilboar",
    "NAGA": "Naga", "UNDEAD": "Undead", "ABERRATION": "Aberration", "ALL": "All",
    "TOTEM": "Totem", "BLANK": "", "INVALID": "",
}

# Wiki spot-check, typed in by hand from hearthstone.wiki.gg Battlegrounds/<name>
# pages on 2026-10-27: tier, attack/health of the normal version, whether the
# wiki lists it as currently in the pool, and the wiki's pool history.
WIKI_CHECKED = "2026-10-27"
WIKI_SPOTCHECK = {
    "Alleycat": (1, 1, 1, False, "removed from pool 34.2.0 (2025-12-02)"),
    "Wrath Weaver": (1, 1, 3, True, "removed 33.2.0 (2025-08-05), re-added 34.2.0 (2025-12-02); Health 4 to 3 in 36.0.3 (2026-07-21)"),
    "Scallywag": (1, 3, 1, False, "removed from pool 32.2.0 (2025-04-29)"),
    "Murloc Warleader": (2, 3, 3, False, "removed from pool 26.2.0 (May 2023)"),
    "Cave Hydra": (4, 2, 4, False, "removed from pool 33.2.0 (2025-08-05); Attack 3 to 2 in 31.6.0"),
    "Brann Bronzebeard": (5, 2, 4, True, "in pool"),
    "Titus Rivendare": (5, 1, 7, True, "in pool"),
    "Baron Rivendare": (5, 1, 7, False, "removed from pool 25.2.0 (2023-01-17), removed from game 34.2.0 (2025-12-02)"),
    "Amalgadon": (7, 6, 6, False, "removed 23.2.0 (2022-05-10), back 27.2.0 (2023-08-22) as Tier 7 (was 6), removed 27.6.2 (2023-10-26)"),
    "Kalecgos, Arcane Aspect": (5, 4, 12, True, "removed 34.2.0 (2025-12-02), re-added 35.2.0 (2026-04-14); Tier 6 to 5 in 35.2.2 (2026-04-28)"),
}


# --------------------------------------------------------------------------- io

def log(*args):
    print(*args, file=sys.stderr, flush=True)


def http_get(url: str, retries: int = 3, method: str = "GET") -> tuple[bytes, dict]:
    last = None
    for attempt in range(retries):
        req = urllib.request.Request(url, method=method, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.read(), dict(resp.headers)
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                raise
            last = exc
        except (urllib.error.URLError, TimeoutError, ConnectionError) as exc:
            last = exc
        time.sleep(2 * (attempt + 1))
    raise RuntimeError(f"GET {url} failed: {last}")


def read_json(path: Path):
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
        fh.write("\n")


# ----------------------------------------------------------------- build list

def fetch_build_list(refresh: bool) -> dict[int, dict]:
    """Return {build: {"version": "x.y.z", "date": "YYYY-MM-DD", "date_source": ...}}."""
    path = CACHE / "builds.json"
    if path.exists() and not refresh:
        cached = read_json(path)
        age_h = (time.time() - path.stat().st_mtime) / 3600
        if age_h < 24:
            return {int(k): v for k, v in cached.items()}
    builds: dict[int, dict] = {}
    # 1. hsdata commit messages: "Update to patch 37.0.0.255790", dated.
    try:
        for page in range(1, 30):
            body, _ = http_get(COMMITS_API.format(page=page))
            commits = json.loads(body)
            if not commits:
                break
            for c in commits:
                msg = c["commit"]["message"]
                m = re.search(r"(\d+\.\d+\.\d+)\.(\d+)", msg)
                if not m:
                    continue
                b = int(m.group(2))
                date = c["commit"]["committer"]["date"][:10]
                builds.setdefault(b, {"version": m.group(1), "date": date, "date_source": "hsdata commit"})
            if len(commits) < 100:
                break
    except Exception as exc:  # GitHub rate limit etc.; fall back to the API index
        log("warning: hsdata commit list unavailable:", exc)
    # 2. HearthstoneJSON's own index (lists recent builds only).
    try:
        body, _ = http_get(API + "/")
        for b in set(int(x) for x in re.findall(r'href="/v1/(\d+)/"', body.decode("utf-8", "replace"))):
            builds.setdefault(b, {"version": None, "date": None, "date_source": None})
    except Exception as exc:
        log("warning: HearthstoneJSON index unavailable:", exc)
    if not builds and path.exists():
        return {int(k): v for k, v in read_json(path).items()}
    # Fill missing dates from the HTTP Last-Modified header of the cards file.
    missing = [b for b, v in builds.items() if not v["date"] and b >= FIRST_TIER_BUILD]

    def head(b):
        try:
            _, hdr = http_get(f"{API}/{b}/enUS/cards.json", method="HEAD")
            lm = hdr.get("Last-Modified")
            return b, email.utils.parsedate_to_datetime(lm).date().isoformat() if lm else None
        except Exception:
            return b, None

    with concurrent.futures.ThreadPoolExecutor(8) as ex:
        for b, d in ex.map(head, missing):
            if d:
                builds[b].update(date=d, date_source="http last-modified")
    write_json(path, {str(k): v for k, v in sorted(builds.items())})
    return builds


def choose_sample(builds: dict[int, dict], every: bool) -> list[int]:
    usable = sorted(b for b, v in builds.items() if b >= FIRST_TIER_BUILD and v.get("date"))
    if every:
        return usable
    by_month: dict[str, int] = {}
    for b in usable:
        by_month[builds[b]["date"][:7]] = b  # last build of each month wins
    chosen = set(by_month.values()) | {usable[0], usable[-1]}
    return sorted(chosen)


# ------------------------------------------------------------- card handling

def clean_text(text: str | None) -> str:
    if not text:
        return ""
    t = text.replace("[x]", "")
    t = re.sub(r"</?[a-zA-Z][^>]*>", "", t)
    t = re.sub(r"[$#](\d+)", r"\1", t)
    t = t.replace(" ", " ").replace("\n", " ")
    t = re.sub(r"\s+", " ", t).strip()
    return t


def tribes_of(card: dict) -> list[str]:
    races = card.get("races") or ([card["race"]] if card.get("race") else [])
    return [TRIBE_NAMES.get(r, r.title()) for r in races if TRIBE_NAMES.get(r, r)]


def keywords_of(card: dict) -> list[str]:
    out = []
    for m in card.get("mechanics") or []:
        if m in NOISE_MECHANICS:
            continue
        out.append(KEYWORD_NAMES.get(m, m.replace("_", " ").title()))
    return out


def effect_class(text: str) -> str:
    """vanilla (no text), keyword_only (only static keywords), or effect."""
    if not text:
        return "vanilla"
    rest = text
    for word in STATIC_KEYWORD_WORDS:
        rest = re.sub(re.escape(word), "", rest, flags=re.IGNORECASE)
    rest = re.sub(r"[\s,.;:]+", "", rest)
    return "keyword_only" if not rest else "effect"


def slim_minion(card: dict | None) -> dict | None:
    if not card:
        return None
    keep = ("dbfId", "id", "name", "techLevel", "attack", "health", "race", "races",
            "mechanics", "referencedTags", "text", "battlegroundsPremiumDbfId",
            "battlegroundsNormalDbfId", "isBattlegroundsDuosExclusive", "cost", "set",
            "battlegroundsTimewarpCard", "isBattlegroundsBuddy", "spellSchool",
            "isBattlegroundsPoolSpell", "battlegroundsAssociatedRaces", "type")
    return {k: card[k] for k in keep if k in card}


def pool_minions(cards: list[dict]) -> tuple[str, list[dict]]:
    minions = [c for c in cards if c.get("type") == "MINION"]
    if any(c.get("isBattlegroundsPoolMinion") for c in minions):
        return "flag", [c for c in minions if c.get("isBattlegroundsPoolMinion")]
    tl = [c for c in minions if "techLevel" in c]
    if not tl:
        return "none", []
    if all("battlegroundsPremiumDbfId" in c for c in tl):
        return "techlevel", tl
    return "heuristic", [
        c for c in tl
        if "battlegroundsNormalDbfId" not in c
        and not c["id"].startswith("TB_BaconUps")
        and not c.get("isBattlegroundsBuddy")
        and c["dbfId"] not in ERA_A_NOT_POOL
    ]


def is_quest(card: dict) -> bool:
    mech = card.get("mechanics") or []
    return (card.get("set") == "BATTLEGROUNDS" and card.get("type") == "SPELL"
            and ("QUEST" in mech or "SIDE_QUEST" in mech or "_Quest_" in card["id"]))


def make_slim(build: int, cards: list[dict]) -> dict:
    by_id = {c["dbfId"]: c for c in cards if "dbfId" in c}
    era, pool = pool_minions(cards)
    pool_recs = {}
    for c in pool:
        rec = slim_minion(c)
        gold = by_id.get(c.get("battlegroundsPremiumDbfId"))
        rec["golden"] = slim_minion(gold)
        pool_recs[c["dbfId"]] = rec
    heroes = {}
    for c in cards:
        if c.get("type") == "HERO" and c.get("battlegroundsHero"):
            hp = by_id.get(c.get("heroPowerDbfId"))
            heroes[c["dbfId"]] = {
                "dbfId": c["dbfId"], "id": c["id"], "name": c["name"], "armor": c.get("armor"),
                "health": c.get("health"), "battlegroundsBuddyDbfId": c.get("battlegroundsBuddyDbfId"),
                "hero_power": {k: hp.get(k) for k in ("dbfId", "id", "name", "cost", "text")} if hp else None,
            }
    pool_spells = {c["dbfId"]: slim_minion(c) for c in cards
                   if c.get("type") == "BATTLEGROUND_SPELL" and c.get("isBattlegroundsPoolSpell")}
    present = {
        "trinkets": sorted(c["dbfId"] for c in cards if c.get("type") == "BATTLEGROUND_TRINKET"),
        "anomalies": sorted(c["dbfId"] for c in cards if c.get("type") == "BATTLEGROUND_ANOMALY"),
        "quest_rewards": sorted(c["dbfId"] for c in cards if c.get("type") == "BATTLEGROUND_QUEST_REWARD"),
        "quests": sorted(c["dbfId"] for c in cards if is_quest(c)),
        "buddies": sorted(c["dbfId"] for c in cards if c.get("isBattlegroundsBuddy")
                          and "battlegroundsNormalDbfId" not in c),
        "bg_spells": sorted(c["dbfId"] for c in cards if c.get("type") == "BATTLEGROUND_SPELL"),
        "timewarp_minions": sorted(c["dbfId"] for c in cards if c.get("battlegroundsTimewarpCard")
                                   and c.get("type") == "MINION" and "battlegroundsNormalDbfId" not in c),
    }
    # Era A candidates that look like tokens are reported for review.
    review = []
    if era == "heuristic":
        review = sorted(c["dbfId"] for c in pool)
    return {"slim_version": SLIM_VERSION, "build": build, "era": era,
            "pool": {str(k): v for k, v in pool_recs.items()},
            "heroes": {str(k): v for k, v in heroes.items()},
            "pool_spells": {str(k): v for k, v in pool_spells.items()},
            "present": present, "heuristic_pool_ids": review}


def load_raw(build: int) -> list[dict]:
    path = RAW_DIR / f"{build}.cards.json"
    if not path.exists():
        log(f"  downloading build {build}")
        body, _ = http_get(f"{API}/{build}/enUS/cards.json")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
    return read_json(path)


def get_slim(build: int, keep_raw: bool) -> dict | None:
    path = SLIM_DIR / f"{build}.json"
    if path.exists():
        data = read_json(path)
        if data.get("slim_version") == SLIM_VERSION:
            return data
    try:
        cards = load_raw(build)
    except urllib.error.HTTPError as exc:
        log(f"  build {build}: {exc.code}, skipped")
        return None
    data = make_slim(build, cards)
    write_json(path, data)
    if not keep_raw:
        (RAW_DIR / f"{build}.cards.json").unlink(missing_ok=True)
    return data


# ---------------------------------------------------------------- assembling

def minion_record(card: dict, golden: dict | None) -> dict:
    text = clean_text(card.get("text"))
    atk, hp = card.get("attack", 0) or 0, card.get("health", 0) or 0
    rec = {
        "dbfId": card["dbfId"], "id": card["id"], "name": card["name"],
        "tier": card.get("techLevel"), "attack": atk, "health": hp, "vanilla_stats": atk + hp,
        "tribes": tribes_of(card), "keywords": keywords_of(card),
        "mechanics_raw": card.get("mechanics") or [],
        "referenced_tags": card.get("referencedTags") or [],
        "text": text, "effect_class": effect_class(text),
        "duos_exclusive": bool(card.get("isBattlegroundsDuosExclusive")),
        "golden_dbfId": golden["dbfId"] if golden else card.get("battlegroundsPremiumDbfId"),
        "golden_attack": golden.get("attack") if golden else None,
        "golden_health": golden.get("health") if golden else None,
        "golden_text": clean_text(golden.get("text")) if golden else None,
    }
    return rec


def build_history(slims: list[dict], builds: dict[int, dict]):
    """Per dbfId: list of builds where the card was in the pool, and its snapshots."""
    seen = defaultdict(list)
    snaps = {}
    hero_seen = defaultdict(list)
    hero_snaps = {}
    spell_seen = defaultdict(list)
    first_present = {}
    for s in slims:
        b = s["build"]
        for k, rec in s["pool"].items():
            seen[int(k)].append(b)
            snaps[int(k)] = (b, rec)
        for k, rec in s["heroes"].items():
            hero_seen[int(k)].append(b)
            hero_snaps[int(k)] = (b, rec)
        for k in s["pool_spells"]:
            spell_seen[int(k)].append(b)
        for kind, ids in s["present"].items():
            for i in ids:
                first_present.setdefault((kind, i), b)
    return seen, snaps, hero_seen, hero_snaps, spell_seen, first_present


def periods(seen_builds: list[int], sample: list[int]) -> list[list[int]]:
    """Contiguous runs of sampled builds in which the card was present."""
    idx = {b: i for i, b in enumerate(sample)}
    out = []
    for b in sorted(seen_builds):
        if out and idx[b] == idx[out[-1][1]] + 1:
            out[-1][1] = b
        else:
            out.append([b, b])
    return out


def date_of(builds, b):
    return builds.get(b, {}).get("date") if b else None


def assemble(latest_cards, latest_build, slims, sample, builds):
    by_id = {c["dbfId"]: c for c in latest_cards if "dbfId" in c}
    seen, snaps, hero_seen, hero_snaps, spell_seen, first_present = build_history(slims, builds)
    era_of = {s["build"]: s["era"] for s in slims}
    current_pool = {c["dbfId"] for c in latest_cards if c.get("isBattlegroundsPoolMinion")}

    # ---- minions
    minions = []
    for dbf, blist in seen.items():
        last_b, snap = snaps[dbf]
        current = dbf in current_pool
        if current:
            card = by_id[dbf]
            golden = by_id.get(card.get("battlegroundsPremiumDbfId"))
            source = latest_build
        else:
            card = snap
            golden = snap.get("golden")
            if not golden and dbf in by_id:  # pre-link era: take the golden link from latest
                golden = by_id.get(by_id[dbf].get("battlegroundsPremiumDbfId"))
            source = last_b
        rec = minion_record(card, golden)
        rec.update({
            "in_current_pool": current,
            "first_seen_build": min(blist), "first_seen_date": date_of(builds, min(blist)),
            "last_seen_build": max(blist), "last_seen_date": date_of(builds, max(blist)),
            "sampled_builds_in_pool": len(blist),
            "pool_periods": [[a, date_of(builds, a), z, date_of(builds, z)] for a, z in periods(blist, sample)],
            "pool_evidence": sorted({era_of[b] for b in blist}),
            "stats_source_build": source,
        })
        minions.append(rec)
    # tiers seen over time
    tiers_seen = defaultdict(set)
    for s in slims:
        for k, rec in s["pool"].items():
            if rec.get("techLevel") is not None:
                tiers_seen[int(k)].add(rec["techLevel"])
    names = defaultdict(list)
    for m in minions:
        m["tiers_seen"] = sorted(tiers_seen[m["dbfId"]])
        names[m["name"]].append(m["dbfId"])
    for m in minions:
        m["same_name_dbfIds"] = [d for d in names[m["name"]] if d != m["dbfId"]]
    # A lineage is every row with the same name (reprints get a new dbfId, e.g.
    # the BG_ copies of classic cards in Aug 2022). The primary row is the
    # current-pool one, else the most recently seen one.
    by_dbf = {m["dbfId"]: m for m in minions}
    for name, ids in names.items():
        rows = [by_dbf[i] for i in ids]
        primary = sorted(rows, key=lambda r: (not r["in_current_pool"], -r["last_seen_build"]))[0]
        first = min(rows, key=lambda r: r["first_seen_build"])
        for r in rows:
            r["lineage_primary"] = r is primary
            r["lineage_first_seen_date"] = first["first_seen_date"]
            r["lineage_last_seen_date"] = max(x["last_seen_date"] for x in rows)
    minions.sort(key=lambda m: (not m["in_current_pool"], m["tier"] or 0, m["name"]))

    # ---- timewarp minions (separate Chronum shop; not part of the Tavern pool)
    timewarp = []
    for c in latest_cards:
        if c.get("type") == "MINION" and c.get("battlegroundsTimewarpCard") and "battlegroundsNormalDbfId" not in c:
            rec = minion_record(c, by_id.get(c.get("battlegroundsPremiumDbfId")))
            rec["first_seen_build"] = first_present.get(("timewarp_minions", c["dbfId"]))
            rec["first_seen_date"] = date_of(builds, rec["first_seen_build"])
            timewarp.append(rec)
    timewarp.sort(key=lambda m: (m["tier"] or 0, m["name"]))

    # ---- spells
    spells = []
    for c in latest_cards:
        if c.get("type") != "BATTLEGROUND_SPELL":
            continue
        blist = spell_seen.get(c["dbfId"], [])
        spells.append({
            "dbfId": c["dbfId"], "id": c["id"], "name": c["name"], "cost": c.get("cost"),
            "tier": c.get("techLevel"), "spell_school": c.get("spellSchool"),
            "text": clean_text(c.get("text")), "keywords": keywords_of(c),
            "associated_tribes": [TRIBE_NAMES.get(r, r) for r in c.get("battlegroundsAssociatedRaces") or []],
            "in_current_pool": bool(c.get("isBattlegroundsPoolSpell")),
            "ever_in_pool_sampled": bool(blist),
            "timewarp": bool(c.get("battlegroundsTimewarpCard")),
            "duos_exclusive": bool(c.get("isBattlegroundsDuosExclusive")),
            "pool_first_seen_build": min(blist) if blist else None,
            "pool_last_seen_build": max(blist) if blist else None,
            "first_in_data_build": first_present.get(("bg_spells", c["dbfId"])),
            "first_in_data_date": date_of(builds, first_present.get(("bg_spells", c["dbfId"]))),
        })
    spells.sort(key=lambda s: (not s["in_current_pool"], s["tier"] or 0, s["cost"] or 0, s["name"]))

    def simple(kind, card_filter, extra=lambda c: {}):
        out = []
        for c in latest_cards:
            if not card_filter(c):
                continue
            fp = first_present.get((kind, c["dbfId"]))
            rec = {"dbfId": c["dbfId"], "id": c["id"], "name": c["name"], "cost": c.get("cost"),
                   "text": clean_text(c.get("text")), "keywords": keywords_of(c),
                   "associated_tribes": [TRIBE_NAMES.get(r, r) for r in c.get("battlegroundsAssociatedRaces") or []],
                   "duos_exclusive": bool(c.get("isBattlegroundsDuosExclusive")),
                   "first_in_data_build": fp, "first_in_data_date": date_of(builds, fp)}
            rec.update(extra(c))
            out.append(rec)
        out.sort(key=lambda r: (r.get("first_in_data_build") or 0, r["name"]))
        return out

    trinkets = simple("trinkets", lambda c: c.get("type") == "BATTLEGROUND_TRINKET",
                      lambda c: {"size": {"LESSER_TRINKET": "lesser", "GREATER_TRINKET": "greater"}.get(c.get("spellSchool"), c.get("spellSchool")),
                                 "related_card_dbfId": c.get("battlegroundsRelatedCard")})
    anomalies = simple("anomalies", lambda c: c.get("type") == "BATTLEGROUND_ANOMALY",
                       lambda c: {"related_card_dbfId": c.get("battlegroundsRelatedCard")})
    quests = simple("quests", is_quest, lambda c: {"kind": "side_quest" if "SIDE_QUEST" in (c.get("mechanics") or []) else "quest"})
    rewards = simple("quest_rewards", lambda c: c.get("type") == "BATTLEGROUND_QUEST_REWARD")

    # ---- buddies
    buddy_hero = {}
    for c in latest_cards:
        if c.get("type") == "HERO" and c.get("battlegroundsBuddyDbfId") and "battlegroundsSkinParentId" not in c:
            buddy_hero.setdefault(c["battlegroundsBuddyDbfId"], c)
    buddies = []
    for c in latest_cards:
        if c.get("isBattlegroundsBuddy") and c.get("type") == "MINION" and "battlegroundsNormalDbfId" not in c:
            rec = minion_record(c, by_id.get(c.get("battlegroundsPremiumDbfId")))
            hero = buddy_hero.get(c["dbfId"])
            rec["hero_dbfId"] = hero["dbfId"] if hero else None
            rec["hero_name"] = hero["name"] if hero else None
            fp = first_present.get(("buddies", c["dbfId"]))
            rec["first_in_data_build"], rec["first_in_data_date"] = fp, date_of(builds, fp)
            buddies.append(rec)
    buddies.sort(key=lambda r: (r["tier"] or 0, r["name"]))

    # ---- heroes (every hero that was draftable in a sampled build)
    current_heroes = {c["dbfId"] for c in latest_cards if c.get("type") == "HERO" and c.get("battlegroundsHero")}
    heroes = []
    for dbf, blist in hero_seen.items():
        last_b, snap = hero_snaps[dbf]
        card = by_id.get(dbf)
        if card and dbf in current_heroes:
            hp = by_id.get(card.get("heroPowerDbfId"))
            hp = {k: hp.get(k) for k in ("dbfId", "id", "name", "cost", "text")} if hp else None
            armor, health, buddy = card.get("armor"), card.get("health"), card.get("battlegroundsBuddyDbfId")
            name, cid = card["name"], card["id"]
        else:
            hp, armor, health, buddy = snap["hero_power"], snap.get("armor"), snap.get("health"), snap.get("battlegroundsBuddyDbfId")
            name, cid = snap["name"], snap["id"]
            if armor is None and card:
                armor = card.get("armor")
        heroes.append({
            "dbfId": dbf, "id": cid, "name": name, "health": health, "armor": armor,
            "hero_power_dbfId": hp.get("dbfId") if hp else None,
            "hero_power_name": hp.get("name") if hp else None,
            "hero_power_cost": hp.get("cost") if hp else None,
            "hero_power_text": clean_text(hp.get("text")) if hp else None,
            "buddy_dbfId": buddy, "buddy_name": by_id.get(buddy, {}).get("name") if buddy else None,
            "in_current_pool": dbf in current_heroes,
            "first_seen_build": min(blist), "first_seen_date": date_of(builds, min(blist)),
            "last_seen_build": max(blist), "last_seen_date": date_of(builds, max(blist)),
            "sampled_builds_in_pool": len(blist),
        })
    heroes.sort(key=lambda h: (not h["in_current_pool"], h["name"]))
    return dict(minions=minions, timewarp=timewarp, spells=spells, trinkets=trinkets,
                anomalies=anomalies, quests=quests, quest_rewards=rewards, buddies=buddies,
                heroes=heroes)


# ------------------------------------------------------------------- outputs

CSV_FIELDS = ["dbfId", "id", "name", "tier", "attack", "health", "vanilla_stats", "tribes",
              "keywords", "effect_class", "text", "in_current_pool", "duos_exclusive",
              "golden_dbfId", "golden_attack", "golden_health", "golden_text",
              "first_seen_build", "first_seen_date", "last_seen_build", "last_seen_date",
              "sampled_builds_in_pool", "tiers_seen", "pool_evidence", "stats_source_build",
              "same_name_dbfIds", "lineage_primary", "lineage_first_seen_date",
              "lineage_last_seen_date", "pool_periods", "mechanics_raw", "referenced_tags"]


def write_csv(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=CSV_FIELDS, extrasaction="ignore", lineterminator="\n")
        w.writeheader()
        for r in rows:
            row = {}
            for k, v in r.items():
                if k == "pool_periods":
                    v = ";".join(f"{a[1]}..{a[3]}" for a in v)
                elif isinstance(v, list):
                    v = "|".join(map(str, v))
                row[k] = v
            w.writerow(row)


def describe(values):
    if not values:
        return ("-",) * 4
    return (f"{statistics.mean(values):.1f}", f"{statistics.median(values):g}", min(values), max(values))


def md_table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(x) for x in r) + " |")
    return "\n".join(out)


def stat_rows(group):
    rows = []
    for tier in sorted({m["tier"] for m in group}):
        ms = [m for m in group if m["tier"] == tier]
        a, h, s = ([m[k] for m in ms] for k in ("attack", "health", "vanilla_stats"))
        da, dh, ds = describe(a), describe(h), describe(s)
        rows.append([tier, len(ms), f"{da[0]} / {da[1]} / {da[2]}-{da[3]}",
                     f"{dh[0]} / {dh[1]} / {dh[2]}-{dh[3]}", f"{ds[0]} / {ds[1]} / {ds[2]}-{ds[3]}"])
    return rows


def write_doc(lib, meta, review_notes):
    minions = lib["minions"]
    cur = [m for m in minions if m["in_current_pool"]]
    hist = [m for m in minions if not m["in_current_pool"]]
    prim = [m for m in minions if m["lineage_primary"]]
    hist_prim = [m for m in prim if not m["in_current_pool"]]
    L = []
    L.append("# Battlegrounds content library\n")
    L.append("Machine-readable Hearthstone Battlegrounds (HSBG) card data for Bramble's power budgeting. "
             "HSBG is Bramble's rules baseline; these files are the reference for what stats a tier buys and what an effect costs.\n")
    L.append(f"*Generated by `tools/research/build_bg_library.py` on {meta['generated']}. Do not edit by hand; re-run the script.*\n")
    L.append("## Source\n")
    L.append(f"- Data: [HearthstoneJSON](https://hearthstonejson.com/) `cards.json` (enUS), build **{meta['latest_build']}** "
             f"(patch {meta['latest_version']}, {meta['latest_date']}). This is the build `v1/latest` served on the run date.")
    L.append(f"- History: {meta['sampled_builds']} builds from {meta['first_sample_date']} to {meta['latest_date']} "
             f"({meta['sample_mode']}). Build numbers and dates come from the [HearthSim/hsdata](https://github.com/HearthSim/hsdata) commit log "
             "(\"Update to patch x.y.z.build\"), falling back to the HTTP Last-Modified date of the file.")
    L.append("- Pool membership was cross-checked by hand against [hearthstone.wiki.gg](https://hearthstone.wiki.gg/) Battlegrounds pages where the JSON was ambiguous (see Known gaps).\n")
    L.append("## Files\n")
    rows = [
        ["minions.json / minions.csv", len(minions), "Every minion seen in the Tavern pool in a sampled build. Normal version; golden fields linked."],
        ["timewarp.json", len(lib["timewarp"]), "Timewarped minions (bought in the separate Timewarp shop, not the Tavern pool)."],
        ["spells.json", len(lib["spells"]), "All `BATTLEGROUND_SPELL` cards: Tavern spells, upgrades and generated spells."],
        ["trinkets.json", len(lib["trinkets"]), "All `BATTLEGROUND_TRINKET` cards (lesser and greater)."],
        ["anomalies.json", len(lib["anomalies"]), "All `BATTLEGROUND_ANOMALY` cards."],
        ["quests.json", len(lib["quests"]) + len(lib["quest_rewards"]), "Quests (`quests`) and quest rewards (`rewards`)."],
        ["heroes.json", len(lib["heroes"]), "Every hero that was draftable in a sampled build, with armor and hero power."],
        ["buddies.json", len(lib["buddies"]), "Hero buddies (a 2022 feature, still in the data)."],
    ]
    L.append(md_table(["File", "Rows", "Contents"], rows) + "\n")
    L.append("Every JSON file is `{\"meta\": {...}, \"cards\": [...]}` (`quests.json` has `quests` and `rewards`). "
             "`text` is the rules text with HTML and layout markup removed. `effect_class` is `vanilla` (no text), "
             "`keyword_only` (text is only static keywords such as Taunt, Divine Shield, Reborn, Windfury, Venomous, Stealth, Magnetic) "
             "or `effect`. `vanilla_stats` = attack + health.\n")

    L.append("## Counts\n")
    L.append(f"- Minion rows (one per dbfId) ever in the pool: **{len(minions)}**; distinct minions by name: **{len(prim)}**; "
             f"in the current pool: **{len(cur)}**; distinct minions no longer in the pool: **{len(hist_prim)}**. "
             "Reprints share a name and are grouped by the `lineage_*` fields; use `lineage_primary` rows to avoid double counting.")
    L.append(f"- Duos-exclusive minions in the current pool: {sum(m['duos_exclusive'] for m in cur)}.")
    L.append(f"- Heroes ever draftable (sampled): {len(lib['heroes'])}; currently draftable: {sum(h['in_current_pool'] for h in lib['heroes'])}.")
    sp_cur = [s for s in lib["spells"] if s["in_current_pool"]]
    L.append(f"- Battleground spells: {len(lib['spells'])}; in the current Tavern spell pool: {len(sp_cur)}; seen in the pool in any sampled build: {sum(s['ever_in_pool_sampled'] for s in lib['spells'])}.")
    tri = Counter(t["size"] for t in lib["trinkets"])
    L.append(f"- Trinkets: {len(lib['trinkets'])} ({tri.get('lesser', 0)} lesser, {tri.get('greater', 0)} greater). Anomalies: {len(lib['anomalies'])}. "
             f"Quests: {len(lib['quests'])}; quest rewards: {len(lib['quest_rewards'])}. Buddies: {len(lib['buddies'])}. Timewarped minions: {len(lib['timewarp'])}.\n")

    L.append("### Minions per tier\n")
    tiers = sorted({m["tier"] for m in minions if m["tier"] is not None})
    L.append("Historical minions are counted at the tier they last held in the pool; one row per distinct name.\n")
    L.append(md_table(["Tier", "Current pool", "No longer in pool", "All (distinct)"],
                      [[t, sum(m["tier"] == t for m in cur), sum(m["tier"] == t for m in hist_prim), sum(m["tier"] == t for m in prim)] for t in tiers]) + "\n")
    L.append("### Current-pool minions per tribe\n")
    L.append("A minion with two tribes counts once in each. `All` is the Amalgadon-style every-tribe minion.\n")
    tribes = sorted({t for m in cur for t in m["tribes"]})
    trow = []
    for t in tribes + ["(none)"]:
        row = [t]
        for tier in tiers:
            row.append(sum(1 for m in cur if m["tier"] == tier and ((t in m["tribes"]) if t != "(none)" else not m["tribes"])))
        row.append(sum(row[1:]))
        trow.append(row)
    L.append(md_table(["Tribe"] + [f"T{t}" for t in tiers] + ["Total"], trow) + "\n")

    L.append("## Power-budget tables (current pool)\n")
    L.append("Each cell is mean / median / min-max. Stats are the normal (non-golden) version.\n")
    L.append("### All current-pool minions\n")
    L.append(md_table(["Tier", "Count", "Attack", "Health", "Attack+Health"], stat_rows(cur)) + "\n")
    plain = [m for m in cur if m["effect_class"] in ("vanilla", "keyword_only")]
    eff = [m for m in cur if m["effect_class"] == "effect"]
    L.append("### Vanilla or keyword-only\n")
    L.append(md_table(["Tier", "Count", "Attack", "Health", "Attack+Health"], stat_rows(plain)) + "\n" if plain else "None in the current pool.\n")
    L.append("### Has a text effect\n")
    L.append(md_table(["Tier", "Count", "Attack", "Health", "Attack+Health"], stat_rows(eff)) + "\n")
    L.append("### Every minion ever in the pool (for a larger sample)\n")
    L.append("Historical minions use their stats from the last sampled build in which they were in the pool, so tier is the tier they held then.\n")
    allplain = [m for m in prim if m["effect_class"] in ("vanilla", "keyword_only")]
    L.append(md_table(["Tier", "Count", "Attack", "Health", "Attack+Health"], stat_rows(prim)) + "\n")
    L.append("Vanilla or keyword-only, all eras:\n")
    L.append(md_table(["Tier", "Count", "Attack", "Health", "Attack+Health"], stat_rows(allplain)) + "\n")

    gold_off = [m for m in cur if m["golden_attack"] is not None and (m["golden_attack"], m["golden_health"]) != (2 * m["attack"], 2 * m["health"])]
    L.append(f"Golden stats are exactly double the normal stats for {len(cur) - len(gold_off)} of {len(cur)} current-pool minions"
             + (f"; exceptions: {', '.join(m['name'] + ' (' + str(m['attack']) + '/' + str(m['health']) + ' to ' + str(m['golden_attack']) + '/' + str(m['golden_health']) + ')' for m in gold_off)}." if gold_off else ".") + "\n")
    L.append("## Stat baseline: minions closest to vanilla\n")
    L.append("The current pool has almost no vanilla minions: nearly every stat line pays for an effect, so the effect tables above are the real budget "
             "and the keyword-only rows below are the floor. Ranking is crude (text length), so read the text column.\n")
    L.append("Per tier, the five current-pool minions with the least rules text: vanilla first, then keyword-only, then the shortest effect text. "
             "Historical vanilla and keyword-only minions follow, because the current pool has very few.\n")
    for tier in tiers:
        ms = sorted([m for m in cur if m["tier"] == tier],
                    key=lambda m: ({"vanilla": 0, "keyword_only": 1, "effect": 2}[m["effect_class"]], len(m["text"]), -m["vanilla_stats"]))[:5]
        hs = sorted([m for m in hist_prim if m["tier"] == tier and m["effect_class"] != "effect"],
                    key=lambda m: (-m["last_seen_build"], m["name"]))
        L.append(f"**Tier {tier}**\n")
        rows = [[m["name"], f"{m['attack']}/{m['health']}", m["vanilla_stats"], m["effect_class"], m["text"] or "-"] for m in ms]
        rows += [[f"{m['name']} *(historical, last {m['last_seen_date']})*", f"{m['attack']}/{m['health']}", m["vanilla_stats"], m["effect_class"], m["text"] or "-"] for m in hs]
        L.append(md_table(["Minion", "Stats", "A+H", "Class", "Text"], rows) + "\n")

    L.append("## Keyword frequency per tier (current pool)\n")
    L.append("Counts minions whose `keywords` (from HearthstoneJSON `mechanics`, display noise removed) include the keyword. "
             "A keyword that is only mentioned (e.g. \"give a minion Taunt\") shows up in `referenced_tags`, not here.\n")
    kws = Counter(k for m in cur for k in m["keywords"])
    krow = []
    for k, _ in kws.most_common():
        row = [k] + [sum(1 for m in cur if m["tier"] == t and k in m["keywords"]) for t in tiers]
        row.append(sum(row[1:]))
        krow.append(row)
    L.append(md_table(["Keyword"] + [f"T{t}" for t in tiers] + ["Total"], krow) + "\n")
    L.append("Effect class per tier:\n")
    L.append(md_table(["Tier", "vanilla", "keyword_only", "effect"],
                      [[t] + [sum(1 for m in cur if m["tier"] == t and m["effect_class"] == c) for c in ("vanilla", "keyword_only", "effect")] for t in tiers]) + "\n")

    L.append("## Other card types\n")
    L.append("### Tavern spells (current pool) per tier\n")
    srow = []
    for t in sorted({s["tier"] for s in sp_cur if s["tier"] is not None}):
        ss = [s for s in sp_cur if s["tier"] == t]
        srow.append([t, len(ss), describe([s["cost"] for s in ss])[0], f"{min(s['cost'] for s in ss)}-{max(s['cost'] for s in ss)}"])
    L.append(md_table(["Tier", "Spells", "Mean cost", "Cost range"], srow) + "\n")
    hcur = [h for h in lib["heroes"] if h["in_current_pool"]]
    L.append("### Heroes (currently draftable)\n")
    L.append(f"Armor: mean {describe([h['armor'] for h in hcur if h['armor'] is not None])[0]}, range "
             f"{min(h['armor'] for h in hcur if h['armor'] is not None)}-{max(h['armor'] for h in hcur if h['armor'] is not None)}. "
             f"Hero power cost: {dict(sorted(Counter(h['hero_power_cost'] for h in hcur).items(), key=lambda x: (x[0] is None, x[0] or 0)))} (cost: heroes).\n")

    L.append("## Method\n")
    L.append("1. List builds from the hsdata commit log and the HearthstoneJSON index.")
    L.append("2. Sample builds: by default the last build of every calendar month since Dec 2019, plus the first and the newest build. "
             "`--every-build` diffs every build instead. First-seen and last-seen are therefore accurate to about a month.")
    L.append("3. For each sampled build, read the pool by era:")
    L.append("   - **flag** (Feb 2022 on): `isBattlegroundsPoolMinion` / `isBattlegroundsPoolSpell` / `battlegroundsHero`. Exact.")
    L.append("   - **techlevel** (Nov 2020 - Jan 2022): only pool minions carry `techLevel`, and all of them link a golden. Exact.")
    L.append("   - **heuristic** (Dec 2019 - Oct 2020): `techLevel` is also on tokens and goldens. Pool = `techLevel` minions that are not golden "
             "and not on a curated token list (below). Dates before Dec 2019 have no tier data at all.")
    L.append("4. Each build is reduced to a small snapshot (pool minions with goldens, draftable heroes with hero power, pool spells, and the ids of trinkets, "
             "anomalies, quests, rewards, buddies and spells present). Raw files are deleted after that, except the newest.")
    L.append("5. Current-pool minions take every field from the newest build. Historical minions take their fields from the last sampled build where "
             "they were in the pool (`stats_source_build`), so tier and stats are the ones they held then; their golden link comes from the newest build when the old build had none.")
    L.append("6. Trinkets, anomalies, quests, quest rewards and buddies have no pool flag in the data. Their files list every card of that type in the newest build, "
             "with the first sampled build in which it appeared (`first_in_data_build`), which approximates its release.\n")
    L.append("Era-A cards excluded as tokens or non-pool:\n")
    L.append(", ".join(sorted(ERA_A_NOT_POOL.values())) + ".\n")
    if review_notes:
        L.append("Era-A cards accepted into the pool only by the heuristic (no later exact-era evidence), for review:\n")
        L.append(", ".join(review_notes) + ".\n")

    L.append("## Spot check\n")
    L.append(f"Ten well-known minions compared by hand with their hearthstone.wiki.gg Battlegrounds pages on {WIKI_CHECKED} (normal version). "
             "Tier, stats and pool status must all agree for a match. Pool periods are sampled months, so a removal shows up one sample after the patch.\n")
    srows = []
    for name, (wt, wa, wh, wpool, wnote) in WIKI_SPOTCHECK.items():
        ms = [m for m in minions if m["name"] == name]
        if not ms:
            srows.append([name, "not found", "-", "-", f"T{wt} {wa}/{wh}", wnote, "MISSING"])
            continue
        m = next(m for m in ms if m["lineage_primary"])
        status = "current pool" if m["in_current_pool"] else f"not in pool (last seen {m['lineage_last_seen_date']})"
        ok = (m["tier"], m["attack"], m["health"], m["in_current_pool"]) == (wt, wa, wh, wpool)
        periods_txt = "; ".join(f"{a[1]}..{a[3]}" for x in sorted(ms, key=lambda r: r["first_seen_build"]) for a in x["pool_periods"])
        srows.append([name, f"T{m['tier']} {m['attack']}/{m['health']}", status, periods_txt,
                      f"T{wt} {wa}/{wh}", wnote, "match" if ok else "DIFFERS"])
    L.append(md_table(["Minion", "Data", "Data status", "Sampled pool periods (all reprints)", "Wiki", "Wiki history", "Result"], srows) + "\n")
    L.append(SPOTCHECK_COMMENTARY + "\n")

    L.append("## Known gaps\n")
    for g in KNOWN_GAPS:
        L.append(f"- {g}")
    L.append("")
    DOC_PATH.parent.mkdir(parents=True, exist_ok=True)
    DOC_PATH.write_text("\n".join(L), encoding="utf-8", newline="\n")


SPOTCHECK_COMMENTARY = (
    "All ten agree on tier, stats and pool status, and the sampled pool periods line up with the wiki's removal and return patches. "
    "Six of the ten are no longer in the pool: Alleycat, Scallywag, Murloc Warleader, Cave Hydra, Baron Rivendare (left in Jan 2023, "
    "when Titus Rivendare arrived) and Amalgadon. One detail is unconfirmed: the data drops Kalecgos for the single Aug 2025 sample "
    "(build 226642) and has it back in Sep 2025; the wiki page does not mention that gap. For the heuristic era the wiki confirmed "
    "Whirlwind Tempest (removed in 18.4.2), and its removed-card list includes Zoobot, Shielded Minibot, Mounted Raptor, Annoy-o-Tron, "
    "Psych-o-Tron, Phalanx Commander, Cobalt Guardian, Festeroot Hulk, Tortollan Shellraiser, The Boogeymonster, Menagerie Magician, "
    "Arcane Cannon, Holy Mackerel, Sated Threshadon and Gentle Megasaur."
)
KNOWN_GAPS: list[str] = [
    "**Monthly sampling.** First-seen and last-seen dates are the sampled builds, accurate to about a month. A minion that was in the pool for less "
    "than a month between samples is missing, and a one-sample gap in `pool_periods` can be a real short removal or an odd build. "
    "Run with `--every-build` for patch-level dates.",
    "**Launch month.** Builds before 2019-12-18 (build 38377) export no `techLevel`, so the Nov 2019 launch pool is read from the Dec 2019 build.",
    "**Dec 2019 - Oct 2020 is heuristic.** Pool membership is inferred (see Method); the cards accepted only on that evidence are listed above. "
    "Golden links did not exist before Apr 2020, so golden fields for early-only minions come from the newest build when it still has them.",
    "**Pool means the whole pool.** `isBattlegroundsPoolMinion` covers every tribe; a lobby uses only some tribes. Per-lobby rules "
    "(tribe-restricted minions such as Wrath Weaver needing Demons) are not in the data. Duos-only minions are flagged `duos_exclusive`.",
    "**Reprints.** Classic minions were reissued as `BG_` copies in Aug 2022, and a few others were reprinted; each copy has its own dbfId and row. "
    "Group with the `lineage_*` fields; the all-era tables use `lineage_primary` rows only.",
    "**No pool flag for trinkets, anomalies, quests, quest rewards or buddies.** Those files hold every card of the type in the newest build, "
    "including variants and cards never or no longer offered. `first_in_data_build` is when the card entered the client, which can precede release.",
    "**Heroes.** `battlegroundsHero` history starts in spring 2020. Heroes that are temporarily disabled may still carry the flag. Armor is the "
    "newest build's value (older builds stored an armor tier instead). Only the default hero power is listed; cost 0 is usually a passive.",
    "**Dynamic text.** Quest text shows `0` where the game fills in a number; counters like \"(3 Gold left!)\" are kept as written. "
    "A few minions have display stats that are not their real budget (e.g. The Boommobile 30/30).",
    "**Keywords come from Blizzard's mechanics tags.** A minion that only grants a keyword lists it in `referenced_tags`, not `keywords`; "
    "Cave Hydra's cleave has no tag. `effect_class` is computed from the text, not the tags.",
    "**Timewarp.** `timewarp.json` lists Timewarped minions from the separate Timewarp shop. They are not in the Tavern pool, and their "
    "`tier` is exported as-is; it may not mean the same as a Tavern tier.",
    "**Version labels.** hsdata commit messages occasionally mislabel a patch (build 226642, Aug 2025, is labeled 32.2.2). Build numbers are reliable.",
]


# ---------------------------------------------------------------------- main

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--every-build", action="store_true", help="diff every build instead of one per month")
    ap.add_argument("--refresh", action="store_true", help="re-fetch the build list")
    ap.add_argument("--keep-raw", action="store_true", help="keep raw historical downloads in the cache")
    ap.add_argument("--workers", type=int, default=4, help="parallel downloads (default 4)")
    args = ap.parse_args(argv)

    CACHE.mkdir(parents=True, exist_ok=True)
    builds = fetch_build_list(args.refresh)
    sample = choose_sample(builds, args.every_build)
    latest = sample[-1]
    log(f"{len(builds)} builds known; sampling {len(sample)}; newest {latest} ({builds[latest]})")

    def work(b):
        return get_slim(b, keep_raw=args.keep_raw or b == latest)

    with concurrent.futures.ThreadPoolExecutor(args.workers) as ex:
        slims = [s for s in ex.map(work, sample) if s]
    slims.sort(key=lambda s: s["build"])
    sample = [s["build"] for s in slims if s["era"] != "none"]
    slims = [s for s in slims if s["era"] != "none"]
    latest_cards = load_raw(latest)

    lib = assemble(latest_cards, latest, slims, sample, builds)

    # Heuristic-only pool members: seen in era A but never in an exact era.
    exact_ids = {int(k) for s in slims if s["era"] in ("flag", "techlevel") for k in s["pool"]}
    review = sorted(f"{m['name']} ({m['id']})" for m in lib["minions"] if m["pool_evidence"] == ["heuristic"] and m["dbfId"] not in exact_ids)

    meta = {
        "generated": dt.date.today().isoformat(),
        "source": "HearthstoneJSON cards.json (enUS)",
        "latest_build": latest, "latest_version": builds[latest].get("version"),
        "latest_date": builds[latest].get("date"),
        "sampled_builds": len(sample), "sample_mode": "every build" if args.every_build else "last build of each month",
        "first_sample_build": sample[0], "first_sample_date": builds[sample[0]].get("date"),
        "eras": {s["build"]: s["era"] for s in slims},
        "builds": {b: builds[b] for b in sample},
        "script": "tools/research/build_bg_library.py",
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    short_meta = {k: v for k, v in meta.items() if k not in ("eras", "builds")}
    for name, key in [("minions", "minions"), ("timewarp", "timewarp"), ("spells", "spells"),
                      ("trinkets", "trinkets"), ("anomalies", "anomalies"), ("heroes", "heroes"),
                      ("buddies", "buddies")]:
        write_json(OUT_DIR / f"{name}.json", {"meta": short_meta, "cards": lib[key]})
    write_json(OUT_DIR / "quests.json", {"meta": short_meta, "quests": lib["quests"], "rewards": lib["quest_rewards"]})
    write_json(OUT_DIR / "builds.json", {"meta": short_meta, "sampled_builds": [
        {"build": b, **builds[b], "era": meta["eras"][b], "pool_minions": len(next(s for s in slims if s["build"] == b)["pool"])}
        for b in sample]})
    write_csv(OUT_DIR / "minions.csv", lib["minions"])
    write_doc(lib, meta, review)
    log(f"minions {len(lib['minions'])} (current {sum(m['in_current_pool'] for m in lib['minions'])}), "
        f"heroes {len(lib['heroes'])}, spells {len(lib['spells'])}, trinkets {len(lib['trinkets'])}, "
        f"anomalies {len(lib['anomalies'])}, quests {len(lib['quests'])}/{len(lib['quest_rewards'])}, "
        f"buddies {len(lib['buddies'])}, timewarp {len(lib['timewarp'])}")
    if review:
        log("heuristic-only pool members (review):", ", ".join(review))


if __name__ == "__main__":
    main()
