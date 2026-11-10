# gdlint:disable=max-public-methods
# One method per effect verb and per question an effect can ask.
class_name CombatWorld
extends EffectWorld
## A data effect firing in a fight. Rules for who, when and what's logged stay in Combat.

var combat: Combat
var side: int = 0
var hit_amount: int = 0
var _combat_source: CombatUnit = null
var _no_store: Dictionary = {}
var _mouse_notice: bool = false


static func make(
	fight: Combat, unit: CombatUnit, unit_side: int, entry: Dictionary, event: String
) -> CombatWorld:
	var world := CombatWorld.new()
	world.combat = fight
	world.side = unit_side
	world.trigger = event
	world.params = entry
	world.own = fight.sides[unit_side]
	world.enemy = fight.sides[1 - unit_side]
	world.rng = fight.effect_rng
	world.source = unit
	world._combat_source = unit
	if unit != null:
		world.source_slot = unit.slot
	return world


func set_subject(unit: CombatUnit) -> void:
	subject = unit
	subject_slot = unit.slot


func default_duration() -> String:
	return "combat"


func tier_now() -> int:
	return combat.tier_of(side)


func announce(name: String) -> void:
	if _combat_source != null:
		combat.trigger(_combat_source, name)
	else:
		_mouse_notice = name == "mice"
		# Count every attempted firing, but describe Mousewife's actual result below.
		combat.side_trigger(side, name, not _mouse_notice)


func limit_store() -> Dictionary:
	return source.limits if source != null else combat.hero_limits[side]


func counter_store() -> Dictionary:
	return source.counters if source != null else _no_store


func persist_counter(key: String, value: int) -> void:
	if _combat_source != null and _combat_source.iid != 0:
		combat.carry_back(
			side, {"op": "counter", "iid": _combat_source.iid, "key": key, "value": value}
		)


func buff(target: BoardUnit, attack: int, health: int, duration: String) -> void:
	var fighter: CombatUnit = target
	if trigger == "on_take" and duration == "permanent" and Pass3Combat.has_content(combat):
		PendingGains.queue(combat, fighter, attack, health, _combat_source, "take")
		return
	if (
		not fighter.on_board
		and Pass3Combat.enabled(combat)
		and Pass3Combat.is_hidden(combat, fighter)
	):
		Pass3Combat.buff_hidden(
			combat, fighter, attack, health, _combat_source, duration == "permanent"
		)
		return
	combat.buff(fighter, attack, health, _combat_source, duration == "permanent")


func summon(def_id: String, count: int, golden: bool) -> void:
	for _index: int in count:
		combat.summon(def_id, golden, side, source_slot, _combat_source)


## 8.4.6 and Spill in a fight: the Acorn waits until the fight is over.
func summon_placed(step: Dictionary, count: int, golden: bool) -> void:
	var def_id: String = str(step.get("unit", ""))
	var stats: int = combat.tier_of(side) if str(step.get("stats", "")) == "tier" else 0
	var at: String = str(step.get("at", ""))
	if at == "empty_rings":
		var slots: Array[int] = CombatMoves.empty_ring_slots(combat, side)
		if slots.is_empty():
			combat.emit_event(
				"no_room",
				{
					"uid": CombatMoves.uid_or_null(_combat_source),
					"side": side,
					"def_id": def_id,
					"place": at
				}
			)
		for slot: int in slots:
			_summon_with_stats(def_id, golden, slot, stats)
		return
	var anchor: int = subject_slot if str(step.get("of", "")) == "subject" else source_slot
	for _index: int in count:
		var slot: int = combat.named_slot(side, at, anchor)
		if slot >= 0:
			if _mouse_notice:
				if not combat.hero_limits[side].has("mice_notice"):
					combat.hero_limits[side]["mice_notice"] = true
					combat.emit_event("side_trigger", {"side": side, "mechanic": "mice"})
				_mouse_notice = false
			_summon_with_stats(def_id, golden, slot, stats)
		else:
			if _mouse_notice:
				# Only successful Mouse replacements spend the twice-a-fight limit.
				combat.hero_limits[side]["mice"] = (
					CoreUtil.to_int(combat.hero_limits[side].get("mice", 0)) - 1
				)
				combat.emit_event("no_room", {"side": side, "mechanic": "mice", "def_id": def_id})
			else:
				combat.emit_event(
					"no_room",
					{"uid": CombatMoves.uid_or_null(_combat_source), "side": side, "def_id": def_id}
				)
			if CoreUtil.to_bool(step.get("spill", false)):
				combat.spill(side, _combat_source)


func borrow_attack(target: BoardUnit) -> void:
	var fighter: CombatUnit = target
	combat.set_status(fighter, "borrowed_attack", true, _combat_source)


