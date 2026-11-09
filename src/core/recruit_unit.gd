class_name RecruitUnit
extends BoardUnit
## One unit a player holds in the Recruit Phase: in the shop, the hand or on the board.
## pool_copies is how many pool copies it holds (5.3.5). Its combat layer holds buffs "for the
## next combat" given during the Recruit Phase; it empties when the fight is over.

const HexValue := preload("res://src/core/hex_value.gd")

const ORIGIN_BOUGHT: String = "bought"
const ORIGIN_CREATED: String = "created"

var iid: int = 0
var origin: String = ORIGIN_BOUGHT
var pool_copies: int = 0
## A transformed card returns the copies of the card it came from.
var pool_origin: String = ""
var poached_discount: int = 0
## Full-price pass 3 copies remain special offers despite having no discount.
var poached_offer: bool = false
## True for a golden made by a triple (4.3.4 sells for 1).
var from_triple: bool = false
## True until a triple's golden is first played (7.3.6 Triple Reward).
var reward_pending: bool = false
## End of Turns ended in this slot; a move resets it (Sleeping Partner, Cold Frame share it).
var turns_in_slot: int = 0
## The slot `turns_in_slot` counts for; -1 until it next ends a turn on the board.
var home_slot: int = -1
## Waiting prizes ("after N turns in its slot"): {"turns", "left", "attack", "health"}.
var timers: Array[Dictionary] = []
## Shy: the stats it last had, to see a rise. x < 0 until first seen on the board.
var shy_seen: Vector2i = Vector2i(-1, -1)
## Only an aimed spell or a reward earned during combat bypasses Shy's recruit immunity.
var shy_accepts_stats: bool = false
## Belly: the units inside, oldest first, so the last in is the last entry. Only a board unit holds.
var held: Array[RecruitUnit] = []
## The round this was last played. A bird played this turn hasn't fought, so it can't fly yet.
var played_round: int = 0
## Cut-and-Come-Again's copies: they don't count for triples or Fly South.
var plain_copy: bool = false
## Current contributions from each tribe, for the icon and unit detail.
var tribe_bonuses: Dictionary = {}
## The owner's current tier, refreshed with recruit auras.
var hex_tier: int = 1


static func make(unit_def: Dictionary, instance_id: int, is_golden: bool = false) -> RecruitUnit:
	var unit := RecruitUnit.new()
	unit.iid = instance_id
	unit.set_base(unit_def, is_golden)
	return unit


func add_permanent(attack_delta: int, health_delta: int) -> void:
	if has_mechanic_id("shy") and not shy_accepts_stats:
		attack_delta = mini(0, attack_delta)
		health_delta = mini(0, health_delta)
	super.add_permanent(attack_delta, health_delta)


func add_combat(attack_delta: int, health_delta: int) -> void:
	if has_mechanic_id("shy") and not shy_accepts_stats:
		attack_delta = mini(0, attack_delta)
		health_delta = mini(0, health_delta)
	super.add_combat(attack_delta, health_delta)


func pool_id() -> String:
	return def_id() if pool_origin == "" else pool_origin


func row_hint() -> String:
	var hint: Variant = def["row_hint"]
	return "" if hint == null else str(hint)


