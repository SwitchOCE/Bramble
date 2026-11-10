*[Saved verbatim from a Sol research agent (codex exec, gpt-6.1-sol, high), 10 Nov, briefed with the owner's note 10b. Calls: DECISIONS "Codex Cloud: calls".]*

Bramble can move bounded jobs to Codex Cloud, but this CLI cannot fully replace persistent Claude routines. Investigation: 10 November 2026; repository unchanged. `git remote -v` confirmed `https://github.com/SwitchOCE/Bramble.git`.

Pro includes cloud tasks. Local and cloud share the weekly pool; cloud can consume more, with no fixed task multiplier. Pro currently has no five-hour limit. [Pricing][pricing] Standard cloud VMs have no separate charge at launch. [Plan][plan]

Credits fund eligible local/cloud usage after included limits. At Standard GPT-6.1 Sol rates, one credit buys 20,000 uncached input tokens, 400,000 cached input tokens, **or** 4,000 output tokens; mixed usage adds these charges. This is not a per-task price or a conversion from weekly percentage. [Pricing][pricing] Purchased credits expire after 12 months. The supplied 62,500 balance’s origin and expiry are unknown; its staying unchanged is consistent with included usage being consumed first. [Credits][credits]

Pro has no guaranteed number of extra resets. Promotional banked/global resets are discretionary; this account’s remaining count is unknown. Redeem banked resets in Usage settings or CLI `/usage`; assistant redemption requires enabling it and ≤10% remaining. [Resets][resets] Selected accounts can buy immediate resets through Usage or an exhaustion banner; these restart the weekly schedule after the next request. [Paid resets][paid]

I ran every requested `--help` on `codex-cli 0.166.0`. Flags, as printed:

| Command | Specific flags/arguments |
|---|---|
| `exec` | required `--env ENV_ID`, optional `QUERY`, `--branch BRANCH` (defaults current), `--attempts N` (default 1) |
| `status` | required `TASK_ID` |
| `list` | `--env ENV_ID`, `--limit N` (1–20; default 20), `--cursor CURSOR`, `--json` |
| `diff`, `apply` | required `TASK_ID`, `--attempt N` (1-based) |

All five also expose `-c/--config key=value`, `--enable FEATURE`, `--disable FEATURE`, `-h/--help`; parent `cloud` adds `-V/--version`. Source: executed help output.

An orchestrator can submit, poll status/list, retrieve diffs and apply locally without a browser. Environment discovery uses `codex cloud` → `o` picker; list JSON also carries environment IDs when tasks exist. Best-of-N supports 1–4 attempts. [CLI docs][cli] Independent parallel tasks are supported; this account’s concurrency ceiling is unknown. [Example][parallel] No cloud follow-up, transcript-export, push or PR command appears in installed help. Web follow-ups exist; running-task steering through this CLI and direct cloud branch pushes remain unverified. [Legacy][legacy]

Script explicit `--branch ideation/... --attempts 1`; collect reports as tracked Markdown diffs because list summaries are insufficient. Apply only in a clean `ideation/*` worktree; locally review, gate, commit, then let the orchestrator push an explicit `refs/heads/ideation/...` destination. Never expose push/merge/PR operations to cloud workers. Prompts alone cannot guarantee the main prohibition: require credentials/server rules denying main writes without admin bypass, and no PR-creation capability. A server-side main-PR block is unverified; enforce these restrictions before migrating builds. Existing sessions have admin rights. [Repo rules][rules]

Owner clicks:

1. Open Usage settings; inspect credit expiry and available resets, without redeeming or buying. [Credits][credits] [Resets][resets]
2. Settings → Codex Cloud → Environments → Create environment; connect GitHub and select this repository. [Cloud][cloud]
3. Get started; request the pinned Ubuntu-compatible toolchain, review setup/tests, save, Publish. New Cloud uses Install script/Start skill and published snapshots; Pro defaults are 4 vCPUs, 16 GiB RAM, 32 GiB disk, with task state recoverable for seven days. [Cloud][cloud]
4. Verify the environment appears in the CLI picker before migration: compatibility with new Cloud is unproved. Legacy settings instead use setup/maintenance scripts, `universal` containers and a 12-hour cache; setup has internet, tasks default offline. Setup exports do not persist. New Cloud’s exact image/OS and Legacy hardware are unknown. [Legacy][legacy]

For new Cloud, restrict setup/task networking using Package managers plus `maven.google.com`, `maven-central.storage-download.googleapis.com`, `docs.godotengine.org`; the preset includes GitHub release hosts, PyPI, apt, Google downloads and Gradle. [Cloud][cloud] For offline jobs, disable public/package access, clear additional domains/secrets and republish. [Network controls][network]

Draft setup, from the checked-out repository; root/sudo and Ubuntu package compatibility require validation:

```bash
set -euo pipefail
if (( EUID )); then
  sudo -n env PATH="$PATH" bash scripts/cloud-setup.sh
else
  bash scripts/cloud-setup.sh
fi
: > "$HOME/.bramble-env"
CLAUDE_CODE_REMOTE=true CLAUDE_ENV_FILE="$HOME/.bramble-env" \
  bash scripts/session-start.sh
```

Legacy maintenance reruns the hook; task briefs/new Start skill must prefix tool commands with `source ~/.bramble-env;`. Republish/rebuild when pins change. This reuses checksum verification, Godot 4.7.2, gdtoolkit 4.5.0, ruff 0.16.8, shellcheck, exports/Android and the Maven mirror; Claude’s hook otherwise does not run. [Setup][setup]

Builds can return diffs for local pushes; reviewers/designers/headless playtesters can return report diffs. Interactive computer/browser playtesting is unsupported in new Cloud. [Cloud][cloud] A 10–20-minute headless gate looks feasible, unproved; maximum cloud task/command duration is unknown. Long simulations should stay local/Actions initially. Keep Claude for message-driven persistent routines until a follow-up/report adapter exists. [Inference from CLI help; repo workflow][rules]

Probe: `codex cloud list --json` exited 0: `{"tasks":[],"cursor":null}`; plain list: `No tasks found.` Picker showed only `All Environments (Global)`. No task submitted; task cost/status unavailable. No environment/settings changes or pushes.

Trial a fourth local worker after reset: it avoids cloud setup, but neither route has proven lower token cost. Six cores do not increase quota; current scripts actually permit two Godot slots, simulations use one. [Slots][slots] Supplied figures: 37% ÷ 1.5–2.5%/h = 14.8–24.7 hours; 52 hours needs 78–130%, exceeding remaining by 41–93 points. Pace at ≤0.71%/h until 12 November 17:42 AEDT; raising concurrency accelerates exhaustion (arithmetic, supplied logs).

[pricing]: https://learn.chatgpt.com/docs/pricing
[plan]: https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan
[credits]: https://help.openai.com/en/articles/12642688-using-credits-for-flexible-usage-in-chatgpt-personal-plans
[resets]: https://help.openai.com/en/articles/20001498-how-resets-work-in-codex
[paid]: https://help.openai.com/en/articles/20001507-paid-weekly-work-and-codex-rate-limit-resets
[cli]: https://learn.chatgpt.com/docs/developer-commands
[parallel]: https://developers.openai.com/blog/codex-at-devday
[legacy]: https://learn.chatgpt.com/docs/environments/cloud-environment
[cloud]: https://learn.chatgpt.com/docs/environments/cloud-environments
[network]: https://learn.chatgpt.com/docs/enterprise/security-cookbook
[rules]: /home/alex/code/Bramble-ideation/docs/ideation/CLOUD.md
[setup]: /home/alex/code/Bramble-ideation/docs/CLOUD_SETUP.md
[slots]: /home/alex/code/Bramble-ideation/scripts/godot_slot.sh
