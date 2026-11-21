//! State, action results, and event order against the GDScript waiting-pile oracle.
use bramble_engine::core::{
    ghosts::ghost_run::GhostRun,
    mechanics::{mechanic::Mechanic, mechanic_params::MechanicParamsRef},
    records::{fight_snapshot::FightSnapshot, record_state::RecordState},
    recruit::{player_state::PlayerStateRef, recruit::Recruit, recruit_context::RecruitContext},
    session::game_session::{GameSession, GameSessionRef},
    units::unit::UnitRef,
};
use bramble_engine::game::game_content::GameContent;
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, ToState, Variant, state_dict};
use sha2::{Digest, Sha256};
use std::{path::Path, rc::Rc};

const PROBE: &str = "waiting_proof";

struct Probe;

impl ToState for Probe {
    fn to_state(&self) -> Variant {
        state_dict! {}
    }
}

impl Mechanic for Probe {
    fn on_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let first = ctx.player.as_ref().unwrap().borrow().hand.get(0).unwrap();
        ctx.buff(&first, 1, 0, true, unit);
    }

    fn on_any_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        _sold: &UnitRef,
        _params: &MechanicParamsRef,
    ) {
        ctx.give_card("sp_seek", unit);
    }

    fn on_recruited(
        &self,
        ctx: &mut RecruitContext,
        unit: &UnitRef,
        _target: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let player = ctx.player.as_ref().unwrap().clone();
        let def = unit.borrow().def.clone().unwrap();
        if def.borrow().id == "quartermaster" {
            let hand = player.borrow().hand.clone();
            for card in hand.iter_live() {
                if !card.borrow().is_spell() {
                    ctx.give_keyword(&card, "pigeon_reserve", Some(unit));
                }
            }
        } else {
            let first = player.borrow().board.get(0).flatten().unwrap();
            let attack = first.borrow().attack();
            ctx.buff(unit, attack, 0, true, Some(unit));
        }
    }
}

#[test]
fn waiting_pile_matches_godot_at_each_step() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let content = GameContent::load_default(&root);
    assert!(content.borrow().errors.is_empty());
    assert!(
        content
            .borrow()
            .registry
            .borrow_mut()
            .register(PROBE, Rc::new(Probe))
    );
    let cases =
        godot_json::parse_string(include_str!("fixtures/waiting_pile_cases.json")).as_dict();
    let expected = include_str!("fixtures/waiting_pile_vectors.jsonl");
    let mut rows = expected.lines().map(godot_json::parse_string);

    for (case, steps) in cases.borrow().iter() {
        let game = content.borrow().new_session(42, &Array::new());
        GameSession::start_round(&game);
        let player = game.borrow().player(0);
        player.borrow_mut().gold = 20;
        game.borrow().events.clear();
        for (i, step) in steps.as_array().iter_live().enumerate() {
            let result = run_step(&game, &player, &step.as_array().to_vec());
            let g = game.borrow();
            let joins = g
                .events
                .iter_live()
                .filter(|e| e.get("type").as_text() == "waiting_join")
                .count();
            let events = format!(
                "{:x}",
                Sha256::digest(godot_json::stringify(&g.events.to_state()))
            );
            let actual = state_dict! {
                "case" => case, "step" => &(i as i64), "result" => &result,
                "hash" => &RecordState::state_hash(&g), "events" => &events,
                "waiting" => &(player.borrow().waiting_pile.len() as i64),
                "joins" => &(joins as i64), "choices" => &(player.borrow().recruit_choices.len() as i64),
            };
            let expected = rows.next().expect("Godot checkpoint").to_state();
            assert_eq!(
                godot_json::stringify(&actual),
                godot_json::stringify(&expected),
                "{case} step {i}: {}\nEvents: {}",
                godot_json::stringify(&step),
                godot_json::stringify(&g.events.to_state()),
            );
            g.events.clear();
        }
    }
    assert!(rows.next().is_none());
}

