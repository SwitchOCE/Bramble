// 3.3.1 every usable ability of a board unit, once per legal target.
//! Port of `src/core/recruit/legal_actions.gd`.
#![allow(unused_variables)]
use crate::core::mechanics::mechanic::Target;
use crate::core::recruit::{player_state::PlayerStateRef, recruit::Recruit};
use crate::core::session::game_session::GameSessionRef;
use crate::{Array, Dictionary, ToState, Variant};
#[derive(Default)]
pub struct LegalActions;
macro_rules! action {
    ($($key:expr => $value:expr),* $(,)?) => {{
        let out = Dictionary::new();
        $(out.insert($key, ($value).to_state());)*
        out
    }};
}
impl LegalActions {
    pub fn of(session: &GameSessionRef, player: &PlayerStateRef) -> Array<Dictionary> {
        let out = Array::new();
        if !player.borrow().alive || player.borrow().turn_ended {
            return out;
        }
        if !player.borrow().discover_options.is_empty() {
            for i in 0..player.borrow().discover_options.len() {
                out.push(action! { "type" => "pick", "index" => i as i64 });
            }
            return out;
        }
        Self::_buys(session, player, &out);
        let units = player.borrow().board_units();
        for unit in units.borrow().iter() {
            out.push(action! { "type" => "sell", "slot" => unit.borrow().slot });
        }
        Self::_plays(session, player, &out);
        Self::_abilities(session, player, &out);
        Self::_moves(session, player, &out);
        let rules = session.borrow().rules.as_ref().unwrap().clone();
        if player.borrow().gold >= rules.borrow().refresh_cost(player) {
            out.push(action! { "type" => "refresh" });
        }
        if player.borrow().freezes_used < rules.borrow().freeze_limit(player) {
            out.push(action! { "type" => "freeze" });
        }
        let upgrade = rules.borrow().upgrade_cost(player);
        if upgrade >= 0 && player.borrow().gold >= upgrade {
            out.push(action! { "type" => "upgrade" });
        }
        out.push(action! { "type" => "end_turn" });
        out
    }
    pub fn _buys(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        let rules = session.borrow().rules.as_ref().unwrap().clone();
        if player.borrow().hand.len() as i64 >= rules.borrow().hand_limit(player) {
            return;
        }
        for spell in [false, true] {
            let shop = if spell {
                player.borrow().shop_spells.clone()
            } else {
                player.borrow().shop_units.clone()
            };
            for i in 0..shop.len() {
                let id = shop.get(i).unwrap();
                if id.is_empty() {
                    continue;
                }
                let library = session.borrow().library.as_ref().unwrap().clone();
                let card = library.borrow().get_card(&id).expect("shop card");
                let price = if spell {
                    rules.borrow().spell_price(player, &card)
                } else {
                    rules.borrow().unit_price(player, &card)
                };
                if player.borrow().gold >= price {
                    out.push(action! { "type" => "buy", "spell" => spell, "index" => i as i64 });
                }
            }
        }
    }
    pub fn _plays(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        let recruit = session.borrow().recruit.as_ref().unwrap().clone();
        let empty = player.borrow().empty_slots();
        let hand_size = player.borrow().hand.len();
        for i in 0..hand_size {
            let card = player.borrow().hand.get(i).unwrap();
            let kind = Recruit::play_target_of(&recruit, &card);
            let mut choices = Array::from([-1_i64]);
            if kind != Target::None {
                let targets = Recruit::targets_for(&recruit, player, kind, Some(&card));
                if !targets.is_empty() {
                    choices = targets;
                } else if card.borrow().is_spell() {
                    continue;
                }
            }
            if card.borrow().is_spell() {
                for target in choices.borrow().iter() {
                    out.push(action! { "type" => "play", "hand" => i as i64, "slot" => -1_i64, "target" => *target });
                }
                continue;
            }
            for slot in empty.borrow().iter() {
                for target in choices.borrow().iter() {
                    out.push(action! { "type" => "play", "hand" => i as i64, "slot" => *slot, "target" => *target });
                }
            }
        }
    }
    pub fn _abilities(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        let recruit = session.borrow().recruit.as_ref().unwrap().clone();
        let units = player.borrow().board_units();
        let mut i = 0;
        while i < units.len() {
            let unit = units.get(i).unwrap();
            i += 1;
            let hooks = unit.borrow().hooks();
            let mut j = 0;
            while j < hooks.len() {
                let bound = hooks.get(j).unwrap();
                j += 1;
                let (mechanic, params, id) = {
                    let b = bound.borrow();
                    (
                        b.mechanic.as_ref().unwrap().clone(),
                        b.params.clone(),
                        b.id.clone(),
                    )
                };
                if !mechanic.has_ability()
                    || !Recruit::ability_error(&recruit, player, &unit, &bound).is_empty()
                {
                    continue;
                }
                let kind = mechanic.ability_target(&params);
                let mut choices = Array::from([-1_i64]);
                if kind != Target::None {
                    choices = Recruit::targets_for(&recruit, player, kind, Some(&unit));
                }
                for target in choices.borrow().iter() {
                    out.push(action! { "type" => "ability", "uid" => unit.borrow().uid, "mechanic" => id, "target" => *target });
                }
            }
        }
    }
    pub fn _moves(session: &GameSessionRef, player: &PlayerStateRef, out: &Array<Dictionary>) {
        let units = player.borrow().board_units();
        for unit in units.borrow().iter() {
            for slot in 0..session
                .borrow()
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .slot_count
            {
                if slot != unit.borrow().slot {
                    out.push(
                        action! { "type" => "move", "from" => unit.borrow().slot, "to" => slot },
                    );
                }
            }
        }
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
