class_name RecruitColumns
extends RefCounted
## The turn, scoreboard, hero, and economy readouts in the L1 recruit columns.

const SWORDS: String = (
	'<path d="M5 4l12 12M19 4L7 16M14 18l4-4M10 18l-4-4' + 'M17.5 17.5l2 2M6.5 17.5l-2 2"/>'
)
const RIM_DARK: Color = Color("15191a")
const HEART_INK: Color = Color("fff4ea")
## The actions that mean the player still has something to do (End turn's light).
const END_TURN_ACTS: PackedStringArray = ["buy", "refresh", "upgrade", "play", "pick", "ability"]


static func build_hero(screen: RecruitScreen) -> void:
	var plate: TextureRect = L1ColumnArt.piece("l1p-plate", L1Layout.rect("left.turn"))
	var turn: GlassText = L1ColumnArt.text(
		"Turn %d" % GlassPieces.as_int(screen.state.get("turn", 1)),
		L1Layout.number("left.turn.font"),
		L1ColumnArt.PLATE_INK
	)
	turn.name = "Turn"
	turn.spacing = turn.font_px * L1Layout.number("left.turn.tracking")
	turn.shadow = L1ColumnArt.shadow(
		L1Layout.number("left.turn.shadow_y"), L1Layout.number("left.turn.shadow_blur"), "00000099"
	)
	turn.position = (plate.size - turn.refresh().size) / 2.0
	plate.add_child(turn)
	screen._front.add_child(plate)

	var hero: Dictionary = screen.state.get("hero", {})
	var frame: Rect2 = L1Layout.rect("left.hero")
	var target: Control = L1ColumnArt.area(frame)
	target.name = "Hero"
	var face: Control = L1ColumnArt.area(Rect2(Vector2.ZERO, frame.size))
	target.add_child(face)
	var opening: Rect2 = L1Layout.rect("left.hero.opening")
	var portrait: GlassBox = GlassBox.new()
	portrait.position = opening.position - frame.position
	portrait.box_size = opening.size
	portrait.radii = Vector4.ONE * L1Layout.number("left.hero.radius")
	portrait.image_texture = GlassPieces.portrait(str(hero.get("portrait", "")))
	portrait.layers = [
		{"kind": "image", "size": "cover", "position": [50.0, L1Layout.number("left.hero.focus_y")]}
	]
	portrait.refresh()
	face.add_child(portrait)
	var shading: GlassBox = GlassBox.new()
	shading.box_size = opening.size
	shading.radii = portrait.radii
	shading.border_width = L1Layout.number("left.hero.inset_edge")
	shading.border_colour = Color("ffecbe40")
	var shade_depth: float = (
		L1Layout.number("left.hero.shade_up") + L1Layout.number("left.hero.shade_blur")
	)
	var foot: GradientTexture2D = L1ColumnArt.gradient(
		[Color.TRANSPARENT, Color.TRANSPARENT, Color("00000059")],
		[0.0, 1.0 - shade_depth / opening.size.y, 1.0],
		Vector2.ZERO,
		Vector2.DOWN
	)
	var padding: Vector2 = shading.padding_rect().size
	foot.width = roundi(padding.x)
	foot.height = roundi(padding.y)
	shading.image_texture = foot
	shading.layers = [{"kind": "image", "size": "cover", "position": [50.0, 100.0]}]
	shading.refresh()
	portrait.add_child(shading)
	face.add_child(L1ColumnArt.piece("l1h-hero-frame", Rect2(Vector2.ZERO, frame.size)))
	screen._front.add_child(target)
	_add_button(screen, "hero", target, face, GlassParts.rect_poly(target.size), "left.hero")

	# STAND-IN: the same heart and fitted text also hold health of three or more digits.
	var health: int = GlassPieces.as_int(screen.state.get("health", 0))
	var hp: TextureRect = _heart(
		health,
		L1Layout.rect("right.health"),
		"right.health",
		L1Layout.number("right.health.font") * L1Layout.number("right.health.rise_em")
	)
	hp.name = "HeroHealth"
	screen._front.add_child(hp)
	screen._counters.build(screen._shown_counters())


