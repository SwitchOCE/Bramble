# Battlegrounds economy engines and infinites

**Status: research for the design pass, 2 November 2026 (task R3).** This catalogues the Battlegrounds engines that ran very long or without end in one turn. For each it says what the loop spends, what stops it, how Blizzard answered it, and how it would behave in Bramble. Bramble has no turn timer, and only the paid Refresh gets dearer within a turn (rulebook 3.1.2, 4.4). It ends with the loop shapes Bramble's content design must police. The guardrails it first proposed (G2–G10) and its rule gaps now live in one list, [economy-bounding.md](../../design/economy-bounding.md) §7 (owner, 2 Nov: "One list in bounding").

The owner's problem statement is [owner-notes/2026-11-02-pre-development-design-pass.md](../../design/owner-notes/2026-11-02-pre-development-design-pass.md):

> In our game, I want it to go for a very, very long time, but not infinitely.

The owner's answers fix the frame: no turn timer; only refreshes escalate; gold-spent engines such as Tethys and Rogers are bounded by content design; the best engines should see "about 20–30 shops" in a turn.

**Inputs**
- Card text, golden text and pool dates: [data/minions.json](data/minions.json), [spells.json](data/spells.json), [heroes.json](data/heroes.json), [trinkets.json](data/trinkets.json), [buddies.json](data/buddies.json), [anomalies.json](data/anomalies.json), [quests.json](data/quests.json), [timewarp.json](data/timewarp.json). Pool dates are the library's monthly samples, so they lag patch dates by up to a month.
- Stat and tier changes: [analysis/stat_changes.csv](analysis/stat_changes.csv).
- Text-change history: Hearthstone Wiki card pages and official patch notes, cited per card. [patch-history.md](patch-history.md) leaves out card balance changes, so it is used only for system changes.
- A small loop model (appendix). It was run once with `python -I`, standard library only, seed 7, 400 turns per cell. It is a throwaway script; the full code is in the appendix so anyone can re-run it.

**Words**
- **Shop:** one look at a refilled shop. Each paid or free refresh gives one shop.
- **r:** gold that comes back, on average, for each gold spent in the same turn.
- **h:** how many matching units a shop shows, on average.
- **Net per buy:** gold gained or lost by buying one matching unit and selling it, in the same turn.
- **Bank (G):** gold the player starts the engine turn with. Bramble keeps unspent gold (4.1.2) and has no cap (4.1.3), so G can be large.

Claims are marked **[data]** (library, model run or cited source) or **[judgement]**.

---

## 1. Findings

1. **Rising refresh cost cannot stop a loop that pays back a gold or more per gold spent.** [data: arithmetic] Rogers, Tethys and every "after you spend N gold" card pay back per gold, not per refresh. If r ≥ 1, the player refreshes at 3 gold forever and gets all 3 back. If r < 1, the turn ends after G / (1 − r) gold whatever the refresh price; escalation only cuts how many shops that gold buys. So for spend-triggered engines, the bound is entirely the content's r. Raising the top price to 5, or letting it climb without a cap, changes nothing here.
2. **Escalation does work against refund loops that need fresh shops.** [data: model, section 5] Cap'n Hoggarr's golden+plain pair (+1 gold per Pirate bought) is infinite in Battlegrounds at 1-gold refreshes. Under Bramble's 1/2/3 it stops after about 20–48 shops. The rule is simple: a loop that needs refreshes to find targets is bounded when h × (net per buy) is below the top refresh price. At tier 6 a tribe fills about 20% of the pool [data: minions.json, 5-tribe lobbies], so h ≈ 1.2, and at a top price of 3 the net per buy must stay under about 2.5. Any effect that fills the shop with one tribe (h up to 6) breaks this: the same Hoggarr pair is then unbounded at 1/2/3 and at a cap of 5.
3. **Free refreshes sit outside escalation, so only content bounds them.** [data: rulebook 4.4.5, 4.4.6] They cost nothing and don't count. Retriggers multiply "gain N free refreshes": golden Brann turns Refreshing Anomaly's 2 into 6. In today's pool the sources are rare single cards, so the loop runs out (median 30 shops from a 30-gold bank, 90th percentile 50) [data: model]. It becomes unbounded only when free shops per shop reach 1. That happens if a source is common, cheap, or triggered by refreshing itself.
4. **Bramble's "Created sells for 0" rule (4.3.3) already removes the biggest Battlegrounds leak.** [data: model] Tethys's random Pirates and Friendly Bounty's minions sell for 1 in Battlegrounds and 0 in Bramble. That one rule moves two golden Rogers + golden Privateer + the Hoggarr hero from unbounded (Battlegrounds sell values, even at 3-gold refreshes) to 59 shops from a 30-gold bank. Any card text that raises a Created unit's sell value reopens the leak.
5. **The 20–30 shop target is reached by banked gold alone.** [data: arithmetic on 4.4.3] With no engine, 30 gold buys 20 shops and 60 gold buys 30. A player who banks two turns of income gets a "very long turn" with no economy card at all. An engine's length therefore depends as much on the bank as on the cards. The target needs to say whether it counts the bank (question 2).
6. **Blizzard answered loops card by card, never with a system.** [data: wiki and patch notes, section 6] It used four tools: raising spend thresholds (Tethys 8 → 9 → 10, Rogers 9 → 10, then back to 9 when Healthy and Hostile Bounty were buffed), per-turn caps written on cards ("Once per turn", "3 times per turn"), removing cards (Hoggarr in 26.2), and never pooling the two big spend engines together (Tethys and Rogers swapped in and out at 34.2 and 35.2). The only system-level loop limits were in combat (30-loop cap, 30.0.2). Galaxy, also async, ended up with a hard 30-shop cap after loops appeared ([galaxy/design-notes.md](../galaxy/design-notes.md) §3).

