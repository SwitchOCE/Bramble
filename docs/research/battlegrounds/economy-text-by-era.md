# Battlegrounds economy text by era

How much of the Hearthstone Battlegrounds (HSBG) pool carries economy text, by era, tier and tribe, how big those effects are, and what the current patch looks like. The last section is a one-page summary of what a good budget looks like in HSBG.

This fills one gap in [power-analysis.md](power-analysis.md). That page covers stats per tier, what text costs in stats, and power creep. It does not count economy text over time. Read it first; this page does not repeat it.

*Compiled 2 November 2026 from the 83 monthly pool snapshots (Dec 2019 to Oct 2026). Every number is in [analysis/economy_text_by_era.csv](analysis/economy_text_by_era.csv). The script that made it (`econ_by_era.py`, standard library only) is not yet in `tools/research/`; the classification rules are in section 1 so the CSV can be audited.*

Labels: **[data]** comes from the card library or a cited source. **[judgement]** is my reading.

## Headline findings

1. **The share of minions with economy text rose fourfold, from 6% to 26%.** [data] It rose in every era: 6% (2019–21), 11%, 13%, 18%, 22%, 26% (Season 14, now). Most of the rise is card generation (get a minion, get a Tavern spell), not gold.
2. **Gold, refresh and discount text on minions stayed rare and small.** [data] "Strict" economy (gold, free or cheaper refreshes, cost and tier-up discounts) peaked at about 6% of minions in 2023–25 and is 3.7% now: 10 of 273 minions. The median effect is **1 gold** in every era. The largest single trigger ever printed is about 4 gold (Tortollan Blue Shell, Snarling Conductor).
3. **Economy moved off minions and into systems that every player gets.** [data] Now: 38% of Tavern spells carry economy text (14% strict), about half of all trinkets (6–9% strict), and 53 of 123 hero powers (14 strict). Spells price economy at about gold parity: "get a random minion" costs 2, "Discover a minion" costs 3, "gain 2 Gold" costs 2.
4. **Economy text lives low in the tiers, and gold text never reaches Tier 6.** [data] Strict economy is 0% at Tiers 5–7 now and at most 4% at Tier 6 in any era. High tiers give cards, not gold. Broad economy peaks at Tiers 3–4 (36%).
5. **Gold-spent engines are about 1 card in 100, and none returns as much as it costs.** [data] "After you spend N Gold" cards that pay out economy are 1–2 per pool. The best single-card return is about 0.3–0.4 gold-equivalent per gold spent, 0.6–0.75 golden (Fleet Admiral Tethys). Blizzard raised Tethys's threshold twice (8 → 9 → 10). Loops come from stacking several sources, not from one card. [judgement]
6. **Pirates are the economy tribe in every era.** [data] Pirates carry economy text on 28–49% of their minions. Their gold text has given way to card generation in Season 14 (strict 27% → 4%).

---

## 1. Method

**Pool.** Each monthly snapshot's minion pool and Tavern spell pool, from `tools/research/.cache/slim/` (built by `build_bg_library.py`; not committed). 2019–2020 pool membership is heuristic (see power-analysis.md). Duos-only cards (30 names) are left out, and so are effects that only give the teammate something. Trinkets have no pool flag, so section 6 groups every trinket in the data by the season it first appeared.

**Eras** follow [patch-history.md](patch-history.md), assigned by client version:

| Era | Versions | Sampled builds | What changed for economy |
|---|---|---|---|
| E1 Launch to revamp | 16.0–21.0 (Dec 2019 – Jul 2021) | 20 | 4 → 8 tribes; Pirates bring the first gold text |
| E2 Revamp, armor, Buddies | 21.2–23.0 (Aug 2021 – Apr 2022) | 8 | 37-card rotation; Avenge |
| E3 Seasons 1–5 | 23.2–27.x (May 2022 – Nov 2023) | 19 | Naga and Spellcraft, Quests, Undead, gold can exceed 10 |
| E4 Tavern spells, Duos, trinkets | 28.2–34.0 (Dec 2023 – Nov 2025) | 25 | Spells in the shop; trinkets twice |
| E5 Timewarp, Tavern Coins | 34.2–36.0 (Dec 2025 – Jul 2026) | 8 | Gold effects reprinted as Tavern Coins |
| E6 Dark Gifts, Activate | 36.2–37.0 (Aug – Oct 2026) | 3 | Activate (pay gold to use); 96 minions rotated out |

