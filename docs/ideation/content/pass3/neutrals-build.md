# A3 neutrals — unfinished checkpoint

Started from `a0878668`, then rebased onto the reviewed wave2b repair `f7955f86`.
The intervening main documentation commits were preserved. Wave2b is unchanged
after that repair. This A3 branch is **not ready for review or a full gate**.

Implemented: Ballooning Spider lends Swoop behind while alive; Charcoal Burner
burns up to 6 gold above 5 (golden 12), giving each recipient a twentieth of its
own printed-plus-permanent stats per gold; Whirligig swaps paired rows and
removes a tenth/fifth of moved units' current Health; Shieldbug grants Shield
behind; Click Beetle repeats When played twice/three times. Pipistrelle Echo
stays because spell scaling ships at B 10/C 20. Portraits are reused. No prototypes
are retired in A3. Definition/pool counts rise 158→160 and 109→111 solely for
Shieldbug and Click Beetle; the old definitions and legacy pool are archived.

Readings:
- Golden Spider and Shieldbug double bodies without doubling their aura/grants.
- Whirligig retains the previously adopted Ring-improvement skip guard; F4 is
  unpaired and stays. Only moved units lose Health, after Ring/aura recalculation.
- Burner excludes Rings, tribe bonuses and auras. Each stat rounds down once
  after multiplying its own body by the total burned amount and share.
- Strongest Click copy determines 2/3 triggers; copies do not multiply together.
- With Click, landing replays When played before the trip's single homecoming
  multiplier; later ordinary play from the returned hand also repeats. Without
  Click, existing landing behaviour is unchanged. This implements the specific
  DECISIONS permission; it is not a global homecoming rewrite.

New data dials (same defaults at B/C): burner cap 6, bank 5, share 0.05; Click 2,
golden Click 3; Whirligig 0.1, golden 0.2. Golden Burner doubles its cap to 12.
New mechanics are individually audited as not picking the biggest enemy.

Current checks:
- 24 new fixed recruit/combat/bot tests ran: 23 pass, 1 fails as an explicit
  counterexample. Old Tern recalls while the recruit queue is already draining
  run queued Click effects after homecoming growth (Chiffchaff 4/6, expected 6/8).
- The new reader initially exposed shadowed local variables; those are renamed.
- Support tests verify native/legacy Burner text, 160 definitions, 111 slice shop
  units, schema documentation and the Whirligig Ring guard.
- Static formatting/lint and content validation have passed; no local full gate.

Still required before A3 hand-off:
1. Stage nested landing completion through the FIFO queue, preserving replay-
   before-growth and deferring triple merging until the returning unit finishes.
   Do not introduce an immediate event delivery that interrupts the queue.
2. Build and log the constructed role checks for each neutral, including scaled
   Echo and two When played units for Click; report Click's homecoming numbers.
3. Complete compatibility/phone coverage and final targeted checks after the fix.

Raw logs stay in `build/neutrals/`. No A3 role-result numbers are claimed yet.
