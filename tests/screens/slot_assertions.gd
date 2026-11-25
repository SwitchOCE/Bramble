extends RefCounted
## Structural rendering invariant shared by fixture and generated-state tests.
## Return only failures, so thousands of rendered states do not retain passing assertions.


static func check(screen: GlassScreen) -> PackedStringArray:
	var errors: PackedStringArray = []
	var stage: Control = screen.get_node("Frame/Stage")
	var slots: Control = stage.get_node_or_null("Slots")
	var cards: Control = stage.get_node("Cards")
	if slots == null:
		return PackedStringArray(["missing persistent Slots layer"])
	var layers: Array[String] = []
	for child: Node in stage.get_children():
		if str(child.name) in ["Back", "Slots", "Cards", "Front"]:
			layers.append(str(child.name))
	if layers != (["Back", "Slots", "Cards", "Front"] as Array[String]):
		errors.append("layer order: %s" % [layers])
	var expected: Dictionary = {}
	if screen is RecruitScreen:
		var recruit: RecruitScreen = screen as RecruitScreen
		for i: int in GlassScreen.BOARD_SLOTS:
			expected["Slot_%d" % i] = [recruit.slot_xy(i), screen.card_box()]
		var units: Array = screen.state.get("shop_units", [])
		var arches: int = maxi(units.size(), int(L1Layout.number("shop.arch.count")))
		for i: int in arches:
			expected["ShopSlot_%d" % i] = [recruit.shop_xy(i), screen.card_box()]
	elif screen is FightScreen:
		var fight: FightScreen = screen as FightScreen
		for side: int in 2:
			for i: int in GlassScreen.BOARD_SLOTS:
				expected["Slot_%d_%d" % [side, i]] = [fight.unit_xy(side, i), screen.card_box()]
	if slots.get_child_count() != expected.size():
		errors.append("%d slots, expected %d" % [slots.get_child_count(), expected.size()])
	var lowest_card_z: int = _z(cards)
	for child: Node in cards.get_children():
		if child is CanvasItem:
			lowest_card_z = mini(lowest_card_z, _z(child as CanvasItem))
	for slot_name: String in expected:
		var node: Node = slots.get_node_or_null(NodePath(slot_name))
		if not node is GlassBox:
			errors.append("%s missing GlassBox" % slot_name)
			continue
		var slot: GlassBox = node as GlassBox
		var geometry: Array = expected[slot_name]
		var at: Vector2 = geometry[0]
		var box: Vector2 = geometry[1]
		if not slot.position.is_equal_approx(at) or not slot.box_size.is_equal_approx(box):
			errors.append(
				(
					"%s geometry %s/%s, expected %s/%s"
					% [slot_name, slot.position, slot.box_size, at, box]
				)
			)
		if not slot.is_visible_in_tree():
			errors.append("%s hidden" % slot_name)
		if _z(slot) > lowest_card_z:
			errors.append("%s draws above cards" % slot_name)
		if not is_equal_approx(slot.self_modulate.a, 1.0):
			errors.append("%s self alpha" % slot_name)
		var ancestor: Node = slot
		while ancestor != null:
			if ancestor is CanvasItem:
				var item: CanvasItem = ancestor as CanvasItem
				if not is_equal_approx(item.modulate.a, 1.0):
					errors.append("%s alpha at %s" % [slot_name, ancestor.name])
			if ancestor is Control and ancestor != slot:
				var control: Control = ancestor as Control
				if control.clip_contents:
					var local: Transform2D = (
						control.get_global_transform().affine_inverse()
						* slot.get_global_transform()
					)
					var bounds: Rect2 = local * Rect2(Vector2.ZERO, slot.box_size)
					if not Rect2(Vector2.ZERO, control.size).grow(0.01).encloses(bounds):
						errors.append("%s clipped by %s" % [slot_name, ancestor.name])
			ancestor = ancestor.get_parent()
	return errors


static func _z(item: CanvasItem) -> int:
	var result: int = item.z_index
	if item.z_as_relative:
		var parent: Node = item.get_parent()
		if parent is CanvasItem:
			result += _z(parent as CanvasItem)
	return result
