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
from common import SCOPES, load, write_json, write_text, fmt, team_tag, code_stamp, THIN_COUNT, THIN_PAIRS  # noqa: E402
import cardplay  # noqa: E402
import fights  # noqa: E402
import synergy  # noqa: E402
import tempo  # noqa: E402

MODULES = (("tempo", tempo), ("cards", cardplay), ("fights", fights), ("synergy", synergy))


def tribe_section(deep, data):
    conv = data["conversion"]
    L = ["## Final tribes, within each team", "",
         "Each team's own seats by final main tribe. Read tribes **within a team**: a pooled row mixes the two "
         "bots' strength into the tribe (a tribe one strong bot plays looks strong). Final tribe is the last "
         "board's main tribe, so a tribe bots move into when already winning looks better than it is. "
         "Win given top four: yardstick 25% (see Tempo).", "",
         "| Team | Final tribe | Seats | Avg place | Seat win | Top four | Win given top four |",
         "|---|---|---|---|---|---|---|"]
    for scope in common.TEAMS:
        for tribe in (*deep.tribes, common.NONE):
            place = tempo.lookup(conv, "place", scope=scope, final_tribe=tribe)
            if not place:
                continue
            L.append(f"| {scope} | {tribe} | {place['count']} | {fmt(place)} | " + " | ".join(
                fmt(tempo.lookup(conv, m, scope=scope, final_tribe=tribe)) for m in ("win", "top4", "win_given_top4")) + " |")
    L += ["", "Worst minus best tribe within each team (tribes with 30+ seats; places, same seed pairs; picking the "
          "extremes after looking inflates the gap a little):", ""]
    for g in data["tribe_gap_within_team"]:
        if g["gap"]:
            L.append(f"- {g['scope']}: {g['worst']} minus {g['best']} = {fmt(g['gap'], False)} over {g['tribes']} tribes")
        else:
            L.append(f"- {g['scope']}: fewer than two tribes with 30+ seats")
    L += ["", "*Pooled, for reference only* (mixes team strength; `red` = red seats' share of the sample):", "",
          "| Final tribe | Seats | Red share | Avg place | Win given top four |", "|---|---|---|---|---|"]
    for tribe in (*deep.tribes, common.NONE):
        place = tempo.lookup(conv, "place", scope="both", final_tribe=tribe)
        if place:
            L.append(f"| {tribe} | {place['count']} | {team_tag(place).strip()} | {fmt(place)} | "
                     f"{fmt(tempo.lookup(conv, 'win_given_top4', scope='both', final_tribe=tribe))} |")
    return "\n".join(L)


def run(match_dir, out_dir=None, records=True, events=True):
    started = time.time()
    deep = load(match_dir, records=records, events=events)
    loaded = time.time() - started
    out = Path(out_dir) if out_dir else Path(match_dir) / "deep"
    s = deep.match.summary
    meta = {"match": str(match_dir), "games": s["games"], "seed_pairs": (s["games"] + 1) // 2,
            "red": s["red"], "blue": s["blue"], "red_label": s.get("red_label", s["red"]),
            "blue_label": s.get("blue_label", s["blue"]), "red_avg_place": s["red_avg_place"],
            "blue_avg_place": s["blue_avg_place"], "rules_hash": s.get("rules_hash"),
            "coverage": deep.coverage, "thin_below": {"count": THIN_COUNT, "pairs": THIN_PAIRS},
            "tribes": deep.tribes, "code": code_stamp()}
    results, md = {}, []
    for name, module in MODULES:
        results[name] = module.analyse(deep)
        write_json(out, name, results[name])
        md.append(module.markdown(deep, results[name]))
    md.insert(1, tribe_section(deep, results["tempo"]))
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
    p.add_argument("--no-events", action="store_true", help="ignore events.jsonl.gz (fall back to the guesses)")
    a = p.parse_args()
    out, meta = run(a.match, a.out_dir, records=not a.no_records, events=not a.no_events)
    print(f"wrote {out} in {meta['seconds']['total']} s")


if __name__ == "__main__":
    main()
