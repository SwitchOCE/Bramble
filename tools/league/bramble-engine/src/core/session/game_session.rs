//! Mirrors src/core/session/game_session.gd. Round gameplay is filled by recruit/combat workers.
use crate::{Array,Dictionary,ToState,Variant};
use crate::core::{board::board_geometry::{BoardGeometry,BoardGeometryRef},mechanics::{mechanic_registry::MechanicRegistryRef,mechanic_spec::MechanicSpec},recruit::{player_state::{PlayerState,PlayerStateRef},recruit::{Recruit,RecruitRef}},rules::{game_config::{GameConfig,GameConfigRef},rules::{Rules,RulesRef}},units::{card_pool::{CardPool,CardPoolRef},unit::{Unit,UnitRef},unit_def::UnitDefRef,unit_library::UnitLibraryRef},records::game_record::GameRecordRef,util::rng::Rng};
use std::{cell::RefCell,rc::Rc};
pub type GameSessionRef=Rc<RefCell<GameSession>>;
pub struct GameSession {
    pub config:Option<GameConfigRef>,pub rules:Option<RulesRef>,pub geometry:Option<BoardGeometryRef>,pub registry:Option<MechanicRegistryRef>,pub library:Option<UnitLibraryRef>,pub units:Option<CardPoolRef>,pub spells:Option<CardPoolRef>,pub recruit:Option<RecruitRef>,pub players:Array<PlayerStateRef>,pub seed_value:i64,pub round_number:i64,pub pairings:Array<Variant>,pub events:Array<Dictionary>,pub fights:Array<Dictionary>,pub keep_fight_events:bool,pub over:bool,pub ghost_board:Array<Option<UnitRef>>,pub ghost_hand:Array<UnitRef>,pub ghost_tier:i64,pub ghost_of:i64,pub ghost_player:Option<PlayerStateRef>,pub display:Dictionary,pub record_recipe:Dictionary,pub record:Option<GameRecordRef>,pub _next_uid:i64,pub _rr_order:Array<i64>,pub _rr_index:i64,pub _any_eliminated:bool,
}
impl Default for GameSession{fn default()->Self{Self{config:None,rules:None,geometry:None,registry:None,library:None,units:None,spells:None,recruit:None,players:Array::new(),seed_value:0,round_number:0,pairings:Array::new(),events:Array::new(),fights:Array::new(),keep_fight_events:true,over:false,ghost_board:Array::new(),ghost_hand:Array::new(),ghost_tier:1,ghost_of:-1,ghost_player:None,display:Dictionary::new(),record_recipe:Dictionary::new(),record:None,_next_uid:1,_rr_order:Array::new(),_rr_index:0,_any_eliminated:false}}}
impl GameSession{
    pub fn create(game_seed:i64,card_library:&UnitLibraryRef,mechanic_registry:&MechanicRegistryRef,game_config:Option<GameConfigRef>,lobby_tribes:&Array<String>)->GameSessionRef{
        let config=game_config.unwrap_or_else(||Rc::new(RefCell::new(GameConfig::new())));
        let rules=Rc::new(RefCell::new(Rules::new(&config)));
        let geometry=BoardGeometry::standard(config.borrow().front_slots,config.borrow().back_slots);
        let units=CardPool::create(&card_library.borrow().pool_cards(false),&config.borrow().unit_copies_by_tier,lobby_tribes);
        let spells=CardPool::create(&card_library.borrow().pool_cards(true),&config.borrow().spell_copies_by_tier,lobby_tribes);
        let session=Rc::new(RefCell::new(Self{seed_value:game_seed,config:Some(config.clone()),rules:Some(rules),geometry:Some(geometry.clone()),registry:Some(mechanic_registry.clone()),library:Some(card_library.clone()),units:Some(units),spells:Some(spells),..Self::default()}));
        let recruit=Rc::new(RefCell::new(Recruit::new(&session)));session.borrow_mut().recruit=Some(recruit);
        for id in 0..config.borrow().players{session.borrow().players.push(PlayerState::create(id,geometry.borrow().slot_count,config.borrow().starting_health,config.borrow().starting_armor));session.borrow()._rr_order.push(id);}
        Rng::derive(game_seed,"round_robin").borrow_mut().shuffle(&session.borrow()._rr_order);
        session
    }
    pub fn new_unit(&mut self,card:&UnitDefRef,golden:bool)->UnitRef{self._next_uid+=1;Unit::create(card,self._next_uid-1,golden,self.registry.as_ref().expect("session registry"),self.config.as_ref().expect("session config").borrow().stat_max)}
    pub fn log_event(&mut self,event:&Dictionary){if !event.has("round"){event.insert("round",self.round_number.into());}self.events.push(event.clone());}
    pub fn player(&self,player_id:i64)->PlayerStateRef{self.players.borrow()[player_id as usize].clone()}
    pub fn alive_players(&self)->Array<PlayerStateRef>{self.players.borrow().iter().filter(|p|p.borrow().alive).cloned().collect()}
    pub fn alive_ids(&self)->Array<i64>{self.alive_players().borrow().iter().map(|p|p.borrow().id).collect()}
    pub fn start_round(_game:&GameSessionRef){todo!("port src/core/session/game_session.gd:start_round")}
    // 2.3.3: GHOST is -1; -2 means unpaired.
    pub fn opponent_of(&self,player_id:i64)->i64{for pair in self.pairings.borrow().iter(){let pair=pair.as_array();let p=pair.borrow();if p[0].as_i64()==player_id{return p[1].as_i64();}if p[1].as_i64()==player_id{return p[0].as_i64();}}-2}
    pub fn act(_game:&GameSessionRef,_player_id:i64,_action:&Dictionary)->String{todo!("port src/core/session/game_session.gd:act")}
    pub fn legal_actions(&self,_player_id:i64)->Array<Dictionary>{todo!("port src/core/session/game_session.gd:legal_actions")}
    pub fn end_turn(_game:&GameSessionRef,_player_id:i64){todo!("port src/core/session/game_session.gd:end_turn")}
    pub fn finish_round(_game:&GameSessionRef)->Array<Dictionary>{todo!("port src/core/session/game_session.gd:finish_round")}
    pub fn _pair_round(_game:&GameSessionRef)->Array<Variant>{todo!("port src/core/session/game_session.gd:_pair_round")}
    pub fn _fight(_game:&GameSessionRef,_a:i64,_b:i64)->Dictionary{todo!("port src/core/session/game_session.gd:_fight")}
    pub fn _after_fight(_game:&GameSessionRef,_each:&PlayerStateRef,_result:&Dictionary,_side:i64,_opponent:i64){todo!("port src/core/session/game_session.gd:_after_fight")}
    pub fn view_for(&self,_player_id:i64)->Dictionary{todo!("port src/core/session/game_session.gd:view_for")}
    pub fn give_standing(&mut self,mechanic_id:&str){for each in self.players.borrow().iter(){if !each.borrow().has_standing(mechanic_id){let registry=self.registry.as_ref().expect("session registry");each.borrow().standing.push(registry.borrow().bind(&MechanicSpec::new(mechanic_id,None),false,false));}}}
    // 10.1.5: armor first, then health.
    pub fn _take_damage(&mut self,loser:&PlayerStateRef,amount:i64){let mut loser=loser.borrow_mut();let absorbed=loser.armor.min(amount);loser.armor-=absorbed;loser.health-=amount-absorbed;}
    // 10.2.1-10.2.2 elimination after every fight; 5.3.8 returns cards; 2.1.2 selects ghost.
    pub fn _eliminate(_game:&GameSessionRef){todo!("port src/core/session/game_session.gd:_eliminate")}
    pub fn _retire(_game:&GameSessionRef,_each:&PlayerStateRef,_place:i64){todo!("port src/core/session/game_session.gd:_retire")}
    // 10.2.3 one remains; 2.1.3 round-limit placements.
    pub fn _check_end(_game:&GameSessionRef){todo!("port src/core/session/game_session.gd:_check_end")}
    pub fn placements(&self)->Dictionary{let out=Dictionary::new();for each in self.players.borrow().iter(){let each=each.borrow();out.insert(each.id.to_string(),each.placement.into());}out}
}
impl ToState for GameSession{
    fn to_state(&self)->Variant{crate::state_dict!{"config"=>&self.config,"rules"=>&self.rules,"geometry"=>&self.geometry,"registry"=>&self.registry,"library"=>&self.library,"units"=>&self.units,"spells"=>&self.spells,"recruit"=>&self.recruit,"players"=>&self.players,"seed_value"=>&self.seed_value,"round_number"=>&self.round_number,"pairings"=>&self.pairings,"events"=>&self.events,"fights"=>&self.fights,"keep_fight_events"=>&self.keep_fight_events,"over"=>&self.over,"ghost_board"=>&self.ghost_board,"ghost_hand"=>&self.ghost_hand,"ghost_tier"=>&self.ghost_tier,"ghost_of"=>&self.ghost_of,"ghost_player"=>&self.ghost_player,"display"=>&self.display,"record_recipe"=>&self.record_recipe,"record"=>&self.record,"_next_uid"=>&self._next_uid,"_rr_order"=>&self._rr_order,"_rr_index"=>&self._rr_index,"_any_eliminated"=>&self._any_eliminated}}
    fn field_names()->&'static [&'static str]{&["config","rules","geometry","registry","library","units","spells","recruit","players","seed_value","round_number","pairings","events","fights","keep_fight_events","over","ghost_board","ghost_hand","ghost_tier","ghost_of","ghost_player","display","record_recipe","record","_next_uid","_rr_order","_rr_index","_any_eliminated"]}
}
