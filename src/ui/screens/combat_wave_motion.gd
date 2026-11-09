extends RefCounted
## Wave 2a's retained state uses the same source/travel/landing vocabulary as fight effects.

const Special := preload("res://src/ui/screens/combat_special_motion.gd")
const Data := preload("res://src/ui/view_data.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
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
	if not animate:
		return
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
			Special.land_kept_gain(screen, kept)


static func _toll(screen: Control, event: Dictionary, animate: bool) -> void:
	if not animate:
		return
	var side: int = Data.i(event, "side")
	var plaques: Array = screen.get("_plaques")
	var hero: Control = plaques[side]
	var mark: Control = Special.transfer_mote(
		screen,
		Special._point(screen, Data.i(event, "source", -1)),
		hero.get_global_rect().get_center(),
		"splash",
		UiTheme.MOSS
	)
	mark.set_meta("bog_toll_side", side)
	(
		Special
		. _tween(screen, hero)
		. tween_callback(Special._pulse.bind(screen, hero, UiTheme.MOSS))
		. set_delay(0.35)
	)
