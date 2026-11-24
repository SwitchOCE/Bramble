#!/usr/bin/env python3
"""Films, measures and cuts the `best` treatment's contested-branch clips (best.md section 6).

Usage:
  clips.py scenarios OUT_DIR           one scenario JSON per film (best, then each option)
  clips.py measure STEM [STEM...]      STEM.timing.json: claimed, planned and measured numbers
  clips.py cut FILM_DIR CLIP_DIR [CB1 .. whole]  one side-by-side clip per branch, and today vs best
  clips.py frames CLIP_DIR             5 frames of each clip into CLIP_DIR/frames, for checking

Films are made with tools/feel/film from the scenarios; FILM_DIR holds <name>.mp4 with their
.report.json, .cards.csv and .markers.csv (fight_compare.gd). `today` is read from FILM_DIR/today.*
(copy or link /data/fight-anim-work/fixture/today.*). Exploratory: nothing here is the game.
"""

import csv
import json
import math
import subprocess
import sys
import tempfile
from pathlib import Path

H = 250.0
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
# the battlefield in film pixels (both boards, the attack paths and the placeholder count)
CROP = (590, 250, 950, 800)
SCENE = "res://tests/screens/feel/fight_compare/fight_compare.tscn"

# branch -> [(option, film, label)], left to right as best.md section 6 lists them
BRANCHES = {
    "CB1": [
        ("today", "cb1-today", "Today: 4f lift x1.04, no hold"),
        ("a", "cb1-a", "A: 10f x1.15, no pull, hold 18"),
        ("b", "cb1-b", "B: 8f x1.14, pull 15, hold 14"),
        ("c", "cb1-c", "C: 10f x1.18, pull 20, hold 14"),
        ("best", "best", "Best: 10f x1.14, pull 12, hold 16"),
    ],
    "CB2": [
        ("a", "cb2-a", "A shallow: 0.78h near, 0.45 far"),
        ("b", "cb2-b", "B medium: 0.70h near, 0.50 far"),
        ("best", "best", "Best: 0.62h near, 0.45 far"),
        ("c", "cb2-c", "C deep: 0.50h near, 0.42 far"),
    ],
    "CB3": [
        ("linear", "best", "Linear (A, B, best)"),
        ("mild", "cb3-mild", "C: mild ease-in, power 1.6"),
        ("quad", "cb3-quad", "Today: quad ease-in"),
    ],
    "CB4": [
        ("freeze", "cb4-freeze", "Today: freeze at contact"),
        ("hold", "best", "Best: in the raised hold"),
        ("after", "cb4-after", "After the return"),
    ],
    "CB5": [
        ("b", "cb5-b", "B: falls at C+14"),
        ("c", "cb5-c", "C: C+24 (stand-in for shatter)"),
        ("best", "best", "Best: C+30"),
        ("bg", "cb5-bg", "Battlegrounds 2020-25: C+60"),
    ],
    "CB6": [
        ("b", "cb6-b", "B: lifts at C+8"),
        ("best", "best", "Best: C+28, gated by the queue"),
        ("a", "cb6-a", "A: C+36, gate 50f"),
        ("bg", "cb6-bg", "Battlegrounds: C+40, no gate"),
    ],
    "CB7": [
        ("bg", "cb7-bg", "Battlegrounds: one at a time"),
        ("a", "cb7-a", "A gentle: x0.7, floor 8"),
        ("c", "cb7-c", "C tempo: x1.3 to x3.5"),
        ("best", "best", "Best: x0.75, floor 5"),
        ("best_xn", "cb7-best_xn", "Best + plain-text xN PLACEHOLDER"),
    ],
}
TITLES = {
    "CB1": "CB1 wind-up",
    "CB2": "CB2 stop point",
    "CB3": "CB3 strike curve",
    "CB4": "CB4 a trigger before the hit",
    "CB5": "CB5 when a card killed in the exchange falls",
    "CB6": "CB6 when the next attacker lifts",
    "CB7": "CB7 one trigger many times",
}
PICKS = {"CB1": "best", "CB2": "best", "CB3": "linear", "CB4": "hold", "CB5": "best", "CB6": "best", "CB7": "best"}
# film seconds of `wait` in each scenario (the film ends 0.5 s after it)
WAIT = {"cb7-bg": 17.5, "cb5-bg": 14.5, "cb6-bg": 14.0}


