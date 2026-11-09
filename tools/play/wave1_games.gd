extends SceneTree
## Reproducible command clients for wave 1 evidence. All mutations use PlayGame.run.
## Normal full_game economy, shops, heroes and Hard lobby; no dev actions or human bot.
## Run under the shared lock and 3G scope, then verify the saves with tools/play/play.sh.

const OUT: String = "res://docs/ideation/evidence/wave1"
const BIRD_ORDER: Array[String] = [
	"mrs_stork",
	"mr_redbreast",
	"great_lump",
	"gabble_ratchet",
	"tom_tit",
	"cuckoo",
	"mother_goose",
	"chiffchaff",
	"mrs_jay",
	"one_swallow",
	"old_tern",
	"seven_whistlers",
	"jack_daw",
	"mrs_dunnock",
	"redwing",
	"mag_pye"
]
const FAIRY_ORDER: Array[String] = [
	"old_moth_annis",
	"fairy_monarch",
	"cradle_fetch",
	"reel_mistress",
	"cluricaun",
	"belladonna",
	"hedge_witch",
	"nan_toadstool",
	"sally_spore",
	"lob_lie_by_the_fire",
	"silky",
	"hob_in_the_hearth",
	"will_o_the_wisp",
	"rainbow_chaser",
	"changeling",
	"queen_of_elfland"
]
const BIRD_CURVE: Array[int] = [3, 5, 7, 10, 12]
const FAIRY_CURVE: Array[int] = [2, 4, 6, 9, 11]
const FLIERS: Array[String] = ["one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"]

var _game: PlayGame
var _tribe: String
var _slug: String
var _trace: FileAccess
var _text: FileAccess
var _snapshots: Array[Dictionary] = []
var _seen_events: Dictionary = {}
var _counts: Dictionary = {}
var _checkpoints: Dictionary = {}
var _refused: Array[Dictionary] = []
var _round: int = 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var seed_value: int = 1
	while seed_value <= 100:
		var candidate := PlayGame.start(seed_value)
		var state: Dictionary = candidate.session.get_state()
		var tribes: Array = state["lobby_tribes"]
		if tribes.has("Birds") and tribes.has("Fairies"):
			break
		seed_value += 1
	if seed_value > 100:
		printerr("No ordinary lobby containing both tribes among seeds 1..100")
		quit(1)
		return
	print("wave1_games: first eligible seed ", seed_value)
	for tribe: String in ["Birds", "Fairies"]:
		_run_game(seed_value, tribe)
	quit(0)


func _run_game(seed_value: int, tribe: String) -> void:
	_game = PlayGame.start(seed_value)
	_tribe = tribe
	_slug = tribe.to_lower()
	_trace = FileAccess.open(OUT.path_join(_slug + "-actions.jsonl"), FileAccess.WRITE)
	_text = FileAccess.open(OUT.path_join(_slug + "-playthrough.txt"), FileAccess.WRITE)
	_snapshots = []
	_seen_events = {}
	_counts = {}
	_checkpoints = {}
	_refused = []
	_text.store_line("Wave 1 scripted command client: committed to " + tribe)
	(
		_text
		. store_line(
			(
				"Seed %d is the first normal lobby from seed 1 with Birds and Fairies. No outcome search."
				% seed_value
			)
		)
	)
	_text.store_line(
		"Every action uses PlayGame.run; no spawns, injected stats, altered gold, or human_bot."
	)
	var turns: int = 0
	while not _game.session.is_over() and turns < 50:
		_choose()
		if _game.session.is_over():
			break
		var state: Dictionary = _state()
		_round = CoreUtil.to_int(state["round"])
		_text.store_line("\n===== ROUND %d: BEFORE ACTIONS =====" % _round)
		_text.store_line(PlayView.text(_game, "Commitment: " + tribe))
		_snapshot("round_start")
		_play_turn()
		_choose()
		_text.store_line("\n===== ROUND %d: READY TO FIGHT =====" % _round)
		_text.store_line(PlayView.text(_game, ""))
		_snapshot("before_fight")
		_act(["end"], "End the turn and fight the ordinary lobby")
		var last_fight: Dictionary = _game.session.get_last_combat()
		var first_home: Dictionary = _checkpoints.get("first_homecoming", {})
		_write_json(_slug + "-fight-r%02d.json" % _round, last_fight)
		if (
			_checkpoints.has("first_homecoming")
			and not _checkpoints.has("homecoming_following_fight")
			and (
				CoreUtil.to_int(last_fight.get("round", 0))
				>= CoreUtil.to_int(first_home.get("round", 1000))
			)
		):
			_checkpoint("homecoming_following_fight")
		_text.store_line("\n===== ROUND %d: FIGHT AND NEXT TURN =====" % _round)
		_text.store_line(PlayView.text(_game, ""))
		turns += 1
	if not _game.session.is_over():
		printerr("wave1_games: did not reach game over for ", tribe)
		quit(1)
		return
	var end: Dictionary = _state()
	_write_json(_slug + "-save.json", _game.to_save())
	_write_json(
		_slug + "-round-states.json", {"seed": seed_value, "tribe": tribe, "snapshots": _snapshots}
	)
	_write_json(_slug + "-game-log.json", _game.session.get_game_log())
	_write_json(
		_slug + "-summary.json",
		{
			"seed": seed_value,
			"commitment": tribe,
			"phase": end["phase"],
			"round": end["round"],
			"placement": end["placement"],
			"health": end["health"],
			"actions": _game.actions.size(),
			"event_counts": _counts,
			"checkpoints": _checkpoints,
			"refused": _refused,
			"final_board": end["board"],
			"final_away": end["away"],
			"ring_size": end["ring_size"],
			"selection":
			"First seed from 1 with both tribes in the ordinary rotated lobby; no outcome selection."
		}
	)
	_text.store_line("\n===== GAME OVER / COMPLETE LOBBY LOG =====")
	_text.store_line(PlayView.log_text(_game))
	_text.flush()
	_trace.flush()
	print(
		"wave1_games: ",
		tribe,
		" game_over round=",
		end["round"],
		" placement=",
		end["placement"],
		" actions=",
		_game.actions.size(),
		" counts=",
		_counts
	)


