#!/usr/bin/env python3
"""After-match check: did a team's agents look where they may not? (T3 amendment, section 4)

Searches what a team's agents asked their tools to do, never what the tools answered:
  - T3's thread store: every tool call and shell command of every thread in the team's
    T3 project, sub-agents and Codex children included, deleted threads too;
  - Codex's session logs: every command of every session started under the team's folders.

It flags two things:
  - a T3 tool that lists, reads, searches, messages or starts threads, unless its target
    is one of the team's own threads or the referee's thread;
  - a path under T3's data, Codex's data, another project's Claude folder, or a folder
    given with --ban (the other team's clone, the shared repo).

A hit is something for the referee to read, not a verdict. No hit doesn't prove a clean
team: an agent can reach a file through a command this search doesn't recognise.

usage: audit_teams.py --clone /home/alex/league/red --referee <thread id>
                      [--ban /home/alex/league/blue ...] [--since 2026-11-18T10:00]
Exit code: 0 no hits, 1 hits, 2 the team's project or threads weren't found.
"""
import argparse, glob, json, os, re, sqlite3, sys

HOME = os.path.expanduser("~")
THREAD_TOOL = re.compile(
    r"(t3_thread_\w+|t3_queue|t3_project_\w+|t3_environment_\w+|create_threads|"
    r"t3_worktree_\w+|task_status|list_scheduled_tasks|mcp__codex__\w+)$")


def banned_paths(text, own, bans):
    """Banned paths named in text. `own` are folders the team may use."""
    hits = []
    for m in re.finditer(r"(?:~|\$HOME|" + re.escape(HOME) + r")?/[\w.@%+=:,~-]+(?:/[\w.@%+=:,~-]+)*", text):
        p = m.group(0).replace("$HOME", HOME)
        if p.startswith("~"):
            p = HOME + p[1:]
        if any(p == o or p.startswith(o + "/") for o in own):
            continue
        for b in bans:
            if p == b or p.startswith(b + "/"):
                hits.append(p)
                break
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clone", required=True)
    ap.add_argument("--referee", required=True, help="the referee's thread id")
    ap.add_argument("--ban", action="append", default=[])
    ap.add_argument("--since", default="", help="ignore anything before this ISO time (UTC)")
    ap.add_argument("--db", default=f"{HOME}/.t3/userdata/statev2.sqlite")
    ap.add_argument("--codex", default=f"{HOME}/.codex/sessions")
    a = ap.parse_args()

    clone = a.clone.rstrip("/")
    worktrees = f"{HOME}/.t3/worktrees/{os.path.basename(clone)}"
    slug = re.sub(r"[^A-Za-z0-9]", "-", clone)
    own = [clone, worktrees, f"{HOME}/.claude/projects/{slug}", f"/tmp/claude-{os.getuid()}/{slug}",
           f"{HOME}/.codex/skills"]
    bans = [f"{HOME}/.t3", f"{HOME}/.codex", f"{HOME}/.claude/projects"] + [b.rstrip("/") for b in a.ban]

    db = sqlite3.connect(f"file:{a.db}?mode=ro", uri=True)
    projects = [r[0] for r in db.execute(
        "select project_id from projection_projects where workspace_root = ?", (clone,))]
    if not projects:
        print(f"no T3 project has the folder {clone}", file=sys.stderr)
        return 2
    marks = ",".join("?" * len(projects))
    threads = {r[0]: r[1] for r in db.execute(
        f"select thread_id, title from orchestration_v2_projection_threads where project_id in ({marks})",
        projects)}
    if not threads:
        print(f"the T3 project for {clone} has no threads", file=sys.stderr)
        return 2
    allowed_targets = set(threads) | {a.referee}

    hits, calls = [], 0
    marks = ",".join("?" * len(threads))
    for thread, payload in db.execute(
            "select thread_id, payload_json from orchestration_v2_projection_turn_items "
            f"where thread_id in ({marks}) and type in ('dynamic_tool','command_execution','file_change','subagent')",
            list(threads)):
        d = json.loads(payload)
        when = d.get("startedAt") or d.get("updatedAt") or ""
        if when < a.since:
            continue
        calls += 1
        tool = d.get("toolName") or d["type"]
        asked = d.get("input", d.get("prompt", ""))
        text = asked if isinstance(asked, str) else json.dumps(asked)
        where = f"T3 thread '{threads[thread]}'"
        if THREAD_TOOL.search(tool):
            target = asked.get("threadId") if isinstance(asked, dict) else None
            if not (target in allowed_targets and not asked.get("environmentId")):
                hits.append((when, where, tool, text))
        for p in banned_paths(text, own, bans):
            hits.append((when, where, tool, p))

    sessions = 0
    for f in sorted(glob.glob(f"{a.codex}/**/*.jsonl", recursive=True)):
        with open(f, errors="replace") as fh:
            first = fh.readline()
            try:
                cwd = json.loads(first)["payload"].get("cwd", "")
            except (ValueError, KeyError):
                continue
            if not any(cwd == o or cwd.startswith(o + "/") for o in (clone, worktrees)):
                continue
            sessions += 1
            for line in fh:
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                p = d.get("payload") or {}
                if d.get("type") != "response_item" or not str(p.get("type", "")).endswith("_call"):
                    continue
                when = d.get("timestamp", "")
                if when < a.since:
                    continue
                calls += 1
                text = str(p.get("input") or p.get("arguments") or p.get("action") or "")
                where = f"Codex session {os.path.basename(f)}"
                if THREAD_TOOL.search(str(p.get("name", ""))):
                    hits.append((when, where, p.get("name"), text))
                for path in banned_paths(text, own, bans):
                    hits.append((when, where, p.get("name"), path))

    print(f"{clone}: {len(threads)} T3 threads, {sessions} Codex sessions, {calls} tool calls and commands searched")
    for when, where, tool, what in sorted(hits):
        print(f"HIT {when[:19]} {where}: {tool}: {what[:160]}")
    print(f"{len(hits)} hits")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
