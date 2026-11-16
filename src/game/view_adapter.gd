class_name ViewAdapter
extends RefCounted
## Turns the core's views (GameSession.view_for) into the screens' view state
## (docs/ideation-track-2/SCREEN-CONTRACT.md): card names, tiers, text, golden text and art from
## the card data; prices; counters, heaps and slot buffs under their display names; player names
## and portraits; legal_actions passed through as the core gives them.


## The recruit screen's state for the human. `message` is a refusal or notice ("" for none).
static func recruit_state(flow: GameFlow, message: String = "") -> Dictionary:
	var session: GameSession = flow.session
	var me: PlayerState = flow.human()
	var view: Dictionary = session.view_for(GameFlow.HUMAN)
	var costs: Dictionary = view["costs"]
	var upgrade: int = CoreUtil.to_int(costs["upgrade"])
	var opponent: int = CoreUtil.to_int(view["opponent"])
	var opp_view: Dictionary = flow.opponent_view(opponent)
	var upgrade_cost: Variant = null
	if upgrade >= 0:
		upgrade_cost = upgrade
	var state: Dictionary = {
		"turn": CoreUtil.to_int(view["round"]),
		"gold": me.gold,
		"tier": me.tier,
		"refresh_cost": CoreUtil.to_int(costs["refresh"]),
		"upgrade_cost": upgrade_cost,
		"frozen": me.frozen,
		"health": me.health,
		"hand_limit": session.rules.hand_limit(me),
		"hero":
		{"name": flow.name_of(GameFlow.HUMAN), "portrait": flow.portrait_of(GameFlow.HUMAN)},
		"counters": counters(flow.content, view),
		"next_opponent":
		{
			"name": flow.name_of(opponent),
			"portrait": flow.portrait_of(opponent),
			"health": maxi(0, CoreUtil.to_int(opp_view.get("health", 0))),
		},
		"message": message,
		"shop_units": _shop(flow, me.shop_units, CoreUtil.to_array(costs["shop_units"]), false),
		"shop_spells": _shop(flow, me.shop_spells, CoreUtil.to_array(costs["shop_spells"]), true),
		"hand": _cards(flow, CoreUtil.to_array(view["hand"]), []),
		"board": _cards(flow, CoreUtil.to_array(view["board"]), CoreUtil.to_array(costs["sell"])),
		"slots": slots(flow.content, CoreUtil.to_array(view["slots"])),
		"players": players(flow),
		"legal_actions": view["legal_actions"],
		"display": flow.content.display_table(),
	}
	var open: Dictionary = discover(flow, view)
	if not open.is_empty():
		state["discover"] = open
	return state


## The fight screen's state around the human's fight (FightReplay.build replaces its boards).
static func fight_base(flow: GameFlow, fight: Dictionary) -> Dictionary:
	var before: Dictionary = fight["before"]
	var you: Dictionary = before["you"]
	var them: Dictionary = before["opponent"]
	var you_side: int = CoreUtil.to_int(fight["you_side"])
	var opponent: int = CoreUtil.to_int(fight["opponent"])
	var side_slots: Array = [[], []]
	side_slots[you_side] = slots(flow.content, CoreUtil.to_array(you["slots"]))
	side_slots[1 - you_side] = slots(flow.content, CoreUtil.to_array(them.get("slots", [])))
	var reserve: Array = [[], []]
	var events: Array = CoreUtil.to_array(fight.get("events", []))
	var start: Dictionary = CoreUtil.to_dict(events[0]) if not events.is_empty() else {}
	if str(start.get("type", "")) == "combat_start":
		# the slots as the fight has them (both sides' slot effects copied in), and each hand's
		# Reserve units, so a unit stepping in has a card to draw
		var fight_slots: Array = CoreUtil.to_array(start.get("slots", []))
		var waiting: Array = CoreUtil.to_array(start.get("reserve", []))
		for side: int in 2:
			if side < fight_slots.size():
				side_slots[side] = slots(flow.content, CoreUtil.to_array(fight_slots[side]))
			if side < waiting.size():
				for view: Variant in CoreUtil.to_array(waiting[side]):
					var list: Array = reserve[side]
					list.append(fight_unit(flow.content, CoreUtil.to_dict(view)))
	return {
		"turn": CoreUtil.to_int(you["round"]),
		"health": CoreUtil.to_int(you["health"]),
		"hero":
		{"name": flow.name_of(GameFlow.HUMAN), "portrait": flow.portrait_of(GameFlow.HUMAN)},
		"players": players(flow),
		"counters": counters(flow.content, you),
		"opponent":
		{
			"name": flow.name_of(opponent),
			"portrait": flow.portrait_of(opponent),
			"health": maxi(0, CoreUtil.to_int(them.get("health", 0))),
		},
		"you_side": you_side,
		"slots": side_slots,
		"reserve": reserve,
		"boards": [[], []],
		"display": flow.content.display_table(),
	}


