**Diagnosis: the primary failure is at the mechanic level.** Eating usually converts a fixed shop body into a fixed gain. The scalable inputs—Soup, Hasty and Slice—do not reach enough boards to make ordinary digestion compound. The [critic](docs/ideation/evidence/a35-step0/critic-oozes.md) found no Slice on the 26 R12 boards; increasing base meal stats would still produce growth by meal count.

The second cause is the acquisition journey. [Soup triage](docs/ideation/evidence/triage-stone-soup.md) found zero yield in 17 of 24 early Soup board-rounds, and five of eleven Soup seats eliminated before R12. The brief’s post-fix 398 remains only 44% of 900.

Measurement exaggerates the paper promise: the synthesis counted Belly contents, while the target counts active bodies. Nevertheless, reserves have combat value; changing the measurement would conceal the growth failure.

**Route:** bottom-up mechanical, starting with “Do I keep this unit as a spare life, or destroy it for food?” Make that sacrifice scale with the eater.

**Design: the eater cultures its food.**

Replace **Digest**’s reminder:

*Start of Turn: non-Oozes inside gain ⅔ of this unit’s stats; eat everything inside.*

The meal becomes larger because it spent a fight inside a larger Ooze. Its destruction turns that investment into permanent, active-board growth.

Rules:

- Snapshot the eater’s base plus permanent Attack and Health before digestion. Each non-Ooze inside gains two thirds of that snapshot, rounded down separately.
- Culture all meals first, then eat in existing last-in-first-out order. Empty Bellies do nothing.
- Culture is a permanent recruiting buff. Existing restrictions, including Shy, apply.
- Eat remains unchanged. Aspic amplifies the cultured meal; Elder shares its cultured stats before Aspic.
- Ooze meals receive no culture. Moving an existing carry therefore transfers its stats without multiplication.
- Golden Belly capacity increases meal count; the culture fraction stays unchanged.
- Existing Start of Turn order, nesting rules and combat releases remain.

This deliberately makes feeding generous without requiring Soup.

Normal cards below retain their existing faces; **Digest changes on all three carriers**. Names occupy the final column.

| Tier | Stats | Full rules text | Name |
|---|---|---|---|
| 1 | 1/2 | Belly 1. Digest. Buying into this costs 1 gold less. | Little Dollop |
| 3 | 3/4 | Belly 1. Digest. After this survives a hit: split in two. Once a fight. | Bubble and Squeak |
| 4 | 2/3 | Belly 1. Digest. This has the text of its last meal. | Frumenty |

The benchmark boards also use these unchanged pieces:

| Tier | Stats | Full rules text | Name |
|---|---|---|---|
| 1 | 2/1 | Belly 1. When this dies: its killer loses half its stats. | Mrs Posset |
| 1 | 1/4 | Belly 1. After this survives a hit: what’s inside comes out, or a 1/1 Drip. | Wee Wobbly |
| 2 | 2/4 | When a unit comes out of your Oozes: it gains Shield. | Moss Ooze |
| 3 | 2/4 | Oozes in front of this gain 50% more from eating non-Oozes. | Aunt Aspic |
| 3 | 2/5 | Belly 2. When this dies: get 1 gold per unit that comes out. | The Sixpenny Pie |
| 1 | 2/3 | No text. | Dewdrop Ooze |
| 3 | 4/4 | No text. | Bramble Ooze |
| — | 1/1 | No text. Created Ooze token. | Drip |

**Concrete pitch: Little Dollop.**

**Tier 1, 1/2, Ooze.** “Belly 1. Digest. Buying into this costs 1 gold less.”

A 20/24 Dollop holds **Wood Mouse Guard**, a tier-3 4/4 with no text. Next turn, culture gives the Guard +13/+16. Dollop eats the resulting 17/20 and becomes **37/44**.

With Aspic behind it, Dollop instead becomes **45/54**. With Elder present and Dollop biggest, every other board Ooze also receives +8/+10. Soup enlarges the initial ingredient; Nell adds another ordinary meal without culturing it.

A player runs Dollop because a cheap foreign body remains useful fuel throughout the game. It works particularly well when the shop offers solid bodies but no further engine pieces.

