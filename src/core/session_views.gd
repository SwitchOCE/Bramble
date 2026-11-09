class_name SessionViews
extends RefCounted
## Stateless view formatting shared by session state, hero offers and field ghosts.


## Each Pass waiting for End of Turn, and where it lands if nothing changes.
static func passes(player: PlayerState) -> Array:
	var out: Array = []
	for entry: Dictionary in player.pending_passes:
		var start: int = BoardUpkeep.pass_start(player, entry)
		var source: RecruitUnit = RecruitRules._unit_by_iid(player, CoreUtil.to_int(entry["iid"]))
		(
			out
			. append(
				{
					"attack": entry["attack"],
					"health": entry["health"],
					"from_slot": start,
					"landing_slot":
					BoardGeometry.pass_landing(
						player.occupied(),
						start if source != null and source in player.board else -1
					),
				}
			)
		)
	return out


static func hero_card(hero: Dictionary) -> Dictionary:
	var power: Dictionary = HeroRules.power_of(hero)
	var view: Dictionary = {
		"id": str(hero["id"]),
		"name": str(hero["name"]),
		"text": str(hero.get("text", "")),
		"kind": str(power.get("kind", HeroRules.PASSIVE)),
		"cost": CoreUtil.to_int(power.get("cost", 0)),
		"uses_per_turn": HeroRules.uses_per_turn(hero),
		"aim": str(power.get("aim", HandItem.AIM_NONE)),
		"armor": CoreUtil.to_int(hero.get("armor", 0)),
		"sample": CoreUtil.to_bool(hero.get("sample", false)),
	}
	UnitLibrary.add_configured_rulings(view, hero)
	return view
