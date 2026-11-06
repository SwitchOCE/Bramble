extends RefCounted
## Which sounds each fight event makes. Pure, so tests can check it. Call after the model has
## applied the event. Only played events reach here: a skipped fight is silent.

const Data := preload("res://src/ui/view_data.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")

## A hit of up to this much damage is small, then medium; more is big.
const SMALL_HIT: int = 2
const MEDIUM_HIT: int = 6


static func hit_name(amount: int) -> String:
	if amount <= SMALL_HIT:
		return "hit_small"
	return "hit_medium" if amount <= MEDIUM_HIT else "hit_big"


static func names_for(event: Dictionary, model: CombatModel, bottom_side: int) -> PackedStringArray:
	var names: PackedStringArray = []
	match str(event.get("type", "")):
		"attack":
			names.append("attack")
			var attacker: Dictionary = model.unit(Data.i(event, "attacker", -1))
			var voice: String = Sfx.voice_for(Data.a(attacker, "tribes"))
			if not voice.is_empty():
				names.append(voice)
		"damage":
			names.append(hit_name(Data.i(event, "amount", 0)))
		"death":
			names.append("death")
		"summon":
			names.append("summon")
		"trigger", "whistle", "health_loss":
			names.append("keyword")
		"status":
			if Data.b(event, "on", true):
				names.append("keyword")
		"slot_mark", "slot_hex":
			names.append("ring")
		"combat_end":
			names.append(_result_name(model.winner, bottom_side))
	return names


## A tie has no fanfare either way: the end-of-turn knock.
static func _result_name(winner: int, bottom_side: int) -> String:
	if winner < 0:
		return "turn_end"
	return "win" if winner == bottom_side else "loss"


static func play(event: Dictionary, model: CombatModel, bottom_side: int) -> void:
	for sound: String in names_for(event, model, bottom_side):
		Sfx.play(sound)
