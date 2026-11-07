extends SceneTree
## Reveal positions from real bot games, for the by-eye test (evidence/reveal-eye.md). Plays
## bench games with the reveal on (one swap), and at every fight from round 3 between two boards
## of 2+ units writes one side's position as a JSON line: the screen a player would see, the score
## of standing still and of every single swap against the enemy as it stood (32 fixed fight
## seeds, win rate with ties half), Hard's 45-fight pick and the one-line rule's pick.
##   godot --headless -s res://tools/sim/reveal_screens.gd -- suite=spread games=3 first_seed=41 \
##     out=<jsonl>
# Boards come out of Variants all through; this throwaway tool reads them unchecked.
@warning_ignore_start("unsafe_call_argument")

const MAX_TURNS: int = 60
const EVAL_SEEDS: int = 32
const FIRST_ROUND: int = 3
const NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]

var _options: Dictionary = {
	"suite": "spread", "games": "3", "first_seed": "41", "out": "screens.jsonl"
}
var _library: UnitLibrary
var _file: FileAccess
var _session: GameSession
var _config: GameConfig
var _seed: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() == 2 and _options.has(parts[0]):
			_options[parts[0]] = parts[1]
	_library = UnitLibrary.load_dir()
	_file = FileAccess.open(str(_options["out"]), FileAccess.WRITE)
	var first: int = str(_options["first_seed"]).to_int()
	for game_seed: int in range(first, first + str(_options["games"]).to_int()):
		var seats: PackedStringArray = BenchSuites.seats(str(_options["suite"]), game_seed)
		_config = GameConfig.full_game()
		_config.set_value("human_bot", seats[0])
		_config.set_value("bots", Array(seats.slice(1)))
		_config.set_value("reveal_swaps", 1)
		_seed = game_seed
		_session = GameSession.create(game_seed, _library, _config)
		_session.fight_observer = _on_fight
		var turns: int = 0
		while not _session.is_over() and turns < MAX_TURNS:
			_session.end_turn()
			turns += 1
	_file.close()
	quit(0)


func _on_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	if id_b < 0 or round_number < FIRST_ROUND or not result.has("reveal"):
		return
	var players: Array = _session.get("_players")
	var rules: RecruitRules = _session.get_rules()
	var sides: Array[PlayerState] = [players[id_a], players[id_b]]
	var reveal: Dictionary = result["reveal"]
	var before: Array = reveal["before"]
	if _units(before[0]) < 2 or _units(before[1]) < 2:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = ("screen|%d|%d|%d" % [_seed, round_number, id_a]).hash()
	var side: int = rng.randi_range(0, 1)
	var slots: Array = [sides[0].combat_slots(), sides[1].combat_slots()]
	var heroes: Array = [HeroRules.effects_of(sides[0].hero), HeroRules.effects_of(sides[1].hero)]
	var tiers: Array[int] = [sides[0].tier, sides[1].tier]
	var side_rules: Array = [rules.fight_rules(sides[0]), rules.fight_rules(sides[1])]
	# The truth scores the picks; the bot chooses from what the screen shows.
	var truth: BoardSearch.Problem = Reveal.problem_for(
		before, slots, heroes, tiers, side_rules, side, _library, _config
	)
	var enemy_rules: Dictionary = side_rules[1 - side]
	truth.side_rules = [side_rules[side], enemy_rules]
	var shown: BoardSearch.Problem = Reveal.problem_for(
		before, slots, heroes, tiers, side_rules, side, _library, _config
	)
	var base: int = rng.randi()
	var scores: Dictionary = {"still": _score(truth, BoardSearch.identity_layout(), base)}
	for pair: Vector2i in Reveal.swap_pairs(before[side]):
		var layout: Array[int] = Reveal.swapped(BoardSearch.identity_layout(), pair)
		scores[_name(pair)] = _score(truth, layout, base)
	var hard: Array[int] = Reveal.search(shown, 1, rng, Reveal.HARD_BUDGET)
	var mine: PlayerState = sides[side]
	var theirs: PlayerState = sides[1 - side]
	var line: Dictionary = {
		"seed": _seed,
		"round": round_number,
		"player": mine.id,
		"tribes_mine": _tribes(before[side]),
		"tribes_theirs": _tribes(before[1 - side]),
		"scores": scores,
		"hard": _layout_name(hard),
		"rule": _rule(before[side], before[1 - side]),
		"screen": _screen(round_number, mine, theirs, before[side], before[1 - side], slots, side),
	}
	_file.store_line(JSON.stringify(line))


static func _units(board: Array) -> int:
	var count: int = 0
	for spec: Variant in board:
		count += 1 if spec != null else 0
	return count


static func _name(pair: Vector2i) -> String:
	return "%s-%s" % [NAMES[pair.x], NAMES[pair.y]]


static func _layout_name(layout: Array[int]) -> String:
	var moved: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] != slot:
			moved.append(slot)
	if moved.size() != 2:
		return "still"
	return _name(Vector2i(moved[0], moved[1]))


## The one-line rule, written before any screen was seen: put your highest-Attack unit across the
## enemy front unit with the least Health (the back row if the front is empty); if it already
## stands there, stand still.
static func _rule(mine: Array, theirs: Array) -> String:
	var best: int = -1
	var most: int = -1
	for slot: int in BoardGeometry.SLOTS:
		var spec: Variant = mine[slot]
		if spec is Dictionary and not _is_egg(spec):
			var attack: int = _attack(spec)
			if attack > most:
				best = slot
				most = attack
	var target: int = -1
	var least: int = 1 << 30
	for row: Array[int] in [BoardGeometry.FRONT, BoardGeometry.BACK]:
		for slot: int in row:
			var spec: Variant = theirs[slot]
			if spec is Dictionary and _health(spec) < least:
				target = slot
				least = _health(spec)
		if target >= 0:
			break
	if best < 0 or target < 0 or best == target:
		return "still"
	return _name(Vector2i(mini(best, target), maxi(best, target)))


