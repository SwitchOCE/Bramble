# Keywords and named terms

Code at `13f44dd9`. Source: every `src/content/*/display.json`, plus the core's own `slot_buff` (`src/core/content/content_set.gd:18-25`). I counted against the 99 units, tokens included, using the real game code in headless Godot (`CardTerms.all_pills` on `ViewAdapter.printed_unit`).

## How a term shows on a card now

- **Card face** (`src/screens/glass_screen.gd:315-356`): art, frame, Attack and Health, and a row of up to **3 round keyword marks** low on the card (`KeywordStyle.CARD_Y` 0.925). With more than 3, the last place says "+N" (`card_terms.gd:62-71`). Each mark is a coloured disc with the term's icon and, if it has one, a number at the lower right ("Fury 1" draws as the flame icon with "1"; `src/glass/keyword_mark.gd:93-128`). Colours and icons come from `assets/glass/keywords.json` by display name (`keyword_style.gd:52-75`).
- **Which terms get a mark** (`card_terms.gd:75-158`):
  - A keyword the unit has, printed or given by an aura, whose name **starts a sentence** of the text, or isn't in the text at all.
  - A numbered mechanic whose name starts a sentence ("Thorns 4", "Order (1)").
  - A numbered mechanic given later (a Fury from Master-at-Arms).
  - The unit's counters ("Medal 2"), and in a fight its uses left.
  - A term only mentioned mid-sentence gets **no mark** ("this eats it", "summon a Hopper", "Hit the enemy").
- **Rules text** shows only in the hover tooltip. Every term in it is drawn as an inline coloured mark with its reminder on hover (`src/glass/keyword_text.gd:18-110`; `glass_parts.gd:294-312`). Reminder lines are listed under the text (`card_terms.gd:163-210`).
- **Player counters and heaps** (Tide, Hopper bonus, Compost) are cream plates above the hero (`src/screens/glass_counters.gd`). Slot buffs and the Guard post are a pill at the foot of the unit standing on that slot (`glass_screen.gd:420-426`, `slot_info` `:383-400`).

Columns: **Printed** = cards whose data carries the mechanic. **Mark** = cards that draw a mark for it on the face (unbuffed). **In text** = cards whose text names it. **Kind**: **K** = a true keyword that changes how a unit fights or is targeted; **T** = a trigger or ability with a name; **C** = a counter, heap or uses; **R** = a reminder or reference term only.

## Core keywords (`src/content/shared/display.json`, `src/core/mechanics/keywords/`)

| Term (id) | Printed / Mark / In text | What it does (code) | Shows now | Kind |
|---|---|---|---|---|
| **Guard** (`taunt`) | 5 / 5 / 6 (Hedge Knight, Gate Warden, Husk Sentry, Hawthorn Warden, Lone Hawthorn; text also on Grenadier Guard). Also given by a Guard post | Enemies must attack it first, among the row that can be attacked (`taunt.gd`; target pick `combat.gd:331-356`). Sortie ignores a front-row Guard | Mark (shield icon, ward family) | **K** (Taunt) |
| **Attacks twice** (`windfury`) | 1 / 1 / 1 (Shrew Harrier). Given by Kettle-drummer (back row) and Brigadier (Decorated Pigeons) as an aura | 2 attacks a turn, back to back. Golden stays 2 (`windfury.gd`) | Mark; on a unit that gets it from an aura too | **K** (Windfury) |
| **Cleave** (`cleave`) | 0 / 0 / 1. Flying Ace gives itself Cleave when Decorated (`flying_ace.gd:28`) | Also damages one random unit next to the target, in its row (`cleave.gd`) | Mark only while it has it (aura keyword) | **K** (Cleave) |
| **Divine Shield** | 0 / 0 / 0 | First damage prevented (`divine_shield.gd`) | Unused by any card | **K**, unused |
| **Reborn** | 0 / 0 / 0 | Returns with 1 Health once (`reborn.gd`) | Unused | **K**, unused |
| **Venomous** | 0 / 0 / 0 | Destroys the first unit it damages (`venomous.gd`) | Unused | **K**, unused |
| **Stealth** | 0 / 0 / 0 | Can't be attacked until it attacks or deals damage (`stealth.gd`) | Unused | **K**, unused |
| **Slot buff** (`slot_buff`, core) | slots, not cards. Named in 8 cards' reminders | Stays on the slot; any unit standing there has it | Pill "+2/+2" at the foot of the unit on the slot | C |

## Badgers (`src/content/badger/display.json`)

