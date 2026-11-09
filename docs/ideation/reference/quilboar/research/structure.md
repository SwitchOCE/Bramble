# Reference-tribe survey: Battlegrounds 37.0 pool and what could be ported into Bramble

## Recommendation

**Port Quilboar and Undead.**

- **Quilboar** is the owner's case study (note 09g). It is the cleanest example of "trivariate" scaling. One new subsystem, the gem kit, carries the whole tribe.
- **Undead** is the straightforward control. Its scaling has two variables, and one of them maps onto Bramble's existing tribe-bonus layer (rulebook 5.2.9).
- **Why this pair:** Quilboar Choose One winners are wide (biggest unit holds 0.26 of the board). Undead Butcher winners are tall (0.51). So the pair covers both shapes.

## Sources and limits

- **Card pool:** `docs/research/battlegrounds/data/minions.json`, build 255790 (37.0.0), with `in_current_pool` true. Token spells come from `spells.json`.
- **Missing text:** Gem Day is not in the local library. I took its text from the wiki: "Choose One - Your Blood Gems give an extra +1 Attack this game; or +1 Health." It costs 0.
- **Naga:** the card data flags them as in the pool, but no lobby in the 1,000 replays has Naga (tribe id 92 is absent). rules.md says they rotated out on 22 Sep. They are not playable in 37.0.
- **"Strategic units":** I couldn't watch video and didn't fetch Tier 7 or HDT guides in this step. I used the local Firestone "perfect game" data instead. These are 1st place without losing health, about 0.36% of games, on patch 37.0, 3–9 Nov 2026:
  - 1,000 final boards: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/web/perfect.json`.
  - 150 parsed per-turn replays: `.../fundamentals/web/perfect_combats.jsonl` in the same folder.
- **Per-turn data is unreliable after about turn 8.** The parser keeps stale entities, so I used turns 1–8 only, deduplicated by board position. Each tribe has only 9 per-turn games, so read those counts as indicative.
- **Scope:** I counted only solo cards at tiers 1–6. Duos-only cards and tier 7 cards are out (rulebook 13.1.2).
- **No Godot was run, and nothing was written to the repo.** My scripts are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/work/`.

## How BG mechanics map to Bramble

Checked against `content/schema/effects.json`, `docs/ideation/engine.md` and the rulebook.

| BG | Bramble | Fit |
|---|---|---|
| Battlecry, Deathrattle, Rally, Start of Combat, End of Turn, sell | `on_play`, `on_death`, `on_attack`, `start_of_combat`, `end_of_turn`, `on_sell` | clean |
| Avenge (X) | `on_friendly_death` with `every: X` (check that the counter resets each fight) | clean |
| Divine Shield | `shield` (Shield) | clean |
| "Also damages the enemies next to…" | `cleave` | clean |
| Discover, Get a card, free Refresh, gold-spent counters, spell cast | `discover`, `add_card`, `free_refresh`, `on_gold_spent` + `every`, `on_spell_cast` | clean |
| "Your X have +N this game, wherever they are" | `tribe_bonus` layer (5.2.9) | needs an Attack-only amount and no +3 cap |
| Right-most / left-most | Last / first unit in Pass order F1-B1-F2-B2-F3-B3-F4 (12.1.6), since 8.2.5 has no board-wide sides | adapt |
| Taunt, Reborn, Windfury, Venomous, Stealth | Absent. Rules already cover them (9.5.4, 9.7.2 step 4, 9.8.3, 9.4.3). `combat_lanes.gd:182` has a Taunt insertion point. | small engine adds |
| Activate (X) on a minion | Exists only on hero powers ("you don't write them on units") | small add |
| Choose One | Absent. The engine already has `pending_choice` and `choose` for Discover. | small add |
| Tavern spells "give an extra +X" | Absent (Bramble has shop spells, but no spell-power counter) | small add |
| Blood Gems | Absent. Precedents: hand items (Acorn, Golden Egg) and the shared Ring size counter (8.5.4) | one subsystem, the "gem kit" |
| Consume a Tavern minion; shop buffs "this game" | Absent (the `shop` selector exists) | medium |
| Magnetic, Spellcraft, Bonus Keywords, Bounties, Lockbox, Fishbait, Fodder, Chromadrakes, golden-minion counts, hero-damage rewind | BG-only systems | none |

