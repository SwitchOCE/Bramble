#!/usr/bin/env python3
"""Proves tools/look/compare.py on tests/look/compare_demo.tscn and tests/look/compare_demo.html.

    python3 tools/look/compare_demo.py [OUTPUT FOLDER]

Two compares at 1280x720, in about ten seconds:
  1. the scene against its page as drawn: every number is near zero;
  2. against the page with its top right badge replaced by a different element (?corner=wrong):
     the whole-screen number stays small, while the badge's region, P1, is named the worst by far.
Both must also say which page they measured. Exits 0 when all checks pass, 1 on any miss, and 77
when something it needs is missing here (Xvfb, xdotool, scrot, headless Chromium or Pillow).
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SCENE = "res://tests/look/compare_demo.tscn"
PAGE = "tests/look/compare_demo.html"
CORNER = "P1"  # the badge (x 1170-1250, y 20-100) covers most of region P1 (x 1200-1280, y 0-80)


def missing() -> str | None:
    for tool in ["Xvfb", "xdotool", "scrot"]:
        if not shutil.which(tool):
            return f"{tool} is not installed (tools/look/README.md)"
    try:
        import PIL  # noqa: F401
    except ImportError:
        return "Pillow (the Python PIL module) is not installed"
    if not list((Path.home() / ".cache" / "ms-playwright").glob("chromium_headless_shell-*")):
        return "no headless Chromium in ~/.cache/ms-playwright"
    return None


def compare(out: Path, query: str) -> dict:
    command = [sys.executable, str(HERE / "compare.py"), SCENE, PAGE, "--size", "1280x720", "--out", str(out)]
    done = subprocess.run([*command, "--query", query] if query else command, capture_output=True, text=True)
    print(done.stdout, end="")
    if done.returncode != 0:
        print(done.stderr, end="")
        raise SystemExit(f"compare demo: FAIL compare.py exited with {done.returncode}")
    result = json.loads((out / "result.json").read_text())
    result["printed"] = done.stdout
    return result


def main() -> int:
    reason = missing()
    if reason:
        print(f"compare demo: skipped: {reason}")
        return 77
    base = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(tempfile.mkdtemp(prefix="compare-demo-"))
    failures = []

    def check(ok: bool, what: str) -> None:
        if not ok:
            failures.append(what)
            print(f"compare demo: FAIL {what}")

    same = compare(base / "same", "")
    mean = same["whole"]["mean"]
    check(mean < 0.5, f"the matching page's whole-screen mean is {mean}, not under 0.5")
    check(same["regions"][0]["mean"] < 5, f"the matching page's worst region scores {same['regions'][0]['mean']}")
    wrong = compare(base / "wrong", "corner=wrong")
    whole, worst = wrong["whole"]["mean"], wrong["regions"][0]
    check(whole < 1.5, f"with the wrong corner the whole-screen mean is {whole}, not small (under 1.5)")
    check(worst["region"] == CORNER, f"the worst region is {worst['region']}, not the corner's {CORNER}")
    check(worst["mean"] > 40, f"the corner's region scores {worst['mean']}, not large (over 40)")
    times = worst["mean"] / max(whole, 0.01)
    check(times > 30, f"the corner's region ({worst['mean']}) is only {times:.0f} times the whole ({whole}), not 30")
    for result in (same, wrong):
        shown = f"measured against: {PAGE}" in result["printed"] and "in the working tree at" in result["printed"]
        check(shown, "the page measured is not printed")
        check(result["page"] == PAGE and bool(result["commit"]), "result.json does not record the page and commit")
    check((base / "wrong" / "diff.png").is_file(), "no diff.png was written")
    print(f"pictures: {base}/same and {base}/wrong (diff.png has the worst regions outlined)")
    if failures:
        return 1
    print(
        f"compare demo: all checks passed: a wrong corner scored {whole:.2f} on the whole screen, "
        f"{worst['mean']:.1f} in P1"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