---

## 2. The Bramble rules that matter here

| Rule | What it says | Effect on loops |
|---|---|---|
| 3.1.2, 2.1.4 | No turn timer; async fights against snapshots | Nothing outside the economy ends a turn. |
| 4.1.2, 4.1.3 | Unspent gold carries over; no cap | The engine turn can start with a large bank. |
| 4.3.3 | Bought sells for 1, Created for 0 | Generated units can't be sold for gold. |
| 4.4.3 | Refreshes 1–10 cost 1, 11–20 cost 2, 21+ cost 3 | Bounds loops that pay per refresh or need refreshes to find targets. |
| 4.4.5, 4.4.6 | Free refreshes and effect refreshes cost 0 and don't count | Free-refresh loops are untouched by escalation. |
| 7.3.5 | Golden doubles every number, thresholds unchanged | Golden retriggers and golden "cast twice" may become ×4, not ×3 (question 4). |
| 9.10.2 | One player action stops after 1,000 triggers | Catches a loop inside one click. Does not catch loops the player drives click by click (refresh, buy, sell). |
| 11.4.5 | Activate: once per turn | Activate engines (Kelp Keeper) are bounded per turn. |

### Shops per gold under refresh schedules [data: arithmetic]

| Schedule | G = 10 | 20 | 30 | 40 | 60 | 100 | Gold for 20 shops | Gold for 30 shops |
|---|---|---|---|---|---|---|---|---|
| **1/2/3 at 10/20 (current)** | **10** | **15** | **20** | **23** | **30** | **43** | **30** | **60** |
| 1/2/3/4/5, +1 every 10 | 10 | 15 | 20 | 23 | 30 | 40 | 30 | 60 |
| 1/2/3 at 5/10 | 7 | 11 | 15 | 18 | 25 | 38 | 45 | 75 |
| 1/2/3/5 at 5/10/15 | 7 | 11 | 15 | 17 | 21 | 29 | 55 | 105 |
| +1 every 5, no cap | 7 | 11 | 15 | 17 | 22 | 29 | 50 | 105 |

- Raising the cap to 5 changes nothing below 30 shops, because the first 30 refreshes cost the same. It only bites in turns already past the target.
- Moving the first step earlier (5 instead of 10) is what makes 20–30 shops cost a real engine.

---

## 3. Three loop shapes and what bounds them

Every engine in section 4 is one of these, or a mix. [judgement: the classification; the arithmetic is data]

**A. Spend-return loops.** Payback scales with gold spent: "After you spend 9 Gold, get a random Bounty", where a Bounty may be gold. Total gold spent in the turn is G / (1 − r).
- r < 1: bounded by gold. The refresh price sets how many shops that gold buys, nothing more.
- r ≥ 1: unbounded at any refresh price, capped or not.
- Escalation makes these engines *stronger* per shop: a 3-gold refresh ticks a "spend 9" counter three times as fast as a 1-gold one.

**B. Refund-per-target loops.** Payback per unit bought or sold: "After you buy a Pirate, gain 1 Gold". Each refresh costs p and shows h targets, each worth the net per buy.
- h × net < p at the top price: bounded by gold. Escalation does the work.
- h × net ≥ p at the top price: unbounded.
- If the target is one named card, the loop is bounded by the pool: one tier-2 card fills about 0.9% of a tier-6 pool, so it shows up about once per 19 shops [data: minions.json, copy weights per rulebook 6.1.3]. Sold Bought copies return to the pool (5.3.4), so the copy count never runs out; the low hit rate is what bounds it.

**C. Free-refresh branching.** Free refreshes that find more sources of free refreshes. If each shop yields b more free shops on average:
- b < 1: each paid shop grows into about 1 / (1 − b) shops. Bounded by gold spent on the sources.
- b ≥ 1: unbounded, and escalation is no help because none of these shops are paid.
- Retriggers (Brann, "cast twice") multiply b directly.

A fourth kind is **not a loop**: start-of-turn gold and "maximum gold" ramps. They act once per turn. In Bramble they matter because, with carry-over and no cap, they set G for the big turn.

---

## 4. Catalogue

"Class" uses the task's three classes: **bounded by gold**, **bounded by pool/board/hand**, or **unbounded without a timer**. In Battlegrounds every loop is also stopped by the 60–120 s turn timer ([rules.md](rules.md) §3); "unbounded without a timer" means the timer is the only thing that stops it.

### 4.1 Fleet Admiral Tethys (Pirate, tier 6) — shape A

- **Text** [data: minions.json]: "After you spend 10 Gold, get a random Pirate. (10 Gold left!)" Golden: "After you spend 10 Gold, get two random Pirates."
- **Loop:** gold spent on anything (refreshes, buys, upgrades) makes Pirates. Pirates sell for 1, so in Battlegrounds r = 0.1 (plain) or 0.2 (golden). The value is cards, not gold.
- **Resource and bound in Battlegrounds:** gold; the hand (10); the timer. Golden Tethys alone is not infinite by its own text. It runs long when other cards return gold per Pirate or per gold spent. [judgement: the library has no record of which lines the owner saw go infinite; question 1.]
- **Blizzard's answers** [data: [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Fleet_Admiral_Tethys), [26.4.3 notes](https://hearthstone.blizzard.com/en-us/news/23968055/26-4-3-patch-notes)]:
  - Added in 26.2 (9 May 2023) as "After you spend 8 Gold, get another random Pirate". The same patch removed the Cap'n Hoggarr minion (4.3).
  - 26.4.3 (15 Jun 2023): 8 → 9 gold. No reason given.
  - 31.2 (3 Dec 2024): removed from the pool.
  - 34.2 (2 Dec 2025): returned as "Whenever you spend 9 Gold".
  - 34.6 (9 Feb 2026): 9 → 10 gold.
  - 35.2 (14 Apr 2026): removed again.
  - The wiki gives the golden text as "Whenever you spend 9 Gold, get 2 random Pirates"; the library's latest build says 10. The library is used here.
