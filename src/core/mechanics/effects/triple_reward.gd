extends Mechanic
## 7.3.6 the Triple Reward: Discover a unit from the tier above the player's tier when cast,
## or the top tier at the top (Rules.triple_reward_tier).


func on_played(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	if ctx.trigger(unit, &"triple_reward"):
		var tier: int = ctx.session.rules.triple_reward_tier(ctx.player)
		ctx.discover(tier, tier)
