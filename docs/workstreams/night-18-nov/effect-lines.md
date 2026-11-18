# Effect-line audit — 18 November 2026

PR 134 follow-up, based on `origin/night/tooltip-no-alt` at `74c25a0b`. Every row below was checked against the [owner’s clarified rule](../../design/owner-notes/2026-11-18b-one-effect-per-line.md). These split decisions are implementation judgments, not additional owner quotations.

## Decision and coverage

Effect boundaries are explicit `\n` separators in the content’s display text. The renderer preserves them and normalizes CRLF; punctuation does not create boundaries. Only the existing separator spaces changed, never words, punctuation, numbers, mechanics or parameters. A continuation, amount, condition, restriction or explanation stays with its effect. An additional independent keyword, trigger or global modifier starts a new group, even when it mentions the preceding keyword.

The five tribal files contain **136 authored text entries: 99 normal `text` fields and 37 custom `golden_text` fields**. The runtime contains **103 card IDs**: those 99 tribal cards, three fallback spells and Triple Reward. The tables cover **all 206 resolved normal/golden forms**, including goldens that inherit their text and only change numbers. Empty token text is included.

`<br>` marks an authored effect boundary, not natural wrapping at a window’s width. Each normal and golden cell is the final string from `Unit.view()` / `ViewAdapter`, passed through the renderer. Group counts are normal/golden. The wording and every sentence were reviewed in both forms; rows with one group were checked too. No judgment remains unresolved.

## Badgers

Source: [display text](../../../src/content/badger/units.json).

| Card | Normal groups | Golden groups | Groups | Review |
|---|---|---|---:|---|
| Brock Cub (`brock-cub`) | Fury 1.<br>Grudge. | Fury 2.<br>Grudge gives +2/+2 for each. | 2/2 | Independent effects separated. |
| Hedge Knight (`hedge-knight`) | Guard.<br>Fury 1. | Guard.<br>Fury 2. | 2/2 | Independent effects separated. |
| Sett Shield-bearer (`sett-shield-bearer`) | Squire.<br>Grudge.<br>Lends its Health to the units in front of it. | Squire.<br>Grudge gives +2/+2 for each.<br>Lends its Health to the units in front of it. | 3/3 | Independent effects separated. |
| Armsbearer (`armsbearer`) | Squire.<br>Grudge.<br>Lends its Attack to the units in front of it. | Squire.<br>Grudge gives +2/+2 for each.<br>Lends its Attack to the units in front of it. | 3/3 | Independent effects separated. |
| Relic Seeker (`relic-seeker`) | Squire.<br>After each fight, gain 1 gold for every 2 units you were outnumbered by. | Squire.<br>After each fight, gain 2 gold for every 2 units you were outnumbered by. | 2/2 | Independent effects separated. |
| Gate Warden (`gate-warden`) | Guard.<br>Whenever this is attacked, gain +2/+2 permanently. | Guard.<br>Whenever this is attacked, gain +4/+4 permanently. | 2/2 | Independent effects separated. |
| Grudge-keeper (`grudge-keeper`) | Fury 1.<br>Your Knights have Grudge. | Fury 2.<br>Your Knights have Grudge. The Grudge it gives is +2/+2 for each. | 2/2 | Golden amount explains the granted Grudge; Fury is separate. |
| Hedge Lancer (`hedge-lancer`) | Fury 1.<br>Start of fight: This attacks immediately and takes no damage. | Fury 2.<br>Start of fight: This attacks immediately and takes no damage. | 2/2 | Independent effects separated. |
| Sword-heir (`sword-heir`) | Squire.<br>After a unit in front of this dies, gain its Attack, Health and Fury this fight. | Squire.<br>After a unit in front of this dies, gain double its Attack and Health, and its Fury, this fight. | 2/2 | Independent effects separated. |
| Herald of the Charge (`herald-of-the-charge`) | Squire.<br>Start of fight: The units in front of this attack immediately. | Squire.<br>Start of fight: The units in front of this attack immediately. | 2/2 | Independent effects separated. |
| Greatsword Bearer (`greatsword-bearer`) | Squire.<br>The units in front of this have Overrun. | Squire.<br>The units in front of this have Overrun. | 2/2 | Independent effects separated. |
| Sett Sexton (`sett-sexton`) | Squire.<br>After another friendly Badger dies, your Badgers gain +2 Fury this fight. | Squire.<br>After another friendly Badger dies, your Badgers gain +4 Fury this fight. | 2/2 | Independent effects separated. |
| Master-at-Arms (`master-at-arms`) | When played: Give a unit +1 Fury. | When played: Give a unit +2 Fury. | 1/1 | One effect. |
| Ironhide Berserker (`ironhide-berserker`) | Fury 3.<br>Overrun. | Fury 6.<br>Overrun. | 2/2 | Independent effects separated. |
| Dame of the Old Sett (`dame-of-the-old-sett`) | Your Knights have +2 Fury and Overrun. | Your Knights have +4 Fury and Overrun. | 1/1 | One effect. |
| Tourney Champion (`tourney-champion`) | Fury 2.<br>Start of fight: This attacks the enemy with the most Attack and takes no damage. | Fury 4.<br>Start of fight: This attacks the enemy with the most Attack and takes no damage. | 2/2 | Independent effects separated. |
| The Oakfeller (`the-oakfeller`) | Fury 3.<br>Overrun.<br>After this attacks and kills a unit, it attacks once more. | Fury 6.<br>Overrun.<br>After this attacks and kills a unit, it attacks once more. | 3/3 | Independent effects separated. |
| Old Brock, Last of His Sett (`old-brock`) | After a friendly unit dies, gain its Attack and Health this fight. | After a friendly unit dies, gain double its Attack and Health this fight. | 1/1 | One effect. |
| Marshal of the Red Mist (`marshal-of-the-red-mist`) | Your units' Fury is doubled. | Your units' Fury is tripled. | 1/1 | One effect. |

