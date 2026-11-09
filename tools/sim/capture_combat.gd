class_name CaptureCombat
extends Combat
## Observe the real state after Start of Combat effects, without changing events or RNG.

var after_start: Array = []


static func instrument(
	unit_library: UnitLibrary, game_config: GameConfig, fight_rng: RandomNumberGenerator
) -> Combat:
	var combat := CaptureCombat.new()
	combat.library = unit_library
	combat.config = game_config
	combat.rng = fight_rng
	combat.effect_rng = RandomNumberGenerator.new()
	combat.effect_rng.seed = fight_rng.seed ^ 0x5EED
	return combat


func _start_of_combat() -> void:
	super._start_of_combat()
	after_start = [_board_views(0), _board_views(1)]
