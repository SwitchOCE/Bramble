# Sim run `ooze-a-20261110-r2`

- Commit: `ee65a55df33086ae0071f2d5d2da01db14dcd758`
- Kind: lines, suite ooze_probe, preset B
- Lobbies: 32 seeds over 8 shards; rates overrides: {"oozes_aspic_bonus": 0.75, "oozes_bubble_belly": 1, "oozes_bubble_splits": 1, "oozes_dollop_belly": 1, "oozes_dollop_discount": 1, "oozes_eat_printed_multiplier": 2, "oozes_elder_share": 0.5, "oozes_frumenty_meals": 1, "oozes_golden_aspic_multiplier": 2.5, "oozes_golden_elder_multiplier": 2.0, "oozes_golden_soup_reads": 2, "oozes_granny_attack_multiplier": 1.0, "oozes_hasty_release_deaths": 3, "oozes_hasty_share": 0.3333333333333333, "oozes_hasty_swallows": 1, "oozes_moss_golden_reduction": 25, "oozes_nell_meals": 1, "oozes_pie_gold": 1, "oozes_posset_loss_share": 0.5, "oozes_slice_count": 1, "oozes_slice_share": 0.2, "oozes_soup_share": 0.125, "oozes_syllabub_fires": 1, "oozes_wobbly_drip": 1}
- Timing: config commit to merge 120 s; run https://github.com/SwitchOCE/Bramble/actions/runs/42754146300
- Dropped trials: 0

Files: `summary.json` (quilboar_h1_report.summarize, plus `sim_job`), `B.lobbies.json.gz` (compact per-lobby records). Raw fight captures are the workflow run's artifacts (7 days).

| Line | R12 pre-start median | R12 boards | Growth R8-R14 |
|---|---:|---:|---:|
| B hard | 386 | 31 | 1.3944 |
| B line_birds_homecoming | 283.0 | 32 | 1.3303 |
| B line_bog_engine | 143.0 | 12 | 1.2376 |
| B line_fairies_ring | 338.0 | 32 | 1.5200 |
| B line_hedgerow_engine | 104.0 | 14 | 1.5027 |
| B line_hunters_engine | 108.0 | 10 | - |
| B line_oozes_engine | 352.0 | 28 | 1.3274 |
| B line_oozes_tempo | 265 | 31 | 1.3262 |