## Mice

Source: [display text](../../../src/content/mouse/units.json).

| Card | Normal groups | Golden groups | Groups | Review |
|---|---|---|---:|---|
| Cousin (`cousin`) | Pile on. | Pile on. | 1/1 | One effect. |
| Needle Page (`needle-page`) | Pile on. | Pile on. | 1/1 | One effect. |
| Hedgerow Scout (`hedgerow-scout`) | Whenever this attacks, summon a Cousin. | Whenever this attacks, summon 2 Cousins. | 1/1 | One effect. |
| Harvest Piper (`harvest-piper`) | Pile on.<br>When played: Give your other Mice +2 Attack. | Pile on.<br>When played: Give your other Mice +4 Attack. | 2/2 | Independent effects separated. |
| Whetstone Vole (`whetstone-vole`) | At the end of your turn, give this slot +3 Attack. | At the end of your turn, give this slot +6 Attack. | 1/1 | One effect. |
| Shrew Cutpurse (`shrew-cutpurse`) | Pile on.<br>The first time this piles on each fight, gain 1 gold. | Pile on.<br>The first time this piles on each fight, gain 2 gold. | 2/2 | Independent effects separated. |
| Thimble Captain (`thimble-captain`) | Whenever a neighbour attacks, summon a Cousin. | Whenever a neighbour attacks, summon 2 Cousins. | 1/1 | One effect. |
| Needle Pikeman (`needle-pikeman`) | Pile on.<br>Can't attack.<br>After this piles on, it gains +3 Attack permanently (5 a fight). | Pile on.<br>Can't attack.<br>After this piles on, it gains +6 Attack permanently (5 a fight). | 3/3 | Pile on, attack restriction and permanent-growth trigger are separate. |
| Toothpick Ballista (`toothpick-ballista`) | Start of fight: Hit the enemy with the least Health. | Start of fight: Hit the enemy with the least Health twice, choosing again. | 1/1 | One effect. |
| Shrew Harrier (`shrew-harrier`) | Attacks twice. | Attacks twice. | 1/1 | One effect. |
| Spoon Catapult (`spoon-catapult`) | Instead of attacking, Hit the enemy with the least Health. | Instead of attacking, Hit the enemy with the least Health twice, choosing again. | 1/1 | One effect. |
| Grindstone Miller (`grindstone-miller`) | At the end of your turn, give this slot and its neighbours +2 Attack. | At the end of your turn, give this slot and its neighbours +4 Attack. | 1/1 | One effect. |
| Dormouse Cook (`dormouse-cook`) | At the end of your turn, if your board is full of Mice, give them +3 Attack. | At the end of your turn, if your board is full of Mice, give them +6 Attack. | 1/1 | One effect. |
| Fencing Master (`fencing-master`) | Pile on.<br>The first time each of your Mice piles on in a fight, it gains +3 Attack permanently. | Pile on.<br>The first time each of your Mice piles on in a fight, it gains +6 Attack permanently. | 2/2 | Independent effects separated. |
| Parish Standard-bearer (`parish-standard-bearer`) | Your Mice have +2 Attack for each Mouse you have. | Your Mice have +4 Attack for each Mouse you have. | 1/1 | One effect. |
| Master of Engines (`master-of-engines`) | Start of fight: Your back-row units each Hit the enemy with the least Health. | Start of fight: Your back-row units each Hit the enemy with the least Health twice, choosing again. | 1/1 | One effect. |
| Edgewright (`edgewright`) | Start of fight: Your slots give double Attack this fight. | Start of fight: Your slots give triple Attack this fight. | 1/1 | One effect. |
| King Speck (`king-speck`) | Whenever this attacks, fill your empty slots with Cousins. | Whenever this attacks, fill your empty slots with golden Cousins (4/4). | 1/1 | One effect. |
| Dame Bodkin (`dame-bodkin`) | Pile on.<br>Pile-on hits deal double damage. | Pile on.<br>Pile-on hits deal triple damage. | 2/2 | Global pile-on multiplier is separate from this card’s Pile on. |
| Kettle-drummer (`kettle-drummer`) | Your back-row units attack twice. | Your back-row units attack twice. | 1/1 | One effect. |

## Pigeons

Source: [display text](../../../src/content/pigeon/units.json).

