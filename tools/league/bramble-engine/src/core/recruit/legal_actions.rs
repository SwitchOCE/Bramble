// 3.3.1 every usable ability of a board unit, once per legal target.
//! Port of `src/core/recruit/legal_actions.gd`.
#![allow(unused_variables)]
use crate::core::recruit::player_state::PlayerStateRef;
use crate::core::session::game_session::GameSessionRef;
use crate::{Array, Dictionary, ToState, Variant};
#[derive(Default)]
pub struct LegalActions;
impl LegalActions {
    pub fn of(session: &GameSessionRef, player: &PlayerStateRef) -> Array<Dictionary> {
        todo!("port src/core/recruit/legal_actions.gd:of")
    }
    pub fn _buys(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        todo!("port src/core/recruit/legal_actions.gd:_buys")
    }
    pub fn _plays(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        todo!("port src/core/recruit/legal_actions.gd:_plays")
    }
    pub fn _abilities(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        todo!("port src/core/recruit/legal_actions.gd:_abilities")
    }
    pub fn _moves(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        todo!("port src/core/recruit/legal_actions.gd:_moves")
    }
}
impl ToState for LegalActions {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
