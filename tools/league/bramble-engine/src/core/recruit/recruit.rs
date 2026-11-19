//! Port of `src/core/recruit/recruit.gd`.
#![allow(unused_variables)]
use crate::core::mechanics::mechanic::Q_DEATH_EFFECT_TIMES;
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::{AURA_GRANTS, AURA_KEYWORDS, AURA_STATS, Hook, HookArgs, Target},
    mechanic_registry::MechanicRegistryRef,
    mechanic_spec::MechanicSpec,
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::rules::rules::RulesRef;
use crate::core::session::game_session::{GameSession, GameSessionRef};
use crate::core::state::{
    aura_context::{AuraContext, AuraContextRef},
    fight_report::FightReportRef,
};
use crate::core::units::unit_library::UnitLibrary;
use crate::core::units::{card_pool::CardPoolRef, unit::UnitRef, unit_def::UnitDefRef};
use crate::core::util::core_util::CoreUtil;
use crate::core::util::rng::{Rng, RngRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};
pub type RecruitRef = Rc<RefCell<Recruit>>;
/// `session` is a GDScript computed property; both handles stay weak to avoid cycles.
pub struct Recruit {
    pub session: Weak<RefCell<GameSession>>,
    pub _session_ref: Weak<RefCell<GameSession>>,
    pub _shop_rng: Dictionary<RngRef, i64>,
    pub _discover_rng: Dictionary<RngRef, i64>,
    pub _effect_rng: Dictionary<RngRef, i64>,
}
impl Recruit {
    fn _session(recruit: &RecruitRef) -> GameSessionRef {
        recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session")
    }
    pub(super) fn _hook(
        bound: &BoundMechanicRef,
    ) -> (
        Rc<dyn crate::core::mechanics::mechanic::Mechanic>,
        crate::core::mechanics::mechanic_params::MechanicParamsRef,
    ) {
        let b = bound.borrow();
        (
            b.mechanic.as_ref().expect("bound mechanic").clone(),
            b.params.clone(),
        )
    }
    pub fn new(game: &GameSessionRef) -> Self {
        let weak = Rc::downgrade(game);
        Self {
            session: weak.clone(),
            _session_ref: weak,
            _shop_rng: Dictionary::new(),
            _discover_rng: Dictionary::new(),
            _effect_rng: Dictionary::new(),
        }
    }
    pub fn _stream(
        recruit: &RecruitRef,
        cache: &Dictionary<RngRef, i64>,
        label: &str,
        player: &PlayerStateRef,
    ) -> RngRef {
        let player_id = player.borrow().id;
        if !cache.borrow().contains_key(&player_id) {
            let seed_value = recruit
                .borrow()
                ._session_ref
                .upgrade()
                .expect("Recruit session")
                .borrow()
                .seed_value;
            cache.borrow_mut().insert(
                player_id,
                Rng::derive(seed_value, &format!("{label}:{player_id}")),
            );
        }
        cache.borrow()[&player_id].clone()
    }
    pub fn shop_rng(recruit: &RecruitRef, player: &PlayerStateRef) -> RngRef {
        let cache = recruit.borrow()._shop_rng.clone();
        Self::_stream(recruit, &cache, "shop", player)
    }
    pub fn discover_rng(recruit: &RecruitRef, player: &PlayerStateRef) -> RngRef {
        let cache = recruit.borrow()._discover_rng.clone();
        Self::_stream(recruit, &cache, "discover", player)
    }
    pub fn effect_rng(recruit: &RecruitRef, player: &PlayerStateRef) -> RngRef {
        let cache = recruit.borrow()._effect_rng.clone();
        Self::_stream(recruit, &cache, "recruit_effect", player)
    }
    pub fn _rules(recruit: &RecruitRef) -> RulesRef {
        recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session")
            .borrow()
            .rules
            .as_ref()
            .expect("session rules")
            .clone()
    }

    // 3.2.1 in order: gold, upgrade discount, refresh counter, shop refill, start-of-turn triggers.
    pub fn start_turn(recruit: &RecruitRef, player: &PlayerStateRef) {
        let game = Self::_session(recruit);
        player.borrow_mut().turn_ended = false;
        for unit in player.borrow().all_cards().iter_live() {
            unit.borrow_mut().worked_this_turn = false;
        }
        let used = Array::new();
        let income =
            Self::_rules(recruit)
                .borrow()
                .income(player, game.borrow().round_number, Some(&used));
        {
            let mut p = player.borrow_mut();
            p.gold += income + p.gold_next_turn;
            for source in used.iter_live() {
                p.mark_worked(Some(&source));
            }
            p.gold_next_turn = 0;
            if game.borrow().round_number >= 2 {
                p.turns_waited += 1;
            }
            p.refreshes_paid = 0;
            p.freezes_used = 0;
        }
        for unit in player.borrow().all_cards().to_vec() {
            unit.borrow().turn_counters.clear();
        }
        Self::_fill_shop(recruit, player);
        player.borrow_mut().frozen = false;
        Self::_log(recruit, player, &crate::state_dict!{"type"=>"turn_start", "gold"=>&player.borrow().gold,"shop"=>&Self::_shop_view(recruit,player)}.as_dict());
        let mut ctx = RecruitContext::new(&game, recruit, player);
        Self::notify(&mut ctx, Hook::OnStartOfTurn, &HookArgs::None);
        Self::_settle(recruit, player);
    }

    // 3.4.1 in order: End of Turn triggers, "this turn" ends, unfrozen shop returns to the pool.
    // Gold is kept (4.1.2). Every Discover still open or waiting, including one an End of Turn
    // trigger opens, is resolved with its first option.
    pub fn end_turn(recruit: &RecruitRef, player: &PlayerStateRef) {
        if player.borrow().turn_ended {
            return;
        }
        Self::_resolve_discovers(recruit, player);
        let mut ctx = RecruitContext::new(&Self::_session(recruit), recruit, player);
        Self::notify(&mut ctx, Hook::OnEndOfTurn, &HookArgs::None);
        Self::_resolve_discovers(recruit, player);
        Self::_settle(recruit, player);
        for unit in player.borrow().all_cards().to_vec() {
            unit.borrow()
                .stats
                .as_ref()
                .expect("unit stats")
                .borrow_mut()
                .end_turn();
        }
        if !player.borrow().frozen {
            Self::_return_shop(recruit, player);
        }
        player.borrow_mut().turn_ended = true;
        Self::_log(recruit, player, &crate::state_dict!{"type"=>"turn_end","gold"=>&player.borrow().gold,"frozen"=>&player.borrow().frozen}.as_dict());
    }

