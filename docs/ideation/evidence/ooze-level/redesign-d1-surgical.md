## Diagnosis

**The primary problem is content: the set’s buying sequence lacks an accessible, independent source of growing food.** Belly’s delay makes that gap expensive.

The [Soup triage](/home/alex/code/Bramble-ideation/docs/ideation/evidence/triage-stone-soup.md) found zero shop bonus in 17 of 24 early Soup board-rounds. Five of eleven Soup seats died before R12. Yet surviving Soup boards reached only 331: access alone cannot close the payout gap. The brief’s post-fix 398 confirms this.

The [dial check](/home/alex/code/Bramble-ideation/docs/ideation/content/pass3/a35-dial-check.md) identifies three growing sources: Soup, enemy-sized Hasty, and Slice. Slice appeared on **none** of the measured R12 boards. The ordinary line therefore buys food while waiting for its scalable food generator.

**Second cause: measurement and modelling.** Paper assumed reliable arrivals and counted Belly contents; the target counts active units. Moving the carry also removes its stats from the active board for a fight. The 0.275 realization ratio warns against calling an assembled example a median.

**Route: surgical content changes, because the missing roles and their arrival windows are identifiable; Belly, Eat and Digest remain unchanged.**

## Existing role map

Current unit files, before these changes:

| Tier | Cards and roles |
|---|---|
| 1 | Little Dollop: enabler/economy. Mrs Posset: tempo/answer. Wee Wobbly: tempo. Dewdrop Ooze: plain tempo filler. |
| 2 | Stone Soup: scaling enabler. Dishwater Nell: economy/enabler. Moss Ooze: combat payoff. |
| 3 | Aunt Aspic: feeding payoff. Bubble and Squeak: carry/combat payoff. The Sixpenny Pie: reserve economy. Bramble Ooze: plain tempo filler. |
| 4 | Frumenty: combination payoff/carry. Figgy Duff: economy. Mr Syllabub: release payoff. Bog Ooze: plain tempo filler. |
| 5 | Elder Ooze: board-wide payoff. Hasty Pudding: answer/finisher. Great Ooze: plain tempo filler. |
| 6 | Granny Stir-Up: finisher. Cut-and-Come-Again: food economy/enabler. |

Drip and Slice are generated tokens.

The gaps are **early active strength**, **food without Soup**, and **a scaling purchase before T6**. Pie and Figgy create value without immediately growing the active board; Moss and Syllabub improve reserves rather than developing a permanent engine.

## Four changes

All four are Oozes. Names follow their intended roles.

**Early stomach that can fight — T1, 3/4.**

> Belly 1. Digest. Buying into this costs 1 gold less.

Golden, 6/8:

> Belly 2. Digest. Buying into this costs 2 gold less.

**Little Dollop — rework.** Its stronger body lets players keep their first carry while searching, rather than requiring Bubble immediately.

**Immediate shop support — T1, 2/3.**

> Shop units gain an eighth of your biggest Ooze’s stats.

Golden, 4/6:

> Shop units gain an eighth of your two biggest Oozes’ stats.

Details: round each stat up; only the best Soup counts. Other Soup rules remain.

**Stone Soup — retain the triage’s proposed tier and rounding fixes.** The checked-in JSON still lists T2.

**Purchase that supplies proportional food — T2, 4/6.**

> When played: get a Slice with your biggest Ooze’s stats.

Golden, 8/12:

> When played: get two Slices with your biggest Ooze’s stats.

**Dewdrop Ooze — replace the filler and add it to the playable slice.** This buys a fighting body and a future meal. Repeated purchases provide an alternative to finding the generator.

**Repeatable food engine — T3, 4/6.**

> Start of Turn: get a Slice with half your biggest Ooze’s stats.

Golden, 8/12:

> Start of Turn: get two Slices with half your biggest Ooze’s stats.

**Cut-and-Come-Again — move from T6 and increase its share from a fifth to half.**

For both sources, read base plus permanent stats. Slice is T1, tribeless, Created, has no rules text, and takes its stats from its source; it sells for 0 gold. Fractions round down. Existing hand limits apply.

## Centrepiece pitch

**Cut-and-Come-Again: T3, 4/6, Ooze.**

> Start of Turn: get a Slice with half your biggest Ooze’s stats.

With a 40/40 Dollop, it serves a 20/20 Slice. Play that Slice immediately, or put it inside Dollop. Next turn, Digest adds 20/20; behind Aspic, that becomes 30/30. Elder separately gives every other active Ooze +10/+10.

