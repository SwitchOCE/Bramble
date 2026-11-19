//! Checks action results, snapshots, logs and state hashes against the GDScript recruit vectors.
use bramble_engine::core::{
    records::{fight_snapshot::FightSnapshot, record_state::RecordState},
    recruit::legal_actions::LegalActions,
    recruit::player_state::PlayerStateRef,
    session::game_session::{GameSession, GameSessionRef},
    units::unit::UnitRef,
};
use bramble_engine::game::game_content::GameContent;
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, ToState, Variant, state_dict};
use std::path::Path;

const SUPPLY: &str = "supply:pigeon_sentry";

fn session() -> (GameSessionRef, PlayerStateRef) {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let content = GameContent::load_default(&root);
    assert!(content.borrow().errors.is_empty());
    let game = content.borrow().new_session(42, &Array::new());
    GameSession::start_round(&game);
    let player = game.borrow().player(0);
    player.borrow_mut().gold = 20;
    (game, player)
}

fn in_hand(game: &GameSessionRef, player: &PlayerStateRef, id: &str) -> UnitRef {
    let card = game
        .borrow()
        .library
        .as_ref()
        .unwrap()
        .borrow()
        .get_card(id)
        .unwrap();
    let unit = game.borrow_mut().new_unit(&card, false);
    player.borrow().hand.push(unit.clone());
    unit
}

fn buy(game: &GameSessionRef, target: Option<i64>) -> String {
    let action = state_dict! { "type" => "buy", "index" => &0_i64, "spell" => &false }.as_dict();
    if let Some(target) = target {
        action.insert("target", target.into());
    }
    GameSession::act(game, 0, &action)
}

fn check(case: &str, actual: &Variant) {
    let expected = godot_json::parse_string(include_str!("fixtures/rework_recruit.json"))
        .as_dict()
        .get(case)
        .to_state();
    assert_eq!(
        godot_json::stringify(actual),
        godot_json::stringify(&expected)
    );
}

#[test]
fn sentry_triple_adds_remaining_supply_and_logs_the_next_use() {
    let (game, player) = session();
    for left in [2_i64, 0] {
        let copy = in_hand(&game, &player, "sentry");
        copy.borrow().counters.insert(SUPPLY, left.into());
    }
    player.borrow().shop_units.borrow_mut()[0] = "sentry".into();
    let bought = buy(&game, Some(-1));
    let golden = player.borrow().hand.get(0).unwrap();
    let snapshot = FightSnapshot::unit(&golden);
    GameSession::end_turn(&game, 0);
    GameSession::start_round(&game);
    let played = GameSession::act(
        &game,
        0,
        &state_dict! { "type" => "play", "hand" => &0_i64, "slot" => &0_i64 }.as_dict(),
    );
    GameSession::end_turn(&game, 0);
    let events: Array<Dictionary> = game
        .borrow()
        .events
        .iter_live()
        .filter(|event| event.get("type").as_text() == "renown")
        .collect();
    check(
        "supply",
        &state_dict! {
            "buy" => &bought, "play" => &played, "triple" => &snapshot,
            "spent" => &golden.borrow().counter(SUPPLY),
            "events" => &events, "hash" => &RecordState::state_hash(&game.borrow()),
        },
    );
}

#[test]
fn quartermaster_picker_excludes_self_and_defaults_to_the_leftmost_eligible_unit() {
    let (game, player) = session();
    for id in ["territorial", "sentry", "brock-cub"] {
        in_hand(&game, &player, id);
    }
    player.borrow().shop_units.borrow_mut()[0] = "quartermaster".into();
    let before: Array<_> = LegalActions::of(&game, &player)
        .iter_live()
        .filter(|action| {
            action.get("type").as_text() == "buy"
                && action.get("index").as_i64() == 0
                && action.get("spell") == Variant::Bool(false)
        })
        .collect();
    let bought = buy(&game, None);
    let after = LegalActions::of(&game, &player);
    let source = player.borrow().recruit_choices.get(0).unwrap();
    let refusal = GameSession::act(
        &game,
        0,
        &state_dict! { "type" => "recruit_target", "target" => &source.borrow().uid }.as_dict(),
    );
    GameSession::end_turn(&game, 0);
    let hand: Array<_> = player
        .borrow()
        .hand
        .iter_live()
        .map(|unit| FightSnapshot::unit(&unit))
        .collect();
    check(
        "quartermaster",
        &state_dict! {
            "buy" => &bought, "before" => &before, "after" => &after, "self_refusal" => &refusal,
            "hand" => &hand, "hash" => &RecordState::state_hash(&game.borrow()),
        },
    );
}

#[test]
fn grenadier_moves_guard_and_leaves_earned_renown_on_the_old_slot() {
    let (game, player) = session();
    let grenadier = in_hand(&game, &player, "grenadier-guard");
    let played = GameSession::act(
        &game,
        0,
        &state_dict! { "type" => "play", "hand" => &0_i64, "slot" => &0_i64 }.as_dict(),
    );
    let action = state_dict! {
        "type" => "ability", "uid" => &grenadier.borrow().uid,
        "mechanic" => "pigeon_grenadier", "target" => &0_i64,
    }
    .as_dict();
    let placed = GameSession::act(&game, 0, &action);
    GameSession::end_turn(&game, 0);
    GameSession::start_round(&game);
    action.insert("target", 3_i64.into());
    let moved = GameSession::act(&game, 0, &action);
    assert_eq!((&*played, &*placed, &*moved), ("", "", ""));
    let slots: Array<_> = player
        .borrow()
        .slots
        .iter_live()
        .map(|slot| slot.borrow().view())
        .collect();
    let events: Array<_> = game
        .borrow()
        .events
        .iter_live()
        .filter(|event| matches!(event.get("type").as_text().as_str(), "slot" | "renown"))
        .collect();
    check(
        "grenadier",
        &state_dict! {
            "play" => &played, "place" => &placed, "move" => &moved,
            "slots" => &slots, "events" => &events,
            "hash" => &RecordState::state_hash(&game.borrow()),
        },
    );
}
