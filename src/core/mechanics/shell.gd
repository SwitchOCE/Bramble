extends Mechanic
## Shell (N) (library entry 4): the first time this takes damage in a combat, that damage is
## capped at N; then the shell breaks. Combat applies the `shell` status to the largest of
## simultaneous hits (SPEC 4.2). N stays the same on golden.


func setup(unit: CombatUnit, params: Dictionary) -> void:
	unit.statuses["shell"] = {"n": CoreUtil.to_int(params.get("n", 0))}
