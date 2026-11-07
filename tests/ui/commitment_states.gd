extends RefCounted
## Explicit staged states for phone review, using real units and their normal views.

const CorePort := preload("res://src/ui/adapter/core_port.gd")


static func stage(port: CorePort, screen_name: String) -> void:
	var session: GameSession = port.session
	var player: PlayerState = session._players[0]
	var rules: RecruitRules = session.get_rules()
	for slot: int in player.board.size():
		player.board[slot] = null
	player.hand.clear()
	player.items.clear()
	player.away.clear()
	player.pending.clear()
	player.round_number = 10
	session._round = 10
	player.gold = 20
	player.tier = 6
	session._lobby_tribes = ["Hedgerow folk", "Fairies", "Oozes", "Birds", "Hunters"]
	player.tribe_bonuses = {"Fairies": 3, "Oozes": 1, "Birds": 2}
	var chosen: String = screen_name.trim_prefix("commit_")
	if chosen in ["bonus", "harvest", "nest", "nest_tile"]:
		chosen = "mrs_jay"
	var unit: RecruitUnit = RecruitUnit.make(port.library.get_unit(chosen), rules.new_iid())
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	unit.played_round = 1
	player.board[0] = unit
	player.board[1] = RecruitUnit.make(port.library.get_unit("one_swallow"), rules.new_iid())
	player.board[4] = RecruitUnit.make(port.library.get_unit("moss_ooze"), rules.new_iid())
	var away: RecruitUnit = RecruitUnit.make(port.library.get_unit("old_tern"), rules.new_iid())
	away.add_permanent(3, 4)
	player.away.append({"unit": away, "left": 9, "due": 12, "nest": 2})
	if screen_name == "commit_nest_tile":
		player.slot_effects[2] = [{"attack": 1, "health": 2}, {"attack": 2, "health": 0}]
		var goose: RecruitUnit = RecruitUnit.make(
			port.library.get_unit("mother_goose"), rules.new_iid()
		)
		goose.add_permanent(9, 9)
		player.away.append({"unit": goose, "left": 9, "due": 12, "nest": 3})
		var occupied: RecruitUnit = RecruitUnit.make(
			port.library.get_unit("chiffchaff"), rules.new_iid()
		)
		player.away.append({"unit": occupied, "left": 9, "due": 12, "nest": 0})
	player.items.append(HandItem.make(port.library.get_card("harvest_supper"), rules.new_iid()))
	rules.board_changed(player)
