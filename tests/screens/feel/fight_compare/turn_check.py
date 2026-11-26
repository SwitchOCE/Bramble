#!/usr/bin/env python3
"""Checks for the turn toward the target in the game (plan step 1a,
docs/workstreams/fight-animation-24-nov/PLAN-implement.md), read from the comparison fight's
per-frame logs (README.md beside this file).

Usage:
  turn_check.py same STEM_A STEM_B [--except COL,COL]   cards.csv equal frame for frame
  turn_check.py turns STEM                              every attacker turned toward its target
  turn_check.py sounds STEM_A STEM_B                    the sound cues at the same frames
  turn_check.py cut STEM OUT.mp4                        the picks page's whole-fight crop and scale

STEM is a film without its extension (/data/fight-anim-work/game-1a/films/game). `turns` uses
the game's numbers (src/screens/fight/fight_motion.gd TURN_*, WINDUP_TURN). Exploratory: nothing
here is the game.
"""

import contextlib
import csv
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import re

# read from src/screens/fight/fight_motion.gd, so a pick changed there is checked here too
_MOTION = (Path(__file__).resolve().parents[4] / "src/screens/fight/fight_motion.gd").read_text()


def _const(name: str) -> float:
    m = re.search(rf"const {name}: float = ([0-9.]+)", _MOTION)
    if m is None:
        raise SystemExit(f"{name} not found in fight_motion.gd")
    return float(m.group(1))


TURN_AIM = _const("TURN_AIM")
TURN_AT_CONTACT = _const("TURN_AT_CONTACT")
TURN_LEAN = _const("TURN_LEAN")
WINDUP_TURN = _const("WINDUP_TURN")
# the log writes rotation and places to 2 decimals
ROUNDING = 0.011
FAST_SAMPLING = 0.05


def rows_of(stem: str) -> list:
    with Path(f"{stem}.cards.csv").open(newline="") as f:
        return list(csv.DictReader(f))


def cmd_same(a: str, b: str, ignored: set) -> int:
    ra, rb = rows_of(a), rows_of(b)
    ka = {(r["frame"], r["key"]): r for r in ra}
    kb = {(r["frame"], r["key"]): r for r in rb}
    only_a = sorted(set(ka) - set(kb), key=lambda k: (int(k[0]), k[1]))
    only_b = sorted(set(kb) - set(ka), key=lambda k: (int(k[0]), k[1]))
    columns = [c for c in ra[0] if c not in ignored] if ra else []
    differ: dict = {}
    frames: set = set()
    for k in ka.keys() & kb.keys():
        for c in columns:
            if ka[k].get(c) != kb[k].get(c):
                d = differ.setdefault(c, {"rows": 0, "frames": set(), "max": 0.0, "first": None})
                d["rows"] += 1
                d["frames"].add(int(k[0]))
                frames.add(int(k[0]))
                with contextlib.suppress(ValueError):
                    d["max"] = max(d["max"], abs(float(ka[k][c]) - float(kb[k][c])))
                if d["first"] is None or int(k[0]) < d["first"][0]:
                    d["first"] = (int(k[0]), k[1], ka[k][c], kb[k][c])
    print(f"rows: {len(ra)} and {len(rb)}; frames {frame_span(ra)} and {frame_span(rb)}")
    print(f"compared columns: {', '.join(columns)}")
    if ignored:
        print(f"not compared: {', '.join(sorted(ignored))}")
    print(f"rows only in A: {len(only_a)}; only in B: {len(only_b)}")
    for c, d in differ.items():
        print(
            f"  {c}: {d['rows']} rows in {len(d['frames'])} frames differ, max {d['max']:.4f};"
            f" first at frame {d['first'][0]} {d['first'][1]}: {d['first'][2]} vs {d['first'][3]}"
        )
    same = not only_a and not only_b and not differ
    print("SAME frame for frame" if same else f"DIFFERENT in {len(frames)} frames")
    return 0 if same else 1


def slot_homes(rows: list) -> dict:
    """(side, slot) -> where a card stands there most frames: the slot's place on the screen."""
    seen: dict = {}
    for r in rows:
        if r["key"] != "burst" and r["state"] == "kept" and r["slot"] != "":
            counts = seen.setdefault((r["side"], r["slot"]), {})
            place = (float(r["x"]), float(r["y"]))
            counts[place] = counts.get(place, 0) + 1
    return {k: max(v, key=v.get) for k, v in seen.items()}


def frame_span(rows: list) -> str:
    frames = [int(r["frame"]) for r in rows]
    return f"{min(frames)}-{max(frames)}" if frames else "none"


