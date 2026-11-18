# Bramble: notes for Codex workers

Read `CLAUDE.md` first. It holds the project's rules, and they apply to you too. Your brief from the orchestrator comes on top of them.

Two habits, from the leftover processes and full `/tmp` of 18 Nov 2026 (`docs/orchestration/leftover-processes.md`):

- Every Godot, `xvfb-run` and `wine` command gets a time limit: `timeout -k 10 <seconds> …`. A command left running after your turn keeps using the machine for hours.
- Put comparison copies of the repo in the gitignored `.copies/` folder inside your own worktree, not in `/tmp`. `/tmp` here is memory with a per-user quota, and a full quota fails everyone's gates.
