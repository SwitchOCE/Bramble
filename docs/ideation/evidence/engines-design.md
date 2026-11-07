# Engines and endings: why stat piles win, and a package

**Cause.** Gold turns into permanent stats at one flat rate through neutral cards: Stand Behind Me (cast 4.9 times a player a game), Rings and the small spells make 40% of round-10 stats. Those stats stay on whatever was bought first (the biggest unit at round 10 is tier 1–2 on 59% of full boards), so a fight follows log total stats, at eight times the weight of kin count or tier. Endings stall because, from five players left, every loss costs the flat cap of 12 whatever the margin, so the round toll does nothing late. On top of that, one late fight in nine is a mutual wipe that settles nothing.

**The package, in build order (each item can be adopted alone):**
1. **Last Blow:** a mutual wipe goes to the side that struck the final blow.
2. **Harvest Supper at tier 3:** the own-tribe spell is offered from tier 3, not tier 5.
3. **The Last Four and Last Stand:** the cap lifts at four left, and each hero once survives a knock-out on 1 Health.
4. **Kin spells:** Stand Behind Me and Bread from the Back pay only units that share the aimed unit's tribe.
5. **Hand-me-down:** a sold unit passes half its gained stats to the next unit you play, capped by that unit's tier.

**Cut first:** Hand-me-down (5). It has the smallest measured effect, it adds state you can't see, and both critics found ways to funnel it. Cut Kin spells (4) next: Supper at tier 3 already does most of its work.

Base: `ideation/commit` at 47b1f48, the commitment build with the round toll. Nothing here is game code: the prototype is `engines/prototype.patch.txt` behind switches that are off by default, the probe is `engines/engines_probe.gd.txt`, and the analysis scripts are in `engines/`. Critics: `engines-critic-play.md` (A, strategy) and `engines-critic-feel.md` (B, newcomer and endings). Costing: `engines-costing.md`.

## 1. Why the engines win: what I measured

