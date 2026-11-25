extends GutTest
## The buy screen's lights (buy-screen-l1.md §9): each is an engine light where it should be, in its
## tier's colour at its tier's strength, and absent where it should be (an empty arch, a plain
## unit, an unlit lantern, End turn while there is still something to do).

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")

var _screen: RecruitScreen


func after_each() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _mockup() -> Dictionary:
	return GlassScreen.load_state("res://tests/screens/fixtures/recruit_mockup.json")


func _make(state: Dictionary) -> RecruitScreen:
	_screen = SCREEN.instantiate()
	_screen.state = state
	add_child_autofree(_screen)
	_screen.settle()
	return _screen


func _find(node_name: String) -> Node:
	return _screen.get_node("Frame/Stage").find_child(node_name, true, false)


func _arch(i: int) -> L1ShopArch:
	return _find("ShopSlot_%d" % i) as L1ShopArch


## The share of the tier's strength a that a light of the arch takes, from the layout file.
func _a(tier: int) -> float:
	return L1Layout.shop_tint(tier).a


func _glint(card: GlassCard) -> Color:
	var face: L1CardFace = card.get_node("Face")
	var mat: ShaderMaterial = face.material
	var colour: Color = mat.get_shader_parameter("glint_colour")
	return colour


func _shop_state(tiers: Array) -> Dictionary:
	var state: Dictionary = _mockup()
	var units: Array = state["shop_units"]
	for i: int in tiers.size():
		if tiers[i] == 0:
			units[i] = null
		else:
			var unit: Dictionary = units[i]
			unit["tier"] = tiers[i]
	return state


func test_tier_strength_follows_the_owner_scale() -> void:
	var a: Array[float] = []
	for tier: int in range(1, 7):
		a.append(_a(tier))
	for tier: int in range(1, 4):
		assert_lt(a[tier - 1], a[tier], "tier %d is lit less than tier %d" % [tier, tier + 1])
	assert_gt(a[5], a[3], "tier 6 is stronger than tier 4")
	assert_lt(a[5], a[4], "and weaker than tier 5")


func test_each_shop_arch_is_lit_in_its_tier_colour_and_strength() -> void:
	_make(_shop_state([1, 2, 3, 6, 5]))
	for i: int in 5:
		var arch: L1ShopArch = _arch(i)
		var tier: int = arch.tier
		var tint: Color = L1Layout.shop_tint(tier)
		for light_name: String in ["Recess", "Spill", "Pool", "Halo"]:
			var light: L1Light = arch.light(light_name)
			assert_not_null(light, "arch %d has its %s light" % [i, light_name])
			assert_true(light.visible, "%s of arch %d is lit" % [light_name, i])
			assert_eq(
				light.colour, Color(tint, 1.0), "%s takes tier %d's colour" % [light_name, tier]
			)
			assert_true(light.material is ShaderMaterial, "%s is drawn by a shader" % light_name)
		var halo: L1Light = arch.light("Halo")
		assert_almost_eq(halo.strength(), L1Layout.number("light.shop.halo.share") * tint.a, 1e-5)
		var spill: L1Light = arch.light("Spill")
		assert_almost_eq(spill.strength(), L1Layout.number("light.shop.spill.share") * tint.a, 1e-5)
		var recess: L1Light = arch.light("Recess")
		var fill: Vector4 = (recess.material as ShaderMaterial).get_shader_parameter("fill")
		assert_almost_eq(fill.x, L1Layout.number("light.shop.recess.centre_share") * tint.a, 1e-5)
	assert_gt(
		_arch(3).light("Halo").strength(),
		_arch(2).light("Halo").strength(),
		"tier 6 glows more than tier 3"
	)
	assert_lt(
		_arch(3).light("Halo").strength(), _arch(4).light("Halo").strength(), "and less than tier 5"
	)


