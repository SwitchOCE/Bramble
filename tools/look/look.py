"""Headless look → act → look sessions. See README.md for the command interface."""

import argparse
import fcntl
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import uuid
from contextlib import suppress
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "bramble/look"
SIZES = {"pc": "1920x1080", "phone": "1688x780"}


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


def prune_sessions():
    live = {path for path, _data in sessions()}
    cutoff = time.time() - 7 * 86400
    for path in STATE.iterdir():
        if (
            path.is_symlink()
            or not path.is_dir()
            or path in live
            or not re.fullmatch(r"\d{8}-\d{6}-[0-9a-f]{6}", path.name)
        ):
            continue
        activity = path / "activity"
        modified = max(path.stat().st_mtime, activity.stat().st_mtime if activity.exists() else 0)
        if modified < cutoff:
            shutil.rmtree(path)


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, **kwargs)


def write_json(path, data):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data))
    temporary.replace(path)


def identity(pid):
    """Include Linux process start time, so an old session never targets a reused PID."""
    try:
        stat = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        return stat[19] if stat[0] != "Z" else None
    except (FileNotFoundError, ProcessLookupError):
        return None


def sessions():
    found = []
    for path in sorted(STATE.glob("*/session.json")):
        data = json.loads(path.read_text())
        if identity(data["pid"]) == data["identity"]:
            found.append((path.parent, data))
    return found


def selected(session_id):
    live = sessions()
    if session_id:
        live = [(p, d) for p, d in live if p.name == session_id]
    if len(live) != 1:
        raise ValueError("Choose one live session with --session ID (see tools/look/look list).")
    return live[0]


def states():
    return (HERE / "states.txt").read_text().rstrip()


def dependencies():
    for command in [os.environ.get("GODOT", "godot"), "Xvfb", "xdotool", "scrot", "flock"]:
        if not shutil.which(command):
            raise ValueError(f"Missing dependency: {command}; see tools/look/README.md")
    if not (ROOT / ".godot/global_script_class_cache.cfg").exists():
        raise ValueError("Import first: scripts/godot_slot.sh godot --headless --editor --import")


def new_directory():
    path = STATE / (time.strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6])
    path.mkdir(parents=True, mode=0o700)
    return path


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
    # Xvfb allocates the display atomically and publishes its number only once ready.
    import select

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


def serve(directory, size, state):
    """One supervisor owns the display and game, including idle and crash cleanup."""
    env = os.environ.copy()
    env["LP_NUM_THREADS"] = env.get("LP_NUM_THREADS", "1")
    env["XDG_DATA_HOME"] = str(directory / "data")
    env["XDG_CONFIG_HOME"] = str(directory / "config")
    children = []

    def terminate(_signum, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)
    try:
        children.append(spawn_xvfb(directory, size, env))
        command = [
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
            "res://tests/ui/shots/look_live.gd",
            "--",
            state,
            size,
            str(directory / "ready"),
        ]
        game_log = (directory / "game.log").open("ab")
        children.append(subprocess.Popen(command, env=env, stdout=game_log, stderr=game_log))
        deadline = time.monotonic() + 90
        while not (directory / "ready").exists():
            if any(p.poll() is not None for p in children) or time.monotonic() > deadline:
                raise ValueError(f"Game failed to become ready; see {directory / 'game.log'}")
            time.sleep(0.1)
        (directory / "activity").touch()
        write_json(
            directory / "session.json",
            {
                "pid": os.getpid(),
                "identity": identity(os.getpid()),
                "display": env["DISPLAY"],
                "size": size,
                "state": state,
                "repo": str(ROOT),
            },
        )
        while all(p.poll() is None for p in children):
            if time.time() - (directory / "activity").stat().st_mtime > 1800:
                print("look: idle timeout", flush=True)
                break
            time.sleep(1)
    finally:
        for child in reversed(children):
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
        (directory / "session.json").unlink(missing_ok=True)


