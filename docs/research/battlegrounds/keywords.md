# Hearthstone Battlegrounds keyword glossary

This glossary lists every Battlegrounds keyword and keyworded mechanic, current and retired. It is written as of patch 36.6.3 (Oct 2026). Each entry has a "two-row potential" idea for Bramble's board. Combat timing is in [rules.md](rules.md) §11, and the history behind each change is in [patch-history.md](patch-history.md).

**Sources for the rules text**
- **[R]** marks reminder text quoted from the Hearthstone Wiki keyword pages: [Ability](https://hearthstone.wiki.gg/wiki/Ability), [Venomous](https://hearthstone.wiki.gg/wiki/Venomous), [Avenge](https://hearthstone.wiki.gg/wiki/Avenge_(ability)), [Rally](https://hearthstone.wiki.gg/wiki/Rally), [Spellcraft](https://hearthstone.wiki.gg/wiki/Spellcraft), [Magnetic](https://hearthstone.wiki.gg/wiki/Magnetic), [Reborn](https://hearthstone.wiki.gg/wiki/Reborn).
- **[C]** marks text quoted from a current card, taken from the card data in [content-library.md](content-library.md) (HearthstoneJSON, build 37.0.0).
- **[N]** marks a quote from the patch notes linked in [patch-history.md](patch-history.md).
- Where the wiki gives only a paraphrase, the text is marked **paraphrase** and the exact in-game wording is UNVERIFIED.
- "Current pool" counts come from the card data. They count the minions whose text uses the keyword.

## Bramble board model these ideas assume

The board is a fixed 4-3 grid, as decided by the coordinator on 27 Oct 2026:

```
 F1   F2   F3   F4      front row (attacks and is attacked first)
    B1   B2   B3        back row: each slot sits between two front slots
```

- **Behind / in front of:**
  - B1 is behind F1 and F2, B2 is behind F2 and F3, B3 is behind F3 and F4.
  - F1 and F4 have one unit behind them; F2 and F3 have two.
- **Adjacency within a row:** F1–F2–F3–F4 and B1–B2–B3.
- **Slots are fixed:**
  - Players may leave gaps.
  - Units never slide when others die, so a death leaves an empty slot.
- **Targeting:** the back row can't be targeted while any front-row unit is alive.
- **Attack order:** front row left to right, then back row left to right, then repeat. Empty slots are skipped.

Consequences worth naming:
- **Summons:** a summon can fill the dead unit's own slot, the nearest empty slot, or a named slot.
- **Empty slots matter:**
  - An empty front slot uncovers nothing, because the back row is protected while any front unit lives.
  - It changes what counts as "adjacent" and "behind".
  - It changes the card count for Battlegrounds-style damage.
- **Back row as a reserve:** the back row is a protected reserve that fights only after the front row is gone. Its units attack after the front row in each cycle, but can't be hit until the front row falls.

---

## A. Combat keywords

| Keyword | Status | Rules text | Battlegrounds behaviour | Two-row potential |
|---|---|---|---|---|
| **Taunt** | Current (18 minions in the pool) | Paraphrase: enemies must attack Taunt minions first. | Attackers pick at random among enemy Taunt minions. With none, they pick from all ([rules](rules.md) §11.4). | The back row is already protected, so front-row Taunt only funnels attacks within the front row. New: **"Guard": a back unit with Guard makes the two front units it sits behind untargetable while it lives.** Or Taunt on a back unit has no effect until the front row is empty. |
| **Divine Shield** | Current (29) | Paraphrase: the first time this takes damage, ignore it. Blocks one instance, then is removed. | Blocks Venomous, Poisonous and cleave damage too. Many cards restore or refresh shields. | "Shield the unit in front": a back unit grants Divine Shield to both front units ahead of it at Start of Combat, or each time they lose one (once per combat). |
| **Windfury** | Current (6) | Paraphrase: can attack twice. In Battlegrounds the two attacks are back to back. | Picks a new target for each attack. Stops if the minion dies. Golden Windfury is no longer Mega-Windfury (26.2). | "Back-line Windfury": a back unit whose second attack waits until the back row's turn in the cycle. Or the second attack goes to the defender's back row if one is exposed. |
| **Mega-Windfury** | **Retired** 26.2 | [R] "(Can attack four times a turn.)" | Was given by golden Windfury minions. Removed for "design space" [N]. | Not needed. |
| **Reborn** | Current (13) | [R] "Resurrects with 1 Health the first time it dies." | Returns as a fresh copy with 1 Health and no buffs; golden stays golden. Resolves after all Deathrattles and Avenges. Appears where the minion died ([rules](rules.md) §11.6, §11.8). | Fixed slots make "where" clear: it returns to its own slot. New: **"Reborn behind"**: comes back in the back slot behind it, if empty, so the dead front unit becomes a protected back unit. |
| **Poisonous** | **Retired** in Battlegrounds, 26.2 | [R] earlier text: "Destroy any minion damaged by this minion." | Replaced by Venomous. Poisonous survived only on old cards and effects. | Not needed. |
| **Venomous** | Current (3) | [N] "Destroy the first minion this deals damage to each combat." (Before 36.2: without "each combat".) | One use per combat. Divine Shield blocks it; the shield takes the hit and the keyword is used up (INFERRED from "deals damage to"; UNVERIFIED). Changed in 36.2 because of Recruit-Phase Fishbait attacks. | "Venom spray": the first kill also poisons the enemy unit behind the target, once the back row is exposed. Or a back unit that lends Venomous to the front unit ahead of it. |
| **Stealth** | Current (1); also a Bonus Keyword | Paraphrase: can't be targeted until it attacks or deals damage. | Rarely used. When an attacker has no valid target because of Stealth, the simulator clears Stealth (`clearStealthIfNeeded`). The real-game rule is UNVERIFIED. | A back-row unit with Stealth stays untargetable even after the front row dies, until it attacks. A strong, easily read anti-snipe tool. |
| **Cleave** (informal name) | Current (Blade Collector) | [C] "Also damages the enemies next to whomever this attacks." | Neighbours take the same damage at the same time. Older cards: Foe Reaper 4000, Cave Hydra. | Three shapes: **row cleave** (left and right), **pierce** (the target plus the units behind it; harmless while the back row is protected unless it ignores that protection), and **fan** (the target, its neighbours and the units behind). Gaps limit cleave: no neighbour, no splash. |
| **"Attack immediately"** | Current (1); more historically | [C] example: P-0UL-TR-0N, "Avenge (5): Gain Divine Shield and attack immediately." | Jumps the attack queue, then the normal order resumes. | "Step forward": a back unit moves into an empty front slot and attacks immediately. Uses gaps directly. |
| **Overkill** | **Retired** (0 in the current pool; 3 ever) | Paraphrase: triggers when this deals more damage than needed to kill the target. | Attack-only trigger. Example: Ironhide Direhorn, "Overkill: Summon a 5/5 Ironhide Runt." Spiritual successor: Wildfire Elemental [C], "deal excess damage to an adjacent enemy". | "Overkill: excess damage carries through to the unit behind the target." The cleanest two-row trample. |
| **Frenzy** | **Retired** (0 current; 1 ever) | Paraphrase: triggers the first time this takes damage and survives. | Added 20.2 with Quilboar. | "Frenzy: the units behind this gain X." A front tank that buffs its back row when hit. |
| **Immune** | **Retired** (0 current; 3 ever) | Paraphrase: prevents all damage. | E.g. Warpwing, "Immune while attacking"; Mal'Ganis made the hero Immune. | "Immune while a unit is behind this": rewards keeping the back slots filled. |
| **Charge / Rush / Lifesteal / Silence / Elusive** | Not Battlegrounds keywords (Charge 1 old card, the rest 0) | — | Battlegrounds has no hero attacks and no player targeting in combat, so most constructed keywords don't apply. | Lifesteal could heal the hero if Bramble adds hero healing. Otherwise skip. |

## B. Triggers and timing words

| Keyword | Status | Rules text | Battlegrounds behaviour | Two-row potential |
|---|---|---|---|---|
| **Battlecry** | Current (49) | Paraphrase: triggers when played from hand. | Recruit Phase only. Murlocs re-trigger Battlecries, e.g. Young Murk-Eye [C], "At the end of your turn, trigger the Battlecries of adjacent minions." | **Slot-aware Battlecry:** the effect depends on where the unit is played (front or back, or which slot). E.g. "Battlecry: if played in the back row, give the two units in front +2/+2." |
| **Deathrattle** | Current (54) | Paraphrase: triggers when this dies. | Resolves left to right (summoning order). Natural Deathrattle first, then granted ones, then Avenge progress. Summons appear in the dead minion's slot; on a full board they are lost ([rules](rules.md) §11.6). | With fixed slots, "summon in this slot" is guaranteed space. New: "Deathrattle: the units behind this gain its Attack" (a passed torch). "When the unit in front of this dies" (owner's example) is a natural trigger on the back row. |
| **Avenge (X)** | Current (6) | [R] "Does something after X friendly minions die in combat." | Counts friendly deaths in this combat. Progresses after each death's Deathrattles, then triggers. Repeats every X deaths (INFERRED from card wording; UNVERIFIED). Added 21.2. | **Row-scoped Avenge:** "Avenge (2, front row)" counts only front-row deaths. Back units naturally avenge the front line. |
| **Rally** | Current (28) | [R] "Does something whenever it attacks." | Resolves before damage, after "when attacked" effects (SIM). Added 32.2. Mainly Quilboar and Dragons. Example: Seafloor Recruiter [C], "Rally: Cast Chef's Choice on the minion to the right." | "Rally: the unit behind this also attacks" or "gains +X". Back-row Rally fires late in the cycle, which pairs well with "after the front row has attacked" payoffs. |
| **Start of Combat** | Current (14) | Paraphrase: triggers at the start of each combat. | Phased order: quest rewards, anomalies, trinkets, hero powers (pre, Illidan, rest), secrets, then minions. In the minion phase a random player resolves all of theirs left to right, then the other player (SIM; [rules](rules.md) §11.2). | Two-row geometry makes setup effects rich: "Start of Combat: swap with the unit in front", "move to an empty front slot", "give the units behind Taunt". Define one global slot order (F1–F4, then B1–B3) for resolution. |
| **"At the end of your turn"** (End of Turn) | Current (23 tagged) | [C] example: Surfing Sylvar, "At the end of your turn, give adjacent minions +1 Attack." | Recruit-Phase trigger. Order across minions is UNVERIFIED (believed left to right). | "End of turn: give the units in front +X" or "…behind +X". Back-row buffers for the front line are an obvious archetype. |
| **"Once per turn" / counters** | Current | [C] "(1 left!)", "(6 Gold left!)" | Displayed counters reset each turn or count up to a threshold. | Counters could be per row, e.g. "after 3 front-row units die". |

