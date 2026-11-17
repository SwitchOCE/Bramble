#!/usr/bin/env python3
"""Shoot a Godot scene and an HTML mock-up page at the same size, and score how far apart they are.

    python3 tools/look/compare.py res://tests/look/compare_demo.tscn tests/look/compare_demo.html --size 1920x1080
    python3 tools/look/compare.py res://src/screens/recruit.tscn docs/mockups/recruit.html --query lb=1
    python3 tools/look/compare.py res://src/screens/recruit.tscn docs/mockups/recruit.html --ref origin/design/x

The page is a path in this working tree, or, with --ref, read from that commit. It is rendered with
the headless Chromium that Playwright keeps in ~/.cache/ms-playwright, in dark mode, with ?shot added
to the query (a page can hide its own controls for a shot). The scene is shot with tools/look/look.

Prints which page was measured (its path, and the commit it was read from), the whole screen's mean
difference (0-255), and the worst regions of a grid over the screen (16 x 9 by default), each with its
own mean. Output goes outside Git, to ${XDG_STATE_HOME:-~/.local/state}/bramble/look-compare/<time>/
(or --out): mockup.png, godot.png, stacked.png (mock-up above, Godot below, worst region outlined),
diff.png (difference x4, grid drawn, worst regions outlined) and result.json (every region's scores).
See tools/look/README.md, "Compare with a mock-up page".
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
from pathlib import Path, PurePosixPath

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
LOOK = ROOT / "tools" / "look" / "look"
CHROMIUM_GLOB = "chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell"
# A pixel "differs" when its difference is above this (0-255), as in the track's first compare.
DIFFERS = 32
WORST_COLOURS = [(255, 40, 40), (255, 150, 0), (255, 220, 0)]


class CompareError(Exception):
    pass


def chromium() -> Path:
    found = sorted((Path.home() / ".cache" / "ms-playwright").glob(CHROMIUM_GLOB))
    if not found:
        raise CompareError(
            f"no headless Chromium in ~/.cache/ms-playwright (looked for {CHROMIUM_GLOB}). "
            "This tool does not install one."
        )
    return found[-1]


def run(*args: str | Path) -> str:
    done = subprocess.run([str(a) for a in args], capture_output=True, text=True, check=False)
    if done.returncode != 0:
        raise CompareError(f"{' '.join(str(a) for a in args[:3])} failed:\n{done.stdout}{done.stderr}")
    return done.stdout


def git(*args: str) -> str:
    return run("git", "-C", ROOT, *args).strip()


def page_from_tree(page: str) -> tuple[Path, dict]:
    """A page in this working tree: its path, the commit checked out, and whether it differs from it."""
    path = Path(page)
    path = (path if path.is_absolute() or path.exists() else ROOT / path).resolve()
    if not path.is_file():
        raise CompareError(f"{page} is not a file in this working tree")
    try:
        shown = path.relative_to(ROOT).as_posix()
        commit = git("rev-parse", "HEAD")
        tracked = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files", "--error-unmatch", "--", shown], capture_output=True, check=False
        )
        # An untracked or ignored page is not in that commit at all; only a tracked one can be unchanged.
        changed = True if tracked.returncode else bool(git("status", "--porcelain", "--", shown))
        in_commit = tracked.returncode == 0
    except (ValueError, CompareError):
        shown, commit, changed, in_commit = str(path), None, None, None
    return path, {
        "page": shown,
        "read_from": "working tree",
        "commit": commit,
        "in_commit": in_commit,
        "changed_since_commit": changed,
    }


def page_from_commit(page: str, ref: str, out: Path) -> tuple[Path, dict]:
    """A page read from a commit: its folder, and what that folder's symlinks point to, are extracted to out."""
    commit = git("rev-parse", "--verify", f"{ref}^{{commit}}")
    page = PurePosixPath(page).as_posix()
    if run("git", "-C", ROOT, "cat-file", "-t", f"{commit}:{page}").strip() != "blob":
        raise CompareError(f"{page} is not a file at {ref}")
    folder = str(PurePosixPath(page).parent)
    paths = [folder]
    for line in git("ls-tree", "-r", commit, "--", folder).splitlines():
        mode, _kind, blob = line.split("\t", 1)[0].split()
        if mode == "120000":
            link = line.split("\t", 1)[1]
            target = os.path.normpath(str(PurePosixPath(link).parent / git("cat-file", "-p", blob)))
            exists = subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e", f"{commit}:{target}"], check=False)
            if not target.startswith("..") and exists.returncode == 0:
                paths.append(target)
    tar = subprocess.run(
        ["git", "-C", str(ROOT), "archive", "--format=tar", commit, *sorted(set(paths))],
        capture_output=True,
        check=True,
    ).stdout
    tree = out / f"page-at-{commit[:8]}"
    with tarfile.open(fileobj=io.BytesIO(tar)) as archive:
        archive.extractall(tree, filter="data")
    return tree / page, {
        "page": page,
        "read_from": ref,
        "commit": commit,
        "in_commit": True,
        "changed_since_commit": False,
    }


