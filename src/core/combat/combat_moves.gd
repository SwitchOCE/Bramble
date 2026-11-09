class_name CombatMoves
extends RefCounted
## The fight's rarer moves: units that change place or side, Rings that dance, and what a few cards
## read from the fight. Combat keeps the state; these keep Combat small.

const REEL: String = "reel_mistress"
## Front and back slots that swap when a row turns over.
const ROW_SWAPS: Array = [[0, 4], [1, 5], [2, 6]]


## Pass in a fight: the last living unit other than `from` gains this immediately, for this fight.
static func pass_buff(
	combat: Combat, from: CombatUnit, attack_delta: int, health_delta: int
) -> void:
	var landing: int = BoardGeometry.pass_landing(combat._occupied(from.side), from.slot)
	var unit: CombatUnit = combat.unit_at(from.side, landing) if landing >= 0 else null
	if unit != null:
		combat.buff(unit, attack_delta, health_delta, from)


## The slots painted with a band on this side.
static func bands_of(combat: Combat, side: int) -> Array[int]:
	var out: Array[int] = []
	var rules_here: Dictionary = combat.side_rules[side]
	var row: Array = rules_here.get("bands", [])
	for slot: int in row.size():
		if CoreUtil.to_int(row[slot]) != 0:
			out.append(slot)
	return out


## Sergeant-at-Conkers: the smallest Acorn item not yet thrown this fight; 0 if none. It leaves the
## hand when the fight is over.
static func take_ammo(combat: Combat, side: int) -> int:
	var rules_here: Dictionary = combat.side_rules[side]
	var thrown: int = CoreUtil.to_int(combat.ammo_thrown[side])
	var ammo: Array = rules_here.get("ammo", [])
	if thrown >= ammo.size():
		return 0
	combat.ammo_thrown[side] = thrown + 1
	var gold: int = CoreUtil.to_int(ammo[thrown])
	combat.carry_back(side, {"op": "spend_item", "gold": gold})
	return gold


## Cradle Fetch: `unit` is gone (no death effects) and a printed copy of `other` stands in its slot.
static func become_copy(combat: Combat, unit: CombatUnit, other: CombatUnit, bonus: int) -> void:
	var slot: int = unit.slot
	var side: int = unit.side
	var row: Array = combat.sides[side]
	row[slot] = null
	unit.on_board = false
	combat._emit("death", {"uid": unit.uid, "side": side, "slot": slot})
	var fields: Dictionary = {"copied": other.uid} if Pass3Combat.enabled(combat) else {}
	var copy: CombatUnit = combat.summon_into(
		other.def_id(), unit.golden, side, slot, unit, 0, fields
	)
	if copy == null:
		return
	if bonus > 0:
		combat.buff(copy, bonus, bonus, copy)
	for index: int in copy.scripts.size():
		copy.scripts[index].on_start_of_combat(combat, copy, copy.params[index])


## Changeling: the two trade places and sides. The enemy comes back after it has attacked once.
static func borrow_across(combat: Combat, unit: CombatUnit, enemy: CombatUnit, bonus: int) -> void:
	trade_sides(combat, unit, enemy)
	combat.set_status(enemy, "borrowed", true, unit, {"partner": unit.uid})
	combat.borrowed[enemy.uid] = unit
	if bonus > 0:
		combat.buff(enemy, bonus, bonus, unit)


static func trade_sides(combat: Combat, a: CombatUnit, b: CombatUnit) -> void:
	CombatLanes.lose_unit(combat, a, true)
	CombatLanes.lose_unit(combat, b, true)
	var slot_a: int = a.slot
	var slot_b: int = b.slot
	var side_a: int = a.side
	var side_b: int = b.side
	var row_a: Array = combat.sides[side_a]
	var row_b: Array = combat.sides[side_b]
	row_a[slot_a] = b
	row_b[slot_b] = a
	a.side = side_b
	a.slot = slot_b
	b.side = side_a
	b.slot = slot_a
	combat._emit("relocate", {"uid": a.uid, "side": a.side, "slot": a.slot})
	combat._emit("relocate", {"uid": b.uid, "side": b.side, "slot": b.slot})
	combat._recalc_auras(true)


