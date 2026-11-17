# Taste calls: Ambush (brief 7)

## Final owner-directed revision, then freeze

**Generous opening.** The owner said “It's still very strong, but yeah, it's probably quite balanceable” and “start generous and dial back”; quarter Attack was too small.
Use HALF current Attack, rounded up. Keep every existing shared-use, timing, return, windfury, golden, Master-selection and payoff rule; retain summon counts and printed bodies.

**Bodkin is the capstone.** The owner explicitly permits FULL Attack for pile-on Ambushes here, still once per unit; normal and golden have the same full-Attack rule.
Text: “Pile on. Your pile-on Ambushes deal full Attack.” Opening Ballista and Catapult strikes remain half Attack; no extra uses or stacking.

**Pigeon charge, not conversion.** The owner rejected temporary Health and specified a full row attacking the enemy across, with normal retaliation and no fallback.
Reuse `attack_now` once per snapshotted unit, normal or golden. The command continues after Lieutenant dies, but dead/unable/replaced attackers and absent/dying across targets are skipped; no immunity is added.

**Measurement rule before the run.** Preserve all frozen algorithms, ten layouts and both parameters; compare original `2e0b9081`, quarter `20e85db2`, then live half/charge once each.
Setup means an actual strike/summon/positive buff for ordinary full cards; Lieutenant is positive opening damage originally, positive temporary Health at quarter, and an actual out-of-turn attack now (including one stopped by Thorns). Publish old/quarter/new and all setup counts, then stop without tuning.

## Historical quarter attempt (`20e85db2`)

**Owner approval and boundary.** The owner approved “the smaller first strike that only goes once per fight”; otherwise keeping damage without retaliation requires asking first.
Use Ambush for that exception only; replace Lieutenant's free row damage with temporary Health. No changes to unrelated tribes, tiers, printed stats or recruit economy.

**Damage and shared use.** Weighed half Attack against a smaller opening that leaves ordinary trades intact; chose a quarter of current Attack, rounded up, once per unit per fight across all sources.
Returns keep the spent use; windfury, golden copies, several Masters and neighbour attacks cannot refresh it. Rounded up keeps a 2-Attack Cousin's opening relevant without repeat damage.

**Timing and Mouse roles.** Keep Pile on as the neighbour trigger, Ballista as an opening Ambush, and make Catapult Ambush before its first ordinary attack rather than replace every turn.
Master of Engines selects only the leftmost back unit, gives +4 Attack this fight (+8 golden), then asks it to Ambush the weakest enemy; a spent unit is not replaced by another shooter. This keeps one artillery moment rather than a row firing.

**Payoffs and capstone.** Pile-on payoffs stay on the neighbour trigger; Pikeman's growth limit becomes one, Cutpurse and Fencing Master still pay only after a pile-on Ambush.
Bodkin makes pile-on Ambush half Attack (75% golden), never full Attack and never extra uses; it remains a large capstone improvement to one small opening. Ordinary attack and summon engines otherwise stay as they were.

**Pigeon defence.** Weighed a smaller free row volley against a defensive replacement; chose temporary Health equal to a quarter of each slot's Attack, half golden, on a full row.
It retains the slot-building theme and existing multipliers but deals no opening damage. Its frozen setup test will require a positive Health buff, not a no-op full-row hook.

**Measurement scope fixed before running.** Keep every frozen layout, parameter, comparison and summary rule. Mouse setup means an actual Ambush; Lieutenant setup means an actual positive Health buff.
Also price all fourteen affected normalized full cards against a read-only export of the old content; a full-card case is set up by an actual strike, summon or positive buff. Economy, printed stat differences and a fully tribal board remain outside those numbers.

**Full-card ties, rather than hidden retuning.** All direct strike replacements fall to ×1 in the medians, but Scout/Captain keep theirs, and King's built-around median stays ×3 because its bodies remain valuable.
Reported the bar as not fully demonstrated and asked whether to preserve that body output or reduce it; no reply is assumed. This patch keeps non-Ambush summon value and the frozen measure intact.

## Final measurement and freeze

**Observed outcome, not another tuning loop.** Half Ambush still ties quarter in most frozen medians; Bodkin becomes ×2 built around / ×1.5 all ten, versus original ×2.5 / ×1.75.
Lieutenant's ordinary charge is ×1 / ×1 on the matched plain boards, firing in seven cases rather than two. Report the remaining ties and partial-damage blind spot; keep the owner-directed revision and stop after passing checks.
