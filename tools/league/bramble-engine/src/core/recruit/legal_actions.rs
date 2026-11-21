// 3.3.1 every usable ability of a board unit, once per legal target.
//! Port of `src/core/recruit/legal_actions.gd`.
#![allow(unused_variables)]
use crate::core::mechanics::mechanic::Target;
use crate::core::recruit::{player_state::PlayerStateRef, recruit::Recruit};
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::unit_def::UnitDefRef;
use crate::{Array, Dictionary, ToState, Variant};
#[derive(Default)]
pub struct LegalActions;
/// Output adapter for the same ordered enumeration. Sandboxes can emit plain typed
/// actions without allocating and immediately discarding Godot dictionaries.
pub trait ActionOutput {
    fn from_fields(kind: &'static str, fields: &[(&'static str, Variant)]) -> Self;
}
impl ActionOutput for Dictionary {
    fn from_fields(kind: &'static str, fields: &[(&'static str, Variant)]) -> Self {
        let out = Dictionary::new();
        out.insert("type", kind.into());
        for (key, value) in fields {
            out.insert(*key, value.clone());
        }
        out
    }
}
macro_rules! action {
    ("type" => $kind:expr $(, $key:expr => $value:expr)* $(,)?) => {
        T::from_fields($kind, &[$(($key, ($value).to_state())),*])
    };
}
impl LegalActions {
    pub fn of(session: &GameSessionRef, player: &PlayerStateRef) -> Array<Dictionary> {
        Self::of_into(session, player)
    }
    pub fn of_into<T: ActionOutput>(session: &GameSessionRef, player: &PlayerStateRef) -> Array<T> {
        let out = Array::new();
        if !player.borrow().alive || player.borrow().turn_ended {
            return out;
        }
        let source = player.borrow().recruit_choices.get(0);
        if let Some(source) = source {
            let registry = session.borrow().registry.clone().expect("registry");
            let def = source.borrow().def.clone().expect("unit definition");
            let effect = Recruit::targeted_recruit(&def, &registry);
            for target in
                Recruit::recruit_targets(player, effect.as_ref(), Some(&source)).iter_live()
            {
                out.push(action! { "type" => "recruit_target", "target" => target });
            }
            return out;
        }
        let options = player.borrow().discover_options.clone();
        if !options.is_empty() {
            let library = session.borrow().library.clone().expect("session library");
            let recruit = session.borrow().recruit.clone().expect("session recruit");
            for (i, id) in options.iter_live().enumerate() {
                if Recruit::gain_waits(&recruit, player) {
                    out.push(action! { "type" => "pick", "index" => i as i64 });
                } else {
                    let card = library.borrow().get_card(&id).expect("discover card");
                    Self::_gains(session, player, &card, "pick", i as i64, false, None, &out);
                }
            }
            return out;
        }
        Self::_buys(session, player, &out);
        let units = player.borrow().board_units();
        for unit in units.borrow().iter() {
            out.push(action! { "type" => "sell", "slot" => unit.borrow().slot });
        }
        for (i, unit) in player.borrow().hand.iter_live().enumerate() {
            if !unit.borrow().is_spell() {
                out.push(action! { "type" => "sell", "hand" => i as i64 });
            }
        }
        let recruit = session.borrow().recruit.clone().expect("session recruit");
        for unit in units.iter_live() {
            let slot = unit.borrow().slot;
            if Recruit::to_hand_error(&recruit, player, slot).is_empty() {
                out.push(action! { "type" => "to_hand", "slot" => slot });
            }
        }
        Self::_plays(session, player, &out);
        Self::_abilities(session, player, &out);
        Self::_moves(session, player, &out);
        let rules = session.borrow().rules.as_ref().unwrap().clone();
        if player.borrow().gold >= rules.borrow().refresh_cost(player, None) {
            out.push(action! { "type" => "refresh" });
        }
        if player.borrow().freezes_used < rules.borrow().freeze_limit(player) {
            out.push(action! { "type" => "freeze" });
        }
        let upgrade = rules.borrow().upgrade_cost(player, None);
        if upgrade >= 0 && player.borrow().gold >= upgrade {
            out.push(action! { "type" => "upgrade" });
        }
        out.push(action! { "type" => "end_turn" });
        out
    }
    pub fn _buys<T: ActionOutput>(
        session: &GameSessionRef,
        player: &PlayerStateRef,
        out: &Array<T>,
    ) {
        let rules = session.borrow().rules.as_ref().unwrap().clone();
        let hand_room = (player.borrow().hand.len() as i64) < rules.borrow().hand_limit(player);
        let empty = player.borrow().empty_slots();
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
                    rules.borrow().spell_price(player, &card, None)
                } else {
                    rules.borrow().unit_price(player, &card, None)
                };
                if player.borrow().gold >= price {
                    if hand_room {
                        Self::_gains(session, player, &card, "buy", i as i64, spell, None, out);
                    }
                    if !spell {
                        for slot in empty.iter_live() {
                            Self::_gains(
                                session,
                                player,
                                &card,
                                "buy",
                                i as i64,
                                spell,
                                Some(slot),
                                out,
                            );
                        }
                    }
                }
            }
        }
    }
    pub fn _plays<T: ActionOutput>(
        session: &GameSessionRef,
        player: &PlayerStateRef,
        out: &Array<T>,
    ) {
        let recruit = session.borrow().recruit.as_ref().unwrap().clone();
        let slot_count = session
            .borrow()
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .slot_count;
        let hand_size = player.borrow().hand.len();
        for i in 0..hand_size {
            let card = player.borrow().hand.get(i).unwrap();
            if !card.borrow().is_spell() {
                for slot in 0..slot_count {
                    let swap = player.borrow().board.get(slot as usize).flatten().is_some();
                    if Recruit::play_slot_error(&recruit, player, slot, swap).is_empty() {
                        if swap {
                            out.push(action! { "type" => "play", "hand" => i as i64, "slot" => slot, "target" => -1_i64, "swap" => true });
                        } else {
                            out.push(action! { "type" => "play", "hand" => i as i64, "slot" => slot, "target" => -1_i64 });
                        }
                    }
                }
                continue;
            }
            let kind = Recruit::play_target_of(&recruit, &card);
            let mut choices = Array::from([-1_i64]);
            if kind != Target::None {
                let targets = Recruit::targets_for(&recruit, player, kind, Some(&card));
                if !targets.is_empty() {
                    choices = targets;
                } else {
                    continue;
                }
            }
            for target in choices.iter_live() {
                out.push(action! { "type" => "play", "hand" => i as i64, "slot" => -1_i64, "target" => target });
            }
        }
    }
    pub fn _abilities<T: ActionOutput>(
        session: &GameSessionRef,
        player: &PlayerStateRef,
        out: &Array<T>,
    ) {
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
    pub fn _moves<T: ActionOutput>(
        session: &GameSessionRef,
        player: &PlayerStateRef,
        out: &Array<T>,
    ) {
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

    // -1 selects the gained unit itself before its uid exists.
    fn _gains<T: ActionOutput>(
        session: &GameSessionRef,
        player: &PlayerStateRef,
        card: &UnitDefRef,
        kind: &'static str,
        index: i64,
        spell: bool,
        slot: Option<i64>,
        out: &Array<T>,
    ) {
        let targets = Array::from([-1_i64]);
        let registry = session.borrow().registry.clone().expect("registry");
        if let Some(effect) = Recruit::targeted_recruit(card, &registry) {
            targets
                .borrow_mut()
                .extend(Recruit::recruit_targets(player, Some(&effect), None).iter_live());
        }
        for target in targets.iter_live() {
            if let Some(slot) = slot {
                out.push(action! { "type" => "buy", "spell" => spell, "index" => index, "slot" => slot, "target" => target });
            } else if kind == "buy" {
                out.push(action! { "type" => "buy", "spell" => spell, "index" => index, "target" => target });
            } else {
                out.push(action! { "type" => "pick", "index" => index, "target" => target });
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