| Card | Normal groups | Golden groups | Groups | Review |
|---|---|---|---:|---|
| Private (`private`) | — (no rules text) | — (no rules text) | 0/0 | No rules text. |
| Sentry (`sentry`) | At the end of your turn, give this slot +2/+2. | At the end of your turn, give this slot +4/+4. | 1/1 | One effect. |
| Territorial (`territorial`) | Reserve. | Reserve. | 1/1 | One effect. |
| Old Campaigner (`old-campaigner`) | After each fight, earn a Medal. Earn 2 if this survived.<br>Decorated: Stiff Upper Lip. | After each fight, earn 2 Medals. Earn 4 if this survived.<br>Decorated: Stiff Upper Lip. | 2/2 | Survival amount qualifies Medal income; Decorated is separate. |
| Recruiting Sergeant (`recruiting-sergeant`) | When a slot in front of this is empty in a fight, summon a Private there (2 a fight). | When a slot in front of this is empty in a fight, summon a golden 4/4 Private there (2 a fight). | 1/1 | One effect. |
| Lance Corporal (`lance-corporal`) | Order (1): Give the slots in front of this +2/+2. | Order (1): Give the slots in front of this +4/+4. | 1/1 | One effect. |
| Colour Sergeant (`colour-sergeant`) | At the end of your turn, if this row is full of Pigeons, give its slots +3/+3. | At the end of your turn, if this row is full of Pigeons, give its slots +6/+6. | 1/1 | One effect. |
| Padre (`padre`) | After a friendly unit dies, give its slot +1/+1 permanently (8 a fight). | After a friendly unit dies, give its slot +2/+2 permanently (8 a fight). | 1/1 | One effect. |
| Flying Ace (`flying-ace`) | Sortie.<br>After this kills, earn a Medal.<br>Decorated: Cleave. | Sortie.<br>After this kills, earn 2 Medals.<br>Decorated: Cleave. | 3/3 | Independent effects separated. |
| Grenadier Guard (`grenadier-guard`) | Order (1): Make a slot your Guard post.<br>At the end of your turn, give your Guard post +2/+4. | Order (1): Make a slot your Guard post.<br>At the end of your turn, give your Guard post +4/+8. | 2/2 | Independent effects separated. |
| Lieutenant (`lieutenant`) | Start of fight: If this row is full, each unit in it deals its slot's Attack buff to the enemy across from it. | Start of fight: If this row is full, each unit in it deals twice its slot's Attack buff to the enemy across from it. | 1/1 | One effect. |
| Squadron Leader (`squadron-leader`) | The units in front of this have Sortie and +4 Attack. | The units in front of this have Sortie and +8 Attack. | 1/1 | One effect. |
| Adjutant (`adjutant`) | After each fight, the units in front of this earn 2 Medals. | After each fight, the units in front of this earn 4 Medals. | 1/1 | One effect. |
| Bugler (`bugler`) | After a Pigeon joins the fight, give your Pigeons +2/+2. | After a Pigeon joins the fight, give your Pigeons +4/+4. | 1/1 | One effect. |
| Colour Ensign (`colour-ensign`) | Start of fight: This slot copies your strongest slot's buff. | Start of fight: This slot and the slots next to it copy your strongest slot's buff. | 1/1 | One effect. |
| Brigadier (`brigadier`) | Your Decorated Pigeons attack twice. | Your Decorated Pigeons attack twice. | 1/1 | One effect. |
| Wing Commander (`wing-commander`) | Sortie.<br>Start of fight: Your Pigeons with Sortie attack immediately. | Sortie.<br>Start of fight: Your Pigeons with Sortie attack immediately, twice. | 2/2 | Independent effects separated. |
| Regimental Sergeant Major (`regimental-sergeant-major`) | At the end of your turn, give every slot +2/+2.<br>Buffs you give to slots are doubled. | At the end of your turn, give every slot +4/+4.<br>Buffs you give to slots are tripled. | 2/2 | Global slot-buff multiplier is separate from end-turn buffing. |
| The Colonel (`the-colonel`) | Units in your hand have Reserve. | Units in your hand have Reserve. | 1/1 | One effect. |
| Field Marshal (`field-marshal`) | Medals on your Pigeons are worth +4/+4.<br>Your Decorated Pigeons have Stiff Upper Lip. | Medals on your Pigeons are worth +6/+6.<br>Your Decorated Pigeons have Stiff Upper Lip. | 2/2 | Medal-value aura and Decorated protection are separate. |

## Locusts

Source: [display text](../../../src/content/locust/units.json).