"Current" is build 255790 (patch 37.0.0, 26 Oct 2026).

**What counts as economy text.** Regular expressions on the rules text, per sentence. The kinds:

| Kind | Examples | Gold-equivalent per trigger |
|---|---|---|
| Gold | "gain 1 Gold", Gold or Tavern Coins, "increase your maximum Gold by 1", "sells for 3 Gold" | the number (sell price minus the normal 1) |
| Refresh | "gain 2 free Refreshes", "your next Refresh costs (0)", "two Refreshes each turn cost Health", "Refresh the Tavern with…" | 1 per refresh |
| Cost | "costs (1) less", "costs Health instead of Gold" | the discount; 3 for a minion, 2 for a spell |
| Tier-up | "reduce the Cost of upgrading the Tavern by (1)" | the discount |
| Card: minion | get, Discover or steal a minion, a copy, a token body | 3 (one buy saved) [judgement] |
| Card: spell | get or Discover a Tavern spell, or a named pool spell | the spell's cost; 2 if random (median current cost) [data] |

- **Strict economy** = gold, refresh, cost or tier-up. **Broad economy** = strict plus card generation.
- **Not counted:** Blood Gems and other non-shop stat tokens (counted separately as `share_stat_token`); spells cast automatically ("cast Shiny Ring"), which are stat effects; shop insertion ("add a Fodder to your next Refresh"); triggers that only mention gold ("after you spend 5 Gold, give your Pirates +2 Attack").
- **Trigger class** of the economy sentence: one-shot (Battlecry, sell, Choose One), per turn (start or end of turn, Deathrattle, Avenge, Rally, Spellcraft, "once per turn"), repeatable within a turn (after you buy, sell, cast or spend, uncapped), Activate, or static.
- **CSV layout.** One row per group. `section` is `era`, `current`, `build` (monthly series) or `trinket_cohort`. `card_kind` is minion, spell, all or trinket; `group_type` is total, tier, tribe, build or size. `econ_share` is broad, `strict_share` strict; `share_<kind>` is the share of the group with that kind; values are gold-equivalent per trigger.
- **Audit.** I read every classified card in E6 and about half of E2–E4. Known errors are small: conditional multipliers ("repeat for each other Pirate") count once, so sizes are under-stated; Choose One options are exclusive, so their value is halved; a few named Spellcraft spells are valued as Tavern spells.

## 2. Share of the pool by era

Mean over the sampled builds in each era. Shares are of all cards of that kind. Source: CSV rows `section = era`, `group_type = total`.

**Minions**

| Era | Minions per build | Broad | Strict | Gold | Refresh | Cost + tier | Card: minion | Card: spell | Repeatable + Activate | Distinct broad / strict cards |
|---|---|---|---|---|---|---|---|---|---|---|
| E1 2019–21 | 123 | 6% | 2.8% | 1.8% | 0.5% | 0.6% | 3.4% | 0% | 0.6% | 13 / 7 |
| E2 2021–22 | 145 | 11% | 5.4% | 2.8% | 1.9% | 1.2% | 5.6% | 0% | 1.4% | 17 / 8 |
| E3 2022–23 | 183 | 13% | 5.3% | 3.4% | 1.3% | 1.2% | 7.3% | 0.7% | 1.2% | 47 / 19 |
| E4 2023–25 | 228 | 18% | 5.7% | 3.5% | 1.4% | 1.2% | 8.2% | 4.7% | 0.9% | 111 / 32 |
| E5 2025–26 | 242 | 22% | 4.7% | 2.8% | 1.1% | 0.8% | 8.7% | 8.4% | 0.8% | 85 / 19 |
| E6 2026 | 265 | 26% | 4.0% | 2.1% | 1.5% | 0.4% | 12.0% | 10.3% | 3.4% | 83 / 11 |
| **Current** | **273** | **26%** | **3.7%** | 1.8% | 1.5% | 0.4% | 12.1% | 10.6% | 3.3% | 71 / 10 |

