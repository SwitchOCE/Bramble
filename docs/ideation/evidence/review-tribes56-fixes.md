# Tribes 5 and 6: cloud-review follow-up

Owner calls on the [cloud review](review-tribes56.md), implemented on ideation/tribes56.
No strength or bot tuning is authorised in this follow-up.

- **Cut 1:** Dr Urchin redirects Pack pricks to the leader; per-hit Pass right remains.
  Normal/golden slice regression plus lone attacker: 2 tests/11 assertions. Commit fe79acc.
- **Ask 2:** lenders use their existing Quarry keyword instead of “At the”; no fourth tribe
  keyword. 3 tests/19 assertions. Commit 90b9cb6.
- **Ask 6:** positive native Take events satisfy the on_take coverage alias. A zero count still
  reports the gap; synthetic named effects remain accepted. Real Nip trade and negative tests.
  Commit 1a41340.
- **Ask 1:** completed under 30 minutes (about eight minutes after Ask 2). Tray chips show
  current kisses and total Bitter; the selected detail explains native plus adjacent aura totals.
  Golden Nan/Chorus, native Bitter, both rows, moving, state immutability and rendered chips
  have directed tests. Combined UI run: 29 tests, 2,974 assertions; no script errors.

Four phone and two desktop previews were rendered with tests/ui/render_screens.sh and inspected.
The lead inspected selected phone [frog](review-tribes56-frog-phone.jpg) and
[Bufo](review-tribes56-bitter-phone.jpg): Kiss 2/3, Bitter 6 = 2 printed + 4 beside, with stats
and economy/Sell/End controls readable.

**Ask 3:** current-slot tags distinguish repeated names in UI and play logs, including movement,
summons and transformations. Borrowed Mire/Bitter are named. Silent target queries and a distinct
Mired-kill reward remove phantom Snap lines. Transient buffs skip dead recipients; a permanent
trade reward carries to recruit without healing/reviving its combat copy or emitting live stats.
Peat King's full-board fizzle is visible in the play tool and does not spend a summon.

Dedicated real-slice regressions: 20 tests/163 assertions; 35 existing scripts: 487 tests/1,632
assertions. Both runs pass strict hooks. [Phone log](review-tribes56-log-phone.jpg) rendered and
inspected by implementation and lead reviewers. Damage, lethal debuffs and deaths remain visible.

## Ask 5 measurement method

Compare all eight seats' last-fight scout unit IDs with the opponent's recruit-board snapshot at
fight time, before the bell/start-of-combat effects. Each observed unit is exactly one of: same
ID in the same slot, same ID in another slot, or absent from that fight board. Absent includes
sales, triples, swallowing, Fly South and benching; a same-named replacement does not count as
the original. Report same-slot share of all seen units and, separately, of those still present.

Report printed-Mire cards (including the Chorus) and top-Attack units (ties included) as two
additional categories. Top Attack is an explicit carry proxy, not a claim to identify every
carry. New additions make the whole identity layout different. Exclude round-one empty scouts
and ghost fights. This is slot/identity retention, not an audit of changed stats, card text,
transformations, Nests, slot effects or hero predictions.

The read-only tool uses fight_observer and existing fought_view snapshots; bots, placers,
information and budgets are unchanged. Five tests/15 assertions cover swaps, identical-card
replacements, absence, stat changes, new additions, tied maxima and snapshot lifetime. A separate
one-Normal/one-Hard pilot (seeds 75590–75591) verified the observer and is excluded from the
recorded sample. Planned sample: 24 Normal and 12 Hard full unpinned games, seeds 75600–75635.

## Ask 5 results

Completed **36 full games** at gameplay head `255b777`: 24 Normal (seeds 75600–75623) and
12 Hard (75624–75635), before the requested ideation/main merge. Command:
`taskset -c 2 godot --headless -s res://tools/sim/scout_retention_probe.gd -- 24 12 75600`,
after sourcing `/opt/bramble/env.sh`. No bot/placer/information/budget change. No aborted
measurement games; the separate two-game pilot is excluded. Raw [per-game and per-round
counts](review-tribes56-scout.json) agree with the level totals; category partitions were checked.

