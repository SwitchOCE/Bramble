# Bot league: running it in T3 Code

**Status: proposed 18 Nov 2026. Not approved yet, apart from the Codex models (section 2), which the owner has decided.** It amends [brief.md](brief.md), which the owner approved as written. Where the two differ on how sessions are started, limited and watched, this page replaces the brief. Everything else in the brief stands: the goal, the rules for teams, the rounds, the matches, the checks, and both stops for the owner.

## 1. Why

The owner, 18 Nov 2026 (filler removed):

> "I want to run the bot balance competition overnight using T3 Code. You are in T3 Code and can see the differences in availability of tools compared to the initial setup that we have in the Bramble repo with the bridge. We are going to be migrating to T3 Code as my platform for agents regardless. So some of our rules may want to change to take advantage of the increased capabilities we have here, in terms of our options for how SSH sessions work, the linkages, all of that, and the fact that we no longer need a Codex bridge, because you can communicate natively with Codex using this app. How does this change the plans for the run, and what changes would you make to amend them?"

The brief was written for a referee in the Claude desktop app, which starts its teams as side sessions and its Codex workers through the codex-bridge. In T3 Code the referee is a thread on the Optiplex's own T3 server (`t3code.service`), so it keeps running with the owner's PC off, and the owner sees every thread in their app.

## 2. Codex models (decided)

The owner, 18 Nov 2026: "Obviously, 6.2 is an upgrade. Yeah, you should change that for both repos. It only came out today."

- Codex workers use **`gpt-6.2-sol`**. This replaces `gpt-6.1-sol` in brief section 4.
- **`gpt-6.2-astra`** takes the role `gpt-6-astra` had: extra parallel work, and the fallback when Sol's plan usage runs out. Brief section 6 stands: the pool is shared, so the referee moves both teams together.
- How the owner ranks them for coding, the same day: Fable is strongest; Astra 6.2 is "maybe a touch stronger than Opus"; Sol 6.2 is "a touch weaker". Astra is "not as good at open-ended tasks. You have to give it detailed instructions". Teams are told this. Astra stays under the rule above unless the owner says teams may choose freely (asked, not answered).

## 3. What replaces what

| Brief | In T3 Code | Checked on 18 Nov? |
|---|---|---|
| Referee: one Opus session in the desktop app (section 4) | The referee is one T3 thread in the Bramble project on the Optiplex. It is a Fable thread, not Opus as the brief says: the owner, 18 Nov 2026, to the thread that wrote this page: "You can be the referee." | It runs there now. |
| Red and blue are "side sessions" (section 4) | Each team is a T3 thread in its own T3 project, whose folder is the team's clone: `/home/alex/league/red`, `/home/alex/league/blue`. The referee starts them with `t3_thread_launch` and talks to them with `t3_thread_send`. | Yes, with a throwaway project: an Opus thread started in a new folder with no trust or approval prompt. |
| Codex workers through the codex-bridge, 5 at once (sections 4 and 6) | `delegate_task` with provider `codex`, and only that: the bridge's tools still load in a T3 thread, and two routes to Codex would make the 2-worker cap hard to count. A worker in a separate checkout uses `isolation: "worktree"`; T3 puts it in `/home/alex/.t3/worktrees/<folder name>/`, outside the clone. | Yes: a Codex child ran in the clone, and another in a T3 worktree. Whether two Codex children run at the same time: see section 5. |
| Opus sub-agents | The thread's own `Agent` tool, as before. | Yes. |
| 2-core cap by starting each team's session inside `systemd-run -p AllowedCPUs` (section 6) | T3's server starts every agent, so a thread can't be started inside a limited group. `tools/league/pin_teams.sh` runs for the whole league as a user service (`systemd-run --user --unit league-pin`), so it outlives the referee's shell. Before every practice and official match the referee checks it is running and reads its log. Every 5 seconds it puts any process whose working folder is under a team's clone or its T3 worktree folder onto that team's cores. Children inherit. It logs every change, so a process that undid its own limit shows up. | Yes for the clone: the team thread, its sub-agent and a Codex child's commands were all moved to the test cores within seconds. The T3 worktree folder wasn't in the test's list, and that child stayed on all cores; the script takes several folders per team. |
| The referee keeps the round clock (sections 7a, 11) | T3 scheduled tasks, bound to the referee's thread, fire at each practice time and each deadline. The clock is then not held in the referee's memory, and it survives a restart of the referee. | Being checked: section 5. |
| Notes come back when a side session's turn ends | The referee reads a team with `t3_thread_read`. A team reports to the referee with `t3_thread_send`. | Not yet: a team messaging the referee. |
| Clean-up of bridge worktrees (`codex_worktrees`) | `t3_worktree_list` at hand-over; remove the two team projects and their T3 worktree folders with the clones. | No. |

