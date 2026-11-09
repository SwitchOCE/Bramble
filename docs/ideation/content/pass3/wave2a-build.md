# Pass 3 wave 2A build

Branch: `ideation/wave2a`, based on `f574eaf`. Work is split into three reviewed commits: pool rules, Bog folk, then Hunters. This document records each checkpoint, its readings and remaining limits. Bog is implemented below; Hunters awaits its separate review step.

## Item 1: pool rules

- Hunters' permanent Take rewards and Bog's Soak rewards use `PendingGains`. Combat records the amounts without changing the fighting body's stats or healing it. Carry transfers the same identity-based queue to recruiting; the next Start of Turn drains it before arrivals, homecomings and ordinary turn listeners. Dead fighters retain their rewards. Combat-only tokens have no permanent body to reward. Combining copies retargets their queued rewards to the golden body without doubling them; rewards for bodies no longer owned are discarded.
- A compact numeric `+Attack/+Health` badge shows the accumulated pending gain during combat, including on a departing card while it fades. Its existing one-tap reader explains the timing. The graphical and play-tool fight logs report each queued increment without implying an immediate buff or heal. Fading-card lookup and cleanup skip freed controls. No new main-screen reminder was added, following [owner note 09e](../../../design/owner-notes/2026-11-09e-ui-clutter-and-tutorials.md).
- Pack joiners cannot Cleave in pass 3. The leading attack still Cleaves normally. The existing diagnostic `pass3_loop_guards` switch reproduces the old joiner splash in a counterexample test.
- The existing source-independent extra-trigger guards also cover manually repeated When played contexts. Scripted scale-engine growth now uses the same guard: extra triggers cannot repeat a doubling (including a golden half-rate engine that doubles) or move a countdown. Fractional and flat growth can still repeat. Guard-off tests demonstrate the otherwise repeated doubling and countdown movement. Future tribe doublers must provide the existing repeat index; no new doubler is introduced in this commit.
- `scale_hero_spell_stats` follows pass 3 content by default. Explicit on/off overrides remain available for comparisons. The existing scaling formula is retained: each positive printed stat point becomes 10% of the corresponding recipient stat, with the printed gain as a floor and fractions rounded down. Effects without a recipient use occupied-board averages. The percentage is now a JSON dial. Counted Ring spells keep their printed Ring count rather than scaling it into dozens of Rings.
- Harvest Supper has no pass 3 size ceiling and retains its once-per-turn guard, including when ordinary rate limits are disabled. With scaling enabled, its shared +Attack/+Health step is the percentage of the lower board average, minimum +1/+1. Its bot valuation uses the same eligibility rules. Legacy capped Supper remains available when pass 3 is off.
- Wave 1 already supplies biggest-enemy-last Start of Combat and Belly see-through. Those paths were checked and retained; their existing tests remain.

### Presets and provisional rates

The orchestrator relayed `docs/design/owner-notes/2026-11-09h-generous-power-first.md` from local `ideation/main`: start generous and cut back. The note is not present at this branch's base. `rates.json` now contains a shared numeric rate map plus A/B/C overrides; `Pass3Rates` resolves a selected preset before individual harness overrides. Metadata is kept outside the numeric rate map.

B is the default. Synthesis rates provisionally serve as B until the paper workflow provides exact B/C values; these values are not evidence of reaching the plan's round-12 size targets. B changes the merged wave 1 Fetch share from one-half to full stats, as explicitly requested. All other merged wave 1 B dials stay unchanged. A retains the former half-Fetch fallback. C provisionally doubles the listed engine growth, copy and Ring-production rates and the spell/hero percentage. Timing, target counts, defensive answers, economy and loop-guard allowances stay unchanged. C's 2× Fetch text says double stats. There are no other proposed wave 1 B dial changes in this build; the paper values may later replace the provisional overrides.

### Readings and limits

