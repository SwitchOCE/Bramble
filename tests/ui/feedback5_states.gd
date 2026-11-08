extends RefCounted
## A real, paused exchange for the round-five log screenshots: Mire, Bitter and a full-board Drip.

const KIT := preload("res://tests/core/combat_kit.gd")


static func fight() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 202611082207
	var combat := Combat.create(KIT.library, GameConfig.full_game(), rng)
	var ours: Dictionary = {0: KIT.u("wee_wobbly", 10, 30)}
	for slot: int in range(1, 7):
		ours[slot] = KIT.plain(2, 10)
	combat._setup(
		[KIT.board(ours), KIT.board({0: KIT.u("madame_bufo", 2, 30), 1: KIT.u("warty_nan", 1, 20)})]
	)
	combat._recalc_auras(false)
	combat.emit_event(
		"combat_start",
		{
			"boards": [combat._board_views(0), combat._board_views(1)],
			"player_ids": [0, 1],
			"first_side": 0
		}
	)
	CombatLanes.bell(combat)
	combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	return {"events": combat.events}
