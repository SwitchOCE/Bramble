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
			"health": CoreUtil.to_int(opp_view.get("health", 0)),
		},
		"message": message,
		"shop_units": _shop(flow, me.shop_units, CoreUtil.to_array(costs["shop_units"]), false),
		"shop_spells": _shop(flow, me.shop_spells, CoreUtil.to_array(costs["shop_spells"]), true),
		"hand": _cards(flow.content, session, CoreUtil.to_array(view["hand"]), []),
		"board":
		_cards(
			flow.content,
			session,
			CoreUtil.to_array(view["board"]),
			CoreUtil.to_array(costs["sell"])
		),
		"slots": slots(flow.content, CoreUtil.to_array(view["slots"])),
		"players": players(flow),
		"legal_actions": view["legal_actions"],
	}
	var options: Array = view["discover"]
	if not options.is_empty():
		var shown: Array = []
		for card_id: Variant in options:
			shown.append(card_from_id(flow.content, session, str(card_id)))
		state["discover"] = {"prompt": "Discover a unit", "options": shown}
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
	return {
		"turn": CoreUtil.to_int(you["round"]),
		"health": CoreUtil.to_int(you["health"]),
		"hero":
		{"name": flow.name_of(GameFlow.HUMAN), "portrait": flow.portrait_of(GameFlow.HUMAN)},
		"players": players(flow),
		"opponent":
		{
			"name": flow.name_of(opponent),
			"portrait": flow.portrait_of(opponent),
			"health": CoreUtil.to_int(them.get("health", 0)),
		},
		"you_side": you_side,
		"slots": side_slots,
		"boards": [[], []],
	}


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
		}
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


## The player's counters and heaps as chips: [{label, value}] under their display names.
static func counters(content: GameContent, view: Dictionary) -> Array:
	var out: Array = []
	var numbers: Dictionary = view.get("counters", {})
	for key: Variant in numbers:
		var label: String = content.display_name(str(key))
		if label != "":
			out.append({"label": label, "value": numbers[key]})
	var heaps: Dictionary = view.get("heaps", {})
	for key: Variant in heaps:
		var label: String = content.display_name(str(key))
		var entries: Array = heaps[key]
		if label != "":
			out.append({"label": label, "value": entries.size()})
	return out


## Seven slot entries: {buff, buff_name} for a slot with a lasting bonus, else {}.
static func slots(content: GameContent, raw: Array) -> Array:
	var out: Array = []
	for i: int in 7:
		var slot: Dictionary = raw[i] if i < raw.size() and raw[i] is Dictionary else {}
		var attack: int = CoreUtil.to_int(slot.get("attack", 0))
		var health: int = CoreUtil.to_int(slot.get("health", 0))
		var words: PackedStringArray = []
		if attack != 0 or health != 0:
			words.append("%+d/%+d" % [attack, health])
		var names: PackedStringArray = []
		for keyword: Variant in slot.get("keywords", []):
			var shown: String = content.display_name(str(keyword))
			if shown != "":
				names.append(shown)
		var marks: Dictionary = slot.get("marks", {})
		for key: Variant in marks:
			var shown: String = content.display_name(str(key))
			if shown != "":
				names.append(shown)
		if words.is_empty() and names.is_empty():
			out.append({})
			continue
		if words.is_empty():
			words.append(names[0])
		out.append({"buff": " ".join(words), "buff_name": names[0] if names.size() > 0 else "Slot"})
	return out


## A card from its id alone (a shop card or a Discover option): its printed numbers and text.
static func card_from_id(content: GameContent, session: GameSession, card_id: String) -> Dictionary:
	var card: UnitDef = content.library.get_card(StringName(card_id))
	if card == null:
		return {}
	var plain: Unit = Unit.create(card, -1, false, content.registry, session.config.stat_max)
	var golden: Unit = Unit.create(card, -1, true, content.registry, session.config.stat_max)
	var out: Dictionary = _unit(content, session, plain.view(), card)
	out["golden_text"] = golden.view()["text"]
	return out


static func _shop(flow: GameFlow, ids: Array[StringName], prices: Array, spell: bool) -> Array:
	var out: Array = []
	for i: int in ids.size():
		if ids[i] == PlayerState.NO_CARD:
			out.append(null)
			continue
		var card: Dictionary = card_from_id(flow.content, flow.session, String(ids[i]))
		card["price"] = CoreUtil.to_int(prices[i]) if i < prices.size() else 0
		if spell:
			card["cost"] = card["price"]
		out.append(card)
	return out


## Held cards (hand or board) from their views; `sell` gives a board slot's sell value.
static func _cards(content: GameContent, session: GameSession, views: Array, sell: Array) -> Array:
	var out: Array = []
	for i: int in views.size():
		if not views[i] is Dictionary:
			out.append(null)
			continue
		var view: Dictionary = views[i]
		var card: UnitDef = content.library.get_card(StringName(str(view["id"])))
		var unit: Dictionary = _unit(content, session, view, card)
		if i < sell.size() and CoreUtil.to_int(sell[i]) >= 0:
			unit["sell_value"] = CoreUtil.to_int(sell[i])
		out.append(unit)
	return out


static func _unit(
	content: GameContent, session: GameSession, view: Dictionary, card: UnitDef
) -> Dictionary:
	var keywords: Array = []
	for keyword: Variant in view.get("keywords", []):
		var shown: String = content.display_name(str(keyword))
		if shown != "":
			keywords.append(shown)
	var numbers: Array = []
	var held: Dictionary = view.get("counters", {})
	for key: Variant in held:
		var label: String = content.display_name(str(key))
		if label != "":
			numbers.append({"label": label, "value": held[key]})
	var golden: bool = CoreUtil.to_bool(view.get("golden", false))
	var health: int = CoreUtil.to_int(view.get("health", card.health))
	var out: Dictionary = {
		"id": str(view.get("id", card.id)),
		"uid": CoreUtil.to_int(view.get("uid", -1)),
		"name": card.name,
		"tier": card.tier,
		"art": content.art_for(String(card.id)),
		"attack": CoreUtil.to_int(view.get("attack", card.attack)),
		"health": health,
		"max_health": health,
		"text": str(view.get("text", card.text)),
		"golden": golden,
		"keywords": keywords,
		"counters": numbers,
		"spell": card.is_spell(),
	}
	if card.is_spell():
		out["cost"] = session.rules.spell_price(session.player(GameFlow.HUMAN), card)
	return out
