class_name ViewAdapter
extends RefCounted
## Turns the core's views (GameSession.view_for) into the screens' view state
## (docs/ideation-track-2/SCREEN-CONTRACT.md): card names, tiers and art from the card data, the
## core's own text (a golden's included); prices; counters, heaps, keywords and slot buffs by id,
## with the display table that names them; player names and portraits; legal_actions passed
## through as the core gives them.

## STAND-IN: an ability that costs no gold says so on its button ("Bury (free)").
const FREE: String = "free"


## The recruit screen's state for the human. `message` is a refusal or notice ("" for none).
## `events`: the game log's events from the player's last action, for `leaving` (see leaving).
static func recruit_state(flow: GameFlow, message: String = "", events: Array = []) -> Dictionary:
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
		"refreshes_left": CoreUtil.to_int(view["refreshes_left"]),
		"upgrade_cost": upgrade_cost,
		"frozen": me.frozen,
		"health": maxi(0, me.health),
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
	state.merge(_triple_state(flow, events))
	var open: Dictionary = discover(flow, view)
	if not open.is_empty():
		state["discover"] = open
	var gone: Dictionary = leaving(flow, events)
	if not gone.is_empty():
		state["leaving"] = gone
	return state


## Presentation evidence, without changing the core log. Summons include a full unit view;
## buy/pick/gain name the arriving copy, whose printed entry is the available starting data.
## Absolute buff/stat updates are retained by UID, including copies drawn in the old state.
## Keep the first origin for a UID (a later gain must not erase its Discover/purchase origin).
static func _triple_state(flow: GameFlow, events: Array) -> Dictionary:
	var uids: Array[int] = []
	var normals: Dictionary = {}
	var stats: Dictionary = {}
	var arrivals: Dictionary = {}
	for value: Variant in events:
		var event: Dictionary = CoreUtil.to_dict(value)
		if CoreUtil.to_int(event.get("player", -1)) != GameFlow.HUMAN:
			continue
		var kind: String = str(event.get("type", ""))
		var id: String = str(event.get("id", ""))
		var uid: int = CoreUtil.to_int(event.get("uid", -1))
		if uid >= 0 and event.has("attack") and event.has("health"):
			stats[str(uid)] = {"attack": event["attack"], "health": event["health"]}
		if kind == "triple":
			uids.append(uid)
			normals[id] = card_from_id(flow.content, flow.session, id)
		elif kind in ["buy", "pick", "summon", "gain"] and uid >= 0:
			var arrival: Dictionary = arrivals.get(uid, {})
			if arrival.is_empty():
				arrival = {"kind": kind, "card": card_from_id(flow.content, flow.session, id)}
			if event.has("attack") and event.has("health"):
				var definition: UnitDef = flow.content.library.get_card(StringName(id))
				if definition != null:
					arrival["card"] = _unit(flow.content, flow.session, event, definition, null)
					arrival["logged_stats"] = true
			var card: Dictionary = arrival["card"]
			card["uid"] = uid
			arrivals[uid] = arrival
	if uids.is_empty():
		return {}
	return {
		"triple_uids": uids,
		"triple_arrivals": arrivals.values(),
		"triple_normals": normals,
		"triple_stats": stats
	}


## Where cards that left in the last action went, so the screen can move them there as they go:
## {card id: {to: "unit", uid} (a sold unit eaten: a trigger whose display icon is "eat" right
## after the sale) or {to: "heap", id} (a card put in a heap: Bury, a sold Seed)}.
static func leaving(flow: GameFlow, events: Array) -> Dictionary:
	var out: Dictionary = {}
	var sold: String = ""
	for value: Variant in events:
		var event: Dictionary = CoreUtil.to_dict(value)
		if CoreUtil.to_int(event.get("player", GameFlow.HUMAN)) != GameFlow.HUMAN:
			continue
		match str(event.get("type", "")):
			"sell":
				sold = str(event.get("id", ""))
			"trigger":
				if sold != "" and flow.content.icon(str(event.get("mechanic", ""))) == "eat":
					out[sold] = {"to": "unit", "uid": CoreUtil.to_int(event.get("uid", -1))}
					sold = ""
			"heap_add":
				var card_id: String = str(event.get("id", ""))
				if not out.has(card_id):
					out[card_id] = {"to": "heap", "id": str(event.get("heap", ""))}
	return out


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
		"health": maxi(0, CoreUtil.to_int(you["health"])),
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
		"recruit_sources": before.get("sources", {}),
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
		out[String(card_id)] = _heap_card(content, String(card_id))
	return out


## Heaps keep card identities, not buffed/golden instances: show their plain printed cards.
## Build detached presentation data without allocating a live UID, touching the pool or RNG.
static func _heap_card(content: GameContent, card_id: String) -> Dictionary:
	var card: UnitDef = content.library.get_card(StringName(card_id))
	if card == null:
		return {"id": card_id, "name": card_id, "tier": 1}
	var plain: Unit = Unit.create(card, -1, false, content.registry, GameConfig.new().stat_max)
	var view: Dictionary = plain.view()
	return {
		"id": card_id,
		"name": card.name,
		"tier": card.tier,
		"art": content.art_for(String(card_id)),
		"text": str(view["text"]),
		"attack": card.attack,
		"health": card.health,
		"mechanics": content.mechanics_of(String(card_id)),
		"reminders": content.reminders_for(String(card_id), card.text),
		"keywords": Array(plain.keyword_ids()),
		"amounts": amounts(view),
	}


