#!/usr/bin/env python3
"""Films, measures and cuts CB14, how a stat gain shows (buff-look/DESIGN.md), from the `buffs`
treatment (buffs.gd) on Old Brock's six gains in moment (e). Beside clips.py, which it borrows
from; it leaves compare/manifest.json alone (its entry is compare/CB14.json, in a manifest
branch's shape).

Usage:
  buff_clips.py scenarios OUT_DIR            one scenario JSON per film (today, best, cb14-a/b/c)
  buff_clips.py measure STEM [STEM...]       STEM.buffs.json: the beats read off the log, and each
                                             check against DESIGN.md's beats, pass or fail
  buff_clips.py compare FILM_DIR OUT_DIR [SCALE]  OUT_DIR/CB14/<option>.mp4 and OUT_DIR/CB14.json
  buff_clips.py cut FILM_DIR CLIP_DIR        CLIP_DIR/CB14.mp4, the options side by side

Every clip is lined up on G, the first frame Old Brock's drawn numbers change in moment (e) (his
first gain; today's only change). Films are made with tools/feel/film from the scenarios.
Exploratory: nothing here is the game.
"""

import contextlib
import csv
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import itertools

import clips

FPS = 60
# your board (both rows) with Old Brock's tags over it, in film pixels; x, y, w, h
CROP = (630, 520, 660, 550)
SCALE = 0.6
BROCK = "old-brock"
# film -> (treatment, options)
FILMS = {
    "today": ("today", {}),
    "best": ("best", {}),
    "cb14-a": ("buffs", {"CB14": "a"}),
    "cb14-b": ("buffs", {"CB14": "b"}),
    "cb14-c": ("buffs", {"CB14": "c"}),
}
OPTIONS = [
    ("today", "today", "Today: 10/9 to 24/33 in one frame"),
    ("best", "best", "Best proposal as it is (retimed only)"),
    ("a", "cb14-a", "A: swell and count"),
    ("b", "cb14-b", "B: A plus a running +N tag"),
    ("c", "cb14-c", "C: B, tags fly from the dead slots"),
]
TITLE = "CB14 a stat gain: Old Brock's six gains in moment (e)"
WHAT = "(e) six of yours die; Old Brock gains six times"
WAIT = 14.5
# the window round G, every option the same
BEFORE = 50
AFTER = 100

# DESIGN.md section 2, Brock x6: beat starts after F (the six falls' end)
STARTS = [0, 18, 32, 42, 50, 56]
LAND_AB = 6
LAND_C = 10
GAINS = [(2, 5), (3, 5), (2, 2), (2, 5), (3, 5), (2, 2)]
FROM = (10, 9)
TO = (24, 33)
TOTALS = [(2, 5), (5, 10), (7, 12), (9, 17), (12, 22), (14, 24)]
H = 250.0
# a flare row counts for a landing when it is this close after it
FLARE_MAX = 20


def read_csv(path: Path) -> list:
    if not path.exists():
        return []
    with path.open() as f:
        return list(csv.DictReader(f))


