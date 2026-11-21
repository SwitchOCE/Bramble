class_name CardArt
## The spells' own pictures, kept out of game_content.gd and data/stand_in_units.json: those two
## files are part of the rules fingerprint (RecordBuild), so changing a picture there would make
## a new rules version and stop the game playing its ghosts (owner, 21 Nov: "keep art out of the
## files the rules version covers"). Names are read by GlassPieces.art, relative to
## assets/glass/art; any card not listed here draws GameContent.art_for.

const SPELLS: Dictionary = {
	"sp_sharpen": "spell-sharpen",
	"sp_seek": "spell-seek",
	"sp_forage": "spell-forage",
	"triple_reward": "spell-triple-reward",
}


static func of(content: GameContent, card_id: String) -> String:
	return str(SPELLS.get(card_id, content.art_for(card_id)))
