# Wave 2B build

Base: local `ideation/main` 722f5ae4. Part 1 builds Oozes only; Hedgerow, neutrals and prototype retirement await their separate hand-offs. No full local gate; targeted checks below, cloud gate at hand-off.

## Oozes: what was built

All 16 named Oozes retain their portraits and use the pass 3 bodies and rules. Slice is a tribeless Created unit. The old Ooze definitions are frozen alongside the pass 2 Birds/Fairies/Bog/Hunters rollback tests until step 5 of plan v3; prototypes remain in the live pool until part 4.

| Support item | Implementation |
|---|---|
| 1 Digest | Ordered Start of Turn Belly eating, LIFO, pool returns, own base/permanent stats |
| 2 Eat, Aspic | One public meal pipeline; strongest Aspic per eater, non-Ooze bonus guard |
| 3 Soup | Live shop aura layer, committed once into permanent stats on purchase or Nell meal; best Soup only |
| 4 Selectors | Filtered own-board ranking, excluded source, next-to ranking, unfrozen lowest-tier shop; shared biggest-enemy selector reused |
| 5 Nell | After Digest; distinct eaters, bigger first, skips frozen offers |
| 6 Moss | Friendly come-out Shield, golden DR25%, including Granny's returned family |
| 7 Bubble | Damaging-hit requirement; halves cannot split; normal/golden split budgets |
| 8 Frumenty | Persistent last-meal definitions feed the existing borrowed-text machinery |
| 9 Elder | Shares original meal stats, board only, after the biggest Ooze eats a non-Ooze |
| 10 Hasty | Empty Belly, biggest eligible enemy, see-through holder swallow, permanent gain from current stats and existing releases |
| 11 Posset | Actual damage source retained for death; killer's current stats reduced, golden same-row neighbours |
| 12 Granny | Cleave and dependent late gather, releases family intact |
| 13 Slice | Fractional body sent to hand, golden widens to two, full hand loses it |
| 14 Replay | Existing see-through reused; starting-Belly survivor damage remains an opt-in replay flag |
| 15 Limits/bodies | Removes Wobbly/Figgy old limits; updates all authored bodies |
| 16 Lines/bot | Engine and Pot Luck JSON; feeding, transfer, second stomach, positions, engine protection and Hasty scout policy |
| 17 UI | Drawn ladle/pot/jelly meal marks and Elder landing pulse; Digest/Soup explanations in reader, transient placement marks |

## Readings and limits