def describe(source: dict, query: str) -> str:
    page = source["page"] + (f"?{query}" if query else "")
    if source["read_from"] == "working tree":
        if source["commit"] is None:
            return f"{page} (outside this Git working tree)"
        if not source["in_commit"]:
            state = "not in Git: untracked or ignored"
        elif source["changed_since_commit"]:
            state = "with uncommitted changes"
        else:
            state = "unchanged from that commit"
        return f"{page} in the working tree at {source['commit'][:8]} ({state})"
    return f"{page} at {source['read_from']} ({source['commit'][:8]})"


def shoot_mockup(html: Path, query: str, size: tuple[int, int], out: Path) -> Path:
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
        print(f"the scene logged: {errors.splitlines()[0]}")
    shot = out / "godot.png"
    shot.write_bytes(path.read_bytes())
    return shot


def column_name(index: int) -> str:
    name = ""
    index += 1
    while index:
        index, rest = divmod(index - 1, 26)
        name = chr(ord("A") + rest) + name
    return name


def place(centre: float, length: int, words: tuple[str, str, str]) -> str:
    return words[min(2, int(3 * centre / length))]


def score(diff: Image.Image) -> tuple[float, float]:
    """Mean difference (0-255) and the share of pixels, in percent, that differ by more than DIFFERS."""
    hist = diff.histogram()
    total = sum(hist)
    mean = sum(i * n for i, n in enumerate(hist)) / total
    return mean, 100 * sum(hist[DIFFERS + 1 :]) / total


def regions(diff: Image.Image, grid: tuple[int, int]) -> list[dict]:
    """Every grid region's score, worst first. diff is the greyscale difference picture."""
    width, height = diff.size
    columns, rows = grid
    found = []
    for row in range(rows):
        for column in range(columns):
            box = (
                column * width // columns,
                row * height // rows,
                (column + 1) * width // columns,
                (row + 1) * height // rows,
            )
            mean, share = score(diff.crop(box))
            where = place((box[1] + box[3]) / 2, height, ("top", "middle", "bottom"))
            side = place((box[0] + box[2]) / 2, width, ("left", "centre", "right"))
            found.append(
                {
                    "region": f"{column_name(column)}{row + 1}",
                    "where": "centre" if (where, side) == ("middle", "centre") else f"{where} {side}",
                    "box": box,
                    "mean": round(mean, 2),
                    "differs_pct": round(share, 2),
                }
            )
    return sorted(found, key=lambda r: (-r["mean"], -r["differs_pct"]))


def measure(mock: Image.Image, game: Image.Image, grid: tuple[int, int]) -> dict:
    """The whole screen's score and every region's, for two shots of the same size."""
    if mock.size != game.size:
        raise CompareError(f"the shots differ in size: mock-up {mock.size}, Godot {game.size}")
    diff = ImageChops.difference(mock.convert("RGB"), game.convert("RGB")).convert("L")
    mean, share = score(diff)
    return {"whole": {"mean": round(mean, 2), "differs_pct": round(share, 2)}, "regions": regions(diff, grid)}


# Bands around diff.png for the grid's names and the legend, so no label covers a difference.
TOP, LEFT, FOOT = 16, 22, 22


def marked_diff(mock: Image.Image, game: Image.Image, result: dict, grid: tuple[int, int], worst: int) -> Image.Image:
    """The difference x4 in a frame: the grid's names on the top and left bands, the grid drawn faintly
    over the picture, the worst regions outlined (worst in red), and a legend in the foot band."""
    difference = ImageChops.difference(mock.convert("RGB"), game.convert("RGB")).point(lambda v: min(255, v * 4))
    width, height = difference.size
    picture = Image.new("RGB", (LEFT + width, TOP + height + FOOT), (24, 24, 32))
    picture.paste(difference, (LEFT, TOP))
    draw = ImageDraw.Draw(picture)
    columns, rows = grid
    for column in range(columns):
        x = LEFT + column * width // columns
        if column:
            draw.line((x, TOP, x, TOP + height - 1), fill=(70, 70, 90))
        draw.text((x + 3, 2), column_name(column), fill=(170, 170, 200))
    for row in range(rows):
        y = TOP + row * height // rows
        if row:
            draw.line((LEFT, y, LEFT + width - 1, y), fill=(70, 70, 90))
        draw.text((3, y + 3), str(row + 1), fill=(170, 170, 200))
    legend = []
    for rank, region in reversed(list(enumerate(result["regions"][:worst]))):
        colour = WORST_COLOURS[min(rank, len(WORST_COLOURS) - 1)]
        x0, y0, x1, y1 = region["box"]
        line = 3 if rank == 0 else 2
        draw.rectangle((LEFT + x0, TOP + y0, LEFT + x1 - 1, TOP + y1 - 1), outline=colour, width=line)
        legend.insert(0, (f"{rank + 1}. {region['region']} {region['where']}: {region['mean']:.1f}", colour))
    x = LEFT
    for text, colour in legend:
        draw.text((x, TOP + height + 5), text, fill=colour)
        x += 7 * len(text) + 24
    return picture