## 6.2 recruit unit view. `stat_layers` shows where the numbers come from.
func view() -> Dictionary:
	var text_key: String = "golden_text" if golden else "text"
	var tribe_list: Array = def["tribes"]
	var keyword_list: Array = def["keywords"]
	var out: Dictionary = {
		"iid": iid,
		"def_id": def_id(),
		"name": str(def["name"]),
		"tier": tier(),
		"tribes": tribe_list.duplicate(),
		"tribe_bonuses": tribe_bonuses.duplicate(),
		"attack": attack,
		"health": health,
		"golden": golden,
		"origin": origin,
		"text": str(def[text_key]),
		"keywords": _keywords_now(keyword_list),
		"counters": counters.duplicate(),
		"hex_amount": hex_amount(),
		"hex_stored": hex_amount(false),
		"keyword_text": UnitLibrary.keyword_text_of(def),
		"stat_layers":
		{
			"base_attack": base_attack_now(),
			"base_health": base_health_now(),
			"perm_attack": perm_attack,
			"perm_health": perm_health,
			"tribe_attack": tribe_attack,
			"tribe_health": tribe_health,
			"combat_attack": combat_attack,
			"combat_health": combat_health,
			"aura_attack": aura_attack,
			"aura_health": aura_health,
		},
		"turns_in_slot": _turns_shown(),
		"turns_goal": _turns_goal_left(),
		"timers": timers.duplicate(true),
		"reward_pending": reward_pending,
		"shy": has_mechanic_id("shy"),
		"eats_items": eat_rate() > 0 and can_gain_permanent(),
		"belly": mechanic_number("belly", "size"),
		"belly_discount": mechanic_number("belly_discount", "gold"),
		"held": _held_views(),
		"fly_south": flight_turns(),
		"played_round": played_round,
		"plain_copy": plain_copy,
		"poached": poached_offer or poached_discount > 0,
		"egged": CoreUtil.to_bool(counters.get("egged", false)),
		"pass3_content": has_mechanic_id("pass3_bird") or has_mechanic_id("pass3_fairy"),
	}

	if Pass3Birds.ability(self, "lump"):
		var rates: Dictionary = get_meta("pass3_rates", def.get("pass3_rates", {}))
		out["nest_multiplier"] = (
			CoreUtil.to_float(rates.get("birds_lump_multiplier", 1.0)) * golden_factor()
		)
	if Pass3Birds.ability(self, "stork"):
		out["stork_count"] = CoreUtil.to_int(counters.get("stork", 0))
		out["stork_goal"] = CoreUtil.to_int(counters.get("stork_goal", 6))
	var percent: int = hex_percent_amount(false)
	if percent > 0:
		out["hex_percent_amount"] = mini(100, percent)
		out["hex_percent_stored"] = percent
	var borrowed: Array[Dictionary] = _borrowed_rules()
	if not borrowed.is_empty():
		out["borrowed_rules"] = borrowed
	UnitLibrary.add_configured_rulings(out, def, golden)
	return out


## Whether the card itself has this mechanic.
func has_mechanic_id(mechanic_id: String) -> bool:
	for value: Variant in MechanicRegistry.compiled(def):
		var compiled: CompiledMechanic = value
		if compiled.id == mechanic_id:
			return true
	return false


## A number parameter of one of the card's mechanics, doubled if golden; 0 if it has none.
func mechanic_number(mechanic_id: String, key: String) -> int:
	for value: Variant in MechanicRegistry.compiled(def):
		var compiled: CompiledMechanic = value
		if compiled.id == mechanic_id:
			var params: Dictionary = compiled.params_for(golden)
			return CoreUtil.to_int(params.get(key, 0))
	return 0


## Base trip length, before neighbouring Cuckoos extend a flight.
func flight_turns() -> int:
	if has_mechanic_id("pass3_bird") and has_mechanic_id("fly_south"):
		var rates: Dictionary = get_meta("pass3_rates", def.get("pass3_rates", {}))
		if def_id() == "one_swallow":
			return CoreUtil.to_int(rates.get("birds_swallow_trip_turns", 1))
		if golden and Pass3Birds.ability(self, "old_tern"):
			return CoreUtil.to_int(rates.get("birds_golden_tern_trip_turns", 1))
		return CoreUtil.to_int(rates.get("birds_trip_turns", 2))
	if golden and (has_mechanic_id("old_tern") or Pass3Birds.ability(self, "old_tern")):
		return 1
	return mechanic_number("fly_south", "turns")


## Stats per gold when an Acorn item is played on this; 0 if it can't take one.
func eat_rate() -> int:
	return mechanic_number("eats_acorns", "per_gold")


## A move: the slot's count starts over, and waiting prizes with it.
func reset_turns() -> void:
	turns_in_slot = 0
	home_slot = -1
	for timer: Dictionary in timers:
		timer["left"] = timer["turns"]


## The card's keywords plus any it gained.
func _keywords_now(printed: Array) -> Array:
	var out: Array = printed.duplicate()
	for grant: Dictionary in grants:
		var keyword: String = grant.get("keyword", "")
		if keyword != "" and not out.has(keyword):
			out.append(keyword)
	return out


