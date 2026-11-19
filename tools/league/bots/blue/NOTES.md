# Blue team notes (round 1)

For the referee only until the league ends. Final for the blue-m1 hand-in.

## How the bot plays

A greedy recruit-phase bot with card values measured from self-play, a tuned economy, and
simulated fights for board arrangement. Each call it re-reads the view and takes the first of these that applies:

1. **Discover pick**: the option with the highest buy value.
2. **Upgrade** when the round reaches the tier schedule: tier 2 at round 3, tier 3 at round 8,
   tier 4 at round 12, 5 at 13, 6 at 14. Self-play tuning drove this far slower than a
   Battlegrounds-style curve (see the log below): in this economy (income 5 rising by 2 to 15,
   gold carries over, units cost tier+1, flat loss damage) buying units early wins more fights
   than levelling. It saves gold the turn before a planned upgrade.
3. **Spells in hand**: Triple Reward and Seek/Forage at once; Sharpen on the best front unit.
4. **Feed eaters**: with Granary Glutton or Gorger on board, sell Hoppers into them.
5. **Play units** from hand into the slot their row wants; with a full board, sell the weakest
   unit if a hand unit is worth more.
6. **Pigeon Orders** (Lance-corporal, Grenadier Guard's Guard post once) before buying.
7. **Buy** the best-valued shop unit it can afford: value = tier x 10 + stats x 0.5 + a per-card
   bonus for its text + a per-turn scaling bonus for units that grow + tribe synergy (2 per owned
   unit of the same tribe, up to 6) + tribe preference (Locust +6, Badger -6, tuned) + pair (+6)
   and triple (+25) bonuses − 100 x the card's measured lift (see "Cards valued most and least";
   this term dominates). With a full board it buys only what beats the weakest unit by a
   margin. With The Colonel on board it may stock up to 3 extra units in hand (Reserve; in
   practice this never fires, see the 00:21 row).
   Sharpen early (to round 7); Seek/Forage only from tier 4.
8. **Bury** (Briars): bury the highest-tier shop unit it isn't buying.
9. **Refresh** while it has gold beyond what it saves (up to 8 a turn, more when gold is piling up),
   never with a full hand.
10. **Arrange**: a row heuristic (Guard and tanky units front; Squires, lenders, supports and
    fragile hitters back; strongest units in the middle and on buffed slots; War-drummer in F2
    with death-effect units behind it), then a hill-climb over slot swaps scored by simulated
    fights against the latest boards of this round's opponent and other recent opponents, within
    a per-turn CPU budget with a 150 ms safety reserve.
11. **Freeze** a shop holding a copy it is collecting.

**Tribe commitment.** The bot never locks a tribe. Its synergy bonus grows with the number of
units of a tribe it owns, so it drifts into the tribe it has most of; from round 6, with 3+ units
of one tribe, off-tribe units take a penalty. The early game is pure tempo: any tribe's tier-1
units, Sharpen, full board by round 3.

## Log of findings (self-play A/B, 4 seats vs 4, 400 games unless noted)

Gap = variant minus base average placement (negative: the variant is better).

