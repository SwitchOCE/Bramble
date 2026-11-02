# Economy bounding with no turn timer

**Status: for the owner's review, 2 November 2026 (task S1, revision 2).** This answers how long one Recruit Phase can run when nothing but gold ends it. It compares refresh price schedules, checks whether engines reach the 20–30-shop target in normal play, sets content limits for free refreshes, effect refreshes and gold-back engines, and gives recommended answers to B5 and B6 from [power-budget-review.md](power-budget-review.md) (decision points 5 and 6); B5's answer has since moved to [power-budget.md](power-budget.md) 4.1. Section 7 is the one list of economy guardrails.

The owner's problem statement is [owner-notes/2026-11-02-pre-development-design-pass.md](owner-notes/2026-11-02-pre-development-design-pass.md):

> In our game, I want it to go for a very, very long time, but not infinitely.

Fixed points from that note: no turn timer; only the paid refresh escalates ("Refreshes only"); free refreshes and gold-spent engines are bounded by content design ([content-guardrails.md](content-guardrails.md) G1); the strongest engines see "about 20–30 shops" in a turn (deferred, see below); strong economy should exist across the game ("everybody has them"); tolerance is ±25% for economy and engine cards.

**Owner direction, later on 2 Nov ([owner-notes/2026-11-02c-bounding-fallback-and-stage-2.md](owner-notes/2026-11-02c-bounding-fallback-and-stage-2.md)):**

> I think as long as we have rising reroll costs and no way of achieving infinite free rerolls, all turns should eventually be bounded. That's our fallback. How long and how ambitious our economy effects go, we can determine later.

What that means for this doc:
- **The standing bound** is the rising paid refresh cost (rulebook 4.4) plus no repeatable source of free refreshes ([content-guardrails.md](content-guardrails.md) G1). On its own it leaves three loop types open: gold back of 1 or more per gold spent (r ≥ 1), refunds of 3 or more gold a shop, and effect refreshes such as Golganneth + Hoggarr + golden Rogers (sections 3 and 4). Closing them relies on the proposed G2, G3, G8 and G14.
- **Deferred to later power budgeting:** how long a turn may run, the "about 20–30 shops" target (and whether it is a ceiling or also a floor), the price tail past the 30th paid refresh, and the limits that rest on them. Recommendations below that depend on these are marked *Deferred*. The findings and numbers stand.
- **The 30-gold bank is high against normal play.** The owner: "30 gold is a lot for a starting amount of gold". Income is 3 on turn 1, rising by 1 a turn to 10 (rulebook 4.1.1), so a 30-gold bank needs saving across turns, which carry-over allows (4.1.2). The main model's tier-6 player spends 10–14 gold a turn and banks almost nothing. Read the 30- and 60-gold results as stress tests of banked turns.

This builds on [economy-engines.md](../research/battlegrounds/economy-engines.md) (task R3), which catalogued the Battlegrounds loops and first proposed guardrails G2–G10. Section 7 of this doc is now the one list of economy guardrails (owner, 2 Nov: "One list in bounding"). **This model supersedes R3's loop model.** R3 used expected gold per gold; this one draws each Bounty and each shop. R3's schedule "Bstep" (+1 every 10 refreshes from the first) is not this doc's `s123_plus1_nocap` (+1 every 5 from the 31st). Where the two differ (R3: two golden Rogers + golden Privateer + Hoggarr hero, 59 shops at a 30-gold bank; here 46, p90 103), use this one. Both say the line is finite under 1/2/3 and has a long tail.

- **Model:** `python -I tools/research/budget_model.py bound` (about 50 seconds on 8 worker processes, standard library only). Assumptions are in the `B` block, `BOUND_SCHEDULES` and `BOUND_PACKAGES`, in the style of the main `ASSUMPTIONS` block.
- **Designer's check:** `python -I tools/research/budget_model.py bound check r=0.3 b=0.1 hnet=0.5 a=4` runs one card's rates against Bramble now and the recommended schedule in under a second.
- **Tables:** [docs/research/budget-model/](../research/budget-model/), files `bound_*.csv`. Each number below names its CSV.

**Words**
- **Shop:** one look at a refilled shop. Each paid, free or effect refresh gives one. The shop the turn opens with is not counted.
- **Bank (G):** gold at the start of the long turn. **10–14 is a normal tier-6 turn:** the main model's player spends 10 (standard econ), 12 (econ heavy) or 14 (high roll) gold a turn at tier 6 and banks 0–1 [data: economy_timeline.csv]. 20 is one saved turn. 30 and 60 are banked turns (rulebook 4.1.2, no cap).
- **Paid / free / effect refresh:** the player's Refresh action (escalates, 4.4.2); a free refresh granted by an effect (4.4.5); a card that replaces the shop directly, "Refresh the Tavern" (4.4.6). Free and effect refreshes don't count toward the price steps.
- **r:** gold back per gold spent, from spend engines ("after you spend N gold…").
- **b:** free shops per shop.
- **hnet:** gold an engine's own buys make or lose per shop (refunds, coins, sell values, source costs).
- **Loop index Λ:** 1 − (net gold lost per shop) ÷ (refresh price). For b < 1 that is 1 − (1 − r)(1 − b) + hnet / price. Expected shops per gold is 1 / (price × (1 − Λ)). The turn is finite, in expectation, when Λ < 1. **Λ (length)** is taken at the price of the 30th paid refresh. That price is 3 under the recommended schedule and under Bramble now; it is 1 under bg_flat1, 4 under s123_plus1_from26 and 5 under s12345_5_20 and s123_plus2_from26 [data: bound_schedules.csv, price_at_target]. **Λ (top)** is taken at the top price and only answers "finite or not".
- **Player classes:** *no engine*; *average* (plain engine cards); *strong* (the strongest plausible board, under the board rule in section 7); *ceiling* (legal but breaks the board rule, e.g. six copies of a 7-copy card); *anomaly* (a lobby-wide modifier); *library* (another legal line from the card library or a past pool); *bramble* (a hypothetical Bramble card shape); *stress* (one rule or one card away).
- **Policies:** *power* buys every positive-value card, then refreshes with what is left (a player who wants stats). *loop* buys engine pieces only and puts all other gold into refreshes (the longest turn the package allows).

Claims are marked **[data]** (model run, card library or cited source) or **[judgement]**.

---

## The owner's schedule (decided 2 Nov)

The owner set the paid refresh price: 1 gold for refreshes 1–15 of a turn, then +1 gold every 5 (16–20 cost 2, 21–25 cost 3, and so on), with no cap ([owner note](owner-notes/2026-11-02d-refresh-schedule-and-free-refreshes.md); rulebook 4.4.2–4.4.3). It is `owner_15_plus1_5` in `budget_model.py bound`. It replaces the recommendation in section 4.1. The owner also expects to keep moving the target as turns are playtested.

Shops seen at tier 6, median (90th percentile), longest-turn policy, against the old 1/2/3 at 10/20 [data: bound_packages.csv]:

| Board | 12 gold (a normal turn) | 20 gold | 30 gold (a banked turn) |
|---|---|---|---|
| No engine | 11 → 12 | 15 → 17 | 20 → 21 |
| Strong Rogers | 11 (17) → 12 (16) | 18 (20) → 20 (22) | 24 (28) → 23 (28) |
| Strong golden Brann + Refreshing Anomaly | 16 (23) → 16 (24) | 20 (40) → 27 (40) | 30 (57) → 36 (59) |
| Strong spend-for-free-refresh | 15 → 16 | 23 → 23 | 32 → 31 |
| Ceiling: two golden Rogers + Hoggarr | 18 (60) → 20 (40) | 31 (88) → 30 (48) | 46 (103) → 38 (53) |
| Stress: Hoggarr refund concentrated | unbounded → 74 | unbounded → 75 | unbounded → 76 |
| Stress: a common free-refresh source | 20 (32) → 20 (32) | 40 (56) → 40 (52) | 65 (86) → 70 (86) |
| Golganneth's Tempest + Hoggarr + golden Rogers | unbounded → unbounded | unbounded → unbounded | unbounded → unbounded |

What it shows [judgement on data]:
- On a normal turn (10–14 gold) players see about 12–16 shops; around 20 takes a saved-up turn of about 20 gold. Builds differ, as the owner expected.
- The uncapped price closes every refund loop that runs through paid refreshes (the concentrated Hoggarr line goes from unbounded to about 75).
- It does not close loops made of free or triggered refreshes: Golganneth's Tempest refreshes the shop after each buy, at no price, so the price never rises. The common free-refresh source runs 70 shops from 30 gold. Both are what the owner's free-refresh principle rules out, and they are left to content guardrail G1.
- Gold back of 1 or more per gold spent (r ≥ 1) stays unbounded under any price. The owner declined a guardrail for it (2 Nov): the refresh system is the primary guardrail, and other content shapes stay open to explore. Such cards are checked case by case with `bound check`.

## 1. The answers

