class_name FieldCombat
extends RefCounted
## Compose captured sides without reconstructing units or discarding hidden state.


static func pair_input(left: Dictionary, right: Dictionary, fight_seed: int) -> Dictionary:
	assert(CoreUtil.to_int(left["round"]) == CoreUtil.to_int(right["round"]))
	assert(left["layout"] == "blind" and right["layout"] == "blind")
	var original: Dictionary = left["config"]
	var config: Dictionary = original.duplicate(true)
	var right_config: Dictionary = right["config"]
	var other: Dictionary = right_config.duplicate(true)
	for key: String in ["bots", "human_bot"]:
		config.erase(key)
		other.erase(key)
	assert(FightCapture.canonical(config) == FightCapture.canonical(other), "mixed fight rules")
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var effects := RandomNumberGenerator.new()
	effects.seed = fight_seed ^ 0x5EED
	return {
		"version": 1,
		"boards": [left["board"], right["board"]],
		"slots": [left["slots"], right["slots"]],
		"hero_effects": [left["hero_effects"], right["hero_effects"]],
		"fight_rules": [left["fight_rules"], right["fight_rules"]],
		"tiers": [left["tier"], right["tier"]],
		"player_ids": [0, 1],
		"round": left["round"],
		"damage_cap": 0,
		"config": config,
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
		"effect_rng_seed": str(effects.seed),
		"effect_rng_state": str(effects.state),
	}


static func fight(
	left: Dictionary, right: Dictionary, fight_seed: int, library: UnitLibrary
) -> Dictionary:
	return FightCapture.replay(pair_input(left, right, fight_seed), library, false)
