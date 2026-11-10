class_name UpsetCombat
extends Combat
## Controlled interventions. The class is masked jointly on both sides, never just the winner.

const CLASS_PICKS: Array[String] = ["biggest", "highest_attack", "highest_health"]
const ENEMY_SELECTS: Array[String] = ["enemies", "mired", "enemy_front_row", "enemy_back_row"]
const NATIVE_CLASS: Array[String] = ["scale_answer", "snap", "whistle", "nightshade_mark"]
# Native audit: scale_answer, Snap, Whistle and prototype Nightshade rank enemies. Shared
# scripts also require an audited ability below; new variants must not inherit approval.
# Whole-library masking covers definitions later reached through copies/summons/text theft.
const AUDITED_NATIVE: Array[String] = [
	"aspic",
	"back_row_immunity",
	"back_strike",
	"band_attack",
	"beadle",
	"belly",
	"belly_discount",
	"bide_slumber",
	"bitter",
	"bog_answer",
	"bog_aura",
	"borrows_text",
	"both_ends",
	"bridge_toad",
	"bristle",
	"brock_aura",
	"bubble",
	"bufo",
	"bystander",
	"changeling",
	"cleave",
	"cradle_fetch",
	"cuckoo",
	"cut_and_come",
	"damage_reduction",
	"death_summon",
	"dunnock",
	"eats_acorns",
	"echo",
	"elder_ooze",
	"end_turn_doubler",
	"ermeline",
	"fairy_monarch",
	"fast",
	"figgy_duff",
	"fly_south",
	"gabble_ratchet",
	"glutton",
	"goodman_hayward",
	"granny",
	"grant_first_bite_in_front",
	"grey_agnes",
	"grizel",
	"hasty",
	"hex",
	"hit_reactor",
	"hunker",
	"jack_daw",
	"jenny",
	"kiss",
	"laird",
	"lantern_man",
	"larder_stats",
	"lend_quarry",
	"lodger",
	"lump",
	"mag_pye",
	"mark",
	"mire",
	"moss_ooze",
	"mother_goose",
	"mr_pym",
	"mrs_clover",
	"mrs_mallow",
	"nell",
	"nightshade_on_hit",
	"no_quarry",
	"old_isegrim",
	"old_tern",
	"on_attack_buff_tribe",
	"pack",
	"parasite",
	"peat_king",
	"peck",
	"pie",
	"pin",
	"poach",
	"pounce",
	"quarry",
	"quick_while_undamaged",
	"rainbow",
	"rainbow_paint",
	"ranocchio",
	"redbreast",
	"redwing",
	"reel_mistress",
	"row_swap",
	"sable",
	"savings",
	"scale_economy",
	"scale_engine",
	"sergeant",
	"shell",
	"shield",
	"shy",
	"silky",
	"skip_across",
	"snap_kill",
	"spell_discount",
	"stone_soup",
	"survive_buff_behind",
	"swarm",
	"swoop",
	"syllabub",
	"take_gold",
	"teind",
	"tiddy_mun",
	"toll_bard",
	"tom_tit",
	"urchin",
	"vault",
	"whistlers",
	"wick",
	"wobbly"
]
const AUDITED_WAVE1: Dictionary = {
	"pass3_bird":
	[
		"chiffchaff",
		"cuckoo",
		"dunnock",
		"goose",
		"jack_daw",
		"jay",
		"lump",
		"mag_pye",
		"old_tern",
		"ratchet",
		"redbreast",
		"redwing",
		"stork",
		"swallow",
		"tom_tit",
		"whistlers"
	],
	"pass3_fairy":
	[
		"annis",
		"belladonna",
		"changeling",
		"chaser",
		"cluricaun",
		"fetch",
		"hob",
		"lob",
		"monarch",
		"nan",
		"queen",
		"reel",
		"sally",
		"silky",
		"will",
		"witch"
	],
}

# Each Bog ability is audited independently; true means a ranked enemy selector to mask.
# Snap stays a separate native class entry rather than approving all pass3_bog dispatches.
const AUDITED_BOG: Dictionary = {
	"bufo": false,
	"chorus": false,
	"cutter": false,
	"frog": false,
	"gideon": false,
	"hopkin": false,
	"jenny": true,
	"king": false,
	"lantern": true,
	"nan": false,
	"pretender": false,
	"ranocchio": false,
	"sal": false,
	"soak": false,
	"tiddy": false,
}

