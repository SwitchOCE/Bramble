class_name CombatUnit
extends BoardUnit
## One unit in a fight: a copy of a board unit (9.1.1) or a combat-only summon (9.8.4). The shared
## state questions ("can it attack", "is it stopped", "is it undamaged") are asked here and only
## here, at the moment they matter; don't carry the answer through a phase.

## Statuses that make a chosen unit skip instead of attacking (9.4.5, Stalled).
const STOP_STATUSES: PackedStringArray = ["stalled"]

var uid: int = 0
## Created by copying during this fight, never part of the recruit snapshot.
var copied_this_fight: bool = false
## A quarry is a unit identity, never a slot or a reference to another RefCounted fighter.
var quarry: int = 0
var quarry_reach: bool = false
## The recruit unit this copies (0 for summons): "permanently" reaches it after the fight.
var iid: int = 0
var pending_attack: int = 0
var pending_health: int = 0
var side: int = 0
var slot: int = -1
## 9.4.5 "attacked this cycle".
var flagged: bool = false
## On the board (false once it has died and left its slot).
var on_board: bool = true
## Status name -> data (SPEC 4.1 statuses).
var statuses: Dictionary = {}
## Has taken damage this combat (Ermine Duellist's Quick).
var damaged: bool = false
## Identity of the source of the hit that first took this below 1 Health.
var killed_by: int = 0
## Built mechanics, with their parameters (golden numbers doubled), in the unit file's order.
var scripts: Array[Mechanic] = []
var params: Array[Dictionary] = []
var mechanic_ids: PackedStringArray = []
## Indices into `scripts` of entries that give auras to other units (12.2.1).
var board_aura_sources: Array[int] = []
## Indexes of the mechanics that hear other units' deaths and summons.
var ally_listeners: Array[int] = []
var acts_without_attack: bool = false
## Recomputed with the board's auras: Hopkin can borrow even after Bitter erased his own Attack.
var bog_can_borrow: bool = false
## Hex on this unit's slot right now (it's part of the aura layer).
var hex_amount: int = 0
## Display provenance of the previous aura layer.
var aura_sources: Dictionary = {}
## Card words borrowed from held units, for details during the fight.
var borrowed_rules: Array = []
## Sandbox scenarios: a name shown instead of the unit's own (e.g. "Boar" on a filler unit).
var display_name: String = ""
## Live text for pass 3 copies and stolen text. Empty is a meaningful silenced card.
var has_text_override: bool = false
var text_override: String = ""
var keywords_override: Array = []
## Own Egg details; public scout snapshots strip these before a rehearsal fight.
var egg_info: Dictionary = {}
## Belly: what's inside as specs, oldest first; they become fighters as they come out.
var held_specs: Array = []
## Fighters swallowed during this fight (Hasty Pudding, Granny Stir-Up), oldest first.
var inside: Array[CombatUnit] = []


static func make(
	unit_def: Dictionary, spec: Dictionary, unit_id: int, unit_side: int
) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.uid = unit_id
	unit.side = unit_side
	unit.set_base(unit_def, CoreUtil.to_bool(spec.get("golden", false)))
	# A board's stats include its standing tribe layer, which remains separate from capped buffs.
	unit.tribe_attack = CoreUtil.to_int(spec.get("tribe_attack", 0))
	unit.tribe_health = CoreUtil.to_int(spec.get("tribe_health", 0))
	if spec.has("attack"):
		unit.perm_attack = (
			CoreUtil.to_int(spec["attack"]) - unit.base_attack_now() - unit.tribe_attack
		)
	if spec.has("health"):
		unit.perm_health = (
			CoreUtil.to_int(spec["health"]) - unit.base_health_now() - unit.tribe_health
		)
	unit.add_permanent(0, 0)
	unit.combat_attack = CoreUtil.to_int(spec.get("combat_attack", 0))
	unit.combat_health = CoreUtil.to_int(spec.get("combat_health", 0))
	unit.iid = CoreUtil.to_int(spec.get("iid", 0))
	unit.gem_attack = CoreUtil.to_int(spec.get("gem_attack", 0))
	unit.gem_health = CoreUtil.to_int(spec.get("gem_health", 0))
	unit.combat_gem_attack = CoreUtil.to_int(spec.get("combat_gem_attack", 0))
	unit.combat_gem_health = CoreUtil.to_int(spec.get("combat_gem_health", 0))
	if CoreUtil.to_bool(spec.get("replay_starting_belly_survivor", false)):
		unit.counters["replay_starting_belly_survivor"] = true
	for field: String in ["egg_full_attack", "egg_full_health", "bog_frog_turn"]:
		if spec.has(field):
			unit.counters[field] = CoreUtil.to_int(spec[field])
	if spec.has("hex_percent"):
		unit.counters["hex_percent"] = CoreUtil.to_int(spec["hex_percent"])
	if spec.has("hex"):
		unit.counters["hex"] = CoreUtil.to_int(spec["hex"])
	if spec.has("kisses"):
		unit.counters["kisses"] = CoreUtil.to_int(spec["kisses"])
	if spec.has("mrs_clover_used"):
		unit.limits["mrs_clover"] = CoreUtil.to_int(spec["mrs_clover_used"])
	var payments: Dictionary = spec.get("lifetime_payments", {})
	unit.counters.merge(payments)
	for field: String in ["bird_attack", "bird_health", "turns_left"]:
		if spec.has(field):
			unit.egg_info[field] = CoreUtil.to_int(spec[field])
	unit.display_name = str(spec.get("display_name", ""))
	var borrowed_words: Array = spec.get("borrowed_rules", [])
	unit.borrowed_rules = borrowed_words.duplicate(true)
	var inner: Array = spec.get("held", [])
	unit.held_specs = inner.duplicate()
	for value: Variant in MechanicRegistry.compiled(unit_def):
		var compiled: CompiledMechanic = value
		unit.add_mechanic(compiled.id, compiled.mechanic, compiled.params_for(unit.golden))
	var granted: Array = spec.get("grants", [])
	for value: Variant in granted:
		var grant: Dictionary = value
		unit.add_grant(grant)
	return unit