**Tags used below:**
- **C:** ports with what Bramble has.
- **K:** needs a missing BG keyword.
- **H:** needs a small new hook.
- **B:** needs a BG-only system.
- **G:** needs the Quilboar gem kit.

**Roles:**
- **enabler:** makes the tribe's resource.
- **condition:** a counter-holder that grows only when the tribe condition is met.
- **payoff:** turns the resource into stats.
- **capstone:** the endgame card.
- **flex/early:** a good early body for any board.
- **filler:** a body with incidental text.

## All ten tribes compared

Solo cards at tiers 1–6. "Wins" counts the 1,000 perfect games, by Firestone archetype.

| Tribe | Cards | C | K | H | B | What a port must build | Wins (median final board stats) |
|---|---|---|---|---|---|---|---|
| **Quilboar** | 24 | 0 | 1 | 2 | 0 | Gem kit (9 cards need only that) + Choose One (9) + unit Activate (2) + Windfury (1). 21 of 24 are faithful; 3 need an extra BG hook. | 77: Choose One 36 (28,831), gem spam 28 (17,005), Felboar 13 (21,559) |
| **Undead** | 22 | 7 | 8 | 6 | 1 | Reborn (8 cards) + Taunt (1) + small hooks; 21 of 22 faithful | 66: Butcher 29 (19,492), Eternal Knight 21 (7,327), APM 16 (10,846) |
| Beast | 21 | 11 | 3 | 4 | 3 | Taunt, token counters; Fishbait (core early) and Golden Touch are BG-only; finals lean on neutral Titus (85%) | 186: Lobster 171 (30,520) |
| Dragon | 21 | 10 | 2 | 5 | 4 | Chromadrakes BG-only; spell power; low ceiling | Shield 47 (5,871), spell power 28 (7,182) |
| Elemental | 21 | 6 | 1 | 14 | 0 | Shop-side tribe buffs "this game", refresh listeners, consume | Azerite 40 (33,581), Tempest 8 |
| Demon | 22 | 3 | 0 | 12 | 7 | Consume-from-shop (6 cards), hero-damage triggers, Fodder | Boost-shop 36 (36,373), self-damage 29 |
| Murloc | 21 | 4 | 2 | 10 | 5 | Hand summons, Battlecry retriggers, Bonus Keywords | Hand-buff 18 (2,921), scam 10 |
| Pirate | 23 | 6 | 0 | 3 | 14 | Bounties, Lockbox, golden-minion counts | Discover 69 (35,522), Bounty 12 |
| Mech | 23 | 2 | 2 | 2 | 17 | Magnetic | APM 43, Volumizer 40, Glambot 9 |
| Naga | 21 | 3 | 0 | 8 | 10 | Spellcraft; not in 37.0 lobbies | none |

The Quilboar row's C/K/H columns don't add to 24 because 21 of its cards also need the gem kit. Its breakdown is in the Quilboar section.

### Compact pools for the other eight tribes

Full rules text is in `minions.json`. Each entry is stats, role and tag.

**Beast**
- T1: Buzzing Vermin 1/1 flex K(Taunt); Flittering Bat 1/4 flex C.
- T2: Forest Rover 1/1 enabler H(Beetle counter); Humming Bird 1/4 enabler C; Lurking Lionfish 3/4 enabler B(Fishbait).
- T3: Sprightly Scarab 3/1 flex H+K(Choose One, Reborn, Windfury); Tasty Lobster 2/1 condition H(improve-future counter); Treasure Parrot 5/5 B(Golden Touch); Wolf Pup 3/6 flex C.
- T4: Banana Slamma 3/6 payoff C; Cage Gnawer 2/7 payoff C; Headhunter Gryphon 3/5 enabler C; Hoarding Hyena 4/6 enabler C; Snarky Shark 4/5 B(Fishbait).
- T5: Ghastcoiler 7/7 payoff C; Goldrinn 7/7 payoff C; Lurking Leviathan 3/9 payoff C; Sewer Lord 4/6 filler K(Taunt); Turquoise Skitterer 5/5 payoff H.
- T6: Deathstrider 10/11 capstone C; Ravaging Scorpid 6/7 capstone H.