    // --- Actions -------------------------------------------------------------------------------------
    pub fn act(recruit: &RecruitRef, player: &PlayerStateRef, action: &Dictionary) -> String {
        if !player.borrow().alive || player.borrow().turn_ended {
            return "not in a Recruit Phase".into();
        }
        let kind = CoreUtil::to_text(&action.get_or("type", "".into()));
        if !player.borrow().recruit_choices.is_empty() && kind != "recruit_target" {
            return "choose a recruit target first".into();
        }
        if !player.borrow().discover_options.is_empty()
            && !matches!(kind.as_str(), "pick" | "recruit_target")
        {
            return "choose a Discover option first".into();
        }
        match kind.as_str() {
            "buy" => Self::_buy(
                recruit,
                player,
                CoreUtil::to_bool(&action.get_or("spell", false.into())),
                action.get_or("index", (-1).into()).as_i64(),
                action.get_or("target", (-2).into()).as_i64(),
            ),
            "sell" => Self::_sell(
                recruit,
                player,
                action.get_or("slot", (-1).into()).as_i64(),
                action.get_or("hand", (-1).into()).as_i64(),
            ),
            "to_hand" => {
                Self::_to_hand(recruit, player, action.get_or("slot", (-1).into()).as_i64())
            }
            "play" => Self::_play(
                recruit,
                player,
                action.get_or("hand", (-1).into()).as_i64(),
                action.get_or("slot", (-1).into()).as_i64(),
                action.get_or("target", (-1).into()).as_i64(),
            ),
            "recruit_target" => Self::_choose_recruit_target(
                recruit,
                player,
                action.get_or("target", (-1).into()).as_i64(),
            ),
            "move" => Self::_move(
                recruit,
                player,
                action.get_or("from", (-1).into()).as_i64(),
                action.get_or("to", (-1).into()).as_i64(),
            ),
            "ability" => Self::_use_ability(
                recruit,
                player,
                action.get_or("uid", (-1).into()).as_i64(),
                &CoreUtil::to_text(&action.get_or("mechanic", "".into())),
                action.get_or("target", (-1).into()).as_i64(),
            ),
            _ => Self::_act_simple(recruit, player, &kind, action),
        }
    }
    pub fn _act_simple(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        kind: &str,
        action: &Dictionary,
    ) -> String {
        match kind {
            "refresh" => Self::_refresh(recruit, player),
            "freeze" => Self::_freeze(recruit, player),
            "upgrade" => Self::_upgrade(recruit, player),
            "pick" => Self::_pick(
                recruit,
                player,
                action.get_or("index", (-1).into()).as_i64(),
                action.get_or("target", (-2).into()).as_i64(),
            ),
            "end_turn" => {
                Self::end_turn(recruit, player);
                String::new()
            }
            _ => format!("unknown action '{kind}'"),
        }
    }

