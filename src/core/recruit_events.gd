class_name RecruitEvents
extends RefCounted
## One queue for every Recruit Phase trigger (architecture-notes 3). An event is delivered to the
## hero, then the board in reading order (each unit's mechanics in file order, then its slot's
## effects), then to a subject that isn't on the board (a bought unit in hand). Anything an effect
## causes queues behind it, so no effect interrupts another. 9.10.2: one player action stops
## resolving new triggers after `trigger_limit_action`.

## A weak reference: the rules own this queue, and a strong one each way would never be freed.
var _rules_ref: WeakRef
var _queue: Array[Dictionary] = []
var _draining: bool = false
var _delivered: int = 0


static func create(rules: RecruitRules) -> RecruitEvents:
	var events := RecruitEvents.new()
	events._rules_ref = weakref(rules)
	return events


func fire(player: PlayerState, trigger: String, fields: Dictionary = {}) -> void:
	_queue.append({"player": player, "trigger": trigger, "fields": fields})
	if _draining:
		return
	_draining = true
	_delivered = 0
	var limit: int = _rules().config.get_int("trigger_limit_action")
	while not _queue.is_empty():
		var event: Dictionary = _queue.pop_front()
		if _delivered > limit:
			var who: PlayerState = event["player"]
			who.log_event("trigger_limit", {"dropped": str(event["trigger"])})
			continue
		_deliver(event)
	_draining = false


func _rules() -> RecruitRules:
	var rules: RecruitRules = _rules_ref.get_ref()
	return rules


func _deliver(event: Dictionary) -> void:
	var player: PlayerState = event["player"]
	var trigger: String = event["trigger"]
	var fields: Dictionary = event["fields"]
	var ctx: RecruitContext = RecruitContext.make(_rules(), player, trigger, fields)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null:
			_deliver_to_unit(ctx, unit, slot)
	var outside: Variant = fields.get("subject")
	if outside != null and player.board.find(outside) < 0:
		var subject: RecruitUnit = outside
		_deliver_to_unit(ctx, subject, -1)


func _deliver_to_unit(ctx: RecruitContext, unit: RecruitUnit, slot: int) -> void:
	ctx.source = unit
	ctx.source_slot = slot
	for value: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = value
		_deliver_one(ctx, compiled.mechanic, compiled.params_for(unit.golden))
	for grant: Dictionary in unit.grants:
		var entry: Dictionary = grant["entry"]
		var mechanic: Mechanic = MechanicRegistry.get_mechanic(str(entry.get("id", "")))
		if mechanic != null:
			var is_golden: bool = grant.get("golden", false)
			_deliver_one(ctx, mechanic, MechanicRegistry.params_for(entry, is_golden))


func _deliver_one(ctx: RecruitContext, mechanic: Mechanic, params: Dictionary) -> void:
	ctx.params = params
	_delivered += 1
	mechanic.recruit_hook(ctx)