## Adds a mechanic to this unit (from its def, or granted).
func add_mechanic(id: String, mechanic: Mechanic, unit_params: Dictionary) -> void:
	scripts.append(mechanic)
	params.append(unit_params)
	mechanic_ids.append(id)
	if mechanic.acts_without_attack(unit_params):
		acts_without_attack = true
	if mechanic.has_board_aura(unit_params):
		board_aura_sources.append(scripts.size() - 1)
	if mechanic.hears_allies(unit_params):
		ally_listeners.append(scripts.size() - 1)
	mechanic.setup(self, unit_params)


## Mag Pye: `thief` takes this unit's text for the fight. Its Belly isn't text, so that stays.
func lend_text_to(thief: CombatUnit) -> void:
	var old_scripts: Array[Mechanic] = scripts
	var old_params: Array[Dictionary] = params
	var old_ids: PackedStringArray = mechanic_ids
	scripts = []
	params = []
	mechanic_ids = []
	board_aura_sources = []
	ally_listeners = []
	acts_without_attack = false
	for index: int in old_scripts.size():
		var target: CombatUnit = self if old_ids[index] == HeldUnits.BELLY else thief
		target.add_mechanic(old_ids[index], old_scripts[index], old_params[index])


## A granted mechanic ({"entry", "golden"}): plays exactly as if it were on the card.
func add_grant(grant: Dictionary) -> void:
	grants.append(grant.duplicate(true))
	var entry: Dictionary = grant["entry"]
	var compiled: CompiledMechanic = MechanicRegistry.compile_entry(entry)
	if compiled != null:
		var is_golden: bool = grant.get("golden", false)
		add_mechanic(compiled.id, compiled.mechanic, compiled.params_for(is_golden))


func is_dead() -> bool:
	return health <= 0


## 9.9.1: it can attack. Whistle never attacks, even with Attack (library entry 10).
func can_attack() -> bool:
	return (
		on_board
		and (attack > 0 or bog_can_borrow or has_status("borrowed_attack"))
		and not acts_without_attack
	)


## 9.4.5 step 1: it can be chosen in the attack order (it can attack, or it whistles).
func can_act() -> bool:
	return (
		on_board
		and (
			attack > 0
			or bog_can_borrow
			or acts_without_attack
			or held_down()
			or has_status("borrowed_attack")
		)
	)


## Hex took all its Attack: it still attacks, for 0, and takes the blow back.
func held_down() -> bool:
	if hex_amount <= 0:
		return false
	var unhexed: int = base_attack_now() + perm_attack + combat_attack + aura_attack + hex_amount
	return unhexed > 0


## It skips its next chance to attack (Stalled). A stopped unit doesn't join attacks either.
func is_stopped() -> bool:
	for status: String in STOP_STATUSES:
		if statuses.has(status):
			return true
	return false


## It has taken no damage this combat. Health loss (Nightshade) isn't damage (SPEC 4.2).
func is_undamaged() -> bool:
	return not damaged


## Damage landing: Health goes down and the unit counts as damaged if any got through.
func take_damage(amount: int) -> void:
	damage_taken += amount
	if amount > 0:
		damaged = true


## Health loss that isn't damage (Nightshade).
func lose_health(amount: int) -> void:
	damage_taken += amount


func has_mechanic(mechanic_id: String) -> bool:
	return mechanic_ids.has(mechanic_id)


func has_status(status: String) -> bool:
	return statuses.has(status)


## 6.3 combat unit view. `status_text` maps a status to its {"keyword", "text"} entry.
func view(status_text: Dictionary = {}) -> Dictionary:
	var text_key: String = "golden_text" if golden else "text"
	var tribe_list: Array = def["tribes"]
	var keyword_list: Array = keywords_override if has_text_override else def["keywords"]
	var status_list: Array = []
	var keyword_text: Array = UnitLibrary.keyword_text_of(def)
	for status: String in statuses:
		var data: Dictionary = statuses[status]
		status_list.append({"status": status, "data": data.duplicate()})
		if status_text.has(status):
			var entry: Dictionary = status_text[status]
			if not keyword_text.has(entry):
				keyword_text.append(entry.duplicate())
	var out: Dictionary = {
		"uid": uid,
		"quarry": quarry,
		"quarry_reach": quarry_reach,
		"def_id": str(def["id"]),
		"name": display_name if display_name != "" else str(def["name"]),
		"tier": tier(),
		"tribes": tribe_list.duplicate(),
		"attack": attack,
		"health": health,
		"max_health": max_health,
		"golden": golden,
		"text": text_override if has_text_override else str(def[text_key]),
		"keywords": keyword_list.duplicate(),
		"statuses": status_list,
		"keyword_text": keyword_text,
	}
	out.merge(egg_info)
	if counters.has("bog_kiss_period"):
		out["bog_kiss_period"] = counters["bog_kiss_period"]
		out["counters"] = {"kisses": CoreUtil.to_int(counters.get("kisses", 0))}
	if pending_attack != 0 or pending_health != 0:
		out["pending_attack"] = pending_attack
		out["pending_health"] = pending_health
	if has_text_override:
		out["text_changed"] = true
	if not borrowed_rules.is_empty():
		out["borrowed_rules"] = borrowed_rules.duplicate(true)
	var held: int = held_specs.size() + inside.size()
	if held > 0:
		out["held"] = held
	UnitLibrary.add_configured_rulings(out, def, golden)
	return out
