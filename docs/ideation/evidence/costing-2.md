# Costing pass 2: Oozes and Birds

Rough, for flagging big misses before these tribes go in. Costed against the units, not today's spells: another worker is lowering spell rates, raising high-tier value and capping Dozey and Hex. Nothing here is a reason to cut a design. Every change below keeps the card's idea.

**How to read it.** Same format as `costing-1.md`. Value = body SP + text SP, against V(t) = 5 / 7 / 8 / 10 / 12 / 14. `[g]` means the number rests on a guess. `[m]` means it was measured in a toy fight sim. Band: ±15% plain, ±25% for recruit triggers, gold, scaling, slots. Row-bound bodies count Attack at 0.75 in the back. Prices leaned on most: c(t) = 3.9 / 3.7 / 3.5 / 3.1 / 2.6 / 2.6, recurring gold 5 [g] / 6.5 / 5.1 / 4.2 / 4.1 / 2.2 per gold a turn (the tier 1-2 figures are the model's prices for what the caps don't allow).

**The sim.** `belly_sim.py` and `reach.py`, in the session scratchpad, not committed: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/`. Rulebook attack order (9.4.5) and summon placement (8.4), plain bodies, 4,000 paired fights a cell, enemy strength varied ±30%, turning win-rate change into SP with a ladder of added stats on the same board. "Tall" means an enemy with one big unit in B2 and weak others, sized so an even board wins half. It is a toy: no gold, no real card text but what's listed, and the tall boards are close to all-or-nothing, so read tall numbers as direction.

**The biggest assumption.** I price tall-counters at **1 tall opponent in 3** [g], with a 50% chance the aim lands. Pudding, Jack Daw and Whistlers are worth little on an even board and enormous against a carry. If the caps make tall rarer, these cards fall toward blank, so re-cost them after the cap lands, before nerfing further.

---

## Pricing Belly

**What it is.** A body that adds no stats to the board now, comes out at full strength when the Ooze dies, and needs its own unit bought. The unit is paid for in gold, so the card pays only for the **capacity**.

**What a body inside is worth** [m]:

| Board | Inside | Front Ooze | B2 Ooze | Worth per SP inside | Same unit on the board (gap cost) |
|---|---|---|---|---|---|
| Turn 3-4, 3 units | 5 SP | +2.8 | +2.9 | 0.56 | -4.5 front, -2.3 back |
| Turn 6, 6 units | 7 SP | +3.1 | +3.6 | 0.45-0.5 | -4.8, -2.2 |
| Turn 8 | 9 SP | +2.8 | +3.1 | 0.3 | -5.3, -2.7 |
| Turn 10 | 13 SP | +2.8 | +3.3 | 0.2-0.25 | -5.5, -3.0 |
| Turn 12 | 17 SP | +5.2 | +5.4 | 0.3 | -6.4, -4.5 |
| Turn 6, against tall | 7 SP | +6.2 | +5.3 | 0.9 | |
| Turn 10, against tall | 13 SP | +13.7 | +12.1 | 1.0 | |
| Turn 12, against tall | 17 SP | +20.6 | +18.1 | 1.2 | |

- **So: about 0.35 × its SP on an even board, about 1.1 × against tall.** The owner's "a tribe tall hates" is real: one unit-sized body inside swings a tall fight by about 33 points of win rate.
- **A 5 SP filler late is poor.** +1.7 to +2.6 SP for 3 gold on even boards, under 1 SP a gold, against a late sink of 2.0. Belly is not a cheap way to buy stats. All seven slots stuffed with 5 SP units is +11 to +14 SP for 21 gold.
- **Two claims in `oozes.md` don't hold.** "A Belly 2 on a full board is really a Belly 1": the second body adds about 0.7 of the first, since gaps open as units die. "A back-row Belly usually does nothing": B2 measures the same as the front on even boards, because close fights reach it. Back-row "storage" is also a real fighter.

**Proposed price (new line, about 0.2 × V(t))** [judgement on m]. Expected body value, 0.63 × the mean unit at the tier's turn (2/3 even, 1/3 tall), less the filler's net cost of 2 gold at the 2.0 sink, plus the 1 SP E23 gives for a slot saved.

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Belly 1 | 1.0 | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 |
| Belly 2 | × 1.7 | | | | | |
| Belly 3 | × 2.0 | | | | | |

- Text that feeds or pays for what's inside is priced on top. Stats given to a unit inside count at 0.5 [g] between the even and tall rates.
- ±25% band, as a slot effect (T14).
- **It moves with two numbers.** With no tall boards, capacity falls to about 1 SP flat at every tier. If the spell work drops the late sink, the filler's gold costs less and the price rises a little.
- **Nesting breaks the cap.** An Ooze inside an Ooze makes bodies per slot limited only by gold. Propose an Ooze inside an Ooze has its own Belly sealed.
- **Damage.** Insides don't count for hero damage. That's a real cost, left unpriced because the bench can measure it.

## Pricing Fly South

**What it is.** A trip takes P turns: play and fight, sell, away, home. P = 3 by default, 4 for a 3-turn trip. So it isn't one line but a repeating Battlecry and a repeating 1 gold, paid for with absence.

**Proposed price:**

> **Fly South = (gold per trip ÷ P) × recurring gold price R(t) + (stats per trip × 0.9 ÷ P) × c(t) − 0.27 × body SP**

- **Gold per trip** is the sale, 1 gold, plus any landing gold. **R(t)** per gold a turn is 5 / 6.5 / 5.1 / 4.2 / 4.1 / 2.2.
- **Stats ÷ P** must sit under the tier's growth cap (2.2), as any scaling does.
- **−0.27 × body** is absence: away 2 fights in 3 × a 40% chance nothing replaces it [g]. It checks against the gap sim: an empty front slot costs 4.5-6.4 SP [m], so × 2/3 × 0.4 is about 1.3 SP, the size this gives on tier 1-3 bodies. Once the board is full and gold is spare, a second body fills the Nest, so this cost mostly disappears late. **The tempo price is an early-game price.**
- **The first play** of a Battlecry is charged once in full, as usual.
- **The keyword alone is about free:** +0.35 / +0.3 / -0.5 / -1.3 / -1.8 / -3.1 SP on a plain V(t) body. All the power is in what repeats, so that's where to charge.

**A hard rule to add: the trip floor.** "No bird comes home sooner than the turn after it left." Mrs Dunnock has it. **Mrs Stork doesn't,** and that is the mechanic's real hole:

- Rule 2 stops a bird leaving twice in a turn, so there's no within-turn loop. But nothing stops: sell at the start of the turn, spend 6, home now, play, fight. The bird is on the board for **every** fight, and pays every turn. P = 1 and the whole tempo price is gone.
- Plain Stork, 4 Swallows, a normal 12-17 gold turn: 2 birds home, +4 gold a turn. Golden Stork, 12 gold: 4 home, **+8 gold a turn**. The tier 4 cap is 1, tier 6 is 2.
- Old Tern with Stork is a Discover **every turn** for 6 gold you were spending anyway. `birds.md` lists the risk as a Discover every 2 turns.
- Golden Stork with golden Swallows is r = 1.0 per firing (G2 limit 0.5), though the number of birds bounds it.

With the floor, P is never below 2 and the formula holds at P = 2.

**Flock check, beyond the per-card price.** Slots are what's scarce, and a flier uses a third of one, so a slot of rotating Swallows yields up to 2 gold a turn. Per card that's 0.57 gold a turn, within reason. 4 Swallows is 2.3, or 3.4 with a Dunnock serving two of them. The bench should record flock income against about +3 gold a turn.

**Reach to tier 6** (`reach.py`, most units bought with T6 on turn 6 / 7 / 8. Base 0 / 2 / 5 matches pass 1; econ-heavy 0 / 4 / 9):

| Line | T6 turn 6 | Turn 7 | Turn 8 |
|---|---|---|---|
| One Nell | 0 | 3 | 7 |
| Two Nells | 1 | 5 | 9 |
| Two Swallows staggered | 1 | 5 | 9 |
| Pie as written, 3 gold from turn 5 | 0 | 5 | 9 |
| Nell after the change | none | 3 | 7 |

Each alone sits at or just above econ-heavy, so no single card breaks the clock. Playtest A found economy too weak, so don't push these far below their bands before the bench reads them. Combined lines need the bench.

---

## Oozes

| Card | T | Stats | Costing | Value / V | % | Verdict | Change that keeps the idea |
|---|---|---|---|---|---|---|---|
| Little Dollop | 1 | 2/2 | 4 + Belly 1 + 1 gold × 2.4 × 0.7 (you'd often rather play it) | 6.7 / 5 | +34 | over, small | 1/2 (5.7, +14%) |
| Wee Wobbly | 1 | 1/4 | 5 + Drips 1.2 [m] | 6.2 / 5 | +24 nominal | fine. A 1/4 fights well under its nominal 5 SP [m] | |
| Mrs Posset | 1 | 2/1 | 3 + 3 damage 2.7 [m] + Belly 1 | 6.7 / 5 | +34 nominal, +12 measured | fine. 2/1 bodies also fight under nominal | |
| Dishwater Nell | 2 | 2/3 | 5 + +1 gold a turn 6.5 (cap 0 at T2) + better shop 1 [g] | 12.5 / 7 | +79 | **over**; travels to any tribe (owner's 02h warning) | 1/2. Gold only when the eaten unit is 2+ tiers below yours, and only the first Nell pays (8.1, +16%). Still improves the shop every turn |
| Aunt Aspic | 2 | 1/4 | 4.75 + s 4 nominal × 0.5 inside × 0.7 filled = 1.4 × 3.7 | 10 / 7 | +42 | over | Tier 3, 1/3 (8.65, +8%). Watch for a fed unit taken out by selling the Ooze: that skips the 0.5 |
| Stone Soup | 2 | 2/3 | 5 + Belly 1 + s 1.2 × 3.7 [g] | 10.4 / 7 | +49 | over. Freezing the shop keeps the stack across turns | 1/2, and the gain lasts this turn only (7.4, +6%) |
| Bubble and Squeak | 3 | 3/4 | 7 + Belly 1.5 + split 0.3 [m] | 8.8 / 8 | +10 | fine. The split does nearly nothing on a plain body [m]; it's for fed Oozes | |
| The Sixpenny Pie | 3 | 1/4 | 5 + Belly 3 3.0 + about 2.2 gold **every fight** about 10 | 18 / 8 | +125 | **over**. Fights run on a copy, so it reopens every turn. Cap is 1 | 1/2. "If 2+ come out, get 1 gold next turn" (9.1, +14%). Golden 2 |
| Frumenty | 4 | 3/5 | 8 + Belly 2 3.4 + 2 texts about 4 each × 1.1 (E22) [g] | 20.2 / 10 | +102 | **over**, and no ceiling: Nell, Committee and Stork all borrow | 2/3, Belly 1, golden Belly 2 (11.4, +14%). Three cards' text moves to True Amalgam |
| Mr Syllabub | 4 | 3/6 | 8.25 + 1.5 fires × 3 × 0.7 × 0.9 [g] | 11 / 10 | +10 | fine, sim with aimed cards after the Hex cap | |
| Hasty Pudding | 5 | 2/8 | 9.5 + even 1.5 [m] + tall 65 [m] × 1/3 × 0.5 | 21.8 / 12 | +82 | **over**: the carry never returns; win rate about 100% in that matchup | "It comes back at your third friendly death" (+23 SP vs tall [m]; 13.3, +11%). **The designer's "after two attacks" does nothing** [m]: fights end first. First death is too weak: -5.8 [m], the same as a plain 2/8; second, -1.5 |
| Figgy Duff | 5 | 4/6 | 9 + Belly 2.5 + triples up by 0.75 a turn × about 10 [g] × 2.6 | 31.5 / 12 | +163 | **over**. A triple-rule change (E85). With Cut, a golden and a Discover every turn | Tier 6, 3/4. Once a turn, needs two Bought copies, golden but **no Triple Reward** (17, +22%). Answers hollow tier 6 |
| Cut-and-Come-Again | 6 | 6/6 | 10.5 + Belly 3 + s 6.4 × 2.6 + a golden every 2 turns about 4 [g] | 34 / 14 | +143 | **over** | 4/4. Every other turn, copies don't count for triples (18.3, +31%). Keep over band, logged: tier 6 is hollow and this is a card sink |
| Granny Stir-Up | 6 | 5/9 | 14 + 48 [m] | 62 / 14 | +340 | **over**: counts all Health twice; about 100% wins | 4/8, gains their **Attack only** (16.1, +15%) [m]. Half stats is still +21 [m]; at most 2 join is +21 [m] |

## Birds

| Card | T | Stats | Costing | Value / V | % | Verdict | Change that keeps the idea |
|---|---|---|---|---|---|---|---|
| One Swallow | 1 | 2/1 | 3 + first gold 2.4 × 0.6 + 1.7 gold per trip ÷ 3 × 5 - 0.8 | 6.4 / 5 | +28 | over, small | 1/1 (5.7, +14%) |
| Mrs Dunnock | 1 | 1/3 | 4 + a third of a trip a turn × Swallow's trip × 0.7 | 6.3 / 5 | +26 | fine, edge | 1/2 if flock income runs high |
| Chiffchaff | 1 | 1/2 | 2.75 + 2.5 first + s 0.84 × 3.9 + 1.7 - 0.7 | 9.5 / 5 | +90 | **over**; at the T1 growth cap | 1/1. "Give the units in front +1 Attack" (5.9, +18%). Still two targets, so still not a stack |
| Tom Tit | 1 | 2/1 | 3 + Swoop 1.5 [g] + 0.75 gold a turn × 5 | 8.3 / 5 | +66 | **over**, like Sexton and Sorrel in pass 1 | 1/1, gold only if you win the fight (5.4, +8%) |
| The Great Lump | 2 | 1/4 | 5 + stats of a mean flier 6 × 0.7, uncapped if stacked | 9.2 / 7 | +31 | over | 1/3, reads the bird's card stats only (8.2, +17%) |
| Mr Redbreast | 2 | 2/3 | 5 + 2.5 Nests × 2 [g] | 10 / 7 | +43 | over. Golden +14/+14 at the cap | 1/2 (8, +14%) |
| Mrs Jay | 2 | 2/2 | 4 + 2.2 + Acorn per trip 2.8 - 1.1 | 7.9 / 7 | +13 | fine | |
| Jack Daw | 3 | 2/3 | 5 + 0.3 + steal: even 0, tall 26.5 [m] × 1/3 + gold 1.7 | 15.8 / 8 | +98 | **over against tall, blank against wide** [m] | 1/2, steal capped at +4/+4 (9, +13%; 12 SP vs tall [m]). Golden +8/+8 |
| Old Tern | 3 | 2/4 | 6 + Discover 6.4 ÷ 4 × 3.5 + gold 1.3 - 1.8 | 11.1 / 8 | +39 | over; much worse with Stork | 1/3 (9.7, +21%) |
| Mrs Stork | 4 | 3/6 | 8.25 + +2 gold a turn at least 9.6, more with Terns; removes the tempo price | 18-30 / 10 | +80 to +200 | **over**. See Fly South | 2/5, and she can't bring home a bird sold this turn (9-11.5, up to +15%). Late gold still buys something |
| Mag Pye | 4 | 3/5 | 8 + 2 × a text about 6 × 0.6 aim [g] | 15 / 10 | +50 | over, sim. Gets better with a huge Hex, so re-check after the cap | 2/3 (12, +20%) |
| Mother Goose | 5 | 4/7 | 11 + 1.4 + strikes 12-14 × 0.85 × 2/3 × 0.7 - 3 | 14.9 / 12 | +24 | fine. Sim with stacked fliers | Say only one Goose fires a fight |
| The Gabble Ratchet | 6 | 4/8 | 11 + 3 birds landing 8.5 [m] × 0.85 | 18.2 / 14 | +30 | over, small | 3/7 (16.5, +18%) |
| The Seven Whistlers | 6 | 5/5 | 8.75 + at seven 72 × 0.4 [g] + below seven 24 [m] × 0.6 | 52 / 14 | +270 | **over**: at seven, about 100% wins [m]. Below seven it's also a carry answer | Every enemy, or the one across, loses a **quarter**. Golden half. 3/3 (23, +64%; quarter of all measures +33 [m], matching E15's 1.1). Keep over band, logged: seven different Birds is the cost. Measure how often it's reached. **Halve Attack only (designer's first lever) is still +36 [m]**; front row only +41 |

---

## Loops

**Nothing goes infinite within a turn.** Rule 2 stops same-turn bird loops. Bellies have to be bought into, and there's no gold back beyond a card's own sale. The risks are per turn, which no refresh price touches.

| Line | Arithmetic | Result |
|---|---|---|
| Figgy + Cut | 3 gold, then a golden and a Discover each turn | **Per-turn compounding.** Fixed by Figgy needing Bought copies and no reward |
| Stork + Swallows | +4 to +8 gold a turn, nobody missing a fight | **Over every cap.** Fixed by the trip floor |
| Stork + Tern | A Discover every turn for 6 gold | Fixed by the trip floor |
| Pie | About 2.2 gold every fight, forever, from 9 gold | Fixed by the flat 1 gold |
| Nesting | Bodies per slot limited only by gold, so banked gold becomes fight length | Seal the inner Belly |
| Sell and replay through a Belly | 2 net gold for a repeat Battlecry. Chiffchaff: 3.6 SP for 2 gold | Designer's right: at the sink, fine |
| Reynard + Dollop or Market Day | Golden Dollop at Market Day buys free, sells for 3, breaking G3 once. Needs a new Dollop each time | Finite. Note it |
| Reynard + fliers | A tier 5-6 bird sells for 3 **every trip**. Goose: 1 gold a turn from the sale alone | Say a flier's sale pays its base 1, as Pawn Ticket's rule 7 does |

## Rule and wording flags

- **Frumenty** should not borrow Fly South or "When sold", as well as Belly. If she flies, what happens to her insides?
- **Mag Pye on an Ooze:** "It has none, and this has it." Does Belly count as text? What happens to what's inside?
- **Two Hasty Puddings across from each other:** who swallows first? Reading order for both sides needs stating.
- **Old Tern's "It sells for 0":** she's Bought, so 1. I read this as the Discovered unit; the line needs fixing.
- **Mrs Stork's count** includes refreshes, so it's a refresh sink too. Probably wanted; state it.
- **Stone Soup and Freeze:** "until they leave it" survives a freeze as written.
- **Golden gold:** Nell, Swallow, Tom Tit and Daw double past the gold caps at their tiers (section 5). The bench should check goldens.

## Can't price without the bench

| Cards | Measure |
|---|---|
| Pudding, Daw, Whistlers, Pye, Belly in general | Share of tall boards in the lobby **after the Dozey and Hex caps**. Re-cost these then. Needs bots that keep a carry still (playtest B) |
| Bellies | Fight length with 12+ bodies. Damage lost to insides not counting. Share of filled Bellies that open |
| Fly South | Mean trips per flier per game, and share of fights lost with fliers away, from round 6 when losses cost 9-15 |
| Flock income | Gold a turn by build, against about +3 |
| Whistlers | Turn seven different Birds are first reached (0.4 is a guess) |
| Nell, Pie, Swallows | T6 turn and units on arrival, against econ-heavy |
| Aspic, Frumenty, Syllabub | Size of the fed reserve by turn; text borrowed, by card |
| Spells after the change | Late sink. Gold prices hold from 1.8 to 2.5 SP a gold. Below that, re-read 4.1 |