- **In Bramble:** the Pirates are Created and sell for 0 (4.3.3), so r = 0 unless a Pirate itself makes gold. The model gives 22 shops from a 30-gold bank, the same as no engine [data: model]. Golden doubles the Pirates but keeps the 10-gold threshold (7.3.5).
- **Class:** Battlegrounds: bounded by gold and hand, long only with partners. Bramble: **bounded by gold**, with r set by whatever gold the generated Pirates make.

### 4.2 Sky Admiral Rogers + Proud Privateer + Bounties (Pirates) — shape A

- **Text** [data: minions.json, spells.json]:
  - Sky Admiral Rogers (tier 6, 4/5): "After you spend 9 Gold, get a random Bounty. (9 Gold left!)" Golden: "get two random Bounties."
  - Proud Privateer (tier 5, 8/8): "Your Bounties cast twice." Golden: "Your Bounties cast three times."
  - The five Bounties (tier 3, 2 gold in the shop): Friendly, "Get a random minion of your most common type."; Healthy, "Give four friendly minions +4 Health."; Hostile, "Give four friendly minions +4 Attack."; Selfish, "Give your left-most minion +6/+6."; Wealthy, "Gain 2 Gold."
  - Other Bounty sources: Bigwig Bandit (Rally), Shipwrecked Rascal (Battlecry and Deathrattle), Lost City Looter (end of turn), the Privateer Portrait and Sunken Anchor trinkets (2 Bounties each turn).
- **Loop:** spending gold makes Bounties; Wealthy Bounty and the sale of Friendly Bounty's minion return gold; Privateer multiplies both. With a uniform pick among the five [judgement: the pick weights are not documented], one Bounty cast once returns 0.4 gold from Wealthy plus 0.2 from selling Friendly's minion in Battlegrounds.

| Board | r, Battlegrounds sell values | r, Bramble (Created sells 0) |
|---|---|---|
| Rogers + Privateer | 0.13 | 0.09 |
| Golden Rogers + golden Privateer | 0.40 | 0.27 |
| Two golden Rogers + golden Privateer | 0.80 | 0.53 |

  [data: arithmetic from card text.] A third golden Rogers would pass r = 1 in Battlegrounds, but the pool holds 7 copies of a tier-6 unit (rulebook 5.1.2), so it can only come from Friendly Bounty or other generated copies. Whether two Privateers stack is not documented (UNVERIFIED).
- **Resource and bound in Battlegrounds:** gold. Unbounded once r ≥ 1, which needs a gold refund per Pirate bought on top (see the Hoggarr hero row in section 5) or more Rogers copies.
- **Blizzard's answers** [data: [Rogers wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Sky_Admiral_Rogers), [Privateer wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Proud_Privateer), [33.6.2 notes](https://hearthstone.blizzard.com/news/24240524), [35.4.2 notes via wiki](https://hearthstone.wiki.gg/wiki/Patch_35.4.2.242566)]:
  - Added in 33.2 (5 Aug 2025) with Privateer and the Bounties, as "Whenever you spend 9 Gold". 33.2.2 changed "Whenever" to "After" and fixed when the Bounties enter the hand.
  - 33.6.2 (9 Oct 2025): 9 → 10 gold, Health 5 → 6. No reason given.
  - 34.2: Rogers, Privateer and the Bounties removed. Tethys came back in the same patch.
  - 35.2 (14 Apr 2026): all back. Tethys removed in the same patch.
  - 35.4.2 (19 May 2026): back to 9 gold, Health 6 → 5. Healthy and Hostile Bounty went from three minions to four. Dev comment: "Most of these changes target Pirates and Mechs."
  - Pool dates confirm the swap: Tethys 2023-05 to 2024-11 and 2025-12 to 2026-03; Rogers 2025-08 to 2025-11 and 2026-04 to now. The two were never in the pool together [data: minions.json pool_periods].
- **In Bramble:** the best legal pair of goldens gives r = 0.53, so a 30-gold bank becomes 30 shops and a 60-gold bank 51 [data: model]. It stays bounded only because Friendly Bounty's minion sells for 0 and nothing refunds gold per Pirate bought.
- **Class:** Battlegrounds: bounded by gold, one partner away from unbounded. Bramble: **bounded by gold**.
- **Correction (8 Nov 2026).** The class above misses a partner that is always there: buying ordinary units. Rogers counts gold spent on buys, so a 3-gold buy returns 3r and sells back for 1. Once r > 2/3, every buy is profitable. At r = 0.80, buying all 6 units in a shop nets +2.20 at a 1-gold refresh, so **two golden Rogers + golden Privateer is unbounded in Battlegrounds on its own**, as the owner reported (owner-notes/2026-11-08b §4.2). In Bramble, Created-sells-0 keeps r at 0.53, below 2/3, so the class "bounded by gold" stands. Model: [tools/research/rogers_loop.py](../../../tools/research/rogers_loop.py); summary in [owner-taste.md §2.1](../../design/owner-taste.md).

