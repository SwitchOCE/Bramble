#!/usr/bin/env python3
"""Words per card: Battlegrounds, Galaxy and Bramble, counted the same way.

    python3 tools/research/word_counts.py            # the working tree
    python3 tools/research/word_counts.py --ref REF  # Bramble's cards at a git ref as well

A word is a run of letters, digits and + / ( ) ' -, so "+1/+1" is one word. Bramble counts the
`text` of every content/units, content/spells and content/heroes file that has any text; "pool"
counts only units and spells offered in shops, plus heroes. Golden text is counted separately.
"""

import argparse
import json
import re
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / "docs" / "research"


def words(text: str) -> int:
    return len(re.findall(r"[A-Za-z0-9'+/()-]+", text or ""))


def stats(counts: list[int]) -> dict:
    counts = sorted(counts)
    n = len(counts)
    return {
        "n": n,
        "median": statistics.median(counts),
        "p90": counts[int(0.9 * (n - 1))],
        "max": counts[-1],
    }


def battlegrounds() -> dict:
    data = RESEARCH / "battlegrounds" / "data"
    minions = [c for c in json.loads((data / "minions.json").read_text())["cards"] if c.get("in_current_pool")]
    spells = [c for c in json.loads((data / "spells.json").read_text())["cards"] if c.get("in_current_pool")]
    heroes = [c for c in json.loads((data / "heroes.json").read_text())["cards"] if c.get("in_current_pool")]
    galaxy_raw = json.loads((RESEARCH / "galaxy" / "data" / "cards.json").read_text())
    galaxy = galaxy_raw if isinstance(galaxy_raw, list) else next(v for k, v in galaxy_raw.items() if k != "meta")
    galaxy = [c for c in galaxy if c.get("status") == "current" and not c.get("token")]
    return {
        "BG minions": stats([words(c["text"]) for c in minions if c["text"]]),
        "BG Tavern spells": stats([words(c["text"]) for c in spells if c["text"]]),
        "BG hero powers": stats([words(c["hero_power_text"]) for c in heroes if c.get("hero_power_text")]),
        "Galaxy cards": stats([words(c["text"]) for c in galaxy if c.get("text")]),
    }


def bramble_files(ref: str | None) -> list[tuple[str, dict]]:
    out = []
    if ref is None:
        for kind in ("units", "spells", "heroes"):
            for path in sorted((ROOT / "content" / kind).glob("*.json")):
                out.append((kind, json.loads(path.read_text())))
        return out
    listing = subprocess.run(
        ["git", "ls-tree", "--name-only", ref, "content/units/", "content/spells/", "content/heroes/"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout.split()
    for name in sorted(listing):
        if name.endswith(".json"):
            blob = subprocess.run(["git", "show", f"{ref}:{name}"], cwd=ROOT, capture_output=True, text=True, check=True)
            out.append((name.split("/")[1], json.loads(blob.stdout)))
    return out


def bramble(ref: str | None) -> dict:
    files = bramble_files(ref)
    cards = [(k, d) for k, d in files if d.get("text")]
    pool = [(k, d) for k, d in cards if k == "heroes" or d.get("pool", False) and not d.get("sample")]
    golden = [d for k, d in cards if k == "units" and d.get("golden_text")]
    return {
        "all cards": stats([words(d["text"]) for _, d in cards]),
        "pool cards": stats([words(d["text"]) for _, d in pool]),
        "units": stats([words(d["text"]) for k, d in cards if k == "units"]),
        "spells": stats([words(d["text"]) for k, d in cards if k == "spells"]),
        "heroes": stats([words(d["text"]) for k, d in cards if k == "heroes"]),
        "golden text": stats([words(d["golden_text"]) for d in golden]),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref", help="also count Bramble's cards at this git ref")
    args = parser.parse_args()
    rows = battlegrounds()
    if args.ref:
        rows |= {f"Bramble {k} ({args.ref})": v for k, v in bramble(args.ref).items()}
    rows |= {f"Bramble {k} (now)": v for k, v in bramble(None).items()}
    print("| Set | Cards | Median | p90 | Max |")
    print("|---|---|---|---|---|")
    for name, s in rows.items():
        print(f"| {name} | {s['n']} | {s['median']:g} | {s['p90']} | {s['max']} |")


if __name__ == "__main__":
    main()
