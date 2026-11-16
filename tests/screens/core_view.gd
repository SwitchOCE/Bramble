extends RefCounted
## STAND-IN for the game flow's conversion (src/game/ is the flow's, not this): the rules core's
## view_for turned into the recruit screen's view state (docs/ideation-track-2/SCREEN-CONTRACT.md),
## for the stand-in controller and the tests. Art, names of players and the display table are
## STAND-IN choices; the rules all come from the core.

const CoreKit := preload("res://tests/core/core_kit.gd")
## STAND-IN mock-up art for the core's test cards, by card id; anything else gets FALLBACK_ART.
const ART: Dictionary = {
	"t1_plain": "mouse-1",
	"t1_guard": "hedgehog-1",
	"t1_herald": "hare-1",
	"t1_seed": "ooze-2",
	"tk_sprout": "fairy-2",
	"t2_shield": "badger-1",
	"t2_mentor": "otter-2",
	"t2_fighter": "stoat-1",
	"t2_merchant": "mouse-2",
	"t3_twin": "otter-1",
	"t3_viper": "stoat-2",
	"t3_banner": "hare-2",
	"t3_hunter": "owl-1",
	"t4_phoenix": "owl-2",
	"t4_cleaver": "boar-1",
	"t4_shade": "fairy-1",
	"t4_wall": "hedgehog-2",
	"t5_avenger": "boar-2",
	"t5_bomber": "ooze-1",
	"t6_titan": "stag-1",
	"t6_brood": "stag-2",
	"b1_burier": "badger-2",
	"b3_officer": "owl-1",
	"st_tutor": "hare-2",
	"sp_sharpen": "spell-1",
	"sp_seek": "spell-2",
	"sp_forage": "spell-1",
	"sp_gift": "spell-2",
	"triple_reward": "spell-1",
}
const FALLBACK_ART: String = "mouse-1"
## STAND-IN lobby: names and portraits for the eight seats.
const SEATS: Array = [
	["Dame Farthing", "dame_farthing"],
	["Brother Bracken", "brother_bracken"],
	["March Hare", "march_hare"],
	["Pipkin", "pipkin"],
	["Dame Hoolet", "dame_hoolet"],
	["Hob Mumblecrust", "hob_mumblecrust"],
	["Little King Wren", "little_king_wren"],
	["Old Mother Mousewife", "old_mother_mousewife"],
]
## STAND-IN display table: what each keyword, counter and ability is called, its reminder, and
## whether it is drawn. The flow fills this from the tribes' card data.
const DISPLAY: Dictionary = {
	"taunt": {"name": "Taunt", "reminder": "Enemies must attack this first."},
	"divine_shield": {"name": "Shield", "reminder": "The first damage this takes is ignored."},
	"windfury": {"name": "Windfury", "reminder": "Attacks twice each turn."},
	"venomous": {"name": "Venomous", "reminder": "Destroys any unit it damages, once."},
	"reborn": {"name": "Reborn", "reminder": "Comes back with 1 Health the first time it dies."},
	"cleave": {"name": "Cleave", "reminder": "Also damages the units beside its target."},
	"stealth": {"name": "Stealth", "reminder": "Can't be attacked until it attacks."},
	"medal": {"name": "Medals", "reminder": "Earned after fights."},
	"tide": {"name": "Tide", "reminder": "Grows when a Tider dies. Lasts the game."},
	"heap": {"name": "Heap", "reminder": "Every unit sold goes here."},
	"test_order_slot": {"name": "Order", "reminder": "Pay 1: a slot gets +2/+2 and Taunt."},
	"test_bury": {"name": "Bury", "reminder": "Once a turn: put a shop unit in your heap."},
	"hidden_mark": {"name": "Mark", "reminder": "", "shown": false},
}
## A STAND-IN card added to the library: a unit whose play buffs a chosen friend.
const EXTRA_CARDS: Array = [
	{
		"id": "st_tutor",
		"name": "Tutor",
		"tier": 1,
		"attack": 1,
		"health": 1,
		"text": "When you play this, give a friend +2/+2.",
		"effects": [{"mechanic": "play_buff", "attack": 2, "health": 2, "to": "target"}],
	},
]


## A bridge session with the stand-in card, every sale feeding the heap.
static func session(game_seed: int = 3) -> GameSession:
	var game: GameSession = CoreKit.bridge_session(game_seed)
	game.library.add_cards(EXTRA_CARDS, game.registry)
	return game


## Round 1 started, with player 0 given gold, a board and a hand that show every input: a
## unit to aim, three kinds of spell, the Triple Reward, an ability with a slot target and one
## with a shop target.
static func playable(game_seed: int = 3) -> GameSession:
	var game: GameSession = session(game_seed)
	game.start_round()
	var me: PlayerState = game.player(0)
	me.gold = 30
	CoreKit.put(game, me, "b3_officer", 0)
	CoreKit.put(game, me, "b1_burier", 1)
	CoreKit.put(game, me, "t3_twin", 2)
	CoreKit.put(game, me, "t1_guard", 4)
	for card_id: String in ["st_tutor", "sp_sharpen", "sp_seek", "sp_gift", "triple_reward"]:
		me.hand.append(CoreKit.unit(game, card_id))
	return game


