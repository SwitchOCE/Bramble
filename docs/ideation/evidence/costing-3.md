# Costing pass 3: Bog folk, Hunters, Great beasts

Rough, for flagging big misses before these tribes go in. The three designs were written without the budget on purpose; this pass costs them now. Nothing here is a reason to cut a design. Every change below keeps the card's idea, numbers first, text second. Bog folk and Hunters are costed closely, since both critics recommend building them; Great beasts are costed lightly, for the file.

**How to read it.** Same format as `costing-1.md` and `costing-2.md`. Value = body SP + text SP, against V(t) = 5 / 7 / 8 / 10 / 12 / 14. `[g]` means the number rests on a guess. `[m]` means it was measured in the toy fight sim below. Band: ±15% plain, ±25% for recruit triggers, gold, scaling, slots. Row-bound bodies count Attack at 0.75 in the back. Prices leaned on most: c_combat(t) = 3.0 / 2.8 / 2.5 / 2.1 / 1.6 / 1.6 for permanent growth from a combat trigger; recurring gold 5 [g] / 6.5 / 5.1 / 4.2 / 4.1 / 2.2 SP per gold a turn (tier 1-2 figures are the model's price for what the caps don't allow); one-off gold at most 1 per trigger from tier 3.

**Which version is costed.** Where both critics propose the same change, the rewrite is costed (marked **B**). Where only one does, the original is costed (**O**) and the rewrite's price is given beside it (**P** = `critic-play.md`, **F** = `critic-feel.md`). Names follow the designs, with the agreed renames noted.

**The sim.** `lanesim.py`, `harness.py` and the `exp_*.py` scripts in `/tmp/claude-0/-home-user-Bramble/10abdd20-1e0c-5f97-8454-48d8169fd6ef/scratchpad/tribes3/costing-sim/`, not committed. Raw output is in the `out_*.txt` files there.
- **What it models:** rulebook attack order (9.4.2, 9.4.5, side with more units first), back-row protection (9.5.1), random targets, the simultaneous exchange, deaths after each exchange, and the 200-attack tie.
- **Card mechanics it models:** Mire patches with first claim in reading order, the lock, Prima Donna's spread, Bitter with its floor of 1 and its auras, Snap, Leapfrog, Gideon's attack-back and Bufo's halving (P). On the Hunter side: Quarry as P's mark at the bell, Takes, exposure, Pack joining, Brother Wolf, Sable, Ambush, Old Brock's grants, the Glutton, the Laird. For Great beasts: Charge, trample and Hide.
- **Method:** 3,000-4,000 paired fights a cell. Enemy strength is varied ±30%, and SP comes from a ladder of +2 and +4 stats on the same card in the same slot, as in pass 2. Cells (units, mean SP per unit) are turn 4 (4, 5), turn 6 (6, 7), turn 8 (7, 9), turn 10 (7, 13) and turn 12 (7, 17). "Tall" means one enemy unit holding half the board's SP, in F2 or B2, sized so a plain board wins half.
- **What it doesn't model:** gold, shops, summons other than the Peat King's, real text on enemy boards (they are plain), hero damage. Lane cards are placed against the real enemy board, so the sim **scouts perfectly**.
- **Its fights are short:** about 8 attacks at turn 6, against the budget's 1-1.5 attacks per front unit. So per-attack payoffs (Toll, Bitter, Gideon, Ambush) read low, and Takes and Mired deaths read about right.
- **Read tall numbers as direction.**

**The biggest assumption.** **Scouting accuracy, which I put at 0.65 [g]**: the share of fights in which the scouted enemy still stands where it stood last round. The sim places perfectly, so every conditional gold line here is discounted by it.
- It moves the gold on Bridge Toad most, and every Take card a little: aimed Takes are 0.70 a fight against 0.52 placed at random [m].
- **Mire and Quarry themselves don't depend on it.** Both measure about 0 aimed or not.
- Second assumption: a Take needs the Hunter **on the board at the death**, as the design says. P's wording ("by any hand") reads as if a dead Hunter's claim still counts. That raises every Take rate by 1.3-2.5× [m] (table below) and pushes most Take cards over.

---