Outside Oozes, Dollop supplies a growing fighter for a mixed board. Frumenty develops this interaction further: foreign combat text becomes both food and a chosen ability.

Two variations:

- Culture at **half** rather than two thirds: the first dial-down.
- Divide one culture allowance among all contents: golden capacity widens feeding without multiplying the whole allowance.

It resembles the feeding silhouette of Battlegrounds’ Demons discussed in the synthesis; here, the eater supplies the meal’s scaling.

**Benchmark boards.**

These are arithmetic scenarios, **not measured medians or acquisition probabilities**. All totals exclude contents, combat summons and hypothetical reserve value.

Meals average 2/3 through R5 and 4/4 thereafter. Each host starts feeding the turn after purchase. Without Aspic, each stat follows:

`next = current + floor(2 × current / 3) + meal`

Average finds Dollop R1 and Bubble R6, with no Soup, Aspic or Elder. High roll finds two Dollops R1/R4 and Aspic R6. Low roll finds Dollop R3 and misses feeding at R4 and R7.

Abbreviations: **P** Posset, **W** Wobbly, **M** Moss, **A** Aspic, **D** Dewdrop, **B** Bramble, **Pie** Sixpenny Pie.

| Scenario | Round / tier | Active board | Total stats |
|---|---|---|---:|
| Average | R6 / T3 | Dollop 23/43; Bubble 3/4; P, M, W | **87** |
| Average | R9 / T3 | Dollop 127/219; Bubble 19/20; P, M, W, D, B | **412** |
| Average | R12 / T4 | Dollop 607/1035; Bubble 107/112; same five supports | **1,888** |
| High | R6 / T3 | Dollops 23/43 and 3/6; A | **81** |
| High | R9 / T3 | Dollops 222/379 and 66/90; A, M, P, W, D | **782** |
| High | R12 / T4 | Dollops 1818/3067 and 570/762; same five supports | **6,242** |
| Low | R6 / T3 | Dollop 3/6; P, M, W, D, B, Pie | **43** |
| Low | R9 / T3 | Dollop 19/27; same six supports | **80** |
| Low | R12 / T4 | Dollop 107/145; same six supports | **286** |

Income totals **33 / 62 / 92 gold** through R6/R9/R12. Allocation below is **bodies / food / tiering / remaining for refreshes or banking**. No sale, hero or combat income is assumed.

| Scenario | R6 | R9 | R12 |
|---|---|---|---|
| Average | 15 / 10 / 8 / 0 | 21 / 25 / 8 / 8 | 21 / 40 / 11 / 20 |
| High | 9 / 14 / 8 / 2 | 21 / 26 / 8 / 7 | 21 / 38 / 11 / 22 |
| Low | 21 / 4 / 8 / 0 | 21 / 8 / 8 / 25 | 21 / 14 / 11 / 46 |

Following these same cohorts through R14 gives geometric R8–R14 growth of approximately **×1.66 / ×2.00 / ×1.54 per round**. The average overshoots deliberately; even removing Bubble leaves its R12 Dollop above 900.

**Skill checks.**

- **Power for its place:** Dollop competes with tier-1 **Mrs Posset** and **Wee Wobbly**. Both offer immediate combat utility; Dollop’s weaker initial body asks for recurring 2-gold investment and a delayed payoff.
- **Play pattern:** choose food versus another fighter, which host receives it, and whether a valuable unit should remain a reserve. Belly capacity bounds digestion; no repeatable recruiting loop is introduced.
- **Path:** Dollop starts independently. Bubble becomes a second growing fighter rather than forcing an early carry transfer. Frumenty is a combat-text pivot. Soup, Nell, Aspic and Elder accelerate a functioning engine.
- **Johnny:** foreign bodies fuel every carrier; Frumenty selects foreign abilities. Posset, Wobbly and Moss support mixed reserve packages. No new keyword is needed.

**Most likely failure:** growth still concentrates on a fighter with no combat ability. The average R12 Dollop holds **87%** of its board’s stats. This could pass the size benchmark while losing badly to swallowing, halving or repeated small attackers.

*Read-only handoff: no files changed, commits made or actions denied. Rules and gold/growth arithmetic checked; no Godot run. Acquisition and combat validation remain.*