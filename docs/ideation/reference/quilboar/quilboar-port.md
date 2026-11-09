# Quilboar reference port: TEST-ONLY

> **TEST-ONLY.**
> - This is a reference set for A/B measurement. It is never in the release pool, and it is never merged, cherry-picked or copied into any branch headed for `main` (owner's rule, 6 Nov).
> - Card ids are `qb_*`. They load only behind the pool flag `reference_quilboar`, which is off by default, from their own folder (`content/reference/quilboar/`, never `content/units/`).
> - The Battlegrounds names are working names only.

Final spec after review, 10 Nov 2026. This is paper only: no Godot was run. The model is `model/qm3.py`, with the drivers `presets3.py`, `final3.py` and `hand3.py` in the same folder. The research it rests on, the first port and its review are in `research/`. It is the first port's model with the review's fixes applied (§10.4).

---

## 0. In short

- **Preset.** The budget is set at **B**, the default, because DECISIONS (09h) says "The Quilboar reference port is budgeted at B, not A." **C** is the fidelity arm: its card text is closest to BG's, with whole numbers and no halves. **A** is listed as the fallback only. Each preset is one dial away from the next:
  - A → B: Hogrider fires after every Choose One card instead of every second one.
  - B → C: gem-size steps go from half to whole.
- **Paper curve, typical line** (board stats at R6 / R9 / R12 / R15):

  | Preset | Board stats | R12 against its target | Growth a round, R8–R14 |
  |---|---|---|---|
  | B | 54 / 167 / 1,144 / 3,363 | 1.27× (900) | ×1.68 |
  | C | 54 / 203 / 1,942 / 6,123 | 1.08× (1,800) | ×1.82 |

  Every Quilboar line passes checkpoint criterion 2 (×1.3 a round) on paper.
- **The owner's prediction ("they will obliterate almost all of our designs"):**
  - **At BG's card text on our economy, it holds from R11.** This is the "uncut" switch. Quilboar beats our pass 3 lines 6.3–13.6× at R12 and 6.5–15.4× at R15, but only 1.0–1.9× at R9.
  - **Two readings are both true.** About 65% of the R12 gap (on a log scale) is Battlegrounds' general scale. But Quilboar reaches that scale through its third axis: freeze gem size alone and BG-text Quilboar falls onto our A curve (532 at R12).
  - **At the same preset,** Quilboar leads every pass 3 line at R12, by 1.2–1.8×. By R15, seven of the twelve lines are level or ahead. That is Quilboar's timing identity: strongest just after the commit card, then caught by our proportional tribes.
- **Trivariate scaling.**
  - Gain a turn = count × applications × size. Count and size grow roughly linearly with time; applications are capped by the board.
  - So growth is polynomial and front-loaded at the commit card. Growth a round decays after Hogrider: at B it runs ×1.90 at R11, then ×2.25, ×1.53, ×1.42, ×1.36, ×1.28.
  - Size is the strongest dial: freezing it costs ×4.3 at R12 and ×7.1 at R15 at B.
  - Its leverage comes from coupling: one card that moves two axes.
- **What the review changed:**
  1. Rate cuts are stored as dials and loop guards, so they survive caps-off.
  2. Refiner triggers on every attack again, so it is a staple again.
  3. Bonker waits for repeat attacks.
  4. The tribe comparison is made at the same preset.
  5. Confiscations are held, and steal only at the end.
  6. The gems-from-hand line is now modelled. It stays behind Choose One at B and C, with a cut named in advance.
  7. Snare Trapper gives +1 gold every turn.
  8. Gems follow the Shy rule.
  9. Leftmost is per row.
  10. Cycling is costed at 6 gold a find instead of 4.5.
- **Test plan (§11).** Two criteria decide whether the reference is usable: accounting (harness within 0.5–2× of paper) and fidelity (uncut beats our lines at least 4× at R12). Ten questions about our tribes are reported, not deciding, as note 09i asks.

---

## 1. What I could and could not access

**Could not:**
- **Video.** I watched none: agents can't watch video. I found no transcripts or VOD summaries for Jeef or XQN.
  - `bobs-ledger-transcripts/comp_transcripts.json` holds only YouTube ids for the Choose One guide (`pSFnITXBal8`, `3ebRlvd1rKI`, `IzEAFMUvG3g`), and says the caption text is deliberately not kept. I did not fetch the captions.
  - For XQN, I have only video titles and descriptions.
- **HSReplay comp pages and Tier 7** (the Hearthstone Deck Tracker guides, which are Jeef's writing). Every page returned 403, and I did not try to get around it.

**Could** (saved under `scratchpad/refs/` as untrusted data; nothing executed):
- **A public copy of Jeef's HSReplay comp data:** bobs-ledger `comps.json`, with tier, difficulty, summary, `when_to_commit`, core and addon cards. Its how-to-play text is that project's own rewrite. It also has a recorded 1st-place Felboar game (20 Oct).
- **Firestone:**
  - comp strategies: `quilboar_choose_one` (power B), `quilboar_felboar_spam` (S, hard) and `quilboar_gem_spam` (C);
  - slyders' tips (17 Oct 2026);
  - 40 final boards per comp.
- **bgbuddy** comp stats and tips.
- **Blizzard patch notes** 36.2.2, 36.4.2, 36.6.3 and 37.0.2.
- **Local data:**
  - `docs/research/battlegrounds/data/minions.csv` and `spells.json` (37.0.0, with 37.0.2 applied by hand);
  - `fundamentals/web/perfect_combats.jsonl` (9 perfect-game Quilboar winners).
- **Wiki, fetched 10 Nov:**
  - [Battlegrounds/Blood Gem Barrage](https://hearthstone.wiki.gg/wiki/Battlegrounds/Blood_Gem_Barrage): tier 4, 1 gold. It was "+1/+1 worth" before 36.6.3, and its script data holds two 2s. It does not say whether gem size scales it (§12).
  - [Battlegrounds/Blood Gem](https://hearthstone.wiki.gg/wiki/Blood_Gem).

**Facts found in the local data, used below:**
- Gem Confiscation and Blood Gem Barrage are **tier 4 Tavern spells, 1 gold, in the current shop pool**, as well as tokens.
- The Choose One Tavern spells are Alliance Flag (T1, 1 gold), Time Management (T3), Boundless Potential (T4), Forest's Bounty (T5) and Fandral's Fortune (T6). They are neutral and not ported (§7).

---

## 2. The tribe, and how good players play it

**Identity and engine.**
- Quilboar are Battlegrounds' Blood Gem tribe. Their cards make 0-gold +1/+1 spells (Blood Gems).
- Uniquely, they also raise what every *future* gem gives: "Your Blood Gems give an extra +1/+1 this game."
- The most played line in the 37.0 pool is **Choose One**:
  - Gem Rat (End of Turn: a Gem Day) and Bramble Tunneler (Rally: a random Choose One card) generate Choose One cards.
  - Turbo Hogrider turns each Choose One card into gems on every Quilboar.
  - Sanguine Refiner, Champion, Fearless Foodie and Gem Day itself raise gem size each turn and each fight.

**How good players play it:**
- **Early (turns 1–5):** tempo with whatever is strong.
  - Quilboar are only 35–45% of perfect-game winners' boards before turn 6.
  - No tier 1–2 Quilboar is core, addon or cycle in any comp.
  - Geomancer, Roadboar and Crater Miner are taken for their banked gems, a currency any unit can use.
- **Pivot:** players commit on "Gem Rat/Bramble Tunneler + Turbo Hogrider" (bobs-ledger). slyders: "Generate some economy and gem boost early with Bramble Tunneler, When you find Turbo Hogrider, Cycle all Choose One card." The Quilboar share of the board then climbs to 54%, 66% and 79% on turns 6, 7 and 8.
- **Mid:** they level to tier 6 for Hogrider, and scale gems "through Gem rat or Sanguine Refiner".
- **Endgame:** they cycle every decent Choose One card in the shop. The guide's only skips are Intrepid Botanist and Time Management.
  - Final boards hold Hogrider (40 of 40 Firestone boards; 100% of perfect games), Tunneler (39/40; 86%), Gem Rat (20/40; 58%) and Refiner (15/40; 47%).
  - The board is wide: the biggest unit is about 30% of it (Firestone median 0.30), against 34% across BG.
  - "At the end, use Gem Confiscation on a carry minion."
  - Choose One has the highest 1st-place rate of 29 comps (29.8%), but only 65% top 4. It wins big or busts.

**The other lines:**
- Felboar shop-buff: S tier, but it needs Demons, Balinda and Brann.
- Gem Spam, or gems from hand: Surveyor + Roogug + Tunneler + Balinda.
- Gem Barrage.
- Firestone final boards: Choose One median 44,467, Gem Spam 37,408 (0.84×; those boards mix in Hogrider and Felboar), Felboar 63,039.

**Patch history.** Over 36.x–37.0 Blizzard moved Quilboar from the weakest tribe to one they called too strong:
- 36.4.2: Refiner +1/+2, Champion +2/+1.
- 36.6.3: Hogrider went from 1 gem on your *other* Quilboar to 2 gems on *all* your Quilboar.
- 37.0.2: Refiner back to +1/+1, and Surveyor moved to tier 5.

**What the reference ports:** Choose One. It is the most played commit, it is mostly in-tribe, and it needs no Demons or Balinda. Gems from hand is a check line (§9).

---

## 3. Trivariate scaling

### 3.1 The three axes and the time terms

`G(t) = C(t) × A(t) × S(t)` and `Board(T) = bodies + Σ_{t≤T} G(t)`

| Axis | What it is | Quilboar sources |
|---|---|---|
| **C, count** | Gems, or gem-producing Choose One cards, arriving each turn | Gem Rat's Gem Day (one a turn per Rat); Tunneler cards (per fight); shop cycling (one Choose One unit per about 6 gold at T6); printed gems (Geomancer 2, Miner 2, Foodie 4, Sly 3, Roadboar 1 a fight); Geomant 6 a turn |
| **A, applications** | How many units each source lands on, or how many times it is cast | Hogrider (each Choose One card lands on every other Quilboar, so A ≈ 5–6); Brigand and Bonker (all units); Roogug (echoes); Surveyor and Balinda (cast again); End of Turn doublers |
| **S, size** | Gem size: one player-wide number that applies to every future gem, not to old ones | Gem Day, Foodie, Refiner (every attack), Champion (when played and when it dies) |

**Time terms.**
- S steps up each turn (Gem Rat) and each fight (Refiner, Champion's death). So it is roughly linear in t, with a slope equal to the number of size engines owned.
- C is also roughly linear, because generators are bought over time.
- A saturates at the board size (7).

**Acceleration terms.**
- Each engine bought steps up a slope: a second Rat, a golden Tunneler, a second Hogrider.
- The axes are **coupled**:
  - Gem Day moves S, and through Hogrider it also moves C × A.
  - Tunneler's cards are themselves Choose One cards.
  - Thorned Trailblazer makes one card do both of its modes.

**Result: polynomial, front-loaded growth.**
- With C and S linear and A capped, G is about quadratic and the board about cubic. There is no proportional term.
- The clearest evidence is the decay in growth a round after the commit card:

  | Arm | R11 | R12 | R13 | R14 | R15 | R16 |
  |---|---|---|---|---|---|---|
  | B | ×1.90 | ×2.25 | ×1.53 | ×1.42 | ×1.36 | ×1.28 |
  | C | ×2.19 | ×2.47 | ×1.58 | ×1.45 | ×1.38 | ×1.30 |
  | Uncut | ×5.25 | ×2.95 | ×1.84 | ×1.51 | ×1.39 | ×1.28 |

- Our proportional tribes add a share of their own board (`G = r × Board`), so they grow as `(1 + r)^t` and catch up later.
- An "effective degree" fit depends on where the clock starts, so I don't lead with it.

### 3.2 Each axis switched off (typical line, board stats)

How each ablation is run:
- **Count flat:** one Gem Day a turn from one Rat, plus printed gems on bought units. No Tunneler cards, no cycling, no Roadboar gems.
- **Apps off:** Hogrider and Brigand gems land on one unit only.
- **Size off:** gems stay +1/+1. Foodie and Miner then take their gem modes, the rational pick (the first spec's version left them on a dead size mode).
- **Time off:** no per-fight growth (Refiner, Champion deaths, Tunneler and Roadboar).

Count flat and time off give the same figures at R6 and R9. Both remove Roadboar's and Tunneler's per-fight output, and nothing else either removes acts before R10 (R8 is a saving turn, so cycling hasn't started).

Each cell: R12 / R15, with the factor lost in brackets.

| Ablation | Uncut (BG text) | B | C |
|---|---|---|---|
| Full | 6,195 / 23,945 | 1,144 / 3,363 | 1,942 / 6,123 |
| Count flat | 1,360 / 2,524 (÷4.6 / ÷9.5) | 534 / 771 (÷2.1 / ÷4.4) | 821 / 1,267 (÷2.4 / ÷4.8) |
| Apps off | 1,672 / 5,727 (÷3.7 / ÷4.2) | 557 / 1,265 (÷2.1 / ÷2.7) | 878 / 2,211 (÷2.2 / ÷2.8) |
| **Size off** | **532 / 1,190 (÷11.6 / ÷20.1)** | 266 / 471 (÷4.3 / ÷7.1) | 266 / 471 (÷7.3 / ÷13.0) |
| Time off | 1,127 / 3,557 (÷5.5 / ÷6.7) | 493 / 1,027 (÷2.3 / ÷3.3) | 704 / 1,630 (÷2.8 / ÷3.8) |
| All three axes off | 164 / 169 | 158 / 157 | 158 / 157 |

- **Headline:** with gem size frozen, BG-text Quilboar sits on preset A: 532 against 500 at R12, and 1,190 against 1,700 at R15. That is the owner's "extra scaling multiplier".
- **Leverage order:** size first at every preset. Count, time and applications are close at R12. By R15 count is second.
- The axes interact, so each figure includes cross terms. Read them as leverage, not as separate shares.

### 3.3 Why BG numbers obliterate our designs

- **The gap.** Uncut Quilboar is 6.3–13.6× every pass 3 line at R12 and 6.5–15.4× at R15, but only 1.0–1.9× at R9. The gap opens at Hogrider (R11).
- **BG's own scale.** BG's median board at R12 is 2,598, which is 5.2× preset A. Uncut Quilboar's 6,195 is 2.4× BG's median and 0.82× BG's perfect-game winners (7,598). So on a log scale, about 65% of the gap is Battlegrounds' general scale, which every BG tribe shares.
- **How Quilboar gets there.** The size axis puts Quilboar on BG's scale: it is one global number, raised by several cards every turn and every fight, and fed by the same card that drives count (Gem Day). None of our tribes has all three properties.
- **Is it the axes or the scale?** Test 8 (§11) answers this with two controls:
  - BG-text Quilboar with gem size frozen;
  - optionally, an uncut two-axis BG tribe.

### 3.4 Our tribes by axis, against the port at the same preset

There are four properties: count; fan-out (one buff landing on several units); global size, and whether it is retroactive; and a proportional term.

The comparison is made at the same preset:
- **Birds, Bog, Hunters and Hedgerow** are compared at A, against Quilboar at A. Their B values aren't written yet; wave 2 writes them.
- **Fairies and Oozes** are at their design size, which is B, so they are compared against Quilboar at B.

Quilboar at A: 54 / 167 / 824 / 2,230. At B: 54 / 167 / 1,144 / 3,363.

| Tribe | Count | Fan-out | Global size | Proportional term | Line ÷ Quilboar (R6 / R9 / R12 / R15) | Growth a round, R12→R15 |
|---|---|---|---|---|---|---|
| **Quilboar** | Gem Days, Tunneler cards, cycling | Hogrider (other Quilboar), Brigand, Bonker, Roogug, Surveyor | Gem size, **future-only** | None | 1 | ×1.39 (A), ×1.43 (B) |
| Fairies (B) | Ring count (gold and sales) | Fetch twin | Ring size, **retroactive** (tier-ups, thanks) | Monarch's ×2 clock | Ring: 0.85 / 0.84 / 0.81 / 0.90. Court: 0.93 / 1.26 / 0.86 / 1.06 | ×1.48, ×1.53 |
| Oozes (B) | Meals a turn | Elder, Aspic | Stone Soup: **self-proportional** | Yes (through Soup) | Pudding: 1.39 / 1.35 / 0.73 / 1.10. Pot Luck: 1.19 / 1.25 / 0.81 / 0.80 | ×1.64, ×1.43 |
| Hedgerow (A) | Supper food | Lollop, Committee | Hayward: a retroactive tribe counter | Dozey, Mallow | Supper: 1.26 / 1.14 / 0.75 / 1.06. Parish: 0.83 / 0.79 / 0.61 / 1.19 | ×1.56, ×1.74 |
| Birds (A) | One doubling per Bird per 2 rounds; Stork | Thin (Redbreast, Cuckoo) | None | Self (homecoming ×2) | A: 0.76 / 0.84 / 0.75 / 0.76. D: 0.67 / 0.68 / 0.57 / 0.70 | ×1.40, ×1.49 |
| Bog (A) | Bites | Tiddy funnel; the frog | Borrowed: a quarter of the biter's Attack | Proportional to the enemy | Court: 0.91 / 0.72 / 0.72 / 1.10. Swamp: 0.96 / 0.72 / 0.55 / 0.75 | ×1.61, ×1.55 |
| Hunters (A) | Takes a fight | Little (Glutton, Laird, Pelts) | Half the quarry's stats | Proportional to the enemy | A: 1.00 / 1.04 / 0.63 / 0.85. B: 1.02 / 1.02 / 0.73 / 1.08 | ×1.54, ×1.59 |

**Reading:**
- None of our tribes is additive-trivariate.
- **Closest by mechanism: Fairies.** Gem size at B (3 / 8 / 15 at R9 / R12 / R15) nearly matches the Ring size curve (2 / 6 / 13). That gives a clean test of retroactive against future-only size (question 6).
- **Timing identity.** Quilboar leads every line at R12. From R12 to R15 it grows slower than every line except Birds A and Pot Luck. By R15, seven lines are at 0.9× or more: Fairies Court and Ring, Oozes Pudding, Bog court, Hunters B, and both Hedgerow lines.
- Birds' ratio is flat (0.75 → 0.76), so there is no overtake in sight. The first spec's "Birds overtake about R17" is withdrawn.
- **Head to head may differ from totals:**
  - Bog's bites and Hunters' Takes borrow from the enemy, and gemmed, high-Attack Quilboar feed them.
  - A wide board (biggest unit 0.32–0.34) limits each Take, and lowers the value of the Whistlers and other biggest-enemy answers.

### 3.5 What the reference teaches

1. **Timing.** Additive trivariate scaling peaks right after the commit card and fades. Proportional scaling catches up late. Which one wins depends on when games end (question 5).
2. **Size is the strongest dial.** One global, future-only size number is worth ×4–7 at B, and ×12–20 at BG's numbers.
3. **Coupling.** The acceleration comes from coupling: Gem Day moves size and count × applications at once. Limiting coupling may be a gentler guardrail than limiting any one axis (question 7).

---

## 4. The cards

**Text conventions.**
- Card text is written for **B**; C's numbers are in brackets.
- Battlecry → "When played"; Deathrattle → "When this dies"; Rally → "When this attacks"; Activate → "Power (X gold): … Once a turn."
- Gems played during a fight last that fight only, unless the text says otherwise (as in BG).
- **Golden** (7.3.5) doubles base stats and every number. Counters keep their value.
- **Changed** marks a number or rate change from 37.0.2.

### 4.1 Units

| T | BG name (BG stats) | BG text (37.0.2) | Bramble id | Bramble text (B) [C] | Golden (B) |
|---|---|---|---|---|---|
| 1 | Razorfen Geomancer (2/1) | Battlecry: Get 2 Blood Gems. | `qb_razorfen_geomancer` | When played: get 2 Blood Gems. | 4 gems |
| 1 | Tusked Camper (2/3) | Rally: This plays a Blood Gem on itself. | `qb_tusked_camper` | When this attacks: play a Blood Gem on it. | 2 gems |
| 2 | Crater Miner (2/2) | Choose One – Get 2 Blood Gems; or Get a Gem Day. | `qb_crater_miner` | Choose one: get 2 Blood Gems; or get a Gem Day. | 4 gems; or 2 Gem Days |
| 2 | Prodigious Tusker (2/5) | Whenever another friendly minion attacks, this plays a Blood Gem on it. | `qb_prodigious_tusker` | When another of your units attacks: play a Blood Gem on it. | 2 gems |
| 2 | Roadboar (2/4) | Rally: Get a Blood Gem. | `qb_roadboar` | When this attacks: get a Blood Gem. | 2 gems |
| 3 | Fearless Foodie (2/4) | Choose One – Your Blood Gems give an extra +1/+1 this game; or Get 4 Blood Gems. | `qb_fearless_foodie` | **Changed:** Choose one: your Blood Gems give an extra **+½/+½** [+1/+1] this game; or get 4 Blood Gems. | +1/+1 [+2/+2]; or 8 gems |
| 3 | Gem Rat (4/4) | At the end of your turn, get a Gem Day. | `qb_gem_rat` | End of Turn: get a Gem Day. | 2 Gem Days |
| 3 | Mangled Bandit (3/3) | Activate (0): Discard a card to get 3 Blood Gems. | `qb_mangled_bandit` | Power (0 gold): discard a card to get 3 Blood Gems. Once a turn. | 6 gems |
| 3 | Sly Infiltrator (4/5) | Choose One – Gain 2 free Refreshes; or Get 3 Blood Gems. | `qb_sly_infiltrator` | Choose one: get 2 free refreshes; or get 3 Blood Gems. | 4 refreshes; or 6 gems |
| 3 | Thorned Trailblazer (4/5) | One Choose One card each turn has both effects combined. | `qb_thorned_trailblazer` | One Choose One card each turn has both effects. (1 left!) | Two cards a turn |
| 3 | Trench Fighter (3/3) | At the end of your turn, get a Gem Confiscation. | `qb_trench_fighter` | End of Turn: get a Gem Confiscation. | 2 |
| 4 | Bonker (2/7) | Windfury. Rally: This plays a Blood Gem on all your other minions. | `qb_bonker` | Attacks twice in a row. When this attacks: play a Blood Gem on each of your other units. **Kept out of the pool until repeat attacks are built (§8, item 22).** | 2 gems |
| 4 | Bramble Tunneler (3/6) | Rally: Get a random Choose One card. | `qb_bramble_tunneler` | **Changed:** When this attacks: get a random Choose One card. **Once a fight.** | 2 cards |
| 4 | Geomagus Roogug (4/6) | Divine Shield. Whenever a Blood Gem is played on this, this plays a Blood Gem on a different friendly minion. | `qb_geomagus_roogug` | Shield. When a Blood Gem is played on this: play a Blood Gem on another random unit of yours. | 2 gems |
| 4 | Razorfen Flapper (5/3) | Battlecry and Deathrattle: Get a Blood Gem Barrage. | `qb_razorfen_flapper` | When played, and when this dies: get a Blood Gem Barrage. | 2 |
| 4 | Snare Trapper (4/4) | Choose One – Get a random Quilboar; or Increase your maximum Gold by 1. | `qb_snare_trapper` | Choose one: get a random Quilboar; or get +1 gold each turn. | 2 Quilboar; or +2 gold |
| 5 | Hot-Air Surveyor (3/7; T4 before 37.0.2) | Blood Gems played from your hand cast an extra time. | `qb_hot_air_surveyor` | Blood Gems you play from your hand cast an extra time. | 2 extra |
| 5 | Felboar (2/6; Demon, Quilboar) | After you cast 3 spells, consume a minion in the Tavern to gain its stats. (3 left!) | `qb_felboar` | Tribe: Quilboar. After you cast 3 spells: Eat a unit in the shop. (3 left!) | Gains double its stats |
| 5 | Razorfen Vineweaver (4/4) | Rally: This plays 4 permanent Blood Gems on itself. | `qb_razorfen_vineweaver` | When this attacks: play 4 Blood Gems on it that last beyond this fight. | 8 gems |
| 5 | Sanguine Refiner (3/8) | Rally: Your Blood Gems give an extra +1/+1 this game. | `qb_sanguine_refiner` | **Changed:** When this attacks: your Blood Gems give an extra **+½/+½** [+1/+1] this game. | +1/+1 [+2/+2] |
| 6 | Sanguine Champion (9/4) | Battlecry and Deathrattle: Your Blood Gems give an extra +2/+1 this game. | `qb_sanguine_champion` | **Changed:** When played, and when this dies: your Blood Gems give an extra **+1/+½** [+2/+1] this game. | +2/+1 [+4/+2] |
| 6 | Turbo Hogrider (6/8) | After you play a Choose One card, this plays 2 Blood Gems on all your Quilboar. | `qb_turbo_hogrider` | **Changed (BG's text before 36.6.3):** After you play a Choose One card: play **a** Blood Gem on each of your **other** Quilboar. | 2 gems on each |
| 6 | Veteran Brigand (8/8) | Choose One – This plays 3 Blood Gems on all your minions; or cast Blood Gem Barrage 3 times. | `qb_veteran_brigand` | **Changed:** Choose one: play **a** Blood Gem on each of your units; or cast Blood Gem Barrage **once**. | 2 gems; or twice |
| 6 | Victorious Geomant (10/10) | Activate (2): Get 6 Blood Gems. Cast any that don't fit on your left-most minion. | `qb_victorious_geomant` | Power (2 gold): get 6 Blood Gems. Once a turn. Any that don't fit in your hand go on your leftmost front-row unit. | 12 gems |

**Left out:**
- Duos-only cards: Generous Geomancer, Loyal Mobster.
- Tier 7: Jailbird Juggernaut.
- Trinkets such as Jar o' Gems.

### 4.2 Spells and tokens

| BG name | BG cost and text | Bramble id | Bramble (B) | Where it comes from |
|---|---|---|---|---|
| Blood Gem | 0: +1/+1 | `qb_blood_gem` | Spell, 0 gold, aimed at a unit: it gets **+[gem size]** (starts +1/+1). | Token |
| Gem Day | 0: Choose One – your Blood Gems give an extra +1 Attack this game; or +1 Health | `qb_gem_day` | **Changed:** Spell, 0 gold. Choose one: your Blood Gems give an extra **+½ Attack** [+1] this game; or **+½ Health** [+1]. It counts as a Choose One card. | Token |
| Gem Confiscation | 1: This plays 3 Blood Gems on a minion. It steals all Blood Gems from its neighbors. | `qb_gem_confiscation` | Spell, 1 gold, aimed: play 3 Blood Gems on a unit. It takes all Blood Gem stats from the units beside it. | Token (Trench Fighter) **and a tier 4 shop spell** (behind the flag) |
| Blood Gem Barrage | 1: After the Tavern is Refreshed this game, give its minions +2/+2 worth of Blood Gems. | `qb_blood_gem_barrage` | Spell, 1 gold: for the rest of the game, after your shop is refreshed, its units gain +2/+2, counted as Blood Gem stats. Stacks. | Token (Flapper, Brigand) **and a tier 4 shop spell** |

**Barrage reading.** I read Barrage as a flat +2/+2 that does not scale with gem size. Two things point that way: the text says "+2/+2 worth", it was "+1/+1 worth" before 36.6.3, and the card's script data holds two 2s. This is unverified (§12). The reference line doesn't use Barrage.

**Halves rule (A and B only; C has none):**
- Gem size counts in halves, as Ring size does (8.5.4).
- **A Blood Gem gives your gem size rounded up**, Attack and Health separately. No remainder is kept on the unit.
- The gem-size counter shows what a gem gives now.
- Rounding up adds about 4% at R12 (1,103 exact against 1,144).
- Rejected alternative: per-unit pips, which add state and clutter, against note 09e.

---

## 5. Mechanic mapping

| BG mechanic | Bramble equivalent | Status |
|---|---|---|
| Blood Gem (0-gold +1/+1 spell) | `kind: spell`, `aim: unit` (friendly), effect `gem {count: 1}`. Played from hand it is a cast, so it fires `on_spell_cast` | Spell kind exists; `gem` is **new** |
| "Your Blood Gems give an extra +X/+Y this game" | Player stat `gem_size` (Attack, Health, in halves; starts 1/1), changed by `gem_size_add`. Not retroactive | **New**; Ring size is the display precedent |
| "This plays N Blood Gems on X" | `gem {count, target, permanent}` with existing selectors (self, all, other + tribe, random_other, `adjacent`). **Not a cast** (no `on_spell_cast`, as in BG). Writes a per-unit gem ledger | **New** effect; existing selectors |
| Gems during a fight | Fight-only unless `permanent: true` (Vineweaver); permanent in recruit (`buff` already has `duration`) | **New** flag |
| Choose One | Card field `modes: [effects, effects]`, tag `choose_one`, using Discover's `pending_choice`/`choose` flow. Trigger `on_choose_one_played` fires **after** the chosen mode resolves, never from `on_play` (so a When-played doubler doesn't repeat it, as Brann doesn't in BG) | **New** |
| Thorned Trailblazer | Rule query `choose_one_both`, per-turn count shown "(1 left!)", stored as the card's dial `both_per_turn`, **not** `uses_per_turn` | **New** |
| Rally / Battlecry / Deathrattle / End of Turn | `on_attack` / `on_play` / `on_death` / `end_of_turn` | Existing |
| Windfury (Bonker) | `repeat_attack` per 9.4.11: back to back, a new target each time, `on_attack` each time. Peck (several strikes on one target) is not the same | **New** |
| Divine Shield (Roogug) | Shield | Existing |
| Activate (Bandit 0, Geomant 2) | `activated` extended from heroes and spells to units: a legal action, UI, a gold cost, once a turn (a **loop guard**) | **New** for units |
| Discard (Bandit) | A cost step: pick a card in hand to remove | **New** |
| Random Choose One card (Tunneler) | `add_card {random: {tag: choose_one, tier_at_most: yours}}`, reusing Discover's filters. Pool: Miner, Foodie, Sly, Trapper, Brigand. Created, so it sells for 0 (4.3.3) | `add_card` exists; the filter is **new** |
| Random Quilboar (Trapper) | `add_card {random: {tribe: quilboar}}`, Created | As above |
| "+1 maximum Gold" | `rule {query: income, op: add, amount: 1}`: +1 gold every turn, like BG. This conflicts with the 4.1.4 ceiling reading (no effect before R8), so log it | Existing query |
| Free Refreshes (Sly) | `free_refresh` | Existing |
| Barrage | A player-scoped, stacking `on_refresh` listener + `shop` selector, reusing Stone Soup's shop-buff path. PlayerState rule handlers are the precedent for player scope | Trigger and selector exist; player scope is **new** |
| Felboar | `on_spell_cast` counter of 3 → the Oozes' Eat on a shop unit | Reuse Eat |
| Roogug | **New** trigger `on_gem_received`. Loop guard: a gem a Roogug plays can't trigger a Roogug in the same chain | **New** |
| Surveyor | Rule query `hand_gem_extra_casts` (+1, golden +2), plus a repeat in the hand-play path. Each extra cast is a cast (it fires `on_spell_cast`) | **New** |
| Confiscation's steal | The per-unit gem ledger + `steal_gems {from: adjacent}` | **New** |
| Geomant's overflow | When the hand (10, 7.1.1) is full, the rest go on the leftmost front-row unit (8.5.2); if the front row is empty, the leftmost back-row unit. The reverse of Acorn Spill | **New** |
| Quilboar tribe | Tribe `quilboar` (test-only). The Harvest Supper bonus applies | Existing `tribe_bonus` |

**Exemptions:**
- **Hero and spell scaling** (switched on in both presets) turns flat gains into a share of the recipient's stats. It touches only spells and hero powers, never unit-played effects. So the four qb_ spells get `scaling_exempt: true`. Otherwise the size axis becomes proportional, and the cards are no longer Quilboar.
- **Shy:** gems follow 12.1.7 as written, with no flag. A thanked Shy unit leaves the board, so there is no gold loop. The real interaction is free thanks feeding Silky's Ring size, which the splash audit reports.

**Positions on the 4-front / 3-back board:**
- "Neighbors", "adjacent", "left/right" → **beside** (the engine's `adjacent`: same row, no skipping gaps, 8.2.2). Never "next to": that would make Confiscation up to twice as strong.
- "Left-most" → the leftmost unit of a named row (8.5.2): the front row first.
- "All your minions" → each of your units. "A different friendly minion" → another random unit of yours.
- Attack order is reading order: F1–F4, then B1–B3, alternating sides (9.4.2). Back-row units can't be attacked while front units live (9.5.1). The model assumes 1.5 Rally attacks a fight to R8 and 2 after.

**Cross-tribe hazards the harness reports:**

| Card | What it does with gems |
|---|---|
| Cricket Busker ("After you cast a spell: get 1 gold. Once a turn.") | Harmless with rate limits on. **With `card_rate_limits=false` it becomes 1 gold per gem**, about 10–30 gold a turn. Under `reference_quilboar`, a loop guard keeps its refund from Created 0-gold spells to once a turn, kept with caps off |
| Pipistrelle Echo | Gems aimed at it also hit the units beside it: ×3 applications on hand gems |
| Moss Ooze (current text) | Echoes spell stats into its Belly, a double count. Pass 3 replaces this text, so the hazard holds only on current content |
| Felboar + Stone Soup or Barrage | Eats buffed shop units: a cross-tribe shop-buff stack |
| Prince Restored | Makes Confiscation or Barrage free |
| Click Beetle | Repeats Geomancer's gems and Champion's When-played step. It does not repeat Choose One |
| `scale_doubler` (End of Turn doubler) | Works as Drakkari: it doubles Gem Rat and Trench Fighter. Gem Day is not a doubling (amendment 11), so it repeats |

---

## 6. Dials by preset

| Dial | Uncut (test switch) | A (fallback) | **B (default)** | C (fidelity) |
|---|---|---|---|---|
| Gem-size steps (Gem Day, Foodie, Refiner, Champion) | full | ½, rounded up | ½, rounded up | full |
| Hogrider | 2 gems on all Quilboar, every card (37.0.2) | 1 gem on other Quilboar, every 2nd card | 1 gem on other Quilboar, every card | as B |
| Tunneler | every attack | once a fight | once a fight | once a fight |
| Refiner | every attack | every attack | every attack | every attack |
| Brigand | 3 gems; Barrage ×3 | 1; ×1 | 1; ×1 | 1; ×1 |
| Typical line, R6 / R9 / R12 / R15 | 54 / 222 / 6,195 / 23,945 | 54 / 167 / 824 / 2,230 | **54 / 167 / 1,144 / 3,363** | 54 / 203 / 1,942 / 6,123 |
| R12 against its target | 12.4× A | 1.65× A | 1.27× B (900) | 1.08× C (1,800) |

**Notes on the presets:**
- B and C get there by raising rates, not bodies, as the plan requires.
- B's and C's targets are written only at R12. R6 is shared, because bodies aren't raised.
- B equals A until R10: their only difference is Hogrider.
- A is not budgeted further. If it is ever played, re-budget first: at A, the gems-from-hand line catches Choose One by R15 (0.98×).
- "Uncut" means BG's card text on Bramble's economy and pool, not BG's economy. Created cards sell for 0, gold carries over, the shop odds are Bramble's, there are no Choose One Tavern spells, and there is no 37.0.2 tribe offer.

**Storage rule.**
- The overlay strips `once`, `limit` and `uses_per_turn` when `card_rate_limits=false`, and the checkpoint runs caps off. So **every rate cut here is a budget dial, and every BG once-a-turn limit is a loop guard.** Neither may be keyed under those three names.
- Hogrider's counter at A uses `every`. Check that `every` is not in `rate_limit_overlay`.

```json
"quilboar_ref": {
  "_note": "Budget dials, not caps: caps-off must not strip them. null = every attack.",
  "uncut": {"gem_size_step": 1.0, "gem_round": "none", "hogrider_every": 1, "hogrider_gems": 2, "hogrider_targets": "all_quilboar",
            "tunneler_per_fight": null, "refiner_per_fight": null, "brigand_gems": 3, "brigand_barrage_casts": 3,
            "trailblazer_both_per_turn": 1, "geomant_gems": 6, "bandit_gems": 3, "roogug_every": 1},
  "A": {"gem_size_step": 0.5, "gem_round": "up", "hogrider_every": 2, "hogrider_gems": 1, "hogrider_targets": "other_quilboar",
        "tunneler_per_fight": 1, "refiner_per_fight": null, "brigand_gems": 1, "brigand_barrage_casts": 1,
        "trailblazer_both_per_turn": 1, "geomant_gems": 6, "bandit_gems": 3, "roogug_every": 1},
  "B": {"gem_size_step": 0.5, "gem_round": "up", "hogrider_every": 1, "hogrider_gems": 1, "hogrider_targets": "other_quilboar",
        "tunneler_per_fight": 1, "refiner_per_fight": null, "brigand_gems": 1, "brigand_barrage_casts": 1,
        "trailblazer_both_per_turn": 1, "geomant_gems": 6, "bandit_gems": 3, "roogug_every": 1},
  "C": {"gem_size_step": 1.0, "gem_round": "none", "hogrider_every": 1, "hogrider_gems": 1, "hogrider_targets": "other_quilboar",
        "tunneler_per_fight": 1, "refiner_per_fight": null, "brigand_gems": 1, "brigand_barrage_casts": 1,
        "trailblazer_both_per_turn": 1, "geomant_gems": 6, "bandit_gems": 3, "roogug_every": 1}
},
"quilboar_ref_loop_guards": {
  "_note": "Always on under reference_quilboar, kept with caps off.",
  "unit_power_once_per_turn": true,
  "roogug_chain_guard": true,
  "surveyor_extra_casts_not_recursive": true,
  "busker_created_spell_refund_once_per_turn": true
}
```

**Each lever restored to BG text, one at a time, from B** (typical line, R12 / R15; B itself is 1,144 / 3,363):

| Lever | R12 / R15 |
|---|---|
| Size steps full (that is, C) | 1,942 / 6,123 |
| Hogrider at 37.0.2 text | 2,048 / 6,694 |
| Tunneler every attack | 1,661 / 5,503 |
| Brigand 3 gems | 1,336 / 4,265 |
| Hogrider every 2nd card (that is, A) | 824 / 2,230 |
| Refiner once a fight (the first spec) | 960 / 2,742 |

---

## 7. Deviations from Battlegrounds

**Chosen (budget):**
- **Hogrider:** 1 gem on other Quilboar, BG's text before 36.6.3. Golden doubles the gem (7.3.5). Because it never gems itself, Hogrider stays a small body (67/69 at R15 at B), unlike 37.0.2.
- **Tunneler once a fight.** This changes play: in BG it rewards surviving and attacking many times. Placement now puts it in the protected back row, so it surely gets its card. Restoring it is the largest single lever after Hogrider (+45% at R12).
- **Size steps ×½ at A and B.** Numbers only, rounded up per gem.
- **Brigand ÷3.** Numbers only.
- **Refiner keeps every attack.** It is back to a staple: its share is 0.26 / 0.36 at B, against BG's 0.30 / 0.31. The first spec cut it twice, to 0.11 / 0.17.

**Forced by our rules, or the least-bad mapping:**
- **Created cards sell for 0 (4.3.3).** In BG they sell for 1. Putting the gold back adds 14% at R12 at B. 4.3.8 would allow a card-text override; I keep our rule so the A/B runs on our economy.
- **Snare Trapper** uses the income query (+1 gold every turn, as in BG). The conflict with 4.1.4 is logged.
- **Felboar loses Demon:** we have no Demons.
- **Tunneler's pool is qb_ cards only.** BG's includes other tribes' Choose One cards.
- **BG's Choose One Tavern spells** (Alliance Flag at 1 gold, Forest's Bounty and others) are not ported, because the port adds no neutrals. The cycle costs about 6 gold a find instead. This is a known undercount of BG's count axis.
- **Gold carry-over (4.1.2)** shifts the timing of cycling and Power use.
- **Leftmost is per row (8.5.2), and neighbours are beside (8.2.2).**
- **The Harvest Supper bonus applies:** a small Bramble-only addition.
- **Activate's once a turn** is BG's own rule (keywords.md). Here it is a loop guard: without it, Bandit is infinite.

---

## 8. Engine support, in build order

Build on branch `ideation/reference-quilboar` (Sol). It merges into `ideation/main` only behind the flag, and never toward `main`. Each phase passes the gate and a fresh scope review.

**Phase 1: what the Choose One line needs. The first harness runs wait only on this.**
1. **Pool flag `reference_quilboar`, off by default, and tribe `quilboar`** (precedent: `pass3_content`).
   - Content lives in `content/reference/quilboar/`, with `rates.json` → `quilboar_ref`.
   - Gate check: no `qb_*` id is reachable with the flag off, and the flag never defaults to true.
2. **`gem_size` and `gem_size_add`:** the player stat in halves, with per-gem rounding up and the counter display (Ring size's path).
3. **`gem {count, target, permanent}`** in both phases (fight duration in combat), writing a per-unit **gem ledger** from day one. It is not a cast.
4. **The `qb_blood_gem` and `qb_gem_day` tokens** (0 gold), plus a per-card `scaling_exempt` flag, checked where `recruit_context.gd` and `combat_world.gd` apply `scale_hero_spell_stats`.
5. **Choose One:**
   - the `modes` field and mode choice on the `pending_choice`/`choose` flow;
   - the `choose_one` tag;
   - the `on_choose_one_played` trigger, after the mode resolves.
6. **Random `add_card` filter** `{random: {tag|tribe, tier_at_most}}`. Created.
7. **Rate dials read from `quilboar_ref`:** Hogrider's counter and targets, Tunneler per fight, size step, Brigand counts. Plus an overlay test showing that caps-off leaves them unchanged.
8. **Trailblazer:** the `choose_one_both` query, with `both_per_turn` as a card dial.
9. **Snare Trapper:** `rule {query: income}`. **Sly:** `free_refresh` (exists).
10. **Gem Confiscation:** `steal_gems {from: adjacent}` on the ledger. It is a token and a tier 4 shop spell.
11. **Bot brain `quilboar_choose_one`** (precedent: `bot_pass3.gd`):
    - Choose One mode picks;
    - the buy–play–sell–refresh cycle with one open slot;
    - hand-gem targeting;
    - Confiscations held, with the end steal;
    - Tunneler cards played and sold for 0.

    Without this, Quilboar looks weak for the wrong reason: cycling alone is worth ×1.6 at R15 at B.
12. **Known-answer tests:**
    - gem size is not retroactive;
    - Hogrider fires after the mode;
    - golden Hogrider gives 2 gems, not after every card;
    - caps-off keeps every dial;
    - Click Beetle doesn't repeat Choose One;
    - `scale_doubler` doubles Gem Rat.

**Phase 2: the rest of the set and the check line.**

13. **Unit Power** (`activated` on units: legal action, UI, gold cost), with once a turn as a loop guard, plus a **discard cost step**. This brings in Bandit and Geomant.
14. **Geomant's overflow** onto the leftmost front-row unit.
15. **`on_gem_received`** plus Roogug's chain guard.
16. **Surveyor:** `hand_gem_extra_casts` and the hand-play repeat. Extra casts fire `on_spell_cast`. They are not recursive.
17. **Barrage:** the player-scoped, stacking `on_refresh` listener + `shop` + flat gem stats. It is a token and a tier 4 shop spell. Also Brigand's Barrage mode.
18. **Felboar:** the `on_spell_cast` counter of 3 → Eat a shop unit.
19. **Vineweaver** with `permanent: true`; **Tusker, Camper, Roadboar** on `on_attack`.
20. **Optional `qb_balinda`** (T6 6/6: "Spells you aim at your units cast twice"). Default off; only for the gems-from-hand check.
21. **Loop guard:** Busker's refund from Created spells, once a turn under the flag.

**Phase 3:**

22. **`repeat_attack`** per 9.4.11, with the attack-pointer tests (11.2.3). Bonker enters the pool only after this lands.

**Already in place:** Shield, `on_refresh`, `on_spell_cast`, `free_refresh`, the `income` query, `scale_doubler`, `tribe_bonus`, `every`, the selector filters, and the Oozes' Eat.

---

## 9. Harness line policies

These use the loader format of `tools/sim/line_profiles.committed.json` on `ideation/harness` (`policy_version` 2, `CommittedLineBrain`).
- Check the meaning of `climb_schedule`: here it is the round each of T2–T6 is reached. Birds' tempo line uses `[4, 7, 9, 12, 14]`.
- The `brain_*` block holds proposals for the new brain, not loader fields.

```json
{
  "line_quilboar_engine": {
    "tribe": "Quilboar", "base_strategy": "quilboar_choose_one", "test_only": true, "pool_flag": "reference_quilboar",
    "priority": ["qb_turbo_hogrider", "qb_bramble_tunneler", "qb_gem_rat", "qb_sanguine_refiner", "qb_thorned_trailblazer",
                 "qb_trench_fighter", "qb_sanguine_champion", "qb_fearless_foodie", "qb_snare_trapper", "qb_sly_infiltrator",
                 "qb_crater_miner", "qb_veteran_brigand", "qb_roadboar", "qb_razorfen_geomancer", "qb_geomagus_roogug",
                 "qb_razorfen_vineweaver", "qb_prodigious_tusker", "qb_tusked_camper", "qb_mangled_bandit",
                 "qb_razorfen_flapper", "qb_hot_air_surveyor", "qb_victorious_geomant", "qb_bonker"],
    "climb_schedule": [2, 4, 6, 9, 11],
    "save_threshold": 0, "save_until": 0,
    "engine": true, "priority_weight": 14, "tribe_weight": 4, "policy_version": 2,
    "commit_round": 6,
    "engine_pieces": ["qb_turbo_hogrider", "qb_bramble_tunneler", "qb_gem_rat", "qb_sanguine_refiner"]
  },
  "line_quilboar_hand": {
    "tribe": "Quilboar", "base_strategy": "quilboar_gems_from_hand", "test_only": true, "pool_flag": "reference_quilboar",
    "priority": ["qb_hot_air_surveyor", "qb_geomagus_roogug", "qb_bramble_tunneler", "qb_victorious_geomant", "qb_sanguine_refiner",
                 "qb_mangled_bandit", "qb_trench_fighter", "qb_fearless_foodie", "qb_sly_infiltrator", "qb_snare_trapper",
                 "qb_crater_miner", "qb_razorfen_geomancer", "qb_roadboar"],
    "climb_schedule": [2, 4, 6, 9, 11],
    "save_threshold": 0, "save_until": 0,
    "engine": true, "priority_weight": 14, "tribe_weight": 4, "policy_version": 2,
    "commit_round": 7,
    "engine_pieces": ["qb_geomagus_roogug", "qb_hot_air_surveyor", "qb_bramble_tunneler", "qb_victorious_geomant"]
  },
  "brain_quilboar_choose_one": {
    "commit_rule": "Before R6 flex. From R6, or from the turn Gem Rat or Bramble Tunneler is on board, the tribe weight applies to every buy.",
    "flex_policy": {
      "until_round": 6,
      "pick": "best stats per gold in the shop, any tribe; tribe_weight 4 for qb_",
      "always_take_if_offered": ["qb_razorfen_geomancer", "qb_roadboar", "qb_crater_miner", "qb_gem_rat"],
      "max_flex_kept": 2,
      "sell_first": "flex units, as soon as a Quilboar needs the slot"
    },
    "max_copies": {"qb_bramble_tunneler": 3, "qb_gem_rat": 2, "qb_turbo_hogrider": 2, "qb_sanguine_refiner": 2, "default": 1,
                   "triple": "a third copy only when it makes a golden; Tunneler first"},
    "harvest_supper_rounds": [7, 9, 11],
    "save_rule": "Spend out every turn. The one save: on the turn before a scheduled tier-up, keep what next turn's discounted cost needs beyond next turn's income. Cycling and Confiscations spend only what that leaves.",
    "choose_one_policy": {
      "qb_gem_day": "the lower of Attack and Health",
      "qb_crater_miner": "2 gems before R9 and before Hogrider; Gem Day after",
      "qb_fearless_foodie": "4 gems before R9 and before Hogrider; size after",
      "qb_sly_infiltrator": "3 gems; the 2 refreshes instead while cycling, when the shop holds no Choose One unit",
      "qb_snare_trapper": "+1 gold each turn",
      "qb_veteran_brigand": "the gem mode",
      "trailblazer_both": "Foodie first, then Crater Miner, then Gem Day",
      "order": "with Hogrider on board: Gem Days first, then Tunneler cards, then cycled units"
    },
    "cycle_policy": {
      "from_round": 8, "min_tier": 3, "requires": "qb_turbo_hogrider or qb_bramble_tunneler on board",
      "rule": "keep one slot open; buy every Choose One unit the shop shows, play it, sell it; refresh to look while spare gold is 4 or more; at most 4 a turn; the last one played stays in the open slot and fights",
      "tunneler_cards": "play, then sell for 0 (Created)"
    },
    "gem_policy": {
      "hand_gems": "half on the carry, half over the other keepers; never on a unit sold this turn",
      "carry": "qb_gem_rat, else the biggest keeper",
      "gem_confiscation": "each turn, cast on the carry in F1 while the cycle slot F2 is empty (3 gems, no steal); with no spare gold, hold up to 5. Once, when 3 or fewer players are left: move the carry between the two biggest other units and cast one (the steal)."
    },
    "keeper_cap": {"before_engine": 7, "engine_out": 6},
    "sell_rank": ["flex", "qb_crater_miner", "qb_snare_trapper", "qb_fearless_foodie", "qb_sly_infiltrator", "qb_tusked_camper",
                  "qb_prodigious_tusker", "qb_razorfen_geomancer", "qb_roadboar", "qb_mangled_bandit", "qb_bonker",
                  "qb_razorfen_flapper", "qb_geomagus_roogug", "qb_trench_fighter", "qb_thorned_trailblazer", "qb_gem_rat",
                  "qb_razorfen_vineweaver", "qb_hot_air_surveyor", "qb_felboar", "qb_veteran_brigand", "qb_victorious_geomant",
                  "qb_sanguine_champion", "qb_sanguine_refiner", "qb_bramble_tunneler", "qb_turbo_hogrider"],
    "placement": "back row (protected, attacks each cycle): Bramble Tunneler B1, Sanguine Refiner B2, a second Tunneler B3. Front row: Gem Rat (the carry) F1, the cycle slot F2, Turbo Hogrider F3, Sanguine Champion F4 (its death raises gem size). Trapper, Trench Fighter and Trailblazer fill any slot left."
  },
  "brain_quilboar_gems_from_hand": {
    "note": "A check line, run to confirm BG's comp order (Choose One ahead). qb_balinda only in its Balinda arm.",
    "gem_policy": "every hand gem on Roogug while it lives; Bandit's Power each turn (discard a Blood Gem); Geomant's Power each turn when 2 gold is spare",
    "placement": "Roogug in the back row; the carry for Geomant's overflow at F1",
    "fallback_cut": "if this line's median reaches Choose One's at R12 or R15: Geomant 6 → 3 gems, then Roogug every 2nd gem"
  }
}
```

---

## 10. Paper curve

### 10.1 The lines at each preset

Board stats at R6 / R9 / R12 / R15. Cycling costs 6 gold a Choose One find.

| Preset | Typical | Strong | Low roll | Gems from hand | Hand ÷ typical (R12 / R15) | Strong ÷ low (R12) | Growth a round, R8–R14 (typical / low) |
|---|---|---|---|---|---|---|---|
| A | 54 / 167 / 824 / 2,230 | 72 / 198 / 1,055 / 3,375 | 60 / 150 / 308 / 1,009 | 58 / 197 / 621 / 2,196 | 0.75 / 0.98 | 3.4× | ×1.58 / ×1.36 |
| **B** | **54 / 167 / 1,144 / 3,363** | 72 / 198 / 1,698 / 5,814 | 60 / 150 / 308 / 1,443 | 58 / 197 / 621 / 2,196 | 0.54 / 0.65 | 5.5× | ×1.68 / ×1.43 |
| C | 54 / 203 / 1,942 / 6,123 | 72 / 241 / 2,992 / 10,888 | 60 / 159 / 423 / 2,508 | 58 / 214 / 845 / 3,624 | 0.44 / 0.59 | 7.1× | ×1.82 / ×1.56 |
| Uncut | 54 / 222 / 6,195 / 23,945 | 72 / 256 / 11,057 / 45,584 | 60 / 159 / 502 / 7,527 | 58 / 250 / 1,500 / 7,470 | 0.24 / 0.31 | 22× | ×2.28 / ×1.89 |

**How the lines differ:**
- **Typical:**
  - climbs to T2 at R2, T3 R4, T4 R6, T5 R9, T6 R11;
  - buys Gem Rat R5, Trench Fighter R6, Tunneler R7, Refiner R9, a second Tunneler R10, Hogrider R11, Champion R13, and makes a golden Tunneler R14.
- **Strong:** climbs on time (T5 at R8, T6 at R10), with two Rats, a golden Tunneler at R11 and a second Hogrider at R12.
- **Low roll:** climbs late (T6 at R12), with one Tunneler, no Refiner, and Hogrider only at R13.
- **Gems from hand:** Roogug R7, Surveyor R9 and R13, Geomant R11, Bandit, and no Hogrider.

**Reading:**
- **Gems from hand stays behind Choose One at B and C.** Its standing relative to Choose One improves about ×2 from uncut to B, because the cuts land on Hogrider. At A it catches up by R15. BG's 0.84 comes from final boards that mix lines; the model's pure line is weaker.
- **Spread.** Strong against low roll is the cost of one commit card. The low roll at B is 0.34× B's target.
- **Calibration.**
  - Uncut R12 is 0.82× BG's perfect-game winners and 2.4× BG's median, so it is a high-skill line.
  - Early it runs below BG's Quilboar winners: 123 against 229 at turn 8. Part of the R12 hump comes from the scripted Hogrider at R11.

### 10.2 Typical line at B, round by round

| Round | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|
| Board | 98 | 111 | 167 | 267 | 508 | 1,144 | 1,752 | 2,481 | 3,363 | 4,320 |
| Growth | ×1.81 | ×1.13 (saving for T5) | ×1.50 | ×1.60 | ×1.90 (Hogrider) | ×2.25 | ×1.53 | ×1.42 | ×1.36 | ×1.28 |

**Gem size, shown as what a gem gives:**

| Preset | R6 | R9 | R12 | R15 |
|---|---|---|---|---|
| B | 2/1 (1½/1) | 3/3 (3/2½) | 8/8 (8/7½) | 15/15 (15/14½) |
| C | 2/1 | 5/4 | 15/14 | 29/28 |

The line plays 3–6 Choose One cards a turn once the engine runs, and cycles 2–3 units a turn from R12.

**R10 to R12 is ×4.3 at B: two near-doublings in a row.** This is the first thing the harness checks (§11).

### 10.3 Boards and staples

**Typical board at B** (Attack/Health):

| Round | Units | Biggest unit's share |
|---|---|---|
| R6 | Geomancer 9/7, Gem Rat 5/5, Roadboar 3/5, flex 4/4, Crater Miner 3/3, Trench Fighter 3/3 | |
| R9 | Gem Rat 40/40, Trailblazer 8/9, Tunneler 7/10, Trench Fighter 7/7, Refiner 4/9, Foodie 3/5, Miner 2/2 | |
| R12 | Gem Rat 193/193, Tunneler 90/93, Refiner 87/92, Tunneler 86/89, Foodie 63/65, Hogrider 20/22, Trapper 12/12 | 0.34 |
| R15 | golden Tunneler 537/535, Gem Rat 458/453, Refiner 336/338, Champion 258/250, Hogrider 67/69, cycled Sly 19/20 | 0.32 |

**The board stays wide until the end steal.** One end-of-game Confiscation that steals from the two biggest units beside the carry raises its share to 0.65 at R12, or 0.79 at R15. That is an upper bound, and the reason the policy holds the steal for the last fights.

**Staples:** the share of the board lost when the card is replaced by a 4/4 body (R12 / R15):

| Card | Uncut | B | C |
|---|---|---|---|
| Hogrider | 0.78 / 0.73 | 0.55 / 0.66 | 0.59 / 0.68 |
| Tunneler | 0.65 / 0.72 | 0.38 / 0.50 | 0.36 / 0.50 |
| Gem Rat | 0.30 / 0.25 | 0.31 / 0.32 | 0.34 / 0.34 |
| Refiner | 0.30 / 0.31 | 0.26 / 0.36 | 0.32 / 0.39 |
| Foodie | 0.28 / 0.10 | 0.32 / 0.13 | 0.35 / 0.14 |
| Champion | 0.00 / 0.16 | 0.00 / 0.17 | 0.00 / 0.18 |

- Hogrider, Tunneler, Gem Rat and Refiner keep their order and their staple status.
- Trench Fighter reads about 0, because the model counts Confiscation as zero-sum. The model can't judge it.

### 10.4 Read the numbers as paper

**Model changes since the first spec** (all in `qm3.py`):
- Hogrider fires after the chosen mode, and each Hogrider skips only itself.
- Trapper gives +1 gold every turn.
- Tunneler gives exactly one card a fight from R7.
- Confiscations cost 1 gold, paid from spare gold only, and are held otherwise.
- A missed scripted buy waits a turn instead of vanishing. This was the cause of a strong-below-typical artefact.
- Halves round up per gem.
- Refiner triggers every attack.
- **Cycling costs 6 gold a find.** A T6 shop shows about 0.23 Choose One units (the five qb_ Choose One cards, tier odds 6.1.3a, 6 unit slots), so a find costs about 4.3 refreshes plus 3 to buy, less 1 for the sale. A T5 shop shows only about 0.13. The first spec assumed 4.5.
- The gems-from-hand line is added. Balinda and Surveyor are read as additive (3 casts); BG's behaviour is unverified.

**Sensitivity at B** (R12 / R15; B is 1,144 / 3,363):

| Change | R12 / R15 |
|---|---|
| Cycling at 4.5 gold | 1,231 / 3,821 |
| Cycling at 7.5 gold | 1,065 / 2,977 |
| No cycling | 944 / 2,071 |
| Rally 1.5 a fight late | 1,095 / 3,097 |
| Rally 2.5 a fight late | 1,261 / 3,722 |
| Created cards sell for 1 | 1,306 / 3,856 |
| Halves exact | 1,103 / 3,281 |

**Still left out:**
- Crater Miner's late Gem Day as one more Choose One card (an undercount);
- the Confiscation steal (reported only as a bound);
- Barrage, Felboar, Bonker, Tusker and Vineweaver (in no modelled line);
- BG's Choose One Tavern spells and the 37.0.2 tribe offer;
- combat, which is assumed: Rally counts as above, and Champion dying in half the fights.

**Arrivals are scripted, not shopped.** Expect the harness median below paper. The plan's 0.5–2× accounting check applies.

---

## 11. A/B test plan

### 11.1 What decides, and what is reported

The reference is a measuring stick, so this step judges only whether the stick is true. Under note 09i, two criteria decide; everything else is reported.

1. **Accounting.** At B and at C, the harness median of committed `line_quilboar_engine` seats lands within 0.5–2× of the paper typical line at R12 and at R15 (pre-start boards). If it misses, fix the bot or the port's accounting before reading any lesson.
2. **Fidelity.** In the uncut arm, the Quilboar median at R12 is **at least 4×** the median of every pass 3 engine line in the same lobbies (paper: 6.3–13.6×). This is proof that the port is faithful, that the cuts are what close the gap, and a direct test of the owner's prediction.

**Kept separate from checkpoint 1.**
- Reference lobbies are their own runs. Nothing from them enters checkpoint 1's two criteria, and they don't block it.
- The control is checkpoint 1's own step-5 lobbies, on paired seeds where the RNG allows (reference off).
- Adding a seventh tribe thins every shop, so that dilution is reported too.

**Extreme misses, triaged.**
- *Quilboar at B wins whatever the player chooses, or snowballs in most lobbies:* cut Hogrider to every 2nd card (A's dial) first.
- *Gems from hand reaches Choose One's median:* Geomant 3, then Roogug every 2nd gem.

### 11.2 Harness runs (H)

Config: pass 3 on, caps off, loop guards on (with `quilboar_ref_loop_guards`), hero and spell scaling on, the chosen damage table, and Ask for Kin off.

| Run | Seats | Arms, lobbies | Output |
|---|---|---|---|
| H1 Reference lobbies | 1 `line_quilboar_engine`, the 6 pass 3 engine lines, 1 Hard anchor | B 150, C 150, uncut 100, **uncut with gem size frozen** 100 | Median and p90 board by round; biggest unit's share; placement; the R8 leader's win rate; growth a round R8–R14; commit round; keystone found by R12 |
| H2 Field fights | 64-board field per round, R6–R16, drawn from H1, in both orientations | per arm | Win matrix, Quilboar against each line, at R9 / R12 / R15 |
| H3 Hand-line check | `line_quilboar_hand` in place of the engine seat | B 50, C 50, plus 50 B with `qb_balinda` | Hand median ÷ Choose One median at R12 / R15 |
| H4 Splash audit | H1 lobbies | B, both rate-limit settings | Gold, stats and frequency from Busker, Pipistrelle Echo, the End of Turn doubler, Click Beetle, Felboar with Stone Soup, and Shy thanks feeding Silky |
| H5 Buy-share | H1 and the control lobbies | B | For every T1–T3 card: the share of its buys made by lines that end on another tribe; own-tribe share of the board by round, R3–R10 |

### 11.3 Designed setups (D)

These come from the harness generator. Each reading threshold is set before the run, and every result is reported, not deciding.

| Setup | What | Reading threshold (reported) |
|---|---|---|
| D1 Flex against enabling | For each tribe and Quilboar: from the same R6 gold, a best-stats flex board against an on-tribe board, then each line's scripted arrivals to R9 / R12 | What early commitment buys and costs. Quilboar's own figure is the yardstick |
| D2 Pivot | One neutral R6 board pivoting into each tribe at R6, R8 or R10 | The slope of R12 / R15 board against pivot round |
| D3 The hump | Quilboar's R12 board with and without Hogrider, against each tribe's R12 typical board | Share of fights decided before they start (one board at least 1.5× the other: 94% wins, fundamentals 1.11) |
| D4 Wide against tall | At R12 and R15, each tribe's carry board against Quilboar's wide board at equal totals, with and without that tribe's answer. Then the same answers against Quilboar after its end steal | Whether our biggest-enemy and across answers lose value against a wide board |
| D5 Retroactive against future-only size | Equal size curves (gem size 3 / 8 / 15 against Rings 2 / 6 / 13), delivered both ways on the same bodies | R12 / R15 boards; growth a round |
| D6 Keystone | Each tribe's R12 board with and without its keystone (Quilboar: Hogrider) | Board loss; compare Quilboar's 0.55 |

### 11.4 Agent playtesters (P)

**Who:** three fresh reward-lens players. They are not checkpoint 1's testers, and they read no earlier report.

**When:** only after criterion 1 passes.

**The games:**
- Each plays three games against checkpoint 1's opponents, with one Quilboar line seat added.
- Game 1 is Quilboar at B and game 2 is Quilboar at C. The order is counterbalanced across players.
- Game 3 is the player's own pass 3 tribe at B, in a lobby with a Quilboar bot seat.
- Each player gets §2 as the "what BG players know" paragraph. They are testing our game, not learning Quilboar.

**Report** (under 250 words; every moment checked against the game log, board before and after):
- The commit round, what made them commit, and which early units they kept past it, and why.
- The biggest jump: its round, cause and size, and whether it felt like progress.
- The round the game felt decided, and whether anything they could afford would have changed it.
- **Game 3:** each fight against the Quilboar seat (round, result, what decided it), and at R9 / R12 / R15, whether their tribe felt stronger, weaker or just different.
- Which number they watched (gem size, Ring size, a carry), and whether it read without help (note 09e).
- **Verdict:** which felt more like progress, Quilboar or their tribe, and at which round.

### 11.5 The questions about our tribes, and what each would change

| # | Question | Measured by | If the answer is bad, the change to our tribes |
|---|---|---|---|
| 1 | **Early flex against enabling.** Do our T1–T3 units help other tribes' boards and still feed their own engine? Quilboar's gem makers bank a currency any unit can use, and BG winners are 35–45% Quilboar before turn 6 | H5; D1; P (commit round, units kept) | A tribe with no T1–T2 card that at least 20% of other lines buy gets one flexible early card that banks value usable by any unit (a gem-like token) |
| 2 | **Pivot timing and the commit signal.** What pair commits each tribe, and what does a late pivot cost? Quilboar: Rat or Tunneler + Hogrider, in at R6–R8, paid at R11 | H1 commit-round bins; D2; P | A steep pivot slope means the tribe needs an earlier commit signal, or a cheaper late entry |
| 3 | **Power jumps.** Does each tribe have a jump players feel, and is a ×2 round fun or decisive? Quilboar: ×1.90 then ×2.25 at B | H1 largest one-round jump; D3; P moments | No felt jump means a tribe's engine card needs a visible step |
| 4 | **Wide against tall.** Does a wide board (0.32–0.34) beat our carry boards, and do our answers lose value against it? | D4; H2; Bog and Hunters against gemmed attackers | Answers that only hit the biggest enemy need a wide-board mode |
| 5 | **Additive against proportional timing.** Do our tribes catch Quilboar where paper says (from about R13–R15), and do games last long enough? | H2 by round; H1 finishing round | If winners finish by R14, our proportional tribes need earlier power |
| 6 | **Global size: retroactive or future-only.** Which reads and plays better? | D5; P (which number they watched); H1 | Fairies' Ring size, or a future-only variant |
| 7 | **Coupling as the guardrail.** Is cutting a two-axis card gentler than cutting an axis? | H1 extra arms at B: Gem Day not counting as Choose One, against half Refiner steps; compare median, top 10% and the R8 leader's win rate | Apply the gentler one to Hayward, Stone Soup and Silky |
| 8 | **Is "obliterate" scale or axes?** | H1: uncut against uncut with gem size frozen (paper: 532 at R12, on our A curve). Optional D: an uncut two-axis BG tribe (Undead) | If size-frozen sits near our lines, the third axis is the gap. If a two-axis BG tribe also wins 5×, it is BG's scale |
| 9 | **Keystone dependence.** Quilboar strong against low roll is 5.5× at B from one card | H1 share of lines missing their keystone by R12, and their placement; D6 | Tribes that bust without their keystone need a second route |
| 10 | **Cross-tribe hazards on a gem board** | H4, both rate-limit settings | Loop guards or text fixes on the neutral, not on the reference |

### 11.6 Order

1. Build Phase 1 (§8, items 1–12), then the gate and scope review.
2. Run H1 B/C and uncut for **criteria 1 and 2**.
3. Run H2, H5 and D1–D6 in parallel. Then the playtests.
4. Build Phase 2, then H3 and H4.
5. Phase 3 (Bonker) is last and optional.

The orchestrator logs the results in DECISIONS as lessons, not as cuts to our tribes. Each lesson that changes a tribe goes through that tribe's own design step.

---

## 12. Open items

- **Blood Gem Barrage:** flat +2/+2 (my reading) or 2 gems at current size. Pin it from a source before Phase 2.
- **Hot-Air Surveyor + Balinda:** additive (3 casts) or multiplicative (4)? And does BG count Surveyor's extra casts as casts for spell counters? This matters for Felboar and Busker.
- **Snare Trapper against rulebook 4.1.4:** log the income-query reading as the reference's exception, or amend 4.1.4.
- **B's targets at R6, R9 and R15 aren't written.** This doc reads B and C only at R12.
- **The B values for Birds, Bog, Hunters and Hedgerow** come with wave 2. Redo §3.4 at B once they land.
- **`climb_schedule` semantics and `save_until: 0`:** check both against the loader.