### 4.3 Cap'n Hoggarr (Pirate minion 2020–2023, hero since 2023) — shape B

- **Text** [data: minions.json, heroes.json]: minion (tier 5): "Whenever you buy a Pirate, gain 1 Gold." Golden: "gain 2 Gold." Hero power: "After you buy a Pirate, gain 1 Gold."
- **Loop:** golden + plain Hoggarr give 3 gold per Pirate bought. A Pirate costs 3 and sells for 1, so each Pirate nets +1 and goes back to the pool to be found again. At 1-gold refreshes, about 1.2 Pirates per shop [data: pool share] makes each refresh net +0.18. A players' guide describes this pair as "infinite" gold in a turn ([Icy Veins Patches guide](https://icy-veins.com/hearthstone/patches-the-pirate-battlegrounds-guide); the page returned 403, so this rests on a search summary of it).
- **Resource and bound in Battlegrounds:** none but the timer and the hand. **Unbounded without a timer.** [data: model: ≥ 2,000 shops at every bank size]
- **Blizzard's answers** [data: [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Cap%27n_Hoggarr)]: added 17.4 (Jun 2020) with "gain 1 Gold this turn only"; 24.6 (Nov 2022) dropped "this turn only"; removed in 26.2 (May 2023), the patch that added Tethys. It returned as a hero (library: from June 2023) at 1 gold per Pirate. The wiki lists a 29.2 change to the minion (tier 5 → 6, no longer Pirate-lobby-only), but the library shows it out of the pool after April 2023.
- **In Bramble:** profitable only while refreshes cost 1. At 2 gold each refresh loses 0.8. The model gives 20 shops from a 10-gold bank and 32 from 30 [data: model]. If one effect made every shop Pirates only (h = 6), the loop nets +3 per refresh at price 3 and is unbounded under 1/2/3 and under a cap of 5 [data: model].
- **Class:** Battlegrounds: **unbounded without a timer**. Bramble: **bounded by gold**, through escalation, as long as nothing concentrates the shop.

### 4.4 Sell-value loops: Freedealing Gambler, Tortollan Blue Shell — shape B

- **Text** [data: minions.json]: Freedealing Gambler (tier 2): "This minion sells for 3 Gold." Golden: 6. Tortollan Blue Shell (tier 4): "If you lost your last combat, this minion sells for 5 Gold." Golden: 10. Also Corpse Refiner and Corpse Recycler: "Avenge (4): This minion sells for 1 more Gold."
- **Loop:** Gambler is gold-neutral (buy 3, sell 3), so any per-buy refund (Hoggarr: +1 to +3) makes it profitable, and the sold copy returns to the pool.
- **Bound in Battlegrounds:** the pool. One named tier-2 card shows about once per 19 shops at tier 6 [data: pool share]. Blue Shell is a one-off: a golden Blue Shell sold once gives 10.
- **Blizzard's answers:** Gambler stayed in the pool 2020–2026 with gaps (removed 2026-07) [data: pool_periods]. No text nerfs found.
- **In Bramble:** a Bought Gambler still sells for 3 (4.3.8: card text wins). With a per-buy refund it nets +1 to +3 per find, and finding it costs about 19 refreshes, so escalation ends it. [judgement]
- **Class:** **bounded by pool** in both games.

### 4.5 Spend-counter scalers — shape A, paid in stats

- **Text** [data: minions.json, trinkets.json, heroes.json]: Gunpowder Courier "Whenever you spend 5 Gold, give your Pirates +3/+1"; Dual-Wield Corsair "Whenever you spend 5 Gold, give two friendly Pirates +4/+5"; Darkgaze Elder "Whenever you spend 8 Gold, this plays two Blood Gems on all your Quilboar"; Captain Flat Tusk "After you spend 4 Gold, get a Blood Gem"; Air Revenant "After you spend 7 Gold, cast Easterly Winds"; Enterprising Escapee "After you spend 6 Gold, get a Lockbox"; trinkets Fancy Spellbook (7), Shark Cannon (7), Extravagant Scale (20, twice per game), Quartermaster's Hook (50); heroes Thorim (60 gold for a tier-7 minion) and Queen Wagtoggle (10).
- **Loop:** none on their own; r = 0. They turn every gold spent into stats or cards.
- **Blizzard's answers:** threshold and tier changes, e.g. Gunpowder Courier moved between tiers 3 and 4 five times and changed text six times, 2023–2026 [data: stat_changes.csv]; Darkgaze Elder tier 6 → 5 (May 2025).
- **In Bramble:** escalation makes late refreshes worth more to them, not less. At 3 gold a refresh, Gunpowder Courier fires every 1.7 refreshes. This cuts against [power-budget-review.md](../../design/power-budget-review.md) §6.1, which values late gold at 0.2–0.6 SP because it "only buys refreshes". With a spend scaler on board, late gold buys stats at a fixed rate. [data: arithmetic; judgement on the budget consequence]
- **Class:** **bounded by gold** (r = 0). Dangerous only as the payoff half of a shape-A or B loop.

### 4.6 Refreshing Anomaly + Brann + Battlecry retriggers — shape C

