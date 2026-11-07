extends BotBrain
## A/A null arm: exactly Hard's policy with a different, reproducible bot-choice stream.
## XOR is a bijection of seed space. Shops, combat, pairing and build deals keep their streams.

const STREAM_SALT: int = 0x5A17C3D
var _stream_ready: bool = false


func _prepare_stream(player: PlayerState) -> void:
	if not _stream_ready:
		player.bot_rng.seed = player.bot_rng.seed ^ STREAM_SALT
		_stream_ready = true


func pick_hero(offer: PackedStringArray, player: PlayerState) -> int:
	_prepare_stream(player)
	return super.pick_hero(offer, player)


func play_turn(player: PlayerState, rules: RecruitRules, round_number: int) -> void:
	_prepare_stream(player)
	super.play_turn(player, rules, round_number)
