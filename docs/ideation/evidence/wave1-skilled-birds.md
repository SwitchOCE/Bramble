# Current-value Birds flight check

The aggressive arm changes only the flight decision inside the existing committed bot turn: largest legal flier at the first flight decision each turn, bypassing danger/score/home-minimum/from-round/omen/allowlist gates for that carry only. Subsequent flight decisions use the native policy. It obeys HeldUnits.flies, pending-choice restrictions and native RecruitRules.sell, trips, return guards, pool purchases, heroes, fights, damage and eliminations. The forced carry leaves its native Egg, where applicable; other flights retain native policy guards. All shop, economy and placement policies remain native. This probes one skilled decision, not optimal human play. No runaway cutoff or gameplay pass/fail bar is defined.

PRE_START means combat_start after initial auras and before Start of Combat text. Human review logs and POST_FIGHT mean GameLog.record_round's post-fight live RecruitUnit board: away Birds and their Eggs are absent, temporary combat layers may differ, and combat carry is applied. Only POST_FIGHT bot rows share the human recording phase; human examples are two selected wins, not a sample.

Frozen N=32 lobbies per arm; source `f9c924b9bc1fff68509b55666268ebd81d71664f`. Two separate arms keep the four written lines and four Hard seats, actual five-tribe rotation including Birds and Fairies. Later rows contain survivors. Missing rows are reported, not continued artificially.

## Two provided human examples (post-fight live recruit boards)

| Example | Round | Board A+H | Biggest unit | A/H | Board share |
|---|---:|---:|---|---:|---:|
| tester_a | 10 | 329 | Old Tern | 38/47 | 25.8% |
| tester_a | 12 | 772 | Old Tern | 87/110 | 25.5% |
| tester_a | 14 | 2,085 | Old Tern | 208/266 | 22.7% |
| tester_a | 16 | 2,676 | Old Tern | 272/346 | 23.1% |
| tester_c | 10 | 272 | The Great Lump | 59/81 | 51.5% |
| tester_c | 12 | 459 | The Great Lump | 113/151 | 57.5% |
| tester_c | 14 | 883 | The Great Lump | 220/290 | 57.8% |
| tester_c | 16 | 1,617 | The Great Lump | 420/554 | 60.2% |

## pre_start_initial_auras

Largest A/H are component medians across each board's largest active unit; they need not describe one observed unit. Exact median-board and maximum-board examples are in the JSON. SKY refers to reserve Birds away, excluded from active board totals.

