extends RefCounted
## One calculation for the printed base plus spell growth, capped by the card.


static func ceiling(params: Dictionary, tier: int) -> int:
	var cap: Variant = params.get("most", 0)
	if str(cap) == "tier":
		return tier
	return tier + 2 if str(cap) == "tier_plus_2" else CoreUtil.to_int(cap)


static func amount(base: int, growth: int, cap: int) -> int:
	var total: int = base + growth
	return mini(total, cap) if cap > 0 else total
