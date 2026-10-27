# Once Upon a Galaxy: rules and systems

**State described:** the live game as of **27 October 2026**. That is the Chromaria set (released 28 Sep 2026) plus the "Shared Pool Shakeup" patch of 22 Oct 2026, the latest patch found ([source](https://galaxy.fun/articles/patch-mid-october-2026/)).

**Game facts**
- Developer and publisher: Million Dreams Games ([Steam](https://store.steampowered.com/app/3062740/Once_Upon_a_Galaxy/)).
- Leads: Matt Place, who co-founded Good Luck Games (Storybook Brawl) and was a senior designer on Hearthstone; Alexis Janson (engineering, ex-MTG Arena/MTGO); Andrew Parnell (executive producer). Sources: [team](https://milliondreamsgames.com/), [Place](https://galaxy.fun/articles/meet-the-dreamers-matt/), [Janson](https://galaxy.fun/articles/meet-the-dreamers-alexis/), [press release](https://www.gamespress.com/Million-Dreams-Games-Announces-Once-Upon-a-Galaxy).
- Release history:
  - Closed alpha before mid-2024.
  - Open beta at GenCon, 1–4 Aug 2024.
  - Early Access with store and Galaxy Pass, 5 Dec 2024.
  - Steam launch, **29 Jul 2025**.
  - See [patch-history.md](patch-history.md) for sources.
- Platforms: Windows, macOS, iOS and Android, with cross-platform accounts and cross-play ([Steam](https://store.steampowered.com/app/3062740/Once_Upon_a_Galaxy/), [App Store](https://apps.apple.com/us/app/once-upon-a-galaxy/id6504776189), [roadmap](https://galaxy.fun/articles/roadmap-2027/)).
- Business model: free to play. Premium captains go free after 2 months; there is a monthly Galaxy Pass, theme decks, Set Rerolls and Infinity Tokens ([monetization](https://guide.galaxy.fun/monetization/)).

**Main sources**
- The official **Galaxy Guide** at guide.galaxy.fun, which the developer runs; its footer credits Million Dreams Games. Every guide page cited below was fetched on 27 Oct 2026.
- The official site's Learn page ([galaxy.fun/learn](https://galaxy.fun/learn/)) and all 72 official articles (see [patch-history.md](patch-history.md)).
- The community wiki ([onceuponagalaxy.wiki.gg](https://onceuponagalaxy.wiki.gg/)).

**Labels.** **INFERRED** means I drew the conclusion from wording or card text; no source states it. **UNVERIFIED** means no public source was found.

---

## Comparison at a glance

The Battlegrounds column is a baseline summary from general knowledge of the game around 2025. It was not re-researched for this file, so check exact numbers against Bramble's Battlegrounds research before relying on them.

| System | Galaxy | Battlegrounds | Notes for Bramble |
|---|---|---|---|
| Players per lobby | 6 | 8 | Galaxy's ranked games are async: you fight recorded "ghost" boards from earlier runs. |
| Live vs async | Ranked play is async ghosts. Live play exists in friend lobbies. | Live, with a turn timer | Async removes timers. Ranked live lobbies were planned in 2025 but never shipped. |
| Player life | 3 hearts. A loss cracks or empties one heart, so each loss costs ½ or 1 heart. | About 30 health plus armour. Damage = opponent's tier + surviving minions' tiers. | Galaxy caps damage at 1 heart per fight, so every player survives at least 3 losses. |
| Currency | **None.** You get a fixed number of shop picks per turn (2 by default). | Gold: 3 on turn 1, +1 per turn, max 10 | Galaxy's economy is counted in picks and bonus shops, not gold. |
| Shop | 3 characters, plus 1 spell from turn 3. Take exactly one card per shop. | 3–7 minions by tier, plus spells. Buy as many as you can afford. | |
| Rerolls | None by default. Only card effects add shops. | 1 gold each | |
| Selling | Removed (Aug 2024). Recruiting onto a full slot replaces that character. | Sell for 1 gold | |
| Tiers | Shop rarity rises automatically: Common T1, Uncommon T3, Rare T5, Epic T7, Legendary T9. Secret Rare only through effects. | Tavern tiers 1–6 (sometimes 7), bought with gold | Galaxy has no levelling decision; the clock levels you. |
| Board | 5 fixed slots: 3 front, 2 back, staggered. Plus a Bank slot. | 7 slots in one row; hand of 10 | Galaxy's layout is a small version of Bramble's staggered board. |
| Copies / triples | Seeing a card again after taking it shows it as Silver (+1/+1 and a bonus shop). The third copy is Golden (+1/+1 more, a treasure shop, often doubled ability). | Three copies make a golden: doubled stats and effect, plus a discover from one tier up | Galaxy needs no hand or duplicates: the copy replaces the original in place. |
| Buff persistence | **All buffs are permanent**, including buffs gained during a fight and buffs on summoned tokens. | Combat buffs vanish, except named exceptions | This is a big difference. Galaxy's stats reach the hundreds or thousands. |
| Slot effects | Slot buffs and Paint attach to a board position | None (some effects key off left- or rightmost) | |
| Heroes | Captains, chosen from 3. Each has a passive power and brings a 12-card deck. | Heroes with a hero power, chosen from 2–4 | |
| Card pool | Shared pool plus your own 12-card deck. Pools are per player, not shared. | Shared, limited copies; 5 of about 10 tribes per lobby | Galaxy varies games through decks and captains, not tribe bans. |
| Other card types | Spells, Treasures (permanent run bonuses), Boons (conditional treasures) | Tavern spells, trinkets, quests and anomalies, which vary by season | |
| Discover | Treasure shops offer a choice of 3, from goldens, quests and effects | Discover 1 of 3 | |
| Combat order | Random first attacker. Slots attack left to right, front to back. Alternation between players is INFERRED. | The side with more minions starts. Alternating, leftmost first. | |
| Targeting | A random front-row enemy. Sneak hits the back row first. | Random, with Taunt forcing targets | |
| Damage exchange | Simultaneous, except Ranged takes no retaliation | Simultaneous | |
| Anti-infinite limits | 5 resummons per character. At most 30 shops a turn (Limit Breaker). An overlong async fight is a win for the active player. | Implicit (combat turn limit) | Galaxy added each limit after real loops appeared. |
| Game length | About 10–20 minutes (player reports) | About 30–45 minutes | |

---

## 1. Match structure

- **Lobby.** 6 players. In an async game the other 5 are recorded runs from real players of similar hidden MMR. Their decisions replay turn by turn, and simulated fights between them decide the lobby's heart damage ([Asynchronous Gameplay](https://guide.galaxy.fun/asynchronous-gameplay/)).
  - Opponents are always on the same turn as you.
  - A run that ended early stays frozen on its last board.
  - In friend lobbies with an odd number of players left, one player faces an "Evil Twin" copy of another board. The twin takes no heart damage ([same page](https://guide.galaxy.fun/asynchronous-gameplay/)).
- **Pre-game** ([Captain Select](https://guide.galaxy.fun/captain-select/), [Decks](https://guide.galaxy.fun/decks/)):
  1. Choose 1 of 3 captains. Slot 3 has one free reroll per game and may show an unowned captain. Slot 2 can be rerolled with owned paid "Set Rerolls". Captains are unique within a lobby ([patch 26 Jul 2024](https://galaxy.fun/articles/patch-open-beta/)).
  2. Choose one of that captain's **12-card decks** of collectible cards.
  3. The deck is shuffled into the **shared pool** to make your personal card pool for the game. Collectible cards outside your deck never appear for you. Your 12 cards are no likelier to appear than shared cards of the same rarity.
- **Turn.** Each turn is a **Shop phase** then a **Fight** against one opponent ([Fight](https://guide.galaxy.fun/fight/)).
- **End.** You play until you run out of hearts or are last standing. Finishing top 3 counts as a "victory" for rewards ([Rewards](https://guide.galaxy.fun/rewards/)). Ranked "jewels" go from +3 for 1st down to −2 for 6th ([Ranks](https://guide.galaxy.fun/ranks/)).
- **Length.** Players report 10–20 minutes per game ([Steam reviews](https://steamcommunity.com/app/3062740/reviews/?browsefilter=mostrecent&filterLanguage=english)).
  - INFERRED: hearts bound the length. Each loss costs at most one heart, so elimination takes at least 3 losses and at most 6.
  - Captain texts reference turns 8, 9 and 10, so games commonly run past turn 10 (INFERRED).

## 2. Economy: shops, picks and rarity

There is **no gold, no rerolling and no selling** ([Shop](https://guide.galaxy.fun/shop/); selling was removed on [27 Aug 2024](https://galaxy.fun/articles/patch-early-september/)).

**Shops**
- A shop shows **3 characters**. From **turn 3** it also shows **1 spell** ([Shop](https://guide.galaxy.fun/shop/), [Spells](https://guide.galaxy.fun/spells/)).
- You take **one** card per shop: recruit a character to the board or bank, or cast the spell. The Learn page says "Each turn you get 2 shop selections before battle" ([Learn](https://galaxy.fun/learn/)).
- Whether you can skip a shop without taking anything is UNVERIFIED.
- **Two shops per turn** by default ([Shop](https://guide.galaxy.fun/shop/)).

**Bonus shops** are extra free shops in the same turn. They come from:
- taking a Silver;
- spells such as "Lost in the Woods: Get a bonus shop";
- losing, through some captains and cards (Ace of Hearts, Gloria Clementine);
- captain effects.

**Treasure shops** offer a choice of 3 treasures. **Spell-only shops** and **all-faction shops** ("Your next shop contains all Fae") also exist through card effects.

**Shop cap ("Limit Breaker").** After 30 shops in one turn you are offered the Limit Breaker treasure (+10/+10 to your characters) and get no more bonus shops that turn.
- Queued shops still resolve, and the cap doesn't block treasure or captain shops.
- It was introduced at 20 on 30 Apr 2026 and raised to 30 on 11 May 2026. Its stated purpose is to bring "long silver and spell chained shops to a conclusion" ([May 2026 patch](https://galaxy.fun/articles/patch-mid-may-2026/)).

**Rarity ("shop level").** The shop levels up automatically on a fixed clock ([Shop](https://guide.galaxy.fun/shop/), [Rarity](https://guide.galaxy.fun/rarity/)):

| Turn | Rarity added to the shop |
|---|---|
| 1 | Common |
| 3 | Uncommon |
| 5 | Rare |
| 7 | Epic |
| 9 | Legendary |
| — | Secret Rare: only through special effects (e.g. the captain Artemis: "Your shop can level up to Secret Rare") |

- Lower rarities stay in the pool.
- Janson says the pool is "weighted towards the higher rarity" so that few picks still give plausible options ([Beacon of Creation](https://www.beaconofcreation.com/2025/10/01/design-crossover-once-upon-a-galaxy/)). The exact weights are UNVERIFIED.
- Captains can shift the clock. Skip "Level up a turn early, but skip your first turn"; Bo Peep: "Animals appear in your shop one rarity sooner"; Itty Aerie gets a one-rarity-higher shop on level-up but only one shop that turn (card database).
- Random summons are limited to your current shop rarity ([Summon](https://guide.galaxy.fun/summon/)).

**Pool gating.** Candy spells appear only if your deck has Candy cards or a Candy captain. Paintbrush spells appear only for the colours your cards reference ([Candy](https://guide.galaxy.fun/candy/), [Paint](https://guide.galaxy.fun/paint/)).

**Bank slot.** An extra off-board slot ([Banking](https://guide.galaxy.fun/banking-characters/)).
- It is usable only once all 5 board slots are filled.
- Banking a character triggers all its Recruit effects and counts as recruiting it for Silver and Golden progress. A banked Silver still gives its bonus shop; a banked Golden still gives its treasure shop.
- The banked character never fights. Spells can't be banked.
- Banked questers don't progress or complete quests.

**Replacing.** Recruiting onto an occupied slot replaces that character. INFERRED from the guide's drag-to-slot description and card texts such as Charon ("When you replace a Golden character…") and Quest notes ("recruit directly onto its slot… while replacing the quester", [Quests](https://guide.galaxy.fun/quest/)). Whether the replaced character returns to the pool is UNVERIFIED.

## 3. Copies: Bronze, Silver, Golden

Galaxy has no triples from a hand. The upgrade is a "seen again" rule ([Learn](https://galaxy.fun/learn/), [Characters](https://guide.galaxy.fun/characters/), [Silver](https://guide.galaxy.fun/silver-characters/), [Golden](https://guide.galaxy.fun/golden-characters/)):

- **Bronze.** The first time a character appears it is Bronze, with no bonus.
- **Silver.** After you recruit a character, it appears in later shops as **Silver**. Recruiting it:
  - gives **+1/+1** over Bronze and a **Bonus Shop** (the Learn page calls taking a Silver "free" for this reason);
  - replaces the Bronze copy automatically if it is on your board.
- **Golden.** The next copy after a Silver appears as **Golden**. Recruiting it:
  - gives **+1/+1 more** (the guide's card viewer shows base +2/+2);
  - gives a **Treasure Shop** of the character's rarity;
  - removes the character from your pool for the rest of the game.
  - "Many characters (but not all)" have doubled abilities when Golden.
- **Spell upgrades.** Upgrading with a spell (Silvery Moon, Midas Touch) gives no bonus shop or treasure. "When you Silver/Golden me" effects still trigger.
- **Buffs carry over.** Copies inherit buffs: a Silver offered in the shop already includes the Bronze copy's permanent buffs ([Buffs](https://guide.galaxy.fun/buffs/)).

## 4. Board and positioning

The rules below are the precise answer to "does Galaxy pack units?" Sources: [Board](https://guide.galaxy.fun/board/), [Attack Order](https://guide.galaxy.fun/attack-order/), [Summon](https://guide.galaxy.fun/summon/), [Farewell](https://guide.galaxy.fun/farewell/), [Slot Buffs](https://guide.galaxy.fun/slot-buffs/), [Sneak](https://guide.galaxy.fun/sneak/).

**Layout**
- **5 fixed slots**: 3 front (top) and 2 back (bottom), plus the Bank. The guide's board image is captioned "three slots in front of two slots in back".
- The image shows the back slots **centred in the gaps**: slot 4 sits between front slots 1 and 2, and slot 5 between front slots 2 and 3. Galaxy uses the same brick stagger as Bramble.
- Slots are numbered 1–5, left to right and front to back.

**Slots are first-class objects**
- **Slot buffs** live on a slot and stay when the character there changes.
- **Paint** colours a slot permanently.
- "Your first slot" or "first character" means slot 1 "regardless of whether or not the slot has a character in it". So **slot 1 can be empty**, and slot-referencing effects don't move to the next character.

**No packing in a fight** (strongly implied; no sentence says "units do not slide" verbatim). When a character is KO'd its slot stays empty:
- A summon "is the same slot as the source that summoned it (if that character was KO'd)".
- A Farewell's first summon appears "in the same slot where the Farewell character was".
- "If there is no space on the board, the summon will fail."
- A summoned character "inherit[s] the same attack priority as its source". If it enters a slot that just attacked, it gets the next attack.
- Leftover Pieces gives "the slots behind" a KO'd Toy +1/+1.
- These rules only make sense if positions are fixed slots that keep their identity through deaths.

**Empty slots during the shop phase**
- Early turns necessarily have empty slots: you get 2 picks on turn 1 and have 5 slots.
- You can move characters between slots during the shop phase. Evidence:
  - The Steam page says you "carefully position your cards".
  - Since Oct 2024, picking up a character shows its stats without support buffs ([patch 10 Oct 2024](https://galaxy.fun/articles/patch-early-october/)).
  - Picking up a character shows the slot buffs on a slot ([Slot Buffs](https://guide.galaxy.fun/slot-buffs/)).
  - A community guide quoted in search results (ouagalaxy.wiki, now unreachable) says you can "rearrange your Characters into the order of your choice" before the fight.
- Whether you can deliberately leave a front slot empty while the back is filled is **UNVERIFIED**. Nothing found forbids it, and the same community guide says that with no front-row characters, attacks go to the back row.

**Neighbour vocabulary on cards** (card database):
- **"in front of me"** (Support, from a back slot): the two front slots the back slot sits between. A back slot therefore has **two** characters in front of it, and front slot 2 has **two** supports behind it.
- **"behind me"** (front-slot effects such as Sleeping Giant, Huntsman's Axe and Daisy Jones): the back slot or slots touching that front slot. INFERRED: front slots 1 and 3 have one slot behind; front slot 2 has two.
- **"neighbors" / "adjacent"** (Gingerbread House, Greenbeard, Sapphire, Netherbinder): the exact adjacency graph is UNVERIFIED. INFERRED: same-row left and right neighbours.
- **"the enemy across from me"** (Mirror Mirror, Viscount Chocolat, Mix-O Match-O): an enemy in the mirrored slot. The facing rule for a back-slot character is UNVERIFIED.
- **"front row" / "back row"** (Bounty Contract, Crow's Nest, Parting Gift, Osiris, Witches III, The Kraken): explicit row-wide effects.
- **"the slots behind where I attack"** (Snapping Hydra): splash damage through the defender to the back row.

## 5. Combat resolution

Sources: [Attack Order](https://guide.galaxy.fun/attack-order/), [Ranged](https://guide.galaxy.fun/ranged/), [Sneak](https://guide.galaxy.fun/sneak/), [Hunt](https://guide.galaxy.fun/hunt/), [Farewell](https://guide.galaxy.fun/farewell/), [Transform](https://guide.galaxy.fun/transform/).

**Who attacks first**
- The first attacker is random by default.
- Effects can grant it: Warp Drive Engine ("You get the first attack"), Jelly Roger. If both players have such an effect, they "may cancel each other out (or stack when duplicated)".

**Order**
- Each player's characters attack "in left-to-right, front-to-back order, starting with the top-left 'Slot 1'". Empty slots are skipped (INFERRED).
- INFERRED: the two players alternate single attacks, as in Battlegrounds. The guide's "player who gets the first attack" implies alternation but doesn't spell it out.
- INFERRED: the order cycles until one side is out of characters. Dragonling's quest "I attack 3 times" implies characters attack more than once in a fight.

**Targeting**
- An attacker hits a **random enemy in the front row** if any exist ("Characters attack a random front row enemy if possible"). Otherwise it hits the back row. The fallback is stated by the community guide and implied by "if possible".
- **Sneak**: attacks one of the two back-row enemies at random. If there are none, it attacks any enemy.
- There is no Taunt equivalent; the front row itself is the taunt.
- Some effects choose targets: "Shrink Tea" targets the enemy with the highest attack ([patch 18 Sep 2025](https://galaxy.fun/articles/patch-mid-september-2025/)).

**Damage**
- Attacker and defender deal their Attack to each other at once.
- **Ranged**: an attacking Ranged character takes no damage back. A Ranged character that is attacked takes damage normally.
- A character at 0 Health is **KO'd**. KO'd characters return after the fight; every fight starts from your saved board ([Characters](https://guide.galaxy.fun/characters/)).

**Triggers**
- **Hunt** fires when this character attacked and KO'd the defender, even if the attacker also died.
- **Farewell** fires when this character is KO'd, whether or not it was attacking.
- "Each fight" abilities fire at the start of the fight (INFERRED from wording and the Paint and Support texts).
- Simultaneous-death ordering is UNVERIFIED. The 18 Sep 2025 patch moved Hunt buffs to resolve *before* effects such as Poison Apple, so that answers to big stats land after the buffs.

**Mid-fight changes**
- A transformed character counts as a new character for attack order.
- Transforms keep buffs and damage already taken ([Candylar release](https://galaxy.fun/articles/candylar-release/)).

**Persistence**
- Buffs gained during a fight are **permanent**, including buffs on summoned tokens: "Summons keep their buffs!" ([Buffs](https://guide.galaxy.fun/buffs/), [Summon](https://guide.galaxy.fun/summon/)).
- Auras (most Support buffs) apply only while the source is on the board.

**Loop guards**
- A character can be resummoned at most 5 times ([patch 3 Jul 2024](https://galaxy.fun/articles/patch-early-july/)).
- If an async fight is abandoned for complexity or an infinite loop, "we now count it as a battle win for the active player" ([27 Aug 2025](https://galaxy.fun/articles/patch-early-september-2025/), [20 Nov 2025](https://galaxy.fun/articles/patch-mid-november-2025/)).
- Since Jul 2025, a trigger that repeats 3 or more times plays one animation with a multiplier.

**Ties** exist: Old Coyote's "Prophecy — Tie a fight"; Whirlidoo's "When you lose or tie a fight". Heart damage on a tie is UNVERIFIED; probably none.

## 6. Hearts and elimination

Source: [Heart Damage](https://guide.galaxy.fun/heart-damage/).

- Each player has **3 hearts**. You are eliminated when you run out.
- **If you lose** a fight:
  - The opponent has **2 or fewer** characters left: one heart **cracks** (½). A heart that is already cracked is emptied.
  - The opponent has **3 or more** characters left: one heart is **emptied**, whether it was full or cracked.
- **Finals.** With 2 players left, every loss empties a heart.
- **Healing.** Winning while you have a cracked heart heals it to full. Emptied hearts are permanent.
- **Modifiers:**
  - Bonus hearts: Lich King's Heart; Baldr starts with 4.
  - Midas starts on 2.5 hearts.
  - Gentle Giant: "When you win a fight, you only deal half a heart in damage." The design reason was to "help you survive the early game" ([19 Feb 2026](https://galaxy.fun/articles/patch-mid-february-2026/)).
  - Bubbles turns your first emptied heart into a crack.

## 7. Captains

Sources: [Captains](https://guide.galaxy.fun/captains/), [Prophecy](https://guide.galaxy.fun/prophecy/).

- Each captain is a passive rule-changer for the whole run, with no activated power. Examples:
  - Ares: "Each fight, double the Attack of your characters."
  - Osiris: "Starting on turn 3, at the start of each fight trigger all of your Farewell abilities in your front row."
  - Toucan Samuel: an extra shop per turn, but shops have only two characters.
- Many captains change the shop or the pick structure rather than adding stats. That is where Galaxy's "economy" design lives.
- **Prophecy.** A card's Prophecy, once completed, makes you a new, stronger captain. Your old captain stays on as co-captain.
- The card database lists 116 captain entries, 115 of them current. These include prophecy and token captains that can't be picked at select; see [content-library.md](content-library.md).
- New premium captains release monthly and go free after 2 months.

## 8. Other card types

**Spells.** One-use effects from the shop's 4th option, from turn 3. Taking one uses that shop. Some target a character or slot (cast by dragging onto it); others have no target. Bonus spells must be cast ([Spells](https://guide.galaxy.fun/spells/)).

**Treasures.** Permanent bonuses for the run ([Treasures](https://guide.galaxy.fun/treasures/)).
- **Sources:** Golden copies (rarity = the character's), Quests (rarity = the quester's), spells and card effects.
- **Wording:** "Discover" or "Choose" means pick 1 of 3; "Get" means a direct gain.
- **Cap:** there is a maximum number of treasures; past it, new treasures remove the oldest. The exact cap is UNVERIFIED.
- **Treasure Find:** a character's first treasure is a specific unique one.

**Boons** (since Mythbound, Apr 2026). Treasures with a condition that reward you once completed, then disappear ([Boons](https://guide.galaxy.fun/boons/)).
- You don't get them from goldens or quests, only from card effects.
- The developers retimed several Boons to check at the start of the fight, so a Boon can't be completed twice in one turn ([11 May 2026](https://galaxy.fun/articles/patch-mid-may-2026/)).

**Slot buffs and Paint.** See section 4 and the [Paint](https://guide.galaxy.fun/paint/) table:
- Any coat of paint: +1/+1 slot buff.
- **Red**: +1 Attack to the ability of the character in that slot each fight.
- **Yellow**: +1 Health to that ability each fight.
- **Blue**: +1/+1 to the slot when you cast a spell.
- **Secondary colours** combine two effects and double them.
- **Rainbow**: +4/+4.
- A slot takes at most two colours unless a card says otherwise. Paint can't be removed.

**Candy** (a card supertype from Candylar, Oct 2025). A shared sweetness counter adds +1/+1 to every stat-buff on your Candy cards for each time you have Sweetened ([Candy](https://guide.galaxy.fun/candy/)).

## 9. Factions (character types)

- **Major factions:** Animal, Dragon, Fae, Mage, Pirate, Toy, Hero, Villain and Candy ([Factions](https://guide.galaxy.fun/factions/)).
- **Minor types:** Celestial, Paintkin, Tree, Giant, Book, Egg, Rock, Bard, Artist, Vampire. Some cards are **All** types (e.g. Catamari, Karma Chameleon).
- Many characters have 2–3 types (e.g. "Animal Pirate Villain"). See the faction counts in [content-library.md](content-library.md).
- **No tribe subset per lobby.** Variety comes from the captain, the 12-card deck shuffled into your own pool, rotating "Shared Pool Shakeups", and pools that differ per player ([Decks](https://guide.galaxy.fun/decks/), [Shared Pool](https://guide.galaxy.fun/shared-pool/)). I found no lobby-level faction exclusion (UNVERIFIED that none exists).
- Faction identities:
  - Dragons: treasure hoarding.
  - Pirates: Hunt and stealing.
  - Toys: summon chains.
  - Fae: Support.
  - Mages: spells.
  - Animals: buffing each other.
  - Heroes: quests.
  - Villains: synergy with other Villains.

## 10. Keywords: exact behaviour

Definitions follow the official guide (linked). Usage counts are in [content-library.md](content-library.md).

| Keyword | Behaviour | Source |
|---|---|---|
| **Recruit** | Triggers when you take the card from the shop: recruiting to the board, recruiting its Silver or Golden copy, or banking it. Does not trigger on transform. Drafty Window doubles Recruit abilities, which "specifically refers to abilities that start with the word 'Recruit'". | [Recruit](https://guide.galaxy.fun/recruit/) |
| **Farewell** | Triggers when this character is KO'd, attacking or not. The first summon it creates takes the same slot. | [Farewell](https://guide.galaxy.fun/farewell/) |
| **Hunt** | Triggers when this character attacks and KOs the defender, even in a trade. Only the attacker hunts, and only characters with a Hunt ability. Can be granted (Tsarmina, Bounty Contract). | [Hunt](https://guide.galaxy.fun/hunt/) |
| **Support** | Gives a bonus to "the two characters in front of it". Written "Support — +2 Attack" and so on. Mostly an aura that ends when the supporter is KO'd. Some supports also grant abilities (Moonshadow: "Your support characters have Ranged") or act each fight (Oberon: "Each fight, give characters in front of me +20 Attack", which is permanent). | [Support](https://guide.galaxy.fun/support/), [Learn](https://galaxy.fun/learn/) |
| **Sneak** | Attacks a random back-row enemy if any, otherwise any enemy. | [Sneak](https://guide.galaxy.fun/sneak/) |
| **Ranged** | Takes no damage back when attacking. Normal damage when attacked. Can be granted as an aura or gained permanently (Mimic). | [Ranged](https://guide.galaxy.fun/ranged/) |
| **Quest** | A condition with a counter. When met, gives a Treasure Shop of the quester's rarity. The quester must be on the board to progress. Once per character unless a card says otherwise (Baba Yaga). | [Quest](https://guide.galaxy.fun/quest/) |
| **Treasure Hoard N** | +N/+N for each treasure you own. Stacks. No number means N=1. | [Treasure Hoard](https://guide.galaxy.fun/treasure-hoard/) |
| **Treasure Find** | This character's first treasure discovery is a named unique treasure. | [Treasure Find](https://guide.galaxy.fun/treasure-find/) |
| **Summon** | A character created mid-fight. It takes the source's slot if the source was KO'd and inherits its attack priority. Fails if there is no space. Keeps its buffs permanently. Random summons respect shop rarity. Each character can be resummoned at most 5 times. | [Summon](https://guide.galaxy.fun/summon/) |
| **Transform** | Becomes a new character, keeping tier, buffs and ability buffs. Removes the original from the pool (except temporary transforms). Doesn't trigger Recruit. | [Transform](https://guide.galaxy.fun/transform/) |
| **Sweeten** | +1 to the shared Candy counter. Each point adds +1/+1 to every Candy buff. | [Sweeten](https://guide.galaxy.fun/sweeten/) |
| **Supersweet N** | Multiplies the sweetness bonus on this card by N. | [Supersweet](https://guide.galaxy.fun/supersweet/) |
| **Prophecy** | A condition; completing it makes you a new captain, and the old one becomes co-captain. | [Prophecy](https://guide.galaxy.fun/prophecy/) |
| **Chance Encounter** | Triggers when the card appears in your shop, without recruiting it. | [Chance Encounter](https://guide.galaxy.fun/chance-encounter/) |
| **Boon** | A conditional treasure that pays out and then disappears. | [Boons](https://guide.galaxy.fun/boons/) |
| **Paint** | Colours a slot permanently (see section 8). | [Paint](https://guide.galaxy.fun/paint/) |
| **Slot buff** | A stat buff on a slot, kept by whoever stands there. | [Slot Buffs](https://guide.galaxy.fun/slot-buffs/) |
| **Each fight** | Trigger wording for the start of each fight (INFERRED). | card text |
| **"Double …"** | House rule: "we lean towards +1 additional trigger when we use the term 'Double'". | [27 Aug 2025](https://galaxy.fun/articles/patch-early-september-2025/) |
| **Cursed** | Listed as a character ability type on the wiki. No definition was found (UNVERIFIED). | [wiki](https://onceuponagalaxy.wiki.gg/wiki/Cursed) |

Recurring verbs on cards that are not formal keywords include Banish (remove from the game), Break (Toys break into other Toys), Steal, Train (Astro), Silver/Golden me, Discover and Get. See [content-library.md](content-library.md) for counts.

## 11. Open questions

All UNVERIFIED:
- Whether players alternate single attacks, and how combat treats simultaneous deaths and trigger order beyond the Hunt-before-Poison-Apple rule.
- Heart damage on a tie.
- Whether you may leave a front slot empty on purpose while the back row is occupied.
- The exact shape of "neighbors" and "adjacent", and how "across from me" works for back slots.
- The exact rarity weights in shops, and the treasure cap.
