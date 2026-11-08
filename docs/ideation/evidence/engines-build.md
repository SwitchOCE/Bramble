# Engines build

Base: `25c68bf`, branch `ideation/engines`. The orchestrator adopted item 2, item 3 (including tester B’s two corrections), then item 1, each as a separate commit. These are normal rules; there are no prototype switches. Showcase cards and the dropped Kin spells/Hand-me-down are not included.

## Rules and regressions

- Harvest Supper is tier 3, still 3 gold, once a turn and capped at +3/+3. The real shop test samples tiers 1–3; existing ownership, summons, dual-tribe and golden tests remain.
- Last Four lifts the cap at four living heroes, fixed for the round’s fights. Last Stand is player state, once per game, saves a lethal hero loss from 2+ Health after Armor, never ghost damage or draw tolls. Tests cover 2, 5 and 40 Health, Armor, reuse and a real session result.
- Last Blow tracks lethal damage ownership independently of Pounce/Take ownership. Simultaneous exchange damage credits the attacker; subsequent lethal effects credit their owner on the side they fight for. A Start of Combat wipe, no-attacks or safety-limit ending remains a tie. Mrs Posset, swapped Posset, both attack orders and the four-damage floor have directed regressions. Bitter in this source reduces Attack, so cannot itself kill; it does not steal credit.

The card detail names Supper’s tier; fight results show Last Blow, damage arithmetic, the lifted cap and a triggered Last Stand. Your hero and scouted opponent panels record Last Stand ready/used. All three are taught in the guide. Desktop and phone result text is checked at the existing font minimum; guide page bounds remain unchanged.

Soak coverage reports counts and an explicit `never fired` list for Harvest Supper, Last Four, Last Stand and Last Blow. An empty event stream is tested to list every rule; a synthetic event is not presented as natural coverage.

## Ring experiment

The candidate was implemented as real recruit/combat arithmetic, with full value on Fairies and half on other units, rounding each merged Ring’s Attack and Health down. It was tested separately from the three adopted items. The [exact candidate patch](engines/ring-trial.patch.txt) and hand saves accompany this report. The Ring calculation is shared with the probe, so biggest-unit Ring attribution measures the value actually received.

The owner’s [bot evidence note](../../design/owner-notes/2026-11-08a-bots-and-data.md) limits what the full-strength bot bench can establish. Same-seed runs use `tools/sim/engines_probe.gd`; only completed seeds present in both arms enter the paired comparison. Round-10 and round-15 carrier figures sample at the fight observer after carry and hero damage, before elimination, and use boards with six or more units, choose the biggest by Attack + Health (reading-order tie), and divide its actual Ring contribution by its stats. Tier 1–2 carrier share uses the same boards. Fairy pick share is Fairy unit purchases / all unit purchases. Fairy place uses full boards with four or more Fairies at the sampled round. Rounds count the complete lobby, not the human’s exit.

Reproduce the paired summary with `python3 tools/sim/summarize_engines.py <base log> <Ring log>`. Intervals resample paired seed differences, 1,000 samples, fixed bootstrap seed 86100. Small samples and bot play are not human balance evidence.

The bounded pilot completed four paired seeds, **86100–86103**. Both longer probe processes were deliberately stopped after those common completed games; partial games are excluded. There are no script errors in the retained runs. This is a pilot, not a powered balance study.

| Metric | Three items | Half to non-Fairies |
|---|---:|---:|
| Biggest-unit Ring share, round 10 | 16.02% | 8.19% |
| Biggest-unit Ring share, round 15 | 24.27% | 7.23% |
| Tier 1–2 biggest carriers, round 10 | 35.71% | 32.74% |
| Tier 1–2 biggest carriers, round 15 | 12.50% | 25.00% |
| Fairy unit purchase share | 8.17% | 7.39% |
| Fairy-board place, round 10 (2 paired seeds) | 3.0 | 4.0 |
| Fairy-board place, round 15 (1 paired seed) | 1.0 | 1.0 |
| Lobby rounds | 17.5 | 18.25 |

The mechanical Ring-share reduction is clear in these seeds; cheap-carrier share is not improved reliably (round-10 change −2.98 percentage points, paired interval −30.36 to +21.43; round 15 moves the other way). Fairy outcomes do not supply positive support. The tiny sample cannot establish balance or harm. [Full comparison and sample counts](engines/ring-comparison.json), [base rows](engines/ring-base.jsonl), [candidate rows](engines/ring-trial.jsonl).

## Hand games

Both games use `tools/play/play.sh`, normal shops and human-selected actions; the saves contain their complete accepted action lists. Searches for a Ring source were bounded repeated refreshes, not a bot making decisions. Refused targeting commands were not saved. No units, gold or shop offers were injected.

**A — seed 86203, Brother Bracken, 8th in round 10.** [Accepted actions](engines/ring-hand-a.json). A low-tier Fairy line sought Nan, Sally and Spore Cloud, then climbed to tier 4 for tech. Sally made empty Rings, Nan moved onto the +3/+3 Ring, and a tier-1 Witch kept another Ring. Nan reached 6/5 with +3/+3 from the slot and +1/+1 from Pinch. A non-Fairy Wasp on a +1/+1 Ring received nothing. At 3 Health the round-9 loss used Last Stand; replacing Mag Pye with Changeling across the scouted 7/15 Gideon did not prevent elimination next round.