- “Next Start of Turn” means the first step of the next Recruit Phase, ahead of homecomings and Start of Turn text. This prevents listeners from reading a stale body and makes the landing happen exactly once.
- The pending badge belongs to a visible fighter. Once its tile has faded away, later queued rewards remain in the existing fight log and event stream; the UI does not keep an extra dead-unit tile or add a reminder panel.
- Pool rules precede the tribe rewrites. Today's Bridge Toad is routed through the new queue, retaining its existing flat reward and authored cap until the Bog commit replaces it with the pass 3 Soak design. The queue reserves any existing cap against rewards already pending; it adds no new size cap.
- The queue applies to permanent stat gains from Takes/Soak, rather than unrelated permanent changes such as Jack Daw's explicitly retained permanent steal. Other prototype Hunter/Bog abilities remain until their respective commits.
- Existing guard-off controls remain diagnostic comparisons. The pool rules apply whenever pass 3 content is present; pass 3 off retains legacy resolution.
- The early-card flexibility audit belongs to the Bog/Hunters commits. No early card has been redesigned in this pool-rule commit.

### Verification

Focused tests cover queue timing, death, identity, triples, token and missing-body cases, cap reservation, Pack leader/joiner Cleave, guard counterexamples, scripted doubling, scaling, Supper eligibility, Ring counts, presets and the phone-size pending badge. Fixed-dial replay fixtures are captured from untouched `f574eaf` for Birds, Fairies, Oozes and Hedgerow; the intentional B Fetch change and hero/spell default change are held fixed for those comparisons. The reader tests open the actual Details slip for scaled spells/heroes and normal/golden Take and bite cards before any reward; the legacy-path test checks immediate Take/bite gains with pass 3 off. The full gate passes: 1,836 GUT tests, 29,915 assertions, a clean strict hook, and 57 Python checks. All eight native-tribe fights replay byte for byte against `f574eaf`; the twelve existing frozen legacy replays also pass. [Gate log](../../evidence/wave2a/pool-rules-gate.log). The final run uses the detached `nohup timeout 5000 flock … systemd-run --user --scope -q -p MemoryMax=3G ./scripts/check.sh` command, with `/opt/bramble/env.sh` sourced first and output in `build/w3-gate.log`.

## Pool-rule review fix-up after the harness merge

Built on the user’s merge `0a31c5f`, before Bog:

- The pre-lever capture test now expects a private pass 3 library, checks cache reuse and source immutability, and retains its caps-on checks.
- `scale_hero_spell_percent` is an explicit nullable `GameConfig` default, so bench and shard overrides can find the key while its value still resolves from JSON. Removed the test-only `Pass3Rates.preset()` API; all preset resolution uses `resolved(config)`.
- Mousewife’s tier-sized Mouse now uses the existing stat-scaling rule against living board averages: each stat is at least the tier, otherwise the corresponding average times the percentage times the tier. Attack and Health can differ. Empty/small boards retain the tier floor; Mouse deaths and failed summons retain their existing guards. Explicit scaling-off keeps the legacy path.
- Used the authorized **short-face fallback**, rather than adding target-aware live-number previews. A single number would misstate Bracken’s different gains across recipients or Cordial’s target/row-dependent gains. Faces omit minimum clauses and Bracken’s cap clause; Supper simply names its tribe bonus. The existing Details reader keeps the percentage formula, floors, caps and original base effect. Phone-reader tests cover all four examples at default and swept percentages. Live per-target previews remain outside this fix-up.
- Fight captures freeze resolved rate values and the effective scaling switch alongside the preset label. They also save the numeric defaults used to decide whether a reader ruling needs an override; otherwise a golden Fetch could gain an extra view field when the default changes. These saved defaults affect text comparison only, while saved effective rates control combat. Real serialized B/C captures with normal and golden Fetches replay exactly against fresh libraries after default/preset edits, with an unfrozen negative control.

C remains provisional. `gain_landed` and the two prototype Hunter reward timings are retained for their scheduled later work. No Bog content is built in this fix-up.

## Wave 1 rule follow-up

The orchestrator's paper-value decisions were read from local `ideation/main:docs/ideation/DECISIONS.md`, “Paper values for presets B and C”. The paper presets have not been applied.