static func build_gold(screen: RecruitScreen) -> void:
	var gold: TextureRect = L1ColumnArt.piece("l1p-coin", L1Layout.rect("right.gold"))
	gold.name = "Button_gold"
	var value: GlassText = L1ColumnArt.text("", L1Layout.number("right.gold.font"), Color("5a3606"))
	value.name = "GoldValue"
	value.shadow = L1ColumnArt.shadow(1.0, 0.0, "ffe9a8")
	gold.add_child(value)
	screen._back.add_child(gold)
	show_gold(value, screen._counts.gold())
	screen._targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": "gold",
			"node": gold,
			"poly": GlassParts.rect_poly(gold.size)
		}
	)
	if not screen.state.has("next_turn_income"):
		return
	var income: Control = L1ColumnArt.area(L1Layout.rect("right.income"))
	income.name = "NextTurnIncome"
	var label: GlassText = L1ColumnArt.text(
		"+%d" % GlassPieces.as_int(screen.state["next_turn_income"]),
		L1Layout.number("right.income.font"),
		Color("f0d68a")
	)
	label.name = "Value"
	label.shadow = L1ColumnArt.shadow(
		L1Layout.number("right.income.shadow_y"),
		L1Layout.number("right.income.shadow_blur"),
		"000000"
	)
	label.position = (income.size - label.size) / 2.0
	income.add_child(label)
	screen._front.add_child(income)


static func show_gold(label: GlassText, amount: int) -> void:
	var rect: Rect2 = L1Layout.rect("right.gold")
	var center: Vector2 = rect.size / 2.0
	center.y -= rect.size.y * L1Layout.number("right.gold.rise_share")
	L1ColumnArt.fit_number(
		label,
		str(amount),
		L1Layout.number("right.gold.font"),
		center,
		rect.size.x * L1Layout.number("right.gold.number_width_share")
	)


static func build_end_turn(screen: RecruitScreen) -> void:
	var rect: Rect2 = L1Layout.rect("right.end_turn")
	var target: Control = L1ColumnArt.area(rect)
	target.name = "EndTurn"
	var shadow: GlassBox = GlassBox.new()
	shadow.box_size = rect.size
	shadow.radii = Vector4.ONE * rect.size.x / 2.0
	shadow.shadows = [
		L1ColumnArt.shadow(
			L1Layout.number("right.end_turn.shadow_y"),
			L1Layout.number("right.end_turn.shadow_blur"),
			"000000a6"
		)
	]
	shadow.refresh()
	target.add_child(shadow)
	target.add_child(_end_turn_light(rect.size, nothing_left(screen.state)))
	var face: TextureRect = L1ColumnArt.piece("l1h-end-swords", Rect2(Vector2.ZERO, rect.size))
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target.add_child(face)
	screen._front.add_child(target)
	_add_button(
		screen, "end_turn", target, face, GlassParts.round_poly(target.size), "right.end_turn"
	)


## Whether the player has nothing left to do but end the turn: the state lists no buy, refresh,
## tier up, play, pick or ability (buy-screen-l1.md §11 item 28, a proposal). Selling, moving and
## freezing are always there, so they do not count. A state with no legal_actions never says so.
static func nothing_left(state: Dictionary) -> bool:
	if not state.has("legal_actions"):
		return false
	for type: String in END_TURN_ACTS:
		if RecruitActions.allows(state, {"type": type}):
			return false
	return true


## End turn's light (buy-screen-l1.md §9, E1): none while the player can still do something, a
## slow glow when nothing is left to do, and a flash as the fight starts (flash_end_turn).
static func _end_turn_light(box: Vector2, ready: bool) -> L1Light:
	var light: L1Light = L1Light.make(
		L1Light.Shape.CIRCLE,
		Rect2(Vector2.ZERO, box),
		L1Layout.colour("light.end_turn.ready_colour"),
		"EndTurnLight"
	)
	light.glow(
		Vector3(
			L1Layout.number("light.end_turn.grow"),
			L1Layout.number("light.end_turn.blur"),
			L1Layout.number("light.end_turn.alpha") if ready else 0.0
		)
	)
	light.blend(1.0).breathe(
		L1Layout.number("light.end_turn.period"), L1Layout.number("light.end_turn.depth")
	)
	light.set_meta(&"ready", ready)
	light.visible = ready
	return light


## The swords flash: End turn's light jumps up and fades, whatever its state.
static func flash_end_turn(screen: RecruitScreen) -> void:
	var light: L1Light = screen._front.get_node_or_null("EndTurn/EndTurnLight") as L1Light
	if light == null:
		return
	if light.has_meta(&"flash"):
		var old: Tween = light.get_meta(&"flash")
		if old.is_valid():
			old.kill()
	light.visible = true
	var flash: Tween = light.create_tween()
	light.set_meta(&"flash", flash)
	flash.tween_method(
		func(u: float) -> void:
			light.set_boost(
				(
					L1Layout.number("light.end_turn.flash_alpha")
					* (1.0 - GlassMotion.bezier(GlassMotion.OUT, u))
				)
			),
		0.0,
		1.0,
		L1Layout.number("light.end_turn.flash_time")
	)
	flash.tween_callback(func() -> void: light.visible = light.get_meta(&"ready", false) == true)


