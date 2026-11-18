extends SceneTree
## Crafted recruit-only oracle. Run -- out=/absolute/path/recruit_action_vectors.json.
## Each fixture step is mirrored by recruit.rs's oracle interpreter; no combat is invoked.


func _initialize() -> void:
	var cases: Array = _cases()
	var checkpoints: int = 0
	for case: Dictionary in cases:
		var content: GameContent = GameContent.load_folders(PackedStringArray())
		assert(content.errors.is_empty())
		var game: GameSession = content.new_session(42)
		var player: PlayerState = game.player(0)
		var checks: Array = [_check(game, "")]
		for step: Dictionary in case["steps"]:
			var result: String = _step(game, player, step)
			checks.append(_check(game, result))
		case["checks"] = checks
		checkpoints += checks.size()
	var text: String = JSON.stringify({"cases": cases})
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			var file := FileAccess.open(arg.substr(4), FileAccess.WRITE)
			assert(file != null)
			file.store_string(text)
			file.close()
	print("RECRUIT_ACTION_ORACLE=" + JSON.stringify({"cases": cases.size(), "checkpoints": checkpoints, "bytes": text.length(), "sha256": text.sha256_text()}))
	quit()


func _check(game: GameSession, result: String) -> Dictionary:
	return {"state": RecordState.state_hash(game), "legal": JSON.stringify(LegalActions.of(game, game.player(0))).sha256_text(), "result": result}


func _step(game: GameSession, player: PlayerState, step: Dictionary) -> String:
	match step["op"]:
		"set":
			for key: String in step["values"]:
				player.set(key, step["values"][key])
		"config":
			for key: String in step["values"]:
				game.config.set(key, step["values"][key])
		"make":
			var unit: Unit = game.new_unit(game.library.get_card(StringName(CoreUtil.to_text(step["card"]))), false)
			unit.bought_copies = CoreUtil.to_int(step.get("bought", 0))
			unit.pool_copies = CoreUtil.to_int(step.get("pool", 0))
			var slot: int = CoreUtil.to_int(step.get("slot", -1))
			if slot >= 0:
				player.place(unit, slot)
			else:
				player.hand.append(unit)
		"buff":
			var unit: Unit = player.find_uid(CoreUtil.to_int(step["uid"]))
			var ctx := RecruitContext.new(game, game.recruit, player)
			ctx.buff(unit, CoreUtil.to_int(step["attack"]), CoreUtil.to_int(step["health"]), CoreUtil.to_bool(step["permanent"]), null)
		"grant":
			var unit: Unit = player.find_uid(CoreUtil.to_int(step["uid"]))
			assert(unit.grant_effect(game.registry, StringName(CoreUtil.to_text(step["mechanic"])), CoreUtil.to_dict(step["raw"])))
		"counter":
			player.find_uid(CoreUtil.to_int(step["uid"])).counters[step["key"]] = CoreUtil.to_int(step["value"])
		"settle":
			game.recruit._settle(player)
		"discover":
			game.recruit.offer_discover(player, CoreUtil.to_int(step["min"]), CoreUtil.to_int(step["max"]))
		"end":
			game.recruit.end_turn(player)
		"act":
			return game.recruit.act(player, CoreUtil.to_dict(step["action"]))
	return ""


func _cases() -> Array:
	var triple: Array = []
	for slot: int in 3:
		triple.append({"op": "make", "card": "t1_plain", "slot": slot, "bought": slot, "pool": 1})
	for card: String in ["t1_guard", "t1_herald", "t1_seed", "t2_shield", "t2_mentor", "t2_fighter", "t2_merchant"]:
		triple.append({"op": "make", "card": card})
	triple.append_array([
		{"op": "buff", "uid": 1, "attack": 3, "health": -2, "permanent": true},
		{"op": "buff", "uid": 2, "attack": -1, "health": 4, "permanent": false},
		{"op": "buff", "uid": 3, "attack": 2, "health": 1, "permanent": true},
		{"op": "grant", "uid": 1, "mechanic": "taunt", "raw": {}},
		{"op": "grant", "uid": 2, "mechanic": "sell_bonus", "raw": {"amount": 2}},
		{"op": "grant", "uid": 3, "mechanic": "sell_bonus", "raw": {"amount": 3}},
		{"op": "counter", "uid": 1, "key": "core_proof", "value": 2},
		{"op": "counter", "uid": 2, "key": "core_proof", "value": 3},
		{"op": "settle"},
		{"op": "act", "action": {"type": "sell", "slot": 0}},
	])
	return [
		{"name": "full_hand_triple_grants_buffs", "steps": triple},
		{"name": "queued_discovers_and_end_resolution", "steps": [
			{"op": "make", "card": "sp_forage"},
			{"op": "act", "action": {"type": "play", "hand": 0, "slot": -1}},
			{"op": "act", "action": {"type": "freeze"}},
			{"op": "act", "action": {"type": "pick", "index": 9}},
			{"op": "act", "action": {"type": "pick", "index": 1}},
			{"op": "discover", "min": 2, "max": 3},
			{"op": "discover", "min": 4, "max": 4},
			{"op": "end"},
			{"op": "act", "action": {"type": "pick", "index": 0}},
		]},
		{"name": "spell_target_validation", "steps": [
			{"op": "make", "card": "sp_sharpen"},
			{"op": "act", "action": {"type": "play", "hand": 0, "slot": -1}},
			{"op": "make", "card": "t1_plain", "slot": 3},
			{"op": "act", "action": {"type": "play", "hand": 0, "slot": -1, "target": 999}},
			{"op": "act", "action": {"type": "play", "hand": 0, "slot": -1, "target": 2}},
			{"op": "act", "action": {"type": "play", "hand": 0, "slot": 0}},
		]},
		{"name": "economy_boundaries", "steps": [
			{"op": "set", "values": {"refreshes_paid": 9, "gold": 1}},
			{"op": "act", "action": {"type": "refresh"}},
			{"op": "act", "action": {"type": "refresh"}},
			{"op": "set", "values": {"gold": 2}},
			{"op": "act", "action": {"type": "refresh"}},
			{"op": "set", "values": {"freezes_used": 4, "frozen": false}},
			{"op": "act", "action": {"type": "freeze"}},
			{"op": "act", "action": {"type": "freeze"}},
			{"op": "set", "values": {"tier": 1, "turns_waited": 3, "gold": 1}},
			{"op": "act", "action": {"type": "upgrade"}},
			{"op": "set", "values": {"gold": 2}},
			{"op": "act", "action": {"type": "upgrade"}},
			{"op": "set", "values": {"tier": 6}},
			{"op": "act", "action": {"type": "upgrade"}},
			{"op": "set", "values": {"refreshes_paid": 0, "gold": 0}},
			{"op": "config", "values": {"refresh_base_cost": 0}},
			{"op": "act", "action": {"type": "refresh"}},
		]},
	]
