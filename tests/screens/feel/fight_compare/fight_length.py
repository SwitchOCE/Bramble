#!/usr/bin/env python3
"""Summarise fight_length.gd's lengths.json: today against best and each variant.

    python3 tests/screens/feel/fight_compare/fight_length.py /data/fight-anim-work/fight-length

Prints markdown tables (seconds at 60 fps): the median, 90th percentile and longest fight to the
result, for today, best, best without rule 7, each contested option and the what-ifs; where the
time goes; the longest attack cycles; a Battlegrounds model from the measured cycle numbers
(docs/workstreams/fight-animation-24-nov/research/battlegrounds.md); and what-ifs computed from
best's own schedule (a fight-wide speed-up after N attacks, a uniform speed toggle).
Writes <dir>/summary.json with the same numbers.
"""

import json
import statistics
import sys
from pathlib import Path

FPS = 60.0
KINDS = ["start", "attack", "trigger", "change", "death", "summon", "wait", "end"]
# Battlegrounds, measured (battlegrounds.md): a plain attack's cycle 76-83 f, with a death
# 150-165 f, sped up late in long 2026 fights 34-50 f.
BG_PLAIN = 80
BG_BUSY = 157
BG_FAST = 40


def pct(values, p):
    """The p-th percentile, nearest rank."""
    ordered = sorted(values)
    k = max(0, min(len(ordered) - 1, round(p / 100 * len(ordered) + 0.5) - 1))
    return ordered[k]


def stats(frames):
    return {
        "median": statistics.median(frames) / FPS,
        "p90": pct(frames, 90) / FPS,
        "max": max(frames) / FPS,
        "mean": statistics.mean(frames) / FPS,
    }


def row(name, s, base=None):
    cells = [name, f"{s['median']:.1f}", f"{s['p90']:.1f}", f"{s['max']:.1f}"]
    if base:
        cells.append(f"{100 * (s['median'] / base['median'] - 1):+.0f} %")
    return "| " + " | ".join(cells) + " |"


def attack_flags(events):
    """Per attack: whether anything died or triggered before the next attack."""
    flags = []
    for event in events:
        kind = event.get("type")
        if kind == "attack":
            flags.append(False)
        elif flags and kind in ("death", "trigger"):
            flags[-1] = True
    return flags