- Enemy selections ranked by Attack plus Health, Attack or Health prefer eligible originals over bodies created by copying in this fight. Existing eligibility filters run first; if no eligible originals remain, copies become eligible. Counted picks do not fill spare places with copies while originals remain. A combat-only marker is set before entry callbacks, survives swallowing/release, and resets in the next fight. Friendly-largest, across-only, all-enemy effects, ordinary summons and copies made before combat retain their rules.
- Covered selectors are the common data path, Snap, Whistle, prototype highest-Health Nightshade, and native/data scale answers. Today's prototype Hasty is across; Jenny picks a friendly adjacent attacker; Isegrim supplies a join bonus; Lantern uses Snap; pass 3 Seven Whistlers is across/all-enemy. Their future biggest-enemy rewrites will use the same selector policy rather than changing those prototype rules now.
- Jack Daw's steal joins the late Start of Combat step, including when its text is copied or borrowed. The persistence switch still controls only whether the gain carries back. Tests exercise both player orders against full Fetch plus its own Ring, Granny's gathering, the Whistlers changing the recipient, and Changeling changing sides. Jack remains a positional effect in the UpsetCombat audit.
- The native audit now also masks Whistle and prototype Nightshade, whose actual selections rank enemy Attack and Health. Their original-first policy belongs to the same answer class. All-enemy and friendly-largest effects remain outside it.

The final detached gate below validates both follow-up commits together; the earlier gate was stopped when the second commit was requested.

Combined validation passed under the detached shared-lock/3G command: **1,908 GUT tests, 31,084 assertions**, strict hook clean, and all quality-gate steps passed. [Combined gate log](../../evidence/wave2a/fixups-gate.log). Focused checks also passed: Mousewife 5, scaling 9, phone readers 6, capture/replay 4, copy targeting 11, Jack timing 5, plus the UpsetCombat and existing combat/replay suites. The working paper B/C values were not applied; Bog remains unbuilt pending confirmation.

## Item 2: Bog folk pass 3

Built after `1144ad6`, with the separately requested rollback Fetch correction in `feebc5a`. The sixteen live Bog bodies now use the pass 3 design, including tier-4 Tiddy (3/5), tier-5 Jenny (4/7), the restored Prince and combat-only Peatling. The five prototype bodies (`marsh_frog`, `mudwallow_toad`, `common_toad`, `crested_newt`, `bitter_toad`) leave the pool. Portraits are reused. Frozen pass 2 Bog definitions remain test-only rollback coverage.

### Rules and readings

- The orchestrator's three calls are implemented: **ordinary starts → Lantern → Jenny → Bog patches → Sal → remaining biggest-enemy effects**; hidden targets bind the exact identity and wait for its natural emergence; Hopkin borrows on every attack while in the back row. This is Bog's dependent sequence within amendment 4. Jack's additional after-all-ranked-effects ordering is reserved for the Hunters commit, as directed in review.
- Bitter removes a quarter of the attacker's current effective attacking Attack, rounded up, with a floor of 1 remaining. Actual Attack removed contributes to the owner's new Toll. Soak banks its own patched enemies' losses through the existing next-Start-of-Turn queue, including when the drinker dies. Free bites contribute Toll but no Soak. Own and lent Soak use the strongest matching copy, never add; golden strength survives borrowing.
- The previous fight's Toll pays Nan and Tiddy at Start of Turn and Sal at Start of Combat. The current fight earns a fresh Toll, including Bitter from combat-only Peatlings; zero earned resets it to zero. Nan chooses the smallest Bog by Attack plus Health; ties use reading order. Amendment 2 limits Tiddy and the frogs to **the Bog folk beside them**, as does the Chorus. The Bog review corrected the earlier broader reading to match the overriding amendment.
- Shares are floored after splitting. Nan/Tiddy/Ranocchio's paper shares are their final shares: Soak's keep dial does not multiply those rewards again. Bitter alone rounds up. Sal divides its previous Toll among all currently Mired enemies, after patches and before the remaining late answers.
- Kisses are owner-owned progress, shared by all frogs; holding all frogs pauses progress without erasing it. A whole death batch determines its witnesses before rewards. A frog dying with a Sink can witness it. The strongest overlapping curse break applies once to each recipient per turn, multiplying printed plus permanent stats, excluding tribe bonuses, Rings, auras, combat buffs and Bitter losses. The first break restores His Highness; the Prince repeats the same shared quest. An immediate permanent gain never revives a fighter already killed in that batch.
- Cutter's once-per-fight gold, King's two/four **successful** summons, one kiss per fight, and one multiplication per recipient per turn are the four named loop guards. Ordinary Ranocchio attacks have no fight cap. Gideon's hit-back is one-way damage, not another attack or a chain of retaliations. Peatlings copy settled starting Attack and maximum Health (entry stats for later arrivals), retain Bitter, and create no permanent owner body. Golden King raises four exact-size bodies, not two doubled bodies.
- Mire remains slot-bound. Lantern reserves its selected identity before Jenny chooses, but if that identity occupies Jenny's destination, Jenny's swap can move it incidentally; the Lantern patch stays on its slot. Deferred hidden lures/pulls do not force Belly release and expire if their source departs.

