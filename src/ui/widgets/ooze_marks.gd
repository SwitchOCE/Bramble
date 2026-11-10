extends Control
## Legacy portrait mount. Ooze identity and exact meal/Soup state are read on demand;
## changing stats use the card's existing beads and RecruitMotion's clock.

var ladle: bool = false
var soup: bool = false
var meal: Texture2D
var landing: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_state(_view: Dictionary) -> void:
	ladle = false
	soup = false
	meal = null
	landing = 0.0
	visible = false


## Accepted by the older CardView adapter; RecruitOozes now owns the shared-clock bead cue.
func share_landed() -> void:
	visible = false