## The recruit screen's view state for one player.
static func recruit_state(game: GameSession, player_id: int, message: String = "") -> Dictionary:
	var me: PlayerState = game.player(player_id)
	var view: Dictionary = game.view_for(player_id)
	var costs: Dictionary = view["costs"]
	var out: Dictionary = {
		"turn": game.round_number,
		"gold": me.gold,
		"tier": me.tier,
		"refresh_cost": costs["refresh"],
		"frozen": me.frozen,
		"health": me.health,
		"hand_limit": game.rules.hand_limit(me),
		"hero": _seat(player_id),
		"message": message,
		"display": DISPLAY,
		"legal_actions": view["legal_actions"],
	}
	if GlassPieces.as_int(costs["upgrade"]) >= 0:
		out["upgrade_cost"] = costs["upgrade"]
	var next: int = game.opponent_of(player_id)
	var opponent: Dictionary = _seat(next)
	opponent["health"] = game.player(next).health if next >= 0 else 0
	out["next_opponent"] = opponent
	out["shop_units"] = _shop(game, me.shop_units, costs["shop_units"])
	out["shop_spells"] = _shop(game, me.shop_spells, costs["shop_spells"])
	var hand: Array = []
	for unit: Unit in me.hand:
		hand.append(card(game, unit))
	out["hand"] = hand
	var board: Array = []
	var sells: Array = costs["sell"]
	for slot: int in me.board.size():
		var unit: Unit = me.board[slot]
		if unit == null:
			board.append(null)
			continue
		var entry: Dictionary = card(game, unit)
		entry["sell_value"] = sells[slot]
		board.append(entry)
	out["board"] = board
	out["slots"] = me.slots.map(_slot)
	out["counters"] = _counters(me)
	if not me.discover_options.is_empty():
		var options: Array = []
		for card_id: StringName in me.discover_options:
			options.append(_def_card(game, game.library.get_card(card_id)))
		out["discover"] = {"prompt": "Choose a card to add to your hand", "options": options}
	var players: Array = []
	for each: PlayerState in game.players:
		var row: Dictionary = _seat(each.id)
		row["health"] = each.health
		row["tier"] = each.tier
		row["you"] = each.id == player_id
		row["next"] = each.id == next
		players.append(row)
	out["players"] = players
	return out


## A held card (hand or board) as the screen draws it.
static func card(game: GameSession, unit: Unit) -> Dictionary:
	var view: Dictionary = unit.view()
	var out: Dictionary = _def_card(game, unit.def)
	out["uid"] = unit.uid
	out["attack"] = view["attack"]
	out["health"] = view["health"]
	out["max_health"] = view["health"]
	out["golden"] = view["golden"]
	out["text"] = view["text"]
	out["keywords"] = view["keywords"]
	var counters: Array = []
	var held: Dictionary = view["counters"]
	for key: Variant in held:
		counters.append({"key": str(key), "value": held[key]})
	out["counters"] = counters
	var target: String = _target_name(game.recruit.play_target_of(unit))
	if target != "":
		out["target"] = target
	var abilities: Array = []
	for bound: BoundMechanic in unit.hooks():
		if bound.mechanic.has_ability():
			(
				abilities
				. append(
					{
						"mechanic": String(bound.id),
						"target": _target_name(bound.mechanic.ability_target(bound.params)),
						"cost": bound.mechanic.ability_cost(bound.params),
					}
				)
			)
	if not abilities.is_empty():
		out["abilities"] = abilities
	return out


static func _def_card(_game: GameSession, def: UnitDef) -> Dictionary:
	var out: Dictionary = {
		"id": String(def.id),
		"name": def.name,
		"tier": def.tier,
		"art": ART.get(String(def.id), FALLBACK_ART),
		"attack": def.attack,
		"health": def.health,
		"text": def.text,
		"keywords": Array(def.keywords).map(func(k: StringName) -> String: return String(k)),
	}
	if def.is_spell():
		out["spell"] = true
		out["cost"] = def.cost
	return out


static func _shop(game: GameSession, ids: Array[StringName], prices: Variant) -> Array:
	var price_list: Array = prices
	var out: Array = []
	for i: int in ids.size():
		if ids[i] == PlayerState.NO_CARD:
			out.append(null)
			continue
		var entry: Dictionary = _def_card(game, game.library.get_card(ids[i]))
		entry["price"] = price_list[i]
		out.append(entry)
	return out


static func _slot(slot: SlotState) -> Dictionary:
	var view: Dictionary = slot.view()
	var attack: int = GlassPieces.as_int(view["attack"])
	var health: int = GlassPieces.as_int(view["health"])
	var keywords: Array = view["keywords"]
	if attack == 0 and health == 0 and keywords.is_empty():
		return {}
	var words: String = "+%d/+%d" % [attack, health]
	return {"buff": words, "buff_name": "Taunt" if keywords.has("taunt") else "Slot"}


static func _counters(me: PlayerState) -> Array:
	var out: Array = []
	for key: Variant in me.counters:
		out.append({"key": str(key), "value": me.counters[key]})
	for key: Variant in me.heaps:
		out.append({"key": str(key), "value": me.heap(StringName(str(key))).size()})
	return out


static func _seat(player_id: int) -> Dictionary:
	if player_id < 0 or player_id >= SEATS.size():
		return {"name": "", "portrait": ""}
	var seat: Array = SEATS[player_id]
	return {"name": seat[0], "portrait": seat[1]}


static func _target_name(kind: Mechanic.Target) -> String:
	match kind:
		Mechanic.Target.FRIENDLY_UNIT:
			return "unit"
		Mechanic.Target.SLOT:
			return "slot"
		Mechanic.Target.SHOP_UNIT:
			return "shop"
	return ""