| Card | Normal groups | Golden groups | Groups | Review |
|---|---|---|---:|---|
| Hopper (`hopper`) | — (no rules text) | — (no rules text) | 0/0 | No rules text. |
| Green Recruit (`green-recruit`) | When this dies, summon 2 Hoppers. | When this dies, summon 4 Hoppers. | 1/1 | One effect. |
| Husk Sentry (`husk-sentry`) | Guard.<br>Molt. | Guard.<br>Molt. | 2/2 | Independent effects separated. |
| Prophet of the Dust (`prophet-of-the-dust`) | At the end of your turn, Tide +1. | At the end of your turn, Tide +2. | 1/1 | One effect. |
| Horde-runner (`horde-runner`) | At the start of your turn, get a Hopper. | At the start of your turn, get 2 Hoppers. | 1/1 | One effect. |
| Wheat Raider (`wheat-raider`) | Molt.<br>When this dies, deal 4 damage to a random enemy. | Molt.<br>When this dies, deal 8 damage to a random enemy. | 2/2 | Independent effects separated. |
| Brood Mother (`brood-mother`) | When this dies, summon a Hopper and give your Hoppers +1/+1 for the rest of the game. | When this dies, summon 2 Hoppers and give your Hoppers +2/+2 for the rest of the game. | 1/1 | Summoning and Hopper bonus share one death resolution. |
| Skin-shedder (`skin-shedder`) | Start of fight: Give Molt to the units next to this. | Start of fight: Give Molt twice to the units next to this. | 1/1 | One effect. |
| Gleaner (`gleaner`) | After a friendly unit dies, deal 5 damage to the highest-Health enemy. | After a friendly unit dies, deal 10 damage to the highest-Health enemy. | 1/1 | One effect. |
| Gorger (`gorger`) | The first time you sell a unit each turn, this eats it. | The first time you sell a unit each turn, this eats it and gains double its stats. | 1/1 | Golden double stats qualifies the same Eat operation. |
| Famine-caller (`famine-caller`) | When this dies, Tide +2. | When this dies, Tide +4. | 1/1 | One effect. |
| Sky-darkener (`sky-darkener`) | Start of fight: Summon 3 Hoppers. | Start of fight: Summon 6 Hoppers. | 1/1 | One effect. |
| Orchard Stripper (`orchard-stripper`) | Molt.<br>When this dies, deal 5 damage to all enemies. | Molt.<br>When this dies, deal 10 damage to all enemies. | 2/2 | Independent effects separated. |
| Granary Glutton (`granary-glutton`) | Whenever you sell a Locust, this eats it. | Whenever you sell a Locust, this eats it and gains double its stats. | 1/1 | Golden double stats qualifies the same Eat operation. |
| War-drummer (`war-drummer`) | Whenever this attacks, trigger the death effect of a unit behind it. | Whenever this attacks, trigger the death effect of a unit behind it twice. | 1/1 | One effect. |
| Twice-shed Veteran (`twice-shed-veteran`) | After another friendly unit returns, it and this gain +6/+6 this fight. | After another friendly unit returns, it and this gain +12/+12 this fight. | 1/1 | One effect. |
| The Eighth Plague (`the-eighth-plague`) | After a friendly unit dies, deal damage to a random enemy equal to the number of friendly units that died this fight. | After a friendly unit dies, deal damage to a random enemy equal to twice the number of friendly units that died this fight. | 1/1 | One effect. |
| Dirge-singer (`dirge-singer`) | Your death effects trigger twice. | Your death effects trigger three times. | 1/1 | One effect. |
| Swarm-lord (`swarm-lord`) | After 2 friendly Locusts die, Tide +1. | After 2 friendly Locusts die, Tide +2. | 1/1 | One effect. |
| Mother of Thousands (`mother-of-thousands`) | Whenever you summon Hoppers, summon twice as many. | Whenever you summon Hoppers, summon three times as many. | 1/1 | One effect. |

## Thorns

Source: [display text](../../../src/content/thorn/units.json).

| Card | Normal groups | Golden groups | Groups | Review |
|---|---|---|---:|---|
| Pip (`pip`) | Seed. | Seed. It adds 2 copies to your Compost. | 1/1 | Golden second sentence only changes Seed’s copy count. |
| Bramble Runner (`bramble-runner`) | Seed. | Seed. It adds 2 copies to your Compost. | 1/1 | Golden second sentence only changes Seed’s copy count. |
| Nettle Sprout (`nettle-sprout`) | Thorns 2. | Thorns 4. | 1/1 | One effect. |
| Hedge Layer (`hedge-layer`) | Bury: Gain 1 gold. | Bury: Gain 2 gold. | 1/1 | One effect. |
| Sweetbriar (`sweetbriar`) | Whenever a unit goes into your Compost, gain +1/+1 permanently. | Whenever a unit goes into your Compost, gain +2/+2 permanently. | 1/1 | One effect. |
| Blackthorn Sapling (`blackthorn-sapling`) | Root 1.<br>After this returns, gain +2/+2 permanently. | Root 1.<br>After this returns, gain +4/+4 permanently. | 2/2 | Return buff also works after Molt; it is a separate trigger. |
| Blackberry Sprawl (`blackberry-sprawl`) | Grow 2. | Grow 4. | 1/1 | One effect. |
| Nettle Skirmisher (`nettle-skirmisher`) | Thorns 4.<br>Root 1. | Thorns 8.<br>Root 1. | 2/2 | Independent effects separated. |
| Crab-apple (`crab-apple`) | Seed.<br>When this dies, summon a Pip. | Seed. It adds 2 copies to your Compost.<br>When this dies, summon a golden Pip. | 2/2 | Seed copy-count explanation stays joined; Pip summon is separate. |
| Old Stump (`old-stump`) | When this dies, summon a copy of the highest-tier unit in your Compost. | When this dies, summon copies of the 2 highest-tier units in your Compost. | 1/1 | One effect. |
| Ivy Climber (`ivy-climber`) | The units in front of this have Grow 1. | The units in front of this have Grow 2. | 1/1 | One effect. |
| Hawthorn Warden (`hawthorn-warden`) | Guard.<br>Root 2. | Guard.<br>Root 2. | 2/2 | Independent effects separated. |
| Holly Knight (`holly-knight`) | Your front-row Briars have +1 Thorns for every 3 units in your Compost. | Your front-row Briars have +2 Thorns for every 3 units in your Compost. | 1/1 | One effect. |
| Leafmould Carter (`leafmould-carter`) | Bury: Give your Briars +2/+2 permanently. | Bury: Give your Briars +4/+4 permanently. | 1/1 | One effect. |
| Lone Hawthorn (`lone-hawthorn`) | Guard.<br>Thorns 8.<br>Enemies your Thorns kill go into your Compost. | Guard.<br>Thorns 16.<br>Enemies your Thorns kill go into your Compost. | 3/3 | Compost trigger applies to friendly Thorns kills, beyond this card’s Thorns. |
| Hazel Coppicer (`hazel-coppicer`) | After a friendly unit returns, give your units +1/+1 permanently. | After a friendly unit returns, give your units +2/+2 permanently. | 1/1 | One effect. |
| Elder Mother (`elder-mother`) | Start of fight: Summon copies of the 2 highest-tier units in your Compost, with +1/+1 for each unit in it. | Start of fight: Summon copies of the 4 highest-tier units in your Compost, with +2/+2 for each unit in it. | 1/1 | Copy stats qualify the same summoning effect. |
| Briar King (`briar-king`) | Your other front-row Briars have Grow 2. | Your other front-row Briars have Grow 4. | 1/1 | One effect. |
| Old Mother Midden (`mother-midden`) | Bury: Give your Briars +2/+2 permanently.<br>Your Bury effects happen twice. | Bury: Give your Briars +4/+4 permanently.<br>Your Bury effects happen three times. | 2/2 | Global Bury repetition is separate from its own Bury action. |
| The Old Hedge (`the-old-hedge`) | Your other Briars have Root 1. | Your other Briars have Root 1. | 1/1 | One effect. |