- Presets override the synthesis's tenth and README's earlier resize. Provisional B Soup is **1/8**, Elder **1/2**; C Soup **1/6**, Elder **3/4**. No existing tribe dial changes. C is its own override map, not a blanket multiplier.
- Every new rate uses the paper key and value. Other B/C values are the same in both: golden Elder multiplier 2; Aspic bonus 0.5/golden multiplier 2; Nell meals 1; Bubble Belly 1; Dollop Belly 1/discount 1; Slice share 0.2/count 1; Hasty share 0.2/swallows 1/release deaths 3; golden Soup reads 2; Granny Attack multiplier 1; Posset loss share 0.5; golden Moss DR 25%; Bubble splits 1; Pie gold 1; Wobbly Drip stats 1; Frumenty meal history 1; Syllabub firings 1. Golden counts double unless the design explicitly widens or preserves the fraction.
- Soup reads displayed board stats, while eating reads a meal's base plus permanent stats. A shop meal first locks in its live Soup bonus. A bought unit keeps that bonus when Soup leaves. Frozen status applies to the whole retained shop (the existing game has no per-offer freeze).
- Soup is a shop aura: Shy offers receive no bonus and buying them commits none (review call applying rulebook 12.1.7). Non-Shy bonuses commit before buy listeners.
- Nell excludes herself: "the biggest Ooze next to this" requires another slot. Ties use reading/shop order. She eats one offer per distinct eligible eater, without refilling the shop between meals. Digest precedes Nell and Slice regardless of their board slots. Other tribes' ordinary Start of Turn text follows this dependent sequence; homecoming keeps its existing earlier timing.
- Elder checks whether the eater was biggest immediately before the meal. Distinct Elders each trigger; printed and borrowed copies on one body use the strongest once. The design explicitly restricts Soup and Aspic across bodies, but gives Elder no such restriction.
- Hasty's native Belly capacity follows the swallow-count dial, so a harness sweep can really widen its target count; borrowed Hasty still uses its carrier's own Belly. Tiny Slices keep the game's minimum one Health.
- Frumenty records the meal's printed definition and golden state, not its temporary grants or accumulated counters. A triple retains the most recent available histories in copy order, up to the golden history size. Digest and empty native dispatcher markers cannot be borrowed; the underlying Bubble/Wobbly/Pie/Syllabub/Figgy rule can.
- Borrowed Figgy really pairs bought copies from Frumenty's Belly without a cooldown. Printed and borrowed Hasty/Granny choose the strongest text once per Start of Combat dispatch; distinct Syllabub replays are new dispatches. Hasty counts actual friendly death identities once. Pass 3 Syllabub can replay its own carrier's other opening text and uses the strongest duplicate firing count.
- Granny's "after your other Start of Combat effects" creates a dependency on Hasty. Resolve both sides' ordinary starts and existing Bog sequence, then remaining stat-ranked answers/Hasty, then both Grannies, then globally final Jack Daw. In a mirror, both Hasties see the pre-gather board. This keeps the existing pool order deterministic and avoids making the gathered family's permanent gain depend on random side order. It differs from the synthesis's illustrative Hasty-eats-gathered-Granny mirror; the dependent timing requirement takes priority.
- Posset removes floor(share × current stat), with Attack at least zero and Health at least one; a dead killer stays dead. Her killer reference comes from the actual damage source, including effect damage.
- Moss's golden reduction uses the existing DR status with its actual 25% value; Tom Tit keeps 50%. The strongest applicable protection wins. Granny returns the family as a batch so Moss can protect siblings that precede it in release order.
- Golden Wobbly releases all held contents on a surviving damaging hit, LIFO, while gaps remain. With no gap, the remaining contents stay inside; a loaded hit never also makes a Drip. This follows the collective face text rather than carrying forward the prototype's one-pop implementation.
- UI item 17 follows the brief's minimum: no new static explanatory labels. Hover carries previews and rules. Existing face chips remain until declutter ports wordless faces.
- A committed Ooze seat may buy off-tribe food straight into a Digest Belly; that food never becomes an off-build board unit. Normal pin flexibility remains before R4 or with fewer than three board bodies. Food respects line bans.
- Low-roll paper row: **remove Stone Soup**, not merely delay it. This is documented here rather than added as an unsupported line-loader key.
- Condition/trigger audit: Digest, Nell and Slice can fire every Start of Turn even at T6; Elder fires on meals, Aspic and Soup are live queries, Figgy fires on a bought pair, and combat rules check the fight state. No Cluricaun-style tier-up/late-condition dead end. Early Dollop and Posset are flexible Belly/economy or answer bodies; Wobbly provides bodies. Soup counts itself, but its unbuffed 2/3 body yields zero shop stats at B after rounding; it needs a larger/buffed Ooze to enable the engine. Nell's text is inactive without another Ooze, and Moss's without friendly Belly releases. Those early tribal conditions are retained as designed, rather than redesigned.

## Validation and measurements

All 17 support items are implemented. **The per-line growth criterion is unfinished: Pot Luck remains below ×1.3 at the paper B rates.** No rates were raised to hide that gap. Hedgerow, neutrals, Click Beetle and prototype retirement are not started.

The targeted runs passed **496 unique GUT tests**, including **88 new tests** covering authored normal/golden faces, known rule answers, loop-guard counterexamples, borrowing, bot routes and UI. This is the union of recorded focused runs, not a claim that the full suite ran. The Python checker tests passed **19/19**; content validation reported **0 problems**. Changed GDScript files passed format/lint; the changed Python checker passed ruff. No new GUT script plays a whole game or lobby. The full gate is left to cloud, as instructed.

