//! Real Godot 4.7.2 states, generated using gd/dump_state.gd from this pinned source.
use bramble_engine::{
    Array, Variant,
    core::{
        records::record_state::RecordState,
        session::game_session::{GameSession, GameSessionRef},
        units::unit_def::UnitDefRef,
    },
    game::game_content::{GameContent, GameContentRef},
    util::godot_json,
};
use std::path::{Path, PathBuf};

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..")
}

fn content() -> GameContentRef {
    let content = GameContent::load_default(&repo_root());
    assert!(
        content.borrow().errors.is_empty(),
        "content errors: {:?}",
        content.borrow().errors
    );
    content
}

fn session(content: &GameContentRef, seed: i64) -> GameSessionRef {
    content.borrow().new_session(seed, &Array::new())
}

fn hash(game: &GameSessionRef) -> String {
    RecordState::state_hash(&game.borrow())
}

fn first_drawable_card(content: &GameContentRef) -> UnitDefRef {
    content
        .borrow()
        .library
        .borrow()
        .drawable_cards(false)
        .get(0)
        .expect("a shipped drawable unit")
}

fn put_first_unit(game: &GameSessionRef, card: &UnitDefRef) {
    let unit = game.borrow_mut().new_unit(card, false);
    unit.borrow_mut().slot = 0;
    game.borrow().player(0).borrow().board.borrow_mut()[0] = Some(unit);
}

#[test]
fn godot_json_is_byte_equal_on_four_real_initial_states() {
    for (seed, expected) in [
        (1, include_str!("fixtures/initial_1.json")),
        (42, include_str!("fixtures/initial_42.json")),
        (-8172, include_str!("fixtures/initial_-8172.json")),
        (
            i64::MAX,
            include_str!("fixtures/initial_9223372036854775807.json"),
        ),
    ] {
        let game = session(&content(), seed);
        let actual = godot_json::stringify(&Variant::Dictionary(RecordState::session_state(
            &game.borrow(),
        )));
        if actual.as_bytes() != expected.as_bytes() {
            let offset = actual
                .bytes()
                .zip(expected.bytes())
                .position(|(a, b)| a != b)
                .unwrap_or(actual.len().min(expected.len()));
            panic!(
                "seed {seed}: first JSON byte difference at {offset}; Rust {} bytes, Godot {} bytes",
                actual.len(),
                expected.len()
            );
        }
    }
}

#[test]
fn planted_card_attack_is_detected_when_a_unit_exists() {
    let baseline_content = content();
    let attack_content = content();
    let baseline_card = first_drawable_card(&baseline_content);
    let attack_card = first_drawable_card(&attack_content);
    assert_eq!(baseline_card.borrow().id, attack_card.borrow().id);
    attack_card.borrow_mut().attack += 1;

    let baseline = session(&baseline_content, 42);
    let attack = session(&attack_content, 42);
    let initial_hash = hash(&baseline);
    // The library is skipped, and there are no unit stats in a fresh session.
    assert_eq!(initial_hash, hash(&attack));

    put_first_unit(&baseline, &baseline_card);
    put_first_unit(&attack, &attack_card);
    assert_ne!(
        hash(&baseline),
        hash(&attack),
        "instantiated unit stats must expose the planted attack change"
    );

    let oracle = godot_json::parse_string(include_str!("../../gd/planted_vectors.json")).as_dict();
    assert_eq!(initial_hash, oracle.get("initial_hash").as_text());
    assert_eq!(hash(&baseline), oracle.get("unit_hash").as_text());
    assert_eq!(hash(&attack), oracle.get("attack_unit_hash").as_text());
}

#[test]
fn planted_card_tier_changes_first_shop_hash() {
    let baseline_content = content();
    let tier_content = content();
    let tier_card = first_drawable_card(&tier_content);
    tier_card.borrow_mut().tier += 1;
    let baseline = session(&baseline_content, 42);
    let tier = session(&tier_content, 42);
    let oracle = godot_json::parse_string(include_str!("../../gd/planted_vectors.json")).as_dict();
    assert_eq!(hash(&baseline), hash(&tier));
    assert_eq!(hash(&tier), oracle.get("tier_initial_hash").as_text());

    baseline.borrow().record_recipe.clear();
    tier.borrow().record_recipe.clear();
    GameSession::start_round(&baseline);
    GameSession::start_round(&tier);
    assert_ne!(hash(&baseline), hash(&tier));
    assert_eq!(hash(&baseline), oracle.get("shop_hash").as_text());
    assert_eq!(hash(&tier), oracle.get("tier_shop_hash").as_text());
}
