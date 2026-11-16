# Ogres: a Battlegrounds minion type

## 1. Identity

**Fantasy.** Ogres follow strength, not bloodlines. The biggest one wears the crown, the rest pay it tribute, and any of them will grab the crown the moment it outgrows the king. When the king falls, the next-biggest takes the crown in the middle of the fight. Ogres will serve whoever is strongest, ogre or not. That's the mercenary streak. Their magi have two heads that never agree: one serves the king, the other looks after the runt.

**Terms (all about one idea: who wears the crown).**
- **Chieftain:** your minion with the highest Attack (on a tie, the leftmost). It can be **any minion type**. It's worked out again all the time, in combat too, and a crown shows who it is. The enemy board always has one too.
- **Runt:** your minion with the lowest Attack (on a tie, the rightmost). This is a plain term, not a keyword with triggers.
- **Tribute +X/+Y:** give your Chieftain +X/+Y. This is permanent in the Recruit Phase and lasts only for this combat when it happens in combat.
- **Crowned:** triggers when this minion becomes your Chieftain, or when an effect re-Crowns it. A minion can be Crowned at most once per Recruit turn and once per combat, and after that, taking the crown doesn't count. This stops loops.
- **Two-Headed:** the minion has a Left head and a Right head. The **Left** head works while more of your minions are to its right. The **Right** head works while more are to its left. **Both** work when the numbers are equal: the exact middle of an odd board, or when it's alone. Left heads always serve the Chieftain, and Right heads serve the minion itself or the Runt.

**How it plays.** Each turn is a small puzzle about the crown. You decide who wears it: an ogre, or a hired carry from another tribe. Tributes stack onto that one minion. Then you decide whether to keep it there, or to hand the crown on and set off the Crowned effects that fire whenever it changes hands. In combat the crown moves as kings die, and succession cards make each death pay. Two-Headed magi turn board order into a third puzzle. Their heads switch on and off as minions die and the middle of the board moves. Effects line up in ways the cards don't spell out. A Tribute engine can feed a Dragon. A Runt-buffer can push a token past the king and steal the crown. Killing the enemy's king re-Crowns your own.

## 2. The 24 minions

