#!/usr/bin/env python3
"""Sequential frozen review arms on cores 0/1, in two shards per arm.

prepare MANIFEST: copy measurement-only overlays and resolve immutable snapshot paths.
launch MANIFEST: detach in host tmux; invoke with approved host execution, not a sandbox.
run RESOLVED_MANIFEST: internal worker, always wrapped by the strict global timeout.
finish RESOLVED_MANIFEST EXIT_CODE: record timeout/failure after the controller exits.

Manifest: output, games_per_arm, first_seed, timeout_seconds, arms=[{name,snapshot,head}].
Optional probe_mode=ladder runs bench.gd, with a suite on each arm and validated focus CIs.
Optional after_status and absolute_deadline share one strict ceiling across a serial queue.
Output must be build/sim/commit-review-*. Snapshots must be independent frozen projects.
No command creates, changes, stops or restarts the existing 1,000-game spread job.
"""

import csv
import hashlib
import json
import math
import os
import shlex
import shutil
import statistics
import subprocess
import sys
import time
from datetime import UTC, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OVERLAYS = ["commit_review_probe.gd", "summarize_commit_review.py"]
FOCUS_SUITES = {
    "hard_naive",
    "hard_lobby_hard",
    "place_search",
    "place_rule",
    "place_shuffled",
    "place_big",
    "blind_alone",
    "blind_lobby",
    "blind_shuffled",
}


def stamp():
    return datetime.now(UTC).isoformat()


def write(path, value):
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def project_digest(snapshot):
    digest = hashlib.sha256()
    count = 0
    for directory in ["src/core", "content"]:
        for path in sorted((snapshot / directory).rglob("*")):
            if path.is_file():
                digest.update(str(path.relative_to(snapshot)).encode() + b"\0")
                digest.update(path.read_bytes())
                count += 1
    return {"sha256": digest.hexdigest(), "files": count, "scope": "src/core and content"}


def prepare(source):
    value = json.loads(source.read_text())
    output = Path(value["output"]).expanduser().resolve()
    if not output.is_relative_to(ROOT / "build/sim") or not output.name.startswith("commit-review-"):
        raise ValueError("Output must be build/sim/commit-review-*")
    if (output / "status.json").exists():
        raise ValueError("Output already has a run; use a fresh output directory")
    mode = value.get("probe_mode", "probe")
    if mode not in ["probe", "ladder"]:
        raise ValueError("probe_mode must be probe or ladder")
    value["games_per_arm"] = int(value.get("games_per_arm", 100 if mode == "ladder" else 30))
    value["timeout_seconds"] = int(value.get("timeout_seconds", 3600))
    value["first_seed"] = int(value["first_seed"])
    if value["games_per_arm"] < 2 or not 1 <= value["timeout_seconds"] <= 7200:
        raise ValueError("Need at least two games and a timeout between 1 and 7200 seconds")
    output.mkdir(parents=True, exist_ok=True)
    names = set()
    for arm in value["arms"]:
        if mode == "ladder" and arm.get("suite") not in FOCUS_SUITES:
            raise ValueError("Unknown active focus suite; use the best bot or tools-only Naive yardstick")
        name = arm["name"]
        if not name or any(char not in "abcdefghijklmnopqrstuvwxyz0123456789-_" for char in name):
            raise ValueError("Arm names use lowercase letters, digits, hyphen or underscore")
        if name in names:
            raise ValueError("Arm names must be distinct")
        names.add(name)
        snapshot = Path(arm["snapshot"]).expanduser().resolve()
        if snapshot == ROOT or (snapshot / ".git").exists() or not (snapshot / "project.godot").is_file():
            raise ValueError("Snapshot must be a frozen independent Godot project, not a worktree")
        for path in OVERLAYS:
            shutil.copyfile(ROOT / "tools/sim" / path, snapshot / "tools/sim" / path)
        if not (snapshot / "tools/sim/commit_probe.gd").is_file():
            raise ValueError("Snapshot must contain the real commitment probe")
        cache = snapshot / ".godot/global_script_class_cache.cfg"
        if not cache.exists() and value.get("reuse_class_cache", True):
            cache.parent.mkdir(exist_ok=True)
            for filename in ["global_script_class_cache.cfg", "uid_cache.bin"]:
                source_cache = ROOT / ".godot" / filename
                if source_cache.exists():
                    shutil.copyfile(source_cache, cache.parent / filename)
            arm["class_cache"] = "minimal prepared checkout cache; no texture/audio imports"
        arm["gameplay_digest"] = project_digest(snapshot)
        arm["snapshot"] = str(snapshot)
        (output / name).mkdir(exist_ok=True)
    if not names:
        raise ValueError("At least one arm is required")
    value.update({"output": str(output), "cores": [0, 1], "measurement_overlays": OVERLAYS})
    resolved = output / "manifest.json"
    write(resolved, value)
    print(resolved)
    return resolved