All runs: 200 lobbies of 8 Hard bots, seeds 50000–50199, on the real rules (`engines_probe.gd`, an extension of `commit_probe.gd` that also logs every fight's boards, kills, result and reason). "Full boards" means 6 or more units, read at a fixed round, so early eliminations don't flatter anything.

**What wins a fight.** I took decisive fights from round 9 (n = 2,974) and fitted a logistic regression to the difference between the two boards. Coefficients are per standard deviation:

| Feature | Coefficient |
|---|---:|
| log total stats | **+1.17** |
| back-row share of stats | −0.18 |
| kin count (most units of one tribe) | +0.15 |
| mean tier | +0.12 |
| biggest unit's share | −0.10 |
| unit count | −0.02 |

The fit is 71% accurate. One huge unit doesn't decide fights. The side with the bigger top unit but the smaller total wins only 32–39%. The biggest unit makes 24–28% of its side's kills and survives 45% of fights. Total stats decide, and what the board is built from barely shows. Wins against the stat ratio (bigger board / smaller), rounds 9+:

| Ratio | 1.0–1.1 | 1.1–1.25 | 1.25–1.5 | 1.5–2 | 2+ |
|---|---:|---:|---:|---:|---:|
| Bigger board wins | 47% | 58% | 70% | 86% | 91% |
| Tie | 14% | 13% | 9% | 4% | 0% |

**Where the stats come from** (full boards):

| Source | Round 10 | Round 15 | Biggest unit, round 15 |
|---|---:|---:|---:|
| Printed | 49% | 44% | 25% |
| Stand Behind Me | 21% | 17% | 17% |
| Rings | 10% | 12% | 27% |
| Other spells (Cordial, Bread, Pinch, Last Orders) | 8% | 6% | 8% |
| Tribe bonus (Harvest Supper) | 0.8% | 8% | 4% |
| Unit grows itself | 6% | 4% | 8% |
| Own-tribe unit text | 0.7% | 1.7% | 1.8% |

Casts per player per game: Stand Behind Me 4.9, Boundary Stone 1.9, Cordial 1.5, Pinch 1.4, Bread 0.7, Harvest Supper 0.5.

**Why the cheap bodies carry.** At round 10, the biggest unit on a full board is tier 1 on 40% of boards and tier 1–2 on 59%. Tier 5–6 is 3%. It averages 30 stats and 30% of its board. Stand Behind Me feeds the back row, Rings feed slots, and both land on the first bodies you placed. Selling one throws its gains away, so nobody upgrades a carrier.

**Snowball.** The rank correlation between board stats and final place is 0.34–0.40 from round 5 on. The round-7 stat leader finishes top 2 in 53% of games. That's real but not runaway: bots of equal skill are less stuck than the playtesters felt.

**Why the end stalls.**
- Damage per decisive loss: 6 with 8 alive, 11.8 with 5, and **12.0 with 4, 3 or 2**. Uncapped it would be 15–19 with the toll in it, so the cap binds on nearly every late loss. The margin of a win stops mattering, and the round toll sits under the cap and does nothing.
- 10.7% of player fights from round 9 are ties, and every one is a mutual wipe: both boards emptied in the same exchange. None ran out of attacks or hit the attack limit.
- The duel starts at about 14 Health each, median gap 10. The leader needs one win and the trailer usually two. The Health leader at four left wins only 45%, but a winner came from the bottom two on Health in only 17% of games.
- The round toll did shorten games: 15.5 rounds, range 14–18.
- With humans the stall shows as banked gold (pt3-c reached 56). The bots spend theirs on Stand Behind Me, which is the stat pile itself.

**Against Battlegrounds.** Bramble's growth is about Battlegrounds-sized: round-15 boards hold about 170 stats, with the biggest unit at 47. Battlegrounds late boards run to hundreds, so the size of the growth isn't the problem. Where it comes from is. Battlegrounds moved its scaling into tribe text and "this game" counters (Undead Attack, Blood Gems, spell-buff counters; `research/battlegrounds/strategy-eras.md` §5). Bramble's scaling sits in neutral spells and Rings. Battlegrounds also lifts its damage cap at the top four (`rules.md` §12). Bramble keeps 12 through the duel (`DECISIONS.md`, line 81). So the package moves growth from neutral cards onto tribes rather than flattening it, and lets margins count again at the end.

## 2. Results: before and after, on the same 200 seeds

Each arm reruns seeds 50000–50199 with one change. Margins are 95% intervals from a seed-paired bootstrap (100–200 resamples). Fight-level shares are resampled by game. "Final" is items 1–5 together, using the prototype versions as benched (see the deviations under each item).

### Endings

| Measure | Base | Last Blow | Last Four only | Last Four + Stand + Blow | Final |
|---|---:|---:|---:|---:|---:|
| Rounds per game | 15.5 | 15.3 (−0.4 to 0.0) | 14.9 (−0.7 to −0.5) | 16.2 (+0.5 to +0.8) | FINAL_ROUNDS |
| Late fights tied | 10.7% | **0%** (−12.1 to −9.9) | 10.6% | **0%** | FINAL_TIES |
| Rounds from four left to the end | 3.6 | 3.6 | 3.0 (−0.7 to −0.5) | **4.5** (+0.7 to +1.1) | FINAL_R4 |
| Duel fights | 1.51 | 1.53 | 1.21 (−0.42 to −0.20) | **1.73** (+0.04 to +0.37) | FINAL_DUEL |
| Winner was bottom 2 on Health at four left | 17% | 18% | 20% (+0.5 to +5.3) | **32.5%** (+7.2 to +23.8) | FINAL_CB |
| Damage per loss, four or fewer left | 12.0 | 12.0 | 16.6 | 16.5 | |

Lifting the cap on its own makes the end abrupt: shorter, and the duel is one fight. That matches critic A's game 3 and critic B's game 1. Last Stand turns the same big hits into a game you can come back in. The last four lasts a round longer, and comebacks from the bottom two nearly double.

### Engines, full boards at a fixed round

| Measure | Base | Supper at tier 3 | Supper 3 + Kin spells | Final |
|---|---:|---:|---:|---:|
| Round 10 board stats | 97.0 | 99.3 (+1.6 to +3.0) | 98.1 (+0.3 to +1.9) | FINAL_S10 |
| Round 10, neutral spells' share | 29.8% | 17.9% (−12.5 to −11.2) | **16.5%** (−14.0 to −12.5) | FINAL_SP10 |
| Round 10, tribe bonus share | 0.8% | 16.3% | **16.8%** (+15.4 to +16.7) | FINAL_TB10 |
| Round 12, neutral spells' share | 27.9% | 16.5% | 15.4% | FINAL_SP12 |
| Round 12, tribe bonus share | 3.8% | 16.6% | 17.8% | FINAL_TB12 |
| Round 10, biggest unit tier 1–2 | 59% | 55% (−8.4 to −1.9) | 55% (−7.3 to −0.7) | FINAL_T10 |
| Round 10, biggest unit's share of board | 30.2% | 28.0% (−2.7 to −1.9) | 28.0% (−2.6 to −1.7) | FINAL_B10 |
| Round 10 place, 6+ kin minus ≤4 kin | −0.51 | −0.59 (±0.36) | −0.58 (±0.30) | FINAL_K10 |
| Fight coefficient, log stats | 1.13 | 1.10 | 1.08 | FINAL_CS |
| Fight coefficient, kin count | 0.15 | 0.16 | 0.20 (−0.08 to +0.19) | FINAL_CK |
| Stand Behind Me casts per player per game | 4.9 | 2.4 | 2.1 | |
| Harvest Supper casts per player per game | 0.5 | 1.9 | 1.9 | |

What moved: about 13 points of every board's stats moved from neutral spells into the tribe bonus, with almost no inflation (+1 to +2 stats on a board of 97). The biggest unit's share fell by 2 points, and fewer carriers are tier 1–2. What didn't move, within noise: the fight coefficients and the commitment gap. Fights still follow total stats. The difference is that a sixth of those stats now exist only if you committed to a tribe, so "what you build" now feeds the totals rather than sitting beside them.

### Placement value

The bench puts a shuffled-placement Hard seat among seven Hard bots, so its place minus 4.5 is what placement is worth to a seat: base SHUF_BASE, final SHUF_FINAL (SHUF_DIFF).

### What I tried and dropped

| Arm | Result | Verdict |
|---|---|---|
| Formation Stand Behind Me (+1/+1 per touching kin, up to +3/+3) | Spells rose to 31% of stats at round 12 (+3.4, ±1); board stats +5.8; tier 1–2 carriers +5.8 points; committed boards place 0.33 better (−0.62 to +0.02) | Variation only. It inflates stats and feeds the same back-row tier-1 bodies (critic B: Gideon 16/20). Critic A: "a flat buff of about +50%" on one-tribe boards, and it taxes off-tribe tech |
| Hand-me-down, uncapped as prototyped | Tier 1–2 carriers −4 points (−7.1 to −1.2); board stats +3.2; spell share −2.9 (moved to the inherited line) | Kept but capped, and cut first |
| Formation + Hand-me-down + Last Blow + Last Four (the first package) | Ties 0; comebacks +7.5 (+0.5 to +14); stats at round 12 +11.9 (+10.4 to +13.5); no change in the fight coefficients | Replaced: it inflated stats and didn't make the end longer |

Winning builds stayed spread in every arm: 15 to 18 different builds won. The top build (Hedgerow Parish, or Second Helpings in the Kin arm) took 18–24% of wins, against 22% in the base. Nothing new dominates.

**Limits.**
- These are bot lobbies. Bots spend gold rather than bank it, so the human stall (56 gold banked) is argued here, not measured.
- Bots don't plan formations or sell their carriers on purpose. I taught Hard one rule for Hand-me-down: count the inherited half when replacing a unit.
- With 200 games, differences under about 0.35 of a place, or 2 points of a share, are noise.
- No bench ran with Rings changed, and critic A's losses all went to Ring stacks on cheap bodies (see Open).

## 3. The items

### 1. Last Blow (combat rule)

**Rule (rulebook 9.9.2):** "If the last units on both sides die together, the side that dealt the final blow wins: the attacker in an exchange, or the owner of the effect that finished it (a death effect, Bitter, Spitfire Sal). It deals its tier in hero damage, at least 4, since nobody survived. A wipe during Start of Combat stays a tie."

**Deviation from the bench:** the prototype credits the side of the last attack declared. Critic A and costing both found that a death effect finishing the wipe (Mrs Posset's 3 damage) should count for its owner, and the rule above does that.

**Showcase card: The Death-Watch Beetle** (neutral, tier 5, 3/7): "If a blow would empty both boards, your side counts as striking it." Tier and body follow costing; my draft was tier 3, 2/5.
- *Interactions:* it makes Bitter and Mrs Posset finish wipes for you. Two Beetles, one on each side, cancel out and the normal rule applies. Changeling's swapped unit counts for the side it fights for.
- *Why run it:* boards that trade evenly (Bog folk's Bitter wall, the Nightshade Fairies) turn their wipes into wins.
- *Where it's good:* a Bog mirror where both lines trade down to Gideon against the Peat King.
- *Variation A:* the defender wins a wipe, which rewards tanks and Mire rather than Quick.
- *Variation B:* a wipe hurts both heroes for the other side's tier, which keeps the tie but makes it cost.

**Why:** it removes every late tie (10.7% to 0, interval −12.1 to −9.9) and makes attack order and the last trade matter. Critic A: early mutual wipes now cost 4–5 rather than the toll; I accept that. **Against Battlegrounds:** Battlegrounds keeps ties at zero damage. This differs on purpose.

### 2. Harvest Supper at tier 3 (spell)

**Card (unchanged text):** "Harvest Supper (now tier 3, 3 gold): Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later. Once a turn. Tribe bonus up to +3/+3; not on units summoned in fights."
- *Interactions:* it competes for the shop's one spell slot with Stand Behind Me, which halves that spell's casts. The bonus is a separate layer, so it survives selling and triples and isn't doubled by golden units. A unit with two tribes gets both bonuses.
- *Why run it:* from round 6, three casts give every present and future unit of your tribe +3/+3. That's the commitment payoff, available in the midgame.
- *Where it's good:* a Hunters board with Grizel and two Brocks at tier 3. Critic A got +5/+5, then +7/+7, across their Hunters in rounds 8–9.
- *Variation A:* tier 3, capped at +2/+2, with Hiring Fair's tier-6 Discover lifting your main tribe's cap to +4/+4.
- *Variation B:* tier 4 at 2 gold, if tier 3 proves too early.

**Costing:** in budget (13.25 SP against 15). **Both critics: keep.** **Against Battlegrounds:** this is the "this game" tribe counter that Battlegrounds' late game runs on (Undead Attack, Blood Gems), on one Bramble card, capped. Watch two things: the Queen leaking the bonus (review ask 8), and Supper alongside Kin spells, since both scale with kin count.

### 3. The Last Four and Last Stand (damage rule)

**Rule (replaces "the cap remains through the final duel" in 10.1.4a):** "When four or fewer heroes are left, the damage cap lifts. Last Stand: once a game, a loss that would knock your hero out from above 5 Health leaves it on 1 instead." The screen shows "Cap lifted: 4 left" and the damage sum in the fight result, and a hero's Last Stand shows as used. Critic B asked for both.

**Showcase card: The Bellman** (neutral, tier 4, 4/6): "While four or fewer heroes are left: if your hero has used its Last Stand, your units have +2 Attack." Body per costing, which rated the first draft's text worth about nothing.
- *Interactions:* it is dead in the first ten rounds and a comeback engine on 1 Health. It stacks with the Committee's touching Attack.
- *Why run it:* it's the one card that's better when you're losing at the end.
- *Where it's good:* you're on 1 after your Last Stand, the leader is on 20, and the Bellman's +14 Attack across seven units turns the next fight.
- *Variation A (critic A):* step the cap instead, 15 with four left, 20 with three, uncapped in the duel.
- *Variation B (costing):* lift the cap at four left but bring 12 back for the duel.

**Why:** the cap lifting alone shortens the end and makes the duel one fight. With Last Stand and Last Blow, the end runs a round longer (3.6 to 4.5 rounds from four left), duels last 1.73 fights rather than 1.51, and a winner comes from the bottom two on Health in 32.5% of games rather than 17%. Margins count again (16.5 per loss rather than 12), and the round toll is real again late. **Against Battlegrounds:** Battlegrounds lifts the cap at the top four; Last Stand is Bramble's. This reverses the logged reason for the permanent cap (DECISIONS, line 81: "removes the top-four cliff"). Last Stand is the answer to that cliff: you can't fall off it from above 5 Health.

### 4. Kin spells (two spells)

- **Stand Behind Me** (tier 3, 2 gold): "Aim at a front-row unit: the units behind it that share its tribe gain +2/+2 permanently."
- **Bread from the Back** (tier 2, 2 gold): "Aim at a back-row unit: the units in front of it that share its tribe gain +2/+2 permanently."

Today a unit of a different tribe still gains +1/+1. Now it gains nothing.
- *Interactions:* a unit with two tribes counts for either. Pipistrelle Echo's extra targets check kin one by one. Moss Ooze passes the stats inside. Shy units still walk out. Neutral tech (Whirligig, Hasty Pudding) gains nothing; it earns its slot with its text.
- *Why run it:* a committed back row gets +4/+4 a unit-pair for 2 gold. That's the same as today for kin, so committed boards lose nothing and mixed boards lose the generic sink.
- *Where it's good:* three Oozes behind an Ooze front line.
- *Variation A, formation (benched):* "+1/+1 for each unit touching it that shares its tribe, up to +2/+2" (critic A's and costing's cap). Placement matters, but stats rise.
- *Variation B:* other units gain +1 Health only, so mixed boards keep a small use.

**Costing:** in budget at the kin numbers. **Measured:** over Supper at tier 3 alone, it adds −1.4 points of neutral-spell share and a slightly higher kin coefficient (noise). It's small: cut it second.

### 5. Hand-me-down (recruit rule)

**Rule:** "When you sell a unit, the next unit you play this turn gains half of what the sold unit had gained (permanent stats only), rounded down, up to twice its own tier in Attack and in Health. One sale feeds one play." Printed stats, Rings and the tribe bonus don't pass. A Bird flying south isn't a sale. A tooltip shows "Next unit played: +3/+3".

**Deviation from the bench:** the prototype added all of a turn's sales together and rounded each half up. Critic A funnelled +1/+1 gains onto Dozey whole that way, and costing flagged that the code went further than the text. The rule above is the fixed version.

**Showcase card: The Rag-and-Bone Man** (neutral, tier 2, 2/3): "When you sell a unit, this gains the half that Hand-me-down leaves behind, up to +3/+3." It replaces the Heir Apparent, which both critic A and costing cut ("well over", and a funnel that already stacks).
- *Interactions:* it can take the lost half while a tier-5 unit takes the gift. It can't triple-launder: golden units don't double a gift.
- *Why run it:* you upgrade a carrier without throwing it away.
- *Where it's good:* round 10, swapping a 23/28 Bridge Toad (+20/+25 gained) for the Peat King, which gets +10/+12, capped at +12/+12.
- *Variation A:* the gift goes only into the sold unit's slot, which adds a placement choice.
- *Variation B:* the whole gift, but only to a unit sharing the sold unit's tribe.

**Measured (uncapped):** tier 1–2 carriers fell 4 points (−7.1 to −1.2) and board stats rose 3. **Costing:** in budget once one sale feeds one play. **Critic B:** "clear and fair, and the half never felt mean". **Against Battlegrounds:** Battlegrounds has no general rule for this; its closest are stat-transfer cards (Mind Muck, Tarecgosa).

## 4. Calls on the critics and costing

| Point | From | Call |
|---|---|---|
| Last Blow should credit the effect that empties the board | A, costing | Taken (item 1 text) |
| Last Four overshoots; the duel is one fight | A, B, costing | Taken: Last Stand added (B's idea), and benched |
| Formation is +50% on one-tribe boards and taxes neutrals | A, B | Taken: replaced by Kin spells; formation is a variation |
| Bread formation over budget (12 SP) | Costing | Moot after the change |
| Hand-me-down funnels and stacks | A, costing | Taken: one sale per play, rounded down, capped at twice tier |
| Cut the Heir Apparent | A, costing | Taken |
| None of the rules show on screen | B | Build requirement: every item shows its line on the card or in the fight result |
| Supper at tier 3: keep | A, B, costing | Kept, item 2 |

## 5. Open

Critic A: "Every loss, though, went to a stat pile," on Rings stacked on tier-1 and tier-2 bodies (a golden Mrs Sorrel at 32/35, 19 of it from a Ring). Rings are 27% of the biggest unit's stats at round 15, and the package doesn't touch them. Next candidate, unbenched: **"A Ring gives its full value to a Fairy and half to anyone else"**. Rings stay a Fairy reward and stay on slots, and the commit review's cut of Ring doubling isn't reopened. Bench it before adopting.

## Reproduce

```sh
git apply docs/ideation/evidence/engines/prototype.patch.txt      # on ideation/commit 47b1f48
cp docs/ideation/evidence/engines/engines_probe.gd.txt tools/sim/engines_probe.gd
godot --headless --import
godot --headless -s res://tools/sim/engines_probe.gd -- games=50 first_seed=50000 \
  proto=last_blow,last_stand,kin_only,heirloom cfg_damage_cap_off_at_alive=4 supper_tier=3 > final_s0.txt
# four shards of 50 per arm (first_seed 50000/50050/50100/50150); then
python3 docs/ideation/evidence/engines/compare.py <base dir> <arm dir>
```
To play the prototype: `BRAMBLE_PROTO=pkg,last_stand,supper3 tools/play/play.sh new --seed 7 --difficulty hard`. `pkg` switches on Last Blow, the Last Four, formation and Hand-me-down; `kin_only` exists only as a probe switch.

## In short

Neutral spells and Rings turn gold into stats at a flat rate, onto the first cheap bodies bought, so fights follow total stats. A capped 12 per loss, plus mutual wipes, flattens the end. The package moves growth onto tribes: Harvest Supper at tier 3 turns 13 points of every board's stats from neutral spells into the tribe bonus, with no inflation. Last Blow, the Last Four and Last Stand end ties, double comebacks and lengthen the last four by a round. Fights still follow totals; the totals now come from what you built.