func _state() -> Dictionary:
	return _game.session.get_state()


func _act(words: Array[String], reason: String) -> bool:
	var before: Dictionary = _state()
	_note_events(before)
	var problem: String = _game.run(PackedStringArray(words))
	var after: Dictionary = _state()
	_note_events(after)
	var row: Dictionary = {
		"action": _game.actions.size(),
		"round": before["round"],
		"command": words,
		"reason": reason,
		"result": "accepted" if problem == "" else problem,
		"gold_before": before["gold"],
		"gold_after": after["gold"],
		"health_after": after["health"],
		"tier_after": after["tier"],
		"ring_size_after": after["ring_size"]
	}
	_trace.store_line(JSON.stringify(row))
	_text.store_line(
		"$ %s  # %s%s" % [" ".join(words), reason, "" if problem == "" else " REFUSED: " + problem]
	)
	if problem != "":
		_refused.append(row)
		return false
	var shop: Array = after["shop"]
	var offers_birds: bool = false
	var offers_fairies: bool = false
	for card: Dictionary in shop:
		var tribes: Array = card.get("tribes", [])
		offers_birds = offers_birds or tribes.has("Birds")
		offers_fairies = offers_fairies or tribes.has("Fairies")
	if offers_birds and offers_fairies and not _checkpoints.has("mixed_shop"):
		_checkpoint("mixed_shop")
	var after_away: Array = after["away"]
	if (
		not _checkpoints.has("ring_and_away")
		and _ring_total(after) > 0
		and not after_away.is_empty()
	):
		_checkpoint("ring_and_away")
	return true


func _note_events(state: Dictionary) -> void:
	var events: Array = state["recruit_log"]
	for index: int in events.size():
		var key: String = "%s:%d" % [str(state["round"]), index]
		if _seen_events.has(key):
			continue
		_seen_events[key] = true
		var event: Dictionary = events[index]
		var type: String = str(event.get("type", ""))
		_counts[type] = CoreUtil.to_int(_counts.get(type, 0)) + 1
		if type == "home" and not _checkpoints.has("first_homecoming"):
			_checkpoint("first_homecoming")


func _snapshot(stage: String) -> void:
	var state: Dictionary = _state()
	_snapshots.append({"stage": stage, "action_count": _game.actions.size(), "state": state})
	_note_events(state)
	if _ring_total(state) >= 10 and not _checkpoints.has("ring_carry"):
		_checkpoint("ring_carry")


func _checkpoint(label: String) -> void:
	_checkpoints[label] = {"action_count": _game.actions.size(), "round": _state()["round"]}
	_write_json(_slug + "-checkpoint-" + label + ".json", _game.to_save())
	_write_json(_slug + "-state-" + label + ".json", _state())