def launch(source):
    resolved = prepare(source)
    value = json.loads(resolved.read_text())
    output = Path(value["output"])
    started = datetime.now(UTC)
    if value.get("absolute_deadline"):
        deadline = datetime.fromisoformat(value["absolute_deadline"])
        remaining = math.floor((deadline - started).total_seconds()) - 2
        if remaining <= 0:
            raise ValueError("The shared absolute queue deadline has passed")
        value["timeout_seconds"] = min(value["timeout_seconds"], remaining)
        write(resolved, value)
    write(
        output / "status.json",
        {
            "state": "starting",
            "started": started.isoformat(),
            "deadline": (started + timedelta(seconds=value["timeout_seconds"])).isoformat(),
        },
    )
    worker = [
        "timeout",
        "--signal=KILL",
        str(value["timeout_seconds"]),
        "taskset",
        "-c",
        "0,1",
        "python3",
        str(Path(__file__).resolve()),
        "run",
        str(resolved),
    ]
    finish = ["taskset", "-c", "0,1", "python3", str(Path(__file__).resolve()), "finish", str(resolved)]
    command = (
        shlex.join(worker)
        + " > "
        + shlex.quote(str(output / "job.log"))
        + " 2>&1; "
        + "result=$?; "
        + shlex.join(finish)
        + ' "$result"'
    )
    session = output.name
    subprocess.run(["tmux", "-L", "bramble-commit-review", "new-session", "-d", "-s", session, command], check=True)
    print(
        json.dumps(
            {
                "session": session,
                "output": str(output),
                "deadline": (started + timedelta(seconds=value["timeout_seconds"])).isoformat(),
            }
        )
    )


def run_arm(value, arm, status):
    output, snapshot = Path(value["output"]) / arm["name"], Path(arm["snapshot"])
    common = os.environ.copy()
    common.update({"LP_NUM_THREADS": "1", "OMP_NUM_THREADS": "1"})
    if not (snapshot / ".godot/global_script_class_cache.cfg").exists():
        env = common | {"XDG_DATA_HOME": str(output / "import-data"), "XDG_CONFIG_HOME": str(output / "import-config")}
        with (output / "import.log").open("w") as log:
            subprocess.run(
                ["taskset", "-c", "0,1", "godot", "--headless", "--path", str(snapshot), "--import"],
                env=env,
                stdout=log,
                stderr=subprocess.STDOUT,
                check=True,
            )
    total = value["games_per_arm"]
    first_count = total // 2
    workers, handles = [], []
    try:
        for shard, count in enumerate([first_count, total - first_count]):
            env = common | {
                "XDG_DATA_HOME": str(output / f"data-{shard}"),
                "XDG_CONFIG_HOME": str(output / f"config-{shard}"),
            }
            handle = (output / f"part-{shard}.log").open("w")
            handles.append(handle)
            command = [
                "taskset",
                "-c",
                str(shard),
                "godot",
                "--headless",
                "--path",
                str(snapshot),
                "-s",
                "res://tools/sim/bench.gd"
                if value.get("probe_mode") == "ladder"
                else "res://tools/sim/commit_review_probe.gd",
                "--",
                f"games={count}",
                f"first_seed={value['first_seed'] + shard * first_count}",
            ]
            if value.get("probe_mode") == "ladder":
                command += [f"suite={arm['suite']}", f"out={output / f'part-{shard}'}"]
            else:
                command += ["level=hard"]
            workers.append(subprocess.Popen(command, env=env, stdout=handle, stderr=subprocess.STDOUT))
        status.update({"state": "running", "arm": arm["name"], "worker_pids": [p.pid for p in workers]})
        write(Path(value["output"]) / "status.json", status)
        while any(worker.poll() is None for worker in workers):
            if any(worker.poll() not in [None, 0] for worker in workers):
                raise RuntimeError("A probe shard failed; inspect its raw log")
            time.sleep(1)
        if any(worker.returncode != 0 for worker in workers):
            raise RuntimeError("A probe shard failed; inspect its raw log")
    finally:
        for worker in workers:
            if worker.poll() is None:
                worker.terminate()
                try:
                    worker.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    worker.kill()
        for handle in handles:
            handle.close()
    combined = output / "probe.log"
    combined.write_text("".join((output / f"part-{shard}.log").read_text() for shard in [0, 1]))
    if any(token in combined.read_text() for token in ["SCRIPT ERROR", "ERROR:", "Assertion failed"]):
        raise RuntimeError("Probe logged an engine/script error")
    if value.get("probe_mode") == "ladder":
        return summarize_ladder(output, arm, total, value["first_seed"])
    with (output / "summary.json").open("w") as log:
        subprocess.run(
            ["python3", str(snapshot / "tools/sim/summarize_commit_review.py"), str(combined)],
            cwd=snapshot,
            stdout=log,
            check=True,
        )
    result = json.loads((output / "summary.json").read_text())
    if result["lobbies"] != total or result["seats"] != total * 8:
        raise RuntimeError("Probe did not complete every requested game/seat")
    print(
        json.dumps(
            {
                "arm": arm["name"],
                "head": arm.get("head"),
                "lobbies": result["lobbies"],
                "round10": result["round10_full_board_commitment"],
                "burner": result["cards"]["charcoal_burner"],
            }
        ),
        flush=True,
    )
    return result


