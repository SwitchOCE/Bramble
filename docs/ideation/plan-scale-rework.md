# Plan: the scale rework (v3, 9 Nov 2026 evening; v2 below for the record)

## v3: what changed and why

**The evidence.** Taken from the harness on today's pool (`ideation/harness`, `evidence/lever-sweep.md`). The figures below were checked by the orchestrator from the lobby CSVs.
- **Caps off (both):** gives a tail. 11% of boards are at twice the median by R16, and the top 1% reach 8,000.
  - The median stays linear: 133 at R12, 209 at R16.
  - Winners finish at R19.
  - Turning off either cap alone does nothing.
- **Lever builds** (the synthetic engine at 25% and 50%):
  - The median final board barely moves: 141–148, against 137 today.
  - The lobby winner is at least 5× the runner-up in 26–42% of lobbies (0% today).
  - Winners still finish at R19.

  One synthetic card on a flat pool is a lottery, not an era. Bot lines also lose to Hard on both lever builds, so the sweep's engine reads would be lower bounds.
- **Four adversarial critics** (fun, method, delivery, devil's advocate; `evidence/path-critics.json`) all chose the same path. The sweep and build 8a on today's pool would tune cards that never ship (amendment 12) and put playtesters on a pool that is about to be replaced. The median has to come from content, and wave 1 already exists and was built in about 2.5 hours.

**Steps from here** (approved 9 Nov after plan-interrogate, `evidence/plan-v3-interrogate.md`, with its changes taken):
1. **Merge what is finished, in this order:**
   - Wave 1 (Birds and Fairies), gated on the merged tree. It sits behind `pass3_content`, so players see nothing new until that is on.
   - The harness, after a follow-up review of everything since `9af89c2`, including the designed-setup driver.
   - Strong-field mode, after its fixes pass a follow-up review. Its tests build their content manifest from current content, so content commits don't break them. The shipped library is recaptured once, at step 5. Until then the mode stays out of player builds.
2. **Build wave 2 on Sol.**
   - **Pool rules first, as one commit:**
     - the one permanent-gain queue;
     - any loop guards wave 1 lacks;
     - hero powers and spells scaled by the board, switched on in both presets;
     - Harvest Supper's late ceiling lifted.
   - **Then W2a:** Bog and Hunters.
   - **Then W2b,** rebased onto W2a: Oozes, the Hedgerow light pass and the neutrals. The neutrals: keep 9, change 4, add Shieldbug and Click Beetle, and retire the 38 prototype bodies last.
   - One reviewed commit per tribe, each with its line JSON and Hard-bot fixes. One integration gate on the merged tree.
   - Every engine rate is a dial. **Generous first** (owner, 9 Nov: `docs/design/owner-notes/2026-11-09h-generous-power-first.md`): dials start at the generous end and are cut back on evidence, never raised from weak. The presets:
     - **B, the default:** about 900 at R12. Fairies and Oozes stay at their design size (the Fetch twin is full), and the other four are raised to match.
     - **C, overly generous:** B's engine rates doubled, about 1,800 at R12. This is the start the owner recommends, and it shows which dial to cut.
     - **A, the fallback only:** the September 2025 shape, about 500 at R12, the size the owner doubted ("50/50 may be too small"). It is played only if both B and C fail for reasons that a smaller scale would fix.

     A paper workflow writes B's and C's values during wave 2. Every new dial lands at B's value or above.
3. **The UI declutter** (owner, 9 Nov: `docs/design/owner-notes/2026-11-09e-ui-clutter-and-tutorials.md`):
   - A workflow audit produces the spec: cut, move or animate every element, plus what the tutorial must teach.
   - A UI branch builds it in batches, with before/after screenshots and a reviewer briefed with the note.
   - It lands before checkpoint 1, with the tutorial and how-to-play updated.
4. **Meanwhile, three things in parallel:**
   - **A wave 1 fun probe** on cloud machines: three reward-lens playtesters, each playing two Birds or Fairies games and one old-tribe game as a control, against Hard.
     - Each named moment is checked against the game log, board before and after. Read moments, not win rates.
     - **Go/no-go before any wave 2 merge:** if fewer than two of three name a logged moment that beats their control game, hold and triage.
   - **Designed setups** from the harness generator. Each runs against bars set before it runs, and they outrank line lobbies when the two disagree (09d).
     - **First:** carry against wide, distribution against totals, answers against carries.
     - **Then wave 1's typical boards, as an accounting check:** if Birds' or Fairies' real R12 board is outside 0.5–2× its paper figure, fix the accounting in the wave 2 briefs before their dial values land.
   - **Offline damage and Health replay:** a shortlist of 2–3 tables in which winners finish by R14–16.
5. **Measure the full pass 3 pool, locally** (cloud shards only if both slots are busy):
   - first, the line-strength gate on the new lines against `hard_field`;
   - 150 or more line lobbies per preset (B and C);
   - fields at R6–16;
   - designed setups against predeclared bars: Granny, the Whistlers, and each tribe's carry against a common board with one answer;
   - the splash audit, as a lobby output;
   - the damage table confirmed;
   - a 200-game soak;
   - the strong-field library recaptured once, from top-4 trajectories.

   The checkpoint config: pass 3 on, caps off, loop guards on, hero and spell scaling on, the chosen damage table.
6. **Checkpoint 1 on the full pass 3 pool.**
   - Three or more reward-lens playtesters play B and C blind, in counterbalanced order, against the strong field, and say which they prefer and why. The cut back from C is made dial by dial, on what they and the measurements show.
   - The portal build (Windows and Android) carries presets B and C as a setting (A only as a fallback), with the agents' pick as the default.
   - The owner hears plainly whether the scale problem is fixed.
7. **Step 4 as written:** opponents, build 8, playtest round 6 and the remaining Done means evidence. Done means 2 is rewritten onto the harness here, before build 8 sign-off.

**The guardrail band before the owner plays** (each preset). The bands are wide and fun comes first, so a miss is triaged, not an automatic fail. The bars marked *guard* already pass on today's flat pool. Only the others can show the fix.
- **Growth and size:**
  - The median grows ×1.3 or more a round from R8 to R14.
  - The R12 median is 700–1,800 for B and 1,400–3,600 for C (A, if used: 300–900).
  - **Generous first:** a high total alone never fails a preset. A dial is cut only for a fun problem it causes: one line winning whatever the player chooses, runaway snowballs in most lobbies, or fights decided before they start.
- **The tail:**
  - 8–25% of R10–14 boards are at twice the median or more.
  - The top 1% is *reported only* (09d).
- **Concentration:**
  - The biggest unit holds 30–45% of its board.
  - **Designed bar, set before the run:** at R12, a carry with its holder (Shield, Damage Reduction or Cleave) beats an even board of the same total at least 50% of the time. Today's figure is 0–15%.
- **Snowballs and comebacks** (*guard*):
  - The R8 leader wins at most 35% of lobbies.
  - A board below the median at R8 reaches the top 2 at least 12% of the time.
  - The winner is 5× the runner-up in at most 10% of lobbies, with both boards compared at the same round.
- **Game length:** the median winner finishes by R14–16.
- **Tribes:**
  - Each tribe's best line is within 3× of the others in field win rate, pooled over R10–16, and cross-checked with designed typical boards.
  - No card is on more than half the winning boards.
- **Fights** (*guard*): 15% or more of R10–14 field pairs are uncertain (20–80%).
- **Tier-ups:** a new tier-up unit, at combat start, beats the player's median unit of the round before at least 60% of the time. The arrival-ratio bar is dropped, because it already passes today.
- **Opponents:** strong-field rivals are 0.7–1.5× the target. Otherwise snowball reports don't count.
- **Play:**
  - Every tester names a logged moment they felt stronger.
  - Fewer than a third of games feel decided by R9.
  - Testers would turn off nothing on the main screen after their third game.

**Cut from v2:**
- the remaining protected sweep on today's pool;
- build 8a on today's pool (kept only as a diagnostic, if both presets miss for unclear reasons);
- checkpoint 2 as a separate step: the wave 1 probe covers its purpose. Decisions that waited on "checkpoint 2" (the Jack Daw comparison, deleting the frozen pass 2 tests) now wait on step 5;
- line-against-Hard placements as tribe evidence.

The rules for the whole rework (below) are unchanged.

---

# v2 (9 Nov 2026), kept for the record

Why: `fundamentals.md`. The owner's words are in notes 2026-11-09a–d:
- "our power budgeting across the board is very, very much too low" (9a)
- "test it and see if it creates a good game. Does it feel like it has a nice flow?" (9c)
- "If it's not fun, it's not a game." (9c)
- "rely far more on empirical simulation data compared to observational bot play" (9d)
- "the shape of the curve … the distribution of how frequently that happens" (9d)

v1 went to plan-interrogate and three adversarial critics (fun, method and speed): `evidence/fundamentals-audit/plan-review.json`. v2 takes most of their changes. The list at the end says what was taken and what wasn't.

**Aim:** a game whose power compounds and has a rare tail; where tier-ups and engines feel like progress; where clever play and answers can beat a stat lead; and where tribes sit within an order of magnitude. Measured mainly on strong scripted play, checked by people playing early, then delivered as build 8.

## Rules for the whole rework
- **Fun first.** Designs are ranked on reward moments, the decisions they create and tribe identity. Sim numbers are a guardrail band, not the target (9c).
- **Rare highrolls never fail work.** A card or tribe fails on how often it breaks games, not on its best 1% (9d). Every reviewer brief says so.
- **Bot lobbies are only a sanity line.** Done means 2 is rewritten at step 2 (below).
- **Gates:** at most two code branches at once. Each code step passes the gate and a fresh scope review. Local Godot runs at most two at a time, each capped at 3 GB. Heavy sweeps go to cloud VMs (owner-agreed, 8 Nov). Workflow agents never run Godot.
- **Critics** sit at the decision points (the lever pick, each tribe's design), not on every step.
- After each checkpoint, the owner hears plainly whether the scale problem is fixed.

## Step 1: three tracks start together

**Track A, the harness (Sol, branch `ideation/harness`).** It reuses `tools/sim/bench.gd` lobbies.
- **Combat-start snapshots:** every unit after auras, including held bodies, Eggs and Bellies; the biggest unit's share; full fight-input capture (board, slots, fight rules, tier, hero effects) through the path ghosts use.
- **Line policies:** profiles over the Hard brain. Each has a per-tribe card priority list, a climb schedule, a save threshold, a committed tribe and an engine flag. They live in `BenchSuites.REGISTRY`, two per tribe (tempo; engine or carry) plus a shared fast-tier/economy profile. Every tribe gets the same automated knob-tuning budget, and the report shows the gain from tuning.
- **All-line lobbies:** eight seats running line policies, with real fights, damage, pool depletion and heroes. About 500–1,000 lobbies per configuration.
- **Field fights:** round robin a 64-board field per round (rounds 6–16) drawn from those lobbies. Each board uses the placer's blind layout, in both orientations. The output is a line-by-line win matrix with the field's weights.
- **Offline damage replay:** Health and damage-table variants are re-scored from the logged fight results, with no new Godot runs.
- **Metrics:** feel in stats (own-board growth per turn, a tier-up's size against the player's own board, stats per gold), and snowball and entropy in outcomes (below). Shop RNG either derives per (seat, round, roll) for paired comparisons, or comparisons are treated as unpaired, with sample sizes set before each run.

Done when the known-answer tests pass:
1. A captured fight re-fought gives the in-game result exactly.
2. A line seat beats Hard in head-to-head.
3. A planted broken card (synthetic +X/+X a turn) shows as a tail and dominates; a planted null card changes nothing.
4. On today's pool, the lines show the flat shape: straight-line growth, no board at twice the median.

**Track B, shared mechanics (Sol, branch `ideation/mechanics`).** Built once and used both as levers and as final neutral content:
- answers that target the biggest enemy in any row;
- proportional versions of the flat debuffs;
- damage reduction, a shield and cleave;
- caps as a data overlay that can switch on and off;
- a synthetic engine-growth dial and a synthetic proportional-answer dial;
- an economy lever: an income or gold engine that feeds stat buys;
- one doubler-style neutral;
- heroes and spells scaled by the board, not by flat amounts.

It also includes a phone-size render of 4- and 5-digit stats on the 4-3 board. If big numbers don't read, the target era drops a step before anything is built on it.

**Track C, design on paper (workflow agents).**
- `evidence/reference-curves.md`: one table from the audit's Battlegrounds data, with its limits stated. The September 2025 figures are means only, and the replay spread comes from November 2026 games of perfect-game winners.
- Six tribe design panels, run at once:
  - three or more independent designers per tribe;
  - judges ranking on reward moments, decisions and identity, with a critic who tries to break each design;
  - a synthesis.

  Each panel is briefed with the target shape, the condition/payoff/enabler frame, enablers, doublers and capstones, and the tribe's identity. No price table. Each design names its engine's rate as a parameter, names the turn the build comes online and the decision the engine creates, and writes its tribe's line priority list. An independent critic later tries to beat that list.
- **Hedgerow gets a light pass:** caps off, Lollop and the Committee tribe-only, more permanent payoffs. The owner sees "nothing fundamentally too wrong" with it.
- **Portraits start** as soon as names settle (Done means 5).

## Step 2: the lever pick and the scale build (checkpoint 1)

**The sweep.** It runs on today's pool through the harness, mostly on cloud VMs:
- caps off;
- the engine dial;
- the answer dial;
- the new keywords and answers;
- the economy lever;
- damage and Health variants (offline).

S1 and the outcome metrics run for every lever; the full suite runs on the finalists.

**Outcome bars (target v1, the September 2025 shape):**
- Growth compounds from round 8, and a tier-up arrives at or above the player's median unit.
- The round 8 leader wins at most about 30% of line lobbies.
- A board below the median at round 8 still finishes top 2 a fair share of the time.
- A set share of rounds 10–14 field pairs is uncertain (20–80%). Count upsets from answers, scam and placement separately from coin flips, and aim the variance budget at the first kind.
- Winners finish by rounds 14–16.
- Wide bands everywhere. Tribes may have different clocks.

**Done when** one critic panel (systems, motivation, devil's advocate) picks the setting, I write a one-page scale spec, and Done means 2 is rewritten onto the harness, with lobby spread as the sanity line and the reason logged.

**Strong-field mode and the scale build (8a).** Each round's opponent comes from that round's field, held as persistent rival seats with tribes, Health and eliminations, so placement and "how far can I get" still mean something. Ghosts become field boards. Build 8a is today's pool with the adopted levers, in two variants: the September 2025 shape and a steeper one.

Three or more reward-lens playtesters play both variants, and both go on the portal for the owner.

**Checkpoint 1:** does it feel like progress, and are snowballs uncommon? The era is picked from play first, sims second.

## Step 3: build the tribes (Sol, content branch; two waves)

- **Wave 1: Birds and Fairies,** the weakest tribes, built and measured. A playtest of that pair against the strong field is **checkpoint 2**.
- **Wave 2: the other four, together,** one reviewed commit per tribe.

**Each tribe passes when:**
- **Fun bar:** a playtester names a moment they felt stronger, and the build's online turn and engine decision show up in play.
- **Guardrail band:** inside the outcome band, same order of magnitude in field win rate, and no common snowball.
- **Answers:** a common board with one answer can beat its carry at its round (reported, wide band).

The field is refreshed as tribes land, and everything is re-measured once all six are in.

## Step 4: opponents and build 8

- **Opponents:** bot seats run the line policies. Bots buy an answer when the scout shows a carry, and climb when they can afford it. Strong-field mode is the playtest default.
- **Owner's games:** from build 8, they are logged in the snapshot format, so their boards can be placed on the lines' distribution. That is our only strong-player anchor.
- **Build 8 and playtest round 6:** five fresh players with the five lenses plus the reward lens. Agreed items are fixed, the build is delivered, and iteration continues while the owner plays. The remaining Done means evidence (2,000-game soak, 20 scripted UI games, Windows and Android builds, the export with `latest`) runs alongside.
- **Power budget v2** is written afterwards from the measured cards, as guardrails and a "too small" test, not a price list.

## Deferred, with triggers
- **Hindsight search:** when a tribe fails low and the lines look weak.
- **Bot rollouts:** when a playtest shows the bot seats matter.
- **Galaxy VOD curves:** when a design question needs them.
- **The owner's eight-board calibration:** optional, whenever they have ten minutes.

## Review changes: what was taken
- **Taken (method):**
  - lines as Hard-brain profiles in all-line lobbies;
  - fight-input capture and known-answer tests;
  - placer layouts in field fights;
  - outcome gates;
  - offline damage replay;
  - synthetic dials instead of six hand-made engines;
  - RNG pairing;
  - sample sizes set before each run;
  - the owner's games as the anchor.
- **Taken (fun):**
  - a scale build played before the redesign;
  - pick the era from play;
  - fun-first ranking with a positive fun bar;
  - economy, doubler, hero and spell levers;
  - upsets split by kind;
  - comebacks;
  - persistent rival seats.
- **Taken (speed):**
  - three tracks from day one;
  - six design panels at once;
  - shared mechanics built once;
  - a phone check of big numbers first;
  - cloud VMs;
  - portraits started early;
  - budget v2 after the pass;
  - one critic panel at the lever pick.
- **Taken (interrogate):**
  - a defined S1 unit (stats for curves, field win rate for ranking);
  - a numeric snowball bar;
  - a progression bar;
  - L4 and L5 treated as engine work;
  - independent checks on line authors;
  - strong-field Health;
  - the rules moved up front.
- **Not taken:**
  - **All six tribes built in one wave (speed).** Wave 1 (Birds and Fairies, the weakest) is played first, because the fun critic and plan-interrogate both warn against building all six before anyone plays.
  - **Cutting the tier-up check.** Kept, as the progression bar.
