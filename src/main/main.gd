extends Control
## The main scene: starts the UI app on a game port. By default that is the rules core
## (CorePort); run with `-- --fixtures` to drive the screens from docs/prototype/fixtures instead.
## scripts/export_smoke.sh boots the exported build and waits for the line printed here.

const READY_LINE: String = "boot: main scene ready"
const FIXTURES_ARG: String = "--fixtures"
const App := preload("res://src/ui/app.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")

var app: App


func _ready() -> void:
	app = App.new()
	add_child(app)
	app.setup(make_port(OS.get_cmdline_user_args()))
	print(READY_LINE)


static func make_port(args: PackedStringArray) -> GamePort:
	if FIXTURES_ARG in args:
		return FixturePort.new()
	var port: CorePort = CorePort.new()
	port.setup()
	return port