**Tavern spells** (from Dec 2023)

| Era | Spells per build | Broad | Strict | Gold | Refresh | Card: minion |
|---|---|---|---|---|---|---|
| E4 | 53 | 40% | 15% | 10% | 5% | 23% |
| E5 | 66 | 37% | 13% | 8% | 5% | 23% |
| E6 / current | 73 | 38% | 14% | 10% | 4% | 22% |

**Minions and spells together, current:** 99 of 346 shop cards carry economy text (29%); 20 carry strict economy (6%). [data]

**Monthly trend** (minions; CSV rows `section = build`):

| Date | Broad | Strict |
|---|---|---|
| Dec 2019 | 1% | 0% |
| Dec 2020 | 9% | 4% |
| Aug 2021 | 11% | 6% |
| Aug 2023 | 16% | 6% |
| Dec 2024 | 19% | 7% (peak) |
| Aug 2025 | 19% | 3% |
| Apr 2026 | 22% | 5% |
| Oct 2026 | 26% | 4% |

Reading: broad economy rose in a straight line with the pool's growth in card-generation text. Strict economy rose to a plateau of 5–6% by 2021 and has drifted down since the Tavern Coin reprint (Dec 2025) and the Season 14 rotation (Aug 2026). [data]

## 3. By tier

Broad / strict share of minions at each tier. Source: CSV `group_type = tier`.

| Tier | E1 | E2 | E3 | E4 | E5 | E6 | Current |
|---|---|---|---|---|---|---|---|
| 1 | 10 / 7% | 17 / 11% | 20 / 14% | 14 / 10% | 15 / 9% | 14 / 8% | 12 / 8% |
| 2 | 3 / 3% | 4 / 4% | 10 / 5% | 18 / 6% | 19 / 8% | 23 / 3% | 22 / 3% |
| 3 | 3 / 3% | 7 / 7% | 12 / 7% | 15 / 6% | 17 / 4% | 33 / 8% | 36 / 7% |
| 4 | 3 / 0% | 13 / 3% | 13 / 3% | 23 / 9% | 31 / 9% | 35 / 7% | 36 / 6% |
| 5 | 16 / 4% | 12 / 4% | 16 / 5% | 23 / 4% | 24 / 1% | 25 / 0% | 25 / 0% |
| 6 | 4 / 0% | 15 / 4% | 11 / 0% | 15 / 0% | 20 / 0% | 17 / 0% | 17 / 0% |
| 7 | — | — | 15 / 0% | 16 / 0% | 16 / 0% | 16 / 0% | 15 / 0% |

- **Gold text is a low-tier job.** [data] Tier 1 has carried the highest or joint-highest strict share in every era (7–14%). Tiers 5–7 carry almost none. What high tiers print is card generation ("get a random Tier 6 minion", "Discover two Tier 6 minions") and gold-spent engines.
- **Broad economy has moved to the middle.** [data] Tiers 3–4 went from 3% (E1) to 36% now. Those are the tiers where mid-game engines are bought.

## 4. By tribe

Broad / strict share of each tribe's minions (dual types count in both). Source: CSV `group_type = tribe`.

