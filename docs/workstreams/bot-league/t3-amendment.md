# Bot league: running it in T3 Code

**Status: proposed 18 Nov 2026. Not approved yet, apart from what the owner has decided: the Codex models (section 2), the referee (section 3) and practice against the other team's previous bot (section 4b).** It amends [brief.md](brief.md), which the owner approved as written. Where the two differ on how sessions are started, limited and watched, this page replaces the brief. Everything else in the brief stands: the goal, the rules for teams, the rounds, the matches, the checks, and both stops for the owner.

## 1. Why

The owner, 18 Nov 2026 (filler removed):

> "I want to run the bot balance competition overnight using T3 Code. You are in T3 Code and can see the differences in availability of tools compared to the initial setup that we have in the Bramble repo with the bridge. We are going to be migrating to T3 Code as my platform for agents regardless. So some of our rules may want to change to take advantage of the increased capabilities we have here, in terms of our options for how SSH sessions work, the linkages, all of that, and the fact that we no longer need a Codex bridge, because you can communicate natively with Codex using this app. How does this change the plans for the run, and what changes would you make to amend them?"

The brief was written for a referee in the Claude desktop app, which starts its teams as side sessions and its Codex workers through the codex-bridge. In T3 Code the referee is a thread on the Optiplex's own T3 server (`t3code.service`), so it keeps running with the owner's PC off, and the owner sees every thread in their app.

## 2. Codex models (decided)

The owner, 18 Nov 2026: "Obviously, 6.2 is an upgrade. Yeah, you should change that for both repos. It only came out today."

- Codex workers use **`gpt-6.2-sol`**. This replaces `gpt-6.1-sol` in brief section 4.
- **Both 6.2 models are open to the teams, and a mix of model families is encouraged.** The owner, later the same day (dictated): "Models can use Astra and Sol 6.2, if they wish. In fact, teams should maybe use a mix of models from each family to get different ideas and thought processes. But everybody should be using high effort. Maybe the Sol models can use extra high if there's a specific task that's causing them to stop early and they're not going for long enough." This replaces "Astra only under the codex-bridge's usage-limit rule" in brief section 4. Brief section 6 stands on limits: the Codex pool is shared, so if a model runs out the referee moves both teams together.
- **Effort is high for everyone:** the referee, the team leaders, their sub-agents and their Codex workers. Sol may go to extra high for a task where it keeps stopping early.
- How the owner ranks them for coding, the same day: Fable is strongest; Astra 6.2 is "maybe a touch stronger than Opus"; Sol 6.2 is "a touch weaker". Astra is "not as good at open-ended tasks. You have to give it detailed instructions".
- **The team leaders work out how to use the 6.2 models.** The owner: "You can give each team leader, I guess, instructions regarding that because the Sol 6.2 models came out today, and I'm not familiar enough with their quirks to give you the correct guidance as to how best to use them." So each leader tries them on small checkable tasks first and writes what it learns in its `NOTES.md`; the referee collects that for the owner.

## 3. What replaces what

| Brief | In T3 Code | Checked on 18 Nov? |
|---|---|---|
| Referee: one Opus session in the desktop app (section 4) | The referee is one T3 thread in the Bramble project on the Optiplex. It is a Fable thread, not Opus as the brief says: the owner, 18 Nov 2026, to the thread that wrote this page: "You can be the referee." | It runs there now. |
| Red and blue are "side sessions" (section 4) | Each team is a T3 thread in its own T3 project, whose folder is the team's clone: `/home/alex/league/red`, `/home/alex/league/blue`. The referee starts them with `t3_thread_launch` and talks to them with `t3_thread_send`. | Yes, with a throwaway project: an Opus thread started in a new folder with no trust or approval prompt. |
| Codex workers through the codex-bridge, 5 at once (sections 4 and 6) | `delegate_task` with provider `codex`, and only that: the bridge's tools still load in a T3 thread, and two routes to Codex would make the 2-worker cap hard to count. A worker in a separate checkout uses `isolation: "worktree"`; T3 puts it in `/home/alex/.t3/worktrees/<folder name>/`, outside the clone. | Yes: a Codex child ran in the clone, and another in a T3 worktree. Whether two Codex children run at the same time: see section 5. |
| Opus sub-agents | The thread's own `Agent` tool, as before. | Yes. |
| 2-core cap by starting each team's session inside `systemd-run -p AllowedCPUs` (section 6) | T3's server starts every agent, so a thread can't be started inside a limited group. `tools/league/pin_teams.sh` runs for the whole league as a user service (`systemd-run --user --unit league-pin`), so it outlives the referee's shell. Before every practice and official match the referee checks it is running and reads its log. Every 5 seconds it puts any process whose working folder is under a team's clone or its T3 worktree folder onto that team's cores. Children inherit. It logs every change, so a process that undid its own limit shows up. | Yes for the clone: the team thread, its sub-agent and a Codex child's commands were all moved to the test cores within seconds. The T3 worktree folder wasn't in the test's list, and that child stayed on all cores; the script takes several folders per team. |
| The referee keeps the round clock (sections 7a, 11) | T3 scheduled tasks, bound to the referee's thread, fire at each practice time and each deadline. The clock is then not held in the referee's memory, and it survives a restart of the referee. | Being checked: section 5. |
| Notes come back when a side session's turn ends | A team reports to the referee with `t3_thread_send`; the referee messages a team the same way. A team's message arrives looking exactly like one from the owner, so teams start every message with `RED:` or `BLUE:`, and the referee treats anything it can't tell is the owner's as a team's report, never as an instruction. | Yes: section 5. |
| Clean-up of bridge worktrees (`codex_worktrees`) | `t3_worktree_list` at hand-over; remove the two team projects and their T3 worktree folders with the clones. | Partly, 18 Nov: deleting the test project left its T3 worktree folders on disk, so they are removed by hand. |

