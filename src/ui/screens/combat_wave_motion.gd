extends RefCounted
## Wave 2a's retained state uses the same source/travel/landing vocabulary as fight effects.

const Special := preload("res://src/ui/screens/combat_special_motion.gd")
const Data := preload("res://src/ui/view_data.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const Numbers := preload("res://src/ui/stat_numbers.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


static func present(screen: Control, event: Dictionary, animate: bool) -> void:
	var kind: String = Data.s(event, "type")
	var source: int = Data.i(event, "source", Data.i(event, "target", -1))
	if animate and source >= 0:
		var motion: RefCounted = screen.get("_motion")
		motion.call("_source_pulse", source)
	match kind:
		"gain_pending":
			_pending(screen, event, animate)
		"bog_toll":
			_toll(screen, event, animate)
		"bog_pull", "bog_bind", "bog_hit_back":
			if animate:
				Special.transfer_mote(
					screen,
					Special._point(screen, source),
					Special._point(screen, Data.i(event, "target", source)),
					"sword" if kind == "bog_hit_back" else "splash",
					UiTheme.MOSS
				)


static func _pending(screen: Control, event: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	var cards: Dictionary = screen.get("_cards")
	var point: Vector2
	var kept: Control
	if cards.has(uid):
		var card: CardView = cards[uid]
		point = card.pending_gain_point()
	else:
		kept = Special.kept_gain(screen, event)
		point = kept.get_global_rect().get_center()
	if animate:
		var source: int = Data.i(event, "source", uid)
		var mark: Control = Special.transfer_mote(
			screen, Special._point(screen, source), point, "spark", UiTheme.MOSS
		)
		mark.set_meta("pending_target_uid", uid)
		if kept != null:
			Special._tween(screen, kept).tween_callback(kept.show).set_delay(0.35)
	elif kept != null:
		kept.show()


static func _toll(screen: Control, event: Dictionary, animate: bool) -> void:
	var side: int = Data.i(event, "side")
	var plaques: Array = screen.get("_plaques")
	var hero: Control = plaques[side]
	var badge: Panel = hero.get_node_or_null("BogToll") as Panel
	if badge == null:
		badge = Panel.new()
		badge.name = "BogToll"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.position = Vector2(0, -66)
		badge.size = Vector2(148, 58)
		badge.add_theme_stylebox_override(
			"panel", UiTheme.flat_box(UiTheme.MOSS, UiTheme.INK, 3, 14)
		)
		hero.add_child(badge)
		var glyph := TextureRect.new()
		glyph.texture = Icons.icon("splash", 44)
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.position = Vector2(4, 7)
		glyph.size = Vector2(44, 44)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(glyph)
		var amount: Label = UiTheme.number("", UiTheme.MIN_FONT, UiTheme.CREAM)
		amount.name = "Amount"
		amount.position = Vector2(51, 5)
		amount.size = Vector2(90, 48)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(amount)
	var number: Label = badge.get_node("Amount") as Label
	Numbers.fit(number, 90, UiTheme.MIN_FONT, Data.i(event, "total"))
	if animate:
		var mark: Control = Special.transfer_mote(
			screen,
			Special._point(screen, Data.i(event, "source", -1)),
			badge.get_global_rect().get_center(),
			"splash",
			UiTheme.MOSS
		)
		mark.set_meta("bog_toll_side", side)
		(
			Special
			. _tween(screen, badge)
			. tween_callback(Special._pulse.bind(screen, badge, UiTheme.MOSS))
			. set_delay(0.35)
		)
