"""Prints the slowest test scripts in a GUT JUnit XML file (used by check.sh's tests step).

    python3 tools/checks/junit_slowest.py <gut.xml> [count]

GUT writes one testsuite per script or inner class; inner classes are added to their script.
"""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET


def script_times(path: str) -> dict[str, float]:
    """Seconds per test script, summed over its inner classes."""
    times: dict[str, float] = {}
    for suite in ET.parse(path).getroot().iter("testsuite"):
        name = suite.get("name", "?")
        script = name.split(".gd", 1)[0] + ".gd" if ".gd" in name else name
        times[script] = times.get(script, 0.0) + float(suite.get("time", "0") or 0)
    return times


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    count = int(argv[2]) if len(argv) > 2 else 20
    times = script_times(argv[1])
    slowest = sorted(times.items(), key=lambda kv: kv[1], reverse=True)[:count]
    print(f"slowest {len(slowest)} of {len(times)} test scripts ({sum(times.values()):.1f}s in all):")
    for script, secs in slowest:
        print(f"{secs:8.1f}s  {script}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
