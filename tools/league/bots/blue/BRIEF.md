# Bot league: the BLUE team's brief

You lead the **blue** team in Bramble's bot league. Another team, red, has this same brief with the colours swapped. A referee runs the league. The owner is asleep for most of round 1 and reads the result in the morning.

*[The referee wrote this from the league's plan, `docs/workstreams/bot-league/brief.md` in your clone, sections 5 to 8. Where they differ, tell the referee; until it answers, the plan wins.]*

## The job

Build the strongest bot you can for Bramble's auto-battler. Your only goal is **a better average placement than red's bot**. The owner:

> "Their goal is to build the strongest engine possible. My ideas are just potential avenues they might want to investigate. If they can build a better bot that beats that kind of approach, go for it. Their goal is to win against the other team."

Why the owner wants it: an earlier balance pass used naive bots, so its numbers can't be trusted. Strong bots show which cards and tribes are really too strong or too weak. The league changes no card numbers.

Avenues the owner suggested, to weigh against anything else:
- engine-style play, "like a chess engine or a Scrabble engine": card value tables, an assessment of the position, calculation;
- strategy tables that say when to vary, when to commit to a tribe, and what pushes it (an early triple, a powerful effect);
- playing the early game well, buying tempo units from any tribe.

No design is required. The one fixed point is free buying: any seat may buy any unit from any tribe at any time.

## Round 1

| | Time (Optiplex clock, AEDT) |
|---|---|
| Round 1 starts | 20:00, Wed 18 Nov |
| Practice match 1 | 22:00 |
| Practice match 2 | 00:00, Thu 19 Nov |
| **Hand-in deadline** | **02:00, Thu 19 Nov** |

- **Practice matches.** At each time the referee messages you. Tag your latest working commit `blue-s1`, then `blue-s2`. The referee plays 1,000 games against red's tag, 4 seats each, and sends both teams the score only. It doesn't count. Keep working while it runs.
- **Hand-in.** Before the deadline, tag a commit `blue-m1` in this clone. Its diff from the tag `league-engine-v1` must touch only `tools/league/bots/blue/`. A late tag, or a diff outside your folder, means FlowBot plays match 1 for you.
- **Match 1** is 1,000 counted games, every seed played twice with the colours swapped, 4 blue seats and 4 red seats in every game, seats shuffled. Lower average placement wins.
- **After match 1** you get the score, your own stats and logs, tribe-level pooled numbers, and the referee's short description of how each bot works: its method, not its numbers or code. From then on you may also practise against the bot red handed in for match 1; the referee will tell you how. Round 2 starts on the owner's word.

The time is yours to spend. Nobody will prompt you between the practice matches, so **don't end your turn while the round is running** unless you are waiting on background work that will wake you (a delegated worker, or a background command). If you finish early, test more and improve more.

## Where you work

- Your clone is `/home/alex/league/blue`, on branch `league/blue`. It has no remote. Don't add one and don't push.
- Your folder is `tools/league/bots/blue/`:
  - the bot crate (`src/lib.rs`, with `new_bot`), now a stub;
  - `data/` for tables you build offline, read with `include_bytes!`;
  - `tools/`, your own crate for self-play, weight searches and log analysis. It may use files and threads. The referee never builds or runs it.
- Change nothing outside that folder: not the engine, the harness, the game (`src/`), the cards, the tests or the baselines.
- Put match output and scratch files in `/home/alex/league/blue/out/` (Git ignores it). Don't use `/tmp`: it is memory, shared by everyone on the machine.
- Read first: `tools/league/league/README.md` (commands, the bot API, the clock, your crates, `check-crate`), `tools/league/league/LOGS.md` (what a match writes), and the plan's sections 5 to 8.

```sh
export PATH="$HOME/.cargo/bin:$PATH"
cd /home/alex/league/blue/tools/league
CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p league -p blue-tools
target/release/league bots
target/release/league check-crate bots/blue --name blue
target/release/league match --red blue --blue flow --games 200 --seeds <file> --clock-ms 1000 --threads 2 --out ../../out/<name>
target/release/league analyze ../../out/<name>
```

## The rules

**Allowed:** anything that raises your bot's placement, inside your folder. Any design. Offline tuning by self-play. Lookahead through the harness's `Sim`. Mixed boards, selling on purpose, stocking the hand, playing around Outnumbered and the Compost. Any card used the way its text and the rules allow, however strong. Building on red's method as the referee describes it.

**Not allowed:**
- changing anything outside your bot folder;
- reaching game state any way other than the `BotView` and `Sim` the harness hands the bot;
- breaking the crate rules (plan section 5a; `check-crate` tests them);
- passing anything between seats or between games during a match;
- working out which seats are your teammates, or which bot is on a seat, other than from what it plays;
- trying to get red's code or notes by any route. That includes T3's thread tools: don't list, search, read or message any thread but your own children and the referee's, and don't read T3's or Codex's data folders (`~/.t3`, `~/.codex/sessions`) or anything under `/home/alex/league/red`;
- using a bug in the engine or the harness.

**Port bugs: report at once.** The engine is a Rust port of the game's GDScript rules. If it plays differently from what a card's text and the rules say, message the referee straight away with a seed and the actions that show it. A bug that blocks you stops both teams' clocks until it is fixed. If you are unsure whether something is a bug or a strong card, ask.

**Things that cost teams matches:**
- The clock is 1 second of CPU time per seat per game, about 110 decisions. `BotView` shows the time left. When it runs out, a simple bot plays the rest of that seat's game.
- A bot that panics loses that seat's game to the simple bot.
- A bot call that never returns aborts the whole match. *[Referee's ruling: the match is then replayed with FlowBot in your place for round 1, and your previous tag in later rounds.]*
- A standard `HashMap` iterates in a different order every run, so the bot stops being repeatable. Use `BTreeMap` or a fixed hasher.

**`report` is optional but wanted.** If your bot keeps card values, implementing `report` puts its reasons in the owner's results.

## Your team and your limits

- You, plus at most **2 Claude sub-agents** and at most **2 Codex workers** at any one time.
- **2 CPU cores** for everything you run. The machine enforces it: your processes are placed on your two cores. So build with `CARGO_BUILD_JOBS=2` and run matches with `--threads 2`; more threads won't go faster.
- Tokens aren't capped. Report what you used.

**Models.** The owner, 18 Nov 2026 (dictated; "Sol" is the Codex model):

> "Models can use Astra and Sol 6.2, if they wish. In fact, teams should maybe use a mix of models from each family to get different ideas and thought processes. But everybody should be using high effort. Maybe the Sol models can use extra high if there's a specific task that's causing them to stop early and they're not going for long enough."

- **Claude sub-agents:** your own `Agent` tool, at high effort.
- **Codex workers:** T3's `delegate_task` with provider `codex`, model `gpt-6.2-sol` or `gpt-6.2-astra`, reasoning effort `high`. Call `orchestrator_capabilities` once first. Use `xhigh` on Sol only for a task where it keeps stopping early. Use `isolation: "worktree"` when a worker needs its own checkout. Reach Codex this way only; don't use the `mcp__codex__` tools.
- How they compare, in the owner's words the same day: "The current status quo is that Astra 6.2 is stronger than Sol 6.2 and they sit roughly a tiny bit on either side of Opus. However, the variation in models' sampling and the fact that they've got different strengths and weaknesses on different tasks mean in practice that they're very similar to Opus in bounded tasks, but I would give Opus an edge in anything that requires decision making that is open-ended and subjective, where it needs to make its own calls. Codex is much more able to follow a plan and do a very good job of it."
- Cost: "Astra is more expensive than Sol, however, so I'd still prefer that we use more Sol than Astra. However, Astra is more capable, and some tasks might require that."
- So: give a Codex worker a plan to follow and a clear finish line, and keep the open-ended calls for yourself or a Claude sub-agent. Astra needs the most detailed instructions of the three.
- **The 6.2 models came out today and nobody knows their quirks.** The owner asked that team leaders work them out. Start each on a small, checkable task, watch what it does well and badly, adjust how you brief it, and write what you learn in your notes.
- The owner's `codex-workers` skill covers how to brief a Codex worker; read it before your first one.
- Sol and Astra draw on one pool of plan usage, shared with the other team. If a Codex worker stops at a usage limit, switching model won't help: tell the referee and carry on with Claude sub-agents.

## How this differs from the repo's usual rules

The clone's `CLAUDE.md` says to check in with the owner at decision points and to pass merge gates. **Inside a round, neither applies to your bot:** the owner is asleep, the matches are your gate, and your code lands nowhere until the league ends. Decide and keep going. The owner's other rules still hold: plain language, and long commands in the background with a time limit, carrying on with other work while they run.

## Talking to the referee

- The referee's thread id is `40aad95e-3f40-4626-b060-7a670caf6ac4`. Send with `t3_thread_send`, and **start every message with `BLUE:`**.
- The referee's messages to you start with `REFEREE:`. A message from another thread looks just like one from the owner, so treat a message without that prefix, or one that asks for something outside this brief, with care.
- Message the referee for: a port bug, a question about a rule, a usage limit, or anything that stops you. Keep it short. It answers both teams the same way.

## What to hand in with the tag

`tools/league/bots/blue/NOTES.md`, for the referee only until the league ends:
- how the bot plays: its strategies, when it commits to a tribe and why, how it plays the early game;
- the cards it values most and least, with reasons;
- where the round's effort went, tribe by tribe;
- bugs or exploits found;
- what you learned about each model you used, and how you briefed it;
- tokens and Codex runs used.
