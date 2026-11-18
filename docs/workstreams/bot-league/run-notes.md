# Bot league: referee's run notes

The referee keeps these so the owner or a later session can see where the league stands without
asking. Newest status first. The plan is [brief.md](brief.md) (approved 18 Nov 2026).

## Status

Phase 0 started 18 Nov 2026, about 14:15. **At the owner stop** (18 Nov, about 17:45): the port
matches GDScript on every check, the harness passes its gates, and the hand-over is
[phase0-handover.md](phase0-handover.md). The owner answered on 18 Nov: "Yes, take all four"
(1 s clock, shuffled seats, TribeBot by seat, team folders). All four are built, reviewed and
recorded in the brief. Then, at the owner's ask, three harness fixes and a fuller data layer
(schema 1); all checks pass on it (18 Nov, about 20:30). The owner answered scope review 4 on 18 Nov: "Yes, all three" (keep the
match labels; build the analysis before match 1's results are read; team tools log decisions by
default). **Frozen** and tagged **`league-engine-v1`** on the commit that records this. The teams
are not started (that needs the owner's word).

## The T3 referee (from 18 Nov, about 19:30)

The league moved to T3 Code on the Optiplex: [t3-amendment.md](t3-amendment.md). The referee is the T3 thread "Migrate Competition Runs to T3 Code" in the Bramble project (id `40aad95e-3f40-4626-b060-7a670caf6ac4`), a Fable thread, by the owner's word ("You can be the referee").

**Ready at 19:48:** team clones `/home/alex/league/red` and `/blue` (branches `league/red`, `league/blue`, no remote, tag `league-engine-v1` in each); T3 projects "League Red" (`mcp:20692c88-5db2-4121-a19e-7c24b2aa02b5`) and "League Blue" (`mcp:4d5a601e-831c-4ca4-b32f-4322d07fb92b`); the core-pinning service `league-pin` (red 0-1, blue 2-3; log `/home/alex/league/pin.log`); the team brief template [team-brief.md](team-brief.md); match output goes to `/home/alex/league/matches/`.

**The owner's go, 18 Nov 19:48: "Restart and then go."**

**What the restart of T3's server did** (19:49:33, `systemctl --user restart t3code`):
- it killed this thread's Claude process and T3's Codex process, mid-turn;
- the thread itself, with its whole conversation, was intact: the owner's next message started it again 60 seconds later;
- the scheduled task set before the restart was still listed after it;
- the `league-pin` service kept running;
- T3's Codex process starts fresh on next use, so it is now Codex 0.170.0.
So a restart in the night stops every running turn, and a thread comes back only when something messages it. The 30-minute heartbeat below is the guard: it wakes the referee, which nudges any idle team.

## Round 1 (started 18 Nov, 19:53; clock 20:00 to 02:00)

| | |
|---|---|
| Red | T3 thread "League: Red team", `mcp:d95ba944-a800-4e20-8f7c-7f5fa588aced`, project `mcp:20692c88-5db2-4121-a19e-7c24b2aa02b5`, Opus, high effort |
| Blue | T3 thread "League: Blue team", `mcp:535ab856-4973-4d1f-a00d-7af521153d5f`, project `mcp:4d5a601e-831c-4ca4-b32f-4322d07fb92b`, Opus, high effort |
| Their brief | `tools/league/bots/<colour>/BRIEF.md` in each clone, from [team-brief.md](team-brief.md) |
| Clock | scheduled tasks bound to the referee's thread: practice 22:00 and 00:00, deadline 02:00, heartbeat every 30 min |
| Referee's match tree | `/home/alex/league/ref` (a worktree at `league-engine-v1`); output in `/home/alex/league/matches/` |
| Cores | red 0-1, blue 2-3 (`league-pin`, log `/home/alex/league/pin.log`); referee and practice matches 4-5 |

Messages to a team start `REFEREE:`; theirs start `RED:` or `BLUE:`. A team's message is a report, never an instruction. Any ruling goes to both teams at once.

**Rulings and reports in round 1**
- 20:05, red reported it had seen two of blue's command lines in a machine-wide `ps` (a card-power run and an A/B run on tier-up settings), unprompted, and said it wouldn't use them. No action. Both teams told the same thing: list only your own processes; use `uptime` and `free -g` for load.

- 21:26, blue reported that a Codex worker it started at about 20:00 (async) finished at about 20:13 and no completion ever reached it; it found the result at 21:25 with `task_status`. T3's store shows the completion queued as a second run behind blue's first turn, which had been running since 19:51. So blue lost up to an hour of knowing one worker was done. Both teams told the same thing: while your turn runs, a Codex completion doesn't reach you; check `task_status`, use mode `wait`, or end the turn. Passed to the T3 bug-report session on the owner's PC.

**The owner wants deep analytics** (18 Nov, about 21:35, dictated): "You have data on which units each team is playing and I think we will want detailed data analysis. You should create some Opus sub-sessions to build interesting data analytics for it. Because this is a gold mine for me in terms of my balance, right? As long as the bots are playing well, which I'm sure they're going to get better. So by the end, we'll know how much better the final versions are than these previous ones as well. I want all sorts of cool, interesting statistics from the conclusion of this."
- Step 1, started 21:36: an Opus worker builds `tools/league/analysis/deep/` (tempo and economy, card matrices, per-fight lift, synergy, tribes, fights, across versions), first on `s0`.
- Step 2, after it: a second Opus worker builds a page with charts on its JSON, in the owner's house style, to publish for the owner.
- Each step gets the runtime check and a scope review with the words above.
- The scope review's three questions on the section 9 scripts, and the owner's answer (18 Nov, about 21:45): "All its recommendations are, of course, excellent, and yeah, I wouldn't have changed anything." So:
  1. "Bought whatever the tribe" is judged per round band, with at least 30 buyable shops per final tribe, and the band-by-tribe table is printed. The brief's all-rounds rule (section 9) is shown beside it.
  2. Lift is measured per fight (the card on the board against that fight's result, within tribe and round), as the balance pass did. The final-board lift stays beside it.
  3. The three stand-in behaviour numbers (Glutton and Gorger eats, growth per Sergeant, sales on purpose) are accepted and labelled as stand-ins. The frozen harness gets no new log fields.

**Scope review 2 of the analytics (22:15), and a correction owed to the owner.** The reviewer kept the band verdicts and the events tool (it confirmed nothing the bots play against changed) and found four deep-analytics headlines that would mislead: 4 cuts, 3 simplifies, 6 asks. All but one are fixes, sent back to the three workers at 22:20. **The referee had already told the owner two of the misleading readings at about 21:57:** that blue's slow levelling "places very reliably and wins rarely" (blue in fact wins 57.5% of lobbies, 115 of 200; its seats share one first place), and tribe and card standouts taken from pooled numbers. The morning pack must lead with that correction.
- 22:40, the fixes are in (commits `2a7770ba`, `70dfde2d`, `702eb3c1`; 45 tests pass). The analytics worker corrected the reviewer on one point, and it is right: 25% is the proper yardstick per top-four finish. So the reading for the owner has two halves, both true on `s0`: **blue wins more lobbies (115 of 200), and blue turns fewer of its top fours into wins than chance would (115 against 152.75 expected; red 85 against 47.25).** Whether that is the discount plan or the rest of blue's bot can't be told from two bots that never vary their timing.
- Still to do tonight, by the referee: play a TribeBot against TribeBot match of 1,000 games on the frozen harness for the naive column (`/home/alex/league/matches/naive-aa`) and run every analysis on it; rebuild the page on `m1` with `--naive` and `--earlier s0 s1 s2`; publish it; push the analysis commits after a last look.
- One question is the owner's: is the replay tool the fix for the missing eat events, or should the harness still log eats at the next engine release?
- If an engine release is ever cut, cut it from the tag plus the fix, never from this branch: the branch now carries analysis code and a new workspace member.

**Scores in round 1** (practice, not counted)

| Match | Tags | Games | Red | Blue | Red − blue | Win-weighted (higher is better) | Notes |
|---|---|---|---|---|---|---|---|
| s0, 21:16 (an early look the owner asked for) | red-s0 `5cb04e21`, blue-s0 `158dc7e8` | 200 | 5.726 ± 0.093 | 3.274 ± 0.093 | +2.453 ± 0.185 | red 3.38, blue 5.87 | no clock-outs, panics, faults or refusals; 3.4 s a game on 2 cores; red: 11% firsts, 24% top four; blue: 14% firsts, 76% top four |
| s1, 22:00 | red-s1 `3c0ba6f8`, blue-s1 `89e03cac` | 1,000 | 5.898 ± 0.037 | 3.102 ± 0.037 | +2.796 ± 0.074 | red 3.16, blue 6.09 | no clock-outs, panics, faults or refusals; 3.1 s a game on 2 cores; blue wins 784 of 1,000 lobbies; red: 5.4% firsts, 21% top four, 47% in the bottom two |
| s2, 00:04 | red-s2 `8af74dbf`, blue-s2 `bf8c3317` | 1,000 | 5.490 ± 0.041 | 3.510 ± 0.041 | +1.980 ± 0.082 | red 3.55, blue 5.70 | no clock-outs, panics, faults or refusals; 2.9 s a game on 2 cores; blue wins 836 of 1,000 lobbies; red: 4.1% firsts, 30% top four, 37% in the bottom two; blue: 13% in the bottom two (3% in s1) |

- 21:54, **red reported a breach.** One of its Claude sub-agents, asked to find broken strategies in the card pool, read the referee's practice output `/home/alex/league/matches/s0/` unasked, which holds blue's seats, and wrote red a summary of blue's method (tier curve, triples and pairs, spell use, main tribe, late-game gold) with three scripts and notes in `out/broken/` (files dated 21:34 to 21:36). Red's lead read the summary, stopped that line of work, and says `red-s1` (commit 21:54) has none of it; the referee has not checked that against red's code. **The cause is the referee's:** the team brief didn't forbid the match folder, though the first referee's list said to keep match output away from the teams. **Ruling, to both teams at 21:55:** no penalty; red doesn't adopt or counter what the summary described; the folder was moved by the referee to `/home/alex/league/held/red-broken-2136`; from now on nothing under `/home/alex/league/` but a team's own clone may be read by a team or its helpers. Blue was told what happened, without detail. For the results: red's lead has seen blue's hour-old method, so the two teams' reads are a little less independent than planned.

- 21:58, the owner, on red's report (dictated): "Tell red that anything that was already on the path of discovering itself, it's fair game ... I don't want it to become a weaker opponent and not prove good opposition for blue if it gets stuck." The ruling was loosened to that, and blue was told. The folder rule stands.
- 21:58, the owner, for both teams: "This is a friendly competition. Okay, I want to repeat that. Both competitors are trying to succeed, but only because it's the good of the project ... there's no prizes or anything. It's just pride. And everyone's done a great job just by participating at all." Sent to both teams.
- 21:58 to 22:00, an extra core for the team behind after each practice match: the owner suggested it, the referee told both teams, and the owner withdrew it two minutes later ("That's going to encourage losing"). Both teams were told it is withdrawn. Cores stay 2 each.

**Match 1 hand-ins, captured by the referee at 02:00:08 on 19 Nov:**
- `red-m1` = `ec6aff2827448e8feb50e0e79a0fb7c2694969ee`, committed 01:27:30; diff from `league-engine-v1`: 15 files, all under `tools/league/bots/red/`.
- `blue-m1` = `ff4ee0324669bcf85f9bf9b80435bbfe31ca29ab`, committed 00:48:42; diff: 35 files, all under `tools/league/bots/blue/`.
- Both on time. At 02:00 nothing was running under either team's folders except red's idle session. Both teams were told the round is over at 02:01.

**Match 1, a fault in the referee's script, caught at the smoke run (02:02).** The first smoke run read red 2.500 ± 0.000, blue 6.500 ± 0.000: red's four seats first to fourth in all 20 games. The cause: cargo rebuilds by file time, and a hand-in unpacked with `git archive` carries its commit time. Blue's hand-in (00:48) was older than the referee's dry run of the match script at 01:08, which had left the stub bots built in the match tree, so cargo skipped blue and **the stub bot played as blue.** Fix (`official_match.sh`, `practice_match.sh`): `cargo clean -p red -p blue` before every build, and the official script refuses to go on unless the build log shows both crates compiled. The bad run is kept in `/home/alex/league/matches/void/`. Second smoke run, 02:03: red 4.875, blue 4.125 (± 0.545), no clock-outs, panics, faults or refusals.
- Were the practice matches affected? No, on two kinds of evidence. Order of times: each practice tag was committed after the previous build in the match tree (s0 tags 21:11 and 21:12 after the 19:55 build; s1 tags 21:54 and 21:49 after 21:16; s2 tags 23:47 and 23:59 after 22:00). Behaviour: in `s2` every blue seat reaches tier 2 in round 3, the one change blue made when it moved its tag at 23:59, and red's tier-2 round moved from 2 (s0, s1) to 3 or 4 (s2).
- What nothing would have seen: had blue's stale build been a plausible older bot instead of the stub, the score would have looked believable. The forced rebuild closes that; nothing in the harness records which source a match's bots were built from. Worth a field in `summary.json` at the next engine release (a hash of each bot's source).

**Match 1, the counted run (02:04 to 02:23, 19 Nov); the checks are below:**

| | Red (`ec6aff28`) | Blue (`ff4ee032`) | Red − blue |
|---|---|---|---|
| Average placement, lower is better (decides) | 4.715 ± 0.047 | 4.285 ± 0.047 | +0.430 ± 0.095: blue wins |
| Win-weighted, higher is better | 4.388 | 4.862 | −0.475 ± 0.103 |
| Lobbies won | 410 | 590 | |
| Top four | 45% | 55% | |

1,000 games, 500 seed pairs, 5 threads, 1.15 s a game. No clock-outs, panics, faults or refusals; no game at the round limit; no draws. Red closed from +1.98 in `s2` two hours earlier; the ladder (red-m1 against red-s2, blue-m1 against blue-s2) is the check that this is red's improvement and not a build fault.

**Match 1 checks (19 Nov):**
- Replay in the GDScript engine, 02:23 to 02:36: **1,000 of 1,000 records matched** (`replay_match.sh`, 5 jobs, 750 s). No port bug in any counted game. The replay's output was read by the referee and not saved, so this line is the only record of it; save the log next time (`replay_match.sh ... > <match>/replay.log`).
- Replay in the Rust engine by the events tool: 47,989 state hashes verified; 294 final-board Gorgers reconciled exactly.
- Diffs, crate checks and the forced rebuild: in `official_match.sh load` (both pass; both bot crates recompiled).
- Both bots read in full by an Opus reader for the referee (`/home/alex/league/held/m1/rules-check.md`): **both clean.** One thing recorded, not chased: red's slower levelling curve was committed at 22:55, after its sub-agent's 21:35 summary of blue; red says the test was queued at 21:09. The owner's ruling makes it fair game either way.
- Method descriptions drafted and read by the referee: `/home/alex/league/held/m1/method-red.md`, `method-blue.md`. Held, with each team's own view (`/home/alex/league/matches/m1/teams/<colour>`), until the owner starts round 2.
- The page: `/home/alex/league/matches/m1/page.html`, published privately for the owner at https://claude.ai/artifact/G2bDsLrzjHQtDJxNWURdn4 (the referee read its whole text first).

**Version ladder (19 Nov, 02:50 to 03:17):** `ladder.sh`, 200 games a pairing (100 seed pairs), each hand-in against its own earlier tags and against TribeBot. Output in `/home/alex/league/matches/ladder-<A>-vs-<B>/`. The gap is the hand-in's average placement minus the other's, so negative means the hand-in is better.

| Hand-in | Against | Gap, places | Win-weighted gap |
|---|---|---|---|
| red-m1 | red-s0 (21:16) | −3.717 ± 0.077 | +3.953 |
| red-m1 | red-s1 (22:00) | −3.647 ± 0.088 | +3.868 |
| red-m1 | red-s2 (00:04) | −1.825 ± 0.193 | +1.970 |
| red-m1 | TribeBot | −3.942 ± 0.033 (2.529 against 6.471) | +4.190 |
| blue-m1 | blue-s0 | −3.007 ± 0.139 | +3.248 |
| blue-m1 | blue-s1 | −2.675 ± 0.160 | +2.853 |
| blue-m1 | blue-s2 | −0.052 ± 0.155 | +0.052 |
| blue-m1 | TribeBot | −3.967 ± 0.019 (2.516 against 6.484) | +4.218 |

What it shows: red's late gain is real (its hand-in beats its own midnight version by 1.8 places), so the closing of the gap from +1.98 in `s2` to +0.43 in match 1 is red's improvement and not a build fault. Blue's hand-in is level with its midnight version, as expected: after `s2` blue changed only its `NOTES.md` (its last bot change is the 23:59 commit), so blue-m1 and blue-s2 are the same bot. Both hand-ins take the top four seats against TribeBot in almost every game (4.0 is the largest gap possible). A ladder gap is one team's eight seats split four and four between two of its own versions; it measures progress, and it is not comparable with a red-against-blue score.

**Scope review 3 (19 Nov, about 03:21 to 03:33), on the commits since scope review 2.** Full report: `/home/alex/league/held/m1/scope-review-3.md`. It recomputed every number above from the match files and all match; the frozen engine, API and harness are untouched. Keep 11, cut 1, simplify 4, ask 2. Not merged or pushed: the cut and ask items go to the owner.
- Fixed at once: the two small errors in these notes (the ladder's start time, a stale heading); `analyse_match.sh` now stops when the events replay fails (the failure was lost in a pipe).
- Being fixed on the page (an Opus worker): three statements led by pooled numbers (the "seat effect" is red's bot alone: red +0.46, blue +0.01; the "sold at once" and "kept or dropped" tiles), and the stamps on findings 9 and 10, which can't be judged from this match.
- For the owner: the cut (first-version deep tables kept "for compatibility" and their fallbacks), the simplify items, and the two asks (whether these notes may reach the teams' clones before the league ends; whether the page should stamp verdicts at all).
- Gaps it listed, open: `practice_match.sh` and `ladder.sh` don't check the rebuild happened; `official_match.sh` falls back to FlowBot where brief section 6 says the previous hand-in from match 2 on (**fix before match 2**); no test makes a Gorger fail to reconcile; the page generator has no test.
- Brief 7c asks for each hand-in against each earlier tag of **both** teams. The cross-team pairings (six, 200 games each) ran 03:34 to 04:27 on the referee's cores (`/home/alex/league/matches/ladder-cross.log`):

| Hand-in | Against | Gap, places (negative = hand-in better) | Win-weighted gap |
|---|---|---|---|
| red-m1 | blue-s0 | −2.735 ± 0.153 | +2.975 |
| red-m1 | blue-s1 | −2.365 ± 0.174 | +2.538 |
| red-m1 | blue-s2 | +0.333 ± 0.249 | −0.398 |
| blue-m1 | red-s0 | −3.810 ± 0.053 | +4.060 |
| blue-m1 | red-s1 | −3.710 ± 0.083 | +3.945 |
| blue-m1 | red-s2 | −1.978 ± 0.215 | +2.130 |

  They agree with the matches already played: red-m1 against blue-s2 (the bot blue handed in) gives blue +0.33, beside match 1's +0.43; blue-m1 against red-s2 gives 1.98, the same as practice match `s2`. Red's hand-in beats blue's 21:16 and 22:00 versions by about 2.5 places: by 02:00 red had passed where blue stood at 22:00, and blue's midnight version is what keeps it ahead.
- The page was rebuilt with the review's fixes and all fourteen ladder pairings (`12088c2e`; the build command now ends `--ladder /home/alex/league/matches/ladder-* --out ...`) and republished at the same link at 04:28. The referee looked at the findings and ladder sections in a headless browser; the rest of the changed text was read from the diff and from the worker's run of the page's script.

**For the owner at the stop (brief 7b.7):**
- Tribe share of final boards in match 1: Locust 49.7%, Pigeon 30.9%, Briar 7.7%, Mouse 7.5%, **Badger 4.2%** (332 of 8,000, all red's). Badgers are under the 5% line, so finding 7 can't be judged; the unscored Badger probe is offered, and built only on the owner's yes.
- A possible game bug, from red's notes, not checked in the Rust port or the game: Twice-shed Veteran's script doesn't check that the returning unit is "another" unit. Neither bot uses it. Brief section 6: logged here for the owner; if it is a bug, the ruling is the same for both teams.

**Practice against the other team's previous bot (amendment 4b), built 19 Nov, ready for round 2.** `tools/league/practice_setup.sh <team> <other team's tag>` makes `/home/alex/league/practice-<team>`: a tree at `league-engine-v1` with the other team's hand-in built in under its tag name and the team's own bot linked live from its clone. The team runs `/home/alex/league/practice-<team>/play.sh <other-tag> <games> <out-dir>`; it rebuilds the team's bot every time (forced), plays on the team's two cores, and writes only inside the team's clone. Set up for both teams against `blue-m1` and `red-m1`.
- Checked by the referee at 04:29: 40 games each way ran clean in 135 s including the build (2.84 s a game on two cores, so 200 games is about 10 minutes); both builds show the team's crate compiling; it refuses an output folder outside the clone, an existing one, and an unknown opponent; the frozen engine, API and harness in both trees are unchanged; the check's output folders are deleted and both clones are clean.
- In the practice output the team's live bot is always "red" and the other team's old bot "blue", whatever the team's colour. `play.sh` and the folder's README say so.
- The Codex worker that wrote it stopped at 03:22 on an approval prompt for its check command (it contained `rm -rf`), in a full-access thread; a parent thread can't answer an approval, so it sat until the referee looked at 04:28, cancelled it and ran the checks itself. Its completion would never have arrived.

**To start round 2 (only on the owner's go):**
1. `official_match.sh`: make the fallback the team's previous hand-in, not FlowBot (brief section 6).
2. Fill `team-brief.md` for round 2: four hours, one practice match at halfway, the new deadline; add the practice command above and "run it, don't open `bots/<other-tag>/`"; commit the filled copy in each clone as before.
3. Send each team, as one message: the match 1 score (both scores); its own view (`/home/alex/league/matches/m1/teams/<colour>`, copied into its clone); the tribe-level pooled numbers; both method summaries (`/home/alex/league/held/m1/method-red.md`, `method-blue.md`); the practice command; the round's times.
4. Schedule the practice match and the deadline as before; check `league-pin` is still running (`systemctl --user is-active league-pin`).

### Practice match (`n` = 1 at 22:00, 2 at 00:00)

1. Send both teams: "REFEREE: practice match n. Tag your latest working commit `<colour>-s<n>` now and carry on; I fetch in 5 minutes. Score only, it doesn't count."
2. For each colour, in `/home/alex/league/ref/tools/league` (PATH needs `~/.cargo/bin`): check the tag exists and `git -C /home/alex/league/<c> diff --name-only league-engine-v1 <c>-s<n>` lists only `tools/league/bots/<c>/`; then load it as README "For a match" says:
   `find bots/<c> -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +` and
   `git -C /home/alex/league/<c> archive <c>-s<n> tools/league/bots/<c> | tar -x -C /home/alex/league/ref --exclude='tools/league/bots/<c>/tools'`; then `target/release/league check-crate bots/<c> --name <c>`.
   No tag, a bad diff or a failed check: that team plays the practice with `flow`, and both teams are told why.
3. Build on the referee's cores: `taskset -c 4,5 env CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p league`.
4. Fresh seeds, 500 lines: `python3 -c "import secrets; print('\n'.join(str(secrets.randbelow(2**31)) for _ in range(500)))" > /home/alex/league/matches/s<n>.seeds`.
5. In the background with a 90-minute limit: `taskset -c 4,5 target/release/league match --red red --blue blue --games 1000 --seeds /home/alex/league/matches/s<n>.seeds --clock-ms 1000 --threads 2 --out /home/alex/league/matches/s<n> --red-label red-s<n> --blue-label blue-s<n>`, then `league analyze` on it.
6. Send both teams only the score line: each team's average placement and the gap, with intervals, plus clock-outs, panics and faults per team (a team needs to know its bot crashed).
7. Log the score here.

### Official match (after 02:00)

Brief section 7b. All commands run from the worktree `/home/alex/code/Bramble/.claude/worktrees/league-t3-amend`; long ones in the background with a time limit.
1. **At 02:00 exactly, capture the hand-ins:** `R=$(git -C /home/alex/league/red rev-parse -q --verify red-m1^{commit} || echo none)`, the same for blue, and write both into these notes. From here the commit ids are the hand-in; a tag moved later changes nothing. A commit made after 02:00:00 (`git log -1 --format=%ci`) is late: that team plays as FlowBot.
2. Send both teams: "REFEREE: round 1 is over. Stop work, stop your background commands and end your turn. Match 1 runs now; results come with the start of round 2." Then list what still runs under `/home/alex/league/red`, `/blue` and `~/.t3/worktrees/{red,blue}` by working folder; give it two minutes, stop what is left, and say which.
3. `tools/league/official_match.sh m1 $R $B load` (diff check, crate check, build), then `... smoke` (20 games; a crash or fault in a bot: tell that team, 30 minutes to fix only that, the other team told the same), then `... counted` (1,000 games, fresh seeds, 5 threads, into `/home/alex/league/matches/m1`).
4. **Checks (brief section 8):** `tools/league/proof/replay_match.sh /home/alex/league/matches/m1 5` replays every game in the GDScript engine (any mismatch is a port bug: stop, fix, replay the match); the diff and crate checks are in `load`; harness health is in the `counted` output; the referee reads both bots and both `NOTES.md` in full.
5. `tools/league/analyse_match.sh /home/alex/league/matches/m1 /home/alex/league/matches/naive-aa --teams` (events, section 9, deep, each team's own view in `m1/teams/<colour>`).
6. Strength: `tools/league/ladder.sh` with every tag of both teams, each team's hand-in against every earlier tag of both teams and against `tribe`, 200 games each (brief 7c).
7. The page: `python3 tools/league/analysis/page/build.py /home/alex/league/matches/m1 --naive /home/alex/league/matches/naive-aa --earlier /home/alex/league/matches/s0 /home/alex/league/matches/s1 /home/alex/league/matches/s2 --ladder /home/alex/league/matches/ladder-* --out /home/alex/league/matches/m1/page.html`, look at it, publish it as an Artifact (load `artifact-design` and `house-style` first).
8. Method summaries (150 to 300 words a team: the kind of bot, how it picks and commits to a tribe, its early game; no numbers, weights, tables or code). Hold them and each team's `teams/<colour>` export until the owner starts round 2.
9. The morning pack (`overnight-run` skill): the correction about blue's wins first; try-this; the calls made without the owner; what nothing could see; done and verified; questions. Then delete the heartbeat task and stop for the owner.

## Round 2 (started 19 Nov, 06:02; hand-in 10:15)

The owner, 19 Nov, 06:00, from their phone (the thread record shows `user` / `mobile`), after the morning pack: "is there a reason we stopped off the match? One, can we go to match two please? I would really like to see how we progress, because it feels like the bots are still getting better." *[Dictated: "match toad" is match two.]* The stop after match 1 is the plan's (brief 7b.7); from here the plan says not to wait: after matches 2 and 3 the owner gets the score in one line (brief 7b.8).

| | Time (AEDT, 19 Nov) |
|---|---|
| Both teams messaged; round 2 brief (`ROUND2.md`) committed in each clone; own match 1 view copied to `out/m1/` | 06:02 |
| Practice match `s3` (1,000 games, tags `red-s3` / `blue-s3`) | 08:15 |
| Hand-in `red-m2` / `blue-m2` | 10:15 |
| Round 3 | starts when match 2's checks and hand-outs are done, about 11:30; four hours; practice match at halfway |

- The round brief is a template, `team-brief-round.md`, filled per team. Teams got: the score and interval (average placement only; the win-weighted score stays with the owner, who said the teams "probably don't need to be notified"), their own view, tribe share and placement pooled, both method summaries, and the practice command.
- `official_match.sh` now plays a team's previous hand-in when its hand-in is missing, outside its folder or fails `check-crate` (`RED_FALLBACK` / `BLUE_FALLBACK`, commit ids), and FlowBot only when there is none. `practice_match.sh` does the same for a missing tag with `FALLBACK_LABEL=m1`.

**Ruling, 06:16: the old bot's report rows in practice output are off limits.** Red asked at about 06:10: `reports.jsonl` from `play.sh` held blue-m1's own `report` rows, its value for every card in each shop; red's analyst had seen them, and red was treating them as off limits until ruled. The referee's miss: amendment 4b says a team sees "the score, its own logs, and the game records", and the practice command handed over everything the harness writes. Ruled the same for both teams: the old bot's report rows may not be used (they are the other team's numbers, which brief 7b.5 keeps out of the method swap); what its seats were offered, bought, sold and fielded stays allowed; nothing held against either team. `play.sh` now drops those rows at the end of each run (`practice_setup.sh` and both practice folders patched); both teams were told to remove them from output they already had and to undo and note anything set from them. Blue answered at 06:18: rows removed, it had never opened `reports.jsonl`, and it had used only `games.jsonl` and the score.

**Owner's allowance, 19 Nov, about 06:35: frontier-model reviews.** The owner: "Tell both teams they can have a small bounded review from an Astra reviewer and a Fable reviewer at some stage. If they wish to use a frontier capability model, they're struggling to find performance gains." Sent to both teams the same minute as: one `gpt-6.2-astra` review and one Fable review per team for the rest of the league, optional, at a time the team chooses; one bounded question each; advice only; may run beside the usual caps (*[the referee's reading of "can have"; not the owner's words]*); every team rule binds them; logged in `NOTES.md`. Carried into the round 3 brief. Use: blue's Fable review started 06:33 (where blue loses placement against red-m1; read-only on its own folder and output; briefed with every rule).

**Blue's slip, 07:13, self-reported.** Blue ran `pgrep -af "prun.sh|play.sh"` without a folder filter and saw red's practice command line (against blue-m1, 200 games, output `/home/alex/league/red/out/pr/sell`). Ruled: accidental, not used, no breach, nothing to undo; blue filters every listing to its own folder. Red was told what was seen, and that the same filter rule holds for it.

### Practice match s3 (08:15)

As "Practice match" above, with one command: message both teams ("REFEREE: practice match. Tag your latest working commit `<colour>-s3` now and carry on; I fetch in 5 minutes. Score only, it doesn't count."), wait 5 minutes, then in the background with a 90-minute limit: `FALLBACK_LABEL=m1 tools/league/practice_match.sh s3 1000`. Send both teams the score line and any clock-outs, panics or faults; log it under "Scores". About 50 minutes on the referee's two cores.

**Practice match s3 (19 Nov, 08:20 to 09:10):** red-s3 `9a44e77d` (committed 07:04) against blue-s3 `a21c02d7` (committed 08:12; bot code the same as blue-m1). 1,000 games, 500 seed pairs, 2 threads on cores 4-5, 3.0 s a game.

| | Red | Blue | Red − blue |
|---|---|---|---|
| Average placement, lower is better | 4.274 ± 0.052 | 4.726 ± 0.052 | −0.453 ± 0.104 |
| Win-weighted, higher is better | 4.880 | 4.370 | +0.510 ± 0.113 |

Red ahead for the first time. No clock-outs, panics, faults or refusals; no game at the round limit; no draws. Seats 0-1 placed best (4.23, 4.29). Both teams sent the score line at 09:11. `practice_match.sh` cleans both bot crates before building but doesn't check the recompile (scope review 3's gap); blue's bot is its match 1 code, so a stale blue build would have played the same bot.

**Match 2 hand-ins, captured 19 Nov 09:49:39, before the deadline on the owner's word.** Both teams handed in early (blue 09:33, red 09:37) and said they were starting nothing that could change the tag. The owner, about 09:48: "Is there any reason to wait till 10:15 if they've handed in early? ... Might as well just run it now. And you can use as many cores as you want because nobody's using the machine anymore." So round 2 ended at 09:50 and match 2 runs on all six cores.
- `red-m2` = `03f8827d754f9cca2e8387c8f172a747124c7136`, committed 09:37:14; same bot code as `red-s3`.
- `blue-m2` = `cdbb7620459bc8b1c5e91a90dc09d0228090b9e8`, committed 09:33:37; same bot code as `blue-m1`.
- Both diffs from `league-engine-v1` touch only the team's own folder. The 10:15 wake-up task is deleted.

### Match 2 (after 10:15), then stop for the owner

**Changed by the owner, 19 Nov, about 08:20:** "I'd like to stop after match two rather than going the full run, actually. I'd like to make balance changes in between and have them iterate based on the new variants." So steps 6 and 8 below don't run: after match 2's checks, ladder and page, the referee stops for the owner. Round 3 and the challenger wait for the owner's balance changes and a new plan.

**Generalized methods (owner, 19 Nov, about 08:25), sent to both teams the same minute:** "Generalized methods would be preferable. I'd way rather a bot learn why a card is strong via empirical analysis rather than having a table saying this card is strong. I understand that ... it will produce a stronger bot for a stable game, but the game will have some balance changes and they may want to pursue a more generalized architecture if they're able to. That being said, good balance data is good balance data." *[Dictated: "car" is card; "..." drops "you know, that may produce a stronger bot for a short. Well,".]* Teams were told: the pause and the card changes; work that re-runs on new numbers is worth more for the rest of round 2; measured tables are still welcome; say in `NOTES.md` what carries over and what needs re-tuning. Any round 3 brief and plan carry this.

As "Official match" above, with these changes:
1. Capture `red-m2` / `blue-m2` at 10:15:00 and write the commit ids here. Late (commit time after 10:15:00) or missing: pass `none`; the fallback plays.
2. Tell both teams the round is over; list and clear what still runs under their folders.
3. `RED_FALLBACK=ec6aff2827448e8feb50e0e79a0fb7c2694969ee BLUE_FALLBACK=ff4ee0324669bcf85f9bf9b80435bbfe31ca29ab tools/league/official_match.sh m2 <red> <blue> load`, then `smoke`, then `counted`.
4. Checks: `tools/league/proof/replay_match.sh /home/alex/league/matches/m2 5 > /home/alex/league/matches/m2/replay.log` (keep the log this time); an Opus reader reads both bots and both `NOTES.md` and drafts the method summaries, with what is new since match 1 (`/home/alex/league/held/m2/`); `tools/league/analyse_match.sh /home/alex/league/matches/m2 /home/alex/league/matches/naive-aa --teams`.
5. **Tell the owner the score in one line and don't wait** (brief 7b.8). Stop only for a confirmed cheat, a harness bug that changes a result, a busy machine, or a Codex limit on both models.
6. *[Not run: the owner stops after match 2.]* Start round 3 as round 2 was started: `tools/league/practice_setup.sh red blue-m1 blue-m2` and the same for blue with red's tags; fill `team-brief-round.md` with n = 3, prev = 2, practice tag `s4`; copy each team's `matches/m2/teams/<colour>` to its `out/m2/`; message both teams; schedule the practice match at halfway and the deadline four hours on.
7. After the checks (all cores are free once the teams stop): the ladder (each `-m2` against `-m1` and `-s3` of both teams and `tribe`, 200 games each; the earlier practice tags are skipped because both `-m1` bots already beat them by two to four places), then the match 2 page (`build.py` with `--earlier` s0 s1 s2 m1 s3 and `--ladder`), read and published as its own page.
8. *[Not run: the owner stops after match 2.]* After match 3 (brief 7b.8, 7c, 10): score to the owner in one line, the checks, the challenger, `results.md`, and the stop for the owner.

## For the next referee: phase 1 setup still to do

Phase 0 is frozen at tag `league-engine-v1`. Starting the teams needs the owner's word. These
came from the Fable reviewer's check of the run (18 Nov) and scope review 4, and are not built:

- **Team brief and referee runbook**, from brief sections 6-8.
- **CPU cap per team:** systemd `AllowedCPUs` doesn't work for a user account; `CPUQuota` does.
  Add `MemoryMax` too.
- **`split_team.py`** with a test, before match 1: each team's own view of the logs.
- **Section 9 analysis** (owner: built before match 1's results are read). The Fable reviewer's
  plan: `tools/league/analysis/`, Python standard library only: `split_team.py`, `cards.py`
  (define "always bought" as pick rate among shops where the seat bought something), `tribes.py`,
  `behaviours.py`, `findings.py`, `agree.py`, `ladder.py`. The fields are in
  [LOGS.md](../../../tools/league/league/LOGS.md); nothing reads the schema 1 fields yet.
- **A parallel GDScript replay:** replaying 1,000 records one at a time takes about 38 min.
- **Isolation:** match outputs kept away from the teams' clones; team scopes frozen between rounds.
- **A ruling on hangs and crashes** (a hung call aborts the match, exit 3).
- Ask the teams to implement `report` if bot card values are wanted.
- Tell the teams to use `BTreeMap` or a fixed hasher (a standard `HashMap` breaks replays).

**Data outside Git** (on this machine, about 18 GB): `/home/alex/league/records/` (the GDScript
reference records `recheck.sh` replays) and `/home/alex/league/proof/` (every proof run's logs).
`tools/league/proof/recheck.sh` reruns every port check in about 8 minutes.

## The pin

- `dev` at **`c0d7db795bcb63ff38de8a5da941f96fb00aeba3`** (merge of PR 149, 18 Nov 2026). PR 128
  (Hit becomes Ambush) is not in it.
- Branch `league/engine` was cut from that commit. All league code lives in `tools/league/`.
- Godot 4.7.2, Rust 1.100.0 (pinned in `tools/versions.env`).

## Phase 0 milestones

| Milestone | State |
|---|---|
| Skeleton (ids, mechanic trait, serializer, random streams) | **done** 14:55 (`e608d642`): 1,000/1,000 record starting hashes match; JSON, Rng and sort match Godot on test cases |
| Combat | **done** 15:21 (`de374e27`, branch `league/p0-combat`): 20,000/20,000 stand-in fights match the full state byte for byte; a planted Attack change was caught by 8,870 |
| Recruit | **done** 15:30 (`4325d7cd`): 500/500 stand-in games replay, every checkpoint, action result and fight payload; planted refresh-cost bug caught at turn 1 |
| Mechanics per tribe | **all five done** 16:11. Each alone: 300/300 games and 20,000+ fights match; a planted bug in each tribe caught (mouse, pigeon, badger, locust, thorn) |
| Records match, GDScript to Rust (1,000 games) | **1,000/1,000 match**, 45,900 checkpoints (16:15, `1d7c6225`, `tools/league/proof/replay_all.sh`) |
| Records match, Rust to GDScript (50 games) | **50/50 replay in GDScript** (`league match` flow vs random, 25 seeds both colours): 773 turns, 2,319 checkpoints, 0 Godot errors |
| Fights match (100,000 mutated fights) | **100,000/100,000 match**, full state string compared (3.1 GB) |
| Planted bugs caught | **caught by every check**: Attack on `lone-hawthorn` changed 4,012 of 10,000 fights; refresh cost +1 failed 1,000/1,000 replays at turn 1; Rust records with the plant rejected by GDScript at turn 1 |
| Speed-up measured | before the speed pass: whole game ~6.4×, late fight ~15×. **After it** (`bff62ad5`): **whole game ~13×** (GD 1.92 s, Rust 0.147 s), **late fight ~40×** (`_fight` only, GD 13.6 ms, Rust 0.33 ms). Load 3-5 from other work. All proofs rerun on the merged code: [proof/SPEED.md](../../../tools/league/proof/SPEED.md) and `/home/alex/league/proof/recheck-final/` (all PASS) |
| Harness built | **built** 16:08 (`3b73a737`). Selfcheck on all tribes: 1,000/1,000 games equal the GDScript records (909,806 actions). Cheat crates caught; clock-out works (stand-in content) |
| Decision log (owner's ask, 18 Nov) | **added** (`4a24abe1`): `decisions.jsonl.gz`, every legal action at every decision with its card, and the pick; one line per record `act` (tested) |
| Clock figures | **measured** on all tribes: a late `Sim` fight 0.61 ms CPU; about 110 decisions per seat a game. 250 ms: 2.3 ms a decision, 6.3 min a match on 4 cores. 1 s: 9 ms a decision, 23 min a match on 4 cores (bots that use their whole clock) |
| Owner's picks (`2ae79a4d`, `ad685b93` fixes) | **done**: 1 s clock; seats shuffled per pair by the secret; TribeBot by seat, now **proved against GDScript** (200/200 games, 145,408 actions; wrong bots fail 200/200); `bots/red`, `bots/blue` registered with `data/` and an unbuilt `tools/`. Scope review 3: 0 cut, 2 asks (tools built by the referee; tools deps) fixed |
| A/A after the picks | TribeBot and FlowBot now play both games of a pair the same: gap **0 by construction** (500/500 pairs identical with colours swapped). **RandomBot A/A: −0.104 ± 0.113**, inside ±0.11. **Seat effect in the game:** FlowBot on all seats, seats 0-2 average 4.1, seats 6-7 4.8 (shows only with identical bots, FlowBot; the Fable reviewer's read: identical bots compete for the same cards in turn order. Not proved to be a game effect). Fair for the league: each seat is red once a pair |
| Three fixes and data layer (`9d268546`, merge `7c74861c`, fixes after review) | **done**: fight results per round, `--no-decisions`, `run_factories` (old bot against new, tested); schema 1 (per-round board, hand, heaps, counters, gold; ghost marking; `died_round`; manifest; `library.json`; gzipped shops). Records byte-identical before and after. Recheck on the merge: all PASS (1,000/1,000 replays, 100,000/100,000 fights, selfchecks 1,000 and 200, r2g 50/50); `check.sh` all passed. **Scope review 4**: logging read-only (its own runs); 2 simplify done (draw is `winner: null`, not -1 like a ghost win; `red_seats` is this game's red seats); 1 cut, 2 asks for the owner |
| A/A, TribeBot vs TribeBot (1,000 games, before the picks) | **gap +0.061 ± 0.108**, inside ±0.11; red 4.531, blue 4.469; seat placements 4.41-4.61; 0 clock-outs, faults, panics or refusals |
| Gates (runtime, scope review) | runtime: `scripts/check.sh` **all steps passed** (`src/` unchanged since the pin); cheat crates (unsafe, static/atomics, include of the other team) **fail** `check-crate`, the clean crate passes; on all tribes, busy, panic and fault bots fall back on all 80 of their seats and every game finishes. **Scope review 1** (`c0d7db79..d25dbbd8`): 0 cut, 1 simplify (README, done), 3 ask (for the owner). **Scope review 2** (`d25dbbd8..e23c7fd7`: speed pass, decision log, hardening): 0 cut, 1 ask (`plant_refresh.sh` could pass with no records; fixed). On the final code: plant_refresh PASS (1,000/1,000 caught for the gold reason, 4/4 rejected by GDScript at turn 1), the Attack plant changes 4,012/10,000 fights, and the A/A replayed with its secret is **byte-identical** to the first run |

## Where things are

- Reference records from the GDScript engine: `/home/alex/league/records/gd/c0..c2/` (seeds
  1-1000, FlowBot and RandomBot seats, made by `scripts/records.sh`).
- Porting rules for workers: [tools/league/PORTING.md](../../../tools/league/PORTING.md).

## Log

- 18 Nov, 20:45: owner: "Yes, all three". Team tools log decisions by default; brief 5b.9 updated. Frozen, tagged `league-engine-v1`.
- 18 Nov, 20:30: owner asked for three fixes and better data structures. Fixes committed; the Fable reviewer designed schema 1, a Codex worker built it, merged. Full recheck and `check.sh` pass. Scope review 4: two traps fixed, one cut and two asks go to the owner.
- 18 Nov, 19:00: owner's four picks built and reviewed; TribeBot proved against GDScript; brief updated with the owner's words; A/A redone (see milestones). Final check.sh and recheck running before the freeze.
- 18 Nov, 18:05: scope review 2 done; its one ask fixed and every plant and the A/A rerun on the final code. Clock figures were measured after the speed pass.
- 18 Nov, 17:45: speed pass merged; full recheck PASS on it. Planted refresh check redone as `proof/plant_refresh.sh` with logs (the first scripted try failed for the wrong reason, a missing repo path, and was fixed to require the planted reason). Decision log added at the owner's ask. Clock figures measured. check-crate now bans memory addresses; the harness refuses a root without card data. Owner stop written.
- 18 Nov, 17:10: `scripts/check.sh` passed. Gate bots on all tribes: busy 80/80 clock-outs, panic 80/80, fault 80/80, games finish. Busy (SimpleBot after the clock-out) beat TribeBot by 0.5 in 20 games; a 400-game SimpleBot vs TribeBot match says that was noise (TribeBot ahead, +0.18 ± 0.15).
- 18 Nov, 16:50: Rust→GD 50/50, fights 100,000/100,000, planted bugs caught, selfcheck 1,000/1,000, speed measured, A/A within the bar. `scripts/check.sh` and the speed pass running.
- 18 Nov, 16:15: all tribes merged; 1,000 GDScript games replay in Rust with every hash matching. 100,000-fight check running.
- 18 Nov, 15:25: integration branch `league/p0-core` (combat + recruit) pushed; tribe workers and harness started on it. The Codex bridge allows 5 workers at once, so the harness went to an Opus sub-agent.
- 18 Nov, 14:58: skeleton merged; combat and recruit workers started in parallel.
- 18 Nov, 14:15: pinned `dev`, made `league/engine`, started the 1,000 GDScript reference games
  (3 processes).

## Rulings and calls made without the owner

- **Planted bug on the starting hash.** The skeleton worker found that a changed card Attack can't
  change the *starting* hash: no units exist yet and the hash leaves out the card library. A
  changed card tier does change it. So planted Attack bugs are checked on later checkpoints and
  fights, where units exist. Nothing about the hash was changed to make it catch more.
- **Clock-out fallback is SimpleBot.** The brief says "a simple baseline bot"; SimpleBot is the
  simplest ported one.
- **"A bot that sleeps past its clock" is tested as a busy bot.** The clock is CPU time (brief
  5b.4.5), so a sleeping bot uses no clock. The gate bot burns CPU instead.
- **A hung bot call aborts the match** (exit 3, past the clock + 5 s CPU or 60 s wall). A thread
  can't be stopped safely, so the baseline can't take over a call that never returns.
- **check-crate allows only `league-api` as a dependency**, and bans memory addresses (`{:p}`,
  raw pointers) as a channel between seats.
- **Harness details** the harness agent chose: typed `Action`s, `report` as (card, value) pairs,
  past fight payloads renumbered by the engine as in GDScript, main tribe ties broken by stats.
  All written in `tools/league/league/README.md` and `LOGS.md`.
- **Models:** Codex workers ran gpt-6.1-sol as instructed (gpt-6.2 exists; not used). The
  bridge allows 5 workers at once, so the harness went to an Opus sub-agent.
- **The decision log is gzipped** at the end of each match (40× smaller, about 40 MB a match).
- **The A/A gate after the picks.** With TribeBot by seat the brief's TribeBot A/A is 0 by
  construction, so the gate also uses a RandomBot A/A (−0.10 ± 0.11). Written into the brief as a
  referee note.
