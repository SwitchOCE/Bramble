# Design review 3: Hunters, Bog folk, Great beasts

On `ideation/c-tribes3`, 7 Nov 2026. Paper only: nothing has been built or played. The owner's words: "It needs to focus on interesting designs and strategic depth." The plan's bar (PLAN.md, Done means 3): each tribe has a signature mechanic Battlegrounds lacks and some economy, isn't a re-skin, and has 12+ units.

## How it was run

Each step was a fresh agent, and none saw another's brief.

1. **Three designers**, one per candidate. They were briefed without the power budget or the costing docs, and asked for slots that matter, because placement is what playtesters liked most and its measured value is falling (`position-test.md`). Drafts are in the session scratchpad, not committed. The Great beasts draft is in `../content/great-beasts.md`.
2. **Two critics**, one on play and depth, one on feel and the owner's notes. Their full reports are `tribes3/critic-play.md` and `tribes3/critic-feel.md`.
3. **A costing reviewer**, using `power-budget.md` and `costing-2.md`'s approach, with a toy lane sim. Report: `costing-3.md`.
4. **Two writers** applied the rulings to the two chosen tribes: `../content/bog-folk.md` and `../content/hunters.md`.

## The verdicts

| Tribe | Play critic | Feel critic | Costing |
|---|---|---|---|
| Bog folk | Strong. The only design that chooses who does the hitting, which neither Battlegrounds nor Galaxy has. Its anti-giant claim fails as written, since a giant kills the 2/6 toad in one swing. | Strong. One picture (a mud patch under their unit, a reed-line to your toad) answers the owner's "I don't understand this design". Not Murlocs. | Mire itself 0 SP, like Taunt. Its payoffs fire about once per front patch per fight. Outliers: Tiddy Mun, Peat Cutter, His Highness, Bridge Toad, Prima Donna |
| Hunters | Workable, strong after rewrites. The most decisions a turn. Poach and Pack are new. Seven keywords; Bait copies Mire; the Laird is the across-targeting rule the position test turned down; Takes could be farmed from refilled slots | Workable, strong after a trim. "A fox claims every kill in its lane" is the best flavour-as-rule. It answers the owner's Swarm and "foxes take a shop card". Name clashes: Tod, "Winter is coming" | Quarry 0 SP, so the value is in the Take: 0.55 Takes a fight per front Hunter. Outliers: the Laird, Low-Water Jack, Brother Wolf, Grizel, Old Brock |
| Great beasts | Workable, on file. Trample and Hide are close to Battlegrounds' retired Overkill and Divine Shield. Charge is Quarry for one attack, and its Room cards are gap text | Workable, on file. Best flavour-to-play table, and Hide is the owner's Shell exactly. But "Charge" is a Hearthstone keyword, Big Ursula repeats Mire, and Old Grazer pays for waiting | Charge, trample and Hide each 0-0.5 SP on even boards. Outliers: Tusker, Bison Elders, Last Aurochs, Ursula |

## Picked: Bog folk and Hunters