| Bots | Category | Seen units | Same slot | Moved | Absent | Same slot among still present |
|---|---|---:|---:|---:|---:|---:|
| Normal | All units | 14,229 | 9,586 (67.4%) | 2,569 (18.1%) | 2,074 (14.6%) | 78.9% |
| Normal | Printed Mire | 1,838 | 995 (54.1%) | 589 (32.0%) | 254 (13.8%) | 62.8% |
| Normal | Top Attack | 3,060 | 2,355 (77.0%) | 572 (18.7%) | 133 (4.3%) | 80.5% |
| Hard | All units | 7,067 | 4,370 (61.8%) | 1,692 (23.9%) | 1,005 (14.2%) | 72.1% |
| Hard | Printed Mire | 810 | 400 (49.4%) | 290 (35.8%) | 120 (14.8%) | 58.0% |
| Hard | Top Attack | 1,433 | 1,053 (73.5%) | 308 (21.5%) | 72 (5.0%) | 77.4% |

Combined: **13,956/21,296 (65.5%)** scouted units stayed in
their slot; 4,261 moved and 3,079 were absent from the next fight board. Among
units still present, 76.6% stayed in slot. This mix weights Normal/Hard games 2:1.

Normal: 368/2,604 (14.1%) identity layouts were unchanged, including empty slots.
Hard: 146/1,290 (11.3%) identity layouts were unchanged, including empty slots.

These are repeated unit/round observations from fixed seeds, not independent draws or a causal
placement/strength benchmark. Unchanged identity does not imply unchanged stats or text. Normal
drafting and useful moves both make scouts stale; this measurement does not judge whether moves
were sensible. The pending reveal-rule experiment may change the relevance of these rates.
Per the owner, **Ask 4: no tuning**; the bench will settle strength and bot tribe rates.

Final full gate and seed-53 100-game soak will be recorded below. Ask 4 remains a deliberate
hold on tuning until the bench reports.


## Main merge and final validation

Integrated origin/ideation/main through **e579fd1** after the six separate work-item commits.
The only textual conflict was PLAN's status block; it now describes the six-tribe review work.
Upstream round-3 corrections, compact phone names, late-shop tap sizes and their tests are kept.
Approved upstream Dozey limits are imported as requested; no new tuning or bot edits are made.
The Ask 5 number is explicitly the pre-merge six-tribe measurement at 255b777, not a post-merge
comparison or a reveal-rule experiment.

Pre-merge checkpoint: full gate PASS, 1,136 tests across 92 scripts, 14,030 assertions.
Final merged full gate: **PASS**, all steps, **1,143 tests across 93 scripts**, 14,113 assertions,
244.7 seconds of GUT tests. Command: `source /opt/bramble/env.sh; taskset -c 2 ./scripts/check.sh`.
Reproduce the pre-merge Ask 5 sample at commit `4ceb444` (tool/data commit; gameplay base
255b777). **Final merged soak: PASS**, `taskset -c 2 tools/checks/soak.sh 100 53`: 100 games, seeds
53–152, 1,743 rounds and 5,341 fights, **zero violations**, exit 0, 202.4 seconds. Directed
copy/text-transfer, Bog and Hunter checks completed first. 5,338 fights ended with a board empty;
three with neither side able to attack; no attack/trigger-limit finishes. All slice cards
recorded activity. **771 native Takes** are recorded and `trigger:on_take` is absent from the
not-reached line, which now lists only on_home/on_swallow. Other keyword-alias reporting limits
remain as already logged; no broader collector cleanup or strength tuning was attempted.

Post-merge `tests/ui/render_screens.sh recruit_bog_preview_select recruit_late` at 1688×780:
both pass and were visually inspected by the lead. The [selected frog preview](review-tribes56-merged-preview-phone.jpg)
keeps Kiss 2/3, Bitter totals, full rules and actions readable alongside the incoming name/layout
fixes. The [late recruit](review-tribes56-merged-late-phone.jpg) keeps the full board, shop,
hand summary, stats and controls readable. The gate also includes the incoming selected-card
phone tap-size tests with eight offers.

All owner-authorised Cut/Ask work is complete in separate tested commits, followed by the main
merge. Ask 4 remains no tuning; no bot files were edited. No approval was denied. Broader human
playtesting, strength/positional-gain benchmarks and the reveal-rule experiment were not run.
