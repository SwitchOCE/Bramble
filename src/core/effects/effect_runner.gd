class_name EffectRunner
extends RefCounted
## Runs one data effect: conditions, then limits, then each step on its targets. All the verbs go
## through the EffectWorld of the phase. The format is docs/ideation/engine.md.


## Runs the effect if its conditions and limits allow.
static func run(params: Dictionary, world: EffectWorld) -> void:
	if not EffectConditions.all_hold(params, world):
		return
	var times: int = _times(params, world)
	if times <= 0:
		return
	var key: String = str(params.get("name", world.trigger))
	if CoreUtil.to_bool(params.get("once", false)):
		var fired: Dictionary = world.counter_store()
		var once_key: String = "fired_%s" % key
		if fired.has(once_key):
			return
		fired[once_key] = 1
	if params.has("limit"):
		var store: Dictionary = world.limit_store()
		var left: int = CoreUtil.to_int(params["limit"]) - CoreUtil.to_int(store.get(key, 0))
		times = mini(times, left)
		if times <= 0:
			return
		store[key] = CoreUtil.to_int(store.get(key, 0)) + times
	world.announce(key)
	var steps: Array = MechanicRegistry.steps_of(params)
	var event_amount: int = world.amount
	for _time: int in times:
		for value: Variant in steps:
			var step: Dictionary = value
			run_step(step, params, world)
	world.amount = event_amount


## How many times this firing counts: "every": N fires each Nth count (thresholds keep their value
## on golden, 7.3.5). With "count_amount" the event's amount is counted instead of 1 per event.
static func _times(params: Dictionary, world: EffectWorld) -> int:
	if not params.has("every"):
		return 1
	var every: int = maxi(1, CoreUtil.to_int(params["every"]))
	var store: Dictionary = world.counter_store()
	var key: String = str(params.get("counter", world.trigger))
	var added: int = world.amount if CoreUtil.to_bool(params.get("count_amount", false)) else 1
	var total: int = CoreUtil.to_int(store.get(key, 0)) + added
	store[key] = total % every
	@warning_ignore("integer_division")
	return total / every


static func run_step(step: Dictionary, params: Dictionary, world: EffectWorld) -> void:
	var effect: String = str(step.get("effect", ""))
	var targets: Array[BoardUnit] = _targets(step, params, world)
	var factor: int = _per(step, world)
	match effect:
		"buff":
			var attack: int = CoreUtil.to_int(step.get("attack", 0)) * factor
			var health: int = CoreUtil.to_int(step.get("health", 0)) * factor
			var duration: String = str(step.get("duration", world.default_duration()))
			var per_slot: bool = str(step.get("per", "")) == "empty_adjacent"
			for target: BoardUnit in targets:
				var times: int = _empty_adjacent(target, world) if per_slot else 1
				world.buff(target, attack * times, health * times, duration)
		"damage":
			for target: BoardUnit in targets:
				world.damage(target, CoreUtil.to_int(step.get("amount", 0)) * factor)
		"grant":
			var entry: Dictionary = step.get("mechanic", {})
			var keyword: String = str(step.get("keyword", ""))
			for target: BoardUnit in targets:
				world.grant(
					target, entry, keyword, str(step.get("duration", world.default_duration()))
				)
		"status":
			for target: BoardUnit in targets:
				world.apply_status(target, str(step.get("status", "")))
		"multiply":
			var more: int = CoreUtil.to_int(step.get("factor", 2)) - 1
			for target: BoardUnit in targets:
				world.buff(target, target.attack * more, target.health * more, "permanent")
		"wait_in_slot":
			for target: BoardUnit in targets:
				world.add_timer(
					target,
					CoreUtil.to_int(step.get("turns", 1)),
					CoreUtil.to_int(step.get("attack", 0)),
					CoreUtil.to_int(step.get("health", 0))
				)
		"borrow_attack":
			for target: BoardUnit in targets:
				world.borrow_attack(target)
		"swap":
			if not targets.is_empty():
				world.swap_with(targets[0])
		"slot_effect":
			_slot_effect(step, targets, world)
		_:
			_untargeted(effect, step, factor, world)