# Hunter reward ranking is bookkeeping; only Isegrim aims a combat answer at biggest.
const AUDITED_HUNTERS: Dictionary = {
	"nip": false,
	"wick": false,
	"young_brock": false,
	"sable": false,
	"lane_bard": false,
	"russet": false,
	"brother_wolf": false,
	"lodger": false,
	"lutra": false,
	"ermeline": false,
	"old_brock": false,
	"agnes": false,
	"grizel": false,
	"glutton": false,
	"laird": false,
	"isegrim": true,
}

# Eat/Digest, Soup, Aspic and Elder read own bodies. Posset follows the actual killer,
# Granny gathers friendlies, and release hooks select no enemy by size. Only Hasty ranks enemies.
const AUDITED_OOZES: Dictionary = {
	"little_dollop": false,
	"mrs_posset": false,
	"wee_wobbly": false,
	"stone_soup": false,
	"dishwater_nell": false,
	"moss_ooze": false,
	"aunt_aspic": false,
	"bubble_and_squeak": false,
	"sixpenny_pie": false,
	"frumenty": false,
	"figgy_duff": false,
	"mr_syllabub": false,
	"elder_ooze": false,
	"hasty_pudding": true,
	"granny_stir_up": false,
	"cut_and_come_again": false,
}

# All sixteen are independent: recruit ranking reads friendlies; the Sergeant aims across
# and spends Larder items. Urchin follows reverse Pass order. None ranks an enemy by size.
const AUDITED_HEDGEROW: Dictionary = {
	"mrs_burdock": false,
	"mr_crumb": false,
	"sleeping_partner": false,
	"mrs_clover": false,
	"mr_pym": false,
	"mrs_sorrel": false,
	"mrs_mallow": false,
	"dr_urchin": false,
	"sergeant_at_conkers": false,
	"alderman_dozey": false,
	"beadle_warrenby": false,
	"honorary_treasurer": false,
	"goodman_hayward": false,
	"standing_committee": false,
	"squire_lollop": false,
	"old_mother_mast": false,
}

var flip_first_attack: bool = false
var first_side_original: int = -1
var first_side_used: int = -1
var first_coin_eligible: bool = false


func _first_side() -> int:
	# Consume precisely the ordinary draw before overriding its result. Start of Combat's
	# separate player-order decision and all later random draws keep their original states.
	first_coin_eligible = units_of(0).size() == units_of(1).size()
	first_side_original = super._first_side()
	first_side_used = (
		1 - first_side_original
		if flip_first_attack and first_coin_eligible
		else first_side_original
	)
	return first_side_used


static func run_input(
	input: Dictionary,
	configured_library: UnitLibrary,
	flip: bool = false,
	record_events: bool = false
) -> Dictionary:
	assert(CoreUtil.to_int(input["version"]) == 1)
	var config_values: Dictionary = input["config"]
	var game_config: GameConfig = FightCapture.config_for(config_values)
	var fight_rng := RandomNumberGenerator.new()
	fight_rng.seed = str(input["rng_seed"]).to_int()
	fight_rng.state = str(input["rng_state"]).to_int()
	var combat := UpsetCombat.new()
	combat.library = configured_library
	combat.config = game_config
	combat.rng = fight_rng
	combat.effect_rng = RandomNumberGenerator.new()
	combat.effect_rng.seed = str(input["effect_rng_seed"]).to_int()
	combat.effect_rng.state = str(input["effect_rng_state"]).to_int()
	combat.log_events = record_events
	combat.flip_first_attack = flip
	var slots: Array = input["slots"]
	var heroes: Array = input["hero_effects"]
	var rules: Array = input["fight_rules"]
	var boards: Array = input["boards"]
	combat.slot_effects = slots.duplicate(true)
	combat.hero_effects = heroes.duplicate(true)
	combat.side_rules = rules.duplicate(true)
	combat.round_number = CoreUtil.to_int(input["round"])
	var tiers: Array[int] = []
	var ids: Array[int] = []
	for tier: Variant in input["tiers"]:
		tiers.append(CoreUtil.to_int(tier))
	for id: Variant in input["player_ids"]:
		ids.append(CoreUtil.to_int(id))
	var result: Dictionary = combat.run(
		boards.duplicate(true), tiers, ids, CoreUtil.to_int(input["damage_cap"])
	)
	return {
		"result": result,
		"first_side_original": combat.first_side_original,
		"first_side_used": combat.first_side_used,
		"first_coin_eligible": combat.first_coin_eligible,
	}