def main(folder):
    data = json.loads((folder / "lengths.json").read_text())
    fights = data["fights"]
    names = list(fights[0]["variants"].keys())
    out = {"fights": len(fights)}

    def lengths(name, key="result"):
        if name == "today":
            return [f["today"][key] for f in fights]
        return [f["variants"][name][key] for f in fights]

    today = stats(lengths("today"))
    out["today"] = today
    print(f"## {len(fights)} fights, rounds {sorted({f['round'] for f in fights})}\n")
    counts = {
        k: statistics.median([f[k] for f in fights])
        for k in ["attacks", "triggers", "deaths", "summons", "damages", "events"]
    }
    print("Median per fight: " + ", ".join(f"{k} {v:g}" for k, v in counts.items()) + "\n")
    out["counts"] = counts

    print("## To the result (s)\n")
    print("| Variant | Median | 90th pct | Longest | Median vs today |")
    print("|---|---|---|---|---|")
    print(row("today", today))
    out["variants"] = {}
    for name in names:
        s = stats(lengths(name))
        out["variants"][name] = s
        print(row(name, s, today))
    print("\nWith the result hold (today 1.5 s, best 90 f): add 1.5 s to every row.\n")

    for subset, pick in [
        ("busiest third (most triggers)", lambda f, cut: f["triggers"] >= cut),
        ("quietest third (fewest triggers)", lambda f, cut: f["triggers"] <= cut),
    ]:
        tr = sorted(f["triggers"] for f in fights)
        cut = tr[2 * len(tr) // 3] if "busiest" in subset else tr[len(tr) // 3]
        chosen = [f for f in fights if pick(f, cut)]
        t = stats([f["today"]["result"] for f in chosen])
        b = stats([f["variants"]["best"]["result"] for f in chosen])
        print(
            f"{subset} ({len(chosen)} fights, triggers {'>=' if 'busiest' in subset else '<='} "
            f"{cut}): today median {t['median']:.1f} s, best {b['median']:.1f} s\n"
        )

    for r in sorted({f["round"] for f in fights}):
        chosen = [f for f in fights if f["round"] == r]
        t = stats([f["today"]["result"] for f in chosen])
        b = stats([f["variants"]["best"]["result"] for f in chosen])
        print(
            f"- round {r}: today median {t['median']:.1f} s (p90 {t['p90']:.1f}), "
            f"best {b['median']:.1f} s (p90 {b['p90']:.1f})"
        )
    print()

    print("## Where the time goes (mean seconds per fight, to the result)\n")
    print("| Kind | today | best | best_no7 |")
    print("|---|---|---|---|")
    out["kinds"] = {}
    for kind in KINDS:
        vals = []
        for name in ["today", "best", "best_no7"]:
            src = [f["today"] if name == "today" else f["variants"][name] for f in fights]
            vals.append(statistics.mean(s["kinds"].get(kind, 0) for s in src) / FPS)
        out["kinds"][kind] = vals
        print(f"| {kind} | " + " | ".join(f"{v:.1f}" for v in vals) + " |")
    print()

    print("## Attack cycles (first motion to the next attacker's first motion, s)\n")
    print("| | today | best | best_no7 |")
    print("|---|---|---|---|")
    longest = {}
    for name in ["today", "best", "best_no7"]:
        src = [(f, f["today"] if name == "today" else f["variants"][name]) for f in fights]
        cycles = [(c["frames"], f["name"], c.get("attacker", ""), i) for f, s in src for i, c in enumerate(s["cycles"])]
        per_fight = [max(c["frames"] for c in s["cycles"]) for _, s in src if s["cycles"]]
        allc = [c[0] for c in cycles]
        longest[name] = {
            "median_cycle": statistics.median(allc) / FPS,
            "p90_cycle": pct(allc, 90) / FPS,
            "median_longest_in_fight": statistics.median(per_fight) / FPS,
            "longest": max(cycles),
        }
    out["cycles"] = {k: {**v, "longest": list(v["longest"])} for k, v in longest.items()}
    for label, key in [
        ("median cycle", "median_cycle"),
        ("90th pct cycle", "p90_cycle"),
        ("median of each fight's longest", "median_longest_in_fight"),
    ]:
        print(f"| {label} | " + " | ".join(f"{longest[n][key]:.2f}" for n in longest) + " |")
    print(
        "| longest anywhere | "
        + " | ".join(
            f"{longest[n]['longest'][0] / FPS:.1f} ({longest[n]['longest'][1]} #{longest[n]['longest'][3]}, "
            f"{longest[n]['longest'][2]})"
            for n in longest
        )
        + " |\n"
    )

    # Battlegrounds model: each of our attacks at Battlegrounds' measured cycle
    print("## Battlegrounds model (our fights' attacks at Battlegrounds' measured cycles)\n")
    bg, bg_fast = [], []
    for f in fights:
        log = json.loads((folder / "fights" / f"{f['name']}.json").read_text())["events"]
        flags = attack_flags(log)
        bg.append(sum(BG_BUSY if x else BG_PLAIN for x in flags))
        bg_fast.append(len(flags) * BG_FAST)
    busy_share = statistics.mean(
        statistics.mean(
            attack_flags(json.loads((folder / "fights" / f"{f['name']}.json").read_text())["events"]) or [0]
        )
        for f in fights
    )
    out["bg_model"] = {"normal": stats(bg), "sped_up": stats(bg_fast), "busy_share": busy_share}
    print(f"Attacks with a death or trigger before the next attack: {100 * busy_share:.0f} %.\n")
    print("| Model | Median | 90th pct | Longest |")
    print("|---|---|---|---|")
    print(row(f"Battlegrounds normal ({BG_PLAIN} f plain, {BG_BUSY} f with a death or trigger)", stats(bg)))
    print(
        row(
            "Battlegrounds normal, at its long-fight 2x (T4: the whole fight about twice as fast)",
            stats([x / 2 for x in bg]),
        )
    )
    print(row(f"Battlegrounds sped up, attacks only ({BG_FAST} f every attack, no chains)", stats(bg_fast)))
    print()

    # what-ifs on best's own schedule: the whole fight played faster from an attack on (every
    # frame of each attack cycle divided by that cycle's speed), as Battlegrounds 31.6 does
    # ("combat animations will now accelerate as the battle rages on and then slow down towards
    # the end"). An upper bound: floors (lift 6, hold 9, falls 10) would keep some frames.
    def ramped(s, first, full, top, last_normal):
        cyc = s["cycles"]
        if not cyc:
            return s["result"]
        total = cyc[0]["from"]
        for i, c in enumerate(cyc):
            if i < first:
                speed = 1.0
            elif i >= full:
                speed = top
            else:
                speed = 1.0 + (top - 1.0) * (i - first + 1) / (full - first + 1)
            if last_normal and i == len(cyc) - 1:
                speed = 1.0
            total += c["frames"] / speed
        return total + (s["result"] - cyc[-1]["from"] - cyc[-1]["frames"])

    print("## What-ifs (to the result, s)\n")
    print(
        "Speed-ups after N attacks are computed from each variant's own schedule: every frame "
        "of an attack cycle divided by that cycle's speed (an upper bound on the saving).\n"
    )
    print("| What-if | Median | 90th pct | Longest | Median vs today |")
    print("|---|---|---|---|---|")
    out["what_ifs"] = {}

    def show(name, vals):
        out["what_ifs"][name] = stats(vals)
        print(row(name, stats(vals), today))

    for base_name in [n for n in ["best", "G3-R7-early_x2"] if n in names]:
        for first, full, top, last_normal, label in [
            (4, 4, 1.5, False, "x1.5 from attack 5"),
            (4, 4, 2.0, False, "x2 from attack 5"),
            (2, 2, 1.5, False, "x1.5 from attack 3"),
            (2, 2, 2.0, False, "x2 from attack 3"),
            (2, 6, 2.0, True, "rising x1 to x2 over attacks 3-7, last attack x1"),
            (1, 5, 2.0, True, "rising x1 to x2 over attacks 2-6, last attack x1"),
        ]:
            show(
                f"{base_name}: {label}",
                [ramped(f["variants"][base_name], first, full, top, last_normal) for f in fights],
            )
    for k in [1.5, 2.0]:
        for base_name in ["today", "best"]:
            show(f"{base_name}: a speed toggle x{k:g}", [x / k for x in lengths(base_name)])
    print()
    (folder / "summary.json").write_text(json.dumps(out, indent=1))


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "/data/fight-anim-work/fight-length"))
