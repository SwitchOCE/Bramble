extends SceneTree
## Ten fixed cases using the real Combat engine. Rerun and interpretation:
## docs/design/power-check.md. Buff-only wiring check: -- control.
## Single effect (includes the buff wiring check): -- mechanic_id '{"parameter": 1}'
## Full normalized cards: -- --cards [res://content/root] (140 card fights + 80 plain fights).
## Historical content: python3 tools/research/ambush_baseline.py; then
## -- --cards res://build/ambush-baseline. Printed stats, tiers and economy are not priced.
## Setup fixed before running: Mouse hooks need an own-side Hit. Lieutenant needs an
## actual friendly out-of-turn attack event (including an attacker killed by Thorns),
## or opening damage for the original res://build/ambush-baseline content.
## Other full cards need an own-side Hit/summon or positive stat buff, never merely a
## trigger. Starting stats precede combat effects.

const BODY: int = 10
const SLOT_ATTACK: int = 10
const LADDER: Array[float] = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0]
const EFFECTS: Dictionary = {
	"catapult": {"mechanic": "mouse_catapult", "params": {}},
	"pile_on": {"mechanic": "mouse_pile_on", "params": {}},
	"ballista": {"mechanic": "mouse_ballista", "params": {}},
	"engines": {"mechanic": "mouse_engines", "params": {"attack": 4}},
	"cleave": {"mechanic": "cleave", "params": {}},
	"summon": {"mechanic": "death_summon", "params": {"card": "power_token", "count": 1}},
	"buff": {},
	"pigeon_row": {"mechanic": "pigeon_lieutenant", "params": {}},
}

const CARDS: Array[String] = [
	"cousin",
	"needle-page",
	"hedgerow-scout",
	"harvest-piper",
	"shrew-cutpurse",
	"thimble-captain",
	"needle-pikeman",
	"toothpick-ballista",
	"spoon-catapult",
	"fencing-master",
	"master-of-engines",
	"king-speck",
	"dame-bodkin",
	"lieutenant",
]

var _content: ContentSet
var _fights: int = 0
var _failed: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var cards_mode: bool = not args.is_empty() and args[0] in ["cards", "--cards"]
	if cards_mode and args.size() > 2:
		printerr("power: expected cards and optional res:// content root")
		quit(1)
		return
	var content_root: String = args[1] if cards_mode and args.size() == 2 else ContentSet.ROOT
	_content = ContentSet.load_folders(ContentSet.folders_in(content_root))
	(
		_content
		. library
		. add_cards(
			[
				{"id": "power_plain", "attack": BODY, "health": BODY},
				{
					"id": "power_token",
					"attack": roundi(BODY * 0.4),
					"health": roundi(BODY * 0.4),
					"token": true
				},
			],
			_content.registry
		)
	)
	if not _content.errors.is_empty() or not _content.library.errors.is_empty():
		printerr("power: invalid content ", _content.errors, _content.library.errors)
		quit(1)
		return
	var effects: Dictionary = EFFECTS
	if cards_mode:
		effects = {}
		for card: String in CARDS:
			if _content.library.get_card(StringName(card)) == null:
				printerr("power: missing card ", card)
				quit(1)
				return
			effects[card] = {
				"card": card,
				"original_lieutenant":
				content_root.trim_suffix("/") == "res://build/ambush-baseline"
			}
		print(
			(
				"power: normalized full cards root=%s; printed stats/tier/economy excluded"
				% content_root
			)
		)
	elif args == PackedStringArray(["control"]):
		effects = {"buff": {}}
	elif not args.is_empty():
		var params: Variant = JSON.parse_string(args[1]) if args.size() > 1 else {}
		if not params is Dictionary or not _content.registry.has(StringName(args[0])):
			printerr("power: expected a registered mechanic id and optional JSON parameters")
			quit(1)
			return
		effects = {"buff": {}, args[0]: {"mechanic": args[0], "params": params}}
	_run(effects)
	print("power: fights=%d failed=%s" % [_fights, _failed])
	quit(1 if _failed else 0)


func _cases() -> Array[Dictionary]:
	return [
		{"slots": [0], "carrier": 0},
		{"slots": [0, 1, 2], "carrier": 1},
		{"slots": [0, 1, 2, 3], "carrier": 0},
		{"slots": [0, 1, 2, 3, 4, 5, 6], "carrier": 0},
		{"slots": [0, 1, 2, 3, 4, 5, 6], "carrier": 4},
		{"slots": [0, 2, 4, 6], "carrier": 4},
		{"slots": [0, 1, 2, 3, 4, 5, 6], "carrier": 4, "guard": true},
		{"slots": [0, 1, 2, 3, 4, 5, 6], "carrier": 4, "fragile": true},
		{"slots": [0, 1, 2, 3, 4, 5, 6], "carrier": 0, "slot_buff": true},
		{"slots": [0, 1, 2, 3, 4, 5, 6], "carrier": 4, "slot_buff": true},
	]


