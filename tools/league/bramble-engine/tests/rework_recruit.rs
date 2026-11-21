//! Checks action results, snapshots, logs and state hashes against the GDScript recruit vectors.
use bramble_engine::core::{
    records::{fight_snapshot::FightSnapshot, record_state::RecordState},
    recruit::legal_actions::LegalActions,
    recruit::player_state::PlayerStateRef,
    recruit::recruit_context::RecruitContext,
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

#[test]
fn sales_match_discover_and_real_and_token_triples() {
    for (case, picks, tokens, shop_card, slot, expected_gold) in [
        ("sell_discover_pick", 1, 0, "", None, 2),
        ("sell_real_triple", 3, 0, "", Some(0_i64), 6),
        ("sell_token_triple", 0, 3, "bramble-runner", None, 0),
        ("sell_bought_token_triple", 0, 2, "pip", None, 1),
    ] {
        let (game, player) = session();
        let act = |action: Variant| GameSession::act(&game, 0, &action.as_dict());
        for _ in 0..picks {
            player.borrow_mut().discover_options = Array::from(["crab-apple".to_owned()]);
            assert_eq!(act(state_dict! { "type" => "pick", "index" => &0_i64 }), "");
        }
        let recruit = game.borrow().recruit.clone().unwrap();
        let mut ctx = RecruitContext::new(&game, &recruit, &player);
        for _ in 0..tokens {
            assert!(ctx.summon("pip", 0, false, false).is_some());
        }
        if !shop_card.is_empty() {
            player.borrow().shop_units.borrow_mut()[0] = shop_card.into();
            assert_eq!(buy(&game, Some(-1)), "");
        }
        // The unrelated buy that settles the summons stays in hand ahead of the triple.
        let hand = i64::from(shop_card == "bramble-runner");
        let unit = player.borrow().hand.get(hand as usize).unwrap();
        let action = if let Some(slot) = slot {
            assert_eq!(
                act(state_dict! { "type" => "play", "hand" => &hand, "slot" => &slot }),
                ""
            );
            state_dict! { "type" => "sell", "slot" => &slot }
        } else {
            state_dict! { "type" => "sell", "hand" => &hand }
        };
        let snapshot = FightSnapshot::unit(&unit);
        let value = game
            .borrow()
            .rules
            .as_ref()
            .unwrap()
            .borrow()
            .sell_value(&player, &unit);
        let before = RecordState::state_hash(&game.borrow());
        let gold = player.borrow().gold;
        let result = act(action);
        let gained = player.borrow().gold - gold;
        assert_eq!(result, "", "{case}");
        assert_eq!(gained, expected_gold, "{case}");
        check(
            case,
            &state_dict! {
                "snapshot" => &snapshot, "value" => &value, "before" => &before,
                "gold_gained" => &gained, "result" => &result,
                "after" => &RecordState::state_hash(&game.borrow()),
            },
        );
    }
}

#[test]
fn horde_runner_raises_tide_on_the_first_locust_sold() {
    let (game, player) = session();
    let mut actions = Vec::new();
    for (slot, id) in ["horde-runner", "bumblebee", "hopper", "green-recruit"]
        .into_iter()
        .enumerate()
    {
        in_hand(&game, &player, id);
        let play = state_dict! {"type"=>"play","hand"=>&0_i64,"slot"=>&(slot as i64)}.as_dict();
        actions.push(GameSession::act(&game, 0, &play));
    }
    let mut levels = Vec::new();
    for slot in [1_i64, 2, 3] {
        let sell = state_dict! {"type"=>"sell","slot"=>&slot}.as_dict();
        actions.push(GameSession::act(&game, 0, &sell));
        levels.push(player.borrow().counter("locust_tide"));
    }
    assert!(actions.iter().all(String::is_empty));
    assert_eq!(levels, [0, 1, 1]);
    check(
        "tide_on_sell",
        &state_dict! {"actions"=>&Array::from(actions), "levels"=>&Array::from(levels), "hash"=>&RecordState::state_hash(&game.borrow())},
    );
}

#[test]
fn a_hopper_overflow_in_recruit_raises_tide_immediately() {
    let (game, player) = session();
    let slots = game.borrow().geometry.as_ref().unwrap().borrow().slot_count;
    for slot in 0..slots {
        let id = if slot == 0 { "gorger" } else { "bumblebee" };
        let card = game
            .borrow()
            .library
            .as_ref()
            .unwrap()
            .borrow()
            .get_card(id)
            .unwrap();
        let unit = game.borrow_mut().new_unit(&card, false);
        player.borrow_mut().place(&unit, slot);
    }
    let recruit = game.borrow().recruit.clone().unwrap();
    let mut ctx = RecruitContext::new(&game, &recruit, &player);
    ctx.give_card("green-recruit", None);
    let sold = GameSession::act(
        &game,
        0,
        &state_dict! {"type"=>"sell","hand"=>&0_i64}.as_dict(),
    );
    let tide = player.borrow().counter("locust_tide");
    assert_eq!(tide, 1);
    check(
        "shop_overflow",
        &state_dict! {"sell"=>&sold,"tide"=>&tide,"hash"=>&RecordState::state_hash(&game.borrow())},
    );
}
