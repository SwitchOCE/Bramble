#!/usr/bin/env bash
# Report only: never stops processes or removes files. Linux /proc, current user only.
# LEFTOVERS_AGE_SECONDS=1800       age threshold for Godot, Xvfb and Wine
# LEFTOVERS_MIN_TMP_BYTES=1073741824  minimum free /tmp space (exit 2 below it)
# LEFTOVERS_MAX_USER_TMP_BYTES=3221225472  warn above this user's allocated /tmp file bytes
# LEFTOVERS_KEEP_UNITS='xvfb@*.service'  space-separated systemd units whose old processes
#   are meant to run (the agents' standing display); a deleted cwd is still reported
# Exit 0: clean or warnings only; exit 2: /tmp space is below the threshold.
set -uo pipefail

python3 - <<'PY'
import fnmatch
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import time

uid = os.getuid()
age_limit = int(os.environ.get("LEFTOVERS_AGE_SECONDS", "1800"))
min_free = int(os.environ.get("LEFTOVERS_MIN_TMP_BYTES", "1073741824"))
max_user_tmp = int(os.environ.get("LEFTOVERS_MAX_USER_TMP_BYTES", "3221225472"))
keep_units = os.environ.get("LEFTOVERS_KEEP_UNITS", "xvfb@*.service").split()
now = time.time()


def age(seconds):
    seconds = max(0, int(seconds))
    return f"{seconds // 3600}h {(seconds % 3600) // 60}m {seconds % 60}s"


def size(amount):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if amount < 1024 or unit == "TiB":
            return f"{amount:.1f} {unit}" if unit != "B" else f"{amount} B"
        amount /= 1024


def user_tmp_bytes():
    # scandir keeps the walk cheap; don't follow symlinks out of /tmp or into loops.
    total = 0
    pending = ["/tmp"]
    seen = set()
    while pending:
        try:
            with os.scandir(pending.pop()) as entries:
                for entry in entries:
                    try:
                        info = entry.stat(follow_symlinks=False)
                        if info.st_uid != uid:
                            continue
                        if stat.S_ISDIR(info.st_mode):
                            pending.append(entry.path)
                        elif stat.S_ISREG(info.st_mode):
                            key = (info.st_dev, info.st_ino)
                            if key not in seen:
                                seen.add(key)
                                total += info.st_blocks * 512
                    except OSError:
                        pass
        except OSError:
            pass
    return total


# One snapshot supplies ages, CPU usage and parent links, including other users' parents.
processes = {}
snapshot = subprocess.check_output(
    ["ps", "-eo", "uid=,pid=,ppid=,etimes=,pcpu=,comm="], text=True
)
for line in snapshot.splitlines():
    owner, pid, parent, elapsed, cpu, comm = line.split(None, 5)
    processes[int(pid)] = (int(owner), int(parent), int(elapsed), cpu, comm)

# check.sh runs the sweep before starting work; skip only ourselves and our shell.
excluded = {os.getpid(), os.getppid()}


def standing(pid):
    # A process of a kept systemd unit, e.g. the xvfb@99 display started at boot for agents.
    try:
        unit = Path(f"/proc/{pid}/cgroup").read_text().strip().rsplit("/", 1)[-1]
    except OSError:
        return False
    return any(fnmatch.fnmatch(unit, pattern) for pattern in keep_units)


def chain(pid):
    parts = []
    seen = set()
    while pid in processes and pid not in seen:
        seen.add(pid)
        proc = processes[pid]
        parts.append(f"{proc[4]}({pid})")
        pid = proc[1]
    if pid:
        parts.append(f"?({pid})")
    return " <- ".join(parts)


print(f"Leftovers sweep (uid {uid}; visible /proc processes only; report-only)")
print(f"Processes (deleted cwd or Godot/Xvfb/Wine age >= {age(age_limit)}):")
warnings = 0
for pid, (owner, parent, elapsed, cpu, comm) in sorted(processes.items()):
    if owner != uid or pid in excluded:
        continue
    reasons = []
    try:
        cwd = os.readlink(f"/proc/{pid}/cwd")
        if cwd.endswith(" (deleted)"):
            reasons.append(f"deleted cwd: {cwd}")
    except OSError:
        pass
    # comm is truncated at 15 characters on Linux; argv[0] also catches long .exe names.
    names = [comm.lower()]
    try:
        argv0 = Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0", 1)[0]
        names.append(Path(os.fsdecode(argv0).replace("\\", "/")).name.lower())
    except OSError:
        pass
    target = any(
        name.startswith(("godot", "wine")) or name in ("xvfb", "xvfb-run") or name.endswith(".exe")
        for name in names
    )
    if target and elapsed >= age_limit and not standing(pid):
        reasons.append("old Godot/Xvfb/Wine process")
    if reasons:
        warnings += 1
        print(f"  WARNING PID {pid}, age {age(elapsed)}, CPU {cpu}%: {'; '.join(reasons)}")
        print(f"    parents: {chain(pid)}")
        print(f"    If no longer needed: kill {pid}")
