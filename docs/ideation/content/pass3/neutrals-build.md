# A3 neutrals

Built on `a0878668`, then rebased onto the wave2b strict-warning repair
`125db4df`. Wave2b is left at that repair. This part changes three neutrals,
adds Shieldbug and Click Beetle, and retains Pipistrelle Echo. The nine other
neutrals keep their rules. The final prototype-retirement follow-up below completes the pool. Counts rise 158→160 definitions and 109→111 slice shop units, solely for
the two additions. Their existing portraits are used.

## Rules and readings

- Ballooning Spider lends Swoop directly behind while alive. Loans follow
  relocation, swallowing, return and text theft, and end when the source leaves.
  Intrinsic targeting, Mire and quarry precedence are preserved.
- Charcoal Burner burns up to 6 gold above 5, or 12 golden. Each recipient gains
  a twentieth of its own base plus permanent Attack/Health per gold. Exclude
  Rings, auras, standing tribe layers and combat buffs; round each total gain
  down once. Golden increases only the burn cap. This body-only reading is the
  orchestrator's DECISIONS call, not additional owner direction.
- Whirligig swaps F1/B1, F2/B2 and F3/B3. F4 stays. The existing Ring-improvement
  guard remains: skip a pair if either enemy would gain Ring Attack or Health.
  Only moved enemies lose a tenth/fifth of current Health, after slot/aura
  recalculation. This is Health loss, not damage, and leaves Shield intact.
- Shieldbug grants Shield directly behind at Start of Combat. The grants remain
  after Shieldbug dies. Golden Spider and Shieldbug double bodies, not coverage.
- Strongest Click determines two/three When played firings; copies do not stack.
  Each landing with Click replays When played before the trip's single growth.
  Later ordinary play from the returned hand repeats again. Without Click,
  landing keeps its previous behaviour. This is the explicit DECISIONS exception,
  not a global homecoming rewrite.
- Landing completion uses the same FIFO recruit queue, without immediate nested
  delivery. Reserve returning batches immediately; unfinished Birds stay outside
  triple ownership. Structural completion still returns a Bird when the trigger
  budget is exhausted. Extra triggers retain multiplication/countdown guards.
- Echo stays because spell scaling shipped: B 10%, C 20%. Spell copies size each
  recipient independently; golden Echo retains its existing targeting rule.

Seven new `neutrals_*` dials have identical defaults in A/B/C: `burner_cap=6`,
`burner_above=5`, `burner_share=0.05`, `click_repeats=2`,
`golden_click_repeats=3`, `whirligig_health_share=0.1`, and
`golden_whirligig_health_share=0.2`. All faces resolve from these rates, with
checked authored defaults and full Details. No Birds, Fairy or other tribe rates
change. Turning off size caps removes Burner's gold ceiling; the configured cap
flag now survives library registration, which previously regenerated capped text
and mechanics. A directed regression covers that failure.

## Bots, UI and rollback

Hard evaluates Shieldbug/Spider using actual recipients and places them at F2/F3
when that covers two useful back units. Click values actual upcoming plays and
Bird landings, discounts redundant copies and protects a productive engine via
`_can_replace`. Burner forecasts cumulative fractional own-body growth and its
actual spending tradeoff; Whirligig values eligible scouted Health conservatively
around Rings. Directed before/after fixed-board tests cover these decisions.

Existing card tags and reader/forecast text are updated; no new main-screen text
nodes or reminder panels are added. The loan uses the existing status display.
The away-tray landing forecast includes Click's printed self-buff payoff before
growth. That estimate covers configured unconditional printed self-buffs; it
does not attempt a general simulation of arbitrary conditional or borrowed text.
All native Bird stat payoffs are covered. The five native abilities are individually in the UpsetCombat audit;
none picks the biggest enemy. Unknown native ability names remain unsupported.

The previous three neutral definitions are archived in the test-only legacy
library. Their old flat-growth and damage tests keep exact expected numbers and
use the faster suite's cached wrappers. The frozen normal replay passes without
changing its fixture. Rulebook 9.6.8, 12.1.4 and 12.1.11 describe the new rules as
`[PROPOSED ideation]`.

## Role evidence

Fixed recipes and compact results are in [the evidence directory](../../evidence/neutrals/README.md).
Each combat case uses 32 paired seeds, 16 in each orientation, normal and golden
separately: 384 fights total. Controls remove only that card's mechanic and retain
its body and every other card. These are controlled role proofs, not population
win-rate or shop-acquisition measurements.

