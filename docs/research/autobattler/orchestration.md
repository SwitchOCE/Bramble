# Autobattler: orchestration, supervision and owner corrections

Sources:
- Autobattler `docs/orchestration/*` (ORCHESTRATOR.md, WORKER.md, HANDOFF.md, dispatch-template.json) and the history of those files;
- `CLAUDE.md`, `docs/MISSION.md`, `docs/STATUS.md`, `docs/design/design-ethos.md`, `docs/design/rules-log.md`;
- the owner's memory notes for that project (`~/.claude/projects/C--Users-keech-Documents-Autobattler/memory/`);
- the five local orchestrator transcripts;
- Bramble owner notes `2026-10-27b` and `2026-11-02`.

**[V]** = verified, **[I]** = inference. Transcript times are UTC (Z); commit times are the owner's local time (+1100).

## How it ran [V]

- **Issues.** The orchestrator was a local Claude Code session in the owner's checkout. It wrote GitHub issues with Scope, Acceptance and Verification fields from `.github/ISSUE_TEMPLATE/task.yml`, and state lived in labels: `status:backlog`, `in-progress`, `review`, `changes`, `blocked`.
- **Dispatch.** Each issue got one cloud worker: a claude.ai routine created with `RemoteTrigger` from `dispatch-template.json`, with `persist_session: true`. The prompt was one line pointing at `WORKER.md`.
- **Workers.** A worker claimed the issue, branched, stayed in scope, merged main and re-imported, ran `check.sh`, took native-size screenshots, wrote decision records, opened a PR and reported on the issue. Escalation tags were `RULES CALL:`, `NEEDS OWNER:` and `DESIGN CALL:`.
- **Review and merge.** The orchestrator reviewed in its own context and merged after update-branch plus a green gate.
- **Pace.** About 213 PRs in 8 days (10–18 October). M0–M7 closed in about 36 hours, including 25 PRs merged overnight by a cloud stand-in orchestrator while the owner slept.

## What "unsupervised early" meant [V]

- **The brief.** The owner's whole brief was one paragraph. Agents wrote the MISSION, the game design doc and the M0–M9 roadmap. M8 was to "tune to… no item in >60 % of winning towers".
- **The rule for decisions.** MISSION §5 kept only business items for the owner. For everything else, agents were told to "pick a reversible default… Don't stop for it". The game-designer and balance-analyst agents set the rules and targets.
- **The 15 October audit** found agent choices all through the foundations:
  - an economy built on interest and banked rerolls (rerolls at a flat 1 gold with no limit, uncapped gold carry-over);
  - one level button bundling shop odds, slots, income and HP;
  - permanent cooldown cuts and +1 multicast, so one carry item could reach about ×27;
  - content designed per tag only ("vertical");
  - sim win rates used as tuning targets (decisions 91 and 92);
  - commit-before-reveal, which quietly answered the open async question.
- **Hidden ethos.** The ethos files were untracked, so cloud workers couldn't see them.
- **The verdict:** "almost all existing content will be redesigned".
- **The owner later** (Bramble note 2026-10-27b §2): "I was too unsupervised at the beginning… I wasn't a big fan of some of the outputs at the end". In §6 the owner names the missing bottom-up power budget as "a large issue".

## Timeline [V]

- **10 October.**
  - Bootstrap at 06:25Z.
  - At 12:48Z the owner went to bed, "moving orchestration to the cloud". The cloud orchestrator merged 25 PRs overnight and reported "Worker sessions reported they're close to the 7-day usage limit."
- **11 October.**
  - Agents designed the M8 content batches; the owner answered M8 questions only as multiple choice.
  - At 09:58Z, after playing the build, the owner paused balance work, because UI and performance were "by far the weakest".
- **12 October.**
  - 04:48Z: "I'm going to take a more active role in designing game systems".
  - In dictation, the owner called an epidemiological approach to balance "foolish".
  - 23:43Z: "I want the online workers stopped for now".