## Fallback and system spells

Source: [display text](../../../src/game/data/stand_in_units.json). Triple Reward uses `GameContent.SYSTEM_TEXT`.

| Card | Normal groups | Golden groups | Groups | Review |
|---|---|---|---:|---|
| Triple Reward (`triple_reward`) | Discover a unit from the tier above yours. | Discover a unit from the tier above yours. | 1/1 | One effect. |
| Sharpen (`sp_sharpen`) | Give a friendly unit +2/+2. | Give a friendly unit +4/+4. | 1/1 | One effect. |
| Seek (`sp_seek`) | Discover a unit. | Discover a unit. | 1/1 | One effect. |
| Forage (`sp_forage`) | Discover two units. | Discover two units. | 1/1 | One effect. |

## Keyword and counter reminder sources

All **54 nonempty display entries**, including duplicate keyword names with different IDs, and all **six general-number variants** were checked sentence by sentence. Each is one explanation, so each cell below remains one group. The 67 empty/hidden display entries have no reminder text to split. `N` is the source placeholder; observed filled bodies are listed in the next table.

| Display ID | Name | Reminder: one group | General-number reminder: one group |
|---|---|---|---|
| `badger_fury` | Fury | Whenever this attacks or is attacked, gain +N Attack for each unit you're outnumbered by. | Whenever this attacks or is attacked, gain Attack for each unit you're outnumbered by. |
| `badger_grudge` | Grudge | After each fight, gain +1/+1 for each unit you were outnumbered by. | — |
| `badger_lend_attack` | Lends | The units in front have that much extra while this is on the board. | — |
| `badger_lend_health` | Lends | The units in front have that much extra while this is on the board. | — |
| `badger_outnumbered` | Outnumbered | Counted when the fight starts: enemy units beyond yours. Back-row Squires aren't counted. | — |
| `badger_overrun` | Overrun | Damage beyond what kills its target carries on to another enemy. | — |
| `badger_squire` | Squire | In the back row, this isn't counted for Outnumbered. | — |
| `cleave` | Cleave | Also damages the units next to its target. | — |
| `divine_shield` | Divine Shield | The first damage this takes is prevented. | — |
| `locust_brood` | Hopper | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | — |
| `locust_glut` | Eat | This gains the sold unit's stats. The sold unit's death effect triggers. | — |
| `locust_gorge` | Eat | This gains the sold unit's stats. The sold unit's death effect triggers. | — |
| `locust_hopper_bonus` | Hopper bonus | Your Hoppers have this much extra Attack and Health for the rest of the game. | — |
| `locust_hopper_to_hand` | Hopper | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | — |
| `locust_hoppers_on_death` | Hopper | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | — |
| `locust_molt` | Molt | The first time this dies each fight, it returns as a plain copy with 1 Health, then gains +2/+2 permanently. | — |
| `locust_mother` | Hopper | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | — |
| `locust_sky_darken` | Hopper | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | — |
| `locust_swarm_lord` | Tide +N | Your Locusts have +N Attack for the rest of the game. | — |
| `locust_tide` | Tide | Your Locusts have this much extra Attack for the rest of the game. | — |
| `locust_tide_end_turn` | Tide +N | Your Locusts have +N Attack for the rest of the game. | — |
| `locust_tide_on_death` | Tide +N | Your Locusts have +N Attack for the rest of the game. | — |
| `mouse_cousin` | Cousin | A 2/2 Mouse with Pile on. | — |
| `mouse_hit` | Hit | Deal this unit's Attack as damage. It takes none back. | — |
| `mouse_pikeman_gains` | Gains left this fight | How many more times the Needle Pikeman can grow this fight. | — |
| `mouse_pile_on` | Pile on | Whenever a neighbour attacks, this hits the target first. | — |
| `pigeon_decorated` | Decorated | Has 3 or more Medals. | — |
| `pigeon_grenadier` | Order (N) | Once a turn, pay N gold to use this. | Once a turn, pay the shown gold cost to use this. |
| `pigeon_guard_post` | Guard post | The unit here has Guard. You have one Guard post. | — |
| `pigeon_joins_the_fight` | Joins the fight | Is summoned, or steps in from Reserve. | — |
| `pigeon_lance_corporal` | Order (N) | Once a turn, pay N gold to use this. | Once a turn, pay the shown gold cost to use this. |
| `pigeon_medal` | Medal | +2/+2 permanently. | — |
| `pigeon_padre_uses` | Left this fight | How many more times this works this fight. | — |
| `pigeon_private` | Private | A 2/2 Pigeon. | — |
| `pigeon_reserve` | Reserve | In a fight, this steps from your hand into a slot a friendly unit died in. Your Guard post first. | — |
| `pigeon_sergeant_privates` | Privates left | How many more Privates this can summon this fight. | — |
| `pigeon_sortie` | Sortie | Attacks the enemy back row while it has units. | — |
| `pigeon_stiff_upper_lip` | Stiff Upper Lip | The first time damage would kill this each fight, it stays on 1 Health. | — |
| `reborn` | Reborn | Comes back with 1 Health the first time it dies. | — |
| `slot_buff` | Slot buff | Stays on the slot. Any unit standing there has it. | — |
| `stealth` | Stealth | Can't be attacked until it attacks. | — |
| `taunt` | Guard | Enemies must attack this first. | — |
| `thorn_bury_feed` | Bury | Once a turn, put a shop unit in your Compost, then do what follows. | — |
| `thorn_bury_gold` | Bury | Once a turn, put a shop unit in your Compost, then do what follows. | — |
| `thorn_compost` | Compost | Your heap. Units you bought go here when you sell them. | — |
| `thorn_elder_mother` | Copy from the Compost | A plain copy for this fight. Each unit in your Compost comes out once a fight. With no room, they wait for a slot. | — |
| `thorn_grow` | Grow | Start of fight: Gain +N/+N for every 2 units in your Compost. | Start of fight: gain the shown stats for every 2 units in your Compost. |
| `thorn_old_stump` | Copy from the Compost | A plain copy for this fight. Each unit in your Compost comes out once a fight. | — |
| `thorn_pip` | Pip | A 3/3 Briar with Seed. | — |
| `thorn_root` | Root | The first time this dies each fight, spend N Compost to return it. | The first time this dies each fight, spend its Root cost in Compost to return it. |
| `thorn_seed` | Seed | When this dies, add a copy of it to your Compost. | — |
| `thorn_thorns` | Thorns | Whenever this is attacked, deal N damage to the attacker first. | Whenever this is attacked, damage the attacker first by its Thorns amount. |
| `venomous` | Venomous | Destroys any unit it damages. | — |
| `windfury` | Attacks twice | Attacks twice, back to back. | — |

