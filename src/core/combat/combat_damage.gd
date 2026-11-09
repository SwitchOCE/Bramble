class_name CombatDamage
extends RefCounted
## Damage batching, prevention and attack splash.


static func apply(combat: Combat, hits: Array[Hit]) -> void:
	var live: Array[Hit] = []
	for hit: Hit in hits:
		if hit.raw <= 0:
			continue
		hit.amount = hit.raw
		if hit.kind == Hit.ATTACK and hit.source.has_status("warned"):
			hit.amount = ceili(hit.amount / 2.0)
			hit.modifiers.append("whistle")
		for index: int in hit.target.scripts.size():
			hit.amount = hit.target.scripts[index].modify_damage_taken(
				hit.target, hit.target.params[index], hit
			)
		Pass3BirdCombat.reduce_hit(combat, hit)
		if hit.amount <= 0:
			continue
		live.append(hit)
	for hit: Hit in live:
		if hit.target.has_status("shield"):
			hit.amount = 0
			hit.modifiers.append("shield")
			combat.set_status(hit.target, "shield", false, null)
	var shell_hits: Dictionary = {}
	for hit: Hit in live:
		if hit.amount <= 0 or not hit.target.has_status("shell"):
			continue
		var current: Hit = shell_hits.get(hit.target.uid)
		if current == null or current.amount < hit.amount:
			shell_hits[hit.target.uid] = hit
	for key: Variant in shell_hits:
		var hit: Hit = shell_hits[key]
		var shell: Dictionary = hit.target.statuses["shell"]
		hit.amount = mini(hit.amount, CoreUtil.to_int(shell.get("n", 0)))
		hit.modifiers.append("shell")
	combat._landing += 1
	for hit: Hit in live:
		var breaker: Hit = shell_hits.get(hit.target.uid)
		land(combat, hit, breaker == hit)
	combat._landing -= 1
	while combat._landing == 0 and not combat._pending_hits.is_empty() and not combat._halted:
		var waiting: Array[Hit] = [combat._pending_hits.pop_front()]
		apply(combat, waiting)


static func land(combat: Combat, hit: Hit, breaks_shell: bool) -> void:
	var target: CombatUnit = hit.target
	var before: int = target.health
	target.take_damage(hit.amount)
	if before > 0 and target.is_dead():
		CombatMoves.credit_lethal(
			combat,
			target,
			before,
			hit.blow_side if hit.kind == Hit.ATTACK else hit.owner_side,
			-1 if hit.source == null else hit.source.uid,
			hit.kind
		)
		if hit.source != null:
			target.killed_by = hit.source.uid
	if combat.log_events:
		(
			combat
			. emit_event(
				"damage",
				{
					"source": CombatMoves.uid_or_null(hit.source),
					"target": target.uid,
					"amount": hit.amount,
					"raw": hit.raw,
					"kind": hit.kind,
					"strike": hit.strike,
					"modifiers": hit.modifiers.duplicate(),
					"health_after": target.health,
				}
			)
		)
	if breaks_shell:
		combat.set_status(target, "shell", false, null)
	if hit.amount <= 0 and hit.modifiers.has("shield"):
		return
	if hit.source != null:
		for index: int in hit.source.scripts.size():
			hit.source.scripts[index].on_damage_dealt(
				combat, hit.source, hit.source.params[index], hit
			)
	for index: int in target.scripts.size():
		target.scripts[index].on_damage_taken(combat, target, target.params[index], hit)
	CombatHunt.damage_dealt(combat, hit)


static func cleave(combat: Combat, hits: Array[Hit]) -> void:
	var original: Array[Hit] = hits.duplicate()
	for hit: Hit in original:
		if not hit.source.has_mechanic("cleave"):
			continue
		for slot: int in BoardGeometry.adjacent(hit.target.slot):
			var beside: CombatUnit = combat.unit_at(hit.target.side, slot)
			if beside != null and not beside.is_dead():
				var splash: Hit = Hit.make(hit.source, beside, hit.raw, Hit.ATTACK, hit.strike)
				splash.modifiers.append("cleave")
				hits.append(splash)
