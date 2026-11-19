# The Regiment

Pigeon rework, 19 Nov 2026. A company earns Renown on its slot. Each starter and each reservist borrows +1/+1 per point. Renown earned during a fight counts from the next fight. Hand reinforcements fill the Guard post first, then the highest Renown, then reading order. After waiting summons land, officers can call Privates into the slots where they witnessed a death.

The owner (16 Nov): "I think we should have a mix of trail *[read as Drill]* and medals, and I think maybe Pigeon should buff the slots rather than teach other pigeons and stuff. We're going to need some slot buffs stuff. We may need additional spice as well. I feel like this is a bit bland as is". *[Replaced by the Renown rework, 19 Nov 2026: see the cards table]*

| Tier | Card | Attack/Health | Text | Golden |
|---|---|---|---|---|
| 1 | Private | 2/2 | Token | Doubled stats |
| 1 | Sentry | 2/5 | Supply 6: At the end of your turn, give this slot 1 Renown. | Supply 6: At the end of your turn, give this slot 2 Renown. |
| 1 | Territorial | 4/5 | Reserve. | Doubled stats |
| 2 | Recruiting Sergeant | 3/7 | Charge 1: After a unit in front of this dies, a Private steps in there. | Charge 2: After a unit in front of this dies, a Private steps in there. |
| 2 | Lance Corporal | 3/6 | 1: Give the slots in front of this 1 Renown. | 1: Give the slots in front of this 2 Renown. |
| 2 | Old Campaigner | 4/7 | After each fight, give this slot 1 Renown, or 2 if this survived. | After each fight, give this slot 2 Renown, or 4 if this survived. |
| 3 | Colour Sergeant | 4/9 | At the end of your turn, if this row is full of Pigeons, give each slot in it 1 Renown. | At the end of your turn, if this row is full of Pigeons, give each slot in it 2 Renown. |
| 3 | Padre | 2/9 | Charge 4: After a friendly unit dies, give its slot 1 Renown. | Charge 4: After a friendly unit dies, give its slot 2 Renown. |
| 3 | Grenadier Guard | 4/11 | 0: Make a slot your Guard post. At the end of your turn, give your Guard post 2 Renown. | 0: Make a slot your Guard post. At the end of your turn, give your Guard post 4 Renown. |
| 3 | Squadron Leader | 4/9 | The units in front of this have Sortie and +3 Attack. | The units in front of this have Sortie and +6 Attack. |
| 3 | Home Guard | 3/11 | Guard. Reserve. | Doubled stats |
| 4 | Flying Ace | 8/7 | Cleave. Charge 2: After this kills, give this slot 1 Renown. | Cleave. Charge 2: After this kills, give this slot 2 Renown. |
| 4 | Lieutenant | 5/11 | Start of fight: If this row is full, each unit in it deals half its slot's Renown as damage to the enemy across from it. | Start of fight: If this row is full, each unit in it deals its slot's full Renown as damage to the enemy across from it. |
| 4 | Bugler | 3/8 | Charge 2: After a friendly unit dies, a Private steps in there. | Charge 4: After a friendly unit dies, a Private steps in there. |
| 4 | Quartermaster | 3/12 | Recruit: Give a unit in your hand Reserve. You can call 1 more reservist each fight. | Recruit: Give 2 units in your hand Reserve. You can call 2 more reservists each fight. |
| 5 | Colour Ensign | 6/14 | Start of fight: This slot copies your highest Renown. | Start of fight: This slot and the slots next to it copy your highest Renown. |
| 5 | Wing Commander | 10/8 | Sortie. Start of fight: Your Pigeons with Sortie attack immediately. | Sortie. Start of fight: Your Pigeons with Sortie attack immediately, twice. |
| 5 | Group Captain | 6/14 | Your reservists have Sortie and +4 Attack. | Your reservists have Sortie and +8 Attack. |
| 6 | Regimental Sergeant Major | 8/14 | At the end of your turn, give every slot 3 Renown. | At the end of your turn, give every slot 6 Renown. |
| 6 | The Colonel | 6/16 | Reservists from your hand have double Renown. | Reservists from your hand have triple Renown. |
| 6 | Air Marshal | 7/15 | Charge 3: After a reservist steps in, it attacks immediately. | Charge 6: After a reservist steps in, it attacks immediately. |

Charge refills at fight start. Supply stays with the unit, and a triple pools the remaining uses. Actives show their gold cost in a coin.

## Implementation proposals

When several eligible friends die together, an officer spends its remaining Charge on the Guard post first, then on eligible deaths in their resolution order. This preserves the previous Recruiting Sergeant’s preference for the post.

A golden Quartermaster uses the leftmost remaining eligible hand unit for its second grant, including when the first grant was aimed explicitly.

The Quartermaster can't give Reserve to itself: it is left out of its own target, in the default pick and in the picker.

Lieutenant: when the enemy slot across is empty, that unit deals no damage, as the card text and rulebook 8.2.6 read. The accepted build sent it to the nearest enemy in that row, else any enemy. The balance orchestrator kept the rule-correct reading; a nerf the pitch didn't list.

## Cut on 19 Nov 2026

| Card or keyword | Last text |
|---|---|
| Adjutant | After each fight, the units in front of this earn 2 Medals. |
| Brigadier | Your Decorated Pigeons attack twice. |
| Field Marshal | Medals on your Pigeons are worth +4/+4. Your Decorated Pigeons have Stiff Upper Lip. |
| Medal | +2/+2 permanently. |
| Decorated | Has 3 or more Medals. |
| Stiff Upper Lip | The first time damage would kill this each fight, it stays on 1 Health. |

The art of the Adjutant, Brigadier and Field Marshal was deleted from assets/units/pigeon/; git history keeps it.
