class_name LineBrain
extends BotBrain
## Hard's legal actions, text values, heroes, Bellies and economy, with a fixed scripted line.
## Blind placement is deliberate: each captured layout is fixed independently of the field.

var line_id: String = "line_fast"
var profile: Dictionary = {}
var fallback_from: String = ""


func configure_line(id: String) -> void:
	line_id = id
	var entry: Dictionary = LinePolicies.profiles()[id]
	profile = entry.duplicate(true)
	pinned_strategy = id
	value.strategy = LinePolicies.strategy(id)
	level.set_place(BotLevel.PLACE_BLIND)


func play_turn(player: PlayerState, rules: RecruitRules, round_number: int) -> void:
	var tribe: String = str(profile["tribe"])
	if tribe != "" and not rules.lobby_tribes.is_empty() and not rules.lobby_tribes.has(tribe):
		fallback_from = line_id
		configure_line("line_fast")
	super.play_turn(player, rules, round_number)


func _choose_build() -> void:
	# Committed from the start; Hard still reads live text, spells and reachable purchases.
	pass


func _open_with_a_plan() -> void:
	_opening_plan = "economy" if CoreUtil.to_bool(profile["engine"]) else "tempo"
	super._open_with_a_plan()


func _target_round(tier: int) -> int:
	var schedule: Array = profile["climb_schedule"]
	return CoreUtil.to_int(schedule[clampi(tier - 1, 0, schedule.size() - 1)])


func _climb(leftover: bool) -> void:
	# The shared brain's leftover climb is one round early. A line follows its stated schedule.
	if not leftover:
		super._climb(false)


func _held_back() -> int:
	var reserve: int = super._held_back()
	if (
		CoreUtil.to_bool(profile["engine"])
		and _round_now <= CoreUtil.to_int(profile["save_until"])
		and _player.board_count() >= 3
		and _player.health > LOW_HEALTH
	):
		reserve = maxi(reserve, CoreUtil.to_int(profile["save_threshold"]))
	return reserve
