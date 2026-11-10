# Breaker report: Hunters, spells, heroes

Snapshot: `/home/alex/code/Bramble-ideation-rules` (ideation/design-hard-rules), preset B. Everything below is from reading code and data; nothing was run. `q` = one enemy unit's stats, `E` = an enemy board's total.

## Top findings (worst first)

1. **Spell scaling is a repeatable multiplier (rule 1 break, system level).** Rulebook 5.2.9a / `flat_stat_scaling.gd`: every printed +1 from a spell becomes 10% of the recipient's *current* stat. Pinch of Dust is x1.1 for 1 gold; Last Orders is +5% per gold with no ceiling. Gold banks without limit, so one unit grows about x1.4 a turn from spells alone, x2+ with an economy.
2. **Harvest Supper compounds a whole tribe.** Live rule drops the +3/+3 ceiling; each cast adds 10% of your board average, which includes earlier Suppers. About x1.1 a turn on every unit of the tribe for 3 gold.
3. **Young Brock + Stone Soup + Frumenty is an in-turn exponential loop.** Frumenty that ate Young Brock inherits sold Hunters; Soup gives shop units a fifth of Frumenty; each buy-and-sell is x1.2. Three or four sales a turn is about x2 a turn.
4. **Young Brock turns Rings into permanent stats.** He reads the sold Hunter's stats including the Ring it stands on. Each 2-gold sale adds the whole Ring again. Linear, but it rides the Fairies' Ring growth.
5. **Madame Ermeline stacks and needs no kill.** Each Ermeline pays 1.75x the biggest marked enemy every turn, win or lose. Three of them with Isegrim is 5.25x the lobby's biggest unit per turn.
6. **Take and Pack payouts add up to 2 enemy boards per won fight** under best play (Glutton x2, Lodger, Laird). Not exponential, since it reads the enemy, but a Hunter who wins twice cannot be caught by a linear board. Rates were fitted to bot play.
7. **Hunter mirror is a two-player exponential.** Each side's trophies read stats the other side took from them; Russet copies the buffs straight back. About x2 per fight when two Hunter players meet repeatedly.
8. **Rule 2 as written kills the whole Hunter tribe** ("gain a share of a unit's current stats every turn is multiplication"). It needs to say *your own* stats.

## Table

| Card | Tier | Growth class | Verdict | Reason |
|---|---|---|---|---|
| **Hunters** | | | | |
| Little Nip | 1 | linear in enemy size | fine | 5/6 q per Take; one Take per fight |
| Wick | 1 | linear in enemy size | fine | 7/12 q per pack kill joined |
| Young Brock | 1 | flat alone; exponential in loop | **rule break (combo)** | reads current stats incl. Rings and Soup bonus |
| Fox Cub, Fox Notary | 1 | flat | fine | combat-only |
| Mistress Russet | 2 | flat (copies) | power fantasy | copy of enemy unit with 5/6 buffs; triple engine with Laird |
| Sable | 2 | linear in enemy size | fine | strike reads frozen Attack |
| The Lane-Bard | 2 | linear gold | fine, rate watch | up to 2 gold a turn each at tier 2; stacks |
| Brother Wolf, Sett Warden, Weasel Second | 3 | flat | fine | enablers |
| The Lodger | 3 | linear in enemy size | fine | 9/8 q per Take beside it |
| Old Lutra | 3 | linear in enemy size | fine | reach version of Nip |
| Grey Agnes, Old Brock, Stoat Captain | 4 | flat | fine | enablers / vanilla |
| Madame Ermeline | 4 | linear in enemy's biggest | **degenerate** | stacks, pays on a loss |
| Grizel | 5 | linear in enemy size | power fantasy, rate flag | 7/12 q to every attacker per pack kill, per Grizel |
| The Mountain Glutton | 5 | linear in enemy size | power fantasy, rate flag | 9/8 q on every Take, stacks |
| Old Badger, Ermine Duellist | 5 | flat | fine | vanilla / Quick |
| Old Isegrim | 6 | flat | fine | targeting; makes Ermeline's Pelts the biggest enemy |
| Laird of the Sett | 6 | flat x2 (x3 golden) | power fantasy | Lairds don't stack while `pass3_loop_guards` is on |
| **Spells** | | | | |
| Pinch of Dust, Elderflower Cordial, Cold Frame, Bread from the Back, Stand Behind Me | 1-3 | **exponential** (via 5.2.9a) | **rule break (system)** | each cast is +10-30% of current stats |
| Last Orders | 5 | **exponential** | **rule break (system)** | +5% of the unit per gold, uncapped |
| Beltane Bonfire | 6 | **exponential** | **rule break (system)** | +2.5% per gold to a row; tripled by Pipistrelle Echo |
| Harvest Supper | 3 | **exponential** (~x1.1) | **rule break** | uncapped, reads its own earlier bonus |
| Golden Egg | - | one-shot x3 | power fantasy | once per Bird; allowed by rule 1 |
| Pelt | - | fixed | fine | exempt from spell scaling |
| Squirrel Away, Acorn, Stash, Great Hoard | 1-2 | one-shot gold gain | fine | 9 Acorns become 16 gold, then stops |
| Market Day | 4 | flat | fine, enabler | makes sale loops cost 1 gold each |
| Market Stall | 4 | flat | fine | capped at 2 |
| Hiring Fair, Triple Reward, Shake the Tree, A Leg Up | - | flat | fine | |
| Hungry Gap, Rainy Day | 1-2 | flat gold | fine | +1 or +2 |
| Spore Cloud, Boundary Stone, Horseshoe | 2-4 | linear count | fine here | add one Ring; Ring size is the Fairies' question |
| sample_* | - | - | skipped | sample cards |
| **Heroes** | | | | |
| Dame Farthing | | linear gold, capped +5 | fine | cap stated |
| Brother Bracken | | flat x1.5 in combat | fine, watch | +50% on five units, not permanent |
| Old Mother Mousewife | | flat | fine | Mouse is 10% x tier of board average |
| March Hare, Jill, Hob, Pipkin, Hoolet, Wren | | flat | fine | tempo or targeting; Jill nets at most +1 gold a turn |

