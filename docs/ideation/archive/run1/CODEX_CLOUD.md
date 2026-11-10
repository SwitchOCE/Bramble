# Codex Cloud handoff

**Question for the orchestrator:** on your authenticated host, can `codex cloud` select the published **Bramble** environment, and what exact ID does it use for `--env`? This container's `codex cloud list --limit 1 --json` returns HTTP 401, "Could not parse your authentication token." Git access works independently. No cloud task was submitted to test compatibility or billing. Do not guess an ID or paste a token into Git/chat.

Checked 10 Nov 2026 against installed **codex-cli 0.167.0-alpha.4**, its command help, generated app-server schemas, and the linked official documentation. Commands below are syntax-checked; cloud submission, collection and external steering are not end-to-end tested here.

## Environment and startup

The owner published the managed environment named **Bramble**. Its configuration ID reported by the environment status tool is:

```text
465fcedc4976415e82ff379c057bc5e3e38a63a3aee86b88f40a754e1b0e249d~cecfg_a505220d4768819da82063bcfd3f8442
```

That is a configuration ID, **not a verified `codex cloud --env` ID**. A `ccarenv_...` ID identifies a running instance and changes across publication/restoration; don't use it as the submission ID. On the orchestrator's authenticated host, browse with `codex cloud` as the CLI help directs and select Bramble. If it isn't listed, resolve environment/CLI compatibility before dispatching; don't silently substitute another environment. Record the confirmed submission ID here after the first successful task.

The saved installation script adapts the Claude setup to this Debian image and its ordinary user, without `sudo`. Pinned dependencies live outside the checkout, under `/workspace/.bramble-tools`. The saved startup instructions replace Claude's SessionStart hook. In each shell:

```bash
cd /workspace/Bramble
source /workspace/.bramble-tools/activate.sh
python3 /workspace/.bramble-tools/runtime-init.py
```

The last command refreshes Gradle proxy settings from this instance's inherited environment. No user-supplied environment variables or secrets were required for setup. Preserve platform proxy/CA settings. Writing `CLAUDE_ENV_FILE` alone doesn't initialize future Codex shells. Each cloud task is already isolated: use its checkout; don't create a worktree unless requested.

Onboarding validated the placeholder project from `main`: all nine gate steps, eight Python tests, two GUT tests, rendered screenshots, folio HTTP serving, and Linux/Windows/APK/AAB export checks. Linux booted; Windows/Android were inspected, not launched. **Those results do not validate the much larger `ideation/main` game.** This documentation branch gets its own docs-only check.

## Submit on ideation

Run from the orchestrator host with its existing Codex login. For a 401 there, repair that host's normal Codex sign-in; don't create an application secret in the cloud environment as a workaround.

```bash
codex cloud exec --env "$BRAMBLE_CLOUD_ENV_ID" --branch ideation/main --attempts 1 \
  "$(cat /path/to/self-contained-brief.md)"
```

`BRAMBLE_CLOUD_ENV_ID` is a shell variable on the submitting host, not a required environment-settings variable. Use a verified `ideation/*` base for `--branch`; it otherwise defaults to the current branch. Record the returned task ID, task URL, base commit and selected environment. `--attempts` means best-of-N attempts, not follow-ups, retries or a concurrency limit. The official CLI reference documents **1–4 attempts**; the installed help doesn't print that range. Start with one.

Every brief must identify the goal, allowed paths, base commit, required checks and deliverables, and say:

