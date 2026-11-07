# Interrogation of the bots plan (`BOTS.md`)

A cloud reviewer's cross-examination of `docs/ideation/BOTS.md` at `218240f` (`origin/ideation/main`), before any code. The plan isn't changed here.

**The problem**, in the owner's words (8 Nov, `owner-notes/2026-11-08a`, `2026-11-08b`):

- "I think if we make bots, we should make them the best players we possibly can."
- "if one strategy is consistently beating other strategies, we should have that bot get better"
- "I think that we should be designing around the best bots we can. Maybe have different flavors of them with different strategic quirks."
- "I don't think Easy and Medium bots will be giving us good data … the Hard bots will be giving us subpar data."
- "Remove altogether. No easy, no medium bot."

The overall goal (6 Nov, `2026-11-06a`): something "really high quality that I can playtest … that I can just try out and see how far I can get with it", with a focus on "interesting designs and strategic depth".

So the problem has four parts:
- **P1:** Easy and Normal exist.
- **P2:** design data comes from weak bots.
- **P3:** bots should improve when one strategy dominates.
- **P4:** "maybe" flavours.

Who it's for: the owner playtesting, then keen players.

**Provenance.** Everything after the quote block in `BOTS.md` is the orchestrator's: "Everything below this quote is the orchestrator's proposal." `DECISIONS.md` (8 Nov) names "the head-to-head promotion test and hand-play hunts" as the "Orchestrator's own additions". In the table, "Orch" means `BOTS.md` below the quote, and "Owner" means a step that restates the owner's words.

## What I ran and read

- I read `src/core/bots/` (in full: `bot_level.gd`, `bot_lobby.gd`, `board_search.gd`; the parts of `bot_brain.gd` that matter here), `tools/sim/bench.sh` and `bench_suites.gd`, `game_session.gd` `end_turn()`, `bench-latest.md`, `bench-reading.md`, `playtest-3.md` and `DECISIONS.md` (7–8 Nov).
- **I ran the bench**, 4 games each of `spread` and `place_search` at seed 1 on `218240f`, one 4-core cloud VM, one core each, nothing else running:
  - Each 4-game run took 43.8 s and 43.4 s. That is about **11 s per all-Hard game on one core.**
  - Bot turns were **41.8 s of the 43.8 s (about 95%)**. Fights and everything else were about 2 s.
  - **A Hard turn now averages 87.5 ms** (95th percentile 180 ms, worst 263 ms; 478 turns). `bench-latest.md` measured 35 ms at `1d12de0`, which had 2 tribes; there are 6 now.
  - It's a small sample on a VM of unknown speed relative to Sol or a phone.
- **I didn't run:** a full bench, any head-to-head, any device timing, or any test.

