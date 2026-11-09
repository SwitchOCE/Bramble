# Battlegrounds tribes as top players play them: research for a reference tribe (patch 37.0.2, 9 Nov 2026)

## 0. What I could and could not reach

- **Could not reach:**
  - **HSReplay comp guides.** HSReplay is the "Hearthstone Deck Tracker" site, and "Tier 7" is its paid stats tier. Its comp guides are written by JeefHS, which is exactly the source the owner meant. Every page returned HTTP 403. All I have from them is each comp's name and one-line description, taken from search results.
  - **Video.** YouTube channel pages returned no titles, and I can't watch video. I found no transcripts or VOD summaries from Jeef or XQN.
  - **Other sites:** Reddit (fetch blocked), esports.gg and Playnews guides (403), and HearthstoneTopDecks, which stopped updating in March 2026.
- **Did reach:**
  - Blizzard's patch notes: 36.2.2 (18 Aug), 36.4.2 (3 Sep), 36.6.3 (1 Oct) and 37.0.2 (3 Nov 2026), plus the Season 14 announcement and the Dark Gifts developer insight.
  - **bgbuddy.gg comp pages.** These use Firestone community data for build 256589, which I infer is 37.0.2. Each page gives core cards, add-ons, enablers, a "when to commit" tip from a contributor called "slyders", and placement numbers.
  - HearthSense's tribe-by-patch summary (senseos.gg, updated 7 Nov).
  - Fantasy Warden's Season 13 strategy guide, which is dated but useful for general principles.
  - hstopdecks.com tribe pages. These are low reliability: machine-translated, and some cards they name are not in the current pool.
  - Our local card library, `docs/research/battlegrounds/data/minions.json` (build 37.0.0, 26 Oct). I applied the 37.0.2 changes by hand where they matter.
- **Caveat on bgbuddy numbers.** Every comp averages better than 4.5, so a game probably counts for a comp only if the player assembled it (survivor bias). Compare the numbers between comps; don't read them as absolute. Its letter tiers don't follow its own placements (Mech Volumizer averages 3.29 but is rated C), so I ignore the letters.
- **Nothing saved.** The curl download was refused by the permission check, so nothing went into `refs/`.

Tags used below: **[source]** means a site says it; **[derived]** means arithmetic from card text or costs; **[judgement]** is mine.

## 1. State of the game

- **Season 14, "Dark Gifts of Dalaran"**, started 4 Aug 2026. The current patch is 37.0.2 (3 Nov).
  - In the pool: Quilboar, Undead, Elementals, Beasts, Murlocs, Pirates, Mechs, Demons, Dragons and Aberrations (added 22 Sep).
  - Naga rotated out on 22 Sep; Blizzard calls this temporary. Each type has a 50% chance to appear in a lobby. [source: HearthSense, 36.6.3 notes]
- **Systems:**
  - Dark Gifts: 3 gold, from turn 3, once a turn, at most 3 a game.
  - Trinkets; the Activate keyword (pay gold in the shop); Tavern spells.
  - Tier 7 minions, reached through effects such as Greedy Conniver.
  - Upgrade costs are 5/7/8/11/11. [source: local patch-history]
- **Blizzard's verdicts, 37.0.2 (3 Nov):**
  - "Quillboar and Demons" are too strong and are being brought down.
  - Pirates, Murlocs and Elementals are underperforming.
  - Elementals are "held back by Living Azerite dominating the type".
  - Murlocs rely on Bile Spitter with Expert Aviator or Diremuck Forager, so Expert Aviator was removed.
  - From turn 7, Dark Discover now offers at least 2 minions of your most common type (was turn 10).
- **Standard leveling curve [derived].** Gold is turn + 2 (capped at 10), and each upgrade gets 1 cheaper per turn. Upgrading at the earliest moment gives T2 on turn 2, T3 on turn 4, T4 on turn 6, T5 on turn 8 and T6 on turn 10. I found no current written curve to check this against. Fantasy Warden's Season 13 advice is to "rush" from tier 3 to tier 5, because tiers 3 and 4 are "very awkward to play".

