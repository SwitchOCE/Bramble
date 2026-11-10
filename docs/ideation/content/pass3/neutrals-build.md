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
