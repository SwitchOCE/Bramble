extends RefCounted
## Designed native inputs; shared by focused action checks and cold-reader capture.
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")


static func _unit(port: CorePort, def_id: String) -> RecruitUnit:
	var rules: RecruitRules = port.session.get_rules()
	var unit: RecruitUnit = RecruitUnit.make(rules.library.get_unit(def_id), rules.new_iid())
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	return unit


static func make(kind: String) -> CorePort:
	var port := CorePort.new()
	var config: GameConfig = GameConfig.full_game()
	config.set_value("hero_choice", false)
	config.set_value("tribes_per_lobby", 0)
	port.setup(config)
	assert(port.new_game(72).is_empty())
	var players: Array[PlayerState] = port.session.get("_players")
	var player: PlayerState = players[0]
	player.shop.clear()
	player.shop_spells.clear()
	player.hand.clear()
	player.items.clear()
	player.board.fill(null)
	player.gold = 10
	player.tier = 1
	player.upgrade_cost = port.session.get_rules().base_upgrade_cost(1)
	player.recruit_log.clear()
	player.board[0] = _unit(port, "mr_crumb")
	player.board[5] = _unit(port, "mrs_sorrel")
	for id: String in ["sleeping_partner", "hedge_witch", "nan_toadstool", "mr_crumb"]:
		player.shop.append(_unit(port, id))
	match kind:
		"play":
			player.hand.append(_unit(port, "sleeping_partner"))
		"sell":
			player.board[1] = _unit(port, "sleeping_partner")
		"triple":
			player.board[1] = _unit(port, "sleeping_partner")
			player.hand.append(_unit(port, "sleeping_partner"))
		"ooze":
			player.board[1] = _unit(port, "figgy_duff")
		"bird":
			player.board[1] = _unit(port, "chiffchaff")
			player.board[1].played_round = player.round_number - 1
		"scout":
			player.board.fill(null)
			player.board[2] = _unit(port, "mr_crumb")
			player.board[5] = _unit(port, "mrs_sorrel")
			var enemy: Array = [null, null, null, null, null, null, null]
			enemy[2] = _unit(port, "wick").view()
			enemy[5] = _unit(port, "old_brock").view()
			player.scout = {"views": enemy, "slots": [[], [], [], [], [], [], []], "nests": []}
	port.session.get_rules().board_changed(player)
	return port


static func perform(screen: RecruitScreen, kind: String) -> void:
	match kind:
		"buy", "triple":
			screen.set("_selected", {"zone": "shop", "index": 0})
			screen._on_buy_selected()
		"sell", "bird":
			screen.set("_selected", {"zone": "board", "index": 1})
			screen._on_sell_selected()
		"play":
			screen._drop({"zone": "hand", "index": 0}, "board", 1)
		"ooze":
			screen._drop({"zone": "shop", "index": 0}, "board", 1)
		"tier-up":
			screen._on_tier_up()
		"scout":
			screen._on_tapped("scout", 2)