fn run_step(game: &GameSessionRef, player: &PlayerStateRef, step: &[Variant]) -> Variant {
    let arg = step.get(1).unwrap_or(&Variant::Nil);
    let index = step.get(2).map_or(-1, Variant::as_i64);
    let op = step[0].as_text();
    match op.as_str() {
        "board" | "hand" => {
            let name = arg.as_text();
            let (id, golden) = name
                .strip_suffix('*')
                .map_or((name.as_str(), false), |id| (id, true));
            let library = game.borrow().library.clone().unwrap();
            let def = library
                .borrow()
                .get_card(id)
                .unwrap_or_else(|| panic!("unknown card {id}"));
            let copies = if op == "hand" { index.max(1) } else { 1 };
            for _ in 0..copies {
                let unit = game.borrow_mut().new_unit(&def, golden);
                if let Some(mechanic) = step.get(3) {
                    unit.borrow_mut().grant(
                        game.borrow().registry.as_ref().unwrap(),
                        &mechanic.as_text(),
                    );
                }
                if op == "hand" {
                    player.borrow().hand.push(unit);
                } else {
                    player.borrow_mut().place(&unit, index);
                }
            }
        }
        "give" => {
            let recruit = game.borrow().recruit.clone().unwrap();
            let mut ctx = RecruitContext::new(game, &recruit, player);
            let source = player.borrow().board.get(index as usize).flatten();
            let ids: Array<_> = (0..step.get(3).map_or(1, Variant::as_i64))
                .map(|_| {
                    ctx.give_card(&arg.as_text(), source.as_ref())
                        .unwrap()
                        .borrow()
                        .uid
                })
                .collect();
            return ids.to_state();
        }
        "grant_waiting" => {
            let unit = player
                .borrow()
                .waiting_pile
                .borrow()
                .last()
                .unwrap()
                .clone();
            unit.borrow_mut()
                .grant(game.borrow().registry.as_ref().unwrap(), &arg.as_text());
        }
        "offer" => player.borrow_mut().discover_options = Array::from([arg.as_text()]),
        "act" => {
            let action = arg.as_dict().duplicate();
            if index >= 0 {
                let unit = player.borrow().board.get(index as usize).flatten().unwrap();
                action.insert("target", unit.borrow().uid.into());
            } else if index < -1 {
                let unit = player.borrow().hand.get((-index - 2) as usize).unwrap();
                action.insert("target", unit.borrow().uid.into());
            }
            return GameSession::act(game, 0, &action).into();
        }
        "legal" => {
            let actions: Array<Dictionary> = game
                .borrow()
                .legal_actions(0)
                .iter_live()
                .filter(|a| matches!(a.get("type").as_text().as_str(), "pick" | "recruit_target"))
                .collect();
            return actions.to_state();
        }
        "settle" => {
            let recruit = game.borrow().recruit.clone().unwrap();
            Recruit::_settle(&recruit, player);
        }
        "auras" => {
            let recruit = game.borrow().recruit.clone().unwrap();
            Recruit::refresh_auras(&recruit, player);
        }
        "attack" => {
            let p = player.borrow();
            let first = p.board.get(0).flatten().unwrap();
            let joined = p.hand.get(arg.as_i64() as usize).unwrap();
            let attack = first.borrow().attack();
            let read = joined.borrow().stats.as_ref().unwrap().borrow().perm_attack;
            return Variant::array(vec![attack.into(), read.into()]);
        }
        "start" => GameSession::start_round(game),
        "end" => GameSession::end_turn(game, 0),
        "stamp" => {
            let unit = player.borrow().waiting_pile.get(0).unwrap();
            let mut unit = unit.borrow_mut();
            unit.worked_this_turn = true;
            unit.turn_counters.insert("proof", 1.into());
            unit.stats.as_ref().unwrap().borrow_mut().turn_attack = 3;
        }
        "restore" => {
            let mut game = game.borrow_mut();
            let payload = RecordState::fight_players(&game).get(0).unwrap().as_dict();
            let owner = game.player(1);
            let mut owner = owner.borrow_mut();
            FightSnapshot::restore_player(&payload, &mut owner, &mut game, GhostRun::UID_STRIDE);
            let restored =
                FightSnapshot::units(&owner.waiting_pile.iter_live().map(Some).collect());
            let saved = payload.get("waiting_pile");
            payload.erase("waiting_pile");
            FightSnapshot::restore_player(&payload, &mut owner, &mut game, GhostRun::UID_STRIDE);
            return state_dict! {
                "saved" => &saved, "restored" => &restored, "cleared" => &owner.waiting_pile.is_empty(),
            };
        }
        "retire" => GameSession::_retire(game, player, 8),
        _ => panic!("unknown waiting-pile proof step {op}"),
    }
    Variant::Nil
}
