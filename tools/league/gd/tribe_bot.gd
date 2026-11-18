extends SimpleBot
## TribeBot from the balance pass of 18 Nov (`docs/workstreams/bot-league/balance-pass-18-nov/
## tribe_lobby.gd.txt`), copied without change apart from being its own file: a tribe-locked
## greedy bot. `tribe_records.gd` plays it so the league's Rust port can be checked against it.
var tribe: String = ""


func _init(stream: Rng, wanted: String) -> void:
	super(stream)
	tribe = wanted


func choose(session: GameSession, player: PlayerState) -> Dictionary:
	var best: Dictionary = {"type": "end_turn"}
	var best_score: float = 0.0
	var refresh: Dictionary = {}
	for action: Dictionary in session.legal_actions(player.id):
		if action["type"] == "refresh":
			refresh = action
			continue
		var score: float = _score(session, player, action)
		if action["type"] == "buy" and not CoreUtil.to_bool(action["spell"]):
			var card: UnitDef = session.library.get_card(
				player.shop_units[CoreUtil.to_int(action["index"])]
			)
			if not card.has_tribe(tribe):
				score = -1.0
		if action["type"] == "buy" and CoreUtil.to_bool(action["spell"]):
			score = -1.0
		if action["type"] == "pick":
			var option: UnitDef = session.library.get_card(
				player.discover_options[CoreUtil.to_int(action["index"])]
			)
			if not option.has_tribe(tribe):
				score = 1.0
		if action["type"] == "play":
			score += _row_pref(player, action)
		if score > best_score:
			best_score = score
			best = action
	var keep: int = 0
	@warning_ignore("integer_division")
	var goal: int = 1 + (session.round_number + 1) / 2
	if player.tier < goal and player.tier < 6:
		keep = session.rules.upgrade_cost(player)
	var may_refresh: bool = player.refreshes_paid < 8 and player.gold >= 3 + keep
	if best_score <= 0.0 and not refresh.is_empty() and may_refresh:
		return refresh
	return best


func _row_pref(player: PlayerState, action: Dictionary) -> float:
	var card: Unit = player.hand[CoreUtil.to_int(action["hand"])]
	if card.is_spell():
		return 0.0
	var slot: int = CoreUtil.to_int(action["slot"])
	if slot < 0:
		return 0.0
	var t: String = card.def.text
	var back: bool = (
		t.contains("in front of this")
		or t.contains("Squire")
		or t.contains("Instead of")
		or t.contains("Can't attack")
		or t.contains("Start of fight: Hit")
	)
	if card.def.keywords.has(&"taunt"):
		back = false
	if back:
		return 1.0 if slot >= 4 else -1.0
	return 0.5 if slot < 4 else 0.0
