# Newcomer clarity

Both interfaces now explain behind, beside and the unbroken touching zigzag, plus Bell, cycle and the golden `*`. The guide adds four short tips: fill slots early, wait on tiers, scout, and change tribes gradually. `tools/play/play.sh help` reads the same guide.

Mr Crumb **queues** Pass when played or sold; it **lands at End of Turn**. A regression moves him before resolution and checks both play and sale. No card designs, card numbers, hero damage rules or damage wording changed.

Buy/sell readers show scheduled next-turn income, queued gold, carry-over and queried sell values. Birds distinguish a zero-gold flight from a final sale; created units and savings use the existing rules.

Last Blow results say both boards fell and whose attack or finishing effect landed last, from either player's viewpoint. The text tool no longer prints an empty survivor list.

Discover already fills thin tiers from lower tiers and requires distinct offers. Triple rewards offer three at all six shop tiers in regression tests. Exhausting the eligible pool to two reproduces a valid two-option choice; both interfaces now explain the shortage. Empty pools produce an explicit notice. pt4-a has no saved action trace, so its exact pool cannot be reconstructed.

Validation: `check.sh` ran once. All non-test checks passed; an old 12-page assertion failed. Updated it and restored the Discover label; the full GUT rerun passes 1,304 tests, including nine new regressions. Inspected 22 PC/phone renders in `build/screens/`; long keyword slips scroll.