## A borrowed unit has attacked (or its Changeling is gone): it goes home, to its own slot if free.
static func send_home(combat: Combat, borrowed: CombatUnit) -> void:
	var partner: CombatUnit = combat.borrowed.get(borrowed.uid)
	if not combat.borrowed.erase(borrowed.uid):
		return
	combat.set_status(borrowed, "borrowed", false, null)
	if not borrowed.on_board or borrowed.is_dead():
		return
	if partner != null and partner.on_board:
		trade_sides(combat, borrowed, partner)
		return
	var home: int = 1 - borrowed.side
	var slot_to: int = borrowed.slot if combat.unit_at(home, borrowed.slot) == null else -1
	if slot_to < 0:
		slot_to = BoardGeometry.summon_slot(combat._occupied(home), borrowed.slot, true)
	if slot_to < 0:
		return
	var row: Array = combat.sides[borrowed.side]
	row[borrowed.slot] = null
	var row_home: Array = combat.sides[home]
	row_home[slot_to] = borrowed
	CombatLanes.lose_unit(combat, borrowed, true)
	borrowed.side = home
	borrowed.slot = slot_to
	combat._emit("relocate", {"uid": borrowed.uid, "side": home, "slot": slot_to})
	combat._recalc_auras(true)


## Whirligig Beetle: a side's rows swap, slot by slot; F4 stays. Returns the units that moved.
static func swap_rows(combat: Combat, side: int, protect_rings: bool = false) -> Array[CombatUnit]:
	var moved: Array[CombatUnit] = []
	var row: Array = combat.sides[side]
	for pair: Array in ROW_SWAPS:
		var front: int = pair[0]
		var back: int = pair[1]
		var front_unit: CombatUnit = combat.unit_at(side, front)
		var back_unit: CombatUnit = combat.unit_at(side, back)
		if (
			protect_rings
			and (
				Pass3RowSwap.improves_ring(combat, front_unit, back)
				or Pass3RowSwap.improves_ring(combat, back_unit, front)
			)
		):
			continue
		row[front] = back_unit
		row[back] = front_unit
		if front_unit != null:
			moved.append(front_unit)
			front_unit.slot = back
			combat._emit("relocate", {"uid": front_unit.uid, "side": side, "slot": back})
		if back_unit != null:
			moved.append(back_unit)
			back_unit.slot = front
			combat._emit("relocate", {"uid": back_unit.uid, "side": side, "slot": front})
	combat._recalc_auras(true)
	return moved


## Reel-Mistress: after a unit on a Ring attacks, the Ring moves to the side's next living unit in
## attack order, and adds to any Ring there. Each Ring dances once. It costs its old holder Health.
static func dance_rings(combat: Combat, attacker: CombatUnit) -> void:
	if Pass3FairyCombat.dance(combat, attacker):
		return
	var side: int = attacker.side
	var mistress: CombatUnit = null
	for unit: CombatUnit in combat.units_of(side):
		if unit.has_mechanic(REEL):
			mistress = unit
			break
	if mistress == null or not attacker.on_board:
		return
	var here: Array = combat._slot_effects_at(side, attacker.slot)
	if not BoardUpkeep.has_ring(here):
		return
	var next_slot: int = next_in_attack_order(combat, attacker)
	if next_slot < 0:
		return
	own_slot_effects(combat, side)
	var row: Array = combat.slot_effects[side]
	var from: Array = row[attacker.slot]
	var ring: Dictionary = {}
	for value: Variant in from:
		var effect: Dictionary = value
		if (
			str(effect.get("name", "")) == BoardUpkeep.RING
			and (
				not effect.get("danced", false)
				or CombatLanes.parameters(mistress, REEL).get("repeat", false)
			)
		):
			ring = effect
			break
	if ring.is_empty():
		return
	from.erase(ring)
	var moved: Dictionary = ring.duplicate()
	moved["danced"] = true
	if mistress.golden:
		moved["attack"] = CoreUtil.to_int(moved["attack"]) + 1
		moved["health"] = CoreUtil.to_int(moved["health"]) + 1
	var to: Array = row[next_slot]
	to.append(moved)
	combat.trigger(mistress, REEL)
	combat._emit(
		"ring_dance",
		{
			"side": side,
			"from": attacker.slot,
			"to": next_slot,
			"attack": moved["attack"],
			"health": moved["health"]
		}
	)
	combat._recalc_auras(true)
	combat._resolve_deaths(side)


