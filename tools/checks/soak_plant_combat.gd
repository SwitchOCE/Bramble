class_name SoakPlantCombat
extends Combat
## A real session fight summons and kills a prototype between combat-start and recruit checks.
## Only selected by soak.gd plant=no_set_combat; events come from the ordinary combat engine.


static func create(
	unit_library: UnitLibrary, game_config: GameConfig, fight_rng: RandomNumberGenerator
) -> Combat:
	var combat := SoakPlantCombat.new()
	combat.library = unit_library
	combat.config = game_config
	combat.rng = fight_rng
	combat.effect_rng = RandomNumberGenerator.new()
	combat.effect_rng.seed = fight_rng.seed ^ 0x5EED
	return combat


func _start_of_combat() -> void:
	super._start_of_combat()
	for side: int in 2:
		var slot: int = BoardGeometry.summon_slot(_occupied(side), 0, true)
		if slot < 0:
			continue
		var prototype: CombatUnit = enter_from_spec({"def_id": "fox_cub"}, side, slot, null)
		deal_effect_damage(null, prototype, prototype.health + 100)
		_resolve_deaths(side)
		return
