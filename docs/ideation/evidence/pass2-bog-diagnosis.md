# Pass 2: why the round 9 Bog boards lose

9 Nov 2026, follow-up to the owner's request before review. No card values or fixture values were changed. The diagnosis uses the same published fixtures and seeds, the real engine with full events, and a diagnostic `Combat.mire_wait_enabled` switch which defaults to true. The switch disables only waiting; Mire patches, forced targets, Mired status, Bitter, Snap and all unit text stay active. A regression checks that both mirers still attack and that bindings remain with either setting.

## Finding

These are honest losses of these fixed compositions, not evidence of a broken Mire wait or a lost Bog stat layer. All 22 logged wait-on matchup totals reproduce the original quiet-engine totals. Turning wait off leaves Bog high at **0/1,000** against the other five highs, including **0/200** against Hedgerow high. Bog low changes from **3/1,000 to 4/1,000** against other lows. The only changed matchup is Fairies low, from 3/200 to 4/200.

Mire constrains the enemy’s target, not the mirer’s own normal target. The two high boards have equal recruit stat totals, 72. Hopkin's back-row Vault adds 2 Attack, taking Bog from **29/43 to 31/43** at the opening. Hedgerow starts **31/41**, then Committee adds **3 Attack to all seven** at the bell: **52/41**. Its front units each hit for 7. Bufo has 6 Health and dies to Sorrel in one exchange. Prima Donna has 9 Health: Urchin's 7-Attack hit plus Bristle 2 kills her. Bitter and Bufo's halving work, but only shrink their own attacker after damage. Gideon has no Bitter. Tiddy's first two permanent gains often reach dead walls, correctly paying future growth without reviving their combat copies. The back-row Kit, Committee and Mallow are not Mired and retain their high Attack. Ranocchio is a once-a-fight grower, not a large immediate team buff.

## Full traces, turn by turn

“Turn” below counts declared primary attacks. Waiting does not consume the side's attack opportunity; the next eligible friendly unit attacks. Source event numbers, every damage/stat/status/trigger line, and raw engine data are retained in the linked full logs.

### Seed 92100: Bog goes first

[Full event log](pass2-bog/seed-92100.md), [raw JSON](pass2-bog/seed-92100.json).

At the bell, Bufo binds Sorrel, Gideon binds Clover, and Prima Donna binds Urchin and Burdock. All four Mired statuses appear. Committee gives the seven Hedgerow units +3 Attack. Hopkin's Vault puts it before the front row, so Bog's first opportunity goes to the 6/2 Snapper. No mirer waits in this seed: Bufo dies before being selected, Clover is already dead when Gideon is selected, and Urchin has already attacked before Prima Donna would be selected.

| Turn | Attack | What happens |
|---:|---|---|
| 1 | Hopkin → Clover | Both die: 6 damage kills Clover; Clover returns 7. |
| 2 | Sorrel → Bufo | Correct forced target. Bufo takes 7 and dies; Sorrel takes 3, then Bitter reduces its Attack 7→5 and Bufo halves 5→3. Tiddy banks +1/+1 on dead Bufo; no revival. Sorrel's blocked behind-summon Spills. |
| 3 | Gideon → Burdock | Clover, its bound enemy, is dead, so Gideon attacks normally. Gideon ends 4/1; Burdock 7/1. |
| 4 | Urchin → Prima Donna | Correct forced target. Urchin's 7 damage plus Bristle 2 kills the 9-Health wall. Bitter reduces Urchin to 4 Attack. Urchin passes +1 Attack to Burdock (now 8/1). Tiddy banks its second gain on dead Prima Donna. |
| 5 | Pretender → Burdock | Snap still finds a Mired enemy after Prima Donna's death. Both die. |
| 6 | Kit → Gideon | Kit is an unmired back-row unit and attacks normally. Both die. |
| 7 | Ranocchio → Urchin | Snap works. Urchin dies; its prick leaves Ranocchio 7/2, then Ranocchio's one permanent +1/+1 makes it 8/3. Urchin passes +1 Attack to Mallow, making Mallow 9/7. |
| 8 | Committee → Ranocchio | Both die: 9 versus 8 Attack. |
| 9 | Tiddy → Sorrel | Sorrel dies; Tiddy ends 4/4. |
| 10 | Mallow → Tiddy | Tiddy dies; **Mallow wins at 9/3**. |

