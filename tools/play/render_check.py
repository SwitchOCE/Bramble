"""Checks two renders of one save agree, and that each fight strip shows the logged fight.

Usage: render_check.py <first render dir> <second render dir> <play.sh log output file> <play.sh hash output file>
"""

import json
import re
import sys
from pathlib import Path


def manifests(folder: Path) -> dict:
    return {p.name: json.loads(p.read_text()) for p in sorted(folder.glob("manifest_*.json"))}


def logged_results(log_text: str) -> dict:
    """The human's per-round results from `play.sh <save> log` (the first player block)."""
    results = {}
    in_you = False
    for line in log_text.splitlines():
        if line.startswith("You:"):
            in_you = True
            continue
        if in_you and not line.startswith("  "):
            break
        found = re.match(r"\s+R(\d+) T\d+ (\w+) ", line)
        if in_you and found:
            results[int(found.group(1))] = found.group(2)
    return results


def main() -> int:
    first, second = manifests(Path(sys.argv[1])), manifests(Path(sys.argv[2]))
    logged = logged_results(Path(sys.argv[3]).read_text())
    expected_hash = Path(sys.argv[4]).read_text().strip()
    problems = []
    if not first or first.keys() != second.keys():
        problems.append("the two renders have different sizes")
    for name, one in first.items():
        two = second.get(name, {})
        for label, manifest in (("first", one), ("second", two)):
            moments = manifest.get("moments", [])
            if not moments or moments[-1]["hash"] != expected_hash:
                problems.append(f"{name}: {label} render's final hash differs from play.sh hash")
        if [m["hash"] for m in one["moments"]] != [m["hash"] for m in two.get("moments", [])]:
            problems.append(f"{name}: state hashes differ between renders")
        if one["files"] != two.get("files"):
            problems.append(f"{name}: file lists differ between renders")
        missing = [f for f in one["files"] if not (Path(sys.argv[1]) / f).is_file()]
        if missing:
            problems.append(f"{name}: missing files {missing}")
        fights = [m for m in one["moments"] if m["kind"] == "fight"]
        if not fights:
            problems.append(f"{name}: no fight was drawn")
        for moment in fights:
            fight, shown = moment["fight"], moment.get("shown", {})
            round_number = fight["round"]
            if logged.get(round_number) != fight["result"]:
                problems.append(f"R{round_number}: log says {logged.get(round_number)}, fight {fight['result']}")
            if shown.get("events") != fight["events"]:
                problems.append(f"R{round_number}: the strip played other events")
            # Older manifests used a shortened plaque name; the current UI uses the hero reader name.
            plaque = shown.get("opponent", "").rstrip(".…")
            if not plaque or plaque not in fight["opponent"]:
                problems.append(f"R{round_number}: the strip shows {shown.get('opponent')}")
            if len(moment["files"]) < 2:
                problems.append(f"R{round_number}: the strip has under two frames")
    for problem in problems:
        print("FAIL", problem)
    if not problems:
        sizes = ", ".join(first)
        print(f"ok: {len(logged)} logged rounds match their strips; both renders agree ({sizes})")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