| Tribe | E1 | E2 | E3 | E4 | E5 | E6 | Current |
|---|---|---|---|---|---|---|---|
| Pirate | 28 / 21% | 34 / 27% | 29 / 25% | 29 / 20% | 28 / 15% | 49 / 7% | 46 / 4% |
| Naga | — | — | 19 / 10% | 36 / 12% | 28 / 10% | 32 / 9% | 32 / 9% |
| Elemental | 33 / 8% | 38 / 15% | 33 / 13% | 25 / 7% | 28 / 5% | 17 / 4% | 23 / 4% |
| Demon | 3 / 3% | 8 / 8% | 12 / 7% | 23 / 13% | 17 / 11% | 20 / 9% | 22 / 9% |
| Mech | 0 / 0% | 0 / 0% | 6 / 2% | 19 / 4% | 32 / 7% | 28 / 4% | 29 / 4% |
| Murloc | 10 / 0% | 10 / 0% | 14 / 0% | 15 / 0% | 26 / 0% | 33 / 0% | 23 / 0% |
| Dragon | 8 / 0% | 8 / 0% | 15 / 1% | 16 / 0% | 17 / 0% | 21 / 0% | 18 / 0% |
| Quilboar | 0 / 0% | 0 / 0% | 0 / 0% | 6 / 3% | 12 / 1% | 24 / 8% | 20 / 8% |
| Undead | — | — | 7 / 5% | 8 / 2% | 15 / 1% | 15 / 0% | 17 / 0% |
| Beast | 0 / 0% | 0 / 0% | 0 / 0% | 3 / 2% | 6 / 2% | 14 / 4% | 14 / 4% |
| Aberration | — | — | — | — | — | 35 / 0% | 36 / 0% |
| Untyped | 1 / 1% | 8 / 2% | 14 / 2% | 21 / 5% | 26 / 4% | 35 / 4% | 38 / 4% |

- **Every tribe now has some economy text.** [data] Beasts and Quilboar had none for four years; now every tribe is at 14% or more broad. This matches the owner's reading that "everybody has them" now. It is true for broad economy. For strict economy it is not: Murlocs, Dragons, Undead and Aberrations have no gold, refresh or discount text at all.
- **Each tribe has one economy flavour.** [data] Pirates: gold and gold-spent engines. Elementals: refreshes and Elementals from selling. Demons: Health instead of Gold. Naga: Spellcraft and Tavern Coins. Murlocs and Dragons: random tribe cards. Aberrations: discard-to-get. Quilboar: Blood Gems (counted as stat tokens, not economy).
- Pirates' strict economy fell from 27% to 4% in Season 14. Their newer cards pay in Lockboxes, Bounties and Golden minions instead of gold. [data]

## 5. Size of the effects

**Strict economy, gold-equivalent per trigger** (minions): median **1** in every era. [data] The largest single triggers:

| Era | Largest strict triggers | Size |
|---|---|---|
| E1–E2 | Soul Devourer (consume a Demon: +3 Gold); Freedealing Gambler (sells for 3) | 2–3 |
| E3 | Tortollan Blue Shell (sells for 5 after a loss); Time Saver (sells for 3 more) | 3–4 |
| E4 | Snarling Conductor (start of turn: discard a spell for 4 Gold); Record Smuggler (start of turn: 2 Gold, +2 with three Pirates) | 4 |
| E5 | Industrious Deckhand (start of turn: 2 Tavern Coins); Refreshing Anomaly (2 free Refreshes) | 2 |
| E6 | Tortollan Blue Shell; Private Investigator (Activate (1): 3 Gold next turn, Aug–Sep 2026) | 3–4 |

**How often they fire.** [data] Strict economy that fires every turn or more often was 1.5% of minions in E1, about 3% in E2–E5, and 0.7% now. In E4 half of the strict cards (16 of 32) were per-turn income; now 8 of 10 are one-shots. The current patch has moved recurring gold off minions and into spells, trinkets and hero powers.

**Gold-spent engines** ("after you spend N Gold" or "after you buy …" that pay out economy):

