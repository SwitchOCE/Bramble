class_name Pass3TriggerGuards
extends RefCounted
## Extra firings may repeat ordinary payoffs, but cannot advance clocks or repeat multipliers.


static func extra(world: EffectWorld) -> bool:
	var ctx: RecruitContext = world as RecruitContext
	return (
		ctx != null
		and ctx.repeat_index > 0
		and ctx.player.pass3_content
		and ctx.rules.config.get_value("pass3_loop_guards") != false
	)


static func doubling(step: Dictionary) -> bool:
	if str(step.get("effect", "")) == "multiply":
		return true
	if str(step.get("effect", "")) != "stat_fraction":
		return false
	var numerator: int = CoreUtil.to_int(step.get("numerator", 1))
	var denominator: int = maxi(1, CoreUtil.to_int(step.get("denominator", 2)))
	return (
		(str(step.get("operation", "set")) == "gain" and numerator >= denominator)
		or (str(step.get("operation", "set")) == "set" and numerator >= denominator * 2)
	)
