# Mouse tuning, round 3

Target **4.3–4.5** for Mouse-locked seats and **4.2–4.6** for Mouse in A/A. Give the Mice a generous Health pass aimed at the round 5–10 losses and the late fights where their remaining Attack needs more time to convert. The targets are unmeasured.

## Diagnosis

1. The round 2 Health pass improved Mouse-locked placement from **5.55 to 5.04** and A/A from **6.13 to 5.45**. In round 2, Mice won 47% of rounds 1–2 fights in both runs. They lost **53–63%** of rounds 5–10 fights against open seats in the locked run and **54–64%** in rounds 5–9 in A/A.
2. Across rounds 6–10, Mice averaged **85 Attack to 71** and **71 Health to 93** in locked fights against open seats, and **85 Attack to 65** and **68 Health to 92** in A/A. Their front rows averaged **44 Health to 60** in A/A. These are pre-fight numbers. The A/A count of losses with fewer total attack actions than attack-capable Mouse starters fell from **158 to 76**, a lower bound on fights where at least one starter missed its attack.
3. Locust was the worst midgame matchup, winning **80%** against locked Mice and **76%** against A/A Mice, even with lower starting Health. It averaged **3.0 arrivals or returns to about 0.4** across those fights. Badger, Briar and Pigeon each won a majority in both runs. From round 12 on, surviving A/A Mice still lost **85%** to Briar and **61%** to Pigeon in smaller samples (40 and 66 fights), with a large Health gap in both.

Fight counts are live seat-fights. Locked comparisons include red against blue only. A/A seats and opponent matchups use the final main tribe and may include mixed boards and Mouse mirrors in the overall figures. The arrivals or returns estimate is deaths plus survivors minus starters. [Round 2 locked games](/data/measure/reworks/tune2/tribe-mouse/games.jsonl) · [Round 2 A/A games](/data/measure/reworks/tune2/tribe-aa/games.jsonl) · [Round 1 A/A games](/data/measure/reworks/tune/tribe-aa/games.jsonl)

## Proposed changes

All values are printed Health. Costs use the prior proposals' normal-copy Bramble body proxies, 7.5 / 9 / 12 / 14 / 18 / 22 at T1–T6. [Tier guide](/data/wt-m-new/docs/design/tier-guide.md) · [Round 1 costing](/data/balance-endcheck/tuning/proposal.md)

| Card | Health | Reason | Tier-guide cost |
|---|---|---|---|
| Harvest Piper (T2) | **3 → 11** | Let a common front-row buy survive an early trade after it pays out its Recruit. | **+0.89 T2 body**, 6 → 14 printed stats. The existing one-off buff already gives 2.8–3.3 bodies with five to six recipients, so the total package is deliberately high. |
| Thimble Captain (T3) | **6 → 18** | Keep the summoner alive for neighbouring attacks after slots open. The existing Cousins give Mice more bodies to trade into Locust. | **+1.00 T3 body**, 9 → 21 printed stats. Each additional Cousin that lands adds 0.33 body in raw stats plus its life and possible gift, within the existing two normal charges. |
| Dormouse Cook (T4) | **9 → 24** | Give both builds a frontline body through the midgame and make it easier to hold the Attack engine while replacing early units. | **+1.07 T4 bodies**, 11 → 26 printed stats. Its existing 2.5–3.0 bodies of permanent Attack per turn on a wide board make this a deliberate budget exception. |
| Widow Thimble (T5) | **10 → 28** | Keep the second-heir effect live deeper into the fight, when frontline donors start dying. | **+1.00 T5 body**, 15 → 33 printed stats. If the extra Health keeps Widow alive for a 30-Attack gift with two live heirs, that one extra recipient gets 30 Attack, or 1.67 bodies. |
| Needle Pikeman (T6) | **14 → 36** | Give the pike capstone time to land more of its five hits, including when it starts in the exposed front row. | **+1.00 T6 body**, 20 → 42 printed stats. At 20 Attack an additional hit deals 20 raw damage, about 1.36 bodies at the prior 1.5× free-hit rate before overkill. With three eligible pilers, that hit also gives 6 permanent Attack across them. |

