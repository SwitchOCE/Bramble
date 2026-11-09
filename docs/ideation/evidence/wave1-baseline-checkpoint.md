# Wave 1 five-tribe baseline: checkpoint

Five-tribe lobbies conditioned on including Birds and Fairies; one committed seat per written line plus four blind Hard seats. Other three tribes follow the actual seeded game rotation. Not the unconditional shipped lobby population.

Same eligible seed set across cap settings; shop comparisons are unpaired because purchases and pool use desynchronize draws.

320 lobbies; source `f9c924b9bc1fff68509b55666268ebd81d71664f`; execution wall 1214.2s.

Only growth and realized committed R12 medians decide this step. Other numbers below are reported, not pass/fail.

| Population | Pre-start R8–R14 growth | Seed 95% interval |
|---|---:|---|
| all_seats | 1.303 | [1.295, 1.315] |
| committed_seats | 1.371 | [1.357, 1.384] |

| Starting line | R12 median [seed 95% interval] | R12 survivors | p90 | ≥2× line median | Lobby wins | Fight wins R8–14 | R14 alive |
|---|---|---:|---:|---:|---:|---:|---:|
| line_birds_homecoming | 311.000 [291.975, 336.000] | 303 | 662.000 | 10.9% | 32.8% | 71.5% | 262/320 (81.9%) |
| line_birds_tempo | 294.000 [279.000, 312.000] | 295 | 607.400 | 10.5% | 23.1% | 69.6% | 259/320 (80.9%) |
| line_fairies_ring | 153.000 [148.000, 160.000] | 237 | 277.600 | 7.2% | 10.3% | 44.6% | 141/320 (44.1%) |
| line_fairies_court | 167.000 [160.000, 183.000] | 215 | 330.200 | 9.8% | 10.9% | 42.1% | 120/320 (37.5%) |

Round summaries contain surviving seats only, with counts and R14 survival reported. No zero imputation. Whole-lobby seed bootstrap retains empty/eliminated clusters.

All line grouping uses immutable starting line; final line is retained separately.