## C. Recruit-Phase keywords and mechanics

| Keyword | Status | Rules text | Battlegrounds behaviour | Two-row potential |
|---|---|---|---|---|
| **Magnetic** | Current (11; Mechs) | [R] "Play this to the left of a Mech to fuse them together!" | Adds its stats and text to the Mech. Counts as playing, not summoning. Works on a full board since 26.2. Can't be used in combat. | "Magnetize behind": attach to the unit in front, or let a back unit act as a socket that feeds both front units ahead of it. |
| **Spellcraft** | Current on cards; Naga rotated out 22 Sep 2026 (13 in data) | [R] "Gain a temporary spell every turn." | The spell comes when the minion is played and at the start of each Recruit Phase. It leaves your hand at the end of your turn. Golden gives a golden spell with double effect. If your hand is full, it waits for space. Added 23.2. | Temporary spells that target a slot rather than a unit ("Front-row ward: F2 and F3 get +2 Health this combat") make the grid itself a target. |
| **Choose One** | Current (10) | Paraphrase: choose one of two or more effects. | Thorned Trailblazer [C]: "One Choose One card each turn has both effects combined." | Choose by placement: front placement gives one mode, back placement the other. That removes a dialog and teaches the board. |
| **Discover** | Current (9 minions, plus systems) | Paraphrase: choose one of three cards. | Draws from the lobby pool and removes the chosen card. Used by the Triple Reward (next tier) ([rules](rules.md) §10). | Discover a unit together with a slot recommendation, or "Discover a back-row unit" as a pool filter. |
| **Activate (X)** | Current (23); added 36.2 | Wiki paraphrase: "Once per turn during the Recruit phase, pay {X} Gold to use the effect." [C] example: Suspicious Prisonguard, "Activate (1): Give another minion +3/+3." | Click the minion on your board. Once per turn. Discarding a card is sometimes the cost (Aberrations). | "Activate (1): swap this with an adjacent or behind unit", "Activate: lock this slot" (an empty slot that can't be filled by summons). These give gaps a gold value. |
| **Blood Gem** | Current (20; Quilboar) | [N] 20.2: "spells that give a friendly minion +1/+1." Improved by Quilboar effects. | A spell token in hand. Victorious Geomant [C] casts "any that don't fit on your left-most minion." | "Blood Gems cast on a back unit also give half to each unit in front" (a row-aware ramp). |
| **Bonus Keyword** | Current (5) | Wiki paraphrase: a random one of Divine Shield, Reborn, Stealth, Taunt, Venomous or Windfury. | Usually lost after combat unless something says "permanently keep" ([C] Tarecgosa, Persistent Poet). | "Adjacent or behind units keep Bonus Keywords" makes position matter for scaling. |
| **Tavern spell** | Current (permanent since 29.2) | — | Bought from the shop slot; single use; variable price ([rules](rules.md) §8). | Spells with grid shapes: "column" (a front slot and the back slot behind it), "row", "diagonal". |
| **Free Refresh** | Current | — | Shown on the Refresh button since 34.2. | Ties into Bramble's escalating reroll cost: decide whether a free refresh resets the escalation counter. |
| **Tavern Coin** | Current | [C] "Gain 1 Gold." (Tier 1 Tavern spell) | Since 34.2 many gold effects give Tavern Coins instead of gold, so gold can be held in hand. | Fits Bramble's gold carry-over decision: coins are a natural way to cap or track banked gold. |
| **Consume** | Current (5; Demons) | [C] e.g. "Activate (2): Your Demons each consume a random minion in the Tavern to gain its stats." | Takes stats from shop minions (or friendly ones). | "Consume the unit in front": a back unit eats a front unit, which opens a front gap on purpose. |
| **Discard** | Current (13; Aberrations); added 36.6.1 | [C] e.g. "Activate (0): Discard a card to give your Deity +2/+2." | Discarding is a cost or a trigger. Some spells are "cast twice if discarded"; Corrupted Coin raises max gold by 2 if discarded [N]. | Not geometric. It pairs with a hand-as-third-row idea (hand slots as a reserve row). |
| **Golden / Triple** | Core | — | 3 copies make a golden with double base stats, keeping net buffs and at least base golden stats; it gives a Triple Reward ([rules](rules.md) §9). Some cards are "always Golden" [C] (Aureate Laureate). | "Golden auras reach further": a golden back unit affects all front units, not only the two ahead of it. |

## D. Tribe- and season-specific keyworded mechanics

| Mechanic | Status | Rules | Two-row potential |
|---|---|---|---|
| **Deity** (Aberrations) | Current, added 36.6.1, changed 36.6.3 | One Deity per game, C'Thun or Y'Shaarj at random. Each friendly Aberration death in a combat advances it; after **4** (was 3) it joins that combat. Deities are Tier 1. C'Thun [N]: "After this awakens, give this minion's stats split amongst your other minions." Y'Shaarj resummons the first 2 Aberrations that died ([ABR](https://hearthstone.blizzard.com/en-us/news/24302091), [36.6.3](https://hearthstone.blizzard.com/en-us/news/24303864/3663-patch-notes)). | Arrives in the first empty slot, front first, or in the slot of the last death. A "summon to an empty slot" rule makes gaps a resource. |
| **Lockbox** (Pirates) | Current, Season 14 | Holds a golden minion that unlocks on a later turn. [C] "Get a Lockbox. If you already have one, it opens 1 turn sooner instead." | A Lockbox that sits in a board slot (front or back) and fights as a dummy until it opens. |
| **Fishbait** (Beasts) | Current, Season 14 | [C] Lurking Lionfish: "Activate (2): Choose a card in the Tavern. Replace it with a Fishbait for your left-most Beast to attack." Reward for the minion that "takes the bait" [N]. First Recruit-Phase attack in Battlegrounds; forced the Venomous change. | "Your F1 unit attacks it", or let the player pick a row. Shows why keyword scopes (this combat versus this turn) must be explicit. |
| **Dark Gift** | Current, Season 14 | From turn 3, pay 3 gold to Discover 1 of 3 minions, each with a unique gift. Once per turn, at most 3 per game. 43 gifts ([36.2](https://hearthstone.blizzard.com/en-us/news/24290432)). | Gifts that are positional: "while in the back row", "while nothing is in front of this". |
| **Chromadrake** (Dragons) | Season 13; removed from the Tavern in 36.2 but still generated | [N] "One of five Dragons with various Battlecries." (Before: "One of five Tier 3 Dragons…".) | Five colours could map to five slot shapes (row, column, diagonal, adjacent, behind). |
| **Fodder** (Demons) | Season 13; current status UNVERIFIED | Fodder tokens are added to your pool for Demons to consume. | Fodder placed in the back row as stored food for front Demons. |
| **Bounty** (Pirates) | Season 11 (33.2); current status UNVERIFIED | Five Tier 3 Tavern spells, in Pirate lobbies only. | — |
| **Beetle** (Beasts) | Card mechanic (4 current) | Tokens with "Beetle"-specific buffs. Trinket example [C]: "Avenge (5): Summon a 2/2 Beetle. Give it Taunt." | Swarm tokens that fill empty back slots first. |
| **Elemental Tavern buffs** | Card mechanic | "Minions in the Tavern have +X/+X this game." | Not geometric; it lives in the economy layer. |
| **Undead Attack auras** | Card mechanic | "Your Undead have +X Attack" for the whole game. | — |

## E. Retired or seasonal systems with keyword-like rules

| System | Status | Rules | Two-row potential |
|---|---|---|---|
| **Buddy** | Off since 34.2 (on 4 times) | A hero-specific minion. Meter version (22.2): fills in combat. Button version (25.6): 11–21 gold, cheaper each round. | A "Buddy slot": a guaranteed eighth slot behind the back row. Probably too much. |
| **Quest** | Off since 33.6 | Turn 4: pick 1 of 3 Quest–Reward pairs. Requirements scale with the reward's strength and your hero's armor. | Quests could count positional achievements ("win with an empty back row"). |
| **Anomaly** | On and off (not confirmed in Season 14) | One lobby-wide rule per game. E.g. "Big League" (Tiers 3–6 only); "Prudence of Amitus" (unspent gold carries over, +1 if you saved 5). | Board-shape Anomalies: "3-3 board this game", "back row can be targeted". A cheap source of variety on top of the grid. |
| **Trinket (Lesser/Greater)** | On in Season 14 | Turn 6 Lesser and turn 9 Greater offers, 4 options each, 0–6 gold, kept for the game. | Trinkets that change the grid: unlock a 4th back slot, or make slot B2 "fortified". |
| **Darkmoon Prize** | Retired 2021 | Every 4 turns, Discover a 0-cost prize. | — |
| **Timewarped Tavern / Chronum** | Season 12 only | A separate shop on turns 6 and 9 with 2 Chronum per visit; Timewarped cards triple only with each other. | — |
| **Spell "Temporary summon"** | Current (wiki-listed) | Wiki paraphrase: copies a card from hand for that combat only; the original stays in hand. | Temporary summons into empty slots only, so leaving gaps pays off. |

## F. Effect scopes (for Bramble's keyword framework)

| Scope wording | Meaning in Battlegrounds | Two-row extension |
|---|---|---|
| "adjacent" / "next to" | Left and right neighbours in the single row (6 current cards). A board gap doesn't exist in Battlegrounds; minions slide together. | Same row only. Gaps break adjacency, since slots are fixed. |
| "left-most" / "right-most" | By board order. Common in Recruit-Phase effects, e.g. 23 current cards say "left". | Per row (front-left-most) or by global slot order (F1 … B3). |
| — | Not available in Battlegrounds. | "in front of" / "behind": diagonal neighbours across the rows (B1 ↔ F1, F2). |
| — | Not available in Battlegrounds. | "column" / "covering": a front unit and all back units behind it. |
| "your minions" / "your [Tribe]" | The whole board. | Can be restricted to a row: "your front-row units". |
| "this combat" / "permanently" / "this game" / "this turn" | See [rules](rules.md) §13. | Unchanged. Needs explicit scopes as Recruit-Phase combat (Fishbait) shows. |
