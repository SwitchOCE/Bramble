class_name BotBog
extends RefCounted
## Pass 3 Bog's visible engine: preserve investments, then match food and neighbours to the scout.


static func active(player: PlayerState) -> bool:
	return player != null and player.pass3_bog


static func has_units(player: PlayerState) -> bool:
	if not active(player):
		return false
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("pass3_bog"):
			return true
	return false


static func has(unit: RecruitUnit, ability: String) -> bool:
	if unit == null:
		return false
	for entry: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = entry
		if (
			compiled.id == "pass3_bog"
			and str(compiled.params_for(unit.golden).get("ability", "")) == ability
		):
			return true
	return false


static func court(value: BotEval) -> bool:
	return str(value.strategy.get("id", "")) == "bog_tongues"


static func rate(value: BotEval, key: String, fallback: float) -> float:
	if value.recruit_rules == null:
		return fallback
	return Pass3Rates.number(value.recruit_rules.config, key)


static func _share(value: BotEval, unit: RecruitUnit, key: String, fallback: float) -> float:
	return rate(value, "bog_" + ("golden_" if unit.golden else "") + key, fallback)


static func _body(unit: RecruitUnit) -> int:
	return unit.base_attack_now() + unit.perm_attack + unit.base_health_now() + unit.perm_health


static func _bogs(player: PlayerState) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_tribe("Bog folk"):
			out.append(unit)
	out.sort_custom(func(a: RecruitUnit, b: RecruitUnit) -> bool: return _body(a) > _body(b))
	return out


static func _take(attack: int) -> float:
	return minf(maxi(0, attack - 1), ceilf(attack * 0.25))


static func _toll(player: PlayerState) -> float:
	if player.bog_toll > 0:
		return player.bog_toll
	var total: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		total += _take(BotLanes._stat(BotLanes._enemy(player, slot), "attack"))
	return total if not player.scout.is_empty() else maxf(2.0, player.round_number * 2.0)


