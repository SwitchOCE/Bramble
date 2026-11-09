class_name BotAim
extends RefCounted
## Target selection for cards and powers, using the brain's current player and valuation.


## The target worth the most, including a deliberate Shy departure.
static func best_slot(brain: BotBrain, legal: Array[int], card_def: Dictionary) -> int:
	if brain.level.reads_text and str(card_def.get("id", "")) == "pelt":
		return BotHunt.pelt_aim(brain._player, legal)
	if BotPass3.active(brain._player) and brain.level.reads_text:
		var thank: int = BotPass3.thank_aim(
			brain._player, HandItem.make(card_def, 0), legal, brain._rules.config
		)
		if thank >= 0:
			return thank
	var aim_at: String = str(
		brain.knowledge.card(str(card_def.get("id", ""))).get("aim_at", "carry")
	)
	if not brain.level.plans_position and (aim_at == "in_front" or aim_at == "behind"):
		aim_at = "carry"
	var best: int = legal[0]
	var best_score: float = -100000.0
	for slot: int in legal:
		var score: float = BotCommitment.aim_value(card_def, slot, brain._player)
		if str(card_def.get("id", "")) == "horseshoe":
			score = BotContent5.horseshoe_value(brain._player, slot)
		elif not BotCommitment.has_live_aim(card_def):
			score = brain._aim_score(slot, aim_at)
		var added: Vector2i = HandItem.make(card_def, 0).ring_add()
		if BotPass3.active(brain._player) and str(card_def.get("id", "")) == "golden_egg":
			score = BotPass3.egg_aim(brain._player, slot)
		elif BotPass3.active(brain._player) and added != Vector2i.ZERO:
			score = BotPass3.ring_aim(brain._player, slot)
		elif added != Vector2i.ZERO:
			var rings: Array = brain._player.slot_effects[slot]
			var actual: Vector2i = BoardUpkeep.ring_room(rings, added)
			score = (score + 2.0) * float(actual.x + actual.y) / float(added.x + added.y)
		if score > best_score:
			best = slot
			best_score = score
	return best