    // 4.2: buy a unit or spell from the shop into the hand.
    pub fn _buy(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        spell: bool,
        index: i64,
        target: i64,
    ) -> String {
        let shop = if spell {
            player.borrow().shop_spells.clone()
        } else {
            player.borrow().shop_units.clone()
        };
        if index < 0
            || index as usize >= shop.len()
            || shop.get(index as usize).expect("shop slot").is_empty()
        {
            return "no card in that shop slot".into();
        }
        if player.borrow().hand.len() as i64 >= Self::_rules(recruit).borrow().hand_limit(player) {
            return "hand is full".into();
        }
        let game = Self::_session(recruit);
        let card = game
            .borrow()
            .library
            .as_ref()
            .expect("session library")
            .borrow()
            .get_card(&shop.get(index as usize).expect("shop slot"))
            .expect("shop card");
        let rules = Self::_rules(recruit);
        let used = Array::new();
        let price = if spell {
            rules.borrow().spell_price(player, &card, Some(&used))
        } else {
            rules.borrow().unit_price(player, &card, Some(&used))
        };
        if player.borrow().gold < price {
            return "not enough gold".into();
        }
        let error = Self::_gain_target_error(recruit, player, &card, target);
        if !error.is_empty() {
            return error;
        }
        player.borrow_mut().gold -= price;
        for source in used.iter_live() {
            player.borrow().mark_worked(Some(&source));
        }
        shop.borrow_mut()[index as usize] = String::new();
        let unit = game.borrow_mut().new_unit(&card, false);
        unit.borrow_mut().bought_copies = 1;
        unit.borrow_mut().pool_copies = 1;
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"buy","uid"=>&unit.borrow().uid,"id"=>&card.borrow().id,"price"=>&price}.as_dict());
        Self::_gain(recruit, player, &unit, target);
        Self::_settle(recruit, player);
        String::new()
    }

    // 4.3.7 units sell from hand or board through the same listener path.
    // Pool copies return (5.3.4-5.3.5).
    pub fn _sell(recruit: &RecruitRef, player: &PlayerStateRef, slot: i64, hand: i64) -> String {
        let game = Self::_session(recruit);
        let geometry = game
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .clone();
        let unit = if hand >= 0 {
            if slot >= 0 || hand as usize >= player.borrow().hand.len() {
                return "no unit at that hand position".into();
            }
            let unit = player.borrow().hand.get(hand as usize).expect("hand unit");
            if unit.borrow().is_spell() {
                return "spells can't be sold".into();
            }
            unit
        } else {
            if !geometry.borrow().is_valid(slot) {
                return "no unit in that slot".into();
            }
            let Some(unit) = player.borrow().board.get(slot as usize).flatten() else {
                return "no unit in that slot".into();
            };
            unit
        };
        let value = Self::_rules(recruit).borrow().sell_value(player, &unit);
        player.borrow_mut().gold += value;
        if hand >= 0 {
            player.borrow().hand.borrow_mut().remove(hand as usize);
        } else {
            player.borrow_mut().remove_from_board(&unit);
        }
        unit.borrow_mut().slot = slot;
        let def = unit.borrow().def.as_ref().expect("unit definition").clone();
        game.borrow()
            .units
            .as_ref()
            .expect("unit pool")
            .borrow_mut()
            .give_back(&def.borrow().id, unit.borrow().pool_copies);
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"sell","uid"=>&unit.borrow().uid,"id"=>&def.borrow().id,"slot"=>&slot,"gold"=>&value,"bought"=>&(unit.borrow().bought_copies>0)}.as_dict());
        let mut ctx = RecruitContext::new(&game, recruit, player);
        let hooks = unit.borrow().hooks();
        let mut i = 0;
        while let Some(bound) = hooks.get(i) {
            i += 1;
            ctx.invoke(Some(&unit), &bound, Hook::OnSold, &HookArgs::None);
        }
        Self::notify(&mut ctx, Hook::OnAnySold, &HookArgs::AnySold { sold: unit });
        Self::_settle(recruit, player);
        String::new()
    }

    // 7.2 play a unit into a chosen empty slot, or 6.1.5 cast a spell.
    pub fn _play(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        hand_index: i64,
        slot: i64,
        target_uid: i64,
    ) -> String {
        if hand_index < 0 || hand_index as usize >= player.borrow().hand.len() {
            return "no card at that hand position".into();
        }
        let card = player
            .borrow()
            .hand
            .get(hand_index as usize)
            .expect("hand card");
        let error = Self::_play_error(recruit, player, &card, slot, target_uid);
        if !error.is_empty() {
            return error;
        }
        let kind = Self::play_target_of(recruit, &card);
        let target = if kind == Target::FriendlyUnit {
            player.borrow().find_uid(target_uid)
        } else {
            None
        };
        player
            .borrow()
            .hand
            .borrow_mut()
            .remove(hand_index as usize);
        let game = Self::_session(recruit);
        let mut ctx = RecruitContext::new(&game, recruit, player);
        ctx.target_index = if kind != Target::None { target_uid } else { -1 };
        if card.borrow().is_spell() {
            Self::_cast(recruit, &mut ctx, &card, target.as_ref());
            return String::new();
        }
        player.borrow_mut().place(&card, slot);
        let def = card.borrow().def.as_ref().expect("unit definition").clone();
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"play","uid"=>&card.borrow().uid,"id"=>&def.borrow().id,"slot"=>&slot}.as_dict());
        Self::refresh_auras(recruit, player);
        Self::_settle(recruit, player);
        String::new()
    }
    pub fn _cast(
        recruit: &RecruitRef,
        ctx: &mut RecruitContext,
        spell: &UnitRef,
        target: Option<&UnitRef>,
    ) {
        let player = ctx.player.as_ref().expect("context player").clone();
        let def = spell
            .borrow()
            .def
            .as_ref()
            .expect("spell definition")
            .clone();
        Self::_log(recruit,&player,&crate::state_dict!{"type"=>"cast","uid"=>&spell.borrow().uid,"id"=>&def.borrow().id,"target_uid"=>&target.map_or(-1,|u|u.borrow().uid),"target"=>&ctx.target_index}.as_dict());
        let mechanics = spell.borrow().mechanics.clone();
        let mut i = 0;
        while let Some(bound) = mechanics.get(i) {
            i += 1;
            let (mechanic, params) = Self::_hook(&bound);
            mechanic.on_played(ctx, Some(spell), target, &params);
        }
        // The spell's pool copy returns once cast (5.3.7 read for spells; see README).
        Self::_session(recruit)
            .borrow()
            .spells
            .as_ref()
            .expect("spell pool")
            .borrow_mut()
            .give_back(&def.borrow().id, spell.borrow().pool_copies);
        Self::_settle(recruit, &player);
    }

    // 7.2.1-7.2.2 a unit needs an empty slot; a card that aims needs a target of its kind when one
    // exists (a friendly unit, a slot, a shop unit), and a spell that aims can't be cast without.
    pub fn _play_error(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        card: &UnitRef,
        slot: i64,
        target: i64,
    ) -> String {
        let game = Self::_session(recruit);
        let geometry = game
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .clone();
        if !card.borrow().is_spell()
            && (!geometry.borrow().is_valid(slot)
                || player.borrow().board.get(slot as usize).flatten().is_some())
        {
            return "choose an empty slot".into();
        }
        let kind = Self::play_target_of(recruit, card);
        if kind == Target::None {
            return if target < 0 {
                String::new()
            } else {
                "this card has no target".into()
            };
        }
        let choices = Self::targets_for(recruit, player, kind, Some(card));
        if target < 0 {
            return if card.borrow().is_spell() || !choices.is_empty() {
                "choose a target".into()
            } else {
                String::new()
            };
        }
        if choices.has(&target) {
            String::new()
        } else {
            "not a valid target".into()
        }
    }

    // What playing this card aims at: the first of its mechanics that aims decides.
    pub fn play_target_of(recruit: &RecruitRef, card: &UnitRef) -> Target {
        if !card.borrow().is_spell() {
            return Target::None;
        }
        let mechanics = card.borrow().mechanics.clone();
        let mut i = 0;
        while let Some(bound) = mechanics.get(i) {
            i += 1;
            let (mechanic, params) = Self::_hook(&bound);
            let kind = mechanic.play_target(&params);
            if kind != Target::None {
                return kind;
            }
        }
        Target::None
    }

    // Spell and ability targets: other friendly board uids, board slots, or filled unit shop
    // indexes. Recruit effects use recruit_targets, which also includes hand.
    pub fn targets_for(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        kind: Target,
        card: Option<&UnitRef>,
    ) -> Array<i64> {
        let out = Array::new();
        match kind {
            Target::FriendlyUnit => {
                for unit in player.borrow().board_units().to_vec() {
                    if !card.is_some_and(|c| Rc::ptr_eq(c, &unit)) {
                        out.push(unit.borrow().uid);
                    }
                }
            }
            Target::Slot => {
                let n = Self::_session(recruit)
                    .borrow()
                    .geometry
                    .as_ref()
                    .expect("session geometry")
                    .borrow()
                    .slot_count;
                for slot in 0..n {
                    out.push(slot);
                }
            }
            Target::ShopUnit => {
                let shop = player.borrow().shop_units.clone();
                for i in 0..shop.len() {
                    if !shop.get(i).expect("shop slot").is_empty() {
                        out.push(i as i64);
                    }
                }
            }
            Target::None => {}
        }
        out
    }

    // 3.3.1 use a board unit's ability: up to its uses this turn, paying its cost.
    pub fn _use_ability(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        uid: i64,
        mechanic_id: &str,
        target: i64,
    ) -> String {
        let unit = player.borrow().find_uid(uid);
        let Some(bound) = Self::_ability_of(recruit, unit.as_ref(), mechanic_id) else {
            return "no such ability on your board".into();
        };
        let unit = unit.expect("ability owner");
        let error = Self::ability_error(recruit, player, &unit, &bound);
        if !error.is_empty() {
            return error;
        }
        let (mechanic, params) = Self::_hook(&bound);
        let kind = mechanic.ability_target(&params);
        if kind != Target::None
            && !Self::targets_for(recruit, player, kind, Some(&unit)).has(&target)
        {
            return "not a valid target".into();
        }
        let cost = mechanic.ability_cost(&params);
        let key = Self::_ability_key(mechanic_id);
        player.borrow_mut().gold -= cost;
        let used = unit.borrow().turn_counter(&key);
        unit.borrow().turn_counters.insert(key, (used + 1).into());
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"ability","uid"=>&unit.borrow().uid,"mechanic"=>mechanic_id,"target"=>&target,"cost"=>&cost}.as_dict());
        let mut ctx = RecruitContext::new(&Self::_session(recruit), recruit, player);
        ctx.target_index = if kind != Target::None { target } else { -1 };
        let target_unit = if kind == Target::FriendlyUnit {
            player.borrow().find_uid(target)
        } else {
            None
        };
        player.borrow().mark_worked(Some(&unit));
        ctx.invoke(
            Some(&unit),
            &bound,
            Hook::OnAbility,
            &HookArgs::Ability {
                target: target_unit,
            },
        );
        Self::_settle(recruit, player);
        String::new()
    }

    // Why a board unit's ability can't be used now ("" when it can), before a target is chosen.
    pub fn ability_error(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        unit: &UnitRef,
        bound: &BoundMechanicRef,
    ) -> String {
        let (mechanic, params) = Self::_hook(bound);
        if unit
            .borrow()
            .turn_counter(&Self::_ability_key(&bound.borrow().id))
            >= mechanic.ability_uses(&params)
        {
            return "already used this turn".into();
        }
        if !mechanic.ability_usable(Some(player), Some(unit), &params) {
            return "can't be used from here".into();
        }
        if player.borrow().gold < mechanic.ability_cost(&params) {
            return "not enough gold".into();
        }
        let kind = mechanic.ability_target(&params);
        if kind != Target::None && Self::targets_for(recruit, player, kind, Some(unit)).is_empty() {
            return "nothing to target".into();
        }
        String::new()
    }
    pub fn _ability_of(
        recruit: &RecruitRef,
        unit: Option<&UnitRef>,
        mechanic_id: &str,
    ) -> Option<BoundMechanicRef> {
        let unit = unit?;
        if unit.borrow().slot < 0 {
            return None;
        }
        let hooks = unit.borrow().hooks();
        let mut i = 0;
        while let Some(bound) = hooks.get(i) {
            i += 1;
            if bound.borrow().id == mechanic_id && Self::_hook(&bound).0.has_ability() {
                return Some(bound);
            }
        }
        None
    }
    pub fn _ability_key(mechanic_id: &str) -> String {
        format!("ability:{mechanic_id}")
    }

    // 8.3.3 move to an empty slot or swap, free.
    pub fn _move(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        from_slot: i64,
        to_slot: i64,
    ) -> String {
        let geometry = Self::_session(recruit)
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .clone();
        if !geometry.borrow().is_valid(from_slot)
            || player
                .borrow()
                .board
                .get(from_slot as usize)
                .flatten()
                .is_none()
        {
            return "no unit to move".into();
        }
        if !geometry.borrow().is_valid(to_slot) || to_slot == from_slot {
            return "choose another slot".into();
        }
        let moving = player
            .borrow()
            .board
            .get(from_slot as usize)
            .flatten()
            .expect("moving unit");
        let other = player.borrow().board.get(to_slot as usize).flatten();
        player.borrow().board.borrow_mut()[from_slot as usize] = None;
        player.borrow_mut().place(&moving, to_slot);
        if let Some(other) = other {
            player.borrow_mut().place(&other, from_slot);
        }
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"move","uid"=>&moving.borrow().uid,"from"=>&from_slot,"to"=>&to_slot}.as_dict());
        Self::refresh_auras(recruit, player);
        String::new()
    }

    // 7.2.4/7.2.5 a free zone move, never an acquisition or a replay trigger.
    pub fn _to_hand(recruit: &RecruitRef, player: &PlayerStateRef, slot: i64) -> String {
        let error = Self::to_hand_error(recruit, player, slot);
        if !error.is_empty() {
            return error;
        }
        let unit = player
            .borrow()
            .board
            .get(slot as usize)
            .flatten()
            .expect("board unit");
        player.borrow_mut().remove_from_board(&unit);
        player.borrow().hand.push(unit.clone());
        let def = unit.borrow().def.clone().expect("unit definition");
        Self::_log(recruit, player, &crate::state_dict!{"type"=>"to_hand","uid"=>&unit.borrow().uid,"id"=>&def.borrow().id,"slot"=>&slot}.as_dict());
        Self::refresh_auras(recruit, player);
        String::new()
    }

    pub fn to_hand_error(recruit: &RecruitRef, player: &PlayerStateRef, slot: i64) -> String {
        let geometry = Self::_session(recruit)
            .borrow()
            .geometry
            .clone()
            .expect("geometry");
        if !geometry.borrow().is_valid(slot) {
            return "no unit in that slot".into();
        }
        let Some(unit) = player.borrow().board.get(slot as usize).flatten() else {
            return "no unit in that slot".into();
        };
        if unit.borrow().worked_this_turn {
            return "Worked this turn: stays for the fight.".into();
        }
        if player.borrow().hand.len() as i64 >= Self::_rules(recruit).borrow().hand_limit(player) {
            return "hand is full".into();
        }
        String::new()
    }

    // 4.4.1-4.4.3 paid refresh: new cards in every shop slot; unfreezes.
    pub fn _refresh(recruit: &RecruitRef, player: &PlayerStateRef) -> String {
        let used = Array::new();
        let cost = Self::_rules(recruit)
            .borrow()
            .refresh_cost(player, Some(&used));
        if player.borrow().gold < cost {
            return "not enough gold".into();
        }
        player.borrow_mut().gold -= cost;
        for source in used.iter_live() {
            player.borrow().mark_worked(Some(&source));
        }
        // 4.4.5: a refresh made free by an effect doesn't advance the paid counter.
        if cost > 0 {
            player.borrow_mut().refreshes_paid += 1;
        }
        player.borrow_mut().frozen = false;
        Self::_return_shop(recruit, player);
        Self::_fill_shop(recruit, player);
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"refresh","cost"=>&cost,"shop"=>&Self::_shop_view(recruit,player)}.as_dict());
        String::new()
    }

    // 4.5.1 toggle the freeze, up to the limit per turn.
    pub fn _freeze(recruit: &RecruitRef, player: &PlayerStateRef) -> String {
        if player.borrow().freezes_used >= Self::_rules(recruit).borrow().freeze_limit(player) {
            return "no freezes left this turn".into();
        }
        {
            let mut p = player.borrow_mut();
            p.freezes_used += 1;
            p.frozen = !p.frozen;
        }
        Self::_log(
            recruit,
            player,
            &crate::state_dict! {"type"=>"freeze","frozen"=>&player.borrow().frozen}.as_dict(),
        );
        String::new()
    }

    // 4.6 upgrade the shop tier; 4.6.4 the discount restarts; 4.6.5 the shop doesn't refill.
    pub fn _upgrade(recruit: &RecruitRef, player: &PlayerStateRef) -> String {
        let used = Array::new();
        let cost = Self::_rules(recruit)
            .borrow()
            .upgrade_cost(player, Some(&used));
        if cost < 0 {
            return "already at the top tier".into();
        }
        if player.borrow().gold < cost {
            return "not enough gold".into();
        }
        {
            let mut p = player.borrow_mut();
            p.gold -= cost;
            for source in used.iter_live() {
                p.mark_worked(Some(&source));
            }
            p.tier += 1;
            p.turns_waited = 0;
        }
        Self::_log(
            recruit,
            player,
            &crate::state_dict! {"type"=>"upgrade","tier"=>&player.borrow().tier,"cost"=>&cost}
                .as_dict(),
        );
        String::new()
    }

    // 6.2 take one Discover option; the others return (5.3.3). The pick is Created (4.3.2).
    pub fn _pick(recruit: &RecruitRef, player: &PlayerStateRef, index: i64, target: i64) -> String {
        if index < 0 || index as usize >= player.borrow().discover_options.len() {
            return "no such Discover option".into();
        }
        let game = Self::_session(recruit);
        let id = player
            .borrow()
            .discover_options
            .get(index as usize)
            .expect("option");
        let def = game
            .borrow()
            .library
            .as_ref()
            .expect("session library")
            .borrow()
            .get_card(&id)
            .expect("discover card");
        let error = Self::_gain_target_error(recruit, player, &def, target);
        if !error.is_empty() {
            return error;
        }
        let options = player.borrow().discover_options.duplicate();
        player.borrow().discover_options.clear();
        let pool = game.borrow().units.as_ref().expect("unit pool").clone();
        for i in 0..options.len() {
            if i != index as usize {
                pool.borrow_mut()
                    .give_back(&options.get(i).expect("option"), 1);
            }
        }
        let unit = game.borrow_mut().new_unit(&def, false);
        unit.borrow_mut().pool_copies = 1;
        Self::_log(
            recruit,
            player,
            &crate::state_dict! {"type"=>"pick","uid"=>&unit.borrow().uid,"id"=>&def.borrow().id}
                .as_dict(),
        );
        Self::_gain(recruit, player, &unit, target);
        Self::_settle(recruit, player);
        // A waiting Discover whose draw finds nothing (an empty pool) is skipped for the next one.
        while player.borrow().discover_options.is_empty()
            && !player.borrow().discover_queue.is_empty()
        {
            let next = player.borrow().discover_queue.borrow_mut().remove(0);
            Self::offer_discover(recruit, player, next.0, next.1);
        }
        String::new()
    }
    pub fn _resolve_discovers(recruit: &RecruitRef, player: &PlayerStateRef) {
        while !player.borrow().discover_options.is_empty()
            || !player.borrow().recruit_choices.is_empty()
        {
            let choice = player.borrow().recruit_choices.get(0);
            if let Some(choice) = choice {
                let uid = choice.borrow().uid;
                Self::_choose_recruit_target(recruit, player, uid);
            } else {
                Self::_pick(recruit, player, 0, -1);
            }
        }
    }

    // 6.2.1-6.2.3: up to N different units, each drawn by 6.1.3 and out of the pool while shown.
    // With one already shown, this one waits its turn and is drawn when that one is picked.
    pub fn offer_discover(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        min_tier: i64,
        max_tier: i64,
    ) {
        if !player.borrow().discover_options.is_empty() {
            player.borrow().discover_queue.push((min_tier, max_tier));
            Self::_log(recruit,player,&crate::state_dict!{"type"=>"discover_queued","waiting"=>&player.borrow().discover_queue.len()}.as_dict());
            return;
        }
        let options = Array::new();
        let pool = Self::_session(recruit)
            .borrow()
            .units
            .as_ref()
            .expect("unit pool")
            .clone();
        let count = Self::_rules(recruit).borrow().discover_options(player);
        for _i in 0..count {
            let id = pool.borrow_mut().draw(
                min_tier,
                max_tier,
                &Self::discover_rng(recruit, player),
                &options,
            );
            if id.is_empty() {
                break;
            }
            options.push(id);
        }
        player.borrow_mut().discover_options = options.clone();
        Self::_log(
            recruit,
            player,
            &crate::state_dict! {"type"=>"discover","options"=>&options}.as_dict(),
        );
    }

    // 8.4.3, 8.4.7: a Recruit Phase summon, Created. Null and logged when the board is full.
    pub fn summon(
        recruit: &RecruitRef,
        ctx: &mut RecruitContext,
        card_id: &str,
        source_slot: i64,
        own_slot_first: bool,
        golden: bool,
    ) -> Option<UnitRef> {
        let player = ctx.player.as_ref().expect("context player").clone();
        let game = Self::_session(recruit);
        let geometry = game
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .clone();
        let slot =
            geometry
                .borrow()
                .summon_slot(&player.borrow().occupied(), source_slot, own_slot_first);
        let library = game
            .borrow()
            .library
            .as_ref()
            .expect("session library")
            .clone();
        if slot < 0 || !library.borrow().has(card_id) {
            Self::_log(
                recruit,
                &player,
                &crate::state_dict! {"type"=>"summon_failed","id"=>card_id}.as_dict(),
            );
            return None;
        }
        let def = library.borrow().get_card(card_id).expect("summon card");
        let unit = game.borrow_mut().new_unit(&def, golden);
        player.borrow_mut().place(&unit, slot);
        Self::refresh_auras(recruit, &player);
        let event = unit.borrow().view();
        event.insert("type", "summon".into());
        Self::_log(recruit, &player, &event);
        Some(unit)
    }

    // Runs a listener hook for every board unit in reading order, then the player's standing
    // mechanics with unit = null. Arguments go between the unit and the params.
    pub fn notify(ctx: &mut RecruitContext, hook: Hook, args: &HookArgs) {
        let player = ctx.player.as_ref().expect("context player").clone();
        let board = player.borrow().board_units();
        let mut i = 0;
        while let Some(unit) = board.get(i) {
            i += 1;
            let hooks = unit.borrow().hooks();
            let mut j = 0;
            while let Some(bound) = hooks.get(j) {
                j += 1;
                ctx.invoke(Some(&unit), &bound, hook, args);
            }
        }
        let standing = player.borrow().standing.clone();
        let mut i = 0;
        while let Some(bound) = standing.get(i) {
            i += 1;
            ctx.invoke(None, &bound, hook, args);
        }
    }

    // After this player's fight (GameSession): after_fight for the real board, then standing.
    pub fn after_fight(recruit: &RecruitRef, player: &PlayerStateRef, report: &FightReportRef) {
        let mut ctx = RecruitContext::new(&Self::_session(recruit), recruit, player);
        ctx.track_work = false;
        Self::notify(
            &mut ctx,
            Hook::AfterFight,
            &HookArgs::AfterFight {
                report: report.clone(),
            },
        );
        Self::_settle(recruit, player);
    }

    // A death effect resolving in the Recruit Phase, from where the unit stands (Mechanic
    // .on_recruit_death), as many times as Q_DEATH_EFFECT_TIMES says (asked through modify_int).
    pub fn run_death_effects(recruit: &RecruitRef, ctx: &mut RecruitContext, unit: &UnitRef) {
        let times = ctx.ask(Q_DEATH_EFFECT_TIMES, 1).max(1);
        for _time in 0..times {
            let hooks = unit.borrow().hooks();
            let mut i = 0;
            while let Some(bound) = hooks.get(i) {
                i += 1;
                ctx.invoke(Some(unit), &bound, Hook::OnRecruitDeath, &HookArgs::None);
            }
        }
    }

    // 7.1.2: a card gained while the hand is full is lost (its pool copies go back).
    pub fn _gain(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        unit: &UnitRef,
        target: i64,
    ) -> bool {
        let def = unit.borrow().def.as_ref().expect("unit definition").clone();
        if player.borrow().hand.len() as i64 >= Self::_rules(recruit).borrow().hand_limit(player) {
            let game = Self::_session(recruit);
            let pool = if unit.borrow().is_spell() {
                game.borrow().spells.as_ref().expect("spell pool").clone()
            } else {
                game.borrow().units.as_ref().expect("unit pool").clone()
            };
            pool.borrow_mut()
                .give_back(&def.borrow().id, unit.borrow().pool_copies);
            Self::_log(
                recruit,
                player,
                &crate::state_dict! {"type"=>"card_lost","id"=>&def.borrow().id}.as_dict(),
            );
            return false;
        }
        player.borrow().hand.push(unit.clone());
        Self::_log(
            recruit,
            player,
            &crate::state_dict! {"type"=>"gain","uid"=>&unit.borrow().uid,"id"=>&def.borrow().id}
                .as_dict(),
        );
        // The completing copy merges without recruiting. Only the golden fires.
        if !Self::_completes_triple(player, unit) {
            Self::_recruit_unit(recruit, player, unit, target);
        }
        true
    }

    // Several gains may wait for the enclosing action to settle. Only each third normal
    // copy completes a triple. A fourth or fifth copy still recruits.
    fn _completes_triple(player: &PlayerStateRef, gained: &UnitRef) -> bool {
        let def = gained.borrow().def.clone().expect("unit definition");
        if gained.borrow().is_spell() || gained.borrow().golden || !def.borrow().combines {
            return false;
        }
        let copies = player
            .borrow()
            .all_cards()
            .iter_live()
            .filter(|unit| {
                let unit = unit.borrow();
                !unit.golden
                    && unit.def.as_ref().expect("unit definition").borrow().id == def.borrow().id
            })
            .count();
        copies >= 3 && copies.is_multiple_of(3)
    }

    // 7.2.3/7.2.6 unit effects use their own hook; spells still use on_played when cast.
    pub fn recruit_target_of(card: &UnitDefRef, registry: &MechanicRegistryRef) -> Target {
        if card.borrow().is_spell() {
            return Target::None;
        }
        let specs = card.borrow().mechanics.clone();
        for spec in specs.iter_live() {
            let bound = registry.borrow().bind(&spec, false, false);
            let (mechanic, params) = Self::_hook(&bound);
            let kind = mechanic.recruit_target(&params);
            if kind != Target::None {
                return kind;
            }
        }
        Target::None
    }

    // Any friendly unit in hand or on board, including the recruited unit. Spells never qualify.
    pub fn recruit_targets(player: &PlayerStateRef) -> Array<i64> {
        player
            .borrow()
            .all_cards()
            .iter_live()
            .filter_map(|unit| {
                let unit = unit.borrow();
                (!unit.is_spell()).then_some(unit.uid)
            })
            .collect()
    }

    fn _gain_target_error(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        card: &UnitDefRef,
        target: i64,
    ) -> String {
        if target < -1 {
            return String::new();
        }
        let registry = Self::_session(recruit)
            .borrow()
            .registry
            .clone()
            .expect("registry");
        if Self::recruit_target_of(card, &registry) == Target::None {
            return if target == -1 {
                String::new()
            } else {
                "this card has no recruit target".into()
            };
        }
        if target == -1 || Self::recruit_targets(player).has(&target) {
            String::new()
        } else {
            "not a valid recruit target".into()
        }
    }

    fn _recruit_unit(recruit: &RecruitRef, player: &PlayerStateRef, unit: &UnitRef, target: i64) {
        if unit.borrow().is_spell() {
            return;
        }
        let game = Self::_session(recruit);
        let registry = game.borrow().registry.clone().expect("registry");
        let def = unit.borrow().def.clone().expect("unit definition");
        if Self::recruit_target_of(&def, &registry) != Target::None && target < -1 {
            player.borrow().recruit_choices.push(unit.clone());
            return;
        }
        let chosen = if target >= 0 {
            player.borrow().find_uid(target)
        } else {
            Some(unit.clone())
        };
        let mut ctx = RecruitContext::new(&game, recruit, player);
        ctx.recruit_source = Some(unit.clone());
        let mechanics = unit.borrow().mechanics.clone();
        let args = HookArgs::Recruited { target: chosen };
        for bound in mechanics.iter_live() {
            ctx.invoke(Some(unit), &bound, Hook::OnRecruited, &args);
        }
    }

    fn _choose_recruit_target(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        target: i64,
    ) -> String {
        let choices = player.borrow().recruit_choices.clone();
        if choices.is_empty() {
            return "no recruit target to choose".into();
        }
        if !Self::recruit_targets(player).has(&target) {
            return "not a valid recruit target".into();
        }
        let unit = choices.borrow_mut().remove(0);
        Self::_recruit_unit(recruit, player, &unit, target);
        Self::_settle(recruit, player);
        String::new()
    }

    // Fills empty shop slots (4.5.2 a frozen shop keeps its cards), sized by 6.1.1's query.
    pub fn _fill_shop(recruit: &RecruitRef, player: &PlayerStateRef) {
        let game = Self::_session(recruit);
        let rules = Self::_rules(recruit);
        let units = game.borrow().units.as_ref().expect("unit pool").clone();
        let spells = game.borrow().spells.as_ref().expect("spell pool").clone();
        let shop = player.borrow().shop_units.clone();
        let size = rules.borrow().shop_units(player);
        Self::_fill(recruit, &shop, size, &units, player);
        let shop = player.borrow().shop_spells.clone();
        let size = rules.borrow().shop_spells(player);
        Self::_fill(recruit, &shop, size, &spells, player);
    }
    pub fn _fill(
        recruit: &RecruitRef,
        shop: &Array<String>,
        size: i64,
        pool: &CardPoolRef,
        player: &PlayerStateRef,
    ) {
        while shop.len() as i64 > size {
            let extra = shop.borrow_mut().pop().expect("shop card");
            pool.borrow_mut().give_back(&extra, 1);
        }
        while (shop.len() as i64) < size {
            shop.push(String::new());
        }
        for i in 0..size as usize {
            if shop.get(i).expect("shop slot").is_empty() {
                let id = pool.borrow_mut().draw(
                    1,
                    player.borrow().tier,
                    &Self::shop_rng(recruit, player),
                    &Array::new(),
                );
                shop.borrow_mut()[i] = id;
            }
        }
    }

    // 5.3.2 shown cards go back to the pool.
    pub fn _return_shop(recruit: &RecruitRef, player: &PlayerStateRef) {
        let game = Self::_session(recruit);
        let units = game.borrow().units.as_ref().expect("unit pool").clone();
        let spells = game.borrow().spells.as_ref().expect("spell pool").clone();
        let shop = player.borrow().shop_units.clone();
        for i in 0..shop.len() {
            units
                .borrow_mut()
                .give_back(&shop.get(i).expect("shop slot"), 1);
            shop.borrow_mut()[i] = String::new();
        }
        let shop = player.borrow().shop_spells.clone();
        for i in 0..shop.len() {
            spells
                .borrow_mut()
                .give_back(&shop.get(i).expect("shop slot"), 1);
            shop.borrow_mut()[i] = String::new();
        }
    }
    pub fn _shop_view(recruit: &RecruitRef, player: &PlayerStateRef) -> Dictionary {
        crate::state_dict!{"units"=>&player.borrow().shop_units,"spells"=>&player.borrow().shop_spells}.as_dict()
    }

    // After every action: triples form (7.3.1-7.3.2, after all summons) and auras are recomputed.
    pub fn _settle(recruit: &RecruitRef, player: &PlayerStateRef) {
        while player.borrow().recruit_choices.is_empty() {
            if !Self::_combine_one(recruit, player) {
                break;
            }
        }
        Self::refresh_auras(recruit, player);
    }

    // 7.3.1 three copies of one non-golden unit across board and hand become one golden.
    pub fn _combine_one(recruit: &RecruitRef, player: &PlayerStateRef) -> bool {
        let copies = Dictionary::<Array<UnitRef>>::new();
        let order = Array::new();
        let cards = player.borrow().hand.duplicate();
        cards
            .borrow_mut()
            .extend(player.borrow().board_units().to_vec());
        for unit in cards.to_vec() {
            let def = unit.borrow().def.as_ref().expect("unit definition").clone();
            if unit.borrow().golden || unit.borrow().is_spell() || !def.borrow().combines {
                continue;
            }
            let id = def.borrow().id.clone();
            if !copies.borrow().contains_key(&id) {
                copies.borrow_mut().insert(id.clone(), Array::new());
                order.push(id.clone());
            }
            copies.borrow()[&id].push(unit);
        }
        for id in order.to_vec() {
            let list = copies.borrow()[&id].clone();
            if list.len() >= 3 {
                let three = Array::from(list.borrow()[..3].to_vec());
                Self::_combine(recruit, player, &three);
                return true;
            }
        }
        false
    }
    pub fn _combine(recruit: &RecruitRef, player: &PlayerStateRef, three: &Array<UnitRef>) {
        let vacated = Array::new();
        let game = Self::_session(recruit);
        let def = three
            .get(0)
            .expect("triple first")
            .borrow()
            .def
            .as_ref()
            .expect("unit definition")
            .clone();
        let golden = game.borrow_mut().new_unit(&def, true);
        // GDScript accumulates each layer in a Vector2i.
        let (mut perm, mut turn) = ((0_i32, 0_i32), (0_i32, 0_i32));
        let registry = game
            .borrow()
            .registry
            .as_ref()
            .expect("session registry")
            .clone();
        for unit in three.to_vec() {
            if unit.borrow().worked_this_turn {
                golden.borrow_mut().worked_this_turn = true;
            }
            golden.borrow_mut().bought_copies += unit.borrow().bought_copies;
            golden.borrow_mut().pool_copies += unit.borrow().pool_copies;
            let stats = unit.borrow().stats.as_ref().expect("unit stats").clone();
            let stats = stats.borrow();
            perm.0 = perm.0.wrapping_add(stats.perm_attack as i32);
            perm.1 = perm.1.wrapping_add(stats.perm_health as i32);
            turn.0 = turn.0.wrapping_add(stats.turn_attack as i32);
            turn.1 = turn.1.wrapping_add(stats.turn_health as i32);
            for (key, value) in unit.borrow().counters.borrow().iter() {
                let n = golden.borrow().counter(key) + value.as_i64();
                golden.borrow().counters.insert(key, n.into());
            }
            let mechanics = unit.borrow().mechanics.clone();
            let mut i = 0;
            while let Some(bound) = mechanics.get(i) {
                i += 1;
                let (granted, empty, id) = {
                    let b = bound.borrow();
                    (b.granted, b.params.borrow().is_empty(), b.id.clone())
                };
                if granted && empty {
                    golden.borrow_mut().grant(&registry, &id);
                } else if granted {
                    golden.borrow().mechanics.push(bound);
                }
            }
            if unit.borrow().slot >= 0 {
                vacated.push(unit.borrow().slot);
                player.borrow_mut().remove_from_board(&unit);
            } else {
                let hand = player.borrow().hand.clone();
                let pos = hand.borrow().iter().position(|u| Rc::ptr_eq(u, &unit));
                if let Some(i) = pos {
                    hand.borrow_mut().remove(i);
                }
            }
        }
        // 7.3.4 floor merged modifiers after buffs and debuffs offset.
        // Floor the lasting sum too, so expiry preserves the permanent buffs.
        {
            let stats = golden
                .borrow()
                .stats
                .as_ref()
                .expect("golden stats")
                .clone();
            let mut s = stats.borrow_mut();
            s.perm_attack = i64::from(perm.0).max(0);
            s.perm_health = i64::from(perm.1).max(0);
            s.turn_attack = (i64::from(perm.0) + i64::from(turn.0)).max(0) - s.perm_attack;
            s.turn_health = (i64::from(perm.1) + i64::from(turn.1)).max(0) - s.perm_health;
        }
        if (player.borrow().hand.len() as i64) < Self::_rules(recruit).borrow().hand_limit(player)
            || vacated.is_empty()
        {
            Self::_gain(recruit, player, &golden, -2);
        } else {
            // 7.3.7: the golden takes the first vacated slot when hand has no room.
            crate::util::godot_sort::sort(&mut vacated.borrow_mut());
            player
                .borrow_mut()
                .place(&golden, vacated.get(0).expect("vacated slot"));
            Self::_recruit_unit(recruit, player, &golden, -2);
        }
        // 7.3.6: grant the spell at formation, with the ordinary full-hand loss path.
        let reward_def = game
            .borrow()
            .library
            .as_ref()
            .expect("session library")
            .borrow()
            .get_card(UnitLibrary::TRIPLE_REWARD_ID)
            .expect("triple reward");
        let reward = game.borrow_mut().new_unit(&reward_def, false);
        let gained = Self::_gain(recruit, player, &reward, -2);
        let reward_uid = if gained { reward.borrow().uid } else { -1 };
        Self::_log(recruit,player,&crate::state_dict!{"type"=>"triple","uid"=>&golden.borrow().uid,"id"=>&def.borrow().id,"slot"=>&golden.borrow().slot,"reward_uid"=>&reward_uid}.as_dict());
    }

    // 12.2.1 auras apply only from board units and standing mechanics, and are recalculated
    // whenever the board changes; slot effects (8.5) are recalculated with them. Public so a
    // mechanic that changes what an aura reads (a player number, a heap) can call it.
    pub fn refresh_auras(recruit: &RecruitRef, player: &PlayerStateRef) {
        for unit in player.borrow().all_cards().borrow().iter() {
            let mut unit = unit.borrow_mut();
            let mut stats = unit.stats.as_ref().expect("unit stats").borrow_mut();
            stats.aura_attack = 0;
            stats.aura_health = 0;
            stats.slot_attack = 0;
            stats.slot_health = 0;
            drop(stats);
            unit.aura_mechanics = Array::new();
        }
        let board = player.borrow().board_units();
        for unit in board.borrow().iter() {
            let slot = unit.borrow().slot;
            let here = player.borrow().slots.borrow()[slot as usize].clone();
            let stats = unit.borrow().stats.as_ref().expect("unit stats").clone();
            stats.borrow_mut().slot_attack = here.borrow().attack;
            stats.borrow_mut().slot_health = here.borrow().health;
        }
        // As in a fight (FightAuras): a second pass on the totals when an aura read a unit's numbers.
        let view = Self::_aura_pass(recruit, player, &board);
        if view.borrow().read_stats {
            Self::_aura_pass(recruit, player, &board);
        }
    }
    pub fn _aura_pass(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        board: &Array<UnitRef>,
    ) -> AuraContextRef {
        let game = recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session");
        let mut view = AuraContext::new();
        view.geometry = game.borrow().geometry.clone();
        view.counters = player.borrow().counters.clone();
        view.heaps = player.borrow().heaps.clone();
        let slot_count = game
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .borrow()
            .slot_count as usize;
        view.defs.borrow_mut().resize(slot_count, None);
        view.unit_counters
            .borrow_mut()
            .resize_with(slot_count, Dictionary::new);
        view.stats.borrow_mut().resize(slot_count, [0, 0, 0]);
        for unit in board.borrow().iter() {
            let unit = unit.borrow();
            let slot = unit.slot as usize;
            view.defs.borrow_mut()[slot] = unit.def.clone();
            view.unit_counters.borrow_mut()[slot] = unit.counters.clone();
            view.stats.borrow_mut()[slot] = [unit.attack(), unit.health(), unit.health()];
        }
        let view = Rc::new(RefCell::new(view));
        for unit in board.borrow().iter() {
            let stats = unit.borrow().stats.as_ref().expect("unit stats").clone();
            stats.borrow_mut().aura_attack = 0;
            stats.borrow_mut().aura_health = 0;
            unit.borrow_mut().aura_mechanics = Array::new();
            let slot = unit.borrow().slot as usize;
            let here = player.borrow().slots.borrow()[slot].clone();
            for keyword in here.borrow().keywords.borrow().iter() {
                Self::_give_aura_keyword(recruit, unit, keyword);
            }
        }
        let grants = Dictionary::<Array<Variant>, i64>::new();
        for source in board.borrow().iter() {
            let source_slot = source.borrow().slot;
            let mechanics = source.borrow().mechanics.clone();
            for bound in mechanics.borrow().iter() {
                let has_aura = bound
                    .borrow()
                    .mechanic
                    .as_ref()
                    .is_some_and(|mechanic| mechanic.has_aura());
                if has_aura {
                    Self::_apply_aura(recruit, &view, bound, source_slot, board, &grants);
                }
            }
        }
        for bound in player.borrow().standing.borrow().iter() {
            let has_aura = bound
                .borrow()
                .mechanic
                .as_ref()
                .is_some_and(|mechanic| mechanic.has_aura());
            if has_aura {
                Self::_apply_aura(recruit, &view, bound, -1, board, &grants);
            }
        }
        // No grants means bind_grants would only allocate empty arrays for every unit.
        if grants.is_empty() {
            return view;
        }
        let registry = game
            .borrow()
            .registry
            .as_ref()
            .expect("session registry")
            .clone();
        for unit in board.borrow().iter() {
            let given = grants
                .borrow()
                .get(&unit.borrow().uid)
                .cloned()
                .unwrap_or_default();
            let bound = registry.borrow().bind_grants(&given);
            unit.borrow()
                .aura_mechanics
                .borrow_mut()
                .extend(bound.borrow().iter().cloned());
        }
        view
    }
    pub fn _apply_aura(
        recruit: &RecruitRef,
        view: &AuraContextRef,
        bound: &BoundMechanicRef,
        source_slot: i64,
        board: &Array<UnitRef>,
        grants: &Dictionary<Array<Variant>, i64>,
    ) {
        let (mechanic, params) = {
            let bound = bound.borrow();
            (
                bound.mechanic.as_ref().expect("bound mechanic").clone(),
                bound.params.clone(),
            )
        };
        // Match combat: skipping inherited empty hooks avoids allocations but never
        // skips a rule callback or changes the order of implemented aura hooks.
        let parts = mechanic.aura_parts();
        for target in board.borrow().iter() {
            let target_slot = target.borrow().slot;
            if parts & AURA_STATS != 0 {
                let gain = mechanic.aura(&mut view.borrow_mut(), source_slot, target_slot, &params);
                let stats = target.borrow().stats.as_ref().expect("unit stats").clone();
                stats.borrow_mut().aura_attack += gain.0;
                stats.borrow_mut().aura_health += gain.1;
            }
            if parts & AURA_KEYWORDS != 0 {
                let keywords = mechanic.aura_keywords(
                    &mut view.borrow_mut(),
                    source_slot,
                    target_slot,
                    &params,
                );
                for keyword in keywords.borrow().iter() {
                    Self::_give_aura_keyword(recruit, target, keyword);
                }
            }
            if parts & AURA_GRANTS != 0 {
                let given =
                    mechanic.aura_grants(&mut view.borrow_mut(), source_slot, target_slot, &params);
                if !given.borrow().is_empty() {
                    let uid = target.borrow().uid;
                    let list = grants.borrow().get(&uid).cloned().unwrap_or_default();
                    list.borrow_mut()
                        .extend(given.borrow().iter().cloned().map(Variant::Dictionary));
                    grants.borrow_mut().insert(uid, list);
                }
            }
        }
    }
    pub fn _give_aura_keyword(recruit: &RecruitRef, unit: &UnitRef, keyword: &str) {
        let game = recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session");
        let registry = game
            .borrow()
            .registry
            .as_ref()
            .expect("session registry")
            .clone();
        if registry.borrow().has(keyword) && !unit.borrow().has_mechanic(keyword) {
            let bound = registry
                .borrow()
                .bind(&MechanicSpec::new(keyword, None), false, true);
            unit.borrow().aura_mechanics.borrow_mut().push(bound);
        }
    }
    pub fn _log(recruit: &RecruitRef, player: &PlayerStateRef, event: &Dictionary) {
        event.insert("player", player.borrow().id.into());
        Self::_session(recruit).borrow_mut().log_event(event);
    }
}
impl ToState for Recruit {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "session"=> &self.session, "_session_ref"=> &self._session_ref, "_shop_rng"=> &self._shop_rng, "_discover_rng"=> &self._discover_rng, "_effect_rng"=> &self._effect_rng }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "session",
            "_session_ref",
            "_shop_rng",
            "_discover_rng",
            "_effect_rng",
        ]
    }
}

