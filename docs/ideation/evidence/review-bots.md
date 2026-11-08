# Review: bot yardstick, profiling and the carrier promotion

8 November 2026. Fresh cloud reviewer. Target `origin/ideation/main...origin/ideation/bots` (head `88e971e`; the Acorn Stash candidate was read only as tooling). Scope came from the owner's words in `2026-11-08a-bots-and-data.md` and `2026-11-08b-remove-easy-medium.md`, plus `BOTS.md` and its interrogation. No code on `ideation/bots` was changed.

**Counts: 14 items. 9 keep, 3 simplify, 0 cut, 2 ask.**

**Does it move the problem? Yes.** The owner asked for "the best players we possibly can" and for bots that "get better". The paired 4-against-4 yardstick makes "better" measurable, and the promoted carrier rule is a real gain. It is small but it held up on fresh seeds: **+0.048 ±0.042 places on 500 new paired seeds (161001–161500)**, against +0.0465 ±0.0415 in the original trial.

- **Ask 1:** The 0.15 floor was dropped *after* carrier had failed it. That is a post-result rule change, which the interrogation's "set 'clearly' in numbers before the first candidate" forbids. This replication confirms the gain. Record it in `DECISIONS.md` as the confirmation, and require the same fresh-seed confirmation run for any future rule change made after a result.
- **Ask 2:** Keep or delete the failed `reactive_saving` candidate (116 lines plus 73 lines of tests in the gate). There's no rule for failed candidates yet.
- **Simplify 1:** The headline of `bots-yardstick.md` (line 7) still defines "clearly better" with the 0.15 floor, and the carrier section still says "NO PROMOTION / stop rule reached". Put the current rule at the top and mark the old text as superseded where it appears.
- **Simplify 2:** `summarize_bench.py`'s timing table prints only the `naive` and `hard` aliases. A head-to-head against any other alias (`old_hard`, `acorn_stash`) loses one arm's turn time. Group the table by the aliases that actually ran.
- **Simplify 3:** `tools/sim/candidates/carrier_upgrade.gd` is now an empty `extends BotBrain`. Point the registry alias at `BEST_BRAIN` and delete the file.

## Fresh-seed rerun (the headline check)

**Setup.** I ran it in this cloud VM (4 cores) with the editor binary, not the release pack. I made a scratch copy of `88e971e` and added one review-only alias, `old_hard`: a BotBrain subclass whose `_unit_gain` and `_clear_slot_for` call `_ordinary_*`, which is pre-promotion Hard. None of this was committed.

**Parity check.** On a separate seed (162001, 2 pairs), the scratch copy ran `hard` against `old_hard`, and the frozen candidate commit `5fb9f79` ran `carrier_upgrade` against `hard`. The players, rounds and cards CSVs were byte-identical after relabelling. So the promoted Hard really is the frozen candidate, and `old_hard` really is the old Hard.

**Declared before running:** a primary sample of 161001–161200 (200 pairs, as briefed) and an extension of 161201–161500 (300 pairs), both reported whatever they showed. No interim looks, no stopping, no tuning, and no seed range reused from earlier trials.

| Sample | Paired seeds / games | Gain ±95% (Student t over seeds) | Bootstrap 95% | Seeds: + / 0 / − |
|---|---:|---:|---:|---:|
| 161001–161200 (primary) | 200 / 400 | +0.055 ±0.068 | [−0.009, +0.124] | 66 / 83 / 51 |
| 161201–161500 (extension) | 300 / 600 | +0.043 ±0.054 | [−0.011, +0.098] | 109 / 105 / 86 |
| **161001–161500 (all)** | **500 / 1,000** | **+0.048 ±0.042 [+0.006, +0.090]** | [+0.008, +0.090] | 175 / 188 / 137 |
| Original trial 131001–131500 | 500 / 1,000 | +0.0465 ±0.0415 | — | — |

- The 200-seed primary alone doesn't exclude zero. That is expected: its precision is about ±0.07, and the effect is about 0.05.
- The full 500-seed fresh run reproduces the original almost exactly. Pooled over 1,000 fresh seeds, the gain is about +0.047 ±0.030.
- 38% of seeds have zero difference, because the rule only fires on a full board offered a tier-4+ engine. The bootstrap agrees with the t interval, so that zero spike doesn't distort the margin.
- Other outcomes for promoted vs old Hard seats: top 4 50.5% vs 49.5%, wins 13.1% vs 12.0%.

**Turn time** in the same run, both arms under the same 4-shard load: promoted Hard 96.39 ms mean / 226.08 ms p95, old Hard 95.23 / 224.33. That is +1.2% mean and +0.8% p95, matching the branch's own <1% figures. Seven bots at 96 ms take about 0.67 s on this VM core; the assumed 3× phone factor makes that about 2.0 s. The phone aim was already unmet before this change, and no device has been timed.