| New script | Tests | Observed seconds |
|---|---:|---:|
| `tests/core/test_pass3_ooze_content.gd` | 7 | 0.677 |
| `tests/core/test_pass3_ooze_recruit.gd` | 19 | 7.991 |
| `tests/core/test_pass3_ooze_combat.gd` | 27 | 11.138 |
| `tests/core/test_pass3_ooze_start.gd` | 13 | 5.401 |
| `tests/core/test_pass3_ooze_bots.gd` | 17 | 12.141 |
| `tests/ui/test_pass3_ooze_ui.gd` | 5 | 0.806 |

Timings are observed suite times from the saved runs; the UI figure is its isolated GUT run. Every listed script has a successful result. Exact historical replay still matches all eight original cases; fixture bytes were not re-recorded. Historical ordinary-gather tests now use explicit synthetic ordinary gatherers, while native Granny's dependent timing has separate tests. Pass 2 Oozes are frozen for legacy suites. A source-card-count assertion now compares against its captured baseline because Slice adds one library definition; the immutability assertion remains.

### Native 32-lobby B measurement

The two-lobby pilot took **12.348 and 15.442 seconds**, projecting about 7.4 minutes for 32, below the one-hour cutoff. The final run took **439.0 seconds** (438.803 summed lobby seconds). Each admitted natural five-tribe lobby contains one engine line, one Pot Luck line and six varied Hard opponents. The driver reuses bench output/capture plumbing; bench and BenchSuites were not edited.

Growth is `(median_R14 / median_R8) ** (1/6)`, using active Attack+Health **before Start of Combat**, excluding Bellies. Eliminated seats have no later observation; they are not zero-filled. Survivor counts therefore matter.

| Line | R8 median (n) | R12 median (n) | R14 median (n) | Growth/round | ×1.3 |
|---|---:|---:|---:|---:|---|
| Engine | 87 (32) | 262 (26) | 572 (21) | **1.369** | pass |
| Pot Luck | 88 (32) | 200 (23) | 337 (12) | **1.251** | **fail** |

Pooling both available line cohorts gives **×1.303**, but this does not establish that both lines pass. Individual round medians and sample counts are in the summary JSON; this is an average across six intervals, not a claim each individual interval exceeds ×1.3.

Reported-only results:

- R12 median: **262 engine / 200 Pot Luck / 250 pooled**, against 900 (29.1% / 22.2% / 27.8%). Including Bellies, the line medians are **285.5 / 248**.
- Paper accounting against the paper table's shared Ooze B R12 figure **978**: **0.268× engine / 0.204× Pot Luck / 0.256× pooled**. These are below the reported 0.5–2× band. They are not line-specific paper predictions.
- Normal Hard seats bought Oozes on **49/3,582 off-build offers (1.37%)**, versus **268/444 own-build offers (60.36%)**. Counts use unique offers, all rounds, and the primary tribe of the final strategy; early flexible buying is included. Ooze line food purchases are excluded. This is under the current pin rules and is not a strength estimate.
- Click Beetle's homecoming effect is deferred to the neutral part; Click Beetle is not in this library yet.

Two measured bot bugs were fixed without changing rates: Pot Luck buried 11 of 28 acquired Bubbles/Frumenties in its first run, so the first useful Digest carrier now gets played and protected; it also protected/valued Aspic despite keeping its pot in the back row, so that inactive Aspic is now replaceable. Both fixes have directed Hard/committed-line tests. The first run's growth was ×1.325 engine / ×1.254 Pot Luck. The final result above is after both fixes; **the remaining Pot Luck growth/accounting gap is open**, with all 38 prototypes still present as required by the build order.

All **1,930 final captured fights refought exactly**, outcomes and event hashes, on the final source (34.314 seconds). A prior diagnostic run predating the last borrowing fix had 39 event-only differences and no changed outcomes; it is not used as the final result.

