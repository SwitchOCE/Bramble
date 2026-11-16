extends Control
## A STAND-IN controller for proving the recruit screen's input with tools/look: it shows the
## mock-up's state, prints each signal the screen sends, and changes the state in the simplest
## way so the next shot shows the action took. It is not the rules: no gold is spent or checked.

const LINE: String = "recruit stand-in: %s"

var _state: Dictionary = {}
var _screen: RecruitScreen


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_state = RecruitScreen.load_state("res://tests/screens/fixtures/recruit_mockup.json")
	_screen = (load("res://src/screens/recruit/recruit_screen.tscn") as PackedScene).instantiate()
	_screen.state = _state
	add_child(_screen)
	_screen.show_state(_state)
	_screen.buy_requested.connect(_on_buy)
	_screen.play_requested.connect(_on_play)
	_screen.move_requested.connect(_on_move)
	_screen.sell_requested.connect(_on_sell)
	_screen.refresh_requested.connect(func() -> void: _on_simple("refresh"))
	_screen.freeze_requested.connect(func() -> void: _on_simple("freeze"))
	_screen.tier_up_requested.connect(func() -> void: _on_simple("tier_up"))
	_screen.end_turn_requested.connect(func() -> void: _on_simple("end_turn"))


func _on_buy(index: int, is_spell: bool) -> void:
	print(LINE % ("buy %s %d" % ["spell" if is_spell else "unit", index]))
	var key: String = "shop_spells" if is_spell else "shop_units"
	var shop: Array = _state[key]
	var card: Dictionary = shop.pop_at(index)
	if not is_spell:
		var hand: Array = _state["hand"]
		hand.append(card)
	_screen.show_state(_state)


func _on_play(hand_index: int, slot: int) -> void:
	print(LINE % ("play %d to %d" % [hand_index, slot]))
	var board: Array = _state["board"]
	if board[slot] == null:
		var hand: Array = _state["hand"]
		board[slot] = hand.pop_at(hand_index)
		_screen.show_state(_state)


func _on_move(from_slot: int, to_slot: int) -> void:
	print(LINE % ("move %d to %d" % [from_slot, to_slot]))
	var board: Array = _state["board"]
	var moved: Variant = board[from_slot]
	board[from_slot] = board[to_slot]
	board[to_slot] = moved
	_screen.show_state(_state)


func _on_sell(slot: int) -> void:
	print(LINE % ("sell %d" % slot))
	var board: Array = _state["board"]
	board[slot] = null
	_screen.show_state(_state)


func _on_simple(what: String) -> void:
	print(LINE % what)
	match what:
		"refresh":
			var shop: Array = _state["shop_units"]
			shop.reverse()
		"freeze":
			_state["frozen"] = not GlassPieces.as_bool(_state.get("frozen", false))
		"tier_up":
			_state["tier"] = GlassPieces.as_int(_state.get("tier", 1)) + 1
		"end_turn":
			_state["turn"] = GlassPieces.as_int(_state.get("turn", 1)) + 1
	_screen.show_state(_state)