## Detail

### 1. Spell and hero percent scaling (rule 1 break)

Rule (5.2.9a): "Each positive printed point becomes 10% of the recipient's corresponding stat, with the printed gain as a minimum." Code: `FlatStatScaling.scaled_amount = max(flat, stat * 10% * flat)`.

- Pinch of Dust "Give a unit +1/+1" (1 gold) = x1.10.
- Elderflower Cordial (1 gold) = +10%/+20%.
- Cold Frame (2 gold) = +30%/+30% after 2 turns.
- Last Orders "Spend all your gold. Give a unit +1/+1 for every 2 spent" = +5% per gold. 20 gold doubles the unit; a Great Hoard (16) plus a turn's income is x2.3.
- Beltane Bonfire "row +1/+1 for every 4 spent" = +2.5% per gold on up to 4 units.

**Best use.** One carry, every stat spell on it. A refresh (1 gold) shows one spell; about 8 of 18 pool spells are stat spells. Roughly 4 gold per +15%, so 10 gold a turn is about x1.4 a turn: `S(t) = S0 * 1.4^t`. Exponential.

**Combos.** Pipistrelle Echo (echo re-runs the spell on both neighbours with the same amount, `recruit_extras.gd`): Last Orders hits three units; Bonfire aimed at Echo buffs the same row three times. Gold banks with no cap, so Dame Farthing (+5 a turn), Lane-Bards (+2 each), Great Hoard and Cricket Busker all feed it. Save three turns, cast Last Orders for 30: x2.5 on three units.

**Fantasy or degenerate.** Degenerate. No assembly: tier 1 spells do it. It stacks on top of every other engine.

**Frequency.** Every game.

**Change.** Scale by shop tier, not by the recipient: each printed point = +1 per tier (Dust at tier 6 = +6/+6). Spells stay worth buying late, growth is linear.

### 2. Harvest Supper (rule break)

Card JSON: "Pick a unit. Your units of its tribe, now and later, gain +1/+1, up to +3/+3. Once a turn." Live rule removes the ceiling and adds 10% of the lower of the board's average Attack and Health. The average includes the tribe bonus already given, so `bonus(t+1) = bonus(t) + 0.1 * (avg + bonus(t))`: about x1.1 a turn on seven units, for 3 gold. Frequency: any committed tribe that sees it (9 copies, tier 3), most games. **Change:** put the ceiling back, or use the tier rule above (+1 per tier, once a turn). The JSON text is also stale.

### 3. Young Brock (rule break in combo; one-line fix)

"When a Hunter beside this is sold: gain its stats permanently." Code: gains `sold.attack - sold.tribe_attack`, which still includes aura (Rings) and any Soup bonus locked in at purchase.

**Loop A, exponential.** Pieces: Stone Soup (tier 1, "Shop units gain a fifth of your biggest Ooze's stats"), Frumenty (tier 4, "has the text of its last meal") fed a Young Brock, and Hunters in the shop. `Pass3Hunters.entries` honours borrowed text, and Frumenty's lend filter doesn't block it. Buy a Hunter (it carries +F/5 permanently), sell it beside Frumenty: `F -> 1.2F + base`. The shop bonus updates live. At 3 gold per cycle with a refresh, three sales a turn is x1.7; with Market Day (net 1 gold per cycle) it is x2.5 or more. Exponential inside one turn.
Frequency: Oozes and Hunters share a lobby 4 times in 6; three cheap pieces (15, 15 and 11 copies). A player who knows it finds it in perhaps 1 game in 6. Once running, nothing linear beats it.

