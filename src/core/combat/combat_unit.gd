class_name CombatUnit
extends BoardUnit
## One unit in a fight: a copy of a board unit (9.1.1) or a combat-only summon (9.8.4). The shared
## state questions ("can it attack", "is it stopped", "is it undamaged") are asked here and only
## here, at the moment they matter; don't carry the answer through a phase.

## Statuses that make a chosen unit skip instead of attacking (9.4.5, Mire).
const STOP_STATUSES: PackedStringArray = ["mired"]

var uid: int = 0
## The recruit unit this copies (0 for summons): "permanently" reaches it after the fight.
var iid: int = 0
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
## Built mechanics, with their parameters (golden numbers doubled), in the unit file's order.
var scripts: Array[Mechanic] = []
var params: Array[Dictionary] = []
var mechanic_ids: PackedStringArray = []
## Indices into `scripts` of entries that give auras to other units (12.2.1).
var board_aura_sources: Array[int] = []
var acts_without_attack: bool = false
## Sandbox scenarios: a name shown instead of the unit's own (e.g. "Boar" on a filler unit).
var display_name: String = ""


static func make(
	unit_def: Dictionary, spec: Dictionary, unit_id: int, unit_side: int
) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.uid = unit_id
	unit.side = unit_side
	unit.set_base(unit_def, CoreUtil.to_bool(spec.get("golden", false)))
	# A board's "attack"/"health" are the unit's stats before this combat: base plus permanent.
	if spec.has("attack"):
		unit.perm_attack = CoreUtil.to_int(spec["attack"]) - unit.base_attack_now()
	if spec.has("health"):
		unit.perm_health = CoreUtil.to_int(spec["health"]) - unit.base_health_now()
	unit.combat_attack = CoreUtil.to_int(spec.get("combat_attack", 0))
	unit.combat_health = CoreUtil.to_int(spec.get("combat_health", 0))
	unit.iid = CoreUtil.to_int(spec.get("iid", 0))
	unit.display_name = str(spec.get("display_name", ""))
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
	mechanic.setup(self, unit_params)


## A granted mechanic ({"entry", "golden"}): plays exactly as if it were on the card.
func add_grant(grant: Dictionary) -> void:
	var entry: Dictionary = grant["entry"]
	var compiled: CompiledMechanic = MechanicRegistry.compile_entry(entry)
	if compiled != null:
		var is_golden: bool = grant.get("golden", false)
		add_mechanic(compiled.id, compiled.mechanic, compiled.params_for(is_golden))


func is_dead() -> bool:
	return health <= 0


## 9.9.1: it can attack. Whistle never attacks, even with Attack (library entry 10).
func can_attack() -> bool:
	return on_board and attack > 0 and not acts_without_attack


## 9.4.5 step 1: it can be chosen in the attack order (it can attack, or it whistles).
func can_act() -> bool:
	return on_board and (attack > 0 or acts_without_attack)


## It skips its next chance to attack (Mire). A stopped unit doesn't join attacks either.
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
	var keyword_list: Array = def["keywords"]
	var status_list: Array = []
	var keyword_text: Array = UnitLibrary.keyword_text_of(def)
	for status: String in statuses:
		var data: Dictionary = statuses[status]
		status_list.append({"status": status, "data": data.duplicate()})
		if status_text.has(status):
			var entry: Dictionary = status_text[status]
			if not keyword_text.has(entry):
				keyword_text.append(entry.duplicate())
	return {
		"uid": uid,
		"def_id": str(def["id"]),
		"name": display_name if display_name != "" else str(def["name"]),
		"tier": tier(),
		"tribes": tribe_list.duplicate(),
		"attack": attack,
		"health": health,
		"max_health": max_health,
		"golden": golden,
		"text": str(def[text_key]),
		"keywords": keyword_list.duplicate(),
		"statuses": status_list,
		"keyword_text": keyword_text,
	}
