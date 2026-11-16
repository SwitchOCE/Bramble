#!/usr/bin/env python3
"""Shoots a Godot scene and its HTML mock-up at the same size, and writes them side by side.

    python3 tools/glass/compare.py res://src/glass/card_sheet.tscn cards.html --size 1920x1220
    python3 tools/glass/compare.py res://src/screens/recruit.tscn recruit.html --size 1920x1080 --query size=b
    python3 tools/glass/compare.py res://tests/screens/recruit_discover.tscn recruit-play.html \\
        --local docs/ideation-track-2/mockups/recruit-play.html --query discover=1

The mock-up page is named inside docs/design/art-direction/mockups on the mock-ups branch, at the
commit assets/glass/source.json records (--ref for another). It is rendered with the headless
Chromium that Playwright keeps in ~/.cache/ms-playwright, in dark mode, with ?shot added to the
query. The scene is shot with tools/look/look. Output goes outside Git, to
${XDG_STATE_HOME:-~/.local/state}/bramble/glass-compare/<time>/ (or --out):
mockup.png, godot.png, stacked.png (mock-up above, Godot below), diff.png (difference x4).
Prints the mean difference (0-255) and the share of pixels that differ by more than 32.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import subprocess
import sys
import tarfile
import time
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
MOCKUPS = "docs/design/art-direction/mockups"
LOOK = ROOT / "tools" / "look" / "look"
CHROMIUM_GLOB = "chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell"


def chromium() -> Path:
    found = sorted((Path.home() / ".cache" / "ms-playwright").glob(CHROMIUM_GLOB))
    if not found:
        sys.exit(
            "compare: no headless Chromium in ~/.cache/ms-playwright "
            f"(looked for {CHROMIUM_GLOB}). This tool does not install one."
        )
    return found[-1]


def run(*args: str | Path) -> str:
    done = subprocess.run([str(a) for a in args], capture_output=True, text=True, check=False)
    if done.returncode != 0:
        sys.exit(f"compare: {' '.join(str(a) for a in args[:3])} failed:\n{done.stdout}{done.stderr}")
    return done.stdout


def shoot_mockup(ref: str, page: str, query: str, size: tuple[int, int], out: Path, local: Path | None = None) -> Path:
    tar = subprocess.run(
        ["git", "-C", str(ROOT), "archive", "--format=tar", ref, MOCKUPS], capture_output=True, check=True
    ).stdout
    with tarfile.open(fileobj=io.BytesIO(tar)) as archive:
        archive.extractall(out / "mockups", filter="data")
    html = out / "mockups" / MOCKUPS / page
    if local is not None:
        html.write_bytes(local.read_bytes())  # a page kept elsewhere, shot from beside the mock-ups
    if not html.is_file():
        sys.exit(f"compare: {page} is not in {MOCKUPS} at {ref}")
    shot = out / "mockup.png"
    url = f"{html.as_uri()}?shot{'&' + query if query else ''}"
    run(
        chromium(),
        "--no-sandbox",
        "--disable-gpu",
        "--hide-scrollbars",
        "--allow-file-access-from-files",
        "--virtual-time-budget=8000",
        "--blink-settings=preferredColorScheme=0",
        f"--window-size={size[0]},{size[1]}",
        f"--screenshot={shot}",
        url,
    )
    return shot


def shoot_godot(scene: str, size: tuple[int, int], out: Path) -> Path:
    started = run(LOOK, "start", "--scene", scene, "--size", f"{size[0]}x{size[1]}")
    session = started.strip().splitlines()[-1].strip()
    try:
        path = Path(run(LOOK, "--session", session, "shot", "--wait", "0.5", "godot").strip().splitlines()[-1])
        errors = run(LOOK, "--session", session, "errors").strip()
    finally:
        subprocess.run([str(LOOK), "--session", session, "stop"], capture_output=True, check=False)
    if errors:
        print(errors.splitlines()[0])
    shot = out / "godot.png"
    shot.write_bytes(path.read_bytes())
    return shot


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("scene", help="the Godot scene, such as res://src/glass/card_sheet.tscn")
    parser.add_argument("page", help="the mock-up page, such as cards.html")
    parser.add_argument("--size", default="1920x1080", help="window size, WIDTHxHEIGHT (default 1920x1080)")
    parser.add_argument("--query", default="", help="extra query for the page, such as size=b&lb=1")
    parser.add_argument(
        "--local",
        type=Path,
        help="a page kept outside the mock-ups (such as docs/ideation-track-2/mockups/x.html), "
        "copied in beside them as PAGE and shot from there",
    )
    parser.add_argument("--ref", help="mock-ups commit (default: the one assets/glass/source.json records)")
    parser.add_argument("--out", type=Path, help="output folder (default: under ~/.local/state/bramble)")
    args = parser.parse_args()
    width, height = (int(v) for v in args.size.lower().split("x"))
    ref = args.ref or json.loads((ROOT / "assets/glass/source.json").read_text())["mockups_commit"]
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    out = args.out or state / "bramble" / "glass-compare" / time.strftime("%Y%m%d-%H%M%S")
    out.mkdir(parents=True, exist_ok=True)

    mock = Image.open(shoot_mockup(ref, args.page, args.query, (width, height), out, args.local)).convert("RGB")
    game = Image.open(shoot_godot(args.scene, (width, height), out)).convert("RGB")
    if mock.size != game.size:
        sys.exit(f"compare: the shots differ in size: mock-up {mock.size}, Godot {game.size}")
    stacked = Image.new("RGB", (width, 2 * height + 30), "white")
    stacked.paste(mock, (0, 0))
    stacked.paste(game, (0, height + 30))
    ImageDraw.Draw(stacked).text((10, height + 9), f"ABOVE: {args.page}   BELOW: {args.scene}", fill="black")
    stacked.save(out / "stacked.png")
    diff = ImageChops.difference(mock, game)
    diff.point(lambda v: min(255, v * 4)).save(out / "diff.png")
    hist = diff.convert("L").histogram()
    total = sum(hist)
    mean = sum(i * n for i, n in enumerate(hist)) / total
    print(f"mean difference {mean:.2f} of 255; {100 * sum(hist[33:]) / total:.2f}% of pixels differ by more than 32")
    print(f"pictures: {out}/stacked.png, diff.png, mockup.png, godot.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