| Card | Tier, tribe | In pool | Threshold | Payout | Return per gold spent: normal / golden |
|---|---|---|---|---|---|
| Cap'n Hoggarr | 5, Pirate | Jun 2020 – Apr 2023; now a hero power | buy a Pirate (3 Gold) | 1 Gold | 0.33 / 0.67 |
| Fleet Admiral Tethys | 6, Pirate | May 2023 – Nov 2024, Dec 2025 – Mar 2026 | 8 → 9 → 10 Gold | a random Pirate (3) | 0.38 → 0.30 / 0.75 → 0.60 |
| Sky Admiral Rogers | 6, Pirate | Aug – Nov 2025, Apr 2026 – now | 10 → 9 Gold | a random Bounty (2; one of five is "Gain 2 Gold") | 0.20–0.22 / 0.40–0.44 |
| Enterprising Escapee | 5, Pirate | Aug 2026 – now | 5 → 6 Gold | a Lockbox (a Golden minion in 5 turns; one at a time) | ≤ 0.6, delayed / not measured |
| Air Revenant | 5, Elemental | Dec 2025 – now | 7 Gold | Easterly Winds (a 1-cost spell), later cast automatically | 0.14, then stats only |
| Kael'thas (hero power) | — | now | buy 3 minions (9 Gold) | a Tavern Coin | 0.11 |

Sources: dump of the snapshots ([data]); golden doubles the payout and keeps the threshold (power-analysis.md section 3).

- **No single card returns as much gold as it costs.** [data] The best normal return is about 0.38; golden about 0.75.
- **Blizzard tunes these by the threshold**, one gold at a time: Tethys 8 → 9 → 10, Rogers 10 → 9, Escapee 5 → 6, and Gunpowder Courier (a stat engine) moved between 4, 5 and 6. [data] That is the same ±1 lever power-analysis.md section 5 found for stats.
- **Loops need stacking.** [judgement] Going "infinite" with Tethys or Rogers needs several sources at once: golden copies, Pirates that make gold or Tavern Coins, Wealthy Bounties, hero powers. No one card's text shows it. A budget that checks cards one at a time won't catch loops; a guardrail on combinations is needed (content-guardrails.md G1 does this for free refreshes).

## 6. Spells, trinkets and hero powers

**Tavern spells price economy at about gold parity.** [data] Current pool, cost against gold-equivalent:

| Spell | Cost | Effect | Net gold-equivalent |
|---|---|---|---|
| Tavern Coin | 1 | Gain 1 Gold | 0 |
| Wealthy Bounty | 2 | Gain 2 Gold | 0 |
| Careful Investment | 1 | Gain 2 Gold next turn | +1, delayed |
| Overconfidence | 1 | Gain 3 Gold if you win your next combat | +2, conditional |
| Corrupted Coin | 2 | Gain 2 Gold; discarded, +2 maximum Gold | 0 to +2 |
| Strike Oil | 3 | Increase your maximum Gold by 1 | −2 now, +1 a turn after |
| Leaf Through the Pages | 1 | Gain 2 free Refreshes | +1 |
| Recruit a Trainee, Friendly Bounty, Enchanted Lasso | 2 | Get a random minion | +1 |
| A New Sprout, Hired Headhunter, Contracted Corpse | 3 | Discover a minion | 0 |
| Hallowed Ritual | 5 | Discover a Tier 7 minion | −2 |

A random minion card is priced at 2 Gold and a Discovered one at 3. Gold-for-gold spells are neutral; their value is moving gold to a later turn, or feeding "spend" and "cast" triggers. [judgement]

**Trinkets** (every trinket in the data, by the season it first appeared; no pool flag exists; Duos-only left out):

| Cohort | Trinkets | Broad | Strict | Strict examples |
|---|---|---|---|---|
| Season 8 (Aug–Nov 2024) | 137 | 41% | 6% | Bob's Tip Jar (Gain 4 Gold, +4 maximum Gold), Goblin Wallet (+1 maximum Gold each turn), Bartend-o-Tron's Oilcan (tier-up −3 each turn) |
| Season 10 (Apr–Jul 2025) | 107 | 49% | 9% | Worn Treasure Map, Ornate Clock |
| Season 13 (Apr–Jul 2026) | 88 | 52% | 9% | Stuffed Coin Purse, Cowrie Necklace |
| Season 14 (Aug–Oct 2026) | 77 | 47% | 9% | Glowing Crystal, Trickster's Sleeve |