### Provisional B dials

The Bog paper B entries available on local `ideation/main` were compared with the synthesis, taking the more generous value. No paper values for another tribe were applied. All values below are provisional pending the accounting check.

| Dial | B | Golden B |
| --- | ---: | ---: |
| Soak keep | 2 | 4 |
| Nan's Toll share | 1/2 | 1 |
| Tiddy's Toll share, split | 1/2 | 1 |
| Ranocchio's target-Attack share | 1/2 | 1 |
| Frog multiplier | 2 | 3 |
| Hopkin's front-Attack share | 1/4 | 1/2 |
| Bufo halvings | 1 | 2 |
| Gideon hit-backs | 1 | 2 |
| Sal's Toll multiplier | 1 | 2 |
| Pretender / Cutter gold | 1 | 2 |
| King's successful Peatlings | 2 | 4 |
| Lantern lures | 1 | 2 |

Other dials: Bitter share 1/4, round up true; Soak own-Mired-only true; kiss period 3, kisses per fight 1, frog multiplications per turn 1; Peatling stat share 1; Prima patches 3; Chorus recipients 2; Jenny pulls 1; capstone When played Toll lever false. These are JSON rates, exposed as nullable configuration overrides for harness sweeps. C uses the separate Soak keep override **3/6**, not a blanket multiplier; the remaining Bog rates inherit B. A provisionally inherits Bog B. Existing wave 1 rates are unchanged by this commit. Card faces and Details are generated from resolved rates, with independent authored-default matching tests.

### Bot, lines, display and limits

Hard's Bog helper values the engine as a board: Tiddy/frog adjacency, soak food versus Bufo threat, Chorus recipients, Hopkin behind Attack, matching Jenny after Lantern, and profitable King gaps. It keeps engine pieces, delays an unproductive frog only within the line's hold rule, and can cash shared progress. Existing strategy IDs remain usable: `bog_tongues` is Court and `bog_bitter` is Swamp.

`tools/sim/lines/bog.json` contains Court and Swamp priorities, triple and tier-up policies, savings, holds and placement rules. It follows the wave 1 schema with explicit `tribe` and `base_strategy`; the generalized file loader is not on this tree, so the JSON awaits that harness merge. No edits were made to `bench.gd` or `BenchSuites`.

The existing Bog icon shows numeric Toll; the frog's existing progress display uses shared kisses. The reader shows recorded-scout per-bite Soak estimates, using current placement and Lantern/Jenny/patch priority, without consuming RNG or predicting the opponent's next buffs. Missing scout data has no estimate. Pending gains use the existing badge. No new main-screen reminder or tutorial was added.

Early flexibility: Nan's Bitter body, Hopkin's early attack, Cutter's economy and Pretender's Snap body can be played before commitment, but their engine text needs Bog/Mired support. Bridge Toad and Bufo enable their own matching; the Chorus and later funnel need tribe commitment. These dependencies are retained rather than redesigning the early cards (owner note 09f).

UpsetCombat audits every new dispatch by ability. Lantern and Jenny select the biggest enemy; Snap remains its separate stat-ranked class. Other new Bog abilities do not choose a biggest enemy. Unknown native abilities continue to make the audit unsupported.

### Bog verification and rollback coverage

The focused native suites cover every body and token, normal/golden rates, printed plus borrowed growth, actual recruit purchases and placement, Toll cash-out, shared kisses, next-turn landing, hidden identity binding, and the full dependent opening. Guard-off cases reproduce repeated Cutter payments, multiple kisses in one fight, overlapping multiplication, and excess King summons. Hopkin is tested through the real attacker picker after Bitter reduces his own Attack to zero, and stops borrowing when the front unit loses its Attack. The native UI tests cover phone and PC state readability, selected-scout estimates, replayed Toll/kisses and human-readable action logs. Native Details are available before any reward, including lent Soak in the recipient's reader.

