# Round {n}: the {COLOUR} team

Your round 1 brief (`BRIEF.md`, beside this file) still holds in full: the job, where you work, the rules, your team and limits, talking to the referee, and what to hand in. This page adds round {n}. *[Written by the referee from the league's plan, section 7b, and its amendment, section 4b.]*

## Match {prev}

{score}

- **Your own view** of the match is in `/home/alex/league/{colour}/out/m{prev}/`: `team.md` and `team.json` (your seats' stats, card by card) and `decisions.jsonl.gz` (your seats' decision logs).
- **Both teams pooled, at tribe level only** (the final main tribe of all 8,000 boards):

{tribes}

- **How each bot works**, as the referee describes it from the code and notes. Both teams get both. You may build on {other}'s method as described here.

{methods}

## Round {n} times

| | Time (Optiplex clock, AEDT) |
|---|---|
| Round {n} starts | {start} |
| Practice match | {practice} |
| **Hand-in deadline** | **{deadline}** |

- **Practice match.** At that time the referee messages you. Tag your latest working commit `{colour}-s{s}`. 1,000 games against {other}'s tag, score only, doesn't count. Keep working while it runs.
- **Hand-in.** Before the deadline, tag a commit `{colour}-m{n}`. Its diff from `league-engine-v1` must touch only `tools/league/bots/{colour}/`. A late tag, a diff outside your folder, or a failed `check-crate` means the bot you handed in for match {prev} plays match {n} for you.
- **Match {n}** is played the same way as match {prev}. {after}
- Add to `NOTES.md` what is new since match {prev}.

As before, nobody will prompt you between now and the practice match: **don't end your turn while the round is running** unless you are waiting on background work that will wake you.

## New: practise against the bot {other} handed in for match {prev}

The owner's amendment to the plan. Your practice folder is `/home/alex/league/practice-{colour}`. It holds the frozen engine, {other}'s match {prev} bot built in under the name `{other}-m{prev}`, and your own bot linked live from your clone.

```sh
/home/alex/league/practice-{colour}/play.sh {other}-m{prev} <games> /home/alex/league/{colour}/out/<new-folder> [--seeds FILE]
```

- It rebuilds your bot from your clone as it is at that moment, then plays on your two cores: about 25 seconds to build and about 3 seconds a game, so 200 games take about 10 minutes. One run at a time.
- **In this output your live bot is always "red" and {other}'s old bot is always "blue", whatever your colour.**
- The output is what any match writes (`tools/league/league/LOGS.md`): the score, your logs, and the game records, which show what the old bot's seats bought and fielded.
- **The rule: run it as often as you like; don't open the other bot's source** (`bots/{other}-m{prev}/` in that folder), and say so in every brief you give a sub-agent or worker. Never practise against {other}'s current work. This folder is the one exception to "nothing under `/home/alex/league/` except your own clone": you may run `play.sh` and read its `README.md`, nothing else there.

## Two things learned in round 1

- **A Codex worker can stall on an approval prompt** that nobody can answer, even in a full-access thread. It happened to the referee's worker on a command containing `rm -rf`. Tell Codex workers not to use `rm -rf` (delete single files, or leave scratch files under `out/`), and if a worker has been quiet for 20 minutes, look at it with `task_status`: a waiting approval shows as `pendingApproval`. Cancel it and restart it with a changed brief.
- **A worker's completion reaches you only when your own turn ends.** If you are working while it runs, check `task_status` yourself now and then.
