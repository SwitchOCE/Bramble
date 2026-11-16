"""Run a Godot scene under Xvfb and look at it, click in it and read its errors. See README.md."""

import argparse
import fcntl
import json
import os
import re
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNNER = "res://tools/look/look_runner.gd"
SIZES = {"pc": "1920x1080"}
# Four look games at most on this machine (each capped at 3 GB). The quality gate's own demo
# (BRAMBLE_LOOK_SLOT=gate, set by scripts/check.sh) uses a lock of its own instead, so gate runs
# never wait on or fail because of agents' sessions; gate demos take turns on that one lock.
SLOTS = 4
LOCKS = [Path(tempfile.gettempdir()) / f"bramble-look-{n}.lock" for n in range(1, SLOTS + 1)]
GATE_LOCK = Path(tempfile.gettempdir()) / "bramble-look-gate.lock"
IDLE_SECONDS = 1800
# The same lines scripts/godot_log.sh counts as problems in a Godot log.
PROBLEM = re.compile(r"(^|[^A-Za-z_])(ERROR|WARNING|SCRIPT ERROR|Parse Error)[: ]|handle_crash")
# Noise from the virtual display, not the game: Xvfb's OpenGL cannot change V-Sync.
IGNORED = re.compile(r"^WARNING: Could not set V-Sync mode")
STATE = Path()


def state_directory():
    override = os.environ.get("BRAMBLE_LOOK_DIR")
    default = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "bramble/look"
    candidates = (
        [Path(override).expanduser()]
        if override
        else [default, Path(tempfile.gettempdir()) / f"bramble-look-{os.getuid()}"]
    )
    for path in candidates:
        try:
            path.mkdir(parents=True, exist_ok=True, mode=0o700)
            # A real write probe also detects read-only agent sandboxes (access() may not).
            with tempfile.TemporaryFile(dir=path):
                pass
            if not override and path != default:
                print(f"look: {default} is not writable; using {path}", file=sys.stderr)
            return path.resolve()
        except OSError:
            continue
    raise ValueError("Look output directory is not writable; set BRAMBLE_LOOK_DIR to a writable folder")


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, **kwargs)


def write_json(path, data):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data))
    temporary.replace(path)


def identity(pid):
    """Linux process start time, so an old session never targets a reused PID."""
    try:
        stat = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        return stat[19] if stat[0] != "Z" else None
    except (FileNotFoundError, ProcessLookupError, IndexError):
        return None


def session_directories():
    return sorted(p for p in STATE.iterdir() if p.is_dir() and re.fullmatch(r"\d{8}-\d{6}-[0-9a-f]{6}", p.name))


def sessions():
    found = []
    for path in session_directories():
        with_data = path / "session.json"
        if with_data.exists():
            data = json.loads(with_data.read_text())
            if identity(data["pid"]) == data["identity"]:
                found.append((path, data))
    return found


def prune_sessions():
    live = {path for path, _data in sessions()}
    cutoff = time.time() - 7 * 86400
    for path in session_directories():
        activity = path / "activity"
        modified = max(path.stat().st_mtime, activity.stat().st_mtime if activity.exists() else 0)
        if path not in live and not path.is_symlink() and modified < cutoff:
            shutil.rmtree(path)


def ended_note(directory):
    ended = directory / "ended.json"
    if not ended.exists():
        return f"session {directory.name} is not running"
    data = json.loads(ended.read_text())
    return f"session {directory.name} ended: {data['reason']}"


def selected(session_id):
    """The live session to act on: the one named, else the only one running."""
    live = sessions()
    if session_id:
        match = [(p, d) for p, d in live if p.name == session_id]
        if not match:
            path = STATE / session_id
            raise ValueError(ended_note(path) + "; read why with: tools/look/look errors --session " + session_id)
        return match[0]
    if len(live) == 1:
        return live[0]
    if not live:
        past = session_directories()
        note = ended_note(past[-1]) + "; read why with: tools/look/look errors" if past else "no session yet"
        raise ValueError(f"No live session ({note}). Start one with: tools/look/look start")
    raise ValueError("Several live sessions; choose one with --session ID (see tools/look/look list)")


def any_session(session_id):
    """A session directory for reading logs: the one named, the only live one, else the latest."""
    if session_id:
        path = STATE / session_id
        if not (path / "game.log").exists():
            raise ValueError(f"No session {session_id} with a game log")
        return path
    live = sessions()
    if len(live) == 1:
        return live[0][0]
    if len(live) > 1:
        raise ValueError("Several live sessions; choose one with --session ID (see tools/look/look list)")
    past = [p for p in session_directories() if (p / "game.log").exists()]
    if not past:
        raise ValueError("No session yet. Start one with: tools/look/look start")
    return past[-1]


