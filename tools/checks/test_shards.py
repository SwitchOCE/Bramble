"""Splits the GUT test scripts into N shards of about equal time, for the sharded Actions gate.

    python3 tools/checks/test_shards.py list <i>/<n>               shard i's scripts, one res:// path a line
    python3 tools/checks/test_shards.py gutconfig <i>/<n> <out>    write a GUT config that runs only shard i
    python3 tools/checks/test_shards.py show [n]                   each shard's scripts and estimated seconds
    python3 tools/checks/test_shards.py times <gut.xml>...         refresh tools/checks/test_times.json

Scripts are found the way .gutconfig.json finds them: every test_*.gd under tests/, subdirectories
included. Times come from tools/checks/test_times.json (seconds per script, from a GUT JUnit file).
Known scripts are placed slowest first, each on the lightest shard so far (ties: lowest shard, then
path). Scripts with no time (new tests) follow in path order at the median known time, again on the
lightest shard, so a new script never moves the known ones. Shards are numbered from 1.
"""

from __future__ import annotations

import json
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TIMES_FILE = ROOT / "tools" / "checks" / "test_times.json"
GUT_CONFIG = ROOT / ".gutconfig.json"
DEFAULT_SHARDS = 4
DEFAULT_WEIGHT = 1.0


def discover(root: Path = ROOT) -> list[str]:
    """Every GUT test script under tests/, as sorted res:// paths."""
    config = json.loads((root / ".gutconfig.json").read_text())
    prefix, suffix = config.get("prefix", "test_"), config.get("suffix", ".gd")
    found: list[str] = []
    for res_dir in config.get("dirs", []):
        base = root / res_dir.removeprefix("res://")
        pattern = "**/*" if config.get("include_subdirs") else "*"
        for path in base.glob(pattern):
            if path.is_file() and path.name.startswith(prefix) and path.name.endswith(suffix):
                found.append("res://" + path.relative_to(root).as_posix())
    return sorted(set(found))


def load_times(path: Path = TIMES_FILE) -> dict[str, float]:
    if not path.exists():
        return {}
    return {k: float(v) for k, v in json.loads(path.read_text()).items()}


def assign(scripts: list[str], times: dict[str, float], n: int) -> list[list[str]]:
    """Splits scripts into n lists of about equal total time."""
    if n < 1:
        raise ValueError("need at least 1 shard")
    known = sorted((s for s in scripts if s in times), key=lambda s: (-times[s], s))
    new = sorted(s for s in scripts if s not in times)
    default = statistics.median(times[s] for s in known) if known else DEFAULT_WEIGHT
    shards: list[list[str]] = [[] for _ in range(n)]
    loads = [0.0] * n
    for script in known + new:
        i = min(range(n), key=lambda k: (loads[k], k))
        shards[i].append(script)
        loads[i] += times.get(script, default)
    return [sorted(shard) for shard in shards]


def parse_shard(spec: str) -> tuple[int, int]:
    """'2/4' -> (2, 4); shards are numbered from 1."""
    try:
        i_text, n_text = spec.split("/")
        i, n = int(i_text), int(n_text)
    except ValueError:
        raise ValueError(f"shard must look like i/n, got '{spec}'") from None
    if not 1 <= i <= n:
        raise ValueError(f"shard {i}/{n} is out of range")
    return i, n


def shard_scripts(spec: str, root: Path = ROOT) -> list[str]:
    i, n = parse_shard(spec)
    return assign(discover(root), load_times(root / TIMES_FILE.relative_to(ROOT)), n)[i - 1]


def times_from_junit(xml_paths: list[Path]) -> dict[str, float]:
    """Seconds per res:// script from GUT JUnit files, such as the 4 shards' (inner classes summed)."""
    from tools.checks.junit_slowest import script_times

    times: dict[str, float] = {}
    for path in xml_paths:
        for name, secs in script_times(str(path)).items():
            # GUT names suites by path without the res:// scheme.
            script = name if name.startswith("res://") else "res://" + name
            if script.startswith("res://tests/"):
                times[script] = times.get(script, 0.0) + secs
    return {s: round(t, 2) for s, t in sorted(times.items())}


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__.strip())
        return 2
    cmd, args = argv[1], argv[2:]
    try:
        if cmd == "list" and len(args) == 1:
            print("\n".join(shard_scripts(args[0])))
        elif cmd == "gutconfig" and len(args) == 2:
            scripts = shard_scripts(args[0])
            config = json.loads(GUT_CONFIG.read_text())
            config.update(dirs=[], include_subdirs=False, tests=scripts)
            Path(args[1]).write_text(json.dumps(config, indent=2) + "\n")
            print(f"shard {args[0]}: {len(scripts)} test scripts")
        elif cmd == "show" and len(args) <= 1:
            n = int(args[0]) if args else DEFAULT_SHARDS
            times = load_times()
            scripts = discover()
            default = statistics.median(times.values()) if times else DEFAULT_WEIGHT
            for k, shard in enumerate(assign(scripts, times, n), 1):
                est = sum(times.get(s, default) for s in shard)
                unknown = sum(s not in times for s in shard)
                print(f"shard {k}/{n}: {len(shard)} scripts, about {est:.0f}s ({unknown} without a time)")
        elif cmd == "times" and args:
            times = times_from_junit([Path(a) for a in args])
            if not times:
                print(f"no test scripts under tests/ in {' '.join(args)}")
                return 1
            TIMES_FILE.write_text(json.dumps(times, indent=1, sort_keys=True) + "\n")
            print(f"wrote {len(times)} script times ({sum(times.values()):.0f}s) to {TIMES_FILE.relative_to(ROOT)}")
        else:
            print(__doc__.strip())
            return 2
    except ValueError as err:
        print(err)
        return 2
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(ROOT))
    sys.exit(main(sys.argv))
