# gdlint:disable=max-public-methods
# One method per effect verb and per question an effect can ask.
class_name RecruitContext
extends EffectWorld
## What a recruit trigger hands a mechanic: the player, the rules and the methods to act. One
## context serves one event; the dispatcher sets `source`, `source_slot` and `params` per owner.
## Mechanic scripts use the same methods as data effects, so every change goes through one place.

var rules: RecruitRules
var player: PlayerState
var paid: bool = false
## The spell or hand item this event is about (on_spell_cast).
var card_def: Dictionary = {}


static func make(
	recruit_rules: RecruitRules, owner: PlayerState, event: String, fields: Dictionary
) -> RecruitContext:
	var ctx := RecruitContext.new()
	ctx.rules = recruit_rules
	ctx.player = owner
	ctx.trigger = event
	ctx.own = owner.board
	ctx.hand = owner.hand
	ctx.shop = owner.shop
	ctx.rng = owner.effect_rng
	ctx.amount = CoreUtil.to_int(fields.get("amount", 0))
	ctx.paid = CoreUtil.to_bool(fields.get("paid", false))
	var unit: Variant = fields.get("subject")
	if unit != null:
		ctx.subject = unit
		ctx.subject_slot = owner.board.find(unit)
	var aimed: Variant = fields.get("chosen")
	if aimed != null:
		ctx.chosen = aimed
	ctx.chosen_slot = CoreUtil.to_int(fields.get("chosen_slot", -1))
	var card: Variant = fields.get("card_def")
	if card != null:
		ctx.card_def = card
	return ctx


func tier_now() -> int:
	return player.tier


func gold_now() -> int:
	return player.gold


func round_now() -> int:
	return player.round_number


func hand_cards() -> int:
	return player.hand.size() + player.items.size()


func paid_now() -> bool:
	return paid


func paid_refreshes_now() -> int:
	return player.paid_refreshes


func won_last_combat() -> bool:
	return player.last_result == "win"


func lost_last_combat() -> bool:
	return player.last_result == "loss"


func counter_store() -> Dictionary:
	return source.counters if source != null else player.owner_counters


func limit_store() -> Dictionary:
	return source.limits if source != null else player.owner_limits


func announce(name: String) -> void:
	player.log_event(
		"trigger", {"mechanic": name, "source": source.def_id() if source != null else ""}
	)


func buff(target: BoardUnit, attack: int, health: int, duration: String) -> void:
	if duration == "combat":
		target.add_combat(attack, health)
	else:
		target.add_permanent(attack, health)
	player.log_event(
		"buff",
		{"target": target.def_id(), "attack": attack, "health": health, "duration": duration}
	)


func summon(def_id: String, count: int, golden: bool) -> void:
	rules.summon_units(player, def_id, count, golden, source_slot)


func gain_gold(gold_amount: int, when: String) -> void:
	rules.give_gold(player, gold_amount, when)


func add_card(card: String, count: int, from_pool: bool) -> void:
	for _index: int in count:
		rules.give_card(player, card, from_pool)


func add_slot_effect(slot: int, step: Dictionary) -> void:
	var effect: Dictionary = {
		"name": str(step.get("name", "Slot effect")),
		"text": str(step.get("text", "")),
		"attack": CoreUtil.to_int(step.get("attack", 0)),
		"health": CoreUtil.to_int(step.get("health", 0)),
		"golden": source != null and source.golden,
	}
	if step.has("mechanic"):
		effect["entry"] = step["mechanic"]
	var effects: Array = player.slot_effects[slot]
	effects.append(effect)
	player.log_event("slot_effect", {"slot": slot, "name": effect["name"]})


func discover(step: Dictionary) -> void:
	rules.discover(player, step)


func add_rule(step: Dictionary) -> void:
	var handler: Dictionary = {
		"query": str(step.get("query", "")),
		"op": str(step.get("op", "add")),
		"value": CoreUtil.to_int(step.get("value", 0)),
		"turn_only": str(step.get("duration", "game")) == "turn",
	}
	player.rule_handlers.append(handler)
	player.log_event("rule", {"query": handler["query"], "value": handler["value"]})


func free_refresh(count: int) -> void:
	player.free_refreshes += count
	player.log_event("free_refresh", {"count": count})


func refresh_shop() -> void:
	rules.replace_shop(player)


func grant(target: BoardUnit, entry: Dictionary, keyword: String, duration: String) -> void:
	var is_golden: bool = source != null and source.golden
	(
		target
		. grants
		. append(
			{
				"entry": entry,
				"golden": is_golden,
				"keyword": keyword,
				"combat_only": duration == "combat",
			}
		)
	)
	player.log_event("grant", {"target": target.def_id(), "keyword": keyword})


func damage(target: BoardUnit, damage_amount: int) -> void:
	var unit: RecruitUnit = target
	rules.damage_unit(player, unit, damage_amount)


func swap_with(target: BoardUnit) -> void:
	var unit: RecruitUnit = target
	var slot: int = player.board.find(unit)
	if source_slot >= 0 and slot >= 0:
		move_unit(source_slot, slot)


func move_source(to: String) -> void:
	if source_slot < 0:
		return
	var slots: Array[int] = []
	match to:
		"front":
			slots = BoardGeometry.FRONT
		"back":
			slots = BoardGeometry.BACK
		_:
			var label: int = BoardGeometry.LABELS.find(to)
			if label >= 0:
				slots = [label]
	for slot: int in slots:
		if player.board[slot] == null:
			move_unit(source_slot, slot)
			return


## 8.3.3 from a mechanic: a move into an empty slot or a swap. Mechanics can read and change
## position in the Recruit Phase. Fires on_move like the player's own move.
func move_unit(from_slot: int, to_slot: int) -> void:
	if rules.move_on_board(player, from_slot, to_slot) and from_slot == source_slot:
		source_slot = to_slot