| Card | Constructed result, normal / golden |
|---|---|
| Shieldbug | Carry has Shield and blocks one hit in 32/32 each; text-off 0/32. Wins 32/32 versus 0/32 for the matched damage-answer fixture. |
| Ballooning Spider | Carry's first attack reaches the enemy back carry in 32/32 each; text-off 0/32. Normal loses both arms; golden wins both. Reach is demonstrated without claiming a general win-rate lift. |
| Whirligig | Back carry moves to F1 and loses 60→54 / 48 Health in 32/32; text-off stays B1 at 60. Both arms win this fixture, so the proof is exposure and Health loss. |
| Charcoal Burner | Two 100/100 recipients become 130/130 / 160/160 for 6 / 12 gold; 120 / 240 total stats, 20 stats per gold. A second funded turn reaches 169/169 / 256/256. |
| Click Beetle | Crumb passes +2/+2 / +3/+3; Lamp Moth discounts by 2 / 3. Unsupported reference gains are 1 each. |
| Pipistrelle Echo | A scaled Pinch aimed at the 100/100 Echo gives all three recipients +10/+10 at B or +20/+20 at C, normal and golden: 60 / 120 total stats rather than 20 / 40 without Echo. |

Click homecoming at B with a normal Bird and the 2× homecoming dial: Chiffchaff
lands 6/8 with normal Click or 8/10 with golden Click (2/4 without Click).
Swallow pays 2/3 gold and Goose makes 2/3 Golden Eggs. A later play repeats again;
no extra homecoming multiplication occurs. Nested three-Chiff returns finish
before combining to a 17/22 golden, and nested return into two owned copies gives
7/10. These are also fixed known-answer tests.

## Validation

**682/682 targeted tests across 53 scripts pass after affected-file reruns.**
The last preview/shared-code rerun passes 57/57 with the strict hook and zero
warnings or errors. All four required lint/format commands pass.

The targeted hand-off results and per-script times are recorded in
[validation.json](../../evidence/neutrals/validation.json). Normal and golden rules
for all five changed/new cards, and retained scaled Echo, have known answers.
All bot/line scripts, the required seven content-compatibility scripts, shared
recruit/held/triple/guard paths, frozen normal replay and relevant UI scripts are
included. The initial compatibility failures exposed stale portrait counts and
the real uncapped Burner reset; both are corrected. An ignored content test's
strict typing error was corrected and rerun separately with the strict hook and
no warnings. No local full gate was run.

Raw fights, paired samples, recruit event logs and test logs remain under
`build/neutrals/`; only recipes, compact summaries and validation are committed.
At this initial checkpoint no instruction was declined, and neither prototype
retirement nor an unissued Stone Soup card-change call was included. Retirement
is completed in the follow-up below.

New fixed test script times (JUnit): content 0.02 s; recruit 0.67 s; combat
0.57 s; bot 0.77 s; role recipes 14.48 s; UI preview 0.58 s. None adds a
whole-game or lobby test; role recipes use short fixed boards.

## A3 review follow-up: Click valuation

Merged `origin/ideation/main` (`80dcc35a`) as `a2206273` before these fixes.
All three review claims were confirmed. Generic golden effect parameters were
already doubled, so the second golden factor is removed. Away payoffs now use
`max(1, due - current_round)`, rather than the departure round. Ordinary plays
value only extra firings above one; supported landings value the full two/three
firings above their unsupported zero (or the one-firing improvement when upgrading
an existing normal Click). Nan's native Ring count, golden factor and current
Ring size now contribute to synergy and engine protection.

The directed test checks golden Chiff's 4-stat and Swallow's 5-value per firing,
actual golden payoffs, unchanged departure dates with different remaining time,
and normal/golden Nan. `test_bot_neutral.gd` passes 10/10 with the strict hook and
no warnings. `./scripts/check.sh --no-tests` passes, including formatting, lint,
content, import, compilation and parity. The import also generated missing UIDs
for five field scripts brought in by the main merge; those metadata files are
tracked. The Stone Soup part remains a separate commit below.

## A3 review follow-up: Stone Soup triage

All six calls in DECISIONS "Stone Soup triage: calls" are implemented, without
changing B/C rate values:

1. Soup is tier 1, 2/3 (4/6 golden). This deliberately changes the Ooze tier
   distribution to 4/2/3/3/2/2; parity reports that deviation but passes.
2. Before the first on-board Digest carry, Dollop receives the higher of the
   declared Dollop/Soup priorities and Soup the lower; the normal written order
   resumes with a carry. Both line files state the conditional route. The +12
   Soup commitment bonus requires that carry.
3. Soup alone rounds each share up, after summing golden's recipients. Authored
   and generated faces, Details and rulebook 12.1.9 say so. Elder/Slice still use
   the unchanged floor helper. Normal and golden tiny-body tests prove +1/+1,
   retained exactly once on purchase; Shy remains excluded.
