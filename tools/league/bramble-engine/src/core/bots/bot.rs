//! Port of `src/core/bots/bot.gd`.
#![allow(unused_imports, unused_variables)]
use crate::core::recruit::player_state::PlayerStateRef;
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::util::rng::RngRef;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type BotRef = Rc<RefCell<Bot>>;
#[derive(Default)]
pub struct Bot {
    pub rng: Option<RngRef>,
    pub refused: i64,
    pub last_refusal: String,
}
impl Bot {
    pub const MAX_ACTIONS: i64 = 120;
    pub fn new(stream: &RngRef) -> Self {
        Self {
            rng: Some(stream.clone()),
            refused: 0,
            last_refusal: String::new(),
        }
    }
    pub fn take_turn(
        &mut self,
        session: &GameSessionRef,
        player_id: i64,
        after_action: Option<&mut dyn FnMut(&Dictionary)>,
    ) {
        todo!("port src/core/bots/bot.gd:take_turn")
    }
    pub fn choose(&mut self, _session: &GameSessionRef, _player: &PlayerStateRef) -> Dictionary {
        let out = Dictionary::new();
        out.borrow_mut()
            .insert("type".to_owned(), Variant::String("end_turn".to_owned()));
        out
    }
}
impl ToState for Bot {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "rng"=> &self.rng, "refused"=> &self.refused, "last_refusal"=> &self.last_refusal }
    }
    fn field_names() -> &'static [&'static str] {
        &["rng", "refused", "last_refusal"]
    }
}
