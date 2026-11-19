//! Port of `src/core/bots/random_bot.gd`.
#![allow(unused_imports, unused_variables)]
use crate::core::recruit::player_state::PlayerStateRef;
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::util::rng::RngRef;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type RandomBotRef = Rc<RefCell<RandomBot>>;
#[derive(Default)]
pub struct RandomBot {
    pub rng: Option<RngRef>,
    pub refused: i64,
    pub last_refusal: String,
}
impl RandomBot {
    pub const END_CHANCE: i64 = 8;
    pub fn new(stream: &RngRef) -> Self {
        Self {
            rng: Some(stream.clone()),
            refused: 0,
            last_refusal: String::new(),
        }
    }
    pub fn choose(&mut self, session: &GameSessionRef, player: &PlayerStateRef) -> Dictionary {
        todo!("port src/core/bots/random_bot.gd:choose")
    }
}
impl ToState for RandomBot {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "rng"=> &self.rng, "refused"=> &self.refused, "last_refusal"=> &self.last_refusal }
    }
    fn field_names() -> &'static [&'static str] {
        &["rng", "refused", "last_refusal"]
    }
}