## Pricing Mire (Bog folk)

**What it is.** At the bell the enemy across is locked onto the toad while the toad lives. Payoffs (Bitter, Snap, Gideon, Sal, the Peat Cutter, Tiddy Mun, the Peat King) read "Mired enemy". So the keyword is priced alone first, then the rates its payoffs run on.

**What the lock alone is worth** [m]:

| Case | Body | Turn 6 | Turn 8 |
|---|---|---|---|
| Mire alone, aimed across their top front Attack, even boards | 2/6 | +0.3 | -0.2 |
| Mire alone, random front slot, even | 2/6 | -0.1 | -0.1 |
| Mire alone, aimed, against a tall unit in F2 | 2/6 | -0.5 | +0.1 |
| Mire alone, against a tall unit in B2 | 2/6 | +0.5 | -0.1 |
| Mire alone, on a 1/4 at turn 4 (Bridge Toad) | 1/4 | -0.1 | |
| Mire alone, on a 6/10 at turn 12 (Peat King's body) | 6/10 | +1.1 at turn 12 | |

- **So Mire is Taunt: about 0 SP, plus the value of what it enables.** Choosing who does the hitting changes nothing on its own when your units are alike. The lock takes one swing their top unit would have made at someone else and points it at the toad. The toad then dies in its place.
- **The anti-tall claim doesn't hold for Mire alone.** Against a carry in F2, aimed Mire measured -0.5 to +0.1. That agrees with critic P: against a giant, Mire is a one-swing Taunt.
- **Where the tribe's anti-tall really sits:** Leapfrog Jack +4.4 against a tall B2 [m], the Prima Donna +4.0 [m] and Sable-style text, not the lock.
- **P's Bufo halving adds only +0.2 to +0.3** against a tall front unit [m]. The halved giant still kills a unit a swing at turn 12.

**What Mire feeds** [m], the rates the payoff cards run on:

| Rate | Value |
|---|---|
| Mired enemies that die in a fight, per front patch | **0.94-0.98** |
| Per back patch (B2 across their B2) | 0.42-0.66 |
| Two front mirers / three / Prima Donna in F2 (three patches) | 1.9 / 2.9 / 2.9 |
| Bitter 1 on a 2/6 wall, turn 6 | +1.0 SP |
| Bitter 2 on a 2/6 wall, turn 6 / 8 | +1.1-1.5 / +1.7-2.0 SP |
| Snap on a 3/2 (alone, with a mirer on board) | 0.0 SP; 0.21-0.31 Snap kills of a Mired enemy a fight |
| Leapfrog (back row, first, +2 Attack) on a 3/2 | +2.5 SP; +3.6 with Snap |

**Proposed prices.**
- **Mire: 0 SP** [m], like Taunt. Its cost is the slot.
- **Bitter N: about 0.6 × N + 0.3 SP at tiers 1-3** [m]. That is about 1.5 SP for Bitter 2 at tier 2. Scale it with A(t) above tier 3 [g].
- **"After a Mired enemy dies": price at 0.95 firings per front patch per fight** [m]. So a committed Bog board with 2-3 patches fires such text about 2-3 times a fight. That is why every per-death payoff below comes out over: they were written as if Mired deaths were rare. They are the tribe's most common event.
- **Snap: 0 SP**, plus 0.25 kills a fight for text that pays on a Snap kill.

## Bog folk

| Card | Ver. | T | Stats | Costing | Value / V | % | Verdict | Change that keeps the idea |
|---|---|---|---|---|---|---|---|---|
| Bridge Toad (was Toll Toad) | B | 1 | 1/4 | 5 + Mire -0.1 [m] + 1 gold × 0.65 aim [g] × 5 | 8.2 / 5 | +64 | **over**. A gold engine with its own Mire: any tribe can buy it | 1/3. "...is their highest-Attack unit **and it attacks this**" (0.55 [m] × 0.65 → 5.8, +16%; 6.3, +26% at a 0.85 aim). Still a scout test every round |
| Young Pretender | O | 1 | 3/2 | 5 + Snap 0 [m] + 0.21 Snap kills [m] × 5 | 6.1 / 5 | +21 | fine (gold band) | |
| Warty Nan | O | 1 | 1/4 | 5 + Bitter and aura 1.2 [m] | 6.2 / 5 | +24 | over, small | 1/3 (5.2, +4%) |
| Madame Bufo | O | 2 | 2/6 | 8 + Bitter 2 1.5 (turn 6) to 2.0 (turn 8) [m] | 9.5-10 / 7 | +36 to +43 | **over**: it's the body (8 SP) | 1/5 (7.5, +7%). **With P's halving** (+0.1 to +1.3 more [m]): 1/4 (about 7.4, +6%) |
| Leapfrog Jack (both: rename) | O | 2 | 3/2 | 5 + 3.6 [m] (leap 2.5, Snap 1.1) | 8.6 / 7 | +23 | over, small. +4.4 against a tall B2 [m]: the tribe's real carry answer | 3/1 (7.6, +9%) |
| The Peat Cutter | O | 2 | 2/3 | 5 + Mired deaths 0.94 a patch [m], about 1.4 gold a turn on a committed board (cap 2) × 6.5 | 14.1 / 7 | +101 | **over**, and with Bridge Toad it's a two-slot gold pair any tribe can run | Once a fight, 1/1 (2 + 0.9 × 6.5 = 7.9, +13%) |
| The Natterjack Chorus | O | 3 | 3/4 | 7 + Mire and Bitter 1 lent to two walls 1.1-1.6 [m] | 8.1-8.6 / 8 | +1 to +8 | fine | |
| Gideon, Basso Profundo | O | 3 | 3/7 | 10 + attack-back -0.1 to +0.6 [m] | 10.3 / 8 | +29 | over: the body (10 SP) | 2/6 (8.3, +4%) |
| Spitfire Sal | O | 3 | 2/4 | 6 + 4.8 (two mirers) to 5.2 (three) [m] × 0.85 for a committed board [g] | 10.2 / 8 | +28 | over | 1/3 (8.2, +3%). Keeps "the more you bog, the more she burns" |
| Jenny Greenteeth | O | 4 | 4/6 | 10 + -2 Attack and exposure 2.0 [m] | 12 / 10 | +20 | over, small | 3/6 (11, +10%). **P's rewrite** ("units beside attack it at once") is about 2 attacks × A(4) × 0.6 [g]: 15.8, +58%. If adopted: one unit beside, the one with most Attack, at 3/5 (about 11.4, +14%) |
| His Highness, Allegedly + The Prince Restored | O | 4 | 3/5, then 6/7 | 8 + 0.85 to finish [g] × (Prince 13 + 2 gold a turn 7.3 − 8). One-gold spells kiss for free | 18.5 / 10 | +85 | **over**. +2 gold a turn unconditional breaks the T4 cap. Best used by a Fairy spell board, which the design itself says. Golden 4 gold a turn | **Both critics remove the gold back.** **F's pair costs on budget:** spells give no stats and each is a kiss; the Prince's "first spell each turn costs 1 less" is worth 3.7. 8 + 0.85 × 8.7 − 3 kisses at 1 gold × 2.0 = **9.4, -6%**. **P's pair is mostly out of reach:** kisses come from Snap kills, 0.21-0.31 a fight [m], so 3 kisses take about 11 fights. That gives 12.7, +27%, with the Prince rarely seen. If P's trigger is wanted, kiss on any Mired death (1.9 a fight [m]) and keep F's Prince |
| Tiddy Mun | O | 5 | 4/8 | 12 + 2.5 firings [m] × about 4 Bog folk [g] × 2 SP × 1.6 = 32 | 44 / 12 | +270 | **over**, the set's biggest runaway: 20 SP of permanent growth a fight, three times the T5 combat cap (6.2) | **P's rewrite** (only the Bog folk it was locked onto grows) gives 20, +67%. Add **twice a fight** and **3/5**: 8 + 1.8 × 2 × 1.6 = **13.8, +15%** |
| The Prima Donna | O | 5 | 3/12 | 15 + F2: 3.5 [m]; B2: 1.4 [m]; against a tall B2: 4.0 [m] | 16.4-18.5 / 12 | +37 to +54 | **over**. The body alone is +25% | 2/8 (about 13, +8%). Take "Bitter once per enemy" (designer's lever, P adopts it): it measured no loss [m], so it's free insurance against the golden B2 case |
| The Peat King | O | 6 | 6/10 | 16 + Mire and Bog-Bodies 1.7 [m]. Bodies rise only 0.08 a fight on full boards [m]: few empty slots when Mired enemies die | 17.7 / 14 | +26 | over, small | 5/9 (15.7, +12%). **F's Peat-Man** (4/4, Bitter 2) measured the same on full boards [m]. Its worth on gappy boards, and the base-stat theft's, is unmeasured |

**Tribe economy after the changes.** Bridge Toad 0.36 gold a fight, the Peat Cutter 0.9, the Pretender 0.2 and F's Prince 1 off a spell. Together that is about 1.5 gold a turn for a committed board, near Birds' flock target (+3) at half the slots.
- **It pays win or lose,** as the design says: Mired enemies die in lost fights too (0.94 a patch across all fights [m]).
- **The export risk is the Bridge Toad and Peat Cutter pair:** both work with nothing else from the tribe. With the fixes it is 1.3 gold a turn for two cheap slots. Watch it on the bench.

---

## Pricing Quarry and the Take (Hunters)

**What it is.** This prices P's version: at the bell, the enemy across becomes the Hunter's quarry, a mark on the unit, and the Hunter attacks it when it legally can. A Take fires when the quarry dies. Both critics keep Quarry, and P's mark closes the refill farm the designer flagged, so it is the version to cost. The original slot rule gave Tod 2-3 Takes a fight across an Ooze or a summoner (not simmed: no summons on enemy boards).

**What aiming is worth** [m]:

| Case | Combat SP |
|---|---|
| Tod 2/1, Quarry aimed at a killable front enemy, turn 4 | +0.2 |
| Tod 2/1, Quarry, random front slot | 0.0 |
| Tod at turn 6 / Russet 3/2 / Toll-Bard 2/3 / Lutra 3/4 (aim anywhere) | -0.1 / +0.1 / 0.0 / -0.1 |
| Quarry for every unit on your side (the Laird's grant, no buff), turn 12 | +0.2 |
| Sable 2/3, +3 if the enemy across has more Attack, aimed | **+2.1** even; **+4.3** against a tall F2 |

- **So Quarry is also about 0 SP.** On boards of like units, picking the target doesn't win fights. Its value is the Take, and the conditional text that reads the quarry (Sable).
- **Can it kill a carry?** P's turn-12 read stands. Sable is the only Hunter whose aim pays against tall (+4.3), and Old Brock's exposure is the other (+7.1 against a tall B2, below).

**Take rates** [m], Takes a fight per Hunter:

| Hunter, slot | Hunter on the board at the death (design rule) | Claim kept after the Hunter dies (P's "by any hand" read) |
|---|---|---|
| Tod 2/1, front, aimed at a killable unit, turn 4 | **0.70** | 0.93 |
| Tod 2/1, random front, turn 4 | 0.52 | 0.84 |
| Tod 2/1, aimed, turn 6 | 0.38 | 0.96 |
| Russet 3/2, aimed, turn 6 | 0.57 | 0.97 |
| Sable 2/3, aimed at their top Attack, turn 6 | 0.74 | 0.98 |
| Lutra 3/4, B2 across their top back unit, Quarry anywhere | 0.71 (all back-row) | 0.74 |
| Three 4/4 Quarry Hunters on a turn-8 board | 1.43 a fight | 2.93 |
| Three 6/6 Hunters, turn 10 | 1.61 | 2.96 |
| The Laird: everything on your side has Quarry, turn 12 | 4.3 (6.1 with +2/+2) | 5.8 |

**Proposed prices.**
- **Quarry: 0 SP** [m].
- **Take text: price × Take rate.** Use 0.55 a fight for a front tier 1-2 Hunter over its life (0.70 at turn 4, falling to 0.38 by turn 6), 0.6 for tier 3+, and 0.7 for a back Hunter across a back unit. A board with three Hunters makes about 1.5 Takes a fight.
- **Settle the wording before pricing further.** If a dead Hunter's mark still pays, multiply the rates by 1.3-2.5.

**Pack and Ambush** [m]:
- **Pack:** +0.9 SP on a 2/2 (a joiner hits without taking the hit back), +2.0 to +2.8 on a 4/5. **So Pack ≈ 0.5 × the unit's Attack.** Wick's +1 Attack a join adds 0.6-1.2. A killing pack attack happens 0.8 times a fight with one Pack unit beside a leader.
- **Ambush:** 0.0 to +0.2 SP on a 3/3, with 0.35-0.58 ambushes a fight. It's an ordinary trade at a target you didn't choose. **Ambush ≈ 0.** P's Pounce reaches the back row but also trades, about +0.5 [g].
- **Brother Wolf as written** (joins both neighbours, never takes the hit back): about 1.1 × Attack. **With P's counter-hit on every join:** below a plain body, -2.7 / -1.1 [m], because he never leads and takes two hits a cycle.

## Hunters

| Card | Ver. | T | Stats | Costing | Value / V | % | Verdict | Change that keeps the idea |
|---|---|---|---|---|---|---|---|---|
| Tod Scrapling (F: rename Little Nip) | O | 1 | 2/1 | 3 + Quarry 0.2 [m] + 0.55 Takes [m] × 1 gold × 5 | 6.0 / 5 | +19 | fine. The only Hunter gold that ports to any tribe; at 0.55 a turn that's fine | Golden 2 gold a Take is at the T1 trigger cap: fine. Over (7.9, +57%) if dead Hunters keep their claim |
| Young Brock | B: Bait removed; P's text | 1 | 1/4 | 5 + neighbours share his quarry and +1 Attack this fight 1.8 [m] | 6.8 / 5 | +36 | over | 1/3 (5.8, +16%). F's text ("after the enemy across attacks, neighbours +1 Attack") is about 1.0 [g]: 1/3 is 5.0 |
| Wick | O | 1 | 2/2 | 4 + Pack and growth 1.5 (turn 4) to 2.1 (turn 6) [m] | 5.5-6.1 / 5 | +10 to +22 | fine, edge late | |
| Sable | O | 2 | 2/3 | 5 + 2.1 even, 4.3 tall [m]; 2/3 even, 1/3 tall | 7.8 / 7 | +12 | fine | F's hook fix |
| The Toll-Bard | B: plain text; P's Quarry fold | 2 | 2/3 | 5 + quarry attacks while he lives: 0.3 a fight [m, short fights], 0.6 likely in real fights [g] × 6.5 | 7.0-8.9 / 7 | 0 to +27 | fine to edge; sim with longer fights. **Golden: up to 6 gold a fight** | Golden: "2 gold, up to 3 gold a fight" |
| Mistress Russet | P (≤ your tier, no Created copy) | 2 | 3/2 | 5 + 0.1 + 0.57 Takes [m] × (1 gold off × 0.5 bought [g] × 6.5 + selection 1.2 + denial 0.3 [g]) | 7.8 / 7 | +11 | fine. **The original** steals higher-tier cards below price, about +1.5 [g]: 9.3, +33% | Take P's tier limit |
| Brother Wolf | O (= F); P costed | 3 | 4/5 | 9 + 4.4 (turn 6) / 3.3 (turn 8) [m] | 12.3-13.4 / 8 | +54 to +68 | **over**. **P's counter-hit rewrite is under:** 6.3-7.9 (-21 to -1%) [m] | Keep the text; 3/4 (7 + 2.3-2.4 [m] = 9.4, +17%), edge. 2/4 measured 7.9 (-1%) if the bench says he's still strong |
| The Lodger | O (Ambush); P's Pounce [g] | 3 | 3/3 | 6 + Ambush 0.0-0.2 [m] | 6.2 / 8 | -23 | **under** | 4/4 (8.2, +2%), either keyword |
| Low-Water Jack (P: rename Old Lutra) | P | 3 | 3/4 | 7 + Quarry anywhere -0.1 [m] + 0.71 back Takes [m] × 2 gold as 1.4 a turn × 5.1 | 14.2 / 8 | +78 | **over**. 2 gold in one trigger breaks the T3 cap of 1. Golden 4 | 1 gold; 2/4 (6 + 3.6 = 9.6, +20%) |
| Madame Ermeline | O (= F) | 4 | 3/6 | 9 + 1.43 Takes [m] × use-or-lose 0.4 [g] × 4.2 | 11.4 / 10 | +14 | fine. At tier 6, gold up to 3 a turn breaks the T6 cap of 2 | "...up to 2 gold at tier 6" |
| Old Brock | P (quarry share, exposed, Pounce, +1 Attack) | 4 | 3/7 | 10 + 3.2 even, 7.1 against a tall B2 [m] (2/3 and 1/3) + Pounce 0.5 [g] | 15.0 / 10 | +50 | **over**. Without Pounce and exposure (Ambush to neighbours and +1 Attack, close to F's text without the dig) it measured 2.3: 12.3, +23% | 2/5 (about 11, +10%) [g: text on the smaller body]. F's "dig out" is not costed |
| The Mountain Glutton | O | 5 | 4/6 | 10 + 4.8 [m] (1.6 Takes a fight) | 14.8 / 12 | +23 | over, small | 4/5 (about 13.8, +15%). With the Laird, 4-6 Takes make it +8/+8 to +12/+12 for one fight: fine, it doesn't carry over |
| Grizel | O | 5 | 5/6 | 11 + in fight 0 [m] + permanent: 2.4 joined units in a killing attack a fight [m] × 2 SP × 1.6 = 7.7 | 18.7 / 12 | +56 | **over**. The tribe's one lasting engine, spread to cheap joiners | Designer's lever: **Attack only**, still spread (11 + 3.9 = 14.9, +24%). Leader only measured 3.5, +21% |
| The Laird of the Sett | B: your side only; F's numbers | 6 | 5/9 | 14 + Quarry for all 0.2 [m] + +2/+2 to units with an enemy across 31 [m] | 45 / 14 | +220 | **over**. +1/+1 measured 17 [m] (31, +120%). P's text (+1/+1 to Hunters per quarry fainting, this fight) is about 15 [g]: 29, +107% | "**Your Hunters** with an enemy across gain +1/+1", 3/5 (8 + about 8 [g] = 16, +14%). Or 4/6 at about +29%, logged over like Cut-and-Come-Again: tier 6 is hollow |

**Tribe economy after the changes.** Tod 0.55 gold a turn, the Toll-Bard 0.3-0.6, Lutra 0.7, Ermeline about 0.6 a turn of upgrade, Russet's card. That is modest and **tracks winning**, as the design says: Take rates fall from 0.70 at turn 4 to 0.38 by turn 6 as boards widen [m].
- **The Toll-Bard is the one source that pays when behind.** Both critics want it in the core set, and its price supports that.
- **Exportable:** only Tod, and he's within band.

---

## Great beasts (light pass, for the file)

**Signature prices** [m]:
- **Charge:** +0.1 on a 2/2, +0.5 on a 5/5, +0.4 against a tall B2.
- **Trample:** +0.5 on a 3/6 that tramples every attack.
- **Hide:** 0.0 on a 4/6 with Hide 5 and a 6/10 with Hide 8. Even boards rarely hit above N. Hide is an anti-tall tool, worth about the excess of the biggest hit it meets [g].

So the tribe's keywords are near free on even boards, and its value is in the payoff text, most of which is over. Most rows are [g].

| Card | T | Stats | Costing | Value / V | % | Verdict | Change |
|---|---|---|---|---|---|---|---|
| Truffle | 1 | 2/2 | 4 + Charge 0.1 [m] + 1 gold × 0.4 empty lane early [g] × 5 | 6.1 / 5 | +22 | fine early, blank late. The critics' rewrite (gap or target died, about 0.55 [g]): 6.9, +38% | With the rewrite, 2/1 |
| The Yearling | 1 | 2/1 | 3 + 0.1 + Trophy about 1.2 gold at sale [g] | 5.1 / 5 | +2 | fine | |
| Ibex Kid | 1 | 1/2 | 3 + 2 SP a Room: 2-3 Room early, 0 on full boards [g] | 7-9 early, 3 late / 5 | +40 to +80 early | over early | +1 Attack a Room (about 5.5 early). F's column version reads enemy gaps instead: similar [g] |
| Old Grazer | 2 | 2/5 | 7 + Hide 0 [m] + 1 gold × 0.5 [g] × 6.5 | 10.3 / 7 | +47 | **over**, and it pays for not playing (owner's "Fast") | F's sell rewrite, 1/4 (8.9, +27%); P's capped-hit rewrite, 1/4 (7.6, +9%) |
| The Roaring Hart | 2 | 3/4 | 7 + Rut: 5 damage across at the bell × 1.15 less 2.5 back [g] | 10.5 / 7 | +50 | over | 2/3 (about 8, +14%) |
| Mother Mudwallow | 2 | 2/3 | 5 + two 1/1 Charge × 0.8 | 8.2 / 7 | +17 | over, small | 2/2 (7.2, +3%) |
| Honeypaw | 3 | 4/6 | 10 + Hide 0 [m] + 0.5 kills × 1 gold × 5.1 [g] | 12.6 / 8 | +57 | over | 3/4, once a fight (9.6, +20%) |
| Old Steinbock | 3 | 3/5 | 8 + 0.6 lived [g] × (swap 0.5 + 4 damage × 0.85) | 10.4 / 8 | +30 | over | 2/4 (8.4, +5%) |
| The Bog Elk (P: rename Alder Elk) | 3 | 3/6 | 9 + trample 0.5 [m] + 4 SP a Room: 0 full, about 8 in a Room build [g] | 9.5-17.5 / 8 | +19 to +119 | over in its build. The board pays for the gaps (4.5-6 SP each, pass 2 [m]) | +1/+1 a Room (9.5-13.5) |
| Mother Wisent | 4 | 3/8 | 11 + Hunker 3 [g] + Hide 5 to neighbours 0 even [m] | 14 / 10 | +40 | over | 2/6 (11, +10%); the critics' Hide-for-Hunker swap is about the same |
| Old Tusker | 4 | 5/5 | 10 + 0.5 [m] + +2 Attack to units yet to attack per charge: 1 charger about 6, 4 chargers about 18 [g] | 16.5-28.5 / 10 | +65 to +185 | **over**, quadratic in chargers | "+1 Attack, after your first charge each fight", 4/4 (about 11.5, +15%) |
| Big Ursula | 5 | 6/10 | B (forced attack removed): 16 + Hide 0 even [m] + return: 1/3 tall × 0.4 hit [g] × 25 [g] | 19.3 / 12 | +61 | over | 4/6 (13.3, +11%) |
| The Bison Elders | 5 | 5/9 | 14 + Hunker 3 + 3 × 3 charges × 0.85 + no-split 1.5 [g] | 26 / 12 | +120 | **over** | Critics' Hide 6, "+2", 2/5 (about 13.6, +13%) |
| The Last Aurochs | 6 | 9/9 | 18 + 4 front × 3 Attack × 0.9 + Charge, trample and Trodden about 2 [g] | 31 / 14 | +120 | **over** | 6/6, "+2 Attack to your front-row Great beasts" (about 18, +31%, logged over: tier 6 is hollow), or 5/5 (16, +16%) |

---

## Loops and runaways

**Nothing goes infinite.**
- Bitter's floor of 1 and the 200-attack cap end Mire mirrors (not measured).
- Ambush, Pounce and attack-back are each once a cycle or never chain.
- Kiss stops at 3.
- Poach needs a Take per card.

The risks are per fight and per turn:

| Line | Arithmetic | Result |
|---|---|---|
| **Tiddy Mun as written** | 2.5 Mired deaths [m] × 4 Bog folk × +1/+1 = 20 SP of permanent growth a fight | **Three times the T5 combat cap.** Fixed by P's rewrite plus twice a fight |
| **Grizel with Brother Wolf** | 2.4 joined units a killing attack [m] × +1/+1 = 4.8 SP a fight, permanent, on a Pact board | Over. Fixed by Attack only (2.4 a fight) |
| Lane Takes on refills (original Quarry) | Tod across a Belly Ooze or a summoner: 2-3 Takes a fight at tier 1 | **Closed by P's mark on the unit.** Adopt it |
| Bridge Toad + Peat Cutter, any tribe | 0.65 + 1.4 gold a turn as written, from two cheap slots | The tribe's best gold travels. After the fixes, 1.3 a turn |
| The Prince Restored (original) | +2 gold a turn, golden 4, reached with three 1-gold spells at no net gold | Flat income, best for Fairies' spell boards. F's Prince fixes it |
| Golden Toll-Bard | 2 gold × 3 = 6 gold a fight; two golden ones 12 | Cap golden at 3 gold a fight |
| Golden gold past the caps | Lutra 4 (T3 cap 1), Peat Cutter 2 × 2, Bridge Toad 2, Tod 2 (T1 cap 2: fine) | The bench should check goldens, as pass 2 asked |
| The Laird with the Glutton | 4-6 Takes: the Glutton +8/+8 to +12/+12 this fight | Combat only, fine |
| Old Tusker with four chargers | +2 Attack × (6+5+4+3) units yet to attack | Quadratic. Fixed by once a fight |

## Rule and wording flags

- **Take after the Hunter dies.** P's "Take: when this unit's quarry faints, by any hand" can be read as surviving the Hunter's death. The design says the Hunter must be on the board. State it: the gap is 1.3-2.5× on every Take rate [m].
- **Brother Wolf "never leads while a unit beside it lives":** a row of only Brother Wolves, or two side by side with nobody else, never attacks (the sim had to stall them). Add: "if no unit beside it can lead, it leads".
- **The Peat King's bodies** need an empty slot when a Mired enemy dies. On full boards that is 0.08 a fight [m], so the card is mostly a 6/10 with Mire. If the Bog-Body is the point, let it take the slot of the friendly unit that died most recently, or say "if you have room" on the card.
- **Jenny's exposure** belongs to Hunters under P's lobby ruling. If it moves to Old Brock, Old Brock carries its price (+3.2 to +7.1 [m]).
- **Bridge Toad "ties count"** (P) is right: without it, two equal top units make the gold a coin flip.
- **The Peat Cutter and Tiddy Mun** count enemies standing on a waiting patch too: a summon into an empty bogged slot is Mired. That's intended, but it adds firings against Oozes and Hedgerow.
- **Ermeline and other discounts:** state the order with A Leg Up, Jill's drop and the March Hare, and a floor of 0 on the upgrade.
- **Mire's measured value is 0.** So the design's line "the tribe a single huge unit hates" rests on Leapfrog, the Prima Donna and Bufo's halving, not on the lock. The intro copy fix P proposes is the honest one.

## Can't price without the bench

| Cards | Measure |
|---|---|
| Every lane card | Scouting accuracy: share of fights in which last round's enemy slot still holds the same unit, with bots that hold carries still (both critics' first ask). 0.65 is the guess everything conditional rests on |
| Toll-Bard, Gideon, Bitter, Ambush | Attacks per unit per fight in the real engine. The toy's fights are short (about 8 attacks at turn 6), so these read low |
| Peat Cutter, Tiddy Mun, Peat King | Mired deaths a fight by build and turn, against 0.95 a front patch [m]; empty slots when they happen |
| Takes | Takes a fight by build, under the chosen death rule |
| His Highness | Turns to the third kiss, under whichever trigger is chosen; who buys him (Bog or Fairy boards) |
| Grizel, Brother Wolf | Joined kills a fight on Pact boards; permanent SP gained by turn |
| Laird, Glutton | Lanes filled at the bell by turn; Laird mirrors (both sides with lanes) for fight length and win-rate swing |
| Bridge Toad + Peat Cutter | Gold a turn on non-Bog boards that buy them |
| Great beasts, Room | Room held by turn in a Room build, and its gap cost |

**Note on the slice's tuning.** Since the slice moved to 40 Health with a damage cap, and the median seat now goes out at round 14, recurring gold and permanent growth run a couple of turns longer than the budget's turn-12 break-even assumes. If anything, the gold and growth lines here are slightly under-priced. The balance step also raised tier 4-6 bodies to about V(t) to V(t)+2, so a late card 1-2 SP over V(t) sits with the slice's current units.