func _write_json(name: String, data: Dictionary) -> void:
	var file := FileAccess.open(OUT.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ", false))


func _choose() -> void:
	for _step: int in 8:
		var choice: Variant = _state()["pending_choice"]
		if choice == null:
			return
		var pending: Dictionary = choice
		var options: Array = pending["options"]
		var best: int = 0
		var score: float = -INF
		for index: int in options.size():
			var card: Dictionary = options[index]
			var value: float = _value(card)
			if value > score:
				score = value
				best = index
		_act(
			["choose", str(best)],
			"Choose the best offered card for the commitment; hero ties use first"
		)


func _play_turn() -> void:
	_play_hand()
	_fly()
	_climb()
	for _step: int in 45:
		_choose()
		_play_hand()
		var state: Dictionary = _state()
		var gold: int = CoreUtil.to_int(state["gold"])
		if gold <= _reserve(state):
			break
		if _buy_best():
			continue
		if _buy_spell():
			continue
		if CoreUtil.to_int(state["refresh_cost"]) <= gold - _reserve(state):
			if not _act(["refresh"], "Look for the committed tribe and its engine pieces"):
				break
		else:
			break
	_play_hand()
	_arrange()
	_fly()
	_play_hand()
	_arrange()


func _reserve(state: Dictionary) -> int:
	var tier: int = CoreUtil.to_int(state["tier"])
	var schedule: Array[int] = BIRD_CURVE if _tribe == "Birds" else FAIRY_CURVE
	if tier < 6 and _round + 1 == schedule[tier - 1]:
		return maxi(0, CoreUtil.to_int(state["tier_up_cost"]) - 1 - mini(10, _round + 3))
	return 0


func _climb() -> void:
	var state: Dictionary = _state()
	var tier: int = CoreUtil.to_int(state["tier"])
	var schedule: Array[int] = BIRD_CURVE if _tribe == "Birds" else FAIRY_CURVE
	if (
		tier < 6
		and _round >= schedule[tier - 1]
		and CoreUtil.to_int(state["gold"]) >= CoreUtil.to_int(state["tier_up_cost"])
	):
		_act(["tier"], "Follow the synthesis tier-up schedule when affordable")


func _value(card: Dictionary) -> float:
	var tribes: Array = card.get("tribes", [])
	var body: float = (
		CoreUtil.to_float(card.get("attack", 0)) + CoreUtil.to_float(card.get("health", 0))
	)
	if not tribes.has(_tribe):
		return body
	var order: Array[String] = BIRD_ORDER if _tribe == "Birds" else FAIRY_ORDER
	var rank: int = order.find(str(card.get("def_id", card.get("id", ""))))
	return 50.0 + body + (order.size() - rank if rank >= 0 else 0)


func _copies(state: Dictionary, id: String) -> int:
	var count: int = 0
	for group: Array in [state["board"], state["hand"], state["away"]]:
		for value: Variant in group:
			if value != null:
				var card: Dictionary = value
				if str(card["def_id"]) == id and not CoreUtil.to_bool(card.get("golden", false)):
					count += 1
	return count


func _buy_best() -> bool:
	var state: Dictionary = _state()
	var shop: Array = state["shop"]
	var board: Array = state["board"]
	var empty: int = board.find(null)
	var best: int = -1
	var most: float = -INF
	for index: int in shop.size():
		var card: Dictionary = shop[index]
		if CoreUtil.to_int(card["cost"]) > CoreUtil.to_int(state["gold"]) - _reserve(state):
			continue
		var tribes: Array = card["tribes"]
		var id: String = str(card["def_id"])
		var copies: int = _copies(state, id)
		if copies >= 3 or (copies == 1 and not FLIERS.has(id) and _round >= 7):
			continue
		var score: float = _value(card) + (25.0 if copies == 2 else 0.0)
		if not tribes.has(_tribe) and (empty < 0 or _round >= 5):
			continue
		if score > most:
			most = score
			best = index
	if best < 0:
		return false
	var offer: Dictionary = shop[best]
	if empty < 0:
		var weakest: int = _weakest_slot(state)
		if weakest < 0:
			return false
		var weakest_card: Dictionary = board[weakest]
		if _value(offer) <= _value(weakest_card) + 3.0:
			return false
		if not _act(
			["sell", BoardGeometry.LABELS[weakest]],
			"Replace the weakest body with a better commitment piece"
		):
			return false
	return _act(["buy", str(best)], "Buy " + str(offer["name"]) + " for " + _tribe)


func _buy_spell() -> bool:
	var state: Dictionary = _state()
	var spells: Array = state["shop_spells"]
	var shop: Array = state["shop"]
	for index: int in spells.size():
		var card: Dictionary = spells[index]
		if CoreUtil.to_int(card["cost"]) > CoreUtil.to_int(state["gold"]) - _reserve(state):
			continue
		var id: String = str(card["def_id"])
		if _tribe == "Fairies" and id in ["spore_cloud", "boundary_stone"]:
			return _act(
				["buy", str(shop.size() + index)],
				"Buy Rings: missing rainbow slots first, then the carry"
			)
		if id in ["a_leg_up", "rainy_day"] and _round <= 2:
			return _act(["buy", str(shop.size() + index)], "Use the ordinary opening economy spell")
		if id == "harvest_supper" and _tribe == "Birds" and _round in [6, 8, 10]:
			return _act(["buy", str(shop.size() + index)], "Buy the Birds' scheduled Supper")
		if id == "pinch_of_dust" and _tribe == "Fairies" and _thank_slot(state) >= 0:
			return _act(["buy", str(shop.size() + index)], "Thank a banked Shy unit")
	return false


func _play_hand() -> void:
	for _step: int in 18:
		_choose()
		var state: Dictionary = _state()
		var hand: Array = state["hand"]
		if not hand.is_empty():
			var board: Array = state["board"]
			var slot: int = board.find(null)
			var card: Dictionary = hand[0]
			if slot < 0:
				slot = _weakest_slot(state)
				if slot < 0:
					break
				var weakest_card: Dictionary = board[slot]
				if _value(card) <= _value(weakest_card):
					break
				if not _act(
					["sell", BoardGeometry.LABELS[slot]],
					"Make room to replay a homecoming or field a stronger hand unit"
				):
					break
			if not _act(
				["play", "@" + str(card["iid"]), BoardGeometry.LABELS[slot]],
				"Play the hand unit through the command interface"
			):
				break
			continue
		if not _play_item(state):
			break


func _play_item(state: Dictionary) -> bool:
	var items: Array = state["hand_items"]
	for item: Dictionary in items:
		var id: String = str(item["def_id"])
		var handle: String = "@" + str(item["iid"])
		var aim: String = str(item["aim"])
		if aim == "none":
			return _act(["play", handle], "Cash or cast an unaimed hand item")
		var slot: int = -1
		if id in ["spore_cloud", "boundary_stone"]:
			slot = _ring_slot(state)
		elif id == "golden_egg":
			slot = _biggest_slot(state, "Birds", true)
		elif id == "harvest_supper":
			slot = _biggest_slot(state, "Birds")
		elif aim == "unit":
			slot = _thank_slot(state) if _tribe == "Fairies" else -1
			if slot < 0:
				slot = _biggest_slot(state, _tribe)
		if slot >= 0:
			var legal: Array[Dictionary] = LegalActions.of(state)
			for action: Dictionary in legal:
				var args: Array = action.get("args", [])
				if (
					str(action.get("action", "")) == "play_item"
					and args.size() == 2
					and CoreUtil.to_int(args[0]) == items.find(item)
					and CoreUtil.to_int(args[1]) == slot
				):
					return _act(
						["play", handle, BoardGeometry.LABELS[slot]],
						"Aim the hand spell at its intended legal target"
					)
	return false


func _ring_total(state: Dictionary) -> int:
	var total: int = 0
	for effects: Array in state["slot_effects"]:
		for effect: Dictionary in effects:
			if str(effect.get("name", "")) == "Ring":
				total += CoreUtil.to_int(effect.get("count", 0))
	return total


func _ring_slot(state: Dictionary) -> int:
	var slots: Array = state["slot_effects"]
	for index: int in slots.size():
		var effects: Array = slots[index]
		if not BoardUpkeep.has_ring(effects):
			return index
	return 4


func _thank_slot(state: Dictionary) -> int:
	var board: Array = state["board"]
	var silky: bool = false
	for value: Variant in board:
		if value != null:
			var card: Dictionary = value
			silky = silky or str(card["def_id"]) == "silky"
	for slot: int in board.size():
		if board[slot] == null:
			continue
		var card: Dictionary = board[slot]
		var counters: Dictionary = card.get("counters", {})
		if (
			str(card["def_id"]) == "lob_lie_by_the_fire"
			and CoreUtil.to_int(counters.get("pass3_turns_stayed", 0)) >= 3
			and (silky or _round >= 11)
		):
			return slot
	return -1


func _biggest_slot(state: Dictionary, tribe: String, unegged: bool = false) -> int:
	var best: int = -1
	var most: int = -1
	var board: Array = state["board"]
	for slot: int in board.size():
		if board[slot] == null:
			continue
		var card: Dictionary = board[slot]
		var tribes: Array = card["tribes"]
		if not tribes.has(tribe) or CoreUtil.to_bool(card.get("shy", false)):
			continue
		if unegged and CoreUtil.to_bool(card.get("egged", false)):
			continue
		var size: int = CoreUtil.to_int(card["attack"]) + CoreUtil.to_int(card["health"])
		if size > most:
			best = slot
			most = size
	return best


func _weakest_slot(state: Dictionary) -> int:
	var board: Array = state["board"]
	var worst: int = -1
	var least: float = INF
	for slot: int in board.size():
		if board[slot] == null:
			continue
		var card: Dictionary = board[slot]
		var value: float = _value(card)
		if _tribe == "Birds" and FLIERS.has(str(card["def_id"])):
			value += 30.0
		if value < least:
			worst = slot
			least = value
	return worst


func _fly() -> void:
	if _tribe != "Birds" or _round < 3:
		return
	for _step: int in 3:
		var state: Dictionary = _state()
		var board: Array = state["board"]
		var away: Array = state["away"]
		var count: int = 0
		for value: Variant in board:
			count += 1 if value != null else 0
		if count <= 3:
			return
		var best: int = -1
		var most: int = -1
		for slot: int in board.size():
			if board[slot] == null:
				continue
			var card: Dictionary = board[slot]
			if (
				not FLIERS.has(str(card["def_id"]))
				or CoreUtil.to_int(card["played_round"]) >= _round
			):
				continue
			if str(card["def_id"]) == "old_tern" and away.size() < 2:
				continue
			var size: int = CoreUtil.to_int(card["attack"]) + CoreUtil.to_int(card["health"])
			if size > most:
				best = slot
				most = size
		if best < 0:
			return
		if not _act(
			["sell", BoardGeometry.LABELS[best]],
			"Fly a Bird that fought at home; keep at least three home bodies"
		):
			return


func _arrange() -> void:
	var state: Dictionary = _state()
	var board: Array = state["board"]
	var wanted: Array = []
	if _tribe == "Fairies":
		wanted = [
			["old_moth_annis", 0],
			["cradle_fetch", 1],
			["cluricaun", 2],
			["sally_spore", 3],
			["fairy_monarch", 5],
			["silky", 6]
		]
	else:
		wanted = [["mrs_stork", 6], ["mr_redbreast", 5], ["tom_tit", 4]]
	for preference: Array in wanted:
		state = _state()
		board = state["board"]
		var target: int = CoreUtil.to_int(preference[1])
		for slot: int in board.size():
			if slot != target and board[slot] != null:
				var card: Dictionary = board[slot]
				if str(card["def_id"]) == str(preference[0]):
					_act(
						["move", BoardGeometry.LABELS[slot], BoardGeometry.LABELS[target]],
						"Place the engine or holder in its planned row"
					)
					break
	state = _state()
	board = state["board"]
	if _tribe == "Fairies":
		var carry: int = _biggest_slot(state, "Fairies")
		if carry >= 0 and carry != 4:
			_act(
				["move", BoardGeometry.LABELS[carry], "B1"],
				"Put the biggest Fairy on the concentrated Ring"
			)
	else:
		var away: Array = state["away"]
		var biggest_nest: int = -1
		var most: int = -1
		for bird: Dictionary in away:
			if CoreUtil.to_int(bird["nest"]) < 0:
				continue
			var size: int = CoreUtil.to_int(bird["attack"]) + CoreUtil.to_int(bird["health"])
			if size > most:
				biggest_nest = CoreUtil.to_int(bird["nest"])
				most = size
		if biggest_nest >= 0:
			for slot: int in board.size():
				if board[slot] != null:
					var card: Dictionary = board[slot]
					if str(card["def_id"]) == "great_lump" and slot != biggest_nest:
						_act(
							[
								"move",
								BoardGeometry.LABELS[slot],
								BoardGeometry.LABELS[biggest_nest]
							],
							"Seat the Lump on the biggest away Bird's Nest"
						)
						break
