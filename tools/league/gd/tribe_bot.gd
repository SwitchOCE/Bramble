extends SimpleBot
## Tribe-locked greedy bot from the 18 Nov balance pass, updated for Pigeon and Mouse reworks.
## `tribe_records.gd` plays it so the league's Rust port can be checked against it.

const GuardPost := preload("res://src/content/pigeon/mechanics/guard_post.gd")

var tribe: String = ""


func _init(stream: Rng, wanted: String) -> void:
	super(stream)
	tribe = wanted


func choose(session: GameSession, player: PlayerState) -> Dictionary:
	var best: Dictionary = {"type": "end_turn"}
	var best_score: float = 0.0
	var refresh: Dictionary = {}
	var actions: Array[Dictionary] = session.legal_actions(player.id)
	var held: Array[int] = _held_reserves(session, player)
	var guard_post: int = GuardPost.post_of(player.slots)
	for action: Dictionary in actions:
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
			if held.has(CoreUtil.to_int(action["hand"])):
				continue
			score += _row_pref(player, action)
		if action["type"] == "sell" and score > 0.0 and not held.is_empty():
			var sold: Unit = player.board[CoreUtil.to_int(action["slot"])]
			if not _has_replacement(player, held, sold):
				score = -1.0
		if action["type"] == "ability":
			match CoreUtil.to_text(action["mechanic"]):
				"pigeon_lance_corporal":
					score = 95.0
				"pigeon_grenadier":
					# Keep the existing post, or choose the first legal slot to establish it.
					var target: int = CoreUtil.to_int(action["target"])
					score = 95.0 if guard_post < 0 or target == guard_post else -1.0
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
	if best["type"] == "play" and CoreUtil.to_int(best["slot"]) >= 0:
		return _play_at_best_renown(player, actions, best, best_score)
	return best


func _held_reserves(session: GameSession, player: PlayerState) -> Array[int]:
	var held: Array[int] = []
	if player.board_count() < 5:
		return held
	# The recruit phase has the config limit. Combat checks for increases at each arrival.
	for i: int in player.hand.size():
		if held.size() >= session.config.reserve_limit:
			break
		var card: Unit = player.hand[i]
		if not card.is_spell() and card.has_mechanic(&"pigeon_reserve"):
			held.append(i)
	return held


func _has_replacement(player: PlayerState, held: Array[int], sold: Unit) -> bool:
	for i: int in player.hand.size():
		var card: Unit = player.hand[i]
		if not held.has(i) and not card.is_spell() and _unit_worth(card) > _unit_worth(sold):
			return true
	return false


func _play_at_best_renown(
	player: PlayerState, actions: Array[Dictionary], best: Dictionary, best_score: float
) -> Dictionary:
	# Keep the unit chosen by the usual scores; use those scores again for equal Renown.
	var hand: int = CoreUtil.to_int(best["hand"])
	var best_renown: int = player.slots[CoreUtil.to_int(best["slot"])].renown
	for action: Dictionary in actions:
		if action["type"] != "play" or CoreUtil.to_int(action["hand"]) != hand:
			continue
		var slot: int = CoreUtil.to_int(action["slot"])
		var renown: int = player.slots[slot].renown
		var score: float = _play_score(player, action) + _row_pref(player, action)
		if renown > best_renown or (renown == best_renown and score > best_score):
			best = action
			best_renown = renown
			best_score = score
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
		or t.contains("Can't attack")
		or t.contains("Pile on {")
		or t.contains("Your Hand-me-downs")
		or t.contains("more reservist")
		or t.contains("Reservists from your hand")
		or t.contains("Your reservists have")
		or t.contains("After a reservist steps in")
	)
	if card.def.keywords.has(&"taunt"):
		back = false
	if back:
		return 1.0 if slot >= 4 else -1.0
	return 0.5 if slot < 4 else 0.0
