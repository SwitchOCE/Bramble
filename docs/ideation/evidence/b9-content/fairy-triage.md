# Fairy Ring: role, journey, competition and measurement

**Symptom.** The supplied build-8 Ring engine is 220 / 480 / 1,658 at R12, while Court reads 901. After the one permitted Ooze cut, the same 32 seeds give Ring 204.6 / 394 / 1,234.8 and Court 265.5 / 866.5 / 1,950. These are surviving seats' active recruit boards before combat-start effects. Both the original Fairy trace and the new pre-change trace show the same gap, rather than a single unlucky game.

| Hypothesis | Expected / falsifier | Evidence before Fairy change |
|---|---|---|
| Parameter: Cluricaun's +6 growth is too small | Full-rainbow Cluricaun boards still weak; ruled out if growth seldom fires | All 4 R9 Cluricaun seats lack a rainbow; all 3 at R12 still lack it. Raising +6 would often multiply zero. Not the first lever. |
| Role/journey: Sally fails to enable a full board | Sally stops covering slots when the board fills; ruled out if full-board Sally reliably spreads | R9: 7/22 Ring seats have Sally, 5/7 have all seven recruit slots occupied; median coverage is only 2. Court: 9/10 Sally seats full. The current rule correctly does nothing there. Kept. |
| Access/competition: early pieces are too scarce | Too few Annis/Cluricaun; high-tier generics or reactive payoffs displace the engine | Only 5/22 have Annis at R6; 4/22 have Cluricaun at R9. Generic early purchases bridge sparse shops. Kept as a limitation; this bounded job changes one enabler, not shop odds or every tier. |
| Measurement/bot: missing combat power or route ignored | Fetch raises post-start totals; no aimed spells/churn even when enablers are present | Ring's R12 active median 394 becomes 465 after start, still below 675. BotPass3 already completes affordable Ring spells, plays Nan into an unringed empty slot and churns through Annis. The full-board Sally dead turn is a rule/role gap. Do not change the metric. |

## Cards and competition

- **Sally Spore**, T2 2/4, enabler. Old normal: “End of Turn: Ring your empty slot nearest this.” Golden: “…twice.” Useful R3–6 while filling the board, poor exactly when a R6–9 full board needs missing Rings. Competes with Annis (same 2/4, repeatedly Rings behind on sales and End of Turn), Nan (T1 2/1, immediately Rings its play/sale slot twice at B), and cross-tribe tempo. An empty-only trigger becomes a trap after filling seven slots.
- **Old Moth Annis**, T2 2/4, economy-to-Ring enabler: “End of Turn and after you sell: Ring the slots behind this.” A real window from R3 with back-row occupants; back-row Annis or no sale money is a bad board. Court's F2 covers two slots; the Ring line's F1 concentrates one. Keep this distinction.
- **Cluricaun**, T3 3/5, payoff: “End of Turn: if every slot has a Ring, your Rings grow +6/+6.” Golden +12/+12. Needs coverage before R7–9; copies share a trigger. On an incomplete board it loses to an immediately useful T3 body, including Mallow feeding actual Hedgerow runts. The prerequisite, not the +6, is failing.
- **Lob-Lie-by-the-Fire**, T3 3/6, Shy bank: “Shy. When this leaves: your Rings grow +6/+6 per 2 turns it stayed.” Needs an aimed spell after an investment, poor when combat urgently needs that slot. **Silky**, T3 3/7: “Shy. After a Shy unit leaves: your Rings grow +3/+3.” Both are delayed alternatives, not dependable early coverage.
- **Fairy Monarch**, T6 6/8, finisher: “Every 2nd End of Turn: triple your Ring size.” Golden ×4. Ten of fifteen R12 Ring survivors have one, but median size is only 10. A late multiplier cannot supply missing Rings; it competes with the other tribes' immediate capstones.
- **Cradle Fetch**, T4 2/4, combat payoff: “Start of Combat: become a copy of the Fairy behind, Ring and all, with full stats.” Doubles fight presence but cannot repair an unbuilt Ring board. Nine of fifteen Ring R12 survivors have it. Post-start median remains short.

