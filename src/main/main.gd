extends Control
## Placeholder main scene until the game's first screen exists. scripts/export_smoke.sh boots
## the exported build and waits for the line printed here.

const READY_LINE: String = "boot: main scene ready"


func _ready() -> void:
	print(READY_LINE)
