# The port's ten questions about our tribes, answered from H1

Source questions: `quilboar-port.md` §11.5 (on `ideation/quilboar`, read in `/home/alex/code/Bramble-ideation-sol`). Nothing in any worktree was changed. No Godot was run.

## How to read this

- **Arms.** B = budgeted preset B (post-fix, seeds 2921001–150). C = preset C (pre-fix, 2911001–150). uncut = BG card text (post-fix, 2921001–100). frozen = BG text with gem size held at +1/+1 (pre-fix, 2911001–100). Two pairs share seeds and differ in one thing: **uncut-pre vs frozen** (gem size grows or not) and **B-pre vs C** (gem-size steps ½ or 1; every other dial equal, port §6).
- **Natives.** Birds and Fairies are pass 3 (wave 1). Bog, Hedgerow, Hunters and Oozes ran **legacy pre-wave-2a profiles and cards**. Anything said about those four is about the old versions.
- **Counting.** Board = pre-start active board, Attack + Health. Hand, sky and Belly are left out. Medians are over surviving boards only.
- **Bot data.** Every rate below is what our bots did, not what people would do. That matters most for flex (Q1), pivots (Q2), whether a jump feels good (Q3) and placement (Q4).
- **Kinds.** *measured*: read straight from the archives. *derived*: computed from measured numbers or from the paper model. *inferred*: my reading of why.
- **Sources.**
  - *compact*: the committed `tools/sim/evidence/quilboar-h1{,-cycle-fix}/<arm>/*.lobbies.json.gz`. Fields: `rounds[].stats, units, gem_size, keystone_found_round, commit_round, largest_share, health, current_line`, and `players[].place, rounds, final_tribe`.
  - *captures*: the gitignored `build/quilboar-h1-captures/**/*.fights.jsonl.gz`. All 150 files matched the `capture_gzip_sha256` in the committed receipts. Fields: `combat_start[].assigned_line, active_stats, largest_share`, `after_start_effects[].active_stats`, `outcome.winner`, `input.fight_rules[].ring_size`, and the Ring counts in `input.slots`. Ghost fights are dropped.
  - Captures give the real lobby pairings, so they are a natural version of H2. If they leave the tree, the capture-based results can only be rebuilt from the archived files with the same hashes.
- **Scripts** live in `scripts/` next to this file, and each one's output is in an `out_*.txt` beside it.

## In short

| # | Question | Answer from H1 | Status |
|---|---|---|---|
| 1 | Early flex | Our lines already play mixed boards early (29–64% own tribe before R6). By the spec's test, only Fairies (Hedge Witch, 30%) has an early card other tribes take up. | Partly. The data are bot buy rules |
| 2 | Pivot timing | Quilboar commits at R6 (83%). An engine start at R6 or earlier is worth 1.2–3.5 places over R9+ at B and C. Native pivots can't be measured: every bot, Hard included, fixes its line at R1. | Quilboar yes; natives no |
| 3 | Power jumps | Quilboar (62–73% of seats) and Birds (68–74%) have ×2 rounds, and those rounds win their fight 84–97% of the time. Legacy Bog, Hunters and Oozes almost never do (≤4%). | Size yes; feel no |
| 4 | Wide against tall | At equal totals, Quilboar's wide board **loses**: it wins 18–25% of R9+ fights. Our tall boards and our answers don't lose value against it. | Yes (aggregate) |
| 5 | Timing | The paper's catch-up never happens. Our lines flatten after R12 (×1.07–1.29 a round) while Quilboar compounds (×1.86–2.06). Games run long enough: median end R18–19. | Yes |
| 6 | Retroactive against future-only size | The equal-curve premise fails in real play. Ring size is 2 at R12, against gem size 5.5–6 at B. Which reads better needs people. | Premise yes; answer no |
| 7 | Coupling as the guardrail | Not run. On paper, the coupling cut takes 31% off the strong line and 11% off typical; the axis cut takes 10% and 16%. | Paper only |
| 8 | Scale or axes | Confirmed: 825.5 → 175.5 at R12 (×4.7), and ×9.6 at R15. Freezing size closes 72–89% of the gap on a log scale. Halving the step costs ×1.5–1.8, close to paper. | Yes |
| 9 | Keystone dependence | Without Hogrider by R12, place is 5.5 against 2.9. Among seats alive at R13 the gap shrinks to 1.6 against 2.3 (B). The real dependence is surviving R9–R11. | Yes (Quilboar) |
| 10 | Splash hazards on a gem board | Not exercised. Busker is on 18 of 500 Quilboar boards, Silky 59, Echo 0, Soup 0. Phase 1 has no Felboar or Barrage. | No |