// Rule comments retained for the pending bodies:
// {"type": "buy", "spell": bool, "index": int}       4.2
// {"type": "sell", "slot": int}                      4.3
// {"type": "play", "hand": int, "slot": int, "target": int}   7.2, 6.1.5; "target" is a uid,
// {"type": "move", "from": int, "to": int}           8.3.3 (swaps when "to" is taken)
// {"type": "refresh"}  {"type": "freeze"}  {"type": "upgrade"}       4.4, 4.5, 4.6
// {"type": "pick", "index": int}                     6.2 (the only action while choosing)
// {"type": "ability", "uid": int, "mechanic": id, "target": int}   3.3.1 a unit's ability
// {"type": "end_turn"}                               3.4
// The spell's pool copy returns once cast (5.3.7 read for spells; see README).
// 4.4.5: a refresh made free by an effect doesn't advance the paid counter.
// 7.3.4 floor merged modifiers after buffs and debuffs offset.
// Floor the lasting sum too, so expiry preserves the permanent buffs.
// 7.3.7 into the first vacated slot. It is never played, so its Triple Reward is gained
// now, into a full hand: lost by 7.1.2.

#[cfg(test)]
mod action_oracle_tests {
    use super::*;
    use crate::core::records::record_state::RecordState;
    use crate::core::recruit::legal_actions::LegalActions;
    use crate::game::game_content::GameContent;
    use crate::util::godot_json;
    use sha2::{Digest, Sha256};