def stacked_picture(mock: Image.Image, game: Image.Image, page: str, scene: str, worst: dict | None) -> Image.Image:
    width, height = mock.size
    stacked = Image.new("RGB", (width, 2 * height + 30), "white")
    stacked.paste(mock.convert("RGB"), (0, 0))
    stacked.paste(game.convert("RGB"), (0, height + 30))
    draw = ImageDraw.Draw(stacked)
    note = f"   worst region {worst['region']} outlined in red" if worst else ""
    draw.text((10, height + 9), f"ABOVE: {page}   BELOW: {scene}{note}", fill="black")
    if worst:
        x0, y0, x1, y1 = worst["box"]
        for top in (0, height + 30):
            draw.rectangle((x0, y0 + top, x1 - 1, y1 - 1 + top), outline=WORST_COLOURS[0], width=3)
    return stacked


def pair(text: str, what: str) -> tuple[int, int]:
    try:
        first, second = (int(v) for v in text.lower().split("x"))
    except ValueError:
        raise CompareError(f"{what} is WIDTHxHEIGHT or COLUMNSxROWS, such as 1920x1080 or 16x9") from None
    if first < 1 or second < 1:
        raise CompareError(f"{what} must be positive")
    return first, second


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("scene", help="the Godot scene, such as res://src/screens/recruit.tscn")
    parser.add_argument("page", help="the mock-up page: a path in this working tree, or in the commit --ref names")
    parser.add_argument("--size", default="1920x1080", help="window size, WIDTHxHEIGHT (default 1920x1080)")
    parser.add_argument("--query", default="", help="extra query for the page, such as size=b&lb=1")
    parser.add_argument("--ref", help="read the page from this commit or branch instead of the working tree")
    parser.add_argument(
        "--grid",
        default="16x9",
        help="regions, COLUMNSxROWS (default 16x9: 120 px squares at 1920x1080)",
    )
    parser.add_argument("--worst", type=int, default=3, help="how many worst regions to print and outline (default 3)")
    parser.add_argument("--out", type=Path, help="output folder (default: under ~/.local/state/bramble/look-compare)")
    args = parser.parse_args()
    size = pair(args.size, "--size")
    grid = pair(args.grid, "--grid")
    if grid[0] > size[0] or grid[1] > size[1]:
        raise CompareError("--grid has more regions than the screen has pixels")
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    out = args.out or state / "bramble" / "look-compare" / time.strftime("%Y%m%d-%H%M%S")
    out.mkdir(parents=True, exist_ok=True)

    html, source = page_from_commit(args.page, args.ref, out) if args.ref else page_from_tree(args.page)
    print(f"measured against: {describe(source, args.query)}")
    print(f"scene: {args.scene} at {size[0]}x{size[1]}")
    mock = Image.open(shoot_mockup(html, args.query, size, out)).convert("RGB")
    game = Image.open(shoot_godot(args.scene, size, out)).convert("RGB")
    result = measure(mock, game, grid)
    worst = result["regions"][: max(0, args.worst)]

    marked_diff(mock, game, result, grid, len(worst)).save(out / "diff.png")
    stacked_picture(mock, game, source["page"], args.scene, worst[0] if worst else None).save(out / "stacked.png")
    record = {"scene": args.scene, "size": list(size), "query": args.query, "grid": list(grid), **source, **result}
    (out / "result.json").write_text(json.dumps(record, indent=1))

    whole = result["whole"]
    print(
        f"whole screen: mean difference {whole['mean']:.2f} of 255; "
        f"{whole['differs_pct']:.2f}% of pixels differ by more than {DIFFERS}"
    )
    columns, rows = grid
    print(f"worst regions ({columns} x {rows} grid, {size[0] // columns}x{size[1] // rows} px each):")
    for rank, region in enumerate(worst, 1):
        x0, y0, x1, y1 = region["box"]
        print(
            f"  {rank}. {region['region']:<4} {region['where']:<14} x {x0}-{x1}, y {y0}-{y1}: "
            f"mean {region['mean']:.2f}; {region['differs_pct']:.2f}% differ by more than {DIFFERS}"
        )
    print(
        f"pictures: {out}/diff.png (worst regions outlined), stacked.png, mockup.png, godot.png; "
        "every region's scores: result.json"
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except CompareError as error:
        sys.exit(f"compare: {error}")