func damage(target: BoardUnit, damage_amount: int) -> void:
	var fighter: CombatUnit = target
	combat.deal_effect_damage(_combat_source, fighter, damage_amount, side)


func no_target(spec: Dictionary) -> void:
	(
		combat
		. emit_event(
			"no_target",
			{
				"uid": CombatMoves.uid_or_null(_combat_source),
				"side": side,
				"reason":
				"no enemy across" if str(spec.get("select", "")) == "across" else "no target",
			}
		)
	)


func grant(target: BoardUnit, entry: Dictionary, keyword: String, duration: String) -> void:
	var is_golden: bool = source != null and source.golden
	var fighter: CombatUnit = target
	fighter.add_grant({"entry": entry, "golden": is_golden})
	combat.emit_event(
		"keyword", {"target": fighter.uid, "keyword": keyword, "permanent": duration == "permanent"}
	)
	if duration == "permanent" and fighter.iid != 0:
		combat.carry_back(
			side,
			{
				"op": "grant",
				"iid": fighter.iid,
				"entry": entry,
				"keyword": keyword,
				"golden": is_golden
			}
		)


func apply_status(target: BoardUnit, status: String) -> void:
	var fighter: CombatUnit = target
	combat.set_status(fighter, status, true, _combat_source)


## Gold gained in a fight arrives next turn (a fight has no recruit gold to add to).
func gain_gold(gold_amount: int, _when: String) -> void:
	combat.carry_back(side, {"op": "gold_next_turn", "amount": gold_amount})


func add_card(card: String, count: int, from_pool: bool) -> void:
	combat.carry_back(
		side, {"op": "add_card", "card": card, "count": count, "from_pool": from_pool}
	)


## A tier is a number of printed stat points; summons without a recipient use the living board.
func _summon_with_stats(def_id: String, golden: bool, slot: int, stats: int) -> void:
	if stats <= 0 or flat_gain_percent() <= 0:
		combat.summon_into(def_id, golden, side, slot, _combat_source, stats)
		return
	var scaled: Vector2i = FlatStatScaling.gains(null, stats, stats, self)
	combat.enter_from_spec(
		{"def_id": def_id, "golden": golden, "attack": scaled.x, "health": scaled.y},
		side,
		slot,
		_combat_source
	)


func flat_gain_percent() -> int:
	return (
		maxi(0, combat.config.get_int("scale_hero_spell_percent"))
		if (
			source == null
			and combat.config.get_bool("scale_hero_spell_stats")
			and not CoreUtil.to_bool(params.get("scaling_exempt", false))
		)
		else 0
	)


func gem_size_add(attack: int, health: int) -> void:
	if (
		ReferenceQuilboar.allowed(combat.config)
		and combat.config.get_bool("reference_quilboar_freeze_size")
	):
		return
	var state: Dictionary = QuilboarCombat.rules(combat, side)
	state["gem_attack_halves"] = CoreUtil.to_int(state.get("gem_attack_halves", 2)) + attack
	state["gem_health_halves"] = CoreUtil.to_int(state.get("gem_health_halves", 2)) + health
	combat.carry_back(side, {"op": "gem_size_add", "attack": attack, "health": health})
	combat.emit_event(
		"gem_size",
		{"side": side, "attack": state["gem_attack_halves"], "health": state["gem_health_halves"]}
	)


func add_random_card(spec: Dictionary, count: int) -> void:
	for _index: int in count:
		var card_id: String = ReferenceQuilboar.random_card(
			combat.library, spec, tier_now(), combat.effect_rng
		)
		if card_id != "":
			add_card(card_id, 1, false)


func gem(target: BoardUnit, count: int, permanent: bool = false) -> void:
	var state: Dictionary = QuilboarCombat.rules(combat, side)
	var fighter: CombatUnit = target
	var attack: int = count * ceili(CoreUtil.to_int(state.get("gem_attack_halves", 2)) / 2.0)
	var health: int = count * ceili(CoreUtil.to_int(state.get("gem_health_halves", 2)) / 2.0)
	# CombatMoves stores uncapped permanent rewards in the combat layer and carries them
	# back separately. Measure both layers, while the ledger remembers the reward's duration.
	var before := Vector2i(
		fighter.perm_attack + fighter.combat_attack, fighter.perm_health + fighter.combat_health
	)
	buff(fighter, attack, health, "permanent" if permanent else "combat")
	var gain := (
		Vector2i(
			fighter.perm_attack + fighter.combat_attack, fighter.perm_health + fighter.combat_health
		)
		- before
	)
	if permanent:
		fighter.gem_attack += gain.x
		fighter.gem_health += gain.y
		if fighter.iid != 0:
			combat.carry_back(
				side, {"op": "gem_ledger", "iid": fighter.iid, "attack": gain.x, "health": gain.y}
			)
	else:
		fighter.combat_gem_attack += gain.x
		fighter.combat_gem_health += gain.y