## The slot effects of a fight are shared with the recruit board until something changes them.
static func own_slot_effects(combat: Combat, side: int) -> void:
	if combat.slots_owned[side]:
		return
	combat.slots_owned[side] = true
	var copied: Array = []
	var row: Array = combat.slot_effects[side]
	for effects: Variant in row:
		var list: Array = effects
		copied.append(list.duplicate(true))
	combat.slot_effects[side] = copied
	combat._slots_active = true


static func next_in_attack_order(combat: Combat, unit: CombatUnit) -> int:
	var order: Array[CombatUnit] = combat._attack_order(unit.side)
	var at: int = order.find(unit)
	for step: int in range(1, order.size()):
		var other: CombatUnit = order[(at + step) % order.size()]
		if other.on_board and other != unit:
			return other.slot
	return -1


## What waits for a unit's attack to be over: Rings dance, a parasite hatches, a loan ends.
static func after_attacked_once(combat: Combat, attacker: CombatUnit) -> void:
	if combat._slots_active:
		dance_rings(combat, attacker)
	if attacker.on_board and attacker.has_status("parasite"):
		var parasite: Dictionary = attacker.statuses["parasite"]
		lose_health(
			combat,
			attacker,
			attacker.health,
			"parasite",
			CoreUtil.to_int(parasite.get("owner_side", -1)),
			CoreUtil.to_int(parasite.get("source_uid", -1))
		)
		combat.set_status(attacker, "parasite", false, null)
		combat._resolve_deaths(attacker.side)
	if not combat.borrowed.is_empty() and combat.borrowed.has(attacker.uid):
		var loan: Dictionary = attacker.statuses.get("borrowed", {})
		if loan.has("attacks_left"):
			loan["attacks_left"] = CoreUtil.to_int(loan["attacks_left"]) - 1
			if CoreUtil.to_int(loan["attacks_left"]) > 0:
				return
		send_home(combat, attacker)


## The empty slots on a side that hold a Ring (Will-o'-the-Wisp).
static func empty_ring_slots(combat: Combat, side: int) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		var ringed: bool = BoardUpkeep.has_ring(combat._slot_effects_at(side, slot))
		if combat.unit_at(side, slot) == null and ringed:
			out.append(slot)
	return out


## Nightshade (library entry 75): the defender first loses half its current Health, rounded
## down; Health loss, not damage, so it never kills.
static func nightshade(combat: Combat, defender: CombatUnit) -> void:
	if not defender.has_status("nightshade"):
		return
	@warning_ignore("integer_division")
	var loss: int = defender.health / 2
	if loss <= 0:
		return
	lose_health(combat, defender, loss, "nightshade")


## A hero's "a friendly unit died" entries (Old Mother Mousewife).
static func hero_on_death(combat: Combat, dead: CombatUnit) -> void:
	var entries: Array = combat.hero_effects[dead.side]
	for value: Variant in entries:
		var entry: Dictionary = value
		if str(entry.get("trigger", "")) == "on_friendly_death":
			var world := CombatWorld.make(combat, null, dead.side, entry, "on_friendly_death")
			world.set_subject(dead)
			EffectRunner.run(entry, world)


## Legacy ideation compresses survivor tiers and charges a floor; bare rules use full tiers.
static func hero_damage(combat: Combat, winner: int, tier: int) -> int:
	var surviving_tiers: int = 0
	for unit: CombatUnit in combat.units_of(winner):
		surviving_tiers += 0 if unit.def_id() == HeldUnits.EGG else unit.tier()
	var divisor: int = maxi(1, combat.config.get_int("survivor_damage_divisor"))
	return maxi(
		combat.config.get_int("hero_damage_floor"), tier + ceili(float(surviving_tiers) / divisor)
	)