def summarize_ladder(output, arm, total, first_seed=4001):
    for part in ["players", "rounds", "cards", "turns"]:
        with (output / f"{arm['suite']}.{part}.csv").open("w") as destination:
            for shard in [0, 1]:
                with (output / f"part-{shard}.{part}.csv").open() as source:
                    header = next(source)
                    if shard == 0:
                        destination.write(header)
                    shutil.copyfileobj(source, destination)
    with (output / f"{arm['suite']}.players.csv").open() as source:
        rows = list(csv.DictReader(source))
    focus = [row for row in rows if row["focus"] == "1"]
    if len(focus) != total or len(rows) != total * 8:
        raise RuntimeError("Ladder did not finish every game/focus seat")
    seeds = set(range(first_seed, first_seed + total))
    if {int(row["seed"]) for row in rows} != seeds:
        raise RuntimeError("Ladder seed range differs from the requested fresh seeds")
    for seed in seeds:
        game = [row for row in rows if int(row["seed"]) == seed]
        if len(game) != 8 or {int(row["seat"]) for row in game} != set(range(8)):
            raise RuntimeError("Each ladder game needs eight distinct seats")
        if sorted(int(row["place"]) for row in game) != list(range(1, 9)):
            raise RuntimeError("Each ladder game needs distinct placements 1 through 8")
        if sum(row["focus"] == "1" for row in game) != 1:
            raise RuntimeError("Each ladder game needs exactly one focus seat")
        if any(row["suite"] != arm["suite"] for row in game):
            raise RuntimeError("A ladder row belongs to another suite")
    places = [int(row["place"]) for row in focus]
    margin = 1.96 * statistics.stdev(places) / math.sqrt(total) if total > 1 else 0.0
    result = {
        "suite": arm["suite"],
        "head": arm.get("head"),
        "games": total,
        "focus_place": round(statistics.mean(places), 3),
        "focus_place_margin_95": round(margin, 3),
        "focus_place_interval_95": [
            round(statistics.mean(places) - margin, 3),
            round(statistics.mean(places) + margin, 3),
        ],
        "first_seed": first_seed,
        "last_seed": first_seed + total - 1,
        "focus_win_percent": round(100 * places.count(1) / total, 3),
        "focus_top4_percent": round(100 * sum(place <= 4 for place in places) / total, 3),
        "focus_final_units": round(statistics.mean(int(row["final_units"]) for row in focus), 3),
    }
    if arm["suite"] == "hard_naive":
        result["yardstick_bar"] = {"top4_percent": 85.0, "win_percent": 45.0}
        result["yardstick_passes"] = result["focus_top4_percent"] >= 85.0 and result["focus_win_percent"] >= 45.0
    write(output / "summary.json", result)
    print(json.dumps(result), flush=True)
    return result


def run(source):
    value = json.loads(source.read_text())
    status = json.loads((Path(value["output"]) / "status.json").read_text())
    summaries = {}
    if value.get("after_status"):
        dependency = Path(value["after_status"]).resolve()
        status.update({"state": "waiting", "after_status": str(dependency)})
        write(Path(value["output"]) / "status.json", status)
        while True:
            previous = json.loads(dependency.read_text())
            if previous["state"] == "complete":
                break
            if previous["state"] in ["failed", "timeout"]:
                raise RuntimeError("Earlier probe queue did not complete; paired follow-up aborted")
            time.sleep(1)
    for arm in value["arms"]:
        summaries[arm["name"]] = run_arm(value, arm, status)
    write(Path(value["output"]) / "summaries.json", summaries)
    status.update({"state": "complete", "finished": stamp(), "arms_completed": list(summaries)})
    write(Path(value["output"]) / "status.json", status)


def finish(source, code):
    value = json.loads(source.read_text())
    path = Path(value["output"]) / "status.json"
    status = json.loads(path.read_text())
    if code != 0:
        status.update({"state": "timeout" if code in [124, 137] else "failed", "exit_code": code, "finished": stamp()})
        write(path, status)


if __name__ == "__main__":
    action, source = sys.argv[1], Path(sys.argv[2]).resolve()
    if action == "prepare":
        prepare(source)
    elif action == "launch":
        launch(source)
    elif action == "run":
        run(source)
    elif action == "finish":
        finish(source, int(sys.argv[3]))
    else:
        raise SystemExit("Use prepare, launch, run or finish")
