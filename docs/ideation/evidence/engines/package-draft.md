# Engines package: draft for critics and costing

Base: `ideation/commit` at 47b1f48 (the tribe commitment build with the round toll). The prototype is in the working tree of /home/user/Bramble behind switches that are off by default.

## What the measurement says (200 lobbies of 8 Hard bots, seeds 50000-50199)

- Fights follow total stats. Decisive fights from round 9: a logistic fit gives log total stats a coefficient of +1.17 per standard deviation; kin count +0.15, mean tier +0.12, unit count -0.02. The side with the bigger top unit but the smaller total wins only 32-39%.
- Where stats come from (full boards, 6+ units): round 10: printed 49%, Stand Behind Me 21%, Rings 10%, small spells (Cordial, Bread, Pinch) 8%, tribe bonus 0.8%, own-tribe unit text 0.7%. Round 15: printed 44%, Stand Behind Me 17%, Rings 12%, tribe bonus 8%, own-tribe text 1.7%.
- Stand Behind Me is cast 4.9 times per player per game, more than any other card.
- The biggest unit at round 10 is tier 1 in 40% of full boards (tier 5-6: 3%). It carries 30% of its board.
- Endings: from 5 players left, nearly every loss costs the flat cap of 12 (uncapped damage is 14-19 with the toll in it), so the size of a win and the round toll change nothing late. About 11% of fights from round 9 are ties, all of them mutual wipes (both boards empty in the same exchange). The duel starts at about 14 Health each with a gap of 10; the Health leader wins it 64%.

## The package (build order; each item stands alone)

### 1. Last Blow (combat rule)
"If one blow empties both boards, the side that struck it wins. It deals only its tier in hero damage (at least 4), since nobody survived."
A mutual wipe during Start of Combat stays a tie.
Prototype switch: `last_blow`.

### 2. The Last Four (damage rule)
"When four or fewer heroes are left, the damage cap lifts. A loss then costs the winner's tier plus half their survivors' tiers, plus the round toll." (Battlegrounds lifts its cap at four too.)
Prototype switch: `last_four`.

### 3. Stand Behind Me becomes a formation spell (and Bread from the Back mirrors it)
Stand Behind Me (tier 3, 2 gold): "Aim at a front-row unit: each unit behind it gains +1/+1 permanently for each unit touching it that shares its tribe, up to +3/+3."
Bread from the Back (tier 2, 2 gold): "Aim at a back-row unit: each unit in front of it gains +1/+1 permanently for each unit touching it that shares its tribe, up to +3/+3."
"Touching" is the rulebook's neighbours: beside it in its row, and the slots in front of and behind it. A unit with no kin touching gains nothing. (Today: +1/+1, or +2/+2 if it shares the aimed unit's tribe.)
Prototype switch: `formation`. **The card text on screen still shows the old wording; the rule above is what runs.**

### 4. Hand-me-down (recruit rule)
"When you sell a unit, the next unit you play this turn gains half its permanent stats, rounded up." Printed stats, Rings and the tribe bonus don't pass; only permanent gains on the unit. A Bird flying south isn't a sale.
Prototype switch: `heirloom`.

### 5. Harvest Supper moves to tier 3 (optional)
Same text and cost (3 gold, once a turn, tribe bonus up to +3/+3), offered from tier 3 instead of tier 5, so the own-tribe payoff is seen as often as Stand Behind Me.
Prototype switch: `supper3`.

## Showcase cards (designed, not built)

- **The Death-Watch Beetle** (neutral, tier 3, 2/5): "If a blow would empty both boards, your side counts as striking it." Two of them, one each side, cancel out.
- **The Bellman** (neutral, tier 4, 3/6): "While four or fewer heroes are left, your surviving units count their full tier for hero damage, not half."
- **The Heir Apparent** (neutral, tier 5, 4/6): "When you play this, it takes all of this turn's Hand-me-down, not half."

## How to play the prototype

```
cd /home/user/Bramble
BRAMBLE_PROTO=pkg tools/play/play.sh new --seed 7 --difficulty hard --save <your scratch dir>/g1.save
BRAMBLE_PROTO=pkg tools/play/play.sh <save> buy 1      # every later call needs the same BRAMBLE_PROTO
```
`pkg` switches on items 1-4. Add `,supper3` for item 5. Leave BRAMBLE_PROTO unset to play the current build for comparison. `tools/play/README.md` lists every command.