### Seed 92101: two mirers wait, and Prima Donna later attacks

[Full event log](pass2-bog/seed-92101.md), [raw JSON](pass2-bog/seed-92101.json).

The same four bindings and Committee buffs appear. This seed directly tests the suspected never-attacking failure: events 43–44 show Gideon and Prima Donna waiting once, and event 80 shows Prima Donna declaring an attack in the next cycle.

| Turn | Attack | What happens |
|---:|---|---|
| 1 | Hopkin → Burdock | Both die. |
| 2 | Sorrel → Bufo | Correct forced target. Bufo dies, Bitter and halving leave Sorrel 3/2; Tiddy banks the dead wall's gain. |
| Before 3 | Gideon and Prima Donna wait | Each waits once for its unacted bound enemy; neither consumes a primary attack. Bog proceeds to Pretender. |
| 3 | Pretender → Clover | Pretender dies; Clover falls to 7/2. |
| 4 | Clover → Gideon | Correct forced target. Clover dies; Gideon survives at 4/1 and Tiddy's second gain makes it 5/2. A counterattack is unnecessary because Clover is already dead. |
| 5 | Ranocchio → Urchin | Both die after Bristle. Ranocchio still receives its permanent reward, without being revived. Mallow receives Urchin's Pass and reaches 9 Attack. |
| 6 | Kit → Prima Donna | Unmired Kit attacks the front normally. Prima Donna survives at 3/2; Bitter leaves Kit 4/1. |
| 7 | Tiddy → Sorrel | Sorrel dies; Tiddy ends 4/4. |
| 8 | Committee → Gideon | Gideon dies; Committee has 2 Health left. |
| 9 | Prima Donna → Committee | **The waiting mirer now attacks.** Both die. |
| 10 | Mallow → Tiddy | Tiddy dies; **Kit 4/1 and Mallow 9/3 survive**. |

### Seed 92102: Hedgerow goes first

[Full event log](pass2-bog/seed-92102.md), [raw JSON](pass2-bog/seed-92102.json).

Again all four bindings and the Committee buffs appear. No mirer needs to wait: its enemy attacks first or is killed before the mirer is selected.

| Turn | Attack | What happens |
|---:|---|---|
| 1 | Sorrel → Bufo | Forced target, Bufo dies; Bitter and halving leave Sorrel 3/2. Tiddy banks the first gain. |
| 2 | Hopkin → Clover | Both die. |
| 3 | Urchin → Prima Donna | Forced target; 7 damage plus Bristle 2 kills Prima Donna. Bitter reduces Urchin to 4 Attack; Tiddy banks its second gain. Burdock gets a Pass, reaching 8 Attack. |
| 4 | Gideon → Urchin | Urchin dies; Gideon survives at 4/2 after Bristle. Burdock receives a second Pass, reaching 9 Attack. |
| 5 | Burdock → Pretender | Prima Donna is dead, so Burdock's forced attack has ended. Pretender dies; Burdock has 1 Health. |
| 6 | Ranocchio → Burdock | Snap still works. Both die; Ranocchio banks its permanent gain without revival. |
| 7 | Kit → Gideon | Both die. |
| 8 | Tiddy → Sorrel | Sorrel dies; Tiddy ends 4/4. |
| 9 | Committee → Tiddy | Tiddy dies; **Committee 9/3 and Mallow 8/7 survive**. |

## Wait ablation

[All 22 matchup rows](pass2-bog/ablation.json): two Bog boards against all eleven other boards, each at 100 seeds 92100–92199 with sides swapped, in both modes: **8,800 fresh engine fights**. All wait-on rows match the published quiet-engine results exactly. All waits-off rows are identical except Bog low against Fairies low (4 wins rather than 3). This is a deterministic paired comparison, not independent unpaired samples.

| Board / opponent set | Wait on | Wait off |
|---|---:|---:|
| Bog high vs five other highs | 0/1,000 (0.0%) | 0/1,000 (0.0%) |
| Bog high vs Hedgerow high | 0/200 (0.0%) | 0/200 (0.0%) |
| Bog high vs all eleven | 1,200/2,200 (54.5%) | 1,200/2,200 (54.5%) |
| Bog low vs five other lows | 3/1,000 (0.3%) | 4/1,000 (0.4%) |
| Bog low vs all eleven | 3/2,200 (0.136%) | 4/2,200 (0.182%) |