- **Text** [data: minions.json, spells.json, heroes.json]:
  - Refreshing Anomaly (Elemental, tier 4): "Battlecry: Gain 2 free Refreshes." Golden: 4.
  - Sly Infiltrator (Quilboar, tier 3): "Choose One - Gain 2 free Refreshes; or Get 3 Blood Gems."
  - Brann Bronzebeard (tier 5): "Your Battlecries trigger twice." Golden: "three times."
  - Retriggers in the pool now or before: Kelp Keeper "Activate (1): Trigger a friendly minion's Battlecry"; Young Murk-Eye "At the end of your turn, trigger the Battlecries of adjacent minions"; Shudderwock hero "Trigger a friendly minion's Battlecry"; Rylak Metalhead; Disco Shuffler; Dreamer's Embrace; Brann's Blessing; Moira Bronzebeard (tier 7); the Echoes of Argus anomaly; Timewarped Deios.
- **Loop:** each Anomaly bought for 3 (sold back for 1) gives 6 free shops with golden Brann. Free shops may show more Anomalies or Infiltrators. This is the case the owner named in [owner-notes/2026-10-27f](../../design/owner-notes/2026-10-27f-power-budget-decisions.md) and the reason for guardrail G1.
- **Bound in Battlegrounds:** gold (2 net per source) and the pool: the two sources fill about 1.4% of a tier-6 pool in a lobby with both tribes, so b ≈ 0.5 [data: pool share × 6 free shops]. Not infinite on today's numbers.
- **Blizzard's answers** [data: [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Refreshing_Anomaly)]:
  - Added 18.4 (Sep 2020) at tier 1 as "Battlecry: Your next Refresh costs (0)." The wiki notes that duplicating this Battlecry gave no extra free refresh. Setting a state ("next refresh costs 0") is immune to retriggers; adding a count is not.
  - 31.2 (Dec 2024): tier 1 → 3, "Gain 2 Refreshes that cost (0)". From here Brann multiplies it.
  - 32.2 (Apr 2025): tier 3 → 4, 4/5. Bug fix: its refresh, triggered by Rylak Metalhead, went to both Duos players.
  - 34.2 (Dec 2025): wording "Gain 2 free Refreshes."
- **In Bramble:** median 30 shops from a 30-gold bank, 90th percentile 50; from 60 gold, median 46, 90th percentile 72-78 [data: model]. Same as Battlegrounds in shape, because free shops ignore escalation. Golden Brann may count ×4 under 7.3.5, which makes b ≈ 0.7.
- **Class:** **bounded by gold and pool**, with a long tail. Unbounded if b reaches 1.

### 4.7 Other free-refresh sources — shape C

- **Text** [data: library]:
  - Leaf Through the Pages (spell, tier 2, cost 1): "Gain 2 free Refreshes."
  - Wyvern Outrider: "Whenever this takes damage, gain a free Refresh. (3 times per turn.)"
  - Malchezaar, Prince of Dance: "Two Refreshes each turn cost Health instead of Gold. (2 left!)"
  - Nozdormu hero: "At the start of your turn, gain a free Refresh."
  - Magnus Manastorm buddy: "Two Refreshes each turn are free."
  - Pigeon Lord buddy: "Your Refreshes are free while the Tavern doesn't have the minion type of your Hero Power."
  - Recycling Sticker trinket: "After you play an Elemental, gain a free Refresh." Recycling Wraith: "After you play an Elemental, your next Refresh costs (1) less." (pool 2021–2024)
  - Feisty Freshwater ("Deathrattle: You and your teammate each gain two free Refreshes"), Ghostly Ymirjar and Grim Freshener (Avenge), Herding Horn (Rally): earned in combat, so bounded by fights.