**Elemental**
- T1: Crackling Cyclone 2/1 flex K(Windfury); Dune Dweller 3/3 enabler H.
- T2: Fire Baller 4/3 enabler H; Sellemental 3/3 flex C; Snow Baller 3/4 enabler H.
- T3: Waveling 5/1 enabler H; Wildfire Elemental 6/3 filler C.
- T4: Air Baller 6/6 payoff H; En-Djinn Blazer 5/5 enabler H; Flaming Enforcer 4/5 payoff H(consume); Ichoron 3/1 enabler C; Leyline Surfacer 4/6 enabler H; Living Prison 4/5 payoff H; Refreshing Anomaly 4/5 flex C; Tavern Tempest 2/2 enabler C.
- T5: Air Revenant 3/6 payoff H; Firelands Fugitive 5/7 payoff C; Living Azerite 8/6 capstone H.
- T6: Elemental of Surprise 8/8 capstone H; Ultraviolet Ascendant 6/6 capstone H; Unbound Tempest 3/12 payoff H.

**Murloc**
- T1: Bubble Gunner 2/3 B(Bonus Keyword); Flighty Scout 3/3 flex H.
- T2: Expert Aviator 3/5 enabler H; Tad 2/2 flex C; Very Hungry Winterfinner 2/6 enabler K(Taunt).
- T3: Diremuck Forager 4/5 enabler H; Shoalfin Mystic 4/4 enabler H(spell power).
- T4: Bream Counter 6/6 payoff H; Gearfin 6/5 enabler H; Gormling Gourmet 4/3 B; Kelp Keeper 5/5 enabler H; Twilight Tidehunter 4/6 payoff H.
- T5: Bile Spitter 1/10 K(Venomous); Costume Enthusiast 4/5 payoff C; Hackerfin 5/3 B; Primalfin Lookout 3/2 flex C; Sewer Escapee 7/7 B; Shamanic Tidecaller 5/7 payoff H.
- T6: Choral Mrrrglr 6/6 capstone C; Magicfin Mycologist 4/8 B; Young Murk-Eye 8/5 capstone H.

**Pirate**
- T1: Aureate Laureate 2/2 flex B; Southsea Busker 3/1 flex C.
- T2: Bilgewater Breakout 3/2 B(Lockbox); Clever Castaway 2/3 flex H; Surfing Sylvar 1/2 enabler B.
- T3: Azsharan Cutlassier 6/4 H; Greedy Conniver 7/7 B; Locked-up Mutineer 6/3 B; Timecap'n Hooktail 1/4 payoff C; Treasure Parrot B.
- T4: Bigwig Bandit 4/6 B(Bounty); Blade Collector 3/2 filler C(Cleave); Gunpowder Courier 2/5 payoff C; Lovesick Balladist 3/4 payoff C; Maritime Extortionist 7/7 payoff B.
- T5: Elite Navigator 5/5 B; Enterprising Escapee 6/6 B; Proud Privateer 8/8 B; Ship Master Eudora 8/3 payoff C; Shipwrecked Rascal 5/4 B.
- T6: Hooktusk 4/4 capstone H; Silent Deliverer 7/7 B; Sky Admiral Rogers 4/5 B.

**Mech:** 17 of 23 cards are Magnetic or count Magnetizations, so all are B: Lullabot, the three Volumizers, Mechagnome Interpreter, Accord-o-Tron, Annoy-o-Module, Auto Accelerator, Prosthetic Hand, Conveyor Construct, Drone Duplicator, Enchanted Sentinel, Glambot, Resourceful Robot, Spark Snapper, Auto Reveille, Utility Drone. The rest:
- C: Cord Puller 1/1, Charging Czarina 4/1.
- K(Taunt): Relentless Deflector 5/4, Rescue Bot 2/1.
- H: Gearfin, Falling Sky Golem 4/2.

**Demon**
- T1: Ominous Seer 2/1 flex C; Wrath Weaver 1/3 payoff H.
- T2: Laboratory Assistant 3/4 B(Fodder); Mind Muck 3/2 H(consume); Soul Rewinder 4/2 B.
- T3: Devout Hellcaller 4/4 payoff C; Malchezaar 4/3 B; Trapped Clapper 2/2 B.
- T4: Ashen Corruptor 6/6 B; Flaming Enforcer H; Imp-lusionist 4/2 H; Imposing Percussionist 4/4 C; Sacrificial Wrathguard 5/3 H; Soulkeeping Jailer 3/5 H.
- T5: Deft Deserter 8/8 H; Devilish Distractor 4/7 H; Felboar H; Felfire Conjurer 6/5 H; Insatiable Ur'zul 4/6 H; Tichondrius 4/4 H.
- T6: Eredar Escapist 6/8 B; Twisted Wrathguard 8/8 B.