---

## Q1. Early flex against enabling

**Asked:** do our T1–T3 units help other tribes' boards and still feed their own engine? BG winners are 35–45% Quilboar before turn 6, then 54%, 66% and 79% on turns 6, 7 and 8 (port §2).

**From H1:**
- **The Quilboar bot's board matches BG's from R6, and is thin before it** (*measured*, compact `units` × run-commit tribes, `q_compact.py` Q1 block).
  - Own-tribe unit share, B: R4 0.23, R5 0.43, R6 0.53, R7 0.69, R8 0.87.
  - Median units on board: 3, 3, 4, 6, 7, against Hard's 4, 6, 7, 7, 7.
  - Against BG's 54/66/79%, R6–R7 match, R8 is higher (0.87), and before R5 it is lower (0.16–0.25 against 0.35–0.45).
  - The 2-flex cap leaves slots empty (review ask 1).
- **Our committed lines already flex by composition** (*measured*, same block). Native lines are fixed from R1, yet their own-tribe share at R2–R5 is 0.29–0.64 (Birds 0.31–0.47, Bog 0.32–0.47, Hedgerow 0.33–0.46, Hunters 0.37–0.49, Oozes 0.29–0.41, Fairies 0.48–0.64). By R10 it reaches 0.73–0.86, and Oozes 0.56–0.59. That is the same range BG winners show. *Inferred:* in a 7–8 tribe pool our lines fill early slots with whatever is good, so the ingredient is there without a gem-like token.
- **Off-tribe uptake of each tribe's T1–T2 cards** (*derived*): the share of seat-games ending on another tribe that had the card on board at some round R1–R8, canonical arms pooled, about 3,450 seat-games per tribe.

  | Tribe | Best early card for other tribes | Share |
  |---|---|---|
  | Fairies | Hedge Witch (T1) | **0.300** |
  | Oozes | Wee Wobbly (T1) | 0.170 |
  | Birds | Mrs Dunnock (T1) | 0.156 |
  | Bog | Bridge Toad (T1) | 0.150 |
  | Hunters | Little Nip (T1) | 0.121 |
  | Hedgerow | Mr Crumb (T1) | 0.101 |

  - The spec's test: a tribe with no T1–T2 card that at least 20% of other lines buy gets a flexible early card. On this proxy it would fire for five tribes.
  - **Don't act on that yet.** It measures holding, not buying. Hard (2,435 off-tribe holdings) and the Quilboar seat (1,670) make most of them, and both follow bot pick rules ("best stats per gold"). Four of the six tribes are pre-wave-2a cards.
- **What the Quilboar seat keeps from our pool, R2–R7** (*measured*): Gideon 16%, Young Pretender 16%, Pill Bug 15%, Hob in the Hearth 14%, Lodger 13%, Wee Wobbly 13% and Wick 13%. This is a raw stats-per-gold ranking of our early bodies.

**Not answered:** whether early commitment pays or costs (D1), and what a person would buy (P).
- **D1 (flex board against on-tribe board from the same R6 gold):** extend the harness generator with scripted per-tribe arrivals. That is a worker task; the run is minutes of Godot at about 10 ms a fight.
- **H5 proper (the buy share of every T1–T3 card):** the bench needs a buy log. Compact boards record holdings only.
- **Rerun on wave 2a/2b content:** about 9 minutes of Godot per 150 lobbies (H1 measured 3.5 s a lobby). It needs a fresh B control, because the frozen plan's seal refuses the merged tree.

## Q2. Pivot timing and the commit signal

**From H1:**
- **Quilboar commits at R6 in 83% of seats** (125/150 at B), at R5 in 15% and at R4 in 2% (*measured*, `commit_round`). Gem Rat and Tunneler first appear at a median R7–R8. Refiner arrives at R10, and Hogrider at R12, a round after paper's R11. Hogrider reaches the board in 67% of B seats (compact `units`).
- **The cost of a late engine start** (*measured*), mean place by the round Gem Rat or Tunneler first appears:

  | Arm | By R6 | R7–8 | R9 or later |
  |---|---|---|---|
  | B | 3.37 | 4.15 | 4.57 |
  | C | 2.19 | 3.58 | 5.69 |
  | uncut | 1.97 | 3.31 | 3.12 (n=8) |
  | frozen | 4.26 | 5.37 | 7.12 |

  So the delay costs 1.2–3.5 places at B and C (*derived*).
