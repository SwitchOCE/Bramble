# Pigeon tuning, round 4 (4b on this branch)

**Every measurement in rounds 1–4 used TribeBot.** On 20 Nov the owner ruled it inadequate for balance and deprecated it ([owner note](../../../design/owner-notes/2026-11-20a-strong-bots-for-balance.md)). The tuning stands as a generous start until the league bots measure it.

**What this branch holds is round 4b: each of round 4's changes halved.** The designer's round 4 proposal is kept below as written. Measured on it, round 4 overshot, so the balance orchestrator halved it (a proposal, not decided).

| Card | Before | Round 4 | **Round 4b (this branch)** |
|---|---|---|---|
| Territorial (T1) | 4/5 | 6/9 | **5/7** |
| Old Campaigner (T2) | 4/7 | 7/11 | **6/9** |
| Grenadier Guard (T3), Guard post Renown | 2 | 4 | **3** |
| Lieutenant (T4), Attack | 5 | 12 | **9** |

Measured with TribeBot, 200 games per arm on the same 100 seed lines, league binary from dev 61601f2d. Placement out of 8, lower is better.

| Arm | Pigeon-locked | Mouse-locked | A/A: Badger | Briar | Locust | Mouse | Pigeon | A/A spread |
|---|---|---|---|---|---|---|---|---|
| Pre-rework (arm C) | 4.24 | 5.49 | | | | | | |
| Rounds 1–3 | 4.56 | 4.54 | 3.85 | 4.72 | 4.50 | 4.59 | 4.86 | 1.01 |
| Round 4 | 4.07 | 4.70 | 4.17 | 5.05 | 4.69 | 4.86 | 3.74 | 1.31 |
| **Round 4b** | **4.32** | **4.66** | **4.07** | **4.87** | **4.59** | **4.79** | **4.18** | **0.80** |

- Pigeon-locked, rounds 1–3 → 4b: −0.24 ± 0.07 (95%). Pre-rework → 4b: +0.08 ± 0.13, so level with before the rework.
- Each A/A tribe figure is about ±0.25. Round 4b has the tightest spread any arm has measured.

---


Proposed on top of rounds 1–3 at `37f5890d`. The aim is **4.2–4.3 Pigeon-locked** and **4.3–4.5 for Pigeon in A/A**, from 4.56 and 4.86 respectively. The pass deliberately gives early units oversized bodies and concentrates midgame growth in the Guard post. Greater damage and durability arrive before players routinely fill their Reserve. The placement targets are unmeasured. [Pigeon card data](/data/wt-m-tune/src/content/pigeon/units.json) · [Accepted rework pitch](/data/wt-m-new/docs/workstreams/reworks/pitch-pigeon.txt)

## Diagnosis

1. **Rounds 4–8 are the bottleneck.** In rounds 4–6 Pigeon won 36% of live fights in both runs. By the end of round 8, 213 of 800 locked seats and 92 of 318 A/A Pigeon seats had finished. Survivors won 56% locked and 55% in A/A from round 11 onward.
2. **The stat problem depends on the opponent.** In rounds 6–10 A/A, Pigeons lost 172 of 294 to Badger, with 95 starting Health to 135 in those losses. They lost 176 of 300 to Locust, which had less starting Health but more Attack and 3.4 additional bodies to Pigeon's 1.4 in those losses. In losses to Mouse they started at 63 Attack to 101 with nearly equal Health. Briar became the worst matchup from round 11, winning 66 of 86.
3. **Renown is working, but Reserve arrives too late to carry the weak rounds.** The locked front row held 18.5 of 19.7 total Renown in round 6. Across rounds 6–10, at least one hand reservist stepped in for 44% of locked and 40% of A/A fights. Only 12% in either run even held two eligible units. A third eligible unit was rare even with Quartermaster on the board.

These are seat-fights against live opponents. Locked comparisons use red seats against blue. A/A uses each seat's final main tribe and excludes Pigeon mirrors from fight comparisons. Mixed boards can qualify. Win and loss rates count draws in the denominator. Starting stats come from the recruit board before fight-start effects. Additional bodies are deaths plus survivors minus starters, including arrivals and returns. Reserve occurrence comes from combat logs, and eligibility comes from the recorded hand, including Quartermaster grants. [Locked games](/data/measure/reworks/p2/tuned-pigeon/games.jsonl) · [A/A games](/data/measure/reworks/p2/tuned-aa/games.jsonl) · [League log schema](/data/wt-m-tune/tools/league/league/LOGS.md:72)