## The entry a combat board takes (the same shape as CombatSandbox boards, plus the layers).
func combat_spec() -> Dictionary:
	var spec: Dictionary = {
		"def_id": def_id(),
		"golden": golden,
		"attack": base_attack_now() + perm_attack + tribe_attack,
		"health": base_health_now() + perm_health + tribe_health,
		"iid": iid,
		"tribe_attack": tribe_attack,
		"tribe_health": tribe_health,
	}
	for field: String in ["gem_attack", "gem_health", "combat_gem_attack", "combat_gem_health"]:
		if CoreUtil.to_int(get(field)) != 0:
			spec[field] = get(field)
	if counters.has("hex"):
		spec["hex"] = counters["hex"]
	if counters.has("bog_frog_turn"):
		spec["bog_frog_turn"] = counters["bog_frog_turn"]
	if counters.has("kisses"):
		spec["kisses"] = counters["kisses"]
	if counters.has("hex_percent"):
		spec["hex_percent"] = counters["hex_percent"]
	if limits.has("mrs_clover"):
		spec["mrs_clover_used"] = limits["mrs_clover"]
	var payments: Dictionary = {}
	for key: Variant in counters:
		if str(key).begins_with("paid_"):
			payments[key] = counters[key]
	if not payments.is_empty():
		spec["lifetime_payments"] = payments
	if combat_attack != 0 or combat_health != 0:
		spec["combat_attack"] = combat_attack
		spec["combat_health"] = combat_health
	var borrowed_rules: Array[Dictionary] = _borrowed_rules()
	if not borrowed_rules.is_empty():
		spec["borrowed_rules"] = borrowed_rules
	var carried: Array[Dictionary] = grants.duplicate()
	carried.append_array(borrowed_text())
	if not carried.is_empty():
		spec["grants"] = carried
	if not held.is_empty():
		var inside: Array = []
		for unit: RecruitUnit in held:
			inside.append(unit.combat_spec())
		spec["held"] = inside
	return spec


## Frumenty: the text of what's inside, as grants. Not its Belly, Fly South or Shy, and nothing that
## only happens as a unit is played, sold or comes home.
func borrowed_text() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if held.is_empty() or not has_mechanic_id("borrows_text"):
		return out
	for unit: RecruitUnit in held:
		var entries: Array = unit.def["mechanics"]
		for value: Variant in entries:
			var entry: Dictionary = value
			if _can_lend(entry):
				out.append({"entry": entry, "golden": unit.golden, "keyword": ""})
	return out


## Whole-card text is safe only when every mechanic is borrowed. Mixed cards provide explicit
## fragments bound to mechanic index and id; never infer an ability from its prose or punctuation.
func _borrowed_rules() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not has_mechanic_id("borrows_text"):
		return out
	for unit: RecruitUnit in held:
		var entries: Array = unit.def["mechanics"]
		var lendable: Array[int] = []
		for index: int in entries.size():
			var entry: Dictionary = entries[index]
			if _can_lend(entry):
				lendable.append(index)
		var key: String = "golden_text" if unit.golden else "text"
		var words: String = "No borrowed text."
		if not lendable.is_empty() and lendable.size() == entries.size():
			words = str(unit.def[key])
		elif not lendable.is_empty():
			var fragments: Dictionary = unit.def.get("mechanic_text", {})
			var kept: PackedStringArray = []
			for index: int in lendable:
				var fragment: Dictionary = fragments.get(str(index), {})
				var entry: Dictionary = entries[index]
				if not _fragment_matches(fragment, entry) or str(fragment.get(key, "")).is_empty():
					kept.clear()
					break
				kept.append(str(fragment[key]))
			words = " ".join(kept) if not kept.is_empty() else "Borrowed rules unavailable."
		out.append({"name": str(unit.def["name"]), "text": words})
	return out


static func _fragment_matches(fragment: Dictionary, entry: Dictionary) -> bool:
	return (
		str(fragment.get("id", "")) == str(entry.get("id", ""))
		and str(fragment.get("trigger", "")) == str(entry.get("trigger", ""))
	)