func test_tier_6_breathes_the_most() -> void:
	_make(_shop_state([4, 5, 6, 1, 2]))
	var depths: Array[float] = []
	for i: int in 5:
		var motion: Vector4 = (
			(_arch(i).light("Halo").material as ShaderMaterial).get_shader_parameter("motion")
		)
		depths.append(motion.y)
	assert_gt(depths[0], 0.0, "the arches breathe")
	var deepest: float = depths.max()
	assert_eq(deepest, depths[2], "tier 6's arch breathes deepest")
	assert_gt(depths[2], depths[0])


func test_an_empty_arch_is_dark() -> void:
	_make(_shop_state([1, 0, 3, 4, 2]))
	var empty: L1ShopArch = _arch(1)
	assert_eq(empty.tier, 0)
	assert_false(empty.light("Halo").visible, "no halo where no card is")
	assert_false(empty.light("Pool").visible, "no pool")
	assert_false(empty.light("Spill").visible, "no light spilling")
	var recess: L1Light = empty.light("Recess")
	assert_true(recess.visible, "the dark recess is still drawn")
	assert_eq(recess.strength(), 0.0, "with no glow of its own")
	var fill: Vector4 = (recess.material as ShaderMaterial).get_shader_parameter("fill")
	assert_eq(Vector3(fill.x, fill.y, fill.z), Vector3.ZERO, "and none inside")


func test_each_shop_spell_is_lit_in_its_tier() -> void:
	var state: Dictionary = _mockup()
	var spells: Array = state["shop_spells"]
	var first: Dictionary = spells[0]
	var second: Dictionary = spells[1]
	first["tier"] = 2
	second["tier"] = 5
	_make(state)
	for k: int in 2:
		var tier: int = [2, 5][k]
		var light: L1Light = _find("SpellLight_%d" % k)
		assert_not_null(light, "spell %d has its light" % k)
		var tint: Color = L1Layout.shop_tint(tier)
		assert_eq(light.colour, Color(tint, 1.0))
		assert_almost_eq(
			light.strength(),
			(
				(
					L1Layout.number("light.spell.near.share")
					+ L1Layout.number("light.spell.far.share")
				)
				* tint.a
			),
			1e-5
		)
		assert_eq(light.shape_rect.get_center(), _screen.spell_xy(k) + light.shape_rect.size / 2.0)
	state["shop_spells"] = [null, spells[1]]
	_make(state)
	assert_null(_find("SpellLight_0"), "an empty spell place has no light")
	assert_not_null(_find("SpellLight_1"))


func test_only_lit_lanterns_and_beads_give_light() -> void:
	var state: Dictionary = _mockup()
	state["tier"] = 3
	state.merge({"refresh_step_size": 10, "refreshes_left": 4})
	_make(state)
	for i: int in 6:
		var light: Node = _find("LanternLight_%d" % i)
		if i < 3:
			assert_not_null(light, "lantern %d is lit at level 3" % i)
		else:
			assert_null(light, "lantern %d is dark at level 3" % i)
	var beads: L1RefreshBeads = _find("RefreshBeads")
	var lit: int = 0
	for child: Node in beads.get_children():
		if child is L1Light:
			lit += 1
	assert_eq(lit, 4, "one light for each refresh left")
	assert_eq(
		(_find("LanternLight_0") as L1Light).colour, L1Layout.colour("light.lantern.light_colour")
	)


func test_a_golden_unit_has_its_halo_rims_and_glint_and_a_plain_one_none() -> void:
	var state: Dictionary = _mockup()
	var board: Array = state["board"]
	var unit: Dictionary = board[0]
	unit["golden"] = true
	_make(state)
	var gold: GlassCard = _screen.node_for("board", 0) as GlassCard
	var plain: GlassCard = _screen.node_for("board", 1) as GlassCard
	assert_true(gold.golden)
	var halo: L1Light = gold.get_node_or_null("GoldenHalo")
	assert_not_null(halo, "a golden unit has a halo")
	assert_eq(halo.colour, L1Layout.colour("light.golden.halo_colour"))
	assert_true(halo.show_behind_parent, "behind the card, never over its art")
	assert_lt(halo.get_index(), gold.get_node("Face").get_index(), "and under its face")
	for stat: String in ["attack", "health"]:
		assert_not_null(gold.get_node_or_null("GoldenRim_" + stat), "a light round its %s" % stat)
	assert_not_null(gold.get_node_or_null("GoldenGlint"), "its twinkle")
	assert_gt(_glint(gold).a, 0.0, "its glint runs")
	for light_name: String in ["GoldenHalo", "GoldenRim_attack", "GoldenGlint"]:
		assert_null(plain.get_node_or_null(light_name), "a plain unit has no %s" % light_name)
	assert_eq(_glint(plain).a, 0.0, "nor a glint")


