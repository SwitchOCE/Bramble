//! Port of `src/core/bots/simple_bot.gd`.
use crate::core::recruit::player_state::{PlayerState, PlayerStateRef};
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::util::{core_util::CoreUtil, rng::RngRef};
use crate::{Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type SimpleBotRef = Rc<RefCell<SimpleBot>>;
#[derive(Default)]
pub struct SimpleBot {
    pub rng: Option<RngRef>,
    pub refused: i64,
    pub last_refusal: String,
}
impl SimpleBot {
    pub const MAX_REFRESHES: i64 = 3;
    pub fn new(stream: &RngRef) -> Self {
        Self {
            rng: Some(stream.clone()),
            refused: 0,
            last_refusal: String::new(),
        }
    }
    pub fn choose(&mut self, session: &GameSessionRef, player: &PlayerStateRef) -> Dictionary {
        let mut best = crate::state_dict! {"type"=>"end_turn"}.as_dict();
        let mut best_score = 0.0;
        let mut refresh = Dictionary::new();
        let mut will_buy = false;
        let id = player.borrow().id;
        for action in session.borrow().legal_actions(id).iter_live() {
            let kind = action.get("type").as_text();
            if kind == "refresh" {
                refresh = action;
                continue;
            }
            let score = self._score(session, player, &action);
            will_buy |= kind == "buy" && score > 0.0;
            if score > best_score {
                best_score = score;
                best = action;
            }
        }
        let player = player.borrow();
        let may_refresh = player.refreshes_paid < Self::MAX_REFRESHES && player.gold >= 3;
        if best_score <= 0.0 && !refresh.is_empty() && !will_buy && may_refresh {
            return refresh;
        }
        best
    }
    pub fn _score(
        &self,
        session: &GameSessionRef,
        player: &PlayerStateRef,
        action: &Dictionary,
    ) -> f64 {
        match action.get("type").as_text().as_str() {
            "recruit_target" => {
                let target = player
                    .borrow()
                    .find_uid(action.get("target").as_i64())
                    .expect("recruit target");
                100.0 + Self::_unit_worth(&target)
            }
            "pick" => {
                let index = action.get("index").as_i64() as usize;
                let id = player
                    .borrow()
                    .discover_options
                    .get(index)
                    .expect("discover option");
                let card = session
                    .borrow()
                    .library
                    .as_ref()
                    .unwrap()
                    .borrow()
                    .get_card(&id)
                    .expect("discover card");
                100.0 + Self::_worth(&card)
            }
            "upgrade" => self._upgrade_score(session, player),
            "play" => self._play_score(player, action),
            "buy" => self._buy_score(session, player, action),
            "sell" if action.has("slot") => self._sell_score(player, action.get("slot").as_i64()),
            "ability" => 2.0,
            _ => -1.0,
        }
    }
    pub fn _worth(card: &UnitDefRef) -> f64 {
        let card = card.borrow();
        card.tier as f64 * 10.0 + (card.attack + card.health) as f64 * 0.1
    }
    pub fn _unit_worth(unit: &UnitRef) -> f64 {
        let unit = unit.borrow();
        let tier = unit.def.as_ref().unwrap().borrow().tier;
        (tier + if unit.golden { 2 } else { 0 }) as f64 * 10.0
            + (unit.attack() + unit.health()) as f64 * 0.1
    }
    pub fn _upgrade_score(&self, session: &GameSessionRef, player: &PlayerStateRef) -> f64 {
        let session = session.borrow();
        let cost = session
            .rules
            .as_ref()
            .unwrap()
            .borrow()
            .upgrade_cost(player, None);
        if cost == 0 {
            return 90.0;
        }
        let goal = 1 + (session.round_number + 1) / 2;
        if player.borrow().tier < goal {
            60.0
        } else {
            -1.0
        }
    }
    pub fn _play_score(&self, player: &PlayerStateRef, action: &Dictionary) -> f64 {
        let player = player.borrow();
        let card = player
            .hand
            .get(action.get("hand").as_i64() as usize)
            .expect("hand card");
        let card = card.borrow();
        let mut score = if card.is_spell() {
            45.0
        } else {
            50.0 + card.def.as_ref().unwrap().borrow().tier as f64
        };
        let slot = action.get("slot").as_i64();
        if slot >= 0 {
            score -= slot as f64 * 0.1;
        }
        if let Some(target) = player.find_uid(action.get("target").as_i64()) {
            score += target.borrow().attack() as f64 * 0.001;
        }
        score
    }
    pub fn _buy_score(
        &self,
        session: &GameSessionRef,
        player: &PlayerStateRef,
        action: &Dictionary,
    ) -> f64 {
        let spell = CoreUtil::to_bool(&action.get("spell"));
        let index = action.get("index").as_i64() as usize;
        let player = player.borrow();
        let shop = if spell {
            &player.shop_spells
        } else {
            &player.shop_units
        };
        let id = shop.get(index).expect("shop slot");
        let session = session.borrow();
        let card = session
            .library
            .as_ref()
            .unwrap()
            .borrow()
            .get_card(&id)
            .expect("shop card");
        if spell {
            return if player.board_count() > 0 { 20.0 } else { -1.0 };
        }
        let mut held = 0;
        let mut units_in_hand = 0;
        for unit in player.all_cards().iter_live() {
            let unit = unit.borrow();
            if unit.def.as_ref().unwrap().borrow().id == id && !unit.golden {
                held += 1;
            }
            if unit.slot < 0 && !unit.is_spell() {
                units_in_hand += 1;
            }
        }
        let room = player.board_count() + units_in_hand
            < session.geometry.as_ref().unwrap().borrow().slot_count;
        let weakest = Self::_weakest(&player);
        if !room
            && weakest
                .as_ref()
                .is_none_or(|unit| Self::_worth(&card) <= Self::_unit_worth(unit) + 5.0)
        {
            return if held > 0 { 15.0 * held as f64 } else { -1.0 };
        }
        40.0 + Self::_worth(&card) * 0.1 + 15.0 * held as f64
    }
    pub fn _sell_score(&self, player: &PlayerStateRef, slot: i64) -> f64 {
        let player = player.borrow();
        if !player.empty_slots().is_empty() {
            return -1.0;
        }
        let Some(weakest) = Self::_weakest(&player) else {
            return -1.0;
        };
        if weakest.borrow().slot != slot {
            return -1.0;
        }
        for unit in player.hand.iter_live() {
            if !unit.borrow().is_spell() && Self::_unit_worth(&unit) > Self::_unit_worth(&weakest) {
                return 35.0;
            }
        }
        -1.0
    }
    pub fn _weakest(player: &PlayerState) -> Option<UnitRef> {
        let mut weakest = None;
        for unit in player.board_units().iter_live() {
            if weakest
                .as_ref()
                .is_none_or(|weak| Self::_unit_worth(&unit) < Self::_unit_worth(weak))
            {
                weakest = Some(unit);
            }
        }
        weakest
    }
}
impl ToState for SimpleBot {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "rng"=> &self.rng, "refused"=> &self.refused, "last_refusal"=> &self.last_refusal }
    }
    fn field_names() -> &'static [&'static str] {
        &["rng", "refused", "last_refusal"]
    }
}