- **Loop:** Leaf with any "cast an extra time" effect (Temporal Tampering quest reward, Replica Cathedral, Sin'dorei Mirror) gives 4 free shops per gold. Its spell-slot share is 1.1% [data: spells.json], so it rarely chains. Recycling Sticker turns every Elemental played into a shop; with ~20% Elementals in the shop, that is about 1.2 Elementals per shop, each costing a net 2 gold.
- **Blizzard's answers:** per-turn caps written on the card (Outrider, Malchezaar, Magnus); Malchezaar moved between tiers 3 and 4 four times; its stats went 5/2 → 6/3 → 4/3 → 5/4 → 2/1 → 4/3 (2023–2026) [data: stat_changes.csv].
- **In Bramble:** the same, plus two rule gaps. Is a health-paid refresh a "paid" refresh for the thresholds? Is a refresh whose price was cut to 0 "free"? Section 8.
- **Class:** **bounded per turn** by written caps, or **bounded by gold** (Leaf, Recycling Sticker). Pigeon Lord is bounded by the pool: with a tribe at 20% of the pool, a 6-unit shop has no unit of that tribe 26% of the time, so about 1.35 free shops per hit [data: arithmetic].

### 4.8 Tavern Coin makers + Battlecry retriggers — shape B

- **Text** [data: minions.json, heroes.json]: Shell Collector (Naga, tier 2): "Battlecry: Get a Tavern Coin." Golden: 2 Coins. Tavern Coin: "Gain 1 Gold." Also Kael'thas hero (a Coin per 3 minions bought), Minted Corsair (Coin on sell), Briny Bootlegger and Greedy Snaketongue (combat).
- **Loop:** with golden Brann a plain Shell Collector gives 3 gold for 3, then sells for 1: net +1 per copy, refindable. Kelp Keeper (Activate (1), golden twice) adds one more trigger per turn.
- **Bound:** the pool (one named tier-2 card, about once per 19 shops) and Activate's once per turn. Chillmere Mosaic ("Spellcraft: Refresh the Tavern with Battlecry minions. They cost (1).") raises the hit rate and cuts the price for one shop a turn.
- **Blizzard's answers:** Shell Collector tier 1 → 2 and 2/1 → 4/3 (Apr 2024) [data: stat_changes.csv].
- **In Bramble:** the same, and the escalated refresh price makes the find cost higher. **Bounded by pool.**

### 4.9 Spell copies and "cast twice" — shapes A and C

- **Text** [data: library]: Storm Splitter "Once per turn, after you Pass a Tavern spell, get a new copy of it"; Zesty Shaker "Once per turn, when a Spellcraft spell is played on this, get a new copy of it"; Reliquary Attendant buddy "Once per turn…"; Timewarped Centurion "After you cast a Tavern spell, get an extra copy of it. (3 times per turn.)"; Timewarped Lava Lurker "(Twice per turn.)"; Cataclysmic Harbinger "At the end of your turn, get a copy of the last Tavern spell you cast"; The Celestial Archive buddy "Whenever you buy a Tavern spell that costs (0), get a copy of it"; Tae'thelan hero "Every third Tavern spell you buy costs (0)"; Hot-Air Surveyor "Blood Gems played from your hand cast an extra time"; Temporal Tampering "Your Tavern spells cast an extra time".
- **Loop:** a copy-on-cast with no cap, aimed at Tavern Coin or Wealthy Bounty, is an instant infinite (cast, copy, cast). Every copy-on-cast in the library carries a per-turn cap, an end-of-turn timing, or a buy-only trigger [data: texts above]. That is Blizzard's consistent answer.
- **In Bramble:** the same answer works. **Bounded per turn** by the written cap.

### 4.10 End-of-turn retriggers — not a loop

- **Text** [data: library]: Drakkari Enchanter "Your end of turn effects trigger twice"; Lucifron buddy; Ghastly Sticker; Primal Staff; Young Murk-Eye; Dreadbeard "At the end of your turn, deal 1 damage to your hero and get a Gold Coin".
- **Bound:** end of turn happens once. **Bounded per turn.** In Bramble the gold lands in next turn's bank (4.1.2).

### 4.11 Start-of-turn gold and maximum-gold ramps — not a loop

- **Text** [data: library]: Record Smuggler "At the start of your turn, gain 2 Gold. If you control at least three Pirates, gain 2 more" (golden 4 + 4); Thieving Rascal and Rascal Sticker "gain 1 Gold … Repeat for each friendly Golden minion"; Accord-o-Tron, Plunder Pal, Industrious Deckhand; "maximum Gold" effects: Strike Oil, Selfless Sightseer, Snare Trapper, Goblin Wallet, Bilgewater Mogul, Timewarped Tipper, Doubloon Grifter.
- **Blizzard's answers:** Record Smuggler got stats and a text change (Apr 2024), then left the pool (Nov 2024); Thieving Rascal tier 4 → 5 (Aug 2025) [data: stat_changes.csv, pool_periods].
- **In Bramble:** bounded per turn, but there is no gold cap and gold carries over, so these raise G for every later turn. Golden Record Smuggler alone banks 8 a turn. **Bounded by gold**, but they set how big the engine turn's bank is.

### 4.12 Health as currency — shape C, paid in Health

- **Text** [data: library]: Malchezaar (above); Hasty Excavation "Gain 1 Gold. This costs Health to buy instead of Gold"; Bounding Felstalker "Refresh the Tavern with an extra Tavern spell. It costs Health instead of Gold"; Demonic Tapestry; Wax Imprinter "Gain 2 Gold and take 2 damage. At the start of each turn, repeat this".
- **Bound:** hero Health and per-turn caps. **Bounded by Health.** In Bramble Health is the game clock; an uncapped "pay Health for gold" would end only at death. [judgement]

### 4.13 Shop concentrators — multiply shape B

- **Text** [data: library]: Lost Staff of Hamuul "Choose a minion. Refresh the Tavern with minions of its type"; Archdruid Hamuul; Overseer's Orb anomaly; Coast Guard "When you sell this, Refresh the Tavern with Pirates, then steal one"; Saloon's Finest "Refresh the Tavern with Tavern spells"; Time Twister Chromie hero; Ysera hero "an extra Dragon whenever it is Refreshed"; Innkeeper's Stein, Minion Bait trinkets.
- **Effect:** each raises h for one tribe. A per-buy refund that is safe at h ≈ 1.2 is not safe at h = 6 (finding 2).
- **In Bramble:** effect refreshes are free and uncounted (4.4.6), so a repeatable concentrator is a free shop of all-targets. **Bounded by** whatever limits the concentrator: one-off spells and once-a-turn hero powers are safe; a repeatable one is not.

### 4.14 Anomalies that change prices

- **Text** [data: anomalies.json]: Uncompensated Upset "Minions cost (1) but sell for (0)"; Golganneth's Tempest "Minions cost 2 Gold. You cannot Refresh the Tavern. It Refreshes itself after you buy a card"; Money Match; Light the Way.
- **Effect:** lobby-wide price changes shift every shape-B net at once: at 1-gold minions, golden Brann + Shell Collector nets +2 per copy. Modifiers need the same loop review as cards. [judgement] Bramble's modifier layer ([architecture-notes.md](../../design/architecture-notes.md)) should treat unit price, sell value and refresh price as reviewed parameters.

---

## 5. Model results

Median shops in one turn, 400 runs each (90th percentile where it differs by 3 or more). Tier 6 shop of 6 units and 1 spell. The player refreshes until broke and buys every target it can afford. "≥ 2000" means the run hit the cap: unbounded. [data: model, appendix; inputs marked judgement in the appendix]

| Engine | Bank | BG (flat 1) | **Bramble 1/2/3** | Cap 5 | +1 every 10, no cap |
|---|---|---|---|---|---|
| None | 10 / 30 / 60 | 10 / 30 / 60 | **10 / 20 / 30** | 10 / 20 / 30 | 10 / 20 / 30 |
| Golden Tethys (r = 0.2 BG; 0 Bramble) | 10 / 30 / 60 | 12 / 37 / 74 | **10 / 22 / 34** | 10 / 22 / 33 | 10 / 22 / 33 |
| Golden Rogers + golden Privateer, Bramble r = 0.27 | 10 / 30 / 60 | 13 / 40 / 81 | **11 / 23 / 36** | 11 / 23 / 35 | 11 / 23 / 35 |
| Two golden Rogers + golden Privateer, Bramble r = 0.53 | 10 / 30 / 60 | 20 / 63 / 127 | **14 / 30 / 51** | 14 / 30 / 44 | 14 / 30 / 44 |
| Same, BG sell values (r = 0.80) | 10 / 30 / 60 | 46 / 146 / 295 | **22 / 56 / 105** | 22 / 46 / 76 | 22 / 46 / 68 |
| Golden + plain Hoggarr, buying Pirates | 10 / 30 / 60 | ≥ 2000 | **20 / 32 / 48** | 20 / 31 / 41 | 20 / 31 / 41 |
| Same, every shop all Pirates (h = 6) | 10 / 30 / 60 | ≥ 2000 | **≥ 2000** | ≥ 2000 | 110 / 114 / 119 |
| Two golden Rogers + golden Privateer + Hoggarr hero, buying Pirates, Bramble | 10 / 30 / 60 | ≥ 2000 | **30 / 59 / 103** | 30 / 44 / 63 | 30 / 44 / 60 |
| Same, BG sell values | 10 / 30 / 60 | ≥ 2000 | **≥ 2000** | ≥ 2000 | 152 / 163 / 178 |
| Refreshing Anomaly / Sly Infiltrator + golden Brann | 10 / 30 / 60 | 14 / 42 / 84 | **14 / 30 (p90 50) / 46 (p90 72)** | 10 / 30 / 46 | 10 / 30 / 46 |
| Same + Leaf Through the Pages cast twice | 10 / 30 / 60 | 13 / 42 / 91 | **14 / 30 (p90 53) / 51 (p90 88)** | 13 / 30 / 55 | 10 / 30 / 51 |

What it shows:
- Under Bramble's rules nothing in today's Battlegrounds library, played alone or in the pairs above, is unbounded. [data]
- Two lines are one rule or one card away: the Rogers + Hoggarr line with Battlegrounds sell values, and any refund line with a repeatable shop concentrator. Both stay unbounded at a cap of 5. Only a price with no cap ends them, and then at 110–180 shops, far past the target. [data]
- With a 30-gold bank, the top Bramble lines land at 30–59 shops; with 60 gold, at 46–103. The target of 20–30 is met only if the bank is small. [data]

---

## 6. How Blizzard answered engines: the patterns

[data: sections 4.1–4.14 and [patch-history.md](patch-history.md); the grouping is judgement]

1. **Raise the spend threshold.** Tethys 8 → 9 → 10; Rogers 9 → 10. Reversible: Rogers went back to 9 when its partners were buffed.
2. **Write a per-turn cap on the card.** "Once per turn", "(3 times per turn)", "(2 left!)", "Your first spell each turn". Every copy-on-cast and every repeatable free-refresh source in the current library has one.
3. **Choose state over count.** Refreshing Anomaly's first text ("Your next Refresh costs (0)") could not be multiplied by Brann. Blizzard later changed it to a count and raised its tier twice instead.
4. **Remove the card, or rotate it against its partner.** Hoggarr left the pool in the patch that added Tethys. Tethys and Rogers were never in the pool together.
5. **Restrict by lobby.** Tethys and Rogers appear only in lobbies with Pirates (wiki); Beasts and Dragons were split for "an unwanted interaction" (30.2).
6. **System limits only in combat.** 30-loop caps (30.0.2) and stat-loop fixes (33.6.2). Recruit-phase economy loops were always left to the timer.

Galaxy has the same no-timer problem. It patched loops card by card, then added a hard shop cap (20, then 30 shops a turn) with a consolation reward ([galaxy/patch-history.md](../galaxy/patch-history.md), 30 Apr and 11 May 2026).

---

## 7. Guardrails

The guardrails this doc first proposed (G2–G10) are merged into the one list in [economy-bounding.md](../../design/economy-bounding.md) §7, with the limits its model measured. All of them are proposals awaiting the owner. Where this doc's numbers differ (r ≤ 0.6, h × net ≤ half the top price, b ≤ 0.5), economy-bounding's replace them.

## 8. Rule gaps

The rule gaps found here (what counts as a free refresh, how price modifiers combine with escalation, golden retriggers under 7.3.5, and 9.10.2 not catching player-driven loops) are proposed rulebook deltas 3 and 5–7 in [economy-bounding.md](../../design/economy-bounding.md) §7.

---

## 9. Questions for the owner

1. *Answered for Rogers (owner, 8 Nov): two golden Rogers + golden Privateer, spending gold by buying and selling units. See the correction in §4.2.* **Which Tethys and Rogers lines did you see go infinite?** By their own text, neither passes r = 1 without a partner. The likely partners are a gold refund per Pirate bought (the Hoggarr hero) or generated Pirates that sell for gold. Knowing the real line tells us which shape to guard hardest.
2. *Deferred (owner, 2 Nov): turn length and shop targets wait for later power budgeting; see economy-bounding.md.* **Does "20–30 shops" include what banked gold buys anyway?** With no engine, 30 banked gold already buys 20 shops and 60 buys 30. Options: count only the shops an engine adds; move the first price step earlier (1/2/3 at 5/10 makes 20 shops cost 45 gold); or limit how much a bank can feed one turn.
3. *Deferred (owner, 2 Nov): turn length and shop targets wait for later power budgeting; see economy-bounding.md.* **"Rising cost only" can't stop a loop that pays back a gold per gold.** Are you content for the guardrails (G2–G8) to be the only defence, or do you want a last-resort system backstop, such as Galaxy's shop cap with a consolation reward, set high enough (for example 60) that no fair engine meets it?
4. **Golden retriggers: three times or four?** economy-bounding.md §7, rulebook delta 6. It changes every retrigger loop by a third.
5. **Should spend-counter scalers get more from escalated refreshes?** At 3 gold a refresh, "after you spend 5 gold" fires every 1.7 refreshes, so late gold stays valuable for those decks. Is that a feature for the "lots of small actions" strategy flavour, or should spend counters count refreshes rather than gold?

---

## 10. Limits

- **No text history in the library.** The library keeps each card's latest text only. Older texts come from the wiki and patch notes; where they disagree (Tethys's golden text), the library is used.
- **No record of real infinite turns.** Neither the library nor the patch notes say which loops players actually ran. Section 4 identifies loops from card text and models them. Player reports were not researched, per the owner.
- **The model is simple.** It assumes a uniform Bounty pick, a fixed tribe share of 20%, unlimited hand and board space, instant selling, and a player who refreshes until broke. It ignores what the shops are worth. Pool depletion is ignored because sold Bought copies return.
- **Pool shares** are averages over 5-tribe lobbies from today's pool; Bramble's pool will differ.
- **Stacking of auras** (two Privateers, two Branns) is undocumented in Battlegrounds and assumed not to stack.
- **The Icy Veins claim** about Hoggarr rests on a search summary; the page returned 403.

