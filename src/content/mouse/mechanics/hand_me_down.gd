extends Mechanic
## Hand-me-down (rulebook 11.7.12-11.7.13), a keyword: when this dies, the nearest friendly
## Mouse gains its own Attack this fight (MouseRules.hand_me_down). A death effect (9.7.2 step
## 2), so the Dirge-singer resolves it twice and a War-drummer sets it off without a death; set
## off on a living unit, it still passes to the nearest other Mouse.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if unit != null:
		MouseRules.hand_me_down(combat, unit)
