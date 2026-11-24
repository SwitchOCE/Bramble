#!/usr/bin/env python3
"""CB16, late-fight speed-ups: one real late fight filmed whole, today, the proposal (`best`) and
the speed-up what-ifs of research/fight-length.md, played on the fight screen.

Usage:
  speed_clips.py scenarios OUT_DIR [FIGHT]   one scenario per option (FIGHT: a fights/<name>.json
                                             saved by fight_length.gd; default the median, r10-074)
  speed_clips.py measure FILM_DIR            FILM_DIR/cb16.json: each film's length to the result
  speed_clips.py compare FILM_DIR OUT_DIR [SCALE]  OUT_DIR/CB16/<option>.mp4 (no labels, the
                                             battlefield crop at SCALE, default 0.38) and
                                             OUT_DIR/CB16.json; manifest.json is left alone
  speed_clips.py cut FILM_DIR CLIP_DIR       CLIP_DIR/CB16.mp4, the five side by side

Every clip is the whole fight from its first step (F+0, the fight screen's first frame), each
pane counting frames from there. Films are made with tools/feel/film from the scenarios.
Exploratory: nothing here is the game, and no one has watched it move.
"""

import contextlib
import csv
import json
import math
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import clips

FIGHTS = Path("/data/fight-anim-work/fight-length/fights")
MEDIAN = "r10-074"
FPS = 60
# both boards in film pixels: a late fight has seven a side, so their back row shows too (the
# comparison fight's CROP cuts it off); the compare format's 0.38 scale is kept
CROP = (485, 40, 950, 1030)
TITLE = "CB16 late-fight speed-ups (fight r10-074, the median late fight)"
# option, film, label, treatment, options (best_timeline.gd: FAST, GROUP, R7), film seconds of wait
OPTIONS = [
    ("today", "cb16-today", "Today (the game now)", "today", {}, 32.5),
    ("best", "cb16-best", "Best (the proposal)", "best", {}, 19.5),
    ("fast", "cb16-fast", "Best, x1.5 from attack 5", "best", {"FAST": "a5"}, 16.5),
    ("group", "cb16-group", "+ up to 3 triggers at once", "best", {"FAST": "a5", "GROUP": 3}, 16.0),
    (
        "rule7",
        "cb16-rule7",
        "+ rule 7 early x2 (best mix)",
        "best",
        {"FAST": "a5", "GROUP": 3, "R7": "early_x2"},
        16.0,
    ),
]
# lengths.json's variant per option, and whether FAST plays on top (fight_length.py's x1.5 from attack 5)
PREDICT = {"today": ("today", False), "best": ("best", False), "fast": ("best", True), "group": ("G3", True)}
PREDICT["rule7"] = ("G3-R7-early_x2", True)


def cmd_scenarios(out_dir: Path, fight: str) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    spec = FIGHTS / f"{fight}.json"
    for option, film, _, treatment, chosen, wait in OPTIONS:
        scenario = {
            "scene": clips.SCENE,
            "treatment": treatment,
            "fight": f"spec:{spec}",
            "steps": [{"move": "1900,1000", "time": 0.0}, {"wait": wait}],
        }
        if chosen:
            scenario["options"] = chosen
        (out_dir / f"{film}.json").write_text(json.dumps(scenario, indent=2) + "\n")
        print(film, option, json.dumps(chosen))


def predicted(fight: str, option: str) -> int | None:
    """Frames to the result from fight_length.gd's headless count (lengths.json beside the
    fights), with FAST as the clock plays it: whole frames to its start, then x1.5 to the result."""
    lengths = FIGHTS.parent / "lengths.json"
    if not lengths.exists():
        return None
    row = next((f for f in json.loads(lengths.read_text())["fights"] if f["name"] == fight), None)
    if row is None:
        return None
    variant, fast = PREDICT[option]
    got = row["today"] if variant == "today" else row["variants"][variant]
    result = got["result"]
    cycles = got.get("cycles", [])
    if not fast or len(cycles) < 5:
        return result
    start = cycles[4]["from"]
    return start + math.ceil((result - start) / 1.5)