def cmd_turns(stem: str) -> int:
    report = json.loads(Path(f"{stem}.report.json").read_text())
    rows = rows_of(stem)
    by_frame: dict = {}
    for r in rows:
        by_frame.setdefault(int(r["frame"]), {})[r["key"]] = r
    homes = slot_homes(rows)
    bad = 0
    for a in report["attacks"]:
        start, contact, end = a["start_frame"], a["contact_frame"], a["end_frame"]
        if contact < 0:
            # no contact: it died before its hit (Thorns), or its target died first and it
            # settled back unstruck; there is no contact turn to check
            print(f"attack {a['attack']} {a['attacker_card']} -> {a['target_card']}: no contact, not checked")
            continue
        # the screen aims from slot to slot (FightScreen._card_motion), not from where cards are
        home = homes[tuple(str(v) for v in a["from"])]
        target = homes[tuple(str(v) for v in a["to"])]
        way = (target[0] - home[0], target[1] - home[1])
        n = math.hypot(*way)
        way = (way[0] / n, way[1] / n)
        lead = -1.0 if way[1] > 0.0 else 1.0
        # the angle from the leading edge's normal to the path, clockwise + (y down)
        ref = (0.0, -lead)
        full = math.degrees(math.atan2(ref[0] * way[1] - ref[1] * way[0], ref[0] * way[0] + ref[1] * way[1]))
        cock = WINDUP_TURN * (-1.0 if way[1] < 0.0 else 1.0)
        if report.get("treatment") == "game":
            # since step 1b the game plays FightTimeline's schedule, whose wind-up has no cock
            cock = 0.0
        want = -cock / 2.0 + TURN_AIM * TURN_AT_CONTACT * full
        got = [
            (f, float(by_frame[f][a["attacker"]]["rotation"]))
            for f in range(start, end + 1)
            if a["attacker"] in by_frame.get(f, {})
        ]
        at_contact = float(by_frame[contact][a["attacker"]]["rotation"])
        peak = max(got, key=lambda fr: abs(fr[1] + cock / 2.0)) if got else (None, 0.0)
        last = got[-1][1] if got else float("nan")
        # the game's FAST (x1.5 from the 5th attack) draws between schedule frames, so its drawn
        # contact frame can sit up to half a schedule frame past the contact
        allowed = FAST_SAMPLING if report.get("treatment") == "game" else ROUNDING
        ok = abs(at_contact - want) <= allowed and (
            abs(full) < 1e-6 or math.copysign(1, at_contact + cock / 2.0) == math.copysign(1, full)
        )
        bad += 0 if ok else 1
        print(
            f"attack {a['attack']} {a['attacker_card']} -> {a['target_card']}: path {full:+.2f} deg,"
            f" expected at contact {want:+.2f} (cock {-cock / 2.0:+.1f} + 95 % x 90 % of the path),"
            f" got {at_contact:+.2f} at frame {contact}; peak {peak[1]:+.2f} at {peak[0]};"
            f" last frame {end}: {last:+.2f} {'ok' if ok else 'WRONG'}"
        )
    print(f"core_matches: {report.get('core_matches')}; result at {report.get('result_at'):.2f} s")
    if not report.get("core_matches"):
        bad += 1
    print("every attacker turned toward its target" if bad == 0 else f"{bad} problem(s)")
    return 0 if bad == 0 else 1


def cmd_sounds(a: str, b: str) -> int:
    def cues(stem: str) -> list:
        with Path(f"{stem}.markers.csv").open(newline="") as f:
            return [(r["frame"], r["detail"]) for r in csv.DictReader(f) if r["marker"] == "sound"]

    ca, cb = cues(a), cues(b)
    moved = [(x, y) for x, y in zip(ca, cb, strict=False) if x != y]
    print(f"cues: {len(ca)} and {len(cb)}; at a different frame or different: {len(moved)}")
    for x, y in moved:
        print(f"  {x} vs {y}")
    same = len(ca) == len(cb) and not moved
    print("SAME cues at the same frames" if same else "DIFFERENT")
    return 0 if same else 1


def cmd_cut(stem: str, out: str) -> int:
    import clips
    import picks_rot

    film = Path(f"{stem}.mp4")
    clips.cut_plain(film, [(0, picks_rot.frames_of(film))], Path(out), picks_rot.COMPARE_SCALE)
    print(out)
    return 0


def main() -> int:
    args = sys.argv[1:]
    if len(args) >= 3 and args[0] == "same":
        ignored = set()
        if "--except" in args:
            ignored = set(args[args.index("--except") + 1].split(","))
        return cmd_same(args[1], args[2], ignored)
    if len(args) == 2 and args[0] == "turns":
        return cmd_turns(args[1])
    if len(args) == 3 and args[0] == "sounds":
        return cmd_sounds(args[1], args[2])
    if len(args) == 3 and args[0] == "cut":
        return cmd_cut(args[1], args[2])
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