| Arm | Starting line | Round | n / missing | Median board A+H | Largest A/H | Largest share | Largest SKY A/H |
|---|---|---:|---:|---:|---:|---:|---:|
| control | line_birds_homecoming | 10 | 32 / 0 | 170.5 | 30.0/39.5 | 36.5% | 18.0/24.0 |
| control | line_birds_homecoming | 12 | 29 / 3 | 328.0 | 57.0/84.0 | 40.8% | 25.0/32.5 |
| control | line_birds_homecoming | 14 | 26 / 6 | 503.5 | 79.5/104.5 | 35.5% | 49.0/64.0 |
| control | line_birds_homecoming | 16 | 23 / 9 | 948.0 | 124.0/160.0 | 31.7% | 89.5/119.0 |
| control | line_birds_tempo | 10 | 32 / 0 | 172.0 | 24.5/31.5 | 36.5% | 11.0/14.0 |
| control | line_birds_tempo | 12 | 31 / 1 | 317.0 | 52.0/64.0 | 37.4% | 14.5/19.5 |
| control | line_birds_tempo | 14 | 27 / 5 | 575.0 | 103.0/130.0 | 35.1% | 53.5/66.5 |
| control | line_birds_tempo | 16 | 24 / 8 | 1,118.0 | 186.0/245.5 | 37.4% | 57.0/73.0 |
| control | line_fairies_ring | 10 | 32 / 0 | 103.0 | 13.0/15.0 | 28.7% | none |
| control | line_fairies_ring | 12 | 27 / 5 | 151.0 | 20.0/24.0 | 30.3% | none |
| control | line_fairies_ring | 14 | 19 / 13 | 282.0 | 40.0/42.0 | 33.2% | none |
| control | line_fairies_ring | 16 | 13 / 19 | 444.0 | 66.0/70.0 | 35.1% | none |
| control | line_fairies_court | 10 | 32 / 0 | 105.5 | 12.5/17.0 | 28.0% | none |
| control | line_fairies_court | 12 | 23 / 9 | 192.0 | 28.0/32.0 | 30.9% | none |
| control | line_fairies_court | 14 | 14 / 18 | 302.0 | 52.5/56.0 | 32.1% | none |
| control | line_fairies_court | 16 | 8 / 24 | 875.0 | 133.0/136.0 | 34.9% | none |
| aggressive | line_birds_homecoming | 10 | 32 / 0 | 173.5 | 32.0/44.0 | 36.2% | 13.0/16.5 |
| aggressive | line_birds_homecoming | 12 | 31 / 1 | 472.0 | 86.0/121.0 | 37.0% | 47.0/56.0 |
| aggressive | line_birds_homecoming | 14 | 27 / 5 | 1,094.0 | 171.0/266.0 | 38.8% | 122.5/140.5 |
| aggressive | line_birds_homecoming | 16 | 25 / 7 | 2,748.0 | 422.0/591.0 | 37.0% | 243.5/280.5 |
| aggressive | line_birds_tempo | 10 | 32 / 0 | 187.5 | 31.5/42.0 | 41.4% | 17.0/22.0 |
| aggressive | line_birds_tempo | 12 | 32 / 0 | 419.0 | 70.5/108.0 | 42.4% | 50.0/67.0 |
| aggressive | line_birds_tempo | 14 | 30 / 2 | 892.0 | 180.0/287.0 | 48.3% | 100.0/132.0 |
| aggressive | line_birds_tempo | 16 | 29 / 3 | 1,780.0 | 335.0/560.0 | 44.3% | 211.5/269.0 |
| aggressive | line_fairies_ring | 10 | 32 / 0 | 90.5 | 11.0/14.0 | 28.6% | none |
| aggressive | line_fairies_ring | 12 | 25 / 7 | 132.0 | 18.0/21.0 | 30.9% | none |
| aggressive | line_fairies_ring | 14 | 21 / 11 | 236.0 | 45.0/48.0 | 41.5% | none |
| aggressive | line_fairies_ring | 16 | 10 / 22 | 566.0 | 133.0/136.0 | 53.0% | none |
| aggressive | line_fairies_court | 10 | 32 / 0 | 104.0 | 13.0/15.0 | 27.9% | none |
| aggressive | line_fairies_court | 12 | 22 / 10 | 175.0 | 26.5/26.5 | 28.8% | none |
| aggressive | line_fairies_court | 14 | 13 / 19 | 391.0 | 67.0/70.0 | 35.3% | none |
| aggressive | line_fairies_court | 16 | 8 / 24 | 611.0 | 100.0/101.5 | 31.0% | none |

## post_fight_live_recruit

Largest A/H are component medians across each board's largest active unit; they need not describe one observed unit. Exact median-board and maximum-board examples are in the JSON. SKY refers to reserve Birds away, excluded from active board totals.