### Committed evidence and hand-off

Evidence is under [`docs/ideation/evidence/wave2b/`](../../evidence/wave2b/):

- `oozes-final.jsonl`: complete final per-lobby measurements, resolved rates, board snapshots and offer/buy counts.
- `oozes-summary.json`: medians, sample counts, growth, accounting, splash and seed list.
- `oozes-before-pot-fix.jsonl`: original 32-lobby diagnostic for the carrier-routing bug.
- `oozes-timing.log`, `oozes-final.log`, `oozes-refight.log`: completed timing/final/refight runs.
- `targeted-results.json` and the copied focused logs: test-file counts and times.

Reproduction command after importing the project, sourcing `/opt/bramble/env.sh`, and taking only the harness lock:

```sh
flock /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G timeout 2500 godot --headless -s res://tools/sim/wave2b_lines.gd -- suite=lines tribe=Oozes games=32 first_seed=280001 out=build/wave2b/ooze-lines-final capture=on
```

Open for the next session: scope review and cloud full gate; the Pot Luck ×1.3 growth failure and low realized accounting; the explicit rule readings above (subsequent review corrections are recorded below). No push or merge was performed. No automatic approval review denied an action. Part 2 must wait for the orchestrator's next instruction.

### Part 1 cloud gate assertion and documentation corrections

Slice adds one loadable unit definition while remaining outside the shop pool. The
UnitLibrary and FixturePort assertions therefore change from 157 to 158; the
fixture's created-card subtotal changes from nine to ten. Pool expectations stay
the same. These assertions still check exact counts rather than weakening the
library completeness checks.

The follow-up tribe chip test now expects `Comes out` for native Moss Ooze, matching
its new friendly Belly-release trigger. `Spells inside` described its retired
spell-copying text and no longer identifies the current card. Both normal and
golden faces retain the explicit chip assertion.

The card-designer engine guide now lists `on_eat`, with the eater in `subject` and
the consumed meal in `meal`, so the existing schema-name documentation test covers
the new shared meal event. The content checker was also run through the repository's
Ruff formatter; its logic is unchanged by that formatting correction.

The unit-view contract now explicitly includes `ooze_share_serial`, a zero-based
landing-animation serial exposed on every recruit view. The existing conditional
Ooze mark/preview fields remain conditional. The shop fixture test checks its zero
initial value; no historical fixture JSON was altered for this addition.

Soup is a shop aura, so Shy offers receive zero live bonus and buying them commits
no Soup stats (rulebook 12.1.7). The known-answer recruit test covers both Soup
qualities with Silky. Elder's reader now separates “No sale gold.” from “Only other
Oozes”. Slice receives its own 512px JPEG portrait; the reproducible prompt is
`tools/art/prompts/wave2b-slice.txt`, generated with Codex's built-in image tool via
`tools/art/run-codex-image.sh` with stdin closed, and exported by `portraits.py`.
The portrait completeness count increases by one for Slice, to 120.

The reported Last Blow failures were old-rule assertions running the replacement
Posset, which halves a living killer rather than dealing the legacy 3 damage.
The equality assertion between logged and quiet results was already passing; the
old winner/source/kind expectations were failing. Those old assertions now use
explicit frozen Ooze definitions, with no changed expected values. New native
normal/golden checks compare logged and quiet results for attack/effect kills and
swapped fighting sides, including RNG state, credit and the death-event killer.
No fast-path attribution mutation was found behind event logging. Posset now
resolves `killed_by` through `CombatLanes.by_uid` and drops the duplicate reference
map, as called in review. Hasty snapshots the enemy's current Attack/Health before
swallowing changes aura membership; known answers include a real Ring and added
tribe/aura/combat layers.

The legacy Elder release tests likewise now select frozen Ooze definitions. The
legacy Dozey bound remains +8/+8: native Frumenty's prior Digest adds the meal's
+2/+5, explaining the extra stats. Separate native and rollback tests check both
steps. Neither legacy rule implementation was changed for those fixture fixes.