| Time | Variant vs base | Gap |
|---|---|---|
| 20:05 | tiers 2/3/4/5/6 at rounds 2/3/5/7/9 vs 2/4/6/8/10 | +0.92 (faster is worse) |
| 20:05 | 2/5/7/9/11 vs 2/4/6/8/10 | −1.19 |
| 20:12 | 2/5/8/10/12 vs 2/5/7/9/11 | −0.44 |
| 20:13 | 3/5/7/9/11 vs 2/5/7/9/11 (partial run) | −0.58 |
| 20:17 | spare-gold mode off vs on | −0.09 ± 0.12 (noise) |
| 20:20 | T2 at round 4 vs round 3 (rest 5/8/10/12) | −0.74 |
| 20:25 | tiers at 3/5/8/10/12 base: T5/T6 later (11/13) or never T6 | 0.00 (games are decided before) |
| 20:30 | base 4/6/9/11/13: T2 at r5 | −0.02 (noise) |
| 20:33 | T3 at r7 / r8 | −0.30 / −0.47 |
| 20:35 | T4 at r10 / r11 | −0.28 / −0.43 |
| 20:37 | T2 at r3 | +0.62 (worse) |
| 20:35 | tribe preference +6 (base 3/5/8/10/12): Badger / Mouse / Pigeon / Locust / Briar | +0.67 / +0.85 / −0.31 / −0.56 / −0.13 |
| 20:25 | sim arrangement on vs off (92 games, partial) | about −0.2; uses 550–930 ms of the clock |
| 20:45 | reviewer fixes off (base 4/8/11/12/14) | +0.23 (fixes help) |
| 20:47 | vs baselines, sim off: TribeBot / FlowBot | 2.81 vs 6.19 / 2.58 vs 6.42 (v1: 3.76 vs 5.24) |
| 20:55 | pref +6 Locust / +6 Pigeon / −6 Mouse / −6 Badger | −0.35 / −0.16 / +0.12 / −0.45 |
| 20:55 | T3 at r9 / r10; T4 at r12; T5/T6 later | +0.03 / +0.04 / −0.12 / 0.00 |
| 21:00 | sim arrangement on vs off (200 games, 1 thread) | −0.11 ± 0.17; no clock-outs, worst seat 853 ms |
| 21:05 | sim-scored buys on vs off | +0.23 ± 0.20 (worse: off) |
| 21:05 | Seek/Forage from tier 2 / 3 / 5 / (base 4) | +1.40 / +0.39 / 0.00 |
| 21:05 | Sharpen only to round 3 / to round 12 (base 7) | +0.43 / −0.01 |
| 21:07 | replace margin 0 / 10 (base 4) | +0.07 / +0.06 (noise) |
| 21:07 | combos off (Glutton feeding, Colonel stock, drummer rows) | 0.00 (rarely fire) |
| 21:23 | synergy weight 4 / 6 / 4 with cap 8 (base 2, new base) | −0.04 / +0.15 / −0.09 (noise) |
| 21:23 | upgrade off-schedule when gold after upgrade ≥ 5 / 10 | +0.62 / +0.10 (worse: banking beats levelling) |
| 21:30 | stat_w 1, tier_w 5, triple bonus 40, commit round 4, no off-tribe penalty | all within ±0.1 (noise) |
| 21:34 | refresh cap 15 / 30 (base 8) | −0.05 / −0.06 (noise) |
| 21:16 | **practice s0 vs red (200 games)** | **blue 3.27, red 5.73** |
| 21:40 | pref Locust 10 / 3, Pigeon +4, Briar +4, Mouse −4, Badger −12 (base L+6, B−6) | −0.06 / +0.03 / −0.12 / +0.20 / +0.02 / +0.13 (keep base) |
| 21:45 | **measured card lift in values**, 4 / 8 / 15 points per place | **−0.54 / −0.85 / −1.09** |
| 21:52 | lift weight 25 / 40 (base 15) | +0.31 / +0.35 (keep 15) |
| 22:00 | **practice s1 vs red (1,000 games; tag blue-s1 = lift v1, weight 15)** | **blue 3.10, red 5.90** (+2.80 ± 0.07; s0 was +2.45) |
| 22:07 | **card lift re-measured under the s1 policy** (1,400 games): half-blended / replaced, vs s1 | **−1.02 / −1.45** |
| 22:14 | lift v3 (second full replacement) vs v2 | +0.33 (worse: overshoots) |
| 22:14 | lift split by round (early/late tables) vs one table | +0.26 (worse) |
| 22:25 | lift v2.5 (half-step from v2) vs v2, 800 games | −0.21 ± 0.12 |
| 22:25 | tier schedule re-check under the new values: T2 r3, T3 r7/r9, T4 r11/r13 | all noise (keep) |
| 22:36 | Astra review fixes on vs off, 800 games | −0.01 (rarely fire; kept as safety) |
| 22:36 | sim arrangement on vs off, 200 games | −0.03 ± 0.15 (noise; kept, worst seat 848 ms) |
| 22:46 | lift v2.75 (half-step from v2.5) vs v2.5, 800 games | −0.19 ± 0.11 |
| 22:52 | lift v2.875 (third half-step) vs v2.5 | −0.16 (v2.75 was −0.19: converged, keep v2.75) |
| 22:59 | with v2.75: lift weight 10 / 12 / 20 / 25 / 30 / 40 / 60 / 100 / 150 (base 15), 600 games | +0.63 / +0.26 / −0.37 / −0.58 / −0.85 / −1.03 / −1.29 / −1.45 / −1.41 |
| 22:59 | tribe preferences off (Badger and Locust 0) | +0.52 (worse: keep) |
| 23:08 | vs FlowBot, weight 60 / 15 | 2.51 / 2.50 (both saturated: all top-4) |
| 23:10 | vs v1 bot, weight 60 / 15 (gap, max +4) | +3.95 / +3.90 |
| 23:22 | weight 100 vs 60 head-to-head | −0.23 ± 0.12 (adopt 100) |
| 23:22 | sim arrangement on vs off at weight 100, 200 games | +0.08 ± 0.17 (noise; worst seat 851 ms) |
| 23:30 | lift re-measured under the weight-100 policy (half-step) vs s4 | +0.22 (worse: keep v2.75) |
| 23:52 | re-check at weight 100, 600 games: T2 r3 / T3 r7 / T3 r9 / T4 r11 | −0.30 / −0.16 / −0.07 / +0.03 |
| 23:52 | tier_w 5 / 20, stat_w 1, triple 50, pair 12, syn 4, replace 10, refresh 15, Sharpen to r10 | all within ±0.12 (noise) |
| 23:52 | Seek from tier 3 / Locust pref 0 / Badger pref 0 | +0.68 / +0.22 / −0.11 |
| 23:58 | fresh seeds: T2 r3 / T2 r3 + T3 r7 / T2 r2 / Locust pref 10 | −0.24 / −0.24 / +0.93 / −0.07 (adopt T2 at r3) |
| 00:08 | lift re-measured again at weight 100 (2,400 games, step 0.3) vs s4 | +0.15 (worse: keep v2.75; re-measuring stops helping once the bot buys by the table) |
| 00:21 | lift weight 70 / 150; T3 r7 / r9; spare mode off; Sharpen to r5; golden bonus 30; Colonel stock off | +0.17 / −0.01; −0.09 / +0.34; +0.22; +0.04; +0.20; 0.000 (identical games: the Colonel stock never fires, since a full board already gates buys) |
| 00:25 | T3 at r7, 1,200 games, fresh seeds | +0.04 ± 0.05 (noise: keep r8) |
| 00:27 | **hand-in bot vs blue-s1 snapshot** (800 games, sim off both) | **3.17 vs 5.83 (−2.66 ± 0.08)** |
| 00:38 | stat weight for held units ×0 / ×2 / ×3 / ×6 (base ×1) | +0.60 / −0.09 / +0.21 / +0.88 (keep ×1; not in the bot) |
| 00:48 | sim arrangement on vs off, 400 games (final bot) | −0.10 ± 0.14 (all runs together lean slightly to on; kept; worst seat 851 ms) |
| 00:04 | **practice s2 vs red (1,000 games; blue-s2 = bf8c3317, the hand-in bot)** | **blue 3.51, red 5.49** (+1.98 ± 0.08; red changed too) |
| 00:56 | overfit check vs the s1 bot (a different policy): weight 40 / weight 100 | −2.31 / −2.66 (weight 100 is not overfitted to mirror matches) |