## Apply the capture overlay once, then clone privately. run_input never reapplies it.
static func prepare(input: Dictionary, source: UnitLibrary) -> Dictionary:
	var values: Dictionary = input["config"]
	var configured: UnitLibrary = FightCapture.library_for(values, source)
	var private := UnitLibrary.new()
	var manifest: Array = []
	var unsupported: Array = []
	for unit: Dictionary in configured.all_units():
		var masked: Dictionary = _walk(
			unit, "library.units." + str(unit["id"]), manifest, unsupported
		)
		assert(private.register_unit(masked) == "")
	for card: Dictionary in configured.all_cards():
		var masked: Dictionary = _walk(
			card, "library.cards." + str(card["id"]), manifest, unsupported
		)
		private.register_card(masked)
	for hero: Dictionary in configured.all_heroes():
		var masked: Dictionary = _walk(
			hero, "library.heroes." + str(hero["id"]), manifest, unsupported
		)
		private.register_hero(masked)
	var masked_input: Dictionary = _walk(input, "input", manifest, unsupported)
	return {
		"input": masked_input,
		"library": private,
		"intact_library": configured,
		"manifest": manifest,
		"unsupported": unsupported,
		"supported": unsupported.is_empty(),
		"scope":
		"joint largest-enemy answer/targeting class; audited native stat-ranked picks; data steps",
	}


## Deterministic board-local intervention. Unit specs move whole; slot effects/rules stay fixed.
static func alternate_layout(board_id: String, board: Array, rules: Dictionary) -> Dictionary:
	assert(board.size() == BoardGeometry.SLOTS)
	var pins: Array[int] = []
	for nest: Dictionary in rules.get("nests", []):
		var slot: int = CoreUtil.to_int(nest["slot"])
		if not pins.has(slot):
			pins.append(slot)
	for slot: int in board.size():
		if board[slot] != null:
			var spec: Dictionary = board[slot]
			if str(spec["def_id"]) == HeldUnits.EGG and not pins.has(slot):
				pins.append(slot)
	pins.sort()
	var movable: Array[int] = []
	for slot: int in board.size():
		if not pins.has(slot):
			movable.append(slot)
	var destinations: Array[int] = movable.duplicate()
	var layout_rng := RandomNumberGenerator.new()
	var layout_seed: int = ("upset-layout-v1|" + board_id).sha256_text().substr(0, 15).hex_to_int()
	layout_rng.seed = layout_seed
	for index: int in range(destinations.size() - 1, 0, -1):
		var other: int = layout_rng.randi_range(0, index)
		var saved: int = destinations[index]
		destinations[index] = destinations[other]
		destinations[other] = saved
	var out: Array = board.duplicate(true)
	var mapping: Array[int] = []
	for slot: int in board.size():
		mapping.append(slot)
	for index: int in movable.size():
		mapping[movable[index]] = destinations[index]
		out[destinations[index]] = board[movable[index]]
	var changed: bool = FightCapture.canonical(out) != FightCapture.canonical(board)
	return {
		"board": out.duplicate(true),
		"old_to_new": mapping,
		"pinned_slots": pins,
		"seed": str(layout_seed),
		"changed": changed,
		"scope":
		"combat layout sensitivity; unarchived recruit timers prevent legality/optimality claims",
	}