    // The fixture records every mutation, successful action and refusal from
    // gd/prove_recruit_actions.gd. Both interpreters execute the same operations.
    #[test]
    fn crafted_recruit_actions_match_godot() {
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let vectors =
            godot_json::parse_string(include_str!("../../../../gd/recruit_action_vectors.json"))
                .as_dict();
        let mut checkpoints = 0;
        for raw_case in vectors.get("cases").as_array().to_vec() {
            let case = raw_case.as_dict();
            let name = case.get("name").as_text();
            let content = GameContent::load_folders(&root, &Array::new());
            assert!(content.borrow().errors.is_empty());
            let game = content.borrow().new_session(42, &Array::new());
            let player = game.borrow().player(0);
            let recruit = game.borrow().recruit.as_ref().unwrap().clone();
            let checks = case.get("checks").as_array();
            check(&game, &checks.get(0).unwrap().as_dict(), "", &name, 0);
            checkpoints += 1;
            for (index, raw_step) in case.get("steps").as_array().to_vec().iter().enumerate() {
                let result = step(&game, &recruit, &player, &raw_step.as_dict());
                check(
                    &game,
                    &checks.get(index + 1).unwrap().as_dict(),
                    &result,
                    &name,
                    index + 1,
                );
                checkpoints += 1;
            }
        }
        assert_eq!(checkpoints, 56);
    }

