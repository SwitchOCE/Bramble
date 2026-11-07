extends RefCounted
## One calculation for the printed base plus spell growth, capped by the card.


static func amount(base: int, growth: int, ceiling: int) -> int:
	var total: int = base + growth
	return mini(total, ceiling) if ceiling > 0 else total
