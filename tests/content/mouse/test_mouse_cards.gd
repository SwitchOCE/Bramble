extends GutTest
## The Mice's card data as a screen reads it: each golden copy's text and stats against the
## design's `golden` line, and every term a card's text uses explained from that card (a shown
## keyword's display entry, or a line in its `reminders`). Behaviour of each golden copy is
## tested beside its unit in test_mouse_units.gd.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")

const PILE: String = "Pile on: Whenever a neighbour attacks, this hits the target first."
const COUSIN: String = "Cousin: A 2/2 Mouse with Pile on."
const HIT: String = "Hit: Deal this unit's Attack as damage. It takes none back."
const SLOT: String = "Slot buff: Stays on the slot. Any unit standing there has it."

## Card id -> [golden text, golden Attack, golden Health].
const GOLDEN: Dictionary = {
	"cousin": ["Pile on.", 4, 4],
	"needle-page": ["Pile on.", 8, 6],
	"hedgerow-scout": ["Whenever this attacks, summon 2 Cousins.", 4, 10],
	"harvest-piper": ["Pile on. When played: Give your other Mice +4 Attack.", 6, 6],
	"whetstone-vole": ["At the end of your turn, give this slot +6 Attack.", 4, 10],
	"shrew-cutpurse":
	["Pile on. The first time this piles on each fight, gain 2 gold.", 4, 8],
	"thimble-captain": ["Whenever a neighbour attacks, summon 2 Cousins.", 6, 14],
	"needle-pikeman":
	[
		"Pile on. Can't attack. After this piles on, it gains +6 Attack permanently (5 a fight).",
		8,
		10
	],
	"toothpick-ballista":
	["Start of fight: Hit the enemy with the least Health twice, choosing again.", 16, 6],
	"shrew-harrier": ["Attacks twice.", 10, 10],
	"spoon-catapult":
	["Instead of attacking, Hit the enemy with the least Health twice, choosing again.", 24, 8],
	"grindstone-miller":
	["At the end of your turn, give this slot and its neighbours +4 Attack.", 6, 14],
	"dormouse-cook":
	["At the end of your turn, if your board is full of Mice, give them +6 Attack.", 4, 18],
	"fencing-master":
	[
		"Pile on. The first time each of your Mice piles on in a fight, it gains +6 Attack permanently.",
		10,
		12
	],
	"parish-standard-bearer": ["Your Mice have +4 Attack for each Mouse you have.", 12, 16],
	"master-of-engines":
	[
		"Start of fight: Your back-row units each Hit the enemy with the least Health twice, choosing again.",
		10,
		16
	],
	"edgewright": ["Start of fight: Your slots give triple Attack this fight.", 8, 18],
	"king-speck":
	["Whenever this attacks, fill your empty slots with golden Cousins (4/4).", 12, 28],
	"dame-bodkin": ["Pile on. Pile-on hits deal triple damage.", 16, 16],
	"kettle-drummer": ["Your back-row units attack twice.", 10, 20],
}

var game: GameSession


func before_each() -> void:
	game = Kit.session()


func _mouse_ids() -> Array[String]:
	var out: Array[String] = []
	for id: StringName in game.library.ids():
		if game.library.get_card(id).has_tribe("Mouse"):
			out.append(String(id))
	return out


func test_every_golden_copy_reads_and_stands_as_its_golden_line() -> void:
	var ids: Array[String] = _mouse_ids()
	ids.sort()
	var expected: Array = GOLDEN.keys()
	expected.sort()
	assert_eq(ids, expected, "every Mouse card is listed here")
	for id: String in GOLDEN:
		var view: Dictionary = Kit.golden_unit(game, id).view()
		var want: Array = GOLDEN[id]
		assert_eq(view["text"], want[0], id)
		assert_eq([view["attack"], view["health"]], [want[1], want[2]], id)


func test_every_term_a_card_uses_is_explained_from_that_card() -> void:
	var display: Dictionary = game.display
	for id: String in _mouse_ids():
		var view: Dictionary = CoreKit.unit(game, id).view()
		var text: String = view["text"]
		var lines: Array = view["reminders"]
		var shown: Array = []
		for keyword: Variant in view["keywords"]:
			assert_true(display.has(keyword), "%s: %s has a display entry" % [id, keyword])
			var entry: Dictionary = display.get(keyword, {})
			if not entry.get("hidden", false):
				shown.append(entry["name"])
				assert_ne(entry["reminder"], "", "%s: %s has a reminder" % [id, keyword])
		if text.contains("Cousin"):
			assert_true(lines.has(COUSIN), id + ": Cousin")
			assert_true(lines.has(PILE), id + ": the Cousin's Pile on")
		if text.contains("Hit "):
			assert_true(lines.has(HIT), id + ": Hit")
		if text.contains("this slot") or text.contains("Your slots"):
			assert_true(lines.has(SLOT), id + ": Slot buff")
		if text.contains("Pile on") or text.contains("piles on"):
			assert_true(shown.has("Pile on"), id + ": Pile on shows as a keyword")
		if text.begins_with("Attacks twice"):
			assert_true(shown.has("Attacks twice"), id + ": Attacks twice shows as a keyword")


func test_the_cousin_token_and_the_mouse_glossary_have_entries() -> void:
	var display: Dictionary = game.display
	assert_eq(display["mouse_cousin"]["reminder"], "A 2/2 Mouse with Pile on.")
	assert_eq(display["mouse_hit"]["name"], "Hit")
	assert_false(display["mouse_pikeman_gains"]["hidden"], "the Pikeman's gains left show")
	for id: Variant in display:
		if String(id).begins_with("mouse_") and display[id]["hidden"]:
			assert_eq(display[id]["name"], "", "%s: a hidden helper names nothing" % id)