| # | Name | Tier | A/H | Text | Golden |
|---|---|---|---|---|---|
| 1 | Grog Runner | 1 | 2/2 | Battlecry: Tribute +2/+2. | 4/4. Tribute +4/+4. |
| 2 | Arena Thrall | 1 | 2/3 | Crowned: Gain +1/+1 permanently. | 4/6. +2/+2. |
| 3 | Squabbling Twinskull | 1 | 2/3 | Two-Headed. Left: Battlecry: Tribute +2/+1. Right: Battlecry: Gain +2/+1. | 4/6. +4/+2 per head. |
| 4 | Ogre Magi | 2 | 3/3 | Two-Headed. Left: At the end of your turn, Tribute +2/+1. Right: At the end of your turn, give your Runt +1/+2. | 6/6. Both doubled. |
| 5 | Tribute Collector | 2 | 2/4 | The first time you Tribute each turn, gain 1 Gold. | 4/8. Gain 2 Gold. |
| 6 | Highmaul Bodyguard | 2 | 2/5 | The first time each combat that your Chieftain would be attacked, this is attacked instead. | 4/10. The first two times. |
| 7 | Hired Maul | 2 | 3/3 | Also has your Chieftain's minion types. | 6/6. Also has your Chieftain's and your Runt's types. |
| 8 | Dire Maul Pretender | 3 | 4/3 | Start of Combat: Attack the enemy Chieftain. | 8/6. Does it twice. |
| 9 | Crown-Bearer | 3 | 3/4 | After your Chieftain dies, give the new Chieftain +3/+3. | 6/8. +6/+6. |
| 10 | Glopgut Brewer | 3 | 3/4 | At the end of your turn, get a Gordok Green Grog. | 6/8. Get two. |
| 11 | Twinskull Bruiser | 3 | 4/4 | Two-Headed. Left: Rally: Tribute +2/+1. Right: Rally: Give your Runt +1/+2. | 8/8. Both doubled. |
| 12 | Bladespire Gladiator | 3 | 3/5 | Crowned: Gain Divine Shield. | 6/10. Crowned: Gain Divine Shield and Reborn. |
| 13 | Meat-Cauldron Cook | 4 | 3/6 | At the end of your turn, Tribute +1/+1 for each Ogre you have. | 6/12. +2/+2 for each. |
| 14 | Captain Kromcrush | 4 | 4/5 | Whenever you Tribute, this gains +1/+1. | 8/10. +2/+2. |
| 15 | Stormaltar Acolyte | 4 | 2/7 | Adjacent Two-Headed minions use both heads. | 4/14. All your Two-Headed minions use both heads. |
| 16 | Mercenary Broker | 4 | 4/5 | At the start of your turn: if your Chieftain is an Ogre, Tribute +4/+4. If it isn't, gain 2 Gold. | 8/10. +8/+8, or 4 Gold. |
| 17 | Bloodmaul Pit-Boss | 4 | 4/6 | Two-Headed. Left: Your minions deal double damage to the enemy Chieftain. Right: Your Runt has Venomous. | 8/12. Left: triple damage. Right: your two lowest-Attack minions have Venomous. |
| 18 | Imperator Mar'gok | 5 | 5/6 | After your Chieftain dies, the new Chieftain gains half its Attack and Health. | 10/12. Gains all of it. |
| 19 | The Butcher | 5 | 6/5 | Whenever an enemy minion dies, your Chieftain gains +3/+3 for this combat. | 12/10. +6/+6. |
| 20 | Cho'Rush the Observer | 5 | 4/6 | Two-Headed. Left: Your Tributes give twice as much. Right: Buffs your Runt receives are doubled. | 8/12. Three times as much, for both heads. |
| 21 | Phemos and Pol | 5 | 5/5 | Deathrattle: Summon Pol, a 5/5 Taunt. If Phemos was your Chieftain, Pol also gets Phemos's Attack. | 10/10. Pol is 10/10. |
| 22 | Gruul the Dragonkiller | 6 | 7/7 | Start of Combat: Your Chieftain attacks the enemy Chieftain. If it kills it, repeat. | 14/14. Your two highest-Attack minions each do this. |
| 23 | King Gordok | 6 | 6/7 | Whenever a friendly minion is Crowned, give your other minions +1/+1 permanently. Whenever the enemy Chieftain dies, re-Crown your Chieftain. | 12/14. +2/+2. |
| 24 | Cho'gall | 6 | 5/8 | Two-Headed. Left: Your other Two-Headed minions use both heads. Right: Your other Two-Headed minions' triggered heads trigger twice. | 10/16. Right: three times. |

Tier counts: 3 / 4 / 5 / 5 / 4 / 3. Every unit is an Ogre. Pol is an Ogre token.

**Extras (kept few)**
- **Gordok Green Grog** (Tavern spell, 1 Gold in Ogre lobbies; free from Glopgut Brewer): Give a minion +2 Attack. If that makes it your Chieftain, give it +2/+2 more. This is the cheap way to move the crown.
- **Pol** (token): 5/5 Ogre, Taunt. It doesn't come back, so there's no loop.
- **Crude Crown** (Lesser Trinket): Your Chieftain has +6 Health. It gives Health only, so it never decides who wears the crown.
- **Highmaul Sigil** (Greater Trinket): Each of your minions can be Crowned twice per combat.

Static heads, such as Cho'Rush's, are not "triggered heads", so Cho'gall's Right head doesn't stack with them.

## 3. Builds