## 2. Comps at a glance

| Tribe | HSReplay comp names (Jeef) [source] | bgbuddy comp: difficulty, avg place, 1st %, top-4 %, games [source] | Commit point (bgbuddy tip) [source] |
|---|---|---|---|
| Quilboar | Choose One; Gems from Hand ("add buffed gems to hand"); Combat Scaling ("high attack gems during combat"); APM Shop Buff; Gem Barrage | Choose One: Medium, 3.42, **29.8%** (highest of 29 comps), 65.3%, 6.9k. Felboar Spam: Hard, 3.62. Gem Spam: Medium, 3.97, 14.1k | Turbo Hogrider (T6) + Bramble Tunneler (T4) |
| Undead | Eternal Knight; Attack Scaling ("high-attack Undead") | APM: Medium, 3.64. Butcher: Medium, 3.7. Eternal Knight: **Easy**, 3.62, 11.4%, 64.8% | "Eternal Knight early + Eternal Summoner" |
| Beasts | Beetles; Summons; Leviathan; Tasty Lobstah | Lobster: Medium, 3.80, 22.3%, 26k games (the most played comp). Beetle: Medium, 3.90. Leviathan: Medium, 3.9 | Beetles: Headhunter Gryphon (T4) + Ravaging Scorpid (T6). Lobster: Gryphon + Tasty Lobster + Deathstrider |
| Dragons | Copebringer ("proc Divine Shields to scale"); Spells | Shield: **Easy**, **2.84**, 24.0%, **80.3%**. Spell Power: Easy, 3.8. Kalecgos: Easy, 4.1 | Hopebringer (T5) + Divine Shield minions |
| Mechs | APM Magnetic; Magnetics/Spells | APM: Hard, 3.28. Glambot: Medium, 3.9. Volumizer: **Easy**, 3.29, 23.5%, 67.4% | Resourceful Robot (T5) + Utility Drone (T6) + Drakkari Enchanter |
| Elementals | Living Azerite; Unbound Tempest ("big shop plays") | Azerite: Hard, 3.49. Cycle: Medium, 3.6. Tempest: Hard, 3.6 | Living Azerite + Leyline Surfacer + Balinda |
| Demons | Shop Buff; Deathrattle/Shop Buff; Self Damage | Boost Shop: Medium, 3.48. Self Damage: Hard, 3.9 | Sacrificial Wrathguard or Devilish Distractor + Imp-lusionist |
| Pirates | APM Golden ("infinite money"); Bounty APM | Discover: Hard, 3.45. Bounty: Hard, 3.9 | "When you find Hooktusk" (T6), playing as many Enterprising Escapees as possible |
| Murlocs | Venom Scam; Tidecaller; Keyword; Magicfin | Scam: Medium, 3.03, 79.3% (lists Expert Aviator, which 37.0.2 removed). Handbuff: Hard, 3.7. End of Turn: Hard, 3.4 | Sewer Escapee + Bile Spitter |
| Aberrations | APM Deity; Deathrattle/Spells | Discard: Easy, 3.2. Deathrattle: Easy, 3.6 | n/a |

Two patterns stand out:

1. **Almost every commit point is a tier 4–6 card** [source]. The tribe is usually chosen around turns 6–10.
2. **Six of HSReplay's comp names carry "APM"** (actions per minute: comps that need many clicks a turn). [judgement] The comps that read as clear rather than heavy on actions are Undead Eternal Knight, Dragon Shield, Mech Volumizer and Beast Beetles.

## 3. Which tribes play straightforwardly [judgement]

