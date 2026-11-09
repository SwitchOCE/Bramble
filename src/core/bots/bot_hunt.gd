class_name BotHunt
extends RefCounted
## Native Hunter payoffs read the prey and the real board; all actions remain RecruitRules actions.


static func factor(unit: RecruitUnit, ability: String) -> int:
	var best: int = 0
	if unit == null:
		return best
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		var params: Dictionary = compiled.params_for(unit.golden)
		if compiled.id == "pass3_hunter" and str(params.get("ability", "")) == ability:
			best = maxi(best, CoreUtil.to_int(params.get("factor", 1)))
	return best


static func has(unit: RecruitUnit, ability: String) -> bool:
	return factor(unit, ability) > 0


static func native(unit: RecruitUnit) -> bool:
	return unit != null and unit.has_mechanic_id("pass3_hunter")


static func _power(unit: RecruitUnit) -> int:
	var best: int = 0
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id == "pass3_hunter":
			best = maxi(best, CoreUtil.to_int(compiled.params_for(unit.golden).get("factor", 1)))
	return best


static func active(player: PlayerState) -> bool:
	if player != null:
		for unit: RecruitUnit in player.board:
			if native(unit):
				return true
	return false


static func rate(value: BotEval, key: String, fallback: float) -> float:
	if value.recruit_rules == null:
		return fallback
	return Pass3Rates.number(value.recruit_rules.config, "hunters_" + key)


static func _rate_for(
	value: BotEval, unit: RecruitUnit, ability: String, key: String, fallback: float
) -> float:
	var prefix: String = "golden_" if factor(unit, ability) > 1 else ""
	return rate(value, prefix + key, fallback)


static func _share(value: BotEval, unit: RecruitUnit, ability: String) -> float:
	var result: float = rate(value, ability + "_share", 2.0 / 3.0)
	if factor(unit, ability) > 1:
		result *= rate(value, "golden_take_multiplier", 2.0)
	return result


static func _body(unit: RecruitUnit) -> int:
	return unit.base_attack_now() + unit.perm_attack + unit.base_health_now() + unit.perm_health


static func _taker(unit: RecruitUnit) -> bool:
	return has(unit, "nip") or has(unit, "sable") or has(unit, "lutra") or has(unit, "russet")


static func _counts(player: PlayerState) -> Vector3i:
	var out := Vector3i.ZERO
	for unit: RecruitUnit in player.board:
		if unit != null:
			out.x += 1 if _taker(unit) else 0
			out.y += 1 if unit.has_mechanic_id("pack") else 0
			out.z += 1 if unit.has_tribe("Hunters") else 0
	return out


static func _prey_size(player: PlayerState) -> float:
	var total: float = 0.0
	var count: int = 0
	for slot: int in BoardGeometry.SLOTS:
		var enemy: Dictionary = BotLanes._enemy(player, slot)
		if not enemy.is_empty() and not BotLanes._egg(enemy):
			total += BotLanes._stat(enemy, "attack") + BotLanes._stat(enemy, "health")
			count += 1
	return total / count if count > 0 else maxf(4.0, player.round_number * 3.0)


