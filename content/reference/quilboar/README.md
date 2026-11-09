# Quilboar reference — test only

This content is an opt-in measuring stick, not release content. Every ID starts
`qb_`; units and spells use the `slice` set so they share the harness's economy
only after the separate `reference_quilboar` loader opts in. The flag defaults
to false. Nothing in this directory belongs in a release export or a normal
shop, discover, creation or tribe-rotation pool.

`rates.json` holds the spec's budget dials under `quilboar_ref`. B is the default;
C restores full gem-size steps, while `uncut` restores the Battlegrounds text
numbers (including Hogrider's all-Quilboar targets and Tunneler's every-attack
rate). These are budget values, not size caps or rate-limit overlays. The A
fallback and later-phase dials are recorded as specified but are not extra
Phase 1 mechanics. `geomant_gems`, `bandit_gems`, `roogug_every` and
`brigand_barrage_casts` are read by Phase 2 when those mechanics are built,
not by the Phase 1 engine. Loop guards live separately and survive caps-off.

The authored faces and integer-half-unit `gem_size_add` effects are B. The
reference loader configures size effects and other named dials for the selected
preset. A step of `attack: 1` means half an Attack of future gem size, not an
immediate stat buff. Gem size starts at two halves on each axis, rounds up for
each gem, and never changes stats already granted.

Phase 1 contains thirteen units and three spells. The five unit Choose One
cards available to Tunneler are Crater Miner, Fearless Foodie, Sly Infiltrator,
Snare Trapper and Veteran Brigand, restricted to the player's tier. Gem Day is
a Choose One spell, not a Tunneler candidate. Created cards sell for zero.

Veteran Brigand's gem mode works in Phase 1. Its Barrage mode is explicitly
`unavailable` and cannot be selected or executed by Trailblazer; the printed
complete face is retained for source comparison. Barrage and its Flapper token
producer wait for Phase 2, where the Barrage reading is settled. This temporary
restriction does not affect the paper Choose One line, which uses the gem mode.

Also deferred to Phase 2: Bandit, Geomant, Roogug, Surveyor, Felboar,
Vineweaver, Tusker, Camper and Roadboar. Bonker waits for Phase 3's repeat
attacks. They have no loaded card definitions, so neither shops nor random
Quilboar generation can accidentally acquire an unsupported body. The paper
line's early Roadboar gem income is consequently an accounting limitation of
Phase 1, rather than a silently implemented extra phase.

All three spells are `scaling_exempt`: hero/spell scaling must not turn the
future-only additive gem axis into proportional scaling. A gem effect from a
unit is not a spell cast. A Blood Gem actually played from hand is a spell cast.
Gem Confiscation applies its three gems first, then moves gem-ledger stats from
adjacent same-row units only.