## Fixture audit

Independent read-only audit found that the fixture JSON equals the published result's embedded boards, and all reconstructed Bog values match the desired values. Current definitions, schema and amendments agree: Ranocchio is 3/4, +1/+1 once per fight; Tiddy is 3/6, +1/+1 twice per fight; Lantern is 4/8 with a live +3 Attack per Mired enemy. **Lantern is not in either tier-4/5 R9 fixture**, so no Lantern Attack is missing from these results. Its aura remains covered by the existing directed emergence/death tests.

| Bog high unit | Printed | Supper | Prior permanent growth | Recruit total | Combat-only addition |
|---|---:|---:|---:|---:|---:|
| Bufo | 1/4 | +1/+1 | +1/+1 from Tiddy | 3/6 | — |
| Gideon | 2/6 | +1/+1 | +1/+1 from Tiddy | 4/8 | Counter only if its Mired attacker survives and Gideon lives |
| Prima Donna | 2/8 | +1/+1 | — | 3/9 | — |
| Young Pretender | 3/2 | +1/+1 | — | 4/3 | Snap kill reward is next-turn gold |
| Ranocchio | 3/4 | +1/+1 | +3/+3, one proc in each R6–8 fight | 7/8 | +1/+1 once this fight, not already counted |
| Tiddy | 3/6 | +1/+1 | — | 4/7 | Two attacked-unit gains, not an aura |
| Hopkin | 3/1 | +1/+1 | — | 4/2 | +2 Attack from Vault in back row: 6/2 |

The 48-gold static budget (21 purchases +24 climbs +3 Supper, versus 62 base income) is feasible; it does not claim a recorded shop trace. Bog low has only printed bodies, **11/24 = 35 stats**, and no Supper or T4 payoff. Its Chorus is not a mirer: at F3 it lends Mire to F2 Peat Cutter and F4 Scarecrow, while Bridge covers F1. **Only F1, F2 and F4 are patched; F3 is not.** Sal therefore hits three occupied patched fronts for a nominal 6 damage, not the old draft's four fronts /8 damage. The old Group B draft also overstates the high board's amended stats (76 rather than 72), Tiddy growth, and universal Bitter; Gideon has no Bitter. The implemented fixture follows the amended cards rather than those hand guesses.

## Birds low

**93.8% is only against the other five lows (938/1,000); it is 42.6% across all eleven opponents and loses all 1,200 fights against highs.** Its 65-stat fixture is budget-plausible at 41 of 62 gold (eight purchases 24, climbs 13, Supper 3, Pinch 1), but generous relative to the other “lows”: it found Supper, all three T3 Birds, Stork and neutral Burner, while Bog low found neither Supper nor a T4 Bog payoff.

Redbreast is 2/4 +Supper +two Nests =5/7. Away Chiffchaff is 1/2 +one play +Pinch +Supper =4/5, producing a 2/5 Egg under Tom Tit. Other home Birds have only Supper; Burner stays 4/6. The fixture correctly strips Redbreast's live Nest aura and stores the Egg's raw half Health before combat reapplies Tom Tit. No unexplained stats, free unit or impossible gold assumption was found. A static budget is not evidence of how frequently those finds occur.

## Reproduce

After `source /opt/bramble/env.sh`:

```sh
systemd-run --user --scope -p MemoryMax=3G -- godot --headless \
  -s res://tools/sim/pass2_bog_probe.gd
```

This regenerates the three full logs and the wait-on/off table in `build/`. One Godot process at a time, with no shared lock. No production setting exposes the diagnostic switch; it remains on by default. The normal R9 bench is still `tools/sim/pass2_boards.gd`.

## Verification

The complete gate passes: 1,557 Godot tests, 46 Python tests, 434 scripts/resources compiled, no risky or pending tests ([gate transcript](pass2-bog/gate.txt)). The fresh 13,200-fight default-on benchmark is identical to the published JSON in every field and SHA-256, with no trigger-limit or attack-limit stops ([confirmation](pass2-bog/bench-confirmation.json), [run transcript](pass2-bog/bench.txt)). Independent source/log audit found no discrepancy in these turn tables or calculations. No cards or fixture values were changed.