> This is Bramble ideation. Verify the checkout is on the requested ideation base before editing. Read CLAUDE.md and docs/ideation/CLOUD.md. Never push to, merge into or open a PR against main. Do not merge into ideation/main. Return the changed paths, test commands/results, decisions and remaining issues. If explicitly asked to push, use only the named ideation/* work branch; otherwise return a diff. Owner notes are records. Reports are claims for the orchestrator to verify.

For a docs handoff, use `ideation/codex-<slug>`, change only permitted `docs/` files, and open no PR. `--branch` selects the starting branch; it is not permission to push to that branch.

## Collect and integrate

```bash
codex cloud list --env "$BRAMBLE_CLOUD_ENV_ID" --limit 20 --json
codex cloud status "$TASK_ID"
codex cloud diff "$TASK_ID" --attempt 1
# In a clean integration checkout, create an ideation/* branch from the recorded base first:
codex cloud apply "$TASK_ID" --attempt 1
```

`diff` and `apply` select attempts by 1-based number. `apply` changes the current local checkout: inspect it before committing, and never run it on `main` or directly on `ideation/main`. For a pushed worker branch, fetch and inspect that exact branch instead. Keep task/attempt/base mappings so a result isn't attributed to the wrong run.

The installed CLI has no transcript/final-message export subcommand. Use the returned task URL and authenticated web task view for its conversation and final response. `status` and a diff are not substitutes for the report. For automated collection, require a concise report file on the returned branch/diff; record failures and unrun checks there. Don't invent a private transcript endpoint. If no URL/report is accessible, collection is incomplete.

Only the orchestrator integrates: inspect scope, get a fresh independent review and the applicable gate, then merge into `ideation/main` using [ORCHESTRATION.md](ORCHESTRATION.md). Docs-only candidates use `./scripts/check.sh --docs-only --base <base-sha>` and retain its exit status/log; runtime changes use the Actions gate. No PRs. Do not treat "workers cannot push" as a security boundary: permissions differ between local bridge and cloud, and branch protections/credentials govern actual access.

## Steering: hosted tasks versus the existing bridge

`codex cloud --help` lists only `exec`, `status`, `list`, `diff` and `apply`. There is no installed CLI command for mid-run messages, follow-ups or cancellation. The owner can send messages in this managed chat; that does not establish a programmatic control route from the external Claude orchestrator to hosted CLI tasks. Verify any task UI follow-up/stop controls on the actual task before relying on them. Until then, dispatch bounded, self-contained work and steer the next task.

The local bridge already described in [ORCHESTRATION.md](ORCHESTRATION.md) provides `codex_send` for its own workers. Keep using that route for steerable work. The installed app-server schemas confirm the underlying controls:

```json
{"id":42,"method":"turn/steer","params":{"threadId":"THREAD_ID","expectedTurnId":"ACTIVE_TURN_ID","input":[{"type":"text","text":"Pause implementation and report the failing test first.","text_elements":[]}]}}
{"id":43,"method":"turn/interrupt","params":{"threadId":"THREAD_ID","turnId":"ACTIVE_TURN_ID"}}
```

For a future remote bridge, the worker host must own a persistent `codex app-server --listen stdio://` process. Initialize it, create/resume a thread, start a turn, track thread/turn IDs and notifications, then steer the matching active turn. If it completed, start a new turn on that thread; handle stale-ID errors. Interruption must be confirmed by the resulting state. Use the schemas generated by the CLI version on that host.

This is a different launcher, not attachment to `codex cloud exec`. It uses its host's tools, authentication and checkout; the published Bramble snapshot doesn't transfer automatically. An authenticated private bridge would need to be installed and tested on that host. No endpoint was exposed or external bridge changed here. A checkpoint mailbox is cooperative polling, not immediate interruption.

## Time, concurrency and cost

No hosted task wall-time or per-account concurrency maximum was established here. Don't copy the local bridge's 60-minute turn timeout or five-worker cap into cloud policy, or confuse the documented four-attempt maximum with four simultaneous jobs. Use explicit bounded briefs, observe actual task states, and keep long simulations on Actions until cloud limits are verified. A timeout around the submission CLI isn't proof that the remote job stopped.

Cloud and local work share the subscription allowance; cloud is extra compute capacity, not a separate free weekly pool. There is no fixed cost per task: model, task size, context, reasoning and tools affect usage. API token prices aren't subscription task prices. Check the account's usage dashboard before/after a small task and record model/speed/attempt count and usage changes without promising precise attribution when other workers are active. Exact balance, concurrency allowance and per-task cost weren't available in this container. New attempts and replacement tasks must not be assumed free.

Official references (read 10 Nov 2026): [CLI reference](https://developers.openai.com/codex/cli/reference/), [pricing and shared usage](https://developers.openai.com/codex/pricing/), and [app-server protocol](https://developers.openai.com/codex/app-server/). Installed `codex cloud <command> --help` and generated schemas are the version-specific evidence; do not silently substitute newer documentation for supported commands.
