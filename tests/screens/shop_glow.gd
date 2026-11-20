extends Control
## Owner review: shop-only Mouse pair and a triple across shop and board.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
var _screen: RecruitScreen


func _ready() -> void:
	var flow: GameFlow = FlowFixture.live(GameContent.load_default(), 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 20
	me.shop_units = [
		&"hedgerow-scout", &"hedgerow-scout", &"territorial", &"brock-cub", &"brock-cub"
	]
	me.place(flow.session.new_unit(flow.content.library.get_card(&"brock-cub"), false), 0)
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(flow)
	add_child(_screen)
	_screen.settle()


func feel_report() -> Dictionary:
	return {
		"marks": RecruitDuplicates.marks(_screen.state),
		"glow_candidate": GlassDuplicateGlow.SELECTED,
	}