**B — seed 86202, Little King Wren, 8th in round 9.** [Accepted actions](engines/ring-hand-b.json). The mixed Hunter/Fairy line bought Nan, three Boundary Stones and Supper for Fairies. On the +3/+3 Ring, Little Nip became 3/2; moving Hedge Witch onto it gave 4/5. The Ring eventually reached +9/+9 and the tier-1 Witch 11/12, including +1/+1 Supper. Switching in Mag Pye to strip a scouted Lodger was worth losing the tiny Ring’s Fairy bonus, but did not rescue the game. Last Stand saved the round-8 loss from 7 Health; the next loss eliminated the hero. [Round boards and results for both games](engines/ring-hand-results.json).

These were agent hand games with mistakes and unspent gold, not optimized human strategy or balance estimates. One early stale-index purchase in A bought One Swallow instead of the intended Nan, and an occupied-slot attempt in B was refused. The frozen candidate snapshot kept the same real rules while final verification ran on production. The last manually chosen action groups used a candidate-only CLI batch helper: it calls the unchanged `PlayGame.run` and writes each accepted action separately, without choosing actions or changing rules. The saved action lists replay through the ordinary play tool after applying the candidate patch; no batch helper is required to reproduce them.

**Orchestrator’s call: leave the Ring candidate out.** Four paired seeds give no reliable carrier or Fairy improvement, and the hand games demonstrate that a cheap Fairy still takes the full Ring pile. Halving neutral recipients narrows a slot choice without establishing a better upgrade decision; rounding down makes a +1/+1 Ring useless on a non-Fairy. Neither placements nor the tiny bot pilot are evidence of a balance verdict. The adoption condition (support from both bench and hand play) is unmet. Production retains full Ring value for every unit, with no experiment switch and no experimental rule commit.

## Visual evidence

Rendered and inspected at 1920×1080 and 1688×780. The fight-guide page initially overlapped its footer on phone; it was shortened twice and rendered again at the original type size. Final inspected evidence:

- Supper detail: [desktop](engines/screens/commit_harvest_1920x1080.jpg), [phone](engines/screens/commit_harvest_1688x780.jpg).
- Last Blow and cap arithmetic: [desktop](engines/screens/engines_blow_1920x1080.jpg), [phone](engines/screens/engines_blow_1688x780.jpg).
- Last Stand: [phone result](engines/screens/engines_stand_1688x780.jpg), [hero status](engines/screens/engines_hero_1688x780.jpg).
- Guide: [endings on phone](engines/screens/guide_10_1688x780.jpg), [Supper on phone](engines/screens/guide_11_1688x780.jpg).

No real phone or audio was tested. Screenshots are staged real-engine states, not naturally encountered hand-game screenshots. Layout checks keep their original minimums.

## Final checks

The focused engine/UI/guide regression run passed **15/15 tests, 184 assertions**. The full gate’s first final run passed through compilation (375 files, zero failures), then passed 1,266/1,268 tests. Its failures were the state-key contract missing `last_stand_used`, and a placement fixture whose pre-elimination combat damage now changes under Last Blow. The contract is updated and the placement test calls the actual elimination routine directly. No game rule or UI minimum was weakened.

**Final verification completed successfully on the engines build at `920def7`.**

- **Gate:** `./scripts/check.sh` passed every step, including compilation of 375 files and **1,268/1,268 tests, 16,173 assertions**, with the strict GUT hook passing. The final test run took 287.829 seconds. [Retained gate log](engines/final-gate.log.txt); original wrapper log `/tmp/engines-final-gate2.log`, GUT log `build/check/gut.log`. The managed exec returned exit **0**.
- **Fresh-seed soak:** `taskset -c 2 timeout 1200 tools/checks/soak.sh 100 88500` passed **100 games**, seeds **88500–88599**, **1,684 rounds**, **5,363 fights**, and **zero violations**, exit **0**, in 1,082.4 seconds. All slice cards fired. Engine coverage recorded Harvest Supper **285**, Last Four **349**, Last Stand **219**, Last Blow **86**; the engines `never fired` list is empty. One no-attacks ending was reported without a violation. [Retained soak log](engines/final-soak.log.txt); original wrapper log `/tmp/engines-final-soak2.log`, detailed log `build/check/soak.log`.

The gate and soak ran concurrently in this worktree and shared its import cache. Both completed successfully, and neither their wrapper logs nor the GUT/soak detail logs contain parse, load or script errors. The user's sequential-rerun condition therefore did not apply; no sequential retry was needed. Their successful results supersede the earlier interrupted jobs and the initial gate's corrected legacy-test failures.

Both jobs used writable temporary Godot user-data directories, since the sandbox cannot write the machine's default user-data location. All compute ran on core 2. No pushes or denied approvals.

Production core sources have been unchanged since the final soak began; later edits shorten guide copy, correct legacy tests and write records. The candidate is isolated in ignored `build/engines-ring-trial/`; it is not a branch, worktree or production switch.


## Integration after verification

Merged `origin/ideation/main` at `88ed352e46bdfa1f07f7a1e499abb86c3a96a1cc` after committing the completed validation records. The incoming commit changes only `docs/ideation/DECISIONS.md`; its build-5 review note and three-item adoption call are retained alongside all engines implementation and Ring-trial decisions. A line-preservation check found no missing additions from either side. This merge changes documentation only (the decision log and this integration record). Per the user's instruction, no gate, soak or other runtime checks were repeated after this docs-only merge.