**A. One King (concentration).** Tribute sources (Grog Runner, Ogre Magi's Left head, Cook, Broker, Bruiser) all feed one Chieftain. Cho'Rush doubles them, Kromcrush grows alongside, and Bodyguard keeps the king from being picked off. Insurance: Crown-Bearer, Mar'gok and Phemos keep a Venomous hit or a destroy effect from wiping out the investment, because the stats pass down the line. The cash-out is Gruul: the king opens the fight by killing the enemy's biggest minions one after another, with Pit-Boss doubling its damage against them. *Johnny angle:* the king doesn't have to be an ogre. A Divine Shield Mech, a Cleave or Windfury carry, or a Reborn Undead each change what "stack the king" means.

**B. Usurpers (the revolving crown).** Keep several mid-sized ogres at similar Attack. Grog, Squabbling Twinskull's Right head and Ogre Magi's Runt buffs push a different one past the king each turn. Each change of hands fires Arena Thrall, Bladespire Gladiator (a fresh Divine Shield) and King Gordok (+1/+1 to everyone). In combat, every king that dies crowns the next. Dire Maul Pretender plus Gordok's re-Crown turns killing the enemy king into another Crowned trigger. Kromcrush steals the crown by himself once he outgrows the king.

**C. Altar of Storms (Two-Headed).** Squabbling Twinskull, Ogre Magi, Twinskull Bruiser, Pit-Boss, Cho'Rush and Cho'gall, with Stormaltar Acolyte placed next to the magi you most want to switch on. Odd board sizes matter, because only an odd board has a middle slot. Heads switch as minions die. A Left-side Bruiser drifts to the middle and then to the Right, so it feeds the king early in the fight and the Runt late. The Right heads build a Runt plan: a 1-Attack token with Venomous from Pit-Boss, or a Runt grown until it steals the crown.

**Mixing in a five-tribe lobby.** Ogres are built to serve other tribes:
- **Mech:** Hired Maul becomes a Mech, so Magnetic upgrades can go on it. A Divine Shield Mech makes a great king.
- **Beast and Undead:** tokens are natural Runts for Pit-Boss Venomous and for Cho'Rush's Right head. A Reborn king comes back and is crowned again.
- **Dragon and Demon:** Dragon stacking and Demon eating grow a king that Tributes then make bigger still. Hired Maul picks up Dragon and Demon synergies.
- **Pirate:** Broker's 2 Gold when a Pirate is king, and Tribute Collector, fit gold-counting plans.
- **Murloc:** Battlecry repeaters re-fire Grog Runner and Squabbling Twinskull.
- **Aberration:** a Deity that joins mid-fight usually takes the crown at once, which crowns it and fires Gordok.
- **Elemental and Quilboar:** Blood Gems and Tavern buffs move the crown, just as Grog does.

## 4. Risks and holes

- **Concentration is swingy.** A single Venomous or destroy effect turns One King's turn into a coin flip. The succession cards soften this, but only from Tier 3 up, so early One King is fragile.
- **Readability.** The crown, the Runt and live Two-Headed states all change during combat. The UI must show the crown, the Runt marker and which heads are lit at every moment. Otherwise a fight reads as random.
- **Even boards hide the middle slot.** Players may not see why Both is off on a 6-board. The tooltip should say so.
- **Tribute Collector timing.** Gold from an end-of-turn Tribute is wasted. That's a fair timing puzzle for Johnny, but it will feel bad until players learn it.
- **Hired Maul rules load.** Types that change mid-combat raise edge cases: counting "types on board", and a king that is All types. It needs a clear ruling, or the golden version should be dropped.
- **Gruul blowouts.** A huge king with Pit-Boss double damage can clear the top of an enemy board before any minion swings. Taunt doesn't stop it. The only counters are an enemy Bodyguard, Divine Shield, or spreading stats out. Watch for it.
- **Hidden state.** "Crowned once per combat" is invisible. The minion needs a spent-crown mark.
- **Identity drain.** With a non-Ogre king, the board may hold few ogres. Cook and Broker's ogre branch pull back toward ogres, but the balance needs watching.
- **Cho'Rush's Right head** doubles tribe-wide buffs that land on the Runt. That's fine on its own, but with mass-buff tribes the Runt changes all the time, so the doubled buff is hard to predict.

## 5. Tier check

- **Tier 1:** Grog Runner is a once-off buffer at ~0.9 body, and Arena Thrall is a seed. Thrall's 2–4 stats a turn is above the ~0.4-body target, on purpose, because it needs the crown moved deliberately. Squabbling Twinskull gives ~0.7 body from one head and ~1.3 in the middle, a small reward for placement.
- **Tier 2:** Ogre Magi gives 3–6 stats a turn, inside the 2–6 band. Tribute Collector is the economy piece at about 1 Gold a turn. Bodyguard and Hired Maul are enablers with no stat output.
- **Tier 3:** Five units instead of four, because the tribe has three directions and each needs its namer: Pretender for Regicide, Gladiator for Usurpers, Bruiser for Two-Headed. Crown-Bearer gives 6–18 in fight, at the top of the 5–10 band and above it when kings die often. Brewer gives ~4 a turn plus crown control.
- **Tier 4:** Cook gives ~10 a turn on 5 Ogres, and Kromcrush ~8–12; both are on the ~12 target. Broker is economy at 2 Gold, or 8 stats, slightly under target because both branches also trigger Tribute effects. Pit-Boss's Venomous Runt is worth about one kill, ~20 in fight. Acolyte enables with no stats.
- **Tier 5:** Mar'gok gives ~40 in fight when the king is ~40/40, on target, and scales with the king, which is the point. Butcher gives 30–42 in fight. Cho'Rush is the first true multiplier, in the role Brann plays. Phemos and Pol is the tempo piece at 20 stats, about twice the body. That's a deliberate break, because the second body carries the king's Attack forward.
- **Tier 6:** Gruul is the payoff; its value is the enemy minions it removes, roughly ~75 in fight. King Gordok gives ~50–70 a turn, around the ~50 target, and runs high in crown-juggling boards. If that runs away, cut combat crownings to Ogres only. Cho'gall is a capstone multiplier with no stats of its own. Its golden ceiling, triggered heads three times, is the high roll worth chasing.

## 6. Design rationale (in order)

1. I started from "might makes right": the biggest wears the crown. So the tribe's core noun had to be a Chieftain worked out from board state, not a card.
2. The Chieftain can be any type, because ogres are mercenaries who serve the strongest. That also gives Johnny a lever into every other tribe.
3. Tribute is the appetite and greed theme as a verb. Every ogre feeds the king, so buffs pile up in one place, which no current tribe does.
4. Crowned turns "anyone can challenge for the throne" into a reason to move the crown, so stacking and juggling pull against each other.
5. I capped Crowned at once per turn and once per combat as soon as it existed, because a crown passed back and forth is a natural infinite loop.
6. Succession effects (Crown-Bearer, Mar'gok, Phemos) answer concentration's weakness, Venomous, and follow the lore of a fallen empire passing on.
7. Two heads that disagree became board position. That's the one lever Battlegrounds players already control, and it shifts on its own as minions die.
8. The Left head serves the king and the Right head serves the Runt, everywhere. The Runt gave the Right head a real job and a second route to the crown.
9. Gladiators and the King Gordok tribute run became Regicide: targeting the enemy's Chieftain, plus Gordok re-crowning yours when theirs dies, which ties Regicide to Crowned.
10. The Grog spell gives a cheap, controllable way to move the crown, so the Usurper puzzle doesn't depend on Tavern luck.
11. The extra five units went to Tier 3 and Tier 4, where the three directions need their namers and a first multiplier, rather than adding more capstones.
12. Named lore figures sit where their legend's scale fits: captains at Tier 4, imperators and raid bosses at Tier 5, and the gronn overlord, the throne and the cult leader at Tier 6.