func test_turning_golden_lights_the_card_and_turning_back_puts_it_out() -> void:
	var card: GlassCard = GlassCard.new()
	card.card_height = 250.0
	add_child_autofree(card)
	assert_null(card.get_node_or_null("GoldenHalo"))
	card.golden = true
	assert_not_null(card.get_node_or_null("GoldenHalo"))
	card.golden = false
	await get_tree().process_frame
	assert_null(card.get_node_or_null("GoldenHalo"), "the light goes with the gilt")


func test_a_card_pointed_at_gets_its_tier_light_and_loses_it_after() -> void:
	var state: Dictionary = _mockup()
	_make(state)
	var tips: RecruitTips = _screen._tips as RecruitTips
	var unit: Control = _screen.node_for("board", 0)
	var board: Array = state["board"]
	var card: Dictionary = board[0]
	var tier: int = GlassPieces.as_int(card["tier"])
	tips.set_hot(unit)
	var light: L1Light = unit.get_node_or_null("TierLight")
	assert_not_null(light, "a board card pointed at shows its tier")
	assert_eq(light.colour, Color(L1Layout.shop_tint(tier), 1.0))
	assert_almost_eq(
		light.strength(), L1Layout.number("light.hover.share") * L1Layout.shop_tint(tier).a, 1e-5
	)
	assert_lt(light.get_index(), unit.get_node("Face").get_index(), "behind the face")
	var hand: Control = _screen.node_for("hand", 0)
	tips.set_hot(hand)
	await get_tree().process_frame
	assert_null(unit.get_node_or_null("TierLight"), "gone when the pointer leaves")
	assert_not_null(hand.get_node_or_null("TierLight"), "a hand card pointed at shows it too")
	var shop: Control = _screen.node_for("shop", 0)
	tips.set_hot(shop)
	assert_null(shop.get_node_or_null("TierLight"), "a shop card has its arch's light instead")


func test_end_turn_glows_only_when_nothing_is_left_to_do_and_flashes_when_pressed() -> void:
	var state: Dictionary = _mockup()
	state["legal_actions"] = [
		{"type": "buy", "spell": false, "index": 0, "slot": -1},
		{"type": "end_turn"},
	]
	_make(state)
	var light: L1Light = _find("EndTurnLight")
	assert_not_null(light)
	assert_false(light.visible, "steady while a buy is left")
	assert_false(RecruitColumns.nothing_left(state))
	state["legal_actions"] = [
		{"type": "sell", "index": 0}, {"type": "freeze"}, {"type": "end_turn"}
	]
	assert_true(RecruitColumns.nothing_left(state), "selling and freezing do not count")
	_make(state)
	light = _find("EndTurnLight")
	assert_true(light.visible, "a slow glow when nothing is left to do")
	assert_gt(light.strength(), 0.0)
	var motion: Vector4 = (light.material as ShaderMaterial).get_shader_parameter("motion")
	assert_gt(motion.y, 0.0, "it breathes")
	assert_false(RecruitColumns.nothing_left({}), "a state without legal actions never says so")
	watch_signals(_screen)
	_screen.ask({"type": "end_turn"})
	assert_signal_emitted(_screen, "action_requested", "End turn still does what it did")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(light.boost(), 0.0, "the swords flash as the fight starts")
