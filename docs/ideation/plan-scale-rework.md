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

**Steps from here:**
1. **Merge what is finished.**
   - The harness, once its cuts are fixed.
   - Wave 1 (Birds and Fairies), gated on the merged tree. Its only reason to wait was 8a.
   - Strong-field mode, once its fixes pass a follow-up review.
2. **Build wave 2 on Sol.**
   - **Pool rules first, as one commit:** see-through, the one permanent-gain queue, and the general loop guards. The Start of Combat order is already in.
   - **Then two branches:**
     - W2a: Bog and Hunters.
     - W2b: Oozes, the Hedgerow light pass and the neutrals. The neutrals: keep 9, change 4, add Shieldbug and Click Beetle, and retire the 38 prototype bodies last.
   - One reviewed commit per tribe, each with its line JSON and Hard-bot fixes, so the bot doesn't sell its own engine.
   - Every engine rate is a dial, with two presets:
     - **A:** the September 2025 shape, typical about 500 at R12;
     - **B:** steeper, typical about 900 at R12. Fairies and Oozes stay at their design size, and the other four are raised.
3. **Meanwhile, three things in parallel:**
   - **A wave 1 fun probe** on cloud machines: three reward-lens playtesters, Birds and Fairies games. Read moments, not win rates, because the four old tribes are flat. **Go/no-go:** if fewer than two of three name a moment they felt stronger (the card, the round, the size), hold the wave 2 merges and triage.
   - **Designed setups** from the harness generator: carry against wide, distribution against totals, answers against carries, then wave 1 boards.
   - **Offline damage and Health replay:** a shortlist of 2–3 tables in which winners finish by R14–16.
4. **Measure the full pass 3 pool:**
   - 150 or more line lobbies per preset, sharded to cloud machines;
   - fields at R6–16;
   - designed setups (Granny, the Whistlers, carries against answers);
   - a splash audit;
   - the damage table confirmed;
   - a 200-game soak;
   - the strong-field library recaptured on the full pool, from top-4 trajectories.

   Then Done means 2 is rewritten onto the harness, with lobby spread as the sanity line.
5. **Checkpoint 1, now on the full pass 3 pool.**
   - Three or more reward-lens playtesters play both presets against the strong field.
   - The build goes on the portal for the owner, on Windows and Android.
   - The era is picked from play first, sims second.
   - The owner hears plainly whether the scale problem is fixed.
6. **Step 4 as written:** opponents, build 8, playtest round 6, and the remaining Done means evidence.

**The guardrail band before the owner plays** (each preset). The bands are wide and fun comes first, so a miss is triaged, not an automatic fail:
- **Growth and size:**
  - The median grows ×1.3 or more a round from R8 to R14.
  - Preset A's R12 median is 300–900.
- **The tail:**
  - 8–25% of R10–14 boards are at twice the median or more.
  - The top 1% is at most 20× the median.
- **Concentration:** the biggest unit holds 25–45% of its board.
- **Snowballs and comebacks:**
  - The R8 leader wins at most 35% of lobbies.
  - A board below the median at R8 reaches the top 2 at least 12% of the time.
  - The winner is 5× the runner-up in at most 10% of lobbies.
- **Game length:** the median winner finishes by R14–16.
- **Tribes:**
  - Each tribe's best line is within 3× of the others in field win rate.
  - No card is on more than half the winning boards.
- **Fights and progress:**
  - 15% or more of R10–14 field pairs are uncertain (20–80%).
  - Tier-ups arrive at 1.0× the median unit or more.
- **Opponents:** strong-field rivals are 0.7–1.5× the target. Otherwise snowball reports don't count.
- **Play:** every tester names a moment they felt stronger, and fewer than a third of games feel decided by R9.

**Cut from v2:**
- the remaining protected sweep on today's pool;
- build 8a on today's pool (kept only as a diagnostic, if both presets miss for unclear reasons);
- checkpoint 2 as a separate step (the wave 1 probe covers its purpose);
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