static func _is_egg(spec: Variant) -> bool:
	var entry: Dictionary = spec
	return entry.get("egg", false)


static func _attack(spec: Variant) -> int:
	var entry: Dictionary = spec
	return CoreUtil.to_int(entry.get("attack", 0)) + CoreUtil.to_int(entry.get("combat_attack", 0))


static func _health(spec: Variant) -> int:
	var entry: Dictionary = spec
	return CoreUtil.to_int(entry.get("health", 0)) + CoreUtil.to_int(entry.get("combat_health", 0))


func _tribes(board: Array) -> Array:
	var out: Array = []
	for spec: Variant in board:
		if spec is Dictionary and not _is_egg(spec):
			var entry: Dictionary = spec
			var def: Dictionary = _library.get_unit(str(entry["def_id"]))
			for tribe: Variant in def.get("tribes", []):
				out.append(str(tribe))
	return out


func _screen(
	round_number: int,
	mine: PlayerState,
	theirs: PlayerState,
	my_board: Array,
	their_board: Array,
	slots: Array,
	side: int
) -> String:
	var lines: PackedStringArray = []
	lines.append("ROUND %d. THE REVEAL." % round_number)
	lines.append("")
	lines.append(_side_text("THEM", theirs, their_board, slots[1 - side]))
	lines.append(_side_text("YOU", mine, my_board, slots[side]))
	return "\n".join(lines)


func _side_text(label: String, player: PlayerState, board: Array, slot_effects: Array) -> String:
	var lines: PackedStringArray = []
	var hero_text: String = str(player.hero.get("text", ""))
	lines.append(
		(
			"%s: hero %s (%s), tier %d, %d Health."
			% [label, str(player.hero.get("name", "?")), hero_text, player.tier, player.health]
		)
	)
	for slot: int in BoardGeometry.SLOTS:
		var spec: Variant = board[slot]
		var text: String = "%s: empty" % NAMES[slot]
		if spec is Dictionary:
			text = "%s: %s" % [NAMES[slot], _unit_text(spec)]
		var effects: Array = slot_effects[slot] if slot < slot_effects.size() else []
		for value: Variant in effects:
			var effect: Dictionary = value
			text += (
				" [slot: %s %+d/%+d. %s]"
				% [
					str(effect.get("name", "")),
					CoreUtil.to_int(effect.get("attack", 0)),
					CoreUtil.to_int(effect.get("health", 0)),
					str(effect.get("text", "")),
				]
			)
		lines.append("  " + text)
	return "\n".join(lines) + "\n"


func _unit_text(spec: Dictionary) -> String:
	if spec.get("egg", false):
		return "Nest: an Egg, 0/2 (a Bird of theirs is away; who is hidden)"
	var def: Dictionary = _library.get_unit(str(spec["def_id"]))
	var golden: bool = spec.get("golden", false)
	var card: String = str(def.get("golden_text" if golden else "text", def.get("text", "")))
	var out: String = (
		"%s%s %d/%d (%s, tier %d). %s"
		% [
			"Golden " if golden else "",
			str(def.get("name", spec["def_id"])),
			_attack(spec),
			_health(spec),
			_tribe_label(def),
			CoreUtil.to_int(def.get("tier", 1)),
			card,
		]
	)
	for value: Variant in UnitLibrary.keyword_text_of(def):
		var entry: Dictionary = value
		out += " (%s: %s)" % [str(entry.get("keyword", "")), str(entry.get("text", ""))]
	if spec.has("hex"):
		out += " Hex so far: %d." % CoreUtil.to_int(spec["hex"])
	var grants: Array = spec.get("grants", [])
	for value: Variant in grants:
		var grant: Dictionary = value
		var keyword: String = str(grant.get("keyword", ""))
		out += " Also has: %s." % (keyword if keyword != "" else "extra text from a spell or Belly")
	var held: Array = spec.get("held", [])
	for value: Variant in held:
		var inside: Dictionary = value
		var inner: Dictionary = _library.get_unit(str(inside["def_id"]))
		out += (
			" Holds in its Belly: %s %d/%d."
			% [str(inner.get("name", "?")), _attack(inside), _health(inside)]
		)
	return out


static func _tribe_label(def: Dictionary) -> String:
	var tribes: Array = def.get("tribes", [])
	return "neutral" if tribes.is_empty() else ", ".join(PackedStringArray(tribes))


## Win rate (ties half) over the fixed fight seeds.
func _score(problem: BoardSearch.Problem, layout: Array[int], first: int) -> float:
	var mine: Array = BoardSearch.arranged_specs(problem.board, layout)
	var wins: float = 0.0
	var fight_rng := RandomNumberGenerator.new()
	for index: int in EVAL_SEEDS:
		fight_rng.seed = first + index
		var combat: Combat = Combat.create(problem.library, problem.config, fight_rng)
		combat.log_events = false
		combat.side_rules = problem.side_rules
		combat.slot_effects = [problem.slots, problem.enemy_slots]
		combat.hero_effects = [problem.hero_effects, problem.enemy_hero_effects]
		var result: Dictionary = combat.run(
			[mine, problem.enemy], [problem.tier, problem.enemy_tier], [0, 1], 0
		)
		var winner: int = result["winner"]
		if winner == 0:
			wins += 1.0
		elif winner != 1:
			wins += 0.5
	return wins / EVAL_SEEDS
