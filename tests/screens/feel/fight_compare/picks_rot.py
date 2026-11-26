#!/usr/bin/env python3
"""The picks page's pairs (docs/workstreams/fight-animation-24-nov/page/picks.html), filmed again
with the rotation switch on in every pane (rotate.gd; the owner, 24 Nov: "Every animation, I want
to have the rotation included"), plus the whole fight: today with rotation against `recommended`
(every pick together). Borrows clips.py, pilot_clips.py and buff_clips.py's measuring and cutting;
writes only under its own folders.

Usage:
  picks_rot.py scenarios OUT_DIR            one scenario JSON per film, rotation on in each
  picks_rot.py measure FILM_DIR             each film's timing / pilot / buffs JSON
  picks_rot.py cut FILM_DIR OUT_DIR         OUT_DIR/<branch>-<option>.mp4 per pane and pairs.json

Films are made with tools/feel/film from the scenarios. Exploratory: nothing here is the game.
"""

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import buff_clips
import clips
import pilot_clips

ROTATE = {"ROTATE": "on"}
# the whole-fight films share one wait, so both panes have the same frames
WHOLE_WAIT = 15.0
SHORT_WAIT = pilot_clips.WAIT["short"]
# film -> (treatment, options, fight, wait); rotation is added to every film's options
FILMS = {
    "today-win": ("today", {}, "", WHOLE_WAIT),
    "best": ("best", {}, "", 13.5),
    "cb1-today": ("best", {"CB1": "today"}, "", 13.5),
    "cb4-freeze": ("best", {"CB4": "freeze"}, "", 13.5),
    "cb8-c": ("best", {"CB8": "c"}, "", 13.5),
    "cb11-quad": ("best", {"CB2": "b", "CB3": "quad"}, "", 13.5),
    "cb11-mild": ("best", {"CB2": "b", "CB3": "mild"}, "", 13.5),
    "cb13-c": ("pilot", {"CB13": "c"}, "", pilot_clips.WAIT["cb13"]),
    "cb14-c": ("buffs", {"CB14": "c"}, "", buff_clips.WAIT),
    "cb12-b-win": ("pilot", {"CB12": "b"}, "", WHOLE_WAIT),
    **{f"cb12-b-{f}": ("pilot", {"CB12": "b"}, f, SHORT_WAIT) for f in ("lose-small", "lose-big", "lose-out")},
    **{f"today-{f}": ("today", {}, f, SHORT_WAIT) for f in ("lose-small", "lose-big", "lose-out")},
    "recommended": ("recommended", {}, "", WHOLE_WAIT),
}
# which measure each film needs: clips.py timing (best's plan), pilot_clips.py, buff_clips.py
TIMED = ["best", "cb1-today", "cb4-freeze", "cb8-c", "cb11-quad", "cb11-mild"]
PILOTED = [
    "today-win",
    "cb13-c",
    "cb12-b-win",
    *[f"{o}-{f}" for o in ("cb12-b", "today") for f in ("lose-small", "lose-big", "lose-out")],
]
BUFFED = ["today-win", "cb14-c"]

ON = " (turning on)"
# branch -> (title, [(option, film, label)] left then right), as picks.html pairs them
PAIRS = {
    "CB1": (
        "The wind-up",
        [
            ("today", "cb1-today", "Today: a 4-frame lift, no hold" + ON),
            ("best", "best", "Lift, then a clear still hold before the strike" + ON),
        ],
    ),
    "CB11": (
        "Strike speed",
        [
            ("quad", "cb11-quad", "Today's strong speed-up" + ON),
            ("mild", "cb11-mild", "A milder speed-up into contact" + ON),
        ],
    ),
    "CB4": (
        "Thorns, before the hit",
        [
            ("freeze", "cb4-freeze", "Today: the attacker freezes mid-strike" + ON),
            ("hold", "best", "Thorns plays while the attacker is still raised" + ON),
        ],
    ),
    "CB8": (
        "Several deaths at once",
        [
            ("a", "best", "All six fall together" + ON),
            ("c", "cb8-c", "They fall one after another, speeding up" + ON),
        ],
    ),
    "CB13": (
        "A single death",
        [
            ("today", "today-win", "Today: the number is gone before the card falls" + ON),
            ("c", "cb13-c", "The number stays; the card's light goes out and it sinks" + ON),
        ],
    ),
    "CB14": (
        "A stat gain (Old Brock)",
        [
            ("today", "today-win", "Today: 10/9 to 24/33 in one frame" + ON),
            ("c", "cb14-c", "Each +N flies from the dead card into the stat" + ON),
        ],
    ),
    "CB12": (
        "Damage to the player",
        [
            ("today", "today", "Today: the new Health shows before anything hits" + ON),
            ("b", "cb12-b", "The winner's portrait strikes, turning toward the loser" + ON),
        ],
    ),
}
COMPARE_SCALE = 0.38