Frozen Bog definitions join the test-only rollback library. This prevents a native Bog elsewhere in the library from enabling pass 3 inside an old Birds/Fairies test. Old cap, discount, aura, kiss-per-death, price-paid and log assertions retain their original bodies; the previous Bog shopping comparisons also retain their old comparison priors. The pool-rule tests retain current Birds/Fairies for Pack/Cleave, while archiving only the prototype Bog reward under test. Native Bog has separate current-rule coverage. The rollback is retained until checkpoint 2, as agreed for the wave 1 archives.

### Trigger-condition and low-roll audit (triage rule, 034b098)

The paper-model low-roll rows remove the line's first-priority keystone for the **entire game**: Court has no Tiddy; Swamp has no Prima Donna. They do not script a later arrival. These choices are explicit build readings for the two different engines, pending harness measurement; other arrivals remain real draws.

| Cards | Condition checked when its trigger fires | Finding |
| --- | --- | --- |
| Bridge Toad, Prima Donna, Lantern | Their own patched attacker bites; actual Bitter loss banks next turn | Aligned; Lantern selects after ordinary buffs, Prima supplies its patches before attacks |
| Nan, Tiddy | Previous Toll and eligible Bog recipients at Start of Turn, after gains land | Aligned; neither depends on tier-ups or stops at T6 |
| Pretender | This kills a currently Mired enemy | Aligned with completed attack/death batch |
| Bufo | Her own Mired enemy kills her | Aligned with death and retained killer/patch identity |
| Hopkin | Back-row attack, live Attack in front | Rechecked on every declared attack; zero own Attack does not prevent borrowing |
| Cutter, King | A Mired enemy dies while they witness the batch | Aligned with Sink; full-board King failures do not spend successful-summon allowance |
| Gideon | Survives his own Mired enemy's completed bite | Aligned, but a fresh small Gideon cannot reply to a lethal giant; Soak still banks. This is an explicit conditional payoff, not evidence of reliable reply frequency |
| Chorus | Adjacent Bog recipient at patch/Soak resolution | Aligned, recomputed from live adjacency |
| Sal | Previous Toll and Mired targets at Start of Combat | Aligned by running after patches; zero Toll or no patches naturally produces no damage |
| His Highness, Prince | A Sink while a frog is present, then each configured kiss milestone | Aligned with shared fight progress; hand time pauses it, repeated Prince milestones still fire |
| Ranocchio | Completes an attack on a currently Mired enemy | Aligned; permanent reward survives a lethal trade |
| Jenny | Eligible biggest enemy in the facing row at her dependent start step | Aligned after Lantern, before own patches; hidden target waits for emergence |

No Bog card has the structural tier-up/full-Ring mismatch found in Cluricaun. Arrival rates and the frequency of conditional payoffs are not calibrated by these rule tests; the realized-board harness check remains necessary. Hunters will receive the same audit with its implementation.

Final Bog validation passed under the detached shared-lock/3G command: **1,989 GUT tests, 32,039 assertions**, strict hook clean, all 57 Python checks and every full-gate step passed. The eight fixed-dial native untouched-tribe replays and twelve archived legacy replays pass. [Bog gate log](../../evidence/wave2a/bog-gate.log). Focused checks additionally passed 72 native Bog tests and the final 88-case rollback/reader check. The low-roll rows are paper-model notes in this build document; they are not bot line-file input.

## Wave 1 re-base after Bog

Requested after `9f03fe0`, using the orchestrator's `034b098` decisions and paper preset JSON from local `ideation/main`. The triage report and critic were read there. B/C now target realized committed-line medians; the paper schedules describe high rolls, not measured typical games. This implementation does not claim that either target has been reached; the shipped-config accounting run belongs to the harness follow-up.

