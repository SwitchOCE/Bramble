extends Mechanic


func setup(unit: CombatUnit, _params: Dictionary) -> void:
	unit.statuses["shield"] = {}