| Arm | Starting line | Round | n / missing | Median board A+H | Largest A/H | Largest share | Largest SKY A/H |
|---|---|---:|---:|---:|---:|---:|---:|
| control | line_birds_homecoming | 10 | 32 / 0 | 176.5 | 31.0/42.0 | 37.3% | none |
| control | line_birds_homecoming | 12 | 29 / 3 | 328.0 | 57.0/84.0 | 41.5% | none |
| control | line_birds_homecoming | 14 | 26 / 6 | 508.5 | 81.0/112.5 | 36.6% | none |
| control | line_birds_homecoming | 16 | 23 / 9 | 948.0 | 124.0/160.0 | 31.7% | none |
| control | line_birds_tempo | 10 | 32 / 0 | 170.5 | 25.0/32.5 | 37.0% | none |
| control | line_birds_tempo | 12 | 31 / 1 | 317.0 | 53.0/67.0 | 37.4% | none |
| control | line_birds_tempo | 14 | 27 / 5 | 575.0 | 105.0/130.0 | 35.1% | none |
| control | line_birds_tempo | 16 | 24 / 8 | 1,118.0 | 193.0/253.0 | 38.1% | none |
| control | line_fairies_ring | 10 | 32 / 0 | 103.0 | 13.0/15.0 | 28.7% | none |
| control | line_fairies_ring | 12 | 27 / 5 | 151.0 | 20.0/24.0 | 30.3% | none |
| control | line_fairies_ring | 14 | 19 / 13 | 282.0 | 40.0/42.0 | 33.2% | none |
| control | line_fairies_ring | 16 | 13 / 19 | 444.0 | 66.0/70.0 | 35.1% | none |
| control | line_fairies_court | 10 | 32 / 0 | 105.5 | 12.5/17.0 | 28.0% | none |
| control | line_fairies_court | 12 | 23 / 9 | 192.0 | 28.0/32.0 | 30.9% | none |
| control | line_fairies_court | 14 | 14 / 18 | 302.0 | 52.5/56.0 | 32.1% | none |
| control | line_fairies_court | 16 | 8 / 24 | 875.0 | 133.0/136.0 | 34.9% | none |
| aggressive | line_birds_homecoming | 10 | 32 / 0 | 180.0 | 33.0/44.0 | 36.9% | none |
| aggressive | line_birds_homecoming | 12 | 31 / 1 | 472.0 | 86.0/121.0 | 37.5% | none |
| aggressive | line_birds_homecoming | 14 | 27 / 5 | 1,094.0 | 173.0/266.0 | 39.9% | none |
| aggressive | line_birds_homecoming | 16 | 25 / 7 | 2,748.0 | 422.0/591.0 | 37.0% | none |
| aggressive | line_birds_tempo | 10 | 32 / 0 | 187.5 | 33.5/45.0 | 41.4% | none |
| aggressive | line_birds_tempo | 12 | 32 / 0 | 419.0 | 70.5/108.0 | 42.4% | none |
| aggressive | line_birds_tempo | 14 | 30 / 2 | 892.0 | 180.0/291.0 | 48.4% | none |
| aggressive | line_birds_tempo | 16 | 29 / 3 | 1,780.0 | 335.0/560.0 | 44.0% | none |
| aggressive | line_fairies_ring | 10 | 32 / 0 | 90.5 | 11.5/14.0 | 29.2% | none |
| aggressive | line_fairies_ring | 12 | 25 / 7 | 132.0 | 18.0/21.0 | 30.4% | none |
| aggressive | line_fairies_ring | 14 | 21 / 11 | 236.0 | 45.0/48.0 | 41.5% | none |
| aggressive | line_fairies_ring | 16 | 10 / 22 | 566.0 | 133.0/136.0 | 53.0% | none |
| aggressive | line_fairies_court | 10 | 32 / 0 | 104.0 | 13.0/15.0 | 27.9% | none |
| aggressive | line_fairies_court | 12 | 22 / 10 | 175.0 | 26.5/26.5 | 28.8% | none |
| aggressive | line_fairies_court | 14 | 13 / 19 | 391.0 | 67.0/70.0 | 35.3% | none |
| aggressive | line_fairies_court | 16 | 8 / 24 | 621.0 | 100.0/101.5 | 31.0% | none |

## Flight implementation check

Counts of legal opportunities and legacy denials use the first flight decision of each player turn, so repeated loop checks do not inflate them.

| Arm | Starting line | Eligible turns | Carry chosen | Native would choose carry | Flights | Homecomings |
|---|---|---:|---:|---:|---:|---:|
| control | line_birds_homecoming | 299 | 155 | 155 | 266 | 248 |
| control | line_birds_tempo | 354 | 168 | 168 | 369 | 337 |
| aggressive | line_birds_homecoming | 296 | 296 | 191 | 407 | 374 |
| aggressive | line_birds_tempo | 348 | 348 | 192 | 458 | 414 |

control line_birds_homecoming carry legacy-denial counts: `{"hard_danger_largest": 102, "policy_keep_home_min": 32, "policy_omen": 7, "policy_tern_two_away": 5}`


control line_birds_tempo carry legacy-denial counts: `{"hard_danger_largest": 85, "policy_allowed": 11, "policy_from_round": 25, "policy_keep_home_min": 67, "policy_omen": 4, "policy_tern_two_away": 20}`


aggressive line_birds_homecoming carry legacy-denial counts: `{"hard_danger_largest": 65, "policy_keep_home_min": 24, "policy_omen": 9, "policy_tern_two_away": 6}`


aggressive line_birds_tempo carry legacy-denial counts: `{"hard_danger_largest": 73, "policy_allowed": 9, "policy_from_round": 18, "policy_keep_home_min": 52, "policy_omen": 10, "policy_tern_two_away": 14}`


## Descriptive growth

Population ratios compare survivor-only medians; same-survivor ratios retain only seats observed at both rounds. No threshold is applied.