| Rounds | Pigeon-locked wins | A/A Pigeon wins |
|---|---:|---:|
| 4 | 31% | 29% |
| 5 | 43% | 42% |
| 6 | 35% | 34% |
| 7 | 44% | 42% |
| 8 | 46% | 42% |
| 9 | 51% | 47% |
| 10 | 53% | 52% |
| 11+ | 56% | 55% |

Rounds 1–3 of tuning lifted locked round-8 Renown from **30.0 to 42.3** and round-8 wins from **42% to 46%**. Earlier, the tuned round-4 board had almost the same starting stats as the opponent but averaged 4.3 starters to 4.6 and 0.4 additional bodies to 0.8. In A/A the round-4 gap was 4.3 to 4.7 starters and 0.4 to 1.0 additional bodies. By round 6 the two sides had nearly equal starting stats in both runs. A hand reservist appeared in just **4% locked and 3% A/A** of rounds 4–5 fights. Privates appeared in **35% and 30%**, so the early reinforcement contribution mostly came from Recruiting Sergeant. The recorded gaps point to more immediate fighting power on early bodies and a stronger post once a refill is available. [Dev locked games](/data/measure/reworks/p2/dev-pigeon/games.jsonl) · [Locked pre-fight records](/data/measure/reworks/p2/tuned-pigeon/records) · [A/A pre-fight records](/data/measure/reworks/p2/tuned-aa/records)

## Changes

Costs use the prior rounds' normal-copy body proxies of **7.5 / 9 / 12 / 14 / 18 / 22** printed stats for tiers 1–6. One Renown is +1/+1 per eligible occupant, and a refill uses it a second time. [Tier guide](/data/wt-m-new/docs/design/tier-guide.md) · [Round 1 costing](/data/balance-endcheck/tuning/proposal.md)

| Card | Old → new | Reason | Tier-guide cost |
|---|---|---|---|
| Territorial (T1) | Printed **4/5 → 6/9** | Let the common opener trade into bigger units and give its eventual Reserve entry a stronger base. | **+0.80 T1 body** per copy when it fights, 9 → 15 printed stats. Deliberately high for early tempo and useful again if held for Reserve. |
| Old Campaigner (T2) | Printed **4/7 → 7/11** | Give the early front line both a stronger swing and a better chance of getting a second one. | **+0.78 T2 body**, 11 → 18 printed stats. A death turned into survival also earns **1 extra Renown** under the existing effect, worth +2 raw stats on the next starter. |
| Grenadier Guard (T3) | End-of-turn Guard post Renown **2 → 4** | Build one front slot that starts bigger and passes the gain to the soldiers who refill it. | **4 → 8 permanent stats/turn** on its starter, **0.33 → 0.67 T3 body** versus the guide's ~0.8. With one ordinary refill that turn's gain is **8 → 16 fight stats** (**0.67 → 1.33 bodies**), or 24 stats with two refills. |
| Lieutenant (T4) | Printed Attack **5 → 12** | Turn its opening chip damage into kills on ordinary swings and give boards Attack against Locust and Mouse. | **+0.50 T4 body**, 16 → 23 printed stats. The marginal Attack is ordinary swing and retaliation damage. The existing opening volley scales with Renown. |

## Why these four