## Observed keyword detail bodies

These **53 distinct header/body combinations** come from the same marked rules, granted-term additions, deduplication and one-level nested lookup used by `GlassTips`. They include printed numbers, general references, plurals and nested words. Every body is one effect explanation; none contains an authored break. Capitalization follows the actual marked reference.

| Header | Reminder: final one-group body | Example card/form |
|---|---|---|
| Attacks twice | Attacks twice, back to back. | `shrew-harrier` |
| Bury | Once a turn, put a shop unit in your Compost, then do what follows. | `hedge-layer` |
| Cleave | Also damages the units next to its target. | `flying-ace` |
| Compost | Your heap. Units you bought go here when you sell them. | `pip` |
| Cousin | A 2/2 Mouse with Pile on. | `hedgerow-scout` |
| Cousins | A 2/2 Mouse with Pile on. | `hedgerow-scout (golden)` |
| Decorated | Has 3 or more Medals. | `old-campaigner` |
| eats | This gains the sold unit's stats. The sold unit's death effect triggers. | `gorger` |
| Fury 1 | Whenever this attacks or is attacked, gain +1 Attack for each unit you're outnumbered by. | `brock-cub` |
| Fury 2 | Whenever this attacks or is attacked, gain +2 Attack for each unit you're outnumbered by. | `brock-cub (golden)` |
| Fury 3 | Whenever this attacks or is attacked, gain +3 Attack for each unit you're outnumbered by. | `ironhide-berserker` |
| Fury 4 | Whenever this attacks or is attacked, gain +4 Attack for each unit you're outnumbered by. | `tourney-champion (golden)` |
| Fury 6 | Whenever this attacks or is attacked, gain +6 Attack for each unit you're outnumbered by. | `ironhide-berserker (golden)` |
| Fury | Whenever this attacks or is attacked, gain +1 Attack for each unit you're outnumbered by. | `master-at-arms` |
| Fury | Whenever this attacks or is attacked, gain +2 Attack for each unit you're outnumbered by. | `sett-sexton` |
| Fury | Whenever this attacks or is attacked, gain +4 Attack for each unit you're outnumbered by. | `sett-sexton (golden)` |
| Fury | Whenever this attacks or is attacked, gain Attack for each unit you're outnumbered by. | `sword-heir` |
| Grow 1 | Start of fight: Gain +1/+1 for every 2 units in your Compost. | `ivy-climber` |
| Grow 2 | Start of fight: Gain +2/+2 for every 2 units in your Compost. | `blackberry-sprawl` |
| Grow 4 | Start of fight: Gain +4/+4 for every 2 units in your Compost. | `blackberry-sprawl (golden)` |
| Grudge | After each fight, gain +1/+1 for each unit you were outnumbered by. | `brock-cub` |
| Guard post | The unit here has Guard. You have one Guard post. | `territorial` |
| Guard | Enemies must attack this first. | `hedge-knight` |
| Hit | Deal this unit's Attack as damage. It takes none back. | `toothpick-ballista` |
| hits | Deal this unit's Attack as damage. It takes none back. | `cousin` |
| Hopper | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | `horde-runner` |
| Hoppers | A 2/2 Locust. In a fight, a Hopper with no room waits for a slot. | `green-recruit` |
| joins the fight | Is summoned, or steps in from Reserve. | `bugler` |
| Lends | The units in front have that much extra while this is on the board. | `sett-shield-bearer` |
| Medal | +2/+2 permanently. | `old-campaigner` |
| Medals | +2/+2 permanently. | `old-campaigner (golden)` |
| Molt | The first time this dies each fight, it returns as a plain copy with 1 Health, then gains +2/+2 permanently. | `husk-sentry` |
| Order (1) | Once a turn, pay 1 gold to use this. | `lance-corporal` |
| Outnumbered | Counted when the fight starts: enemy units beyond yours. Back-row Squires aren't counted. | `sett-shield-bearer` |
| outnumbered | Counted when the fight starts: enemy units beyond yours. Back-row Squires aren't counted. | `brock-cub` |
| Overrun | Damage beyond what kills its target carries on to another enemy. | `greatsword-bearer` |
| Pile on | Whenever a neighbour attacks, this hits the target first. | `cousin` |
| Pip | A 3/3 Briar with Seed. | `crab-apple` |
| Private | A 2/2 Pigeon. | `recruiting-sergeant` |
| Reserve | In a fight, this steps from your hand into a slot a friendly unit died in. Your Guard post first. | `territorial` |
| Root 1 | The first time this dies each fight, spend 1 Compost to return it. | `blackthorn-sapling` |
| Root 2 | The first time this dies each fight, spend 2 Compost to return it. | `hawthorn-warden` |
| Seed | When this dies, add a copy of it to your Compost. | `pip` |
| Sortie | Attacks the enemy back row while it has units. | `flying-ace` |
| Squire | In the back row, this isn't counted for Outnumbered. | `sett-shield-bearer` |
| Stiff Upper Lip | The first time damage would kill this each fight, it stays on 1 Health. | `old-campaigner` |
| Thorns 16 | Whenever this is attacked, deal 16 damage to the attacker first. | `lone-hawthorn (golden)` |
| Thorns 2 | Whenever this is attacked, deal 2 damage to the attacker first. | `nettle-sprout` |
| Thorns 4 | Whenever this is attacked, deal 4 damage to the attacker first. | `nettle-sprout (golden)` |
| Thorns 8 | Whenever this is attacked, deal 8 damage to the attacker first. | `nettle-skirmisher (golden)` |
| Thorns | Whenever this is attacked, deal 1 damage to the attacker first. | `holly-knight` |
| Thorns | Whenever this is attacked, deal 2 damage to the attacker first. | `holly-knight (golden)` |
| Tide | Your Locusts have this much extra Attack for the rest of the game. | `prophet-of-the-dust` |