| Phase | Arm | Starting line | Rounds | Median ratio | Per-round factor | Same-survivor median ratio (n) |
|---|---|---|---:|---:|---:|---:|
| pre_start_initial_auras | control | line_birds_homecoming | 10–12 | 1.924 | 1.387 | 1.763 (29) |
| pre_start_initial_auras | control | line_birds_homecoming | 12–14 | 1.535 | 1.239 | 1.550 (26) |
| pre_start_initial_auras | control | line_birds_homecoming | 14–16 | 1.883 | 1.372 | 1.746 (23) |
| pre_start_initial_auras | control | line_birds_tempo | 10–12 | 1.843 | 1.358 | 1.882 (31) |
| pre_start_initial_auras | control | line_birds_tempo | 12–14 | 1.814 | 1.347 | 1.732 (27) |
| pre_start_initial_auras | control | line_birds_tempo | 14–16 | 1.944 | 1.394 | 1.460 (24) |
| pre_start_initial_auras | control | line_fairies_ring | 10–12 | 1.466 | 1.211 | 1.370 (27) |
| pre_start_initial_auras | control | line_fairies_ring | 12–14 | 1.868 | 1.367 | 1.636 (19) |
| pre_start_initial_auras | control | line_fairies_ring | 14–16 | 1.574 | 1.255 | 1.437 (13) |
| pre_start_initial_auras | control | line_fairies_court | 10–12 | 1.820 | 1.349 | 1.619 (23) |
| pre_start_initial_auras | control | line_fairies_court | 12–14 | 1.573 | 1.254 | 1.763 (14) |
| pre_start_initial_auras | control | line_fairies_court | 14–16 | 2.897 | 1.702 | 1.484 (8) |
| post_fight_live_recruit | control | line_birds_homecoming | 10–12 | 1.858 | 1.363 | 1.831 (29) |
| post_fight_live_recruit | control | line_birds_homecoming | 12–14 | 1.550 | 1.245 | 1.550 (26) |
| post_fight_live_recruit | control | line_birds_homecoming | 14–16 | 1.864 | 1.365 | 1.746 (23) |
| post_fight_live_recruit | control | line_birds_tempo | 10–12 | 1.859 | 1.364 | 1.882 (31) |
| post_fight_live_recruit | control | line_birds_tempo | 12–14 | 1.814 | 1.347 | 1.732 (27) |
| post_fight_live_recruit | control | line_birds_tempo | 14–16 | 1.944 | 1.394 | 1.500 (24) |
| post_fight_live_recruit | control | line_fairies_ring | 10–12 | 1.466 | 1.211 | 1.370 (27) |
| post_fight_live_recruit | control | line_fairies_ring | 12–14 | 1.868 | 1.367 | 1.636 (19) |
| post_fight_live_recruit | control | line_fairies_ring | 14–16 | 1.574 | 1.255 | 1.437 (13) |
| post_fight_live_recruit | control | line_fairies_court | 10–12 | 1.820 | 1.349 | 1.619 (23) |
| post_fight_live_recruit | control | line_fairies_court | 12–14 | 1.573 | 1.254 | 1.763 (14) |
| post_fight_live_recruit | control | line_fairies_court | 14–16 | 2.897 | 1.702 | 1.587 (8) |
| pre_start_initial_auras | aggressive | line_birds_homecoming | 10–12 | 2.720 | 1.649 | 2.213 (31) |
| pre_start_initial_auras | aggressive | line_birds_homecoming | 12–14 | 2.318 | 1.522 | 2.194 (27) |
| pre_start_initial_auras | aggressive | line_birds_homecoming | 14–16 | 2.512 | 1.585 | 2.071 (25) |
| pre_start_initial_auras | aggressive | line_birds_tempo | 10–12 | 2.235 | 1.495 | 2.027 (32) |
| pre_start_initial_auras | aggressive | line_birds_tempo | 12–14 | 2.129 | 1.459 | 2.102 (30) |
| pre_start_initial_auras | aggressive | line_birds_tempo | 14–16 | 1.996 | 1.413 | 2.112 (29) |
| pre_start_initial_auras | aggressive | line_fairies_ring | 10–12 | 1.459 | 1.208 | 1.280 (25) |
| pre_start_initial_auras | aggressive | line_fairies_ring | 12–14 | 1.788 | 1.337 | 1.362 (21) |
| pre_start_initial_auras | aggressive | line_fairies_ring | 14–16 | 2.398 | 1.549 | 1.544 (10) |
| pre_start_initial_auras | aggressive | line_fairies_court | 10–12 | 1.683 | 1.297 | 1.459 (22) |
| pre_start_initial_auras | aggressive | line_fairies_court | 12–14 | 2.234 | 1.495 | 1.883 (13) |
| pre_start_initial_auras | aggressive | line_fairies_court | 14–16 | 1.563 | 1.250 | 1.938 (8) |
| post_fight_live_recruit | aggressive | line_birds_homecoming | 10–12 | 2.622 | 1.619 | 2.293 (31) |
| post_fight_live_recruit | aggressive | line_birds_homecoming | 12–14 | 2.318 | 1.522 | 2.194 (27) |
| post_fight_live_recruit | aggressive | line_birds_homecoming | 14–16 | 2.512 | 1.585 | 2.071 (25) |
| post_fight_live_recruit | aggressive | line_birds_tempo | 10–12 | 2.235 | 1.495 | 2.027 (32) |
| post_fight_live_recruit | aggressive | line_birds_tempo | 12–14 | 2.129 | 1.459 | 2.106 (30) |
| post_fight_live_recruit | aggressive | line_birds_tempo | 14–16 | 1.996 | 1.413 | 2.113 (29) |
| post_fight_live_recruit | aggressive | line_fairies_ring | 10–12 | 1.459 | 1.208 | 1.282 (25) |
| post_fight_live_recruit | aggressive | line_fairies_ring | 12–14 | 1.788 | 1.337 | 1.340 (21) |
| post_fight_live_recruit | aggressive | line_fairies_ring | 14–16 | 2.398 | 1.549 | 1.544 (10) |
| post_fight_live_recruit | aggressive | line_fairies_court | 10–12 | 1.683 | 1.297 | 1.472 (22) |
| post_fight_live_recruit | aggressive | line_fairies_court | 12–14 | 2.234 | 1.495 | 1.883 (13) |
| post_fight_live_recruit | aggressive | line_fairies_court | 14–16 | 1.588 | 1.260 | 1.938 (8) |