Free-choice's knowledge-isolation assertion passed. Its value-difference assertion
failed because the native Ooze fallback bypassed authored hints in both arms.
Unmodeled native abilities now fall through to ordinary BotEval; directed checks
assert the plain tier fallback, authored hinted value and unchanged shared data.

First targeted validation: **179/179 tests across 17 files, 65.036 seconds**, strict
hook clean, including all seven mandatory content-wide files plus both engine UI
and core tests and all five Ooze suites. Per-file times and full output are in
`docs/ideation/evidence/wave2b/part1-fixes/targeted-initial.json` and `.log`. Ruff,
GDScript formatting/lint and the content checker's 19 Python tests also pass.

### Normal-game regression: rollback leak fixed, no re-record

The new `return_inside` hook called legacy Syllabub whenever *any* pass 3 content
was enabled. That enabled a new Start of Combat replay for frozen pass 2 Ooze
returns. The added return path now selects only native Syllabub sources; the
original Belly-pop path still invokes the old plain/golden replay unchanged. A
fixed mixed-board test combines native Chiffchaff with archived Syllabub and
checks both cases. The first version of this new test used raw IDs where the
helper requires board specifications; the final run corrects that setup.

With this code fix, **all four original normal-game hashes match**, including
seed 17's `e1d564be89246d3879463beea109b36997df4ee7ed8661794ab8b452467ecf28`.
The cloud's `d9a976d8…` mismatch was a rollback regression, not a new baseline to
adopt. `test_field_normal_regression.gd` and every field fixture remain unchanged.
No re-record was needed or performed; no assertion was loosened.

Final targeted run after the complete fixes: **182/182 across 18 files**,
**121.603 seconds**, strict hook clean. This includes the original exact replay
and all seven mandatory content-wide files. Full output and per-file times are
in `part1-fixes/targeted-final.log` and `targeted-final.json`. Content validation:
165 files, zero problems; Ruff formatting/lint and changed GDScript checks pass.
Hasty and Soup's reader text and rulebook now state the corrected current-stat
and Shy rules; normal/golden Details tests also prevent Elder's missing space.
No local full gate was run.

## Part 2: Hedgerow light pass

The sixteen pass 3 Hedgerow cards replace their same-ID live definitions. The
separate 38-body retirement remains part 4. Frozen Hedgerow definitions are kept
in `tests/core/data/pass2_hedgerow_units.json`; old-rule fixtures select them
explicitly, retaining current content for other tribes.

`Pass3HedgerowText` generates faces and parameters from the selected preset.
`Pass3Hedgerow` owns recruit clocks, late wakes, source snapshots and gains;
`Pass3HedgeCombat` owns the Hunker aura, summon sharing and positional throws.
All sixteen audit entries are explicit; none selects the biggest enemy.
B/C values are the paper values; no other tribe's dials changed.

| Dial | B | C |
| --- | --- | --- |
| `hedgerow_beadle_pass` | 2 | 2 |
| `hedgerow_burdock_kits` | 1 | 1 |
| `hedgerow_clover_share` | 1.0 | 1.0 |
| `hedgerow_committee_share` | 0.25 | 0.25 |
| `hedgerow_crumb_pass` | 1 | 1 |
| `hedgerow_crumb_sell_share` | 1.0 | 1.0 |
| `hedgerow_dozey_food_per_gold` | 2.0 | 2.0 |
| `hedgerow_dozey_period` | 3 | 3 |
| `hedgerow_dozey_wake_multiplier` | 2.0 | 3.0 |
| `hedgerow_golden_dozey_wake_multiplier` | 2.0 | 3.0 |
| `hedgerow_hayward_per_gold` | 1.0 | 1.0 |
| `hedgerow_larder_gold` | [1, 5, 16] | [1, 5, 16] |
| `hedgerow_lollop_share` | 0.1 | 0.1 |
| `hedgerow_mallow_multiplier` | 2.0 | 3.0 |
| `hedgerow_mallow_targets` | 2 | 2 |
| `hedgerow_mast_cap` | 5 | 5 |
| `hedgerow_mast_gold_step` | 5 | 5 |
| `hedgerow_partner_acorns` | 2 | 2 |
| `hedgerow_partner_period` | 3 | 3 |
| `hedgerow_pym_pass` | 3 | 3 |
| `hedgerow_sergeant_share_per_gold` | 0.1 | 0.1 |
| `hedgerow_sergeant_throws` | 1 | 1 |
| `hedgerow_sorrel_summons` | 1 | 1 |
| `hedgerow_treasurer_per_gold` | 1.0 | 2.0 |
| `hedgerow_urchin_bristle` | 2 | 2 |
| `hedgerow_urchin_hunker_targets` | 1 | 1 |