- **No native pivot data exists** (*measured*).
  - Native lines are seated on a line from R1.
  - Hard picks one of 21 lines at R1 (`current_line`: fairies_rings 36, neutrals_economy 31, hedgerow_treasury 29, …), and in 500 of 500 seats it never changes.
  - So the harness has no bot that pivots. *Implication:* any "commit signal" or "late entry" lesson about our tribes needs a new bot behaviour or designed setups. It can't come from lobbies as they stand.

**Not answered:** the slope of R12/R15 board against pivot round for our tribes (D2). Two ways to get it:
- **Designed pivots:** one neutral R6 board pivoting into each tribe at R6, R8 or R10. That is 7 × 3 scripted arrival paths: a generator task, then minutes of Godot.
- **A Hard variant that picks its line at R6, R8 or R10:** a bot change, then about 9 minutes of Godot per 150 lobbies.

## Q3. Power jumps

**Size of the largest one-round jump** (pre-start board, R7–R16, previous board at least 30; *measured*, `q_compact.py` Q3 block):

| Line | Median largest jump (B) | Round | Seats with a ≥×2 round (B / C / uncut / frozen) |
|---|---|---|---|
| Quilboar | ×2.40 (C ×2.89, uncut ×4.46, frozen ×1.77) | R12 | 0.62 / 0.73 / 0.73 / 0.28 |
| Birds | ×2.35 | R10 | 0.69 / 0.68 / 0.71 / 0.74 |
| Fairies | ×1.71 | R10 | 0.27 / 0.24 / 0.30 / 0.25 |
| Hedgerow (legacy) | ×1.62 | R9 | 0.15 / 0.19 / 0.18 / 0.20 |
| Bog, Hunters, Oozes (legacy) | ×1.47–1.53 | R8–R10 | 0.00–0.04 |
| Hard | ×1.50 | R9–R10 | 0.14–0.17 |

**Is a ×2 round decisive?** Yes, for that round's fight (*measured*, captures, `q_captures.py`).
- Win rate in the fight of a ×2 round, against the seat's other fights from R8:
  - Quilboar 0.84 against 0.51 (B), 0.88 against 0.58 (C), 0.97 against 0.63 (uncut);
  - Birds 0.89 against 0.68 (B);
  - Fairies 0.68 against 0.48;
  - Hedgerow 0.88 against 0.51.
- Quilboar seats with a ×2 round average 2.16th, and those without 6.79th (B). *Inferred:* that gap is mostly survival, since seats that die before R12 never get one.