| Tribe and comp | One clear engine | Clear endgame | Early game | Neutrals in core | Power now | Straightforward? |
|---|---|---|---|---|---|---|
| Undead, Eternal Knight | Yes: one named counter | Eternal Summoner (T5), Eternal Tycoon (T5) | On-tribe from T2 | None (Titus is an add-on) | Low (C on bgbuddy) | **Most** |
| Dragon, Shield | Yes: Divine Shield breaks grow Hopebringer | Heroic Broodmother, Crimson Vindicator | Bronze Warden (T2) | Nadina (core) | Highest | High |
| Mech, Volumizer | Yes: "Volumizers have +X this game" | Resourceful Robot + Utility Drone | T2 Volumizers are the best T2 cards | Drakkari (core) | High | High, but needs Magnetic |
| Beast, Beetles | Yes: "Beetles have +X this game", plus summons | Banana Slamma doubles summons; Deathstrider | Buzzing Vermin (T1), Forest Rover (T2) | None in core (Titus add-on) | Mid | High |
| Quilboar, Choose One | Three stacked axes (section 5) | Hogrider board; gems piled onto one carry | Gem makers fit any board | None in core (Drakkari add-on) | Too strong per Blizzard; most 1st places | Medium |
| Demons, Boost Shop | Buff the shop, then eat it | Large Demons | Weak | Balinda (core) | Too strong per Blizzard | Low |
| Elementals | Shop-side buffs | Unbound Tempest, Azerite | Weak | Brann and Balinda (core) | Underperforming | Low (Hard) |
| Pirates | Gold-spent counters and Golden minions | Hooktusk | Busker, Laureate | Brann (add-on) | Underperforming | Low (Hard, APM) |
| Murlocs, Scam | Venomous kills, not scaling | n/a | Mixed | Leeroy, Deadly Spore | Underperforming | Poor as a scaling reference |

## 4. Tribe profiles

Cards are shown as tier, name, then rules in brief. Text is from build 37.0.0, with 37.0.2 changes noted.

### Quilboar (the owner's case study)

- **Engine.** Blood Gems are a +1/+1 spell that can target any minion. Players then raise three things at once: how many gems they get, how many times each gem is applied, and how big each gem is. Section 5 breaks this down.
- **Count (making gems):**
  - T1 Razorfen Geomancer (Battlecry: 2 gems); T1 Tusked Camper (Rally: plays a gem on itself).
  - T2 Crater Miner (Choose One: 2 gems or a Gem Day); T2 Roadboar (Rally: a gem).
  - T3 Fearless Foodie (Choose One: 4 gems, or gems give +1/+1 more this game).
  - T3 Sly Infiltrator (Choose One: 2 free Refreshes or 3 gems); T3 Mangled Bandit (Activate 0: discard a card for 3 gems).
  - T4 Razorfen Flapper (Battlecry and Deathrattle: Blood Gem Barrage); T4 Bramble Tunneler (Rally: a random Choose One card).
  - T6 Victorious Geomant (Activate 2: 6 gems).
