# The owner's taste in auto-battler systems

**What this is.** A guide for agents to what the owner thinks makes auto-battler systems good or bad, and why. It pulls together the owner's dictations of 8 November 2026 and adds evidence an agent can check: card text, equations and runnable models. The owner's own words are in the three source notes. Read them for nuance; this page doesn't replace them.

- [owner-notes/2026-11-08-autobattler-systems-thoughts.md](owner-notes/2026-11-08-autobattler-systems-thoughts.md) (N-A): paradigms, damage, shop, pool, combining copies.
- [owner-notes/2026-11-08b-taste-answers.md](owner-notes/2026-11-08b-taste-answers.md) (N-B): where Bramble should sit, designs the owner likes, Infinite Pirates, depth vs complexity.
- [owner-notes/2026-11-08c-rulebook-go-ahead-and-scaling.md](owner-notes/2026-11-08c-rulebook-go-ahead-and-scaling.md) (N-C): rulebook go-ahead, the third scaling factor, engine output.

**How to use it.** Use it as a lens, not a veto. Each principle is something to aim for and to explain your design against. Per the working rules, don't cut a design because it seems to break one. Say which principle it strains, and propose a version that keeps the design's core. The principle wording is Claude's synthesis, and each one cites the owner's words. Where the owner hasn't decided, this page says so.

**Status against the rules.** The rulebook (v0.5, 8 Nov) now reflects this page in several places:
- **Damage:** base damage for the round + 1 per surviving starting unit, with no cap (10.1).
- **Stat scale:** about double Battlegrounds (1.2.5).
- **Shop:** a fixed 5-card shop as the working value to experiment from (6.1.1).
- **Still open:** starting health, the pool, tier weighting, shop-slot upgrades and multiple-copy strategies (2.2.5, 5.1.4, 6.1.6, 6.1.7, 7.3.8).

See [rulebook-deltas.md](rulebook-deltas.md).

---

## 1. The principles

### P1. Depth without complexity
The owner wants "the kind of depth TFT has, with mechanics as simple as Galaxy's" (N-B §1). Great designers keep decisions meaningful and remove everything a decision doesn't need to keep its weight.