## A unit from a fight log's unit view, as a card entry: {id, uid, side, slot, name, tier, art,
## text, attack, health, max_health, golden, keywords (display names), counters}.
static func fight_unit(content: GameContent, view: Dictionary) -> Dictionary:
	var card_id: String = str(view.get("id", ""))
	var card: UnitDef = content.library.get_card(StringName(card_id))
	var keywords: Array = []
	for keyword: Variant in CoreUtil.to_array(view.get("keywords", [])):
		var shown: String = content.display_name(str(keyword))
		if shown != "":
			keywords.append(shown)
	# a fight's uses left ("Privates left") show like counters
	var counters_held: Dictionary = CoreUtil.to_dict(view.get("counters", {})).merged(
		CoreUtil.to_dict(view.get("uses", {}))
	)
	var numbers: Array = []
	for key: Variant in counters_held:
		var label: String = content.display_name(str(key))
		if label != "":
			var value: Variant = counters_held[key]
			numbers.append({"id": str(key), "key": str(key), "label": label, "value": value})
	var health: int = CoreUtil.to_int(view.get("health", 0))
	var text: String = str(view.get("text", card.text if card != null else ""))
	return {
		"mechanics": mechanic_ids(content, card_id, view),
		"reminders": content.reminders_for(card_id, text),
		"id": card_id,
		"uid": CoreUtil.to_int(view.get("uid", -1)),
		"side": CoreUtil.to_int(view.get("side", 0)),
		"slot": CoreUtil.to_int(view.get("slot", -1)),
		"name": card.name if card != null else card_id,
		"tier": card.tier if card != null else 1,
		"art": content.art_for(card_id),
		"text": text,
		"attack": CoreUtil.to_int(view.get("attack", 0)),
		"health": health,
		"max_health": health,
		"golden": CoreUtil.to_bool(view.get("golden", false)),
		"keywords": keywords,
		"counters": numbers,
	}


## The fight log as FightReplay reads it. A Reserve unit stepping in from the hand (`reserve`) is
## a unit view entering a slot, the same shape as a `summon`, so it is passed on as one; a
## replay that does not know `reserve` would otherwise leave that unit off the board while it
## fights. Everything else passes unchanged.
static func replay_events(events: Array) -> Array:
	var out: Array = []
	for value: Variant in events:
		var event: Dictionary = CoreUtil.to_dict(value)
		if str(event.get("type", "")) == "reserve":
			event = event.duplicate()
			event["type"] = "summon"
			event["reserve"] = true
		out.append(event)
	return out


## Gold `side` earned in a fight log, paid at the start of the next turn.
static func fight_gold(events: Array, side: int) -> int:
	var total: int = 0
	for value: Variant in events:
		var event: Dictionary = CoreUtil.to_dict(value)
		if str(event.get("type", "")) == "gold" and CoreUtil.to_int(event.get("side", -1)) == side:
			total += CoreUtil.to_int(event.get("amount", 0))
	return total