def problems(log):
    """Each error or warning in a Godot log, with the indented 'at:' and backtrace lines after it."""
    found, current = [], None
    for line in log.read_text(errors="replace").splitlines():
        if PROBLEM.search(line):
            current = [line]
            if not IGNORED.search(line):
                found.append(current)
        elif current is not None and line.startswith((" ", "\t")) and line.strip():
            current.append(line)
        else:
            current = None
    return ["\n".join(lines) for lines in found]


def dependencies():
    for command in [os.environ.get("GODOT", "godot"), "Xvfb", "xdotool", "scrot"]:
        if not shutil.which(command):
            raise ValueError(f"Missing dependency: {command}; see tools/look/README.md")
    if not (ROOT / ".godot").is_dir():
        raise ValueError("Import first: godot --headless --import")


def take_slot(timeout):
    """Hold one of the look locks; wait up to timeout seconds while all are taken."""
    deadline = time.monotonic() + timeout
    said = False
    gate = os.environ.get("BRAMBLE_LOOK_SLOT") == "gate"
    while True:
        for path in [GATE_LOCK] if gate else LOCKS:
            handle = path.open("a")
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return handle
            except BlockingIOError:
                handle.close()
        if time.monotonic() > deadline:
            raise ValueError(f"all look slots were still taken after {timeout:g} s; stop a game (tools/look/look list)")
        if not said:
            print("look: all look slots are taken; waiting for a game to stop", file=sys.stderr, flush=True)
            said = True
        time.sleep(1)


def spawn_xvfb(directory, size, env):
    read_fd, write_fd = os.pipe()
    log = (directory / "xvfb.log").open("ab")
    process = subprocess.Popen(
        ["Xvfb", "-displayfd", str(write_fd), "-screen", "0", size + "x24", "-nolisten", "tcp"],
        pass_fds=(write_fd,),
        stdout=log,
        stderr=log,
    )
    os.close(write_fd)
    # Xvfb picks a free display itself and publishes its number only once it is ready.
    if not select.select([read_fd], [], [], 15)[0]:
        process.terminate()
        process.wait()
        os.close(read_fd)
        raise ValueError(f"Xvfb did not become ready; see {directory / 'xvfb.log'}")
    with os.fdopen(read_fd) as pipe:
        display = pipe.readline().strip()
    if not display:
        process.wait()
        raise ValueError(f"Xvfb failed; see {directory / 'xvfb.log'}")
    env["DISPLAY"] = ":" + display
    return process


def serve(directory, size, scene, timeout):
    """One supervisor owns the display and the game, and cleans up after a crash or idle time."""
    env = os.environ.copy()
    env["LP_NUM_THREADS"] = env.get("LP_NUM_THREADS", "1")
    # The game's user:// data and settings stay inside the session folder.
    env["XDG_DATA_HOME"] = str(directory / "data")
    env["XDG_CONFIG_HOME"] = str(directory / "config")
    children = []
    reason = "stopped"

    def terminate(_signum, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)
    try:
        slot = take_slot(timeout)  # noqa: F841 - held until this process exits
        children.append(spawn_xvfb(directory, size, env))
        # Cap the game at 3 GB where a user systemd is available, as the first run's tool did.
        cap = ["systemd-run", "--user", "--scope", "-q", "-p", "MemoryMax=3G"]
        if not shutil.which("systemd-run") or subprocess.run([*cap, "true"], capture_output=True).returncode:
            cap = []
        command = [
            *cap,
            env.get("GODOT", "godot"),
            "--path",
            str(ROOT),
            "--rendering-driver",
            "opengl3",
            "--audio-driver",
            "Dummy",
            "--windowed",
            "--resolution",
            size,
            "--position",
            "0,0",
            "--max-fps",
            "30",
            "--script",
            RUNNER,
            "--",
            scene,
            str(directory / "ready"),
        ]
        game_log = (directory / "game.log").open("ab")
        game = subprocess.Popen(command, env=env, stdout=game_log, stderr=game_log, stdin=subprocess.DEVNULL)
        children.append(game)
        deadline = time.monotonic() + timeout
        while not (directory / "ready").exists():
            if game.poll() is not None:
                reason = f"the game exited with code {game.returncode} before the scene was ready"
                raise ValueError(reason)
            if time.monotonic() > deadline:
                reason = f"the scene was not ready after {timeout:g} s"
                raise ValueError(reason)
            time.sleep(0.1)
        (directory / "activity").touch()
        write_json(
            directory / "session.json",
            {
                "pid": os.getpid(),
                "identity": identity(os.getpid()),
                "game_pid": game.pid,
                "game_identity": identity(game.pid),
                "display": env["DISPLAY"],
                "size": size,
                "scene": (directory / "ready").read_text(),
                "repo": str(ROOT),
            },
        )
        while True:
            if game.poll() is not None:
                reason = f"the game exited with code {game.returncode}"
                break
            if children[0].poll() is not None:
                reason = "Xvfb exited"
                break
            if time.time() - (directory / "activity").stat().st_mtime > IDLE_SECONDS:
                reason = f"idle for {IDLE_SECONDS // 60} minutes"
                break
            time.sleep(0.5)
    except ValueError as error:
        reason = str(error)
        raise
    finally:
        write_json(directory / "ended.json", {"reason": reason, "time": time.time()})
        (directory / "session.json").unlink(missing_ok=True)
        for child in reversed(children):
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()


