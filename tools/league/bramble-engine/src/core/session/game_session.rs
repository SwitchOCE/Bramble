#![allow(unused_variables)]
//! Mirrors src/core/session/game_session.gd. Round gameplay is filled by recruit/combat workers.
use crate::core::{
    board::board_geometry::{BoardGeometry, BoardGeometryRef},
    combat::combat::Combat,
    mechanics::{mechanic_registry::MechanicRegistryRef, mechanic_spec::MechanicSpec},
    records::{
        game_record::{GameRecord, GameRecordRef},
        record_state::RecordState,
    },
    recruit::legal_actions::LegalActions,
    recruit::{
        player_state::{PlayerState, PlayerStateRef},
        recruit::{Recruit, RecruitRef},
    },
    rules::{
        game_config::{GameConfig, GameConfigRef},
        rules::{Rules, RulesRef},
    },
    session::matchmaking::Matchmaking,
    state::fight_report::FightReport,
    units::{
        card_pool::{CardPool, CardPoolRef},
        unit::{Unit, UnitRef},
        unit_def::UnitDefRef,
        unit_library::UnitLibraryRef,
    },
    util::rng::Rng,
};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type GameSessionRef = Rc<RefCell<GameSession>>;
pub struct GameSession {
    pub config: Option<GameConfigRef>,
    pub rules: Option<RulesRef>,
    pub geometry: Option<BoardGeometryRef>,
    pub registry: Option<MechanicRegistryRef>,
    pub library: Option<UnitLibraryRef>,
    pub units: Option<CardPoolRef>,
    pub spells: Option<CardPoolRef>,
    pub recruit: Option<RecruitRef>,
    pub players: Array<PlayerStateRef>,
    pub seed_value: i64,
    pub round_number: i64,
    pub pairings: Array<Variant>,
    pub events: Array<Dictionary>,
    pub fights: Array<Dictionary>,
    pub keep_fight_events: bool,
    pub over: bool,
    pub ghost_board: Array<Option<UnitRef>>,
    pub ghost_hand: Array<UnitRef>,
    pub ghost_tier: i64,
    pub ghost_of: i64,
    pub ghost_player: Option<PlayerStateRef>,
    pub display: Dictionary,
    pub record_recipe: Dictionary,
    pub record: Option<GameRecordRef>,
    pub _next_uid: i64,
    pub _rr_order: Array<i64>,
    pub _rr_index: i64,
    pub _any_eliminated: bool,
}
impl Default for GameSession {
    fn default() -> Self {
        Self {
            config: None,
            rules: None,
            geometry: None,
            registry: None,
            library: None,
            units: None,
            spells: None,
            recruit: None,
            players: Array::new(),
            seed_value: 0,
            round_number: 0,
            pairings: Array::new(),
            events: Array::new(),
            fights: Array::new(),
            keep_fight_events: true,
            over: false,
            ghost_board: Array::new(),
            ghost_hand: Array::new(),
            ghost_tier: 1,
            ghost_of: -1,
            ghost_player: None,
            display: Dictionary::new(),
            record_recipe: Dictionary::new(),
            record: None,
            _next_uid: 1,
            _rr_order: Array::new(),
            _rr_index: 0,
            _any_eliminated: false,
        }
    }
}
impl GameSession {
    pub fn create(
        game_seed: i64,
        card_library: &UnitLibraryRef,
        mechanic_registry: &MechanicRegistryRef,
        game_config: Option<GameConfigRef>,
        lobby_tribes: &Array<String>,
    ) -> GameSessionRef {
        let config = game_config.unwrap_or_else(|| Rc::new(RefCell::new(GameConfig::new())));
        let rules = Rc::new(RefCell::new(Rules::new(&config)));
        let geometry =
            BoardGeometry::standard(config.borrow().front_slots, config.borrow().back_slots);
        let units = CardPool::create(
            &card_library.borrow().pool_cards(false),
            &config.borrow().unit_copies_by_tier,
            lobby_tribes,
        );
        let spells = CardPool::create(
            &card_library.borrow().pool_cards(true),
            &config.borrow().spell_copies_by_tier,
            lobby_tribes,
        );
        let session = Rc::new(RefCell::new(Self {
            seed_value: game_seed,
            config: Some(config.clone()),
            rules: Some(rules),
            geometry: Some(geometry.clone()),
            registry: Some(mechanic_registry.clone()),
            library: Some(card_library.clone()),
            units: Some(units),
            spells: Some(spells),
            ..Self::default()
        }));
        let recruit = Rc::new(RefCell::new(Recruit::new(&session)));
        session.borrow_mut().recruit = Some(recruit);
        for id in 0..config.borrow().players {
            session.borrow().players.push(PlayerState::create(
                id,
                geometry.borrow().slot_count,
                config.borrow().starting_health,
                config.borrow().starting_armor,
            ));
            session.borrow()._rr_order.push(id);
        }
        Rng::derive(game_seed, "round_robin")
            .borrow_mut()
            .shuffle(&session.borrow()._rr_order);
        session
    }
    pub fn new_unit(&mut self, card: &UnitDefRef, golden: bool) -> UnitRef {
        self._next_uid += 1;
        Unit::create(
            card,
            self._next_uid - 1,
            golden,
            self.registry.as_ref().expect("session registry"),
            self.config
                .as_ref()
                .expect("session config")
                .borrow()
                .stat_max,
        )
    }
    pub fn log_event(&mut self, event: &Dictionary) {
        if !event.has("round") {
            event.insert("round", self.round_number.into());
        }
        self.events.push(event.clone());
    }
    pub fn player(&self, player_id: i64) -> PlayerStateRef {
        self.players.borrow()[player_id as usize].clone()
    }
    pub fn alive_players(&self) -> Array<PlayerStateRef> {
        self.players
            .borrow()
            .iter()
            .filter(|p| p.borrow().alive)
            .cloned()
            .collect()
    }
    pub fn alive_ids(&self) -> Array<i64> {
        self.alive_players()
            .borrow()
            .iter()
            .map(|p| p.borrow().id)
            .collect()
    }
    pub fn start_round(game: &GameSessionRef) {
        if game.borrow().over {
            return;
        }
        let begin = game.borrow().record.is_none() && !game.borrow().record_recipe.is_empty();
        if begin {
            let record = GameRecord::begin(game);
            game.borrow_mut().record = Some(record);
        }
        game.borrow_mut().round_number += 1;
        let pairs = Self::_pair_round(game);
        game.borrow_mut().pairings = pairs;
        let pairs = game.borrow().pairings.to_state();
        game.borrow_mut()
            .log_event(&crate::state_dict! {"type"=>"round_start","pairs"=>&pairs}.as_dict());
        let recruit = game
            .borrow()
            .recruit
            .as_ref()
            .expect("session recruit")
            .clone();
        let alive = game.borrow().alive_players();
        for each in alive.to_vec() {
            Recruit::start_turn(&recruit, &each);
        }
        let record = game.borrow().record.clone();
        if let Some(record) = record {
            let entry=crate::state_dict!{"op"=>"start","turn"=>&game.borrow().round_number,"hash"=>&RecordState::state_hash(&game.borrow())}.as_dict();
            record.borrow_mut().append(&entry);
        }
    }
    // 2.3.3: GHOST is -1; -2 means unpaired.
    pub fn opponent_of(&self, player_id: i64) -> i64 {
        for pair in self.pairings.borrow().iter() {
            let pair = pair.as_array();
            let p = pair.borrow();
            if p[0].as_i64() == player_id {
                return p[1].as_i64();
            }
            if p[1].as_i64() == player_id {
                return p[0].as_i64();
            }
        }
        -2
    }
    pub fn act(game: &GameSessionRef, player_id: i64, action: &Dictionary) -> String {
        let recruit = game
            .borrow()
            .recruit
            .as_ref()
            .expect("session recruit")
            .clone();
        let player = game.borrow().player(player_id);
        let result = Recruit::act(&recruit, &player, action);
        let record = game.borrow().record.clone();
        if let Some(record) = record {
            record.borrow_mut().append(&crate::state_dict!{"op"=>"act","turn"=>&game.borrow().round_number,"player"=>&player_id,"action"=>action,"result"=>&result}.as_dict());
        }
        result
    }
    pub fn legal_actions(&self, player_id: i64) -> Array<Dictionary> {
        let game = self
            .recruit
            .as_ref()
            .expect("session recruit")
            .borrow()
            ._session_ref
            .upgrade()
            .expect("recruit session");
        LegalActions::of(&game, &self.player(player_id))
    }
    pub fn end_turn(game: &GameSessionRef, player_id: i64) {
        let recruit = game
            .borrow()
            .recruit
            .as_ref()
            .expect("session recruit")
            .clone();
        let player = game.borrow().player(player_id);
        Recruit::end_turn(&recruit, &player);
        let record = game.borrow().record.clone();
        if let Some(record) = record {
            record.borrow_mut().append(&crate::state_dict!{"op"=>"end","turn"=>&game.borrow().round_number,"player"=>&player_id}.as_dict());
        }
    }
    pub fn finish_round(game: &GameSessionRef) -> Array<Dictionary> {
        let round_fights = Array::new();
        if game.borrow().over {
            return round_fights;
        }
        let recruit = game
            .borrow()
            .recruit
            .as_ref()
            .expect("session recruit")
            .clone();
        let alive = game.borrow().alive_players();
        for each in alive.to_vec() {
            Recruit::end_turn(&recruit, &each);
        }
        let record = game.borrow().record.clone();
        if let Some(record) = record {
            let entry = crate::state_dict!{"op"=>"fight_boards","turn"=>&game.borrow().round_number,"players"=>&RecordState::fight_players(&game.borrow()),"hash"=>&RecordState::state_hash(&game.borrow())}.as_dict();
            record.borrow_mut().append(&entry);
        }
        let pairs = game.borrow().pairings.clone();
        let mut i = 0;
        while let Some(value) = pairs.get(i) {
            i += 1;
            let pair = value.as_array();
            round_fights.push(Self::_fight(
                game,
                pair.get(0).expect("pair a").as_i64(),
                pair.get(1).expect("pair b").as_i64(),
            ));
        }
        Self::_eliminate(game);
        Self::_check_end(game);
        let record = game.borrow().record.clone();
        if let Some(record) = record {
            let entry = crate::state_dict!{"op"=>"finish","turn"=>&game.borrow().round_number,"hash"=>&RecordState::state_hash(&game.borrow()),"over"=>&game.borrow().over}.as_dict();
            record.borrow_mut().append(&entry);
        }
        round_fights
    }
    pub fn _pair_round(game: &GameSessionRef) -> Array<Variant> {
        let ids = game.borrow().alive_ids();
        let pairs;
        if !game.borrow()._any_eliminated
            && ids.len() == game.borrow()._rr_order.len()
            && ids.len().is_multiple_of(2)
        {
            pairs = Matchmaking::round_robin(&game.borrow()._rr_order, game.borrow()._rr_index);
            game.borrow_mut()._rr_index += 1;
        } else {
            let history = Dictionary::new();
            for each in game.borrow().players.to_vec() {
                history.insert(
                    each.borrow().id.to_string(),
                    each.borrow().opponents.to_state(),
                );
            }
            pairs = Matchmaking::avoiding(
                &ids,
                &history,
                &Rng::derive(
                    game.borrow().seed_value,
                    &format!("pair:{}", game.borrow().round_number),
                ),
            );
        }
        for value in pairs.to_vec() {
            let pair = value.as_array();
            let a = pair.get(0).expect("pair a").as_i64();
            let b = pair.get(1).expect("pair b").as_i64();
            game.borrow().player(a).borrow().opponents.push(b);
            if b != Matchmaking::GHOST {
                game.borrow().player(b).borrow().opponents.push(a);
            }
        }
        pairs
    }
    pub fn _fight(game: &GameSessionRef, a: i64, b: i64) -> Dictionary {
        let is_ghost = b == Matchmaking::GHOST;
        let player_a = game.borrow().player(a);
        let board_b = if is_ghost {
            game.borrow().ghost_board.clone()
        } else {
            game.borrow().player(b).borrow().board.clone()
        };
        let owner_b = if is_ghost {
            game.borrow().ghost_player.clone()
        } else {
            Some(game.borrow().player(b))
        };
        let hand_b = if is_ghost {
            game.borrow().ghost_hand.clone()
        } else {
            game.borrow().player(b).borrow().hand.clone()
        };
        let seed = Rng::hash32(&format!(
            "{}|fight|{}|{}|{}",
            game.borrow().seed_value,
            game.borrow().round_number,
            a,
            b
        ));
        let combat = {
            let g = game.borrow();
            Combat::create(
                g.geometry.as_ref().expect("geometry"),
                g.config.as_ref().expect("config"),
                g.registry.as_ref().expect("registry"),
                g.library.as_ref().expect("library"),
                seed,
            )
        };
        combat.borrow_mut().keep_events = game.borrow().keep_fight_events;
        let boards = Array::from(vec![player_a.borrow().board.clone(), board_b]);
        let ids = Array::from(vec![a, b]);
        let owners = Array::from(vec![Some(player_a.clone()), owner_b]);
        let live = Array::from(vec![true, !is_ghost]);
        let hands = Array::from(vec![player_a.borrow().hand.clone(), hand_b]);
        let result = combat
            .borrow_mut()
            .run(&boards, &ids, &owners, &live, &hands);
        let winner = result.get("winner").as_i64();
        let mut damage = 0;
        let mut loser_id = -2;
        if winner >= 0 {
            let loser_side = 1 - winner;
            loser_id = if loser_side == 0 { a } else { b };
            let starting = result.get("starting").as_array();
            let killed = result.get("killed").as_array();
            let winner_start = starting
                .get(winner as usize)
                .expect("starting count")
                .as_i64();
            let winner_killed = killed.get(winner as usize).expect("killed count").as_i64();
            let big = winner_killed * 2 < winner_start;
            if loser_id != Matchmaking::GHOST {
                let loser = game.borrow().player(loser_id);
                damage = game
                    .borrow()
                    .rules
                    .as_ref()
                    .expect("rules")
                    .borrow()
                    .loss_damage(&loser, game.borrow().round_number, big);
                game.borrow_mut()._take_damage(&loser, damage);
            }
        }
        let events = if game.borrow().keep_fight_events {
            combat.borrow().events.clone()
        } else {
            Array::new()
        };
        let fight=crate::state_dict!{"round"=>&game.borrow().round_number,"players"=>&vec![a,b],"result"=>&result,"loser"=>&loser_id,"damage"=>&damage,"events"=>&events}.as_dict();
        game.borrow().fights.push(fight.clone());
        let first_after = game.borrow().events.len();
        Self::_after_fight(game, &player_a, &result, 0, b);
        if !is_ghost {
            let player_b = game.borrow().player(b);
            Self::_after_fight(game, &player_b, &result, 1, a);
        }
        // What after_fight changed on the real boards, for the screen that shows the fight.
        let after = Array::from(game.borrow().events.borrow()[first_after..].to_vec());
        fight.insert("after", after.to_state());
        game.borrow_mut().log_event(&crate::state_dict!{"type"=>"fight","players"=>&vec![a,b],"winner"=>&winner,"loser"=>&loser_id,"damage"=>&damage,"reason"=>&result.get("reason")}.as_dict());
        fight
    }
    pub fn _after_fight(
        game: &GameSessionRef,
        each: &PlayerStateRef,
        result: &Dictionary,
        side: i64,
        opponent: i64,
    ) {
        let winner = result.get("winner").as_i64();
        let kept = result.get("survivor_recruit_uids").as_array();
        let mine = kept.get(side as usize).expect("side survivors").as_array();
        let report = Rc::new(RefCell::new(FightReport {
            outcome: if winner < 0 {
                0
            } else if winner == side {
                1
            } else {
                -1
            },
            opponent,
            survivors: mine.borrow().iter().map(Variant::as_i64).collect(),
            deaths: result
                .get("deaths")
                .as_array()
                .get(side as usize)
                .expect("side deaths")
                .as_i64(),
            outnumbered_by: result
                .get("outnumbered_by")
                .as_array()
                .get(side as usize)
                .expect("side outnumbered")
                .as_i64(),
        }));
        let recruit = game
            .borrow()
            .recruit
            .as_ref()
            .expect("session recruit")
            .clone();
        Recruit::after_fight(&recruit, each, &report);
    }
    pub fn view_for(&self, player_id: i64) -> Dictionary {
        let each = self.player(player_id);
        let out = each.borrow().view();
        let rules = self.rules.as_ref().expect("session rules");
        let library = self.library.as_ref().expect("session library");
        let unit_prices = Array::<i64>::new();
        for id in each.borrow().shop_units.to_vec() {
            unit_prices.push(if id.is_empty() {
                -1
            } else {
                rules.borrow().unit_price(
                    &each,
                    &library.borrow().get_card(&id).expect("shop card"),
                    None,
                )
            });
        }
        let spell_prices = Array::<i64>::new();
        for id in each.borrow().shop_spells.to_vec() {
            spell_prices.push(if id.is_empty() {
                -1
            } else {
                rules.borrow().spell_price(
                    &each,
                    &library.borrow().get_card(&id).expect("shop spell"),
                    None,
                )
            });
        }
        let sell = Array::<i64>::new();
        for unit in each.borrow().board.to_vec() {
            sell.push(unit.map_or(-1, |u| rules.borrow().sell_value(&each, &u)));
        }
        out.insert("costs",crate::state_dict!{"refresh"=>&rules.borrow().refresh_cost(&each, None),"upgrade"=>&rules.borrow().upgrade_cost(&each, None),"shop_units"=>&unit_prices,"shop_spells"=>&spell_prices,"sell"=>&sell});
        out.insert(
            "refreshes_left",
            rules.borrow().refreshes_left(&each).into(),
        );
        out.insert("round", self.round_number.into());
        out.insert("opponent", self.opponent_of(player_id).into());
        out.insert("legal_actions", self.legal_actions(player_id).to_state());
        out.insert("display", Variant::Dictionary(self.display.clone()));
        out
    }
    pub fn give_standing(&mut self, mechanic_id: &str) {
        for each in self.players.borrow().iter() {
            if !each.borrow().has_standing(mechanic_id) {
                let registry = self.registry.as_ref().expect("session registry");
                each.borrow().standing.push(registry.borrow().bind(
                    &MechanicSpec::new(mechanic_id, None),
                    false,
                    false,
                ));
            }
        }
    }
    // 10.1.5: armor first, then health.
    pub fn _take_damage(&mut self, loser: &PlayerStateRef, amount: i64) {
        let mut loser = loser.borrow_mut();
        let absorbed = loser.armor.min(amount);
        loser.armor -= absorbed;
        loser.health -= amount - absorbed;
    }
    // 10.2.1-10.2.2 elimination after every fight; 5.3.8 returns cards; 2.1.2 selects ghost.
    pub fn _eliminate(game: &GameSessionRef) {
        let out = Array::new();
        for each in game.borrow().alive_players().to_vec() {
            if each.borrow().health <= 0 {
                out.push(each);
            }
        }
        if out.is_empty() {
            return;
        }
        Rng::derive(
            game.borrow().seed_value,
            &format!("placement:{}", game.borrow().round_number),
        )
        .borrow_mut()
        .shuffle(&out);
        crate::util::godot_sort::sort_by(&mut out.borrow_mut(), |x, y| {
            x.borrow().health < y.borrow().health
        });
        let mut place = game.borrow().alive_players().len() as i64;
        let hands = Dictionary::<Array<UnitRef>, i64>::new();
        for each in out.to_vec() {
            hands
                .borrow_mut()
                .insert(each.borrow().id, each.borrow().hand.duplicate());
            Self::_retire(game, &each, place);
            place -= 1;
        }
        let ghost = out.get(out.len() - 1).expect("eliminated ghost");
        let board = ghost.borrow().board.duplicate();
        let kept = hands.borrow()[&ghost.borrow().id].clone();
        {
            let mut g = game.borrow_mut();
            g.ghost_board = board;
            g.ghost_hand.borrow_mut().clone_from(&kept.borrow());
            g.ghost_player = Some(ghost.clone());
            g.ghost_tier = ghost.borrow().tier;
            g.ghost_of = ghost.borrow().id;
            g._any_eliminated = true;
        }
    }
    pub fn _retire(game: &GameSessionRef, each: &PlayerStateRef, place: i64) {
        {
            let mut p = each.borrow_mut();
            p.alive = false;
            p.placement = place;
            p.eliminated_round = game.borrow().round_number;
        }
        let units = game.borrow().units.as_ref().expect("unit pool").clone();
        let spells = game.borrow().spells.as_ref().expect("spell pool").clone();
        for card in each.borrow().all_cards().to_vec() {
            let pool = if card.borrow().is_spell() {
                &spells
            } else {
                &units
            };
            pool.borrow_mut().give_back(
                &card
                    .borrow()
                    .def
                    .as_ref()
                    .expect("unit definition")
                    .borrow()
                    .id,
                card.borrow().pool_copies,
            );
        }
        for id in each.borrow().shop_units.to_vec() {
            units.borrow_mut().give_back(&id, 1);
        }
        for id in each.borrow().shop_spells.to_vec() {
            spells.borrow_mut().give_back(&id, 1);
        }
        for id in each.borrow().discover_options.to_vec() {
            units.borrow_mut().give_back(&id, 1);
        }
        {
            let p = each.borrow();
            p.shop_units.clear();
            p.shop_spells.clear();
            p.discover_options.clear();
            p.discover_queue.clear();
            p.hand.clear();
        }
        game.borrow_mut().log_event(&crate::state_dict!{"type"=>"eliminated","player"=>&each.borrow().id,"placement"=>&place,"health"=>&each.borrow().health}.as_dict());
    }
    // 10.2.3 one remains; 2.1.3 round-limit placements.
    pub fn _check_end(game: &GameSessionRef) {
        let left = game.borrow().alive_players();
        if left.len() > 1
            && game.borrow().round_number
                < game
                    .borrow()
                    .config
                    .as_ref()
                    .expect("config")
                    .borrow()
                    .round_limit
        {
            return;
        }
        Rng::derive(game.borrow().seed_value, "final_places")
            .borrow_mut()
            .shuffle(&left);
        crate::util::godot_sort::sort_by(&mut left.borrow_mut(), |x, y| {
            x.borrow().health + x.borrow().armor > y.borrow().health + y.borrow().armor
        });
        for i in 0..left.len() {
            left.get(i).expect("final player").borrow_mut().placement = i as i64 + 1;
        }
        game.borrow_mut().over = true;
        let placements = game.borrow().placements();
        game.borrow_mut().log_event(
            &crate::state_dict! {"type"=>"game_end","placements"=>&placements}.as_dict(),
        );
    }
    pub fn placements(&self) -> Dictionary {
        let out = Dictionary::new();
        for each in self.players.borrow().iter() {
            let each = each.borrow();
            out.insert(each.id.to_string(), each.placement.into());
        }
        out
    }
}
impl ToState for GameSession {
    fn to_state(&self) -> Variant {
        self.script_state_without(&[])
    }
    fn script_state_without(&self, skip: &[&str]) -> Variant {
        crate::state_dict! {without skip; "config"=>&self.config,"rules"=>&self.rules,"geometry"=>&self.geometry,"registry"=>&self.registry,"library"=>&self.library,"units"=>&self.units,"spells"=>&self.spells,"recruit"=>&self.recruit,"players"=>&self.players,"seed_value"=>&self.seed_value,"round_number"=>&self.round_number,"pairings"=>&self.pairings,"events"=>&self.events,"fights"=>&self.fights,"keep_fight_events"=>&self.keep_fight_events,"over"=>&self.over,"ghost_board"=>&self.ghost_board,"ghost_hand"=>&self.ghost_hand,"ghost_tier"=>&self.ghost_tier,"ghost_of"=>&self.ghost_of,"ghost_player"=>&self.ghost_player,"display"=>&self.display,"record_recipe"=>&self.record_recipe,"record"=>&self.record,"_next_uid"=>&self._next_uid,"_rr_order"=>&self._rr_order,"_rr_index"=>&self._rr_index,"_any_eliminated"=>&self._any_eliminated}
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "config",
            "rules",
            "geometry",
            "registry",
            "library",
            "units",
            "spells",
            "recruit",
            "players",
            "seed_value",
            "round_number",
            "pairings",
            "events",
            "fights",
            "keep_fight_events",
            "over",
            "ghost_board",
            "ghost_hand",
            "ghost_tier",
            "ghost_of",
            "ghost_player",
            "display",
            "record_recipe",
            "record",
            "_next_uid",
            "_rr_order",
            "_rr_index",
            "_any_eliminated",
        ]
    }
}

