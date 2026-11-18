//! Port of `src/core/bots/simple_bot.gd`.
#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::recruit::player_state::PlayerStateRef;
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::util::rng::RngRef;
pub type SimpleBotRef = Rc<RefCell<SimpleBot>>;
#[derive(Default)]
pub struct SimpleBot {
    pub rng: Option<RngRef>,
    pub refused: i64,
    pub last_refusal: String,
}
impl SimpleBot {
    pub const MAX_REFRESHES: i64 = 3;
    pub fn new(stream: &RngRef) -> Self { Self { rng: Some(stream.clone()), refused: 0, last_refusal: String::new() } }
    pub fn choose(&mut self, session: &GameSessionRef, player: &PlayerStateRef) -> Dictionary { todo!("port src/core/bots/simple_bot.gd:choose") }
    pub fn _score(&self, session: &GameSessionRef, player: &PlayerStateRef, action: &Dictionary) -> f64 { todo!("port src/core/bots/simple_bot.gd:_score") }
    pub fn _worth(card: &UnitDefRef) -> f64 { todo!("port src/core/bots/simple_bot.gd:_worth") }
    pub fn _unit_worth(unit: &UnitRef) -> f64 { todo!("port src/core/bots/simple_bot.gd:_unit_worth") }
    pub fn _upgrade_score(&self, session: &GameSessionRef, player: &PlayerStateRef) -> f64 { todo!("port src/core/bots/simple_bot.gd:_upgrade_score") }
    pub fn _play_score(&self, player: &PlayerStateRef, action: &Dictionary) -> f64 { todo!("port src/core/bots/simple_bot.gd:_play_score") }
    pub fn _buy_score(&self, session: &GameSessionRef, player: &PlayerStateRef, action: &Dictionary) -> f64 { todo!("port src/core/bots/simple_bot.gd:_buy_score") }
    pub fn _sell_score(&self, player: &PlayerStateRef, slot: i64) -> f64 { todo!("port src/core/bots/simple_bot.gd:_sell_score") }
    pub fn _weakest(player: &PlayerStateRef) -> Option<UnitRef> { todo!("port src/core/bots/simple_bot.gd:_weakest") }
}
impl ToState for SimpleBot {
    fn to_state(&self) -> Variant { crate::state_dict!{ "rng"=> &self.rng, "refused"=> &self.refused, "last_refusal"=> &self.last_refusal } }
    fn field_names() -> &'static [&'static str] { &["rng", "refused", "last_refusal"] }
}
