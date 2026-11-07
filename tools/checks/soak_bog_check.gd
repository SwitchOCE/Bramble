class_name SoakBogCheck
extends RefCounted
## Directed bog mirrors, transformation, and refill checks. Natural shops may miss these together.


static func problems(library: UnitLibrary) -> PackedStringArray:
	var out: PackedStringArray = []
	for golden: bool in [false, true]:
		for fight_seed: int in range(53, 65):
			var ours: Array = _board(
				[
					[0, "madame_bufo"],
					[1, "prima_donna"],
					[4, "gideon"],
					[5, "his_highness"],
					[6, "peat_king"]
				],
				golden
			)
			ours[5]["kisses"] = 2
			var theirs: Array = _board(
				[
					[0, "madame_bufo"],
					[1, "little_dollop"],
					[2, "bridge_toad"],
					[4, "gideon"],
					[5, "spitfire_sal"],
					[6, "peat_king"]
				],
				golden
			)
			theirs[1]["held"] = [{"def_id": "field_vole", "golden": false}]
			var rng := RandomNumberGenerator.new()
			rng.seed = fight_seed
			var result: Dictionary = Combat.create(library, GameConfig.full_game(), rng).run(
				[ours, theirs], [6, 6], [0, 1], 0
			)
			var kings: Dictionary = {}
			var kisses: Dictionary = {}
			var transforms: Dictionary = {}
			for event: Dictionary in result["events"]:
				if event["type"] == "kiss":
					var uid: int = CoreUtil.to_int(event["target"])
					kisses[uid] = CoreUtil.to_int(kisses.get(uid, 0)) + 1
				if event["type"] == "transform":
					var uid: int = CoreUtil.to_int(event["target"])
					transforms[uid] = CoreUtil.to_int(transforms.get(uid, 0)) + 1
				if event["type"] == "summon":
					var view: Dictionary = event["unit"]
					if view["def_id"] == "peatling":
						var source: int = CoreUtil.to_int(event["source"])
						kings[source] = CoreUtil.to_int(kings.get(source, 0)) + 1
			if result["reason"] == Combat.REASON_TRIGGER_LIMIT:
				out.append("bog mirror hit trigger limit, seed %d golden=%s" % [fight_seed, golden])
			for count: int in kisses.values():
				if count > 1:
					out.append("bog mirror granted multiple kisses in one fight")
			for count: int in transforms.values():
				if count > 1:
					out.append("bog mirror transformed the same frog twice")
			for count: int in kings.values():
				if count > 2:
					out.append("bog mirror raised more than two Peatlings per King")
	return out


static func _board(entries: Array, golden: bool) -> Array:
	var board: Array = []
	board.resize(BoardGeometry.SLOTS)
	for pair: Array in entries:
		board[CoreUtil.to_int(pair[0])] = {"def_id": str(pair[1]), "golden": golden}
	return board
