# Birds, pass 3 synthesis: "They come home bigger"

9 Nov 2026. This is the synthesis for the Track C Birds panel (`docs/ideation/plan-scale-rework.md`, step 1). It starts from the best-ranked design, Wild (`birds-wild.md`). It takes the best ideas from Engine (`birds-engine.md`) and Carry (`birds-carry.md`), and it fixes the breaker's points (`birds-breaker.md`) that I accept.

This is a paper design: nothing ran in Godot, and no price list was used. The numbers come from a growth-and-combat model, `build/orchestrator/pass3/birds-pass3-model.py`:
- Run `python3 -I birds-pass3-model.py ablate=1`. The saved output is `birds-pass3-model.out.txt`.
- It plays scripted lines and charges gold.
- Then it fights each line's board against target-shape boards, using the audit's combat model (reading order, pointer and flags, back-row protection, Last Blow). It adds this design's half damage, Cleave, drop-ins, halving and steals.

The target, as the breaker uses it: level with today's boards to R7, then about ×1.5 a round. Median boards are about 55 / 145 / 490 / 1,650 at R6 / 9 / 12 / 15. A strong board is 1.4× the median, about 700 at R12, and in Battlegrounds the biggest unit holds about 34% of the board.

## The pitch in three lines

1. **Nobody is ever all home.** Sell a Bird and it flies south instead. You keep it.
2. **They come home with double stats.** Each trip doubles the Bird once, so the biggest Bird gains the most. Mrs Stork makes trips short.
3. **When all seven are home, the world ends.** On the turn seven different Birds stand on your board, the Seven Whistlers halve every enemy.

The sky is your bench and your bank. The board the opponent scouted isn't the board they fight:
- a Great Lump on a Nest fights with the stats of the Bird that's away;
- when the Lump dies, that Bird drops in;
- the whole flock lands at once for the omen.

**What Battlegrounds doesn't have:**
- a unit you sell to make it stronger;
- a bench that doubles while it's off the board;
- a capstone that needs seven different units of one tribe.

The closest things: Magic's suspend (the delay), stat doublers (the Golden Egg) and Hearthstone's Menagerie cards (the "different units" count).

## What I took from each design

| From | Kept | Changed |
|---|---|---|
| **Wild** (base) | Fly South as the engine. 0/1 Eggs. The Golden Egg as the T5 reward. The Ratchet's landing (the owner's "both halves"). The omen. Answers aimed across. The sky as a dodge | **Growth moves to one doubling at homecoming** (Wild's own variation, "Grow at homecoming only"), not a Grow each End of Turn. The Golden Egg is once per Bird. Tom Tit stops touching Eggs. The Cuckoo and the Lump are rebuilt |
| **Engine** | Mr Redbreast, the robin who stays and gains a share of every homecoming. Old Tern landing the sky at once | No Tailwind (a tribe number, see the cross-tribe notes). I modelled the Cuckoo keepers and rejected them |
| **Carry** | Jack Daw's permanent steal across, given to your biggest Bird (the breaker's "best single card"). Tom Tit's half damage on your biggest Bird. Mag Pye handing stolen text to your biggest Bird | No Chick, no Feed, no Ratchet chain, no Lump shove |

**Why one doubling, and not Wild's Grow:**
- **The breaker's top break goes away.** That break was stacked Grows (a flight beside the Cuckoo, every End of Turn, every Stork recall) making a common 10× runaway. Now there is one multiplier, and the trip rules limit how often it fires.
- **The Fairies keep Grow.** The Fairies engine uses the same keyword, at the same rate, at the same time of turn. With this change Birds need no new keyword, because "comes home with double stats" sits in the Fly South reminder.
- **One visible jump.** A Bird lands at twice its size: one number, shown in the away tray before it happens.

## Why this fixes what the audit found

- **Stats parked at half.** An Egg is 0/1. Being away is the payoff now, not a tax, and the Lump lets an away Bird's stats fight anyway.
- **Flat, capped growth.** Growth is proportional with no cap. It is small early (a 2/3 lands 4/6) and large late (a 157/189 lands 314/378). Each Bird doubles at most once every two rounds, which gives the ×1.5-a-round shape on a cycling flock.
- **Combat-only payoffs.** The main payoffs are permanent and visible: homecomings, Redbreast, the Cuckoo, the Golden Egg and Jack Daw's steal. The Lump's borrowed stats are shown live on its card.
- **No concentration.** The Homecoming route builds a 31–41% carry with holders: the Lump, Tom Tit and the Ratchet. In the model, those holders are worth 25–80 points of win rate.
- **Thin gold-to-stats channel.** Mrs Stork turns every 6 gold spent into a homecoming, which doubles a Bird.

---

## Tribe rules (pass 3)

**Fly South** (keyword, 5 cards). Reminder: *"Sold, it flies south 2 turns, then comes home to hand with double stats."* (14 words)
- **Details:**
  - It pays no sale gold.
  - A Bird played this turn can't fly, so selling it is a plain sale. Every Bird must fight at home once before it flies again.
  - It comes home before Start of Turn text. If your hand is full, it waits on the doorstep and lands when there's room.
  - It doubles its own Attack and Health, including permanent buffs. It doesn't double auras or the Supper bonus.
  - A golden Bird doubles like any other (×2, not ×4).
- **The doubling is the tribe's rate parameter, h** (default ×2).

**The missed-fight rule** (Details on Mrs Stork and Old Tern, and in the rulebook). Anything that brings a Bird home early calls only Birds that have missed a fight. With the rule above, each Bird doubles at most once every two rounds. This is the tribe's loop guard. It is a rate limit, not a size cap.

**Nest.** Reminder: *"The slot a Bird left. A 0/1 Egg fights there unless a unit stands on it."*
- One Nest per slot. A new Nest replaces the old one, but the older Bird still comes home. Kept from Wild.

