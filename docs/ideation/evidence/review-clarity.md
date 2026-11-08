# Review: clarity (b99b5ad..a425a00)

**Counts: cut 0, ask 3, simplify 4.** The change moves pt4-b's problems 3 and 4, and the "basics only from log" remark. The basics are now in the help, but they aren't shown during play.

## Ask
- `src/core/recruit_discover.gd:50`, `recruit_view.gd:459`: the short-Discover and empty-pool notices come from pt4-a, not pt4-b. They're unrequested, though behaviour-neutral. Keep them or drop them?
- `src/ui/widgets/card_picker.gd:132`: the change removes the `must_fit` meta and makes the slips scroll, so the layout check no longer guards Discover slips. Is that acceptable?
- `src/ui/widgets/gold_plaque.gd:60`: the income text permanently replaces the acorn pile. That's a visual change nobody asked for.

## Simplify
- `content/schema/effects.json:743`: the Pass reminder names Mr Crumb and uses jargon ("final touching run", "where that Pass was queued"). Say: "At End of Turn the bonus moves right through touching units along F1-B1-F2-B2-F3-B3-F4; the last keeps it. A sold giver starts from its old slot."
- `recruit_view.gd:524`, `tools/play/play_view.gd:387`: "before card effects" misleads, because `sell_value` already includes savings and query modifiers (Pennywort Snail). The text tool also shows a sell value on unbought shop offers, and it labels board units differently ("[sell: N gold]"). Drop the qualifier and the shop rows.
- `src/ui/screens/how_to_play.gd:180-181`: pt4-b asked for two tips (fill early, sit on a tier). Scouting and changing tribes are extra, and "Move a helper away from a threat" is vague. Keep two tips.
- `how_to_play.gd:546`, `keyword_rules.gd:21`: the Sell demo now reads "See its sell value" (it should be "Free a slot for gold"), and "A gap stays a gap" says nothing. Cut it.

## Checked
- No card numbers or designs changed. The diff touches only the Pass reminder in `content/`.
- The Behind, Beside, Touching, Bell and Cycle text matches `board_geometry.gd`, `combat.gd:380` and `:470`. The cycle text gives the default attack order. The golden-page fix (Triple Reward spell) matches `recruit_rules.gd:323`.
- The "next income" index is correct (`recruit_rules.gd:131`).
- Probes: breaking the Last Blow wording fails `test_clarity`. Removing the "Pass lands at End of Turn" hint (`recruit_view.gd:560`) fails nothing, so it's untested.
- `./scripts/check.sh`: all steps passed, 1,304 tests.
- Text tool, seed 11, scripted newcomer play (8th): `help` answers behind, beside, touching, Bell, cycle, `*`, Pass timing and sell value. Income shows every turn, and `log` explains `*`. The tool doesn't point you to `help` at the moment of need: the tips appear only if you run it. No mutual wipe came up in play, so the Last Blow line was checked through its test only. I didn't render or inspect the GUI.