## Values future text separately from the permanent body the ordinary evaluator already counts.
static func text_value(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	if not active(player) or not unit.has_mechanic_id("pass3_bog"):
		return -1.0
	var bogs: Array[RecruitUnit] = _bogs(player)
	var biggest: float = float(_body(bogs[0])) if not bogs.is_empty() else 6.0
	var attack: int = 0
	for slot: int in BoardGeometry.SLOTS:
		attack = maxi(attack, BotLanes._stat(BotLanes._enemy(player, slot), "attack"))
	var toll: float = _toll(player)
	var total: float = 0.0
	if has(unit, "soak"):
		var patches: int = (
			3 if CoreUtil.to_bool(BotLanes._params(unit, "mire").get("spread", false)) else 1
		)
		var drink: float = maxf(_take(attack), toll / maxf(1.0, bogs.size()))
		total += (
			drink * _share(value, unit, "soak_keep", 4.0 if unit.golden else 2.0) * 2.0 * patches
		)
	if has(unit, "tiddy"):
		total += maxf(
			8.0, toll * _share(value, unit, "tiddy_share", 1.0 if unit.golden else 0.5) * 4.0
		)
	if has(unit, "nan"):
		total += toll * _share(value, unit, "nan_share", 1.0 if unit.golden else 0.5) * 3.0
	if has(unit, "frog"):
		var wait: int = _kiss_wait(player, value)
		var multiplier: float = _share(value, unit, "frog_multiplier", 3.0 if unit.golden else 2.0)
		var best_neighbour: float = biggest
		for other: RecruitUnit in player.board:
			if other != null and other != unit:
				best_neighbour = maxf(best_neighbour, _body(other))
		total += maxf(10.0, best_neighbour * (multiplier - 1.0) / wait)
	if has(unit, "chorus"):
		var recipients: int = 0
		for bog: RecruitUnit in bogs:
			if bog != unit and not has(bog, "soak"):
				total += 8.0 + _body(bog) * 0.2 + toll
				recipients += 1
				if recipients == 2:
					break
	if has(unit, "hopkin"):
		var front: int = 0
		for slot: int in BoardGeometry.FRONT:
			if player.board[slot] != null:
				front = maxi(front, player.board[slot].attack)
		total += (
			6.0
			+ (
				maxf(
					0.0,
					(
						front * rate(value, "bog_hopkin_share", 0.25) * unit.golden_factor()
						- unit.attack
					)
				)
				* 2.0
			)
		)
	if has(unit, "ranocchio"):
		total += (
			6.0 + attack * _share(value, unit, "ranocchio_share", 1.0 if unit.golden else 0.5) * 3.0
		)
	if has(unit, "sal"):
		total += toll * unit.golden_factor() * 0.7
	if has(unit, "king"):
		var best: int = 0
		for slot: int in BoardGeometry.SLOTS:
			var enemy: Dictionary = BotLanes._enemy(player, slot)
			best = maxi(best, BotLanes._stat(enemy, "attack") + BotLanes._stat(enemy, "health"))
		total += maxf(14.0, best * 0.6) * unit.golden_factor()
	if has(unit, "bufo"):
		total += 5.0 + attack * 0.5
	if has(unit, "gideon"):
		total += 6.0 + unit.attack * 0.5
	if has(unit, "jenny") or has(unit, "lantern"):
		total += 8.0 + attack * 0.3
	if has(unit, "cutter") or has(unit, "pretender"):
		total += 5.0 * unit.golden_factor()
	return total


static func _kiss_wait(player: PlayerState, value: BotEval) -> int:
	var period: int = maxi(1, int(rate(value, "bog_kiss_period", 3)))
	return period - player.bog_kisses % period


## Only the court holds the first frog, and releases it as soon as the written payoff exists.
static func hold_frog(player: PlayerState, unit: RecruitUnit, value: BotEval) -> bool:
	if not active(player) or not court(value) or not has(unit, "frog") or player.round_number >= 10:
		return false
	var sizes: Array[int] = []
	for other: RecruitUnit in player.board:
		if other != null:
			if has(other, "frog"):
				return false
			sizes.append(_body(other))
	if sizes.is_empty():
		return false
	sizes.sort()
	var middle: int = floori(sizes.size() * 0.5)
	var median: float = sizes[middle]
	if sizes.size() % 2 == 0:
		median = (sizes[middle - 1] + median) * 0.5
	return sizes.back() < 2.0 * median


static func keep_engine(player: PlayerState, unit: RecruitUnit, value: BotEval) -> bool:
	if not active(player) or not unit.has_tribe("Bog folk"):
		return false
	var bogs: Array[RecruitUnit] = _bogs(player)
	if bogs.size() < 2:
		return false
	var engine: bool = has(unit, "tiddy") or has(unit, "frog")
	engine = engine or (not court(value) and (has(unit, "nan") or has(unit, "chorus")))
	if has(unit, "chorus"):
		engine = false
		for other: RecruitUnit in bogs:
			engine = engine or (other != unit and not has(other, "soak"))
	if engine:
		for other: RecruitUnit in bogs:
			if other != unit and other.def_id() == unit.def_id():
				if (
					other.golden_factor() > unit.golden_factor()
					or (other.golden == unit.golden and other.iid < unit.iid)
				):
					return false
		return true
	# Keep the grown recipient through its next Toll or kiss, instead of pricing only its tier.
	if unit != bogs[0] or unit.perm_attack + unit.perm_health <= 0:
		return false
	for other: RecruitUnit in bogs:
		if has(other, "tiddy") or has(other, "frog"):
			return true
	return false


## Lantern binds an identity first; Jenny then pulls another enemy before ordinary patches.
static func forecast(player: PlayerState, layout: Array[int]) -> Dictionary:
	var enemies: Array[Dictionary] = []
	var identity: int = 0
	for slot: int in BoardGeometry.SLOTS:
		var enemy: Dictionary = BotLanes._enemy(player, slot).duplicate(true)
		identity = _tag(enemy, slot, identity, false)
		enemies.append(enemy)
	var makers: Array[int] = [-1, -1, -1, -1, -1, -1, -1]
	var lured: Array[int] = []
	var pending: Array[Dictionary] = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if not has(unit, "lantern"):
			continue
		var chosen: Array[int] = []
		for _target: int in unit.golden_factor():
			var target: Dictionary = _biggest(
				enemies, BoardGeometry.FRONT + BoardGeometry.BACK, chosen
			)
			if target.is_empty():
				continue
			chosen.append(CoreUtil.to_int(target["bog_identity"]))
			lured.append(CoreUtil.to_int(target["bog_identity"]))
			var destination: int = CoreUtil.to_int(target["bog_slot"])
			if CoreUtil.to_bool(target["bog_hidden"]):
				pending.append({"enemy": target, "maker": slot, "ability": "lantern"})
			elif makers[destination] < 0:
				makers[destination] = slot
	for slot: int in BoardGeometry.SLOTS:
		if not has(BotLanes._at(player, layout, slot), "jenny"):
			continue
		var target: Dictionary = _biggest(enemies, BoardGeometry.row_of(slot), lured)
		if target.is_empty():
			continue
		if CoreUtil.to_bool(target["bog_hidden"]):
			pending.append({"enemy": target, "maker": slot, "ability": "jenny"})
			continue
		var origin: int = CoreUtil.to_int(target["bog_slot"])
		if origin != slot:
			var keep: Dictionary = enemies[slot]
			enemies[slot] = enemies[origin]
			enemies[origin] = keep
			_relocate(enemies[slot], slot)
			_relocate(enemies[origin], origin)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if unit == null or (not unit.has_mechanic_id("mire") and not _lent(player, layout, slot)):
			continue
		var targets: Array[int] = [slot]
		if CoreUtil.to_bool(BotLanes._params(unit, "mire").get("spread", false)):
			targets.append_array(BoardGeometry.adjacent(slot))
		for target: int in targets:
			if makers[target] < 0:
				makers[target] = slot
	return {"enemies": enemies, "patches": makers, "pending": pending}


static func _biggest(enemies: Array[Dictionary], slots: Array[int], skip: Array[int]) -> Dictionary:
	var best: Dictionary = {}
	var most: int = -1
	for enemy: Dictionary in _flatten(enemies):
		var size: int = BotLanes._stat(enemy, "attack") + BotLanes._stat(enemy, "health")
		if (
			slots.has(CoreUtil.to_int(enemy["bog_slot"]))
			and not skip.has(CoreUtil.to_int(enemy["bog_identity"]))
			and size > most
		):
			best = enemy
			most = size
	return best


static func _tag(enemy: Dictionary, slot: int, identity: int, hidden: bool) -> int:
	if enemy.is_empty():
		return identity
	enemy["bog_identity"] = identity
	enemy["bog_slot"] = slot
	enemy["bog_hidden"] = hidden
	identity += 1
	var held: Array = enemy.get("held", [])
	for child: Dictionary in held:
		identity = _tag(child, slot, identity, true)
	return identity


static func _flatten(enemies: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for enemy: Dictionary in enemies:
		if not enemy.is_empty():
			out.append(enemy)
			var held: Array = enemy.get("held", [])
			out.append_array(_flatten(held))
	return out


static func _relocate(enemy: Dictionary, slot: int) -> void:
	if enemy.is_empty():
		return
	enemy["bog_slot"] = slot
	var held: Array = enemy.get("held", [])
	for child: Dictionary in held:
		_relocate(child, slot)


static func _lent(player: PlayerState, layout: Array[int], slot: int) -> bool:
	var unit: RecruitUnit = BotLanes._at(player, layout, slot)
	if unit == null or not unit.has_tribe("Bog folk"):
		return false
	for next: int in BoardGeometry.adjacent(slot):
		if has(BotLanes._at(player, layout, next), "chorus"):
			return true
	return false


static func flexible_row(unit: RecruitUnit) -> bool:
	return has(unit, "tiddy") or has(unit, "frog") or has(unit, "chorus") or has(unit, "lantern")


static func _soak_keep(player: PlayerState, value: BotEval, layout: Array[int], slot: int) -> float:
	var unit: RecruitUnit = BotLanes._at(player, layout, slot)
	var keep: float = (
		_share(value, unit, "soak_keep", 4.0 if unit.golden else 2.0) if has(unit, "soak") else 0.0
	)
	if unit.has_tribe("Bog folk"):
		for next: int in BoardGeometry.adjacent(slot):
			var lender: RecruitUnit = BotLanes._at(player, layout, next)
			if has(lender, "chorus"):
				keep = maxf(keep, _share(value, lender, "soak_keep", 4.0 if lender.golden else 2.0))
	return keep


## Additive to ordinary Hunter/row scoring; all Bog ownership uses the predicted post-pull board.
static func score(player: PlayerState, value: BotEval, layout: Array[int]) -> float:
	var predicted: Dictionary = forecast(player, layout)
	var enemies: Array[Dictionary] = predicted["enemies"]
	var patches: Array[int] = predicted["patches"]
	var bogs: Array[RecruitUnit] = _bogs(player)
	var biggest: float = maxf(1.0, float(_body(bogs[0])) if not bogs.is_empty() else 1.0)
	var carry_health: int = bogs[0].health if not bogs.is_empty() else 1
	var total: float = 0.0
	var frog_gifts: Dictionary = {}
	var chorus_gifts: Dictionary = {}
	for enemy_slot: int in BoardGeometry.SLOTS:
		if patches[enemy_slot] < 0 or player.scout.is_empty():
			continue
		var unit: RecruitUnit = BotLanes._at(player, layout, patches[enemy_slot])
		var enemy: Dictionary = enemies[enemy_slot]
		var attack: int = BotLanes._stat(enemy, "attack")
		var keep: float = _soak_keep(player, value, layout, patches[enemy_slot])
		var soak: bool = keep > 0.0
		if enemy.is_empty() or BotLanes._egg(enemy) or attack <= 0:
			total -= 16.0 if soak else 5.0
			continue
		total += 2.0 + attack * 0.35
		if soak:
			var take: float = _take(attack)
			var bites: float = clampf(float(unit.health) / maxf(1.0, attack - take), 1.0, 1.7)
			total += take * keep * 2.0 * bites
			total += 5.0 * _body(unit) / biggest
		if has(unit, "bufo"):
			total += attack * (1.6 if attack > 2 * carry_health else 0.15)
		if has(unit, "gideon"):
			total += 8.0 if attack - _take(attack) < unit.health else -4.0
	# A hidden identity can eventually emerge into its binding; it does not own its holder's patch.
	for binding: Dictionary in predicted["pending"]:
		var enemy: Dictionary = binding["enemy"]
		var attack: int = BotLanes._stat(enemy, "attack")
		var keep: float = _soak_keep(player, value, layout, CoreUtil.to_int(binding["maker"]))
		total += _take(attack) * keep
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if unit == null:
			continue
		var neighbours: Array[RecruitUnit] = []
		for next: int in BoardGeometry.adjacent(slot):
			var other: RecruitUnit = BotLanes._at(player, layout, next)
			if other != null and other.has_tribe("Bog folk"):
				neighbours.append(other)
		if has(unit, "tiddy") and not neighbours.is_empty():
			for other: RecruitUnit in neighbours:
				total += (12.0 + _toll(player)) * (0.5 + _body(other) / biggest) / neighbours.size()
			if court(value):
				total += 10.0 if neighbours.size() == 1 and BoardGeometry.is_row_end(slot) else -4.0
			elif neighbours.size() == 2:
				total += 20.0
		if has(unit, "frog"):
			for next: int in BoardGeometry.adjacent(slot):
				var other: RecruitUnit = BotLanes._at(player, layout, next)
				if other == null:
					continue
				var gift: float = (
					_body(other)
					* (_share(value, unit, "frog_multiplier", 3.0 if unit.golden else 2.0) - 1.0)
					* 0.6
					/ _kiss_wait(player, value)
				)
				frog_gifts[other.iid] = maxf(
					CoreUtil.to_float(frog_gifts.get(other.iid, 0.0)), gift
				)
		if has(unit, "chorus"):
			for other: RecruitUnit in neighbours:
				if not has(other, "soak"):
					chorus_gifts[other.iid] = 12.0 + _body(other) * 0.3
		if has(unit, "hopkin") and BoardGeometry.is_back(slot):
			var front: int = 0
			for next: int in BoardGeometry.in_front_of(slot):
				var other: RecruitUnit = BotLanes._at(player, layout, next)
				if other != null:
					front = maxi(front, other.attack)
			total += (
				maxf(
					0.0,
					(
						front * rate(value, "bog_hopkin_share", 0.25) * unit.golden_factor()
						- unit.attack
					)
				)
				* 2.0
			)
		if has(unit, "king"):
			for next: int in BoardGeometry.adjacent(slot):
				if layout[next] < 0:
					total += 8.0
	for gift: float in frog_gifts.values():
		total += gift
	for gift: float in chorus_gifts.values():
		total += gift
	return total


static func search_pins(player: PlayerState, layout: Array[int]) -> Array[int]:
	var out: Array[int] = []
	var bogs: Array[RecruitUnit] = _bogs(player)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if unit != null and (flexible_row(unit) or (not bogs.is_empty() and unit == bogs[0])):
			if not out.has(slot):
				out.append(slot)
		if has(unit, "tiddy") or has(unit, "frog") or has(unit, "chorus"):
			for next: int in BoardGeometry.adjacent(slot):
				var recipient: RecruitUnit = BotLanes._at(player, layout, next)
				if recipient != null and (has(unit, "frog") or recipient.has_tribe("Bog folk")):
					if not out.has(next):
						out.append(next)
		if has(unit, "hopkin") and BoardGeometry.is_back(slot):
			if not out.has(slot):
				out.append(slot)
	return out


## Make room only when a real early Sink is worth much more than the replaceable body.
## A fragile front will already open a slot naturally, so it never pays an extra sale here.
static func prepare_fight(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	if (
		not active(player)
		or not brain.level.reads_text
		or player.board_count() < BoardGeometry.SLOTS
		or player.scout.is_empty()
	):
		return
	var king: bool = false
	var layout: Array[int] = []
	var highest_attack: int = 0
	for slot: int in BoardGeometry.SLOTS:
		layout.append(slot)
		king = king or has(player.board[slot], "king")
		highest_attack = maxi(
			highest_attack, BotLanes._stat(BotLanes._enemy(player, slot), "attack")
		)
	if not king:
		return
	for slot: int in BoardGeometry.FRONT:
		if player.board[slot].health <= highest_attack:
			return
	var predicted: Dictionary = forecast(player, layout)
	var cheapest_sink: float = INF
	for slot: int in BoardGeometry.SLOTS:
		var owner: int = CoreUtil.to_int(predicted["patches"][slot])
		var enemy: Dictionary = predicted["enemies"][slot]
		if owner < 0 or enemy.is_empty() or BotLanes._egg(enemy):
			continue
		if player.board[owner].attack < BotLanes._stat(enemy, "health"):
			return
		cheapest_sink = minf(
			cheapest_sink, BotLanes._stat(enemy, "attack") + BotLanes._stat(enemy, "health")
		)
	var weakest: int = brain._weakest_slot()
	if weakest < 0 or cheapest_sink == INF:
		return
	if (
		cheapest_sink
		<= 2.0 * brain.value.keep_value(player.board[weakest]) + brain.level.replace_margin
	):
		return
	if brain._rules.sell(player, weakest) == "":
		brain._replacements += 1
		brain._settle()


static func play_slot(player: PlayerState, unit: RecruitUnit, value: BotEval) -> int:
	if not active(player) or not value.level.reads_text or not unit.has_mechanic_id("pass3_bog"):
		return -1
	var best: int = -1
	var most: float = -INF
	for slot: int in BoardGeometry.SLOTS:
		if not BotEggs.playable(player, unit, value, slot):
			continue
		# A temporary recruit snapshot prices placement; the eventual action still uses Rules.play.
		player.board[slot] = unit
		var layout: Array[int] = []
		for at: int in BoardGeometry.SLOTS:
			layout.append(at if player.board[at] != null else -1)
		var candidate: float = BotLanes.score(player, value, layout)
		player.board[slot] = null
		if candidate > most:
			most = candidate
			best = slot
	return best
