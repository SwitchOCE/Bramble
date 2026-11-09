extends RefCounted
## Real recruit views with a golden aura, a stacked wall and a frog two kisses into courtship.


static func unit(id: String, iid: int, golden: bool = false, kisses: int = -1) -> Dictionary:
	var made: RecruitUnit = RecruitUnit.make(LegacyBog.library().get_unit(id), iid, golden)
	if kisses >= 0:
		made.counters["kisses"] = kisses
	return made.view()


static func board() -> Array:
	return [
		unit("warty_nan", 1, true),
		unit("madame_bufo", 2),
		unit("natterjack_chorus", 3, true),
		null,
		unit("his_highness", 4, false, 2),
		unit("warty_nan", 5),
		null,
	]


static func recruit(state: Dictionary) -> void:
	state["board"] = board()
	state["slot_effects"] = [[], [], [], [], [], [], []]
	state["bands"] = [false, false, false, false, false, false, false]
	state["away"] = []
	state["hand"] = []
	state["hand_items"] = []
	state["next_opponent_last_board"] = [
		unit("little_nip", 101), unit("old_lutra", 102), null, null, null, null, null
	]
	state["next_opponent_last_slot_effects"] = [[], [], [], [], [], [], []]
	state["next_opponent_last_nests"] = []
