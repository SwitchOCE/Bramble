extends RefCounted
## Rainbow's cash-out rule, shared by the sale and its preview.


static func sale_bonus(params: Dictionary, painted: int) -> int:
	var per: int = CoreUtil.to_int(params.get("gold", 0))
	if per <= 0:
		return 0
	@warning_ignore("integer_division")
	var pays: int = (painted / maxi(1, CoreUtil.to_int(params.get("gold_every", 1)))) * per
	if painted >= BoardGeometry.SLOTS:
		pays += CoreUtil.to_int(params.get("finish", 0))
	return pays
