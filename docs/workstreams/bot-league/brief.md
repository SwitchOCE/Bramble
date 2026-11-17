# Bot league: red team against blue team

**Status: proposal, 18 Nov 2026, third revision. Not approved, nothing run.** The owner turned down the first version because it locked seats to a tribe; this one is free play. Since then the owner has said the bot's design is the team's call, and that the match bot must be written in a performant language. The owner approves it before anything starts. It is written for the session that will run the league (the **referee**), which starts the two team orchestrators.

## 1. Why

On 18 Nov an Opus agent did a bounded balance pass on `dev` (8f55bcca): [balance-pass-18-nov/findings.md](balance-pass-18-nov/findings.md), with its probe scripts beside it (`tribe_lobby.gd.txt`, `duel.gd.txt`; drop `.txt` and put them in `tools/checks/` to run them). Its full transcript is outside Git at `/home/alex/.claude/handoff/bramble-balance-2026-11-18/balance-agent-transcript.jsonl`.

It found Pigeons far ahead (average place 3.2 in 455 tribe-locked lobbies) and Mice far behind (6.2), with several uncapped cards (Colour Sergeant, the Colonel's Reserve, Gleaner). But it warned that its bots were naive: tribe-locked, greedy, never selling on purpose, never stocking the hand for the Colonel, never feeding the Compost or planning around Outnumbered. So its numbers are a first read, not something to rebalance from.

The owner wants better bots built under competition, so the balance numbers can be trusted. The owner's words, 18 Nov 2026, in full:

> "Okay, I think I want you to write me a brief based on that agent's findings regarding balance. And I want to take a red team, blue team approach where we have two orchestrators who are each running their own team whose goal it is to make the best bot possible. And they can do anything they want to make the bot's win rate go up, and should. And their job is to put that bot against the other team's bot after maybe a certain number of tokens or something, maybe. I don't know what the best limit is. Time, tokens, something? Runs? I'm not sure. And then they're allowed to look at each other's bot's code and then go back to the drawing board and iterate. Once they've done a single pass, and once they've done three passes, three matches, and the bots can, I don't know, have 1,000 simulated games or something. I'm not sure what a good sample size is that strikes the balance between reliable but not overkill. And I guess the population needs to come in slowly, I guess, because you need to have an existing field of ghosts to play against of the bot strength. Probably need to, like, the first 100 games are just played against random bots, and then they don't count. And then once we've got enough ghosts of each of the bots, the lobby should be comprised of 4 of each, and the average placement, I guess, of each team's bots at the end will determine the winner. And we can look at stuff like distribution and stuff as hints as well. But yeah, I want to get stats from this basically, and I want it to be opposed. The teams are competing against one another. So give me a prompt to set that up."

On the first version, which locked each seat to one tribe, the owner said (18 Nov 2026; filler removed):

> "I do not approve this as written. Seats should not be locked to a tribe. Playing a tribe well is also about knowing how to play the early game. And you can't always only buy units from one tribe. That will cause a lot of waste, and the ghosts will be far *[probably "the boards will be far weaker"; unclear as heard]*, and the bots will be far weaker because of it. If the bots are only buying units from one tribe, that's a design where the balance is bad, which is exactly what this is supposed to help fix. And if some tier 1 units are really good tempo, and everyone always buys the Pigeon units on tier 1, even if they're playing Badgers, because the Pigeon tier 1 units are better than the Badger tier 1 units, always, under all circumstances, that's a problem we want to know about, right? So I don't want it made like that, because that won't highlight the problems.
>
> I would also prefer that the bots operate like an engine, in that they have tables with values, and they make assessments of the position, or calculate. And maybe strategy tables as well, to know when to vary, and the concept of committing to a specific tribe at some point. So they can understand: at this point, this is the strongest strategy for me, and I've hit these powerful effects, off an early triple, which pushes me in one direction or whatever. Kind of like how a real player would play. I don't want them locked to one tribe. That will cause bad results. If, in picking which tier 1 units to buy, there's the equivalent of value tables, like a chess engine or a Scrabble engine would use, and they never buy one unit ever, it's got a weighting of 0 or something: that's the most perfect information we could get. So no, I do not want them locked to one tribe. Rewrite the prompt."

**What done looks like:** three matches played and a winner. A results page that says, for each of the balance pass's ten findings, whether it holds under strong bots, with numbers. And the strong bots' own verdicts on every card: what they never buy, what they always buy whatever tribe they're in, and when they commit to a tribe and why. The league changes no card numbers. Rebalancing is a separate decision for the owner.

**The owner gets a usable read early.** The ten-findings table and the card verdicts are filled in after every match, not only at the end. If match 1's read is enough, the owner can stop the league there.

## 2. The shape

- A **referee** (the session that runs this brief) builds and freezes a match harness on a pinned `dev` commit, starts the two teams, runs every official match, checks every match for cheating and harness bugs, and writes the results.
- **Red** and **blue** are each one Opus orchestrator session with its own helpers. Each builds the strongest bot it can. Their only goal: **a better average placement than the other team.**
- **Free play.** Every seat may buy any unit from any tribe, as a player can. All five tribes are in every lobby.
- **Three rounds.** Each round is a fixed time to build, then an official match of 1,000 counted games. In every game, 4 seats are red bots and 4 are blue. After each match, both teams get the other's bot source and data and the full match data, and the next round starts.

## 3. The owner's open questions: recommendations

| Question | Recommendation | Why |
|---|---|---|
| What limits a round: time, tokens, runs? | **Wall-clock time** (round 1: 4 hours; rounds 2 and 3: 3 hours each), plus **equal caps** on helpers and CPU (section 6). Tokens are not capped; each team reports what it used. | Time is the one limit that is easy to enforce, equal for both and keeps the matches in step. Claude and Codex tokens aren't comparable, and an orchestrator can't see its own total live. |
| Sample size per match | **1,000 counted games**, played as 500 pairs: each seed twice, with the teams' seats swapped. | It gives each team's average placement to about **±0.05 places** (95%), and the red-minus-blue gap to **±0.11**. Per tribe it depends on how often strong bots play that tribe. A tribe that is the main tribe of 1 board in 5 gets about ±0.11 places; 1 in 20 gets about ±0.22. A tribe almost nobody plays gets almost no numbers, and that is itself the finding. 500 games would give ±0.15 on the gap; 2,000 only ±0.08 for double the time. |
| The warm-up and the ghost field | **No ghost warm-up.** Every official game is a live 8-seat lobby, 4 red and 4 blue, from the first game. The first 20 games of each match are a smoke run that doesn't count. | The build on `dev` plays all 8 seats live in one process: every seat is a real bot taking its turns, so there is no empty field to fill and no cold start. The owner's warm-up was to make sure bots meet a field of their own strength; live seats give that directly. A ghost field would also mean designing how snapshots are chosen and matched, which is open rule 2.1.5 (async play) in the rulebook, so the harness would be deciding a rule the owner hasn't. **Owner to check** (section 12). |
| Scoring | **Average placement of each team's seats over the 1,000 counted games. Lower wins the match. Two match wins out of three win the league.** The distribution and the stats in section 9 are hints. | It is the owner's measure. With 4 seats each in an 8-seat lobby, red's average plus blue's is always 9, so it is one fair number. The results say whether each margin is outside the noise. |
| Iteration | **Three matches.** After each, the referee gives each team the other's bot source and data at the match tag, the match records and the stats. Teams may copy from them, credited in their notes. | It is what the owner asked for. Copying is allowed because better bots on both sides give better balance numbers. |

## 4. Roles

**Referee** (one Opus session; the session that runs this brief):
- builds the harness (phase 0), gets it through both gates, and freezes it;
- sets up the two team folders and starts red and blue as side sessions, with the same team brief apart from the colour;
- answers both teams the same way: any ruling or harness fix goes to both at once;
- runs every official match, checks it (section 8), publishes results and code to both teams, and starts the next round;
- writes the results page and the hand-over (section 10);
- never helps either team with its bot, and never passes one team's work to the other before a match ends.

**Red and blue** (one Opus orchestrator each): may use Opus sub-agents and Codex workers on `gpt-6.1-sol` (Astra only under the codex-bridge's usage-limit rule), within the caps in section 6. Each team works only in its own folder and talks only to the referee.

Every session follows the owner's global rules: plain language, and long commands in the background with a time limit. Any unforeseen judgment call with no decision on record goes to a Fable advisor first.

The owner's merge gates apply to the referee's harness (section 5) and to the final PR into `dev`. **Inside a team's timed round, the bot code needs no `plan-interrogate`, owner approval or scope review:** the matches and the referee's checks are its gates, and it lands nowhere until the final PR. **Owner to check** (section 12).

## 5. The bot: whatever wins

The owner, 18 Nov 2026: "Their goal is to build the strongest engine possible. My ideas are just potential avenues they might want to investigate. If they can build a better bot that beats that kind of approach, go for it. Their goal is to win against the other team."

So **no design is required**. Free buying is the only fixed point: no tribe lock anywhere, and any seat may buy any unit at any time.

**Avenues the owner suggested, for teams to weigh against anything else:**
- engine-style play, "like a chess engine or a Scrabble engine": card value tables, an assessment of the position, calculation;
- strategy tables that say when to vary, when to commit to a tribe, and what pushes it (an early triple, a powerful effect hit);
- playing the early game well, buying tempo units from any tribe.

**The card verdicts don't depend on how the bot is built.** "Never bought" and "bought by every tribe" come from the harness's log of every shop and every buy (section 5b, point 6), whatever the bot is like inside.

**`report()` is optional.** A bot that keeps card values can report them: whenever it sees a shop or a Discover choice, the harness calls `report()`, times it on the bot's clock, and logs:
- its value for every card on offer, not only the one it buys;
- its current strategy name.

This adds the bot's reasons to the verdicts. A bot without it simply logs nothing there.

### 5a. What to write the bot in

The owner, 18 Nov 2026: "They're allowed to use a scripting language like Python to prototype stuff, but the final run must be written in a performant language, and the code must be performant enough that … we're trying to save time and resources. That's the role of the performant code. It doesn't need to be optimized down to the nth degree."

**Prototype in anything.** Python, GDScript, or whatever saves the team a compile. Tuning by self-play, analysing logs and searching for weights are offline work and can stay in any language. Their results go into the bot's folder as data.

**The bot that plays a match is written in Rust (or C++).** It is built as a GDExtension inside the team's folder, so Godot can load it. A GDScript adapter, kept thin, passes the harness's calls to it.
- Rust: `rustc` and `cargo` 1.100 (stable) are installed on the Optiplex, in `~/.cargo/bin`, which is not on the default `PATH`. Bindings come from the `godot-rust` (gdext) crate.
- C++: `gcc` 15 and `clang` 21 are installed. Bindings come from `godot-cpp`.
- The referee builds every bot from source at the match tag; a pre-built binary doesn't count.
- The rules for bot code apply to the native part too: no threads, no global state, nothing outside the folder.
- "Performant enough" means it doesn't waste the clock or the machine: no needless copying, no slow loops in hot paths. It doesn't mean tuned to the last cycle.

**What native code can and can't speed up.** The rules core and the real fight engine are GDScript and stay frozen. A bot still takes its actions through them, and any lookahead with the real engine runs at GDScript speed (about 40 ms a late-game fight). Native code makes the bot's own thinking fast: values, search, and its own fight estimate if it writes one. Such an estimate is the team's risk: if it disagrees with the real engine, the bot plays worse. The game itself, about 2.5 seconds a game with simple bots, stays the floor of every match.

### 5b. The harness, built by the referee and then frozen

**Pin the build.** Use the `dev` commit at the start (write its SHA in the run notes). Make branch `league/harness` from it. Teams never change anything it contains.

**What the harness does:**

1. **Plays a match:** `godot --headless -s res://tools/league/match.gd -- red=<folder> blue=<folder> games=1000 seeds=<file of random seeds> clock=1`. It loads each team's bot from its folder under `tools/league/bots/` (`red/bot.gd` with any data files beside it, and the same for blue), with one fresh bot object per seat per game. Everything stays under `tools/league/`, so none of it goes into the export.
2. **Runs the turn loop itself.** A bot's `take_turn` is overridable, so the harness never calls it. The harness calls `choose()`, checks the action is in `session.legal_actions`, calls `session.act`, and ends the turn. `choose()`, the optional `report()` (section 5) and the round-start hook (below) are the only calls into the bot. Each seat's bot is made before the game starts. The harness gives each seat its own deep copy of the team's data files, so teammates share nothing. The time to make the bot counts against that seat's clock.
3. **Seats and seeds:** seats alternate red and blue. Seat order rotates with the seed. Every seed is played twice with the colours swapped. All five tribes are in every lobby, as in the shipped game.
   - Seeds are random 31-bit numbers, listed in the seeds file, not a counted sequence.
   - Each bot gets a random stream that isn't derived from the game seed. The existing bots' `Rng.derive(game_seed, "bot:%d")` would let a bot work the seed out, and from it every shop.
4. **The thinking clock:** each seat gets **1 second of thinking per game**, timed around every call the harness makes into the bot. When a seat's clock runs out, the harness plays the rest of that seat's game with `SimpleBot` and logs a clock-out. The harness can't interrupt a single call, so one call over half a second is logged as a fault.
   - The clock is a ceiling, not a cost. A table bot uses milliseconds, and 1 second still allows about 25 late-game lookahead fights a game.
   - Without any clock, a match has no end time and the teams' bots aren't on equal compute. So the clock is what makes a faster language or a smarter search a fair advantage.
5. **The same content as the shipped game.** It loads the game's own content, the stand-in spells included, with no test or neutral cards.
6. **Records every game** with the existing game records (`src/core/records/`), into the league's data folder (not `user://`). It also writes, in JSON:
   - one stats line per game, extending the balance pass's lobby format;
   - one line per shop the bot saw, read by the harness from `shop_units` and `shop_spells` before each `choose()`. Each card on offer is marked **buyable** (affordable, and room in the hand) or not, alongside what the bot bought;
   - one line per Discover choice: the options and the pick;
   - each `report()`.
7. **Works out each board's tribe from the game state, not from what the bot says.**
   - The **main tribe** is the tribe with the most units on the board, with ties going to the higher total stats.
   - The **commit round** is the first round with 4 or more units of the final main tribe.
   - A seat **pivots** when, after its commit round, another tribe reaches 4 or more units and becomes the main tribe. A tie, such as 3 Pigeons and 3 Badgers, is not a pivot.
8. **Hands each seat, at round start, what it saw of past opponents:** the opponent's fight payload as `RecordState.fight_players` gives it, which is board, slots, counters, heaps and Reserve hand. A board alone would get Pigeons wrong, because their slot buffs live on `PlayerState.slots`, and Briars wrong, because of their Compost heap.
9. **Baselines** for practice and the anchor (section 7): `SimpleBot`, `FlowBot`, `RandomBot`, and the balance pass's `TribeBot`, committed as `tools/league/bots/baseline/`. They are the only tribe-locked bots, and they never count.
10. **`tools/league/analyze.py`.** Phase 0 needs only the log format, the score and the health checks. The referee writes the rest of section 9 during round 1, while the teams build.
11. **`tools/league/verify.sh`:** the cheat and bug checks in section 8.

**Rules for bot code**, so two teams' code can load side by side and seats can't share anything:
- no `class_name` (use `preload`);
- no `static var`, no autoloads;
- no `Engine.set_meta` or other global stores;
- no `Thread` or `WorkerThreadPool`;
- no file, network or `OS.` access, except reading its own data files through the harness at load;
- nothing outside the team's folder;
- the same rules for any Rust part (section 5a).

A bot extends `Bot` (`src/core/bots/bot.gd`) and may extend `SimpleBot` or `FlowBot`.

**The information rule.** A bot gets the live `GameSession`, because the core has no copy or view object for it. It may read only:
- its own `PlayerState` and `session.view_for(own id)`;
- every player's health, armor, tier and whether they are still alive;
- the board each past opponent showed when they fought, which the harness hands each seat through its round-start hook;
- the card library, the rules and all code.

It may run the fight engine (`Combat.create` and `run`, as `duel.gd` does) on boards it is allowed to know, with any seed except the real fight's. Two rules keep an honest bot's lookahead from changing the real game, which the replay would then flag as cheating:
- pass `live=false` for both sides, because a live side writes into the real counters, heaps and units;
- never call `session.new_unit`, which moves the game's unit counter. Make lookahead units with `Unit.create` and the bot's own ids.

It may not read:
- other players' hands, shops, current boards or gold;
- the pool (`session.units`, `session.spells`);
- the game's seed (`session.seed_value`) or any random stream: every shop, pairing and fight is derived from the seed (`Rng.derive`, `Rng.hash32`), so a bot that reads it can predict them;
- `session.events`, `session.fights`, `session.recruit` or the record.

It may not change the session except through the actions the harness takes for it.

**Gate before freezing** (the owner's two gates):
- **Runtime:** `scripts/check.sh` passes. Then:
  - an **A/A match**, where both colours run `TribeBot` for 1,000 games, shows a red-minus-blue gap within ±0.11. This also gives the **naive column** for the results. The balance pass played without the game's 3 stand-in spells (`sp_sharpen`, `sp_seek`, `sp_forage`), and the harness plays with them, so its own numbers aren't a fair comparison;
  - colour and seat balance is checked in the stats;
  - **each planted cheat is caught**:
    - a bot that adds gold to itself, caught by the replay;
    - one that reads another player's hand, caught by the code scan;
    - one that keeps a `static var` across seats, caught by the scan;
  - a single call that sleeps 1 second produces a clock-out;
  - **a native bot works end to end.** A minimal Rust GDExtension bot builds from source with the installed toolchain (`~/.cargo/bin`, `godot-rust` for Godot 4.7), loads in the harness, and plays a whole match game. If the bindings won't build for Godot 4.7, stop and ask the owner before starting the teams;
  - a sample bot's `report()` shows in the logs.
- **Scope review:** a fresh `scope-reviewer` on the harness commits, given the owner's words above and this brief.

**Stop for the owner:** show the A/A result and the planted cheats being caught, in a few lines. Start the teams on the owner's go. Then tag `league-harness-v1`. A fix later is `v2`, goes to both teams at once, and any match it affects is played again.

## 6. The rules for teams

**Isolation.** Each team works in its own clone, not a worktree of the shared repo, so the other team's commits never show in `git log --all`: `/home/alex/league/red` and `/home/alex/league/blue`, cloned from the harness tag on branches `league/red` and `league/blue`. Teams don't push until the referee asks for the match tag. Until a match ends, a team doesn't read anything outside its own clone, the pinned build, its own Codex worktrees and the folder of published opponent code. The referee publishes opponent code into `league/published/<colour>-m<n>/`, which both teams can read after that match.

**Allowed: anything that raises the bot's placement, inside its own folder (sections 5 and 5a).** For example:
- any design: value tables, search, simulation, rules of thumb, weights tuned offline by self-play;
- strategy per tribe and across tribes: when to stay open, when to commit, when to pivot;
- buying any unit from any tribe: tempo units early, mixed boards, a splash of another tribe's engine;
- search, and lookahead with the real fight engine;
- selling on purpose, stocking the hand, planning around Outnumbered and the Compost;
- using any card the way its text and the rules allow, however strong;
- copying from the other team's published code and data (credit it in the notes);
- tuning against the other team's published bots.

**Not allowed:**
- changing anything outside its bot folder: the rules core (`src/core`), the cards (`src/content`), the harness, tests, baselines or the other team's bot;
- breaking the information rule (section 5b);
- passing anything between seats or between games during a match: no shared memory, files, network or clocks other than the harness's;
- detecting which seats are teammates or which bot is on a seat, other than through what it plays;
- using a bug in the rules core or the harness.

A team that finds such a bug reports it to the referee at once. The referee logs it for the owner, tells both teams, and rules whether it's a bug (banned from matches) or the rules working as written (allowed, and itself a balance finding). The rules core stays frozen during the league unless a bug crashes games.

**Equal caps for each team**, all at once:
- the orchestrator, at most 2 Opus sub-agents, and at most 2 Codex workers;
- at most 2 Godot processes for practice games.

The Codex plan pool is shared, so if Sol hits its limit, the referee moves both teams to Astra together.

**Hand-in at the round's deadline:** a commit tagged `red-m<n>` or `blue-m<n>` in the team's clone, whose diff from the harness tag touches only `tools/league/bots/<colour>/`, plus `NOTES.md` in that folder:
- how the bot plays: its strategies, when it commits and why, and how it plays the early game;
- the cards it values most and least, with its reasons;
- where the round's effort went, tribe by tribe;
- what changed since the last match and why;
- what it took from the other team;
- the bugs or exploits found;
- the tokens and Codex runs used.

A late tag, or a diff outside the team's folder, means the team plays that match with its previous tag (round 1: `FlowBot`).

## 7. A match, step by step

1. **Check the machine** (section 7a). Fetch both tags from the clones. Check each diff is limited to the team's folder, and copy both folders onto the frozen harness.
2. **Smoke run:** 20 games, not counted. On a crash or a fault in a bot, the referee tells that team, which gets 30 minutes to fix only that. The other team is told the same.
3. **Counted run:** 1,000 games (500 seed pairs). The seeds are fresh for each match and not announced beforehand.
4. **Verify** (section 8), then publish to both teams at once:
   - the score and stats;
   - the ten-findings table and the card verdicts (section 10) for this match;
   - the records;
   - the other team's source and data into `league/published/`;
   - the start of the next round.
5. **After match 1, stop for the owner:** the score, the first findings table and the card verdicts, in a few lines. Start round 2 on their go. They may stop the league here.
   - Also give each tribe's share of final boards. If a tribe is the main tribe of fewer than 5% of them, the findings about it can't be judged (for Mice, Locusts or Badgers, findings 5–7).
   - Offer the owner an unscored probe for that tribe. Don't build it unless they say yes.
6. **After matches 2 and 3, tell the owner the score in one line, and don't wait.** Also stop and ask for a confirmed cheat, a harness bug that changes a result, a busy machine, or a Codex limit on both models.

**After match 3**, run **the anchor** once, not scored: each team's final bot in 4 seats against 4 `TribeBot` seats, 200 games. It shows how far the final bots are above the balance pass's tribe-locked bots, and whether a bot only learned to beat the other team's habits.

### 7a. Compute

The machine is the owner's always-on Optiplex: 6 cores, about 14 GB of memory, shared with other agents. The owner has said the half-the-cores rule is for the main computer, not the Optiplex. Still, before each match and before each team's first practice batch, check:
- the load (`uptime`);
- the memory (`free -g`, and committed memory in `/proc/meminfo`);
- what else is running (`ps -eo pid,pcpu,rss,etime,cmd --sort=-pcpu | head`).

Matches run with 4 Godot processes while the teams are paused between rounds. If the 1-minute load is above 3, or less than 3 GB is free, wait or ask the owner.

**Rough cost**, from the balance pass:
- one greedy-bot lobby game takes about 2.5 seconds on one core;
- 455 games took about 7 minutes in 5 processes;
- a late-game fight takes roughly 40 ms;
- a fresh checkout needs `godot --headless --import` first, about 25 seconds.

With the 1-second clock, the worst case is about 11 seconds a game, so about 50 minutes for a match at 4 processes, and about an hour once the replay checks are added. Plan on the worst case: the clock is free strength, so teams may use all of it.

**The floor is the game engine itself**, about 2.5 seconds a game even with trivial bots. Native bots shrink the thinking time but not this floor. Only a faster rules core would; that is listed as a follow-up, not part of the league.

## 8. Catching cheats and harness bugs

1. **Replay every counted game** from its record on the frozen build, with no bot code loaded (`scripts/records.sh record=...`). A bot that changed the game other than through `act` breaks the state hashes and is caught. Replay can't catch a bot that only reads what it shouldn't; checks 3 and 4 are for that.
2. **Check the diffs:** each tag's diff from the harness tag touches only that team's folder.
3. **Scan the code.** Look for reads the information rule forbids:
   - `.player(` with another id, `players`, `ghost_`;
   - `units`, `spells`, `events`, `fights`, `recruit`, `seed_value`;
   - `Rng`, `record`, and private `_` fields of the session.

   Also look for:
   - `static var`, `class_name`, `Engine.set_meta`, `Thread`, `WorkerThreadPool`;
   - file access and `OS.` calls;
   - `GameSession.create`, `ContentSet`, `GameContent`, `get(`, `call(`, `Expression` and `load(`. Building a game from the readable core is one way to work out the seed.

   The same names are searched in the native source, where they appear as calls into Godot objects. A hit isn't proof: the referee reads the code.
4. **The opposing audit:** after each match, each team may file complaints about the other's published code, with the line and the reason. The referee rules, and tells both teams. A confirmed cheat forfeits that match, and the clean bot replays it.
5. **Harness health:**
   - the colour-swap pairs and the A/A baseline;
   - the soak's round checks on 1 game in 10;
   - refused actions, clock-outs and faults counted per team;
   - games that hit the 50-round limit, and draws.

   Anything odd stops publication until the referee explains it.

## 9. Stats in every match report

**Score:**
- each team's average placement with a 95% interval;
- the red-minus-blue gap with its interval;
- the winner, and whether the gap is outside the noise.

**Distribution, per team:** the rate of each place 1st to 8th, the top-4 rate and the win rate.

**Cards: what strong bots really think of them.** For every unit, per team and both together, counting only shops where the card was buyable:
- **offered-to-bought rate** by round band (rounds 1–3, 4–6, 7–9, 10–12, 13+), and by the buyer's **final** main tribe. This shows, for example, how often bots that end up as Badgers buy Pigeon tier 1 units. A board's main tribe at the time of an early buy is noise, because it has only 0–3 units;
- where a bot gives `report()`, its **value rank** for the card within the shop it was offered in. Raw values from `report()` aren't comparable between teams, because each team uses its own scale. Ranks and buy rates are;
- **never bought** (or under 2% when buyable), and **always bought** (over 80% when buyable, for every final main tribe);
- Discover pick rate against the options offered;
- lift: its presence on the final board against placement, within its tribe and round, as in the balance pass;
- golden rate.

**Tribes and commitment:**
- **main-tribe share:** how often each tribe is the final board's main tribe, per team. A tribe strong bots won't play shows here;
- average placement, top-4 and win rate by final main tribe, with each interval (it depends on how often the tribe is played);
- commit round by tribe, and whether a triple, a golden unit or a slot buff came in the round before it (the harness sees these);
- pivot rate, and the placement of boards that pivoted;
- **mixed boards:** the share of final boards with 2 or more units from outside the main tribe, and their placement;
- fight win rate by stage, by main tribe;
- main tribe against main tribe from round 7;
- median board stats and tier by round;
- gold left unspent by round;
- strategy use, per team only (each team names its own): how often each strategy is played, and its placement;
- how often each bot buys its own highest-valued card. This describes the bot; it isn't a cheat check.

Because each team puts its effort where it gains most, a tribe both teams neglect looks weaker than it is. So read each tribe's numbers from the team whose bot plays it better as well, and say where both teams' notes show little effort on a tribe.

**The balance pass's specific checks:**
- the Colonel's hand size at each fight, and win rate by hand size;
- the Briars' Compost size by round;
- Gleaners on board, and friendly deaths a fight;
- the Badgers' Outnumbered count at fights;
- sells per game, on purpose or to make room;
- Granary Glutton and Gorger eats;
- Colour Sergeant and Sergeant Major slot growth.

**Health:** seconds a game, clock-outs, faults, refused actions, replay mismatches and draws.

**Anchor** (after match 3 only): each final bot's average placement against the `TribeBot` field.

**Across matches:** how each card's buy rate and each tribe's numbers move as the bots get stronger. If a gap shrinks as play improves, the naive bots overstated it; if it grows, they understated it.

## 10. Hand-over

- **Each team:** its three tagged bots, their data and their `NOTES.md` files.
- **The referee:**
  - `docs/workstreams/bot-league/results.md`, written to the house rules (plain, most important first);
  - the per-match stats files;
  - a log of rulings and bugs;
  - the morning pack, if any part ran while the owner was away (the `overnight-run` skill).

**`results.md` has three parts.** The same three parts, with that match's numbers, go in every match report.

1. **The ten findings** from [balance-pass-18-nov/findings.md](balance-pass-18-nov/findings.md). For each one it says whether the finding is confirmed, weaker, stronger or reversed under the final bots. It puts the numbers from match 3 next to the naive column (the `TribeBot` A/A match on the same harness) and those from matches 1 and 2. It says plainly that "placement by final main tribe" is not the same measure as the naive bots' "seat locked to a tribe". Free bots commit to a tribe when it is going well, which flatters the tribes they commit to.
2. **The card verdicts.** Cards strong bots never buy, and how each team ranks them in the shop. Cards bought whatever the tribe. Cards the two teams' ranks or buy rates disagree on most. Each with the numbers.
3. **Tribes:**
   - the main-tribe shares and ranking under strong bots;
   - when and why bots commit;
   - how often mixed boards win.

Then it gives:
- new findings: strategies the strong bots found that naive ones missed;
- the anchor result;
- the rules-core bugs found;
- what still can't be judged. For example: the build has live lobbies but the real game will be asynchronous, there are no heroes, and bots play no better than their teams could make them in a day.

**One PR into `dev`** carries the harness, the baselines, both teams' final bots with their source, and the results. It changes no card numbers and nothing in `src/core`. Nothing goes to `main`.

**Clean up:** once the PR is open and the records are kept, remove the clones and the leftover worktrees. Large data goes to R2 through `tools/assets/`, not Git.

**Follow-ups to offer, not run:**
- the same final bots on `night/ambush` (the Mice change), to measure it;
- the final bots as the game's opponents in place of `FlowBot`;
- a native port of the rules core, the only way to cut the 2.5-second floor of every game, checked against the GDScript core by replaying records;
- the rebalance itself, from `results.md`.

## 11. Timeline

| Step | Wall time |
|---|---|
| Phase 0: harness, native bot proof, A/A test (the naive column), planted cheats, both gates; then stop for the owner | about 4 hours |
| Round 1, then match 1 and its checks; then stop for the owner | 4 hours + about 1 hour |
| Round 2, then match 2 | 3 hours + about 1 hour |
| Round 3, match 3, then the anchor | 3 hours + about 1.5 hours |
| Results and hand-over | about 1 hour |

That is about 18.5 hours of running, plus the owner's two stops: a night and a day. The dials are round length and the thinking clock. Shorter rounds make it faster and the bots weaker. The clock now costs little: going from 1 second to none would save about 30 minutes a match, but would leave matches with no end time.

## 12. Choices the owner should check

1. **Live 4-against-4 lobbies from game one, with no ghost warm-up.** The build plays all eight seats live, so the warm-up isn't needed. A ghost field would decide open rule 2.1.5 (how async play matches snapshots) inside a test harness. If the owner wants the stats to reflect async play anyway, phase 0 grows: a snapshot pool by round, seeded from 100 uncounted games, as the owner described.
2. **The match bot must be native: Rust or C++, as a GDExtension** (section 5a). Prototypes and offline tools may be in anything. The rules core stays GDScript, so a native bot speeds up its own thinking, not the game. C++ is allowed alongside Rust because both are installed and both bind to Godot.
3. **The time dials:**
   - rounds of 4, 3 and 3 hours;
   - 1 second of thinking per seat per game, down from 3, as a ceiling;
   - about 18.5 hours in all.
4. **Copying is allowed:** each team may lift the other's code and data after a match.
5. **Teams skip the merge gates inside a round** (section 4), or every team plan would wait on the owner mid-round.
6. **Two stops for the owner:** after phase 0 and after match 1. Matches 2 and 3 only report.
