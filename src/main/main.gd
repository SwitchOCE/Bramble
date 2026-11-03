extends Control
## The main scene: starts the UI app on the rules core (CorePort).
## scripts/export_smoke.sh boots the exported build and waits for the line printed here.

const READY_LINE: String = "boot: main scene ready"
const App := preload("res://src/ui/app.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")

var app: App


func _ready() -> void:
	app = App.new()
	add_child(app)
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)
	print(READY_LINE)