    fn check(game: &GameSessionRef, expected: &Dictionary, result: &str, name: &str, index: usize) {
        assert_eq!(
            result,
            expected.get("result").as_text(),
            "{name} step {index}: refusal"
        );
        assert_eq!(
            RecordState::state_hash(&game.borrow()),
            expected.get("state").as_text(),
            "{name} step {index}: state"
        );
        let player = game.borrow().player(0);
        let legal = godot_json::stringify(&LegalActions::of(game, &player).to_state());
        assert_eq!(
            format!("{:x}", Sha256::digest(legal.as_bytes())),
            expected.get("legal").as_text(),
            "{name} step {index}: ordered legal actions"
        );
    }

    fn step(
        game: &GameSessionRef,
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        step: &Dictionary,
    ) -> String {
        match step.get("op").as_text().as_str() {
            "set" => {
                for (key, value) in step.get("values").as_dict().borrow().iter() {
                    let mut player = player.borrow_mut();
                    match key.as_str() {
                        "gold" => player.gold = value.as_i64(),
                        "refreshes_paid" => player.refreshes_paid = value.as_i64(),
                        "freezes_used" => player.freezes_used = value.as_i64(),
                        "frozen" => player.frozen = CoreUtil::to_bool(value),
                        "tier" => player.tier = value.as_i64(),
                        "turns_waited" => player.turns_waited = value.as_i64(),
                        _ => panic!("unknown fixture player field {key}"),
                    }
                }
            }
            "config" => {
                let config = game.borrow().config.as_ref().unwrap().clone();
                for (key, value) in step.get("values").as_dict().borrow().iter() {
                    match key.as_str() {
                        "refresh_base_cost" => {
                            config.borrow_mut().refresh_base_cost = value.as_i64()
                        }
                        _ => panic!("unknown fixture config field {key}"),
                    }
                }
            }
            "make" => {
                let library = game.borrow().library.as_ref().unwrap().clone();
                let card = library
                    .borrow()
                    .get_card(&step.get("card").as_text())
                    .unwrap();
                let unit = game.borrow_mut().new_unit(&card, false);
                unit.borrow_mut().bought_copies = step.get_or("bought", 0_i64.into()).as_i64();
                unit.borrow_mut().pool_copies = step.get_or("pool", 0_i64.into()).as_i64();
                let slot = step.get_or("slot", (-1_i64).into()).as_i64();
                if slot >= 0 {
                    player.borrow_mut().place(&unit, slot);
                } else {
                    player.borrow().hand.push(unit);
                }
            }
            "buff" => {
                let unit = player.borrow().find_uid(step.get("uid").as_i64()).unwrap();
                let mut ctx = RecruitContext::new(game, recruit, player);
                ctx.buff(
                    &unit,
                    step.get("attack").as_i64(),
                    step.get("health").as_i64(),
                    CoreUtil::to_bool(&step.get("permanent")),
                    None,
                );
            }
            "grant" => {
                let unit = player.borrow().find_uid(step.get("uid").as_i64()).unwrap();
                let registry = game.borrow().registry.as_ref().unwrap().clone();
                assert!(unit.borrow_mut().grant_effect(
                    &registry,
                    &step.get("mechanic").as_text(),
                    &step.get("raw").as_dict()
                ));
            }
            "counter" => {
                let unit = player.borrow().find_uid(step.get("uid").as_i64()).unwrap();
                unit.borrow()
                    .counters
                    .insert(step.get("key").as_text(), step.get("value").as_i64().into());
            }
            "settle" => Recruit::_settle(recruit, player),
            "discover" => Recruit::offer_discover(
                recruit,
                player,
                step.get("min").as_i64(),
                step.get("max").as_i64(),
            ),
            "end" => Recruit::end_turn(recruit, player),
            "act" => return Recruit::act(recruit, player, &step.get("action").as_dict()),
            op => panic!("unknown fixture operation {op}"),
        }
        String::new()
    }
}
