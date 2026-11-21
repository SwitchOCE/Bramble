//! Mirrors src/core/records/record_state.gd.
use crate::core::{
    records::fight_snapshot::FightSnapshot,
    session::{game_session::GameSession, matchmaking::Matchmaking},
};
use crate::{Array, Dictionary, ToState, Variant};
use sha2::{Digest, Sha256};
pub struct RecordState;
impl RecordState {
    pub const SESSION_SKIP: &'static [&'static str] = &[
        "registry",
        "library",
        "unit_odds",
        "spell_odds",
        "recruit",
        "rules",
        "geometry",
        "display",
        "events",
        "fights",
        "keep_fight_events",
        "record",
        "record_recipe",
        "runs",
    ];
    pub fn session_state(game: &GameSession) -> Dictionary {
        let out = Self::fields(game, Self::SESSION_SKIP);
        // An all-live seat map is implicit in live records.
        if !game.is_async() {
            out.erase("run_ids");
        }
        let recruit = game.recruit.as_ref().expect("session recruit");
        out.insert(
            "recruit_rng",
            Variant::Dictionary(Self::fields(
                &*recruit.borrow(),
                &["session", "_session_ref"],
            )),
        );
        out
    }
    pub fn state_hash(game: &GameSession) -> String {
        format!(
            "{:x}",
            Sha256::digest(
                crate::util::godot_json::stringify(&Variant::Dictionary(Self::session_state(game)))
                    .as_bytes()
            )
        )
    }
    pub fn fields<T: ToState>(object: &T, skip: &[&str]) -> Dictionary {
        object.script_state_without(skip).as_dict()
    }
    pub fn value(raw: &Variant) -> Variant {
        raw.to_state()
    }
    pub fn fight_players(game: &GameSession) -> Array<Variant> {
        let out = Array::new();
        for player in game.alive_players().borrow().iter() {
            let p = player.borrow();
            let entry=crate::state_dict!{"id"=>&p.id,"tier"=>&p.tier,"slots"=>&p.slots,"counters"=>&p.counters,"heaps"=>&p.heaps,"standing"=>&p.standing}.as_dict();
            entry.insert("board", Variant::Array(FightSnapshot::units(&p.board)));
            let hand = p.hand.borrow().iter().cloned().map(Some).collect();
            entry.insert("hand", Variant::Array(FightSnapshot::units(&hand)));
            if !p.waiting_pile.is_empty() {
                let waiting_pile = p.waiting_pile.borrow().iter().cloned().map(Some).collect();
                entry.insert(
                    "waiting_pile",
                    Variant::Array(FightSnapshot::units(&waiting_pile)),
                );
            }
            out.push(Variant::Dictionary(entry));
        }
        if let Some(ghost) = &game.ghost_player
            && game.pairings.borrow().iter().any(|p| {
                p.as_array()
                    .borrow()
                    .iter()
                    .any(|id| id.as_i64() == Matchmaking::GHOST)
            })
        {
            let p = ghost.borrow();
            let entry=crate::state_dict!{"tier"=>&p.tier,"slots"=>&p.slots,"counters"=>&p.counters,"heaps"=>&p.heaps,"standing"=>&p.standing,"id"=>&Matchmaking::GHOST,"of"=>&game.ghost_of}.as_dict();
            entry.insert(
                "board",
                Variant::Array(FightSnapshot::units(&game.ghost_board)),
            );
            let hand = game.ghost_hand.borrow().iter().cloned().map(Some).collect();
            entry.insert("hand", Variant::Array(FightSnapshot::units(&hand)));
            out.push(Variant::Dictionary(entry));
        }
        out
    }
}
impl ToState for RecordState {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::game::game_content::GameContent;
    use crate::util::godot_json::stringify;
    use std::path::Path;

    #[test]
    fn filtered_session_matches_convert_then_erase_bytes_and_hash() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR"))
            .ancestors()
            .nth(3)
            .unwrap();
        let content = GameContent::load_folders(root, &Array::new());
        let content = content.borrow();
        assert!(content.errors.is_empty());
        let game =
            GameSession::create(42, &content.library, &content.registry, None, &Array::new());
        let game = game.borrow();
        game.events
            .push(crate::state_dict! {"ignored" => "event"}.as_dict());
        game.fights
            .push(crate::state_dict! {"ignored" => "fight"}.as_dict());
        game.display.insert("ignored", Variant::from("display"));

        // The previous implementation converted every field, then erased exclusions.
        let legacy = game.script_state().as_dict();
        for key in RecordState::SESSION_SKIP {
            legacy.erase(key);
        }
        legacy.erase("run_ids");
        let recruit = game.recruit.as_ref().unwrap().borrow();
        let recruit_state = recruit.script_state().as_dict();
        recruit_state.erase("session");
        recruit_state.erase("_session_ref");
        legacy.insert("recruit_rng", Variant::Dictionary(recruit_state));
        let legacy_json = stringify(&Variant::Dictionary(legacy.clone()));
        let actual = RecordState::session_state(&game);
        assert_eq!(
            actual.borrow().keys().collect::<Vec<_>>(),
            legacy.borrow().keys().collect::<Vec<_>>()
        );
        assert_eq!(stringify(&Variant::Dictionary(actual)), legacy_json);
        assert_eq!(
            RecordState::state_hash(&game),
            format!("{:x}", Sha256::digest(legacy_json.as_bytes()))
        );
    }

    #[test]
    fn filtered_session_does_not_convert_excluded_containers() {
        let game = GameSession::default();
        // Converting any of these held containers would panic on its RefCell borrow.
        let _events = game.events.borrow_mut();
        let _fights = game.fights.borrow_mut();
        let _display = game.display.borrow_mut();
        let actual = RecordState::fields(&game, RecordState::SESSION_SKIP);
        assert!(!actual.has("events"));
        assert!(!actual.has("fights"));
        assert!(!actual.has("display"));
        assert!(actual.has("_next_uid"));
    }

    #[test]
    fn filtered_fields_fallback_preserves_script_state_override() {
        struct Special;
        impl ToState for Special {
            fn to_state(&self) -> Variant {
                Variant::from("special value conversion")
            }
            fn script_state(&self) -> Variant {
                crate::state_dict! {"first" => &1_i64, "skip" => &2_i64, "last" => &3_i64}
            }
        }
        assert_eq!(
            stringify(&Variant::Dictionary(RecordState::fields(
                &Special,
                &["skip", "missing"]
            ))),
            r#"{"first":1,"last":3}"#
        );
    }
}