func _run(effects: Dictionary) -> void:
	var ratings: Dictionary = {}
	var set_up: Dictionary = {}
	for label: String in effects:
		ratings[label] = []
		set_up[label] = []
	var cases: Array[Dictionary] = _cases()
	for index: int in cases.size():
		var scenario: Dictionary = cases[index]
		var plain: Array[Dictionary] = []
		var margins: Array[int] = []
		for factor: float in LADDER:
			var comparison: Dictionary = _fight(scenario, index % 2, {}, factor)
			plain.append(comparison)
			margins.append(CoreUtil.to_int(comparison["margin"]))
		var monotone: bool = true
		for rung: int in range(1, margins.size()):
			monotone = monotone and margins[rung] >= margins[rung - 1]
		print("power: case=%d plain=%s monotone=%s" % [index + 1, margins, monotone])
		for label: String in effects:
			var spec: Dictionary = effects[label]
			var outcome: Dictionary = _fight(scenario, index % 2, spec, 1.0, label == "buff")
			var rung: int = LADDER.size()
			for candidate: int in LADDER.size():
				if _matches(plain[candidate], outcome):
					rung = candidate
					break
			var values: Array = ratings[label]
			values.append(rung)
			if outcome["set_up"]:
				var active: Array = set_up[label]
				active.append(rung)
			if label == "buff" and rung != 1:
				_failed = true
				printerr("power: buff wiring check failed in case ", index + 1)
			outcome["rung"] = _rung_text(rung)
			outcome["below_plain"] = CoreUtil.to_int(outcome["margin"]) < margins[0]
			print("power: %s case=%d %s" % [label, index + 1, JSON.stringify(outcome)])
	for label: String in ratings:
		var values: Array = ratings[label]
		print("power: %s rungs=%s" % [label, values.map(_rung_text)])
		var active: Array = set_up[label]
		print(
			(
				"power: %s built_around=%s all_ten=%s set_up=%d/10"
				% [label, _median(active), _median(values), active.size()]
			)
		)


func _median(values: Array) -> String:
	if values.is_empty():
		return "no set-up cases"
	var ordered: Array = values.duplicate()
	ordered.sort()
	var low: int = CoreUtil.to_int(ordered[floori((ordered.size() - 1) * 0.5)])
	var high: int = CoreUtil.to_int(ordered[floori(ordered.size() * 0.5)])
	var low_value: float = LADDER[-1] if low == LADDER.size() else LADDER[low]
	var high_value: float = LADDER[-1] if high == LADDER.size() else LADDER[high]
	return (">" if high == LADDER.size() else "") + str((low_value + high_value) * 0.5)


func _matches(plain: Dictionary, effect: Dictionary) -> bool:
	var margin: int = CoreUtil.to_int(plain["margin"])
	var target: int = CoreUtil.to_int(effect["margin"])
	return (
		margin > target
		or (
			margin == target and CoreUtil.to_int(plain["stats"]) >= CoreUtil.to_int(effect["stats"])
		)
	)


func _rung_text(index: int) -> String:
	return ">8" if index == LADDER.size() else str(LADDER[index])