def start(args):
    dependencies()
    prune_sessions()
    directory = new_directory()
    with (directory / "supervisor.log").open("ab") as log:
        process = subprocess.Popen(
            [
                str(HERE / "slot.sh"),
                sys.executable,
                str(Path(__file__).resolve()),
                "_serve",
                str(directory),
                SIZES[args.size],
                args.state,
            ],
            stdout=log,
            stderr=log,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
    deadline = time.monotonic() + 100
    try:
        while not (directory / "session.json").exists():
            if process.poll() is not None or time.monotonic() > deadline:
                raise ValueError(f"Start failed or both look slots are busy; see {directory / 'supervisor.log'}")
            time.sleep(0.1)
    except BaseException:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=15)
        raise
    print(directory.name)


def act(args):
    directory, data = selected(args.session)
    # Serialize input and shot numbering for agents sharing a session.
    with (directory / "command.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        (directory / "activity").touch()
        env = dict(os.environ, DISPLAY=data["display"])
        if args.command == "shot":
            count = (
                max(
                    [
                        int(p.name.split("-", 1)[0])
                        for p in directory.glob("*-*.png")
                        if p.name.split("-", 1)[0].isdigit()
                    ]
                    or [0]
                )
                + 1
            )
            if not re.fullmatch(r"[A-Za-z0-9_-]+", args.label):
                raise ValueError("Shot label must contain only letters, numbers, _ or -")
            path = directory / f"{count:03d}-{args.label}.png"
            run(["scrot", path], env=env)
            print(path)
        elif args.command == "key":
            run(["xdotool", "key", "--clearmodifiers", args.keysym], env=env)
        elif args.command in {"click", "move", "drag"}:
            width, height = (int(n) for n in data["size"].split("x"))
            coords = [(args.x, args.y)]
            if args.command == "drag":
                coords.append((args.x2, args.y2))
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
        # Let Godot receive the event and settle at least a couple of rendered frames.
        time.sleep(0.2)


def stop(session_id):
    directory, data = selected(session_id)
    os.kill(data["pid"], signal.SIGTERM)
    deadline = time.monotonic() + 15
    while identity(data["pid"]) == data["identity"]:
        if time.monotonic() > deadline:
            raise ValueError(f"Stop timed out; see {directory / 'supervisor.log'}")
        time.sleep(0.1)
    print(f"stopped {directory.name}")


def clip(args):
    dependencies()
    if not (0 < args.seconds <= 60 and 1 <= args.fps <= 60):
        raise ValueError("Clip seconds must be > 0 and <= 60; fps must be 1..60")
    target = args.target
    script = "res://tests/ui/shots/look_movie.gd"
    state = "new_game_2" if target == "recruit_turn" else target
    if target.endswith(".gd"):
        path = (ROOT / target.removeprefix("res://")).resolve()
        if not path.is_relative_to(ROOT) or not path.is_file():
            raise ValueError("Custom clip script must be a .gd file inside this worktree")
        script = "res://" + str(path.relative_to(ROOT))
        state = "recruit"
    directory = new_directory()
    # Godot initializes MovieWriter before SceneTree._initialize and uses the project's
    # window overrides for its capture buffer (ignoring a later window_set_size).
    # A session-local project shares resources/imports but sets the buffer size up front.
    project = directory / "project"
    project.mkdir()
    for item in ROOT.iterdir():
        if item.name != "project.godot" and (not item.name.startswith(".") or item.name == ".godot"):
            (project / item.name).symlink_to(item, target_is_directory=item.is_dir())
    width, height = SIZES[args.size].split("x")
    config = (ROOT / "project.godot").read_text()
    config = re.sub(r"window/size/window_width_override=\d+", "window/size/window_width_override=" + width, config)
    config = re.sub(r"window/size/window_height_override=\d+", "window/size/window_height_override=" + height, config)
    (project / "project.godot").write_text(config)
    frames = directory / "frames"
    frames.mkdir()
    env = dict(
        os.environ,
        LP_NUM_THREADS=os.environ.get("LP_NUM_THREADS", "1"),
        XDG_DATA_HOME=str(directory / "data"),
        BRAMBLE_LOOK_FRAMES=str(round(args.seconds * args.fps)),
        BRAMBLE_LOOK_FPS=str(args.fps),
        BRAMBLE_LOOK_DRIVER="1" if target == "recruit_turn" else "0",
    )
    command = [
        str(HERE / "slot.sh"),
        "xvfb-run",
        "-a",
        "-s",
        f"-screen 0 {SIZES[args.size]}x24 -nolisten tcp",
        env.get("GODOT", "godot"),
        "--path",
        str(project),
        "--rendering-driver",
        "opengl3",
        "--audio-driver",
        "Dummy",
        "--windowed",
        "--resolution",
        SIZES[args.size],
        "--position",
        "0,0",
        "--disable-vsync",
        "--write-movie",
        str(frames / "frame.png"),
        "--fixed-fps",
        str(args.fps),
        "--script",
        script,
        "--",
        state,
        SIZES[args.size],
        str(directory / "ready"),
    ]
    print(f"Recording to {directory}", file=sys.stderr, flush=True)
    with (directory / "movie.log").open("wb") as log:
        # Kill the whole process group on failure/timeout, including xvfb-run's children.
        process = subprocess.Popen(command, env=env, stdout=log, stderr=log, start_new_session=True)
        try:
            if process.wait(timeout=900) != 0:
                raise ValueError(f"Movie failed; see {directory / 'movie.log'}")
        finally:
            with suppress(ProcessLookupError):
                os.killpg(process.pid, signal.SIGTERM)
    if not (directory / "ready").exists():
        raise ValueError(f"Movie never reached its state; see {directory / 'movie.log'}")
    # Pillow's distro install may be outside the project's venv.
    python = sys.executable
    if subprocess.run([python, "-c", "from PIL import Image"], capture_output=True).returncode:
        python = "/usr/bin/python3"
    run([python, HERE / "media.py", directory, str(args.fps), str(round(args.seconds * args.fps))])
    if not args.keep_frames:
        shutil.rmtree(frames)


def main():
    global STATE
    if len(sys.argv) > 1 and sys.argv[1] == "_serve":
        serve(Path(sys.argv[2]), sys.argv[3], sys.argv[4])
        return
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", default=os.environ.get("BRAMBLE_LOOK_SESSION"), help="session ID from start/list")
    commands = parser.add_subparsers(dest="command", required=True)
    p = commands.add_parser("start")
    p.add_argument("--size", choices=SIZES, required=True)
    p.add_argument("--state", default="menu")
    for name in ["click", "move", "drag"]:
        p = commands.add_parser(name)
        for coord in ["x", "y", "x2", "y2"] if name == "drag" else ["x", "y"]:
            p.add_argument(coord, type=int)
    p = commands.add_parser("shot")
    p.add_argument("label", nargs="?", default="shot")
    commands.add_parser("states")
    commands.add_parser("list")
    commands.add_parser("stop")
    p = commands.add_parser("key")
    p.add_argument("keysym")
    p = commands.add_parser("clip")
    p.add_argument("target")
    p.add_argument("--seconds", type=float, required=True)
    p.add_argument("--fps", type=int, default=30)
    p.add_argument("--size", choices=SIZES, default="phone")
    p.add_argument("--keep-frames", action="store_true", help="keep raw PNG frames after making GIF/contact sheet")
    args = parser.parse_args()
    if args.command != "states":
        STATE = state_directory()
        os.environ["BRAMBLE_LOOK_DIR"] = str(STATE)
    if args.command == "start":
        start(args)
    elif args.command == "states":
        print(states())
    elif args.command == "list":
        for path, data in sessions():
            print(f"{path.name}  {data['display']}  {data['size']}  {data['state']}  {data['repo']}")
    elif args.command == "stop":
        stop(args.session)
    elif args.command == "clip":
        clip(args)
    else:
        act(args)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"look: {error}", file=sys.stderr)
        sys.exit(1)