**Dragon**
- T1: Glim Guardian 1/4 flex C; Scarlet Survivor 3/3 flex C.
- T2: Bronze Warden 2/1 flex K(Reborn); Electric Synthesizer 3/4 enabler C; Tarecgosa 4/4 B.
- T3: Amber Guardian 3/2 K(Taunt); Blue Whelp 1/5 H; Hired Mount 3/5 B(Chromadrake); Roaring Recruiter 2/8 payoff C; Hooktail C.
- T4: Bronze Timewalker 4/5 B; Persistent Poet 2/3 H; Runic Arcanist 2/4 payoff C; Sky-hatch Runaway 4/7 H.
- T5: Draconic Warden 7/4 B; Felfire Conjurer H; Firescale Hoarder 5/5 C; Hopebringer 4/3 payoff C; Kalecgos 4/12 capstone C.
- T6: Crimson Vindicator 8/9 capstone C; Heroic Broodmother 7/7 capstone H.

**Naga:** 10 cards are Spellcraft and so B: Mini-Myrmidon, Lava Lurker, Thaumaturgist, Deep-Sea Angler, Waverider, Rimescale Priestess, Zesty Shaker, Darkcrest Strategist, Glowscale, Tranquil Meditative. Eight are H, because they count or target spells: Fleeing Fugitive, Abyssal Bruiser, Cagey Conjurer, Seafloor Recruiter, Showy Cyclist, Fauna Whisperer, Groundbreaker, Torrential Ruiner. Three are C: Ominous Seer, Shell Collector, Firescale Hoarder.

## Why Quilboar and Undead

**Quilboar**
- The owner named it.
- It is the purest live example of three-variable scaling:
  - **count:** how many gems you get;
  - **applications:** how many times each gem is cast, and on how many units;
  - **size:** how big each gem is.
- Its early cards make a currency that buffs any unit. That is the "flexible as well as enabling" balance the owner asked about (09f).
- Its endgame is almost all Quilboar. The neutral Balinda (29%) only duplicates what Hot-Air Surveyor already does inside the tribe.

**Undead**
- It plays straightforwardly: stack Attack across the tribe, die repeatedly, and let a carry collect it.
- Its main scaling text is the BG twin of Bramble's tribe-bonus layer. That gives the most direct A/B against our own layer.
- Its final boards are the most self-contained of all the tribes: no neutral above 6%, and only Pirate Rogers at 14%.
- What it needs are standard keywords (Reborn, Taunt) that the rulebook already rules on.

**Why not Beasts:** they are the most-winning tribe (186 wins). But their early engine is Fishbait, which is BG-only: Lurking Lionfish shows up 15–28 times in 28 winning boards at turns 3–7. Their endgame needs the neutral Titus (85%) plus the Deathstrider loop.

**Why not Dragons:** they port almost as cleanly, but their ceiling is low (5,871 median), so they teach little about scaling. Every other tribe needs a whole BG system: Magnetic, Spellcraft, Bounties, consume-and-Fodder, or Bonus Keywords.

## Quilboar

### The three variables in the 37.0 pool

| Variable | Cards |
|---|---|
| **Count** (gems gained) | Razorfen Geomancer, Crater Miner, Roadboar, Mangled Bandit, Sly Infiltrator, Fearless Foodie (mode 2), Victorious Geomant (6 gems per 2 gold) |
| **Applications** (casts and recipients) | Hot-Air Surveyor (each gem from hand casts twice), Geomagus Roogug (gems on it echo onto another unit), Prodigious Tusker, Bonker (a gem on every other unit per attack, twice with Windfury), Turbo Hogrider (2 gems on every Quilboar per Choose One card), Veteran Brigand |
| **Size** (gem strength) | Gem Day (+1 Attack or +1 Health), Fearless Foodie (+1/+1), Sanguine Refiner (+1/+2 per attack), Sanguine Champion (+2/+1 when played and when it dies) |

