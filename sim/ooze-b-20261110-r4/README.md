# Sim run `ooze-b-20261110-r4`

- Commit: `f3b21fe1cfb065caeee97a77ee5186f6ae4cb3d8`
- Kind: lines, suite ooze_probe, preset B
- Lobbies: 32 seeds over 8 shards; rates overrides: {"oozes_aspic_bonus": 1.8, "oozes_bubble_belly": 1, "oozes_bubble_splits": 1, "oozes_dollop_belly": 1, "oozes_dollop_discount": 1, "oozes_eat_printed_multiplier": 7, "oozes_elder_share": 1, "oozes_frumenty_meals": 1, "oozes_golden_aspic_multiplier": 4.6, "oozes_golden_elder_multiplier": 2.0, "oozes_golden_soup_reads": 2, "oozes_granny_attack_multiplier": 1.0, "oozes_hasty_release_deaths": 3, "oozes_hasty_share": 1, "oozes_hasty_swallows": 1, "oozes_moss_golden_reduction": 25, "oozes_nell_meals": 1, "oozes_pie_gold": 1, "oozes_posset_loss_share": 0.5, "oozes_slice_count": 1, "oozes_slice_share": 0.2, "oozes_soup_share": 0.3, "oozes_syllabub_fires": 1, "oozes_wobbly_drip": 1}
- Timing: config commit to merge 180 s; run https://github.com/SwitchOCE/Bramble/actions/runs/42755593213
- Dropped trials: 0

Files: `summary.json` (quilboar_h1_report.summarize, plus `sim_job`), `B.lobbies.json.gz` (compact per-lobby records). Raw fight captures are the workflow run's artifacts (7 days).

| Line | R12 pre-start median | R12 boards | Growth R8-R14 |
|---|---:|---:|---:|
| B hard | 740 | 31 | 1.5593 |
| B line_birds_homecoming | 365 | 31 | 1.3679 |
| B line_bog_engine | 161.5 | 10 | 1.5202 |
| B line_fairies_ring | 351.5 | 32 | 1.4634 |
| B line_hedgerow_engine | 89 | 13 | 1.8286 |
| B line_hunters_engine | 102.0 | 8 | - |
| B line_oozes_engine | 1205.5 | 30 | 1.4580 |
| B line_oozes_tempo | 736 | 31 | 1.4029 |