## Why these values

- **Early coverage.** Piper's Recruit already pays at purchase, and that is the strongest case for its old body. In round 5, about 9 in 10 Piper copies stood in front in both runs. Extra Health makes it a viable alternative to Aunt's extra body or Cutpurse's economy when the player needs a front slot. Captain adds a different lever. Its 6 Health is defensible when a player can protect it, but 70% of locked round-6 copies started in front. Of 127 rounds 6–10 locked fights against Locust with a Captain, only 64 recorded a Captain summon. On a full board the summon can spend a charge with no arrival, so the Health increase buys opportunity, and the amount realized depends on board space. [Captain](/data/wt-m-tune/src/content/mouse/mechanics/captain.gd:11) · [Cousin summons](/data/wt-m-tune/src/content/mouse/lib/mouse_rules.gd:138)
- **Midgame coverage.** Cook already pays from the shop and could justify its slot on scaling alone. At round 8 it was on 41% of locked boards and 45% of A/A Mouse boards, and about two-thirds of copies stood in front in both runs. Give the Health to that common frontliner. Sentinel is already a 24-Health Guard, and Drill-sergeant already converts neighbours' Attack into free hits. Locked seats bought Captain on 608/1,487 buyable offers and Cook on 568/1,098. These rates are evidence that the bot exercises both cards. Tier, stats and existing copies all affect the scores. [Locked shops](/data/measure/reworks/tune2/tribe-mouse/shops.jsonl.gz) · [Bot valuation](/data/wt-m-tune/tools/league/league/src/baselines.rs:99)
- **Late coverage.** Widow can do its job from a protected slot at 10 Health, and Pikeman already averages roughly two credited kills per fight on boards that field it. Nearly half the round-12 Widows and Pikemen stood in front in both runs. Their Health gives the Hand-me-down and Pile on builds separate ways to finish fights. Standard-bearer already pays at fight start, and King Speck already landed Cousins in 69 of 97 locked fights against Locust from round 11 on when fielded. The largest human-play high rolls are a protected golden Pikeman beside healthy attackers and Widow staying live for bonus heirs with Old Mother Needle. [Widow and Mother rules](/data/wt-m-tune/src/content/mouse/lib/mouse_rules.gd:77) · [Pile on rules](/data/wt-m-tune/src/content/mouse/mechanics/pile_on.gd:1)
- **Size of the pass.** Applying the new printed Health to recorded round 2 boards, with golden copies doubled, adds about **7 / 14 / 21 / 28 / 37** Health in the locked run and **8 / 16 / 22 / 30 / 36** in A/A at rounds **5 / 6 / 8 / 10 / 12**. In rounds 6 and 8, the A/A frontline gets about **12 and 15** of that Health. All five new printed Health values exceed the highest printed Health among non-Mouse shop units at the corresponding tier in the round 2 library. These are deliberate exceptions. The calculation holds lineups fixed. TribeBot uses printed stats to score cards, so changed buys and replacements can shift both exposure and results. [Round 2 card library](/data/measure/reworks/tune2/tribe-aa/library.json)

## Tier check

- **T1.** Scout and Page still cover the opening, where round 2 fight wins recovered to 47%.
- **T2.** Piper gives a direction and immediate tempo. The wide Recruit with the larger printed body runs above budget.
- **T3.** Captain is an oversized summon enabler beside Fencing Master's immediate damage and Sister's inheritance payoff.
- **T4.** Cook bridges the Attack engine into the late shop tiers. Its printed body and growth together exceed the guide.
- **T5.** Widow makes the inheritance build more reliable. The strongest return still requires large gifts and two live heirs.
- **T6.** Pikeman gets the Health to play the pike capstone role. A live neighbour and available charges are required to use it.

## Patch check

`git -C /data/wt-m-tune apply --check /data/balance-endcheck/tuning/round3/round3.patch` passed against the current working file. The proposed JSON parsed in memory and matched exactly the five Health fields above. Verification used the recorded data and static checks. [Unified diff](/data/balance-endcheck/tuning/round3/round3.patch)
