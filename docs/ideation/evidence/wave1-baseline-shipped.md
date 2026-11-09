# Wave 1 five-tribe baseline: shipped

Five-tribe lobbies conditioned on including Birds and Fairies; one committed seat per written line plus four blind Hard seats. Other three tribes follow the actual seeded game rotation. Not the unconditional shipped lobby population.

Same eligible seed set across cap settings; shop comparisons are unpaired because purchases and pool use desynchronize draws.

320 lobbies; source `f9c924b9bc1fff68509b55666268ebd81d71664f`; execution wall 2161.0s.

Only growth and realized committed R12 medians decide this step. Other numbers below are reported, not pass/fail.

| Population | Pre-start R8–R14 growth | Seed 95% interval |
|---|---:|---|
| all_seats | 1.301 | [1.290, 1.312] |
| committed_seats | 1.372 | [1.362, 1.386] |

| Starting line | R12 median [seed 95% interval] | R12 survivors | p90 | ≥2× line median | Lobby wins | Fight wins R8–14 | R14 alive |
|---|---|---:|---:|---:|---:|---:|---:|
| line_birds_homecoming | 311.000 [281.000, 339.000] | 303 | 695.000 | 11.9% | 35.3% | 73.1% | 269/320 (84.1%) |
| line_birds_tempo | 302.500 [275.000, 335.000] | 300 | 638.200 | 11.3% | 30.9% | 70.2% | 259/320 (80.9%) |
| line_fairies_ring | 142.500 [135.000, 148.500] | 228 | 267.300 | 8.3% | 9.4% | 43.9% | 142/320 (44.4%) |
| line_fairies_court | 163.500 [156.000, 181.000] | 202 | 330.900 | 11.4% | 9.4% | 42.0% | 115/320 (35.9%) |

Round summaries contain surviving seats only, with counts and R14 survival reported. No zero imputation. Whole-lobby seed bootstrap retains empty/eliminated clusters.

All line grouping uses immutable starting line; final line is retained separately.
