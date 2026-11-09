extends SceneTree
## Capture on the untouched f574eaf tree; compare fixed spell/Fetch dials across pool changes.

const CK := preload("res://tests/core/combat_kit.gd")
const ROSTERS: Array = [
	[
		"mrs_dunnock",
		"mr_redbreast",
		"tom_tit",
		"great_lump",
		"old_tern",
		"gabble_ratchet",
		"seven_whistlers"
	],
	[
		"old_moth_annis",
		"cradle_fetch",
		"hob_in_the_hearth",
		"hedge_witch",
		"nan_toadstool",
		"will_o_the_wisp",
		"reel_mistress"
	],
	[
		"granny_stir_up",
		"moss_ooze",
		"hasty_pudding",
		"elder_ooze",
		"frumenty",
		"bubble_and_squeak",
		"wee_wobbly"
	],
	[
		"mr_pym",
		"mr_crumb",
		"alderman_dozey",
		"goodman_hayward",
		"dr_urchin",
		"squire_lollop",
		"standing_committee"
	],
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(2)
		return
	var library: UnitLibrary = UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	config.set_value("scale_hero_spell_stats", false)
	config.set_value("fairies_fetch_share", 0.5)
	config.set_value("pass3_preset", "A")
	library = ScaleOverlay.library_for(library, config)
	var rows: Array[Dictionary] = []
	for tribe_index: int in ROSTERS.size():
		for sample: int in 2:
			var rng := RandomNumberGenerator.new()
			var seed_value: int = 8701 + tribe_index * 11 + sample
			rng.seed = seed_value
			var combat := Combat.create(library, config, rng)
			var boards: Array = [
				_board(tribe_index, sample), _board((tribe_index + 1) % 4, sample + 1)
			]
			combat.side_rules = [{"pass3_content": true}, {"pass3_content": true}]
			combat.slot_effects = [_rings(), _rings()]
			var result: Dictionary = combat.run(boards, [5, 5], [0, 1], 0)
			rows.append(
				{
					"seed": seed_value,
					"boards": boards,
					"side_rules": combat.side_rules,
					"slot_effects": [_rings(), _rings()],
					"result": JSON.stringify(result)
				}
			)
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(
		(
			JSON.stringify(
				{
					"source_commit": "f574eaf",
					"cases": rows,
					"comparison":
					"spell scaling off; Fetch share one-half; native Birds/Fairies/Oozes/Hedgerow"
				},
				"\t"
			)
			+ "\n"
		)
	)
	print("captured ", rows.size(), " native unchanged-tribe fights")
	quit()


func _board(tribe_index: int, sample: int) -> Array:
	var out: Array = []
	for slot: int in 7:
		var roster: Array = ROSTERS[tribe_index]
		out.append(
			CK.u(str(roster[slot]), 7 + slot * 5 + sample, 18 + slot * 7 + sample, slot == 6)
		)
	return out


func _rings() -> Array:
	var out: Array = [[], [], [], [], [], [], []]
	out[0] = [{"name": "Ring", "count": 2, "attack": 6, "health": 6, "ring_size": 3.0}]
	out[4] = [{"name": "Ring", "count": 5, "attack": 15, "health": 15, "ring_size": 3.0}]
	return out