**Fights decided before they start** (D3's definition: one board at least 1.5× the other; *measured*, captures, R12–R15).
- Lopsided fights: 64–72% of all fights, 83–94% of Quilboar's fights in the B, C and uncut arms (68% frozen), and 61–63% of native-only fights.
- The bigger side wins 0.94–0.97, which confirms the fundamentals' 94%.
- *Implication:* the "Generous first" cut trigger "fights decided before they start" would already fire on our own pool in bot play. It needs a baseline before it can flag a dial.

**The spec's trigger** ("no felt jump means the engine card needs a visible step") points at legacy Bog, Hunters and Oozes, which have no ×2 round in 96–100% of seats. Check this on wave 2a/2b before acting.

**Not answered:** whether the jump feels like progress. That is checkpoint 1's criterion 1, and only P answers it: three fresh agent players × three games, with every moment checked against the log. The H1 review dropped the rule that P waits for accounting.

## Q4. Wide against tall

**Shape** (*measured*, compact `largest_share`): the biggest unit's share at R12/R15.
- Quilboar is wide: 0.23–0.26 / 0.19–0.22.
- Birds is the one tall line: 0.39–0.40 / 0.37–0.41.
- The others sit at 0.25–0.31 / 0.25–0.39.

**At equal totals, the wide gem board loses** (*measured*, captures; R9+ lobby fights where Quilboar's pre-start stats are 0.8–1.25× the opponent's):

| Arm | Quilboar win rate at equal totals | n | Native against native, wider side's win rate |
|---|---|---|---|
| B | 0.22 | 224 | 0.42 |
| C | 0.18 | 180 | 0.43 |
| uncut | 0.25 | 114 | 0.42 |
| frozen | 0.19 | 157 | 0.46 |

- **By round band** (B): R6–8 0.46, R9–11 0.22, R12–14 0.25 (n=28), R15+ 0.24 (n=21). Once its board is mostly gemmed Quilboar, it fights worse per stat.
- **On post-start totals** (after Start of Combat effects) it still wins only 0.28–0.36, against a 0.48–0.50 baseline. Start-of-combat gains explain part of it: Hedgerow ×1.25–1.35, Fairies ×1.08–1.12, Bog ×1.04–1.07, Quilboar ×1.00.
- **Stat-ratio curve** (B), the bigger side's win rate:

  | Bigger side has | 1–1.25× | 1.25–1.5× | 1.5–2× | 2–4× |
  |---|---|---|---|---|
  | Quilboar bigger | 0.33 | 0.62 | 0.77 | 0.96 |
  | Native against native | 0.58 | 0.72 | 0.84 | 0.98 |

  Quilboar breaks even only at about 1.3–1.4× the opponent's stats in every arm, so its stat point fights like about 0.7–0.75 of one of ours (*derived*).
- **Against tall opponents** (biggest share 0.4 or more), Quilboar wins 0.08–0.25 at equal totals, no better than against wide ones. Wide does not beat tall. Among natives, tall does slightly better (the wider side wins 0.42–0.46).
- **Our answers don't lose value.** Win rate at equal totals, against Quilboar and against other natives:

  | Line | Against Quilboar | Against other natives |
  |---|---|---|
  | Bog | 0.73–0.91 | 0.45–0.52 |
  | Hunters | 0.71–0.83 | 0.43–0.46 |
  | Birds | 0.55–1.00 | 0.46–0.50 |
  | Fairies | 0.64–0.84 | 0.43–0.53 |

  Every line gains, so most of this is a general per-stat weakness of the Quilboar board, not the borrowing mechanic. Bog's gain is the largest at C (+0.46).
- *Inferred causes, not separated by these data:*
  - in-fight power our tribes have and pre-start counting leaves out (sky, Belly, Takes, bites, Rings);
  - Quilboar's in-fight gems lasting only that fight;
  - the Quilboar bot's placement.

**The spec's trigger** ("answers that only hit the biggest enemy need a wide-board mode") is not supported in aggregate. Specific biggest-enemy answers, such as Whistlers, can't be isolated from lobby fights. That needs D4: equal-total designed boards with and without each tribe's answer, a few thousand fights, minutes of Godot, plus a generator task.

## Q5. Additive against proportional timing

**Paper's claim** (port §3.4): at the same preset, seven of twelve lines are level or ahead of Quilboar by R15. **Real: the reverse** (*measured*).
- **Medians, Quilboar against Birds** (h1.md tables):
  - B: Quilboar trails at R12 (259 against 309), leads 2.1× at R13 (811 against 379) and 3.2× at R15 (2,339 against 737).
  - Quilboar passes Birds' median at R12 in C and uncut, at R13 in B, and at R15 in frozen.
- **Same-cohort growth R12→R15** (seats alive at R15; median of per-seat (R15/R12)^(1/3), B):

  | Line | Growth a round | Cohort R12 → R15 |
  |---|---|---|
  | Quilboar | ×1.86 (C ×1.86, uncut ×2.06, frozen ×1.46) | 324 → 2,339 |
  | Birds | ×1.28 | |
  | Fairies | ×1.29 | |
  | Hedgerow | ×1.17 | |
  | Hard | ×1.14 | |
  | Bog, Hunters, Oozes | ×1.07–1.08 | |

  Our lines flatten after R12. For Birds and Fairies, real late growth is 0.6–0.75 of paper's on a log scale (Birds ×1.28 against paper's ×1.40, Fairies ×1.29 against ×1.48–1.53) (*derived*). Paper's §3.4 rows for the other four are pass 3 designs, not the legacy versions that ran.
- **Head to head** (captures, *measured*), Quilboar's win rate against all opponents by round band:

  | Arm | R6–8 | R9–11 | R12–14 | R15+ |
  |---|---|---|---|---|
  | B | 0.49 | **0.34** | 0.75 | 0.76 |
  | C | 0.48 | **0.38** | 0.84 | 0.88 |
  | uncut | 0.50 | 0.48 | 0.89 | 0.96 |
  | frozen | 0.45 | **0.27** | 0.54 | 0.61 |

  Against Birds alone (B): 0.38, 0.24, 0.48, 0.78. Quilboar's weak window is R9–R11, between the commit and Hogrider.
