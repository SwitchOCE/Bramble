# Mice (The Thimble Guard)

The final brief-7 revision replaces repeating Hit with **half-Attack Ambush**; Bodkin is the full-Attack capstone. Units and implementation notes are in [units.json](units.json), history in [LOG.md](LOG.md), and cross-tribe rules in [SHARED-RULES](../SHARED-RULES.md). Printed stats and tiers are unchanged; this is a utility reduction, not a tribe-wide balance pass.

The owner approved “the smaller first strike that only goes once per fight.” Earlier direction still holds: Mice scale Attack and slot Attack, not their own Health, with a few summons. They use small coordinated openings, then ordinary attacks and trades; they no longer repeatedly kill enemies without retaliation.

## Current rules

| Term | Reminder |
|---|---|
| **Ambush** | Deal half of this unit's Attack (rounded up), with no damage back. Once a fight. |
| **Pile on** | Once a fight, before a neighbour attacks, Ambush its target. |
| **Cousin** | A 2/2 Mouse with Pile on. |
| **Slot buff** | Stays on the slot. Any unit standing there has it. |

**One allowance per unit.** Pile on, Ballista, Catapult and every Master share it. Returns keep a spent use. Golden, windfury, repeated neighbour attacks, multiple Masters or new grants never refresh it. A newly summoned Cousin is a new unit with its own allowance. Zero Attack cannot fire or spend it.

**Damage.** Ambush reads total current Attack, including slots and auras, then rounds the fraction up. It is not an attack: no attacked/attack triggers, Cleave or Overrun. Stiff Upper Lip can save a target. Bodkin changes only pile-on Ambush to full Attack for normal and golden, still once.

**Timing.** Pile-on requests join after the attacker's own triggers and summons. All eligible neighbours request their Ambushes together; amounts are fixed before their own growth rewards. If they kill the target, no normal exchange follows, and the kill is theirs. Otherwise the attacker and defender trade normally. Thorns killing the attacker first prevents neighbours joining.

**Targets.** Pile on uses its neighbour's target. Catapult uses its own ordinary attack target. Ballista and the Master's selected unit pick lowest current Health in either enemy row, ignoring Guard; ties are random.

## Changed cards and connected engines

| Card | Current job |
|---|---|
| Cousin; Needle Page | One small pile-on Ambush, then ordinary trades. |
| Harvest Piper | Same recruit Attack buff; one pile-on Ambush. |
| Shrew Cutpurse | One pile-on Ambush pays its existing next-turn gold. |
| Needle Pikeman | Cannot attack; one pile-on Ambush earns +3 Attack permanently (+6 golden), once. It still retaliates when attacked. |
| Toothpick Ballista | One opening Ambush of the weakest enemy, then normal attacks. |
| Spoon Catapult | Ambush its first ordinary attack target, then trade normally. Windfury gives another ordinary attack, not another Ambush. |
| Fencing Master | Existing permanent Attack reward for each Mouse's first pile-on; no additional damage allowance. |
| Master of Engines | Reinforce only the leftmost back-row unit by +4 Attack this fight (+8 golden), then ask for that unit's one Ambush. Never advance to a second shooter if its use is spent. |
| Dame Bodkin | Improve pile-on Ambush to full Attack; no extra uses. |
| Hedgerow Scout; Thimble Captain; King Speck | Existing summon triggers and counts; every new Cousin now has the smaller one-use opening. |
| Kettle-drummer | Existing ordinary extra attack; does not duplicate any Ambush. |

Whetstone Vole, Grindstone Miller, Dormouse Cook, Standard-bearer, Edgewright and Shrew Harrier keep their other effects. Edgewright still improves slot Attack, including the slot Attack used in Lieutenant’s ordinary row charge.

## The four plans after Ambush

- **Needles:** position Pages and a Pikeman around a sturdy attacker. Their first coordination matters, but later attacks trade normally. Fencing Master still rewards the first pile-on; Pike no longer gets five growths in one fight.
- **Parish:** fill with Mice for Standard-bearer and Cook. Cousins fill gaps and count as Mice. Fresh bodies bring fresh Ambush uses; an existing body's allowance never resets.
- **Ground:** Vole, Miller and Edgewright build slot Attack. A Cousin uses that slot's Attack at half strength for its one Ambush and at full strength in ordinary exchanges.
- **Siege:** Ballista provides one small opening. Master readies one shooter, not the entire back row; Catapults resume normal trades. A shooter whose use was spent by another source cannot fire another Ambush.

The old turn-9 damage totals and win-rate sketches predate this revision and are retired; they are not evidence for current balance. No new whole-game simulations were run.

## Tier check for this revision

- **T1:** Page and Cousin retain early bodies; their utility is now a small seed rather than repeat free damage.
- **T2:** Piper and Cutpurse retain their buff/economy jobs, with a single weaker opening.
- **T3:** Ballista and Pikeman retain their roles but lose the full free strike and repeated growth; the latter may be underpowered pending balance work.
- **T4:** Catapult now trades; Fencing Master retains scaling, with fewer openings to exploit. No printed-stat compensation is added.
- **T5:** Master no longer gives three free full attacks. One reinforced shooter may fall short of this tier's strategic-direction target; that is flagged rather than compensated outside this brief.
- **T6:** Bodkin still improves the opening to full Attack for its one pile-on opening. King and Drummer retain summon/ordinary-attack capstones; each existing unit still has only one Ambush.

Use the [frozen power check](../../../design/power-check.md) and the brief-7 comparison recorded there. Its small-case scores can miss sublethal utility and do not price gold, a fully tribal board, acquisition costs or actual printed stat differences.
