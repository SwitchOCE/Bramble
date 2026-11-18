# Round 2: the BLUE team

Your round 1 brief (`BRIEF.md`, beside this file) still holds in full: the job, where you work, the rules, your team and limits, talking to the referee, and what to hand in. This page adds round 2. *[Written by the referee from the league's plan, section 7b, and its amendment, section 4b.]*

## Match 1

| | Red | Blue | Red minus blue |
|---|---|---|---|
| Average placement, lower is better | 4.715 ± 0.047 | 4.285 ± 0.047 | +0.430 ± 0.095 |

**Blue won match 1.** 1,000 games, 500 seed pairs, intervals are 95%. Neither bot had a clock-out, a panic, a fault or a refused action. All 1,000 games were replayed in the GDScript engine and matched, so no port bug touched the result.

- **Your own view** of the match is in `/home/alex/league/blue/out/m1/`: `team.md` and `team.json` (your seats' stats, card by card) and `decisions.jsonl.gz` (your seats' decision logs).
- **Both teams pooled, at tribe level only** (the final main tribe of all 8,000 boards):

| Final main tribe | Share of boards | Average placement |
|---|---|---|
| Locust | 49.7% | 4.47 |
| Pigeon | 30.9% | 4.96 |
| Briar | 7.7% | 3.79 |
| Mouse | 7.5% | 3.39 |
| Badger | 4.2% | 4.82 |

- **How each bot works**, as the referee describes it from the code and notes. Both teams get both. You may build on red's method as described here.

### Red's bot, match 1: method summary

**Kind of bot.** A rule-driven bot that works down a fixed priority list each call, judging every buy, sell and Discover by a card value table. A model wrote the table from the card text. Then it was corrected several times by regression on self-play games in which card values were nudged at random, to see which cards really moved placement.

**Tribe and early game.** It never locks a tribe. A card's value rises with how many units of its tribes the bot already holds. Its main tribe is just the one it holds most of, and that tribe gets a bonus that grows over the game. Early on it buys the best-valued units it can afford. It gives extra weight to a second copy and always takes a third.

**Upgrades, selling, positioning, spells.** It levels on a target-tier curve by round, which self-play pushed well slower than Battlegrounds habits. It also levels when the waiting discount makes an upgrade cheap, but not if that leaves it unable to buy a visible third copy. It freezes a shop that holds one. When the board is full it swaps its weakest unit for a clearly better one, never one bought that turn. It also sells on purpose: to feed units that eat, to fill the Compost, and to cycle cheap units when its board pays for each Compost entry. Positioning starts from row rules, then a hill-climb of swaps scored in fights against the latest boards it has seen. It mostly buys only the cheap stat spell, cast on its most valuable unit.

**Thinking clock.** Nearly all of it goes to the positioning search, shared over the rounds left. A simulated-fight check on buys exists but is switched off.

### Blue's bot, match 1: method summary

**Kind of bot.** A greedy bot that works down a fixed priority list each call. Card values have two parts. A small hand-written part says which row a card wants, what its text is worth and how much it grows. A large measured part says how much better the seats that held the card placed in the bot's own self-play. The team measured this again under each newer version of the bot and blended it in by steps until that stopped helping. The measured part mostly decides the buys.

**Tribe and early game.** It never locks a tribe. A synergy bonus grows with how many units of a tribe it owns, so it drifts toward its biggest tribe. Later in the game, once one tribe is clearly ahead, off-tribe units are marked down. A small fixed lean toward or away from some tribes was set by self-play. The early game is pure tempo: cheap units from any tribe, the cheap stat spell, and a full board fast.

**Upgrades, selling, positioning, spells.** It levels on a fixed schedule by round, which self-play pushed far slower than Battlegrounds habits. With a full board it buys only what clearly beats its weakest unit, then sells that unit. It values pairs and triples and freezes for copies it is collecting. Orders that pay for themselves come before buying. It casts the stat spell early on its best front unit and buys Discover spells only later.

**Thinking clock.** Only arranging the board uses it. The bot starts from row rules, then tries swaps in turn. It scores each in fights against the next opponent's last board, weighted most, and other recent boards. Each turn gets a capped share with a reserve kept back. A simulated-fight check on buys exists but is switched off.

## Round 2 times

| | Time (Optiplex clock, AEDT) |
|---|---|
| Round 2 starts | Thu 19 Nov, 06:15 |
| Practice match | 08:15 |
| **Hand-in deadline** | **Thu 19 Nov, 10:15** |

- **Practice match.** At that time the referee messages you. Tag your latest working commit `blue-s3`. 1,000 games against red's tag, score only, doesn't count. Keep working while it runs.
- **Hand-in.** Before the deadline, tag a commit `blue-m2`. Its diff from `league-engine-v1` must touch only `tools/league/bots/blue/`. A late tag, a diff outside your folder, or a failed `check-crate` means the bot you handed in for match 1 plays match 2 for you.
- **Match 2** is played the same way as match 1. Round 3 follows it without a stop for the owner: you get the score, your own view and new method descriptions, and four more hours.
- Add to `NOTES.md` what is new since match 1.

As before, nobody will prompt you between now and the practice match: **don't end your turn while the round is running** unless you are waiting on background work that will wake you.

## New: practise against the bot red handed in for match 1

The owner's amendment to the plan. Your practice folder is `/home/alex/league/practice-blue`. It holds the frozen engine, red's match 1 bot built in under the name `red-m1`, and your own bot linked live from your clone.

```sh
/home/alex/league/practice-blue/play.sh red-m1 <games> /home/alex/league/blue/out/<new-folder> [--seeds FILE]
```

- It rebuilds your bot from your clone as it is at that moment, then plays on your two cores: about 25 seconds to build and about 3 seconds a game, so 200 games take about 10 minutes. One run at a time.
- **In this output your live bot is always "red" and red's old bot is always "blue", whatever your colour.**
- The output is what any match writes (`tools/league/league/LOGS.md`): the score, your logs, and the game records, which show what the old bot's seats bought and fielded.
- **The rule: run it as often as you like; don't open the other bot's source** (`bots/red-m1/` in that folder), and say so in every brief you give a sub-agent or worker. Never practise against red's current work. This folder is the one exception to "nothing under `/home/alex/league/` except your own clone": you may run `play.sh` and read its `README.md`, nothing else there.

## Two things learned in round 1

- **A Codex worker can stall on an approval prompt** that nobody can answer, even in a full-access thread. It happened to the referee's worker on a command containing `rm -rf`. Tell Codex workers not to use `rm -rf` (delete single files, or leave scratch files under `out/`), and if a worker has been quiet for 20 minutes, look at it with `task_status`: a waiting approval shows as `pendingApproval`. Cancel it and restart it with a changed brief.
- **A worker's completion reaches you only when your own turn ends.** If you are working while it runs, check `task_status` yourself now and then.