4. Native Ooze Hard and line seats can buy off-tribe bodies without a Digest
   carry. The exception requires native Ooze content, not merely the shared pool
   flag: the first broader test caught a frozen pass 2 replay regression, and
   this guard restores all three exact hashes without changing the fixture.
5. A second plain Soup is priced at body plus pair bonus, without build, future
   or repeated engine bonuses. Golden/third-copy opportunities retain their
   separate value. Directed fixed-board tests cover both Hard and both lines.
6. Line telemetry logs unique offers, purchases, swallows and Nell meals by card,
   plus placement/elimination round. Nell's existing eat event carries an explicit
   `cause: nell`; Digest event shapes remain unchanged. Observers chain prior
   listeners and bind seat IDs, avoiding self-reference cycles. The report places
   elimination counts beside survivor medians and validates the original 32 seeds.

The broader affected selection plus corrected-script reruns passes 387 tests in
35 scripts. The new Soup bot script passes 7/7, native recruit 21/21, and the
frozen full-game replay passes. The Frumenty memory test now expects Spider's
new printed aura rather than its former self-Swoop. Four fast report tests pass.
`./scripts/check.sh --no-tests` passes after the last code edit, including ruff,
gdformat, gdlint, content, import, compilation and parity. No full local GUT gate
was run. Raw check logs are under `build/neutrals/review-fixes/`.

The confirmation measurement uses B and exactly the original 32 seeds from
`oozes-final.jsonl`, one engine and one tempo seat against six varied Hard seats.
Its results will be appended after the committed implementation is measured.
At that checkpoint retirement was deferred: 13 of the 38 no-set definitions
remained in their legacy pool. The final follow-up below retires them.

### Stone Soup confirmation: one bar remains unmet

All 32 original seeds completed at B on `a2504fee`, with no runtime errors, in
462.5 seconds (14.45 seconds/lobby). [Compact results](../../evidence/neutrals/stone-soup-confirm.json)
retain the exact cohort, source hashes and per-card engine totals; raw captures,
CSVs, metrics and the full per-seat report stay in `build/neutrals/soup-confirm.*`.

| Confirmation bar | Observed | Result |
|---|---|---|
| Soup fielded by R6 on at least 20/32 engine seats | 17/32 | **Dropped as a merge condition (DECISIONS)** |
| Soup seats out before R12 no more often than the rest | 2/17 (11.8%) versus 4/15 (26.7%) | **PASS** |
| Soup on at least half the R12 engine boards | 15/26 (57.7%) | **PASS** |

The survival cohort is ever fielded before R12. Using fielded by R6, R10 or R11
produces the same 17 versus 15 seats and the same result. These are descriptive
exposure cohorts, not a causal survival estimate. The engine seats saw 30 unique
Soup offers across 20 seats and bought 19 copies; Nell ate one Soup on engine
seats. No extra card or route change was made to force the failed arrival bar.
The orchestrator subsequently dropped the arrival bar as a merge condition
(DECISIONS, “Neutrals (A3): the Soup arrival bar is dropped as a merge condition”).
The proposed freeze change stays out; the bot is unchanged by this follow-up.

| Round | Observed engine boards / 32 | Eliminated before round | Median active stats | Median including Bellies |
|---|---:|---:|---:|---:|
| R6 | 32 | 0 | 52.5 | 58 |
| R8 | 32 | 0 | 94 | 116.5 |
| R10 | 31 | 1 | 174 | 206 |
| R12 | 26 | 6 | 398 | 402.5 |
| R14 | 13 | 19 | 962 | 1,059 |

The R12 active median is 44.2% of 900; the payout gap is not claimed fixed.
The new seven-test bot script takes 0.68 seconds, and the four Python report tests
0.006 seconds. Checks, fixture hashes and source remain unchanged after measuring.
Retirement was not started during that confirmation turn; it is completed below.

## Immediate Slice triples: soak follow-up

The native producer appended each Created Slice without calling `check_triples`.
That left three eligible owned copies uncombined and could lose a golden
producer's second Slice because the first had not yet freed hand space. The fix
checks immediately after each fully buffed copy is appended and logged. It uses
the shared triple rule, including copies inside Bellies, and preserves creation,
stat assignment, reward and full-hand rules. The pass 2 producer is unchanged.

All three fixed regressions fail without the line and pass with it: normal
29/35 golden, full-hand golden batch 59/59 plus a second 20/20, and Belly ownership.
The broader affected run passes 41/41; `check.sh --no-tests` passes with formatting,
lint, content, imports and compilation. [Evidence](../../evidence/neutrals/slice-triples.json)
records the red/green results and links the 48 historical soak violations.

