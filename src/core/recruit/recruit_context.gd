class_name RecruitContext
extends RefCounted
## What a Recruit Phase hook may do, for one player during one action. Mechanics call these and
## never touch the player, the pool or the log directly. Counts triggers against the per-action
## limit (9.10.2).

var session: GameSession
var player: PlayerState
var rng: Rng
var _recruit: Recruit
var _triggers: int = 0
var _limit: int = 1000


func _init(game: GameSession, recruit: Recruit, who: PlayerState) -> void:
	session = game
	_recruit = recruit
	player = who
	rng = recruit.effect_rng(who)
	_limit = game.config.action_trigger_limit


func geometry() -> BoardGeometry:
	return session.geometry


## Call before a hook acts: logs the trigger. False once the action's trigger limit is reached,
## and the hook must then do nothing.
func trigger(unit: Unit, mechanic_id: StringName) -> bool:
	if _triggers >= _limit:
		return false
	_triggers += 1
	session.log_event(
		{"type": "trigger", "player": player.id, "uid": unit.uid, "mechanic": String(mechanic_id)}
	)
	return true


func triggers_used() -> int:
	return _triggers


## 12.1.1: `permanent` for the rest of the game, otherwise this turn.
func buff(unit: Unit, attack: int, health: int, permanent: bool, source: Unit) -> void:
	if permanent:
		unit.stats.perm_attack += attack
		unit.stats.perm_health += health
	else:
		unit.stats.turn_attack += attack
		unit.stats.turn_health += health
	var event: Dictionary = {
		"type": "buff",
		"player": player.id,
		"uid": unit.uid,
		"attack": unit.attack(),
		"health": unit.health(),
		"source_uid": source.uid if source != null else -1,
		"duration": "permanent" if permanent else "turn",
	}
	session.log_event(event)


func gain_gold(amount: int, source: Unit) -> void:
	player.gold = maxi(0, player.gold + amount)
	session.log_event(
		{
			"type": "gold",
			"player": player.id,
			"amount": amount,
			"gold": player.gold,
			"source_uid": source.uid
		}
	)


## 8.4.7 a summon in the Recruit Phase: placed by 8.4, Created (4.3.1). Null when it fails.
func summon(card_id: StringName, source_slot: int) -> Unit:
	return _recruit.summon(player, card_id, source_slot)


## 6.2 Discover a unit with a tier in [min_tier, max_tier].
func discover(min_tier: int, max_tier: int) -> void:
	_recruit.offer_discover(player, min_tier, max_tier)


## The units on this player's board for a selector (Selectors), in reading order.
func select(unit: Unit, selector: String) -> Array[Unit]:
	var out: Array[Unit] = []
	for slot: int in Selectors.slots(session.geometry, unit.slot, player.occupied(), selector):
		out.append(player.board[slot])
	return out


func random_of(units: Array[Unit]) -> Unit:
	if units.is_empty():
		return null
	return units[rng.index(units.size())]