#[cfg(test)]
mod session_oracle_tests {
    use super::*;
    use crate::game::game_content::GameContent;
    use std::path::Path;

    // Mirrors gd/prove_session.gd::_fixture; no recruit or Combat calls.
    fn fixture() -> GameSessionRef {
        let root = Path::new(env!("CARGO_MANIFEST_DIR"))
            .ancestors()
            .nth(3)
            .unwrap();
        let content = GameContent::load_folders(root, &Array::new());
        let content = content.borrow();
        assert!(content.errors.is_empty());
        let mut config = GameConfig::new();
        config.round_limit = 9;
        let game = GameSession::create(
            42,
            &content.library,
            &content.registry,
            Some(Rc::new(RefCell::new(config))),
            &Array::new(),
        );
        game.borrow_mut().round_number = 4;
        for id in [0, 1, 2] {
            let each = game.borrow().player(id);
            each.borrow_mut().health = if id == 2 { 0 } else { -2 };
            each.borrow_mut().tier = id + 1;
            let def = content.library.borrow().get_card("t1_plain").unwrap();
            let board = game.borrow_mut().new_unit(&def, true);
            board.borrow_mut().pool_copies = 3;
            each.borrow().board.borrow_mut()[0] = Some(board);
            let units = game.borrow().units.clone().unwrap();
            let spells = game.borrow().spells.clone().unwrap();
            for _ in 0..3 {
                assert!(units.borrow_mut().take("t1_plain"));
            }
            for card_id in ["t1_guard", "sp_sharpen"] {
                let def = content.library.borrow().get_card(card_id).unwrap();
                let card = game.borrow_mut().new_unit(&def, false);
                card.borrow_mut().pool_copies = 1;
                each.borrow().hand.push(card.clone());
                let pool = if card.borrow().is_spell() {
                    &spells
                } else {
                    &units
                };
                assert!(pool.borrow_mut().take(card_id));
            }
            each.borrow().shop_units.push("t1_seed".into());
            assert!(units.borrow_mut().take("t1_seed"));
            each.borrow().shop_spells.push("sp_seek".into());
            assert!(spells.borrow_mut().take("sp_seek"));
            each.borrow().discover_options.push("t1_plain".into());
            assert!(units.borrow_mut().take("t1_plain"));
            each.borrow().discover_queue.push((2, 3));
        }
        game
    }