if not warnings:
    print("  none")

# The Optiplex's memory guard (earlyoom) stops the biggest process when memory runs out.
# List what it stopped, so a job that ended with "Terminated" has an explanation.
stops = []
if shutil.which("earlyoom") and shutil.which("journalctl"):
    try:
        journal = subprocess.run(
            ["journalctl", "-u", "earlyoom", "--since", "-1d", "-g", "to process",
             "-o", "short", "--no-pager", "-q"],
            capture_output=True, text=True, timeout=20,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        journal = ""
    for line in journal.splitlines():
        match = re.search(
            r'^(\S+ +\d+ [\d:]+) .*sending (SIG\w+) to process (\d+) uid \d+ "([^"]*)"'
            r'.*VmRSS (\d+) MiB, cmdline "(.*?)"?$', line)
        if match:
            stops.append(match.groups())
    print("Memory guard stops in the last 24 hours (journalctl -u earlyoom):")
    for when, signal, pid, name, rss, command in stops:
        print(f"  {when}: {signal} to {name} (PID {pid}), {size(int(rss) * 1024 * 1024)}: {command[:120]}")
    if not stops:
        print("  none")

free = shutil.disk_usage("/tmp").free
low_space = free < min_free
owned = user_tmp_bytes()
quota_warning = owned > max_user_tmp
print(f"/tmp free: {size(free)} (minimum {size(min_free)})" + (" — LOW" if low_space else "")
      + f"; uid {uid} files: {size(owned)} ({owned} bytes allocated)")
if quota_warning:
    print(f"WARNING: /tmp has a per-user quota; uid {uid} files use {size(owned)} "
          f"(warning threshold {size(max_user_tmp)}).")

claude = Path(f"/tmp/claude-{uid}")


def tmp_folders(root, repo_only=False):
    folders = []
    try:
        for path in root.iterdir():
            try:
                if path.is_dir() and (not repo_only or (path / "project.godot").is_file()):
                    folders.append(path)
            except OSError:
                pass
    except OSError:
        pass
    return sorted(folders)


sessions = tmp_folders(claude)
copies = tmp_folders(Path("/tmp"), repo_only=True)
folders = list(dict.fromkeys(sessions + copies))
sizes = {}
if folders:
    # Batch du: one walk per folder, no per-file subprocesses. Never delete others' files.
    usage = subprocess.run(["du", "-sk", "-0", "--", *map(str, folders)], capture_output=True)
    for entry in usage.stdout.split(b"\0"):
        if entry:
            blocks, path = entry.split(b"\t", 1)
            sizes[os.fsdecode(path)] = size(int(blocks) * 1024)
    if usage.returncode:
        print("WARNING: some folder sizes are incomplete (unreadable or removed during sweep)")

for label, paths in ((f"Claude temp folders ({claude}/)", sessions), ("Repo copies directly under /tmp", copies)):
    print(f"{label}:")
    if not paths:
        print("  none")
    for path in paths:
        try:
            modified = f"last modified {age(now - path.stat().st_mtime)} ago"
        except OSError:
            modified = "last modified unknown (folder disappeared)"
        print(f"  {path}: {sizes.get(str(path), 'size unavailable')}; {modified}")

print(f"leftovers: {'LOW /tmp SPACE' if low_space else 'ok'}; {warnings} process warning(s); "
      f"{len(sessions)} Claude temp folder(s); {len(copies)} repo copy/copies; /tmp free {size(free)}; "
      f"user /tmp files {size(owned)}" + (" (quota warning)" if quota_warning else "")
      + (f"; {len(stops)} memory guard stop(s) in 24 h" if stops else ""))
raise SystemExit(2 if low_space else 0)
PY