def films() -> dict:
    out = {"best": {}}
    for branch, options in BRANCHES.items():
        for option, film, _ in options:
            if film != "best":
                out[film] = {branch: option}
    return out


def cmd_scenarios(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, options in films().items():
        scenario = {
            "scene": SCENE,
            "treatment": "best",
            "options": options,
            "steps": [{"move": "1900,1000", "time": 0.0}, {"wait": WAIT.get(name, 13.5)}],
        }
        (out_dir / f"{name}.json").write_text(json.dumps(scenario, indent=2) + "\n")
        print(name, json.dumps(options))


# ---- measuring ----


def load(stem: Path) -> tuple[dict, dict, list]:
    report = json.loads(stem.with_suffix(".report.json").read_text())
    cards: dict = {}
    with stem.with_suffix(".cards.csv").open() as f:
        for row in csv.DictReader(f):
            if row["card_id"] == "burst":
                continue
            cards[(int(row["frame"]), row["key"])] = row
    with stem.with_suffix(".markers.csv").open() as f:
        markers = list(csv.DictReader(f))
    return report, cards, markers


def at(cards: dict, frame: int, key: str) -> tuple | None:
    row = cards.get((frame, key))
    if row is None:
        return None
    return float(row["x"]), float(row["y"]), float(row["scale"]), row["state"]


def rest(cards: dict, key: str) -> tuple | None:
    """Where a card stands: its first logged frame (no card changes slot in this fight)."""
    first = min((f for (f, k) in cards if k == key), default=None)
    return None if first is None else at(cards, first, key)


def bursts_between(markers: list, first: int, last: int) -> list:
    return [
        (int(m["frame"]), m["detail"]) for m in markers if m["marker"] == "burst" and first <= int(m["frame"]) <= last
    ]


def measure_attack(attack: dict, nxt: dict | None, cards: dict, markers: list) -> dict:
    key, target = attack["attacker"], attack["target"]
    start, end = attack["start_frame"], attack["end_frame"]
    home = rest(cards, key)
    aim = rest(cards, target)
    out: dict = {"attack": attack["attack"], "attacker": attack["attacker_card"], "target": attack["target_card"]}
    if home is None or aim is None:
        return out
    frames = []
    for f in range(start, end + 1):
        p = at(cards, f, key)
        if p is None:
            break
        frames.append((f, p))
    lift_start = next((f for f, p in frames if p[2] > 1.0005 or math.dist(p[:2], home[:2]) > 0.3), None)
    contact = attack.get("contact_frame", -1)
    before = [(f, p) for f, p in frames if contact < 0 or f < contact]
    if lift_start is None or not before:
        return out
    top = max(p[2] for _, p in before)
    peak = next(f for f, p in before if p[2] >= top - 0.0005)
    out["lift_start"] = lift_start
    out["lift_frames"] = peak - (lift_start - 1)
    out["lift_scale"] = round(top, 3)
    pulled = at(cards, peak, key)
    out["pull_px"] = round(math.dist(pulled[:2], home[:2]), 1)
    # the hold: from the lift's peak to the launch (the frame before the strike's run of big steps);
    # drift: how far the card moves in the hold (it should be dead still)
    launch = peak
    if contact >= 0:
        launch = contact
        while launch - 1 >= peak:
            a, b = at(cards, launch - 1, key), at(cards, launch, key)
            if a is None or b is None or math.dist(a[:2], b[:2]) < 2.0:
                break
            launch -= 1
    else:
        for f, p in before:
            if f > peak and math.dist(p[:2], pulled[:2]) < 0.05 and abs(p[2] - pulled[2]) < 0.0005:
                launch = f
            elif f > peak:
                break
    out["hold_frames"] = launch - peak
    held = [at(cards, f, key) for f in range(peak, launch + 1)]
    out["hold_drift_px"] = round(max(math.dist(h[:2], pulled[:2]) for h in held if h), 1)
    until = nxt["contact_frame"] if nxt is not None and nxt.get("contact_frame", -1) >= 0 else end + 200
    if contact < 0:
        out["no_strike"] = True
        fall = min((f for (f, k), row in cards.items() if k == key and row["state"] == "leaving"), default=None)
        hits = bursts_between(markers, start, fall or end)
        out["fall_start"] = fall
        out["bursts_in_hold"] = [f - start for f, _ in hits]
        if fall is not None and hits:
            out["fall_after_last_burst"] = fall - hits[-1][0]
        return out
    out["bursts_before_contact"] = [[f - contact, d] for f, d in bursts_between(markers, start, contact - 1)]
    out["bursts_after_contact"] = [[f - contact, d] for f, d in bursts_between(markers, contact, contact + 60)]
    hit = at(cards, contact, key)
    out["launch"] = launch
    out["contact"] = contact
    out["strike_frames"] = contact - launch
    out["stop_gap_h"] = round(math.dist(hit[:2], aim[:2]) / H, 3)
    out["distance_h"] = round(math.dist(home[:2], aim[:2]) / H, 3)
    out["pop_scale"] = round(hit[2], 3)
    steps = []
    for f in range(launch + 1, contact + 1):
        a, b = at(cards, f - 1, key), at(cards, f, key)
        steps.append(round(math.dist(a[:2], b[:2]), 1))
    out["strike_px_per_frame"] = steps
    back = None
    for f in range(contact + 1, until + 1):
        p = at(cards, f, key)
        if p is not None and math.dist(p[:2], home[:2]) < 0.05 and abs(p[2] - 1.0) < 0.0005:
            back = f
            break
    out["home_after_contact"] = back - contact if back is not None else None
    numbers = [int(m["frame"]) for m in markers if m["marker"] == "numbers" and contact <= int(m["frame"]) <= end]
    out["numbers_after_contact"] = numbers[0] - contact if numbers else None
    falls = {}
    for (f, k), row in cards.items():
        if row["state"] == "leaving" and contact <= f <= until and (k not in falls or f < falls[k]):
            falls[k] = f
    out["falls_after_contact"] = {k: f - contact for k, f in sorted(falls.items(), key=lambda kv: kv[1])}
    if nxt is not None:
        nxt_home = at(cards, nxt["start_frame"], nxt["attacker"])
        lift = None
        for f in range(nxt["start_frame"], nxt["end_frame"] + 1):
            p = at(cards, f, nxt["attacker"])
            if p is None or nxt_home is None:
                break
            if p[2] > 1.0005:
                lift = f
                break
        out["next_lift_after_contact"] = lift - 1 - contact if lift is not None else None
    return out


def brock_combo(cards: dict, markers: list, report: dict) -> dict:
    """Old Brock's numbers changing after the six deaths of moment (e): the combo's landings."""
    attacks = report["attacks"]
    first, last = attacks[5]["contact_frame"], attacks[6]["contact_frame"]
    # after the six deaths: Old Brock's numbers, up to its own attack's first burst (Thorns)
    thorns = min(
        (
            int(m["frame"])
            for m in markers
            if m["marker"] == "burst" and int(m["frame"]) > max(attacks[6]["start_frame"], first + 60)
        ),
        default=last,
    )
    pops = [int(m["frame"]) for m in markers if m["marker"] == "numbers" and m["key"] == "u4"]
    pops = [f for f in pops if first + 60 < f < thorns]
    return {
        "landings": pops,
        "gaps": [b - a for a, b in zip(pops, pops[1:], strict=False)],
        "last_to_next_contact": last - pops[-1] if pops else None,
    }


def claims_for(plan: dict) -> dict:
    return plan.get("claims", {})


def mismatches(measured: list, plan: dict) -> list:
    out = []
    claims = claims_for(plan)
    windup = claims.get("windup", {})
    for m, p in zip(measured, plan.get("attacks", []), strict=False):
        n = m["attack"]

        def check(name, got, want, tol=0.0, n=n):
            if got is None or want is None:
                return
            if abs(got - want) > tol:
                out.append(f"attack {n}: {name} measured {got}, claimed {want}")

        if "lift_frames" not in m:
            continue
        check("lift frames", m["lift_frames"], windup.get("lift"))
        check("lift scale", m["lift_scale"], windup.get("scale"), 0.002)
        check("pull-back px", m["pull_px"], windup.get("pull"), 0.6)
        if m.get("no_strike"):
            check("fall after the Thorns burst", m.get("fall_after_last_burst"), 20)
            continue
        check("hold frames", m["hold_frames"], p["hold_frames"])
        check("drift in the hold (px)", m.get("hold_drift_px"), 0.0, 0.5)
        if p["hold_frames"] != windup.get("hold") and p["hold_frames"] >= 0:
            out.append(
                f"attack {n}: (expected) hold stretched to {p['hold_frames']} f (least {windup.get('hold')}) "
                f"for what plays before the hit or the previous queue"
            )
        got_falls = m.get("falls_after_contact") or {}
        for fall in p.get("falls", []):
            check(f"{fall['key']} falls after contact", got_falls.get(fall["key"]), fall["frame"] - p["contact"])
        check("strike frames", m["strike_frames"], p["strike_frames"])
        check("stop gap h", m["stop_gap_h"], p["stop_gap_h"], 0.01)
        check("contact pop", m["pop_scale"], 1.24, 0.002)
        check("home after contact", m["home_after_contact"], p["home"] - p["contact"], 1)
        check("numbers after contact", m["numbers_after_contact"], p["numbers"] - p["contact"])
        if m.get("next_lift_after_contact") is not None and p.get("next_lift", -1) >= 0:
            check("next lift after contact", m["next_lift_after_contact"], p["next_lift"] - p["contact"])
        steps = m["strike_px_per_frame"]
        curve = claims.get("curve", 1.0)
        if curve == 1.0 and steps and max(steps) - min(steps) > 1.5:
            out.append(f"attack {n}: strike not constant speed: {steps}")
    return out


def cmd_measure(stems: list[Path]) -> None:
    for stem in stems:
        if stem.suffix == ".mp4":
            stem = stem.with_suffix("")
        report, cards, markers = load(stem)
        attacks = report["attacks"]
        measured = []
        for i, attack in enumerate(attacks):
            nxt = attacks[i + 1] if i + 1 < len(attacks) else None
            measured.append(measure_attack(attack, nxt, cards, markers))
        plan = report.get("plan") or {}
        offset = plan.get("frame_offset", 0)
        planned = []
        for p in plan.get("attacks", []):
            film = {k: (v + offset if isinstance(v, int) and v >= 0 and k in FRAME_KEYS else v) for k, v in p.items()}
            film["falls"] = [dict(f, frame=f["frame"] + offset) for f in p.get("falls", [])]
            planned.append(film)
        steps = [
            {"frame": int(m["frame"]), "step": int(m["step"]), "detail": m["detail"]}
            for m in markers
            if m["marker"] == "step"
        ]
        timing = {
            "treatment": report.get("treatment"),
            "options": plan.get("options", {}),
            "claims": claims_for(plan),
            "frame_offset": offset,
            "contacts": [a["contact_frame"] for a in attacks],
            "attack_starts": [a["start_frame"] for a in attacks],
            "measured": measured,
            "planned_film_frames": planned,
            "brock_combo": brock_combo(cards, markers, report) if len(attacks) >= 7 else {},
            "mismatches": mismatches(measured, plan) if plan else [],
            "notes": plan.get("notes", []),
            "result_at_s": report.get("result_at"),
            "core_matches": report.get("core_matches"),
            "steps": steps,
        }
        out = stem.parent / (stem.name + ".timing.json")
        out.write_text(json.dumps(timing, indent=1) + "\n")
        print(out, "mismatches:", len(timing["mismatches"]))


FRAME_KEYS = {"lift", "launch", "contact", "release", "home", "numbers", "queue_from", "queue_end", "next_lift"}


# ---- cutting ----


def plan_frames(film_dir: Path, film: str) -> list:
    report = json.loads((film_dir / f"{film}.report.json").read_text())
    plan = report["plan"]
    offset = plan["frame_offset"]
    out = []
    for p in plan["attacks"]:
        q = dict(p)
        for k in FRAME_KEYS:
            if isinstance(q.get(k), int) and q[k] >= 0:
                q[k] += offset
        q["falls"] = [dict(f, frame=f["frame"] + offset) for f in p["falls"]]
        out.append(q)
    return out


def segments(branch: str, a: list) -> list:
    """[(name, first, last)] film frames for one option's film."""
    if branch == "CB1":
        return [("(a) plain attack straight across", a[0]["lift"] - 8, a[0]["contact"] + 40)]
    if branch == "CB2":
        return [
            ("(a) straight across, 1.18h", a[0]["lift"] - 6, a[0]["contact"] + 30),
            ("(b) far corner, 2.17h", a[1]["lift"] - 6, a[1]["contact"] + 30),
        ]
    if branch == "CB3":
        return [("(b) far corner, 2.17h, 8f strike", a[1]["launch"] - 12, a[1]["contact"] + 24)]
    if branch == "CB4":
        return [("(c) Thorns hits the attacker before the hit", a[2]["lift"] - 6, a[2]["release"] + 45)]
    if branch == "CB5":
        # through the Stripper's fall, its damage to all, and the six falls that follow
        six = [f for f in a[5]["falls"] if f["key"] != "u10"]
        return [("(e) Orchard Stripper killed in the exchange", a[5]["contact"] - 8, max(f["frame"] for f in six) + 20)]
    if branch == "CB6":
        return [
            ("(a) to (b): two plain attacks", a[0]["contact"] - 8, a[1]["contact"] + 8),
            ("(d) to (e): Thorns kill, Hopper, next attacker", a[4]["release"] - 4, a[5]["contact"] + 8),
            ("(e) to Old Brock's attack: a long chain", a[5]["contact"] + 40, a[6]["contact"] + 8),
        ]
    if branch == "CB7":
        six = [f for f in a[5]["falls"] if f["key"] != "u10"]
        start = min(f["frame"] for f in six) + 10
        return [("(e) Old Brock triggers 6 times", start, a[6]["lift"] + 20)]
    raise ValueError(branch)


def run(args: list) -> None:
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *args], check=True)