def cmd_scenarios(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (treatment, options, fight, wait) in FILMS.items():
        scenario = {
            "scene": clips.SCENE,
            "treatment": treatment,
            "options": {**options, **ROTATE},
            "steps": [{"move": "1900,1000", "time": 0.0}, {"wait": wait}],
        }
        if fight:
            scenario["fight"] = fight
        (out_dir / f"{name}.json").write_text(json.dumps(scenario, indent=2) + "\n")
        print(name, treatment, json.dumps(scenario["options"]), fight)


def cmd_measure(film_dir: Path) -> None:
    clips.cmd_measure([film_dir / f for f in TIMED])
    pilot_clips.cmd_measure([film_dir / f for f in PILOTED])
    buff_clips.cmd_measure([film_dir / f for f in BUFFED])


def frames_of(path: Path) -> int:
    out = subprocess.run(
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
    return int(out.stdout.strip())


def best_windows(branch: str, film_dir: Path, films: list) -> tuple:
    """clips.py compare's windows for a best-schedule branch: [(what, [(film, ref, lo, hi)])], letter."""
    plans = {f: clips.plan_frames(film_dir, f) for f in films}
    refs = {f: clips.references(film_dir, f, branch) for f in films}
    names = [n for n, _, _ in clips.segments(branch, plans[films[0]])]
    segs = []
    for k, name in enumerate(names):
        segs.append((name, [(f, refs[f][k], *clips.segments(branch, plans[f])[k][1:]) for f in films]))
    return segs, clips.ref_names(branch, len(names))[0]


def pilot_windows(branch: str, film_dir: Path, films: list) -> tuple:
    """pilot_clips.py windows for two films: CB12 on R per fight, CB13 on the killing hit H."""
    segs = []
    if branch == "CB12":
        for fight in pilot_clips.FIGHTS:
            row = []
            for f in films:
                film = f"{f}-{fight}"  # today-win, cb12-b-lose-big ...
                m = json.loads((film_dir / f"{film}.pilot.json").read_text())
                m = m.get("CB12", m)
                row.append((film, m["R"], m["R"] - 12, m["R"] + 140))
            segs.append((pilot_clips.FIGHT_WHAT[fight], row))
        return segs, "R"
    for k, (key, what) in enumerate(pilot_clips.DEATHS):
        row = []
        for film in films:
            m = json.loads((film_dir / f"{film}.pilot.json").read_text())
            m = m.get("CB13", m)
            death = m["deaths"][key]
            hi = death["D"] + 40 if k == 0 else m["R"] + 30
            row.append((film, death["H"], death["H"] - 20, hi))
        segs.append((what, row))
    return segs, "H"


def buff_windows(film_dir: Path, films: list) -> tuple:
    row = []
    for film in films:
        m = json.loads((film_dir / f"{film}.buffs.json").read_text())
        g = m["G"]
        row.append((film, g, g - buff_clips.BEFORE, min(g + buff_clips.AFTER, m["last_frame"])))
    return [(buff_clips.WHAT, row)], "G"


def cut_pair(branch: str, film_dir: Path, out_dir: Path) -> dict:
    title, sides = PAIRS[branch]
    films = [film for _, film, _ in sides]
    crop, scale = clips.CROP, COMPARE_SCALE
    if branch in ("CB12", "CB13"):
        segs, letter = pilot_windows(branch, film_dir, films)
        crop = pilot_clips.WHOLE if branch == "CB12" else clips.CROP
    elif branch == "CB14":
        segs, letter = buff_windows(film_dir, films)
        crop, scale = buff_clips.CROP, buff_clips.SCALE
    else:
        segs, letter = best_windows(branch, film_dir, films)
    parts = [[], []]
    out_segs = []
    start = 0
    for what, row in segs:
        firsts, length = clips.aligned([(ref, lo, hi) for _, ref, lo, hi in row])
        before = row[0][1] - firsts[0]
        for side, ((film, ref, _, _), first) in enumerate(zip(row, firsts, strict=True)):
            parts[side].append((film, first, length, ref))
        out_segs.append({"what": what, "reference": letter, "start": start, "frames": length, "before": before})
        start += length
    entry = {
        "pair": branch,
        "title": title,
        "reference": letter,
        "frames": start,
        "crop": list(crop),
        "scale": scale,
        "segments": out_segs,
        "panes": [],
    }
    kept = clips.CROP
    clips.CROP = crop
    try:
        for side, (option, _, label) in enumerate(sides):
            out = out_dir / f"{branch}-{option}.mp4"
            pilot_clips.cut_parts(
                [film_dir / f"{p[0]}.mp4" for p in parts[side]], [(p[1], p[2], p[3]) for p in parts[side]], out, scale
            )
            entry["panes"].append(
                {
                    "option": option,
                    "file": out.name,
                    "label": label,
                    "frames": frames_of(out),
                    "films": [p[0] for p in parts[side]],
                    "film_frames": [[p[1], p[1] + p[2] - 1] for p in parts[side]],
                }
            )
            print(out)
    finally:
        clips.CROP = kept
    return entry


def cut_whole(film_dir: Path, out_dir: Path) -> dict:
    sides = [
        ("today", "today-win", "Today's build" + ON),
        ("best", "recommended", "Every recommendation together" + ON),
    ]
    length = min(frames_of(film_dir / f"{film}.mp4") for _, film, _ in sides)
    entry = {
        "pair": "whole",
        "title": "The whole fight",
        "reference": "",
        "frames": length,
        "crop": list(clips.CROP),
        "scale": COMPARE_SCALE,
        "segments": [],
        "panes": [],
    }
    for option, film, label in sides:
        out = out_dir / f"whole-{option}.mp4"
        clips.cut_plain(film_dir / f"{film}.mp4", [(0, length)], out, COMPARE_SCALE)
        report = json.loads((film_dir / f"{film}.report.json").read_text())
        entry["panes"].append(
            {
                "option": option,
                "file": out.name,
                "label": label,
                "frames": frames_of(out),
                "films": [film],
                "film_frames": [[0, length - 1]],
                "victory_s": round(report["result_at"], 2),
                "victory_frame": round(report["result_at"] * 60),
                "core_matches": report.get("core_matches"),
            }
        )
        print(out)
    return entry


def cmd_cut(film_dir: Path, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    pairs = [cut_whole(film_dir, out_dir)] + [cut_pair(b, film_dir, out_dir) for b in PAIRS]
    for pair in pairs:
        counts = {p["frames"] for p in pair["panes"]}
        if len(counts) != 1:
            raise SystemExit(f"{pair['pair']}: panes differ in frames {sorted(counts)}")
    doc = {"rotation": "on in every pane (rotate.gd SET)", "fps": 60, "pairs": pairs}
    (out_dir / "pairs.json").write_text(json.dumps(doc, indent=1) + "\n")
    print(out_dir / "pairs.json")


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    what = sys.argv[1]
    if what == "scenarios":
        cmd_scenarios(Path(sys.argv[2]))
    elif what == "measure":
        cmd_measure(Path(sys.argv[2]))
    elif what == "cut" and len(sys.argv) > 3:
        cmd_cut(Path(sys.argv[2]), Path(sys.argv[3]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