- **Birds hold:** every `birds_*` base value and B/C override remains exactly as in `9f03fe0`, the build the playtesters played. Two independent skilled playtests showed compounding homecomings running away (a 2,085 board at R14 and an 820/1082 unit at R18), while bot boards remained near 270 at R12. The bot-based argument for increasing Birds is withdrawn; Birds receive a separate triage. No Bird card data, growth rule, economy value or dial is changed by this re-base.
- **Fairies B** uses paper B with initial Ring size **4**, **C** paper C with initial Ring size **6**. Growth is 2/4 for normal/golden Cluricaun in B, 4/8 in C. Nan makes 2/4 Rings; Lob's bank period and the Monarch's period are both 2. C has Lob growth 3, Silky growth 2, Monarch multiplication 3/4; B retains growth 1,1 and multiplication 2/3. Fetch is full in both. Annis and Sally stay at one Ring, as directed.
- The base numeric map and preset A retain the historical wave 1 values; the new Fairy B/C values are explicit overlays. Authored Fairy defaults are regenerated for B. The unchanged paper constants for Witch share 1, Hob/Belladonna/Changeling target counts 1 and Shy payment 2 match the existing rules and are not added as unused rate keys. Bog, the other tribes and the hero/spell percentage presets are unchanged.
- **Queen**, still T6 8/8, destroys the units behind her at **Start of Turn**. This hook already exists and runs while the Recruit Phase remains open. Tests refill an emptied slot legally and show that its replacement survives End of Turn. Her optional period dial uses Start of Turns; an extra trigger cannot advance its countdown. End of Turn doublers no longer fire her.
- **Cluricaun**, still T3 3/5, checks the full Ring board at **End of Turn**, including at T6. The resolved growth dial determines both the effect and the face. Shared printed/borrowed growers still resolve once at the strongest strength. Tier-ups no longer grow Rings. Hard values this recurring payout and retains it at T6; Queen's food arrangement follows the next Start of Turn's due counter, while shopping can refill her slots.
- The pass 2 archive remains unchanged. A remains available for fixed-rate mechanic comparisons. The existing exact replay fixture is retained: runtime rates and the historical reader comparison basis are both pinned. The fixture itself is unchanged; the explicit comparison basis prevents new authored Fairy defaults from changing historical reader metadata. No fight results were re-recorded.
- The Bog low-roll policies and trigger-condition table above implement the two new triage rules. No Bog card has Cluricaun's phase/tier mismatch; Gideon's survival requirement and arrival-dependent payoff frequencies remain explicit measurement risks. The same check is required for Hunters.

The larger starting Rings exposed an existing legality-list mismatch: the UI still treated four flat Ring stats as a full slot, although pass 3 counts uncapped Rings. The action list now follows the pass 3 pool rule. Tests show both four-Ring and three-Ring slots remain legal spell targets, an actual cast increases the latter to five Rings, and the copied pass 2 state still filters a capped slot. Other generic tests now assert B's actual +8/+8 and +12/+12 Ring-spell gains. Capture-drift tests keep both frozen exact replays and unfrozen negative controls with full Fetch in both Fairy presets.

The generic Ring-size reminder no longer claims a universal starting size of 1; the live size display and resolved card rulings supply the selected value. Lob's reader regression now expects B's two-turn bank. The final gate below covers the Birds hold and these reader corrections together.


## Bog review fix-up after the wave 1 re-base

- Amendment 2 wins over the synthesis faces: Tiddy, His Highness and the Prince affect only adjacent Bog folk. Faces, Details, recruit/combat filters, bot frog valuation and exclusion tests use the same tribe restriction. Bog B/C rates stay unchanged.
- `tools/sim/lines/bog.json` uses only card IDs in `keep`. Positional carry guidance stays in `placement`. The Court-without-Tiddy and Swamp-without-Prima low-roll rows remain paper-model notes above; `low_roll` is removed from the bot input.
- The new Bog rulebook entries are tagged `[PROPOSED ideation]`; no owner decision is claimed. The schema's Soak reminder now correctly describes the Mired enemy biting the drinker.
- The combined detached gate below validates this fix-up together with the separately committed Fairies-only re-base `f86f2d7c`. Birds remain held at the playtested `9f03fe0` rates.

Hunters follow-up notes: Jack Daw must resolve after all of both sides' stat-ranked enemy effects. Whirligig Beetle must not improve the opponent's placement on bigger Rings; its rebuilt swap rule needs a resulting-Ring check or an explicit design reason to allow the benefit. These are reserved for the Hunters commit.

The historical pinned-strategy purchase-share regression now explicitly selects preset A; its original 60%/40% thresholds are unchanged. Full-game coverage elsewhere still runs the current B field. The detached verification checks this fixed-rate regression before running the complete gate; logs are `build/wave2a-pinned-profile.log` and `build/wave1-rebase-bog-fixup-gate.log`.