- **Games last long enough** (*measured*, `players[].rounds`).
  - No lobby in any arm ended by R14. The median end is R18–R19 (p10 R17).
  - Four players are left until a median R14.
  - Quilboar seats that don't win are out at a median R12, with a median 10 hero HP at R12 against 18 for eventual winners (B).
- **The spec's trigger** ("if winners finish by R14, proportional tribes need earlier power") doesn't fire. The problem the data show is the opposite one: our lines' late growth is below ×1.3. All-seat R8–R14 growth is ×1.24–1.26 in every arm (h1.md). *Implication:* checkpoint 1's criterion 2 should be read same-cohort and after R12 as well, not only as a pooled R8–R14 survivor median.

## Q6. Global size: retroactive or future-only

**The premise doesn't hold in real play** (*measured*).
- Paper put Ring size at 2 / 6 / 13 at R9 / R12 / R15, against gem size at B of 3 / 8 / 15.
- Real Ring size (captures, `fight_rules[].ring_size` on the Fairies seat): 1 / 2 / 6 at B, and 1 / 2 / 4 in the other arms; p90 at R15 is 11–15. Ring count on the board: 5–6 / 15–16 / 32–44.
- Real gem size, attack side (compact `gem_size`/2): B 2 / 5.5–6 / 9.5–10, C and uncut 3 / 10 / 16–18.
- Real Ring size is about a third of paper's at R12, and real gem size about 0.65–0.75× paper's at B (*derived*).
- Fairies make up for the small size with Ring count, so "retroactive size" in practice is count × size, with count doing the work.

**Not answered:** which reads and plays better.
- **Plays better:** D5, equal size curves delivered both ways on the same bodies. Use the **real** curves above, not paper's. This is a generator task, then minutes of Godot.
- **Reads better:** only P answers it ("which number did you watch").

## Q7. Coupling as the guardrail

**Not run.** H1 had no "Gem Day isn't a Choose One card" arm and no "half Refiner steps" arm.

**Paper estimate** (*derived*, `q7_paper.py` on a patched scratch copy of `qm3.py`; cycling at 6 gold; dial `gemday_no_hog`), at B:

| Arm | Typical R12 / R15 | Strong R12 / R15 | Low roll R12 / R15 | Strong ÷ low (R12) |
|---|---|---|---|---|
| As built | 1,144 / 3,363 | 1,698 / 5,814 | 308 / 1,443 | 5.5× |
| Coupling cut: Gem Day doesn't trigger Hogrider | 1,016 / 2,943 (−11%) | 1,178 / 5,164 (**−31%**) | 308 / 1,218 | 3.8× |
| Axis cut: half Refiner steps | 960 / 2,742 (−16%) | 1,532 / 4,782 (−10%) | 308 / 1,443 | 5.0× |

- C and uncut show the same pattern: the coupling cut takes 31% and 22% off the strong line, and the axis cut 14% and 14%.
- **Reading:** on paper, cutting the coupling cuts from the top, which is what "Generous first" asks a cut to do. Cutting the axis lowers the median more than the top.
- **Can paper be trusted here?** Paper's dial *ratios* transferred in H1 even though its levels missed by 4×. B→C was ×1.70 / ×1.82 on paper and ×1.54 / ×1.76 real (Q8). Paper's strong ÷ low (5.5 / 7.1 / 22) matches the real p90 ÷ p10 (5.4 / 7.4 / 20.6, Q9). So this paper ranking is a reasonable first read, but not a measurement.