Card values by measured lift: each card's value includes −100 × (mean final placement of seats
holding it on a round 4/6/9/12 board − the mean). The table is re-measured from self-play under
the current policy and moved toward the new measurement (policy iteration: one full step, then
half-steps); see tools/scripts/lift.py and the caveat under "Cards valued most and least".

## Models used, and what we learned

- **Opus 5.5 (me, lead)**: wrote the bot and ran the tuning loop.
- **Claude sub-agent (Opus, high), code review against the card rules.** Brief: read-only, the
  bot files, rules docs and card files to read, a list of things to look for, "ranked list, cite
  line numbers, 1–3 line fixes, no redesigns". Result: 12 concrete issues in 8 minutes, all
  checkable; the fixes it suggested were worth −0.23 places together. Very good value.
- **Claude sub-agent (Opus, high), offline card-power table by simulation.** Open-ended research
  with a compute budget; its first run hit its own 15-minute timeout and it then sat waiting on a
  monitor for an hour without reporting. Needed a nudge with a smaller scope. Lesson: give
  research agents a wall-clock deadline and ask for partial results written as they go.
- **Codex gpt-6.2-sol (high), a log-analysis script.** Brief: one file, exact CLI, exact output
  sections, finish line ("run it on this dir, histogram sums to seat count"). It followed the
  spec exactly, tested both bots and the edge cases it was told to, reported the first 40 lines.
  About 15 minutes. Its completion did not wake this thread; I only saw it with `task_status`
  (the referee found the completion is queued behind the lead's running turn).
- **Codex gpt-6.2-astra (high), read-only code review.** Brief: files, rules docs, four ranked
  categories (panics/hangs, clock, rule mistakes, missed value), "skip style and nits", at most 10
  findings with file:line and a 1–5 line fix, 25-minute limit, no builds. About 7 minutes. Result:
  no panics or hangs; 10 findings, each with a concrete game situation and engine-file citations
  (it read the engine to check the rules, unasked but useful). Several were real but rare; four
  cheap ones were taken (full-hand stall, clock guard inside fight scoring, no refresh past a
  visible third copy, Seek vs Forage by hand room). Compared with the Opus reviewer: more careful
  about stating what it had not measured ("risks, not measured incidents"), findings deeper in
  the engine, fewer of them high-impact.

**What we learned about the 6.2 models (first day).** Both did best with a closed brief: the
files, the exact output, a finish line and a time limit. Sol followed a spec to the letter and
checked what it was told to check, no more. Astra went further on its own (read engine code to
confirm rules) and was careful to separate measured facts from risks; its findings were correct
but mostly rare cases. Neither needed a follow-up. For open-ended work (the card-power research)
we used Claude, and that was the one task that stalled; on this evidence, bounded tasks go to
Codex, and open research needs a deadline and partial results whichever model does it.

## Cards valued most and least

Values come from two sources: the hand-written table (`src/cards.rs`: row, text bonus, per-turn
scaling) and, much stronger, the measured lift (`src/lift.rs`): how much lower (better) the final
placement of seats holding the card was, in self-play under the current policy. Weight 100 points
per place; a shop tier is worth 10, so at the end the measured lift dominates and the hand-written
values mostly break ties. The weight was tuned up from 4 in steps; every step to 100 helped.

From the final table (v2.75), in places relative to the mean when held:

**Valued most**: The Colonel (−1.06), Regimental Sergeant-Major (−0.84), Needle Pikeman (−0.71),
Field Marshal (−0.48), Orchard Stripper (−0.46), Elder Mother (−0.42), Brigadier (−0.38), Mother
Midden (−0.38), Old Brock (−0.33), Skin-shedder (−0.33), Lieutenant (−0.29), Blackthorn Sapling
(−0.28). Pigeons lead: their Orders and buffs compound over turns, and the bot plays
Lance-corporal's and Grenadier Guard's Orders every turn. Most of the top cards are high-tier
units that end games.

**Valued least**: Horde-runner (+1.17, a tier-1 Locust the bot held when it was already losing),
Hopper tokens (+0.88), Shrew Harrier (+0.85), Harvest Piper (+0.81), Shrew Cutpurse (+0.76),
Thimble Captain (+0.73), Relic-seeker (+0.69), Toothpick Ballista and Dormouse Cook (+0.58),
Nettle Skirmisher (+0.57), Recruiting Sergeant and Master-at-Arms (+0.47). Mice as a whole
underperform under this bot; low-tier bodies held late mark a seat that is behind.

Caveat: lift is correlation, not cause. A card bought by seats that are already behind looks bad.
Re-measuring under each new policy (policy iteration) corrects some of this; one full
replacement helped a lot (−1.45), a second full replacement made it worse (+0.33). Half-steps
helped twice (−0.21, −0.19), then stopped helping (−0.16 vs −0.19), and at weight 100 every
re-measure made the bot worse (+0.22, +0.15): once the bot buys almost only by the table, which
seats hold a card says more about the table than about the card. Final table: v2.75.

## Effort by tribe

The bot is tribe-agnostic by design; tribe work is in card knowledge and a few combos:

- **Pigeons**: the most. Orders before buying (Lance-corporal every turn, Grenadier Guard's Guard
  post once), Colonel's Reserve (stock 3 extra units in hand), RSM/Colour-sergeant rows.
- **Locusts**: feeding Hoppers to Granary Glutton and Gorger; War-drummer in F2 with death-effect
  units behind it; tuned tribe preference +6.
- **Briars**: Bury the best shop unit it is not buying.
- **Badgers**: rows only (Squires and lenders back); tuned preference −6 (they lost in self-play).
- **Mice**: rows only; no special play. Measured lift says they underperform under this bot.

## Bugs and exploits

- No engine bugs found, none used. The bot reads only BotView and Sim.
- Our own bugs found and fixed: a negative tribe preference was ignored (max() from 0); a `pkill
  -f` in our own scripts killed our shell (tooling only); a full hand plus a full board of better
  units could stop buying for the rest of a game (Astra review; fixed with a sell).
- Harness and tooling: a T3 delegate's completion notice did not wake the lead thread while its
  turn was running (reported to the referee; the completion is queued behind the running turn).

## Tokens and runs

- Lead: Opus 5.5, one long session (compacted once).
- Claude sub-agents: 2 (Opus, high): rules review (about 180k tokens), card-power research (about
  152k tokens, partial result).
- Codex runs: 2. gpt-6.2-sol (high), log-analysis script, about 15 minutes. gpt-6.2-astra (high),
  read-only code review, about 7 minutes.
- Compute: self-play A/B on the 2 allowed cores throughout; over 50,000 self-play games (53,000 still on disk, more overwritten) in
  total, all in `out/`.

## Round 2 (since match 1)

Match 1: blue 4.285, red 4.715 (+0.43 ± 0.09 for blue). Practice from here is against red's
match 1 bot (`red-m1`) through the referee's play.sh, 200–400 games a run (±0.2 / ±0.15).

What the practice games showed (our seats vs red-m1, from games.jsonl, never red's reports):
- Red's boards carry 25–30% more stats every round; we still place better.
- Head-to-head fights by round: we lose round 3 (31% vs 64%; the turn we go to tier 2) and
  rounds 4–5, win rounds 8–12 (up to 65%), and lose from round 13 on as red's boards outscale.
- Our Mouse and Briar final boards place about 2.6, but forcing them with tribe preference
  (Mouse +6, Briar +6, Locust 0) made the bot worse (−0.10 vs −0.39 baseline, same seeds).

**Fable review** (06:33, one question: where blue loses placement against red-m1 and the three
changes most likely to gain it; read-only on our folder and practice output, no reports.jsonl):
found the late game is lost to Seek/Forage. At round 12 the bot spends about 25 of 32 gold on
Discover spells for about 10 picks, of which 1.4 reach the board; the rest fill the hand, and the
full-hand rule then sells grown board units. Proposed: no Seek/Forage, Sharpen whenever
affordable, and a different late tier schedule. About 5 minutes, 119k tokens.

**Astra review** (07:05, one question: from the observable practice data only, how red-m1 grows
its boards late and the three changes most likely to copy or counter it; read-only, no
reports.jsonl, no builds). About 7 minutes. Found: (1) we cast Triple Reward at tier 4 the turn
before reaching tier 5, so its Discover comes from a tier lower than it could; red fields
Regimental Sergeant-Major far more (74 seats vs 8) and its tier-6 boards with it grow 160 stats
a round vs 90; (2) 12,385 of our 17,250 late sales happen with a full hand, selling units that
grow every fight (933 Flying Aces sold after round 9): the automatic full-hand sell from the
round 1 Astra review does harm; (3) Hazel Coppicer is strong on boards with several returners.
Red's late growth comes almost entirely from units growing in place (+65 of +72 stats a turn).
Acted on (1) and (2), together with no Seek/Forage (so the hand fills less).

| Time | Variant vs red-m1 (we are "red" in play.sh output) | Our gap (ours minus red-m1) |
|---|---|---|
| 06:11 | baseline (blue-m1 bot), 200 games | −0.39 ± 0.21 |
| 06:22 | tribe pref Mouse +6, Briar +6, Locust 0 (same seeds) | −0.10 ± 0.24 (worse) |
| 06:42 | baseline, 400 games, new seeds (all later rows use these seeds) | −0.59 ± 0.16 |
| 07:01 | Fable's fix: no Seek/Forage, Sharpen whenever affordable (checked in the logs: 0 Seek/Forage buys, 2.5× late Sharpens) | −0.58 ± 0.16 (no change) |
| 07:33 | Astra's fixes + no Seek/Forage: hold Triple Reward the turn before an upgrade, no automatic full-hand sell | −0.60 ± 0.17 (no change) |
| 07:52 | tier 2 at round 4 (round 3 is where we lose most fights) | −0.24 ± 0.17 (worse) |
| 08:11 | card table re-measured from our seats in 1,200 games vs red-m1 (half-step) | +0.01 ± 0.16 (much worse) |
| 08:32 | late levelling like red: tier 4 at round 10, tier 5 at 12 | −0.30 ± 0.16 (worse) |
| 08:51 | lift weight 150 (base 100) | −0.66 ± 0.16 (+0.07 better, within noise) |
| 09:14 | think harder: 150 ms per-turn search cap, 5 fight seeds (base 80 ms, 3) | −0.62 ± 0.15 (noise; worst seat 971 ms of 1,000: too close, rejected) |
| 09:33 | lift weight 200 | −0.42 ± 0.16 (worse; so weight 150's +0.07 was noise: keep 100) |

Practice s3 (red-s3 against blue-s3, the match 1 bot): red 4.27, blue 4.73 (red ahead by 0.45).
Red improved a lot after match 1; nothing we tried against red-m1 beat our match 1 bot.

**Hand-in for match 2:** the match 1 bot unchanged. Of eleven variants tested against red-m1,
none was better outside the noise; four were clearly worse (Mouse/Briar lean, tier 2 at round
4, red-style late levelling, card table re-measured against red). The fixes the two reviewers
found (Seek/Forage waste, full-hand sells, Triple Reward timing) are real in the logs but did
not change placement, so they stay out. Round 2 added a re-runnable card-table rebuild script
for the coming balance changes.

## What carries over to changed cards (the owner's 19 Nov note)

**Rebuilds itself, no code change:**
- The measured card values (`src/lift.rs`, the dominant term at weight 100). They come from
  self-play only: `tools/scripts/rebuild_lift.sh <steps>` plays self-play games, measures each
  card's placement lift and rebuilds the table (one full step, then half-steps; A/B each new
  table against the previous one before keeping it). A changed card's value moves with its
  measured effect on placement; a new card starts at 0 and is measured like the others.
- Everything read from the game itself each turn: tiers, prices, stats, legal actions,
  triples, Discover options, upgrade costs.
- Board arrangement by simulated fights against the boards we have seen (eval.rs), which
  uses the engine's own combat and so sees any changed numbers at once.

**Needs re-tuning (a short self-play sweep, same tools):** the upgrade schedule, tribe
preferences, lift weight and the spell switches (Sharpen until round 7, Seek/Forage from tier
4). These are numbers chosen by A/B for today's economy and card pool; `tools/src/bin/ab.rs`
plus `out/ab/sweepb.sh` re-tunes each in minutes of CPU.

**Hand-written, would go stale:** `src/cards.rs` (per card: preferred row, a text bonus, a
per-turn growth bonus) and a few card-specific rules in lib.rs (feeding Hoppers to Glutton and
Gorger, War-drummer rows, Pigeon Orders, Bury). These are small next to the measured term; a
changed card keeps its old hint until someone edits it. The general direction we'd take next:
derive the row preference from simulated fights (try the unit front and back) instead of
writing it down, so that part also rebuilds from the engine.