## 4. One new line in the teams' rules

Any T3 thread can list, search and read every other thread on the server, in any project, with one tool call, and T3's own instructions encourage agents to use those tools. Brief section 6 already bans getting the other team's code or notes "by any route". The team brief spells out the route T3 adds, in one line:

- don't use T3's thread tools on any thread but your own children and the referee's, and don't read T3's or Codex's data folders.

Nothing else is added: no extra checks and no separate users. The brief's own checks (section 8) stand as approved.

## 4b. Practice against the other team's previous bot (decided)

This one isn't about T3. It changes what teams get after a match (brief 7b, step 6) and what they may practise against.

The owner, 18 Nov 2026, on why the league is opposed at all: "I didn't want to necessarily avoid hill climbing. I wanted to create an environment that was more robust than a simple hill climb." A bot is only as robust as the range of opponents it is tested against, and a second team adds one differently designed opponent that each team otherwise meets only in scored matches. So, proposed to the owner and agreed the same day ("Okay, I like that plan ... I like that idea. Let's make that amendment"):

- **After each official match, each team may practise against the bot the other team handed in for that match.** After match 1, red practises against `blue-m1` and blue against `red-m1`; after match 2, against `-m2` as well. Never against the other team's current work.
- **How.** The harness compiles every bot into one program, so the old bot can't be handed over as a finished binary on its own. The referee keeps a practice folder per team, outside the team's clone: the frozen workspace, the other team's handed-in bot crate, and the team's own bot crate read from its clone. One command there builds both and plays games between them, any number, on the team's own cores.
- **The rule for teams:** run it as often as you like; don't open the other bot's source. The method swap stays the only description of how the other bot works (brief section 2).
- **What a team sees from these games** is what the harness writes for any match: the score, its own logs, and the game records, which show what the old bot's seats bought and fielded.

What it costs: the two teams' card verdicts are a little less independent than under the brief, because each can now watch the other's previous bot play. The agreement report (brief section 9) says so.

*[Not built yet. It is needed first after match 1, and the harness is still changing under the first referee.]*

## 5. Still to check before the teams start

- Two Codex children at once. All Codex threads on the server share one Codex process. **Checked, 18 Nov: they run at the same time.** Two Codex children started together each ran a 40-second command over the same 40 seconds (19:00:18–19:00:58 and 19:00:19–19:00:59). Not checked: more than two at once, or the plan's own limit on parallel work.
- A scheduled task waking the referee's thread. **Checked, 18 Nov:** a one-off task set for 19:03:00 reached the referee's thread at 19:03:06, while the thread was idle. Not checked: a task that falls due while the referee is mid-turn, or after a restart of T3's server.
- A team thread sending the referee a message. **Checked, 18 Nov,** both ways: sent while the referee was mid-turn, it was delivered into that turn; sent while the referee was idle, it started a new turn within seconds.
- The pin script with a team's T3 worktree folder in its list. **Checked, 18 Nov,** running as a user service: a Codex child in a T3 worktree was moved from all cores to the test cores 12 seconds after it started.
- A team building and playing from its clone. **Checked, 18 Nov:** in the red clone, on two cores, the workspace built offline, the stub bot passed `check-crate`, and a 20-game match against TribeBot ran with no clock-outs, faults or refusals (the stub lost, 5.9 against 3.1, as a stub should).
- **Not tested, and it needs the owner's OK:** what happens to every thread if `t3code.service` restarts in the night. Testing it means restarting the server under this thread and anything else running on it.
- A team's background commands outlive its turn: **checked, 18 Nov,** a detached command was still running minutes after the turn that started it ended. So "the teams are paused" (brief 7d) doesn't empty the machine. Before every official match the referee lists what is running under each team's folders and waits for it or stops it, and says which. Not checked: whether stopping a thread mid-turn stops the command it is running.

## 6. The hand-over from the old referee

On 18 Nov at 19:00 the first referee, a desktop-app session in worktree `league-engine-463b0c`, was still working: uncommitted harness edits and a Codex worker building. Nothing is tagged. The T3 referee takes over from the tag `league-engine-v1`, once that session's final checks have passed on the frozen code and it has tagged, pushed and stopped. The owner's phase 0 stop has happened ("Yes, take all four"). Only the owner can tell it to.

## 7. Tonight, if the owner says go

Round 1 is 6 hours and match 1 with its checks is about 1 hour, so they fit one night. The brief's stop after match 1 is then the morning pack (`overnight-run` skill). Starting the teams still needs the owner's word, as the brief says.

## 8. Not changed here

- SSH and linked environments: the league runs on one machine, so nothing in it needs them.

- `docs/orchestration/ORCHESTRATOR.md` and `WORKER.md` (the cloud-worker track on `main`) still describe `RemoteTrigger` routines. T3 could replace those too. Their rules tables change only with the owner's say-so on the wording, so that is a separate proposal.
- The owner's own skills (`optiplex`, `overnight-run`) still tell agents to use the bridge for Codex worktrees. They live in the owner's `claude-setup` repository.