**The time and acceleration terms:**
- Refiner and Champion raise gem size every fight, so size grows each turn with no further gold.
- Geomant and Tunneler raise count as gold and attacks grow.
- So board gain per turn is roughly count × applications × size(t), with size growing linearly. The total is at least quadratic in turns, and cubic once count also grows with gold.

**Inferred:** gems played in combat last only that fight. Vineweaver's text says "permanent Blood Gems", which only makes sense if ordinary ones aren't.

### How winners play it

From 9 per-turn games and 77 final boards:

- **Early (turns 1–5):** boards are only 35–45% Quilboar. Razorfen Geomancer, Prodigious Tusker, Roadboar and Tusked Camper sit next to off-tribe bodies (Zoatroid, Risen Rider, Aureate Laureate, Southsea Busker, Cord Puller, Locked-up Mutineer).
- **Turns 6–8:** 54% Quilboar at turn 6, 66% at turn 7, 79% at turn 8. The switch to the Choose One package happens here: Bramble Tunneler (8 of 9 boards at turn 8), then Thorned Trailblazer, Gem Rat and Fearless Foodie.
- **Endgame, by archetype:**
  - Choose One: Hogrider 100%, Tunneler 86%, Gem Rat 58%, Refiner 47%.
  - Gem spam: Surveyor 86%, Roogug 68%, Geomant 61%, Refiner 54%.
  - Felboar: Felboar 92%, Balinda 62%, Surveyor 54%.

### Quilboar cards (37.0, solo, tiers 1–6)

"Final" is the share of the 77 Quilboar final boards that held the card.

| T | Card | Stats | Text | Role | Bramble mapping | Tag | Final |
|---|---|---|---|---|---|---|---|
| 1 | Razorfen Geomancer | 2/1 | Battlecry: Get 2 Blood Gems. | flex/early, enabler | `on_play` → add 2 gems | G | <1% |
| 1 | Tusked Camper | 2/3 | Rally: This plays a Blood Gem on itself. | flex/early | `on_attack` → 1 gem on self (this fight) | G | <1% |
| 2 | Crater Miner | 2/2 | Choose One - Get 2 Blood Gems; or Get a Gem Day. | enabler | Choose One: 2 gems, or a Gem Day | G+H | <1% |
| 2 | Prodigious Tusker | 2/5 | Whenever another friendly minion attacks, this plays a Blood Gem on it. | flex/early, payoff | `on_attack`, subject other friendly → 1 gem on it | G | 3% |
| 2 | Roadboar | 2/4 | Rally: Get a Blood Gem. | enabler | `on_attack` → add 1 gem | G | 13% |
| 3 | Fearless Foodie | 2/4 | Choose One - Your Blood Gems give an extra +1/+1 this game; or Get 4 Blood Gems. | enabler (size or count) | Choose One: gem size +1/+1, or 4 gems | G+H | 4% |
| 3 | Gem Rat | 4/4 | At the end of your turn, get a Gem Day. | enabler (size; also a Choose One card for Hogrider) | `end_of_turn` → add Gem Day | G+H | 29% |
| 3 | Mangled Bandit | 3/3 | Activate (0): Discard a card to get 3 Blood Gems. | enabler | unit Activate, discard from hand → 3 gems | G+H | 13% |
| 3 | Sly Infiltrator | 4/5 | Choose One - Gain 2 free Refreshes; or Get 3 Blood Gems. | flex | Choose One: `free_refresh` 2, or 3 gems | G+H | 1% |
| 3 | Thorned Trailblazer | 4/5 | One Choose One card each turn has both effects combined. (1 left!) | enabler | rule: your first Choose One each turn gets both modes | H | 13% |
| 3 | Trench Fighter | 3/3 | At the end of your turn, get a Gem Confiscation. | enabler | `end_of_turn` → add Confiscation. Its steal needs a per-unit record of gem stats. | G+B | 3% |
| 4 | Bonker | 2/7 | Windfury Rally: This plays a Blood Gem on all your other minions. | payoff (applications) | Windfury + `on_attack` → 1 gem on others. Without Windfury: 2 gems per Rally. | G+K | 8% |
| 4 | Bramble Tunneler | 3/6 | Rally: Get a random Choose One card. | enabler | `on_attack` → add a random Choose One card (needs a tag filter) | H | 57% |
| 4 | Geomagus Roogug | 4/6 | Divine Shield. Whenever a Blood Gem is played on this, this plays a Blood Gem on a different friendly minion. | payoff (applications) | Shield + a "gem played on this" trigger → 1 gem on another unit (loop guard) | G | 36% |
| 4 | Hot-Air Surveyor | 3/7 | Blood Gems played from your hand cast an extra time. | payoff (applications ×2) | rule: gems played from hand cast +1 time (stacks) | G | 52% |
| 4 | Razorfen Flapper | 5/3 | Battlecry and Deathrattle: Get a Blood Gem Barrage. | enabler (shop-side) | `on_play` + `on_death` → add Barrage. Needs a game-long shop-refresh listener. | G+B | 8% |
| 4 | Snare Trapper | 4/4 | Choose One - Get a random Quilboar; or Increase your maximum Gold by 1. | flex/econ | Choose One: random Quilboar card, or `rule` income +1 for the game | H | 5% |
| 5 | Felboar (Demon/Quilboar) | 2/6 | After you cast 3 spells, consume a minion in the Tavern to gain its stats. (3 left!) | payoff | `on_spell_cast` every 3 (gems count as spells) → consume a shop unit | H(consume) | 39% |
| 5 | Razorfen Vineweaver | 4/4 | Rally: This plays 4 permanent Blood Gems on itself. | payoff (carry) | `on_attack` → 4 permanent gems on self | G | 14% |
| 5 | Sanguine Refiner | 3/8 | Rally: Your Blood Gems give an extra +1/+2 this game. | capstone (size accelerator) | `on_attack` → gem size +1/+2 | G | 43% |
| 6 | Sanguine Champion | 9/4 | Battlecry and Deathrattle: Your Blood Gems give an extra +2/+1 this game. | capstone (size) | `on_play` + `on_death` → gem size +2/+1 | G | 18% |
| 6 | Turbo Hogrider | 6/8 | After you play a Choose One card, this plays 2 Blood Gems on all your Quilboar. | capstone (applications) | trigger "Choose One card played" → 2 gems on every Quilboar | G+H | 60% |
| 6 | Veteran Brigand | 8/8 | Choose One - This plays 3 Blood Gems on all your minions; or cast Blood Gem Barrage 3 times. | payoff | Choose One: 3 gems on all, or 3 Barrages | G+H(+B) | 12% |
| 6 | Victorious Geomant | 10/10 | Activate (2): Get 6 Blood Gems. Cast any that don't fit on your left-most minion. | capstone (count) | unit Activate → 6 gems; overflow cast on the first unit in Pass order (like Acorn Spill) | G+H | 30% |

