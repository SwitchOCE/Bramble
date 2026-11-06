class_name HeroRules
extends RefCounted
## Reading a hero file (content/heroes/*.json, 2.2) and setting a player up with one. A hero's
## power runs on the same effects as a card. Format: docs/ideation/engine.md.

const PASSIVE: String = "passive"
const ACTIVATED: String = "activated"
const START_OF_COMBAT: String = "start_of_combat"


static func power_of(hero: Dictionary) -> Dictionary:
	var power: Dictionary = hero.get("power", {})
	return power


## The hero's triggered entries, always with "trigger" and "do".
static func effects_of(hero: Dictionary) -> Array:
	var entries: Array = power_of(hero).get("effects", [])
	return entries


static func uses_per_turn(hero: Dictionary) -> int:
	var power: Dictionary = power_of(hero)
	if str(power.get("kind", "")) != ACTIVATED:
		return 0
	return CoreUtil.to_int(power.get("uses_per_turn", 1))


## 2.2.5-2.2.7: health, armor and rule handlers.
static func assign(player: PlayerState, hero: Dictionary) -> void:
	player.hero = hero
	if hero.has("health"):
		player.health = CoreUtil.to_int(hero["health"])
	player.armor = CoreUtil.to_int(hero.get("armor", 0))
	player.power_uses_left = uses_per_turn(hero)
	var rules: Array = power_of(hero).get("rules", [])
	for value: Variant in rules:
		var handler: Dictionary = value
		player.rule_handlers.append(handler)


## 2.2.6: armor absorbs damage before health and doesn't come back.
static func take_hero_damage(player: PlayerState, damage: int) -> void:
	var absorbed: int = mini(player.armor, damage)
	player.armor -= absorbed
	player.health -= damage - absorbed


## 2.2.1, 2.2.4: the deal. Each player's offer comes from one shuffled deck, so no hero is offered
## twice while the roster lasts; only a roster too small for the lobby deals a hero again.
static func deal(
	roster: Array[Dictionary],
	lobby_tribes: PackedStringArray,
	players: int,
	offered: int,
	rng: RandomNumberGenerator
) -> Array:
	var eligible: Array = []
	for hero: Dictionary in roster:
		var needs: String = str(hero.get("requires_tribe", ""))
		if needs == "" or lobby_tribes.is_empty() or lobby_tribes.has(needs):
			eligible.append(str(hero["id"]))
	var deck: Array = []
	var offers: Array = []
	for _player: int in players:
		var offer: PackedStringArray = []
		while offer.size() < mini(offered, eligible.size()):
			if deck.is_empty():
				deck = eligible.duplicate()
				_shuffle(deck, rng)
			var next: String = deck.pop_back()
			if not offer.has(next):
				offer.append(next)
		offers.append(offer)
	return offers


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(items.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: Variant = items[index]
		items[index] = items[other]
		items[other] = swap