**Egg.** A 0/1 with no text (it was half the Bird's stats). It cracks at the first hit, which is what makes the Ratchet's drop-in a moment. Only Redwing raises it.

**Drops in** (the Ratchet's verb, one card, so plain words). The Bird fights from that slot for the rest of the fight at its current stats, then it is away again with its trip unchanged. It is not a homecoming: it doesn't double, and When played doesn't fire.

**Biggest** means the most Attack plus Health. On a tie, the first in reading order.

**Mrs Stork's count carries over** between turns, as today's engine already does (`source.counters`). Her card shows it as a pip, "4/6". Selling her loses the count.

**Golden Egg** (token spell, 0 gold, Created): *"Double a Bird's stats. Once per Bird."*
- An egged Bird shows a gold rim. A triple keeps the rim if any copy had it.
- It no longer gives Cleave, which Wild's did. The Lump owns Cleave, and Cleave on the Egg was neither modelled nor needed.

**Unchanged:**
- Away Birds can't be aimed at and don't count for triples.
- Their copies stay out of the pool, and go back if you are eliminated.
- Ghost snapshots carry the away list, so the Ratchet and the Lump work against ghosts.

---

## The 16 Birds

The tier spread stays 3/3/3/3/2/2, and every creature, name and portrait is kept.
- **Five Birds fly:** One Swallow, Chiffchaff, Mrs Jay, Old Tern and Mother Goose.
- **Two stopped flying:** Jack Daw (his steal works best every fight) and Redwing (her aura needs her home).

| T | Card | Stats | Text | Golden |
|---|---|---|---|---|
| 1 | One Swallow | 1/2 | Fly South. When played: get 1 gold. | 2/4. …get 2 gold. |
| 1 | Chiffchaff | 1/2 | Fly South. When played: gain +1/+1. | 2/4. …gain +2/+2. |
| 1 | Mrs Dunnock | 2/3 | End of Turn: your biggest Bird away comes home a turn sooner. | 4/6. …your two biggest Birds away… |
| 2 | Mr Redbreast | 2/4 | After a Bird comes home: gain an eighth of its stats. | 4/8. …gain a quarter… |
| 2 | Mrs Jay | 3/3 | Fly South. When sold: get an Acorn. | 6/6. …get two Acorns. |
| 2 | Redwing | 2/4 | Your two biggest Birds away leave Eggs with half their stats. | 4/8. Your four biggest… |
| 3 | Jack Daw | 3/4 | Start of Combat: your biggest Bird permanently steals a quarter of the stats of the enemy across. | 6/8. …steals half… |
| 3 | Old Tern | 3/4 | Fly South. When this comes home: so do your Birds that missed a fight. | 6/8. Its trips last 1 turn (golden Details). |
| 3 | Tom Tit | 3/4 | Your biggest other Bird takes half damage. | 6/8. Your two biggest other Birds… |
| 4 | Mrs Stork | 4/7 | Every 6 gold you spend: a Bird that missed a fight comes home. | 8/14. …two Birds that missed a fight… |
| 4 | The Cuckoo | 4/7 | After a Bird comes home: other Birds gain a tenth of its stats. | 8/14. …a fifth… |
| 4 | Mag Pye | 4/7 | Start of Combat: your biggest Bird steals the text of the enemy across. | 8/14. …of the enemy across and one next to it. |
| 5 | The Great Lump | 5/8 | Cleave. On a Nest, this has its Bird's stats too. | 10/16. …twice its Bird's stats. |
| 5 | Mother Goose | 6/8 | Fly South. When played: get a Golden Egg. | 12/16. …two Golden Eggs. |
| 6 | The Gabble Ratchet | 6/10 | When a unit on a Nest dies: its Bird drops in. | 12/20. …drops in with double stats. |
| 6 | The Seven Whistlers | 7/9 | Start of Combat: halve the enemy across. With seven different Birds, halve every enemy. | 14/18. …halve it twice… halve every enemy twice. |

**Text length:**
- Median 11 words, p90 14, longest 17 (Jack Daw). The guide asks for a median of 11 or less, p90 of 17 or less and a maximum of 22.
- The Fly South reminder is 14 words (limit 16).
- Old Tern's golden breaks guide rule 7 (golden text doubles the numbers). A one-turn trip is the only golden that doesn't double her pull. The other option is a plain 6/8.

**Bodies:** T3–T6 bodies are a little larger than today's. The tier-up reward is still each card's payoff, not its body (breaker shared point 2): the Lump arrives at its Nest's size, the Goose's Egg doubles your best Bird the turn she lands, and the Ratchet and the Whistlers act in the fight.

**Rounding:** every fraction rounds up (Details).

### Reading the per-card lines
- R9 / R12 / R15 numbers are from the model's typical line A (below) unless another line is named. C is the low roll, D the Flock and U the tempo line.
- Per-card numbers are end-of-round stats without the Supper bonus. The board tables show combat-start boards with it, so they differ by a point or two.
- "Away" means in the sky that fight.

### Tier 1

**One Swallow** (1/2). *Swallow, Seasonal Labourer.* Fly South. When played: get 1 gold.
- **Condition:** played. That includes every homecoming, because it comes home to hand and is played again.
- **Payoff:** about 1 gold a trip. On A that's 2 gold by R9, 3 by R12 and 5 by R16. Lines that fly her more get 4–6 by R9 and 10–14 by R16. Her body doubles too: 2/4, 8/13 and 32/52.
- **Permanence:** gold is economy; her stats are permanent.
- **Enables:** Mrs Stork's count (Swallow gold is spent gold), the Whistlers' count. On turn 1 she's a 1/2 that pays back a gold.
- **Concentrates:** no.

**Chiffchaff** (1/2). *Warbler, Town Crier.* Fly South. When played: gain +1/+1.
- **Condition:** played.
- **Payoff:**
  - He plays as a 2/3 on turn 1, the turn-1 reason to buy a Bird (08f).
  - The +1/+1 lands before the next trip doubles it, so it compounds.
  - Stats by round: R9 19/23 (Flock 7/9), R12 78/94 after a Golden Egg, R15 315/379. The low roll has 16/20, 40/48 and 163/195.
- **Permanence:** permanent.
- **Enables:** the carry. He is the usual Golden Egg target and the Lump's food. The tiny warbler that comes back from Africa as the carry.
- **Concentrates:** yes.

**Mrs Dunnock** (2/3). *Hedge Sparrow, Foster Mother.* End of Turn: your biggest Bird away comes home a turn sooner.
- **Condition:** a Bird away with 2 or more turns left (Details). It has still missed a fight.
- **Payoff:**
  - Tempo. One Bird a turn runs on Mrs Stork's two-round cycle from turn 1.
  - Growth is per trip now, so a shorter trip loses nothing. She is no longer the trap the breaker found.
  - R4–R8 she lands a 3–15-stat Bird a turn sooner. Later she does the same for a 50–150-stat Bird, if she keeps a slot.
- **Permanence:** none (tempo).
- **Enables:** early flights, and a second Stork-like source next to Stork.
- **Concentrates:** partly: she speeds up your biggest.
- **Model:** she is on A's R6 board and gone by R9, when tier 4 stayers take the capped stayer slots.

### Tier 2

**Mr Redbreast** (2/4). *Robin, Who Stays.* After a Bird comes home: gain an eighth of its stats.
- **Condition:** homecomings, from trips, Stork, the Tern and Dunnock. About 2–3 a turn from R7.
- **Payoff:** a stay-home carry that grows with the sky.
  - Stats by round: R9 14/16, R12 50/54, R15 224/255 (after a Golden Egg on R14).
  - The low roll has 9/11, 28/32 and 82/95. The Flock has 10/12, 68/75 and 195/221.
- **Permanence:** permanent and visible.
- **Enables:** a Golden Egg target that never misses a fight, and a back-row second carry.
- **Concentrates:** yes, as the second carry.
- **Dial:** ⅛. At ¼ (in an earlier run, with the keeper Cuckoo) he held 55–73% of the board.

**Mrs Jay** (3/3). *Jay, Who Plants Oaks.* Fly South. When sold: get an Acorn.
- **Condition:** flown, since flying is selling.
- **Payoff:**
  - An Acorn (Hedgerow's token: 1 gold, or food) every trip.
  - The best flier body. On A the two Jays are 16/16 and 12/12 at R9, 78/78 and 34/34 at R12, and 156/156 and 68/68 at R15.
- **Permanence:** permanent.
- **Enables:** Stork's count, the Lump's food, Hedgerow's Acorn payoffs.
- **Concentrates:** yes.
- **Not modelled:** the Acorn.

**Redwing** (2/4). *Thrush, Winter Visitor.* Your two biggest Birds away leave Eggs with half their stats.
- **Condition:** Birds away, with Redwing home.
- **Payoff:** two Eggs fight as half a Bird each: about 8/8 at R9, 15–40 stats each at R12 and 45–80 at R15. That shows the sky in the fight.
- **Permanence:** a fight aura, shown on the Nest.
- **Enables:**
  - The Ratchet: an Egg that trades first, then cracks and the Bird drops in.
  - The Flock's early boards.
- **Concentrates:** no.
- **Changes:** it no longer flies, and it no longer needs "beside".
- **Model:** the Flock and low-roll lines sell her by R12–R15 for T5–T6 stayers.

### Tier 3

**Jack Daw** (3/4). *Jackdaw, Collector of Other People's Things.* Start of Combat: your biggest Bird permanently steals a quarter of the stats of the enemy across.
- **Condition:** an enemy across Jack Daw at Start of Combat. The back row counts.
- **Payoff:**
  - The steal grows with the field. Across an average enemy it is about 4 stats at R9, 13 at R12 and 45 at R15. Across their carry it is about 12, 42 and 140.
  - The model assumes you face their carry half the time. Then your biggest Bird keeps about +8, +27 and +93 a turn.
- **Permanence:** permanent on your Bird; the enemy's loss lasts the fight.
- **Enables:** the carry, and answers: it rewards scouting.
- **Concentrates:** yes, onto your biggest.
- **Origin:** from the Carry design. It no longer flies.
- **Model:** he is in A's R9 board, and sold by R12 under the stayer cap.

**Old Tern** (3/4). *Arctic Tern, Who Has Seen Both Poles.* Fly South. When this comes home: so do your Birds that missed a fight.
- **Condition:** the Tern lands while others are away. A Stork recall counts.
- **Payoff:** every eligible Bird doubles at once.
  - On A's R15, the Tern's own trip ends and Chiffchaff lands with her: 157/189 becomes 314/378. The Swallow comes too.
  - Redbreast and the Cuckoo pay out on each Bird she brings.
- **Permanence:** permanent.
- **Enables:** the omen turn (seven home at once) and Stork (her recall can bring the Tern).
- **Concentrates:** no: it spreads, but the biggest gains most.
- **Harness rule:** fly her only with two or more Birds away.

**Tom Tit** (3/4). *Blue Tit, Petty Thief.* Your biggest other Bird takes half damage.
- **Condition:** Tom Tit alive. It's an aura, so killing him ends it. The Bird is chosen at Start of Combat.
- **Payoff:** about twice the carry's Health. In the model, R12 without him drops from 90% to 75% against a shielded carry, and from 100% to 96% against the median.
- **Permanence:** a fight aura, every fight.
- **Enables:** the carry, the Lump and Redbreast.
- **Concentrates:** yes. This is what lets a carry hold its stats (fundamentals 1.6).
- **Origin:** from the Carry design. It no longer touches Eggs, so the golden doesn't make flying free.

### Tier 4

**Mrs Stork** (4/7). *White Stork, Postmistress.* Every 6 gold you spend: a Bird that missed a fight comes home.
- **Condition:** 6 gold spent, counted across turns, with a Bird away that has missed a fight. She calls the one away longest; on a tie, the biggest.
- **Payoff:**
  - A two-turn trip becomes one missed fight, so a Bird doubles every two rounds, not three.
  - On A there are 1–2 homecomings a turn (trips and recalls) from R7, and 2–3 from R11.
  - Each recall fires the Bird's When played again: Swallow gold, Chiffchaff's +1/+1, Goose's Golden Egg.
- **Permanence:** the doubling is permanent.
- **Enables:** every homecoming payoff. Late gold buys power, because every 3-gold buy or refresh counts.
- **Concentrates:** partly. You steer her through flight order: the first Bird you fly is the first she brings back.

**The Cuckoo** (4/7). *Cuckoo, Who Doesn't Raise Its Own.* After a Bird comes home: other Birds gain a tenth of its stats.
- **Condition:** homecomings, with Birds in play. Copies stack.
- **Payoff:**
  - Every homecoming feeds the whole board. A 156/156 Jay landing gives +16/+16 to each Bird in play. Even a small landing gives +1/+1, because it rounds up.
  - Line A is +25% at R9 and R12 with her (141 vs 113, 615 vs 492).
  - The Flock route stands on her: 472 against 175 at R12, and 1,551 against 394 at R15.
- **Permanence:** permanent.
- **Enables:** the Flock route. She makes the stayers (Stork, Tom Tit, the Ratchet) worth their slots.
- **Concentrates:** no. It's the tribe's spread payoff.
- **Changed after modelling:** the Engine's keeper version left the Flock at 0.39× at R15. It was also the chore the breaker named.

**Mag Pye** (4/7). *Magpie, Receiver of Stolen Goods.* Start of Combat: your biggest Bird steals the text of the enemy across.
- **Condition:** the enemy across Mag Pye has text worth taking. It resolves before other Start of Combat text, as now.
- **Payoff:** their unit loses its text, and your carry fights with it:
  - Cleave or half damage off their carry;
  - a Ring or Pass engine;
  - Nightshade;
  - the Lantern Man's count.
- **Permanence:** this fight only.
- **Enables:** answers.
- **Concentrates:** onto your biggest.
- **Origin:** from the Carry design.
- **Not modelled:** her effect (her body is).

### Tier 5

**The Great Lump** (5/8). *Cuckoo Chick.* Cleave. On a Nest, this has its Bird's stats too.
- **Condition:** standing on the Nest of a Bird that is away. You place it, and it stays until you move it. When that Bird comes home, the Lump keeps standing on the empty slot until you move it to another Nest.
- **Payoff:** the away Bird's stats fight anyway, and Cleave uses the overkill.
  - On A it is 85/104 at R12 (on Chiffchaff's Nest) and 163/166 at R15 (on a Jay's Nest).
  - Taking its Nest stats away, R12 wins against the median fall from 100% to 19%, and R15 wins from 97% to 64%.
- **Permanence:** a live aura, shown on the card ("+156/+156 from Mrs Jay"). The Bird's stats it reads are permanent.
- **Enables:** the Ratchet. When the Lump dies on a Nest, that Bird drops in: both halves.
- **Concentrates:** yes. It's the stay-home carry body, much too big for the nest. The joke is the flavour.

**Mother Goose** (6/8). *Greylag, on a Very Fine Gander.* Fly South. When played: get a Golden Egg.
- **Condition:** played: bought, or played again after each trip. Each Bird can eat one Egg.
- **Payoff:**
  - One doubling the turn she arrives. On A she lands at R10, and Chiffchaff goes 39/47 → 78/94 on R11.
  - Another on each landing. Her R14 homecoming eggs Redbreast, 74/84 → 148/168.
  - Without Golden Eggs, A is −14% at R12 and −34% at R15.
- **Permanence:** permanent.
- **Enables:** any carry, and Stork (who brings her back sooner).
- **Concentrates:** yes, but once per Bird, so two Geese egg two different Birds. From the rhyme: Jack's goose laid him a golden egg.

### Tier 6

**The Gabble Ratchet** (6/10). *Wild Geese, Hounds of the Night Sky.* When a unit on a Nest dies: its Bird drops in.
- **Condition:** an Egg, or a unit standing on a Nest, dies in the fight. Once per Nest a fight.
- **Payoff:**
  - The sky fights. At R15 on A, the Lump dies and a 156/156 Jay drops in.
  - Without the Ratchet, R15 wins fall from 97% to 71% against the median, from 84% to 48% against a shielded carry, and from 40% to 7% against strong boards.
- **Permanence:** the drop-in lasts the fight.
- **Enables:** 0/1 Eggs (they crack at once), Redwing Eggs (they trade first), and the Lump.
- **Concentrates:** yes, it drops in the big ones.
- **Owner's favourite:** kept from pass 1. The breaker quotes 08f: "Taking away the downsides is the big thematic payoff of the Gabble Ratchet ... and that's cool".

**The Seven Whistlers** (7/9). *Curlews, Six Looking for the Seventh.* Start of Combat: halve the enemy across. With seven different Birds, halve every enemy.
- **Condition:**
  - Always: an enemy across.
  - The omen: seven different Birds on your board, the Whistlers included. That means no Eggs, no copies and no other tribes.
- **Payoff:**
  - Across their carry at R12 that is about −80 stats on a median board and −120 on a strong one.
  - In the model, swapping A's Tern for the Whistlers lifts R12 wins against strong boards from 42% to 96%. That is high, because the model's field never moves its carry (see the weak points).
  - The omen at R15 wins every model fight.
- **Permanence:** this fight only.
- **Enables:** a planned all-home turn: Stork and the Tern recall, and nothing flies.
- **Concentrates:** no (it's an answer).

---

## The tribe

### Engine and rate parameter

**The engine is the homecoming.** A Bird that flies comes home with double stats. It can't fly again until it has fought at home once, and an early recall needs a missed fight.
- With plain two-turn trips, a Bird doubles every three rounds (×1.26 a round).
- With Stork or Dunnock it doubles every two rounds (×1.41 a round), the fastest a Bird can go.
- Redbreast, the Cuckoo, Jack Daw and the Golden Egg add to that, which makes about ×1.5 a round on a cycling flock.
- Additive buffs (Supper, Chiffchaff's +1/+1, spells) bought before a trip get doubled by it. **Buff a Bird before it flies.**

**Rate parameter: h, the homecoming multiplier. Default ×2 ("double"). Sweep ×1.75 and ×2.**

The response is exponential: a step of 0.25 in h moves R15 by 1.4–1.8×. Board totals:

| Setting | A R12 | A R15 | C R15 (low) | D R15 (Flock) | X R15 (probe) |
|---|---|---|---|---|---|
| **h ×2 (default)** | **615 (1.26)** | **1,692 (1.03)** | **983 (0.60)** | **1,551 (0.94)** | **1,135 (0.69)** |
| h ×1.75 | 516 (1.05) | 1,202 (0.73) | 710 (0.43) | 1,188 (0.72) | 882 (0.53) |
| h ×2.25 (too hot) | 843 (1.72) | 3,066 (1.86) | 1,620 (0.98) | 2,209 (1.34) | 2,414 (1.46) |
| Target median | 490 | 1,650 | 1,650 | 1,650 | 1,650 |

**Secondary dials**, in the order to turn them if a piece runs hot or cold:

| Dial | Default | Sweep | What the model shows |
|---|---|---|---|
| Cuckoo share, k | ⅒ | 1⁄12–⅛ | ⅛ lifts the Flock to 1.18× at R15; ⅙ to 1.84× (too hot); 1⁄20 drops it to 0.64× |
| Redbreast share, s | ⅛ | ⅒–⅙ | A at R15: 1,795 at ⅒, 1,402 at ⅙ (path effects: he takes Golden Eggs); ¼ held 55–73% of the board in an earlier run |
| Jack Daw steal, f | ¼ | ⅕–⅓ | A at R15: 1,634 at ⅕, 2,119 at ⅓ |
| Stork step, g | 6 gold | 5–8 | Within about 15% of the default: the scripted lines respond to timing as much as to the step |
| Golden Egg | ×2, once per Bird | on / off | Off: A −14% at R12, −34% at R15 |
| Whistlers | ½ | ½, ⅓ | ⅓ if the harness confirms the model's 42% → 96% |

Differences under about 15% are path noise in this model, because its lines are scripted.

### When it comes online (typical line A, board ÷ target)

| R5 | R6 | R7 | R8 | R9 | R10 | R11 | R12 | R13 | R14 | R15 | R16 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0.50 | 0.75 | 0.94 | 0.96 | 0.97 | 1.09 | 1.37 | 1.26 | 1.06 | 1.16 | 1.03 | 0.79 |

- **Behind at once, R3–R6.** Flights cost bodies while losses are cheap.
- **Level R7–R9.** Mrs Stork arrives at R7 and the flock cycles every two rounds.
- **Ahead R10–R12.** The Goose's first Egg lands, then the Lump stands on the biggest Nest.
- **About level R13–R15.** The R16 dip is the model running out of scripted arrivals and tier-ups.

The model leaves out neutrals and spells other than Supper, so R4–R7 read 10–20% low.

### The decision it creates

Every turn: **who flies, before which fight?**
- **The best fighter or the best grower.** The biggest Bird gains the most from a trip, and it's your best fighter. The Lump (it holds the Nest's stats) and the Ratchet (it drops the Bird in) let the sky fight anyway, but only on one Nest.
- **Flight order is Stork's order.** She brings back the Bird away longest, so the order you fly in is the order they come home. That is how you steer her. It replaces the breaker's "you pick", which needed a mid-purchase prompt.
- **Where the Lump stands.** On the biggest Nest it fights biggest. On the Nest of the Bird that comes home next, it moves again next turn.
- **Which Bird eats the Golden Egg.** Each Bird eats one, so it goes to the carry, or to Redbreast who never misses a fight. Hold it while that Bird is away, because away Birds can't take spells. Cast additive buffs before a flight.
- **Stayer slots or flier slots.** Seven slots. Every stayer (Stork, Tom Tit, the Ratchet, the Whistlers) is a slot that never doubles. The model caps stayers at 5 from R7 and 4 from R10, and lines that break the cap fall behind.
- **The all-home omen turn.** Land everyone with Stork and the Tern, fly nothing, and halve every enemy. Growth is per trip now, so an all-home turn costs only a turn of tempo, not growth.
- **Scouting and dodging.** Fly before a ghost or a weak board, and keep the flock home before an elimination fight. If a Changeling, Belladonna or Bufo sits across your carry, fly the carry this turn.

### Carry route: Homecoming (the main route)

- One big flier (Chiffchaff by default, or Mrs Jay) cycles every two rounds with Stork and eats the first Golden Egg.
- The Lump stands on its Nest while it's away, Tom Tit halves the damage it takes, and the Ratchet drops it in when the Lump dies.
- Mr Redbreast is the stay-home second carry and the second Egg.
- **Line A:** 615 at R12 (biggest 31%), 1,692 at R15 (biggest 41%). It wins 100% and 97% against median boards and 42% and 40% against strong ones.

### Non-carry route: the Flock

- Five or six fliers cycle through Stork. The Cuckoo feeds every Bird a tenth of each homecoming, Redwing Eggs fight as half Birds, and the Ratchet drops the sky in.
- No unit is over 35%.
- **Line D:** 472 at R12 (0.96×), 1,551 at R15 (0.94×).
- **It fights worse than Homecoming:** 53% and 27% against the median at R12 and R15, 0% against strong. A wide board of mid-size Birds trades badly into a 34% carry when it has no Lump and few holders.
- **It stands on the Cuckoo:** 0.24× at R15 without her.
- **The fix if the harness agrees:** the Cuckoo at ⅛ first, then Whistlers in the Flock's keep list.

### Answers to other tribes' carries
- **The Seven Whistlers:** halve the enemy across. On an all-home turn, halve every enemy.
- **Jack Daw:** permanently steals a quarter of the enemy across, so he scales with the field.
- **Mag Pye:** hands the text of the enemy across to your biggest Bird.
- **The sky:** away Birds can't be aimed at. No other tribe can hide its carry from a scouted answer.
- **All three answers aim across**, and Birds add no any-row answer to the pool's budget (fundamentals question 2). They reach a back-row carry only when you scout and place them there.

### Weak points
- **Early boards.** Every line is 0.38–0.85× at R6, and loses nearly every model fight at R6. The model reads 10–20% low early (no neutrals, few spells), and its field is the ideal median. **The harness should check Birds' R4–R7 win rate first.** Levers, in order:
  - Dunnock at tier 1 as a 2/4;
  - Eggs at ¼ of their Bird;
  - flights from R4, not R3.
- **No tempo line.** Birds have no stay-home payoff, so the tempo line (U) is 0.61–0.85× to R12 and 0.65× at R15. A Bird player who doesn't fly is a weak Bird player. That's the identity, but the harness's tempo line still needs to be playable, and U is the best of four tempo policies tried.
- **The slot squeeze.** Schedules that look strong are weaker in the model:
  - Line B (Stork R6, Goose R9, Lump R10, early tier-ups) is 0.72–0.81×.
  - Line X (every engine piece early, two Geese, golden Jay, golden Stork) is 0.45–0.88×.
  - Extra small fliers and early stayers starve the flier slots and use up Stork's recalls on small Birds. Real players face this as a decision; scripted bots get it wrong. The harness's knob-tuning budget should cover the stayer cap and flight order.
- **The Flock route depends on the Cuckoo**, the pattern the breaker flagged in Carry. Homecoming doesn't: A without her is 1.00× at R12 and 1.15× at R15.
- **Back-row reach.** Kill Tom Tit and the carry loses half damage. Kill the Ratchet and nothing drops in.
- **Proportional answers on the carry.** A Changeling copies a 316/380 Chiffchaff. The dodge needs scouting and a free flight.
- **Being read.** Nests show, and the Lump's live number tells the opponent which Bird it holds.
- **Supply.** Five fliers are shared by the lobby, so a second Bird player starves you of Jays and Chiffchaffs.
- **The Whistlers may be too strong.** The model's field never moves its carry away from the Whistlers. Real opponents will. If the harness shows the same 42% → 96%, the Whistlers' dial goes to ⅓.

### Two highroll moments
1. **Everybody home.**
   - Round 15 on line A: Old Tern's trip ends, and she brings home every Bird that missed a fight.
   - Chiffchaff lands at 314/378, double the 157/189 that left, and the Swallow comes with him.
   - Redbreast takes an eighth of each. With the Whistlers on the board and seven different Birds home, the curlews whistle and every enemy halves before the first attack.
   - The motto is "Nobody is ever all home". The one time they are, the world ends. That board wins every model fight at R15.
2. **The goose that laid the golden egg.**
   - Golden Mother Goose lands with two Golden Eggs. On A's R14, the first doubles Redbreast as she lands, 74/84 → 148/168. The second waits for Mrs Jay, whom Stork brings home at 156/156 the same turn, and makes her 312/312.
   - That is about +480 stats in one turn, over 40% of a median R14 board.
   - Stork brings her back two turns later, and she eggs the next two.
   - Once per Bird keeps it from stacking on one unit.

**The everyday surprise is the Ratchet.** The Lump takes the first hits, dies, and a 156/156 Jay drops out of the sky into its slot.

**The tail.** No modelled line goes above 1.4× the target, and none runs away. The breaker's probe, with every engine piece, peaks at 0.88×. The owner allows a rare top 1% at up to 10× the median (09d). By arithmetic, these highrolls reach about 2–3×. The model can't show it: its scripted golden probes lose more to slot and gold costs than they gain.
- Today's tail sources: golden Goose, golden Ratchet (drop-ins at double), golden Cuckoo, the omen.
- If the harness wants a longer tail, the lever is **golden Birds come home with triple stats**. It is rare (it needs a triple of a flier), visible, and bounded by the missed-fight rule.

---

## Boards at R6 / R9 / R12 / R15

The board is 7 slots: units home plus Eggs. The sky isn't counted unless it drops in.

Win rates are against four target-shape fields:
- **median:** a 34% carry in the front or back row;
- **shielded:** the same, with a Shield on their carry;
- **even:** seven equal units;
- **strong:** 1.4× the median.

### Line A, Homecoming (typical roll)

Arrivals: Chiffchaff R1, Swallow R2, Jay and Redbreast R3, Dunnock R4, Tom Tit R5, Jack Daw and Tern R6, Stork R7, the Cuckoo R9, Goose R10, the Lump R11, the Ratchet R12, the Whistlers R13. Tier-ups: T2 R3, T3 R5, T4 R7, T5 R10, T6 R12.

| Round | Board (×target) | Biggest | On the board | Away | Wins: median / shielded / even / strong |
|---|---|---|---|---|---|
| R6 | 41 (0.75) | Jay 6/6, 29% | Jay, Redbreast 3/5, Tom Tit, Jack Daw, Dunnock, two 0/1 Eggs | Chiffchaff 2/3, Swallow, Jay | 0 / 0 / 0 / 0% |
| R9 | 141 (0.97) | Chiffchaff 16/20, 26% | Chiffchaff, Redbreast 15/17, Stork 7/10, Cuckoo 7/10, Tom Tit, Jack Daw, Tern | Swallow, Jay 16/16 (Jay 12/12 in hand) | 78 / 56 / 35 / 2% |
| R12 | 615 (1.26) | Lump 85/104, 31% | Lump (on Chiffchaff's Nest), Jay 79/79, Redbreast 51/55, Jay 35/35, Stork 16/20, Tom Tit 15/17, Tern 11/13 | Chiffchaff 78/94, Swallow, Goose | 100 / 90 / 100 / 42% |
| R15 | 1,692 (1.03) | Chiffchaff 316/380, 41% | Chiffchaff, Redbreast 225/256, Lump 163/166 (on a Jay's Nest), Swallow 33/53, Tern 21/25, Stork 16/20, Ratchet 7/11 | Jay 156/156, Jay 68/68, Goose | 97 / 84 / 100 / 40% |

### The other lines (board ÷ target, then wins against the median)

| Line | R6 | R9 | R12 | R15 |
|---|---|---|---|---|
| B, early Stork and tier-ups | 21 (0.38) 0% | 118 (0.81) 38% | 374 (0.76) 3% | 1,180 (0.72) 5% |
| C, low roll (no Stork to R12, no Goose, no Cuckoo) | 43 (0.78) 0% | 115 (0.79) 34% | 374 (0.76) 24% | 983 (0.60) 17% |
| D, Flock | 36 (0.65) 0% | 114 (0.79) 6% | 472 (0.96) 53% | 1,551 (0.94) 27% |
| U, `birds_tempo` | 47 (0.85) 0% | 89 (0.61) 0% | 361 (0.74) 2% | 1,066 (0.65) 29% |
| X, breaker probe (everything early, two Geese, golden Jay and Stork) | 25 (0.45) 0% | 117 (0.81) 72% | 430 (0.88) 14% | 1,135 (0.69) 39% |
| T, an earlier tempo try (fold in at R9) | 31 (0.56) 0% | 100 (0.69) 8% | 247 (0.50) 0% | 546 (0.33) 0% |

**Reading:**
- The low roll stays within an order of magnitude (0.6–0.8×), which meets the owner's fun-first bar (09c).
- Nothing runs away. The typical line is ahead R10–R12 and about level after.
- The smaller side wins more often than the plan's 14–26% band: line A has fewer stats than the strong field (615 against 686 at R12) and still wins 40–42%. The field has no text, so the real figure will be lower. The harness should check it.

### Holder ablations (line A, `ablate=1`)

| Board | As is | Without Tom Tit | Without the Ratchet | Lump without its Nest | One stayer → Whistlers |
|---|---|---|---|---|---|
| R12 (615) | 100 / 90 / 100 / 42 | 96 / 75 / 100 / 43 | — | 19 / 6 / 8 / 0 | 100 / 100 / 100 / 96 |
| R15 (1,692) | 97 / 84 / 100 / 40 | — | 71 / 48 / 100 / 7 | 64 / 42 / 100 / 0 | 100 / 100 / 100 / 100 (omen) |

---

## Where it could run away, and the lever for each

| Risk | Why it's bounded | Lever if the harness shows it |
|---|---|---|
| Stacked multipliers | One doubling a trip; a Bird must fight at home before it flies; early recalls need a missed fight. At most ×2 every two rounds per Bird | h ×1.75 |
| Goose cycling | The Golden Egg is once per Bird. Two Geese or a golden Goose egg different Birds | Golden Goose gets one Egg, plus Cleave |
| Redbreast or the Cuckoo on a fast flock | They are additive shares of each homecoming: ⅛ to him, ⅒ to each Bird in play | s ⅒, k 1⁄12 |
| Copies of the Cuckoo | Copies stack. Two of a T4 is reachable | Sweep two Cuckoos. Lever: "your other Birds" excludes other Cuckoos |
| Lump on a big Nest | It mirrors one Bird; it doesn't compound | Golden Lump ×1.5 |
| Whistlers' halving | The field in the model doesn't dodge | ⅓ |
| Stork + Swallow gold | A Swallow refunds 1 gold per trip, against 6 gold per recall | none needed |

There are no per-card size caps. The only rate limits are the loop guards in Fly South and the Golden Egg.

---

## Harness line policies

Card ids are as in `content/units/`. The new token is `golden_egg`, and `nest_egg` changes to 0/1. Line A in the model is `birds_homecoming`, and line U is `birds_tempo`. The model's arrival rounds stand in for the shop. The harness uses the priority lists.

```json
{
  "birds_homecoming": {
    "tribe": "birds",
    "engine_flag": true,
    "buy_priority": ["mr_redbreast", "chiffchaff", "mrs_jay", "one_swallow", "mrs_dunnock", "tom_tit", "mrs_stork",
                     "jack_daw", "old_tern", "mother_goose", "cuckoo", "great_lump", "gabble_ratchet",
                     "seven_whistlers", "redwing", "mag_pye"],
    "max_copies": {"mrs_jay": 2, "default": 1, "triple": "buy a third copy only when it makes a golden"},
    "stayer_keep_rank": ["mrs_stork", "mr_redbreast", "great_lump", "gabble_ratchet", "tom_tit", "seven_whistlers",
                         "cuckoo", "jack_daw", "mrs_dunnock", "redwing", "mag_pye"],
    "stayer_cap": {"R1": 7, "R7": 5, "R10": 4},
    "climb": {"T2": 3, "T3": 5, "T4": 7, "T5": 10, "T6": 12},
    "harvest_supper_rounds": [6, 8, 10],
    "save_rule": "Spend out every turn. The one save: on the turn before a scheduled tier-up, keep what next turn's discounted tier cost needs beyond next turn's income. With Mrs Stork in play, spend any leftover on refreshes; her count carries over, so no 6-gold blocks are needed.",
    "fly_policy": {
      "from_round": 3,
      "who": "every flier that has fought at home since it was played; Mother Goose first, then biggest first",
      "keep_home_min": 3,
      "old_tern": "fly only with 2 or more Birds away",
      "omen_turn": "if seven different Birds including seven_whistlers can stand on the board this turn, fly nothing",
      "elimination_guard": "don't fly the biggest Bird when Health is 2x the round's likely loss or less"
    },
    "great_lump_seat": "End of Turn: the Nest of the biggest Bird away",
    "golden_egg": "the biggest Bird without an Egg; hold it while that Bird is away; play it at End of Turn if that Bird isn't due home next turn",
    "placement": "seven_whistlers across the scouted biggest enemy, jack_daw across the second biggest, mag_pye across the enemy with the best text; back row: the biggest Bird, then tom_tit, gabble_ratchet, mr_redbreast, mrs_stork; Eggs and the rest in the front row"
  },
  "birds_tempo": {
    "tribe": "birds",
    "engine_flag": false,
    "switch_to": {"line": "birds_homecoming", "round": 7},
    "buy_priority": ["mrs_jay", "mr_redbreast", "mrs_dunnock", "chiffchaff", "one_swallow", "tom_tit", "jack_daw",
                     "mrs_stork", "mag_pye", "mother_goose", "great_lump", "old_tern", "cuckoo", "seven_whistlers",
                     "gabble_ratchet", "redwing"],
    "max_copies": {"mrs_jay": 2, "default": 1, "triple": "buy a third copy only when it makes a golden"},
    "stayer_keep_rank": ["mr_redbreast", "mrs_stork", "great_lump", "tom_tit", "jack_daw", "seven_whistlers",
                         "gabble_ratchet", "mag_pye", "mrs_dunnock", "cuckoo", "redwing"],
    "stayer_cap": {"R1": 7, "R7": 5, "R10": 4},
    "climb": {"T2": 3, "T3": 5, "T4": 7, "T5": 10, "T6": 12},
    "harvest_supper_rounds": [4, 6, 8],
    "save_rule": "Spend out every turn; the one save is the turn before a scheduled tier-up, as in birds_homecoming.",
    "fly_policy": {
      "from_round": 4,
      "who": "Chiffchaff and One Swallow only, until the switch round; never mrs_jay before it",
      "keep_home_min": 4,
      "max_away": 3
    },
    "great_lump_seat": "as birds_homecoming",
    "golden_egg": "as birds_homecoming",
    "placement": "as birds_homecoming"
  }
}
```

**Bot needs for both lines:** a fly decision, the stayer cap and keep rank, the Lump's seat, the Golden Egg target and hold, and scouted placement. Without them Birds look weak for the wrong reason, as in passes 1 and 2. In the model, schedule and slot choices alone (line B against line A) moved R15 by 1.4×.

---

## The breaker's points: accepted and rejected

| Breaker point | Call | How or why |
|---|---|---|
| Wild, must fix: a common 10× runaway from stacked Grows and Goose cycling | **Accepted, fixed another way** | One doubling a trip, under the missed-fight rule, replaces every Grow source, and the Golden Egg is once per Bird. The breaker's own fixes ("Grow once a turn", Goose "when bought") aren't needed. The Goose keeps her replay, which is the tribe's identity. The probe X peaks at 0.88× |
| Wild, must fix: two Geese = golden Goose | **Accepted** | Once per Bird: two Geese egg two different Birds |
| Wild, must fix: golden Tom Tit makes flying free | **Accepted** | Tom Tit is the Carry's half damage on your biggest other Bird. Only Redwing raises Eggs: two of them, to half |
| Wild, should fix: stayers never grow | **Accepted, partly** | Redbreast, the Cuckoo, the Lump and Jack Daw now grow stayers. Stork and the Ratchet stay small, and their payoff is their reward |
| Wild, should fix: Redbreast is dead late | **Accepted** | The Engine's Redbreast at ⅛ of each homecoming: 224/255 at R15 |
| Wild, should fix: Dunnock is a trap | **Accepted, fixed another way** | Growth is per trip now, so shortening a trip costs nothing. The breaker's fixes (lengthen trips, or Grow a Nest) aren't needed |
| Wild, should fix: exponential rate sensitivity; sweep only clean values | **Accepted** | Sweep h ×1.75 and ×2 only. ×2.25 tested at 1.86× (too hot) |
| Wild, should fix: early tempo above target | **Accepted** | Every line is 0.38–0.85× at R6 now. If anything it's too far behind; the levers are listed |
| Wild, note: a fake Golden Egg timing decision | **Accepted** | Dropped. The real one: cast additive buffs before a flight, and hold the Egg while the target is away |
| Wild, note: "Stork, you pick which" | **Rejected: no pick** | It stays "the one away longest", which matches DECISIONS' pass 2 call. The player steers her through flight order, and no new mid-purchase prompt is needed |
| Engine, must fix: two Geese and Tailwind's guard | **N/A** | Tailwind isn't adopted; the Golden Egg is once per Bird |
| Engine, must fix: under target at R9 | **Checked** | A is 0.97× at R9 |
| Engine, should fix: answers aim themselves | **Accepted** | Jack Daw, Mag Pye and the Whistlers all aim across |
| Engine, should fix: fliers are interchangeable fuel | **Accepted** | The doubling is proportional, so who lands matters, and each flier replays differently: gold, +1/+1, an Acorn, the Tern's pull, a Golden Egg |
| Engine, should fix: golden Redbreast is a plan, not a highroll | **Accepted** | Not counted in the tail |
| Engine, note: Cuckoo keepers are a chore | **Accepted** | Modelled first: the Flock was 0.39× at R15 with keepers. Replaced with the spread Cuckoo (0.94×) |
| Engine, note: Tailwind's "X" is undefined | **N/A** | No Tailwind |
| Carry, must fix: the Ratchet chain | **N/A** | No chain. The Ratchet drops in |
| Carry, must fix: the curve hangs on one T4 card | **Accepted for the tribe; it stays for one route** | Homecoming doesn't need the Cuckoo; the Flock does. Listed in the weak points |
| Carry, should fix: unmodelled | **Accepted** | This model fights boards |
| Carry, should fix: auto-biggest repeats Hunters' Alpha | **Rejected, with a reason** | "Your biggest Bird" stays on Jack Daw, Mag Pye, Tom Tit and Dunnock. Flights change who is biggest at home every turn, so it doesn't lock the carry, which was the Hunters designer's objection |
| Carry, should fix: drops the owner's Ratchet landing | **N/A** | Kept |
| Carry, should fix: "Feed" is taken | **N/A** | No Feed. Homecomings use "comes home" |
| Carry, should fix: golden Whistlers destroy across | **N/A** | Golden halves twice: a quarter is left |
| Carry, note: copies stack k | **Accepted** | Copies of the Cuckoo stack; the sweep should test two |
| Carry, the Lump shove (in "what the synthesis should take") | **Rejected** | The Lump already takes over by standing on the carry's Nest. A shove would add a second way to switch carries and a second carry-buff layer |
| Shared: Stork's count undefined | **Accepted** | It carries over, with a pip on the card |
| Shared: T5–T6 bodies miss the progression bar | **Accepted** | Bodies a little larger, and the payoff is stated as the reward. The harness should check payoff, not body |
| Shared: "lands" vs "comes home" | **Accepted** | The Ratchet's verb is "drops in" |
| Shared: no design fought a board | **Accepted** | Fought against four field shapes, with ablations |
| Shared: the any-row answer budget | **Accepted** | Birds add none |
| Breaker's synthesis: "Core: Wild's Grow-while-away" | **Rejected for a variation** | Grow at homecoming as one doubling. It needs no keyword, leaves Grow to the Fairies, and has one rate limit, not two |
| Breaker's synthesis: Tom Tit's Shield or the Carry's half damage | **Took the half damage** | It is proportional, so it holds at 4-digit stats, and other tribes already use Shield |

---

## Cross-tribe notes

- **Grow goes to the Fairies.** Birds use no Grow keyword: their growth is one doubling at homecoming, off the board, tied to a trip. It doesn't look like the Fairies' growing Ring, or the Oozes' Simmer (halving each End of Turn in the back row).
- **No tribe number.** Engine's Tailwind followed the Blood Gem template, like the Bog engine's Peat, the Fairies carry's Glamour and the Hunters carry's Titbits. Birds don't use it, which leaves room for one or two other tribes to keep theirs.
- **Answers:**
  - Birds add no any-row answers, only three across.
  - Mag Pye's text steal and the Whistlers' halving overlap Track B's proportional pieces. The cross-tribe count should include them.
- **"Your biggest Bird"** is on five Bird cards. The Hunters carry rejected auto-biggest. Birds keep it, because flights move it.
- **Acorns.** Mrs Jay makes Hedgerow's token: a deliberate splash, kept from Wild.
- **Other Bird-tagged units.** Six more are in the pool and outside these 16: `buzzard`, `carrion_crow`, `drumming_woodpecker`, `fieldfare`, `old_crane` and `still_water_heron`, from the prototype spec. None of them reads homecomings. Whether they stay Birds is the cross-tribe synthesis's call.

---

## Engine support needed

**Exists** (pass 2):
- the Fly South away zone and Nests;
- `on_home`, `bring_home` and `on_gold_spent every N` (with the counter on the unit);
- the Ratchet's landing;
- `mag_pye`'s text steal;
- `dunnock`;
- Acorns.

**Changed or new:**
1. **Homecoming doubling.** On `on_home`, multiply the Bird's permanent Attack and Health by h (config). It doesn't touch auras or the tribe bonus.
2. **The missed-fight flag.** It is set on away Birds at combat and cleared on homecoming. `bring_home` from Stork and the Tern filters on it.
3. **Egg.** The default `egg_spec` becomes 0/1. Redwing sets ceil(½ stats) on the Eggs of the two biggest away Birds (golden: four).
4. **Mr Redbreast.** `on_home` (any Bird): this gains ceil(s × the Bird's stats).
5. **The Cuckoo.** `on_home` (any Bird): every other Bird in play gains ceil(k × the Bird's stats). Each copy fires.
6. **Mrs Stork.** The every-6 counter persists across turns. `bring_home` takes the eligible Bird away longest (tie: biggest).
7. **Old Tern.** `on_home` (self): `bring_home` every flagged Bird away. Golden: trips of 1 turn.
8. **Mrs Dunnock.** At End of Turn, the biggest away Bird with 2+ turns left has its trip cut by 1.
9. **Jack Daw.** A Start of Combat proportional steal across (Track B), written to the permanent layer of your biggest Bird.
10. **Tom Tit.** A half-damage aura (Track B) on the biggest other Bird, chosen at Start of Combat. It ends when Tom Tit dies.
11. **Mag Pye.** The stolen text goes to your biggest Bird, not to Mag Pye.
12. **The Great Lump.** Cleave (Track B), plus a live aura: + the stats of the Bird whose Nest it stands on (golden ×2). It moves only when placed.
13. **Mother Goose.** `on_play` adds a `golden_egg` spell. The Golden Egg is a 0-gold aimed spell, Bird only, using Track B's doubler. It sets an `egged` flag, kept through triples, and Birds with the flag can't be aimed at.
14. **The Gabble Ratchet.** When a unit on a Nest dies: summon the Nest's Bird at its current stats ("drops in"). Once per Nest a fight. It is not an `on_home`.
15. **The Seven Whistlers.** Halve across (Track B). With seven distinct Bird cards on the board, halve every enemy.

**UI:**
- The away tray shows each Bird now and at landing (`home in 1 · 78/94 → 156/188`).
- Stork's pip shows "4/6".
- The Lump shows "+156/+156 from Mrs Jay".
- The Golden Egg previews its target, and egged Birds show a rim.
- The Sell button already reads "Fly south".

---

## Variations, if the panel wants another shape

- **Golden Birds come home with triple stats.** It adds a tail with no new text, and the missed-fight rule still bounds it. It's the first lever if the harness shows too little top-1% upside.
- **Long Haul** (from Wild). When sold, choose 1–3 turns away, and longer trips multiply more (×2, ×2.5, ×3). Trip length becomes a decision per flight.
- **The keeper Cuckoo** (from Engine, modelled). "When a Bird comes home, the unit on its Nest gains half its stats." A placement puzzle, but the Flock fell to 0.39× at R15, and the breaker called it a chore. Keep it in reserve if the spread Cuckoo plays flat.
- **If the Fairies give up Grow,** Wild's End of Turn Grow at ⅓ could come back under the missed-fight rule. I don't recommend it: two growth moments per trip are harder to read than one.

## Calls for the orchestrator to log

1. Birds give Grow to the Fairies; their growth is one doubling at homecoming (h ×2).
2. The missed-fight rule is the tribe's loop guard, and the Golden Egg is once per Bird.
3. The spread Cuckoo at ⅒ replaces the keeper Cuckoo (the Flock went from 0.39× to 0.94× at R15).
4. Stork has no player pick, and her count carries over.
5. Jack Daw and Redwing stop flying.
6. The Carry design's Lump shove is not taken.

## Model limits

- Scripted arrivals stand in for the shop, so lines are path-sensitive. Differences under about 15% are noise, and strong-looking schedules can come out lower.
- No neutrals, and no spells except Harvest Supper: R4–R7 read 10–20% low.
- The field boards are plain: no text, and they never move their carry away from the Whistlers or Jack Daw.
- Jack Daw's permanent steal is an expected value (their carry half the time). Mag Pye's text and Jay's Acorn aren't modelled. The omen turn and the elimination guard in the harness JSON aren't played by the model's lines; the omen is tested only as a board.
- It is not a lobby: no pool depletion, no second Bird player, no hero Health.