| Term | Printed / Mark / In text | What it does | Shows now | Kind |
|---|---|---|---|---|
| **Fury N** | 7 / 7 / 12. Given by Master-at-Arms (for good), Dame (Knights, aura) and Sword-heir (this fight). Doubled or tripled by Marshal | Whenever it attacks or is attacked: +N Attack × (1 + outnumbered count), this fight (`badger_rules.gd:55-65`) | Mark "Fury N" with flame icon. A given Fury shows the summed number | **K**: a combat trigger that changes the fight's numbers (a rage-style keyword) |
| **Grudge** | 3 / 3 / 4 (Brock Cub, Shield-bearer, Armsbearer; Grudge-keeper names it). Knights get it from Grudge-keeper | After each fight, alive or dead: +N×count Attack, +N×(count+1) Health, permanently (`grudge_pay.gd`) | Mark (no number shown, because the text has no number). The reminder is fixed at "+1", even on a golden | T (after-fight growth) |
| **Squire** | 7 / 7 / 7 | In the back row, not counted for Outnumbered (`squire.gd`) | Mark (pawn icon) | R / counting rule. It changes no fighting |
| **Lends** | 2 / 2 / 2 (Shield-bearer: Health, Armsbearer: Attack) | Units in front get its Health or Attack as an aura | Mark | T (aura) |
| **Overrun** | 2 / 2 / 4. Given by Greatsword Bearer (units in front) and Dame (Knights) | Extra damage from its attack carries on to another enemy (`overrun.gd`) | Mark, also on a unit that gets it from an aura | **K** (Cleave-like trample) |
| **Outnumbered** | 0 / 0 / 1 (named in 13 cards' reminders) | Counted at fight start: enemy counted units beyond yours (`combat.gd:203-207`) | No mark. A reminder line, and in a fight the hover adds "Outnumbered by N." (`fight_screen.gd:454-466`) | R |

## Locusts (`src/content/locust/display.json`)

| Term | Printed / Mark / In text | What it does | Shows now | Kind |
|---|---|---|---|---|
| **Molt** | 2 / 2 / 3 (Husk Sentry, Wheat Raider; Skin-shedder gives charges) | The first death each fight, it returns as a plain copy with 1 Health, then +2/+2 permanently (`molt.gd`) | Mark. Dimmed in a fight once used | **K** (Reborn-like) |
| **Tide** (`locust_tide`, counter) / **Tide +N** (3 trigger ids) | 3 cards (Prophet, Famine-caller, Swarm Lord) / 0 marks / 3 | A player counter: your Locusts have +Tide Attack for the rest of the game | Counter plate above the hero. On cards, only inline text. No mark ("Tide +1" doesn't start a sentence) | C |
| **Hopper bonus** | counter / 0 / 0 | Your Hoppers have +N/+N | Counter plate | C |
| **Hopper** (5 ids) | 5 cards / 0 / 5 | Token reference: "A 2/2 Locust; waits for a slot" | Inline mark and reminder only | R (token) |
| **Eat** (gorge, glut) | 2 / 0 / 2 | Sold unit's stats go to this; the sold unit's death effect triggers | Inline only ("eats" mid-sentence → no mark) | T (shop) |
| Hidden (`swarm`, `shed`, death-damage, `glean`, `drum`, `veteran`, `plague`, `dirge`) | — | card-specific rules | Not shown as terms | — |

## Mice (`src/content/mouse/display.json`)

| Term | Printed / Mark / In text | What it does | Shows now | Kind |
|---|---|---|---|---|
| **Pile on** | 7 / 7 / 7 (incl. Cousin token) | Whenever a neighbour (next to, in front or behind) attacks, this hits the target first (`pile_on.gd`) | Mark | **K**: joins attacks, changes damage and kills |
| **Hit** | 0 / 0 / 4 (Ballista, Catapult, Engines, Bodkin) | Deal this unit's Attack as damage; takes none back. Not an attack | Inline only | R (an action word; the effect is on the card) |
| **Cousin** | token ref / 0 / 3 | "A 2/2 Mouse with Pile on" | Inline only | R (token) |
| **Gains left this fight** (`mouse_pikeman_gains`) | uses / 0 / 0 | Needle Pikeman's growth left (5 a fight) | In a fight, a uses pill on the card (`fight_replay.gd:556` adds `uses` to counters) | C |
| Hidden (`scout`, `captain`, `king_speck`, `ballista`, `catapult`, `engines`, `whetstone`, `grindstone`, `edgewright`, `piper`, `cook`, `cutpurse`, `pikeman`, `fencing_master`, `standard_bearer`, `bodkin`, `kettle_drummer`) | — | — | Not shown | — |

## Pigeons (`src/content/pigeon/display.json`)

| Term | Printed / Mark / In text | What it does | Shows now | Kind |
|---|---|---|---|---|
| **Order (N)** (2 ids) | 2 / 2 / 2 (Lance Corporal, Grenadier Guard) | Once a turn, pay N gold to use. An activated shop ability | Mark "Order (1)", plus an ability button on the board card (`recruit_buttons.gd`) | T (shop ability) |
| **Guard post** | slot / 0 / 1 | The slot gives Guard; Reserve fills it first (`guard_post.gd`) | Slot pill under the unit | K via Guard (a slot keyword) |
| **Reserve** | 1 / 1 / 2 (Territorial; Colonel gives it to the hand) | Steps from the hand into a slot where a friend died (`reserve.gd`; `fight_arrivals.gd`) | Mark | **K** (a fight-entry keyword, Reborn-adjacent) |
| **Sortie** | 1 / 1 / 2 (Wing Commander; Squadron Leader gives it to units in front) | Attacks the enemy back row while it has units; ignores a front-row Guard (`sortie.gd`) | Mark | **K** (targeting) |
| **Stiff Upper Lip** | 0 / 0 / 2. Old Campaigner when Decorated; Field Marshal gives it to Decorated Pigeons | The first lethal damage each fight leaves it on 1 Health (`stiff_upper_lip.gd`) | Mark while it has it (aura keyword) | **K** (Divine-Shield-like) |
| **Medal** | counter / (pill when it has some) / 4 | A count on the unit; each is +2/+2 permanently (`medals.gd`) | Counter pill "Medal N" on the card (`card_terms.gd:149-157`) | C |
| **Decorated** | 0 / 0 / 4 | 3+ Medals | Inline only. No mark of its own; read from the Medal number | R (state) |
| **Joins the fight** | 0 / 0 / 1 (Bugler) | Is summoned or steps in from Reserve | Inline only | R |
| **Private** | token / 0 / 1 | "A 2/2 Pigeon" | Inline only | R (token) |
| **Privates left**, **Left this fight** | uses / 0 / 0 | Recruiting Sergeant's and Padre's uses this fight | Uses pill in a fight | C |
| Hidden (13 card-specific ids) | — | — | Not shown | — |

## Thorns / Briars (`src/content/thorn/display.json`)

| Term | Printed / Mark / In text | What it does | Shows now | Kind |
|---|---|---|---|---|
| **Thorns N** | 3 / 3 / 4 (Holly Knight gives it to front-row Briars) | When attacked, deal N to the attacker first (`thorns.gd`) | Mark "Thorns N" | **K** (retaliation; changes fights) |
| **Root N** | 3 / 3 / 4 (The Old Hedge gives Root 1 to Briars) | The first death each fight: spend N Compost to return it at full Health (`root.gd`) | Mark "Root N". Dimmed once used | **K** (Reborn-like) |
| **Grow N** | 1 / 1 / 3 (Ivy Climber and Briar King give it) | Start of fight: +N/+N for every 2 Compost (`grow.gd`) | Mark "Grow N" | T (start-of-fight buff) |
| **Seed** | 3 / 3 / 3 | When this dies, add a copy to your Compost (2 on a golden) | Mark | T (death effect) |
| **Bury** (2 ids) | 3 / 3 / 3 | Once a turn, put a shop unit in your Compost, then do the rest | Mark, and a shop ability | T (shop ability) |
| **Compost** (heap) | heap / 0 / 5 | Your heap of sold bought units | Counter plate; clicking opens the Compost panel (`glass_counters.gd:29-41`, `src/screens/compost/compost_panel.gd`) | C |
| **Pip** | token ref / 0 / 1 | "A 3/3 Briar with Seed" | Inline only | R (token) |
| **Copy from the Compost** (2 ids) | 2 / 0 / 0 (Old Stump, Elder Mother) | Plain copies for this fight | Reminder line only. Its name never appears in the text | R |
| Hidden (`bury_twice`, `sweetbriar`, `sapling`, `ivy`, `holly_knight`, `briar_king`, `old_hedge`, `lone_hawthorn`, `coppicer`) | — | — | Not shown | — |

## Summary

- **True fight keywords in use (11):** Guard, Attacks twice, Cleave (only given by an aura), Overrun, Pile on, Molt, Reserve, Sortie, Stiff Upper Lip (only given by an aura), Thorns and Root. Fury is a fight-time growth keyword that changes combat numbers, so it fits here too.
- **Defined but unused:** Divine Shield, Reborn, Venomous and Stealth.
- **Counters and heaps:** Tide, Hopper bonus, Compost (plates); Medal (pill on the unit); Slot buff and Guard post (slot pills); and three uses counters (pills in a fight).
- **Triggers with names:** Grudge, Lends, Grow, Seed, Bury, Order and Eat.
- **Reminder or reference terms with no mark:** Outnumbered, Hit, Decorated, Joins the fight, Squire (it has a mark but doesn't change fighting), the tokens (Hopper, Cousin, Private, Pip) and Copy from the Compost.
- **58 of 99 cards show no mark at all.** Their whole effect is in hover text, and so are terms named mid-sentence: Eat, Hit, Tide +N, Hopper. Hidden display entries (per-card rules) never show as terms.
