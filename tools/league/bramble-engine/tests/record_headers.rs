use bramble_engine::{
    Array, Variant, core::records::record_replay::RecordReplay, util::godot_json,
};
use std::path::Path;

#[test]
fn godot_recipe_headers_rebuild_both_factories_subsets_stand_ins_and_custom_config() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let lines = include_str!("../../gd/recipe_headers.jsonl");
    for (index, line) in lines.lines().enumerate() {
        let header = godot_json::parse_string(line).as_dict();
        let result = RecordReplay::rebuild(&root, &Array::from(vec![header.clone()]));
        assert!(result.ok, "recipe {index}: {}", result.message);
        let game = result.session.unwrap();
        assert_eq!(
            game.borrow().seed_value.to_string(),
            header.get("seed").as_text()
        );
        let config = game.borrow().config.as_ref().unwrap().clone();
        assert_eq!(config.borrow().front_slots, 2);
        assert_eq!(config.borrow().back_slots, 3);
        assert_eq!(config.borrow().starting_armor, 7);
        assert!(!result.complete);

        let damaged = header.duplicate();
        damaged.insert("initial_hash", Variant::from("planted wrong hash"));
        let refused = RecordReplay::rebuild(&root, &Array::from(vec![damaged]));
        assert!(!refused.ok);
        assert_eq!(
            refused.message,
            "first differing turn 0: initial state differs"
        );
    }
}