## Step-by-step

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| **1. Remove Easy and Normal**: levels, menu choice, level-only rules, per-level records, guide text, tests | P1, fully | Owner ("Remove altogether. No easy, no medium bot.") | **keep** | It's the owner's literal ask, and the code is contained: `BotLevel.of()` EASY/NORMAL branches and `EASY_CURVE`, `Records.DIFFICULTIES`, `main_menu.gd`'s chooser, `BotLobby.seats(difficulty)`, `PLAYTEST.md` line 19, the bench suites, and tests in `test_bot_*`. The smallest version is this step as written. |
| 1a. "The record shows best placement and wins, with no level" | P1; the goal's "how far I can get" | Orch | **keep** | Without a level, the record is the only "how far" signal left. It needs one migration call: keep the old Hard record, or reset. Log it. |
| 1b. "Naive stays only as a test yardstick in tools" | Nothing for the owner; the bench's floor | Orch | **keep, shrink** | It's needed as a regression floor and costs nothing to keep (1.3 ms a turn). Its bar has stopped informing, though (see the Done-means row). |
| 1c. Drop the dead bench suites (`hard_easy`, `hard_normal`, `normal_easy`, `easy_naive`, `hard_lobby_normal`, `hard_lobby_normal4`) | P2 indirectly: frees bench time | Not in the plan; implied | **keep (add)** | That's 2,600 of the default set's ~10,000 games. Without this, `bench.sh` with no arguments breaks or wastes hours. |
| **2. Head-to-head yardstick**: 4 candidate vs 4 current best, strategies spread evenly, honest noise, fresh seeds | P3 (the definition of "get better") and P2 (guards against regressions) | Orch | **keep, shrink** | Without it, "best we possibly can" is unmeasurable. What exists is close: `BenchSuites.LADDER` seats 1 focus against 7, and `place_search` already runs Hard against Hard. **Smallest version:** one new seating rule in `bench_suites.gd` (4 and 4, seats shuffled by seed, varied builds), plus one table in `summarize_bench.py` giving the average-place difference with a 95% margin. No new tool or doc. **Add an A/A run**, Hard against Hard, which must read 0 within its margin, to prove the margins. Better still, **pair each seed with sides swapped**, which cuts noise more cheaply than doubling games. If dropped, step 4 ships changes on hope, as the hand-tuned `power` priors did (DECISIONS, 7 Nov). |
| 2a. "only replaces the current best if it beats it clearly on fresh seeds" | P3 | Orch | **keep** | This is what stops overfitting to seeds. Set "clearly" in numbers before the first candidate: margin excludes 0, and the change is at least 0.15 of a place. |
| **3. Find what the bots miss**: fresh cloud players play by hand against the best bot, and read the code for blind spots; output a ranked list | P3; owner: "human players will find stuff the bots haven't" | Orch (owner's suspicion, orchestrator's method) | **shrink** | Much of the list already exists, unranked: `bench-reading.md` (Purse "holds gold on a set schedule that doesn't react to the shop", Rings "hard for a bot to play", Queen's tithe "a simple rule"), `DECISIONS` 7 Nov ("`neutrals_economy` has no save plan, so no economy line has been tested"; Acorn Stash "held in 19 of 4,475 player-turns"; Dozey on 70–96% of boards), and `playtest-3.md` (Charcoal Burner and one-unit stat piles beat tribes). **Hand play as a bot-gap finder is weak evidence:** cold cloud reviewers placed 6th–8th in every Hard game (`playtest-3`, reviewer C), so they mostly show Hard beats newcomers, not what Hard misses. **Smallest version:** one cloud worker reads the code against that list and ranks it. Hand play folds into the Round 4 playtests that `PLAN.md` already schedules, with one extra question ("what did you do that the bots never did?"). |
| **4. Make the bot stronger**: work down the list | P3, P2 | Orch | **keep, bound** | It's the core of the owner's ask. As written it's open-ended (see "Is step 4 open-ended?"). **Smallest version:** the top 5 items from step 3, one worker run each, each through step 2. **Stop rule:** stop when the list is done, or when two promotions in a row fail. |
| 4a. "Buying and tier-up choices may test options with real fight simulations" | P3, speculatively | Orch | **defer** | The evidence runs against it so far. Bigger placement search "bought nothing measurable: 200 fights over 20 is +0.04 ±0.35 places" (DECISIONS 7 Nov). Placement search over shuffled fell to "0.14 ±0.27 … the cause is unknown" (DECISIONS). Bot time is already about 95% of bench cost. Explain the placement-search drop first; try fight simulations only once the cheap gaps are spent. |
| 4b. "within a time limit per turn that keeps the game responsive on a phone" | The goal (playable on a phone); not P1–P4 | Orch | **keep, reshape** | See "Is a per-turn time limit on a phone real?". The limit must be a **fight count, not a clock**: a clock makes seeded games and benches machine-dependent. The current numbers already break the plan's own limit, before step 4 adds anything. |
| 4c. "Each change passes step 2 or doesn't ship" | P3 | Orch | **keep** | This is what makes step 4 finite and honest. |
| **5. Flavours**: one strength, quirks such as greedy economy, early tempo, late pivot and one-tribe purist, each "within sight of the best", reusing the 21 pinned strategies | P4 | Owner ("Maybe have different flavors"); the quirk list is the orchestrator's | **shrink, then defer the rest** | Flavours **already exist**. `BotLobby.resolve` deals each seat a different one of the 21 strategies ("a lobby of seven of one build is a worse game"), and three of those already are economy quirks (`neutrals_economy`, `neutrals_purse`, `neutrals_low_roll`). **Smallest version:** call the strategies flavours, and add per-strategy head-to-head results to step 2's table, which gives "within sight of the best" for free. New quirk axes such as late pivot wait until step 4 is done: the owner said "Maybe", and a quirk on a weak base measures nothing. |
| **6. Rule for imbalance**: improve the bots playing against a dominant strategy and the bots playing the others; change cards only after hand play or stronger bots confirm | P3 | Orch's reading of "we should have that bot get better" | **keep as a rule; ask about the reading** | It's a policy and needs no code: one entry in `DECISIONS.md`, not a step. The owner's sentence is ambiguous. "that bot" may mean the losing strategies' bots, or bots in general. The plan reads it as both, which is reasonable. The orchestrator should log that reading. Risk: "improve the bots first" can postpone card fixes forever. Give it a cap: after one step-4 pass, if the strategy still leads, the cards change. |
| **7. Re-measure**: spread and placing bars with the best bot; re-read Engine and Bird conclusions drawn from older bots | P2 | Orch | **keep, split** | The spread half is needed **early** as well as late. `bench-latest.md` is from `1d12de0`, which had 2 tribes and 9 strategies; there are 21 now. There's no current baseline. Shrink the re-read to a list of which conclusions in `DECISIONS`, `LEARNINGS` and `balance-1` rest on Easy or Normal data, marked "stale"; re-argue only the ones a later step leans on. |
| Done means: remove "Easy, Normal, Hard with a measured ladder" and "1 Hard among 7 Normal" | P1 | Owner (implied by "Remove altogether") | **keep** | Directly follows from the owner. |
| Done means: "1 best bot among 7 Naive places top 4 at least 85% and wins at least 45%" | Nothing new | Orch (carried over) | **shrink** | It already passes at 100% top 4 and 100% wins (`bench-latest`). As a bar it can't fail and says nothing. Keep it as a regression check only, at 300 games. |
| Done means: "the current best beats the previous best in head-to-head play on fresh seeds" | P3 | Orch | **keep** | This is the real bar. It needs a finite end, or Done means can never close: "and the last step-4 pass found no promotable change". |
| "Expert bot is no longer deferred: this work is it, under one name" | P1 (one name) | Orch | **keep** | Pick the name once. Bench names (`hard:…`) can stay internal. |

## Fixed after which step, and how the owner would check

- **P1 is fixed after step 1.** The owner opens the build: "New game" goes straight to the hero pick with no difficulty chooser, the menu shows one record, and `PLAYTEST.md` no longer says "Pick a difficulty".
- **P3 is first moved after step 4's first promotion.** It's only checkable by report: the step-2 table shows the new bot beating the old with a margin that excludes 0. The owner's own check is the same as now: does a game feel harder, and do the bot boards look smarter?
- **P2 is fixed after step 7,** when the spread is re-read with the promoted bot. Until then, every design conclusion is labelled weak evidence (DECISIONS 8 Nov already says so).
- **P4 is fixed after step 1 plus a naming change** (the strategies already differ per seat), unless the orchestrator decides the owner meant more than that.

## Order

Steps 1 and 2 are independent. Run them in parallel, then a baseline before any bot change:

- **1 ∥ 2.** Removal, and head-to-head plus its A/A check.
- **Baseline.** Spread and head-to-head on one commit, with the six-tribe pool and Hard only. This is the early half of step 7. Today's `bench-latest` is two tribes old.
- **3, shrunk.** Rank the existing gap list. Hand play rides on Round 4.
- **4, bounded.** Top 5 gaps, each through 2.
- **7.** Re-measure. Step 6 is logged as a rule at any point.
- **5.** Whatever is left of flavours.

Cheap investigations should come before 4a: explaining why placement search fell from 0.91 to 0.14 is cheaper than adding buy-side search, and it tells you whether fight simulations pay.

## Checkpoints

1. **After step 2:** the A/A run reads 0 within its margin. If not, the yardstick is wrong; stop.
2. **After the baseline:** record the Hard turn time on this commit (mean, 95th percentile) and the cost of a 2,000-game spread. Check them against the phone limit and the bench budget below before step 4 starts.
3. **After each step-4 change:** head-to-head result, turn-time change, bench cost per game. A change that's stronger but blows the time budget doesn't ship until it's made cheaper.
4. **After the step-4 list is done:** apply the stop rule. Compare the spread against the baseline.
5. **One real-device check:** the owner, or the Android export, times the wait after End turn in round 12+. The 3× phone factor "is an assumption: no device was tested" (`bench-latest`).

## Is step 4 open-ended?

As written, yes. "Work down that list" with no list length, no stopping condition, and an optional fight-simulation branch that could absorb any amount of work.

**Will a stronger bot be measurably stronger within a few days?** Likely yes, for the known gaps, and unlikely for search:

- **Gaps.** The gaps are concrete and large. There's no reactive saving, the Acorn Stash is almost never held, and some tribe signatures are barely played (Rings ends on 5.6 units). A fix to one of them can move average place by tenths.
- **Can the yardstick see it?** Yes, if step 2 is built as described. A 4-and-4 lobby gives 4 seats a side per game, so 500 paired games resolve differences of about 0.15–0.2 of a place. That's an estimate from the 1-against-7 margins in `bench-latest` (±0.18 at 500 games, one seat), not measured.
- **Search.** Evidence so far shows extra search buys about nothing.

**What stops it:** a fixed list (top 5), one worker run per item, the step-2 bar, and "two failed promotions in a row, stop". Anything after that is a new plan.

## Is a per-turn time limit on a phone real, given fight simulations?

**How bots run now.** Bots play synchronously in `GameSession.end_turn()`, after the player taps End turn, one after another. The player waits for all seven.

**Today's numbers already break the plan's limit.** At `218240f` a Hard turn averages 87.5 ms here (95th percentile 180 ms). Seven bots on the assumed 3×-slower phone core is about **1.8 s mean** and roughly 3–4 s on bad rounds. The plan's limit is "7 bots in about 1 s" (`bench-latest`). The 20-fight budget's comment ("near 140 ms") predates six tribes.

**So the limit is real, and the question is how to keep it:**

- **Count, not clock.** It must be a fight or decision **count**, not milliseconds. A wall-clock cutoff makes the same seed play differently on Sol, a cloud VM and a phone, which breaks reproducible benches and the step-2 bar. Calibrate the count against a measured device time.
- **Run bots during the player's turn.** The cheapest big win isn't in the bot at all. Bots could take their turns **while the player is recruiting** (a worker thread, or spread across frames), since they act on their own state and scout last round's boards. The wait after End turn then mostly disappears, and the bot can keep its budget. It's a `GameSession` and UI change, so it needs a check that bots can't read the player's current-turn state. Flag it, and leave it for the orchestrator to decide.
- **If neither happens,** buy-side fight simulations (4a) make the phone limit worse with every option tested. That's another reason to defer them.

## How bots must change to keep bench runs affordable

**Cost now.** About 11 s per all-Hard game on one core, about 95% of it bot decisions. A 2,000-game spread is about 6 core-hours, or about 2 hours on Sol's 3-core share. The full default set (around 10,000 games, ~7,400 after step 1c) costs several times that. Every millisecond added to a Hard turn costs about 2% of bench time.

**What keeps it affordable:**

1. **Run benches in cloud VMs.** "Cloud VMs don't count towards" the 3-core limit (`CLOUD.md`). This VM has 4 cores. Several routines can each run a shard. It's the biggest lever and it's free.
2. **Spend search only where it decides.** Placement already searches "contested boards only (4+ units, stat ratio 0.6–1.7)". Any buy-side search needs the same gate: only when two options are close by the cheap evaluation.
3. **Use the same budget in both arms of every comparison.** A bench budget may be lower than the game's, as long as candidate and incumbent use the same one. This only works if the knob is a count (see above).
4. **Profile before adding anything.** Turn time more than doubled from 35 ms to 87 ms between the 2-tribe and 6-tribe pools with no change to the search budget. Find out where it went (evaluation, the lanes and held-units logic, or the search's fight setup) before step 4 adds cost.
5. **Smaller default sets after step 1** (1c), and paired seeds in head-to-head (step 2) instead of more games.

## Does removing easier bots leave a first-time player able to get anywhere?

**Evidence: barely, and stronger bots make it worse.**

- **What playtests show.** In `playtest-3`, reviewer C placed 7th, 6th and 8th in every Hard game, and 1st twice against Normal. Reviewer B: "Hard is a wall." Reviewer A lost 10 straight on Easy, then came 2nd on Normal: "My places followed what I'd learned, not the level."
- **What that suggests.** Learning, not bot level, was the main driver. The guide gap ("The guide skips how the game works … gold, tiering up, refresh or freeze, spells, heroes") is the bigger obstacle.

**What the owner's words allow, other than an easy bot:**

- **The 8-place ladder itself.** Going from 8th to 4th to 1st is "how far can I get", and the record (1a) already shows best placement. A first-time player who places 6th has gotten somewhere.
- **Teaching, not handicapping.** Fixing the guide's missing basics is already a Round 4 item. That is the one change that should matter most to a first-timer, and it touches no bot.
- **Not allowed in spirit:** a weaker flavour, a beginner lobby, a slower climb for new players, or anything else that weakens bots. Those are an easy bot by another name, and the owner said "No easy, no medium bot." The audience is "the owner playtesting, then keen players", not casual newcomers.

**Recommendation: leave difficulty alone.** Do the guide fix already queued, and let flavours (step 5) give lobbies variety without weakening them.

## Smallest plan

1. **Remove Easy and Normal.** Remove them everywhere players and docs see them, keep one record, and drop their bench suites (1c). Naive stays as a 300-game floor check. Log the records-migration call.
2. **Add 4-and-4 head-to-head** to `bench_suites.gd` and the summary, with paired seeds and an A/A check. Put "clearly better" in numbers.
3. **Baseline** on one commit: spread, head-to-head A/A, Hard turn time and bench cost. Run in cloud VMs.
4. **Rank the existing gap list** with one code read. Hand-play hunting rides on Round 4 with one added question.
5. **Fix the top 5 gaps**, each through step 2, with a stop rule and turn-time and bench-cost checks per change.
6. **Re-measure the spread** with the promoted bot. Mark which older conclusions rest on Easy or Normal data.
7. **Log the imbalance rule** in `DECISIONS.md`, with a cap after one pass. Present the 21 strategies as the flavours.

## Deferred

- **4a**, buy-side and tier-up fight simulations, until the placement-search drop is explained and the cheap gaps are spent.
- **New flavour quirks** (late pivot, one-tribe purist as a separate axis), until step 4 is done.
- **A full re-argument** of Engine and Bird conclusions. List the stale ones; re-argue only the ones a later step needs.
- **Running bot turns during the player's Recruit Phase.** The orchestrator decides; it's not part of the bots plan, but it settles the phone limit.

## Open questions (the orchestrator decides and logs)

1. **The reading of "we should have that bot get better".** Improve bots against the leader, bots on the losing strategies, or both? And what cap on bot-first before cards change?
2. **The records migration:** keep each player's old Hard record as the one record, or reset.
3. **What "clearly" means in step 2**, in numbers, before the first candidate.
4. **Should `power` priors and hand-set curves stay in the best bot?** They are bench-tuned choices (DECISIONS 7 Nov: "set by hand after seeing bench results"), so the "best" bot partly encodes past bench reads.
5. **The phone limit:** keep "7 bots in about 1 s" and cut Hard's cost now (it's already about 1.8 s), or move bots off the End-turn wait? And who times a real device?
6. **Is P4 met** by the varied lobby renamed as flavours, or did the owner want quirks beyond strategies?
