#!/usr/bin/env python3
"""Films, measures and cuts the animation pilot's cheap options: CB12 (damage to the player after a
fight) and CB13 (a single death), from the `pilot` treatment (pilot.gd). Beside clips.py, which it
borrows from; it leaves clips.py's branches and compare/manifest.json alone (each decision's entry
is its own file, compare/CB12.json and compare/CB13.json, in a manifest branch's shape).

Usage:
  pilot_clips.py scenarios OUT_DIR          one scenario JSON per film
  pilot_clips.py measure STEM [STEM...]     STEM.pilot.json: each option's beats, measured
  pilot_clips.py compare FILM_DIR OUT_DIR [SCALE]  OUT_DIR/CB12/<option>.mp4, CB13/..., CB12.json, CB13.json
  pilot_clips.py cut FILM_DIR CLIP_DIR      CLIP_DIR/CB12.mp4 and CB13.mp4, the options side by side

Films are made with tools/feel/film from the scenarios. Exploratory: nothing here is the game.
"""

import contextlib
import csv
import json
import math
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import clips

SCENE = clips.SCENE
FPS = 60
WHOLE = (0, 0, 1920, 1080)
# CB12's fights: the comparison fight (you win) and the three short losses
FIGHTS = ["win", "lose-small", "lose-big", "lose-out"]
FIGHT_OF = {"win": "", "lose-small": "lose-small", "lose-big": "lose-big", "lose-out": "lose-out"}
FIGHT_WHAT = {
    "win": "you win: the opponent loses 7",
    "lose-small": "you lose small: round + 1",
    "lose-big": "you lose big: round + 1, then +3",
    "lose-out": "you lose to 0 Health",
}
# film seconds of `wait`: the comparison fight's result is at 11.5 s, the short fights' near 2 s;
# each film runs past R+190 (compare clips aligned on R need R-12 to R+140)
WAIT = {"win": 14.8, "short": 5.6, "cb13": 13.0}
OPTIONS = {
    "CB12": [
        ("today", "Today: the -N and the new Health at R"),
        ("b", "B: portrait strike (C = R+47)"),
        ("c", "C: in place, no travel (C = R+32)"),
    ],
    "CB13": [
        ("today", "Today: 15 f fall; the number gone at H+33"),
        ("b", "B: tip and fall (22 f)"),
        ("c", "C: the light goes out (24 f)"),
    ],
}
TITLES = {
    "CB12": "CB12 damage to the player after a fight",
    "CB13": "CB13 a single death",
}
# CB13's single deaths (pilot/death.md, filming plan): the attacker killed in moment (b), and the
# last kill, into the result
DEATHS = [
    ("u8", "(b) Prophet of the Dust dies attacking"),
    ("u9", "the last kill, Nettle Sprout, into the result"),
]
# the beat specs, frames after the anchor (pilot/player-damage.md and death.md, section 4)
SPEC12 = {
    "b": {"windup": 12, "lift_end": 22, "launch": 37, "contact": 47, "contact_2": 62, "home": 66, "home_big": 81},
    "c": {"windup": 12, "contact": 32, "contact_2": 48},
}
SPEC13 = {
    "today": {"start_after_hit": 34, "last_drawn": 14, "number_to": None},
    "b": {"start_after_hit": 34, "tip_end": 7, "drop_start": 8, "opaque_to": 14, "last_drawn": 21, "number_to": 16},
    "c": {"start_after_hit": 34, "dark_end": 7, "hold": (8, 11), "sink_start": 12, "last_drawn": 23, "number_to": 18},
}
NUMBER_FADE = 8


def film_name(decision: str, option: str, fight: str = "", speed: float = 1.0) -> str:
    """today-win, cb12-b-lose-big, cb13-c, cb12-b-lose-big-x2 ..."""
    if option == "today":
        name = f"today-{fight or 'win'}"
    elif decision == "CB12":
        name = f"cb12-{option}-{fight}"
    else:
        name = f"cb13-{option}"
    return name + ("-x2" if speed != 1.0 else "")


