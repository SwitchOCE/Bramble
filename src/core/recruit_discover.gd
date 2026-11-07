class_name RecruitDiscover
extends RefCounted
## Discover generation, including Hiring Fair's one guaranteed kin option. All picks
## reserve real pool copies and stay distinct; the remaining choices stay open.


static func run(rules: RecruitRules, player: PlayerState, step: Dictionary) -> void:
	var from_spells: bool = str(step.get("kind", "unit")) == "spell"
	var source_pool: UnitPool = rules.spell_pool if from_spells else rules.pool
	if source_pool == null:
		return
	var pick: CardPick = _pick(rules, player, step)
	var options: PackedStringArray = _guarantee(player, step, pick, source_pool)
	var guaranteed: int = options.size()
	pick.exclude = options
	pick.count -= guaranteed
	options.append_array(pick.run(source_pool, player.discover_rng))
	pick.count += guaranteed
	var top_tier: int = pick.max_tier
	# A Discover from one tier shows its full count: a thin tier is topped up from the tiers below.
	var wider: int = pick.min_tier - 1
	while options.size() < pick.count and wider >= 1:
		pick.min_tier = wider
		pick.max_tier = wider
		pick.count -= options.size()
		pick.exclude = options
		var more: PackedStringArray = pick.run(source_pool, player.discover_rng)
		pick.count += options.size()
		options.append_array(more)
		wider -= 1
	pick.max_tier = top_tier
	if options.is_empty():
		return
	player.pending.append(
		{
			"kind": "discover",
			"options": options,
			"spells": from_spells,
			"round": player.round_number
		}
	)
	player.log_event("discover", {"options": ",".join(options)})
	if rules.choice_observer.is_valid():
		rules.choice_observer.call(player, pick, options)


static func _pick(rules: RecruitRules, player: PlayerState, step: Dictionary) -> CardPick:
	var count: int = CoreUtil.to_int(step.get("count", rules.config.get_int("discover_options")))
	var tier: Variant = step.get("tier", "current")
	var top: int = player.tier
	var bottom: int = 1
	if str(tier) == "next":
		top = mini(player.tier + 1, UnitLibrary.TIERS)
		bottom = top
	elif str(tier) == "same":
		bottom = top
	elif str(tier) != "current":
		top = CoreUtil.to_int(tier)
		bottom = top
	var pick: CardPick = CardPick.spec(count, top, bottom)
	pick.distinct = true
	if step.has("tribe"):
		pick.tribes = PackedStringArray([str(step["tribe"])])
	if step.has("not_tribe"):
		pick.not_tribes = PackedStringArray([str(step["not_tribe"])])
	return pick


static func _guarantee(
	player: PlayerState, step: Dictionary, pick: CardPick, pool: UnitPool
) -> PackedStringArray:
	var threshold: int = CoreUtil.to_int(step.get("commitment", 0))
	if threshold <= 0:
		return PackedStringArray()
	var counts: Dictionary = {}
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		for tribe: Variant in unit.tribes():
			counts[tribe] = CoreUtil.to_int(counts.get(tribe, 0)) + 1
	var tribes: PackedStringArray = []
	for tribe: Variant in counts:
		if CoreUtil.to_int(counts[tribe]) >= threshold:
			tribes.append(str(tribe))
	if tribes.is_empty():
		return PackedStringArray()
	var guaranteed: CardPick = CardPick.spec(1, pick.max_tier, pick.min_tier)
	guaranteed.tribes = tribes
	return guaranteed.run(pool, player.discover_rng)
