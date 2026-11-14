#!/usr/bin/env python3
"""Build each seed's designer brief from its three parts.

Usage: assemble_briefs.py [RUN_DIR]
For every seeds/<seed>.json, writes seeds/<seed>.BRIEF.md from:
  Part A  seeds/_A.<seed>.md   (the seed; starts with "## Part A")
  Part B  seeds/_PART-B.md     (how Bramble plays; shared)
  Part C  docs/design/tier-guide.md, Parts 1 and 2, unchanged
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INTRO_C = ("A short guide to what each tier is for and roughly how much a unit there gives. "
           "It was built from 310 Battlegrounds units valued by role and by stats added per turn. "
           "It's a guide, not a limit: a unit can break it if that makes the tribe more fun and you say why.")


def part_c():
    text = (ROOT / "docs/design/tier-guide.md").read_text()
    body = text[text.index("## Part 1:"):text.index("## Where the numbers come from")].rstrip()
    return "## Part C: tier guide\n\n" + INTRO_C + "\n\n" + re.sub(r"(?m)^## ", "### ", body) + "\n"


def main():
    run = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "docs/design/tribe-run/run"
    seeds = run / "seeds"
    b, c, n = (seeds / "_PART-B.md").read_text().strip(), part_c(), 0
    for sp in sorted(seeds.glob("*.json")):
        if sp.name.startswith("_"):
            continue
        s = json.loads(sp.read_text())
        ap = seeds / f"_A.{s['id']}.md"
        if not ap.exists():
            print("no Part A yet:", s["id"])
            continue
        head = (f"# Designer Brief: {s['name']}\n\nYour task is to design a complete new Bramble tribe from this seed: "
                f"**{s['name']}**. This brief has three parts: the seed, how Bramble plays, and a tier guide.\n")
        (seeds / f"{s['id']}.BRIEF.md").write_text("\n\n---\n\n".join([head.strip(), ap.read_text().strip(), b, c.strip()]) + "\n")
        n += 1
    print(n, "brief(s) written")


if __name__ == "__main__":
    main()
