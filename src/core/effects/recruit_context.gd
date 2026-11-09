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
## Echoes reach neighbours, but the player did not aim the spell at them.
var direct_spell: bool = true
## Extra firings cannot repeat a doubling or advance a countdown.
var repeat_index: int = 0


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


func debt_now() -> int:
	return player.debt


func carried_gold_now() -> int:
	return player.carried_gold


func holds_item(card: String) -> bool:
	return player.holds_item(card)


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
	var recruit: RecruitUnit = target as RecruitUnit
	if recruit != null and recruit.has_mechanic_id("shy"):
		recruit.shy_accepts_stats = (
			direct_spell
			and trigger == "cast"
			and target == chosen
			and str(card_def.get("kind", "")) == "spell"
		)
		if not recruit.shy_accepts_stats:
			attack = mini(0, attack)
			health = mini(0, health)
	var before: Vector2i = Vector2i(target.perm_attack, target.perm_health)
	if duration == "combat":
		before = Vector2i(target.combat_attack, target.combat_health)
	if duration == "combat":
		target.add_combat(attack, health)
	else:
		target.add_permanent(attack, health)
	if recruit != null:
		recruit.shy_accepts_stats = false
	player.log_event(
		"buff",
		{"target": target.def_id(), "attack": attack, "health": health, "duration": duration}
	)
	if trigger == "cast" and str(card_def.get("kind", "")) == "spell" and target is RecruitUnit:
		var after: Vector2i = Vector2i(target.perm_attack, target.perm_health)
		if duration == "combat":
			after = Vector2i(target.combat_attack, target.combat_health)
		var ooze: RecruitUnit = target
		MossOoze.share(player, ooze, after.x - before.x, after.y - before.y, duration)
	rules.board_changed(player)


func summon(def_id: String, count: int, golden: bool) -> void:
	rules.summon_units(player, def_id, count, golden, source_slot)


## 8.4.6, Spill: each unit that finds no room becomes an Acorn if the step says "spill".
func summon_placed(step: Dictionary, count: int, golden: bool) -> void:
	var at: String = str(step.get("at", ""))
	var anchor: int = subject_slot if str(step.get("of", "")) == "subject" else source_slot
	var slots: Array[int] = []
	var taken: Array[bool] = player.occupied()
	for _index: int in count:
		var slot: int = BoardGeometry.named_slot(taken, at, anchor, false)
		if slot >= 0:
			taken[slot] = true
			slots.append(slot)
		else:
			var def_id: String = str(step.get("unit", ""))
			var unit_def: Dictionary = rules.library.get_unit(def_id)
			player.log_event("no_room", {"unit": def_id, "name": str(unit_def.get("name", "unit"))})
			if CoreUtil.to_bool(step.get("spill", false)):
				rules.spill(player)
	rules.place_summons(player, str(step.get("unit", "")), golden, slots)


func gain_gold(gold_amount: int, when: String) -> void:
	rules.give_gold(player, gold_amount, when)


func add_card(card: String, count: int, from_pool: bool) -> void:
	for _index: int in count:
		rules.give_card(player, card, from_pool)


func ring_full_at(slot: int) -> bool:
	var rings: Array = player.slot_effects[slot]
	return BoardUpkeep.ring_full(rings, player.card_size_caps and not player.pass3_fairies)


func add_slot_effect(slot: int, step: Dictionary) -> void:
	if str(step.get("name", "")) == BoardUpkeep.RING:
		BoardUpkeep.add_ring(player, slot, step)
		rules.board_changed(player)
		player.log_event("slot_effect", {"slot": slot, "name": BoardUpkeep.RING})
		return
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
	rules.board_changed(player)


func discover(step: Dictionary) -> void:
	rules.discover(player, step)


func add_rule(step: Dictionary) -> void:
	var handler: Dictionary = {
		"query": str(step.get("query", "")),
		"op": str(step.get("op", "add")),
		"value": CoreUtil.to_int(step.get("value", 0)),
		"turn_only": str(step.get("duration", "game")) == "turn",
		"next_turn": str(step.get("duration", "game")) == "next_turn",
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


## Pass: waits for End of Turn. Remembers the source's slot, in case it has gone by then.
func queue_pass(attack: int, health: int) -> void:
	var source_iid: int = (source as RecruitUnit).iid if source != null else 0
	player.pending_passes.append(
		{"iid": source_iid, "slot": source_slot, "attack": attack, "health": health}
	)
	player.log_event("pass_queued", {"slot": source_slot, "attack": attack, "health": health})


func add_timer(target: BoardUnit, turns: int, attack: int, health: int) -> void:
	var unit: RecruitUnit = target
	unit.timers.append({"turns": turns, "left": turns, "attack": attack, "health": health})
	player.log_event("timer", {"target": unit.def_id(), "turns": turns})


func spend_all() -> void:
	amount = player.gold
	rules.spend(player, amount)


func burn_gold(keep: int, most: int = 0) -> void:
	amount = maxi(0, player.gold - keep)
	if most > 0:
		amount = mini(amount, most)
	player.gold -= amount
	player.log_event("burn", {"amount": amount})


func tier_down(climb_back: int = 0) -> void:
	rules.tier_down(player, climb_back)


func upgrade_discount(gold_off: int) -> void:
	player.upgrade_cost = maxi(0, player.upgrade_cost - gold_off)
	player.log_event("rule", {"text": "upgrade_discount", "amount": gold_off})


func rainy_day(win: int, lose: int) -> void:
	player.rainy_win += win
	player.rainy_lose += lose
	player.log_event("rainy_day", {"win": win, "lose": lose})


func borrow(gold_amount: int, repay: int, _health: int = 0, turns: int = 1) -> void:
	player.gold += gold_amount
	player.debt += repay * turns
	player.debt_payment = repay
	player.log_event("borrow", {"gold": gold_amount, "repay": repay})


func bring_home(count: int) -> void:
	HeldUnits.bring_home(rules, player, count)


func refresh_keep() -> void:
	rules.refresh_keeping(player, chosen_slot)


## 8.3.3 from a mechanic: a move into an empty slot or a swap. Mechanics can read and change
## position in the Recruit Phase. Fires on_move like the player's own move.
func move_unit(from_slot: int, to_slot: int) -> void:
	if rules.move_on_board(player, from_slot, to_slot) and from_slot == source_slot:
		source_slot = to_slot


func tribe_bonus(bonus: int) -> void:
	if chosen != null:
		TribeBonus.grant(player, chosen, bonus)
		rules.board_changed(player)


func market_stall() -> void:
	player.market_stalls = (
		mini(MarketStalls.LIMIT, player.market_stalls + 1)
		if player.card_rate_limits
		else player.market_stalls + 1
	)
	MarketStalls.remove_unavailable(rules, player)
	player.log_event("rule", {"text": "market_stall", "value": player.market_stalls})


func flat_gain_percent() -> int:
	if (
		source != null
		or not rules.config.get_bool("scale_hero_spell_stats")
		or CoreUtil.to_bool(card_def.get("fixed_stat_reward", false))
	):
		return 0
	var spell: bool = trigger == "cast" and str(card_def.get("kind", "")) == "spell"
	var hero: bool = trigger != "cast" and not player.hero.is_empty()
	return maxi(0, rules.config.get_int("scale_hero_spell_percent")) if spell or hero else 0