## The mechanic ids a card shows terms for (CardTerms.unit_terms, the fight's reading too).
static func mechanic_ids(content: GameContent, card_id: String, view: Dictionary) -> Array:
	return CardTerms.unit_terms(content.mechanics_of(card_id), view)["mechanics"]


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
## (no entry or `hidden` leaves it out); a heap chip carries detached plain cards in `entries`,
## oldest first, matching CardHeap.view().
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
			var shown: Dictionary = _heap_card(content, entry_id)
			shown["tier"] = CoreUtil.to_int(entry.get("tier", tier))
			entries.append(shown)
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


## A board unit's activated abilities (3.3.1): [{id, name, cost, usable, target_kind, reminder}],
## from its bound mechanics; `usable` is the core's own test (gold, uses, a target). The name is
## the display table's with its N filled from the cost ("Order (1)"); a name with no N gets the
## cost after it ("Bury (1)"), so every button shows its cost. `reminder` is what it does, for the
## button's own hover. An ability with no display name has an empty name (a content bug the tests
## catch), never made-up words.


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
		var words: String = CardTerms.fill(shown, str(cost))
		if shown != "" and not CardTerms.has_n(shown):
			words = "%s (%s)" % [shown, str(cost) if cost > 0 else FREE]
		(
			out
			. append(
				{
					"id": mechanic_id,
					"name": words,
					"reminder": CardTerms.fill(content.reminder(mechanic_id), str(cost)),
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
			var sources: Array = stat_sources(flow.content, flow.session, me, held)
			if not sources.is_empty():
				unit["sources"] = sources
		out.append(unit)
	return out


## One card entry. A spell: {id, uid, name, art, cost, text, spell, target_kind, mechanics,
## reminders}; a unit adds tier, combines, Attack, Health, golden, keywords [id],
## counters [{id, value}], amounts {mechanic id: summed number} and its printed numbers.
## Board entries also show the slot bonuses (slot_attack, slot_health).
## Its text is the core's view text, including a golden's own.
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
	out.merge(
		{
			"tier": card.tier,
			"combines": card.combines,
			"attack": CoreUtil.to_int(view.get("attack", card.attack)),
			"health": health,
			"max_health": health,
			"golden": CoreUtil.to_bool(view.get("golden", false)),
			"keywords":
			CoreUtil.to_array(view.get("keywords", [])).map(
				func(id: Variant) -> String: return str(id)
			),
			"counters": numbers,
			"amounts": amounts(view),
			"base_attack": held.stats.base_attack if held != null else card.attack * golden,
			"base_health": held.stats.base_health if held != null else card.health * golden,
			"slot_attack": held.stats.slot_attack if held != null else 0,
			"slot_health": held.stats.slot_health if held != null else 0,
		}
	)
	return out


## Each numbered mechanic's shown number on a unit view ({id: n}), from the core's `totals`:
## what it prints and what it was given since ("Fury" 1 + 1 given = 2).
static func amounts(view: Dictionary) -> Dictionary:
	return CardTerms.unit_terms([], view)["amounts"]


## STAND-IN words (polish.html .src): where a board unit's numbers come from when they differ
## from what it prints, each part named: "Printed 4/9.", "Buffs +0/+2 from Drill Sergeant." (its
## own gains, by the units the game log names as their source), each aura by the unit that gives
## it or the counter it reads ("Tide +2/+0.", "Medal +1/+1."), and "Its slot +2/+0." (with the
## slot's name when it has one). Nothing when they are its printed numbers.
static func stat_sources(
	content: GameContent, session: GameSession, player: PlayerState, held: Unit
) -> Array:
	var stats: StatBlock = held.stats
	if held.attack() == stats.base_attack and held.health() == stats.base_health:
		return []
	var out: Array = ["Printed %d/%d." % [stats.base_attack, stats.base_health]]
	var own: Vector2i = Vector2i(
		stats.own_attack() - stats.base_attack, stats.own_health() - stats.base_health
	)
	if own != Vector2i.ZERO:
		var names: PackedStringArray = _buff_sources(session, held)
		var from: String = " from %s" % ", ".join(names) if not names.is_empty() else ""
		out.append("Buffs %s%s." % [_plus(own.x, own.y), from])
	var aura: Vector2i = Vector2i(stats.aura_attack, stats.aura_health)
	if aura != Vector2i.ZERO:
		var named: Vector2i = Vector2i.ZERO
		for part: Dictionary in _aura_parts(content, session, player, held.def, held.slot, held):
			var gain: Vector2i = part["gain"]
			named += gain
			out.append("%s %s." % [part["name"], _plus(gain.x, gain.y)])
		if named != aura:
			out.append("Other units %s." % _plus(aura.x - named.x, aura.y - named.y))
	if stats.slot_attack != 0 or stats.slot_health != 0:
		var label: String = ""
		for keyword: StringName in player.slots[held.slot].keywords:
			label = content.display_name(String(keyword))
			if label != "":
				break
		var slot_words: String = "Its slot (%s)" % label if label != "" else "Its slot"
		out.append("%s %s." % [slot_words, _plus(stats.slot_attack, stats.slot_health)])
	return out


## Each aura a unit (`def` in `slot`; `held` when it is on the board) gets, named: by the unit
## giving it, or, for one read from a counter (the Tide, a Medal), by that counter, found by
## reading the aura again with the counter at 0. [{name, gain: Vector2i}], zero gains left out.
static func _aura_parts(
	content: GameContent,
	session: GameSession,
	player: PlayerState,
	def: UnitDef,
	slot: int,
	held: Unit
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var view: AuraContext = _aura_view(session, player, def, slot, held)
	var sources: Array[Dictionary] = []
	for source: Unit in player.board_units():
		for bound: BoundMechanic in source.mechanics:
			if bound.mechanic.has_aura():
				sources.append({"bound": bound, "slot": source.slot, "unit": source})
	for bound: BoundMechanic in player.standing:
		if bound.mechanic.has_aura():
			sources.append({"bound": bound, "slot": -1, "unit": null})
	for source: Dictionary in sources:
		var bound: BoundMechanic = source["bound"]
		var from: int = source["slot"]
		var gain: Vector2i = bound.mechanic.aura(view, from, slot, bound.params)
		if gain == Vector2i.ZERO:
			continue
		var giver: Unit = source["unit"]
		# split by the counters it reads: the Tide, the Hopper bonus, a Medal
		var rest: Vector2i = gain
		for key: Variant in player.counters.keys() + view.unit_counters[slot].keys():
			var shown: String = content.display_name(str(key))
			if shown == "":
				continue
			var player_number: bool = player.counters.has(key)
			var saved: Variant = (
				view.counters[key] if player_number else view.unit_counters[slot][key]
			)
			if player_number:
				view.counters[key] = 0
			else:
				view.unit_counters[slot][key] = 0
			var without: Vector2i = bound.mechanic.aura(view, from, slot, bound.params)
			if player_number:
				view.counters[key] = saved
			else:
				view.unit_counters[slot][key] = saved
			var part: Vector2i = gain - without
			if part != Vector2i.ZERO:
				out.append({"name": shown, "gain": part})
				rest -= part
		if rest == Vector2i.ZERO:
			continue
		var named: String = ""
		if giver != null:
			named = giver.def.name if giver != held else content.display_name(String(bound.id))
		if named == "":
			named = content.display_name(String(bound.id))
		out.append({"name": named if named != "" else "Other units", "gain": rest})
	return out


## The aura view the core builds for a player's board (Recruit._aura_pass), with `def` in `slot`.
static func _aura_view(
	session: GameSession, player: PlayerState, def: UnitDef, slot: int, held: Unit
) -> AuraContext:
	var view := AuraContext.new()
	view.geometry = session.geometry
	view.counters = player.counters.duplicate()
	view.heaps = player.heaps
	var count: int = session.geometry.slot_count
	view.defs.resize(count)
	view.unit_counters.resize(count)
	view.stats.resize(count)
	for i: int in count:
		view.unit_counters[i] = {}
	for unit: Unit in player.board_units():
		view.defs[unit.slot] = unit.def
		view.unit_counters[unit.slot] = unit.counters.duplicate()
		view.stats[unit.slot] = Vector3i(unit.attack(), unit.health(), unit.health())
	if held == null and slot >= 0 and slot < count:
		view.defs[slot] = def
		view.unit_counters[slot] = {}
	return view


## The names of the units the game log gives as the sources of a unit's buffs, first seen first.
static func _buff_sources(session: GameSession, held: Unit) -> PackedStringArray:
	var out: PackedStringArray = []
	var wanted: Dictionary = {}
	for event: Dictionary in session.events:
		if (
			str(event.get("type", "")) != "buff"
			or CoreUtil.to_int(event.get("uid", -1)) != held.uid
		):
			continue
		var source: int = CoreUtil.to_int(event.get("source_uid", -1))
		if source >= 0:
			wanted[source] = true
	if wanted.is_empty():
		return out
	var names: Dictionary = {}
	for event: Dictionary in session.events:
		var uid: int = CoreUtil.to_int(event.get("uid", -1))
		if wanted.has(uid) and not names.has(uid) and event.has("id"):
			var card: UnitDef = session.library.get_card(StringName(str(event["id"])))
			if card != null:
				names[uid] = "itself" if uid == held.uid else card.name
	for uid: Variant in wanted:
		var shown: String = str(names.get(uid, ""))
		if shown != "" and not out.has(shown):
			out.append(shown)
	return out


static func _plus(attack: int, health: int) -> String:
	return "%s%d/%s%d" % ["+" if attack >= 0 else "", attack, "+" if health >= 0 else "", health]
