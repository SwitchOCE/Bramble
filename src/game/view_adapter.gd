class_name ViewAdapter
extends RefCounted
## Turns the core's views (GameSession.view_for) into the screens' view state
## (docs/ideation-track-2/SCREEN-CONTRACT.md): card names, tiers and art from the card data, the
## core's own text (a golden's included); prices; counters, heaps, keywords and slot buffs by id,
## with the display table that names them; player names and portraits; legal_actions passed
## through as the core gives them.

## STAND-IN: the words on an ability button whose ability has no display name.
const ABILITY_WORD: String = "Use"


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
	var events: Array = CoreUtil.to_array(fight.get("events", []))
	var start: Dictionary = CoreUtil.to_dict(events[0]) if not events.is_empty() else {}
	if str(start.get("type", "")) == "combat_start":
		# the slots as the fight has them (both sides' slot effects copied in); a Reserve unit
		# stepping in is placed by the replay from its own `reserve` event
		var fight_slots: Array = CoreUtil.to_array(start.get("slots", []))
		for side: int in mini(2, fight_slots.size()):
			side_slots[side] = slots(flow.content, CoreUtil.to_array(fight_slots[side]))
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
		"boards": [[], []],
		"display": flow.content.display_table(),
	}


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
			"attack": card.attack,
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
## (no entry or `hidden` leaves it out); a heap chip also carries its `entries` [{id, name, tier}].
## The display table gives each its name, reminder and emblem.
static func counters(content: GameContent, view: Dictionary) -> Array:
	var out: Array = []
	var numbers: Dictionary = view.get("counters", {})
	for key: Variant in numbers:
		if content.display_name(str(key)) != "":
			out.append({"id": str(key), "value": numbers[key]})
	var heaps: Dictionary = view.get("heaps", {})
	for key: Variant in heaps:
		if content.display_name(str(key)) == "":
			continue
		var raw: Array = CoreUtil.to_array(heaps[key])
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
		out.append({"id": str(key), "value": raw.size(), "entries": entries})
	return out


## Seven slot entries (FightReplay.slot_entry, one converter for both screens): {attack, health,
## keywords [{id}], label, percent} for a slot with a lasting bonus, else {}. `label` is the first
## shown keyword's or mark's display name ("" for numbers only).
static func slots(content: GameContent, raw: Array) -> Array:
	var out: Array = []
	for i: int in 7:
		var slot: Dictionary = raw[i] if i < raw.size() and raw[i] is Dictionary else {}
		var entry: Dictionary = FightReplay.slot_entry(slot)
		if not entry.is_empty():
			entry["label"] = ""
			for keyword: Variant in entry["keywords"]:
				var shown: String = content.display_name(str(CoreUtil.to_dict(keyword)["id"]))
				if shown != "":
					entry["label"] = shown
					break
		out.append(entry)
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


## A board unit's activated abilities (3.3.1): [{id, name, cost, usable, target_kind}], from its
## bound mechanics; `usable` is the core's own test (gold, uses, a target). The name is the
## display table's with its N filled from the cost ("Order (1)"); with no display name, "Use".
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
		var usable: bool = (
			unit.slot >= 0 and session.recruit.ability_error(player, unit, bound) == ""
		)
		# "Order (N)", "pay N gold": N is the ability's cost, never shown as a letter
		var cost: int = bound.mechanic.ability_cost(bound.params)
		var shown: String = content.display_name(mechanic_id)
		if shown == "":
			# STAND-IN: an ability its content leaves unnamed still gets words on its button
			shown = ABILITY_WORD
		(
			out
			. append(
				{
					"id": mechanic_id,
					"name": CardTerms.fill(shown, str(cost)),
					"cost": cost,
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
			var sources: Array = stat_sources(held)
			if not sources.is_empty():
				unit["sources"] = sources
		out.append(unit)
	return out


## One card entry. A spell: {id, uid, name, art, cost, text, spell, target_kind, mechanics,
## reminders}; a unit adds tier, Attack, Health, golden, keywords [id], counters [{id, value}],
## amounts {mechanic id: summed number} and its printed numbers. Its text is the core's view
## text, a golden's own.
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
		out["cost"] = session.rules.spell_price(session.player(GameFlow.HUMAN), card)
		return out
	var numbers: Array = []
	var counters_held: Dictionary = view.get("counters", {})
	for key: Variant in counters_held:
		numbers.append({"id": str(key), "value": counters_held[key]})
	var health: int = CoreUtil.to_int(view.get("health", card.health))
	var golden: int = 2 if CoreUtil.to_bool(view.get("golden", false)) else 1
	(
		out
		. merge(
			{
				"tier": card.tier,
				"attack": CoreUtil.to_int(view.get("attack", card.attack)),
				"health": health,
				"max_health": health,
				"golden": CoreUtil.to_bool(view.get("golden", false)),
				"keywords": CoreUtil.to_array(view.get("keywords", [])).map(
					func(id: Variant) -> String: return str(id)
				),
				"counters": numbers,
				"amounts": amounts(view),
				"base_attack": held.stats.base_attack if held != null else card.attack * golden,
				"base_health": held.stats.base_health if held != null else card.health * golden,
			}
		)
	)
	return out


## Each numbered mechanic's shown number on a unit view ({id: n}), from the core's `totals`:
## what it prints and what it was given since ("Fury" 1 + 1 given = 2).
static func amounts(view: Dictionary) -> Dictionary:
	return CardTerms.amounts(CoreUtil.to_dict(view.get("totals", {})))


## STAND-IN words (polish.html .src): where a board unit's numbers come from when they differ
## from what it prints: "Its own 6/5." and "From other units +0/+8." (auras, lent stats) and
## "From its slot +2/+0."; nothing when they are its printed numbers.
static func stat_sources(held: Unit) -> Array:
	var stats: StatBlock = held.stats
	if held.attack() == stats.base_attack and held.health() == stats.base_health:
		return []
	var out: Array = ["Its own %d/%d." % [stats.own_attack(), stats.own_health()]]
	if stats.aura_attack != 0 or stats.aura_health != 0:
		out.append("From other units %s." % _plus(stats.aura_attack, stats.aura_health))
	if stats.slot_attack != 0 or stats.slot_health != 0:
		out.append("From its slot %s." % _plus(stats.slot_attack, stats.slot_health))
	return out


static func _plus(attack: int, health: int) -> String:
	return "%s%d/%s%d" % ["+" if attack >= 0 else "", attack, "+" if health >= 0 else "", health]