Readings and limits:

- A wake includes standing tribe stats once, but not slot/fight auras; its new
  permanent increment survives moves. Golden wake strength is its own dial,
  not a second application of the ordinary multiplier.
- Dozey wakes after ordinary End of Turn effects and queued Passes. Repeated
  wake/Partner clocks and Mallow multiplications are guarded; other ordinary
  End of Turn growth remains eligible for legitimate extra triggers.
- Source sharing is a reusable native snapshot helper: Clover reads its current
  source, Committee freezes its runt, and all Lollops freeze the global biggest
  before any Lollop growth. Biggest ties use reading order; smallest ties zigzag.
- Hayward's bonus is a standing ownership layer, including later purchases and
  held units. Shop offers preview that layer, as the synthesis specifies; buying
  keeps the same layer and does not turn it into a permanent buff. It is separate
  from Harvest Supper and has no cap.
- Mast retains only its named rate guard; caps-off removes it. Its payout can
  combine into larger Larder items immediately, counted as actual item events.
- Larder item values are an actual three-element dial, rewriting gold paid and
  reminders. Captures whose frozen rates predate it keep their original items.
- UI reuses the hand header and reader; clock pips, selected-clock reset outline,
  runt circle and live Hunker shield add no static explanatory labels.
- The strict line JSON supplies Supper and Parish. Treasury remains an ordinary
  strategy, cashing out on R13. Engine pieces are protected through the existing
  replacement check, including the full-board purchase path. Supper holds food
  until a wake; Parish cashes and grows its floor. Clock placement respects
  real wake timing, with a deliberate move only in the free post-wake turn.
- Paper low rolls remove the keystone: Dozey for Supper, Mallow for Parish. These
  are paper policies, not unsupported keys in bot line JSON.
- Trigger/condition audit: repeatable wake and Partner clocks continue at T6;
  Mallow/Committee/Treasurer act every End of Turn, Lollop/Mast every Start of
  Turn, and Hayward/Pym/Beadle require actual item events. No tier-up-only trap.
- Early flexibility: Burdock/Sorrel provide bodies and summons without commitment;
  Crumb's Pass can feed another tribe; Partner can make food counting itself;
  Pym can use generic Larder acquisition. Clover's text needs Hedgerow summons
  and is weak alone outside that package; no redesign was made.

Intermediate checkpoints exposed strict helper typing, duplicate no-op markers,
native timer pins, frozen-rate item handling and an old-content bot cash policy.
These were fixed without loosening the legacy assertions or re-recording any
field fixture. The 70-test native checkpoint and 14-test rollback checkpoint
are retained in the evidence; the completed checks below supersede their WIP
status.

### Part 2 route fidelity and final source checks

Both line files' complete priorities and climb schedules match the synthesis
exactly (`hedgerow/route-fidelity.json`). Their saving rule is the exact next-turn
discounted climb shortfall after income and promised income, not a flat reserve:
Supper keeps 3 at R6 in the directed case, Parish 4 at R5. Tests use actual
BenchSuites-created CommittedLineBrain instances. That exposed and fixed omitted
purchase-timing/copy hooks, unscheduled early climbs, and held food incorrectly
backing purchases/refreshes that should preserve banked climb gold. These fixes
are conditional on native Hedgerow; the generic other-tribe early-climb checks
and original complete-game replay still pass.