static func _untargeted(effect: String, step: Dictionary, factor: int, world: EffectWorld) -> void:
	match effect:
		"summon":
			_summon(step, world)
		"gold":
			world.gain_gold(
				CoreUtil.to_int(step.get("amount", 0)) * factor, str(step.get("when", "now"))
			)
		"add_card":
			world.add_card(
				str(step.get("card", "")),
				CoreUtil.to_int(step.get("count", 1)) * factor,
				CoreUtil.to_bool(step.get("from_pool", false))
			)
		"free_refresh":
			world.free_refresh(CoreUtil.to_int(step.get("count", 1)) * factor)
		"refresh_shop":
			world.refresh_shop()
		"move":
			world.move_source(str(step.get("to", "")))
		"discover":
			world.discover(step)
		"rule":
			world.add_rule(step)
		_:
			_board_verbs(effect, step, world)


static func _board_verbs(effect: String, step: Dictionary, world: EffectWorld) -> void:
	match effect:
		"pass":
			world.queue_pass(
				CoreUtil.to_int(step.get("attack", 0)), CoreUtil.to_int(step.get("health", 0))
			)
		"spend_all":
			world.spend_all()
		"burn_gold":
			world.burn_gold(CoreUtil.to_int(step.get("above", 0)))
		"tier_down":
			world.tier_down()
		"borrow":
			world.borrow(
				CoreUtil.to_int(step.get("amount", 0)), CoreUtil.to_int(step.get("repay", 0))
			)
		"refresh_keep":
			world.refresh_keep()
		_:
			push_error("Unknown effect '%s'" % effect)


## "copies" doubles on golden, "count" doesn't. A step that names a place or Spills goes its own
## way; a plain one keeps 8.4.
static func _summon(step: Dictionary, world: EffectWorld) -> void:
	var count: int = CoreUtil.to_int(step.get("copies", step.get("count", 1)))
	if step.has("at") or step.has("spill") or step.has("stats"):
		world.summon_placed(step, count, _golden(step, world))
		return
	world.summon(str(step.get("unit", "")), count, _golden(step, world))


## 8.5: into the targets' slots, or "at": "chosen" for the slot a spell or power was aimed at.
static func _slot_effect(step: Dictionary, targets: Array[BoardUnit], world: EffectWorld) -> void:
	if str(step.get("at", "")) == "chosen":
		if BoardGeometry.is_valid(world.chosen_slot):
			world.add_slot_effect(world.chosen_slot, step)
		return
	if str(step.get("at", "")) == "nearest_empty":
		var slot: int = BoardGeometry.summon_slot(world.occupied_slots(), world.source_slot, false)
		if slot >= 0:
			world.add_slot_effect(slot, step)
		return
	for target: BoardUnit in targets:
		var slot: int = world.own.find(target)
		if slot >= 0:
			world.add_slot_effect(slot, step)


## 7.3.5: a golden source summons golden tokens, unless the step says "golden": false.
static func _golden(step: Dictionary, world: EffectWorld) -> bool:
	if step.has("golden"):
		return CoreUtil.to_bool(step["golden"])
	return world.source != null and world.source.golden


static func _targets(step: Dictionary, params: Dictionary, world: EffectWorld) -> Array[BoardUnit]:
	var spec: Dictionary = step.get("target", params.get("target", {}))
	return TargetSelect.pick(spec, world)


## How many slots adjacent to the target are empty ("per": "empty_adjacent").
static func _empty_adjacent(target: BoardUnit, world: EffectWorld) -> int:
	var slot: int = world.own.find(target)
	return 0 if slot < 0 else BoardGeometry.empty_adjacent(world.occupied_slots(), slot)


## "per": a word ("gold", "tier", "hand", "amount", "carried") or a selector {"select", ...}: the
## step's numbers are multiplied by that count, after "per_div" (rounded down) and "per_max".
static func _per(step: Dictionary, world: EffectWorld) -> int:
	if not step.has("per"):
		return 1
	var count: int = _per_count(step["per"], world)
	if step.has("per_div"):
		@warning_ignore("integer_division")
		count = count / maxi(1, CoreUtil.to_int(step["per_div"]))
	if step.has("per_max"):
		count = mini(count, CoreUtil.to_int(step["per_max"]))
	return count


static func _per_count(per: Variant, world: EffectWorld) -> int:
	if typeof(per) == TYPE_DICTIONARY:
		var spec: Dictionary = per
		return TargetSelect.pick(spec, world).size()
	match str(per):
		"gold":
			return world.gold_now()
		"tier":
			return world.tier_now()
		"hand":
			return world.hand_cards()
		"amount":
			return world.amount
		"carried":
			return world.carried_gold_now()
		"empty_adjacent":
			return 1
	push_error("Unknown per '%s'" % str(per))
	return 1
