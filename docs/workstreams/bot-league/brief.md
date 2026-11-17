# Bot league: red team against blue team

**Status: proposal, 18 Nov 2026. Not approved, nothing run.** The owner approves this brief before anything starts. It is written for the session that will run the league (the **referee**), which starts the two team orchestrators.

## 1. Why

On 18 Nov an Opus agent did a bounded balance pass on `dev` (8f55bcca): [balance-pass-18-nov/findings.md](balance-pass-18-nov/findings.md), with its probe scripts beside it (`tribe_lobby.gd.txt`, `duel.gd.txt`; drop `.txt` and put them in `tools/checks/` to run them). Its full transcript is outside Git at `/home/alex/.claude/handoff/bramble-balance-2026-11-18/balance-agent-transcript.jsonl`.

It found Pigeons far ahead (average place 3.2 in 455 tribe-locked lobbies) and Mice far behind (6.2), with several uncapped cards (Colour Sergeant, the Colonel's Reserve, Gleaner). But it warned that the bots are naive: tribe-locked, greedy, never sell on purpose, never stock the hand for the Colonel, never feed the Compost or plan around Outnumbered. So the numbers are a first read, not something to rebalance from.

The owner wants better bots built under competition, so the balance numbers can be trusted. The owner's words, 18 Nov 2026, in full:

> "Okay, I think I want you to write me a brief based on that agent's findings regarding balance. And I want to take a red team, blue team approach where we have two orchestrators who are each running their own team whose goal it is to make the best bot possible. And they can do anything they want to make the bot's win rate go up, and should. And their job is to put that bot against the other team's bot after maybe a certain number of tokens or something, maybe. I don't know what the best limit is. Time, tokens, something? Runs? I'm not sure. And then they're allowed to look at each other's bot's code and then go back to the drawing board and iterate. Once they've done a single pass, and once they've done three passes, three matches, and the bots can, I don't know, have 1,000 simulated games or something. I'm not sure what a good sample size is that strikes the balance between reliable but not overkill. And I guess the population needs to come in slowly, I guess, because you need to have an existing field of ghosts to play against of the bot strength. Probably need to, like, the first 100 games are just played against random bots, and then they don't count. And then once we've got enough ghosts of each of the bots, the lobby should be comprised of 4 of each, and the average placement, I guess, of each team's bots at the end will determine the winner. And we can look at stuff like distribution and stuff as hints as well. But yeah, I want to get stats from this basically, and I want it to be opposed. The teams are competing against one another. So give me a prompt to set that up."

**What done looks like:** three matches played, a winner, and a results page that says, for each of the balance pass's ten findings, whether it holds under strong bots, with numbers. The league changes no card numbers. Rebalancing is a separate decision for the owner.

**The owner gets a usable read early.** The ten-findings table is filled in after every match, not only at the end. If match 1's table is enough, the owner can stop the league there.

**Plan check.** A fresh agent ran `plan-interrogate` on the first draft, given the owner's words. This version takes its fixes:
- closes four ways a bot could beat the harness rather than the game;
- drops the free-play exhibition, the spot-check hashing and the transcript search;
- runs the anchor once;
- adds two stops for the owner.

## 2. The shape

- A **referee** (the session that runs this brief) builds and freezes a match harness on a pinned `dev` commit, starts the two teams, runs every official match, checks every match for cheating and harness bugs, and writes the results.
- **Red** and **blue** are each one Opus orchestrator session with its own helpers. Each builds the strongest bot it can. Their only goal: **a better average placement than the other team.**
- **Three rounds.** Each round is a fixed time to build, then an official match of 1,000 counted games. In every game, 4 seats are red bots and 4 are blue. After each match, both teams get the other's bot code and the full match data, and the next round starts.

## 3. The owner's open questions: recommendations

| Question | Recommendation | Why |
|---|---|---|
| What limits a round: time, tokens, runs? | **Wall-clock time** (round 1: 4 hours; rounds 2 and 3: 3 hours each), plus **equal caps** on helpers and CPU (section 6). Tokens are not capped; each team reports what it used. | Time is the one limit that is easy to enforce, equal for both and keeps the matches in step. Claude and Codex tokens aren't comparable, and an orchestrator can't see its own total live. |
| Sample size per match | **1,000 counted games**, played as 500 pairs: each seed twice, with the teams' seats swapped. | It gives each team's average placement to about **±0.05 places** (95%), the red-minus-blue gap to **±0.11**, and each tribe's average placement to **±0.11** (both teams together) or **±0.16** (one team). 500 games would give ±0.15 on the gap; 2,000 only ±0.08 for double the time. The balance pass's tribe gaps were up to 3 places, and a gap worth acting on is about 0.3, so 1,000 resolves it with room to spare. |
| The warm-up and the ghost field | **No ghost warm-up.** Every official game is a live 8-seat lobby, 4 red and 4 blue, from the first game. The first 20 games of each match are a smoke run that doesn't count. | The build on `dev` plays all 8 seats live in one process: every seat is a real bot taking its turns, so there is no empty field to fill and no cold start. The owner's warm-up was to make sure bots meet a field of their own strength; live seats give that directly. A ghost field would also mean designing how snapshots are chosen and matched, which is open rule 2.1.5 (async play) in the rulebook, so the harness would be deciding a rule the owner hasn't. **Owner to check** (section 12). |
| Scoring | **Average placement of each team's seats over the 1,000 counted games. Lower wins the match. Two match wins out of three win the league.** The distribution and the stats in section 9 are hints. | It is the owner's measure. With 4 seats each in an 8-seat lobby, red's average plus blue's is always 9, so it is one fair number. The results say whether each margin is outside the noise. |
| Iteration | **Three matches.** After each, the referee gives each team the other's bot code at the match tag, the match records and the stats. Teams may copy from it, credited in their notes. | It is what the owner asked for. Copying is allowed because better bots on both sides give better balance numbers. |

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

## 5. Phase 0: the harness, built by the referee and then frozen

**Pin the build.** Use the `dev` commit at the start (write its SHA in the run notes). Make branch `league/harness` from it. Teams never change anything it contains.

**What the harness does:**

1. **Plays a match:** `godot --headless -s res://tools/league/match.gd -- red=<folder> blue=<folder> games=1000 first_seed=<n> clock=3`. It loads each team's bot from its folder under `tools/league/bots/` (`red/bot.gd`, `blue/bot.gd`), with one fresh bot object per seat per game. Keep everything under `tools/league/`, so none of it goes into the export.
2. **Runs the turn loop itself.** A bot's `take_turn` is overridable, so the harness never calls it. The harness calls `choose()`, checks the action against its filtered legal list, calls `session.act`, and ends the turn. `choose()` and the harness's one round-start hook (below) are the only calls into the bot. Each seat's bot is made before the game starts, and the time to make it counts against that seat's clock.
3. **Seats and tribes:** seats alternate red and blue. Each game has 4 tribes, one left out in turn, so each tribe sits out one game in five. The harness passes the 4 tribes as `lobby_tribes` to `ContentSet.session`, which already takes it, so the left-out tribe isn't in the pool. Red's seat *i* and blue's seat *i* get the same tribe, so both teams play the same tribes in every game. Seat order and tribe order rotate with the seed. Every seed is played twice with the colours swapped. **Owner to check:** tribe-assigned seats rather than free play (section 12).
4. **The tribe lock:** the bot is told its tribe. The harness filters the legal actions it hands the bot, so the bot can't buy another tribe's units. Spells are allowed (the game's stand-in spells, the same for everyone). Discover can't be locked without changing `src/core`: the core offers any tribe there, and a pick is compulsory. So an off-tribe Discover pick is allowed and may be played.
5. **The thinking clock:** each seat gets **3 seconds of thinking per game**, timed around every call the harness makes into the bot. When a seat's clock runs out, the harness plays the rest of that seat's game with `SimpleBot` and logs a clock-out. The harness can't interrupt a single call, so one call over 2 seconds is logged as a fault.
6. **The same content as the shipped game.** It loads the game's own content, with no test or neutral cards.
7. **Records every game** with the existing game records (`src/core/records/`), into the league's data folder (not `user://`). It also writes one stats line per game in JSON, extending the balance pass's lobby format.
8. **Baselines** for practice and the anchor (section 9): `SimpleBot`, `FlowBot`, `RandomBot`, and the balance pass's `TribeBot`, committed as `tools/league/bots/baseline/`.
9. **`tools/league/analyze.py`:** every stat in section 9, with 95% intervals.
10. **`tools/league/verify.sh`:** the cheat and bug checks in section 8.

**Rules for bot code**, so two teams' code can load side by side and seats can't share anything:
- no `class_name` (use `preload`);
- no `static var`, no autoloads;
- no `Engine.set_meta` or other global stores;
- no `Thread` or `WorkerThreadPool`;
- no file, network or `OS.` access;
- nothing outside the team's folder.

A bot extends `Bot` (`src/core/bots/bot.gd`) and may extend `SimpleBot` or `FlowBot`.

**The information rule.** A bot gets the live `GameSession`, because the core has no copy or view object for it. It may read only:
- its own `PlayerState` and `session.view_for(own id)`;
- every player's health, armor, tier and whether they are still alive;
- the board each past opponent showed when they fought, which the harness hands each seat through its round-start hook;
- the card library, the rules and all code.

It may run the fight engine (`Combat.create` and `run`, as `duel.gd` does) on boards it is allowed to know, with any seed except the real fight's.

It may not read:
- other players' hands, shops, current boards or gold;
- the pool (`session.units`, `session.spells`);
- the game's seed (`session.seed_value`) or any random stream: every shop, pairing and fight is derived from the seed (`Rng.derive`, `Rng.hash32`), so a bot that reads it can predict them;
- `session.events`, `session.fights`, `session.recruit` or the record.

It may not change the session except through the actions the harness takes for it.

**Gate before freezing** (the owner's two gates):
- **Runtime:** `scripts/check.sh` passes. Then:
  - an **A/A match**, where both colours run the same bot for 1,000 games, shows a red-minus-blue gap within ±0.11;
  - colour, seat and tribe balance is checked in the stats;
  - **each planted cheat is caught**:
    - a bot that adds gold to itself, caught by the replay;
    - one that reads another player's hand, caught by the code scan;
    - one that keeps a `static var` across seats, caught by the scan;
  - a single call that sleeps 3 seconds produces a clock-out.
- **Scope review:** a fresh `scope-reviewer` on the harness commits, given the owner's words above and this brief.

**Stop for the owner:** show the A/A result and the planted cheats being caught, in a few lines. Start the teams on the owner's go. Then tag `league-harness-v1`. A fix later is `v2`, goes to both teams at once, and any match it affects is played again.

## 6. The rules for teams

**Isolation.** Each team works in its own clone, not a worktree of the shared repo, so the other team's commits never show in `git log --all`: `/home/alex/league/red` and `/home/alex/league/blue`, cloned from the harness tag on branches `league/red` and `league/blue`. Teams don't push until the referee asks for the match tag. Until a match ends, a team doesn't read anything outside its own clone, the pinned build, its own Codex worktrees and the folder of published opponent code. The referee publishes opponent code into `league/published/<colour>-m<n>/`, which both teams can read after that match.

**Allowed: anything that raises the bot's placement, inside its own folder.** For example:
- hand-written strategy per tribe;
- search, and lookahead with the real fight engine;
- tables or weights learned offline by self-play;
- selling on purpose, stocking the hand, planning around Outnumbered and the Compost;
- using any card the way its text and the rules allow, however strong;
- copying from the other team's published code (credit it in the notes);
- tuning against the other team's published bots.

**Not allowed:**
- changing anything outside its bot folder: the rules core (`src/core`), the cards (`src/content`), the harness, tests, baselines or the other team's bot;
- breaking the information rule (section 5);
- passing anything between seats or between games during a match: no shared memory, files, network or clocks other than the harness's;
- detecting which seats are teammates or which bot is on a seat, other than through what it plays;
- using a bug in the rules core or the harness.

A team that finds such a bug reports it to the referee at once. The referee logs it for the owner, tells both teams, and rules whether it's a bug (banned from matches) or the rules working as written (allowed, and itself a balance finding). The rules core stays frozen during the league unless a bug crashes games.

**Equal caps for each team**, all at once:
- the orchestrator, at most 2 Opus sub-agents, and at most 2 Codex workers;
- at most 2 Godot processes for practice games.

The Codex plan pool is shared, so if Sol hits its limit, the referee moves both teams to Astra together.

**Hand-in at the round's deadline:** a commit tagged `red-m<n>` or `blue-m<n>` in the team's clone, whose diff from the harness tag touches only `tools/league/bots/<colour>/`, plus `NOTES.md` in that folder:
- what the bot does, tribe by tribe, and roughly how much of the round's effort went to each tribe;
- what changed since the last match and why;
- what it took from the other team;
- the bugs or exploits found;
- the tokens and Codex runs used.

A late tag, or a diff outside the team's folder, means the team plays that match with its previous tag (round 1: `SimpleBot`).

## 7. A match, step by step

1. **Check the machine** (section 7a). Fetch both tags from the clones. Check each diff is limited to the team's folder, and copy both folders onto the frozen harness.
2. **Smoke run:** 20 games, not counted. On a crash or a fault in a bot, the referee tells that team, which gets 30 minutes to fix only that. The other team is told the same.
3. **Counted run:** 1,000 games (500 seed pairs). The seeds are fresh for each match and not announced beforehand.
4. **Verify** (section 8), then publish to both teams at once:
   - the score and stats;
   - the ten-findings table (section 10) for this match;
   - the records;
   - the other team's code into `league/published/`;
   - the start of the next round.
5. **After match 1, stop for the owner:** the score and the first findings table, in a few lines. Start round 2 on their go. They may stop the league here.
6. **After matches 2 and 3, tell the owner the score in one line, and don't wait.** Also stop and ask for a confirmed cheat, a harness bug that changes a result, a busy machine, or a Codex limit on both models.

**After match 3**, run **the anchor** once, not scored: each team's final bot in 4 seats against 4 `TribeBot` seats, 200 games. It shows how far the final bots are above the balance pass's bots, and whether a bot only learned to beat the other team's habits.

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

With the 3-second clock, the worst case is about 27 seconds a game, so about 2 hours for a match at 4 processes. Plan on the worst case: the clock is free strength, so teams will use all of it.

## 8. Catching cheats and harness bugs

1. **Replay every counted game** from its record on the frozen build, with no bot code loaded (`scripts/records.sh record=...`). A bot that changed the game other than through `act` breaks the state hashes and is caught. Replay can't catch a bot that only reads what it shouldn't; checks 3 and 4 are for that.
2. **Check the diffs:** each tag's diff from the harness tag touches only that team's folder.
3. **Scan the code.** Look for reads the information rule forbids:
   - `.player(` with another id, `players`, `ghost_`;
   - `units`, `spells`, `events`, `fights`, `recruit`, `seed_value`;
   - `Rng`, `record`, and private `_` fields of the session.

   Also look for `static var`, `class_name`, `Engine.set_meta`, `Thread`, `WorkerThreadPool`, file access and `OS.` calls. A hit isn't proof: the referee reads the code.
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

**Per tribe**, per team and both together. Because each team puts its effort where it gains most, a tribe both teams neglect will look weaker than it is. So read each tribe's numbers from the team whose bot plays it better as well, and say where both teams' notes show little effort on a tribe.
- average placement, top-4 and win rate;
- fight win rate by stage (rounds 1–3, 4–6, 7–9, 10–12, 13+);
- tribe against tribe from round 7;
- median board stats and tier by round;
- gold left unspent by round.

**Per card:**
- lift: its presence on the final board against placement, within its tribe and round, as in the balance pass;
- buy rate and golden rate.

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

**Across matches:** how each tribe's numbers move as the bots get stronger. If a gap shrinks as play improves, the naive bots overstated it; if it grows, they understated it.

## 10. Hand-over

- **Each team:** its three tagged bots and their `NOTES.md` files.
- **The referee:**
  - `docs/workstreams/bot-league/results.md`, written to the house rules (plain, most important first);
  - the per-match stats files;
  - a log of rulings and bugs;
  - the morning pack, if any part ran while the owner was away (the `overnight-run` skill).

**`results.md` starts with the ten findings** from [balance-pass-18-nov/findings.md](balance-pass-18-nov/findings.md). For each one it says whether the finding is confirmed, weaker, stronger or reversed under the final bots, with the numbers from match 3 next to the naive-bot numbers and those from matches 1 and 2. The same table, with that match's numbers, is part of every match report. Then it gives:
- the tribe ranking under strong bots;
- new findings: strategies the strong bots found that naive ones missed, and cards they never buy;
- the anchor result;
- the rules-core bugs found;
- what still can't be judged. For example: the build has live lobbies but the real game will be asynchronous, there are no heroes, and bots play no better than their teams could make them in a day.

**One PR into `dev`** carries the harness, the baselines, both teams' final bots and the results. It changes no card numbers and nothing in `src/core`. Nothing goes to `main`.

**Clean up:** once the PR is open and the records are kept, remove the clones and the leftover worktrees. Large data goes to R2 through `tools/assets/`, not Git.

**Follow-ups to offer, not run:**
- a free-play league (no tribe lock), if the owner wants to know what wins rather than how each tribe does;
- the same final bots on `night/ambush` (the Mice change), to measure it;
- the final bots as the game's opponents in place of `FlowBot`;
- the rebalance itself, from `results.md`.

## 11. Timeline

| Step | Wall time |
|---|---|
| Phase 0: harness, A/A test, planted cheats, both gates; then stop for the owner | about 3–4 hours |
| Round 1, then match 1 and its checks; then stop for the owner | 4 hours + about 2.5 hours |
| Round 2, then match 2 | 3 hours + about 2.5 hours |
| Round 3, match 3, then the anchor | 3 hours + about 3 hours |
| Results and hand-over | about 1 hour |

That is about 22 hours of running, plus the owner's two stops: a night and a day. The dials are round length and the thinking clock: shorter rounds or a smaller clock make it faster and the bots weaker. A 1-second clock brings each match down to about 45 minutes.

## 12. Choices the owner should check

1. **Live 4-against-4 lobbies from game one, with no ghost warm-up.** The build plays all eight seats live, so the warm-up isn't needed. A ghost field would decide open rule 2.1.5 (how async play matches snapshots) inside a test harness. If the owner wants the stats to reflect async play anyway, phase 0 grows: a snapshot pool by round, seeded from 100 uncounted games, as the owner described.
2. **Tribe-assigned seats.** This is the biggest change to "anything they want". Each game gives both teams the same four tribes, one seat each, and locks each seat's buys to its tribe. This gives fair matches and the per-tribe numbers the ten findings need. But it bans mixed boards, so it measures how each tribe does, not what wins. A free-play league is a follow-up.
3. **The time dials:**
   - rounds of 4, 3 and 3 hours;
   - 3 seconds of thinking per seat per game;
   - about 22 hours in all.
4. **Copying is allowed:** each team may lift the other's code after a match.
5. **Teams skip the merge gates inside a round** (section 4), or every team plan would wait on the owner mid-round.
6. **Two stops for the owner:** after phase 0 and after match 1. Matches 2 and 3 only report.