## What a fight log does not carry, by card id, for FightReplay: {name, tier, art, text, health}.
static func catalog(content: GameContent) -> Dictionary:
	var out: Dictionary = {}
	for card_id: StringName in content.library.ids():
		var card: UnitDef = content.library.get_card(card_id)
		out[String(card_id)] = {
			"name": card.name,
			"tier": card.tier,
			"art": content.art_for(String(card_id)),
			"text": card.text,
			"health": card.health,
			"mechanics": content.mechanics_of(String(card_id)),
			"reminders": content.reminders_for(String(card_id), card.text),
		}
	return out


## The mechanic ids a card shows terms for: what it prints, what it was given since (a view's
## `effects` and `grants`), and its keywords.
static func mechanic_ids(content: GameContent, card_id: String, view: Dictionary) -> Array:
	var out: Array = content.mechanics_of(card_id)
	for key: String in ["effects", "grants"]:
		for value: Variant in CoreUtil.to_array(view.get(key, [])):
			var mechanic: String = str(CoreUtil.to_dict(value).get("mechanic", ""))
			if mechanic != "" and not out.has(mechanic):
				out.append(mechanic)
	return out


## The leaderboard: living players by Health, then the eliminated by place.
static func players(flow: GameFlow) -> Array:
	var session: GameSession = flow.session
	var rows: Array[PlayerState] = session.players.duplicate()
	rows.sort_custom(
		func(x: PlayerState, y: PlayerState) -> bool:
			if x.alive != y.alive:
				return x.alive
			if not x.alive:
				return x.placement < y.placement
			if x.health != y.health:
				return x.health > y.health
			return x.id < y.id
	)
	var next: int = session.opponent_of(GameFlow.HUMAN)
	var out: Array = []
	for each: PlayerState in rows:
		(
			out
			. append(
				{
					"name": flow.name_of(each.id),
					"portrait": flow.portrait_of(each.id),
					"health": maxi(0, each.health),
					"tier": each.tier,
					"you": each.id == GameFlow.HUMAN,
					"next": each.id == next,
					"alive": each.alive,
				}
			)
		)
	return out


## The player's counters and heaps as chips: [{id, value}] for every id the display table shows
## (no entry or `hidden` leaves it out). Each chip also carries `key` and `label` (the display
## name) for screens that read those, `icon` when the glass pieces have that emblem
## (assets/glass/ui/tr-<icon>.png), and a heap chip its `entries` [{id, name, tier}].
static func counters(content: GameContent, view: Dictionary) -> Array:
	var out: Array = []
	var numbers: Dictionary = view.get("counters", {})
	for key: Variant in numbers:
		var chip: Dictionary = _chip(content, str(key), numbers[key])
		if not chip.is_empty():
			out.append(chip)
	var heaps: Dictionary = view.get("heaps", {})
	for key: Variant in heaps:
		var raw: Array = CoreUtil.to_array(heaps[key])
		var chip: Dictionary = _chip(content, str(key), raw.size())
		if chip.is_empty():
			continue
		var entries: Array = []
		for value: Variant in raw:
			var entry: Dictionary = CoreUtil.to_dict(value)
			var entry_id: String = str(entry.get("id", ""))
			var card: UnitDef = content.library.get_card(StringName(entry_id))
			var tier: int = card.tier if card != null else 1
			(
				entries
				. append(
					{
						"id": entry_id,
						"name": card.name if card != null else entry_id,
						"tier": CoreUtil.to_int(entry.get("tier", tier)),
					}
				)
			)
		chip["entries"] = entries
		out.append(chip)
	return out


static func _chip(content: GameContent, key: String, value: Variant) -> Dictionary:
	var label: String = content.display_name(key)
	if label == "":
		return {}
	var chip: Dictionary = {"id": key, "key": key, "label": label, "value": value}
	var icon: String = content.icon(key)
	if icon != "" and ResourceLoader.exists("res://assets/glass/ui/tr-%s.png" % icon):
		chip["icon"] = icon
	return chip