Half of trinkets generate cards, many as "Portraits" that give a named minion plus a buff. The strict ones are where HSBG prints its biggest gold: Bob's Tip Jar is worth 8 Gold on the turn plus 4 a turn after, far above any minion. [data] Trinkets are offered to every player twice a game, so this is economy everybody gets. [judgement]

**Hero powers** (current, hand-checked from [data/heroes.json](data/heroes.json)): 53 of 123 have economy text in the broad sense; 14 give gold, refreshes or discounts directly (for example Forest Lord Cenarius: +1 maximum Gold; Nozdormu: a free Refresh each turn; Snake Eyes: roll a die for Gold). [data]

**Not measured:** Dark Gifts (Season 14), Quest rewards, Buddies, Anomalies and Darkmoon Prizes. These also carry economy in their seasons. [data gap]

## 7. The current patch (37.0.0)

- **Shop cards:** 99 of 346 (29%) carry economy text; 20 (6%) carry gold, refresh or discount text. [data]
- **Strict economy minions (10):** Southsea Busker (T1, gain 1 Gold next turn), Ominous Seer (T1, next spell −1), Shell Collector (T2, a Tavern Coin), Accord-o-Tron (T3, +1 Gold each turn), Malchezaar (T3, two Refreshes a turn cost Health), Sly Infiltrator (T3, Choose One: 2 free Refreshes), Refreshing Anomaly (T4, 2 free Refreshes), Snare Trapper (T4, Choose One: +1 maximum Gold), Snarky Shark (T4, sold: Refresh with a Fishbait), Tortollan Blue Shell (T4, sells for 5 after a loss). [data]
- **Trigger mix of economy minions:** 35 per turn, 27 one-shot, 6 Activate, 3 repeatable within a turn (Sky Admiral Rogers, Enterprising Escapee, Auto Reveille). [data]
- **Gold sinks:** 23 of 273 minions have Activate (pay 0–2 Gold to use). This is new in Season 14 and gives late gold somewhere to go. [data]
- **Free refreshes** on minions are all one-shots or capped per turn (Malchezaar: two a turn). No current minion gives a free refresh that repeats within a turn. [data] This is the shape [content-guardrails.md](../../design/content-guardrails.md) G1 asks for.

---

## 8. What a good budget looks like in Battlegrounds

One page, drawing on power-analysis.md and the sections above. Section numbers in brackets point to power-analysis.md.

**Price.**
- **The tier is the price.** Bodies rise about 1.75 stats per tier (4.5 at Tier 1 to 12.5 at Tier 6). Text explains only 15–27% of the stat spread within a tier. [data, §1–2]
- **Stats are charged for effects that act after the body is gone or make one fight harder:** Divine Shield, Reborn, Venomous, Magnetic and Deathrattles cost 11–27% of the tier budget. [data, §2]
- **Recruit-phase value is almost free in stats.** Economy, card generation and per-turn buffs cost −0.02 to −0.06 of the budget. These cards are paid for by tier and by being sold before the late fights. [data, §2]
- **Stats on spells are 2–3× cheaper per gold than stats on bodies.** A body buys a slot; the slot is the scarce resource. [data, §4]

**Economy.**
- **Lots of economy text, small effects.** About a quarter of minions and over a third of spells carry economy text now, but the median gold effect is 1 Gold and the biggest single minion trigger is about 4. [data, §2, §5 above]
- **Gold low, cards high.** Gold, refresh and discount text sits at Tiers 1–4. Tiers 5–7 pay in cards. [data, §3 above]
- **Economy is spread across systems, so every player has some.** Minions in every tribe, tribe-neutral spells, two trinket offers a game, and hero powers. [data, §4 and §6 above]
- **Shop spells price gold at parity.** A random minion card is 2 Gold, a Discovered one 3, "gain 2 Gold" costs 2. [data, §6 above]
- **Engines return less than they cost.** Gold-spent engines are about 1% of the pool and return at most about 0.4 gold-equivalent per gold (0.75 golden). Loops come from combinations. [data, §5 above]

