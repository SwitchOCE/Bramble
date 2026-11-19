//! Port of `src/core/bots/random_bot.gd`.
use crate::core::recruit::player_state::PlayerStateRef;
use crate::core::session::game_session::GameSessionRef;
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
        let id = player.borrow().id;
        let legal = session.borrow().legal_actions(id);
        let by_type = Dictionary::<Array<Dictionary>>::new();
        let types = Array::new();
        for action in legal.iter_live() {
            let kind = action.get("type").as_text();
            if kind == "end_turn" {
                continue;
            }
            if !by_type.borrow().contains_key(&kind) {
                by_type.borrow_mut().insert(kind.clone(), Array::new());
                types.push(kind.clone());
            }
            by_type.borrow()[&kind].push(action);
        }
        let must_pick = by_type.borrow().contains_key("pick")
            || by_type.borrow().contains_key("recruit_target");
        let mut rng = self.rng.as_ref().expect("bot RNG").borrow_mut();
        if types.is_empty() || (!must_pick && rng.index(Self::END_CHANCE) == 0) {
            return crate::state_dict! {"type"=>"end_turn"}.as_dict();
        }
        let kind = types
            .get(rng.index(types.len() as i64) as usize)
            .expect("action type");
        let options = by_type.borrow()[&kind].clone();
        options
            .get(rng.index(options.len() as i64) as usize)
            .expect("legal action")
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