**Why** (orchestrator's call; both critics agreed independently):

- **They are complements.** Bog folk pull the enemy's attacks onto you; Hunters send yours into the enemy. Both read the scouted board, from opposite ends of the same lane. The counterplay differs too: moving a unit off a patch frees it from Bog folk, but a Hunter's mark follows it. Walling answers Hunters and feeds Bog folk.
- **Both make the slot matter against a specific enemy board.** That is what the position test found missing: the gain past a simple row rule comes from knowing whom you face.
- **They carry the owner's warmest reactions.** Swarm becomes Pack. "Foxes take a shop card" becomes Poach, made concrete. The glutton is uncapped. The frog prince becomes a playable card. The Mire idea is built on, though the owner was exploring it, not asking for it (02i).
- **Setting.** Hunters are the familiar woodland cast, and Bog folk bring the spooky half of cozy-spooky.
- **Great beasts wait on identity, not quality.** Built beside Hunters, a first attack aimed across blurs with Quarry. Their fix, Headlong (needing room on your own board), should be tried first. They are the obvious next tribe, and their rulings are at the top of `great-beasts.md`.

## Calls that bind all three tribes

1. **One relationship to the lane per tribe**, exclusive across the whole game:
   - Bog folk own *inbound*: the enemy across must attack this unit. The patch stays on the slot.
   - Hunters own *the quarry*: the enemy unit across at the bell is marked, the mark follows it, and Hunters are paid when it faints.
   - Great beasts own *the column*: through the slot across, into what's behind it.

   Built cards' one-shot across effects (Hex, Changeling, Hasty Pudding and others) are unaffected.
2. **A bell step:** a new first phase of Start of Combat, after Mag Pye's "first of all". Both sides lay patches and fix marks at once, from one snapshot.
3. **Targeting precedence:** Mire lock, then the attacker's own text (quarry, Snap, Swoop), then Taunt, then random. A Mired unit can join a Pack attack or Pounce only at the unit that Mired it.
4. **A Take needs the Hunter on the board when its quarry faints;** dying in the same step counts. That is how costing priced it: if dead Hunters counted, Takes would rise 1.3-2.5×. A summon into a marked slot isn't quarry, which closes the refill farm.
5. **Bait leaves Hunters** (the badgers now lend their quarry instead). **Big Ursula loses her forced attack.**

## Main rulings applied

Each writer lists every change and every pick between the critics in the "Review calls" section at the end of its tribe doc. The main ones:

**Bog folk**
- **Kiss no longer pays gold**, which copied Fairies' Shy. His Highness is kissed by Mired deaths, once a fight. On the third kiss he becomes the Prince Restored, a frog: "Mire. Your first spell each turn costs 1 less." So he pays only for an action, never "gold each turn".
- **Toll Toad becomes Bridge Toad.** It pays only if it Mired their highest-Attack unit, which rewards reading the scout.
- **The Peat King raises Peatlings**, not human bog bodies, and steals nothing, so he doesn't overlap the Changeling.
- **Madame Bufo halves the Attack of the enemy she Mires if it kills her**, which makes the anti-giant claim true.
- **Leapfrog Jack becomes Vaulting Hopkin**, away from Battlegrounds' Leapfrogger. Jenny Greenteeth's hook is softened.
- **The Scarecrow's existing `mired` status is renamed `stalled`.**

**Hunters**
- **Three keywords:** Quarry (with Take), Pack and Pounce. Toll and Poach become printed text. Ambush becomes Pounce.
- **The Laird now changes only your own targeting.**
- **Tod Scrapling becomes Little Nip, and Low-Water Jack becomes Old Lutra.** Sable's hook and the wolverine's line are rewritten, and Brother Wolf loses a human legend.
- **Madame Ermeline keeps her name.** She is from the public-domain Reynard fables (orchestrator's call).
- **Costing's numbers are applied.** The Laird stays over budget at 4/6, logged in the doc.

## What the engine must add

Shared by both tribes:

- **The bell step,** above.
- **One targeting-precedence table** in `Combat`.
- **An `on_enemy_death` trigger,** with filters (Bog folk `mired`, Hunters `on_take`).
- **Immediate out-of-turn attacks at a named enemy,** ignoring rows (Gideon, Jenny, Pounce).
- **Scouting and bots.** The next opponent's last board must be shown, and opponent bots must hold carries still between rounds. Without both, every lane card measures as noise. Tray previews and fight replay must draw patches, paw-prints and lines.

**Bog folk:**
- Bog patches as per-side combat slot state, with `maker`. `Combat.hexes` is the nearest model.
- `mired` condition and selector.
- Bitter (combat Attack loss with a floor of 1; aura stacking; once per attacker).
- Snap target override.
- A back-row attack-order flag (Hopkin).
- Mire spread to the slots beside (Prima Donna).
- Halve on kill (Bufo).
- A bell-snapshot condition (Bridge Toad).
- A kiss counter that persists between fights, plus `transform` into a non-pool card.
- A first-spell discount.
- `summon at: nearest_empty` (Peat King).

**Hunters:**
- A `quarry` field on combat units.
- Reach.
- Lend quarry.
- A joint attack for Pack: one exchange, with counter-damage to the leader only.
- Pounce.
- `on_quarry_attacks` (Toll-Bard).
- Poach: an extra next-turn shop slot holding a pool copy, which returns at End of Turn.
- Takes reducing upgrade cost (Ermeline).
- Permanent buffs sent back from a fight event (Grizel).

Full tables are in each tribe doc's "Engine needs" section.

## Not done

- Nothing was played, simmed in the real engine or benched. Costing's sim is a toy, and its biggest guess is that a scouted enemy still stands where it stood last round 65% of the time.
- The two tribes haven't been checked against each other in one lobby beyond the lane ruling.
- No art, and no first-8 slice picked. Both critics' first-8 lists are in their reports.
