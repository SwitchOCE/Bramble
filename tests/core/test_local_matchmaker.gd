extends GutTest

const SHIPPED: String = "res://tools/league/proof/fixtures/async-store"


class StoreProbe:
	extends GhostStore

	var rows: Array[Dictionary] = []

	func find(query: Dictionary = {}) -> Array[Dictionary]:
		return rows.filter(func(info: Dictionary) -> bool: return _matches(query, info))


class RngProbe:
	extends Rng

	var bounds: Array[Vector2i] = []

	func range_int(low: int, high: int) -> int:
		bounds.append(Vector2i(low, high))
		return low


func test_sorts_then_deduplicates_and_skips_unfinished() -> void:
	var store := StoreProbe.new()
	for index: int in range(12, 0, -1):
		(
			store
			. rows
			. append(
				{
					"id": "%02d" % index,
					"rules_hash": "rules" if index != 11 else "old",
					"kind": "player",
					"label": "A" if index != 12 else "B",
					"placement": 3,
					"ended": "unfinished" if index == 5 else "won",
					"record_sha256": "record-2" if index in [2, 4] else "",
					"seat": 0,
				}
			)
		)
	store.rows.append(store.rows[2])
	store.rows.append(store.rows[0])
	var rng := RngProbe.new()
	var picked: Dictionary = LocalMatchmaker.pick(
		store, "rules", {"labels": ["A"], "placement": [2, 3]}, {"10": true}, rng
	)
	assert_eq(picked, {"ok": true, "ids": ["01", "02", "03", "06", "07", "08", "09"]})
	assert_eq(
		rng.bounds,
		[
			Vector2i(0, 6),
			Vector2i(1, 6),
			Vector2i(2, 6),
			Vector2i(3, 6),
			Vector2i(4, 6),
			Vector2i(5, 6),
			Vector2i(6, 6),
		]
	)


func test_too_few_eligible_runs_does_not_draw_rng() -> void:
	var store := GhostStore.new(SHIPPED)
	var info: Dictionary = store.find()[0]
	var rules: String = info["rules_hash"]
	var rng := RngProbe.new()
	var picked: Dictionary = LocalMatchmaker.pick(store, rules, {"labels": ["random"]}, {}, rng)
	assert_eq(picked, {"ok": false, "message": "need 7 eligible ghost runs, found 3"})
	assert_eq(rng.bounds, [])


func test_seed_47_matches_rust_seat_order() -> void:
	# From the Rust LocalMatchmaker on async-store. Regenerate with proof/ghost_core.sh.
	var expected: Array[String] = [
		"8cf13f9664c246b2664d42833d7f78cc79f39aa94d0268cee97bc23096370a54",
		"2a32d19657c0179f64f9be3060b2c6431d92072d158dfa3d55e25d7f398a12ac",
		"02f918a6e3c6876ddf88edee1b9a3a9753093adb5f56155348a29a28ac701789",
		"2d1f0e44d46237142cd551486f60222c627bedcba083e4f8ba76d10b86f7dcd6",
		"5b4abf0f2af184a712145a0ede48854b96fafcf0e44c5ace835735aec06fff5d",
		"1c59cad21a1fb468efa4859e653711d223e42c6b54529bce7b3b3e048a603c8c",
		"8ab9ea31b4e744a17ca574ee5cdc39a94d52777cd56eff3fa8e014efe49c5e33",
	]
	var store := GhostStore.new(SHIPPED)
	var rules: String = store.find()[0]["rules_hash"]
	var picked: Dictionary = LocalMatchmaker.pick(store, rules, {}, {}, Rng.new(47))
	assert_eq(picked, {"ok": true, "ids": expected})