**Loop B, linear.** A Hunter on a slot with Rings worth R, sold beside Brock, gives +R permanently, and the Ring stays. 2 gold per +R. With Nan Toadstool double-ringing and the Fairy Monarch tripling Ring size, R is large.

**Change (keeps the core):** Brock inherits the sold Hunter's printed stats plus its trophies and spell buffs, not slot auras or shop bonuses. The fantasy, passing a lifetime of trophies to an heir, is untouched.

### 4. Madame Ermeline (degenerate; change one piece)

"After each fight: get three Pelts of your biggest quarry." Pelt = 7/12 of the quarry's bell stats, permanent, on any Hunter. Paid "killed or not", even if she fainted, and once per Ermeline.

- One Ermeline: +1.75 q a turn, guaranteed. With Old Isegrim or Old Lutra marking the biggest enemy, 1.75x their carry.
- Three Ermelines (or a Frumenty copy): 5.25x the biggest enemy unit per turn. Golden: 3.5x each.
- Class: linear in enemy size. Never needs to win.

Assembly is one card plus any quarry Hunter. It doesn't auto-win, but stacked it out-grows a normal board without fighting well. **Change:** your Ermelines pay once per fight (the strongest), keep three Pelts. Optional: Pelts only of a quarry you took.

### 5. Glutton, Grizel and the Take economy (power fantasy; rate flag)

- Glutton: "Pack. After each Take: gain nine eighths of the quarry's stats permanently."
- Grizel: "Pack. After your pack kills: its attackers gain seven twelfths of the target's stats permanently."
- Laird: "Your 'Take:' text triggers twice."

**Best board:** Nip, Sable, Lutra, Lodger between two takers, two Gluttons, Laird. Three Takes: takers 3 x 5/3 q, Gluttons 2 x 3 x 9/8 q, Lodger 2 x 9/8 q = **14 q per fight, twice the enemy board**. Golden pieces push it past 4 boards. A quarry only has to die while its Hunter is alive, so a winning board always collects.

**Class:** `H(t+1) = H(t) + 2E(t)`. Linear in the lobby, not self-feeding. If the lobby grows x1.3 a turn, the Hunter settles near 8 boards' worth.

**Verdict:** keep. It takes tier 5-6 pieces (7 and 5 copies) and has to win fights first; perhaps 1 game in 10. But once it has won twice, no linear board comes back. If that plays as unbeatable, the smallest dial is Glutton paying on the first Take each fight, or a second Glutton adding nothing.

### 6. Russet + Laird (power fantasy)

Russet: "Quarry. Take: your next shop has a copy, with five sixths of its buffs." Laird repeats it: 2 copies (3 with golden Laird). Golden Laird + Russet is a guaranteed triple of any enemy unit at or below your tier each turn, with 2.5x its buffs, plus a Triple Reward. Costs 9 gold and three pool copies. Needs a golden tier 6; rare (well under 1 game in 20). Keep.

### 7. Golden Egg (power fantasy, allowed)

"Triple a Bird's stats. Once per Bird." One-shot per recipient, which rule 1 permits. Click Beetle or a golden Goose gives two Eggs for two Birds. Its danger is the Birds' homecoming multiplier (x2.5 a trip at B), which belongs to the Birds review.

## Rule wording problems

1. **Rule 2 wrongly kills Hunters.** "Gain a share of a unit's current stats every turn is multiplication" covers Nip, Sable, Lutra, Wick, Grizel, Lodger, Glutton, Ermeline, Russet and Young Brock. Reword: "a share of stats *on your own side, or of any number your own earlier gains increased*". Add a named class: "tracking growth (a share of an enemy's stats) is allowed."
2. **"One-shot" needs a scope.** A spell is one-shot per cast and "when sold" is one-shot per sale, yet both repeat freely. Say: one-shot means at most once per game per recipient (Golden Egg is the model).
3. **"States a cap" must mean a lifetime cap.** A per-turn cap ("up to 6 gold" on Charcoal Burner, by its text x1.3 a turn; "once a turn" on Supper) still compounds.
4. **System dials aren't cards.** Rule 1 says "no card, and no combination of cards". 5.2.9a breaks it from the rulebook. Add "or system rule".
5. **Layer laundering.** Nothing stops a card reading temporary or positional stats (Rings, Soup's shop bonus) and making them permanent. Add: inherit, copy and "gain its stats" effects read printed stats plus permanent buffs only, and no card's gain may read a number its own gain raised through the shop or another card.
6. **Two-player loops.** Reading enemy stats is safe only against an independent enemy. Two Hunter players facing each other repeatedly (final two) grow about x2 a fight, and Russet copies the buffs back. Low frequency and the health clock ends it in 2-4 fights. Owner call: accept, or have trophies ignore stats the quarry itself gained from trophies.
7. **Rule 2's "fixed amount each turn" has no room for amounts set by the opponent.** Say "fixed, or set by the enemy's board".
