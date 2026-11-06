extends GutTest
## The full game through the real screen on the real core: pick a hero, buy and aim a spell, aim
## the hero's power at a slot. Taps go in as a player's would, and the core's state must change.

const App := preload("res://src/ui/app.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const Data := preload("res://src/ui/view_data.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const Settings := preload("res://src/ui/settings.gd")

const AIMED_POWER: String = "any_slot"
const AIMED_SPELL: String = "unit"
const SEEDS: int = 30


## A started game on the first seed that offers a hero whose power is aimed; the hero is taken by
## tapping its card. Null if none offers one.
func _game_with_aimed_hero() -> RecruitScreen:
	var app: App = App.new()
	add_child_autofree(app)
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)
	Settings.seen_guide = true
	for game_seed: int in range(1, SEEDS):
		app.start_game(game_seed)
		var options: Array = Data.a(Data.d(port.get_state(), "pending_choice"), "options")
		for i: int in options.size():
			if Data.s(Data.entry(options, i), "aim") == AIMED_POWER:
				var screen: RecruitScreen = app.current as RecruitScreen
				var picker: Control = screen.get("_discover")
				picker.call("_on_card_tapped", "picker", i)
				return screen
	return null


func _spell_index(screen: RecruitScreen) -> int:
	var shop: Array = Data.a(screen.state, "shop")
	for i: int in shop.size():
		if Data.s(Data.entry(shop, i), "aim") == AIMED_SPELL:
			return i
	return -1


func test_aimed_hero_power_lands_on_the_tapped_slot() -> void:
	var screen: RecruitScreen = _game_with_aimed_hero()
	assert_not_null(screen, "a seed offers an aimed hero")
	if screen == null:
		return
	screen.port.dev_add_gold(5)
	screen.render()
	var gold: int = Data.i(screen.state, "gold")
	var cost: int = Data.i(Data.d(screen.state, "hero"), "cost")
	screen.call("_on_hero_power")
	assert_eq(Data.i(screen.port.get_state(), "gold"), gold, "aiming costs nothing yet")
	screen.call("_on_tapped", "board", 2)
	var state: Dictionary = screen.port.get_state()
	assert_eq(Data.i(state, "gold"), gold - cost, "the power is paid for")
	var slots: Array = Data.a(state, "slot_effects")
	var painted: Array = slots[2]
	var other: Array = slots[1]
	assert_false(painted.is_empty(), "F3 was painted")
	assert_true(other.is_empty(), "F2 wasn't")


func test_aimed_spell_is_bought_and_lands_on_the_tapped_unit() -> void:
	var screen: RecruitScreen = _game_with_aimed_hero()
	assert_not_null(screen, "a seed offers an aimed hero")
	if screen == null:
		return
	screen.port.dev_add_gold(40)
	screen.render()
	var index: int = _spell_index(screen)
	for attempt: int in 25:
		if index >= 0:
			break
		screen.call("_on_refresh")
		index = _spell_index(screen)
	assert_true(index >= 0, "an aimed spell reached the shop")
	if index < 0:
		return
	screen.call("_on_tapped", "shop", 0)
	screen.call("_on_buy_selected")
	screen.call("_on_tapped", "hand", 0)
	screen.call("_on_tapped", "board", 1)
	var before: Dictionary = Data.entry(Data.a(screen.port.get_state(), "board"), 1)
	index = _spell_index(screen)
	for attempt: int in 25:
		if index >= 0:
			break
		screen.call("_on_refresh")
		index = _spell_index(screen)
	screen.call("_on_tapped", "shop", index)
	screen.call("_on_buy_selected")
	var hand: Array = Data.a(screen.state, "hand")
	assert_eq(Data.s(Data.entry(hand, hand.size() - 1), "aim"), AIMED_SPELL, "bought to hand")
	screen.call("_on_tapped", "hand", hand.size() - 1)
	screen.call("_on_tapped", "board", 1)
	var after: Dictionary = Data.entry(Data.a(screen.port.get_state(), "board"), 1)
	assert_eq(Data.a(screen.port.get_state(), "hand_items").size(), 0, "the spell was played")
	assert_gt(Data.i(after, "attack"), Data.i(before, "attack"), "it landed on that unit")