Hayward now previews its standing bonus on shop offers, without making it a
permanent shop buff; buy and Belly storage retain it exactly once. This corrects
the earlier ownership-only reading against the synthesis's explicit shop line.
Lollop may read a big Shy unit as a source; immunity still excludes Shy recipients.
A recruit printed-plus-borrowed Clover case shows strongest-once growth, and the
extra growth when that shared guard is disabled.

Every seat-round now logs gold, shop tier, Larder gold and full nested Belly
contents by top-level holder slot, alongside pre-start stats. The report includes
both active-only and including-Belly growth, survivor counts, matched R14 cohorts
and raw per-seat ratios. Known neutral builds count as off-build in splash;
missing strategies remain separate. Its eight synthetic tests pass and its
Ooze cross-check reproduces the previous 1.368714/1.250810 growth and 49/3582
off-build purchases exactly. Paper per-line B R12 references are 979 (Supper) and
870 (Parish), from `presets-model/six.json`; `six.py:31` identifies their order.

Final source validation: **185/185 across 18 targeted files, 227.400s**, including
all seven mandatory content-wide files and original replay hashes; checker and
report Python checks **29/29**. `gdlint src tools`, `(cd tests && gdlint .)`,
`ruff check tools/`, and `ruff format --check tools/` all pass. The requested
FixturePort line wrap is isolated in `157c65e4`. Per-file counts/times are recorded
in `hedgerow/targeted-final.json`; the full 37-file baseline was 360/360.

The final two pilots took **12.617s and 15.529s**, mean **14.073s**, projecting
**7.506 minutes** for 32. Telemetry keys and tiers were verified. The completed final remeasurement is recorded below. No local full gate ran.

Final cross-tribe turn-order correction: Lollop's frozen snapshot belongs after
the existing Digest → Nell → Slice dependent sequence, before ordinary Start of
Turn dispatch. A mixed Digest/Lollop board proves the normal/golden share reads
the pot's 200/200 after eating rather than its prior 100/100. This preserves
rulebook 12.1.9; the same 32 seeds are remeasured after this correction.

### Part 2 completed hand-off

Both deciding criteria pass. All sixteen cards have authored/default generated
normal/golden text checks and fixed known-answer behavior coverage: **80 new GUT
tests** across six scripts. The latest targeted runs are **185/185**, the final
cross-tribe Start of Turn checks **41/41**, and all seven mandatory content-wide
files **59/59** on the final source. The earlier broader compatibility run passed
**360/360 across 37 files**. No new test plays a whole game or lobby. Python
checker/reporter tests pass **29/29**. Both requested repository-wide GDScript
lint commands and both tools-wide Ruff commands pass.

At B, **32 complete line lobbies**, 32 distinct admitted seeds, ran in
**356.452 seconds** (5.94 minutes). There were no lobbies ending before R14.
The one-line-growth rate is `(R14 median / R8 median)^(1/6)`; eliminated seats
are absent, never replaced with zero.

| Line | Active growth | Including Bellies | R8/R12/R14 survivors | R12 active median | /900 | /paper R12 |
| --- | ---: | ---: | --- | ---: | ---: | ---: |
| Supper | ×1.615 | ×1.611 | 32 / 25 / 19 | 730 | 0.811 | 0.746 |
| Parish | ×1.848 | ×1.848 | 32 / 24 / 20 | 1,094.5 | 1.216 | 1.258 |

Both exceed **×1.3**. Both R12 accounting ratios fall within **0.5–2×**;
this is reported evidence, not an additional deciding criterion. Pooled R12 is
**874** across 49 surviving seats, **0.971×** the 900 reference.

