extends Control
## The main scene: starts the UI app on a game port. Tonight that is the fixture port; once the
## rules core is merged it becomes the core-backed port, and nothing else here changes.
## scripts/export_smoke.sh boots the exported build and waits for the line printed here.

const READY_LINE: String = "boot: main scene ready"
const App := preload("res://src/ui/app.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")

var app: App


func _ready() -> void:
	app = App.new()
	add_child(app)
	app.setup(FixturePort.new())
	print(READY_LINE)
