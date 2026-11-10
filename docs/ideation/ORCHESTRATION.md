# How the ideation orchestrator works

One page for the owner and for other agents. Details live in `RESTART.md` §5 (procedures), `CLOUD.md` (cloud rules) and `DECISIONS.md` (every call, with its reason). Last updated 10 Nov 2026.

## Where each job goes, and why

Owner direction, 10 Nov (`owner-notes/2026-11-10b`, `10c`): "way, way, way more Codex usage and less Opus usage." Claude budget is the scarce one.

| Job | Where | Why |
|---|---|---|
| Planning, merge calls, DECISIONS, the owner's questions | The orchestrator: one Claude session on this machine | One decider. It keeps its turns short. |
| Builds, fixes, sims, tests, exports, art | Sol (`gpt-6.1-sol`, effort high) through the Codex bridge | Sol is close to Opus, at about half the price. Art needs Codex's image tool. |
| Reviews of Codex work, critics, triage, cold readers and scorers | Fresh Sol threads (`kind: review` or `ask`), given the owner's words and the plan, with the author's notes as claims | Independent of the author, and off the Claude budget. |
| Extra parallel work | `gpt-6-astra`, effort medium or high, alongside Sol when there's spare usage, or in place of Sol when Sol's weekly limit is reached | Owner, 10 Nov. Sol keeps the hardest work. |
| More work than this machine holds | Codex Cloud (below), once the owner creates its environment | RAM caps local workers at 5 (14 GB; Godot runs take up to 3 GB each). |
| Full gates | GitHub Actions: `scripts/cloud-gate.sh` | Sharded and off this machine. |
| Work that needs follow-up messages | Claude cloud routines, only with a logged reason | They're persistent, but they cost Claude budget. |

## Commands

```bash
# Gate a commit on Actions (about 12 min). Prints "GATE <sha> PASS|FAIL <url>".
timeout 5400 scripts/cloud-gate.sh <sha> "<label>"
scripts/cloud-gate.sh --check <sha>                   # did this exact commit pass?
gh run view <run id> --log-failed | grep -E "\[Failed\]|SCRIPT ERROR|Float/Int"
# Docs-only commits: no Godot, about 30 s. Log to a file and check the exit code; don't pipe it.
./scripts/check.sh --docs-only --base <gated sha> > build/docs-check.log 2>&1; echo $?
# Merging a step: build the merge in the scratch worktree, gate it, then bring it into ideation/main.
git -C ../Bramble-ideation-merge checkout --detach origin/ideation/main
git -C ../Bramble-ideation-merge merge --no-ff origin/ideation/<branch>
git merge --no-ff <gated sha>     # in the main checkout, then the docs-only check, then push
# Godot on this machine, always through a slot: 2 at once, 3 GB cap each.
GODOT_SLOT_CLASS=worker scripts/godot_slot.sh <godot command>
# Codex weekly usage: used_percent, resets_at, credits.
grep -o '"rate_limits":{[^}]*}[^}]*}' "$(ls -t ~/.codex/sessions/*/*/*/*.jsonl | head -1)" | tail -1
# A Sol worker outside the bridge, when its slots are full: background, hard timeout, own worktree.
timeout 3300 codex exec -C <worktree> -s workspace-write -c sandbox_workspace_write.network_access=true \
  -m gpt-6.1-sol -c model_reasoning_effort='"high"' -o <out>/final.md "$(cat <brief>.md)"
# Codex Cloud (needs an environment id).
codex cloud exec --env <id> --branch ideation/main --attempts 1 "<self-contained brief>"
codex cloud list --json; codex cloud status <task>; codex cloud diff <task>; codex cloud apply <task>
# codex cloud writes error.log into the current directory: run it from build/.
# This machine's GitHub token has no workflow scope: a push that changes .github/workflows/ is refused.
```

**Codex bridge tools** (MCP, `~/code/codex-bridge`; its served instructions hold the model rules):
- `codex_delegate`: implement, review or ask, in a worktree under `CODEX_BRIDGE_ROOTS`.
- `codex_send`: steer a running turn, or start a follow-up.
- `codex_wait` and `codex_status`: follow a worker.
- `codex_close`: end a worker.

The bridge cap is `CODEX_BRIDGE_MAX` = 5 (the owner's config). It loads when the bridge reconnects. A turn ends silently at 60 min, so turns stay under 45. Workers commit but can't push; the orchestrator pushes. The local `build/orchestrator/bin/waitw.sh w2 w4` returns when a worker's turn ends.

**Claude cloud routines** (the `RemoteTrigger` tool):
- start one with `create`, then `update` with `clear_mcp_connections`, then `run`;
- message it with `update` (content starting "Orchestrator:") and then `run`;
- read it with `list_runs` and `get_run_log`.

## Rules that don't bend
- **Never push to, merge into or open a PR against `main`.** Ideation reaches `main` only with the owner's say-so (06a). Work lands on `ideation/*` branches. No PRs at all: a PR's default base is `main`.
- **Every step passes the Actions gate and a fresh reviewer before it merges into ideation/main.** Cut items get fixed first. Ask items are the orchestrator's call, logged in DECISIONS.
- **Owner notes are records.** They're never edited, and corrections go in a new note.
- **Never run `pgrep -f` or `pkill -f`.** Workflow agents and Claude subagents never run Godot.

## Talking to the orchestrator (other agents)
- **To add to this page,** push a branch named `ideation/codex-<slug>`. Change only `docs/` (this file, or a new file beside it). Don't open a PR. The orchestrator checks `git ls-remote origin 'refs/heads/ideation/codex-*'` each cycle and merges docs-only branches after `check.sh --docs-only`.
- **For anything that needs a decision,** put the question in the branch's commit message or at the top of the file you changed. The orchestrator answers in DECISIONS.
- **The owner's messages** come in the orchestrator session and the portal inbox (`docs/workstreams/README.md`).

## Codex Cloud: steering and collecting

The owner published the **Bramble** environment on 10 Nov 2026. [Codex Cloud handoff](CODEX_CLOUD.md) covers setup, submission, collecting results, steering, limits and usage, with verified commands and the remaining authentication/ID question at the top.

The installed `codex cloud` CLI has no follow-up or steering command. The existing local bridge's `codex_send` is the available steering route for workers it owns; it does not attach to hosted cloud tasks. Cloud results come back as diffs applied on an `ideation/*` branch, or as a worker's `ideation/*` branch. Never apply to `main`, open a PR, or assume cloud workers cannot push. The orchestrator still gates and reviews before merging.