**Left out:**
- Generous Geomancer 1/1 and Loyal Mobster 6/5 are Duos-only.
- Jailbird Juggernaut 6/15 is tier 7. It still appears in 4% of finals, through tier 7 access.

**Token cards:**

| Card | Text | Notes |
|---|---|---|
| Blood Gem | Give a minion +1/+1. | A spell, cost 0 |
| Gem Day | Choose One - Your Blood Gems give an extra +1 Attack this game; or +1 Health. | Cost 0, from the wiki |
| Gem Confiscation | This plays 3 Blood Gems on a minion. It steals all Blood Gems from its neighbors. | |
| Blood Gem Barrage | After the Tavern is Refreshed this game, give its minions +2/+2 worth of Blood Gems. | |

**Neutral the winners use:** Balinda Stonehearth (T6 6/6, "Your spells that target friendly minions cast twice"), in 29% of finals.

### The gem kit to build

One subsystem:
- A Blood Gem card: kind `spell`, so it counts for Felboar; aimed at a unit; cost 0; not from the pool.
- A player gem-size counter (Attack, Health) starting at +1/+1, with no cap. The shared Ring size and the tribe-bonus layer are the precedents.
- A "play N gems on target" effect for both phases. Recruit-phase gems are permanent; combat gems last the fight unless the card says "permanent".
- A trigger for "a gem is played on this", with a loop guard.
- A rule for "gems from hand cast an extra time".

Plus:
- Choose One: modes, a tag, a "Choose One card played" trigger, and a once-a-turn "both modes" rule.
- Activate on units.
- Windfury, or re-number Bonker instead.