## Seven slot entries: {attack, health, keywords [{id}], label} for a slot with a lasting bonus,
## else {}. `label` is the first shown keyword's or mark's display name ("" for numbers only).
## `buff` ("+2/+1"), `buff_name` and `names` are kept for screens that read those.
static func slots(content: GameContent, raw: Array) -> Array:
	var out: Array = []
	for i: int in 7:
		var slot: Dictionary = raw[i] if i < raw.size() and raw[i] is Dictionary else {}
		var attack: int = CoreUtil.to_int(slot.get("attack", 0))
		var health: int = CoreUtil.to_int(slot.get("health", 0))
		var ids: Array = []
		var names: Array = []
		var marks: Dictionary = CoreUtil.to_dict(slot.get("marks", {}))
		for key: Variant in CoreUtil.to_array(slot.get("keywords", [])) + marks.keys():
			var shown: String = content.display_name(str(key))
			if shown != "":
				ids.append({"id": str(key)})
				names.append(shown)
		if attack == 0 and health == 0 and ids.is_empty():
			out.append({})
			continue
		var label: String = str(names[0]) if names.size() > 0 else ""
		var buff: String = "%+d/%+d" % [attack, health] if attack != 0 or health != 0 else label
		(
			out
			. append(
				{
					"attack": attack,
					"health": health,
					"keywords": ids,
					"label": label,
					"buff": buff,
					"buff_name": label if label != "" else "Slot",
					"names": names,
				}
			)
		)
	return out


## A card from its id alone (a shop card or a Discover option): its printed numbers and text.
static func card_from_id(content: GameContent, session: GameSession, card_id: String) -> Dictionary:
	var card: UnitDef = content.library.get_card(StringName(card_id))
	if card == null:
		return {}
	var plain: Unit = Unit.create(card, -1, false, content.registry, session.config.stat_max)
	return _unit(content, session, plain.view(), card, plain)


## The core's target kinds by the contract's names.
static func target_kind(kind: Mechanic.Target) -> String:
	var out: String = "none"
	match kind:
		Mechanic.Target.FRIENDLY_UNIT:
			out = "unit"
		Mechanic.Target.SLOT:
			out = "slot"
		Mechanic.Target.SHOP_UNIT:
			out = "shop"
	return out


## A board unit's activated abilities (3.3.1): [{id, name, text, cost, uses_left, usable,
## target_kind}], from its bound mechanics; `usable` is the core's own test (gold, uses, a target).
static func abilities(
	content: GameContent, session: GameSession, player: PlayerState, unit: Unit
) -> Array:
	var out: Array = []
	if unit == null:
		return out
	for bound: BoundMechanic in unit.hooks():
		if not bound.mechanic.has_ability():
			continue
		var mechanic_id: String = String(bound.id)
		# the core counts uses under "ability:<id>" in the unit's turn counters (Recruit)
		var used: int = unit.turn_counter(StringName("ability:%s" % mechanic_id))
		var usable: bool = (
			unit.slot >= 0 and session.recruit.ability_error(player, unit, bound) == ""
		)
		# "Order (N)", "pay N gold": N is the ability's cost, never shown as a letter
		var cost: int = bound.mechanic.ability_cost(bound.params)
		(
			out
			. append(
				{
					"id": mechanic_id,
					"name": CardTerms.fill(content.display_name(mechanic_id), str(cost)),
					"text": CardTerms.fill(content.reminder(mechanic_id), str(cost)),
					"cost": cost,
					"uses_left": maxi(0, bound.mechanic.ability_uses(bound.params) - used),
					"usable": usable,
					"target_kind": target_kind(bound.mechanic.ability_target(bound.params)),
				}
			)
		)
	return out


## The Discover the player has open: {prompt, options (full unit or spell entries), waiting}, or
## {} with none.
static func discover(flow: GameFlow, view: Dictionary) -> Dictionary:
	var options: Array = CoreUtil.to_array(view.get("discover", []))
	if options.is_empty():
		return {}
	var shown: Array = []
	var spells: bool = true
	for card_id: Variant in options:
		var entry: Dictionary = card_from_id(flow.content, flow.session, str(card_id))
		spells = spells and CoreUtil.to_bool(entry.get("spell", false))
		shown.append(entry)
	return {
		"prompt": "Discover a spell" if spells else "Discover a unit",
		"options": shown,
		"waiting": CoreUtil.to_int(view.get("discovers_waiting", 0)),
	}