- **15 October.** "This repo was very hands off at first." The audit followed, and PR #258 made design calls owner-only.
- **17 October.** Delegation widened again:
  - content, balance and rules calls went to agents (#260, rules log R1–R17), plus merge authority and no worker cap;
  - the owner wrote "3 hours left till usage limits. Fan out agressively";
  - 15 cloud workers, 2 local Opus agents and 3 Codex workers ran at once;
  - after the owner's direction to build budgets bottom-up and to state a prediction before every test, the orchestrator still started tuning passes T1–T4 "instead of waiting for #310", the power model.
- **18 October.**
  - Cloud-only work, builds v0.8.0 and v0.8.1.
  - UI direction was spread over several sources and needed a precedence order. The owner had to ask whether the redesign document was being followed.
  - The last commit; the project stopped.
- **[I]** Two orchestrating sessions ran at once on 17 October. The owner told one: "you are a fork, do not attempt to orchestrate".

## Mechanics that failed, and the fixes [V]

| Failure | Fix | Source |
|---|---|---|
| Routines inherit the owner's claude.ai connectors (Drive, Figma, Docs); `mcp_connections: []` doesn't remove them | Documented; workers told not to use them | c656a645 |
| GitHub refuses "request changes" on PRs under the owner's own account | Review by comment with a fixed header, plus label `status:changes` | 64a79666 |
| PRs passed alone and failed together (#34) | Update-branch before merge | 64a79666 |
| Two sessions pushing to one PR (#29, #43, #165, #242) | Wait up to 20 minutes for the original worker; never run both | da536986 |
| Idle workers never saw later PR comments (#134, #91, #94, #138) | Dispatch a review-fix worker (Mode B) at once if the original is idle | fecff19c |
| …but idle workers sometimes did wake (#165, #242) | Check `last_event_at` and name which session should act | memory `worker-sessions-wake-on-pr-comments` |
| A review never woke the worker (#391, about 80 minutes) | 20-minute deadline | memory |
| Downscaled screenshots cost review rounds | Native-size PNGs (which then bloated the repo) | 0d7fc38a |
| Stale class cache after merges | Verify on the merged head after re-import | 0cb8dde4 |
| A merge broke main for 30 minutes (#294 after #275) | Ancestor check plus a symbol grep; a merge order for PRs that change goldens | memory `update-branch-before-merge` |
| Classifier refused "Merge Without Review" and "Self-Approval" | Local allow rules in `.claude/settings.local.json` | memory `merge-permission-rule` |
| Release export refused as "Production Deploy"; RemoteTrigger drops `auto_mode_allow` | One-off local build worker | memory `build-release-authorisation` |
| Messages one turn late (`update` and `run` sent in one parallel batch) | `run` only after `update` returns; check the echoed message | 79649f65 |
| Messages sent before the worker's `init` were never answered | Wait for the first `init` line in the log | 7b008add |

- **The mailbox.** A persistent routine served as a mailbox for its worker (7b008add, at the owner's suggestion): update the trigger's message, `run` it, then read the reply with `get_run_log`. Workers can't message back.
- **Pausing.** Pausing the orchestrator didn't stop cloud workers.

## Rules the owner added [V]

- Give notice before local test runs; they "stole focus" and froze the PC.
- Balance paused in favour of performance and UI.
- The owner keeps the board and progression redesigns.
- "Please don't record memories" (12 October), yet memory files were written on 17–18 October.
- Design calls owner-only (15 October), then delegated again (17 October).
- Balance principles: name the lever, measure effective health per second, predict, then test.
- Cloud-only execution, build version numbers, and headless-only tests.

## Cost [V]

- The 7-day usage warning came on night one.
- No CI from 11 October (see [toolchain.md](toolchain.md) §2.12).
- Orchestrator context:

| Session | Calls | Cache-read tokens | Avg context per call | Compactions |
|---|---|---|---|---|
| `5e7eff16` | 1,757 | 473M | ~270k | 11 |
| `6a54c044` | 1,226 | 426M | ~350k | 4 |

- **[I]** Each poll re-read that whole context. Short-lived orchestrator sessions would be cheaper.
- About 150 "status update" commits went straight to main, and `STATUS.md` reached 38 KB.

## Worth copying [V]

- **Issues and dispatch:**
  - the issue contract (Scope, Acceptance, Verification) and one-line dispatch prompts;
  - non-overlapping file scope as the limit on parallel work, with each brief naming the other workers' files;
  - one file per decision;
  - the `RULES CALL` format, and a rules log with "wrong if" triggers.
- **Safety:**
  - only the orchestrator edits STATUS;
  - worker text treated as data;
  - checks on the merged, re-imported head.
- **Tools:**
  - the persistent-routine mailbox;
  - HANDOFF.md with explicit stop conditions for a stand-in orchestrator;
  - owner decision pages built as artifacts with a database, which the owner praised.
- **Reviews** caught real bugs, as did a QA subagent before each PR.

## Suggested changes for Bramble [I]

Bramble's CLAUDE.md and the owner's global orchestration gates (plan-interrogate before plans, scope-reviewer on each step, merge only when both gates pass) already cover the general lesson. On top of those:
- Keep design calls with the owner, and don't re-widen them under time or usage pressure.
- Cap the number of merges between owner check-ins.
- Settle the CI budget before dispatching.
- Batch STATUS updates through PRs, not direct pushes to main.
- Use short-lived orchestrator sessions, with state in the repo rather than in context.
- Run one orchestrator at a time, and tell forks explicitly that they are not orchestrators.
- Make pausing a real kill switch that also stops cloud workers.
- Keep one precedence list for design sources.
- Ask the owner whether the "don't record memories" rule applies here.
