# Plan: the scale rework (9 Nov 2026, draft for review)

Why: `fundamentals.md`. The owner's words: notes 2026-11-09a, b, c and d. The core of them:

> "our power budgeting across the board is very, very much too low" … "Large amounts of design need to be completely reworked, and that's okay." (9a)

> "If it's not fun, it's not a game … rewards give the player power, always." (9c)

> "rely far more on empirical simulation data compared to observational bot play" … "I'm more concerned about the shape of the curve … the distribution of how frequently that happens." (9d)

The aim is a game whose power curve compounds and has a tail, where rewards feel like progress, where carries can be answered, and where tribes sit within an order of magnitude of each other. It is measured with sims of strong play, not with bot lobbies. Then build 8 goes to fresh playtesters.

Rules that hold throughout:
- At most two code branches open at once.
- Every code step passes the gate and a fresh scope review before it merges.
- Godot runs one or two at a time, each capped at 3 GB. Workflow agents never run Godot; Sol does.
- Every path choice in steps 2–4 goes to adversarial critics before it is adopted.

## Step 0: the measurement harness (Sol, branch `ideation/harness`)

The tool everything else rests on. It has four parts:
1. **Combat-start snapshots:** every unit's stats at the start of combat, after auras, including held bodies, Eggs and Bellies. Plus the biggest unit's share of the board. Logged in the bench and in fixtures.
2. **Scripted strong lines:** two or three per tribe (tempo, fast tier, economy or engine), played through the real shop and pool on seeded sequences. Each snapshots its board, gold, tier and Health at rounds 6, 8, 10, 12, 14 and 16. Health comes from a damage model calibrated on the lobby data and the line's win rate against the field.
3. **Hindsight search:** on the same seed, search the buys for the strongest reachable board. This is the upper bound a strong player approaches.
4. **Field fights:** each board fights a sampled field of boards from the same round, sides swapped. Layouts are sampled, including the existing placer's scout-adapted layout. A board's strength is its field win rate.

It reports the curve-shape metrics (S1 below) and each line's distribution of field win rates.

**Done when** it runs deterministic from seeds, and on today's pool reproduces today's flat curve (within the lobby data's band at rounds 8–16) in under an hour. Its scope review checks that it measures what this plan says.

## Step 1: the reference and the target (workflow plus orchestrator)

- `evidence/reference-curves.md`: Battlegrounds medians, spread and tail by turn, for the September 2025 and November 2026 eras, from the audit's Firestone pull and 129 replays, with sources and confidence. Galaxy as far as the VOD trial reaches.
- **Target v1:** the September 2025 shape, as set in `fundamentals.md` §3. The owner may pick another era (question 1).

## Step 2: lever experiments on today's pool (Sol runs, critics judge)

No redesign yet. Each lever is a data or config change, run through the harness:

| Lever | What changes |
|---|---|
| L1 | Caps off (Dozey, Treasurer, Rings, Supper, Toad and the rest). |
| L2 | One uncapped "this game" engine per tribe. Example: the Harvest Supper tribe bonus grows with each cast and has no cap. |
| L3 | Combat-only payoffs made permanent. |
| L4 | Answers: two or three that target the biggest enemy, and proportional versions of the flat debuffs. |
| L5 | Stat-holding keywords on a few cards: damage reduction, a shield, cleave. |
| L6 | Damage and Health variants, so winners finish by rounds 14–16. Includes survivors dealing 2 each from round 10. |

Each lever, alone and in sensible combinations, reports:
- **S1 curve shape:** p50, p90 and p99 board strength by round, the share of boards at twice the median, the biggest unit's share, and stats per gold.
- **S2 invest against tempo:** buy the engine or the best tempo unit on the same seed, then fight the field 0–5 turns later. Target: behind at once, level in 2–3 turns, ahead after.
- **S3 greed against tempo:** an economy line against a tempo line on the same seeds. Health at round 8, power at rounds 11 and 14, and how often greed ends ahead.
- **S4 carry against answer:** each tribe's best round 11 and round 14 carry against field boards with 0, 1 and 2 answers. The carry's owner re-places after the scout.
- **Upsets:** the share of rounds 10–14 fights won by the side with fewer stats.
- **Scripted-line lobbies:** eight seats, each running a line from the set, with real fights and real damage. They report game length, how often the round 8 leader wins, and comebacks from behind at round 8.
- **Readability:** a phone-size screenshot with the largest numbers the lever produces.

**Done when** a critic panel (systems, motivation and a devil's advocate) has picked which levers to adopt, with evidence, and the curve with them adopted lands near target v1.

## Step 3: the scale spec and the new budget (orchestrator, then plan-interrogate)

- **Scale spec v2:** the target shape, the adopted levers, the damage table and Health, and the variance budget.
- **The new costing model:**
  - **Strength:** a card's strength is its effect on field win rate at its opening round and 3 turns later.
  - **Payoffs:** priced by their contribution to the curve.
  - **Tests:** a "too small" test as well as a "too big" one.
  - **Caps:** rate limits only where sims show common snowballs.
  - **Gold table:** its stats-per-gold values are re-set from the measured curve.

  `power-budget.md` gets a v2 and the old one is marked superseded.
- **Done means rewritten:**
  - The depth bar moves to the harness: strategies' field win-rate distributions, and tribes within an order of magnitude.
  - Lobby spread stays only as a sanity line.
  - The reasons are logged in DECISIONS.md.

## Step 4: pass 3, the tribe redesign (design workflows, Sol builds, two tribes at a time)

For each tribe, a design panel runs:
1. Three or more independent designers, briefed with the target shape, the condition/payoff/enabler frame, and the tribe's identity. No price table.
2. Judges with harness numbers.
3. A synthesis that keeps the best ideas from the runners-up.

Every tribe gets:
- a compounding, permanent, visible engine;
- a route to a carry;
- payoffs mostly permanent;
- tribe-only payoffs that say so.

Neutrals get answers and a few stat-holding keywords. Birds and Fairies go first, then Bog and Hunters, then Oozes and Hedgerow.

**Each tribe passes when:**
- **S1:** its best line is inside the target band;
- **S2:** its engine pays back on the target clock;
- **S4:** a common board with one answer beats its carry at least 30% of the time at its round;
- **Critic:** a fun critic with the reward lens doesn't flag it.

Rare highrolls don't fail a card (owner, 9d).

## Step 5: opponents worth facing (Sol)

- **Strong-field mode:** each round's opponent is drawn from that round's constructed field, so a human meets strong boards, greed lines and answers. It is the default for playtests.
- **Bots:**
  - value delayed payoffs through short rollouts;
  - climb when it pays, not on a fixed curve;
  - save when saving pays;
  - buy answers when the scout shows a carry.
- **Ghosts:** the strongest field board for that round, not a frozen dead board.

## Step 6: build 8, then playtest round 6 (cloud playtesters, then fixes)

- **Lenses:** round 6's five lenses plus a reward lens: when did you feel stronger, and when did nothing you did matter?
- **Reviewers:** three fresh reviewers play full games. Their agreed items are fixed, and the loop repeats until all three judge it very good.
- **Then the remaining Done means evidence:** the 2,000-game soak, the 20 scripted UI games, Windows and Android builds, and the export to `/data/bramble-builds/` with `latest` pointing at it.

## What would change this plan

- If the harness can't reproduce today's curve, step 2 waits until it can.
- If no lever set reaches target v1 without common snowballs, the variance levers (L4 and L5, plus summons) grow before more engines are added.
- If 4–5 digit numbers don't read at phone size, the target era drops a step.
