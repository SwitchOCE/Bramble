# Pass 3 wave 2A build

Branch: `ideation/wave2a`, based on `f574eaf`. Work is split into three reviewed commits: pool rules, Bog folk, then Hunters. This document records the implementation and its readings; tribe implementation is still pending after the first commit.

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