def fight_start(stem: Path) -> int:
    """The film frame of the fight's first step (F+0)."""
    with stem.with_suffix(".markers.csv").open() as f:
        return min(int(m["frame"]) for m in csv.DictReader(f) if m["marker"] == "step")


def sounds(stem: Path) -> int:
    with stem.with_suffix(".markers.csv").open() as f:
        return sum(1 for m in csv.DictReader(f) if m["marker"] == "sound")


def measured(film_dir: Path, fight: str) -> dict:
    out = {}
    for option, film, label, _, chosen, _ in OPTIONS:
        stem = film_dir / film
        report = json.loads(stem.with_suffix(".report.json").read_text())
        plan = report.get("plan") or {}
        start = fight_start(stem)
        result = round(report["result_at"] * FPS)
        fast = plan.get("fast", {})
        entry = {
            "label": label,
            "options": chosen,
            "fight_start_frame": start,
            "result_frame": result,
            "to_result_s": round(report["result_at"], 2),
            "headless_predicted_frames": predicted(fight, option),
            "core_matches": report.get("core_matches"),
            "attacks": len(report.get("attacks", [])),
            "sound_cues_started": sounds(stem),
            "film_frames": clips.count_frames(stem.with_suffix(".mp4")),
        }
        if fast.get("from", -1) >= 0:
            # the speed-up's start in film frames: the schedule's frames are drawn frames before it
            entry["fast_from_film_frame"] = fast["from"] + plan.get("frame_offset", 0)
            entry["fast_speed"] = fast["speed"]
        out[option] = entry
    return out


def cmd_measure(film_dir: Path, fight: str) -> None:
    got = measured(film_dir, fight)
    (film_dir / "cb16.json").write_text(json.dumps(got, indent=1) + "\n")
    for option, m in got.items():
        print(
            option,
            m["to_result_s"],
            "s; result frame",
            m["result_frame"],
            "predicted",
            m["headless_predicted_frames"],
            "core",
            m["core_matches"],
        )


@contextlib.contextmanager
def board_crop():
    """clips.cut_plain with CB16's crop."""
    was = clips.CROP
    clips.CROP = CROP
    try:
        yield
    finally:
        clips.CROP = was


def cmd_compare(film_dir: Path, out_dir: Path, scale: float, fight: str) -> None:
    got = measured(film_dir, fight)
    frames = {option: got[option]["film_frames"] - got[option]["fight_start_frame"] for option in got}
    longest = max(frames.values())
    entry = {
        "title": TITLE,
        "reference": "F",
        "before": 0,
        "frames": longest,
        "fps": 60,
        "crop": list(CROP),
        "scale": scale,
        "segments": [
            {
                "what": "the whole fight, from its first frame",
                "reference": "F",
                "start": 0,
                "frames": longest,
                "before": 0,
                "reference_index": 0,
                "counter_at_start": 0,
            }
        ],
        "options": [],
    }
    for option, film, label, _, _, _ in OPTIONS:
        first = got[option]["fight_start_frame"]
        out = out_dir / "CB16" / f"{option}.mp4"
        with board_crop():
            clips.cut_plain(film_dir / f"{film}.mp4", [(first, frames[option])], out, scale)
        entry["options"].append(
            {
                "option": option,
                "file": f"CB16/{option}.mp4",
                "label": label,
                "film": film,
                "frames": frames[option],
                "film_frames": [[first, first + frames[option] - 1]],
                "measured": got[option],
            }
        )
        print(out)
    (out_dir / "CB16.json").write_text(json.dumps(entry, indent=1) + "\n")
    print(out_dir / "CB16.json")


