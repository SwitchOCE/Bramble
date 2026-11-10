# Ceiling triage

The one-billion Attack/Health getter ceiling already works. Reaching it is not itself a rules hole. The hole is Hedgerow `own_stats`: the permanent layer keeps growing, and narrowing 2.4 billion into `Vector2i` wraps negative. The Mallow ×3 read then subtracts 3,789,934,588 Attack instead of gaining 2 billion. Clamp the read to the existing unit ceiling before narrowing; preserve the permanent layer and exclusion of aura/fight buffs.

Known answer: `test_capped_mallow_reads_own_stats_before_narrowing_to_vector` fails four assertions without the fix and passes with it. Combined targeted run: 17/17 tests pass (`build/b9-content/bugs-before.log`, `bugs-after.log`). No new gameplay cap is introduced.
