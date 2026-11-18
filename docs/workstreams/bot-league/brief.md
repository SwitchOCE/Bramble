# Bot league: red team against blue team

**Status: approved by the owner as written, 18 Nov 2026 (fourth revision). Nothing run yet.** The section 12 defaults hold: the clock is picked at the phase 0 stop, and the Rust engine stays on `league/engine`. It has free play, a method swap in place of a code swap, and a Rust port of the engine as the referee's first job. It is written for the session that will run the league (the **referee**), which starts the two team orchestrators.

## 1. Why

On 18 Nov an Opus agent did a bounded balance pass on `dev` (8f55bcca): [balance-pass-18-nov/findings.md](balance-pass-18-nov/findings.md), with its probe scripts beside it (`tribe_lobby.gd.txt`, `duel.gd.txt`; drop `.txt` and put them in `tools/checks/` to run them). Its full transcript is outside Git at `/home/alex/.claude/handoff/bramble-balance-2026-11-18/balance-agent-transcript.jsonl`.

It found Pigeons far ahead (average place 3.2 in 455 tribe-locked lobbies) and Mice far behind (6.2), with several uncapped cards (Colour Sergeant, the Colonel's Reserve, Gleaner). But it warned that its bots were naive: tribe-locked, greedy, never selling on purpose, never stocking the hand for the Colonel, never feeding the Compost or planning around Outnumbered. So its numbers are a first read, not something to rebalance from.

The owner wants better bots built under competition, so the balance numbers can be trusted. The owner's words, 18 Nov 2026, in full:

> "Okay, I think I want you to write me a brief based on that agent's findings regarding balance. And I want to take a red team, blue team approach where we have two orchestrators who are each running their own team whose goal it is to make the best bot possible. And they can do anything they want to make the bot's win rate go up, and should. And their job is to put that bot against the other team's bot after maybe a certain number of tokens or something, maybe. I don't know what the best limit is. Time, tokens, something? Runs? I'm not sure. And then they're allowed to look at each other's bot's code and then go back to the drawing board and iterate. Once they've done a single pass, and once they've done three passes, three matches, and the bots can, I don't know, have 1,000 simulated games or something. I'm not sure what a good sample size is that strikes the balance between reliable but not overkill. And I guess the population needs to come in slowly, I guess, because you need to have an existing field of ghosts to play against of the bot strength. Probably need to, like, the first 100 games are just played against random bots, and then they don't count. And then once we've got enough ghosts of each of the bots, the lobby should be comprised of 4 of each, and the average placement, I guess, of each team's bots at the end will determine the winner. And we can look at stuff like distribution and stuff as hints as well. But yeah, I want to get stats from this basically, and I want it to be opposed. The teams are competing against one another. So give me a prompt to set that up."

On the first version, which locked each seat to one tribe, the owner said (18 Nov 2026; filler removed):

> "I do not approve this as written. Seats should not be locked to a tribe. Playing a tribe well is also about knowing how to play the early game. And you can't always only buy units from one tribe. That will cause a lot of waste, and the ghosts will be far *[probably "the boards will be far weaker"; unclear as heard]*, and the bots will be far weaker because of it. If the bots are only buying units from one tribe, that's a design where the balance is bad, which is exactly what this is supposed to help fix. And if some tier 1 units are really good tempo, and everyone always buys the Pigeon units on tier 1, even if they're playing Badgers, because the Pigeon tier 1 units are better than the Badger tier 1 units, always, under all circumstances, that's a problem we want to know about, right? So I don't want it made like that, because that won't highlight the problems.
>
> I would also prefer that the bots operate like an engine, in that they have tables with values, and they make assessments of the position, or calculate. And maybe strategy tables as well, to know when to vary, and the concept of committing to a specific tribe at some point. So they can understand: at this point, this is the strongest strategy for me, and I've hit these powerful effects, off an early triple, which pushes me in one direction or whatever. Kind of like how a real player would play. I don't want them locked to one tribe. That will cause bad results. If, in picking which tier 1 units to buy, there's the equivalent of value tables, like a chess engine or a Scrabble engine would use, and they never buy one unit ever, it's got a weighting of 0 or something: that's the most perfect information we could get. So no, I do not want them locked to one tribe. Rewrite the prompt."

After a Fable reviewer judged the third revision against the owner's goal, the owner said (18 Nov 2026):

> "Their goal is to build the strongest engine possible. My ideas are just potential avenues they might want to investigate. If they can build a better bot that beats that kind of approach, go for it. Their goal is to win against the other team."

> "[The goal of] this experiment … is to build strong bots. And my idea is that we're building strong bots by having it be an opposed situation, because competition should hopefully force the agents to innovate rather than getting stuck without a hill climbing operation."

> "Okay, don't give the teams code swapping then, I guess. Just give them like method swapping, right? We use this method, right? Like a loose high-level method swap, and the referee can be in charge of explaining the method, but not all the particulars and the details of the execution."

The owner then agreed to the rest of the reviewer's changes, as recommended to them: "Everything else I agree with you can apply." Those changes are:
- any language for the match bot;
- score-only practice matches against the other team in the middle of each round;
- checks that the bots are strong, not just better than each other;
- a report of where the two teams agree;
- longer rounds, with round 1 overnight.

And on the engine (18 Nov 2026):

> "We should absolutely port the real engine to Rust, though. We want the most performant situation. Like, surely that'll be far, far faster than whatever the rules engine we've currently got is. We don't want to have to use the game's client or a simulation thereof if we can avoid it, because we want absolute performance and nothing, as least friction as possible for fast iteration. The referee's first job is to port the engine to Rust, and the team should log any bugs they find with it immediately so that the referee can have it be fixed before resuming."

The port changes two of the points the owner agreed just before it:
- bots are written in Rust, against the Rust engine, not "any language";
- rounds are shorter, not longer, because practice games are now cheap (section 11).

**The goal:** strong bots, built under real competition, so the balance numbers from them can be trusted.

**What done looks like:**
- three matches played, and a winner;
- evidence that the final bots are strong;
- a results page that says, for each of the balance pass's ten findings, whether it holds under strong bots, with numbers;
- the strong bots' verdicts on every card: what they never buy, what they buy whatever tribe they're in, and when they commit to a tribe.

The league changes no card numbers. Rebalancing is a separate decision for the owner.

**The owner gets a usable read early.** The findings table and the card verdicts are filled in after every match. If match 1's read is enough, the owner can stop the league there.

## 2. The shape

- A **referee** (the session that runs this brief) **first ports the game's rules engine to Rust** from a pinned `dev` commit, and proves the port plays exactly like the GDScript engine. On that port it builds a match harness. It then starts the two teams, runs every match and practice match, fixes port bugs the teams report, checks for cheating, writes the method summaries, and writes the results.
- **Everything the league runs is Rust:** the engine, the harness and the bots. The game client and the GDScript engine are used only to check the port.
- **Red** and **blue** are each one Opus orchestrator session with its own helpers. Each builds the strongest bot it can. Their only goal: **a better average placement than the other team.**
- **Free play.** Every seat may buy any unit from any tribe, as a player can. All five tribes are in every lobby.
- **Three rounds.** Each round is a fixed time to build, with score-only practice matches against the other team partway through. It ends in an official match of 1,000 counted games. In every game, 4 seats are red bots and 4 are blue.
- **Method swap, not code swap.** After each match, the referee tells both teams, in a few paragraphs, how each bot works at a high level: its approach, not its numbers, tables or code. The teams never see each other's code. So they keep competing with different ideas, and where they reach the same verdict on a card, it is two independent reads.
- **Strength checks.** After each match the bots also play earlier versions and the naive baseline. After match 3 a fresh challenger tries to beat them, and the owner can play against them.

## 3. The owner's open questions: recommendations

| Question | Recommendation | Why |
|---|---|---|
| What limits a round: time, tokens, runs? | **Wall-clock time:** round 1 runs 6 hours; rounds 2 and 3 run 4 hours each. The clock stops while a blocking port bug is fixed. Both teams get **equal caps** on helpers and CPU (section 6). Tokens are not capped; each team reports what it used. | Time is easy to enforce and equal for both. With the Rust engine, practice games are cheap, so the agents' own build time is the limit, not compute. Claude and Codex tokens aren't comparable. |
| Sample size per match | **1,000 counted games**, played as 500 pairs: each seed twice, with the teams' seats swapped. | It gives each team's average placement to about **±0.05 places** (95%), and the red-minus-blue gap to **±0.11**. Per tribe it depends on how often strong bots play that tribe: a tribe that is the main tribe of 1 board in 5 gets about ±0.11 places, and 1 in 20 gets about ±0.22. A tribe almost nobody plays gets almost no numbers, and that is itself the finding. 500 games would give ±0.15 on the gap; 2,000 only ±0.08, for twice the time. |
| The warm-up and the ghost field | **No ghost warm-up.** Every official game is a live 8-seat lobby, 4 red and 4 blue, from the first game. The first 20 games of each match are a smoke run that doesn't count. | The build on `dev` plays all 8 seats live: every seat is a real bot taking its turns, so there is no empty field to fill. Live seats give the owner's "field of the bot strength" directly. A ghost field would mean designing how snapshots are matched, which is open rule 2.1.5 (async play), so the harness would be deciding a rule the owner hasn't. |
| Scoring | **Average placement of each team's seats over the 1,000 counted games. Lower wins the match. Two match wins out of three win the league.** The distribution and the stats in section 9 are hints. | It is the owner's measure. With 4 seats each in an 8-seat lobby, red's average plus blue's is always 9, so it is one fair number. |
| Iteration | **Three matches.** After each, both teams get the score, the pooled stats and the referee's method summary of both bots (section 7b). | The owner's choice: "a loose high-level method swap", so ideas cross over but teams stay independent. |

## 4. Roles

**Referee** (one Opus session; the session that runs this brief):
- ports the engine to Rust and proves it matches (phase 0, section 5b). It may use Codex workers and Opus sub-agents for this, one per part, as the codex-bridge says;
- builds the harness on the port, gets both through the gates, and freezes them;
- fixes port bugs the teams report, and releases each fix to both teams at once (section 6);
- sets up the two team folders and starts red and blue as side sessions, with the same team brief apart from the colour;
- answers both teams the same way: any ruling or harness fix goes to both at once;
- runs the practice matches and every official match, checks each match (section 8), and starts the next round;
- reads both bots in full after each match, and writes the method summaries (section 7b);
- runs the strength checks (section 7c) and writes the results (section 10);
- never helps either team with its bot. Before a match ends, it passes nothing from one team to the other except practice-match scores.

**Red and blue** (one Opus orchestrator each): may use Opus sub-agents and Codex workers on `gpt-6.1-sol` (Astra only under the codex-bridge's usage-limit rule), within the caps in section 6. Each team works only in its own folder and talks only to the referee.

Every session follows the owner's global rules: plain language, and long commands in the background with a time limit. Any unforeseen judgment call with no decision on record goes to a Fable advisor first.

The owner's merge gates apply to the referee's port and harness (section 5b) and to the final PR into `dev`. **Inside a team's timed round, the bot code needs no `plan-interrogate`, owner approval or scope review:** the matches and the referee's checks are its gates, and it lands nowhere until the final PR.

## 5. The bot: whatever wins

The owner: "Their goal is to build the strongest engine possible. My ideas are just potential avenues they might want to investigate. If they can build a better bot that beats that kind of approach, go for it."

So **no design is required**. Free buying is the only fixed point: no tribe lock anywhere, and any seat may buy any unit at any time.

**Avenues the owner suggested, for teams to weigh against anything else:**
- engine-style play, "like a chess engine or a Scrabble engine": card value tables, an assessment of the position, calculation;
- strategy tables that say when to vary, when to commit to a tribe, and what pushes it (an early triple, a powerful effect hit);
- playing the early game well, buying tempo units from any tribe.

**The card verdicts don't depend on how the bot is built.** "Never bought" and "bought by every tribe" come from the harness's log of every shop and every buy (section 5b, point 6).

**`report` is optional.** A bot that keeps card values can report them: whenever it sees a shop or a Discover choice, the harness calls the bot's `report`, times it on the bot's clock, and logs:
- its value for every card on offer, not only the one it buys;
- its current strategy name.

This adds the bot's reasons to the verdicts. A bot without it logs nothing there.

### 5a. What to write the bot in

**Match bots are Rust**, written against the harness's `Bot` trait in the referee's crate (section 5b). They run in the same fast engine as the matches, so self-play and lookahead cost little. Rust 1.100 (stable) is installed on the Optiplex in `~/.cargo/bin`, which isn't on the default `PATH`.

**Prototypes and offline tools can be in anything.** That covers Python for trying ideas, log analysis and weight searches. Their results go into the bot's folder as data. "Performant enough" for the match bot means it doesn't waste the clock or the machine. It doesn't mean tuned to the last cycle.

**Rules for a team's crate:**
- `#![forbid(unsafe_code)]`;
- no `static`, `static mut`, `thread_local!`, `OnceLock`, `lazy_static` or `once_cell`, and no atomics. Seats must share nothing;
- no `std::thread`, `std::fs`, `std::net`, `std::process` or `std::env`, and no reading the time;
- no `extern`, `#[no_mangle]` or `asm!`;
- crates only from the referee's vendored allowlist. Builds run `--offline --locked` with `CARGO_BUILD_JOBS=2`;
- no `build.rs` and no proc macros of the team's own, and no `include!`, `include_str!`, `include_bytes!` or `#[path]` that points outside the team's folder;
- the referee builds each team's crate in a tree that holds only the engine, the harness and that team's folder, so one team can't compile in the other's code;
- the referee builds every bot from source at the match tag. A pre-built binary doesn't count.

### 5b. Phase 0: the Rust engine and the harness, built by the referee and then frozen

**Pin the build.** Use the `dev` commit at the start (write its SHA in the run notes). Make branch `league/engine` from it. All of the league's code lives in one Rust workspace under `tools/league/`, outside the Godot project's export.

**1. Port the engine.** The referee ports the GDScript rules engine to a Rust crate, `bramble-engine`. It covers:
- the rules core (`src/core`, about 5,100 lines of GDScript): rules and config, recruit phase, shop and pool, triples and Discover, board and slots, combat, deaths and summons, matchmaking, eliminations and placements, and the seeded random streams (`Rng`), bit for bit;
- the five tribes' mechanics (`src/content/*/mechanics`, about 1,600 lines in 100 small scripts);
- the card data, read from the same `units.json` files the game ships, plus the game's 3 stand-in spells. The engine loads cards; it doesn't copy their numbers into code.

The referee splits the work by part (combat, recruit, each tribe's mechanics), with one Codex worker or sub-agent each, and owns how the parts fit together. It is a real project, roughly 7,000–10,000 lines of Rust. Phase 0 is planned at about **16–24 hours** (section 11). The parts must be done in order:
1. a skeleton: unit ids, the mechanic trait, a serializer shaped like Godot's, and the random streams;
2. combat (about 2,100 GDScript lines) and recruit (about 1,300), in parallel;
3. the 100 mechanics, which need the combat and recruit interfaces first (49 hooks);
4. hash debugging, which is the long tail.

The state hash covers every GDScript field, private ones included (`_next_uid`, the pool's `_copies` and `_order`, `Rng._s`, `MechanicParams`, the `UNSET` stat values), plus exact refusal strings and fight payloads. The port must mirror them all. Where it is easy to go wrong:
- dictionary insertion order in game logic;
- loops over arrays that change mid-loop;
- units shared by reference (`ghost_board` is a shallow copy);
- the sort used for tie-breaks, which must be stable.

If one field truly can't be matched, the fallback is a projected hash computed by a GDScript tool, with action results and fight payloads still matched exactly.

**The owner's stop reports these milestones:** skeleton, combat, recruit, mechanics per tribe, records matching both ways, fights matching, harness built.

**2. Prove it plays exactly like the GDScript engine.** The game's records make this checkable. Each record holds a seed, every action, and a SHA-256 hash of the full rules state three times a turn (`src/core/records/README.md`).
- **GDScript to Rust:** the GDScript engine plays 1,000 bot games with records (`scripts/records.sh games=1000`). The Rust engine replays every record, and every state hash must match.
- **Rust to GDScript:** the Rust engine plays 50 games with its baseline bots and writes records in the same format, with the pinned build's fingerprint in the header, because the GDScript replay refuses any other. `scripts/records.sh record=...` replays them in GDScript, and every hash must match.
- **Fights:** at least 100,000 fights on boards made by changing real `fight_boards` payloads from records (swapping units, golden flags, slot buffs, heap sizes, Reserve hands), across all five tribes. Both engines must give the same winner, the same damage, and the same state for both sides after the fight, compared with the records' serializer. Combat event logs aren't compared: they're outside the hash, and nothing in the league reads them.
- **Planted bugs:** change one number in the Rust port, such as a card's Attack or a refresh's cost. The checks must catch it.

These checks also run again for every port fix during the league.

**Hash debugging:** a hash mismatch says nothing about where the two engines differ. So both sides can dump the JSON a hash is computed from, at the first mismatch, to diff. The GDScript side of that dump, and the GDScript side of the fight comparison, live in `tools/league/gd/`, not in `src/`. Pin Rust 1.100 in `tools/versions.env`, where every toolchain version lives.

**3. Measure the speed-up**, against the GDScript engine on the same machine: a whole game with simple bots, and a late-game fight. The owner expects it to be "far, far faster". Expect tens of times faster, but give the measured figure, not a guess.

**4. The harness**, a Rust binary, `league`:
1. **Plays a match:** `league match --red <crate> --blue <crate> --games 1000 --seeds <file> --clock-ms 1000`. The same command plays practice matches and strength checks with other crates and game counts. It runs games in parallel, one per thread, up to the core limit it is given.
2. **The `Bot` trait.** A bot gets a read-only `BotView` and returns an action from the legal list. Optionally, it reports its card values. Each seat gets a fresh bot each game. The view holds only what a player may know:
   - the bot's own state;
   - every player's health, armor, tier and whether they are alive;
   - who it fights next;
   - the full fight payload of each past opponent at the time they fought: board, slots, counters, heaps and Reserve hand;
   - the card library and the rules.

   The bot never touches the game itself, so it can't read other players' hands, shops, gold or the pool, or the seed, and it can't change anything. Rust's types enforce the information rule.
3. **Lookahead through the harness:** a `Sim` handle that:
   - runs real-engine fights on boards the bot may know, with fresh seeds;
   - tries recruit-phase moves in a **sandbox**, built so it can't leak:
     - a copy of the bot's own player;
     - the other players as their last fight payloads;
     - an estimated pool (the start counts minus the cards the bot can see), not the real one;
     - shop and Discover draws from the bot's own random stream, never the real recruit streams;
     - nothing written back.

   The real pool counts would show what other players hold, and the real recruit streams would predict the next refresh exactly.
4. **Seats and seeds:** 4 seats are red and 4 blue, shuffled per seed pair from the match secret, so a bot can't tell its teammates from seat numbers (the owner's pick at the phase 0 stop, 18 Nov: "Yes, take all four" ([phase0-handover.md](phase0-handover.md)); this replaces "seats alternate red and blue"). Every seed is played twice with the colours swapped. All five tribes are in every lobby, as in the shipped game.
   - Seeds are random numbers, listed in the seeds file.
   - Each bot's random stream isn't derived from the game seed, so no bot can work the seed out.
5. **The thinking clock:** each seat gets **1 second of thinking per game** (the owner's pick at the phase 0 stop, 18 Nov: "Yes, take all four" ([phase0-handover.md](phase0-handover.md)); this replaces 250 ms), measured as thread CPU time, not wall time, so load on the machine doesn't decide clock-outs. It is timed around every call into the bot, the bot's construction included. When the clock runs out, the harness plays the rest of that seat's game with a simple baseline bot and logs a clock-out.
   - `BotView` shows the time left, so a search can stop in time.
   - Tables may be built into the crate (`const`, `include_bytes!` of the team's own files), so a bot doesn't have to parse them every game.
   - Measured in phase 0: about 110 decisions a seat a game, so 1 second is about 9 ms a decision, about 15 late lookahead fights (250 ms would have been about 4). A 1,000-game match takes about 23 minutes on 4 cores, and a practice match about 43 minutes on 2.
   - The clock is a ceiling, not a cost. Without it, a match has no end time and the two teams aren't on equal compute.
   - Phase 0 checks the figure against the measured speed of a fight.
6. **Logs**, in JSON:
   - every game, as a record in the GDScript format;
   - one stats line per game;
   - one line per shop a bot saw, with each card marked **buyable** (affordable, with room in the hand) or not, beside what was bought;
   - one line per Discover choice;
   - each `report`.
7. **Works out each board's tribe from the game state:**
   - the **main tribe** is the one with the most units, with ties going to the higher total stats;
   - the **commit round** is the first round with 4 or more units of the final main tribe;
   - a **pivot** is when, after the commit round, another tribe reaches 4 or more units and becomes the main tribe.
8. **Baselines, ported from GDScript:** `SimpleBot`, `FlowBot`, `RandomBot` and the balance pass's `TribeBot`. They are the only tribe-locked bots, and they never count. In a match, `TribeBot` on seat `s` plays tribe `(s + game seed) % 5`, as the balance pass did, so all five tribes are in every lobby (the owner's pick at the phase 0 stop, 18 Nov: "Yes, take all four").
9. **`league analyze`:** every stat in section 9, with 95% intervals. Phase 0 needs only the score and the health checks; the referee writes the rest during round 1.

**Gate before freezing** (the owner's two gates):
- **Runtime:**
  - all the port checks in step 2 pass;
  - `cargo test`, plus `scripts/check.sh` on the Godot project, whose `src/` is unchanged;
  - an **A/A match** with `TribeBot` on both colours, 1,000 games, shows a red-minus-blue gap within ±0.11. It also gives the **naive column** for the results;
    *[Referee, 18 Nov: with TribeBot's tribe by seat, TribeBot plays both games of a pair the same, so its A/A gap is 0 by construction. The harness check also runs an A/A with `RandomBot`, whose play differs between the two games.]*
  - colour and seat balance is checked;
  - a planted cheat is caught: a bot crate that uses `unsafe` or a `static` fails the build check, and so does one that reaches into the other team's folder;
  - a sandbox refresh doesn't equal the real next refresh;
  - a bot that sleeps past its clock produces a clock-out.
- **Scope review:** a fresh `scope-reviewer` on the engine and harness commits, given the owner's words above and this brief.

**Stop for the owner:** show the port's check results, the measured speed-up and the A/A result, in a few lines. Start the teams on the owner's go. Then tag `league-engine-v1`.

## 6. The rules for teams

**Isolation.** Each team works in its own clone, not a worktree of the shared repo, so the other team's commits never show in `git log --all`:
- the clones are `/home/alex/league/red` and `/home/alex/league/blue`, cloned from the engine tag on branches `league/red` and `league/blue`;
- teams don't push; the referee fetches their tags straight from the clones;
- a team reads nothing outside its own clone, the pinned build, its own Codex worktrees, and what the referee gives it (section 7b);
- each team's bot is a crate in `tools/league/bots/<colour>/`, registered at the engine tag. The folder also holds `data/` and a `tools/` crate for the team's own self-play and analysis, which the bot can't reach and the referee never builds (the owner's pick at the phase 0 stop, 18 Nov: "Yes, take all four"; see `tools/league/league/README.md`).

The other team's code, data and notes stay private until the league is over.

**Allowed: anything that raises the bot's placement, inside its own folder.** For example:
- any design: value tables, search, simulation, rules of thumb, weights tuned offline by self-play;
- strategy per tribe and across tribes: when to stay open, when to commit, when to pivot;
- buying any unit from any tribe: tempo units early, mixed boards, a splash of another tribe's engine;
- self-play and lookahead with the Rust engine, through the harness's `Sim`;
- selling on purpose, stocking the hand, planning around Outnumbered and the Compost;
- using any card the way its text and the rules allow, however strong;
- building on the other team's methods as the referee describes them.

**Not allowed:**
- changing anything outside its bot folder: the Rust engine, the harness, the GDScript game (`src/`), the cards, tests or baselines;
- reaching game state any way other than the `BotView` and `Sim` the harness hands it;
- breaking the crate rules (section 5a);
- passing anything between seats or between games during a match;
- detecting which seats are teammates or which bot is on a seat, other than through what it plays;
- trying to get the other team's code or notes, by any route;
- using a bug in the engine or the harness.

**Port bugs: report at once.** The owner: "the team should log any bugs they find with it immediately so that the referee can have it be fixed before resuming." A port bug is any place where the Rust engine plays differently from the GDScript game, or from what the card's text and the rules say. When a team finds one, it tells the referee at once, with a seed and the actions that show it. Then the referee:
- checks it against the GDScript engine;
- fixes the port if the two differ, and reruns the port checks (section 5b, step 2);
- releases the fixed engine, `league-engine-v<n>`, to both teams at once. The note names only the engine area (for example "combat: death order"), never what triggered it or which team found it, because that could give away what a team is working on.

A bug that blocks a team's work stops **both** teams' round clocks until the fix is out, then both resume. A bug that doesn't block anyone is fixed and released without stopping the clock. If a fix changes how games play, any official match it touched is played again on the fixed engine.

If the Rust engine and the GDScript engine agree, but both differ from a card's text, it's a bug in the game, not the port. The referee logs it for the owner and rules for both teams whether exploiting it is allowed. The engine isn't changed for it during the league.

**Equal caps for each team**, all at once:
- the orchestrator, at most 2 Opus sub-agents, and at most 2 Codex workers;
- at most 2 cores for everything the team runs: practice games, builds and its helpers' commands. This drops to 1 core while a practice match against the other team runs (section 7a). The referee enforces it by running each team's sessions inside a CPU-limited group (`systemd-run --scope -p AllowedCPUs=...`, or `taskset`). If that can't be set up, the brief says the caps are on trust.

The Codex plan pool is shared, so if Sol hits its limit, the referee moves both teams to Astra together.

**Hand-in at a round's deadline:** a commit tagged `red-m<n>` or `blue-m<n>` in the team's clone. Its diff from the engine tag must touch only `tools/league/bots/<colour>/`, and it includes `NOTES.md` in that folder, for the referee only until the end:
- how the bot plays: its strategies, when it commits and why, and how it plays the early game;
- the cards it values most and least, with its reasons;
- where the round's effort went, tribe by tribe;
- what changed since the last match and why, and what it took from the other team's method summary;
- the bugs or exploits found;
- the tokens and Codex runs used.

A late tag, or a diff outside the team's folder, means the team plays that match with its previous tag (round 1: `FlowBot`).

## 7. A round and a match, step by step

### 7a. Practice matches during a round

The owner's theory is that opposition forces innovation where a lone agent gets stuck hill-climbing. So the teams meet partway through each round, not only at its end:
- **round 1:** at about 2 hours and about 4 hours;
- **rounds 2 and 3:** at the halfway point.

Each practice match works like this:
- each team tags its latest commit `red-s<n>` / `blue-s<n>`;
- the referee plays 1,000 games, 4 seats each, with seed pairs, using 2 cores (one from each team's practice cap). At Rust speed that should take minutes;
- both teams get **only the score**: each team's average placement and the gap, with intervals. No stats, no method.
- It doesn't count toward the league.

### 7b. An official match

1. **Check the machine** (section 7d). Fetch both tags from the clones. Check each diff is limited to the team's folder, and build both crates from source into the frozen workspace.
2. **Smoke run:** 20 games, not counted. On a crash or a fault in a bot, the referee tells that team, which gets 30 minutes to fix only that. The other team is told the same.
3. **Counted run:** 1,000 games (500 seed pairs). The seeds are fresh for each match and not announced beforehand.
4. **Verify** (section 8).
5. **Write the method summaries.** The referee reads both bots and both `NOTES.md` files, then writes one summary per team, about 150–300 words each:
   - the kind of bot (for example "card values by stage, plus a one-fight lookahead");
   - how it chooses and commits to a tribe, and how it plays the early game;
   - what is new since the last match.

   It leaves out the numbers, weights, thresholds, card-by-card values, table contents and code. The owner: "a loose high-level method swap … not all the particulars and the details of the execution." Both teams get both summaries, so each sees what was said about it.
6. **Give both teams, at once:**
   - the score and its interval;
   - each team's own stats, card by card, and its own seats' decision logs;
   - pooled numbers at tribe level only: tribe shares and placement by tribe;
   - the two method summaries;
   - the start of the next round.

   The referee keeps the full records, all pooled card-level stats and the agreement section. Pooled card rates minus a team's own would give the other team's buy rates card by card, which is execution detail.
7. **After match 1, stop for the owner** with a few lines:
   - the score;
   - the first findings table and card verdicts;
   - the strength check;
   - each tribe's share of final boards. If a tribe is the main tribe of fewer than 5% of them, findings about it can't be judged (for Mice, Locusts or Badgers, findings 5–7). Offer an unscored probe for that tribe, and build it only if the owner says yes.

   Start round 2 on the owner's go. They may stop the league here.
8. **After matches 2 and 3, tell the owner the score in one line, and don't wait.** Stop and ask only for:
   - a confirmed cheat;
   - a harness bug that changes a result;
   - a busy machine;
   - a Codex limit on both models.

### 7c. Strength checks: are the bots strong, or just better than each other?

These don't count. Each uses 4 seats of the bot being tested against 4 seats of the opponent.

- **After every match:** each team's new bot plays 200 games against `TribeBot` (the naive bots), and against each earlier tag of both teams. It shows progress from round to round, and whether a bot only learned to beat the other team's habits.
- **Behaviour checks, from the findings:** do the bots stock the hand for the Colonel, feed the Compost, sell on purpose, play around Outnumbered, and feed the Granary Glutton? The answers are read from the logs (section 9).
- **After match 3, the challenger:** a fresh Opus session that took no part in the league gets 3 hours, the same caps, and both final bots' source. Its job is to build a bot that beats the league's winner. Then 400 games, 4 seats each.
  - If it wins by more than about 0.5 places, the league's bots aren't strong yet, and the results say so.
  - If it can't beat the winner, that is the best evidence the bots are strong.
- **The owner plays them, if they want to.** The winning bot is a Rust crate for the Rust engine, so putting it in the Windows game needs a bridge: a GDExtension that turns the game's state into a `BotView` each turn. Offer it to the owner at the end, and build it only on their yes. If built, it goes on a throwaway branch that is never merged, and the zip goes to the owner's PC by Taildrop, to start with `Play-Bramble.cmd`.

### 7d. Compute

The machine is the owner's always-on Optiplex: 6 cores, about 14 GB of memory, shared with other agents. The owner has said the half-the-cores rule is for the main computer, not the Optiplex. Still, before each match and before each team's first practice batch, check:
- the load (`uptime`);
- the memory (`free -g`, and committed memory in `/proc/meminfo`);
- what else is running (`ps -eo pid,pcpu,rss,etime,cmd --sort=-pcpu | head`).

During a round the teams use up to 4 cores between them. Official matches use up to 4 cores while the teams are paused. If the 1-minute load is above 3 before a match, or less than 3 GB is free, wait or ask the owner. On 18 Nov the load was already about 3.8 from other work.

**Cost.** The GDScript engine takes about 2.5–4.6 seconds a game, depending on load, and roughly 40 ms a late-game fight. Phase 0 measures the Rust engine against those figures. The bots' clock then sets the worst case: 8 seats × 1 s is 8 seconds a game, so a 1,000-game match takes about 23 minutes on 4 cores (measured; the clock was 250 ms when this was written). Most of a match's time will be the checks, chiefly replaying every game in GDScript, about 15–20 minutes (section 8).

## 8. Catching cheats and harness bugs

1. **Check the port on every match.** Replay every counted game from its record in the GDScript engine (`scripts/records.sh record=...`), about 15–20 minutes on 4 cores. Every hash must match. Strong bots reach states the baseline bots never do (stocked Colonel hands, big Compost, eat loops), and that's where port bugs that bend the numbers would hide. Any mismatch is a port bug: stop, fix it (section 6), and play the match again.
2. **Check the diffs:** each tag's diff from the engine tag touches only that team's folder.
3. **Check the crates.** Each must build with the crate rules (section 5a): `forbid(unsafe_code)`, the vendored allowlist, and `--offline --locked`. Search the source for the banned items in section 5a. The bot only ever sees a `BotView` and a `Sim`, so the types keep it from reading what it shouldn't. The search is for ways around the types.
4. **The referee reads both bots in full after every match.** It has to, to write the method summaries. A confirmed cheat forfeits that match, and the clean bot replays it. Since the teams can't see each other's code, a team that suspects the other from the scores or the summaries may ask the referee to look at something specific.
5. **Harness health:**
   - the colour-swap pairs and the A/A baseline;
   - clock-outs, faults and panics counted per team. A bot that panics loses that seat's game to the baseline bot, and the panic is logged;
   - games that hit the 50-round limit, and draws.

   Anything odd stops the results until the referee explains it.

## 9. Stats in every match report

**Score:**
- each team's average placement with a 95% interval;
- the red-minus-blue gap with its interval;
- the winner, and whether the gap is outside the noise.

**Distribution, per team:** the rate of each place 1st to 8th, the top-4 rate and the win rate.

**Cards: what strong bots really think of them.** For every unit, per team and both together, counting only shops where the card was buyable:
- **offered-to-bought rate** by round band (rounds 1–3, 4–6, 7–9, 10–12, 13+), and by the buyer's **final** main tribe. This shows, for example, how often bots that end up as Badgers buy Pigeon tier 1 units. A board's main tribe at the time of an early buy is noise, because it has only 0–3 units;
- where a bot gives `report()`, its **value rank** for the card within the shop it was offered in. Raw values aren't comparable between teams, because each team uses its own scale; ranks and buy rates are;
- **never bought** (under 2% when buyable), and **always bought** (over 80% when buyable, for every final main tribe);
- Discover pick rate against the options offered;
- lift: its presence on the final board against placement, within its tribe and round, as in the balance pass;
- golden rate.

**Where the two teams agree.** The teams never see each other's code, so their verdicts are independent reads. Say which cards and tribes both teams' bots rate the same way, such as both never buying a card or both committing to a tribe early. Also say where they disagree most. Agreement is the strongest sign a verdict is real.

**Tribes and commitment:**
- **main-tribe share:** how often each tribe is the final board's main tribe, per team. A tribe strong bots won't play shows here;
- average placement, top-4 and win rate by final main tribe, each with its interval;
- commit round by tribe, and whether a triple, a golden unit or a slot buff came in the round before it (the harness sees these);
- pivot rate, and the placement of boards that pivoted;
- **mixed boards:** the share of final boards with 2 or more units from outside the main tribe, and their placement;
- fight win rate by stage, by main tribe;
- main tribe against main tribe from round 7;
- median board stats and tier by round;
- gold left unspent by round;
- only for bots that give `report()`: strategy use per team, and how often each bot buys its own highest-valued card.

A tribe both teams neglect looks weaker than it is, because each team puts its effort where it gains most. So read each tribe's numbers from the team whose bot plays it better as well. Say where both teams' notes show little effort on a tribe.

**The balance pass's specific checks**, which are also the behaviour checks in section 7c:
- the Colonel's hand size at each fight, and win rate by hand size;
- the Briars' Compost size by round;
- Gleaners on board, and friendly deaths a fight;
- the Badgers' Outnumbered count at fights;
- sells per game, on purpose or to make room;
- Granary Glutton and Gorger eats;
- Colour Sergeant and Sergeant Major slot growth.

**Strength:** each bot's placement against `TribeBot` and against earlier tags (section 7c); after match 3, the challenger's result.

**Health:** seconds a game, clock-outs, faults, refused actions, replay mismatches and draws.

**Across matches:** how each card's buy rate and each tribe's numbers move as the bots get stronger. If a gap shrinks as play improves, the naive bots overstated it; if it grows, they understated it.

## 10. Hand-over

- **Each team:** its three tagged bots, their data and their `NOTES.md` files.
- **The referee:**
  - `docs/workstreams/bot-league/results.md`, written to the house rules (plain, most important first);
  - the per-match stats files and the method summaries;
  - a log of rulings and bugs;
  - the morning pack, if any part ran while the owner was away (the `overnight-run` skill).

**`results.md` starts with whether the bots are strong:**
- the challenger's result;
- the progress ladder;
- the behaviour checks;
- the owner's impression, if they have played.

Then come three parts. The same three parts, with that match's numbers, go in every match report.

1. **The ten findings** from [balance-pass-18-nov/findings.md](balance-pass-18-nov/findings.md). For each one, it says whether the finding is confirmed, weaker, stronger or reversed under the final bots. It puts the match 3 numbers next to the naive column (the `TribeBot` A/A match on the same harness) and next to the numbers from matches 1 and 2. It says plainly that "placement by final main tribe" isn't the same measure as the naive bots' "seat locked to a tribe": free bots commit to a tribe when it's going well, which flatters the tribes they commit to.
2. **The card verdicts.** For each, with the numbers:
   - cards strong bots never buy;
   - cards bought whatever the tribe;
   - where the two teams agree, and where they disagree most.
3. **Tribes:**
   - the main-tribe shares and the ranking under strong bots;
   - when and why bots commit;
   - how often mixed boards win.

Then it gives:
- new findings: strategies the strong bots found that naive ones missed;
- the rules-core bugs found;
- what still can't be judged. For example: the build has live lobbies but the real game will be asynchronous, there are no heroes, and bots play no better than their teams could make them in a day. The engine is a port: it matched the GDScript game on every game checked, which isn't proof it matches everywhere.

**One PR into `dev`** carries the results, the method summaries and the teams' notes. The engine, the harness and the bots stay on `league/engine` unless the owner says to bring them in (section 12). It changes no card numbers and nothing in `src/core`. Nothing goes to `main`.

**Clean up:** once the PR is open and the records are kept, remove the clones, the owner's throwaway build branch and the leftover worktrees. Large data goes to R2 through `tools/assets/`, not Git.

**Follow-ups to offer, not run:**
- the same final bots on `night/ambush` (the Mice change), to measure it;
- the final bots as the game's opponents in place of `FlowBot`;
- keeping the Rust engine as the project's fast simulator for later balance work, checked against the GDScript game by the same record replays whenever the game changes;
- the rebalance itself, from `results.md`.

## 11. Timeline

| Step | Wall time |
|---|---|
| Phase 0: port the engine to Rust, prove it against the GDScript engine, build the harness, A/A test, both gates; then stop for the owner | about 16–24 hours: a night and most of a day |
| Round 1, with 2 practice matches | 6 hours |
| Match 1, checks, method summaries, strength checks; then stop for the owner | about 1 hour |
| Round 2, with 1 practice match; then match 2 and its checks | 4 + 1 hours |
| Round 3, with 1 practice match; then match 3 and its checks | 4 + 1 hours |
| Challenger (3 hours) and its test | about 3.5 hours |
| Results and hand-over | about 1 hour |

That is about 37–45 hours, plus the owner's two stops and any clock stops for port bugs: about two days. The port is the part most likely to run long. If it does, phase 0 says how far it got at the owner's stop, rather than starting the teams on an engine that hasn't passed its checks.

Rounds are shorter than in the last draft because the Rust engine makes practice games cheap. Agent build time, not compute, is now the limit. The dial is round length.

## 12. Settled with the owner, and what is still theirs to check

Settled on 18 Nov 2026:
- free play;
- any bot design;
- a method swap, not a code swap;
- practice matches mid-round;
- strength checks;
- the agreement report;
- **the referee ports the engine to Rust first.** The league runs on the port, and teams report port bugs at once.

The owner also agreed to the earlier recommendations: no ghost warm-up, 1,000 games a match, teams skipping the merge gates inside a round, and two stops.

Agent calls inside those, for the owner to check:
1. **The port must match the GDScript game exactly**, hash for hash on recorded games (section 5b, step 2). The GDScript game stays the truth: where the two differ, the port is fixed. This is what makes balance numbers from the port count for the real game.
2. **Bots are Rust too, and see the game only through a read-only view.** This replaces most of the cheat checks with Rust's type rules.
3. **Clock and rounds:** rounds of 6, 4 and 4 hours. The clock is the owner's pick at the phase 0 stop: **1 second** (the owner's pick at the phase 0 stop, 18 Nov: "Yes, take all four" ([phase0-handover.md](phase0-handover.md))). The options were:
   - 250 ms per seat per game: about 1–3 lookahead fights a decision, and matches in minutes;
   - 1 second: about four times the search, with matches of about 35 minutes.
4. **A blocking port bug stops both teams' clocks** until it is fixed; other fixes go out without stopping.
5. **What teams get after a match:**
   - the pooled stats and their own per-team stats and logs;
   - not the other team's per-team numbers or decision logs, which would show execution detail.
6. **The challenger** gets both final bots' source, because the league is over by then.
7. **Playing the bots yourself** needs a bridge into the Windows game. It is offered at the end, not built by default.
8. **Whether the Rust engine goes into `dev`.** It is about 10,000 lines: a second rules engine beside the game's. The final PR shouldn't decide that by carrying it. The default is for it to stay on `league/engine`, and the PR into `dev` carries the results, the method summaries and the bots' notes. The owner may choose to bring the engine into `dev` instead.
