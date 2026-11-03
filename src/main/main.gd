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


## The real core, or the SPEC fixtures with --fixtures in an editor run. An exported build
## (feature "template") always gets the core: its pack has no fixtures and must not fake a game.
static func make_port(
	args: PackedStringArray, exported: bool = OS.has_feature("template")
) -> GamePort:
	if FIXTURES_ARG in args and not exported:
		return FixturePort.new()
	var port: CorePort = CorePort.new()
	port.setup()
	return port