For the same seats alive entering R14, Supper's matched medians are **186 →
2,500** (×**1.542** a round); its median individual seat growth is ×**1.480**,
19 pairs. Parish is **167 → 4,600** (×**1.738**), median individual growth
×**1.723**, 20 pairs. Including Bellies gives the same paired values. Full raw
seed/seat pairs and each round's medians are in `hedgerow-summary.json`.

Normal Hard seats' Hedgerow purchases per unique offer: **110/2,975 = 3.697%**
off-build, **371/614 = 60.423%** own-build. This includes early flexible buying,
excludes line food purchases, and groups by the final build's declared primary
tribe. Known neutral builds are off-build; there were no unknown strategies.
This is an adoption count, not proof of relative strength.

The turn-order correction was remeasured on the exact same seed list. Its
constructed mixed board differs as intended; all recorded pre-start rows in
these 32 lobbies were unchanged. Hero tier jumps remain legal (notably March
Hare); the written schedule governs the bot's upgrade actions. Common early
flexibility and neutral fillers remain shared brain behavior. The paper's
special neutral-two-tiers-higher rule through R6 has no separate implementation.
Late feeder pairs may still be completed into a golden. Optional Treasury is
supported by the normal bot, not a third committed measurement line. These are
policy readings/limits; no Hedgerow card or dial remains unfinished.

Final new-script times (fixed boards only):

| Script | Tests | Seconds |
| --- | ---: | ---: |
| `test_bot_hedgerow.gd` | 18 | 10.283 |
| `test_pass3_hedge_recruit.gd` | 19 | 12.234 |
| `test_pass3_hedge_shares.gd` | 6 | 9.557 |
| `test_pass3_hedge_content.gd` | 9 | 0.103 |
| `test_pass3_hedge_combat.gd` | 24 | 13.600 |
| `test_pass3_hedge_ui.gd` | 4 | 0.391 |

Reporter synthetic tests: **8 in 0.03s**. The captured lobbies are the sole
measurement input; no extra test lobby was added.

Evidence under `docs/ideation/evidence/wave2b/hedgerow/`:

- `hedgerow-lines.jsonl`: all seat-round rows, gold, tier, Larder, full nested Bellies and unique-offer purchase counts.
- `hedgerow-summary.json`: both growth views, raw paired seats, sample counts, accounting, splash, source revision and exact seeds.
- `hedgerow-fights.jsonl.gz`: full combat-boundary captures, including resolved rates, for replay.
- `hedgerow-players.csv`, `hedgerow-rounds.csv`, `hedgerow-cards.csv`, `hedgerow-lines.log`: completed lobby records.
- `measurement.json`: final source and data hashes; `targeted-final.json`, `start-order.json`, `content-wide.json`: test-file counts/times and corresponding logs.
- `route-fidelity.json`, `timing.json`, and the four lint logs: policy, cost and check evidence.

No push or merge was performed. No action was denied. Part 3 and prototype
retirement have not started. Pot Luck route arms and constructed-board work are
queued separately, following the orchestrator's new call.

### Explicit instruction deviation and queued Pot Luck protocol

For the part 1 Elder repair, I declined the requested production-code-only
remedy. The test loaded the replacement live Elder rather than its archived
pass 2 definition; I rebound it to frozen Ooze content while preserving every
expected value. The analogous legacy Posset and borrowed-Dozey assertions were
also isolated rather than changing their expected rules. The actual Syllabub
rollback leak was fixed in production code. This deviation should have been
flagged explicitly in the original hand-off.

Pot Luck's next measurements will use a same-commit, same-seed, same-count
control with no route change, plus save-3, Dollop-priority and combined arms.
The old 1.251/1.37 outcomes are historical only. Primary comparison will use
R14-surviving seats' matched R8/R14 medians, with survivor-median growth and
share alive beside it. No arm has been measured yet. The orchestrator's specified
main-merge resolutions (combat gem/replay union, checker union, wrapped fixture
message) are recorded for the next merge; no merge was performed here.