static func _can_lend(entry: Dictionary) -> bool:
	const NEVER: PackedStringArray = ["belly", "belly_discount", "fly_south", "shy", "borrows_text"]
	const NOT_TRIGGERS: PackedStringArray = ["on_play", "on_sell", "on_home"]
	if (
		str(entry.get("id", "")) == "pass3_bird"
		and str(entry.get("ability", "")) in ["swallow", "chiffchaff", "jay", "goose", "old_tern"]
	):
		return false
	if (
		str(entry.get("id", "")) == "pass3_fairy"
		and str(entry.get("ability", "")) in ["nan", "chaser"]
	):
		return false
	return (
		not NEVER.has(str(entry.get("id", "")))
		and not NOT_TRIGGERS.has(str(entry.get("trigger", "")))
	)


func _held_views() -> Array:
	var out: Array = []
	for unit: RecruitUnit in held:
		out.append(unit.view())
	return out


## The fight is over: "next combat" buffs end (12.1.1).
func clear_combat_layer() -> void:
	combat_attack = 0
	combat_health = 0
	combat_gem_attack = 0
	combat_gem_health = 0
	if grants.is_empty():
		return
	var kept: Array[Dictionary] = []
	for grant: Dictionary in grants:
		if not grant.get("combat_only", false):
			kept.append(grant)
	grants = kept


## A card that pays every N turns shows how far it is into this round of N.
func _turns_shown() -> int:
	var goal: int = CoreUtil.to_int(def.get("turns_goal", 0))
	if goal > 0 and CoreUtil.to_int(def.get("turns_repeat", 0)) > 0:
		return turns_in_slot % goal
	return turns_in_slot


## What the unit's "After N turns" still waits for; 0 once it has fired, so screens stop counting.
func _turns_goal_left() -> int:
	for key: Variant in counters:
		if str(key).begins_with("fired_"):
			return 0
	if def.has("turns_repeat") and not pays_again():
		return 0
	return CoreUtil.to_int(def.get("turns_goal", 0))


## A card that pays every N turns has payments left in this unit's life. They survive a move.
func pays_again() -> bool:
	var paid: int = 0
	for key: Variant in counters:
		if str(key).begins_with("paid_"):
			paid = maxi(paid, CoreUtil.to_int(counters[key]))
	return paid < CoreUtil.to_int(def.get("turns_repeat", 0))


## Conversion rounds a small Acorn up; the divisor does not double on golden.
func acorn_stats(gold: int) -> int:
	var step: int = maxi(1, mechanic_number("eats_acorns", "gold_step"))
	return eat_rate() * ceili(float(gold) / step)


## Sum the actual Hex effects, including granted and borrowed text; counters store growth only.
func hex_amount(capped: bool = true) -> int:
	var total: int = 0
	for value: Variant in MechanicRegistry.compiled(def):
		var compiled: CompiledMechanic = value
		if compiled.id == "hex":
			total += _hex_value(compiled.params_for(golden), capped)
	for group: Array in [grants, borrowed_text()]:
		for value: Variant in group:
			var grant: Dictionary = value
			var entry: Dictionary = grant["entry"]
			if str(entry.get("id", "")) == "hex":
				total += _hex_value(
					MechanicRegistry.params_for(
						entry, CoreUtil.to_bool(grant.get("golden", false))
					),
					capped
				)
	return total


func _hex_value(params: Dictionary, capped: bool) -> int:
	if params.has("percent"):
		return 0
	return HexValue.amount(
		CoreUtil.to_int(params.get("n", 0)),
		CoreUtil.to_int(counters.get("hex", 0)),
		HexValue.ceiling(params, hex_tier) if capped else 0
	)


## Proportional Hex has its own unit, rather than pretending percent is flat Attack.
func hex_percent_amount(capped: bool = true) -> int:
	var total: int = 0
	var entries: Array = []
	for compiled: CompiledMechanic in MechanicRegistry.compiled(def):
		if compiled.id == "hex":
			entries.append(compiled.params_for(golden))
	for grant: Dictionary in grants + borrowed_text():
		var entry: Dictionary = grant["entry"]
		if str(entry.get("id", "")) == "hex":
			entries.append(
				MechanicRegistry.params_for(entry, CoreUtil.to_bool(grant.get("golden", false)))
			)
	for params: Dictionary in entries:
		if params.has("percent"):
			total += (
				CoreUtil.to_int(params["percent"]) + CoreUtil.to_int(counters.get("hex_percent", 0))
			)
	return mini(100, total) if capped else total