static func text_value(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	if player == null or not native(unit):
		return -1.0
	var counts: Vector3i = _counts(player)
	var prey: float = _prey_size(player)
	for ability: String in ["nip", "sable", "lutra"]:
		if has(unit, ability):
			var strike: float = 0.3 * prey if ability == "sable" else 0.0
			return 5.0 + prey * _share(value, unit, ability) + strike
	if has(unit, "wick"):
		return 4.0 + prey * _share(value, unit, "wick") * mini(2, counts.x)
	if has(unit, "grizel"):
		return (
			prey * _share(value, unit, "grizel") * mini(5, counts.y + counts.x)
			if player.board_count() > 1
			else 0.0
		)
	if has(unit, "glutton"):
		var sources: int = counts.x
		if sources == 0 and (_has(player, "isegrim") or _has(player, "old_brock")):
			sources = 1
		return prey * _share(value, unit, "glutton") * sources
	if has(unit, "lodger"):
		return prey * _share(value, unit, "lodger") * mini(2, counts.x)
	if has(unit, "laird"):
		var multiplier: float = _rate_for(
			value, unit, "laird", "laird_multiplier", 3.0 if unit.golden else 2.0
		)
		return prey * counts.x * (multiplier - 1.0) * 0.6
	if has(unit, "ermeline"):
		var pelts: float = _rate_for(
			value, unit, "ermeline", "ermeline_pelts", 2.0 if unit.golden else 1.0
		)
		return (
			prey * rate(value, "pelt_share", 1.0 / 3.0) * pelts * 2.0
			if counts.x > 0 or _has(player, "isegrim") or _has(player, "old_brock")
			else 0.0
		)
	if has(unit, "russet"):
		return _russet_text(unit, player, value)
	if has(unit, "brother_wolf") or has(unit, "agnes"):
		return 5.0 + prey * mini(2, maxi(counts.x, player.board_count() - counts.y)) * 0.4
	if has(unit, "isegrim") or has(unit, "old_brock"):
		return 6.0 + prey * mini(3, counts.z) * 0.5
	if has(unit, "young_brock"):
		return 4.0 + maxi(0, counts.z - 1) * 2.0
	if has(unit, "lane_bard"):
		return (
			BotEval.GOLD_POINTS
			* _rate_for(
				value, unit, "lane_bard", "lane_bard_gold", float(factor(unit, "lane_bard"))
			)
			* rate(value, "lane_bard_triggers", 2.0)
		)
	return -1.0


static func _russet_text(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	if value.library == null:
		return 0.0
	var share: float = _rate_for(
		value, unit, "russet", "russet_buff_share", 1.0 if unit.golden else 2.0 / 3.0
	)
	var best: float = 0.0
	var views: Array = player.scout.get("views", [])
	for slot: int in BoardGeometry.SLOTS:
		var prey: Dictionary = BotLanes._enemy(player, slot)
		var card: Dictionary = value.library.get_unit(str(prey.get("def_id", "")))
		if (
			card.is_empty()
			or not CoreUtil.to_bool(card.get("pool", false))
			or CoreUtil.to_int(card.get("tier", 0)) > player.tier
		):
			continue
		var layers: Dictionary = prey.get("stat_layers", {})
		if slot < views.size() and views[slot] is Dictionary:
			var view: Dictionary = views[slot]
			layers = view.get("stat_layers", layers)
		var attack: int = maxi(0, CoreUtil.to_int(layers.get("perm_attack", 0)))
		var health: int = maxi(0, CoreUtil.to_int(layers.get("perm_health", 0)))
		# The copy is still a paid offer; only its actual permanent layers are inherited.
		best = maxf(best, 6.0 + floorf(attack * share) + floorf(health * share))
	return best


static func _has(player: PlayerState, ability: String) -> bool:
	for unit: RecruitUnit in player.board:
		if has(unit, ability):
			return true
	return false


static func keep_engine(player: PlayerState, unit: RecruitUnit) -> bool:
	if not native(unit):
		return false
	var counts: Vector3i = _counts(player)
	var live: bool = false
	for ability: String in ["laird", "lodger"]:
		live = live or (has(unit, ability) and counts.x > 0)
	for ability: String in ["glutton", "ermeline"]:
		live = (
			live
			or (
				has(unit, ability)
				and (counts.x > 0 or _has(player, "isegrim") or _has(player, "old_brock"))
			)
		)
	live = live or (has(unit, "brother_wolf") and player.board_count() > 1)
	live = live or (has(unit, "grizel") and player.board_count() > 1 and counts.y > 0)
	live = (
		live
		or (
			has(unit, "isegrim")
			and counts.z > 1
			and (_has(player, "glutton") or _has(player, "ermeline") or _has(player, "grizel"))
		)
	)
	if live:
		for other: RecruitUnit in player.board:
			if other != null and other != unit and other.def_id() == unit.def_id():
				if (
					_power(other) > _power(unit)
					or (
						_power(other) == _power(unit)
						and (
							_body(other) > _body(unit)
							or (_body(other) == _body(unit) and other.iid < unit.iid)
						)
					)
				):
					return false
		return true
	if _taker(unit) and not has(unit, "russet") and unit.perm_attack + unit.perm_health > 0:
		return _has(player, "glutton") or _has(player, "laird") or _has(player, "grizel")
	return false


## All own marks precede Hunter-only loans; the first Hunter in reading order owns each Take.
static func forecast(player: PlayerState, layout: Array[int]) -> Dictionary:
	var enemies: Array[Dictionary] = []
	var marks: Array[Dictionary] = []
	var identity: int = 0
	var views: Array = player.scout.get("views", [])
	for slot: int in BoardGeometry.SLOTS:
		var enemy: Dictionary = BotLanes._enemy(player, slot).duplicate(true)
		if not enemy.is_empty() and slot < views.size() and views[slot] is Dictionary:
			var view: Dictionary = views[slot]
			enemy["stat_layers"] = view.get("stat_layers", {})
		identity = _tag(enemy, slot, identity)
		enemies.append(enemy)
		marks.append({})
	var biggest: Dictionary = _biggest(enemies)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if unit == null or unit.has_mechanic_id("no_quarry"):
			continue
		if unit.has_mechanic_id("quarry") and _eligible(enemies[slot]):
			marks[slot] = enemies[slot]
		if has(unit, "isegrim") and not biggest.is_empty():
			marks[slot] = biggest
	for source: int in BoardGeometry.SLOTS:
		var lender: RecruitUnit = BotLanes._at(player, layout, source)
		if not has(lender, "isegrim") and not has(lender, "old_brock"):
			continue
		var targets: Array[int] = BoardGeometry.neighbours(source)
		var prey: Dictionary = enemies[source]
		if has(lender, "isegrim"):
			prey = marks[source]
			if factor(lender, "isegrim") == 1:
				targets = BoardGeometry.adjacent(source)
		for target: int in targets:
			var unit: RecruitUnit = BotLanes._at(player, layout, target)
			if (
				unit != null
				and unit.has_tribe("Hunters")
				and not unit.has_mechanic_id("no_quarry")
				and marks[target].is_empty()
				and _eligible(prey)
			):
				marks[target] = prey
	var owners: Dictionary = {}
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if unit != null and unit.has_tribe("Hunters") and not marks[slot].is_empty():
			var key: int = CoreUtil.to_int(marks[slot]["hunt_identity"])
			if not owners.has(key):
				owners[key] = slot
	return {"marks": marks, "owners": owners}


static func _tag(enemy: Dictionary, slot: int, identity: int) -> int:
	if enemy.is_empty():
		return identity
	enemy["hunt_identity"] = identity
	enemy["hunt_slot"] = slot
	identity += 1
	var held: Array = enemy.get("held", [])
	for child: Dictionary in held:
		identity = _tag(child, slot, identity)
	return identity


static func _eligible(enemy: Dictionary) -> bool:
	return not enemy.is_empty() and not BotLanes._egg(enemy)


static func _biggest(enemies: Array) -> Dictionary:
	var best: Dictionary = {}
	var size: int = -1
	for enemy: Dictionary in enemies:
		var body: int = BotLanes._stat(enemy, "attack") + BotLanes._stat(enemy, "health")
		if _eligible(enemy) and body > size:
			best = enemy
			size = body
		var held: Array = enemy.get("held", [])
		var inside: Dictionary = _biggest(held)
		var inner: int = BotLanes._stat(inside, "attack") + BotLanes._stat(inside, "health")
		if not inside.is_empty() and inner > size:
			best = inside
			size = inner
	return best


static func poach_value(
	player: PlayerState, value: BotEval, russet: RecruitUnit, enemy: Dictionary
) -> float:
	if value.library == null:
		return 0.0
	var card: Dictionary = value.library.get_unit(str(enemy.get("def_id", "")))
	if (
		card.is_empty()
		or not CoreUtil.to_bool(card.get("pool", false))
		or CoreUtil.to_int(card.get("tier", 0)) > player.tier
	):
		return -10.0
	var copy := RecruitUnit.make(card, 0)
	var layers: Dictionary = enemy.get("stat_layers", {})
	var share: float = _rate_for(
		value,
		russet,
		"russet",
		"russet_buff_share",
		1.0 if factor(russet, "russet") > 1 else 2.0 / 3.0
	)
	copy.add_permanent(
		floori(CoreUtil.to_int(layers.get("perm_attack", 0)) * share),
		floori(CoreUtil.to_int(layers.get("perm_health", 0)) * share)
	)
	return value.buy_value(copy, player)


static func score(player: PlayerState, value: BotEval, layout: Array[int]) -> float:
	var predicted: Dictionary = forecast(player, layout)
	var marks: Array[Dictionary] = predicted["marks"]
	var owners: Dictionary = predicted["owners"]
	var total: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if unit == null:
			continue
		var prey: Dictionary = marks[slot]
		var hit: float = unit.attack
		if not prey.is_empty():
			var attack: int = BotLanes._stat(prey, "attack")
			var health: int = BotLanes._stat(prey, "health")
			if has(unit, "sable"):
				hit += (
					attack
					* _rate_for(value, unit, "sable", "sable_strike", float(factor(unit, "sable")))
				)
			var joins: int = 0
			for next: int in BoardGeometry.adjacent(slot):
				var joiner: RecruitUnit = BotLanes._at(player, layout, next)
				if joiner != null and joiner.has_mechanic_id("pack"):
					hit += joiner.attack
					joins += 1
			var chance: float = 1.0 if hit >= health else 0.2 * hit / maxi(1, health)
			if (
				BoardGeometry.is_back(slot)
				and not has(unit, "lutra")
				and unit.has_mechanic_id("quarry")
			):
				chance *= 0.35
			total += 0.15 * attack + (8.0 if hit >= health else 0.0)
			if CoreUtil.to_int(owners.get(prey["hunt_identity"], -1)) == slot:
				for ability: String in ["nip", "sable", "lutra"]:
					if has(unit, ability):
						total += (attack + health) * _share(value, unit, ability) * chance
				if has(unit, "russet"):
					total += poach_value(player, value, unit, prey) * chance
				for next: int in BoardGeometry.adjacent(slot):
					if has(BotLanes._at(player, layout, next), "lodger"):
						total += 8.0 + (attack + health) * 0.3 * chance
			if has(unit, "lane_bard"):
				total += 8.0 + minf(2.0, float(health) / maxf(1.0, hit)) * 4.0
			if has(unit, "lutra") and BoardGeometry.is_back(slot):
				total += 10.0
			if joins > 0 and _has(player, "agnes"):
				total += minf(attack, unit.health) * 0.3
		if has(unit, "brother_wolf"):
			for next: int in BoardGeometry.adjacent(slot):
				var leader: RecruitUnit = BotLanes._at(player, layout, next)
				if leader != null and not leader.has_mechanic_id("pack"):
					total += 10.0 + leader.attack * 0.3
		if has(unit, "glutton"):
			for next: int in BoardGeometry.adjacent(slot):
				var leader: RecruitUnit = BotLanes._at(player, layout, next)
				if has(leader, "isegrim") or has(leader, "lutra"):
					total += 12.0 + unit.attack * 0.3
	return total


static func pelt_aim(player: PlayerState, legal: Array[int]) -> int:
	var total: int = 0
	var best: int = -1
	var smallest: int = 2147483647
	for unit: RecruitUnit in player.board:
		if unit != null:
			total += _body(unit)
	for slot: int in legal:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not unit.has_tribe("Hunters"):
			continue
		if has(unit, "glutton") and _body(unit) < total * 0.35:
			return slot
		if (
			(has(unit, "nip") or has(unit, "sable") or has(unit, "lutra"))
			and _body(unit) < smallest
		):
			best = slot
			smallest = _body(unit)
	if best >= 0:
		return best
	for slot: int in legal:
		if player.board[slot] != null and player.board[slot].has_tribe("Hunters"):
			return slot
	return -1


static func wants_poached(player: PlayerState, unit: RecruitUnit) -> bool:
	if not CoreUtil.to_bool(unit.get("poached_offer")):
		return true
	if BotEval.copies_of(player, unit.def_id()) >= 2:
		return true
	var alternative: int = 0
	for other: RecruitUnit in player.shop:
		if other != unit and not CoreUtil.to_bool(other.get("poached_offer")):
			alternative = maxi(alternative, other.attack + other.health)
	return unit.attack + unit.health >= 1.5 * alternative


static func poached_offer(brain: BotBrain, spare: int) -> Dictionary:
	var best: Dictionary = {}
	var most: float = 0.0
	for index: int in brain._player.shop.size():
		var unit: RecruitUnit = brain._player.shop[index]
		if (
			not CoreUtil.to_bool(unit.get("poached_offer"))
			or not wants_poached(brain._player, unit)
		):
			continue
		var cost: int = brain._unit_offer_cost(unit)
		if cost > spare or brain._rules.buys_left(brain._player) == 0:
			continue
		var gain: float = brain._unit_gain(unit)
		if gain > most:
			most = gain
			best = {"index": index, "spell": false, "cost": cost, "gain": gain}
	return best


static func can_inherit(player: PlayerState, unit: RecruitUnit) -> bool:
	if unit == null or not unit.has_tribe("Hunters"):
		return false
	for heir: RecruitUnit in player.board:
		if heir != unit and has(heir, "young_brock"):
			return true
	return false


## Return the real sale slot after a legal move; callers must not assume the original gap stays.
static func prepare_sale(brain: BotBrain, slot: int) -> int:
	var player: PlayerState = brain._player
	var unit: RecruitUnit = player.board[slot]
	if not can_inherit(player, unit):
		return slot
	var pinned: Array[int] = BotPlacer.pinned_slots(player)
	for source: int in BoardGeometry.SLOTS:
		var heir: RecruitUnit = player.board[source]
		if heir == unit or not has(heir, "young_brock"):
			continue
		var reach: Array[int] = (
			BoardGeometry.adjacent(source)
			if factor(heir, "young_brock") == 1
			else BoardGeometry.neighbours(source)
		)
		if reach.has(slot):
			return slot
		if pinned.has(slot):
			continue
		for target: int in reach:
			if not pinned.has(target) and brain._rules.move(player, slot, target) == "":
				brain._settle()
				return target
	return slot


static func search_pins(player: PlayerState, layout: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = BotLanes._at(player, layout, slot)
		if (
			has(unit, "glutton")
			or has(unit, "brother_wolf")
			or has(unit, "lodger")
			or has(unit, "isegrim")
			or has(unit, "old_brock")
		):
			if not out.has(slot):
				out.append(slot)
			var reach: Array[int] = BoardGeometry.adjacent(slot)
			if has(unit, "old_brock") or factor(unit, "isegrim") > 1:
				reach = BoardGeometry.neighbours(slot)
			for next: int in reach:
				var recipient: RecruitUnit = BotLanes._at(player, layout, next)
				if recipient != null and recipient.has_tribe("Hunters") and not out.has(next):
					out.append(next)
	return out