def cmd_cut(film_dir: Path, clip_dir: Path, fight: str) -> None:
    """The five side by side, each from its F+0, the shorter ones holding their last frame."""
    clip_dir.mkdir(parents=True, exist_ok=True)
    got = measured(film_dir, fight)
    frames = {option: got[option]["film_frames"] - got[option]["fight_start_frame"] for option in got}
    longest = max(frames.values())
    x, y, w, h = CROP
    width = min(640, (1920 // len(OPTIONS)) // 2 * 2)
    size = max(14, round(width / 22))
    out = clip_dir / "CB16.mp4"
    with tempfile.TemporaryDirectory() as tmp:
        chains = []
        args = []
        for i, (option, film, label, _, _, _) in enumerate(OPTIONS):
            args += ["-i", str(film_dir / f"{film}.mp4")]
            lf = Path(tmp) / f"label{i}.txt"
            lf.write_text(label)
            rf = Path(tmp) / f"result{i}.txt"
            rf.write_text(f"result at {got[option]['to_result_s']:.1f} s")
            first = got[option]["fight_start_frame"]
            pad = (longest - frames[option]) / FPS + 0.1
            pos = f"fontsize={size}:x=8:y={size * 2 + 18}"
            chains.append(
                f"[{i}:v]trim=start_frame={first},setpts=PTS-STARTPTS,crop={w}:{h}:{x}:{y},"
                f"scale={width}:-2,tpad=stop_mode=clone:stop_duration={pad:.2f},"
                f"pad=iw:ih+{size * 3 + 20}:0:{size * 3 + 20}:color=white,"
                f"drawtext=fontfile={clips.FONT_BOLD}:textfile={lf}:fontsize={size}:fontcolor=black:x=8:y=6,"
                f"drawtext=fontfile={clips.FONT}:textfile={rf}:fontsize={size}:fontcolor=black:x=8:y={size + 12},"
                + clips.counter("F", 0).replace("{pos}", pos)
                + f"[p{i}]"
            )
        tf = Path(tmp) / "title.txt"
        tf.write_text(f"{TITLE}  ·  panes start together at F+0, the fight's first frame")
        joined = "".join(f"[p{i}]" for i in range(len(OPTIONS)))
        tail = (
            f"{joined}hstack=inputs={len(OPTIONS)},pad=iw:ih+40:0:40:color=0x222222,"
            f"drawtext=fontfile={clips.FONT}:textfile={tf}:fontsize=22:fontcolor=white:x=10:y=9[v]"
        )
        clips.run(
            [
                *args,
                "-filter_complex",
                ";".join([*chains, tail]),
                "-map",
                "[v]",
                "-frames:v",
                str(longest),
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
    listing = clip_dir / "clips.json"
    index = json.loads(listing.read_text()) if listing.exists() else {}
    index["CB16"] = {
        "file": out.name,
        "plays": 1,
        "options": [f"{option} ({film})" for option, film, *_ in OPTIONS],
        "ranges": [
            {
                "segment": "the whole fight",
                "reference": "F",
                "before": 0,
                "after": longest - 1,
                "film_frames": {
                    film: [got[o]["fight_start_frame"], got[o]["film_frames"] - 1, got[o]["fight_start_frame"]]
                    for o, film, *_ in OPTIONS
                },
            }
        ],
    }
    listing.write_text(json.dumps(index, indent=1) + "\n")
    print(out, longest, "frames")


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    what = sys.argv[1]
    if what == "scenarios":
        cmd_scenarios(Path(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else MEDIAN)
    elif what == "measure":
        cmd_measure(Path(sys.argv[2]), MEDIAN)
    elif what == "compare":
        scale = float(sys.argv[4]) if len(sys.argv) > 4 else 0.38
        cmd_compare(Path(sys.argv[2]), Path(sys.argv[3]), scale, MEDIAN)
    elif what == "cut":
        cmd_cut(Path(sys.argv[2]), Path(sys.argv[3]), MEDIAN)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