def films() -> dict:
    """name -> scenario"""
    out = {}

    def add(name: str, treatment: str, options: dict, fight: str, wait: float, speed: float = 1.0) -> None:
        scenario = {
            "scene": SCENE,
            "treatment": treatment,
            "options": options,
            "steps": [{"move": "1900,1000", "time": 0.0}, {"wait": wait}],
        }
        if fight:
            scenario["fight"] = fight
        if speed != 1.0:
            scenario["speed"] = speed
        out[name] = scenario

    for fight in FIGHTS:
        wait = WAIT["win"] if fight == "win" else WAIT["short"]
        add(film_name("CB12", "today", fight), "today", {}, FIGHT_OF[fight], wait)
        for option in ("b", "c"):
            add(film_name("CB12", option, fight), "pilot", {"CB12": option}, FIGHT_OF[fight], wait)
    for option in ("b", "c"):
        add(film_name("CB13", option), "pilot", {"CB13": option}, "", WAIT["cb13"])
    # fight speed 2: the beats must scale (S4)
    for option in ("b", "c"):
        add(
            film_name("CB12", option, "lose-big", 2.0),
            "pilot",
            {"CB12": option},
            "lose-big",
            WAIT["short"] / 2 + 1.5,
            2.0,
        )
        add(film_name("CB13", option, "", 2.0), "pilot", {"CB13": option}, "", WAIT["cb13"] / 2 + 0.5, 2.0)
    return out