## Other card reminder paragraphs

These additional reminder strings appear in the card-view reminder source (some repeat a named keyword source). They were reviewed too. Token stats, per-fight limits and waiting-for-room explanations stay joined. Each row is one reminder paragraph; separate source entries remain separate entries.

| Reminder | Example card/form |
|---|---|
| Discover: Choose 1 of 3 cards to put in your hand. | `triple_reward` |
| Fury: Whenever this attacks or is attacked, gain +N Attack for each unit you're outnumbered by. | `brock-cub` |
| Grudge: After each fight, gain +1/+1 for each unit you were outnumbered by. | `brock-cub` |
| Outnumbered: Counted when the fight starts: enemy units beyond yours. Back-row Squires aren't counted. | `brock-cub` |
| Guard: Enemies must attack this first. | `hedge-knight` |
| Squire: In the back row, this isn't counted for Outnumbered. | `sett-shield-bearer` |
| Lends: The units in front have that much extra while this is on the board. | `sett-shield-bearer` |
| Only one Relic Seeker pays each fight. | `relic-seeker` |
| Overrun: Damage beyond what kills its target carries on to another enemy. | `greatsword-bearer` |
| Hopper: A 2/2 Locust. | `green-recruit` |
| Each Molt given is one more return this fight, on top of any Molt the unit has. | `skin-shedder` |
| Cousin: A 2/2 Mouse with Pile on. | `hedgerow-scout` |
| Pile on: Whenever a neighbour attacks, this hits the target first. | `hedgerow-scout` |
| Cousin: A 2/2 Mouse. Pile on. | `hedgerow-scout` |
| Slot buff: Stays on the slot. Any unit standing there has it. | `whetstone-vole` |
| Hit: Deal this unit's Attack as damage. It takes none back. | `toothpick-ballista` |
| Reserve: In a fight, this steps from your hand into a slot a friendly unit died in. Your Guard post first. | `territorial` |
| Medal: +2/+2 permanently. | `old-campaigner` |
| Decorated: Has 3 or more Medals. | `old-campaigner` |
| Stiff Upper Lip: The first time damage would kill this each fight, it stays on 1 Health. | `old-campaigner` |
| Private: A 2/2 Pigeon. | `recruiting-sergeant` |
| Sortie: Attacks the enemy back row while it has units. | `flying-ace` |
| Cleave: Also damages the units next to its target. | `flying-ace` |
| Guard post: The unit here has Guard. You have one Guard post. | `grenadier-guard` |
| Joins the fight: Is summoned, or steps in from Reserve. | `bugler` |
| Seed: When this dies, add a copy of it to your Compost. | `pip` |
| Compost: Your heap. Units you bought go here when you sell them. | `pip` |
| Thorns N: Whenever this is attacked, deal N damage to the attacker first. | `nettle-sprout` |
| Bury: Once a turn, put a shop unit in your Compost, then do what follows. | `hedge-layer` |
| Root 1: The first time this dies each fight, spend 1 Compost to return it. | `blackthorn-sapling` |
| Grow N: Start of fight: Gain +N/+N for every 2 units in your Compost. | `blackberry-sprawl` |
| Pip: A 3/3 Briar with Seed. | `crab-apple` |
| Pip: A 3/3 Briar. Seed. | `crab-apple` |
| Copy from the Compost: A plain copy for this fight. Each unit in your Compost comes out once a fight. | `old-stump` |
| Root 2: The first time this dies each fight, spend 2 Compost to return it. | `hawthorn-warden` |
| With no room, they wait for a slot. | `elder-mother` |

