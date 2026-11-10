# What the Quilboar reference taught us

Draft for the owner. Your question (10 Nov): "What have we learned from it? And does it help us improve any of our processes or challenge any of our assumptions?"

What ran: 500 bot lobbies (H1) with one Quilboar seat beside our tribes. There were four arms:
- **B** and **C**: Quilboar re-costed to our presets B and C (about 900 and 1,800 at R12);
- **uncut**: Battlegrounds' own card text;
- **frozen**: Battlegrounds' text with Blood Gem size held at +1/+1.

How to read it:
- **Rn** is round n. Board numbers are pre-start Attack + Health. Medians are over surviving boards unless a line says "all seats" (eliminated seats counted lowest) or "same cohort".
- **Bot data.** Every win rate, placement and flex share is what our bots did, not what people would do.
- **Old versions.** Birds and Fairies are pass 3. Bog, Hedgerow, Hunters and Oozes ran their old (pre-wave-2a) profiles, so anything said about those four is about the old versions.
- **Tags.** *Measured*: read off the archives. *Derived*: computed from measured numbers or from the paper model. *Inferred*: our reading of why.
- **Sources:**
  - **[compact]**: the committed `tools/sim/evidence/quilboar-h1*/<arm>/*.lobbies.json.gz`, plus `summary.json.gz`.
  - **[captures]**: the gitignored `build/quilboar-h1-captures/**/*.fights.jsonl.gz`. All 150 files match the hashes in the committed receipts.
  - **[paper]**: `docs/ideation/reference/quilboar/quilboar-port.md`.
  - **Scripts** are in `lessons/scripts.tar.gz` beside this file (the analysts' Python, unpacked paths as cited below; the pickles and JSON caches they wrote are not kept).

Every finding below was re-checked by a separate skeptic. Findings the skeptic marked as overreaching are left out, and section 6 lists them.

---

## 1. In short

1. **You were right, and it's the gem size that keeps growing.** Freeze gem size and Battlegrounds-text Quilboar falls from 825.5 to 175.5 at R12, and from winning 60% of its lobbies to 9%. Paper got the direction right but made the effect about 2.5× too big (÷11.6 on paper, ÷4.7 measured).
2. **Our flat scale comes from our own lines.** Even with a Battlegrounds-text tribe in every lobby, the lobby median grows only ×1.24–1.26 a round, under our ×1.3 bar. Mean for mean, our lines grow ×1.37, against Battlegrounds' ×1.56–1.76. The old Bog, Hunters and Oozes go almost flat after R12 (×1.03–1.13 a round).
3. **Stat totals don't compare tribes fairly.** At equal totals, Quilboar's wide gem board wins only 18–25% of fights, and our own tribes range from 43% to 62% (bot fights).
4. **Several of our yardsticks misread a tribe that is weak early and takes off late, and our paper models assumed cards arrive on time.** All four Quilboar engine pieces arrived on paper's schedule in 1 of 150 seats. Those are the process fixes in section 4.
5. **It can't yet answer what you asked most: how the jumps feel, and whether early flex works.** The bot capped early flex and no playtest ran. The cheapest next steps are two designed setups (D1, D5) and one playtest lobby with a Quilboar seat.

---

## 2. What we learned about scale and design

**L1. Your prediction holds, and the cause is gem size that grows.** *Measured.*
- **Board size.** BG text with and without growing size, on the same seed labels, pre-fix:
  - R12 median 825.5 against 175.5 (÷4.70);
  - all seats, 645.5 against 137.5 (÷4.69).
  - R15 is 7,718 against 803, but only 31% of frozen seats are alive then (71% uncut), so read R12.
- **Results.** Frozen Quilboar's mean place goes from 2.87 to 5.10, first place from 60% to 9%, and top 4 from 72% to 35%.
  - It places below our Hard bot (3.53).
  - It also places behind Fairies (4.17) and Hedgerow (4.53), though its R12 board is bigger than theirs (175.5 against 133 and 125.5).
  - Birds' first-place rate in the same lobbies rises from 18% to 50%.
- **The port's question 8.** This is the answer it hoped to test: "If size-frozen sits near our lines, the third axis is the gap."
- **Source:** [compact] uncut (pre-fix) and uncut_frozen, `rounds[].stats` and `players[].place`. Scripts: `check-process/ck_size.py`, `scripts/q_compact.py`, `check/ck_compact.py`.

**L2. The size engines run late in real play too, and Fairies grow by Ring count, not Ring size.** *Measured.*
- **Gem size** (Attack side, R9 / R12 / R15):
  - B: 2 / 6 / 9.5, against paper's 3 / 8 / 15;
  - uncut: 10 / 16 at R12 / R15, against 19 / 35;
  - C: 10 / 18, against 15 / 29.
- **Fan-out.** The median board holds 7 Quilboar from R12 in every arm, so that axis is fully used.
- **Fairies.** Ring size is 1 / 2 / 6 at B (1 / 2 / 4 in the other arms), against paper's 2 / 6 / 13. Fairies make up for it with count: 5–6, 15–16 and 32–44 Rings on the board.
- **Source:** [compact] `rounds[].gem_size`; [captures] `input.fight_rules[].ring_size`, and the Ring counts in `input.slots`. Scripts: `scripts/q_captures.py`, `check-process/ck_size.py`.

**L3. One strong tribe can't fix a flat lobby. The flatness is in our lines.** *Measured; the comparison with Battlegrounds is derived.*
- **Lobby median growth, R8–R14** (checkpoint 1's bar): B 1.244 [1.226, 1.278], C 1.257, uncut 1.255 [1.230, 1.298], frozen 1.236. Every arm is under ×1.3, even beside a Battlegrounds-text tribe at 5,319 at R14.
- **Per line.** Only two of the eight lines pass ×1.3 in every arm:
  - Quilboar: B 1.64, C 1.75, uncut 2.06, frozen 1.41;
  - Birds: 1.36–1.41.

  The rest: Fairies 1.23–1.27, Hedgerow 1.23–1.25, Bog, Hunters and Oozes 1.16–1.20, Hard 1.16–1.19. Same-cohort readings agree within 0.05.
- **Against Battlegrounds, mean for mean.** Our lobby without Quilboar grows ×1.37 a round. Battlegrounds' September 2025 lobby grows ×1.56, and November 2026 ×1.76 (Firestone mean). So passing ×1.3 means "no longer flat", not "Battlegrounds-shaped". Plan v3 already calls the bar that. Read it that way when you hear whether the scale problem is fixed.
- **Source:** [compact] `summary.json.gz` `all_seat_growth_r8_r14`; `bars.py` §1; `check/bars/ck1.py`, `ck3.py`; `docs/ideation/evidence/reference-curves.md`.

**L4. Three of the old lines go almost flat after R12. Birds and Fairies don't.** *Derived.*
- **R12–R15 growth a round:** Bog 1.10–1.12, Hunters 1.09–1.13, Oozes 1.03–1.08, Hedgerow 1.18–1.22, Birds 1.30–1.40, Fairies 1.34–1.43.
- **The check it answers.** DECISIONS asked for this check ("Step 5 should check whether our lines' growth flattens after R12"). This answers it for the old versions only. Recheck on the wave 2 lines at step 5.
- **Caveat.** These lobbies also ran a broad Busker guard, which capped native seats' free Created spells (DECISIONS "Quilboar fixes narrow check", Gap 1).
- **Source:** `extras.py`; `check/bars/ck2.py`.

**L5. Quilboar's real shape is a big step a round later than paper, and then it keeps compounding.** *Derived.*
- **Survivor-median growth a round at B:**

  | | R11 | R12 | R13 | R14 | R15 |
  |---|---|---|---|---|---|
  | Real | ×1.22 | ×2.38 | ×3.13 | ×1.65 | ×1.74 |
  | Paper (port §0) | ×1.90 | ×2.25 | ×1.53 | ×1.42 | ×1.36 |

  - **Uncut** jumps ×5.34 at R12 and ×3.34 at R13.
  - **After the step,** every arm still grows ×1.65–2.13 at R14 and ×1.54–1.74 at R15.
  - **Survivor bias.** Late survivor medians run high (L6). But the B seats still alive at R15 also grow ×2.18, ×1.75 and ×1.53 over R13–R15 (`bars-out.txt`, same-cohort table), which is still above paper.
- **Biggest one-round jump per seat:** a median ×3.35 at B, ×3.57 at C, ×6.37 uncut and ×2.06 frozen, mostly at R12–R13. Our lines jump earlier and smaller:
  - Birds at R10 (×2.4–2.7);
  - Hedgerow, Bog, Hunters and Oozes at R8–R10 (×1.4–1.8);
  - Fairies late, at R13–R15 (×1.8–1.9).
- **Game length.** Games last long enough for a late engine to matter: no lobby ended by R14 in any arm, and the median last round is R18–19. The port's question 5 trigger ("If winners finish by R14, our proportional tribes need earlier power") doesn't fire.
- **Source:** `bars.py` §2 and `bars-out.txt`; `check/bars/ck2.py`; [compact] `players[].rounds`.

**L6. By R15 Quilboar is ahead of every native line, even counting its dead seats, yet Birds wins as many lobbies.** *Derived.*
- **At B at R15:** Quilboar's survivor median is 2,339 against Birds' 737 (3.17×). Counting eliminated seats lowest, it is 773.5 against 604 (1.28×).
- **Every arm.** Birds is the best native line at R15 in every arm. On all seats, Quilboar leads it 2.93× at C and 9.36× uncut.
- **Lobbies won.** Even so, at B Birds wins 36% of lobbies and Quilboar 32%.
- **Survivor overstatement.** Survivor medians overstate the boom-or-bust line against Birds by about 2.5× at B, 1.6× at C and 1.3× uncut.
  - They get the order wrong only in frozen lobbies: 803 against 708, with 31% of Quilboar seats alive.
- **Source:** `bars.py` §2 rank table (`bars-out.txt`); `check/bars/ck2.py`.

**L7. A stat point doesn't fight the same for every tribe.** *Measured (bot fights).*
- **Equal totals.** In R9+ fights at equal pre-start totals (0.8–1.25×), Quilboar wins:
  - 22% at B (n=224);
  - 18% at C (n=180);
  - 25% uncut (n=114);
  - 19% frozen (n=157).

  Between two native boards, the wider side wins 42–46%.
- **By round at B:** 46% at R6–8, then 22%, 25% and 24% once the board is mostly gemmed Quilboar.
- **After Start of Combat effects,** Quilboar wins 28–36%, against a native baseline of 45–50%.
- **Break-even.** Quilboar needs between 1.25× and 1.5× its opponent's stats to break even. At B it wins 32% at 1.0–1.25× and 62% at 1.25–1.5×.
- **Our own tribes differ too.** At equal totals against other natives: Hedgerow wins 54–62%, Oozes 53–55%, Fairies 43–53%, Hunters 43–46%. It shows in placement as well: frozen Quilboar has a bigger R12 board than Fairies or Hedgerow and places below both (L1).
- **Paper flagged it.** Paper warned that "Head to head may differ from totals" (port §3.4). It does.
- **Causes** (*inferred*, not separated by these data):
  - in-fight power that pre-start counting misses (sky, Belly, Takes, bites, Rings);
  - Quilboar's in-fight gems lasting one fight;
  - the bot's unit placement.
- **Source:** [captures] `combat_start[].active_stats`, `after_start_effects[].active_stats`, `outcome.winner`. Scripts: `scripts/q_captures.py`, `scripts/q_followup.py`, `check/ck_captures.py`.

**L8. Who gets a round where the board doubles.** *Measured.*
- **Share of seats with a ×2 round** (R7–R16, previous board 30 or more):
  - Quilboar 62–73% (frozen 28%);
  - Birds 68–74%;
  - Fairies 24–30%;
  - Hedgerow 15–20%;
  - old Bog, Hunters and Oozes 0–4%.
- **That round's fight.** Quilboar wins it 84–97% of the time, and Birds 84–94%, against 51–71% for their other fights. But the doubling board is usually 2.5× or more its opponent's (Quilboar at B: 3.3×). So the win is close to automatic, and it says nothing yet about how it feels.
- **The port's question 3.** By its trigger ("No felt jump means a tribe's engine card needs a visible step"), the old Bog, Hunters and Oozes have no visible step. Recheck on wave 2 content before acting.
- **Source:** [compact] `rounds[].stats`; [captures]. Scripts: `scripts/q_compact.py`, `scripts/q_captures.py`.

**L9. Keystones: Quilboar's matters, and the old Hedgerow leans on Dozey the same way.** *Measured; Hedgerow is derived.*
- **Quilboar at B.** With Turbo Hogrider by R12: mean place 2.92 and 44% wins (n=91). Without: 5.46 and 14% (n=59).
  - Uncut: 2.16 and 75%, against 4.48 and 39%.
  - Part of this gap is survival: seats out before R12 never find it.
- **Our lines** (R12 survivors, B arm):
  - Hedgerow with Dozey on board (35%) wins 36%, without him 1%.
  - Fairies with Monarch (61%): 18% against 8%.
  - Birds with Stork (44%): mean place 1.78 against 2.52.
  - Bog, Hunters and Oozes win 0% with or without their pieces.
- **Association, not cause.** Dozey seats were already ahead at R9 (85 against 71).
- **The port's question 9.** Its trigger ("Tribes that bust without their keystone need a second route") points at Hedgerow. Recheck on wave 2's Hedgerow first.
- **Source:** [compact] `keystone_found_round`, `units`, `players[].place`; `bars.py` §4; `check/bars/ck5.py`.

**L10. Our engine lines lose seats early too. Birds and Hard are the exceptions.** *Measured.*
- **Out before R12:**

  | Line | Seats out |
  |---|---|
  | Quilboar | 15–32% |
  | Fairies | 13–16% |
  | Bog | 17–25% |
  | Hedgerow | 19–21% |
  | Hunters | 19–23% |
  | Oozes | 28–37% |
  | Birds and Hard | 1–4% |

- **Early boards.** Quilboar holds 2.5 units at R4, against Hard's 4.2–4.7. Fairies hold 2.8. That the bot's flex cap causes Quilboar's thin board is *inferred*.
- **Source:** `extras.py`; `check/bars/ck4.py`, `ck5.py`.

**L11. Our committed lines already flex early.** *Measured (bot pick rules).*
- **Own-tribe share of the board:**
  - our lines: 31–64% at R2–R5, and 73–87% at R10 (Oozes 58–60%);
  - Battlegrounds winners: 35–45% Quilboar before turn 6, then 54% / 66% / 79% at turns 6 / 7 / 8;
  - our Quilboar bot: 51% / 68% / 86% at R6 / R7 / R8.
- **Off-tribe early cards.** Only one T1–T2 card is held by at least 20% of other tribes' seat-games by R8: Fairies' Hedge Witch (30%), held evenly across lines. Next come Wee Wobbly 17%, Mrs Dunnock 15.6%, Bridge Toad 15%, Little Nip 12.1% and Mr Crumb 10.1%.
- **Limits.** These are cards held, not cards bought, and they follow bot pick rules. Hard and the Quilboar seat account for 45% of off-tribe T1–T3 holdings. Not enough to add flex cards on.
- **Source:** [compact] `rounds[].units`, against tribes and tiers from `git archive bb8bb5f2`; `scripts/q_compact.py` (Q1 block); `check/ck_flex.py`. About 3,400–3,560 seat-games per tribe.

---

## 3. Assumptions it challenges

### The paper model

**A1.** Port §3.5: "One global, future-only size number is worth ×4–7 at B, and ×12–20 at BG's numbers."
- **Evidence.** Measured at Battlegrounds' text, freezing size costs ÷4.7 at R12, against paper's ÷11.6 (L1). The direction is right, but the size is about 2.5× too big. B was never run frozen. *Measured / derived.*
- **Status.** DECISIONS logs 825.5 → 175.5 ("Quilboar H1 and merge review: calls"), but not the gap with paper.

**A2.** Port §0: "By R15, seven of the twelve lines are level or ahead. That is Quilboar's timing identity: strongest just after the commit card, then caught by our proportional tribes." Also: "Growth a round decays after Hogrider".
- **Evidence.** The step comes a round later and doesn't fade by R15 (L5). At R15 Quilboar is ahead of every native line, even on all seats: 1.28× Birds at B (L6). *Derived.*
- **Caveat.** Paper compared pass 3 designs, and four of our six lines here ran their old versions.
- **Status.** Logged as "It compounds late" (DECISIONS "Quilboar H1 and merge review: calls"). New here: it holds on all seats. The paper text is unchanged.

**A3.** Port §10.1: "Low roll: climbs late (T6 at R12), with one Tunneler, no Refiner, and Hogrider only at R13." And §10.4: "Arrivals are scripted, not shopped. Expect the harness median below paper. The plan's 0.5–2× accounting check applies."
- **On-time arrivals** at B (150 seats), against paper's rounds:

  | Piece | Paper's round | On time |
  |---|---|---|
  | Gem Rat | R5 | 16.7% |
  | Tunneler | R7 | 48.7% |
  | Refiner | R9 | 33.3% |
  | Hogrider | R11 | 22.7% |
  | T6 | R11 | 96% |

  All four pieces plus T6 arrived on time in 1 seat (0.7%), 0 of 100 uncut and 3 of 150 at C. *Measured.*
- **Below the low roll.** The real B median at R12 (259) is below paper's own low roll (308). *Derived.*
- **A lag, not a ceiling.** Seats with Hogrider and T6 by R11 reach 453 at R12 (0.40× paper, n=26), which is below paper's R11 board (508), so they are more than a round behind. By R15 the same seats reach 0.92× (n=21). Uncut on-time seats reach 0.24× and 0.44×. *Measured.*
- **Status.**
  - Fixed for wave 2's native models: "The low-roll row removes the keystone", and paper lines are "labelled as high rolls" (DECISIONS "Wave 1 triage: what we fix").
  - Open for the reference's model, which is parked.

**A4.** DECISIONS "Wave 1 triage": "Replaying them with real arrivals reproduces the measured ratios."
- **Evidence.** Not shown for Quilboar. On-time keystone seats still sit at 0.40× (B) and 0.24× (uncut) of paper at R12 (A3). That neither proves nor refutes the claim, since the other pieces are still late. *Measured.*
- **Status.** Open: it needs an arrival replay for this tribe.

**A5.** DECISIONS "Quilboar H1 rerun", quoting w6: "A matching shared gap is not established." And: "The two arms disagree about the gap, so neither supports a shared one."
- **Evidence.** Measured in rounds behind paper at R12, the Quilboar arms sit inside our wave 1 lines' range:

  | | Rounds behind paper |
  |---|---|
  | Quilboar B | 2.06 |
  | Quilboar C | 1.79 |
  | Quilboar uncut | 1.62 |
  | Our wave 1 lines | 0.80 (Tempo) to 3.38 (Court) |

  *Derived.*
- **Why the ratio misleads.** Paper Quilboar grows ×2.25 (B) and ×2.95 (uncut) into R12. So the 0.5–2× band allows Quilboar under one round of lateness (0.85 at B, 0.64 uncut), and our lines 1.47–2.07. The uncut arm looked like an outlier because its paper curve is steeper.
- **Caveat.** Four lines across a range 2.6 rounds wide is a weak test, and rounds don't prove a shared gap either.
- **Status.** Open. Revisit before anyone cites the "no shared gap" call.

**A6.** Port §0 and §3.2: the paper typical line is "C | 54 / 203 / 1,942 / 6,123", against uncut "Full | 6,195 / 23,945". That is C at 0.31× of BG text at R12 and 0.26× at R15.
- **C against BG text.** Real C is 0.51× [0.38, 0.64] of BG text at R12 and 0.44× [0.35, 0.54] at R15. *Derived.*
- **B against BG text.** Real B is 0.33× and 0.25×, against paper's 0.18× and 0.14×.
- **On a log scale,** the real cut is 58–60% of paper's for C and 65–71% for B. The B → C size step alone tracks paper at 81–94% (×1.54 and ×1.76, against ×1.70 and ×1.82).
- **What it means.** Paper overstates how far our presets sit below Battlegrounds' text, and most of that overstatement is in the text's other levers, not in the size step.
- **Status.** Not logged.

### How we compare tribes

**A7.** Plan v3: "B, the default: about 900 at R12." And DECISIONS "Quilboar H1 rerun": "a BG-faithful tribe reaches about 750 at R12 in our engine with our bots, near B's 900, so B-scale is reachable."
- **Evidence.** Both are stat totals, and totals don't fight the same across tribes (L7). Quilboar needs 1.25–1.5× the stats to break even. So B-scale totals are reachable, but B-scale fighting power isn't shown. *Measured; the reading is inferred.*
- **Status.** Open.

**A8.** Your note 09d: "It's way harder to beat 3 units that are 500 million / 500 million than a single 2.1 billion one."
- **Evidence.** In our engine today, in bot fights, the wide board is not the harder one to beat. At equal totals the wider native side wins 42–46%, and Quilboar's very wide board 18–25% (L7). *Measured.*
- **A possible reason** (*inferred*): the note's own reason ("very beatable with scam units") may be what our pool lacks, which is few answers to one big unit. D4 tests that.
- **Status.** The note's heading, "Distribution of stats beats the total", holds: same totals, different results.

**A9.** Port §3.4: "Gem size at B (3 / 8 / 15 at R9 / R12 / R15) nearly matches the Ring size curve (2 / 6 / 13). That gives a clean test of retroactive against future-only size (question 6)."
- **Evidence.** In real play, Ring size is 1 / 2 / 6 and gem size 2 / 6 / 9.5 at B (L2). At R12 they differ 3×, and Fairies scale by Ring count instead. *Measured.*
- **Status.** Open. D5 never ran, and when it does, it must use the real curves.

**A10.** Port §11.5, question 1's trigger: "A tribe with no T1–T2 card that at least 20% of other lines buy gets one flexible early card".
- **Evidence.** On the data we have, it would fire for five of six tribes (L11). But the harness records holdings, not buys, and the holdings follow bot pick rules. *Measured.*
- **Status.** Not acted on, correctly. Deciding it needs a buy log or D1.

**A11.** Port §9 bot policy: `"flex_policy": {"until_round": 6, … "max_flex_kept": 2}`, under "Before R6 flex". The research it cites: "BG winners are 35–45% Quilboar before turn 6".
- **Evidence.** The bot capped flex from R1, as the spec literally says and the Phase 1 review asked. It holds 2.54 units at R4 against Hard's 4.29, and its R6 board is 33 against Hard's 47. *Measured.*
- **Paper was thin early too.** The paper model itself plays 3 units and 1 flex unit at R4, and 67–83% Quilboar before R6.
- **Status.** Logged as a floor and not retuned (DECISIONS "Quilboar H1 and merge review: calls", Ask 1). H1 can't answer your early-flex question.

### Our yardsticks

**A12.** Plan v3 extreme miss: "a tribe's best line outside an order of magnitude of the others (09c)".
- **Evidence.** It depends on the round. Best line ÷ worst line, on survivor medians:

  | | R12 | R14 | R15 |
  |---|---|---|---|
  | B | 3.2× | 12.5× | 22.1× |
  | C | 4.3× | 17.5× | 27.7× |
  | uncut | 7.7× | 47.5× | 75.5× |

  *Derived.*
- **It also depends on the comparison.** Best ÷ the median of the others gives B 8.4× at R14 (no fire) and 12.2× at R15. Our lines alone spread 5.9–7.0× at R15.
- **The worst line is thin.** At R14–R15 it is Oozes, with 19–29% of seats alive.
- **Status.** Open: the check needs a named round, ratio and population.

**A13.** Plan v3 reported read: "snowballs and comebacks: the R8 leader's win rate".
- **Evidence.** The uncut arm has the lowest R8-leader win rate (0.30 [0.21, 0.39]) while Quilboar wins 64% of its lobbies. Quilboar leads at R8 in only 18% of those lobbies. Leave out Quilboar's wins and the leader's rate is 0.42–0.45 in every arm. So a low figure can mean one late tribe dominating, not healthy comebacks. *Derived.*
- **Caveat.** The arms' intervals overlap, so the mechanism is clear but the difference isn't statistically shown.
- **Status.** Open.

**A14.** Done means (PLAN.md): "At least 5 distinct strategies (tribe plus archetype shape) each win 6–25% of lobbies they appear in. Nothing above 25%."
- **Evidence.** It fails every arm, and it flags whichever line leads that field. In B it flags both Quilboar (32%) and Birds (36%); in C and uncut, Quilboar (50% and 64%); in the frozen lobbies, Birds (50%). Bog, Hunters and Oozes win 0–2%, so the floor fails too. *Derived.*
- **What also flags uncut.** BG-text Quilboar is also caught by the order-of-magnitude check at R14–R15, by "one line winning whatever the player chooses" (64%), and by per-line growth (2.06).
- **Scope.** The bar is defined for 8 pinned strategies over 2,000+ games, and H1 has 100–150 lobbies.
- **Status.** Open, for when Done means 2 is rewritten (plan v3 step 7).

### Constants

**A15.** Rulebook 4.6.2: "Upgrade base costs (to 2–6) | 5, 7, 8, 11, 11".
- **Evidence.** The game charges 13 for T6 (`game_config.gd:20–21`, "Tier 6 by round 11 won too often"). Every paper model that copied 11 is high: B's R12 board moves from 1,144 to 1,065 (−6.9%). *Measured.*
- **The same 11 is in** the Birds, Fairies, Hedgerow and Oozes pass 3 models, `oozes-wild-model.py`, `bog-engine-model.py` and the triage's copies. Native ratios stay like for like, because they share the 11.
- **Status.** Logged for H1 only ("T6 stays at the game's cost of 13", DECISIONS "Quilboar H1: both criteria failed"). Open for the rulebook and the native models.

---

## 4. Process changes

None of these adds a deciding criterion (09i). They change how a bar is checked before it decides, and what is reported beside the two criteria we have.

**P1. Sim bars: test a bar on a known case before it decides anything.**
- **What happened.** The 0.5–2× accounting band had already failed 3 of our 4 wave 1 lines (0.169–0.722 at R12) at 01:27. The H1 plan froze it as a deciding criterion at 07:48. Quilboar B's 0.23× sat inside that native range, so the bar couldn't tell a bad port from a bad model. *Measured* (git log, `wave1-accounting.md`, the plan's `created_utc`).
- **Where else.** The band appears in about 14 docs on ideation/main. `plan-scale-rework.md:48` still says to "fix the accounting in the wave 2 briefs". The prototype LEARNINGS has the matching rule for checks: "Plant one fault per check before trusting a clean run."
- **Status.** Partly done:
  - accounting no longer gates the reference's playtests (DECISIONS "Quilboar H1 and merge review: calls", Ask 3);
  - paper is no longer a target (DECISIONS "Quilboar H1 rerun"; "Wave 1 triage: what we fix", item 1).

  **Open:** the rule itself, and line 48.

**P2. Paper accounting: three separate checks, and rounds behind beside the ratio.**
- **What to change.** Check paper against real in three ways:
  - the engine on paper's scripted arrivals, which tests the port and the rules;
  - an arrival replay, which tests the shop;
  - the bot against the script on the same seeds, which tests the bot's policy.

  Report rounds behind as well as the ratio (A5).
- **Why.** A3 and A4: the roughly two-round lag can't be split between shop, bot and rules today.
- **Where else.** Every tribe's paper model, and the preset targets.
- **Status.** **Open.** There is no tool yet.

**P3. Triage: make "where else" a search.**
- **What happened.** The wave 1 triage found the scripted-arrival flaw at 02:22. Its list of other places with the same cause (`wave1-triage/report.md:94`) left out the reference, whose plan froze the same band that morning.
- **What to change.** When a triage finds a flaw in a method, grep every frozen plan, brief and criterion that uses the method, and label or amend each one before its next run.
- **Where else.** The triage skill's "list where else the same cause applies" step.
- **Status.** **Open.**

**P4. Paper models read constants from the game config.**
- **What to change.** Read economy constants from `GameConfig.full_game()`, not from the rulebook (A15).
- **Status.** Logged for H1 only. **Open** for the rulebook text and the native models.

**P5. Bot specs and smoke runs: give each rule a number from its source, and check it before the frozen run.**
- **What to change.** Each bot rule carries an observable taken from the research it cites. For example: 35–45% own tribe before turn 6; board fill at R4 within one unit of Hard's; shop cycles counted apart from Created cards. A smoke run of a few lobbies checks those observables.
- **Why.** The first smoke version (68b0b42a) already showed 2.25 units at R4 against Hard's 5.25 over four lobbies, and nobody compared it with the research. The paper model had the same thin early board (A11). *Measured.*
- **Where else.** Wave 1's line rules that bots loaded but never ran (`thank`, `max_copies`, `stayer_cap`; DECISIONS "Wave 1 triage"), and Pot Luck's route (LEARNINGS "A committed line must play the route its paper costed").
- **Status.**
  - The cycle cap is fixed (4cf1a219; DECISIONS "Quilboar H1: both criteria failed").
  - The flex cap is logged as a floor (Ask 1).

  **Open:** the rule.

**P6. Reruns: predict the fix's effect first, and rerun every arm you'll compare.**
- **What happened.**
  - Accounting needed ×2.08, and the cycle fix's ceiling on paper was about ×1.21. Real B went from 274.5 to 259.
  - Fidelity needed ×1.31, against a paper ceiling of ×1.20.
  - The rerun left the frozen arm paired only with the superseded pre-fix uncut arm. *Derived.*
- **What to change.** Read the largest plausible effect off the paper's sensitivity table before authorizing a rerun.
- **Status.** **Open** (minor). The stop rule worked and stays (DECISIONS "Quilboar H1 rerun").

**P7. Learning steps: decide on "can we read the lesson", and run designed setups first.**
- **What happened.** The two validity checks failed, and stopping then also stopped the learning arms.
  - H1's lobbies answer questions 3, 5, 8 and 9.
  - Questions 1, 4 and 6 have partial answers from data H1 happened to record.
  - The designed setups (D1–D6), the field runs and the playtests never ran.
- **What to change.** In a step whose purpose is lessons, the deciding criteria say "lesson X can be read". Validity checks are reported. Designed setups run before bot lobbies: 09d, and plan v3 says designed setups "outrank line lobbies".
- **Status.** The stop was a logged call (DECISIONS "Quilboar H1 and merge review: calls", Ask 3, citing 09i). Running D1, D4 and D5 would reopen it by choice; it doesn't fix an error. **Open.**

**P8. Late rounds: report who is alive beside survivor medians.**
- **What to change.** Beside any survivor median used to compare tribes after about R12, give the share of seats alive and the all-seat median.
- **Why.**
  - L6: survivor medians put Quilboar 3.17× ahead of Birds at R15, against 1.28× on all seats.
  - From R12 to R15 the survivor-median lobby grows 1.36–1.42 a round, while the same seats grow 1.25–1.30.
  - On survivor medians, ×1.3 passes in all four arms if the window moves to R10–R16 (1.31–1.38).
- **Where else.** Checkpoint 1's report, the "It compounds late" lesson, and wave reviews.
- **Status.**
  - The window and formula are fixed in writing (DECISIONS "Harness follow-up 3", Ask A).
  - Survivor bias is already reported (DECISIONS "Wave 1 triage").

  **Open:** showing the share alive beside late medians. Also, when step 5 picks the damage table, check how it moves elimination timing, because that moves survivor medians.

**P9. Extreme-miss checks and the depth bar: say exactly what is read.**
- **What to change.**
  - Give "outside an order of magnitude" a round, a ratio and a population (A12).
  - Read the R8-leader figure beside the winning line's R8 rank and its win share (A13).
  - When Done means 2 is rewritten onto the harness, treat its 6–25% band as relative to the field, next to an absolute read (A14).
- **Status.** **Open.**

**P10. Head-to-head beside totals.**
- **What to change.** Any "tribe X is N× tribe Y" or "B-scale is reachable" claim carries a head-to-head win rate at equal totals (L7, A7). The designed carry-against-even bar in `tools/sim/HARNESS.md` is the existing place for it.
- **Where else.** The preset targets, the reference's fidelity criterion, and wave reviews.
- **Status.** **Open.** It fits 09d's heading, "Distribution of stats beats the total".

**P11. Evidence size: raw captures stay out of git.**
- **What happened.** 154 capture files (93.85 MB) went into `ideation/quilboar`'s history.
- **Status.**
  - Done for this run: ideation/main's history has none. The squash b19a0af6 was merged as 5425c907, and `git log HEAD -- '*.fights.jsonl.gz'` is empty (DECISIONS "Quilboar H1 and merge review: calls", Ask 2). A backup sits outside git ("Quilboar fixes narrow check", Gap 3).
  - **Open:** one line in HARNESS.md and the brief template: raw captures stay under `build/`, their hashes go in committed receipts, and any commit that adds more than a few MB of evidence gets flagged.

**P12. Small text fixes.**
- `plan-scale-rework.md:48` is stale (P1).
- `RESTART.md:100` still says "0.17–0.44×". Line 478 was fixed in 7274cd2b.
- Shop dilution from a seventh tribe is due with step 5's lobbies, not yet.
- **Status.** **Open.**

---

## 5. What it still can't tell us, and the cheapest way to find out

The time estimates are the analysts' figures: about 3.5 s of Godot a lobby, and about 10 ms a designed fight.

- **Whether the jumps feel like progress.** This is checkpoint 1's play criterion, and no playtest has had a Quilboar seat.
  - **Cheapest:** the optional playtest lobby with a Quilboar seat once checkpoint 1 picks a preset (DECISIONS Ask 3): three fresh agent players × three games, with every moment checked against the game log.
- **Whether early flex works (09f: "Early units should be somewhat flexible as well as enabling").** H1's early game is a bot artefact (A11), and holdings aren't buys (L11).
  - **Cheapest:** D1. Build a flex board and an on-tribe board from the same R6 gold, using scripted per-tribe arrivals. That is a generator task, then minutes of Godot.
  - A buy log in the bench would give true buy shares.
- **Pivot timing for our tribes.** H1 seated a Hard bot pinned to one build (0 of 500 seats changed line). But the engine already has an unpinned Hard: it re-picks its build each round until R9 (`bot_brain.gd`, `LOCK_BUILD_ROUND = 9`).
  - **Cheapest:** seat unpinned Hard. That gives pivots up to R8 with no new bot code, at about 9 min of Godot per 150 lobbies.
  - Pivots at R10 need designed pivots (D2).
- **Whether our biggest-enemy answers lose value against a wide board.** D4: equal-total designed boards with and without each answer, a few thousand fights, after a generator task.
- **Which size reads and plays better, retroactive or future-only.** D5 on the real curves (A9) answers "plays". "Reads" needs the playtest.
- **Whether cutting coupling is gentler than cutting an axis** (question 7). Paper doesn't settle it (section 6).
  - **Cost:** two new reference dials, then three B arms of 150 lobbies (about 26 min of Godot), plus a review.
- **Where the two-round lag comes from: shop, bot or rules.** An engine run on paper's scripted arrivals (P2).
- **Whether L3, L4 and L8 hold for wave 2's tribes.** Rerun on current content: about 9 min of Godot per 150 lobbies, plus a fresh B control.
- **Cross-tribe hazards on a gem board** (question 10). H1 barely exercised them: Busker was on 18 of 500 Quilboar boards, Silky on 59, Stone Soup on 0.
  - Native seats did pick up Quilboar units in 249 of 3,000 seat-games, so a few cases exist.
  - The one hazard found so far, the Busker guard, came from code review.
  - **Cost:** Phase 2, a line policy that keeps splash cards, then 2 × 150 lobbies (about 18 min).
- **Whether count and applications alone reach Battlegrounds' scale.** The optional control is a second Battlegrounds tribe (Undead). It needs a port about the size of Quilboar's Phase 1, then about 6 min of Godot.
- **Not reachable from these runs:**
  - human frequencies;
  - Battlegrounds at R15 (the reference curves stop at R14);
  - paired shop comparisons between arms (shops are unpaired).

---

## 6. Dropped claims (the skeptic said they overreach)

- **"Size is the dial to watch on any additive tribe."** The numbers hold (L1), but this generalises from one tribe, and paper says none of ours is additive-trivariate.
- **"Freezing size closes 72–89% of the gap, which contradicts paper's 65%."** This misreads paper. Its 65% compared Battlegrounds' median with preset A and wasn't an ablation. Paper's own size-off figure predicted 97% of the gap, so the real share is less than paper said, not a contradiction.
- **"Paper predicts how much each dial moves things."** Paper's ×1.70 lies outside the real paired interval at R12 ([1.33, 1.66]). It had ×1.22 at R9 against a real ×1.01, and it overstated the size freeze 1.58× on a log scale.
- **"Paper predicts how swingy a tribe is."** The p90/p10 match comes from a uniform level miss. A bot-policy fix alone moved the spread ×1.5. Paper's strong and low rolls are scripted scenarios, not percentiles.
- **"Our biggest-enemy answers don't lose value against wide boards."** Every line gains against Quilboar, with or without answers. Cells are 8–43 fights, and no answer card was identified on the board. The data show Quilboar's weakness per stat, and nothing about answers.
- **"Our tribes flatten after R12, so read ×1.3 same-cohort too."** Fairies speed up after R12. The ×1.3 bar is defined on the pooled median, and 09i caps deciding criteria at two.
- **"Quilboar has a trough at R9–R11, like Battlegrounds' Choose One."** The Battlegrounds-text arm has no trough (50% → 48%). The trough appears only in our budgeted arms and frozen, so the comparison reverses the data.
- **"The 'fights decided before they start' cut trigger would fire on our pool."** That trigger isn't live. It was replaced by the agency bar, which was then withdrawn. The uncertain-fight share is reported only.
- **"Hogrider is worth 0.3–0.6 places once a seat gets there; native pieces 0.4–1.4."** The range is 0.1–1.9 across arms, and the native comparison wasn't like for like.
- **"Cutting coupling cuts from the top" (paper only).** At R15 the reading reverses at every preset. The scratch patch was also narrower than the spec's cut.
- **"Dropping the Quilboar seat barely moves the lobby median, so checkpoint 1 needs a per-line check."** Plan v3 already triages the order-of-magnitude and one-line-wins cases.
- **"Same-cohort growth would separate frozen Quilboar from Birds."** It doesn't (1.388 against 1.402). Only the share alive, the all-seat median or the win rate does.
- **"Most of Quilboar's growth is after R12; an R12 read gets the order wrong; paper predicted the opposite."** The order is wrong only in B and frozen. Paper never predicted that Birds would catch Quilboar. B Quilboar at R12 is already 1.9–2.7× the other five native lines. DECISIONS already logged the lesson.
- **"Preset C is generous at R12 and not at R15."** This is backwards: real C is 0.56× Battlegrounds' September 2025 mean at R12 and 1.16× at R14. Preset C for our own tribes wasn't tested.
- **"Assume a named T6 card lands a round after T6."** This generalises from one card, one pool and one bot, and 21–45% of seats never find Hogrider. A paper model should carry the arrival distribution instead.
- **"Hogrider matters less than paper said."** On-time against none by R12, the board ratio is 2.34× (B), 2.42× (C) and 3.0× (uncut), which matches paper at B and C. The late bucket's high win rate is survivorship.
- **"The line-strength gate punishes boom-or-bust."** Mean place gives the right pairwise answer: B Quilboar finishes above Hard in 52% of lobbies. The gate tests script strength, not a gameplay criterion.
- **"The fidelity bar measured Birds, not the port."** The fall from paper's 10.1× to a real 2.38× comes mainly from the reference realising poorly, which is a fidelity fact. Seed noise didn't change the verdict.
- **"power-budget.md would misprice coupled size scaling."** The doc already disclaims geometric growth, and budget v2 is planned as guardrails, not a price list. No doc has adopted "cut the coupling" as a guardrail.
- **Not checked, so left out:** "late-round survivor medians inflate the R15 accounting pass" (process lens). P8 covers its point using checked numbers.
