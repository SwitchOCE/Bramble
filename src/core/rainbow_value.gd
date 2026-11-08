extends RefCounted
## Rainbow's cash-out rule, shared by the sale and its preview.


static func sale_bonus(params: Dictionary, painted: int) -> int:
	var per: int = CoreUtil.to_int(params.get("gold", 0))
	if per <= 0:
		return 0
	var pays: int = painted * per
	if painted >= BoardGeometry.SLOTS:
		pays += CoreUtil.to_int(params.get("finish", 0))
	return pays