This is a descriptive trajectory check. The tables supply no automatic 'runaway round'. Interpret the round-by-round levels and changes beside the two human trajectories, survival, and flight coverage. Poor engine assembly remains a limitation of the inherited bot shopping policy.

## Reading the result

Current B (2× normal and golden homecoming) can compound rapidly when the carry is flown consistently. The first measured interval, R10–R12, already shows that acceleration; separation from the native control is clear at R12 and large at R14–R16. For Homecoming, the post-fight board median is 180, 472, 1,094 and 2,748, versus control 176.5, 328, 508.5 and 948. Median same-survivor board growth is 2.293×, 2.194× and 2.071× over those successive two-round intervals. This supports rapid compounding rather than only a change in which players survive.

The largest active unit's median A+H is 79.5, 212, 408 and 1,010. The supplied human A boards are 329/772/2,085/2,676; human C boards are 272/459/883/1,617. Human C's biggest unit is 140/264/510/974, nearly doubling every two rounds from R10. The script probes this one decision while retaining native shopping/other flight choices; it does not establish optimal human play or add a runaway pass/fail threshold. The control exactly matches 613 historical native pre-start snapshots at R10/R12/R14.

The 32+32 lobbies use the shipped current wave-1 B pool at f9c924b9, including the context of the human logs, rather than the later d5b5b4f8 Bog/Fairies rebase. Both normal and golden homecoming remain 2×, caps and loop guards are on, heroes/fights/damage/eliminations/pool depletion are native.

## Rebuilding the report

```sh
python3 tools/sim/skilled_birds.py report --plan tools/sim/evidence/wave1-skilled-birds-plan.json --control tools/sim/evidence/wave1-skilled-birds-control.jsonl.gz --aggressive tools/sim/evidence/wave1-skilled-birds-aggressive.jsonl.gz --output build/sim/skilled-birds-rebuilt.json
```

Full captures, sufficient board rows, source/helper hashes, human reference blobs, and native test logs are archived beside the report. The extraction command above rebuilds the measurements; this reading and validation footer are added by the committed finalization driver.

Native Godot compute: control 75.028s, forced carry 75.628s. Full final gate: 1909 tests / 42495 assertions, strict hook clean. Focused flight checks and banned-card smoke passed.
