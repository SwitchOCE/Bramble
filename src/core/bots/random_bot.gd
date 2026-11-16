class_name RandomBot
extends Bot
## Random legal play, for the soak: picks an action type at random, then an action of that
## type. Ends its turn about one time in eight, so turns stay short but varied.

const END_CHANCE: int = 8


func choose(session: GameSession, player: PlayerState) -> Dictionary:
	var legal: Array[Dictionary] = session.legal_actions(player.id)
	var by_type: Dictionary = {}
	var types: Array[String] = []
	for action: Dictionary in legal:
		var kind: String = CoreUtil.to_text(action["type"])
		if kind == "end_turn":
			continue
		if not by_type.has(kind):
			by_type[kind] = [] as Array[Dictionary]
			types.append(kind)
		var list: Array[Dictionary] = by_type[kind]
		list.append(action)
	var must_pick: bool = by_type.has("pick")
	if types.is_empty() or (not must_pick and rng.index(END_CHANCE) == 0):
		return {"type": "end_turn"}
	var options: Array[Dictionary] = by_type[types[rng.index(types.size())]]
	return options[rng.index(options.size())]