static func _walk(value: Variant, path: String, manifest: Array, unsupported: Array) -> Variant:
	if value is Array:
		var source_list: Array = value
		var masked_list: Array = []
		for index: int in source_list.size():
			var child: Variant = _walk(
				source_list[index], "%s[%d]" % [path, index], manifest, unsupported
			)
			if child != null or source_list[index] == null:
				masked_list.append(child)
		return masked_list
	if not value is Dictionary:
		return value
	var original: Dictionary = value
	var out: Dictionary = original.duplicate(true)
	out.erase(MechanicRegistry.COMPILED_KEY)
	var id: String = str(original.get("id", ""))
	var is_entry: bool = (
		id != ""
		and not original.has("mechanics")
		and (path.contains("mechanics[") or path.ends_with(".entry") or path.ends_with(".mechanic"))
	)
	if (
		is_entry
		and (
			NATIVE_CLASS.has(id)
			or (
				id == "pass3_bog"
				and CoreUtil.to_bool(AUDITED_BOG.get(str(original.get("ability", "")), false))
			)
			or (
				id == "pass3_hunter"
				and CoreUtil.to_bool(AUDITED_HUNTERS.get(str(original.get("ability", "")), false))
			)
			or (
				id == "pass3_ooze"
				and CoreUtil.to_bool(AUDITED_OOZES.get(str(original.get("ability", "")), false))
			)
		)
	):
		(
			manifest
			. append(
				{
					"path": path,
					"kind": "native",
					"mechanic": id,
					"removed": original.duplicate(true),
				}
			)
		)
		return null
	if is_entry and id != "effect" and not _audited_native(original):
		(
			unsupported
			. append(
				{
					"path": path,
					"reason": "unaudited native mechanic or ability",
					"mechanic": id,
					"ability": str(original.get("ability", "")),
				}
			)
		)
	if original.has("do") and (id == "effect" or original.has("trigger")):
		return _effect(original, path, manifest, unsupported)
	for key: String in out.keys():
		var child: Variant = _walk(out[key], path + "." + key, manifest, unsupported)
		if child == null and out[key] is Dictionary:
			# A grant whose entire mechanic was removed must not remain as an invalid grant.
			if key == "entry" or key == "mechanic":
				return null
		out[key] = child
	return out


static func _audited_native(entry: Dictionary) -> bool:
	var id: String = str(entry.get("id", ""))
	if id == "pass3_hedgerow":
		return AUDITED_HEDGEROW.has(str(entry.get("ability", "")))
	if id == "pass3_ooze":
		return AUDITED_OOZES.has(str(entry.get("ability", "")))
	if id == "pass3_hunter":
		return AUDITED_HUNTERS.has(str(entry.get("ability", "")))
	if id == "pass3_bog":
		return AUDITED_BOG.has(str(entry.get("ability", "")))
	if AUDITED_WAVE1.has(id):
		var abilities: Array = AUDITED_WAVE1[id]
		return abilities.has(str(entry.get("ability", "")))
	return AUDITED_NATIVE.has(id)


static func _effect(
	entry: Dictionary, path: String, manifest: Array, unsupported: Array
) -> Variant:
	var kept: Array = []
	var removed: int = 0
	var steps: Array = MechanicRegistry.steps_of(entry)
	for index: int in steps.size():
		var step: Dictionary = steps[index]
		var selector: Dictionary = step.get("target", entry.get("target", {}))
		var step_path: String = "%s.do[%d]" % [path, index]
		if (
			ENEMY_SELECTS.has(str(selector.get("select", "")))
			and CLASS_PICKS.has(str(selector.get("pick", "")))
		):
			manifest.append(
				{
					"path": step_path,
					"kind": "data_step",
					"selector": selector.duplicate(true),
					"removed": step.duplicate(true)
				}
			)
			removed += 1
		else:
			var child: Variant = _walk(step, step_path, manifest, unsupported)
			if child != null:
				kept.append(child)
			else:
				removed += 1
	if kept.is_empty() and removed > 0:
		return null
	if removed > 0:
		for key: String in ["once", "limit", "every", "lifetime", "count_amount"]:
			if entry.has(key):
				unsupported.append(
					{
						"path": path,
						"reason": "mixed answer and other steps share stateful limits",
						"key": key
					}
				)
	var out: Dictionary = entry.duplicate(true)
	out.erase(MechanicRegistry.COMPILED_KEY)
	out["do"] = kept
	return out
