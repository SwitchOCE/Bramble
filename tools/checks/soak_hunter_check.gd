class_name SoakHunterCheck
extends RefCounted
## Packs and back-row pouncers against both quarries and Mire, beyond natural shop coverage.


static func problems(library: UnitLibrary) -> PackedStringArray:
	var out: PackedStringArray = []
	for golden: bool in [false, true]:
		for fight_seed: int in range(53, 65):
			var ours: Array = _board(
				[
					"sable",
					"brother_wolf",
					"grizel",
					"mistress_russet",
					"lodger",
					"old_brock",
					"mountain_glutton"
				],
				golden
			)
			var theirs: Array = _board(
				[
					"madame_bufo",
					"prima_donna",
					"bridge_toad",
					"young_pretender",
					"gideon",
					"natterjack_chorus",
					"peat_king"
				],
				golden
			)
			var rng := RandomNumberGenerator.new()
			rng.seed = fight_seed
			var combat := Combat.create(library, GameConfig.full_game(), rng)
			var result: Dictionary = combat.run([ours, theirs], [6, 6], [0, 1], 0)
			if result["reason"] in [Combat.REASON_TRIGGER_LIMIT, Combat.REASON_ATTACK_LIMIT]:
				out.append(
					(
						"Hunter/Mire directed fight hit a limit, seed %d golden=%s"
						% [fight_seed, golden]
					)
				)
			var counts: Dictionary = {}
			var takes: Array[int] = [0, 0]
			for event: Dictionary in result["events"]:
				if event["type"] == "immediate_attack" and event["kind"] == "pounce":
					var uid: int = CoreUtil.to_int(event["attacker"])
					counts[uid] = CoreUtil.to_int(counts.get(uid, 0)) + 1
				if event["type"] == "take":
					takes[CoreUtil.to_int(event["side"])] += 1
			for count: int in counts.values():
				if count > combat.cycles[0] + 1:
					out.append("a Hunter pounced more than once per own cycle")
			if takes != combat.takes:
				out.append("Hunter Take result disagrees with its events")
	return out


static func _board(ids: Array, golden: bool) -> Array:
	var board: Array = []
	for id: String in ids:
		board.append({"def_id": id, "golden": golden})
	return board