## Journey and one bounded change

R1–3: buy Nan/tempo, start local Rings. R4–6: Annis/Sally add counts; Cluricaun begins to make a rainbow attractive. R7–9: the board is full, but empty-only Sally stops; the engine stalls at two covered slots. R10+: Monarch/Fetch arrive, often amplifying a small or incomplete substrate. Court has wider Annis and Queen coverage, so it crosses this gap more often.

**Chosen before the run:** Sally instead says “End of Turn: Ring your nearest unringed slot.” Golden Rings that chosen slot twice. Occupied slots, including Sally's, count; once every slot has a Ring she stops. This retains her spreading-enabler role, pays on full boards and completes rather than repeatedly decorating one hole. It is a generous targeting change to one card; all B/C numbers, clocks, bot priorities and other cards stay fixed. Existing nearest-placement order supplies deterministic targets. Counterexamples pin occupied targeting, skipping an existing Ring, golden counts and a complete full-board rainbow that then stops.

**Process cause:** paper boards assumed an empty flex slot and ready access to enablers, while real shops and the survival bot fill seven slots. Card review should require a full-board counterexample for each enabler and record prerequisite uptime, not only a model's online growth. The diagnostic now reports coverage, blocked Cluricauns and full-board Sally seats at R3/6/9/12; the same test applies to summon-space and Belly routes.

One local confirmation, same 32 seeds, no overrides. Decides only Ring R12 median ≥675; full distributions and every other line's median are reported. A miss is not refit.

## Empirical benchmark boards

Observed near-p10 / median / p90 seats, before the Fairy change. Gold is cumulative actual spend; shops are not assumed to supply a fixed recipe. These give low / average / high examples at the requested journey rounds. Combat payoff remains separately reported above.

| Round | Example | Seed / seat | Tier | Gold spent | Active A+H | Recruit board |
|---|---|---|---|---|---|---|
| 3 | low | 2911029 / 6 | 2 | 12 | 8 | little_nip, hedge_witch |
| 3 | average | 2911011 / 3 | 2 | 14 | 13 | little_nip, young_brock, hedge_witch |
| 3 | high | 2911005 / 2 | 2 | 14 | 30 | peat_cutter, mrs_dunnock, nan_toadstool |
| 6 | low | 2911011 / 3 | 4 | 36 | 34 | rainbow_chaser, ballooning_spider, young_brock, pennywort_snail, hedge_witch, little_nip |
| 6 | average | 2911029 / 6 | 4 | 40 | 54 | old_moth_annis, little_nip, madame_bufo, hedge_witch |
| 6 | high | 2911023 / 4 | 4 | 38 | 85 | sally_spore, nan_toadstool, nan_toadstool |
| 9 | low | 2911032 / 2 | 6 | 74 | 84 | rainbow_chaser, shieldbug, sally_spore, cradle_fetch, will_o_the_wisp, money_spider, vaulting_hopkin |
| 9 | average | 2911007 / 3 | 5 | 74 | 112 | nan_toadstool, little_nip, pennywort_snail, changeling, hedge_witch, rainbow_chaser, reel_mistress |
| 9 | high | 2911010 / 0 | 5 | 74 | 245 | old_moth_annis, little_nip, wick, reel_mistress, sally_spore, hob_in_the_hearth, jenny_greenteeth |
| 12 | low | 2911016 / 2 | 6 | 105 | 187 | bridge_toad, cradle_fetch, cluricaun, belladonna, hob_in_the_hearth |
| 12 | average | 2911010 / 0 | 5 | 108 | 394 | old_moth_annis, cradle_fetch, belladonna, fairy_monarch, sally_spore, hob_in_the_hearth, jenny_greenteeth |
| 12 | high | 2911029 / 6 | 5 | 113 | 1598 | old_moth_annis, cradle_fetch, little_nip, old_moth_annis, belladonna, cluricaun, fairy_monarch |