## 4. One new rule for teams: other threads are out of bounds

Any T3 thread can list, search and read every other thread on the server, in any project, with one tool call. The smoke test's thread saw the referee's thread in its list. So a team could read the other team's work, or the referee's.

Before T3 the same was true on disk (session transcripts sit under the same Linux user), so the brief's "a team reads nothing outside its own clone" was already on trust. T3 makes it one call.

Brief section 6 already bans getting the other team's code or notes "by any route". This spells out the routes T3 adds, because T3's own instructions encourage agents to list and read threads. Added to "Not allowed":

- using any T3 tool to list, search, read or message a thread other than the team's own children and the referee's thread; that includes `t3_thread_list` with `allProjects`, and `t3_thread_search`;
- reading T3's data (`/home/alex/.t3`, other than the team's own worktrees), Codex's session logs (`/home/alex/.codex`), or another project's folder under `/home/alex/.claude/projects`. A team's own skills, instructions and saved tool output under `/home/alex/.claude` are fine.

The check: after every match, with the diff check (section 8.2), the referee runs a scripted search of each team's tool calls for those tools and paths, in T3's thread store (`~/.t3/userdata/statev2.sqlite`) and Codex's session logs. It does not read the threads into its own context. *[The script isn't written yet.]* A hit is handled like any other cheat (section 8.4). Between checks it is on trust, and the results say so.

Not done, and why: separate Linux users or a second T3 server per team would close the hole, but would need the owner at the keyboard and a second sign-in for Claude and Codex.

## 5. Still to check before the teams start

- Two Codex children at once. All Codex threads on the server share one Codex process. **Checked, 18 Nov: they run at the same time.** Two Codex children started together each ran a 40-second command over the same 40 seconds (19:00:18–19:00:58 and 19:00:19–19:00:59). Not checked: more than two at once, or the plan's own limit on parallel work.
- A scheduled task waking the referee's thread. **Checked, 18 Nov:** a one-off task set for 19:03:00 reached the referee's thread at 19:03:06, while the thread was idle. Not checked: a task that falls due while the referee is mid-turn, or after a restart of T3's server.
- A team thread sending the referee a message, both while the referee is busy and while it is idle. *[Running.]*
- The pin script with a team's T3 worktree folder in its list. *[Running.]*
- **Not tested, and it needs the owner's OK:** what happens to every thread if `t3code.service` restarts in the night. Testing it means restarting the server under this thread and anything else running on it.
- What happens to a team's running commands when its thread is stopped (the brief pauses teams for an official match). `docs/orchestration/leftover-processes.md` found the bridge left commands running; T3 is untested.

## 6. The hand-over from the old referee

On 18 Nov at 19:00 the first referee, a desktop-app session in worktree `league-engine-463b0c`, was still working: uncommitted harness edits and a Codex worker building. Nothing is tagged. The T3 referee takes over from the tag `league-engine-v1`, once that session's final checks have passed on the frozen code and it has tagged, pushed and stopped. The owner's phase 0 stop has happened ("Yes, take all four"). Only the owner can tell it to.

## 7. Tonight, if the owner says go

Round 1 is 6 hours and match 1 with its checks is about 1 hour, so they fit one night. The brief's stop after match 1 is then the morning pack (`overnight-run` skill). Starting the teams still needs the owner's word, as the brief says.

## 8. Not changed here

- SSH and linked environments: the league runs on one machine, so nothing in it needs them.

- `docs/orchestration/ORCHESTRATOR.md` and `WORKER.md` (the cloud-worker track on `main`) still describe `RemoteTrigger` routines. T3 could replace those too. Their rules tables change only with the owner's say-so on the wording, so that is a separate proposal.
- The owner's own skills (`optiplex`, `overnight-run`) still tell agents to use the bridge for Codex worktrees. They live in the owner's `claude-setup` repository.
