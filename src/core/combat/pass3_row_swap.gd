class_name Pass3RowSwap
extends RefCounted
## A hostile row swap cannot move either enemy onto a larger effective Ring bonus.


static func improves_ring(combat: Combat, unit: CombatUnit, destination: int) -> bool:
	if unit == null:
		return false
	var before: Vector2i = CombatRings.bonus(combat, unit)
	var previous: int = unit.slot
	unit.slot = destination
	var after: Vector2i = CombatRings.bonus(combat, unit)
	unit.slot = previous
	return after.x > before.x or after.y > before.y


static func configure(card: Dictionary, config: GameConfig) -> void:
	if str(card.get("id", "")) != "whirligig_beetle" or not config.get_bool("pass3_content"):
		return
	for golden: bool in [false, true]:
		var damage: int = 0
		for entry: Dictionary in card.get("mechanics", []):
			if str(entry.get("id", "")) == "row_swap":
				damage = CoreUtil.to_int(entry.get("damage", 0)) * (2 if golden else 1)
		card["golden_text" if golden else "text"] = (
			"Start of Combat: swap enemy rows without improving Rings. Moved enemies take %d damage."
			% damage
		)
	card["details"] = (
		"Swap F1 with B1, F2 with B2 and F3 with B3. "
		+ "Skip a pair if either enemy would gain Attack or Health from its destination Ring. "
		+ "F4 stays. Only units actually moved take damage."
	)
