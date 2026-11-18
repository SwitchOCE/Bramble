extends SceneTree
## Reproducible non-combat session oracle for the inline Rust session tests.
## Run: timeout -k 10 30 godot --headless --path . -s res://tools/league/gd/prove_session.gd
## No recruit turns or Combat are invoked; all persistent state is hashed at each checkpoint.


func _initialize() -> void:
	var game: GameSession = _fixture()
	_emit("fixture", game)
	var kept_hand: Unit = game.player(2).hand[0]
	game._eliminate()
	assert(game.ghost_of == 2)
	var ghost: PlayerState = game.player(2)
	assert(is_same(game.ghost_player, ghost))
	assert(is_same(game.ghost_board[0], ghost.board[0]))
	assert(not is_same(game.ghost_board, ghost.board))
	assert(ghost.hand.is_empty() and game.ghost_hand.size() == 2)
	assert(game.ghost_hand[0].def.id == &"t1_guard")
	assert(is_same(game.ghost_hand[0], kept_hand))
	for id: int in [0, 1, 2]:
		var each: PlayerState = game.player(id)
		assert(not each.alive and each.hand.is_empty())
		assert(each.shop_units.is_empty() and each.shop_spells.is_empty())
		assert(each.discover_options.is_empty() and each.discover_queue.is_empty())
	for card_id: StringName in game.units.ids():
		assert(game.units.copies_left(card_id) == game.units.starting_copies(card_id))
	for card_id: StringName in game.spells.ids():
		assert(game.spells.copies_left(card_id) == game.spells.starting_copies(card_id))
	_emit("eliminate", game)
	for round_id: int in [5, 6, 7, 8]:
		game.round_number = round_id
		game.pairings = game._pair_round()
		_emit("pair%d" % round_id, game)
	# Duplicated containers retain the same Unit objects, while a slot edit stays local.
	game.ghost_board[0].pool_copies = 7
	assert(ghost.board[0].pool_copies == 7)
	game.ghost_hand[0].pool_copies = 4
	game.ghost_board[0] = null
	assert(ghost.board[0] != null)
	_emit("alias_mutation", game)
	game.round_number = 9
	for each: PlayerState in game.alive_players():
		each.health = 10
		each.armor = each.id % 2
	game._check_end()
	assert(game.over)
	_emit("round_limit", game)
	var last: GameSession = _fixture()
	for id: int in 7:
		last.player(id).health = 0
	last._eliminate()
	last._check_end()
	assert(last.over and last.player(7).placement == 1)
	_emit("one_left", last)
	print("session_oracle: PASS aliases, preserved hand, pool returns, ties and final places")
	quit(0)


func _fixture() -> GameSession:
	var content: GameContent = GameContent.load_folders([])
	assert(content.errors.is_empty())
	var config := GameConfig.new()
	config.round_limit = 9
	var game: GameSession = GameSession.create(42, content.library, content.registry, config)
	game.round_number = 4
	for id: int in [0, 1, 2]:
		var each: PlayerState = game.player(id)
		each.health = 0 if id == 2 else -2
		each.tier = id + 1
		var board: Unit = game.new_unit(content.library.get_card(&"t1_plain"), true)
		board.pool_copies = 3
		each.board[0] = board
		for _copy: int in 3:
			assert(game.units.take(&"t1_plain"))
		for card_id: StringName in [&"t1_guard", &"sp_sharpen"]:
			var card: Unit = game.new_unit(content.library.get_card(card_id), false)
			card.pool_copies = 1
			each.hand.append(card)
			assert((game.spells if card.is_spell() else game.units).take(card_id))
		each.shop_units.append(&"t1_seed")
		assert(game.units.take(&"t1_seed"))
		each.shop_spells.append(&"sp_seek")
		assert(game.spells.take(&"sp_seek"))
		each.discover_options.append(&"t1_plain")
		assert(game.units.take(&"t1_plain"))
		each.discover_queue.append(Vector2i(2, 3))
	return game


func _emit(label: String, game: GameSession) -> void:
	print("session_oracle: " + JSON.stringify({
		"label": label, "hash": RecordState.state_hash(game),
		"pairs": game.pairings, "placements": game.placements(), "ghost": game.ghost_of
	}))