def counter(ref: str, off: int) -> str:
    """drawtext filters for a pane's own counter: frames from its reference, e.g. C-5, C+0, C+12.
    off is the pane's first frame minus its reference frame."""
    common = f"fontfile={FONT_BOLD}:fontcolor=0xb02020"
    plus = f"n+{off}" if off >= 0 else f"n-{-off}"
    if off >= 0:
        return f"drawtext={common}:text='{ref}+%{{eif\\:{plus}\\:d}}':{{pos}}"
    return (
        f"drawtext={common}:text='{ref}+%{{eif\\:{plus}\\:d}}':enable='gte(n\\,{-off})':{{pos}},"
        f"drawtext={common}:text='{ref}-%{{eif\\:{-off}-n\\:d}}':enable='lt(n\\,{-off})':{{pos}}"
    )


def pane_filter(
    i: int, first: int, last: int, width: int, label_file: Path, ref: str, off: int, trail: list | None = None
) -> str:
    x, y, w, h = CROP
    scale = width / w
    chain = (
        f"[{i}:v]trim=start_frame={first}:end_frame={last + 1},setpts=PTS-STARTPTS,"
        f"crop={w}:{h}:{x}:{y},scale={width}:-2"
    )
    if trail:
        for k, (tx, ty) in enumerate(trail):
            px, py = (tx - x) * scale - 3, (ty - y) * scale - 3
            chain += f",drawbox=x={px:.0f}:y={py:.0f}:w=7:h=7:color=yellow@1:t=fill:enable='gte(n\\,{k})'"
    size = max(14, round(width / 22))
    pos = f"fontsize={size}:x=8:y={size + 12}"
    chain += (
        f",pad=iw:ih+{size * 2 + 16}:0:{size * 2 + 16}:color=white,"
        f"drawtext=fontfile={FONT_BOLD}:textfile={label_file}:fontsize={size}:fontcolor=black:x=8:y=6,"
        + counter(ref, off).replace("{pos}", pos)
        + f"[p{i}]"
    )
    return chain