**To measure:**
- Build two reference dials (Gem Day's Hogrider trigger, and the Refiner step).
- Run three B arms (control, coupling, axis) at 150 lobbies each on the current tree. That is about 26 minutes of Godot at 3.5 s a lobby, plus a new frozen plan, targeted tests and a review.
- Compare median, p90 and the R8 leader's win rate.

## Q8. Is "obliterate" scale or axes?

**Confirmed** (*measured*, compact, same seed labels 2911001–100, `q_compact.py` Q8 block): uncut-pre against frozen, Quilboar median.

| Round | R9 | R10 | R11 | R12 | R13 | R15 | R16 |
|---|---|---|---|---|---|---|---|
| uncut-pre | 83 | 97 | 137 | **825.5** (n=80) | 2,192.5 | 7,718 (n=71) | 10,939 |
| frozen | 73.5 | 88.5 | 104 | **175.5** (n=68) | 296 | 803 (n=31) | 979 |
| ratio | 1.13 | 1.10 | 1.32 | **4.70** | 7.41 | 9.61 | 11.17 |

**Extended:**
- **Intervals** (*derived*). Paired seed bootstrap at R12: [3.97, 5.36]. At R15: ×9.61 [8.11, 12.53].
- **Per seed** (*derived*). Where both seats are alive, uncut is bigger in 92% of seeds at R12 (median ×4.11, n=66) and in 100% at R15 (×11.0, n=31). Shop draws diverge after the first choices, so read this as a strong tendency, not a controlled pair.
- **Outcomes** (*measured*). Freezing size moves the Quilboar seat:

  | | Uncut-pre | Frozen |
  |---|---|---|
  | Mean place | 2.87 | 5.10 |
  | First place | 0.60 | 0.09 |
  | Top 4 | 0.72 | 0.35 |
  | Alive at R15 | 0.71 | 0.31 |

  Frozen BG-text Quilboar places below Hard (3.53). Birds' first-place rate goes from 0.18 to 0.50 in the same lobbies. Head to head, frozen beats Birds 0.04 of the time at R9–11 and 0.18 at R12–14.
- **Share of the gap** (*derived*). ln(uncut/frozen) ÷ ln(uncut/native) at R12 is 0.72–0.89 for Fairies, Bog, Hedgerow, Hunters, Oozes and Hard, and 1.39 for Birds (frozen falls below Birds). Frozen keeps BG's count and application text, so in our engine the gap comes from size growth, not from BG's other numbers. That contradicts paper's "about 65% of the gap is BG's general scale". That figure came from BG's whole-game median against preset A, not from an ablation, and the real ablation doesn't support it.
- **The size *rate* dial, controlled** (*measured*, B-pre against C, same seeds, only the gem-size step differs):

  | | Real | Paper |
  |---|---|---|
  | C ÷ B at R12 | ×1.54 [1.33, 1.67] | ×1.70 |
  | C ÷ B at R15 | ×1.76 [1.52, 1.95] | ×1.82 |
  | First place, B → C | 0.34 → 0.50 | |
  | Birds' first place, B → C | 0.34 → 0.23 | |

- **Paper against real for the frozen ablation** (*derived*). Paper's size-off cut was ÷11.6 at R12 and ÷20.1 at R15; the real cut was ÷4.7 and ÷9.6. Paper overstates the *level* effect, but not the direction or the ranking of the dials.
- **Not run:** the optional uncut two-axis BG tribe (Undead) control. It would separate "BG's scale" from "the third axis" outside Quilboar. Cost: a second test-only port of about Quilboar Phase 1's size (spec, build, gate, review), then 100 lobbies, about 6 minutes of Godot.

## Q9. Keystone dependence

**From H1** (*measured*, compact `keystone_found_round`, `units`):

| Arm | Hogrider by R12 | Mean place with / without | First place with / without |
|---|---|---|---|
| B | 0.61 | 2.92 / 5.46 | 0.44 / 0.14 |
| C | 0.55 | 2.32 / 4.62 | 0.65 / 0.32 |
| uncut | 0.69 | 2.16 / 4.48 | 0.75 / 0.39 |
| frozen | 0.45 | 3.33 / 6.55 | 0.16 / 0.04 |

- **Among seats alive at R13**, which removes early deaths (`q_followup.py`):

  | Arm | Hogrider by R12 | Mean place with / without |
  |---|---|---|
  | B | 0.77 | 1.62 / 2.25 |
  | C | 0.68 | 1.48 / 1.76 |
  | uncut | 0.80 | 1.05 / 1.14 |
  | frozen | 0.70 | 2.51 / 4.40 |

  *Inferred:* most of the "keystone" gap is surviving the R9–R11 trough (Q5). Hogrider itself is worth about 0.3–0.6 places once a seat gets there.
- **Hogrider's arrival round among holders is flat or non-monotonic.** At B: R11 3.88, R12 2.60, R13 1.86. *Inferred:* survivor bias, since getting it at R13 needs being alive at R13.
- **Native legacy engine pieces** (`engine_pieces` in `line_profiles.committed.json` at bb8bb5f2) are on the board by R12 in 60–86% of seats. They are worth 0.4–1.4 places. Quilboar's unconditional gap is 2.3–3.2 places.
- **Spread at R12** (p90 ÷ p10 of survivors; *measured*):
  - Quilboar: 5.4 (B), 7.4 (C), 20.6 (uncut). Paper's strong ÷ low is 5.5 / 7.1 / 22 (*derived*: paper's spread transfers almost exactly).
  - Birds 4.3–5.3, Hedgerow 2.3–3.3, Fairies 2.4–2.8, Hard 2.5–2.8, legacy Bog/Hunters/Oozes 1.7–2.1.