**Growth.**
- **Printed stats barely crept; text did.** Tier means moved +0.5 to +1.5 stats in seven years. Scaling text went from 6% to 32% of the pool, and economy text from 6% to 26%. [data, §5; §2 above]

**Tuning.**
- **The levers are ±1–2 stats, ±1 tier, and ±1 on a threshold.** 760 stat changes: 209 moved 1 stat, 142 moved 2. Tier moves are about as common. Engine thresholds move one gold at a time. [data, §5; §5 above]
- **Golden = 2× body, 2× effect, 1× thresholds.** [data, §3]

**What HSBG accepts that Bramble can't.** [judgement] HSBG lets combinations go unbounded because the turn timer ends the turn. Bramble has no timer (rulebook 2.1.4, 3.1.2 deltas), and only the refresh action escalates. So the same density of economy text is safe in Bramble only if each source is small, recurring gold is capped per turn, free refreshes can't be repeated (G1), and gold-spent engines are checked as combinations rather than as single cards.

## 9. What this means for Bramble

All [judgement]. Each item points at an open decision; none decides it.

- **B2 (target economy level).** HSBG's current density is about 1 economy card in 4 and 1 gold-or-refresh card in 25 on minions, plus spells, trinkets and hero powers. A Bramble target can be set the same way: a share of the pool per tier and per tribe, not only a price per card.
- **B5 (re-price recurring economy).** Per-turn gold on HSBG minions is usually 1 Gold a turn (Accord-o-Tron, Briny Bootlegger). The 2–4 Gold-a-turn minions (Record Smuggler, Snarling Conductor, Industrious Deckhand, all Tier 4–5) each stayed in the pool 4–18 months. Bigger recurring gold sits on trinkets and hero powers, one per player. HSBG prints at most about 1 Gold a turn on minions as a rule, and 2–4 a turn only briefly. The gold caps Bramble uses are in [power-budget.md](../../design/power-budget.md) 4.1, their one home.
- **B6 (what late gold buys).** HSBG's answer in Season 14 is Activate: 8% of minions are gold sinks. Late cards pay out cards, not gold.
- **G1 and the 20–30 shop turn.** A per-card check of "return per gold spent" (section 5) is cheap: HSBG's single cards stay under 0.4 normal and 0.75 golden. Combinations still need the whole-turn check. The guardrails themselves, including the limit on gold back per gold, are in the one list in [economy-bounding.md](../../design/economy-bounding.md) §7 (owner, 2 Nov: "One list in bounding"); all are proposals awaiting the owner.

## Caveats

- **Regex classification.** Section 1 lists the rules. Conditional multipliers count once, so sizes are low. "Get a card" is valued at a flat 3 Gold whatever the card.
- **Pool membership, not lobby.** A lobby sees 5 tribes plus untyped cards, so a player in an economy-light lobby sees fewer economy cards than the pool share suggests. Current pool data still lists Naga, which patch-history.md says rotated out in 36.6.1; I used the data flag as is.
- **Historical text.** Minion and current spell text are per build. Spell text for Dec 2023 – Feb 2024 comes from the latest version, because those snapshots stored only spell ids.
- **Trinkets** are counted by first appearance, not by what was offered. Retired trinkets inflate the counts.
- **Economy share is not economy power.** One card with "+1 Gold each turn" in a lobby can matter more than five one-shot Discover cards. This page counts and sizes text; [budget-model](../budget-model/) prices it.

## Sources

- Card library: [data/minions.json](data/minions.json), [data/spells.json](data/spells.json), [data/trinkets.json](data/trinkets.json), [data/heroes.json](data/heroes.json), [data/builds.json](data/builds.json) (HearthstoneJSON, builds 38377 to 255790).
- Monthly snapshots: `tools/research/.cache/slim/` and token names from `tools/research/.cache/raw/` (both made by `tools/research/build_bg_library.py`, not committed).
- Eras and system changes: [patch-history.md](patch-history.md).
- Stat pricing, golden rule and tuning levers: [power-analysis.md](power-analysis.md).
