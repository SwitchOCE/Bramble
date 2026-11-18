//! Proves loaded card numbers, golden stats/params, and pure metadata against Godot.
use bramble_engine::{
    Array, ToState, core::records::record_state::RecordState, game::game_content::GameContent,
    util::godot_json,
};
use sha2::{Digest, Sha256};
use std::path::Path;

#[test]
fn every_card_plain_and_golden_state_matches_godot() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let content = GameContent::load_default(&root);
    assert!(
        content.borrow().errors.is_empty(),
        "{:?}",
        content.borrow().errors
    );
    let game = content.borrow().new_session(42, &Array::new());
    let states = Array::new();
    let metadata = Array::new();
    let ids = content.borrow().library.borrow().ids();
    for id in ids.borrow().iter() {
        let card = content.borrow().library.borrow().get_card(id).unwrap();
        for golden in [false, true] {
            let unit = game.borrow_mut().new_unit(&card, golden);
            let unit = unit.borrow();
            states.push(RecordState::value(&unit.to_state()));
            for bound in unit.mechanics.borrow().iter() {
                let bound = bound.borrow();
                let mechanic = bound
                    .mechanic
                    .as_ref()
                    .expect("bound mechanic implementation");
                metadata.push(bramble_engine::state_dict! {
                    "unit" => &unit.uid,
                    "id" => &bound.id,
                    "golden" => &golden,
                    "param_kinds" => &mechanic.param_kinds(),
                    "has_aura" => &mechanic.has_aura(),
                    "has_ability" => &mechanic.has_ability(),
                    "has_death_effect" => &mechanic.has_death_effect(),
                    "play_target" => &(mechanic.play_target(&bound.params) as i64),
                    "start_of_combat_priority" => &mechanic.start_of_combat_priority(&bound.params),
                    "return_priority" => &mechanic.return_priority(&bound.params),
                    "return_as_recruit" => &mechanic.return_as_recruit(&bound.params),
                });
            }
        }
    }
    let payload = bramble_engine::state_dict! { "units" => &states, "metadata" => &metadata };
    let text = godot_json::stringify(&payload);
    let expected =
        godot_json::parse_string(include_str!("../../gd/content_vectors.json")).as_dict();
    assert_eq!(ids.len() as i64, expected.get("cards").as_i64());
    assert_eq!(states.len() as i64, expected.get("units").as_i64());
    assert_eq!(metadata.len() as i64, expected.get("bindings").as_i64());
    let hash = format!("{:x}", Sha256::digest(text.as_bytes()));
    if hash != expected.get("sha256").as_text() {
        let diagnostics = root.join(".copies/content-proofs");
        std::fs::create_dir_all(&diagnostics).unwrap();
        let path = diagnostics.join("rust.json");
        std::fs::write(&path, &text).unwrap();
        panic!(
            "content state hash differs: Rust {hash}, Godot {}; Rust {} bytes, Godot {}; raw Rust saved to {}",
            expected.get("sha256").as_text(),
            text.len(),
            expected.get("bytes").as_i64(),
            path.display()
        );
    }
    assert_eq!(text.len() as i64, expected.get("bytes").as_i64());
}
