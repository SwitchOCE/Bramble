# Newcomer clarity

Both interfaces explain behind, beside, the touching zigzag, Bell, cycle, the golden `*`, and Pass timing. `tools/play/play.sh help` reads the same guide. Its three tips cover filling slots early, waiting on tiers and scouting.

Pass waits until End of Turn. Its reminder names no card and describes the movement in plain words. Regression tests cover play/sale timing and the visible End of Turn hint.

Owned units show their queried sell value, including savings and modifiers. Unbought shop offers omit it. Next-turn income sits under the original acorn pile, with saved and queued gold explained in the reader.

Last Blow names both fallen boards and whose attack or finishing effect won. Short-Discover and empty-pool notices remain, as requested. Discover fills thin tiers from lower tiers; an exhausted two-card pool reproduces two offers. pt4-a lacks a saved action trace, so its exact pool cannot be reconstructed.

Discover slips retain the layout marker. The guard checks that overflowing text has a readable scroll area and can scroll through all its content. Tests deliberately break scrolling and shrink the area to verify detection.

No card designs, card numbers, hero damage rules or damage wording changed.

Review follow-up validation: `./scripts/check.sh` ran once on core 0; all steps and 1,306 tests passed. Inspected 14 PC/phone renders in `build/screens/`; text-play smoke passed.
