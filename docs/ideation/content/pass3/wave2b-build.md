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
| 10 Hasty | Empty Belly, biggest eligible enemy, see-through holder swallow, own-body permanent gain and existing releases |
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
- Shop-offer reading: Soup is applied before ownership and committed before buy listeners, including on Shy offers. Owned Shy immunity then applies normally. This is a build reading of “shop units”, not an owner ruling; it remains a specific interaction for scope review.
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

Open for the next session: scope review and cloud full gate; the Pot Luck ×1.3 growth failure and low realized accounting; the explicit rule readings above, especially shop bonuses on Shy offers. No push or merge was performed. No automatic approval review denied an action. Part 2 must wait for the orchestrator's next instruction.

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