1. **Central finding: in a normal turn, no strong engine reaches 20 shops. The long turn comes from banked gold.** [data: bound_floor.csv, bound_summary.csv] At 10–14 gold, the main model's tier-6 turn, strong engines see a median of 8–17 shops in the longest-turn policy, against 10–12 with no engine. Players who also buy stats see 4–8. Only banking makes turns of 20–30 shops, and banking does that with no engine at all (30 gold buys 20 shops, 60 buys 30). Whether "about 20–30 shops" is a ceiling for banked turns or also a floor for the best engines in a normal turn is question 1. *Deferred (owner direction, top of this doc).*
2. **A gold-back or free-refresh rate can't do both.** [data: bound_window.csv] A rate high enough to give 20 shops from 12 gold (r ≥ 0.65 or b ≥ 0.48) gives 36–37 shops from a 30-gold bank and 56–65 from 60 under today's prices. No schedule that keeps normal turns as they are fixes that; the tail that bites earliest (+2 every 5 from the 26th) opens the r window by 0.02 and the b window not at all. **A fixed number of free refreshes per turn can:** about 9 a turn gives 20 shops from 12 gold, 29 from 30 and 39 from 60. So if the owner wants the floor, the long-turn engines should be additive (a per-turn count or cap), not uncapped rates (proposed G13). An additive engine on the same board as a gold-back or free-refresh engine at today's limits breaks the 30-shop median at a 30-gold bank (37–42 shops, section 4.2), so reading B's limits are not settled. *Deferred (owner direction, top of this doc).*
3. **Effect refreshes are a hole in the bounding rules.** [data: bound_summary.csv] An effect refresh is free and uncounted (4.4.6), so no price schedule touches it. Golganneth's Tempest ("It Refreshes itself after you buy a card") + Hoggarr hero + golden Rogers is unbounded under every schedule, the uncapped tail included. Golganneth + Hoggarr alone runs 108 shops from 30 gold and 221 from 60. Counting effect refreshes toward the steps doesn't help when the buy is the price. The fix is content: a per-turn cap on every repeatable refresh source other than the paid Refresh, and no lobby modifier that removes the paid Refresh (widened G8 and new G14).
4. **Recommended schedule: keep 1/2/3 at 10/20, then +1 gold every 5 paid refreshes from the 31st, with no cap.** [judgement on data] It changes no turn of 30 paid refreshes or fewer. Every refund loop that runs through paid refreshes becomes finite. The ceiling Rogers + Hoggarr line at 60 gold drops from 89 shops (p90 176) to 51 (p90 66). It doesn't touch free refreshes, effect refreshes or r ≥ 1; those stay with content. *Deferred (owner direction, top of this doc).* The tail is not needed for the standing bound.
5. **Content limits, tested:** [data: bound_summary.csv, bound_limits.csv] for the strongest plausible board at a 30-gold bank, Λ (length) ≤ 0.5, r ≤ 0.5, and in the Monte Carlo a median of at most 30 shops and a 90th percentile of at most 45. Golden Brann + Refreshing Anomaly fails the 90th percentile (30, p90 53–57). Under "set, don't add" (G5) it gives 22 (p90 24) from 30 gold and 33 (p90 37) from 60, which passes. A free-refresh unit at b = 0.35 with no retrigger gives 24 (p90 27) and 38 (p90 44), which passes. The thresholds (median 30, p90 45, Λ 0.5) are turn-length targets: *Deferred (owner direction, top of this doc).*
6. **Bounding shops doesn't bound power.** [data: bound_summary.csv, power policy, bank 30] Strong Rogers makes 327 stat points (SP) against 62 for no engine. Two golden Rogers make 920 and pass every shop limit. Two golden Rogers + Hoggarr make 3,100. SP per gold runs 1.9 (no engine), 7.3 (strong Rogers), 9.9 (strong scaler) and 13 (ceiling Rogers). This needs its own limit in the power budget (proposed open point B8, section 4.4).
7. **B6: late gold should buy Tavern spells at flat prices.** [data: bound_packages.csv] A no-engine tier-6 player who buys spells and useful units gets 1.7–2.0 SP per gold at any bank (about 1.5 at the margin from 30 to 60 gold). The old refresh-only sink gave 0.5–0.67.
8. **B5: re-price recurring gold once the sink is in.** Superseded: [power-budget.md](power-budget.md) 4.1 now prices gold on units from a per-tier break-even table and is the one home of the gold caps (section 6).

---

## 2. Method

**One long Recruit Phase** [judgement: the frame]. The player has a full board and a bank of G gold, at tier 6 unless marked. A tier-6 shop has 6 units and 1 Tavern spell (rulebook 6.1.1); tier 4 has 5 and 1, tier 3 has 4 and 1. The player takes effect refreshes first, then free ones, then paid ones, until it can't pay. Nothing else ends the turn (rulebook 3.1.2). A run that reaches 1,000 shops counts as unbounded.

**What a shop holds** [data unless marked]:
- Buff spells are 31 of the 73 current Tavern spells, median cost 2 (spells.json). Single-target buffs give 4–6 SP per gold, team buffs less (analysis/spell_gold_to_stats_by_tier.csv). The model uses 5. [judgement for the middle value]
- A tribe fills about 20% of a shop: 1.18 units of one tribe per tier-6 shop, 0.91 at tier 4, 0.76 at tier 3 (minions.json, current pool, 5-tribe lobbies, rulebook 5.1.2 copy counts).
- Refreshing Anomaly and Sly Infiltrator fill 1.38% of tier-6 unit slots; Leaf Through the Pages 1.11% of the spell slot; one named tier-2 card 0.88% (economy-engines.md appendix). Tier 3 and 4 shares are the tier-6 value times the card's share ratio from the same library (section 3.8).
- Coast Guard (tier 5, 9 copies, in the pool 2024-12 to 2025-07) is 0.52% of a normal unit slot and 3.1% of a Pirate-only shop (minions.json).
- Bounty picks are uniform among the five. [judgement: Battlegrounds weights are undocumented]
- A Created unit sells for 0 (rulebook 4.3.3) and adds 3 SP to a full board. [judgement for the SP]

**Clicks and time** [judgement]. The model counts actions: a refresh click; buy, play and sell of each bought unit; buy and cast of each spell; one cast per Bounty; play and sell of each Created unit. The last is how a player clears a 10-card hand (rulebook 7.1.1), because units in hand can't be sold (4.3.7). Time is 4 seconds per shop plus 1.5 seconds per action.