- **Territorial and Old Campaigner.** Territorial's 4/5 already fills the T1 tempo role beside Sentry, and Reserve makes the cheap body useful later. It stood in front on 884 of 895 locked copies in round 4 and is the immediate lever for that trough. Old Campaigner's old body already pays for itself over a long run when it survives. The larger body lets it fight for that payoff sooner. Lance Corporal buys growth in two lanes and Recruiting Sergeant supplies a Private when it survives to witness a suitable death. Neither gives the same immediate durable swing. TribeBot bought Territorial on 53% of buyable offers in both runs and Old Campaigner on 42% locked and 37% A/A. [Locked shops](/data/measure/reworks/p2/tuned-pigeon/shops.jsonl.gz) · [A/A shops](/data/measure/reworks/p2/tuned-aa/shops.jsonl.gz)
- **Grenadier Guard.** A free post and 2 Renown a turn already focus fire and bank value. Doubling the amount strengthens that one lane through the rounds where Reserve is becoming available. Colour Sergeant already gives wide growth to a full Pigeon row. Padre puts growth where units die and pays from the next fight. Grenadier pays on the current turn and works with mixed rows. TribeBot bought it on 41% of buyable offers in both runs and used its Active 296 times in round 6 across 800 locked seats. In round 8 the post was front-row in all 304 locked and 128 A/A boards that had one. [Guard rules](/data/wt-m-tune/src/content/pigeon/mechanics/grenadier.gd) · [Locked decisions](/data/measure/reworks/p2/tuned-pigeon/decisions.jsonl.gz)
- **Lieutenant.** Its opening volley already pays off well on a developed row. Attack makes the fresh buy better in the fights where that row still has modest Renown. Bugler is the extra-body option and Flying Ace already converts Attack to Cleave. Lieutenant's buff needs an ordinary attack or retaliation to deal damage. It appeared on 31% of locked and 37% of A/A round-8 boards, and TribeBot bought it on 57% and 55% of buyable offers. Shop rates reflect both access and the bot's tier-first valuation. [Lieutenant rules](/data/wt-m-tune/src/content/pigeon/mechanics/lieutenant.gd) · [TribeBot valuation](/data/wt-m-tune/tools/league/league/src/baselines.rs:99)

At rounds **4 / 6 / 8 / 10**, the three printed-stat buffs add about **4/7, 6/8, 6/5 and 6/3 Attack/Health** on the recorded locked starters. A/A gets about **4/7, 6/7, 6/5 and 5/3**. Counting each recorded Grenadier grant at twice its amount adds another **0.3 / 1.4 / 3.3 / 5.7** Attack and the same Health on those locked starters, or **0.3 / 1.5 / 3.7 / 6.2** in A/A. These are arithmetic on fixed lineups and triggers. Stronger buys can change bot choices, Campaigner survival and refill timing. The high roll is a stacked or copied post that keeps refilling, especially with The Colonel. A normal Grenadier's extra two Renown gives +4 total stats to its starter, +4 to an ordinary refill or +8 to a hand reservist under The Colonel. A golden Grenadier doubles that increment. A slot left empty gives its stored gain to a later eligible occupant. [Locked pre-fight records](/data/measure/reworks/p2/tuned-pigeon/records) · [A/A pre-fight records](/data/measure/reworks/p2/tuned-aa/records) · [Renown rules](/data/wt-m-new/docs/design/rulebook.md:901)

## Tier check

- **T1.** Territorial is deliberately above the printed curve as the tempo buy. Sentry is the capped growth seed.
- **T2.** Campaigner gets an oversized body for the early fighting job. Lance Corporal and Recruiting Sergeant provide the first growth and refill setups.
- **T3.** Grenadier names the post and concentrates near-target permanent growth in one lane. Repeated refills make that lane stronger than its starter budget.
- **T4.** Lieutenant contributes immediate tempo while the Honours row develops. The extra printed Attack puts its body above the curve.
- **T5.** Colour Ensign, Wing Commander and Group Captain provide direction for the developed Renown, air and Reserve boards.
- **T6.** The three capstones already carry the surviving boards to a majority of late live wins in both runs. Briar is the late exception, with more additional bodies in both runs.

## Card values and patch check

| Card | Normal display before → after | Golden display before → after | Relevant tooltip meaning |
|---|---|---|---|
| Territorial | 4/5 → 6/9 | 8/10 → 12/18 | Reserve calls a unit from hand into a slot where a friendly unit died, Guard post first. The base limit is two per fight. |
| Old Campaigner | 4/7 → 7/11 | 8/14 → 14/22 | Renown gives +1/+1 per point to the starter and each reservist in the slot. |
| Grenadier Guard | 4/11, 2 → 4 Renown per turn | 8/22, 4 → 8 Renown per turn | The occupant of your one Guard post has Guard. |
| Lieutenant | 5/11 → 12/11 | 10/22 → 24/22 | The opening volley uses the row's slot Renown. |

`git -C /data/wt-m-tune apply --check /data/balance-endcheck/tuning/round4/round4.patch` passed. The candidate JSON parsed in memory and matches exactly six integer field changes in four cards. The diff touches only `src/content/pigeon/units.json` and remains unapplied. Verification used static checks and existing records. The species-seed artifact was unavailable to this session. [Unified diff](/data/balance-endcheck/tuning/round4/round4.patch) · [Keyword tooltips](/data/wt-m-tune/src/content/pigeon/display.json) · [Text substitution](/data/wt-m-tune/src/core/units/unit_text.gd:8)
