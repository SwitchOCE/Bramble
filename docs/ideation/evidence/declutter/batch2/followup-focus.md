# Batch 2 focus and budget follow-up (10 Nov)

Checkpoint before the orchestrator's next batch 1 review fixes. This is still WIP;
normal recruit overview and lobby remain over the 40-node cap.

- Scout focus collapses the shop and lobby, keeps both boards, and restores the
  recruit view on the close token or Escape. It clears selected-shop readers and
  pending hover timers; the port's game state remains byte-for-byte equivalent.
- Every original visible text node still counts. `budget-breakdown.md` and JSON
  split all 16 scenario/size rows by unit stats, hero Health, fallback names,
  costs/controls and other, using actual widget ownership. No numeric-text guesses
  and no exclusions. The five categories sum exactly to each raw count.
- Standard Refresh cost 1 is a known rule, so the icon's tooltip retains it and
  the resting pill is removed. Modified prices, including free 0, remain visible.
  The away heading and 'Now → landing' prefix are removed; the complete Bird
  forecast remains. The freed heading space goes to that forecast.
- Scout drops 64→35, overview 59→57, lobby 55→54, natural Birds 39→37. Remaining
  Other values are changing tier, Ring, Belly/Hex/Midsummer, turn and away state;
  they were not hidden to force the gate green. Removing fallback names alone
  would still leave overview 56 and lobby 48, so portraits alone cannot fix them.
- Phone layout now passes 11/11 (223 assertions, 3.133s). Reader actions already
  occupy an external side column: the obsolete vertical-only test is replaced
  with global non-overlap, content bounds and viewport/button checks. Counter
  pips now adapt to the actual bead gap and font height and remain inside the
  card. A new matrix checks 30 normal/combat sizes/counts: 1/1 test, 240 assertions,
  0.428s. Combat face remains 11/11, 180 assertions, 0.417s.
- Classifier tests pass 3/3, 18 assertions, 0.459s. Scout transition regression
  passes 1/1, 14 assertions, 0.860s. Budget remains red only for normal overview
  and lobby: 6 tests, 5 pass, 68/72 assertions, 5.239s, no runtime errors.

The DECISIONS file belongs to the orchestrator. My notes were inserted into its
Format line in error. The batch 1 DECISIONS-only revert is 76ad2049, merged into
batch 2 at 3fb19a45, removing both worker entries and restoring the original file.
No further entries will be written there. Notes remain in evidence follow-ups.

The newly requested full static checks found the duplicate AttackCue preload in
my batch 1 Pounce test. The lint-only fix is 998b24cf on batch 2 and will be applied
as its own batch 1 commit during the requested review follow-up. Python capture
scripts have also been cleaned up under explicit Ruff lint/format checks, with
normalized AST equivalence checked for the three mechanical cleanup files.

New refresh-price/forecast regressions, a clean final targeted rerun, and updated
focus screenshots/strips are pending this checkpoint. Historical captures remain
unchanged. Current code and tests are saved before switching to batch 1.


## Batch 1 review follow-ups merged before continuing batch 2

Batch 1 through `330ed2cd` is merged at `bf8bb4d1`. The lint gate, short
next-action cue retirement, lunge/portrait tests, and reader-5 Toll/pending/kiss/
Mire fixes are committed separately on `ideation/declutter`. The new packet is
`../batch1/strips/cue-retirement/README.md`: nine sheets / 72 frames, with
observed lunge peaks, at ×1/×4/reduce. Final Bog amounts are visibly unobscured;
the accepted before images are unchanged. A fresh independent read is pending.

After the merge, six targeted combat files pass **78/78 tests, 2957 assertions,
25.764 s**, strict hook clean. Required Ruff and both full gdlint commands pass;
full gdformat verification is recorded at hand-off. DECISIONS still exactly
matches d400831e. No pushes were made.

Batch 2 remains WIP: recruit overview 57, lobby 54, scout 35 against the unchanged
40-node cap. New focus screenshots and the pending refresh/forecast rerun remain
undone. No art merge was performed; updating spec portrait-name exceptions and
removing dead SHORT_NAMES entries awaits the requested ideation/main integration.
Stopping for the orchestrator's 45-minute turn limit.
