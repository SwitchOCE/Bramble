class_name RecruitColumns
extends RefCounted
## The existing recruit HUD art, placed in L1's two window columns.


static func build_hero(screen: RecruitScreen) -> void:
	var turn: GlassText = GlassText.from_rule(
		"stage", ".lbl", "Turn %d" % GlassPieces.as_int(screen.state.get("turn", 1))
	)
	turn.name = "Turn"
	turn.refresh()
	turn.position = L1Layout.centre("left.turn", turn.size)
	screen._front.add_child(turn)

	var hero: Dictionary = screen.state.get("hero", {})
	var port: GlassBox = GlassParts.make_portrait(
		str(hero.get("portrait", "")), GlassPieces.number("stage.hero.port"), [".hero"]
	)
	port.name = "Hero"
	var hero_name: GlassText = GlassText.from_rule("stage", ".lbl", str(hero.get("name", "")))
	hero_name.name = "HeroName"
	hero_name.font_px = GlassPieces.number("stage.hero.name_size")
	hero_name.refresh()
	var area: Rect2 = L1Layout.rect("left.hero")
	# STAND-IN: keep the hero's name beneath the portrait inside the hero's area.
	var top: float = area.get_center().y - (port.box_size.y + hero_name.size.y) / 2.0
	port.position = Vector2(area.get_center().x - port.box_size.x / 2.0, top)
	hero_name.position = Vector2(
		area.get_center().x - hero_name.size.x / 2.0, top + port.box_size.y
	)
	screen._front.add_child(port)
	screen._front.add_child(hero_name)
	screen._targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": "hero",
			"node": port,
			"poly": GlassScreen._circle(port.box_size)
		}
	)

	var hp: GlassBox = GlassParts.health_badge(
		GlassPieces.as_int(screen.state.get("health", 0)), [".hp"]
	)
	hp.name = "HeroHealth"
	hp.position = L1Layout.centre("right.health", hp.box_size)
	screen._front.add_child(hp)
	screen._counters.build(screen._shown_counters())


static func build_leaderboard(screen: RecruitScreen) -> void:
	var players: Array = screen.state.get("players", [])
	if players.is_empty():
		return
	var first: Rect2 = L1Layout.rect("left.player")
	var health: Rect2 = L1Layout.rect("left.player_health")
	var step: float = L1Layout.number("left.player.step")
	var pane: GlassBox = GlassBox.new()
	pane.name = "Leaderboard"
	pane.box_size = Vector2(
		GlassPieces.number("stage.leaderboard.pane_w"), (players.size() - 1) * step + step
	)
	pane.position = first.get_center() - Vector2(pane.box_size.x / 2.0, step / 2.0)
	pane.use_css("stage", "#lbpane").refresh()
	screen._front.add_child(pane)

	var side: float = GlassPieces.number("stage.leaderboard.port")
	for i: int in players.size():
		var player: Dictionary = players[i]
		var rules: Array = [".lb .port"]
		if player.get("next", false):
			rules.append(".lb .next .port")
		elif player.get("you", false):
			rules.append(".lb .you .port")
		var out: bool = not player.get("alive", true)
		var portrait: String = str(player.get("portrait", ""))
		var port: GlassBox = (
			GlassParts.out_portrait(portrait, side, rules)
			if out
			else GlassParts.make_portrait(portrait, side, rules)
		)
		var offset: Vector2 = Vector2(0, step * i)
		port.name = "LeaderPortrait_%d" % i
		port.position = first.get_center() + offset - port.box_size / 2.0
		screen._front.add_child(port)
		# STAND-IN: keep the place numeral on the left of the portrait.
		var place: GlassText = GlassText.from_rule("stage", ".lb .pl", str(i + 1))
		if out:
			place.colour = GlassParts.OUT_PLACE
		place.refresh()
		place.position = Vector2(
			port.position.x - 20.0, port.position.y + (side - place.size.y) / 2.0
		)
		screen._front.add_child(place)
		if not out:
			var hp: GlassBox = GlassParts.health_badge(
				GlassPieces.as_int(player.get("health", 0)), [".hp", ".lb .hp"]
			)
			hp.name = "LeaderHealth_%d" % i
			hp.position = health.get_center() + offset - hp.box_size / 2.0
			screen._front.add_child(hp)


static func counter_area(i: int) -> Rect2:
	var area: Rect2 = L1Layout.rect("right.counter")
	var step: float = L1Layout.number("right.counter.step")
	# STAND-IN: keep every current counter available, using further rows for overflow.
	area.position += Vector2(i % 2, floorf(i / 2.0)) * step
	return area