Optional:
- The shop-refresh listener (Barrage).
- A per-unit gem record (Confiscation).
- Discard (Bandit).
- Consume a shop unit (Felboar).

## Undead

### How it scales

- **The counter:** a tribe-wide Attack counter applies to every Undead, everywhere. Its sources:
  - Nerubian Deathswarmer +1, once when played.
  - Plaguerunner +2 when it dies, +4 if that happens in the Recruit Phase.
  - Forsaken Weaver +3 per spell cast.
  - Butchering +8 per copy. Drustfallen Butcher hands one out per 4 friendly deaths, and Butchering is itself a spell, so it also fires Weaver.
- **The two variables:** that Attack counter, times the number of Undead it reaches.
- **The clock:** deaths per fight. Reborn, Skeletons and Hands raise it, so more deaths mean more Butcherings next turn.
- **The carry:** Snazzy Phantom turns each Reborn into stats on one Undead, using that unit's Attack. That explains the 0.51 biggest-unit share.

### How winners play it

- **Turns 1–2:** about 10% Undead. Winners play off-tribe bodies: Aureate Laureate, Crackling Cyclone, Bubble Gunner, Cord Puller.
- **Turn 3:** 35% Undead. They enter the tribe through several copies of Eternal Knight, plus Deathswarmer.
- **Turns 6–7:** Mummifier and Handless Forsaken arrive.
- **Turn 8 on:** Deathly Striker, Weaver, Dead Bellringer, Phantom and Butcher.
- **Final boards:** Phantom 86%, Butcher 65%, Mummifier 59%, Handless 56%, Bellringer 53%.

### Undead cards (37.0, solo, tiers 1–6)

"Final" is the share of the 66 Undead final boards that held the card.

| T | Card | Stats | Text | Role | Bramble mapping | Tag | Final |
|---|---|---|---|---|---|---|---|
| 1 | Harmless Bonehead | 1/1 | Deathrattle: Summon two 1/1 Skeletons. | flex/early | `on_death` summon two 1/1s | C | <1% |
| 1 | Risen Rider | 2/1 | Taunt Reborn | flex/early | Taunt + Reborn | K | 11% |
| 1 | Rot Hide Gnoll | 1/4 | Has +1 Attack for each friendly minion that died this combat. | flex/early | `on_friendly_death` → +1 Attack self (this fight) | C | <1% |
| 2 | Eternal Knight | 4/2 | Has +4/+2 for each friendly Eternal Knight that died this game (wherever this is). | condition (its own sub-theme) | per-name game death counter | H | 17% |
| 2 | Nerubian Deathswarmer | 1/4 | Battlecry: Your Undead have +1 Attack this game (wherever they are). | enabler | `on_play` → Undead tribe layer +1 Attack | C (Attack-only amount) | <1% |
| 2 | Scarlet Skull | 2/1 | Reborn Deathrattle: Give a friendly Undead +1/+2. | flex/early | Reborn + `on_death` buff | K | 5% |
| 3 | Cadaver Caretaker | 3/3 | Deathrattle: Summon three 1/1 Skeletons. | filler, enabler (deaths) | `on_death` summon three | C | 9% |
| 3 | Handless Forsaken | 2/1 | Deathrattle: Summon a 2/1 Hand with Reborn. | enabler (Reborns) | `on_death` summon a 2/1 Reborn token | K | 56% |
| 3 | Mummifier | 5/2 | Deathrattle: Give a different friendly Undead Reborn. | enabler (Reborns) | `on_death` → `grant` Reborn | K | 59% |
| 3 | Prosthetic Hand (Undead/Mech) | 3/1 | Magnetic, Reborn. Can Magnetize to Mechs or Undead. | filler | drop, or port as a 3/1 Reborn | B | — |
| 4 | Dead Bellringer | 3/6 | Activate (1): Give a different friendly Undead Reborn. Then destroy it to gain +4/+4. | payoff (gold to stats; Recruit Phase deaths) | unit Activate → grant Reborn, destroy friendly (it returns, inferred), +4/+4 | K+H | 53% |
| 4 | Friendly Geist | 6/3 | Deathrattle: Your Tavern spells give an extra +1 Attack this game. | enabler | spell-power counter | H | 15% |
| 4 | Maw Caster | 4/5 | Battlecry: Destroy a friendly Undead to Discover an Undead. | flex | destroy friendly + `discover` tribe | H | <1% |
| 4 | Plaguerunner | 4/2 | Deathrattle: Your Undead have +2 Attack this game, wherever they are. (+4 if triggered outside combat!) | enabler | `on_death` → tribe layer; needs death effects in the Recruit Phase | H | 5% |
| 5 | Barrier Banshee | 8/8 | After a friendly minion is Reborn, gain Divine Shield and +8/+8. | payoff | Reborn trigger → Shield, +8/+8 (this fight) | K | 14% |
| 5 | Drustfallen Butcher | 2/7 | Avenge (4): Get a Butchering. | capstone (the clock) | `on_friendly_death` every 4 → add Butchering | C (+destroy) | 65% |
| 5 | Eternal Summoner | 8/1 | Reborn. Deathrattle: Summon 1 Eternal Knight. | payoff (EK line) | Reborn + `on_death` summon Knight | K | 30% |
| 5 | Eternal Tycoon | 4/8 | Avenge (5): Summon an Eternal Knight. It attacks immediately. | payoff | every 5 → summon a Knight that attacks at once (9.4.12) | H | 12% |
| 5 | Lichling Hoarder | 6/9 | Avenge (3): Get a plain copy of a minion that started in your warband this combat. | enabler | every 3 → `add_card` of a starting unit | C | 5% |
| 6 | Deathly Striker | 8/8 | Avenge (4): Get a random Undead. Deathrattle: Summon it from your hand for this combat only. | payoff | every 4 → random Undead to hand; `on_death` summons it from hand for the fight | H | 29% |
| 6 | Forsaken Weaver | 3/8 | After you cast a Tavern spell, your Undead have +3 Attack this game (wherever they are). | capstone (size) | `on_spell_cast` → tribe layer +3 | C | 33% |
| 6 | Snazzy Phantom | 6/8 | After a friendly minion is Reborn, give stats equal to its Attack to your right-most Undead. | capstone (carry) | Reborn trigger → stats to your last Undead in Pass order | K | 86% |

