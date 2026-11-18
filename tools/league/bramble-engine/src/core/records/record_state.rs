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
        "recruit",
        "rules",
        "geometry",
        "display",
        "events",
        "fights",
        "keep_fight_events",
        "record",
        "record_recipe",
    ];
    pub fn session_state(game: &GameSession) -> Dictionary {
        let out = Self::fields(game, Self::SESSION_SKIP);
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
        let out = object.script_state().as_dict();
        for key in skip {
            out.erase(key);
        }
        out
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