static func _shop(flow: GameFlow, ids: Array[StringName], prices: Array, spell: bool) -> Array:
	var out: Array = []
	for i: int in ids.size():
		if ids[i] == PlayerState.NO_CARD:
			out.append(null)
			continue
		var card: Dictionary = card_from_id(flow.content, flow.session, String(ids[i]))
		var price: int = CoreUtil.to_int(prices[i]) if i < prices.size() else 0
		# a spell has only its cost; a unit its price
		card["cost" if spell else "price"] = price
		out.append(card)
	return out


## Held cards (hand or board) from their views; `sell` gives a board slot's sell value.
static func _cards(flow: GameFlow, views: Array, sell: Array) -> Array:
	var out: Array = []
	var me: PlayerState = flow.human()
	for i: int in views.size():
		if not views[i] is Dictionary:
			out.append(null)
			continue
		var view: Dictionary = views[i]
		var card: UnitDef = flow.content.library.get_card(StringName(str(view["id"])))
		var held: Unit = me.find_uid(CoreUtil.to_int(view.get("uid", -1)))
		var unit: Dictionary = _unit(flow.content, flow.session, view, card, held)
		if i < sell.size() and CoreUtil.to_int(sell[i]) >= 0:
			unit["sell_value"] = CoreUtil.to_int(sell[i])
		if held != null and held.slot >= 0:
			unit["abilities"] = abilities(flow.content, flow.session, me, held)
		out.append(unit)
	return out


## One card entry. A spell: {id, uid, name, art, cost, text, spell, kind, target_kind}; a unit
## adds tier, Attack, Health, golden, keywords (display names; hidden ones left out), counters
## [{id, key, label, value}] and golden_text.
static func _unit(
	content: GameContent, session: GameSession, view: Dictionary, card: UnitDef, held: Unit
) -> Dictionary:
	var card_id: String = String(card.id)
	var out: Dictionary = {
		"id": str(view.get("id", card_id)),
		"uid": CoreUtil.to_int(view.get("uid", -1)),
		"name": card.name,
		"art": content.art_for(card_id),
		"text": str(view.get("text", card.text)),
		"spell": card.is_spell(),
		"target_kind": "none",
	}
	if held != null:
		out["target_kind"] = target_kind(session.recruit.play_target_of(held))
	if str(out["text"]) == "":
		out["text"] = content.text_for(card_id)
	out["mechanics"] = mechanic_ids(content, card_id, view)
	out["reminders"] = content.reminders_for(card_id, str(out["text"]))
	if card.is_spell():
		out["kind"] = "spell"
		out["cost"] = session.rules.spell_price(session.player(GameFlow.HUMAN), card)
		return out
	var keywords: Array = []
	for keyword: Variant in view.get("keywords", []):
		var shown: String = content.display_name(str(keyword))
		if shown != "":
			keywords.append(shown)
	var numbers: Array = []
	var counters_held: Dictionary = view.get("counters", {})
	for key: Variant in counters_held:
		var label: String = content.display_name(str(key))
		if label != "":
			var value: Variant = counters_held[key]
			numbers.append({"id": str(key), "key": str(key), "label": label, "value": value})
	var health: int = CoreUtil.to_int(view.get("health", card.health))
	(
		out
		. merge(
			{
				"kind": "unit",
				"tier": card.tier,
				"attack": CoreUtil.to_int(view.get("attack", card.attack)),
				"health": health,
				"max_health": health,
				"golden": CoreUtil.to_bool(view.get("golden", false)),
				"keywords": keywords,
				"counters": numbers,
				"golden_text": _golden_text(content, session, card),
			}
		)
	)
	return out


## A card's golden text: the design's hand-written `golden` line when the card data has one,
## else the core's text with its numbers doubled (7.3.5).
static func _golden_text(content: GameContent, session: GameSession, card: UnitDef) -> String:
	var written: String = content.golden_for(String(card.id))
	if written != "":
		return written
	var golden: Unit = Unit.create(card, -1, true, content.registry, session.config.stat_max)
	return str(golden.view()["text"])