- **Applications (gems played without spending cards, or cast twice):**
  - T2 Prodigious Tusker: when another friendly minion attacks, plays a gem on it.
  - T4 Bonker: Windfury; Rally plays a gem on all your other minions.
  - T4 Geomagus Roogug: when a gem is played on it, it plays one on another minion.
  - Hot-Air Surveyor: gems played from hand cast an extra time. It moved from T4 to T5 in 37.0.2.
  - T6 Turbo Hogrider: after you play a Choose One card, plays **2** gems on **all** your Quilboar. In 36.6.3 this went from 1 gem on your *other* Quilboar.
  - T6 Veteran Brigand: 3 gems on all your minions.
  - T5 Razorfen Vineweaver: Rally plays 4 permanent gems on itself.
  - Neutral T6 Balinda: spells you cast on friendly minions cast twice.
  - T3 Trench Fighter: at end of turn, get a Gem Confiscation (plays 3 gems on one minion and steals its neighbours' gems). This concentrates stats onto a carry.
- **Size (how big each gem is):**
  - Gem Day: Choose One, your gems give +1 Attack or +1 Health more this game. T3 Gem Rat makes one at the end of every turn.
  - T3 Thorned Trailblazer: one Choose One card each turn gets both effects.
  - Fearless Foodie: +1/+1 this game.
  - T5 Sanguine Refiner: Rally, +1/+1 this game. It triggers on **every attack**; it was +1/+2 until 37.0.2.
  - T6 Sanguine Champion: Battlecry and Deathrattle, +2/+1.
  - Trinkets add more.
- **Capstone:** T7 Jailbird Juggernaut (13/17 after 37.0.2). Rally summons a Golem with its stats.
- **Early game:**
  - The gem makers (Geomancer, Crater Miner, Foodie, Sly Infiltrator) are **flexible as well as enabling**. Gems buff whatever board you have, and the economy modes (free Refreshes, and Snare Trapper's +1 maximum gold) work in any game. That is the balance the owner asked about in 9f. [judgement]
  - On bgbuddy's played-minion data, Crater Miner (3.02) and Fearless Foodie (2.93, among the best T3 cards) beat most of their tier. [source]
  - Older guides (Seasons 9 and 10) say "don't force Quilboars from the first turns" and call the mid-game survivability low. [source, dated]
- **Endgame [source: bgbuddy]:** Find Hogrider, then "cycle all Choose One cards". Late on, use Gem Confiscation "on a carry minion", and the examples it gives are off-tribe: Blade Collector (a Pirate) and Heroic Broodmother (a Dragon). Best heroes: Xavius (3.21) and Marin (3.17).
- **Power curve:** It comes online at Hogrider, so around turn 10 or later [derived]. It has the highest 1st-place rate (29.8%) with only 65% top-4, so it wins big or busts [source; interpretation is judgement].
- **Mistakes [source, partly dated]:** Forcing the tribe early; dying in the mid-game before the payoffs arrive. Blizzard's 37.0.2 Dark Gift changes are meant to make holding gifts viable, which suggests players overspend them early.
- **Dependence:**
  - Choose One needs no neutral in its core; Drakkari is an add-on.
  - Gem Spam and Felboar Spam need Balinda (and Brann for Felboar).
  - Trinkets matter: in 37.0.2 Jar o' Gems went from 0 to 3 gold, and Hoggy Bank and Bloodbound Earrings went up in cost.
- **The balance swing, in about two months [source]:**
  - 18 Aug: "generally underperforming".
  - 3 Sep (36.4.2): "among the weakest… increasing Blood Gem scaling". Refiner went from +1/+1 to +1/+2 and Champion from +1/+1 to +2/+1.
  - 1 Oct (36.6.3): Hogrider went from 1 gem to 2, and now counts itself.
  - 3 Nov (37.0.2): named "too strong". Refiner went back to +1/+1, Surveyor moved to T5, and **Wand of Divination was "banned in Quill lobbies"**.
- **Why that ban matters [derived].** Blood Gems are spells cast on minions, so Quilboar feed every spell-count engine in the game: Felboar (eats a shop minion after 3 spells), Glambot, Shamanic Tidecaller, Devilish Distractor, Balinda and the Wand. A lever moved one step on the size axis, or one step on the count axis, turned the weakest type into the strongest. This is evidence for the owner's worry.

### Undead

- **Engine:** Global "Attack this game, wherever they are" counters. These raise size, and the effect reaches hand and shop too.
  - Size sources: T2 Nerubian Deathswarmer (+1); T4 Plaguerunner (+2 Attack, or +4 if it dies outside combat); Butchering (+8, via T5 Drustfallen Butcher); T6 Forsaken Weaver (+3 Attack per Tavern spell); the Artisanal Urn trinket (+20).
  - Reborn line: T3 Mummifier; T4 Dead Bellringer (Activate 1: give an Undead Reborn, destroy it, gain +4/+4); T5 Barrier Banshee (after a Reborn, gain Divine Shield and +8/+8); T6 Snazzy Phantom (after a Reborn, gives that minion's Attack as stats to your right-most Undead).
  - Knight line: T2 Eternal Knight (+4/+2 for each Knight that died this game); T5 Eternal Summoner (Reborn; Deathrattle summons a Knight; moved to T5 in 36.6.3); T5 Eternal Tycoon (Avenge 5: summon a Knight that attacks immediately).
  - Capstone: T7 Stitched Salvager.
- **Early game:** On-tribe from T2 (Knight, Deathswarmer). hstopdecks' rule: "fewer than two Eternal Knights at level 4, consider pivoting" (low reliability).
- **Endgame:** Undead APM uses the Pirate pair Sky Admiral Rogers + Proud Privateer to make Bounties (Tavern spells), so Weaver triggers without limit, plus Snazzy. Eternal Knight is the plain version.
- **Power curve [judgement]:** Steady from early on. Only Attack scales, not Health.
- **Dependence:** Eternal Knight is self-contained. APM borrows the Pirate economy engine.
- **Patch notes:** Untouched in 37.0.2.

### Beasts

- **Beetles engine:** "Your Beetles have +X this game" (size), times the number of Beetles summoned (count, from Deathrattles, doubled by Titus), times Banana Slamma (T4: doubles the Attack of each Beast summoned in combat).
  - Size sources: T2 Forest Rover (+2/+1, and its Deathrattle summons a Beetle); T5 Turquoise Skitterer (+5/+5); T6 Ravaging Scorpid (+4/+4 after each friendly attack).
  - Count sources: T1 Buzzing Vermin (Taunt; Deathrattle summons a Beetle).
- **Fishbait (new this season):** T2 Lurking Lionfish (Activate 2) and T4 Snarky Shark (sell it to refresh with a Fishbait) let Beasts attack in the shop. Triggers that normally fire only in combat now fire during the Recruit Phase and become permanent. bgbuddy's Lobster tip: "trigger Tasty Lobster as much as you can" through Fishbait attacks.
- **Early game:** Strong standalone early cards. Among played minions, Buzzing Vermin (3.13) and Flittering Bat (3.15) are top T1s, and Humming Bird (2.92), Lurking Lionfish (2.96) and Forest Rover (3.07) are top T2s. [source]
- **Commit and endgame:** Commit at Gryphon (T4) + Scorpid (T6), and "at the end play Banana Slamma to summon big beetles". Other endgame cards: Deathstrider, Goldrinn, Stalwart Kodo (T7, reworked in 37.0.2).
- **Dependence:** Titus Rivendare (neutral: Deathrattles trigger an extra time) is core for Lobster and an add-on for Beetles. The Snarky Portrait trinket went up in cost.

### Dragons

- **Shield engine:**
  - T5 Hopebringer: Start of Combat gives your minions +4/+3, and it permanently improves each time a friendly minion loses Divine Shield.
  - T4 Persistent Poet: adjacent Dragons keep stats and keywords gained in combat. T2 Tarecgosa does the same for itself.
  - Neutral T6 Nadina: Deathrattle gives 3 Dragons Divine Shield again.
  - T6 Heroic Broodmother (Rally: gain Divine Shield; attacks first); T6 Crimson Vindicator (9/7 Divine Shield, now Windfury).
  - Capstone: T7 Obsidian Ravager (11/11).
- **How to play [source]:** Fill the board with Divine Shield minions, reset shields to power Hopebringer, and keep stats on Poet.
- **Numbers:** The best average placement of any comp (2.84) and 80% top-4.
- **Lesson [judgement]:** Turning fight-time buffs into permanent ones (Poet, Tarecgosa) is a clean scaling idea.

### Mechs

- **Volumizer engine:**
  - T2 Red, Blue and Green Volumizer: the first time one is played or Magnetized, your Volumizers get +3 Attack, +3 Health or +1/+1 this game, wherever they are.
  - Volumizer makers: T3 Auto Accelerator, T4 Conveyor Construct, T5 Resourceful Robot (end of turn), T6 Auto Reveille (after every 3 cards bought).
  - Payoffs: T6 Utility Drone (end of turn: each minion gets +4/+5 per Magnetization it has); Drakkari (neutral: end-of-turn effects trigger twice).
- **Numbers:** The three T2 Volumizers are the best T2 cards by average placement (2.85–2.88). Mech APM (Spark Snapper, Auto Reveille) needs the Rogers + Privateer economy or Brann.

### Elementals

- **Engine:** Buff the shop, then buy from it or absorb it.
  - T5 Living Azerite: after each Tavern spell, Elementals in the Tavern get +3/+3 this game (was +4/+3 before 37.0.2).
  - T1 Dune Dweller; T3 Waveling, T4 En-Djinn Blazer and T5 Air Revenant (buff a random shop minion after each Refresh).
  - T4 Leyline Surfacer (Arcane Absorption: half the stats of the shop's highest-Health minion).
  - T6 Unbound Tempest (gains the stats of the shop's highest-Health minion; after 37.0.2 it triggers every 3 Elementals instead of 4).
  - Capstone: T7 Stone Age Slab.
- **Rating:** Hard. Brann and Balinda are core. Blizzard calls the type underperforming. hstopdecks' pivot rule: commit at T4 only with two or more Elementals that grow.

### Demons

- **Boost Shop:**
  - Shop minions get "+X this game": T4 Sacrificial Wrathguard; T5 Devilish Distractor; T5 Deft Deserter (Activate 1: +8/+8 and a keyword).
  - Demons then eat the shop: T4 Imp-lusionist (Methodical Madness); T5 Insatiable Ur'zul; T4 Soulkeeping Jailer.
- **Self Damage:** Hero Health is spent as a resource: T1 Wrath Weaver, T2 Soul Rewinder, T4 Ashen Corruptor, T5 Tichondrius, T6 Eredar Escapist.
- **Patch notes:** Blizzard calls Demons too strong; 37.0.2 nerfed Corruptor, Escapist and Wrathguard. Balinda is core for Boost Shop.

### Pirates

- **Engine:** Counters on gold spent and on Golden minions played.
  - Early: T1 Southsea Busker (+1 gold next turn); T1 Aureate Laureate (always Golden; the best T1 by average placement, 2.86).
  - Golden minions: Lockboxes from T2 Bilgewater Breakout, T3 Locked-up Mutineer and T5 Enterprising Escapee (after 5 gold spent, from 37.0.2).
  - Golden payoffs: T4 Maritime Extortionist (+7/+7 per Golden played this game); T5 Ship Master Eudora (Deathrattle: +8/+8, kept permanently by Golden minions); T6 Hooktusk (after you Discover, all your Pirates get +1/+1, improved by Golden minions).
  - Gold-spent payoffs: T4 Gunpowder Courier; T6 Sky Admiral Rogers (a Bounty per 9 gold spent) with T5 Proud Privateer (Bounties cast twice).
  - Capstone: T7 Captain Sanders.
- **Assessment:** Hard and APM, and underperforming. The Rogers + Privateer pair is also the economy engine inside four other tribes' top comps (Undead APM, Mech APM, Elemental Azerite, Felboar Spam). [source: bgbuddy cores]

### Murlocs

- **Scam:** T5 Bile Spitter (Venomous; Rally spreads Venomous) and T5 Sewer Escapee (Activate 1: +7/+7 and a keyword) kill big minions instead of scaling. **Handbuff:** T4 Twilight Tidehunter and T5 Shamanic Tidecaller grow cards in hand, and T6 Choral Mrrrglr absorbs them.
- **Assessment:** Blizzard calls Murlocs underperforming, and Expert Aviator is gone. Scam is poor as a scaling reference.

### Aberrations

New on 22 Sep. A Deity (C'Thun or Y'Shaarj, now T1) joins after 4 Aberration deaths, alongside discard engines (Activate 0). Rated Easy, and trimmed in 36.6.3 and 37.0.2.

## 5. Count × applications × size: how each tribe scales [judgement on derived card text]

In the owner's terms (number of buffs, times each is applied, size of each buff, plus time):

| Tribe | Count | Applications | Size | Grows with time? | Permanent? |
|---|---|---|---|---|---|
| **Quilboar** | Gem makers, Choose One cycling | Bonker, Hogrider (all Quilboar), Brigand (all minions), Surveyor ×2, Balinda ×2, Roogug chain | Gem Day every turn, Refiner on every attack, Champion | Yes: size climbs every turn and every attack | **Yes, on any minion of any tribe** |
| Beasts (Beetles) | Beetle summons, Titus ×2 | Banana Slamma ×2 Attack | Beetle counter | Through Scorpid attacks and Fishbait | Counter yes; bodies only for that fight |
| Mechs (Volumizer) | Volumizers from Robot and Reveille | Drone per Magnetization, Drakkari ×2 | Volumizer counter | End of turn | Yes, but only on Mechs |
| Undead | Spell or death triggers | All Undead, everywhere | Attack only | Weaver, once per spell | Attack only |
| Elementals and Demons | Refreshes and spells | One shop minion each time, then absorbed | Shop counters | Per refresh | Yes |

- **Why Quilboar is the outlier.** All three axes stack together, and all of them are permanent. Gem size rises with time (one Gem Day a turn, one Refiner trigger per attack), and the count per turn rises too (Tunneler adds Choose One cards, each of which fires Hogrider on every Quilboar). So the stats a Quilboar board adds each turn grow faster than linearly, and the running total grows roughly with the square of turns or faster.
- **The two traits no other tribe shares.** Gems can go on any minion, and gems are spells, so they feed other tribes' spell engines. That is the multiplier the owner expects to "obliterate" our designs. Blizzard's evidence: single steps on the size and count levers swung Quilboar from the bottom to the top in two months, and it had to ban a trinket in Quilboar lobbies.

## 6. Early game across tribes

- **Commit late, open strong [source].** Commit points are T4–T6 cards (section 2). Fantasy Warden (Season 13): "Don't commit early to tribes based on weak early minions"; commit "one or two turns before a greater trinket"; a 3-gold tribe sticker before you know the tribe "isn't great".
- **What opens games [source: bgbuddy played-minion data; derived].** The best early cards are strong alone and also lead somewhere:
  - Pirate T1s give gold or a Golden minion.
  - Beast T1/T2s give Taunt and Deathrattle bodies.
  - Mech T2 Volumizers grow a counter.
  - Quilboar T1–T3s give gems that suit any board, and some offer economy modes.
  - The worst early cards are narrow or slow: Suspicious Prisonguard (3.91), Decoy Conjurer (4.01).
- **Pivoting.** From turn 7, Dark Gifts steer you toward your most common type (37.0.2). Most comps take a lot of their power from neutral or borrowed pieces (section 7), so changing tribe late is normal.

## 7. Dependence on neutrals and borrowed engines [source: bgbuddy cores and add-ons]

| Piece | What it does | Core in |
|---|---|---|
| Brann (T5) | Battlecries trigger twice | Elemental Azerite, Felboar Spam, Murloc End of Turn |
| Balinda (T6) | Spells on friendly minions cast twice | Elemental Azerite, Felboar Spam, Demon Boost Shop, Quilboar Gem Spam |
| Drakkari (T5) | End-of-turn effects trigger twice | Mech Volumizer, Murloc End of Turn; add-on in Quilboar Choose One |
| Titus (T5) | Deathrattles trigger an extra time | Beast Lobster; add-on in Beetles and Eternal Knight |
| Rogers + Privateer (Pirates) | Gold-spent Bounties, cast twice | Undead APM, Mech APM, Elemental Azerite (add-on), Felboar Spam |

**Comps with no neutral in their core:** Quilboar Choose One, Undead Eternal Knight, Beast Beetles, Pirate Discover. Dragon Shield needs Nadina.

## 8. Reference tribe [judgement, for the orchestrator to decide]

- **Case study: Quilboar Choose One.** The owner's latest words name Quilboar, and it is the clearest three-axis engine in the game. It has a readable early game (flexible gem makers), one commit point (Hogrider + Tunneler) and a known endgame (gems concentrated onto one carry). To copy it into Bramble we need Choose One, a gem-as-spell token and "this game" size counters.
- **Straightforward control: Beast Beetles, or Undead Eternal Knight.**
  - Beetles: one named counter, no neutral in core, good standalone early units, and Deathrattle summons Bramble already models (`death_summon`).
  - Eternal Knight: the simplest line and on-tribe from T2, but it is weak in the current patch.
  - Dragon Shield is the strongest Easy comp, but it rests on a neutral (Nadina) and on Divine Shield resets.
- **Mapping to Bramble's board.** Battlegrounds wording like "left-most", "adjacent" and "right-most" needs a version for our 4-front/3-back rows.

## Sources

**Blizzard (primary):**
- [37.0.2 patch notes, 3 Nov 2026](https://hearthstone.blizzard.com/en-us/news/24307311/3702-patch-notes)
- [36.6.3 patch notes, 1 Oct 2026](https://hearthstone.blizzard.com/en-us/news/24303864)
- [36.4.2 patch notes, 3 Sep 2026](https://hearthstone.blizzard.com/news/24296231)
- [36.2.2 patch notes, 18 Aug 2026](https://hearthstone.blizzard.com/news/24293284)
- [Season 14 announcement](https://hearthstone.blizzard.com/en-us/news/24290433)
- [Developer Insight: Dark Gifts](https://us.forums.blizzard.com/en/hearthstone/t/battlegrounds-developer-insight-dark-gifts/163606)

**Comp guides and stats:**
- bgbuddy.gg (Firestone data, build 256589, read 9 Nov 2026): [comps](https://bgbuddy.gg/comps), [Quilboar Choose One](https://bgbuddy.gg/comps/quilboar-choose-one), [Quilboar Gem Spam](https://bgbuddy.gg/comps/quilboar-gem-spam), [Quilboar Felboar Spam](https://bgbuddy.gg/comps/quilboar-felboar-spam), [Undead Eternal Knight](https://bgbuddy.gg/comps/undead-eternal-knight), [Undead APM](https://bgbuddy.gg/comps/undead-apm), [Beast Beetle](https://bgbuddy.gg/comps/beast-beetle), [Beast Lobster](https://bgbuddy.gg/comps/beast-lobster), [Dragon Shield](https://bgbuddy.gg/comps/dragon-shield), [Mech Volumizer](https://bgbuddy.gg/comps/mech-volumizer), [Mech APM](https://bgbuddy.gg/comps/mech-apm), [Elemental Azerite](https://bgbuddy.gg/comps/elemental-azerite), [Demon Boost Shop](https://bgbuddy.gg/comps/demon-boost-shop), [Pirate Discover](https://bgbuddy.gg/comps/pirate-discover), [Murloc Scam](https://bgbuddy.gg/comps/murloc-scam), [minions](https://bgbuddy.gg/minions)
- HSReplay comp index, powered by JeefHS (403; names and one-liners from search only): [comps](https://hsreplay.net/battlegrounds/comps/), for example [Quilboar Choose One](https://hsreplay.net/battlegrounds/comps/88/quilboar-choose-one) and [Quilboar Gems from Hand](https://hsreplay.net/battlegrounds/comps/63/quilboar-gems-from-hand); [Tier7](https://hsreplay.net/battlegrounds/tier7/)

**Summaries and older guides:**
- [HearthSense tribe summary, 1–7 Nov 2026](https://senseos.gg/guides/hearthstone/battlegrounds-tier-list/)
- [hsbg.cards 36.2 notes](https://hsbg.cards/patch-notes/36.2)
- [hstopdecks.com comps](https://hstopdecks.com/en/battlegrounds/comps) (reviewed 17 Sep 2026; low reliability)
- [Fantasy Warden strategy guide, Season 13, 18 May 2026](https://fantasywarden.com/games/hearthstone-battlegrounds-strategy-guide)
- [Fantasy Warden Quilboar, Season 10, Dec 2025](https://fantasywarden.com/games/hearthstone-battlegrounds-quilboar-minions)
- [hearthstone.wiki.gg Quilboar](https://hearthstone.wiki.gg/wiki/Battlegrounds/Quilboar)

**Local:**
- `/home/alex/code/Bramble-ideation/docs/research/battlegrounds/data/minions.json` and `spells.json` (build 37.0.0, 26 Oct 2026)
- `/home/alex/code/Bramble-ideation/docs/research/battlegrounds/strategy-eras.md`
- `/home/alex/code/Bramble-ideation/docs/ideation/evidence/reference-curves.md`