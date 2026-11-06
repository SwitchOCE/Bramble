extends RefCounted
## What a keyword means, in the player's words. The game's list comes from the schema
## (content/schema/effects.json); the older library's keywords are worded here, because a raw
## source.note in a unit file is a designer's note and never goes on screen.

const LIBRARY_WORDS: Dictionary[String, String] = {
	"Peck": "Its attack strikes the target several times, its Attack split between the strikes.",
	"Quick": "Deals its damage first. If that kills, it takes none.",
	"First Bite": "Quick in this unit's first exchange each fight.",
	"Mark": "Start of Combat: marks the enemy slot across. Units that enter it later take damage.",
	"Bystander": "When an enemy attacks one of your other units, this gains +1/+1 for this fight.",
	"Shell": "The first time this takes damage in a fight, that damage is capped.",
	"Bide": "Skips its attacks and grows each time its side's order passes it, until it is hurt.",
	"Both Ends": "With a partner at both ends of a row, each gets stronger and guards the other.",
	"Whistle": "Never attacks. It warns the strongest enemy, whose next attack does half damage.",
	"Mire": "An enemy this hurts skips its next attack.",
	"Fast": "End of Turn: with no paid refresh this turn, the count goes up, else back to 0.",
	"Swarm": "When a Swarm unit attacks, the others in its row join in on the same target.",
}


## "" for a word that isn't a keyword.
static func text(keyword: String) -> String:
	var game_words: Dictionary = EffectSchema.section("keywords")
	if game_words.has(keyword):
		return str(game_words[keyword])
	return LIBRARY_WORDS.get(keyword, "")