- **The spec's trigger** ("tribes that bust without their keystone need a second route"): no native line shows a bust pattern. D6 (each tribe's R12 board with and without its keystone) is still needed for Birds and Fairies. Their line files name no keystone, so one has to be picked first. It is a generator task, then minutes of Godot.

## Q10. Cross-tribe hazards on a gem board

**Not exercised by H1** (*measured*).
- The Quilboar seat holds at least one native unit from R8 in 71% of games, mostly flex units on the way out.
- The hazard cards are rare or absent: Busker 18 of 500 seats, Silky 59, Sexton Beetle 5, Whirligig Beetle 10, Pipistrelle Echo 0, Stone Soup 0.
- Natives never receive gems. Phase 1 has no Felboar, Barrage or Bonker.
- One hazard was found anyway, by code review rather than sim: the Busker loop guard capped *native* seats' Created 0-cost spells (Triple Rewards, Pelts) in reference lobbies (review simplify 1, fixed).

**To answer:** build Phase 2, and give the line a policy that keeps the splash card, because the current bot sells flex units. Then run H4 at B under both rate-limit settings: 2 × 150 lobbies, about 18 minutes of Godot, plus the build and its review.

---

## Assumptions these answers challenge

1. **Board-stat totals are a fair cross-tribe power measure.** At equal totals the gem board wins 18–25% (Q4), so a stat total counts differently by tribe.
   - Preset targets (500 / 900 / 1,800 at R12), the accounting criterion and "obliterate" are all stat totals.
   - It fits the owner's "stat distribution beats totals". Any "tribe X is N× tribe Y" claim should carry a head-to-head number beside it.
2. **Our tribes are proportional and catch up late.** In bot play they flatten after R12 (×1.07–1.29), while additive-trivariate Quilboar compounds (Q5).
3. **Paper levels can be targets.** They can't (0.12–0.23× at R12). But paper ratios held: the size dial within ~10%, and the strong ÷ low spread almost exactly (Q8, Q9). Use paper to rank dials and predict spread, and realized medians for levels. This agrees with the 10 Nov call "targets stay on realized medians".
4. **The harness can measure flex and pivots.** It can't. Every bot, Hard included, fixes its line at R1 (Q2), and holdings mirror bot pick rules (Q1).
5. **"Fights decided before they start" works as a cut trigger.** 61–63% of native-only late fights already meet the 1.5× definition, and the bigger board wins 95% (Q3). It needs a baseline, or a narrower definition.
6. **Retroactive and future-only size can be compared on paper curves.** Real Ring and gem sizes diverge 3× at R12 (Q6).

## Reproduce

From `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/quilboar-lessons/`:

```sh
python3 -I scripts/q_compact.py   > out_compact.txt     # Q1-Q3, Q5, Q8, Q9, Q10 (committed compact archives only)
python3 -I scripts/q_captures.py  > out_captures.txt    # Q3-Q6 head to head (local captures, hash-checked; writes fights.pkl)
python3 -I scripts/q_followup.py  > out_followup.txt    # post-start totals, Hogrider among R13 survivors, Hard's lines, splash cards
python3 -I scripts/q4_bands.py    > out_q4_bands.txt
python3 -I scripts/q5_bands_all.py > out_q5_bands_all.txt
cd scripts && python3 -I -B q7_paper.py > ../out_q7_paper.txt   # paper only, on model-copy/ (patched copy of qm3.py)
```

The unit tribes and tiers come from `content-bb8bb5f2/`, a `git archive` of the run's source commit. The native content is identical at edfe1ed1, the post-fix runtime (an empty diff for `content/units`, `content/reference`, `tools/sim/lines` and the line profiles).
