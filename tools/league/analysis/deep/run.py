#!/usr/bin/env python3
"""Deep balance analytics for one match folder.

    python3 run.py MATCH [--out-dir DIR] [--no-records]

Writes DIR/{meta,tempo,cards,fights,synergy}.json and DIR/deep.md, where DIR
defaults to MATCH/deep. See README.md for every table."""
import argparse
from pathlib import Path
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common  # noqa: E402
from common import SCOPES, load, write_json, write_text, fmt, THIN_COUNT, THIN_PAIRS  # noqa: E402
import cardplay  # noqa: E402
import fights  # noqa: E402
import synergy  # noqa: E402
import tempo  # noqa: E402

MODULES = (("tempo", tempo), ("cards", cardplay), ("fights", fights), ("synergy", synergy))


def tribe_section(deep, conv):
    L = ["## Final tribes: winners or placers", "",
         "Win given top four = share of top-four finishes that were wins (even = 25%). "
         "Final tribe is the last board's main tribe, so a tribe bots move into when already winning looks better "
         "than it is.", "",
         "| Seats | Final tribe | Seats | Avg place | Win | Top four | Win given top four |",
         "|---|---|---|---|---|---|---|"]
    for scope in SCOPES:
        for tribe in (*deep.tribes, common.NONE):
            place = tempo.lookup(conv, "place", scope=scope, final_tribe=tribe)
            if not place:
                continue
            L.append(f"| {scope} | {tribe} | {place['count']} | {fmt(place)} | " + " | ".join(
                fmt(tempo.lookup(conv, m, scope=scope, final_tribe=tribe)) for m in ("win", "top4", "win_given_top4")) + " |")
    return "\n".join(L)


def run(match_dir, out_dir=None, records=True):
    started = time.time()
    deep = load(match_dir, records=records)
    loaded = time.time() - started
    out = Path(out_dir) if out_dir else Path(match_dir) / "deep"
    s = deep.match.summary
    meta = {"match": str(match_dir), "games": s["games"], "seed_pairs": (s["games"] + 1) // 2,
            "red": s["red"], "blue": s["blue"], "red_label": s.get("red_label", s["red"]),
            "blue_label": s.get("blue_label", s["blue"]), "red_avg_place": s["red_avg_place"],
            "blue_avg_place": s["blue_avg_place"], "rules_hash": s.get("rules_hash"),
            "coverage": deep.coverage, "thin_below": {"count": THIN_COUNT, "pairs": THIN_PAIRS},
            "tribes": deep.tribes}
    results, md = {}, []
    for name, module in MODULES:
        results[name] = module.analyse(deep)
        write_json(out, name, results[name])
        md.append(module.markdown(deep, results[name]))
    md.insert(1, tribe_section(deep, results["tempo"]["conversion"]))
    meta["seconds"] = {"load": round(loaded, 1), "total": round(time.time() - started, 1)}
    write_json(out, "meta", meta)
    head = [f"# Deep analysis: {meta['red_label']} (red) vs {meta['blue_label']} (blue)", "",
            f"{meta['games']} games, {meta['seed_pairs']} seed pairs. Red averages {s['red_avg_place']:.2f}, "
            f"blue {s['blue_avg_place']:.2f}. Intervals are 95% over seed pairs; ⚠thin marks fewer than "
            f"{THIN_COUNT} observations or {THIN_PAIRS} pairs. Logs read: "
            + ", ".join(k for k, v in deep.coverage.items() if v) + ". "
            "With two bots, a pattern can be one bot's habit rather than the game's balance; "
            "each table says which seats it covers.", ""]
    write_text(out, "deep.md", "\n".join(head) + "\n" + "\n\n".join(md))
    return out, meta


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("match", type=Path)
    p.add_argument("--out-dir", type=Path)
    p.add_argument("--no-records", action="store_true", help="skip unit tenure from replay records")
    a = p.parse_args()
    out, meta = run(a.match, a.out_dir, records=not a.no_records)
    print(f"wrote {out} in {meta['seconds']['total']} s")


if __name__ == "__main__":
    main()
