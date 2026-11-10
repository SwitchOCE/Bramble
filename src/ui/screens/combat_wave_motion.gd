extends RefCounted
## Wave 2a's retained state uses the same source/travel/landing vocabulary as fight effects.

const Special := preload("res://src/ui/screens/combat_special_motion.gd")
const Data := preload("res://src/ui/view_data.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Numbers := preload("res://src/ui/stat_numbers.gd")


static func present(screen: Control, event: Dictionary, animate: bool) -> void:
	var kind: String = Data.s(event, "type")
	var source: int = Data.i(event, "source", Data.i(event, "target", -1))
	if animate and source >= 0 and kind != "gain_pending":
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
	var delay: float = 0.0
	for child: Node in Special._overlay(screen).get_children():
		delay = maxf(delay, CoreUtil.to_float(child.get_meta("pending_after_toll_delay", 0.0)))
	var travel: float = maxf(0.04, 0.15 / CoreUtil.to_float(screen.get("speed")))
	var card: CardView = Data.control(cards.get(uid)) as CardView
	if card != null:
		point = card.pending_gain_point()
		var popup: Label = _number_popup(
			screen,
			(
				"+%s/+%s"
				% [
					Numbers.compact(Data.i(event, "attack")),
					Numbers.compact(Data.i(event, "health"))
				]
			),
			point,
			delay + travel
		)
		popup.name = "PendingLanding_%d" % uid
		popup.set_meta("gain_landing_uid", uid)
	else:
		kept = Special.kept_gain(screen, event)
		point = kept.get_global_rect().get_center()
		travel = 0.35
	var source: int = Data.i(event, "source", uid)
	var motion: RefCounted = screen.get("_motion")
	if delay > 0:
		Special._tween(screen).tween_callback(motion.call.bind("_source_pulse", source)).set_delay(
			delay
		)
	else:
		motion.call("_source_pulse", source)
	var mark: Control = Special.transfer_mote(
		screen,
		Special._point(screen, source),
		point,
		"spark",
		UiTheme.MOSS,
		travel,
		false,
		Vector2.INF,
		delay
	)
	mark.set_meta("pending_target_uid", uid)
	if kept != null:
		(
			Special
			. _tween(screen, kept)
			. tween_callback(Special.land_kept_gain.bind(screen, kept))
			. set_delay(delay)
		)


static func _toll(screen: Control, event: Dictionary, animate: bool) -> void:
	if not animate:
		return
	var side: int = Data.i(event, "side")
	var plaques: Array = screen.get("_plaques")
	var hero: Control = Data.control(plaques[side])
	if hero == null:
		return
	var speed: float = CoreUtil.to_float(screen.get("speed"))
	var travel: float = maxf(0.04, 0.18 / speed)
	var mark: Control = Special.transfer_mote(
		screen,
		Special._point(screen, Data.i(event, "source", -1)),
		hero.get_global_rect().get_center(),
		"splash",
		UiTheme.MOSS,
		travel
	)
	mark.set_meta("bog_toll_side", side)
	var amount: String = "+%s" % Numbers.compact(Data.i(event, "amount"))
	var carried: Label = UiTheme.number(amount, UiTheme.MIN_FONT, UiTheme.CREAM)
	carried.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carried.position = Vector2(-14, 28)
	carried.size = Vector2(80, 42)
	carried.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_child(carried)
	Special._tween(screen, carried).tween_callback(carried.hide).set_delay(travel)
	var popup: Label = _number_popup(
		screen, amount, hero.get_global_rect().get_center() + Vector2(0, 28), travel
	)
	popup.name = "TollLanding_%d" % side
	popup.set_meta("toll_landing_side", side)
	(
		Special
		. _tween(screen, hero)
		. tween_callback(Special._pulse.bind(screen, hero, UiTheme.MOSS))
		. set_delay(travel)
	)
	# This marker uses the same manual clock and overlay retirement as the visible cues.
	# It separates two simultaneous callbacks without delaying the next action.
	var beat: Control = Control.new()
	beat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Special._overlay(screen).add_child(beat)
	var lead: float = travel + maxf(0.02, 0.08 / speed)
	beat.set_meta("pending_after_toll_delay", lead)
	var clock: Tween = Special._tween(screen, beat)
	clock.tween_method(
		func(value: float) -> void: beat.set_meta("pending_after_toll_delay", value),
		lead,
		0.0,
		lead
	)
	clock.tween_callback(beat.queue_free)


## Numeric event feedback lives only for its landing; exact queued state stays in the reader.
static func _number_popup(screen: Control, words: String, point: Vector2, delay: float) -> Label:
	var number: Label = UiTheme.number(words, UiTheme.MIN_FONT, UiTheme.CREAM)
	number.z_index = 1
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.MOSS, 2, 8))
	var width: float = (
		(
			number
			. get_theme_font("font")
			. get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.MIN_FONT)
			. x
		)
		+ 20.0
	)
	number.size = Vector2(maxf(64.0, width), 44)
	number.pivot_offset = number.size / 2.0
	Special._overlay(screen).add_child(number)
	number.position = Special._local(screen, point) - number.size / 2.0
	number.hide()
	var tween: Tween = Special._tween(screen, number)
	tween.tween_interval(delay)
	tween.tween_callback(number.show)
	tween.tween_callback(Special._pulse.bind(screen, number, UiTheme.MOSS))
	tween.tween_interval(maxf(0.1, 0.25 / CoreUtil.to_float(screen.get("speed"))))
	tween.tween_property(number, "modulate:a", 0.0, 0.15)
	tween.tween_callback(number.queue_free)
	return number