**Left out:**
- Grave Narrator 2/7 and San'layn Scribe 4/4 are Duos-only.
- Stitched Salvager 16/4 is tier 7 (2% of finals).

**Token card:** Butchering, a spell costing 3: "Destroy a friendly Undead. Your Undead have +8 Attack this game (wherever they are)."

**Kit to build:**
- Reborn, plus an "after a friendly unit is Reborn" trigger.
- Taunt (Risen Rider only).
- An Attack-only tribe-layer amount with no cap.
- Destroying a friendly unit in the Recruit Phase, with its death effects firing there.
- Activate on units.
- A per-name game death counter.
- "Attacks immediately".
- Summoning from hand for this fight only.
- A spell-power counter, for one card (Friendly Geist), which could be cut.

## Notes on numbers

- **Base bodies port nearly as they are.** Current BG median Attack+Health by tier is 4.5 / 6 / 7 / 9 / 10 / 12.5, which is close to Bramble's tier sizes.
- **The scaling numbers are the dials:**
  - Quilboar: gem start size and each size step (Gem Day, Foodie, Refiner, Champion), and Surveyor's extra casts.
  - Undead: Butchering +8, Weaver +3, Plaguerunner +2, Deathswarmer +1, Knight +4/+2.
- **Suggested order:** run each port first at BG numbers against our tribes, to see the real gap the owner expects. Then run it again re-budgeted to preset A (about 52 / 150 / 500 / 1,700 board stats at rounds 6 / 9 / 12 / 15). BG's median at round 12 is about 5 times that.

## Web sources

- [Battlegrounds/Gem Day, hearthstone.wiki.gg](https://hearthstone.wiki.gg/wiki/Battlegrounds/Gem_Day): Gem Day's text and cost.
- [Battlegrounds/Blood Gem, hearthstone.wiki.gg](https://hearthstone.wiki.gg/wiki/Blood_Gem): the base +1/+1 and that a Blood Gem is a spell.
- [Gem Day, playhearthstone.com](https://playhearthstone.com/en-us/battlegrounds/116596-gem-day): returned no card text.
- [Crater Miner, playhearthstone.com](https://playhearthstone.com/en-us/battlegrounds/116182-crater-miner): shows older text (a 1-Cost Tavern spell). The local 37.0 data says Gem Day, and I used the local data.