---

## Appendix: the loop model

Run with `python -I loops.py` from any folder (standard library only). Inputs marked [judgement]: Bounty pick uniform; r values from card text with uniform picks; h = 1.18 Pirates per shop (20% of 6 slots, from minions.json); free-refresh source share 1.38% per unit slot (Refreshing Anomaly 11 copies + Sly Infiltrator 13 copies over about 1,743 copies in a lobby with both tribes); Leaf Through the Pages 1.11% of the spell slot (7 of 628 spell copies, spells.json); golden Brann gives 6 free refreshes per source, net cost 2; Leaf cast twice gives 4 per gold.

```python
import random
CAP = 2000  # shops in one turn; reaching it counts as unbounded
def price(rule, n):  # n = paid refreshes already made this turn
    return {'BG': 1, 'B123': 1 if n < 10 else 2 if n < 20 else 3,
            'B1-5': min(5, 1 + n // 10), 'Bstep': 1 + n // 10}[rule]
def turn(rule, G, e, rng):
    g, paid, free, shops = float(G), 0, 0, 0
    while shops < CAP:
        if free: free -= 1
        else:
            p = price(rule, paid)
            if g < p: break
            g += p * (e.get('r', 0) - 1); paid += 1
        shops += 1
        for _ in range(6):                       # 6 unit slots at tier 6
            if rng.random() < e.get('h', 0) / 6 and g >= 3: g += e['net_buy']
            if rng.random() < e.get('q', 0) and g >= 2: g -= 2; free += 6
        if rng.random() < e.get('q_spell', 0) and g >= 1: g -= 1; free += 4
    return shops
ENG = {
 'none': {},
 'golden Rogers+golden Privateer (Bramble)': {'r': 2.4/9},
 '2 golden Rogers+golden Privateer (Bramble)': {'r': 4.8/9},
 '2 golden Rogers+golden Privateer (BG sell rules)': {'r': 7.2/9},
 'golden Tethys (BG sell rules)': {'r': 0.2},
 'golden+plain Hoggarr buying Pirates': {'h': 1.18, 'net_buy': 1.0},
 'same, Pirate-only shops': {'h': 6, 'net_buy': 1.0},
 '2gR+gP+Hoggarr hero (Bramble)': {'r': 4.8/9, 'h': 1.18, 'net_buy': 3*4.8/9 - 1},
 '2gR+gP+Hoggarr hero (BG sell rules)': {'r': 7.2/9, 'h': 1.18, 'net_buy': 3*7.2/9 - 1},
 'Anomaly/Sly + golden Brann': {'q': 0.0138},
 'same + Leaf cast twice': {'q': 0.0138, 'q_spell': 0.0111},
}
rng = random.Random(7)
for name, e in ENG.items():
    for G in (10, 30, 60):
        cells = []
        for rule in ('BG', 'B123', 'B1-5', 'Bstep'):
            xs = sorted(turn(rule, G, e, rng) for _ in range(400))
            cells.append('%d (p90 %d)' % (xs[200], xs[360]))
        print(name, G, *cells)
```

Net per buy in the Hoggarr-hero rows is 3r (spend return on the 3-gold buy) + 1 (hero) + 1 (sell) − 3 (price) = 3r − 1. Results in section 5 come from a run that also included plain Rogers + Privateer (r = 0.8/9), which this listing drops for length; the random draws therefore differ slightly if re-run from this listing.