static func _add_button(
	screen: RecruitScreen,
	id: String,
	node: Control,
	face: Control,
	poly: PackedVector2Array,
	key: String
) -> void:
	screen._targets.append(
		{
			"kind": "button",
			"id": id,
			"index": 0,
			"node": node,
			"poly": poly,
			"pressed_face": face,
			"press_offset": L1Layout.number(key + ".press_y")
		}
	)


static func build_leaderboard(screen: RecruitScreen) -> void:
	var players: Array = screen.state.get("players", [])
	if players.is_empty():
		return
	var pane: Control = L1ColumnArt.area(Rect2())
	pane.name = "Leaderboard"
	screen._front.add_child(pane)
	var first: Rect2 = L1Layout.rect("left.player")
	var health: Rect2 = L1Layout.rect("left.player_health")
	var step: float = L1Layout.number("left.player.step")
	for i: int in players.size():
		var player: Dictionary = players[i]
		var offset: Vector2 = Vector2(0, step * i)
		var alive: bool = GlassPieces.as_bool(player.get("alive", true))
		var port: GlassBox = _player_portrait(player, first.position + offset, first.size.x, alive)
		port.name = "LeaderPortrait_%d" % i
		screen._front.add_child(port)
		screen._targets.append(
			{
				"kind": "player",
				"index": i,
				"node": port,
				"card": player,
				"poly": GlassParts.round_poly(port.size)
			}
		)
		if not alive:
			continue
		var hp: TextureRect = _heart(
			GlassPieces.as_int(player.get("health", 0)),
			Rect2(health.position + offset, health.size),
			"left.player_health",
			L1Layout.number("left.player_health.rise")
		)
		hp.name = "LeaderHealth_%d" % i
		screen._front.add_child(hp)
		if GlassPieces.as_bool(player.get("next", false)):
			var mark: TextureRect = L1ColumnArt.icon(
				SWORDS,
				Color("e0866e"),
				int(L1Layout.number("left.swords.icon")),
				L1Layout.number("left.swords.stroke")
			)
			mark.name = "NextOpponentSwords"
			mark.position = L1Layout.point("left.swords") + offset
			screen._front.add_child(mark)


static func _player_portrait(player: Dictionary, at: Vector2, side: float, alive: bool) -> GlassBox:
	var dark: float = L1Layout.number("left.player.ring_dark")
	var trim: float = L1Layout.number("left.player.ring_trim")
	var ring_width: float = dark + trim
	var portrait_name: String = str(player.get("portrait", ""))
	var port: GlassBox = GlassParts.make_portrait(portrait_name, side, [])
	port.position = at - Vector2.ONE * ring_width
	port.box_size = Vector2.ONE * (side + 2.0 * ring_width)
	port.radii = Vector4.ONE * port.box_size.x / 2.0
	var rim: Color = Color("4d5356")
	if GlassPieces.as_bool(player.get("next", false)):
		rim = Color("c4553c")
	elif GlassPieces.as_bool(player.get("you", false)):
		rim = Color("e8d49a")
	port.border_width = ring_width
	port.border_colour = RIM_DARK
	port.shadows = [
		L1ColumnArt.shadow(
			L1Layout.number("left.player.shadow_y"),
			L1Layout.number("left.player.shadow_blur"),
			"000000aa"
		)
	]
	port.refresh()
	var outline: GlassBox = GlassBox.new()
	outline.box_size = port.box_size
	outline.radii = port.radii
	outline.border_width = trim
	outline.border_colour = rim
	outline.refresh()
	port.add_child(outline)
	if not alive:
		# Desaturate the sampled portrait, including its imported mip levels.
		var material: ShaderMaterial = port.material as ShaderMaterial
		material.set_shader_parameter("image_grayscale", true)
		var dim: float = L1Layout.number("left.player.out_brightness")
		port.modulate = Color(dim, dim, dim)
	return port


static func _heart(amount: int, rect: Rect2, key: String, rise: float) -> TextureRect:
	var heart: TextureRect = L1ColumnArt.piece("l1h-heart", rect)
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var px: float = L1Layout.number(key + ".font")
	var label: GlassText = L1ColumnArt.text("", px, HEART_INK)
	label.name = "Value"
	label.shadow = L1ColumnArt.shadow(
		L1Layout.number("right.health.shadow_y"),
		L1Layout.number("right.health.shadow_blur"),
		"5a120a"
	)
	var center: Vector2 = rect.size / 2.0 - Vector2(0, rise)
	L1ColumnArt.fit_number(
		label,
		str(maxi(0, amount)),
		px,
		center,
		rect.size.x * L1Layout.number("right.health.number_width_share")
	)
	heart.add_child(label)
	return heart