## Soup arrival odds and final prototype retirement

The [arrival audit](../../evidence/neutrals/stone-soup-odds.md) estimates a
53.22% first-offer probability by R6 on the actual climb and refresh routes
(90% bootstrap interval 46.91–59.31%). This is a route estimate, not a universal
shop ceiling. The unchanged trace exposes Soup to 18/32 engine seats by R6;
17/32 buy it. Thus even perfect purchasing on this trace cannot reach 20/32.
The single missed purchase is the seed 280023 reserve conflict; freezing that
first Soup while saving is proposed only, and has not been implemented.

All 38 no-set prototypes are now absent from the live pool: 25 were already
retired and this commit flips the remaining 13 pool flags. The 160 definitions
stay loadable, and the 111 native/slice pool definitions are unchanged. No
other production content or gameplay logic changes in this retirement commit.

An explicit test-only archive retains the previous thirteen prototype bodies
for historical pool, recruit and UI fixtures. Legacy tribal wrappers restore
those thirteen without overwriting their older tribal archives. Tests that
exercise the old default prototype shop select that archive explicitly; the
shared current library stays live. The Ooze content test now expects retirement.
Frozen field fixture bytes, hashes and exact replay assertions remain unchanged.

The final affected selection passes 1,135 unique tests in 103 scripts,
after correcting legacy empty-shop fixtures and rerunning each affected script.
The three new fixed retirement tests take 0.752 seconds.
`check.sh --no-tests` passes after the last code edit, including ruff checks,
gdformat, gdlint, content, imports and compilation. No local full GUT gate was
run. [Compact evidence](../../evidence/neutrals/prototype-retirement.json) records
the IDs and validation; raw logs remain in `build/neutrals/retirement/`.

## Retirement tool follow-up

Merged `origin/ideation/main` at `3ab98ae5` (merge `3c6e8aaf`), including A3.5's
dials and the upstream soak rework. That rework already replaces the obsolete
defaults/prototype arm with full-game B/C/field lobbies. The fight benchmark now
also uses `full_game()` and its selected card set. It rejects an empty supply
before board construction. The soak rejects missing tier-1 supply before
creation and checks the actual tribe-filtered pool before playing each game.

All 67 targeted tests in seven files pass, including fixed empty-pool guard
coverage and current benchmark board construction. The benchmark completes
64 fights. The six-seed soak (1–6, B with C and a generated field library) plays
all six games: 111 rounds, 344 fights, 95 units in each actual lobby pool,
**zero empty-pool games**. It exits 1 with seven separate legality violations:
`LegalActions` offers Golden Egg item targets rejected with “Choose a Bird”.
That legality mismatch remains open; this is not a clean whole-soak result.

`check.sh --no-tests` passes after the final code edit; no full GUT suite was
run. [Compact output and checks](../../evidence/neutrals/pool-tools.json) retain
the result, including all seven violations. Raw logs remain under
`build/neutrals/pool-tools/`.

## Combined soak-fix gate follow-up

Merged the reviewed `ideation/soak-bugs` commit `450098d8` as `23850fee`,
including Egg legality and held-release fixes. The combined cloud run
`42759121987` found three stale fixture contracts:

- Soup's existing face already says “rounded up”, its Details say shares round
  up, and its rule uses `ceil` after summing. The A3.5 endpoint test still
  expected floors. The independent known answers are corrected to 13/25 normal
  and 19/38 golden at one eighth; both faces must explicitly say “rounded up”.
  Printing, rates and gameplay remain unchanged.
- Russet's prey was retired Field Vole. The rule intentionally skips prey with
  `pool=false`; there is no random pool draw involved. Live tier-1 Young Brock
  has the same printed 2/3, retaining the test's 120/240 buff input and every
  expected share. A failed count assertion now prevents an additional invalid
  array access.
- The aimed-hero UI fixture selected the empty old unit pool with
  `pool_filter=all`. It now keeps current full-game units and spells, exposing
  Sample Painter in that test library's live card set for the aimed-power
  check. Its spell selection names Elderflower Cordial, a legal buff on the
  played unit, rather than accepting any `aim=unit` item. The test additionally
  asserts a unit actually reached F2 and the bought spell has the expected ID.

All 85 tests across the four requested files pass, including the merged Egg
legality and held-release tests, with the strict hook and no GUT warnings.
`check.sh --no-tests` passes after the final code edit, including Ruff, gdformat
and gdlint. No full GUT suite was run.
[Compact results](../../evidence/neutrals/cloud-fixture-fixes.json); raw logs:
`build/neutrals/cloud-fixes/`.