func _fight(
	scenario: Dictionary, friendly: int, effect: Dictionary, factor: float, buff: bool = false
) -> Dictionary:
	var owners: Array[PlayerState] = [
		PlayerState.create(0, 7, 40, 0), PlayerState.create(1, 7, 40, 0)
	]
	var carrier: int = CoreUtil.to_int(scenario["carrier"])
	for side: int in 2:
		for value: Variant in scenario["slots"]:
			var slot: int = CoreUtil.to_int(value)
			var card_id := StringName(
				(
					str(effect.get("card", "power_plain"))
					if side == friendly and slot == carrier
					else "power_plain"
				)
			)
			var made: Unit = Unit.create(
				_content.library.get_card(card_id),
				side * 7 + slot + 1,
				false,
				_content.registry,
				1000000000
			)
			# Normalize the body after Unit.create retains the real card's complete mechanics.
			made.stats = StatBlock.of(BODY, BODY, 1000000000)
			made.slot = slot
			if scenario.get("fragile", false):
				made.stats.set_attack = BODY if slot < 4 else BODY * 2
				made.stats.set_health = BODY * 2 if slot < 4 else roundi(BODY * 0.5)
			if scenario.get("slot_buff", false):
				owners[side].slots[slot].attack = SLOT_ATTACK
			if side == friendly and slot == carrier:
				made.stats.perm_attack += roundi(made.attack() * (factor - 1.0))
				made.stats.perm_health += roundi(made.health() * (factor - 1.0))
				owners[side].slots[slot].attack = roundi(owners[side].slots[slot].attack * factor)
				if buff:
					made.stats.perm_attack += roundi(
						(made.attack() + owners[side].slots[slot].attack) * 0.5
					)
					made.stats.perm_health += roundi(made.health() * 0.5)
				if effect.has("mechanic"):
					if not made.grant_effect(
						_content.registry,
						StringName(str(effect["mechanic"])),
						CoreUtil.to_dict(effect["params"])
					):
						_failed = true
						printerr("power: could not grant ", effect)
			if side != friendly and slot == 1 and scenario.get("guard", false):
				made.grant(_content.registry, &"taunt")
			owners[side].board[slot] = made
	var original: Unit = owners[friendly].board[carrier]
	var starting_stats: int = (
		original.attack() + original.health() + owners[friendly].slots[carrier].attack
	)
	var combat: Combat = Combat.create(
		BoardGeometry.standard(4, 3), GameConfig.new(), _content.registry, _content.library, 1
	)
	combat.run([owners[0].board, owners[1].board], [0, 1], owners)
	_fights += 1
	if combat.result["reason"] != Combat.REASON_BOARD_EMPTY:
		_failed = true
		printerr("power: fight did not finish normally ", combat.result)
	var margin: int = 0
	for side: int in 2:
		for survivor: CombatUnit in combat.units(side):
			margin += survivor.health() * (1 if side == friendly else -1)
	var pre_attack: bool = true
	var opening_damage: int = 0
	var splashes: int = 0
	var attack: Dictionary = {}
	var triggered: bool = false
	var opening_deaths: int = 0
	var row_attacks: int = 0
	var hits: int = 0
	var summons: int = 0
	var positive_buffs: int = 0
	var observed: Dictionary = {}
	for event: Dictionary in combat.events:
		if event["type"] == "combat_start":
			for board: Array in event["boards"]:
				for entry: Variant in board:
					if entry is Dictionary:
						observed[entry["uid"]] = CoreUtil.to_dict(entry).duplicate()
		if event.has("uid") and event.has("health"):
			var previous: Dictionary = observed.get(event["uid"], {})
			if event["type"] == "buff" and CoreUtil.to_int(event["side"]) == friendly:
				var health_gain: bool = (
					not previous.is_empty()
					and CoreUtil.to_int(event["health"]) > CoreUtil.to_int(previous["health"])
				)
				var attack_gain: bool = (
					not previous.is_empty()
					and CoreUtil.to_int(event["attack"]) > CoreUtil.to_int(previous["attack"])
				)
				if health_gain or attack_gain:
					positive_buffs += 1
			previous.merge(event, true)
			observed[event["uid"]] = previous
		if event["type"] == "attack":
			attack = event
			if (
				CoreUtil.to_int(event["side"]) == friendly
				and CoreUtil.to_bool(event.get("out_of_turn", false))
			):
				row_attacks += 1
		if event["type"] == "trigger" and CoreUtil.to_int(event["side"]) == friendly:
			triggered = triggered or event["mechanic"] == effect.get("mechanic", "")
		if event["type"] == "damage" and CoreUtil.to_int(event["side"]) != friendly:
			if pre_attack:
				opening_damage += CoreUtil.to_int(event["amount"])
			if not attack.is_empty() and CoreUtil.to_int(attack["side"]) == friendly:
				if event["source_uid"] == attack["uid"] and event["uid"] != attack["target_uid"]:
					splashes += 1
		if event["type"] == "attack" or event["type"] == "instead_of_attack":
			pre_attack = false
		if event["type"] == "death" and CoreUtil.to_int(event["side"]) != friendly and pre_attack:
			opening_deaths += 1
		if event["type"] == "hit" and CoreUtil.to_int(event["side"]) == friendly:
			hits += 1
		if event["type"] == "summon" and CoreUtil.to_int(event["side"]) == friendly:
			summons += 1
	var used: bool = triggered
	match str(effect.get("mechanic", "")):
		"mouse_catapult", "mouse_pile_on", "mouse_ballista", "mouse_engines":
			used = hits > 0
		"cleave":
			used = splashes > 0
		"death_summon":
			used = summons > 0
		"pigeon_lieutenant":
			used = row_attacks > 0
	if effect.has("card"):
		used = hits > 0 or summons > 0 or positive_buffs > 0
		if effect["card"] == "lieutenant":
			used = opening_damage > 0 if effect["original_lieutenant"] else row_attacks > 0
	return {
		"set_up": buff or used,
		"splashes": splashes,
		"opening_damage": opening_damage,
		"stats": starting_stats,
		"margin": margin,
		"opening_kills": opening_deaths,
		"hits": hits,
		"row_attacks": row_attacks,
		"summons": summons,
		"positive_buffs": positive_buffs
	}