**Packages** (card text from docs/research/battlegrounds/data/*.json; the combinations are judgement). Λ is at the target length under the recommended schedule.

| Package | Class | What it is | r | b | hnet | Λ (length) |
|---|---|---|---|---|---|---|
| none | no engine | buys spells and useful units | 0 | 0 | 0 | 0 |
| avg_pirates | average | plain Rogers + plain Privateer | 0.09 | 0 | 0 | 0.09 |
| avg_mixed | average | plain Tethys + plain Gunpowder Courier + Refreshing Anomaly | 0 | 0.17 | −0.17 | 0.11 |
| avg_spendfree | bramble | plain "after you spend 5 gold, gain a free Refresh" | 0 | 0.38 | 0 | 0.38 |
| strong_rogers | strong | golden Rogers + golden Privateer | 0.27 | 0 | 0 | 0.27 |
| strong_rogers_hoggarr | strong | same + Hoggarr hero (+1 gold per Pirate bought) | 0.27 | 0 | −0.24 | 0.19 |
| strong_brann | strong | Anomaly / Sly Infiltrator + golden Brann (×3) + Leaf cast twice | 0 | 0.54 | −0.18 | 0.48 |
| strong_brann_set | strong | the same under "set, don't add" (G5) | 0 | 0.19 | −0.18 | 0.13 |
| strong_scaler | strong | golden Gunpowder Courier + golden Tethys | 0 | 0 | 0 | 0 |
| strong_coin | strong | Shell Collector + golden Brann (×3) | 0 | 0 | +0.05 | 0.02 |
| strong_spendfree | bramble | golden "after you spend 5 gold, gain 2 free Refreshes" | 0 | 0.55 | 0 | 0.55 |
| strong_sticker | library | Recycling Sticker ("after you play an Elemental, gain a free Refresh") | 0 | 1.18 | −2.36 | 0.21 |
| strong_pigeon_rogers | library | Pigeon Lord (refreshes free while the shop has no Pirate) + golden Rogers + golden Privateer | 0.27 | ≥ 1 | −1.42 | 0.53 |
| b035_free_src | bramble | a "gain 2 free Refreshes" unit at 2.9% of slots (gross b 0.35), no retrigger | 0 | 0.35 | −0.35 | 0.23 |
| bramble_additive8 | bramble | golden "Start of turn: gain 4 free Refreshes" (8) | 0 | 0 | 0 | 0 (adds 8 shops) |
| ceiling_2rogers | ceiling | two golden Rogers + golden Privateer | 0.53 | 0 | 0 | 0.53 |
| ceiling_2rogers_hoggarr | ceiling | same + Hoggarr hero | 0.53 | 0 | +0.71 | 0.77 |
| golganneth_none | anomaly | Golganneth's Tempest: units cost 2, no Refresh action, the shop refreshes itself after each buy | 0 | — | −1.0 | 0.5 |
| golganneth_hoggarr | anomaly | same + Hoggarr hero | 0 | — | −0.27 | 0.87 |
| golganneth_hoggarr_rogers | anomaly | same + golden Rogers + golden Privateer | 0.27 | — | +0.27 | 1.13 |
| coastguard_hoggarr_rogers | library | Coast Guard ("when you sell this, Refresh the Tavern with Pirates, then steal one") + Hoggarr hero + golden Rogers | 0.27 | 0 | −0.24 | 0.19 (excludes Coast Guard) |
| stress_sticker_refund | stress | Recycling Sticker + a Hoggarr for Elementals (+1 per Elemental bought) | 0 | 1.18 | −1.18 | 0.61 |
| stress_brann_x4 | stress | strong_brann with golden Brann read as ×4 (rulebook 7.3.5 open) | 0 | 0.71 | −0.18 | 0.65 |
| stress_rogers_hoggarr_bgsell | stress | ceiling_2rogers_hoggarr with Battlegrounds sell values | 0.80 | 0 | +1.65 | 1.35 |
| stress_hoggarr_concentrated | stress | golden + plain Hoggarr (+3 per Pirate), every shop all Pirates, each shop paid as a refresh | 0 | 0 | +6 | 2.0 |
| stress_common_free_src | stress | a common free-refresh unit (3% of slots, "gain 2 free Refreshes") + golden Brann | 0 | 1.08 | −0.36 | 0.88 |

[data: bound_packages.csv columns r, b, engine_net_gold_per_shop, loop_index]

Pigeon Lord (a buddy, 2022) and golden Rogers (2025–26) were never in the pool together, so strong_pigeon_rogers is a cross-era line. Brann's three Battlecry triggers on a "Refresh the Tavern" Battlecry (the Baby Kodo and Waxadred buddies) give one usable shop, not three, because the player can act only on the last one [judgement: Hearthstone resolves all triggers before the player acts]. That is why no package multiplies a Battlecry effect refresh.

**Schedules** (price of the next paid refresh; [bound_schedules.csv](../research/budget-model/bound_schedules.csv)):

| Schedule | Prices | Gold for 20 / 30 / 40 shops | Shops from 12 / 20 / 30 / 60 / 100 gold |
|---|---|---|---|
| bg_flat1 (Battlegrounds) | always 1 | 20 / 30 / 40 | 12 / 20 / 30 / 60 / 100 |
| **s123_10_20 (Bramble now)** | 1/2/3 at 10/20 | 30 / 60 / 90 | 11 / 15 / 20 / 30 / 43 |
| s12345_10_40 | 1/2/3/4/5 at 10/20/30/40 | 30 / 60 / 100 | 11 / 15 / 20 / 30 / 40 |
| s123_5_10 | 1/2/3 at 5/10 | 45 / 75 / 105 | 8 / 11 / 15 / 25 / 38 |
| s12345_5_20 | 1/2/3/4/5 at 5/10/15/20 | 50 / 100 / 150 | 8 / 11 / 15 / 22 / 30 |
| **s123_plus1_nocap (recommended)** | 1/2/3 at 10/20, then +1 every 5 from the 31st, no cap | 30 / 60 / 105 | 11 / 15 / 20 / 30 / 39 |
| s123_plus1_from26 | same, from the 26th | 30 / 65 / 120 | 11 / 15 / 20 / 28 / 36 |
| s123_plus2_from26 | +2 every 5 from the 26th | 30 / 70 / 150 | 11 / 15 / 20 / 28 / 34 |
| s123_double | 1/2/3 at 10/20, then doubles every 5 from the 31st | 30 / 60 / 150 | 11 / 15 / 20 / 30 / 35 |
| s12345_plus1_10 | 1/2/3/4/5 at 10/20/30/40, then +1 every 10 from the 51st | 30 / 60 / 100 | 11 / 15 / 20 / 30 / 40 |

[data: arithmetic] Every schedule that keeps 1/2/3 at 10/20 is the same for the first 20 paid refreshes, and the ones with a tail from the 31st for the first 30. Moving the steps earlier (5/10) is the only change that touches normal turns.

**Noise.** 400 runs per cell. Each cell seeds its own generator from the seed (7) and the cell's names, so results don't depend on run order. Schedules that are the same up to a turn's length give medians up to 3 shops apart for the same package; that is noise. Revision 1 shared one generator across cells, so some numbers moved by 1–3 shops.

---

## 3. Results

### 3.1 What bounds what [data: bound_sweeps.csv, bound_limits.csv]

A pure refresher with one engine rate and nothing else, shops in one turn at banks 20 / 30 / 60:

| Rate | 1/2/3 now | +1 every 5 from the 31st | doubles from the 31st |
|---|---|---|---|
| r = 0.35 | 19 / 24 / 40 | 19 / 24 / 36 | 19 / 24 / 34 |
| r = 0.5 | 22 / 29 / 49 | 22 / 29 / 41 | 22 / 29 / 36 |
| r = 0.7 | 29 / 41 / 74 | 29 / 36 / 51 | 29 / 34 / 40 |
| r = 0.9 | 67 / 101 / 201 | 45 / 56 / 79 | 35 / 40 / 45 |
| b = 0.35 | 22 / 30 / 45 | same | same |
| b = 0.5 | 29 / 39 / 59 | same | same |
| b = 0.7 | 47 / 64 / 97 | same | same |
| hnet = 1.0 | 24 / 29 / 44 | 24 / 29 / 38 | 24 / 29 / 35 |
| hnet = 2.0 | 48 / 58 / 88 | 37 / 40 / 47 | 34 / 35 / 38 |
| hnet = 3.0 | unbounded | 49 / 51 / 57 | 38 / 39 / 41 |
| hnet = 5.0 | unbounded | 70 / 72 / 76 | 43 / 43 / 45 |
| a = 8 free refreshes at start of turn | 23 / 28 / 38 | same | same |

- **b is untouched by any price schedule.** Free shops aren't paid, so b = 0.5 doubles the turn.
- **r is bounded below 1 by gold.** A rising tail shortens long r-turns but can't end r ≥ 1.
- **hnet needs a price above it.** At a top price of 3, hnet ≥ 3 never ends. A tail with no cap ends every hnet that runs through paid refreshes, but hnet = 5 still runs 72 shops. Λ (length) shows that; Λ (top) doesn't.
- **a adds a fixed number of shops**, whatever the bank.

### 3.2 The floor: normal turns against banked turns [data: bound_floor.csv]

Median shops (p90), recommended schedule (the same as Bramble now at these lengths, within noise). Normal turn = 12 gold.

| Package | Loop, 12 gold | Power, 12 gold | Loop, 30 gold | Power, 30 gold |
|---|---|---|---|---|
| none | 11 | 6 | 20 | 12 |
| strong_rogers | 11 (17) | 6 (10) | 22 (28) | 15 (20) |
| strong_rogers_hoggarr | 9 (16) | 6 (10) | 20 (26) | 13 (19) |
| strong_brann | 16 (24) | 6 (11) | 30 (53) | 16 (24) |
| strong_brann_set | 12 (12) | 6 (8) | 22 (24) | 12 (14) |
| strong_spendfree | 15 | 8 (10) | 32 | 20 (22) |
| strong_pigeon_rogers | 17 (25) | 8 (13) | 34 (48) | 18 (25) |
| bramble_additive8 | 19 | 10 (12) | 28 | 16 (19) |
| ceiling_2rogers | 14 (24) | 8 (15) | 28 (37) | 20 (30) |
| ceiling_2rogers_hoggarr | 20 (47) | 10 (31) | 39 (53) | 28 (46) |

- **In a normal turn today's engines add 0–6 shops over no engine** in the longest-turn policy, and 0–2 for a player who also buys stats. No strong package reaches a median of 20. Only the ceiling Rogers + Hoggarr line does, and only in the loop policy. The additive Bramble shape adds 8.
- **At 30 gold the engine's share is still small.** No engine already sees 20 shops. Strong Rogers adds 2, golden Brann adds 10 (with a long tail).
- **An engine turn is no longer than a banked turn.** A player who saves two turns sees 30 shops with no engine. That undercuts the "very, very long" engine fantasy (section 8).

### 3.3 Floor against ceiling: one rate can't do both [data: bound_window.csv]

The smallest rate that gives 20 shops from 12 gold, against the largest that keeps 30 gold to 30 shops and 60 gold to 45 (pure refresher):

| Rate | Needed for 20 from 12 gold | Most allowed: 30 at 30 gold / 45 at 60 gold, recommended | That floor rate at 30 / 60 gold | Window |
|---|---|---|---|---|
| r | 0.65 | 0.56 / 0.60 | 34 / 48 | closed |
| b | 0.48 | 0.36 / 0.35 | 37 / 56 | closed |
| hnet | 0.95 | 1.10 / 1.80 | 28 / 38 | open, narrow |
| a (free refreshes per turn) | 9 | 10 / 15 | 29 / 39 | open |

- **r and b scale with the bank.** A gold-back rate multiplies the gold; a free-shop rate multiplies the paid shops. 30 gold buys 20 paid refreshes against 11 from 12 gold, so any b that lifts 12 gold to 20 shops lifts 30 gold to 37.
- **No schedule opens the r or b window** without changing normal turns. Under +2 every 5 from the 26th, r opens barely (needs 0.65, allows 0.67). b is closed under every schedule, because price doesn't touch it.
- **Additive engines don't scale with the bank.** "Gain 4 free Refreshes at the start of your turn" (golden: 8) gives 19 shops from 12 gold, 28 from 30 and 38 from 60 [data: bramble_additive8]. A spend engine with a per-turn cap ("up to 4 times a turn") is additive too, once it hits the cap.
- **hnet sits between.** Net gold per shop is paid per shop, not per gold, so it neither multiplies the bank nor stays fixed. Its window is open only between 0.95 and 1.10.

### 3.4 The longest turn: loop policy [data: bound_summary.csv]

Median shops (p90), bank 30. U = some runs hit the 1,000-shop cap.

| Package | 1/2/3 now | 1–5 at 10–40 | 1/2/3 at 5/10 | +1/5 from 31 | +1/5 from 26 | doubles |
|---|---|---|---|---|---|---|
| none | 20 | 20 | 15 | 20 | 20 | 20 |
| avg_pirates | 20 (21) | 20 (21) | 15 (16) | 21 (22) | 21 (22) | 20 (21) |
| avg_mixed | 22 (24) | 22 (24) | 16 (19) | 22 (24) | 22 (24) | 22 (24) |
| strong_rogers | 24 (28) | 22 (28) | 17 (21) | 22 (28) | 24 (27) | 24 (28) |
| strong_rogers_hoggarr | 20 (26) | 19 (27) | 15 (21) | 20 (26) | 20 (26) | 19 (26) |
| strong_brann | 30 (57) | 30 (52) | 20 (47) | 30 (53) | 30 (50) | 30 (50) |
| strong_brann_set | 22 (23) | 22 (24) | 16 (19) | 22 (24) | 21 (23) | 22 (23) |
| strong_spendfree | 32 | 32 | 27 | 32 | 32 | 32 |
| strong_pigeon_rogers | 34 (46) | 34 (49) | 29 (40) | 34 (48) | 33 (46) | 34 (46) |
| b035_free_src | 23 (27) | 24 (27) | 19 (23) | 24 (27) | 24 (27) | 24 (27) |
| ceiling_2rogers | 28 (42) | 28 (37) | 23 (37) | 28 (37) | 25 (33) | 30 (35) |
| ceiling_2rogers_hoggarr | 46 (103) | 40 (65) | 39 (102) | 39 (53) | 36 (51) | 35 (40) |
| golganneth_hoggarr | 109 (132) | 106 (132) | 106 (131) | 108 (128) | 106 (130) | 107 (131) |
| golganneth_hoggarr_rogers | U | U | U | U | U | U |
| stress_brann_x4 | 41 (86) | 37 (83) | 29 (73) | 37 (86) | 37 (83) | 41 (83) |
| stress_common_free_src | 65 (86) | 70 (82) | 62 (86) | 65 (86) | 65 (86) | 65 (86) |
| stress_rogers_hoggarr_bgsell | U | U | U | 105 (139) | 95 (130) | 45 (50) |
| stress_hoggarr_concentrated | U | U | U | 83 (83) | 76 (76) | 45 (45) |

Bank 60:

| Package | 1/2/3 now | 1–5 at 10–40 | 1/2/3 at 5/10 | +1/5 from 31 | +1/5 from 26 | doubles |
|---|---|---|---|---|---|---|
| none | 30 | 30 | 25 | 30 | 28 | 30 |
| avg_pirates | 31 (34) | 31 (33) | 26 (29) | 31 (33) | 29 (31) | 30 (32) |
| strong_rogers | 36 (42) | 34 (39) | 31 (39) | 34 (38) | 32 (36) | 33 (36) |
| strong_brann | 51 (85) | 49 (88) | 41 (67) | 51 (88) | 50 (85) | 49 (85) |
| strong_brann_set | 33 (37) | 33 (37) | 27 (30) | 33 (37) | 33 (36) | 34 (37) |
| b035_free_src | 39 (44) | 39 (44) | 31 (37) | 38 (44) | 37 (44) | 39 (44) |
| strong_pigeon_rogers | 60 (75) | 60 (76) | 54 (68) | 59 (76) | 59 (75) | 60 (75) |
| ceiling_2rogers | 48 (68) | 44 (53) | 43 (61) | 41 (48) | 39 (47) | 37 (40) |
| ceiling_2rogers_hoggarr | 89 (176) | 60 (90) | 78 (172) | 51 (66) | 47 (61) | 40 (43) |
| golganneth_none | 59 | 59 | 59 | 59 | 59 | 59 |
| golganneth_hoggarr | 215 (245) | 218 (250) | 217 (251) | 221 (255) | 219 (251) | 221 (250) |
| stress_rogers_hoggarr_bgsell | U | U | U | 115 (149) | 109 (142) | 49 (50) |
| stress_hoggarr_concentrated | U | U | U | 86 (86) | 80 (80) | 46 (46) |

What it shows:
- **Strong Rogers boards sit at 20–24 shops at a 30-gold bank** under every schedule that keeps 1/2/3 at 10/20.
- **The ceiling Rogers + Hoggarr line is what the tail is for.** It drops from 46 (p90 103) to 39 (p90 53) at 30 gold, and from 89 (p90 176) to 51 (p90 66) at 60.
- **A cap at 5 doesn't end refund loops.** Under 1–5 at 10–40 the concentrated Hoggarr loop is unbounded in every run, at every bank, in the loop policy [data: bound_packages.csv share_unbounded 1.0]. Any cap leaves refunds above it open.
- **Free-refresh and effect-refresh lines are the same under every schedule** (strong_brann, strong_pigeon_rogers, the Golganneth lines, stress_common_free_src).
- **Moving the steps earlier (5/10) shortens everyone's turn by about a quarter**, the no-engine player's included, and bounds nothing new.

### 3.5 Effect refreshes and conditional free refreshes [data: bound_summary.csv]

These are the shapes revision 1 left out. All of them sidestep the price.

- **Buy-triggered effect refresh (Golganneth's Tempest).** "Minions cost 2 Gold. You cannot Refresh the Tavern. It Refreshes itself after you buy a card." Each shop costs one buy at 2 gold, less 1 back from selling: a flat 1-gold shop that never escalates. With no engine that is 29 shops from 30 gold and 59 from 60, for every player in the lobby. With the Hoggarr hero a Pirate pays for itself (−2 + 1 + 1), so only shops without a Pirate cost gold: 108 shops from 30 gold, 221 from 60. Add golden Rogers and a Pirate nets +0.53, and the turn is unbounded under every schedule (Λ 1.13).
- **Sell-triggered effect refresh (Coast Guard, Snarky Shark).** Coast Guard refreshes into a Pirate-only shop, a real concentrator. In the model it rarely chains, because Coast Guard is only 3% of a Pirate shop: 19–20 shops (p90 28) from 30 gold with Hoggarr + golden Rogers. Snarky Shark is one-shot. A common or self-returning version would chain.
- **Battlecry effect refresh (Baby Kodo, Waxadred).** Retriggers don't multiply usable shops (section 2). One-shot per copy.
- **"Free after you play X" (Recycling Sticker).** Gross b is 1.18, three times proposed G7's 0.35, yet it adds no shops at 30 gold (20, as no engine) and 5 at 60. Each free refresh costs an Elemental, 2 gold net, which is no cheaper than a paid refresh at 2. Add a 1-gold refund per Elemental and every shop costs 1 gold flat: 30 shops from 30 gold, 60 from 60 (stress_sticker_refund), the Battlegrounds rate.
- **"Free while the shop has no X" (Pigeon Lord).** The player buys out the type and refreshes free. With golden Rogers each Pirate costs 1.2 net: 17 shops (p90 25) from 12 gold, 34 (p90 48) from 30 and 59 (p90 76) from 60. It fails the 90th-percentile limit. Any refund that covers the net buy cost makes it infinite at any price.

**What these share:** the shop's price is a buy, not a paid refresh. Gross b is the wrong test for them; the net gold per shop is what counts. Counting them toward the price steps doesn't help either, because the escalating price is never paid. The rule that works is a per-turn cap on the source (proposed G8, widened) or a net cost per shop of at least the price at the target length, 3 gold.

### 3.6 Testing the free-refresh fixes [data: bound_summary.csv, loop policy]

| Package | 30 gold: median (p90) | 60 gold | Passes median ≤ 30, p90 ≤ 45 at 30 gold? |
|---|---|---|---|
| strong_brann (adds, ×3) | 30 (53) | 51 (88) | no: p90 |
| **strong_brann_set (G5)** | 22 (24) | 33 (37) | yes |
| **b035_free_src (b = 0.35, no retrigger)** | 24 (27) | 38 (44) | yes |
| stress_brann_x4 | 37 (86) | 66 (143) | no |

- **"Set, don't add" works.** Each grant sets the free count to 2, so Brann's extra triggers and a second Anomaly add nothing while two free refreshes are still waiting. Its b falls from 0.54 to at most 0.19.
- **The tail comes from lumpy grants, not from b.** A b = 0.35 source with no retrigger has a p90 only 3 shops above its median. strong_brann has the same expected b (Λ 0.48) but gets it in lumps of 6, so its p90 is 23 above. G5 removes the lumps.

### 3.7 What players get: power policy, Bramble now [data: bound_summary.csv]

Median shops (p90) / mean gold spent / mean units gained (bought + Created) / mean SP gained / SP per gold / median minutes:

| Package | Bank 12 | Bank 30 | Bank 60 |
|---|---|---|---|
| none | 6 / 13 / 1.1 / 26 / 1.99 / 0.8 | 12 (14) / 33 / 2.8 / 62 / 1.88 / 1.6 | 20 (22) / 64 / 5.1 / 108 / 1.68 / 2.8 |
| avg_pirates | 6 (8) / 14 / 1.6 / 48 / 3.41 / 0.8 | 13 (15) / 36 / 4.3 / 133 / 3.73 / 1.9 | 22 (24) / 70 / 8.4 / 255 / 3.62 / 3.2 |
| strong_rogers | 6 (10) / 17 / 3.4 / 115 / 6.81 / 1.0 | 15 (20) / 45 / 9.1 / 327 / 7.30 / 2.5 | 25 (30) / 88 / 17.5 / 656 / 7.47 / 4.4 |
| strong_rogers_hoggarr | 6 (10) / 34 / 11.5 / 217 / 6.33 / 1.4 | 13 (19) / 86 / 30.2 / 583 / 6.75 / 3.8 | 23 (30) / 163 / 54.7 / 1,130 / 6.93 / 7.1 |
| strong_brann | 6 (11) / 14 / 1.5 / 27 / 2.02 / 0.8 | 16 (24) / 34 / 4.4 / 72 / 2.09 / 2.1 | 27 (39) / 68 / 8.6 / 138 / 2.02 / 3.7 |
| strong_scaler | 6 (8) / 13 / 3.1 / 114 / 8.67 / 0.9 | 12 (14) / 33 / 8.8 / 324 / 9.88 / 1.9 | 20 (22) / 64 / 17.0 / 641 / 9.98 / 3.4 |
| ceiling_2rogers | 8 (15) / 24 / 7.2 / 294 / 12.3 / 1.5 | 20 (31) / 70 / 22.5 / 920 / 13.2 / 4.1 | 34 (50) / 139 / 45.8 / 1,882 / 13.5 / 7.8 |
| ceiling_2rogers_hoggarr | 9 (32) / 97 / 44.4 / 1,222 / 12.7 / 2.8 | 28 (61) / 240 / 111.5 / 3,116 / 13.0 / 10.9 | 53 (96) / 449 / 202.9 / 5,881 / 13.1 / 21.4 |

- **A player who wants stats sees fewer shops than one who wants shops.** Spells at 5 SP per gold beat refreshes, and for spend engines every gold spent on a spell also ticks the counter.
- **The engine's reward is stats, not shops.** At 30 gold strong Rogers sees 3 more shops than no engine but makes 5× the SP.
- **Clicks, not shops, set the time of an engine turn.** Two golden Rogers + Hoggarr at 30 gold take 436 actions and about 11 minutes (p90 24) in the power policy, for 28 shops. The Rogers lines gain 9–112 units a turn (bought plus Created) and their Bounties, each played and sold or cast by hand.

### 3.8 Lower Tavern tiers [data: bound_tiers.csv]

Sources at tiers 1–3 are denser in a lower-tier shop. Shell Collector's share of a slot is 2.0× its tier-6 share at tier 3 and 1.36× at tier 4; Sly Infiltrator's 1.95× and 1.34×; Leaf's 2.7× and 1.43×. Refreshing Anomaly is tier 4, so it is missing at tier 3. Shops are smaller (4 or 5 units). Golden Brann is tier 5, so these runs use no retrigger, or Brann's Blessing (tier-4 spell) read as active all turn. Loop policy, Bramble now, median (p90) at 10 / 20 / 30 gold:

| Package | Tier 3 | Tier 4 | Tier 6 |
|---|---|---|---|
| Anomaly / Sly + Leaf, no retrigger | 10 / 16 / 22 (24) | 10 / 17 / 22 (25) | 10 / 16 / 22 (24) |
| Same, Battlecries ×2 | 11 / 18 / 24 (30) | 12 / 21 / 27 (38) | 11 / 18 / 26 (35) |
| Shell Collector | 10 / 14 / 19 | 10 / 14 / 19 | 10 / 14 / 19 |
| Recycling Sticker + Elemental refund | 10 / 20 / 30 | 10 / 20 / 30 | 10 / 20 / 30 |

- **Tier 4 is the worst tier for free-refresh sources**: per shop, b is 0.40 there against 0.35 at tier 6 with a ×2 retrigger. It adds 1–3 shops to the median and 3 to the 90th percentile.
- **Coins barely matter at any tier** (Λ about 0).
- So the G10 check should run at tier 4 as well as tier 6 for any source of tier 4 or lower.

### 3.9 Where it goes unbounded [data: bound_packages.csv share_unbounded]

- **Under Bramble's rules and every schedule, the uncapped tail included:** Golganneth's Tempest + Hoggarr hero + golden Rogers (effect refreshes, from a 12-gold normal turn up).
- **Under every capped schedule as well:** the two stress lines that need Created units to sell for gold (against 4.3.3) or a Pirate-only shop paid as a refresh.
- **Battlegrounds' flat 1:** also ceiling_2rogers_hoggarr.
- **Not unbounded but past 100 shops:** Golganneth + Hoggarr (108 from 30 gold, 221 from 60), and the two stress lines under the tail (76–115).
- Revision 1 said nothing in the library was unbounded under an uncapped price. That was wrong: it left out effect refreshes.

---

## 4. Recommendation

### 4.1 Refresh price schedule [judgement on section 3]

*Deferred (owner direction, top of this doc).* The owner's fallback is the rising paid refresh cost as it is now (1/2/3 at 10/20); whether to add a tail is for later power budgeting. The comparison below stands as evidence for that.

**Keep 1/2/3 at 10/20. From the 31st paid refresh, add 1 gold every 5 paid refreshes (4 for 31–35, 5 for 36–40, 6 for 41–45, …), with no cap.**

- It is still "rising cost only", and it does reach 5, as the owner floated.
- It never touches a turn of 30 paid refreshes or fewer. No-engine players don't reach that below a 60-gold bank, and average players only at about 60 gold (avg_pirates at 60 gold, loop policy: median 31 paid refreshes) [data: bound_packages.csv].
- It makes every refund loop that runs through paid refreshes finite. Λ (length) still measures how long such a loop runs (section 4.3).
- It doesn't touch free refreshes, effect refreshes or r ≥ 1. Those stay with content (section 7).

Rejected options:
- **1/2/3/4/5 at 10/20/30/40, capped at 5.** Same cost to normal turns, but the concentrated Hoggarr loop stays unbounded in the loop policy at every bank. A cap at any price leaves refund loops above it open.
- **Earlier steps (1/2/3 at 5/10, or 1–5 at 5–20).** They cut every player's turn by about a quarter, and 20 shops cost 45–50 gold instead of 30. They bound nothing new.
- **+1 every 5 from the 26th.** Holds a 60-gold no-engine turn to 28 instead of 30 and shortens long r-turns by 2–4 shops. It doesn't open the floor window (section 3.3). A fair fallback if the owner wants banked turns a little shorter.
- **Doubling from the 31st.** The tightest bound: every loop with r < 1 and b < 1 ends at about 40–50 shops. But 6, 12, 24, 48 gold reads as a wall, close to the hard cap the owner chose against.
- **A steeper schedule to make engines reach 20 in a normal turn.** No schedule does it for r or b without changing normal turns (section 3.3).

### 4.2 What the 20–30 target should measure [judgement; the owner decides, question 1]

*Deferred (owner direction, top of this doc).*

Two readings, with what each needs:

- **A. Ceiling only.** The longest plausible turn, from a 30-gold bank, stays at a median of 30 shops and a 90th percentile of 45. The engine's reward is stats. A normal 12-gold engine turn is about 9–16 shops. This is what today's library, with G5 and the effect-refresh rules, already gives.
- **B. Floor and ceiling.** The best engines also reach about 20 shops on a normal 12-gold turn. That needs additive engines (proposed G13): about 8–10 extra shops a turn from a fixed per-turn count or a per-turn cap. Uncapped rates stay at Λ (length) ≤ 0.5, which gives 16–17 shops on a normal turn.

**My recommendation is B** [judgement]. It makes "a very, very long turn" something an engine does, not something banking does. It matches the "lots of small actions" flavour. It also keeps the turn bounded by construction, because a per-turn cap is a number on the card. Under A the engine turn is no longer than a banked turn (section 3.2).

**Deferred with question 1: reading B's limits don't fit together yet.** An additive engine and an uncapped rate at its limit on the same board break G10's median of 30 at a 30-gold bank. "Start of turn: 8 free Refreshes" with r = 0.5 gives 37 shops from 30 gold (49 from 60); with b = 0.35 it gives 42 (57 from 60), loop policy, recommended schedule [data: `bound check r=0.5 a=8`, `bound check b=0.35 a=8`]. So under B one of these has to give: uncapped rates are held lower on a board that also has an additive engine, the additive total counts against the same budget, or G10's median rises for banked turns. Which one depends on question 1: whether "about 20–30 shops" is a ceiling only, or also a floor. Until turn length is power-budgeted, the reading-B rows below (G13 and the 8–10-shop total) are proposals that are known not to fit with G2, G7 and G10 as written.

Under either reading: ceiling packages may reach a median of 45 at 30 gold, and every package must be finite at every bank (Λ (top) < 1, no repeatable uncapped effect refresh).

### 4.3 Content limits [data: sections 3.1–3.6; thresholds judgement]

*Deferred (owner direction, top of this doc).* The thresholds are turn-length targets, so they wait for later power budgeting; the measurements against them stand. For the strongest plausible board (board rule, section 7), at tier 6, and at tier 4 for sources of tier 4 or lower:

| Limit | Value | What it allows, recommended schedule |
|---|---|---|
| Λ (length), at the price of the 30th paid refresh | ≤ 0.5 (ceiling boards ≤ 0.75) | about 30 shops from 30 gold, 40–45 from 60 |
| r, gold back per gold spent | ≤ 0.5 | 29 / 41 shops from 30 / 60 gold |
| Monte Carlo, loop policy, 30-gold bank | median ≤ 30, p90 ≤ 45 | the test that catches lumpy grants |
| Free-refresh grants | set, don't add (G5), or a per-turn cap | strong_brann_set: 22 (p90 24) |
| Repeatable refresh sources other than the paid Refresh | a per-turn cap, unless net cost per shop ≥ 3 gold | closes the Golganneth, Pigeon Lord and Sticker shapes |
| Additive engines (G13), if the owner picks reading B | about 8–10 shops a turn from the best board. **Not settled:** with a rate engine at its limit on the same board it breaks the median of 30 (section 4.2) | 19–20 / 28–29 / 38–39 from 12 / 30 / 60 gold, alone |

- **Λ (length) replaces revision 1's Λ for refunds.** Revision 1 took Λ at the top price, which is infinite under the tail, so refunds dropped out and hnet = 5 passed while running 72 shops. Λ (length) is taken at price 3.
- **Gross b is dropped as the main test.** It flags Recycling Sticker (gross b 1.18), which adds no shops, and misses that golden Brann's long tail comes from lumps. The Monte Carlo p90 and G5 handle the tail; Λ handles source costs. A gross b of 0.35 stays as a quick rule for a grant that costs about one unit and has no retrigger.
- **Today's library against the limits:** Rogers lines without Hoggarr pass (Λ 0.27 strong, 0.53 ceiling), and strong Rogers + Hoggarr passes (Λ 0.19). The ceiling line, two golden Rogers + golden Privateer + Hoggarr, does not pass cleanly: its Λ (length) is 0.77, over the ceiling limit of 0.75, while its Monte Carlo median of 39 (p90 53) at 30 gold is under the ceiling median of 45 [data: bound_packages.csv, ceiling_2rogers_hoggarr, s123_plus1_nocap]. As the table is written a board must pass every row, so it fails. Λ is an expected-value test and the Monte Carlo measures the turn itself, so there is a case for letting the Monte Carlo govern when the two disagree; this doc doesn't decide that (question 10). Golden Brann + Anomaly passes Λ (0.48) but fails the p90 (53); it passes under G5. Pigeon Lord + golden Rogers fails both (Λ 0.53, p90 48). Golganneth with Hoggarr fails, with or without Rogers. The golden Bramble spend-free shape (2 free refreshes per 5 gold) fails narrowly (Λ 0.55, 32 shops); the plain one passes (0.38, 26).

### 4.4 Bounding shops doesn't bound power [data: section 3.7]

Every shop limit above can pass while a turn makes thousands of stats. Two golden Rogers pass G2 (r 0.53, ceiling) and make 920 SP from 30 gold. Strong Rogers makes 7.3 SP per gold against 1.9 for no engine.

**Proposed open point B8 for power-budget.md: engine SP per gold.** The power budget should price an engine's stats per gold spent, the way it prices scaling per turn. A starting point to test [judgement]: the strongest plausible engine makes at most about 4× the no-engine SP per gold (about 8 at tier 6), inside the ±25% engine band. Today's strong Rogers (7.3) and strong scaler (9.9) sit near or above that; ceiling Rogers (13) is well above. The number needs the combat link the power budget has and this model doesn't. I haven't proposed it as a guardrail for that reason.

---

## 5. B6: what late-game gold buys

**Recommended answer: Tavern spells at flat prices, plus spend-counter engines for decks that build one.** [judgement on data]

- **Measured:** a no-engine tier-6 player that buys buff spells and useful units gets 1.99, 1.97, 1.88 and 1.68 SP per gold at banks 12, 20, 30 and 60 [data: bound_packages.csv, none, power, 1/2/3]. At the margin the gold from 30 to 60 buys about 1.5 SP per gold (62 to 108 SP for 33 to 64 gold spent). bound_econ_recheck.csv runs at 1.6 as the margin case. The main model's refresh-only sink gives 0.67 SP per gold at 30 gold and 0.5 at 60 [data: arithmetic on bound_schedules.csv].
- **Why it works:** spells are bought, not refreshed. Their price doesn't escalate ("refreshes only"), so late gold keeps a steady value while escalation still limits shops.
- **Spend-counter engines** turn gold into stats at a fixed rate: golden Gunpowder Courier makes 324 SP from 30 gold, about 10 per gold [data: strong_scaler]. They are the late sink for the "lots of small actions" flavour. Their rate is B8's question.
- **What this needs from the rules [proposal]:** state in 4.2.5 that Tavern spell prices never escalate within a turn. Keep a spell slot in every tier-5 and tier-6 shop, as Battlegrounds does. Check the spell pool so about 40% of late spells are buffs (today's 42%, spells.json).
- **Risk:** a flat sink makes a big bank linear in stats. That is fine; it isn't a loop. But spell SP per gold must be budgeted, because it sets what every late gold is worth ([power-budget.md](power-budget.md) 4.1).

## 6. B5: re-pricing recurring economy

Superseded by [power-budget.md](power-budget.md) 4.1, which is the one home of the gold caps and of gold prices on units. It reads the price per tier from the model's break-even at the measured late sink of section 5, and lists the sinks at which those prices hold. This section's earlier factors and caps are withdrawn; the break-even runs behind them are still in [bound_econ_recheck.csv](../research/budget-model/bound_econ_recheck.csv), which power-budget.md 4.1 cites.

---

## 7. Economy guardrails: the one list

**Every guardrail below except G1 is a proposal awaiting the owner. None of G2–G14 is decided, and none is in [content-guardrails.md](content-guardrails.md) yet.** The standing bound is G1 plus the rising paid refresh cost (owner direction at the top of this doc). The turn-length targets (G10, G13 and rulebook delta 1) are deferred to later power budgeting, and so are the numeric thresholds in G2, G3, G7 and G11 (section 4.3); the shape of each guardrail stays proposed.

This is the one list of economy guardrails (owner, 2 Nov: "One list in bounding"). It replaces the proposals in [economy-engines.md](../research/battlegrounds/economy-engines.md) §7–8, [effect-taxonomy.md](effect-taxonomy.md) §7.5 and [economy-text-by-era.md](../research/battlegrounds/economy-text-by-era.md) §9. Each limit is stated once, here. Where those docs proposed a different number, this list keeps the number this model measured and says what it replaced. Two things live elsewhere: the gold caps on units ([power-budget.md](power-budget.md) 4.1, their one home) and how recruit triggers are counted for pricing (power-budget.md 3.5).

**Board rule (what "strongest plausible board" means)** [judgement]: at most one golden plus one plain copy of any tier-5 or tier-6 card (4 of its 7–9 copies); one retrigger (golden Brann counts as one); the hero's power; one anomaly; one trinket. Cross-tribe and neutral pieces count if the lobby can hold them together. A board that breaks this rule is a ceiling board.

**How to check a card:** add it to `BOUND_PACKAGES` using the listed kinds. For a mechanic none of them covers, use the `board` kind (r, b, hnet per card) or run `bound check r=… b=… hnet=… a=…`. Run at tier 6, and at tier 4 if the card is tier 4 or lower.

- **G1. Free and triggered refreshes can't chain without end.** *Decided* (owner, 27 Oct; reworded 2 Nov to cover effect refreshes): "G1. Free and triggered refreshes can't chain without end. Any refresh the player doesn't pay for (a free Refresh, or an effect that refreshes the shop) must be limited so that an endless chain is mathematically impossible: on the strongest legal board, the expected number of unpaid refreshes each shop leads to stays well below 1. A rare card that gives a few is fine; a common trigger such as 'when sold, refresh the shop' on most shop units is not. Purpose: unpaid refreshes skip the rising price, so with no turn timer they are the one way a turn could run forever." Text in [content-guardrails.md](content-guardrails.md). G5, G7 and G8 are proposals that put numbers on it.
- **G2. Gold back per gold spent:** r ≤ 0.5 on the strongest plausible board, ≤ 0.75 on a ceiling board. Compute r with golden copies (rulebook 7.3.5), as many copies as the board rule allows, and every multiplier in the pool, and count the reward's own economy (a generated unit that gives a Coin counts). r counts gold only: Wealthy-style gold, sell values of Created units, refunds per gold. A free refresh from a spend counter is not gold; it counts in b, as free shops per shop: b = x / (1 + x), where x = price × per ÷ N is the free refreshes it gives per paid refresh ("after you spend N gold, gain per free Refreshes"), taken at the target-length price (3). That share rises with price, but it can never make a turn infinite on its own, because those free shops don't spend gold. *Source:* sections 3.1, 4.3. *Replaces:* economy-engines.md's r ≤ 0.6 with a free refresh counted as 1 gold, and effect-taxonomy.md's r ≤ 0.6 per card. economy-text-by-era.md's "a card plus its golden under 1 gold-equivalent per gold" is covered: G2 checks the golden on the strongest board at 0.5.
- **G3. Refunds per buy or sell:** Λ (length) ≤ 0.5, counting refunds at price 3, at h = 1.2 for a tribe and h = 6 if any repeatable shop concentrator is in the pool. Under the recommended schedule refunds through paid refreshes are finite; this limits length. Also, *first proposed in economy-engines.md G3:* no effect makes a Bought unit return 3 gold or more in the turn it was bought (refund plus sell value). A per-action engine that returns gold is checked by this Λ test, and one that returns free refreshes by G8. *Replaces:* economy-engines.md's h × net ≤ half the top refresh price (the top price has no cap under the recommended schedule), and effect-taxonomy.md's "at most 2 gold-equivalent per action, or a limiter".
- **G4. Created units never sell for gold.** *First proposed in economy-engines.md G4.* Keep rulebook 4.3.3 as a load-bearing anti-loop rule. Card text that sets a sell value applies only to Bought units, unless the card passes G2 with the Created copies counted. *Risk:* with Battlegrounds sell values, two golden Rogers + Hoggarr is unbounded under every capped schedule (stress_rogers_hoggarr_bgsell, section 3.9).
- **G5. Set, don't add:** free-refresh grants are states ("your next 2 Refreshes are free") that a second grant or a retrigger re-sets, not adds to, or they carry a per-turn cap. The same holds for "gain N gold" under retriggers. Also, *first proposed in economy-engines.md G5:* Battlecry, spell and end-of-turn retriggers don't stack with each other on economy effects; two doublers give one extra trigger, not three. *Tested:* golden Brann + Anomaly goes from 30 (p90 53) to 22 (p90 24) [data: section 3.6].
- **G6. Copy and repeat effects carry a per-turn cap.** *First proposed in economy-engines.md G6.* Every "get a copy", "cast an extra time" or "trigger again" effect that can fire in the Recruit Phase carries a per-turn cap, or excludes gold and free-refresh effects by its text. *Risk:* an uncapped copy-on-cast aimed at a gold spell is an instant infinite; every copy-on-cast in Battlegrounds' library has a cap (economy-engines.md §4.9). G12 applies this to spells.
- **G7. Free refreshes:** a free-refresh grant with no retrigger and a cost of about one unit may reach b = 0.35 [data: b035_free_src passes]. Anything else is checked by Λ (length) and the Monte Carlo (G10), not by gross b. *Replaces:* economy-engines.md's b ≤ 0.5. Its outright ban on "After you refresh, gain a free Refresh" is covered by G8: such a source needs a per-turn cap.
- **G8. Every repeatable refresh source other than the paid Refresh carries a per-turn cap printed on the card.** That covers effect refreshes ("Refresh the Tavern" after a buy, sell, play or cast), conditional free refreshes ("free while…", "after you play an X, gain a free Refresh"), free-refresh grants, and shop concentrators ("Refresh the Tavern with minions of one type": one-off or once a turn, as economy-engines.md G8 proposed). The exception is a source whose net cost per shop on the strongest plausible board is at least 3 gold. *Risk:* Golganneth + Hoggarr + golden Rogers is unbounded under every schedule; Pigeon Lord + golden Rogers runs 34 (p90 48) [data: section 3.5].
- **G9. Refreshes paid in Health or at a cut price are paid refreshes.** *First proposed in economy-engines.md G9.* Any use of the Refresh action the player pays for, whatever it costs, counts toward the price steps. Only free refreshes granted by an effect and effect refreshes don't (rulebook delta 3 below).
- **G10. Record turn length:** *Deferred (owner direction, top of this doc).* The numbers are turn-length targets. At a 30-gold bank, loop policy, median ≤ 30 and p90 ≤ 45 for the strongest plausible package; median ≤ 45 for ceiling packages; finite at every bank. Run at tier 6, and at tier 4 for sources of tier 4 or lower. Every economy, scaling or engine card's review records this, and the pool's top packages are re-run whenever a card or modifier is added (economy-engines.md G10). A new source of free cards, spells or refreshes (E40–E44, E52) is checked against every engine its free inputs feed (effect-taxonomy.md §7.5). *Not settled under reading B:* an additive engine plus a rate engine at its limit breaks the median of 30 (section 4.2).
- **G11. One loop budget per board, not per lobby.** Λ (length) ≤ 0.5 for the strongest combination one board can assemble from the pool. *How many engines fit:* rates combine as 1 − (1 − r₁ − r₂)(1 − b₁ − b₂) + (h₁ + h₂)/3, so two engines at Λ ≈ 0.25 come to about 0.44–0.5 and fit, and three don't. So every tribe can have one strong engine at about Λ 0.25 ("everybody has them"), provided no board can hold more than two at once. **That proviso is untested:** no package in the model combines three tribes' engines. It is a content requirement that tribe-locked engine text must enforce, with the board rule and lobby tribe restriction (economy-engines.md, Blizzard pattern 5). Neutral enablers such as Brann count against every tribe's engine.
- **G12. Tavern spells never escalate, and gold-giving spells are capped per turn.** *Risk:* if spells are the late sink (B6), a 0-cost or gold-returning spell with a copy effect is an r ≥ 1 loop. Every copy-on-cast in today's library has a per-turn cap (economy-engines.md §4.9).
- **G13. Long-turn engines are additive** (only if the owner picks reading B, section 4.2). *Deferred (owner direction, top of this doc).* An engine meant to lengthen the turn gives a fixed number per turn ("Start of turn: gain 4 free Refreshes"), or carries a per-turn cap ("up to 4 times a turn"). The best board's additive total is about 8–10 shops a turn. *Source:* section 3.3; additive engines are the only shape that gives 20 shops on a normal turn and stays near 30 on a banked one. **Not settled:** on a board that also has a rate engine at the G2 or G7 limit it breaks G10 (section 4.2).
- **G14. No lobby modifier removes the paid Refresh, makes refreshes free, or sets a flat shop price.** *Risk:* Golganneth's Tempest turns every player's turn into flat 1-gold shops (59 from 60 gold with no engine) and makes the Hoggarr lines run 100–220 shops or forever.

**Rulebook deltas proposed** (for rulebook-deltas.md; not written into the rulebook):
1. **4.4.2 / 4.4.3:** *Deferred (owner direction, top of this doc).* add the tail: from the 31st paid refresh, the price rises by 1 every 5 paid refreshes, with no cap. Thresholds and step stay tunable (Appendix A).
2. **4.2.5:** Tavern spell prices are fixed for the turn; only the paid refresh escalates.
3. **4.4.5, by source.** *Counts toward the steps:* every use of the Refresh action the player pays for, whatever pays: gold, Health (a hero power that pays in Health), or a price lowered by a card or modifier. *Doesn't count:* free refreshes granted by an effect (4.4.5) and effect refreshes (4.4.6). (G9; economy-engines.md §8 rule gap 1.)
4. **4.4.6:** keep effect refreshes free and uncounted, and add: "A card or modifier that refreshes the shop each time the player buys, sells, plays or casts must state a per-turn limit (G8)." Counting them toward the steps was considered and rejected: when the buy is the price (Golganneth), the escalating price is never paid, so counting changes nothing.
5. **How price modifiers combine with escalation** (*first proposed in economy-engines.md §8*). A hero like Millhouse ("Refreshes cost 2 Gold") or a "(1) less" effect needs an order: step price first, then additions, then reductions, floor 0.
6. **Golden retriggers under 7.3.5** (*first proposed in economy-engines.md §8*). Golden doubles the *extra* triggers, so "trigger twice" becomes three times, as Battlegrounds' golden Brann does. Read as four times, golden Brann + Anomaly runs 37 shops (p90 86) at 30 gold instead of 30 (p90 53) (stress_brann_x4, section 3.4).
7. **9.10.2 doesn't catch player-driven loops** (*rule gap from economy-engines.md §8; no delta proposed*). The 1,000-trigger limit is per action, so a loop of refresh, buy and sell clicks never reaches it. With no timer, only this list stops such loops.

---

## 8. Player experience

All of this section is **[judgement]**, except where marked. The owner asked to be asked about feel; questions are in section 9.

**What a 20–30-shop turn is like.**
- 25 shops is about 175 cards to look at. At the model's 4 seconds a shop plus 1.5 seconds an action, a strong engine turn of 20–30 shops takes about 2.5–5 minutes [data: minutes columns, bound_summary.csv]. With async fights against snapshots (rulebook 2.1.4), nobody else waits.
- The price steps give the turn a shape. The first 10 shops are cheap and quick. Shops 11–20 cost twice as much and the player starts to choose. From 21 each refresh is a real decision, and under the tail, past 30 the player feels the end coming.
- **Clicks set the length more than shops do.** Two golden Rogers + Hoggarr at 30 gold is about 28 shops but 436 actions, about 11 minutes (p90 24) [data]. Each Bounty is a cast and each Created unit a play and a sell. A turn of many cheap actions is the "lots of small actions" flavour; past a few minutes it becomes chores.
- **The risk is tedium, not infinity.** A turn of 50+ shops is long enough to stop being fun. With no timer, a player who can keep going will feel they must. The 90th-percentile limit matters as much as the median for this reason.

**Over a whole game.** A game has about 6–8 late rounds after tier 6 [judgement from economy_timeline.csv: tier 6 by turn 8–10]. If an engine player's late Recruit Phase is 3–5 minutes each round, that is 20–40 minutes of recruiting on top of fights. That may be fine for a solo-paced async game, but it is the owner's call (question 6).

**Hand and board clutter.** Rogers lines gain 9–112 units a turn (bought plus Created), plus their Bounties [data: units columns]. The 10-card hand fills fast, and a card gained into a full hand is lost (7.1.2). Created units can't be sold from hand (4.3.7), so the player plays and sells each one, for 0 gold. That needs an empty board slot, and the model assumes a full board: the player has to keep a slot empty or sell a board unit to make one, and either costs combat power. The model doesn't count that cost. It counts the plays and sells as clicks, not as a bound on gold: a player who clears the hand never runs out of room.

**How "set, don't add" reads.** A second Anomaly, or golden Brann, appears to do nothing while two free refreshes are waiting. That can feel like a bug. The UI should show "Next 2 refreshes free" as a state, and the card text should say "Set your free Refreshes to 2", not "Gain 2". A per-turn cap ("up to 2 a turn") reads more naturally but needs a counter on screen.

**An engine turn should be longer than a banked turn.** Today it isn't: a player who saves two turns sees 30 shops with no engine, more than most engines see on a normal turn [data: section 3.2]. Under reading B (section 4.2) the engine adds a fixed 8–10 shops a turn, so the engine turn is the long one and the player can feel it.

**Escalation rewards spending each turn.** The refresh price is convex within a turn: two 15-gold turns buy 24 shops, one 30-gold turn buys 20 [data: arithmetic, 1/2/3 at 10/20]. So banking costs shops as well as fights. That is a good pacing push: it keeps carry-over for saving up to a big buy, not for hoarding refreshes.

**What it is like without an engine.**
- A no-engine player at tier 6 sees 6–12 shops from a normal turn [data: section 3.2]. The escalation barely shows; the tail never does.
- Late gold still buys something: spells at a steady 1.7–2.0 SP per gold [data].
- The gap is in stats, not shops: strong Rogers makes about 5× the SP from the same gold. Its size is B8's question.

**Tools for long turns** [proposal, for the UI backlog]: show the next refresh price and when it next rises; "refresh until a target appears" (with a gold limit); auto-cast Bounties; auto-sell Created units with no keep value; a running count of free refreshes waiting. Each one cuts clicks without changing the economy.

---

## 9. Questions for the owner

1. **Is "about 20–30 shops" a ceiling for banked turns, or also a floor for the best engines on a normal turn?** Today a strong engine on a normal 10–14-gold turn sees 8–17 shops, and banking two turns gives 30 with no engine. If you want the floor, the long-turn engines should give a fixed number of shops per turn (G13), because no gold-back or free-refresh rate can reach 20 on a normal turn and stay near 30 on a banked one. The floor also decides a limit that doesn't fit yet: an additive engine plus a rate engine at its limit gives 37–42 shops from 30 gold, over G10's median of 30 (section 4.2). If 20–30 is a ceiling only, G13 isn't needed and the problem goes away; if it is also a floor, something has to give (lower rates beside an additive engine, one shared budget, or a higher banked-turn median). *Deferred (owner, 2 Nov): for later power budgeting.*
2. **Effect refreshes ("Refresh the Tavern" after a buy, sell, play or cast) are free and don't count toward the steps. Should every repeatable one carry a per-turn cap on the card (widened G8), and should lobby modifiers be barred from removing the paid Refresh (G14)?** Golganneth's Tempest with Hoggarr and golden Rogers is unbounded under every price schedule.
3. **Do you accept the uncapped tail (from the 31st paid refresh, +1 gold every 5)?** It changes no turn of 30 paid refreshes or fewer. A cap at 5 leaves refund loops open; doubling acts as a wall at about 40–50 shops. *Deferred (owner, 2 Nov): for later power budgeting.*
4. **Should one turn's stats from an engine have a limit (B8)?** Two golden Rogers pass every shop limit and still make about 900 stats from 30 gold; with Hoggarr, about 3,100.
5. **How long can one Recruit Phase take before it stops being fun: 3 minutes, 5, 10?** The model's strong engine turns run 2.5–5 minutes; the ceiling Rogers + Hoggarr turn about 11 (p90 24), mostly clicks. Your answer sets the 90th-percentile limit better than the model can. *Deferred (owner, 2 Nov): for later power budgeting.*
6. **How long may a whole game take?** A 3–5 minute Recruit Phase in each of 6–8 late rounds adds 20–40 minutes. *Deferred (owner, 2 Nov): for later power budgeting.*
7. **Do you want quality-of-life tools for long turns** (auto-cast Bounties, auto-sell Created units, refresh-until), or should clearing the hand by hand stay part of the cost?
8. **For free refreshes under retriggers: "set, don't add" (Brann and a second copy add nothing while refreshes are waiting), or a per-turn cap on each card?** Both pass the test (section 3.6). The first keeps cards short; the second reads more naturally.
9. **Should Tavern spells be the late-gold sink (B6), with fixed prices and a spell in every tier-5 and tier-6 shop?** B5's gold prices depend on it (power-budget.md 4.1).
10. **When Λ (length) and the Monte Carlo disagree, which governs?** Two golden Rogers + golden Privateer + Hoggarr has Λ 0.77, over the ceiling limit of 0.75, but a median of 39 shops at 30 gold, under the ceiling median of 45 (section 4.3). As written, a board must pass both, so it fails. *Deferred (owner, 2 Nov): for later power budgeting.*

---

## 10. Limits

- **One player, one turn.** No opponents, no triples made during the turn, no board-space limit on Created units. The hand is modelled as clicks, not as a limit.
- **Shop contents are averages.** A fixed 20% tribe share, a uniform Bounty pick, a 25% chance of a useful unit. Bramble's pool will differ.
- **Two scripted policies, not an optimiser.** A real player mixes them, and may stop refreshing to bank gold (4.1.2). The "smart" rule (buy a refresh-giving unit only when it costs no more than the next paid refresh) is used only for Sticker and Pigeon Lord.
- **Lower tiers** use tier-6 spell values and useful-unit odds; only shop size and engine-source shares change.
- **The SP figures use card text at face value.** Bounty buffs dominate the Rogers numbers. Whether those are fair is the power budget's job (B8).
- **Golden Brann is ×3.** Rulebook 7.3.5 may make it ×4 (stress_brann_x4).
- **Time per shop and per action are guesses** (4 and 1.5 seconds).
- **The B5 check reuses the main model** (`econ_break_even`), with all its limits ([power-budget-review.md](power-budget-review.md) §11). Only the late sink changes.
- **Monte Carlo noise** is up to about 3 shops between cells; the 90th percentiles are noisier.

## 11. Review notes (revision 2)

What changed after the critic's review of revision 1, and what was declined.

- **Taken:** the floor check (sections 1, 3.2, 3.3); effect refreshes and conditional free refreshes as packages (3.5); Λ at the target-length price (2, 4.3); tests of G5 and of b = 0.35 (3.6); bounding shops vs power (4.4, B8); the cap-5 claim now cites the loop policy (4.1); G2's spend-for-free-refresh case and a "free" spend kind; the board rule and a generic `board` kind with `bound check`; G11 per board, with how many engines fit; the tier-3 and tier-4 check (3.8); delta 3 reworded by source; R3 reconciled (header); the one-off gold fix split from B5 and the marginal 1.6 sink added (6); the average-player claim softened (4.1); the player-experience gaps (8).
- **Taken in part: the hand limit.** It is modelled as clicks (actions and minutes), not as a bound on gold. A player can always clear the hand by casting Bounties and playing and selling Created units through an empty board slot, so the hand limits time, not the loop. Keeping that slot empty costs a board slot of combat power, which the model (full board) doesn't count. A player who doesn't clear it loses gained cards (7.1.2), which only shortens the turn.
- **Taken in part: a per-turn SP limit for engines.** Named as open point B8 for the power budget with data and a starting figure, not as a guardrail, because SP per gold needs the combat link the power budget has and this model doesn't.
- **Not modelled: Battlecry effect refreshes multiplied by Brann**, because only the last refreshed shop is usable (section 2).