def stack(
    inputs: list,
    firsts: list,
    length: int,
    refs: list,
    ref: str,
    labels: list,
    title: str,
    out: Path,
    trails=None,
    slow=1,
) -> None:
    """One pane per input, each from its own first frame for length frames; refs[i] is that pane's
    reference frame (its counter reads ref+0 there)."""
    n = len(inputs)
    width = min(640, (1920 // n) // 2 * 2)
    with tempfile.TemporaryDirectory() as tmp:
        parts = []
        for i, label in enumerate(labels):
            lf = Path(tmp) / f"label{i}.txt"
            lf.write_text(label)
            first = firsts[i]
            parts.append(
                pane_filter(
                    i, first, first + length - 1, width, lf, ref, first - refs[i], trails[i] if trails else None
                )
            )
        tf = Path(tmp) / "title.txt"
        tf.write_text(title)
        joined = "".join(f"[p{i}]" for i in range(n))
        tail = f"{joined}hstack=inputs={n}" if n > 1 else f"{joined}null"
        tail += (
            f",pad=iw:ih+40:0:40:color=0x222222,"
            f"drawtext=fontfile={FONT}:textfile={tf}:fontsize=22:fontcolor=white:x=10:y=9"
        )
        if slow > 1:
            tail += f",setpts={slow}*PTS,fps=60"
        tail += "[v]"
        args = []
        for path in inputs:
            args += ["-i", str(path)]
        graph = ";".join([*parts, tail])
        run(
            [
                *args,
                "-filter_complex",
                graph,
                "-map",
                "[v]",
                "-c:v",
                "libx264",
                "-preset",
                "medium",
                "-crf",
                "28",
                "-pix_fmt",
                "yuv420p",
                "-r",
                "60",
                str(out),
            ]
        )


MAX_BYTES = 3_000_000


def loop3(clip: Path) -> int:
    """best.md section 6: each clip plays three times; fewer when three would pass 3 MB."""
    looped = clip.with_name(f".{clip.stem}-3x.mp4")
    for times in (3, 2):
        run(["-stream_loop", str(times - 1), "-i", str(clip), "-c", "copy", str(looped)])
        if looped.stat().st_size < MAX_BYTES:
            looped.replace(clip)
            return times
    looped.unlink()
    return 1


def concat(parts: list, out: Path) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        listing = Path(tmp) / "list.txt"
        listing.write_text("".join(f"file '{p}'\n" for p in parts))
        run(["-f", "concat", "-safe", "0", "-i", str(listing), "-c", "copy", str(out)])


def centres(film_dir: Path, film: str, key: str, first: int, last: int) -> list:
    out = []
    with (film_dir / f"{film}.cards.csv").open() as f:
        for row in csv.DictReader(f):
            if row["key"] == key and first <= int(row["frame"]) <= last:
                out.append((int(row["frame"]), float(row["x"]), float(row["y"])))
    out.sort()
    return [(x, y) for _, x, y in out]


# what each pane's counter counts from: S the attack's first motion, C contact, P the first combo pulse
REF_NAME = {"CB1": "S", "CB7": "P"}
# per branch, per segment: the attack whose contact is the reference (CB1: its first motion)
REF_ATTACK = {"CB1": [0], "CB2": [0, 1], "CB3": [1], "CB4": [2], "CB5": [5], "CB6": [0, 4, 5]}


def first_pulse(film_dir: Path, film: str, timing: dict) -> int:
    """Old Brock's first combo pulse: its first move in the 20 frames before its first combo landing."""
    landing = timing["brock_combo"]["landings"][0]
    rows = {}
    with (film_dir / f"{film}.cards.csv").open() as f:
        for row in csv.DictReader(f):
            frame = int(row["frame"])
            if row["key"] == "u4" and landing - 21 <= frame <= landing:
                rows[frame] = (float(row["x"]), float(row["y"]), float(row["scale"]))
    for frame in range(landing - 20, landing + 1):
        a, b = rows.get(frame - 1), rows.get(frame)
        if a and b and (math.dist(a[:2], b[:2]) > 0.3 or abs(a[2] - b[2]) > 0.002):
            return frame - 1
    return landing - 12


def references(film_dir: Path, film: str, branch: str) -> list:
    timing = json.loads((film_dir / f"{film}.timing.json").read_text())
    measured = timing["measured"]
    if branch == "CB7":
        return [first_pulse(film_dir, film, timing)]
    if branch == "CB1":
        return [measured[0]["lift_start"]]
    out = []
    for k in REF_ATTACK[branch]:
        m = measured[k]
        # killed before it strikes (attack 4, Thorns): the Thorns burst stands in for contact
        out.append(m["contact"] if "contact" in m else m["lift_start"] + m["bursts_in_hold"][0])
    return out


def ref_names(branch: str, count: int) -> list:
    """The counter's letter per segment: S first motion, C contact, T Thorns lands (no strike), P pulse."""
    if branch == "CB6":
        return ["C", "T", "C"]
    return [REF_NAME.get(branch, "C")] * count


def aligned(windows: list) -> tuple:
    """windows: [(ref, lo, hi)] per option. Returns (firsts, length): every pane gets the same frames
    before and after its own reference, enough to hold every option's window."""
    before = max(ref - lo for ref, lo, _ in windows)
    before = min(before, min(ref for ref, _, _ in windows))
    after = max(hi - ref for ref, _, hi in windows)
    return [ref - before for ref, _, _ in windows], before + after + 1


def cmd_cut(film_dir: Path, clip_dir: Path, only: list) -> None:
    clip_dir.mkdir(parents=True, exist_ok=True)
    listing = clip_dir / "clips.json"
    index = json.loads(listing.read_text()) if listing.exists() else {}
    for branch, options in BRANCHES.items():
        if only and branch not in only:
            continue
        films_ = [film for _, film, _ in options]
        plans = {film: plan_frames(film_dir, film) for film in films_}
        refs = {film: references(film_dir, film, branch) for film in films_}
        names = [name for name, _, _ in segments(branch, plans[films_[0]])]
        letters = ref_names(branch, len(names))
        inputs = [film_dir / f"{film}.mp4" for film in films_]
        labels = [label for _, _, label in options]
        parts = []
        ranges = []
        for k, name in enumerate(names):
            ref = letters[k]
            windows = [(refs[film][k], *segments(branch, plans[film])[k][1:]) for film in films_]
            firsts, length = aligned(windows)
            before = refs[films_[0]][k] - firsts[0]
            part = clip_dir / f".{branch}-{k}.mp4"
            stack(
                inputs,
                firsts,
                length,
                [refs[film][k] for film in films_],
                ref,
                labels,
                f"{TITLES[branch]}  ·  {name}  ·  panes lined up at {ref}",
                part,
            )
            parts.append(part)
            ranges.append(
                {
                    "segment": name,
                    "reference": ref,
                    "before": before,
                    "after": length - before - 1,
                    "film_frames": {
                        film: [first, first + length - 1, refs[film][k]]
                        for film, first in zip(films_, firsts, strict=True)
                    },
                }
            )
        out = clip_dir / f"{branch}.mp4"
        if len(parts) == 1:
            parts[0].rename(out)
        else:
            concat(parts, out)
            for part in parts:
                part.unlink()
        plays = loop3(out)
        index[branch] = {
            "file": out.name,
            "plays": plays,
            "options": [f"{option} ({film})" for option, film, _ in options],
            "ranges": ranges,
        }
        print(out, [(r["segment"], r["reference"], -r["before"], r["after"]) for r in ranges])
        if branch == "CB3":
            windows = [(refs[film][0], plans[film][1]["launch"] - 2, plans[film][1]["contact"] + 3) for film in films_]
            firsts, length = aligned(windows)
            trails = [
                centres(film_dir, film, "u8", first, first + length - 1)
                for film, first in zip(films_, firsts, strict=True)
            ]
            slow = clip_dir / "CB3-slow.mp4"
            stack(
                inputs,
                firsts,
                length,
                [refs[film][0] for film in films_],
                "C",
                labels,
                "CB3 strike curve  ·  (b) at 0.25x, the attacker's centre each frame  ·  lined up at C",
                slow,
                trails=trails,
                slow=4,
            )
            plays = loop3(slow)
            before = refs[films_[0]][0] - firsts[0]
            index["CB3-slow"] = {
                "file": slow.name,
                "plays": plays,
                "options": index[branch]["options"],
                "ranges": [
                    {
                        "segment": names[0],
                        "reference": "C",
                        "before": before,
                        "after": length - before - 1,
                        "film_frames": {
                            film: [first, first + length - 1, refs[film][0]]
                            for film, first in zip(films_, firsts, strict=True)
                        },
                    }
                ],
            }
            print(slow, -before, length - before - 1)
    if only and "whole" not in only:
        listing.write_text(json.dumps(index, indent=1) + "\n")
        return
    whole = clip_dir / "today-vs-best.mp4"
    with tempfile.TemporaryDirectory() as tmp:
        files = []
        for i, label in enumerate(["Today (the game now)", "Best proposal (every branch at its pick)"]):
            lf = Path(tmp) / f"l{i}.txt"
            lf.write_text(label)
            files.append(lf)
        graph = (
            f"[0:v]scale=960:-2,tpad=stop_mode=clone:stop_duration=4,pad=iw:ih+36:0:36:color=white,"
            f"drawtext=fontfile={FONT_BOLD}:textfile={files[0]}:fontsize=22:x=8:y=6[a];"
            f"[1:v]scale=960:-2,tpad=stop_mode=clone:stop_duration=4,pad=iw:ih+36:0:36:color=white,"
            f"drawtext=fontfile={FONT_BOLD}:textfile={files[1]}:fontsize=22:x=8:y=6[b];"
            f"[a][b]hstack=inputs=2,drawtext=fontfile={FONT}:text='film frame %{{frame_num}}':"
            f"fontsize=20:fontcolor=black:x=w-tw-10:y=8[v]"
        )
        frames = max(count_frames(film_dir / "today.mp4"), count_frames(film_dir / "best.mp4"))
        run(
            [
                "-i",
                str(film_dir / "today.mp4"),
                "-i",
                str(film_dir / "best.mp4"),
                "-filter_complex",
                graph,
                "-map",
                "[v]",
                "-frames:v",
                str(frames),
                "-c:v",
                "libx264",
                "-preset",
                "medium",
                "-crf",
                "28",
                "-pix_fmt",
                "yuv420p",
                "-r",
                "60",
                str(whole),
            ]
        )
    index["today-vs-best"] = {
        "file": whole.name,
        "options": ["today", "best"],
        "ranges": [("whole fight", 0, frames - 1)],
    }
    (clip_dir / "clips.json").write_text(json.dumps(index, indent=1) + "\n")
    print(whole)


def count_frames(path: Path) -> int:
    got = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-count_frames",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=nb_read_frames",
            "-of",
            "csv=p=0",
            str(path),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return int(got.stdout.strip())


def cmd_frames(clip_dir: Path) -> None:
    out = clip_dir / "frames"
    out.mkdir(exist_ok=True)
    index = json.loads((clip_dir / "clips.json").read_text())
    for clip in sorted(clip_dir.glob("*.mp4")):
        n = count_frames(clip)
        n //= index.get(clip.stem, {}).get("plays", 1)  # the first play only
        for k in range(5):
            frame = round((n - 1) * (k + 0.5) / 5)
            run(
                [
                    "-i",
                    str(clip),
                    "-vf",
                    f"select='eq(n\\,{frame})'",
                    "-frames:v",
                    "1",
                    str(out / f"{clip.stem}-{k}-f{frame}.png"),
                ]
            )
        print(clip.name, n, "frames")


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    what = sys.argv[1]
    if what == "scenarios":
        cmd_scenarios(Path(sys.argv[2]))
    elif what == "measure":
        cmd_measure([Path(a) for a in sys.argv[2:]])
    elif what == "cut":
        cmd_cut(Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4:])
    elif what == "frames":
        cmd_frames(Path(sys.argv[2]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
