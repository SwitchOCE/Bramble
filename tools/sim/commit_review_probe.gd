extends "res://tools/sim/commit_probe.gd"
## Measurement overlay: retain the real commitment probe, with purchase/flight/burn evidence.
## Gameplay is supplied by each frozen variant; this script changes no rules or bot choices.


func _note(type: String, fields: Dictionary, pid: int) -> void:
	super._note(type, fields, pid)
	if type not in ["buy", "burn", "fly_south", "home", "play", "sell"]:
		return
	if _rules_round == null:
		return
	var details: Dictionary = fields.duplicate(true)
	if type == "fly_south":
		details.merge(_flight_body(pid))
	print(
		(
			"commit_aux: %s"
			% (
				JSON
				. stringify(
					{
						"seed": _rules_round._seed,
						"player": pid,
						"round": _rules_round._round,
						"type": type,
						"fields": details,
						"source": _last_source.get(pid, ""),
					}
				)
			)
		)
	)


func _flight_body(pid: int) -> Dictionary:
	var player: PlayerState = _rules_round._players[pid]
	if player.away.is_empty():
		return {"body_observed": false}
	var entry: Dictionary = player.away.back()
	var bird: RecruitUnit = entry["unit"]
	var egg: Dictionary = HeldUnits.egg_spec(bird)
	var egg_attack: int = CoreUtil.to_int(egg["attack"])
	var egg_health: int = CoreUtil.to_int(egg["health"])
	var native_home: bool = false
	for mechanic: Dictionary in bird.def.get("mechanics", []):
		if str(mechanic.get("trigger", "")) == "on_home":
			native_home = true
	return {
		"body_observed": true,
		"bird_attack": bird.attack,
		"bird_health": bird.health,
		"egg_attack": egg_attack,
		"egg_health": egg_health,
		"body_loss": maxi(0, bird.attack - egg_attack) + maxi(0, bird.health - egg_health),
		"free_body": bird.attack == egg_attack and bird.health == egg_health,
		"native_on_home": native_home,
	}
