class_name MechanicRegistry
extends RefCounted
## The mechanic ids that have a script in the core (SPEC section 4). A unit whose mechanics are
## not all built plays as its plain stats, and UnitLibrary.unbuilt_units() lists it.
## Milestone A (the walking skeleton) builds none.

const BUILT: Dictionary = {}


static func is_built(mechanic_id: String) -> bool:
	return BUILT.has(mechanic_id)
