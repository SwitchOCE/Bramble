extends Control
## The real game for the film tool (tools/feel/film): a GameController with the scenario's seed,
## then the human's board, hand, gold and Renown set as the scenario's "setup" says. Named
## targets for the scenario: "shop:i", "spell:k", "slot:i", "hand:i" (a hand card's upper part),
## "sell" (over the shop's middle).
## setup: {gold, board {slot: card id}, hand [card ids], renown {slot: amount}}
## "drop_by_middle": true films with cards dropping where their middle is (GameSettings, not
## saved); absent or false, where the pointer is.

var game: GameController


func feel_setup(scenario: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var by_middle: bool = scenario.get("drop_by_middle", false) == true
	GameSettings.set_drop_by_middle(by_middle, false)
	game = GameController.new()
	game.name = "Game"
	add_child(game)
	var tribes: PackedStringArray = PackedStringArray()
	for tribe: Variant in scenario.get("tribes", []):
		tribes.append(str(tribe))
	game.start(GameContent.load_default(), GlassPieces.as_int(scenario.get("seed", 1)), tribes)
	var setup: Dictionary = scenario.get("setup", {})
	var me: PlayerState = game.flow.human()
	var session: GameSession = game.flow.session
	var board: Dictionary = setup.get("board", {})
	for key: Variant in board:
		me.place(_unit(session, str(board[key])), str(key).to_int())
	for card_id: Variant in setup.get("hand", []):
		me.hand.append(_unit(session, str(card_id)))
	var renown: Dictionary = setup.get("renown", {})
	for key: Variant in renown:
		me.slots[str(key).to_int()].renown = GlassPieces.as_int(renown[key])
	if setup.has("gold"):
		me.gold = GlassPieces.as_int(setup["gold"])
	# apply Renown and slot keywords to the units on them, as the core does after any board change
	session.recruit.refresh_auras(me)
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()


func feel_point(target: String) -> Vector2:
	var screen: RecruitScreen = game.recruit
	var box: Vector2 = screen.card_box()
	var parts: PackedStringArray = target.split(":")
	var index: int = parts[1].to_int() if parts.size() > 1 else 0
	match parts[0]:
		"shop":
			return screen.shop_xy(index) + box / 2.0
		"slot":
			return screen.slot_xy(index) + box / 2.0
		"spell":
			var spell: Control = screen.node_for("spell", index)
			return spell.position + spell.size / 2.0
		"hand":
			var hand: Array = screen.state.get("hand", [])
			var n: int = hand.size()
			var place: Vector3 = screen.hand_place(index, n)
			return Vector2(place.x, place.y) + Vector2(box.x / 2.0, box.y * 0.3)
		"sell":
			return screen.shop_xy(2) + Vector2(box.x, box.y / 2.0)
	push_error("feel_game: no target '%s'" % target)
	return Vector2.ZERO


static func _unit(session: GameSession, card_id: String) -> Unit:
	var made: Unit = session.new_unit(session.library.get_card(StringName(card_id)), false)
	made.bought_copies = 1
	return made