**Why run it:** it turns an established carry into renewable material without requiring Soup or another paid meal. Pot Luck can deploy the material instead of swallowing it.

**Good situation:** you have a large Dollop, six active units, and little gold after tiering up. A Slice fills the seventh slot now; feeding it instead exchanges that immediate strength for compounding growth.

**Interactions:** Soup improves later purchased supports; Nell adds another meal. Frumenty can eat Cut and inherit its generator. Outside a full Ooze board, one large Ooze supplies tribeless attackers that can receive Mr Crumb’s Pass.

Two alternative versions, each T3, 4/6:

- **Dinner for Two:** “Start of Turn: get two Slices with a quarter of your biggest Ooze’s stats.”
- **Fresh Cut:** “When played: get a Slice with your biggest Ooze’s stats.” An immediate, repeatable purchase instead of passive income.

It resembles the Felbat/Ur’zul eating pattern cited in pass 3, with food the player can also field.

## Benchmark constructions

These are **conditional estimates**, not measured averages. “Average” means the ordinary-find construction below; its population frequency remains unproved.

Abbreviations: D Dollop, S Soup, B Dewdrop, N Nell, C Cut, A Aspic, E Elder, M Moss, P Posset, W Wobbly, Pie Sixpenny Pie.

All lines tier up on R3/5/8/10, spending 3/5/5/9 gold. Thus the checkpoint tiers are **2/4/5**. Cumulative income is **33/62/92**; cumulative paid refresh spending is **1/12/30**.

| Find case | Round | Active cards | Carry stats | Total active stats | Gold bank |
|---|---:|---|---:|---:|---:|
| Average | 6 | D, S, B, P, N, W | 16/21 | **79** | 0 |
| Average | 9 | D, S, B, N, C, A | 79/109 | **252** | 7 |
| Average | 12 | D, S, N, C, A, E, M | 728/1007 | **4,480** | 5 |
| High | 6 | D, S, B, N, C, W | 25/34 | **116** | 0 |
| High | 9 | D, S, B, N, C, golden A | 167/230 | **514** | 6 |
| High | 12 | D, S, N, C, golden A, E, M | 2647/3662 | **14,440** | 4 |
| Low | 6 | D, P, W, S, B | 7/10 | **43** | 5 |
| Low | 9 | D, P, W, S, Pie, M, B | 23/33 | **112** | 6 |
| Low | 12 | D, S, Pie, M, C, B, E | 108/156 | **392** | 1 |

Average finds B R4, N R6, C R7, A R8, E R10. High finds N R4, C R6, A R7, then goldens Aspic through Figgy and a second copy R9. Low misses Nell/Aspic, finds C R10, and buys Dewdrops R6/9/11, selling earlier copies before a triple forms.

At R12, cards/paid meals cost **30/8**, **33/6**, and **33/10** gold respectively; sales return **3/3/4** gold.

Calculations exclude Belly contents, combat gains, spells and hero bonuses. Paid food and Nell use non-Shy 2/3 meals before Soup. New Cut produces its first Slice next turn; Digest consumes that Slice another turn later.

The average construction grows from 152 at R8 to 21,824 at R14: approximately **×2.29 per round**, deliberately excessive.

## Checks and likely failure

**Power for place:** Cut competes at T3 with **Mrs Mallow** and **Bubble and Squeak**. Mallow doubles two small bodies immediately; Bubble provides combat utility. Cut supplies half a carry each turn, with a delayed feeding return. Its generosity is intentional.

**Play and journey:** buy a functional stomach; choose bodies versus meals; use Dewdrop before finding Cut; then choose concentration, deployed Slices, or Elder’s wider board. T4 offers combinations, T5 distribution/answers, and T6 a finisher.

**Johnny:** Dewdrop and Cut support mixed boards; Frumenty inherits Cut; Slice accepts generic buffs. Purchases cost gold, Created sales pay nothing, and generation advances by turns: no endless loop.

**Most likely failure:** early food still misses too many seats. Ignoring depletion, a T3 four-unit shop has roughly a 16% chance to offer either food source—about 65% across six shops. That does not guarantee Aspic or Elder. Measure the full seat cohort before treating 4,480 as representative.

Validation: in-memory arithmetic checked; no edits, commits, Godot runs or denied actions. Playtesting remains undone.