## Decisions that required judgment

- **Old Campaigner:** survival changes the amount of the same Medal award. Decorated is the independent second effect.
- **Golden Grudge-keeper and Seed:** the extra sentence explains the amount/copy count of the preceding effect. Crab-apple’s death summon still starts a separate group.
- **Blackthorn Sapling:** its post-return buff also fires after Molt, so it is not just an explanation of Root ([mechanic](../../../src/content/thorn/mechanics/sapling.gd)).
- **Dame Bodkin:** the multiplier affects all friendly pile-on hits, independently of her own Pile on ([mechanic](../../../src/content/mouse/mechanics/bodkin.gd)).
- **Lone Hawthorn:** the Compost trigger listens for friendly Thorns kills generally; it is separate from this unit’s Guard and Thorns ([mechanic](../../../src/content/thorn/mechanics/lone_hawthorn.gd)).
- **Old Mother Midden / Regimental Sergeant Major:** the global Bury/slot-buff multipliers affect other sources too, independently of their own activated/end-turn effect ([Bury](../../../src/content/thorn/mechanics/bury_twice.gd), [slot buffs](../../../src/content/pigeon/mechanics/sergeant_major.gd)).
- **Needle Pikeman:** Pile on, the normal-attack restriction, and the permanent-growth trigger are three independent rules ([mechanic](../../../src/content/mouse/mechanics/pikeman.gd)).
- **Keyword reminders:** Guard post’s limit, Reserve’s preferred slot, Outnumbered’s Squire exclusion, Hit’s lack of retaliation, Eat’s death-effect handling, and Compost-copy lifetime/room limits explain their parent keyword. They stay together.

Normal/golden regression tests pin the reported misses and true multi-effect examples. The authored-newline border-mark test also protects keyword counts after the separator change.

## Verification

`check.sh: all steps passed` — all 12 steps; 412 compiled resources; 825 tests / 19,277 assertions; 15 soak games / 683 fights with zero violations; all six planted faults caught; two replay games / 30 turns / 90 checkpoints matched and the altered action was caught. Runs used `LP_NUM_THREADS=2`, CPUs 2–3 and temporary XDG/film directories.

The five content JSON files were compared structurally with `74c25a0b` after changing only authored newlines back to spaces: every word, punctuation mark, number, parameter and other field matches. The audit table was checked against every runtime ID and both exact resolved forms. The new owner quote was checked verbatim. Native Grenadier capture: `/home/alex/code/Bramble/.claude/worktrees/n18-media/tipfix/grenadier-effects-1366.png` (1366×768), with its log and `effect-lines-source-sha256.json` beside it.
