# A3 neutrals

Built on `a0878668`, then rebased onto the wave2b strict-warning repair
`125db4df`. Wave2b is left at that repair. This part changes three neutrals,
adds Shieldbug and Click Beetle, and retains Pipistrelle Echo. The nine other
neutrals keep their rules. Prototype retirement is the next part, not included
here. Counts rise 158→160 definitions and 109→111 slice shop units, solely for
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
No instruction was declined. Nothing from the later prototype-retirement part
or an unissued Stone Soup card-change call is included.

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
Prototype retirement is deferred to its own turn; all 38 no-set definitions are
still present, with 13 remaining in their legacy pool.