def cmd_scenarios(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, scenario in films().items():
        (out_dir / f"{name}.json").write_text(json.dumps(scenario, indent=2) + "\n")
        print(name)


# ---- reading a film's logs ----


def read_csv(path: Path) -> list:
    with path.open() as f:
        return list(csv.DictReader(f))


def markers_of(stem: Path) -> list:
    return read_csv(stem.with_suffix(".markers.csv"))


def first_marker(markers: list, name: str, key: str = "") -> int | None:
    for m in markers:
        if m["marker"] == name and (not key or m["key"] == key):
            return int(m["frame"])
    return None


def heroes_by_frame(stem: Path) -> dict:
    """{frame: {key: row}}"""
    out: dict = {}
    for row in read_csv(stem.with_suffix(".heroes.csv")):
        out.setdefault(int(row["frame"]), {})[row["key"]] = row
    return out


def num(row: dict, field: str) -> float:
    return float(row[field])


# ---- CB12 ----


def measure_cb12(stem: Path, report: dict) -> dict:
    markers = markers_of(stem)
    heroes = heroes_by_frame(stem)
    frames = sorted(heroes)
    r = first_marker(markers, "result_shown")
    treatment = report["treatment"]
    option = report.get("options", {}).get("CB12", "today") if treatment == "pilot" else "today"
    loser = "opponent" if report["fight"] == "comparison" else "hero"
    winner = "hero" if loser == "opponent" else "opponent"
    speed = float(report.get("speed", 1.0))
    before = heroes[r - 1]
    old = int(before[loser]["health"])
    home_w = (num(before[winner], "x"), num(before[winner], "y"))
    home_l = (num(before[loser], "x"), num(before[loser], "y"))

    def rel(frame: int | None) -> int | None:
        return None if frame is None else frame - r

    health_changes = [
        (f, int(heroes[f][loser]["health"]))
        for k, f in enumerate(frames)
        if k and f >= r and heroes[f][loser]["health"] != heroes[frames[k - 1]][loser]["health"]
    ]
    contact = first_marker(markers, "hero_contact")
    contact_2 = first_marker(markers, "hero_contact_2")
    after = [f for f in frames if f >= r]
    # the loser's portrait: first frame lit or moved
    reacts = next(
        (
            f
            for f in after
            if num(heroes[f][loser], "light") > 1.02
            or math.dist((num(heroes[f][loser], "x"), num(heroes[f][loser], "y")), home_l) > 0.5
        ),
        None,
    )
    moved_w = [
        f
        for f in after
        if math.dist((num(heroes[f][winner], "x"), num(heroes[f][winner], "y")), home_w) > 0.5
        or abs(num(heroes[f][winner], "scale") - 1.0) > 0.001
    ]
    stage = [(f, math.hypot(num(heroes[f][loser], "stage_x"), num(heroes[f][loser], "stage_y"))) for f in after]
    shaking = [f for f, d in stage if d > 0.05]
    burst = [(f, heroes[f][loser]) for f in after if float(heroes[f][loser]["burst_alpha"]) > 0.0]
    amounts = []
    for _, row in burst:
        a = int(row["burst_amount"])
        if not amounts or amounts[-1] != a:
            amounts.append(a)
    # striker: where its centre comes nearest the loser's
    dist = [(f, math.dist((num(heroes[f][winner], "x"), num(heroes[f][winner], "y")), home_l)) for f in after]
    nearest = min(dist, key=lambda fd: fd[1]) if dist else (None, None)
    last = frames[-1]
    end_w, end_l = heroes[last][winner], heroes[last][loser]
    changing = [
        f
        for k, f in enumerate(frames)
        if k
        and f >= r
        and any(
            heroes[f][key][c] != heroes[frames[k - 1]][key][c]
            for key in ("hero", "opponent")
            for c in ("x", "y", "scale", "rotation", "light", "health", "badge_scale", "stage_x", "stage_y")
        )
    ]
    out = {
        "option": option,
        "fight": report["fight"],
        "speed": speed,
        "loser": loser,
        "damage": report.get("damage"),
        "big_loss": report.get("big_loss"),
        "R": r,
        "health_old": old,
        "health_new": int(end_l["health"]),
        "health_first_change": rel(health_changes[0][0]) if health_changes else None,
        "health_final_at": rel(health_changes[-1][0]) if health_changes else None,
        "health_steps": [h for _, h in health_changes],
        "contact": rel(contact),
        "contact_2": rel(contact_2),
        "loser_reacts": rel(reacts),
        "striker_first_moves": rel(moved_w[0]) if moved_w else None,
        "striker_last_moves": rel(moved_w[-1] + 1) if moved_w else None,
        "striker_nearest": rel(nearest[0]),
        "striker_nearest_px": round(nearest[1], 1) if nearest[1] is not None else None,
        "shake_max_px": round(max((d for _, d in stage), default=0.0), 2),
        "shake_from": rel(shaking[0]) if shaking else None,
        "shake_to": rel(shaking[-1]) if shaking else None,
        "burst_from": rel(burst[0][0]) if burst else None,
        "burst_to": rel(burst[-1][0]) if burst else None,
        "burst_amounts": amounts,
        "badge_scale_max": round(max(num(heroes[f][loser], "badge_scale") for f in after), 3),
        "last_change": rel(changing[-1]) if changing else None,
        "end_at_rest": (
            math.dist((num(end_w, "x"), num(end_w, "y")), home_w) < 0.5
            and abs(num(end_w, "scale") - 1.0) < 0.001
            and abs(num(end_w, "rotation")) < 0.01
            and abs(num(end_l, "stage_x")) < 0.01
            and abs(num(end_l, "stage_y")) < 0.01
            and math.dist((num(end_l, "x"), num(end_l, "y")), home_l) < 0.5
        ),
        "sounds_after_R": [
            (int(m["frame"]) - r, m["detail"]) for m in markers if m["marker"] == "sound" and int(m["frame"]) >= r
        ],
        "markers": {m["marker"]: int(m["frame"]) - r for m in markers if m["marker"].startswith(("hero_", "health_"))},
    }
    # A1: flashes in the loser's portrait (its 128 px box), R to R+150, from the film's pixels
    box = (round(home_l[0]) - 64, round(home_l[1]) - 64, 128, 128)
    series = luminance(stem.with_suffix(".mp4"), box, r, min(r + 150, frames[-1]))
    out["portrait_luma"] = [round(min(series), 1), round(max(series), 1)] if series else None
    out["flashes_per_s"] = flashes(series)
    out["checks"] = checks_cb12(out)
    return out


def checks_cb12(m: dict) -> list:
    """[(check, pass/fail/n.a., measured)]: the filming plan's checks and the beat spec's frames."""
    c = m["contact"]
    k = 1 / m["speed"]
    out = [
        (
            "Health changes only at or after hero_contact",
            "fail" if c is None or (m["health_first_change"] or 0) < c else "pass",
            f"first change R+{m['health_first_change']}, contact {'R+' + str(c) if c is not None else 'none'}",
        ),
        (
            "contact to the first change on the portrait <= 3 f (T5)",
            "n.a." if c is None else ("pass" if 0 <= m["loser_reacts"] - c <= 3 else "fail"),
            f"portrait reacts R+{m['loser_reacts']}",
        ),
        (
            "shake <= 20 px and zero by C+30 (E4)",
            "n.a."
            if c is None
            else ("pass" if m["shake_max_px"] <= 20 and (m["shake_to"] or c) <= (m["contact_2"] or c) + 30 else "fail"),
            f"max {m['shake_max_px']} px, R+{m['shake_from']} to R+{m['shake_to']}",
        ),
        ("everything at rest at the end (S2)", "pass" if m["end_at_rest"] else "fail", ""),
        (
            "at most 3 flashes in any second in the loser's portrait (A1)",
            "pass" if m["flashes_per_s"] <= 3 else "fail",
            f"{m['flashes_per_s']} (portrait luma {m['portrait_luma']})",
        ),
        (
            "everything inside 150 f after R",
            "pass" if (m["last_change"] or 0) <= 150 * k else "fail",
            f"last change R+{m['last_change']}",
        ),
        (
            "the whole loss counted",
            "pass" if m["health_new"] == max(0, m["health_old"] - m["damage"]) else "fail",
            f"{m['health_old']} -> {m['health_new']} ({m['damage']}{', big' if m['big_loss'] else ''})",
        ),
    ]
    spec = SPEC12.get(m["option"])
    if spec:
        want = {"contact": round(spec["contact"] * k), "windup": round(spec["windup"] * k)}
        got = {"contact": c, "windup": m["striker_first_moves"]}
        if m["big_loss"]:
            want["contact_2"] = round(spec["contact_2"] * k)
            got["contact_2"] = m["contact_2"]
        if m["option"] == "b":
            want["home"] = round(spec["home_big" if m["big_loss"] else "home"] * k)
            got["home"] = m["striker_last_moves"]
            want["nearest"] = round(spec["contact_2" if m["big_loss"] else "contact"] * k)
            got["nearest"] = m["striker_nearest"]
        for name, frame in want.items():
            ok = got[name] is not None and abs(got[name] - frame) <= 1
            out.append((f"{name} at R+{frame} (spec, +-1 f)", "pass" if ok else "fail", f"R+{got[name]}"))
    return out


# ---- CB13 ----


def measure_cb13(stem: Path, report: dict) -> dict:
    treatment = report["treatment"]
    option = report.get("options", {}).get("CB13", "today") if treatment == "pilot" else "today"
    speed = float(report.get("speed", 1.0))
    markers = markers_of(stem)
    rows = read_csv(stem.with_suffix(".cards.csv"))
    r = first_marker(markers, "result_shown")
    out = {"option": option, "speed": speed, "R": r, "deaths": {}}
    for key, what in DEATHS:
        mine = sorted((row for row in rows if row["key"] == key), key=lambda row: int(row["frame"]))
        hit = next(
            (
                int(m["frame"])
                for m in markers
                if m["marker"] == "numbers" and m["key"] == key and m["detail"].endswith("/0")
            ),
            None,
        )
        leaving = [row for row in mine if row["state"] == "leaving"]
        if hit is None or not leaving:
            out["deaths"][key] = {"what": what, "error": "no killing hit or no death in the log"}
            continue
        d = int(leaving[0]["frame"])
        last = int(leaving[-1]["frame"])
        at_d = leaving[0]
        start = (float(at_d["x"]), float(at_d["y"]))
        # the killing number: the burst nearest the card just after the hit (it follows the card
        # home), by its node's name, while it stays within 120 px of the card (or of where the
        # card was when it was hit or started to die; the names Hit_0... come back for later hits)
        at = {int(row["frame"]): (float(row["x"]), float(row["y"])) for row in mine}
        near = [row for row in rows if row["card_id"] == "burst" and int(row["frame"]) == hit + 1 and hit + 1 in at]
        name = min(near, key=lambda row: math.dist((float(row["x"]), float(row["y"])), at[hit + 1]))["key"]
        bursts = [
            row
            for row in rows
            if row["key"] == name
            and hit <= int(row["frame"]) <= last + 40
            and min(
                math.dist((float(row["x"]), float(row["y"])), at.get(int(row["frame"]), start)),
                math.dist((float(row["x"]), float(row["y"])), start),
                math.dist((float(row["x"]), float(row["y"])), at.get(hit, start)),
            )
            < 120
            and float(row["alpha"]) > 0.0
        ]
        shown = sorted({int(row["frame"]) for row in bursts})
        full = sorted({int(row["frame"]) for row in bursts if float(row["alpha"]) >= 0.999})
        missing = [f for f in range(hit, last + 1) if f not in shown]
        per = []
        for row in leaving:
            per.append(
                {
                    "f": int(row["frame"]) - d,
                    "moved": round(math.dist((float(row["x"]), float(row["y"])), start), 1),
                    "rot": round(float(row["rotation"]), 1),
                    "scale": round(float(row["scale"]), 3),
                    "alpha": round(float(row["alpha"]), 3),
                    "light": round(float(row["light"]), 3),
                }
            )
        others = {}
        for row in rows:
            f = int(row["frame"])
            if row["card_id"] != "burst" and row["key"] != key and f in (d, last):
                others.setdefault(row["key"], {})[f] = (float(row["x"]), float(row["y"]))
        closer = []
        end = (float(leaving[-1]["x"]), float(leaving[-1]["y"]))
        for other, at in others.items():
            if d in at and last in at and math.dist(end, at[last]) < math.dist(start, at[d]) - 30:
                closer.append(other)
        death = {
            "what": what,
            "number_node": name,
            "H": hit,
            "D": d,
            "D_after_H": d - hit,
            "last_drawn": last - d,
            "card_out": (first_marker(markers, "card_out", key) or 0) - d,
            "number_shown_from_H": [shown[0] - hit, shown[-1] - hit] if shown else None,
            "number_full_to": (full[-1] - d) if full else None,
            "number_gone_at": (shown[-1] + 1 - d) if shown else None,
            "number_missing_H_to_last": [f - hit for f in missing][:5],
            "number_missing_count": len(missing),
            "moved_toward": closer,
            "frames": per,
        }
        # the same, from pixels, while the card dies: how red the box is where the number stands
        # (it stays there), against its red at H+8 or at D, whichever is more (today's number has
        # gone by D, so H+8 is the level to keep)
        popped = [row for row in rows if row["key"] == name and int(row["frame"]) == hit + 8]
        if popped:
            box = (float(popped[0]["x"]), float(popped[0]["y"]))
            peak = red_share(stem.with_suffix(".mp4"), box, hit + 8, hit + 8)[0]
            then = [row for row in bursts if int(row["frame"]) == d]
            if then:
                box = (float(then[0]["x"]), float(then[0]["y"]))
            reds = red_share(stem.with_suffix(".mp4"), box, d, last + 4)
            peak = max(peak, reds[0])
            lost = next((i for i, v in enumerate(reds) if v < peak / 2), None)
            seen = next((i for i, v in enumerate(reds) if v < peak / 10), None)
            death["number_pixels_peak"] = peak
            death["number_pixels_D_on"] = reds
            death["number_pixels_lost_at_D"] = lost
            death["number_pixels_gone_at_D"] = seen
        if r is not None and key == "u9":
            death["result_after_D"] = r - d
            death["cut_by_result"] = last < (d + SPEC13[option]["last_drawn"] / speed) - 1 and last < r
        death.update(beats13(option, per))
        out["deaths"][key] = death
    out["checks"] = checks_cb13(out)
    return out


def beats13(option: str, per: list) -> dict:
    """The frames after D each beat ends or starts, read off the per-frame rows."""
    beats: dict = {}
    if option == "b":
        top = next((p["f"] for p in per if abs(p["rot"]) > 13.95), None)
        beats["tip_end"] = top
        # the tip turns the card round its corner, so its centre moves from D; the drop is the
        # first frame it turns past the tip's 14 degrees
        beats["drop_start"] = next((p["f"] for p in per if abs(p["rot"]) > 14.05), None)
        beats["fade_start"] = next((p["f"] for p in per if p["alpha"] < 0.999), None)
        beats["end_rot"] = per[-1]["rot"]
        beats["end_moved"] = per[-1]["moved"]
        beats["end_scale"] = per[-1]["scale"]
        beats["light_after_tip"] = next((p["light"] for p in per if p["f"] == top), None)
    elif option == "c":
        beats["dark_end"] = next((p["f"] for p in per if abs(p["light"] - 0.25) < 0.005), None)
        beats["sink_start"] = next((p["f"] for p in per if p["moved"] > 0.05), None)
        beats["fade_start"] = next((p["f"] for p in per if p["alpha"] < 0.999), None)
        beats["end_moved"] = per[-1]["moved"]
        beats["end_scale"] = per[-1]["scale"]
    else:
        beats["fade_start"] = next((p["f"] for p in per if p["alpha"] < 0.999), None)
        beats["end_moved"] = per[-1]["moved"]
    return beats


def checks_cb13(m: dict) -> list:
    option = m["option"]
    k = 1 / m["speed"]
    spec = SPEC13[option]
    out = []
    for key, death in m["deaths"].items():
        if "error" in death:
            out.append((f"{key}: logged", "fail", death["error"]))
            continue
        gone = death["last_drawn"]
        out.append(
            (
                f"{key}: the killing number on every frame from H to the card's last",
                "pass" if death["number_missing_count"] == 0 else "fail",
                f"missing {death['number_missing_count']} frames, first H+{death['number_missing_H_to_last'][:1]}",
            )
        )
        lost = death.get("number_pixels_lost_at_D")
        seen = death.get("number_pixels_gone_at_D")
        held = spec["number_to"] if spec["number_to"] is not None else gone
        out.append(
            (
                f"{key}: the same from pixels: burst red over half its H+8 level to D+{held}, "
                "over a tenth to the card's last",
                "pass" if (lost is None or lost > held * k) and (seen is None or seen > gone) else "fail",
                f"half lost at D+{lost}, tenth at D+{seen}, card drawn to D+{gone}",
            )
        )
        out.append(
            (
                f"{key}: death starts at H+{round(spec['start_after_hit'] * k)} (+-1 f)",
                "pass" if abs(death["D_after_H"] - spec["start_after_hit"] * k) <= 1 else "fail",
                f"H+{death['D_after_H']}",
            )
        )
        out.append(
            (
                f"{key}: last drawn at D+{round(spec['last_drawn'] * k)} (+-1 f)",
                "pass" if abs(gone - spec["last_drawn"] * k) <= 1 else "fail",
                f"D+{gone}",
            )
        )
        if spec["number_to"] is not None:
            out.append(
                (
                    f"{key}: number full to D+{round(spec['number_to'] * k)}, gone by "
                    f"D+{round((spec['number_to'] + NUMBER_FADE) * k)} (+-1 f)",
                    "pass"
                    if abs((death["number_full_to"] or 0) - spec["number_to"] * k) <= 1
                    and abs((death["number_gone_at"] or 0) - (spec["number_to"] + NUMBER_FADE) * k) <= 1
                    else "fail",
                    f"full to D+{death['number_full_to']}, gone D+{death['number_gone_at']}",
                )
            )
        out.append(
            (
                f"{key}: some pixels change in the slot >= 15 f after the card is gone (D1 trace)",
                "n/a",
                "no trace in this option by design (the card is the only thing that moves)",
            )
        )
        out.append(
            (
                f"{key}: no card moves toward another card (V1)",
                "pass" if not death["moved_toward"] else "fail",
                ",".join(death["moved_toward"]),
            )
        )
        if option == "b":
            for name, want in (("tip_end", 7), ("drop_start", 8), ("fade_start", 15)):
                got = death.get(name)
                ok = got is not None and abs(got - want * k) <= 1
                out.append((f"{key}: {name} D+{round(want * k)} (+-1 f)", "pass" if ok else "fail", f"D+{got}"))
        if option == "c":
            for name, want in (("dark_end", 7), ("sink_start", 12)):
                got = death.get(name)
                ok = got is not None and abs(got - want * k) <= 1
                out.append((f"{key}: {name} D+{round(want * k)} (+-1 f)", "pass" if ok else "fail", f"D+{got}"))
        if "cut_by_result" in death:
            out.append(
                (
                    f"{key}: the last death is not cut by the result",
                    "fail" if death["cut_by_result"] else "pass",
                    f"R at D+{death['result_after_D']}",
                )
            )
    return out


def cmd_measure(stems: list) -> None:
    for stem in stems:
        report = json.loads(stem.with_suffix(".report.json").read_text())
        name = stem.name
        out = measure_cb13(stem, report) if name.startswith("cb13") else measure_cb12(stem, report)
        if name.startswith("today-win"):
            out = {"CB12": out, "CB13": measure_cb13(stem, report)}
        stem.with_suffix(".pilot.json").write_text(json.dumps(out, indent=1) + "\n")
        checks = out["checks"] if "checks" in out else out["CB12"]["checks"] + out["CB13"]["checks"]
        bad = [c for c in checks if c[1] == "fail"]
        counted = [c for c in checks if c[1] != "n/a"]
        print(
            f"{name}: {len(counted) - len(bad)}/{len(counted)} pass" + "".join(f"\n  FAIL {c[0]}: {c[2]}" for c in bad)
        )


# ---- the flash check (A1), from the film's pixels ----


def luminance(film: Path, crop: tuple, first: int, last: int) -> list:
    """Mean luma (0-255) of a region on each frame first..last."""
    x, y, w, h = crop
    got = subprocess.run(
        [
            "ffmpeg",
            "-loglevel",
            "error",
            "-i",
            str(film),
            "-vf",
            f"trim=start_frame={first}:end_frame={last + 1},setpts=PTS-STARTPTS,crop={w}:{h}:{x}:{y},signalstats,"
            "metadata=print:key=lavfi.signalstats.YAVG:file=-",
            "-f",
            "null",
            "-",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return [float(line.split("=")[1]) for line in got.stdout.splitlines() if "YAVG" in line]


def red_share(film: Path, centre: tuple, first: int, last: int, side: int = 40) -> list:
    """Per frame first..last, how red a side x side box round centre is (mean of r - max(g, b),
    0-1): the burst's red glass, which scales with its opacity, so whether the "-N" is on screen,
    read from pixels. A card's warm art under it counts too."""
    x, y = round(centre[0] - side / 2), round(centre[1] - side / 2)
    got = subprocess.run(
        [
            "ffmpeg",
            "-loglevel",
            "error",
            "-i",
            str(film),
            "-vf",
            f"trim=start_frame={first}:end_frame={last + 1},setpts=PTS-STARTPTS,crop={side}:{side}:{x}:{y}",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "-",
        ],
        check=True,
        capture_output=True,
    )
    size = side * side * 3
    out = []
    for k in range(len(got.stdout) // size):
        px = got.stdout[k * size : (k + 1) * size]
        red = sum(max(0, px[i] - max(px[i + 1], px[i + 2])) for i in range(0, size, 3))
        out.append(round(red / (side * side) / 255, 3))
    return out


def flashes(series: list, window: int = 60) -> int:
    """WCAG 2.3.1's general flash, roughly: a pair of opposing changes of at least 10 % of the
    brighter level. The most flashes in any `window` frames."""
    turns = []
    low = high = series[0] if series else 0.0
    rising = None
    for i, v in enumerate(series):
        if rising is not False and v < high * 0.9:
            turns.append(i)
            rising, low = False, v
        elif rising is not True and v > low / 0.9 and v - low > 0.1 * max(v, 1.0):
            turns.append(i)
            rising, high = True, v
        low, high = min(low, v), max(high, v)
    best = 0
    for i in range(len(turns)):
        n = sum(1 for t in turns[i:] if t - turns[i] < window)
        best = max(best, n // 2)
    return best


# ---- clips ----


@contextlib.contextmanager
def cropped(crop: tuple):
    kept = clips.CROP
    clips.CROP = crop
    try:
        yield
    finally:
        clips.CROP = kept


def windows(decision: str, film_dir: Path) -> tuple:
    """[(segment, [(option, film, ref, lo, hi)])], the counter's letter."""
    segs = []
    if decision == "CB12":
        for fight in FIGHTS:
            row = []
            for option, _ in OPTIONS["CB12"]:
                film = film_name("CB12", option, fight)
                m = json.loads((film_dir / f"{film}.pilot.json").read_text())
                m = m.get("CB12", m)
                # lined up on the result (R), as the spec says: whether B's travel is worth its
                # time shows as how much later its hit lands than C's
                r = m["R"]
                row.append((option, film, r, r - 12, r + 140))
            segs.append((FIGHT_WHAT[fight], row))
        return segs, "R"
    for k, (key, what) in enumerate(DEATHS):
        row = []
        for option, _ in OPTIONS["CB13"]:
            film = "today-win" if option == "today" else film_name("CB13", option)
            m = json.loads((film_dir / f"{film}.pilot.json").read_text())
            m = m.get("CB13", m)
            death = m["deaths"][key]
            hi = death["D"] + 40 if k == 0 else m["R"] + 30
            row.append((option, film, death["H"], death["H"] - 20, hi))
        segs.append((what, row))
    return segs, "H"


def plan(decision: str, film_dir: Path) -> tuple:
    segs, letter = windows(decision, film_dir)
    parts = {option: [] for option, _ in OPTIONS[decision]}
    films_ = {}
    out_segs = []
    start = 0
    for what, row in segs:
        firsts, length = clips.aligned([(ref, lo, hi) for _, _, ref, lo, hi in row])
        before = row[0][2] - firsts[0]
        for (option, film, ref, _, _), first in zip(row, firsts, strict=True):
            parts[option].append((first, length, ref))
            films_.setdefault(option, []).append(film)
        out_segs.append(
            {
                "what": what,
                "reference": letter,
                "start": start,
                "frames": length,
                "before": before,
                "reference_index": start + before,
                "counter_at_start": -before,
            }
        )
        start += length
    return out_segs, parts, films_, start, letter


def cut_parts(films: list, parts: list, out: Path, scale: float) -> None:
    """Like clips.cut_plain, one part per segment, each from its own film."""
    x, y, w, h = clips.CROP
    width = round(w * scale / 2) * 2
    args, chains = [], []
    for i, (film, (first, length, _)) in enumerate(zip(films, parts, strict=True)):
        args += ["-i", str(film)]
        chains.append(
            f"[{i}:v]trim=start_frame={first}:end_frame={first + length},setpts=PTS-STARTPTS,"
            f"crop={w}:{h}:{x}:{y},scale={width}:-2[s{i}]"
        )
    joined = "".join(f"[s{i}]" for i in range(len(parts)))
    tail = f"{joined}concat=n={len(parts)}:v=1:a=0[v]" if len(parts) > 1 else f"{joined}null[v]"
    out.parent.mkdir(parents=True, exist_ok=True)
    clips.run([*args, "-filter_complex", ";".join([*chains, tail]), "-map", "[v]", *clips.COMPARE_ENCODE, str(out)])


def measured_entry(decision: str, film_dir: Path, films: list) -> dict:
    out = {}
    for film in dict.fromkeys(films):
        m = json.loads((film_dir / f"{film}.pilot.json").read_text())
        m = m.get(decision, m)
        if decision == "CB12":
            out[m["fight"]] = {
                k: m[k]
                for k in (
                    "damage",
                    "big_loss",
                    "health_old",
                    "health_new",
                    "contact",
                    "contact_2",
                    "health_first_change",
                    "health_final_at",
                    "striker_first_moves",
                    "striker_last_moves",
                    "shake_max_px",
                    "burst_from",
                    "burst_to",
                    "burst_amounts",
                    "last_change",
                )
            }
            out[m["fight"]]["flashes_per_s"] = m.get("flashes_per_s")
        else:
            for key, death in m["deaths"].items():
                out[key] = {k: v for k, v in death.items() if k != "frames"}
    return out


def cmd_compare(film_dir: Path, out_dir: Path, scale: float) -> None:
    for decision in ("CB12", "CB13"):
        crop = WHOLE if decision == "CB12" else clips.CROP
        segs, parts, films_, frames, letter = plan(decision, film_dir)
        entry = {
            "title": TITLES[decision],
            "reference": letter,
            "before": segs[0]["before"],
            "frames": frames,
            "fps": FPS,
            "crop": list(crop),
            "scale": scale,
            "segments": segs,
            "options": [],
        }
        with cropped(crop):
            for option, label in OPTIONS[decision]:
                out = out_dir / decision / f"{option}.mp4"
                cut_parts([film_dir / f"{f}.mp4" for f in films_[option]], parts[option], out, scale)
                entry["options"].append(
                    {
                        "option": option,
                        "file": f"{decision}/{option}.mp4",
                        "label": label,
                        "film": films_[option][0] if len(set(films_[option])) == 1 else films_[option],
                        "film_frames": [[first, first + length - 1] for first, length, _ in parts[option]],
                        "measured": measured_entry(decision, film_dir, films_[option]),
                    }
                )
                print(out)
        (out_dir / f"{decision}.json").write_text(json.dumps(entry, indent=1) + "\n")
        print(out_dir / f"{decision}.json")


def cmd_cut(film_dir: Path, clip_dir: Path) -> None:
    clip_dir.mkdir(parents=True, exist_ok=True)
    for decision in ("CB12", "CB13"):
        crop = WHOLE if decision == "CB12" else clips.CROP
        segs, parts, films_, _, letter = plan(decision, film_dir)
        labels = [label for _, label in OPTIONS[decision]]
        pieces = []
        with cropped(crop), tempfile.TemporaryDirectory() as tmp:
            for k, seg in enumerate(segs):
                inputs = [film_dir / f"{films_[option][k]}.mp4" for option, _ in OPTIONS[decision]]
                firsts = [parts[option][k][0] for option, _ in OPTIONS[decision]]
                refs = [parts[option][k][2] for option, _ in OPTIONS[decision]]
                part = Path(tmp) / f"{decision}-{k}.mp4"
                clips.stack(
                    inputs,
                    firsts,
                    seg["frames"],
                    refs,
                    letter,
                    labels,
                    f"{TITLES[decision]}  ·  {seg['what']}  ·  panes lined up at {letter}",
                    part,
                )
                pieces.append(part)
            out = clip_dir / f"{decision}.mp4"
            if len(pieces) == 1:
                pieces[0].replace(out)
            else:
                clips.concat(pieces, out)
        plays = clips.loop3(out)
        print(out, f"plays {plays}x")


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
        cmd_compare(Path(sys.argv[2]), Path(sys.argv[3]), float(sys.argv[4]) if len(sys.argv) > 4 else 0.38)
    elif what == "cut":
        cmd_cut(Path(sys.argv[2]), Path(sys.argv[3]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