## A permanent gain on a capped unit carries only the gain that actually fits.
static func apply_buff(unit: CombatUnit, attack: int, health: int, permanent: bool) -> Vector2i:
	if permanent and CoreUtil.to_int(unit.def.get("permanent_buff_cap", 0)) > 0:
		var before := Vector2i(unit.perm_attack, unit.perm_health)
		unit.add_permanent(attack, health)
		return Vector2i(unit.perm_attack, unit.perm_health) - before
	unit.add_combat(attack, health)
	return Vector2i(attack, health)


## A simultaneous trade can earn a permanent reward. It reaches the recruit unit without
## healing its dying combat copy or presenting a new live stat line after death.
static func buff(
	combat: Combat,
	unit: CombatUnit,
	attack: int,
	health: int,
	source: CombatUnit,
	permanent: bool,
	cause: String = ""
) -> void:
	var departed: bool = not unit.on_board or unit.is_dead()
	if departed and not permanent:
		return
	var old_attack: int = unit.attack
	var old_health: int = unit.health
	var applied: Vector2i = apply_buff(unit, attack, health, permanent)
	if departed:
		unit.damage_taken += unit.health - old_health
		if applied != Vector2i.ZERO and unit.iid != 0:
			(
				combat
				. emit_event(
					"permanent_reward",
					{
						"target": unit.uid,
						"source": uid_or_null(source),
						"attack_delta": applied.x,
						"health_delta": applied.y,
						"cause": cause,
					}
				)
			)
	else:
		emit_stats(
			combat,
			unit,
			unit.attack - old_attack,
			unit.health - old_health,
			source,
			permanent,
			cause
		)
	if permanent and unit.iid != 0:
		combat.carry_back(
			unit.side, {"op": "buff", "iid": unit.iid, "attack": applied.x, "health": applied.y}
		)


static func uid_list(units: Array[CombatUnit]) -> Array:
	var out: Array = []
	for unit: CombatUnit in units:
		out.append(unit.uid)
	return out


static func uid_or_null(unit: CombatUnit) -> Variant:
	if unit == null:
		return null
	return unit.uid


## All damage paths share lethal credit, including Health loss that is not damage.
static func credit_lethal(
	combat: Combat, target: CombatUnit, before: int, owner_side: int, source_uid: int, kind: String
) -> void:
	if before > 0 and target.is_dead():
		combat._last_blow_side = owner_side
		combat._last_blow_source = source_uid
		combat._last_blow_kind = kind


static func lose_health(
	combat: Combat,
	target: CombatUnit,
	amount: int,
	cause: String,
	owner_side: int = -1,
	source_uid: int = -1
) -> void:
	var before: int = target.health
	target.lose_health(amount)
	credit_lethal(combat, target, before, owner_side, source_uid, Hit.EFFECT)
	combat.emit_event(
		"health_loss",
		{
			"target": target.uid,
			"amount": amount,
			"cause": cause,
			"source": CoreUtil.int_or_null(source_uid, -1),
			"owner_side": owner_side,
			"health_after": target.health
		}
	)


## Presentation only; buff owns permanent state and carry outside this logging guard.
static func emit_stats(
	combat: Combat,
	unit: CombatUnit,
	attack_delta: int,
	health_delta: int,
	source: CombatUnit,
	permanent: bool = false,
	cause: String = "",
	causes: Array = []
) -> void:
	if not combat.log_events:
		return
	(
		combat
		. _emit(
			"stats",
			{
				"target": unit.uid,
				"attack_delta": attack_delta,
				"health_delta": health_delta,
				"attack": unit.attack,
				"health": unit.health,
				"max_health": unit.max_health,
				"source": CombatMoves.uid_or_null(source),
				"permanent": permanent,
				"cause": cause,
				"causes": causes,
			}
		)
	)


## Returns preserve uid; combat creations get a new uid and have no starting side.
static func starting_survivors(combat: Combat, winner: int) -> int:
	var count: int = 0
	for unit: CombatUnit in combat.units_of(winner):
		if (
			not unit.is_dead()
			and CoreUtil.to_int(combat.starting_sides.get(unit.uid, -1)) == winner
		):
			count += 1
	return count