def report_problems(directory, heading):
    found = problems(directory / "game.log")
    if found:
        print(f"look: {heading} {len(found)} error(s) or warning(s):", file=sys.stderr)
        for problem in found[:20]:
            print(problem, file=sys.stderr)
    return found


def start(args):
    dependencies()
    prune_sessions()
    size = SIZES.get(args.size, args.size)
    if not re.fullmatch(r"[1-9]\d{2,4}x[1-9]\d{2,4}", size):
        raise ValueError("Size is pc or WIDTHxHEIGHT, such as 1280x720")
    if args.scene and not args.scene.startswith("res://"):
        raise ValueError("Scene is a res:// path, such as res://tests/look/look_demo.tscn")
    directory = STATE / (time.strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6])
    directory.mkdir(parents=True, mode=0o700)
    with (directory / "supervisor.log").open("ab") as log:
        process = subprocess.Popen(
            [
                sys.executable,
                str(Path(__file__).resolve()),
                "_serve",
                str(directory),
                size,
                args.scene,
                str(args.timeout),
            ],
            stdout=log,
            stderr=log,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
    said = False
    while not (directory / "session.json").exists():
        if not said and "waiting" in (directory / "supervisor.log").read_text():
            print("look: all look slots are taken; waiting for a game to stop", file=sys.stderr, flush=True)
            said = True
        if process.poll() is not None:
            # No game.log when the game never started (no free slot, or Xvfb failed).
            logs = "game.log and supervisor.log" if (directory / "game.log").exists() else "supervisor.log"
            if logs.startswith("game"):
                report_problems(directory, "the game logged")
            raise ValueError(f"Start failed: {ended_note(directory).split(': ', 1)[-1]}. Log: {directory}/{logs}")
        time.sleep(0.1)
    data = json.loads((directory / "session.json").read_text())
    report_problems(directory, f"{data['scene']} is running, but while starting it logged")
    print(directory.name)


def act(args):
    directory, data = selected(args.session)
    # One command at a time per session, so input order and shot numbers stay consistent.
    with (directory / "command.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        check_game(directory, data)
        (directory / "activity").touch()
        env = dict(os.environ, DISPLAY=data["display"])
        if args.command == "shot":
            if not re.fullmatch(r"[A-Za-z0-9_-]+", args.label):
                raise ValueError("Shot label must contain only letters, numbers, _ or -")
            if args.wait:
                time.sleep(min(args.wait, 30))
            numbers = [int(p.name.split("-", 1)[0]) for p in directory.glob("[0-9][0-9][0-9]-*.png")]
            path = directory / f"{max(numbers, default=0) + 1:03d}-{args.label}.png"
            run(["scrot", "--overwrite", path], env=env)
            print(path)
        elif args.command == "key":
            run(["xdotool", "key", "--clearmodifiers", *args.keysyms], env=env)
        else:
            width, height = (int(n) for n in data["size"].split("x"))
            coords = [(args.x, args.y)] + ([(args.x2, args.y2)] if args.command == "drag" else [])
            if any(not (0 <= x < width and 0 <= y < height) for x, y in coords):
                raise ValueError(f"Coordinates must be within {data['size']}")
            run(["xdotool", "mousemove", "--sync", args.x, args.y], env=env)
            if args.command == "click":
                run(["xdotool", "click", "1"], env=env)
            elif args.command == "drag":
                run(["xdotool", "mousedown", "1"], env=env)
                try:
                    time.sleep(0.1)
                    for step in range(1, 21):
                        x = round(args.x + (args.x2 - args.x) * step / 20)
                        y = round(args.y + (args.y2 - args.y) * step / 20)
                        run(["xdotool", "mousemove", x, y], env=env)
                        time.sleep(0.025)
                finally:
                    run(["xdotool", "mouseup", "1"], env=env)
        # Let Godot receive the event and draw a few frames (it runs at 30 fps).
        time.sleep(0.2)
        check_game(directory, data)


def check_game(directory, data):
    """Fail loudly when the game has quit or crashed, with the reason the supervisor recorded."""
    if identity(data["game_pid"]) == data["game_identity"]:
        return
    deadline = time.monotonic() + 3
    while not (directory / "ended.json").exists() and time.monotonic() < deadline:
        time.sleep(0.1)
    raise ValueError(f"{ended_note(directory)}; read why with: tools/look/look errors")


def errors(args):
    directory = any_session(args.session)
    found = problems(directory / "game.log")
    for problem in found:
        print(problem)
    note = "" if (directory / "session.json").exists() else f" ({ended_note(directory).split(': ', 1)[-1]})"
    print(f"look: {len(found)} error(s) or warning(s) in {directory / 'game.log'}{note}", file=sys.stderr)


def log(args):
    directory = any_session(args.session)
    lines = (directory / "game.log").read_text(errors="replace").splitlines()
    print("\n".join(lines[-args.lines :]))


def stop(session_id):
    directory, data = selected(session_id)
    os.kill(data["pid"], signal.SIGTERM)
    deadline = time.monotonic() + 15
    while identity(data["pid"]) == data["identity"]:
        if time.monotonic() > deadline:
            raise ValueError(f"Stop timed out; see {directory / 'supervisor.log'}")
        time.sleep(0.1)
    print(f"stopped {directory.name}")


def main():
    global STATE
    if len(sys.argv) > 1 and sys.argv[1] == "_serve":
        STATE = Path(sys.argv[2]).parent
        try:
            serve(Path(sys.argv[2]), sys.argv[3], sys.argv[4], float(sys.argv[5]))
        except ValueError as error:
            print(f"look: {error}", file=sys.stderr)
            sys.exit(1)
        return
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", default=os.environ.get("BRAMBLE_LOOK_SESSION"), help="session ID from start/list")
    commands = parser.add_subparsers(dest="command", required=True)
    p = commands.add_parser("start", help="run a scene; prints the session ID")
    p.add_argument("--scene", default="", help="res:// scene (default: the project's main scene)")
    p.add_argument("--size", default="pc", help="pc (1920x1080, default) or WIDTHxHEIGHT")
    p.add_argument("--timeout", type=float, default=60, help="seconds to wait for the scene (default 60)")
    for name in ["click", "move", "drag"]:
        p = commands.add_parser(name)
        for coord in ["x", "y", "x2", "y2"] if name == "drag" else ["x", "y"]:
            p.add_argument(coord, type=int)
    p = commands.add_parser("shot", help="screenshot; prints the PNG path")
    p.add_argument("label", nargs="?", default="shot")
    p.add_argument("--wait", type=float, default=0, help="seconds to wait first, such as for an animation")
    p = commands.add_parser("key", help="X keysyms, such as Escape, space, ctrl+a; several press in turn")
    p.add_argument("keysyms", nargs="+")
    commands.add_parser("errors", help="the game's errors and warnings so far")
    p = commands.add_parser("log", help="the end of the game's full log")
    p.add_argument("-n", "--lines", type=int, default=40)
    commands.add_parser("list", help="live sessions")
    commands.add_parser("stop")
    args = parser.parse_args()
    STATE = state_directory()
    os.environ["BRAMBLE_LOOK_DIR"] = str(STATE)
    if args.command == "start":
        start(args)
    elif args.command == "list":
        for path, data in sessions():
            print(f"{path.name}  {data['display']}  {data['size']}  {data['scene']}  {data['repo']}")
    elif args.command == "stop":
        stop(args.session)
    elif args.command == "errors":
        errors(args)
    elif args.command == "log":
        log(args)
    else:
        act(args)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"look: {error}", file=sys.stderr)
        sys.exit(1)