## Is the yardstick honest?

I read `bench_suites.gd`, `summarize_bench.py`, `hard_stream.gd` and the `game_session.gd` factory.

- **Seat swapping:** keep. Each seed shuffles 8 seats with its own RNG and takes 4 per side. Leg 2 exchanges the labels while keeping the same game seed, so any seat or first-mover bias cancels within each seed.
- **Strategy dealing:** keep. The deal happens in `BotLobby.resolve` before the factory picks a policy. The summarizer rejects a seed whose strategies differ between legs or whose sides didn't swap.
- **Statistics:** keep. Each seed gives one observation (the mean of its two legs), with a Student t interval over seeds, never over 8 seats. The t95 expansion is correct. Missing or duplicated pairs raise an error.
- **No early stopping or reused seeds:** confirmed. Every range (91k, 111k, 121k, 131k, 141k/151k) was declared in the evidence file before its result was written, and the recorder refuses partial samples. The carrier trial reused the old-Hard A/A, which is fair, since the incumbent and the rules were unchanged.
- **A/A arm:** keep. `hard_stream` is exactly Hard with its bot-choice seed XOR-permuted once. That gives equal strength by construction and different play in practice: the A/A margin is ±0.163, not 0. Caveats:
  - The A/A sees mostly-different games, while carrier-vs-Hard games are mostly identical. So the A/A says nothing about the candidate interval's width; the candidate's own seed variance sets that, which is correct.
  - A/A coverage is one pass, as the doc already says.
  - The A/A for the promoted Hard (141001) is queued with Acorn Stash and has not run.

## Does the carrier rule play like a strong human?

I added a scratch-only print to `BotCarrier.clear_slot_for` and watched 8 promoted-Hard lobbies (seeds 163001–163008). There were **20 distinct carrier sales: 18 made room for Standing Committee, 2 for Grizel, 1 for Peat King.** In practice the rule is "make room for a late aura engine".

- **Most sales were bodies a strong player would sell** for a +2 Attack aura on a full late board: Cricket Busker 2/2, Hob 1/3, Spitfire Sal 1/3, Mr Redbreast 1/2, Sexton Beetle 2/4, Little Nip 6/5.
- **Marginal ones:**
  - Old Moth Annis 9/9 sold for a *second* Committee (gain score 2.0).
  - Hedge Witch 8/10 sold for a Committee.
  - Bridge Toad 8/14 sold for a second Peat King at 15 health.
  - A golden Great Lump 2/8 sold: goldens aren't protected, only unpaired-copy pairs are.
- **No large or buffed carry was thrown away.** The rule never sold a 13+/20 unit. The "large real carry" test covers that case, and Wee Wobbly 13/20G, Peat Cutter 50/49, Dozey 23/26 and Old Lutra 23/27G all stayed.

My verdict is that it plays like a reasonable human here. The narrow trigger (mostly Committee) is why the gain is small.

## Other checks

- **Profiling "identical play":** confirmed independently. In a scratch copy of head, I reverted `combat.gd` to `7529183` and made the placer re-score the base layout per candidate. On spread seeds 81001–81004 with `trace=on`, the trace, players, rounds and cards files had identical hashes before and after (400 turn records). Wall time was 40.7 s vs 38.3 s.
- **Tests for the promotion:** keep. When I reverted `BotBrain._unit_gain` and `_clear_slot_for` to the ordinary path, **5 of 10** carrier tests failed, including `test_player_facing_hard_uses_the_promoted_policy`. The tests do guard the promotion.
- **Gate:** `./scripts/check.sh` at `88e971e` **passed all steps: 1,288/1,288 Godot tests, 16,271 asserts**, Python checks green, 2 min 56 s.
- **Keep, no further probing:** the profile hooks and `compare_bots.py`; the release-pack builder and parity checks (I didn't rerun them, because my run used the editor); the ranked-gap list (a hypothesis list, as labelled); and the combat payload guards.

**Not run:** the release-pack path, a phone timing, a `play.sh` hand game (I used bench logs instead), the promoted-Hard A/A at 141001, and the Acorn Stash trial.

## Summary

The yardstick is honest: seats swap within each seed, strategies stay fixed across legs, there is one observation per seed, the t interval is correct, and seed ranges were declared up front. The profiling claim of identical play holds. The promotion is backed by tests. The floor was dropped after the result, but carrier's gain replicated on 500 fresh seeds: +0.048 ±0.042 (the 200-seed primary alone was +0.055 ±0.068). Turn time rose about 1%. Its sales mostly look like strong play. Fix the stale headline and the timing table, log this confirmation, and decide what to do with failed candidates.