def cmd_scenarios(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (treatment, options) in FILMS.items():
        scenario = {
            "scene": clips.SCENE,
            "treatment": treatment,
            "options": options,
            "steps": [{"move": "1900,1000", "time": 0.0}, {"wait": WAIT}],
        }
        (out_dir / f"{name}.json").write_text(json.dumps(scenario, indent=2) + "\n")
        print(name, treatment, json.dumps(options))


# ---- measuring ----


def brock_key(cards: list) -> str:
    for row in cards:
        if row["card_id"] == BROCK:
            return row["key"]
    raise ValueError("no Old Brock in the log")


def friends_out(markers: list, cards: list, brock: str) -> list:
    """Moment (e)'s six falls: [(key, frame)] of your units leaving together, the last batch of
    card_out rows on side 0 before Old Brock's last attack."""
    side = {row["key"]: row["side"] for row in cards if row["card_id"] != "burst"}
    outs = [(m["key"], int(m["frame"])) for m in markers if m["marker"] == "card_out" and side.get(m["key"]) == "0"]
    outs = [o for o in outs if o[0] != brock]
    return outs[-6:]


def first_gain(markers: list, brock: str, after: int) -> int:
    for m in markers:
        if m["marker"] == "numbers" and m["key"] == brock and int(m["frame"]) > after:
            a, b = m["detail"].split(" -> ")
            was, now = [tuple(int(v) for v in s.split("/")) for s in (a, b)]
            if now[0] > was[0] or now[1] > was[1]:
                return int(m["frame"])
    raise ValueError("no gain on Old Brock")


def measure(stem: Path) -> dict:
    report = json.loads(stem.with_suffix(".report.json").read_text())
    cards = [r for r in read_csv(stem.with_suffix(".cards.csv")) if r["card_id"] != "burst"]
    markers = read_csv(stem.with_suffix(".markers.csv"))
    rows = read_csv(stem.with_suffix(".buffs.csv"))
    brock = brock_key(cards)
    outs = friends_out(markers, cards, brock)
    out_at = min(f for _, f in outs)
    # G: the first gain's landing (a CB14 option), else the first rise of his drawn numbers
    landed = [
        int(m["frame"])
        for m in markers
        if m["marker"] == "gain_land" and m["key"] == brock and int(m["frame"]) > out_at - 30
    ]
    g = landed[0] if landed else first_gain(markers, brock, out_at - 30)
    plan = report.get("plan") or {}
    offset = plan.get("frame_offset", 0) if plan else 0
    option = (plan.get("options") or {}).get("CB14", "none") if plan else "today"
    by = {}
    for row in cards:
        if row["key"] == brock:
            by[int(row["frame"])] = row
    last_frame = max(by)
    attacks = plan.get("attacks", []) if plan else []
    next_lift = attacks[6]["lift"] + offset if len(attacks) > 6 else g + 30
    # Old Brock's drawn numbers from G to the window's end
    window = [f for f in sorted(by) if g - 1 <= f <= g + AFTER]
    numbers = [(f, int(by[f]["attack"]), int(by[f]["health"])) for f in window]
    # every rise of his drawn numbers (a later fall, Thorns on his own attack, is not a gain)
    changes = [
        (f, a, h)
        for (f, a, h), (_, a0, h0) in zip(numbers[1:], numbers[:-1], strict=False)
        if (a, h) != (a0, h0) and a >= a0 and h >= h0
    ]
    out = {
        "film": stem.name,
        "option": option,
        "brock": brock,
        "frame_offset": offset,
        "G": g,
        "friends_out": outs,
        "numbers_before": [int(by[g - 1]["attack"]), int(by[g - 1]["health"])],
        "numbers_after": [max(a for _, a, _ in numbers), max(h for _, _, h in numbers)],
        "number_changes": len(changes),
        "number_frames": [f - g for f, _, _ in changes],
        # Old Brock's own scale from before G to his next lift (attack 6)
        "card_scale_max": max(float(by[f]["scale"]) for f in window if f < next_lift),
        "core_matches": report.get("core_matches"),
        "victory_s": round(report.get("result_at", -1), 2),
        "last_frame": last_frame,
    }
    gains = [m for m in markers if m["marker"] == "gain_land" and m["key"] == brock]
    if not gains:
        return out
    # moment (e)'s run: the last six landings
    run_id = gains[-1]["detail"].split()[1]
    run = [m for m in gains if m["detail"].split()[1] == run_id]
    lands = [int(m["frame"]) for m in run]
    runs = (plan.get("buffs") or {}).get("runs", [])
    start = next(r for r in runs if str(r["run"]) == run_id)["start"] + offset
    out["F"] = start
    out["next_lift_after_F"] = next_lift - start
    out["lands_after_F"] = [x - start for x in lands]
    out["lands_after_G"] = [x - g for x in lands]
    discs = {}
    for row in rows:
        if row["key"] == brock and row["what"] == "disc":
            discs.setdefault(row["stat"], {})[int(row["frame"])] = row
    out["disc_keys"] = sorted({row["key"] for row in rows if row["what"] == "disc"})
    per = []
    for k, land in enumerate(lands):
        nxt = lands[k + 1] if k + 1 < len(lands) else None
        entry = {"k": k, "L": land - g}
        for stat in ("attack", "health"):
            d = discs.get(stat, {})
            entry[stat] = {
                "scale_L_to_L2": [round(float(d[f]["scale"]), 3) for f in range(land, land + 3) if f in d],
                "scale_L13": round(float(d[land + 13]["scale"]), 3)
                if land + 13 in d and (nxt is None or land + 13 < nxt)
                else None,
                "rest_at": next((f - land for f in range(land, land + 30) if f not in d), None)
                if nxt is None or nxt - land > 14
                else None,
                "value_L": int(d[land]["value"]) if land in d else None,
                "value_L8": int(d[land + 8]["value"]) if land + 8 in d and (nxt is None or land + 8 < nxt) else None,
            }
        per.append(entry)
    out["per_gain"] = per
    # every disc value drawn over the run, in order: a count never goes down
    for stat in ("attack", "health"):
        d = discs.get(stat, {})
        values = [int(d[f]["value"]) for f in sorted(d) if lands[0] <= f]
        out[f"{stat}_values_monotone"] = all(b >= a for a, b in itertools.pairwise(values))
        out[f"{stat}_distinct_values"] = len(set(values))
    out["settled_after_F"] = max(max(d) for d in discs.values()) + 1 - start if discs else None
    tags = {}
    flights = {}
    flares = {}
    for row in rows:
        if row["key"] != brock:
            continue
        f = int(row["frame"])
        if row["what"] == "tag":
            tags.setdefault(row["stat"], {})[f] = row
        elif row["what"] == "flight":
            flights.setdefault(row["stat"], []).append(row)
        elif row["what"] == "flare":
            flares.setdefault(row["stat"], []).append((f, int(row["value"])))
    if tags:
        t = {}
        for stat, d in tags.items():
            frames = sorted(f for f in d if f >= lands[0] - 10)
            first = frames[0]
            t[stat] = {
                "appear": first - lands[0],
                "appear_scale": round(float(d[first]["scale"]), 3),
                "scale_L0_2": round(float(d[lands[0] + 2]["scale"]), 3) if lands[0] + 2 in d else None,
                "scale_L0_6": round(float(d[lands[0] + 6]["scale"]), 3) if lands[0] + 6 in d else None,
                "texts_at_L": [d[x]["text"] for x in lands if x in d],
                "repop_scale_at_L": [round(float(d[x]["scale"]), 3) for x in lands[1:] if x in d],
                "last_drawn_after_last_L": max(frames) - lands[-1],
                # the last frame it is drawn whole: it sinks from the next
                "sink_start_after_last_L": max(
                    (f - lands[-1] for f in frames if f >= lands[-1] and float(d[f]["alpha"]) >= 1.0), default=None
                ),
                "above_disc_px": None,
            }
            disc = discs.get(stat, {})
            both = [f for f in frames if f in disc and float(d[f]["scale"]) == 1.0]
            if both:
                f = both[0]
                t[stat]["above_disc_px"] = round(float(disc[f]["y"]) - float(d[f]["y"]), 1)
                t[stat]["disc_r_px"] = float(disc[f]["text"])
        out["tags"] = t
    if flights:
        gains_planned = (plan.get("buffs") or {}).get("gains", [])
        ids = [j for j, gn in enumerate(gains_planned) if str(gn["run"]) == run_id and gn["key"] == brock]
        fl = {}
        homes = {}
        for row in cards:
            if row["side"] == "0" and int(row["frame"]) < out_at - 40:
                homes[row["slot"]] = (float(row["x"]), float(row["y"]))
        for stat, got in flights.items():
            d = discs.get(stat, {})
            # where the disc sits on a card: its offset from the card's centre, at L
            disc_off = (
                float(d[lands[0]]["x"]) - float(by[lands[0]]["x"]),
                float(d[lands[0]]["y"]) - float(by[lands[0]]["y"]),
            )
            items = []
            for k, j in enumerate(ids):
                group = [r for r in got if int(r["value"]) == j]
                if not group:
                    continue
                born = int(group[0]["frame"])
                land = lands[k]
                pts = [(float(r["x"]), float(r["y"])) for r in group]
                steps = [((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5 for a, b in itertools.pairwise(pts)]
                # where it lands: the tally's place on the landing frame
                tag = tags.get(stat, {}).get(land)
                end = (float(tag["x"]), float(tag["y"])) if tag else pts[-1]
                # how far it rose above the straight line from its birth to its landing
                rise = 0.0
                for i, p in enumerate(pts):
                    line_y = pts[0][1] + (end[1] - pts[0][1]) * i / (land - born)
                    rise = max(rise, line_y - p[1])
                start_at = pts[0]

                def off(home, at=start_at, shift=disc_off):
                    return ((home[0] + shift[0] - at[0]) ** 2 + (home[1] + shift[1] - at[1]) ** 2) ** 0.5

                nearest = min(homes.items(), key=lambda kv, off=off: off(kv[1]))
                items.append(
                    {
                        "gain": j,
                        "born_after_F": born - start,
                        "frames": len(group),
                        "lands_after_born": land - born,
                        "from_slot": int(nearest[0]),
                        "from_off_px": round(off(nearest[1]), 1),
                        "first_step_px": round(steps[0], 1) if steps else None,
                        "last_step_px": round(((end[0] - pts[-1][0]) ** 2 + (end[1] - pts[-1][1]) ** 2) ** 0.5, 1),
                        "rise_px": round(rise, 1),
                        "born_scale": round(float(group[0]["scale"]), 3),
                    }
                )
            fl[stat] = items
        out["flights"] = fl
        out["flare_frames_per_gain"] = {
            stat: [sum(1 for f, j in fs if j == gid and 0 <= f - lands[k] < FLARE_MAX) for k, gid in enumerate(ids)]
            for stat, fs in flares.items()
        }
    return out


def checks(m: dict) -> list:
    """Each option's beats against DESIGN.md section 2 (A, B, C; Brock x6)."""
    out = []

    def check(name: str, want, got) -> None:
        out.append({"check": name, "expected": want, "measured": got, "pass": want == got})

    option = m["option"]
    check("numbers before G (Brock in moment e)", list(FROM), m["numbers_before"])
    check("highest numbers drawn after the gains", list(TO), m["numbers_after"])
    if option == "today":
        check("(today) Brock's numbers rise in one frame", 1, m["number_changes"])
    if option == "none":
        check("(best) Brock's numbers rise once per gain, no count", 6, m["number_changes"])
    if option not in ("a", "b", "c"):
        # the check bites: the CB14 beats are absent
        check("gain landings (gain_land markers)", 6, len(m.get("lands_after_F", [])))
        return out
    land = LAND_C if option == "c" else LAND_AB
    check("landings L after F (falls' end)", [s + land for s in STARTS], m["lands_after_F"])
    check("only Old Brock's discs swell", [m["brock"]], m["disc_keys"])
    check("the card itself never scales", 1.0, round(m["card_scale_max"], 3))
    for e in m["per_gain"]:
        for stat in ("attack", "health"):
            s = e[stat]
            check(f"gain {e['k']} {stat}: x2.0 from L to L+2", [2.0, 2.0, 2.0], s["scale_L_to_L2"])
            if s["scale_L13"] is not None:
                check(f"gain {e['k']} {stat}: easing back, about x1.0 at L+13", True, 1.0 <= s["scale_L13"] < 1.05)
            if s["rest_at"] is not None:
                check(f"gain {e['k']} {stat}: at rest from L+14", 14, s["rest_at"])
            if s["value_L8"] is not None:
                want = TO if e["k"] == 5 else None
                if want:
                    check(
                        f"gain {e['k']} {stat}: counted to the new number by L+8",
                        want[0 if stat == "attack" else 1],
                        s["value_L8"],
                    )
    for stat in ("attack", "health"):
        check(f"{stat}: the count never goes down", True, m[f"{stat}_values_monotone"])
    steps = (TO[0] - FROM[0]) + (TO[1] - FROM[1])
    check("Brock's drawn numbers count (more than one change)", True, m["number_changes"] > 6)
    check(
        f"each step one at a time ({steps} steps between attack and health, at most)",
        True,
        m["number_changes"] <= steps,
    )
    if option == "a":
        check("settled by F+76 (1.3 s)", 76, m["settled_after_F"])
        check("no tag", None, m.get("tags"))
        return out
    t = m["tags"]
    totals = {"attack": [f"+{a}" for a, _ in TOTALS], "health": [f"+{h}" for _, h in TOTALS]}
    for stat in ("attack", "health"):
        s = t[stat]
        check(f"tag {stat}: running total at each landing", totals[stat], s["texts_at_L"])
        check(f"tag {stat}: re-pops x1.35 at each later landing", [1.35] * 5, s["repop_scale_at_L"])
        check(f"tag {stat}: sinks from the last L+30", 30, s["sink_start_after_last_L"])
        check(f"tag {stat}: gone by the last L+36 (last drawn L+35)", 35, s["last_drawn_after_last_L"])
        check(
            f"tag {stat}: centre 38 px above the disc's top",
            True,
            s["above_disc_px"] is not None and abs(s["above_disc_px"] - (38.0 + s["disc_r_px"])) < 1.0,
        )
        if option == "b":
            check(f"tag {stat}: appears at L-2", -2, s["appear"])
            check(f"tag {stat}: at x0.5 when it appears", 0.5, s["appear_scale"])
            check(f"tag {stat}: x1.25 at L+2", 1.25, s["scale_L0_2"])
            check(f"tag {stat}: x1.0 by L+6", 1.0, s["scale_L0_6"])
        else:
            check(f"tag {stat}: pins at L (the flight lands)", 0, s["appear"])
    if option == "c":
        for stat in ("attack", "health"):
            items = m["flights"][stat]
            check(f"flight {stat}: six pairs", 6, len(items))
            check(f"flight {stat}: born at F+0, 18, 32, 42, 50, 56", STARTS, [i["born_after_F"] for i in items])
            check(f"flight {stat}: lands 10 f after it is born", [10] * 6, [i["lands_after_born"] for i in items])
            check(
                f"flight {stat}: from slots 0, 1, 2, 4, 5, 6 (the dead friends', in log order)",
                [0, 1, 2, 4, 5, 6],
                [i["from_slot"] for i in items],
            )
            check(
                f"flight {stat}: born at the dead slot's disc (within 2 px)",
                True,
                all(i["from_off_px"] <= 2.0 for i in items),
            )
            check(f"flight {stat}: born at x0.5", [0.5] * 6, [i["born_scale"] for i in items])
            check(
                f"flight {stat}: arc at most 0.15 h (37.5 px) high",
                True,
                all(i["rise_px"] <= 37.5 + 0.5 for i in items),
            )
            check(
                f"flight {stat}: arrives at speed (last step longer than the first)",
                True,
                all(i["last_step_px"] > i["first_step_px"] for i in items),
            )
            check(f"flare {stat}: 8 f at each landing", [8] * 6, m["flare_frames_per_gain"][stat])
    return out


def cmd_measure(stems: list) -> None:
    for stem in stems:
        m = measure(stem)
        m["checks"] = checks(m)
        failed = [c for c in m["checks"] if not c["pass"]]
        m["passed"] = len(m["checks"]) - len(failed)
        m["failed"] = len(failed)
        stem.with_suffix(".buffs.json").write_text(json.dumps(m, indent=1) + "\n")
        print(f"{stem.name}: {m['passed']} pass, {m['failed']} fail; G={m['G']}")
        for c in failed:
            print("  FAIL", c["check"], "expected", c["expected"], "measured", c["measured"])


# ---- clips ----


@contextlib.contextmanager
def cropped(crop: tuple):
    kept = clips.CROP
    clips.CROP = crop
    try:
        yield
    finally:
        clips.CROP = kept


def plan(film_dir: Path) -> tuple:
    windows = []
    for _, film, _ in OPTIONS:
        m = json.loads((film_dir / f"{film}.buffs.json").read_text())
        g = m["G"]
        windows.append((g, g - BEFORE, min(g + AFTER, m["last_frame"])))
    firsts, length = clips.aligned(windows)
    return firsts, length, [w[0] for w in windows]


def measured_of(film_dir: Path, film: str) -> dict:
    m = json.loads((film_dir / f"{film}.buffs.json").read_text())
    keep = (
        "G",
        "F",
        "lands_after_F",
        "lands_after_G",
        "number_changes",
        "numbers_before",
        "numbers_after",
        "settled_after_F",
        "passed",
        "failed",
    )
    out = {k: m[k] for k in keep if k in m}
    if "tags" in m:
        out["tag_texts_at_L"] = {s: v["texts_at_L"] for s, v in m["tags"].items()}
    if "flights" in m:
        out["flights_born_after_F"] = {s: [i["born_after_F"] for i in v] for s, v in m["flights"].items()}
    return out


def cmd_compare(film_dir: Path, out_dir: Path, scale: float) -> None:
    firsts, length, refs = plan(film_dir)
    before = refs[0] - firsts[0]
    entry = {
        "title": TITLE,
        "reference": "G",
        "before": before,
        "frames": length,
        "fps": FPS,
        "crop": list(CROP),
        "scale": scale,
        "segments": [
            {
                "what": WHAT,
                "reference": "G",
                "start": 0,
                "frames": length,
                "before": before,
                "reference_index": before,
                "counter_at_start": -before,
            }
        ],
        "options": [],
    }
    with cropped(CROP):
        for (option, film, label), first in zip(OPTIONS, firsts, strict=True):
            out = out_dir / "CB14" / f"{option}.mp4"
            clips.cut_plain(film_dir / f"{film}.mp4", [(first, length)], out, scale)
            entry["options"].append(
                {
                    "option": option,
                    "file": f"CB14/{option}.mp4",
                    "label": label,
                    "film": film,
                    "film_frames": [[first, first + length - 1]],
                    "measured": measured_of(film_dir, film),
                }
            )
            print(out)
    (out_dir / "CB14.json").write_text(json.dumps(entry, indent=1) + "\n")
    print(out_dir / "CB14.json")


def cmd_cut(film_dir: Path, clip_dir: Path) -> None:
    clip_dir.mkdir(parents=True, exist_ok=True)
    firsts, length, refs = plan(film_dir)
    out = clip_dir / "CB14.mp4"
    with cropped(CROP):
        clips.stack(
            [film_dir / f"{film}.mp4" for _, film, _ in OPTIONS],
            firsts,
            length,
            refs,
            "G",
            [label for _, _, label in OPTIONS],
            f"{TITLE}  ·  panes lined up at G, the first gain  ·  STAND-INS: recruit pill, arc, amber ring",
            out,
        )
    plays = clips.loop3(out)
    print(out, f"plays {plays}x")


def stills(film: Path, frames: list, out_dir: Path) -> None:
    """Full frames of a film, for checking what is drawn (not motion)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    for n in frames:
        subprocess.run(
            [
                "ffmpeg",
                "-loglevel",
                "error",
                "-y",
                "-i",
                str(film),
                "-vf",
                f"select='eq(n\\,{n})'",
                "-frames:v",
                "1",
                str(out_dir / f"{film.stem}-{n}.png"),
            ],
            check=True,
        )


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    what = sys.argv[1]
    if what == "scenarios":
        cmd_scenarios(Path(sys.argv[2]))
    elif what == "measure":
        cmd_measure([Path(a) for a in sys.argv[2:]])
    elif what == "compare":
        cmd_compare(Path(sys.argv[2]), Path(sys.argv[3]), float(sys.argv[4]) if len(sys.argv) > 4 else SCALE)
    elif what == "cut":
        cmd_cut(Path(sys.argv[2]), Path(sys.argv[3]))
    elif what == "stills":
        stills(Path(sys.argv[2]), [int(a) for a in sys.argv[4:]], Path(sys.argv[3]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