- **Complexity is fine when it buys enough depth.** Nothing adds complexity with zero depth, but some things add much more complexity than depth (N-B §4.2).
- **Test:** does this add options a good player would actually weigh? Or options they learn to ignore?
- **Positive example:** Galaxy. No gold, no levelling choice, pick 1 of 3 (plus a spell). Yet top players disagree about the best pick, because the cards are flexible enough to use in many ways and different enough in what they offer (N-B §5). Evidence: [§2.2](#22-shop-clutter-how-much-of-a-late-battlegrounds-shop-is-noise).
- **Negative examples:** Infinite Pirates (§2.1), and late-game Battlegrounds shops full of tier 1 units that players train themselves to skip over (§2.2).

### P2. Strategy and tactics, with solved comps only late
A paradigm is good when it offers lots of interesting strategic or tactical options, ideally a mix (N-A §1).

- Some solved strategy is inevitable and acceptable, **as long as it takes cool tactical play to reach it** (N-B §2).
- When it shows up matters. Solved in the **end game**: acceptable. Solved in the **mid game**: a problem. Solved in the **early game**: a very big problem.
- **What the owner dislikes in TFT:** you pick a solved comp instead of making a strategy. Thresholds are the cause. Traits give nothing from 2 to 3 units and a lot at 4, so running 3 is never a real choice (N-A §3.1).
- **What the owner likes in TFT:** tactical depth, especially the economy. It's a constant trade between strength now and more strength later, with HP as the resource you risk (N-A §3.1).
- **Design implication (synthesis):** avoid power curves with dead steps (2 → 3 gives nothing). Each extra piece should be worth something, so in-between counts are real choices.
- **What "tactical play to reach it" means** (N-B §7.1):
  - **The shop doesn't offer the best option every time.** Strong setups exist but appear only sometimes. Example: one early Eternal Knight is decent tempo, two can carry the whole early game, and on the Lich King or Teron Gorefiend (who give it an extra death) they can carry you almost straight to tier 6. You don't get offered that every game.
  - **Make the best of what you're offered.** The choice is between a creative path with what you have and paying gold to refresh for the theoretically best piece. There's often a good path if you're creative.
  - **Be just selective enough** to get real synergy, rather than a pile of individually strong units that don't work together.
  - **Know when to invest in strength now.** Spending some early economy to stay strong saves HP, so you don't have to spend in two turns' time, and can use that time to reach the top tier. The owner sees this as what separates the best players from very good ones.
- **Design implication (synthesis):** the pool and shop must make strong setups *available but not guaranteed*, with enough alternative paths that improvising is usually viable.

### P3. Exciting chase units, with counterplay
At the top tiers, you want powerful, exciting chase units. Combining them will sometimes get out of hand, and that's acceptable **if there's counterplay**: every unit, however strong, should have a weakness (N-B §2).

- **Example of counterplay the owner likes:** in Battlegrounds, a clever opponent with Venomous units, Leeroy the Reckless ("Deathrattle: Destroy the minion that killed this.") and other scam units, positioned well, can beat a board far bigger than theirs.
- **Strategies should have weaknesses that force adaptation** (N-B §7.5). Battlegrounds boards often ended up lopsided: all Attack, all Health, or one or two huge units next to small unbuffed ones. Fixing your board's weakness over the game is interesting, **as long as there are several ways to fix it**. Refreshing for one exact unit, where hitting it wins and missing it loses, is "very uninteresting".
- **Galaxy's gap:** units end up with about equal Attack and Health, so the game never poses that problem. You get everything you need and are comfortable by the end game.
- **The owner's favourite game** shows what this allows: Blood Gems giving about +9 Attack and +1 Health built a high-Attack board early. Then the player sold the gem pieces and used Tavern-spell buffs that gave only Health to finish it. It was an atypical path that worked because strategies had distinct strengths and weaknesses and the engines let a creative player combine them (N-B §7.4).
- **Design implication (synthesis):** let effects lean, giving more Attack or more Health, or big single units versus wide boards, rather than always balanced stats. And make sure each lean has more than one fix in the pool.
- **Positioning should matter a bit** (N-B §8.1). It doesn't need to be the biggest part of the game, but it should feel relevant and be a tactical and strategic motif. That needs units that care about position, for example:
  - attacks that target only the back row;
  - a bonus when attacking a given position (extra effect, no damage taken);
  - "summon a copy of the unit to my left" effects, so that unit needn't survive, and cards that counter that;
  - attacks on the lowest-Health unit.

### P4. Engines should be bounded, and the bound should keep the design's goal
The owner likes **bounded value engines** and dislikes **unbounded** ones (N-B §4.1–4.2).

- **Liked:** mid-range Battlegrounds engines with strong but bounded economy, e.g. menagerie (mixed-type) comps: about 10 spells a turn, buffing the board by roughly +50/+50 to +100/+100, then you run out. Each turn you ask whether a unit is worth swapping. Mixing economy units that don't scale with units that hold stats well is interesting.
- **Why economy is worth having** (N-B §7.4): more decisions, more to do, and the feeling that the limits don't apply to you, as if you're breaking the game. Players love it. Unbounded engines destroy the game state, so the answer is bounds, not less economy.
- **Variety the owner wants**, in kinds of economy:
  - spells
  - random units of a type
  - gold
  - weighted refreshes, or better chances to Discover a type
  - delayed economy (nothing now, more in two turns)
  - random copies of units you already have
- **And variety in triggers:** taking certain actions, playing certain unit types, triggering certain effects.
- **Engines as early forks:** a source of recursive value picked up early can lead to several mid-game directions.
- **No fixed output number, but plenty of stat-giving actions late** (N-C §3). In the late mid game and the end game, a player should take a good number of stat-giving actions per turn, fed by economy effects that supply their scaling vector. The menagerie example is Nalaa the Redeemer: "Whenever you cast a Tavern spell, give a friendly minion of each type +4/+3." You choose units of different types, some that make Tavern spells and some that hold stats, then cast as many spells as you can.
- **Watch for runaway inflection points** (N-C §4). In Battlegrounds, once a player's economy took off it kept accelerating: economy bought more economy. Reaching that point two turns early through good luck could leave others unable to catch up. The owner is unsure how they feel about it. Bramble has a built-in brake in escalating refresh costs, and Created units selling for 0, but the owner wants to try more builds before deciding. Data on stats gained per turn (Firestone used to show it for replays) would help, if it's public.
- **Disliked:** Infinite Pirates (§2.1). The cards were cool; the missing limit was the problem.
- **The right limit preserves the design's goal** (N-B §4.2). Rogers' goal was a comp of many small actions with small benefits, as against comps of few, large actions or combat scaling. A limit that merely makes the loop finite isn't enough if it still runs for hundreds of shops. Evidence: §2.1, the "B-ref" rows.
- **Surplus shouldn't let one tribe play every tribe best.** Infinite gold let Pirate players take other tribes' payoffs (Fire-forged Evoker for Dragons, and Silky Shimmermoth for Beasts. Shimmermoth's Beetle buff then triggered "whenever it gained stats", and the owner calls it the card that made the Rogers comp broken. Blizzard changed it to "whenever this takes damage", then removed it; N-B §8.6) and be the best version of those tribes. It cannibalised other designs and made one strategy the only one (N-B §4.2).
- **Tempo of play matters too.** A loop that needs an action every quarter-second is complexity without depth.

### P5. Flexible pieces that lean towards sub-strategies
The owner likes tribes whose units all work together but are each **significantly better in one or two sub-strategies**. Pieces you bought for tempo then keep later directions open (N-B §4.3–4.4).

- **Undead:** Eternal Knight ("Has +4/+2 for each friendly Eternal Knight that died this game") wants Reborn. Reborn also serves Avenge and token-summoning Undead. Early Knights plus Reborn sources leave several ways to go.
- **Quilboar:** one resource, Blood Gems, played three ways. (a) Buff the shop with Blood Gem Barrage, then move the gems onto your board with Gem Confiscation, or eat a shop unit with Felboar. (b) Choose One cards with Turbo Hogrider ("After you play a Choose One card, this plays 2 Blood Gems on all your Quilboar"). (c) Gems from hand cast extra times with Geomagus Roogug and Hot-Air Surveyor.
- **Murlocs** (recent Battlegrounds): one sub-strategy buffs units in hand, another buffs by the number of keywords on board. Some units serve both, some only one. Early overlapping pieces let you play for either (N-B §7.6).
- **Three-factor scaling.** Quilboar could grow sources, triggers *and* buff size, so they swung between amazing and terrible. The owner says Blizzard has since given most tribes all three (N-B §7.7; arithmetic in §2.3).
- **How many sub-strategies:** whatever fits. More than three working at once is hard, but some things naturally work together (N-B §8.2).
- **Third scaling factor (C): try it, and watch it closely** (N-B §8.3, N-C §2). The owner is torn but willing to pursue Cs for now.
  - **Why the owner distrusts C:** it magnifies small balance differences, so boards that are close on A and B produce one-sided fights over something that feels arbitrary. Once it's in the game, everything merges into the A-B-C mix.
  - **Why it stays:** players expect it, and it's fun. Galaxy's Fae was "obscenely" the best comp but really fun, and the owner's favourite card was Wink ("Buffs from Fae give an additional +1/+1 for the rest of the game"). Galaxy later spread C widely with Candy's shared sweetness counter.
  - **The danger is repeatable C, especially at a low base.** A one-off upgrade from 3/3 to 4/4 is "not a big deal". A C that takes a 1/1 to 3/3 and adds +2/+2 every turn makes 7/7s from 1/1s in three turns, and "your power budgeting's out the window".
  - **Lean on A and B first:** how many times per turn you can apply buffs, and how good the buffs are. How fast you can improve the buffs comes second.
- **Galaxy** gets flexibility through generically useful units. The cost is some sameness and less asymmetry than TFT or Battlegrounds (N-A §3.3).

### P6. Damage should reflect the player's goals
Damage should measure how well you did against your opponent, without big swings or arbitrary-feeling numbers (N-A §4).

- **Battlegrounds' formula** (winner's tavern tier + the tiers of its surviving units) measures game length through proxies and punishes surviving high-tier units, not how close the fight was. Every cap Blizzard added treated the symptom (N-A §4.1–4.2).
- **Preferred (TFT, as the owner last knew it):** count surviving units, ignoring tier, plus a number that grows with game length. Measure game length directly, not through proxies (N-A §4.4).
- **Danger:** combat summons inflate the count. Recurring Nightmare (tier 7 Undead) could leave 7 copies alive, worth 49 damage from units alone under Battlegrounds' formula (N-A §4.5).
- **To try in Bramble:** surviving *starting* units + a number that grows with time. Performance should be a **significant share, but not the majority**; most damage could be a flat amount per loss. The split and starting health are open (N-A §4.6–4.7).
- **Fallbacks:** tavern-tier modifiers, or summed Health or Attack. Rejected for now as hard to read on the fly.

### P7. Numbers big enough to tune
With +1/+1 stats, the smallest change is about 50% of a stat. That's why golden and silver versions double, and why Galaxy and early Battlegrounds can't be fine-tuned. TFT, in the hundreds, steps 300 → 450 → 650 (N-A §2). The owner's guess is **about double Battlegrounds**. Not every number needs doubling, but upgradeable effects need room so an improvement isn't a literal doubling (N-B §3, §7.2). Evidence and the two Battlegrounds examples, Felfire Conjurer and Blood Gems: §2.3.

### P8. Systems belong to their paradigm
Each game's systems work because of the rest of that game. Galaxy's 1-of-3 shop needs generically useful units. Battlegrounds can't have a "platinum" above golden because doubling compounds and the pool is too small. Galaxy's free silvers fit a game with no currency (N-A §5–6). Before borrowing a system, say what in its home game makes it work. The owner's open question: build Bramble's own paradigm, or be a subfamily of an existing one (N-A §1)?

### P9. Shop size is a feel question; experiment
5 is the current lean, anywhere from 3 to 7 is plausible, and 8 is too many. Visual layout matters. Try several sizes, including ones that don't seem right yet (N-A §5.2). Related ideas: buying extra shop slots as an upgrade of their own, and never bundling two upgrades a strategy may want separately, as TFT bundles board space with shop odds (N-A §5.3, §5.7).

---

## 2. Worked evidence

### 2.1 Infinite Pirates: why it was infinite, and what Bramble's rules do to it

**Cards** (library text): golden Sky Admiral Rogers, "After you spend 9 Gold, get two random Bounties". Golden Proud Privateer, "Your Bounties cast three times". The five Bounties are equally likely (a judgement). Wealthy: "Gain 2 Gold". Friendly: "Get a random minion of your most common type". The other three give only stats. Bounties from Rogers are free to cast.

**The equation.** Let r be the gold returned per gold spent. With two golden Rogers and a golden Privateer, every 9 gold spent gives 4 Bounties × 3 casts = 12 casts. Each cast returns (2 + s_F)/5 gold, where s_F is what Friendly's unit sells for:

    r = 12 × (2 + s_F) / 5 / 9
    Battlegrounds, s_F = 1:  r = 0.80     (owner's estimate s_F ≈ 4/3: r ≈ 0.89)
    Bramble, Created sells 0: r = 0.53

A refresh at price p nets −p(1 − r). Buying a 3-gold unit and selling it for s nets 3r − 3 + s. A turn is **unbounded** when one shop gives back at least what it costs:

    −p(1 − r) + Σ over profitable buys of (3r − 3 + s)  ≥  0

- Ordinary units (s = 1) are worth buying once r > 2/3. Freedealing Gambler ("This minion sells for 3 Gold") is worth buying at any r.
- At r = 0.80 and a 1-gold refresh, buying all 6 units nets −0.20 + 6 × 0.40 = **+2.20 a shop**, so the loop never ends.
- This is the owner's point (N-B §4.2 follow-up): Rogers counts gold spent on buys, and buys refund part of their cost, so spending gold to trigger Rogers was cheap.

**Model** ([tools/research/rogers_loop.py](../../tools/research/rogers_loop.py), `python -I tools/research/rogers_loop.py`). Median shops in one turn from a 10 / 30 / 60 gold bank. The player refreshes until broke and buys every unit whose buy is profitable:

| Board | Battlegrounds | Bramble's refresh prices, Battlegrounds sell values | Bramble |
|---|---|---|---|
| Golden Rogers + golden Privateer (r 0.40 / 0.40 / 0.27) | 16 / 53 / 109 | 15 / 27 / 37 | 13 / 25 / 34 |
| Two golden Rogers + golden Privateer (r 0.80 / 0.80 / 0.53) | **unbounded** | 134 / 141 / 150 | 18 / 30 / 41 |
| Same, owner's sell estimate (r 0.89 / 0.89 / 0.53) | **unbounded** | 370 / 374 / 381 | 18 / 30 / 41 |

What it shows:
- **Battlegrounds:** the owner's line is infinite on its own. It needs no extra partner card, because buying and selling ordinary units is the partner.
- **Bramble's escalating refresh price on its own** makes the loop finite, as the owner predicted, but only after 134–381 shops and thousands of gold spent. That's still action spam. Per P4, it doesn't preserve the design's goal.
- **Bramble's "Created sells for 0" rule** does most of the work. It lowers r below 2/3, so buying ordinary units stops paying, and the turn ends near the 20–30-shop target set for the strongest engines ([economy-bounding.md](economy-bounding.md)).
- Limits of the model: it ignores hand and board space, the timer and stats, and assumes a uniform Bounty pick. See the script's header.

**How Blizzard handled it** ([economy-engines.md §4.2, §6](../research/battlegrounds/economy-engines.md)): it raised Rogers to 10 gold, then removed Rogers, Privateer and the Bounties, then brought them back while removing Tethys. It never used a system-level limit. Freedealing Gambler left the pool on 21 July 2026, and the owner says Rogers is "in a better spot now".

### 2.2 Shop clutter: how much of a late Battlegrounds shop is noise

The owner's claim (N-B §5): almost every tier 1 unit is useless in the late game, yet tier 1 units litter every late shop.

**Arithmetic** from today's pool (library units in the current pool, solo only) and the copies per unit (rulebook 5.1.2: 15 / 15 / 13 / 11 / 9 / 7 / 5 for tiers 1–7). At tavern tier 6, a shop slot is drawn in proportion to copies:

| Unit tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Units in pool | 25 | 37 | 45 | 62 | 56 | 35 |
| Share of tier-6 shop slots | 12.7% | 18.8% | 19.9% | 23.2% | 17.1% | 8.3% |

So about **a third of the slots in a tier-6 shop are tier 1–2 units**, and half are tier 3 or lower, while tier 6 units fill 8%. (This uses the full pool; a 5-tribe lobby scales each tier similarly. Units already bought are ignored.)

**Galaxy, by contrast** ([galaxy/rules.md §2](../research/galaxy/rules.md)): 3 characters plus 1 spell per shop, no gold, no rerolls. The shop gains rarities on a clock (Common turn 1, up to Legendary turn 9). Lower rarities stay in the pool, but draws are "weighted towards the higher rarity" (exact weights unverified). Fewer options, but a larger share of them matter.

**Trade-off to remember** (N-A §5.4): weighting towards higher tiers, as TFT does, makes a specific low-tier unit hard to find late. Leaving it flat, as Battlegrounds does, fills late shops with noise.

### 2.3 Stat scale: why +1/+1 is hard to balance

The owner's two examples (N-B §7.2), as arithmetic.

**Scaled resources.** Let a resource (a Blood Gem, a Tavern spell) give base stats b, plus u from permanent upgrades. Played n times, it gives

    stats = n × (b + u)
    one more upgrade adds 1 / (b + u) to the total

- At b = 1, the first +1/+1 upgrade **doubles** every future gem. At b = 2 it adds 50%.
- **The owner's numbers.** Player A plays 50 gems with no upgrades; player B plays 10 gems with 4 upgrades.
  - b = 1: A gets 50 × 1 = **50**, B gets 10 × 5 = **50**. Equal, despite A playing five times as many.
  - b = 2: A gets 50 × 2 = **100**, B gets 10 × 6 = **60**.
- **Break-even.** B matches A once A plays (b + u)/b times as many gems. With 4 upgrades that's 5× at b = 1 and 3× at b = 2. A low base makes upgrade cards mandatory, because playing more copies can't keep up. That's the "absolutely mandatory" dependence the owner describes.

**Felfire Conjurer** ("At the end of your turn, your Tavern spells give an extra +1/+1 this game"). Tavern spells then gave about +1/+1 to +2/+2 to the whole board.
- One trigger adds 100% to a +1/+1 spell and 50% to a +2/+2 spell. Two or three triggers multiply that.
- The smallest nerf removes a whole stat (+1/+0 or +0/+1), and either version is useless. All-Attack boards die to sticky units, and all-Health boards (1/10s) lose to 3/3s and 4/4s. So the card had no middle setting.
- At double scale, with spells around +2/+2 to +4/+4, the card could give +2/+2 and be nerfed to +2/+1 (−25% of the buff) or +1/+1 (−50%) without dropping a stat.

**Scaling factors** (N-B §7.7). Most tribes scaled on two factors: total = sources × triggers × a fixed buff. Quilboar had a third, because the buff size (gem value) could also grow:

    two factors:   sources × triggers × 2         doubling both: × 4
    three factors: sources × triggers × gem value  doubling all three: × 8

That third factor is why Quilboar swung between "pretty amazing" and "kind of terrible". The owner says Blizzard has since given most tribes all three.

**The owner's conclusion:** about double Battlegrounds' numbers, not every number, but enough room to move on effects that could become problems (N-B §7.2).

### 2.4 Damage arithmetic

- **Battlegrounds:** winner's tavern tier + Σ tiers of its surviving units, capped at 5 on turns 1–3, 10 on turns 4–7, and 15 after that until 4 or fewer players remain (rulebook 10.1.1, 10.1.4).
- **Recurring Nightmare:** 7 surviving copies × tier 7 = 49, plus the tavern tier, once caps are off.
- **The owner's example** (N-A §4.2): a fight you win 80% of the time, where three-quarters of the 20% you lose still cost 15. It hasn't been measured. A fight-simulator run of damage distributions could test it once Bramble has one.

---

## 3. Questions still open for the owner

Answered (8 Nov): the Rogers maths and the right kind of limit (N-B §4.2); depth vs complexity (§5); tactical play to reach a solved comp (§7.1); stat scale (§7.2); menagerie (§7.3); why bounded engines (§7.4); weaknesses (§7.5); sub-strategies (§7.6, §8.2); Quilboar (§7.7); positioning (§8.1); the Beetle card (§8.4).

1. **Feel-bad moments, and judging designs.** No list or veto rule yet; to be learned in development (N-B §8.5). This connects to the owner's biggest open problem, below.
2. **Stats-per-turn data.** Is per-turn stat data from Firestone or similar trackers public? It would give a real curve for the inflection-point question (N-C §4). Not yet researched.

Settled on 8 Nov, after the list above was first written: the third scaling factor (try it, watch it closely; P5), the bounded-engine target (no fixed number; P4), and the rulebook changes (now in rulebook v0.5).

## 4. The open process problem: filtering agent designs

The owner's biggest problem with the project right now (N-B §8.5). Agents will produce many good and bad designs. If agents judge them, good ones may be buried in turns and documents the owner never reads. If agents don't, the owner can't review 200 options at the pace agents work. No answer has been chosen yet.

Constraints the owner set on any answer (N-B §8.7):
- **Mental effort is the scarce resource, not time** (corrected by the owner, N-B §8.8). Working through problems one at a time by dictation is enjoyable. Facing a long list of items at once is draining, especially alongside other projects. But items must not be lost when they aren't shown.
- **What gets measured gets made.** If designers can see a scoring system, or guess at it, they'll design for the score.
- **Reactions aren't final.** The owner's view changes with new information, with play, and when the context around a design changes, for example when a card it interacted with is removed. The owner has often found that something they thought was bad turned out good.

**Deferred to the end (owner, N-B §7):** where this document lives, and whether to split it into levels of detail for different agents.