    fn hash(game: &GameSessionRef, label: &str) {
        let oracle = crate::util::godot_json::parse_string(include_str!(
            "../../../../gd/session_vectors.json"
        ))
        .as_dict();
        assert_eq!(
            RecordState::state_hash(&game.borrow()),
            oracle.get(label).as_text(),
            "{label}"
        );
    }

    #[test]
    fn session_oracle_elimination_ghost_aliases_pair_ties_and_round_limit() {
        let game = fixture();
        hash(&game, "fixture");
        let kept_hand = game.borrow().player(2).borrow().hand.get(0).unwrap();
        GameSession::_eliminate(&game);
        assert_eq!(game.borrow().ghost_of, 2);
        assert!(Rc::ptr_eq(
            &game.borrow().ghost_hand.get(0).unwrap(),
            &kept_hand
        ));
        let ghost = game.borrow().player(2);
        assert!(Rc::ptr_eq(
            game.borrow().ghost_player.as_ref().unwrap(),
            &ghost
        ));
        let board = ghost.borrow().board.get(0).unwrap().unwrap();
        assert!(Rc::ptr_eq(
            &game.borrow().ghost_board.get(0).unwrap().unwrap(),
            &board
        ));
        assert!(ghost.borrow().hand.is_empty());
        assert_eq!(game.borrow().ghost_hand.len(), 2);
        assert_eq!(
            game.borrow()
                .ghost_hand
                .get(0)
                .unwrap()
                .borrow()
                .def
                .as_ref()
                .unwrap()
                .borrow()
                .id,
            "t1_guard"
        );
        for id in [0, 1, 2] {
            let each = game.borrow().player(id);
            let p = each.borrow();
            assert!(!p.alive && p.hand.is_empty());
            assert!(p.shop_units.is_empty() && p.shop_spells.is_empty());
            assert!(p.discover_options.is_empty() && p.discover_queue.is_empty());
        }
        for pool in [
            game.borrow().units.clone().unwrap(),
            game.borrow().spells.clone().unwrap(),
        ] {
            let pool = pool.borrow();
            for id in pool.ids().to_vec() {
                assert_eq!(pool.copies_left(&id), pool.starting_copies(&id), "{id}");
            }
        }
        hash(&game, "eliminate");
        for (round, expected, pairs) in [
            (5, "pair5", "[[3,5],[4,6],[7,-1]]"),
            (6, "pair6", "[[3,7],[4,5],[6,-1]]"),
            (7, "pair7", "[[3,-1],[4,7],[5,6]]"),
            (8, "pair8", "[[3,6],[4,-1],[5,7]]"),
        ] {
            game.borrow_mut().round_number = round;
            let paired = GameSession::_pair_round(&game);
            game.borrow_mut().pairings = paired;
            assert_eq!(
                crate::util::godot_json::stringify(&game.borrow().pairings.to_state()),
                pairs
            );
            hash(&game, expected);
        }
        game.borrow()
            .ghost_board
            .get(0)
            .unwrap()
            .unwrap()
            .borrow_mut()
            .pool_copies = 7;
        assert_eq!(board.borrow().pool_copies, 7);
        game.borrow()
            .ghost_hand
            .get(0)
            .unwrap()
            .borrow_mut()
            .pool_copies = 4;
        game.borrow().ghost_board.borrow_mut()[0] = None;
        assert!(ghost.borrow().board.get(0).unwrap().is_some());
        hash(&game, "alias_mutation");
        game.borrow_mut().round_number = 9;
        for each in game.borrow().alive_players().to_vec() {
            each.borrow_mut().health = 10;
            let id = each.borrow().id;
            each.borrow_mut().armor = id % 2;
        }
        GameSession::_check_end(&game);
        assert!(game.borrow().over);
        hash(&game, "round_limit");
    }

    #[test]
    fn session_oracle_one_remaining_player_ends_before_round_limit() {
        let game = fixture();
        for id in 0..7 {
            game.borrow().player(id).borrow_mut().health = 0;
        }
        GameSession::_eliminate(&game);
        GameSession::_check_end(&game);
        assert!(game.borrow().over);
        assert_eq!(game.borrow().player(7).borrow().placement, 1);
        hash(&game, "one_left");
    }
}
